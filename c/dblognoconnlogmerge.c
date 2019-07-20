/****************************************************************************
** (c) Copyright IBM Corp. 2011 All rights reserved.
** 
** The following sample of source code ("Sample") is owned by International 
** Business Machines Corporation or one of its subsidiaries ("IBM") and is 
** copyrighted and licensed, not sold. You may use, copy, modify, and 
** distribute the Sample in any form without payment to IBM, for the purpose of 
** assisting you in the development of your applications.
** 
** The Sample code is provided to you on an "AS IS" basis, without warranty of 
** any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
** IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
** not allow for the exclusion or limitation of implied warranties, so the above 
** limitations or exclusions may not apply to you. IBM shall not be liable for 
** any damages you suffer as a result of using, copying, modifying or 
** distributing the Sample, even if IBM has been advised of the possibility of 
** such damages.
*****************************************************************************
**
** SOURCE FILE NAME: dblognoconnlogmerge.sqc
**
** SAMPLE: How to read and merge the database logs in pureScale with
**         no database connection
**
** Archive logging needs to be enabled to read database logs when there is 
** no connection to the database. The database logs are archived and read 
** from the archive location.
**
** PREREQUISITES :
**    -  Log stream paths passed in should be in 'ascending' order
**       based on the log stream number.
**
**    - Member numbers must start at 0 and can only incrementally
**      increase
**
** Note : log paths with no logs will not be included in the log merge
**
** EXECUTION:  dblognoconnlogmerge <db name> <logpath1> <logpath2> ... <logpathi>
**
** DB2 APIs USED:
**         db2ReadLogNoConn -- Read the database logs without a db connection 
**         db2ReadLogNoConnInit -- Initialize reading the database logs 
**                                 without a db connection 
**         db2ReadLogNoConnTerm -- Terminate reading the database logs 
**                                 without a db connection 
**
*****************************************************************************
**
** For detailed information about database backup and database recovery, see
** the Data Recovery and High Availability Guide and Reference. This manual
** will help you to determine which database and table space recovery methods
** are best suited to your business environment.
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
**
** For information on using SQL statements, see the SQL Reference.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <sqlenv.h>
#include <sqlca.h>
#include <db2ApiDf.h>
#include <string.h>

#define   DB2VERSION     db2Version1010

#define   TRUE           1
#define   FALSE          0

#define   READLOG_ERR_READ_ERROR      1
#define   READLOG_ERR_NO_LOGS         2
#define   READLOG_ERR_READ_TO_CUR     3
#define   READLOG_ERR_DISPLAY         4


/* Log record header */
typedef struct BASE_LOG_RECORD_HEADER
{
   db2Uint32           logRecordLength;
   db2Uint16           logRecordType;
   db2Uint16           logRecordFlags;
   db2LSN              logRecordLSN;
   db2Uint64           logRecordLFS;
   db2Uint64           prevLogRecordLSO;
   unsigned char       logRecordTID[6];
   db2LogStreamIDType  logRecordLogStreamID;
} BASE_LOG_RECORD_HEADER;


/* Each log streams read control block */
typedef struct LOGSTREAM_READ_CB
{
   struct sqlca                   sqlca;
   db2LSN                         endLSN;
   db2LRI                         currentLRI;
   int                            logStreamNumber;
   char                          *readLogMemBlock;
   char                          *logBuffer;
   int                            logBufferSize;
   char                          *curLogBuffPtr;
   int                            numLogRecordsRemaining;
   int                            needTermReadLog;
   db2ReadLogNoConnInfoStruct    *readLogInfo;
} LOGSTREAM_READ_CB;

/* sorted queue element */
typedef struct SORTED_QUEUE_ELEMENT
{
   LOGSTREAM_READ_CB            *streamCB;
   struct SORTED_QUEUE_ELEMENT  *nextElement;
} SORTED_QUEUE_ELEMENT;

/* read log control block */
typedef struct READLOG_NC_CB
{
   SORTED_QUEUE_ELEMENT   *qHead;
   SORTED_QUEUE_ELEMENT   *lastReadFromQElem;
   db2LRI                  lastReadLri;
   db2LRI                  prevLastReadLri;
   char                   *logRecord;
} READLOG_NC_CB;


/****************************************************************************
 * Function Nuame:
 *    compLRItype1
 *
 * Description:
 *    Compare two type 1 db2LRIs
 *
 * Input:
 *    lhsLRI - first db2LRI to compare
 *    rhsLRI - second db2LRI to compare
 *
 * Output:
 *     1 if lhsLRI is > than rhsLRI
 *     0 if lhsLRI is == to rhsLRI
 *    -1 if lhsLRI is < than rhsLRI
 ***************************************************************************/
int compLRItype1(db2LRI *lhsLRI, db2LRI *rhsLRI)
{
   if (lhsLRI->part1 > rhsLRI->part1) return 1;
   if (lhsLRI->part1 < rhsLRI->part1) return -1;
   if (lhsLRI->part2 > rhsLRI->part2) return 1;
   if (lhsLRI->part2 < rhsLRI->part2) return -1;

   return 0;
}

/****************************************************************************
 * Function Name:
 *    ableToReadFromSameLogStream
 *
 * Description:
 *    Returns whether or not it is possible to continue reading from the
 *    same log stream without sorting the queue again.
 *
 * Input:
 *    readLogCB - read log CB
 *
 * Output:
 *     TRUE if possible to continue reading from the same log stream
 *     FALSE otherwise
 ***************************************************************************/
int ableToReadFromSameLogStream(READLOG_NC_CB *readLogCB)
{
   if (readLogCB->lastReadFromQElem != NULL)
   {
      db2Uint64 lfsDiff = readLogCB->lastReadFromQElem->streamCB->currentLRI.part1 -
                          readLogCB->lastReadLri.part1;
      if (lfsDiff < 2)
      {
         return TRUE;
      }
   }
   return FALSE;
}

/****************************************************************************
 * Function Name:
 *    enqueueElement
 *
 * Description:
 *    Insert a SORTED_QUEUE_ELEMENT into the queue, specified by qHead.
 *    The new queue element will be inserted in the correct order based
 *    on the next available db2LRI available in it's log output buffer.
 *
 * Input:
 *    qHead - pointer to pointer of the first queue element in the queue
 *    qElement - pointer to queue element to insert into queue
 *
 ***************************************************************************/
void enqueueElement(SORTED_QUEUE_ELEMENT   **qHead,
                    SORTED_QUEUE_ELEMENT    *qElement)
{
   SORTED_QUEUE_ELEMENT *myQHead      = *qHead;
   SORTED_QUEUE_ELEMENT *prevQElement = NULL;

   while (myQHead != NULL)
   {
      if (compLRItype1(&myQHead->streamCB->currentLRI,
                       &qElement->streamCB->currentLRI) > 0)
      {
         break;
      }
      prevQElement = myQHead;
      myQHead = myQHead->nextElement;
   }

   if (prevQElement == NULL)
   {
      *qHead = qElement;
   }
   else
   {
      prevQElement->nextElement = qElement;
   }

   if (myQHead != NULL)
   {
      qElement->nextElement = myQHead;
   }
}


/****************************************************************************
 * Function Name:
 *    freeLogStreamCB
 *
 * Description:
 *    Frees the memory allocated for the LOGSTREAM_READ_CB.
 *
 * Input:
 *    logStreamCB - pointer to pointer to LOGSTREAM_READ_CB
 *
 ***************************************************************************/
void freeLogStreamCB(LOGSTREAM_READ_CB **logStreamCB)
{
   if (*logStreamCB)
   {
      LOGSTREAM_READ_CB *pLogStreamStruct = *logStreamCB;
      if (pLogStreamStruct->needTermReadLog)
      {
         struct db2ReadLogNoConnTermStruct readLogTerm = { 0 };
         readLogTerm.poReadLogMemPtr = &pLogStreamStruct->readLogMemBlock;
         db2ReadLogNoConnTerm(DB2VERSION,
                              &readLogTerm,
                              &(pLogStreamStruct->sqlca));
      }

      if (pLogStreamStruct->readLogInfo)
      {
         free(pLogStreamStruct->readLogInfo);
      }

      if (pLogStreamStruct->logBuffer)
      {
         free(pLogStreamStruct->logBuffer);
      }

      free(pLogStreamStruct);
      *logStreamCB = NULL;
      pLogStreamStruct = NULL;
   }
   return;
}


/****************************************************************************
 * Function Name:
 *    freeSortedQueueElement
 *
 * Description:
 *    Frees the memory allocated for the a SORTED_QUEUE_ELEMENT
 *
 * Input:
 *    qElement - pointer to pointer to SORTED_QUEUE_ELEMENT
 *
 ***************************************************************************/
void freeSortedQueueElement(SORTED_QUEUE_ELEMENT  **qElement)
{
   if (*qElement)
   {
      SORTED_QUEUE_ELEMENT *pQElement = *qElement;
      if (pQElement->streamCB)
      {
         freeLogStreamCB(&pQElement->streamCB);
      }

      if (pQElement->nextElement)
      {
         freeSortedQueueElement(&pQElement->nextElement);
      }
      free(pQElement);
      *qElement = NULL;
      pQElement = NULL;
   }
   return;
}

/****************************************************************************
 * Function Name:
 *    getReasonCodeForInvaidParam
 *
 * Description:
 *    Returns the numeric reasonCode from the sqlca when the sqlcode
 *    is -2650
 *
 * Input:
 *    sqlca - pointer to sqlca
 *
 * Output:
 *    numeric value of the reasonCode found in the sqlca
 ***************************************************************************/
int getReasonCodeForInvaidParam(struct sqlca  *sqlca)
{
   int reasonCode = 0;
   int i = 0;
   int numDelimiters = 0;
   while (i < sqlca->sqlerrml)
   {
      if (sqlca->sqlerrmc[i] == '\xff')
      {
         numDelimiters++;
         if (numDelimiters == 2)
         {
            reasonCode = atoi(&sqlca->sqlerrmc[i+1]);
            break;
         }
      }
      i++;
   }
   return reasonCode;
}


/****************************************************************************
 * Function Name:
 *    getBaseLogRecordHeader
 *
 * Description:
 *    Given the pointer to the start of a log record in the buffer,
 *    (includes db2LSN value pre-pended to the log record), will return
 *    a pointer to the log record header.
 *
 * Input:
 *    logBuffer - pointer to start of log record, including pre-pended
 *                db2LSN
 *    lrh - pointer to pointer to BASE_LOG_RECORD_HEADER
 *
 * Output:
 *    lrh - will be set to point to the log record header
 ***************************************************************************/
void getBaseLogRecordHeader(char                     *logBuffer,
                            BASE_LOG_RECORD_HEADER  **lrh)
{
   db2LSN   *logRecordLsn = (db2LSN *)logBuffer;
   char     *recordPtr    = logBuffer + sizeof(*logRecordLsn);

   *lrh = (BASE_LOG_RECORD_HEADER *)recordPtr;
}


/****************************************************************************
 * Function Name:
 *    getFirstLriValue
 *
 * Description:
 *    Given the pointer to the start of a log record in the buffer,
 *    (includes db2LSN value pre-pended to the log record), will return
 *    the log record's type 1 LRI.
 *
 * Input:
 *    logBuffer - pointer to start of log record, including pre-pended
 *                db2LSN
 *    lri - pointer to LRI to set.
 *
 * Output:
 *    lri - will be set to the log record's type 1 LRI value
 ***************************************************************************/
void getFirstLriValue(char      *logBuffer,
                      db2LRI    *lri)
{
   BASE_LOG_RECORD_HEADER *logRecordHeader = NULL;

   getBaseLogRecordHeader(logBuffer, &logRecordHeader);


   lri->lriType = DB2READLOG_LRI_1;
   lri->part1 = logRecordHeader->logRecordLFS;
   lri->part2 = logRecordHeader->logRecordLSN.lsnU64;
}


/****************************************************************************
 * Function Name:
 *    getNextLogRecPtr
 *
 * Description:
 *    Given the pointer to the start of a log record in the buffer,
 *    (includes db2LSN value pre-pended to the log record), will return
 *    the pointer to the start of the next log record in the buffer.
 *
 * Input:
 *    logBuffer - pointer to start of log record, including pre-pended
 *                db2LSN
 *    nextLogRecrd - pointer to pointer to be set to point to next log
 *                   record in the buffer
 *
 * Output:
 *    nextLogRecord - set to point to the next log record in the buffer.
 ***************************************************************************/
void getNextLogRecPtr(char     *logBuffer,
                      char    **nextLogRecord)
{
   BASE_LOG_RECORD_HEADER *logRecordHeader = NULL;
   getBaseLogRecordHeader(logBuffer, &logRecordHeader);

   *nextLogRecord =   logBuffer
                    + logRecordHeader->logRecordLength
                    + sizeof(db2LSN);
}


/****************************************************************************
 * Function Name:
 *    initializeReadLog
 *
 * Description:
 *    Given the db2ReadLogNoConnInitStruct, calls db2ReadLogNoConnInit
 *    and initializes the logStreamCB.
 *
 * Input:
 *    readLogInit - pointer to db2ReadLogNoConnInitStruct to pass to
 *                  db2ReadLogNoConnInit
 *    endLSN - end LSN to read to
 *    logStreamNumber - log stream number
 *    logStreamCB - pointer to pointer to LOGSTREAM_READ_CB to initialize
 *
 * Output:
 *    logStreamCB - allocated and setup after call to db2ReadLogNoConnInit
 *
 * Normal return:
 *     0
 *
 * Error return:
 *    READLOG_ERR_NO_LOGS - if there are no logs
 *    READLOG_ERR_READ_ERROR - for any other unexpected error
 ***************************************************************************/
int initializeReadLog(db2ReadLogNoConnInitStruct   *readLogInit,
                      db2LSN                       *endLSN,
                      int                           logStreamNumber,
                      LOGSTREAM_READ_CB           **logStreamCB)
{
   int rc = 0;
   LOGSTREAM_READ_CB *pLogStreamStruct = NULL;

   pLogStreamStruct = (LOGSTREAM_READ_CB *)malloc(sizeof(LOGSTREAM_READ_CB));

   memset(pLogStreamStruct, 0, sizeof(LOGSTREAM_READ_CB));

   db2ReadLogNoConnInit(DB2VERSION, readLogInit, &pLogStreamStruct->sqlca);

   if (   (pLogStreamStruct->sqlca.sqlcode != SQLU_RLOG_LSNS_REUSED)
       && (pLogStreamStruct->sqlca.sqlcode < 0))
   {
      int reasonCode = getReasonCodeForInvaidParam(&pLogStreamStruct->sqlca);
      if (reasonCode == 11)
      {
         printf("No logs to read from DB partition %s!\n", readLogInit->piDbPartitionName);
         rc = READLOG_ERR_NO_LOGS;
         goto Finish;
      }
      else
      {
         SqlInfoPrint("Error initializing no conn api", &pLogStreamStruct->sqlca,
               __LINE__, __FILE__);
         rc = READLOG_ERR_READ_ERROR;
      }
      goto Finish;
   }

   pLogStreamStruct->logStreamNumber = logStreamNumber;
   pLogStreamStruct->endLSN          = *endLSN;
   pLogStreamStruct->readLogMemBlock = *readLogInit->poReadLogMemPtr;
   pLogStreamStruct->logBufferSize   = 32 * 4096;
   pLogStreamStruct->logBuffer       = (char *)malloc(pLogStreamStruct->logBufferSize);
   pLogStreamStruct->readLogInfo     = (db2ReadLogNoConnInfoStruct *)malloc(sizeof(db2ReadLogNoConnInfoStruct));
   pLogStreamStruct->curLogBuffPtr  = pLogStreamStruct->logBuffer;
   pLogStreamStruct->numLogRecordsRemaining = 0;

   memset(pLogStreamStruct->readLogInfo, 0, sizeof(*(pLogStreamStruct->readLogInfo)));

   pLogStreamStruct->needTermReadLog = TRUE;
   *logStreamCB = pLogStreamStruct;

Finish:
   return rc;
}


/****************************************************************************
 * Function Name:
 *    initializeAndReadAllStreams
 *
 * Description:
 *    Initialize and make an initial call to read logs for all log streams.
 *    Will allocate one SORTED_QUEUE_ELEMENT for each log stream which
 *    contains logs.
 *
 * Input:
 *    dbAlias - database name
 *    logPaths - pointer to list of log paths to read try reading from
 *    numPaths - number of log paths to check
 *    qHead - pointer to pointer to be set to the head of the queue
 *            when it is allocated
 *
 * Output:
 *    qHead - allocated and setup after call to db2ReadLogNoConnInit
 *
 * Normal return:
 *     0
 *
 * Error return:
 *    READLOG_ERR_READ_TO_CUR - if read to end of logs
 *    READLOG_ERR_NO_LOGS - if there are no logs
 *    READLOG_ERR_READ_ERROR - for any other unexpected error
 ***************************************************************************/
int initializeAndReadAllStreams(char                     *dbAlias,
                                char                    **logPaths,
                                int                       numPaths,
                                SORTED_QUEUE_ELEMENT    **qHead)
{
   int                    rc              = 0;
   SORTED_QUEUE_ELEMENT  *myQHead         = NULL;
   db2Uint32              readLogMemSize  = 16 * 4096;
   char                   memNameBase[10] = "NODE000\0";
   char                   memName[10]     = {'\0'};
   db2LSN                 endLSN          = {0};
   int                    i               = 0;

   endLSN.lsnU64 = (db2Uint64)-1;

   for (i = 0; i < numPaths; i++)
   {
      LOGSTREAM_READ_CB     *logStreamCB     = NULL;
      char                  *readLogMemory   = NULL;
      int                    reasonCode      = 0;
      int                    readToCur       = FALSE;
      struct db2ReadLogNoConnInitStruct readLogInit = { 0 };

      /* Assume that member number is incremental and starts at 0 */
      sprintf(memName, "%s%d", memNameBase, i );

      readLogInit.iFilterOption       = DB2READLOG_FILTER_OFF;
      readLogInit.piLogFilePath       = *(logPaths + i);
      readLogInit.piOverflowLogPath   = NULL;
      readLogInit.iRetrieveLogs       = DB2READLOG_RETRIEVE_OFF;
      readLogInit.piDatabaseName      = dbAlias;
      readLogInit.piDbPartitionName   = memName;
      readLogInit.iReadLogMemoryLimit = readLogMemSize;
      readLogInit.poReadLogMemPtr     = &readLogMemory;

      /* Initialize each log stream */
      rc = initializeReadLog(&readLogInit,
                             &endLSN,
                             i,
                             &logStreamCB);
      if (rc == READLOG_ERR_NO_LOGS)
      {
         freeLogStreamCB(&logStreamCB);
         rc = 0;
         continue;
      }
      else if (rc != 0)
      {
         printf("Error initializing read log!\n");
         goto Finish;
      }

      /* query the log to set the startLSN */
      rc = queryTheLog(logStreamCB);
      if (rc == READLOG_ERR_NO_LOGS)
      {
         /* skip this log stream if there are no logs found */
         freeLogStreamCB(&logStreamCB);
         rc = 0;
         continue;
      }
      else if (rc != 0)
      {
         printf("Error querying readlog!\n");
         goto Finish;
      }

      /* Start reading the log now */
      rc = readTheLog(&logStreamCB->readLogInfo->nextStartLSN,
                      &logStreamCB->endLSN,
                      logStreamCB);
      if (rc != 0)
      {
         printf("Error reading from readlog!\n");
         goto Finish;
      }
      else if (logStreamCB->numLogRecordsRemaining <= 0)
      {
         /* skip this log stream if there are no logs found */
         rc = 0;
         freeLogStreamCB(&logStreamCB);
         continue;
      }

      /**
       ** if some log records were read, allocate a queue element and
       ** add it to the queue
       **/
      myQHead = (SORTED_QUEUE_ELEMENT *)malloc(sizeof(SORTED_QUEUE_ELEMENT));
      myQHead->streamCB = logStreamCB;
      myQHead->nextElement = NULL;
      getFirstLriValue(logStreamCB->logBuffer,
                       &logStreamCB->currentLRI);
      enqueueElement(qHead, myQHead);
   }

Finish:
   if (   (rc == 0)
       && (*qHead == NULL))
   {
      rc = READLOG_ERR_READ_TO_CUR;
   }

   return rc;
}


/****************************************************************************
 * Function Name:
 *    queryTheLog
 *
 * Description:
 *    Calls db2ReadLogNoConn to query for the startLSN
 *
 * Input:
 *    logStreamCB - pointer to LOGSTREAM_READ_CB
 *
 * Normal return:
 *     0
 *
 * Error return:
 *    READLOG_ERR_NO_LOGS - if there are no logs
 *    READLOG_ERR_READ_ERROR - for any other unexpected error
 ***************************************************************************/
int queryTheLog(LOGSTREAM_READ_CB *logStreamCB)
{
   int rc = 0;
   db2ReadLogNoConnStruct readLogInput = { 0 };

   readLogInput.iCallerAction   = DB2READLOG_QUERY;
   readLogInput.piStartLSN      = NULL;
   readLogInput.piEndLSN        = NULL;
   readLogInput.poLogBuffer     = NULL;
   readLogInput.iLogBufferSize  = 0;
   readLogInput.piReadLogMemPtr = logStreamCB->readLogMemBlock;
   readLogInput.poReadLogInfo   = logStreamCB->readLogInfo;

   db2ReadLogNoConn(DB2VERSION,
                    &readLogInput,
                    &logStreamCB->sqlca);
   if (logStreamCB->sqlca.sqlcode != 0)
   {
      if (logStreamCB->sqlca.sqlcode == -2650)
      {
         /* invalid parameter, check if the reason is because the log path
          * is not valid. If so, just skip it.
          */
         int reasonCode = getReasonCodeForInvaidParam(&logStreamCB->sqlca);
         if (reasonCode == 11)
         {
            printf("No logs to read!");
            rc = READLOG_ERR_NO_LOGS;
            goto Finish;
         }
      }
      else
      {
         SqlInfoPrint("Error querying the logs!", &logStreamCB->sqlca,
                      __LINE__, __FILE__);
         printf("Error querying the logs!");
         rc = READLOG_ERR_READ_ERROR;
      }
   }


Finish:
   return rc;
}


/****************************************************************************
 * Function Name:
 *    readTheLog
 *
 * Description:
 *    Calls db2ReadLogNoConn to read the log
 *
 * Input:
 *    startLSN - startLSN to read from
 *    endLSN - endLSN to read to
 *    logStreamCB - pointer to LOGSTREAM_READ_CB
 *
 * Output:
 *    logStreamCB->logBuffer - contains log records read
 *
 * Normal return:
 *     0
 *
 * Error return:
 *    READLOG_ERR_NO_LOGS - if there are no logs
 *    READLOG_ERR_READ_ERROR - for any other unexpected error
 ***************************************************************************/
int readTheLog(db2LSN                 *startLSN,
               db2LSN                 *endLSN,
               LOGSTREAM_READ_CB      *logStreamCB)
{
   int  rc = 0;
   db2ReadLogNoConnStruct readLogInput = { 0 };
   db2LSN   myStartLSN = {0};
   db2LSN   myEndLSN   = {0};

   memcpy(&myStartLSN, startLSN, sizeof(myStartLSN));
   memcpy(&myEndLSN, endLSN, sizeof(myEndLSN));

   readLogInput.iCallerAction    = DB2READLOG_READ;
   readLogInput.piStartLSN       = &myStartLSN;
   readLogInput.piEndLSN         = &myEndLSN;
   readLogInput.poLogBuffer      = logStreamCB->logBuffer;
   readLogInput.iLogBufferSize   = logStreamCB->logBufferSize;
   readLogInput.piReadLogMemPtr  = logStreamCB->readLogMemBlock;
   readLogInput.poReadLogInfo    = logStreamCB->readLogInfo;

   db2ReadLogNoConn(DB2VERSION,
                    &readLogInput,
                    &logStreamCB->sqlca);
   if (   (logStreamCB->sqlca.sqlcode != SQLU_RLOG_READ_TO_CURRENT)
       && (logStreamCB->sqlca.sqlcode < 0))
   {
      SqlInfoPrint("Error reading from logs!", &logStreamCB->sqlca,
                   __LINE__, __FILE__);
      rc = READLOG_ERR_READ_ERROR;
   }
   else if ((logStreamCB->readLogInfo->logRecsWritten == 0))
   {
      /* No more log from the log stream */
      logStreamCB->curLogBuffPtr    = NULL;
      logStreamCB->currentLRI.part1 = (db2Uint64) -1;
      logStreamCB->currentLRI.part2 = (db2Uint64) -1;
   }
   else
   {
      /* There are more log records from this log stream */
      logStreamCB->curLogBuffPtr = logStreamCB->logBuffer;
      logStreamCB->numLogRecordsRemaining =
              logStreamCB->readLogInfo->logRecsWritten;
      getFirstLriValue(logStreamCB->curLogBuffPtr, &logStreamCB->currentLRI);
   }

   return rc;
}


/****************************************************************************
 * Function Name:
 *    getNextLogRecordFromLogStream
 *
 * Description:
 *    Gets the next log reacod for the given log stream.
 *    Note, that this function assumes there is at least 1 log reocrd
 *    available in the log buffer. When the last log record is consumed
 *    from the buffer, another call to db2ReadLogNoConn is made to
 *    read more log records into the buffer.
 *
 * Input:
 *    streamCB - pointer to LOGSTREAM_READ_CB
 *    logLRI - pointer to log record identifier
 *    logBuffer - pointer to log buffer
 *
 * Output:
 *    logLRI - set to the log record identifier for the log record being
 *             returned
 *    logBuffer - log record copied over to the buffer
 *
 * Normal return:
 *     0
 *
 * Error return:
 *    READLOG_ERR_NO_LOGS - if there are no logs
 *    READLOG_ERR_READ_ERROR - for any other unexpected error
 ***************************************************************************/
int getNextLogRecordFromLogStream(LOGSTREAM_READ_CB   *streamCB,
                                  db2LRI              *logLRI,
                                  char                *logBuffer)
{
   int                       rc   = 0;
   BASE_LOG_RECORD_HEADER   *lrh  = NULL;

   getFirstLriValue(streamCB->curLogBuffPtr, logLRI);
   getBaseLogRecordHeader(streamCB->curLogBuffPtr, &lrh);

   /* Copy the log record to the provieded logBuffer */
   memcpy(logBuffer, streamCB->curLogBuffPtr,
          lrh->logRecordLength + sizeof(db2LSN));

   streamCB->numLogRecordsRemaining--;

   if (streamCB->numLogRecordsRemaining > 0)
   {
      /* There are still more log records in the db2ReadLogNoConn output
       * buffer, so just move along the buffer to the next log record
       */
      getNextLogRecPtr(streamCB->curLogBuffPtr, &streamCB->curLogBuffPtr);
      getFirstLriValue(streamCB->curLogBuffPtr, &streamCB->currentLRI);
   }
   else
   {
      /* Check if the last call recieved SQLU_RLOG_READ_TO_CURRENT,
       * if so, reset curLogBuffPtr and the currentLRI. This
       * stream will be removed from the queue, after processing the
       * log record being returned now
       */
      if (streamCB->sqlca.sqlcode == SQLU_RLOG_READ_TO_CURRENT)
      {
         streamCB->curLogBuffPtr    = NULL;
         streamCB->currentLRI.part1 = (db2Uint64) -1;
         streamCB->currentLRI.part2 = (db2Uint64) -1;
      }
      else
      {
         rc = readTheLog(&streamCB->readLogInfo->nextStartLSN,
                         &streamCB->endLSN,
                         streamCB);
         if (rc == READLOG_ERR_READ_TO_CUR)
         {
            rc = 0;
         }
         else if (rc != 0)
         {
            printf("Error reading the next set of log records!\n");
            goto Finish;
         }
      }
   }

Finish:
   return rc;
}


/****************************************************************************
 * Function Name:
 *    getNextLogRecord
 *
 * Description:
 *    Get the next logical log record to process. The next log record
 *    will be placed in the logRecord member of the READLOG_NC_CB.
 *
 * Input:
 *    readLogCB - pointer to READLOG_NC_CB
 *
 * Normal return:
 *     0
 *
 * Error return:
 *    READLOG_ERR_READ_TO_CUR - if reached end of logs
 *    READLOG_ERR_READ_ERROR - for any other unexpected error
 ***************************************************************************/
int getNextLogRecord(READLOG_NC_CB *readLogCB)
{
   int rc;

   /* Check if it's possible to continue reading from the same stream,
    * if not, place the queue element back in the queue to be resorted.
    * If possible, continue reading from the same stream
    */
   if (!ableToReadFromSameLogStream(readLogCB))
   {
      if (readLogCB->lastReadFromQElem != NULL)
      {
         if (readLogCB->lastReadFromQElem->streamCB->numLogRecordsRemaining > 0)
         {
            /* put the queue element back into the queue */
            enqueueElement(&readLogCB->qHead, readLogCB->lastReadFromQElem);
         }
         else
         {
            /* no more log records to read from the log stream
             * free the queue element and all the structures used
             */
            freeSortedQueueElement(&readLogCB->lastReadFromQElem);
         }
         readLogCB->lastReadFromQElem = NULL;
      }

      /* Get the next queue head */
      readLogCB->lastReadFromQElem = readLogCB->qHead;
      if (readLogCB->lastReadFromQElem == NULL)
      {
         /* Done reading all logs */
         rc = READLOG_ERR_READ_TO_CUR;
         goto Finish;
      }
      else
      {
         /* Remove qHead from the queue */
         readLogCB->qHead = readLogCB->lastReadFromQElem->nextElement;
         readLogCB->lastReadFromQElem->nextElement = NULL;
      }
   }

   memcpy(&readLogCB->prevLastReadLri, &readLogCB->lastReadLri, sizeof(db2LRI));

   rc = getNextLogRecordFromLogStream(readLogCB->lastReadFromQElem->streamCB,
                                      &readLogCB->lastReadLri,
                                      readLogCB->logRecord);
   if (rc != 0)
   {
      printf("Error getting Next Log record from log stream!\n");
      goto Finish;
   }

   /* Sanity check to make sure the LRIs are increasing */
   if (compLRItype1(&readLogCB->prevLastReadLri,
                    &readLogCB->lastReadLri) >= 0)
   {
      printf("LRIs are not increasing !!!\n");
      rc = READLOG_ERR_READ_ERROR;
   }

Finish:
   return rc;
}


/****************************************************************************
 * Function Name:
 *    DisplayLogRecord
 *
 * Description:
 *    Print some basic information given the log record in the READLOG_NC_CB
 *
 * Input:
 *    readLogCB - pointer to READLOG_NC_CB
 *    logRecordNumber - log record number
 *
 ***************************************************************************/
void DisplayLogRecord(READLOG_NC_CB *readLogCB,
                      int            logRecordNumber)
{
   int                       rc = 0;
   db2Uint32                 logRecordHeaderSize = 0;
   db2LSN                   *logRecordLSN = (db2LSN *)readLogCB->logRecord;
   BASE_LOG_RECORD_HEADER   *logRecordHdr =
            (BASE_LOG_RECORD_HEADER *)(readLogCB->logRecord + sizeof(db2LSN));

   printf("Log Record Number: %d\n", logRecordNumber);

   printf("   Member number: %d\n"
          "   Record LSN: %d\n"
          "   Record LRI: (%d, %d, %d)\n"
          "   Record length: %d\n"
          "   Record type: %d\n"
          "   Record flags: %X\n",
          readLogCB->lastReadFromQElem->streamCB->logStreamNumber,
          logRecordLSN->lsnU64,
          readLogCB->lastReadLri.lriType,
          readLogCB->lastReadLri.part1,
          readLogCB->lastReadLri.part2,
          logRecordHdr->logRecordLength,
          logRecordHdr->logRecordType,
          logRecordHdr->logRecordFlags);
   return;
}


int main(int argc,  char *argv[])
{
   int                 rc                        = 0;
   READLOG_NC_CB       readLogCB                 = {0};
   char                dbAlias[SQL_ALIAS_SZ + 1] = { 0 };
   char                logRecordBuffer[458752];
   int                 i                         = 0;
   int                 numLogRecords             = 0;
   char              **logPaths                  = NULL;
   struct db2ReadLogNoConnTermStruct readLogTerm = { 0 };

   logPaths = (char **)malloc(argc - 2);
   readLogCB.logRecord = logRecordBuffer;

   /* Copy the db name and log paths passed in */
   strcpy(dbAlias, argv[1]);
   for (i = 2; i < argc; i++)
   {
      logPaths[i-2] = (char *)malloc(SQL_PATH_SZ + 1);
      strcpy((char *)logPaths[i-2], argv[i]);
   }

   rc = initializeAndReadAllStreams(dbAlias,
                                    logPaths,
                                    argc - 2,
                                    &readLogCB.qHead);
   if (rc != 0)
   {
      goto Finish;
   }

   /* keep looping until there are no more logs to process */
   while (1)
   {
      rc = getNextLogRecord(&readLogCB);
      if (rc == READLOG_ERR_READ_TO_CUR)
      {
         break;
      }
      else if (rc != 0)
      {
         printf("Problem getting next log record\n");
         goto Finish;
      }

      /* process a log record */
      DisplayLogRecord(&readLogCB, ++numLogRecords);
   }

   printf("Done processing all log records! :-D\n");

Finish:
   for (i = 0; i < argc - 2; i++)
   {
      free(logPaths[i]);
   }
   free(logPaths);
   return rc;
}
