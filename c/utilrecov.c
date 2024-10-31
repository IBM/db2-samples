/****************************************************************************
** (c) Copyright IBM Corp. 2007 All rights reserved.
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
** SOURCE FILE NAME: utilrecov.c
**
** SAMPLE: Utilities for the backup, restore and log file samples
**
**         This set of utilities gets the server working path, prunes
**         recovery history file, creates a database, backup a database,
**         saves and restores log retain values.
**
** DB2 APIs USED:
**         db2CfgGet -- Get Configuration
**         db2CfgSet -- Set Configuration
**         db2Prune -- Prune Recovery History File
**         db2Backup -- Backup Database
**         sqledrpd -- Drop and uncatalog a database
**         sqlecrea -- creates a database
**
** STRUCTURES USED:
**         sqlca
**         sqledbdesc
**         db2PruneStruct
**         db2HistoryData
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
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
#include <sqludf.h>
#include "utilapi.h"

#define CHECKRC(x,y)                                   \
    if ((x) != 0)                                      \
    {                                                  \
       printf("Non-zero rc from function %s.\n", (y)); \
       return (x);                                     \
    }

#define MIN(x,y)                                       \
    ((x)<(y)?(x):(y))

#define ADD_BYTES 2

#define TID_LENGTH 6

/* This is the transaction identifier. */
union SQLU_TID
{
   unsigned char tid[TID_LENGTH];
   sqluint16     tidword[3];
};

/* The LogRecordHeader struct below is explained in the "Log record header"
   section of the Db2 Knowledge Center.

   Certain types of log records will contain more data within their headers.
   This struct represents the basic 40 bytes of data that all log record
   headers contain. */
typedef struct LogRecordHeader
{
   sqluint32 recordSize;
   sqluint16 recordType;
   sqluint16 recordFlag;
   sqluint64 recordLSN; /* db2LSN */
   sqluint64 recordLFS;
   sqluint64 backPointerLSO; /* LSO of previous log record in this transaction */
   union SQLU_TID recordTID;
   sqluint16 logstreamID;
} LogRecordHeader;

/* support function called by DbLogRecordsForCurrentConnectionRead() */
int LogBufferDisplay( char *, sqluint32, int );
int LogRecordDisplay( char *, LogRecordHeader * );
int SimpleLogRecordDisplay( LogRecordHeader *, char *, sqluint32 );
int ComplexLogRecordDisplay( sqluint16, sqluint16, char *, sqluint32,
                            sqluint8, char *, sqluint32 );
int LogSubRecordDisplay( char *, sqluint16 );
int UserDataDisplay( char *, sqluint16 );
int ServerWorkingPathGet( char *, char * );
int DbLogRetainValueSave( char *, sqluint16 * );
int DbLogRetainValueRestore( char *, sqluint16 * );

/* The Record ID is 6 bytes in size. */
typedef struct RID
{
    char ridParts[6];
} RID;

int RidToString( RID* rid, char* buf )
{
    char *ptrBuf = rid->ridParts;
    int size = sprintf( buf, "x%2.2X%2.2X%2.2X%2.2X%2.2X%2.2X",
                        *ptrBuf, *(ptrBuf+1), *(ptrBuf+2),
                        *(ptrBuf+3), *(ptrBuf+4), *(ptrBuf+5) );
    return size;
}

/***************************************************************************/
/* ServerWorkingPathGet                                                    */
/* Get the server working directory path where the backup images are kept  */
/***************************************************************************/
int ServerWorkingPathGet(char dbAlias[], char serverWorkingPath[])
{
  struct sqlca sqlca = { 0 };
  char         serverLogPath[SQL_PATH_SZ + 1] = { 0 };
  char         dbAlias_upper[SQL_ALIAS_SZ + 1] = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };
  int          len = 0;
  int          ctr = 0;

  /* initialize cfgParameters */
  /* SQLF_DBTN_LOGPATH is a token of the non-updatable database configuration
     parameter 'logpath'; it is used to get the server log path */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGPATH;
  cfgParameters[0].ptrvalue =
    (char *)malloc( (SQL_PATH_SZ + 1) * sizeof(char) );

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = dbAlias;

  printf("\nUSE THE DB2 API:\n");
  printf("  db2CfgGet -- Get Configuration\n");
  printf("TO GET THE DATABASE CONFIGURATION AND DETERMINE\n");
  printf("THE SERVER WORKING PATH.\n");

  /* get database configuration */
  /* the API db2CfgGet returns the values of individual entries in a
     database configuration file */
  db2CfgGet( db2Version1010,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("server log path -- get");

  strncpy( serverLogPath, cfgParameters[0].ptrvalue, SQL_PATH_SZ );
  
  free( cfgParameters[0].ptrvalue );
  cfgParameters[0].ptrvalue = NULL;

  /* choose the server working path; if, for example, serverLogPath =
     "C:\DB2\NODE0001\....", we'll keep "C:\DB2" for the serverWorkingPath
     variable; backup images created in this sample will be placed under
     the 'serverWorkingPath' directory */

  for (ctr = 0; ctr < strlen (dbAlias); ctr++)
  {
    dbAlias_upper[ctr] = toupper (dbAlias[ctr]);
  }
  dbAlias_upper[ctr] = '\0';  /* terminate the constructed string */

  len = (int)(strstr(serverLogPath, "NODE") - serverLogPath - 1);
  memcpy( serverWorkingPath, serverLogPath, len );
  serverWorkingPath[len] = '\0';

  return 0;
} /* ServerWorkingPathGet */

/***************************************************************************/
/* DbLogRetainValueSave                                                    */
/* Save LOGARCHMETH1 value for the database                                   */
/***************************************************************************/
int DbLogRetainValueSave(char dbAlias[], sqluint16 * pLogRetainValue)
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgGet -- GET CONFIGURATION\n");
  printf("TO GET THE CONFIGURATION OF A DATABASE.\n");

  /* save logarchmeth1 value */
  printf("\n******* Save LOGARCHMETH1 for '%s' database. *******\n", dbAlias);

  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGARCHMETH1;
  cfgParameters[0].ptrvalue = (char *)pLogRetainValue;

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = dbAlias;

  /* get database configuration */
  db2CfgGet( db2Version1010,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("log retain value -- save");

  return 0;
} /* DbLogRetainValueSave */

/***************************************************************************/
/* DbLogRetainValueRestore                                                 */
/* Restore the LOGARCHMETH1 value for the database                            */
/***************************************************************************/
int DbLogRetainValueRestore(char dbAlias[], sqluint16 * pLogRetainValue)
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  /* restore the log retain value */
  printf("\n***** Restore LOGARCHMETH1 for '%s' database ******\n", dbAlias);
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGARCHMETH1;
  cfgParameters[0].ptrvalue = (char *)pLogRetainValue;

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  /* set database configuration */
  db2CfgSet( db2Version1010,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("log retain value -- restore");

  return 0;
} /* DbLogRetainValueRestore */

/***************************************************************************/
/* DbRecoveryHistoryFilePrune                                              */
/* Prunes the recovery history file by calling db2Prune API                */
/***************************************************************************/
int DbRecoveryHistoryFilePrune(char dbAlias[], char user[], char pswd[])
{
  int                   rc = 0;
  struct sqlca          sqlca = { 0 };
  struct db2PruneStruct histPruneParam = { 0 };
  char                  timeStampPart[SQLU_TIME_STAMP_LEN + 1] = { 0 };

  printf("\n***************************************\n");
  printf("*** PRUNE THE RECOVERY HISTORY FILE ***\n");
  printf("***************************************\n");
  printf("\nUSE THE DB2 API:\n");
  printf("  db2Prune -- Prune Recovery History File\n");
  printf("AND THE SQL STATEMENTS:\n");
  printf("  CONNECT\n");
  printf("  CONNECT RESET\n");
  printf("TO PRUNE THE RECOVERY HISTORY FILE.\n");

  /* Connect to the database: */
  rc = DbConn(dbAlias, user, pswd);
  CHECKRC(rc, "DbConn");

  /* Prune the recovery history file: */
  printf("\n  Prune the recovery history file for '%s' database.\n",
         dbAlias);

  /* timeStampPart is a pointer to a string specifying a time stamp or
     log sequence number. Time stamp is used here to select records for
     deletion. All entries equal to or less than the time stamp will be
     deleted. */
  histPruneParam.piString = timeStampPart;
  strcpy(timeStampPart, "2010");        /* year 2010 */

  /* The action DB2PRUNE_ACTION_HISTORY removes history file entries: */
  histPruneParam.iAction = DB2PRUNE_ACTION_HISTORY;

  /* The option DB2PRUNE_OPTION_FORCE forces the removal of the last backup: */
  histPruneParam.iOptions = DB2PRUNE_OPTION_FORCE;

  /* db2Prune can be called to delete entries from the recovery history file
     or log files from the active log path. Here we call it to delete
     entries from the recovery history file.
     You must have SYSADM, SYSCTRL, SYSMAINT, or DBADM authority to prune
     the recovery history file. */
  db2Prune(db2Version1010, &histPruneParam, &sqlca);
  DB2_API_CHECK("recovery history file -- prune");

  /* Disconnect from the database: */
  rc = DbDisconn(dbAlias);
  CHECKRC(rc, "DbDisconn");

  return 0;
} /* DbRecoveryHistoryFilePrune */

/***************************************************************************/
/* DbBackup                                                                */
/* Performs the database backup                                            */
/***************************************************************************/
int DbBackup(char            dbAlias[],
             char            user[],
             char            pswd[],
             char            serverWorkingPath[],
             db2BackupStruct *backupStruct )
{
  struct sqlca sqlca = { 0 };
  db2TablespaceStruct tablespaceStruct = { 0 };
  db2MediaListStruct mediaListStruct = { 0 };

  /*******************************/
  /*    BACK UP THE DATABASE    */
  /*******************************/
  printf("\n  Backing up the '%s' database...\n", dbAlias);

  tablespaceStruct.tablespaces = NULL;
  tablespaceStruct.numTablespaces = 0;

  mediaListStruct.locations = &serverWorkingPath;
  mediaListStruct.numLocations = 1;
  mediaListStruct.locationType = SQLU_LOCAL_MEDIA;

  backupStruct->piDBAlias = dbAlias;
  backupStruct->piTablespaceList = &tablespaceStruct;
  backupStruct->piMediaList = &mediaListStruct;
  backupStruct->piUsername = user;
  backupStruct->piPassword = pswd;
  backupStruct->piVendorOptions = NULL;
  backupStruct->iVendorOptionsSize = 0;
  backupStruct->iCallerAction = DB2BACKUP_BACKUP;
  backupStruct->iBufferSize = 16;        /*  16 x 4KB */
  backupStruct->iNumBuffers = 2;
  backupStruct->iParallelism = 1;
  backupStruct->iOptions = DB2BACKUP_OFFLINE | DB2BACKUP_DB;

  /* The API db2Backup creates a backup copy of a database.
     This API automatically establishes a connection to the specified
     database. (This API can also be used to create a backup copy of a
     table space). */
  db2Backup(db2Version1010, backupStruct, &sqlca);
  DB2_API_CHECK("Database -- Backup");

  while (sqlca.sqlcode != 0)
  {
    /* continue the backup operation */

    /* depending on the sqlca.sqlcode value, user action may be */
    /* required, such as mounting a new tape */

    printf("\n  Continuing the backup operation...\n");

    backupStruct->iCallerAction = DB2BACKUP_CONTINUE;

    db2Backup(db2Version1010, backupStruct, &sqlca);

    DB2_API_CHECK("Database -- Backup");
  }

  printf("  Backup finished.\n");
  printf("    - backup image size      : %d MB\n", backupStruct->oBackupSize);
  printf("    - backup image path      : %s\n",
         mediaListStruct.locations[0]);

  printf("    - backup image time stamp: %s\n", backupStruct->oTimestamp);
  return 0;
} /* DbBackup */

/***************************************************************************/
/* LogBufferDisplay                                                        */
/* Displays the log buffer                                                 */
/***************************************************************************/
int LogBufferDisplay( char *logBuffer,
                      sqluint32 numLogRecords, int conn )
{
  int       rc = 0;
  sqluint32 logRecordNb = 0;
  char *recordBuffer = NULL;
  int headerSize = 0;

  if (logBuffer == NULL)
  {
    if (numLogRecords == 0)
    {
      /* there's nothing to do */
      return 0;
    }
    else
    {
      /* we can't display NULL log records */
      return 1;
    }
  }

  /* If there is no connection to the database or if the iFilterOption
     is OFF, the 8-byte LRI 'db2LRI' is prefixed to the log records.
     If there is a connection to the database and the iFilterOption is
     ON, the db2ReadLogFilterData structure will be prefixed to all
     log records returned by the db2ReadLog API ( for compressed and
     uncompressed data ) */

  if (conn == 0)
  {
    headerSize = sizeof(db2Uint64);
  }
  else
  {
    headerSize = sizeof(db2ReadLogFilterData);
  }
  recordBuffer = logBuffer;

  for (logRecordNb = 0; logRecordNb < numLogRecords; logRecordNb++)
  {
    if (conn == 1)
    {
      db2ReadLogFilterData  *filterData = (db2ReadLogFilterData *)recordBuffer;
      printf("\nRLOG_FILTERDATA:\n");
      printf("    recordLRIPart1: %llu\n", filterData->recordLRIType1.part1);
      printf("    recordLRIPart2: %016llX\n", filterData->recordLRIType1.part2);
      printf("    realLogRecLen: %lu\n", filterData->realLogRecLen );
      printf("    sqlcode: %d\n", filterData->sqlcode );
    }

    recordBuffer += headerSize;

    /* Populate a LogRecordHeader struct with the log record header data. */
    LogRecordHeader *lrh = (LogRecordHeader *)recordBuffer;

    printf("\n    LOG_RECORD_HEADER:\n");
    printf("    recordSize: %lu\n", lrh->recordSize );
    printf("    recordType: %04llX\n", lrh->recordType );
    printf("    recordFlag: %04llX\n", lrh->recordFlag );
    printf("    recordLSN: %u\n", lrh->recordLSN );
    printf("    recordLFS: %u\n", lrh->recordLFS );
    printf("    backPointerLSO: %u\n", lrh->backPointerLSO );

    printf("    recordTID: " );
    int i;
    for (i = 0; i < TID_LENGTH; i++)
    {
       printf("%X", lrh->recordTID.tid[i] );
    }
    printf("\n");

    printf("    logstreamID: %u\n", lrh->logstreamID );

    rc = LogRecordDisplay(recordBuffer,
                          lrh);

    CHECKRC(rc, "LogRecordDisplay");

    recordBuffer += lrh->recordSize;
  }

  return 0;
} /* LogBufferDisplay */

/***************************************************************************/
/* LogRecordDisplay                                                        */
/* Displays the log records                                                */
/***************************************************************************/
int LogRecordDisplay( char            *recordBuffer,
                      LogRecordHeader *lrh )
{
  int       rc = 0;
  sqluint32 logManagerLogRecordHeaderSize = 0;
  char      *recordDataBuffer = NULL;
  sqluint32 recordDataSize = 0;
  char      *recordHeaderBuffer = NULL;
  sqluint8  componentIdentifier = 0;
  sqluint32 recordHeaderSize = 0;

  /* Determine the log manager log record header size. */

  logManagerLogRecordHeaderSize = 40;

  if (lrh->recordType == 0x0043)
  {            /* compensation */
    logManagerLogRecordHeaderSize += sizeof(db2Uint64) * 2;

    if (lrh->recordFlag & 0x0002)
    {          /* propagatable */
      logManagerLogRecordHeaderSize += sizeof(db2Uint64);
    }
  }

  switch (lrh->recordType)
  {
    case 0x008A: /* Local Pending List */
    case 0x0084: /* Normal Commit */
    case 0x0041: /* Normal Abort */
      recordDataBuffer = recordBuffer + logManagerLogRecordHeaderSize;
      recordDataSize = lrh->recordSize - logManagerLogRecordHeaderSize;
      rc = SimpleLogRecordDisplay( lrh,
                                   recordDataBuffer,
                                   recordDataSize );
      CHECKRC(rc, "SimpleLogRecordDisplay");
      break;
    case 0x004E: /* Normal */
    case 0x0043: /* Compensation */
      recordHeaderBuffer = recordBuffer + logManagerLogRecordHeaderSize;
      componentIdentifier = *(sqluint8 *) recordHeaderBuffer;
      switch (componentIdentifier)
      {
          case 1: /* Data Manager Log Record */
              recordHeaderSize = 6;
              break;
         default:
             printf( "    Unknown complex log record: %lu %c %u\n",
                     lrh->recordSize, lrh->recordType, componentIdentifier );
             return 1;
      }
      recordDataBuffer = recordBuffer +
                         logManagerLogRecordHeaderSize +
                         recordHeaderSize;
      recordDataSize = lrh->recordSize -
                       logManagerLogRecordHeaderSize -
                       recordHeaderSize;
      rc = ComplexLogRecordDisplay( lrh->recordType,
                                    lrh->recordFlag,
                                    recordHeaderBuffer,
                                    recordHeaderSize,
                                    componentIdentifier,
                                    recordDataBuffer,
                                    recordDataSize );
      CHECKRC(rc, "ComplexLogRecordDisplay");
      break;
    default:
      printf( "    Unknown log record: %lu \"%c\"\n",
              lrh->recordSize, (char)(lrh->recordType) );
      break;
  }

  return 0;
} /* LogRecordDisplay */

/***************************************************************************/
/* SimpleLogRecordDisplay                                                  */
/* Prints the minimum details of the log record                            */
/***************************************************************************/
int SimpleLogRecordDisplay( LogRecordHeader *lrh,
                            char            *recordDataBuffer,
                            sqluint32       recordDataSize)
{
  int       rc = 0;
  sqluint32 timeTransactionCommited = 0;
  sqluint16 authIdLen = 0;
  char      *authId = NULL;

  switch (lrh->recordType)
  {
    case 138:
      printf("\n    Record type: Local pending list\n");
      timeTransactionCommited = *(sqluint32 *) (recordDataBuffer);
      authIdLen = *(sqluint16 *) (recordDataBuffer + 2*sizeof(sqluint32));
      authId = (char *)malloc(authIdLen + 1);
      memset( authId, '\0', (authIdLen + 1 ));
      memcpy( authId, (char *)(recordDataBuffer + 2*sizeof(sqluint32) +
              sizeof(sqluint16)), authIdLen);
      authId[authIdLen] = '\0';
      printf( "      %s: %lu\n",
              "UTC transaction committed (in seconds since 70-01-01)",
              timeTransactionCommited);
      printf("      authorization ID of the application: %s\n", authId);
      free(authId);
      authId = NULL;
      authIdLen = 0;
      break;
    case 132:
      printf("\n    Record type: Normal commit\n");
      timeTransactionCommited = *(sqluint32 *) (recordDataBuffer);
      authIdLen = *(sqluint16 *) (recordDataBuffer + 2*sizeof(sqluint32));
      authId = (char *)malloc(authIdLen + 1);
      memset( authId, '\0', (authIdLen + 1 ));
      memcpy(authId, (char *)(recordDataBuffer + 2*sizeof(sqluint32) +
                              sizeof(sqluint16)), authIdLen);
      authId[authIdLen] = '\0';
      printf( "      %s: %lu\n",
              "UTC transaction committed (in seconds since 70-01-01)",
              timeTransactionCommited);
      printf("      authorization ID of the application: %s\n", authId);
      free(authId);
      authId = NULL;
      authIdLen = 0;
      break;
    case 65:
      printf("\n    Record type: Normal abort\n");
      authIdLen = *(sqluint16 *) (recordDataBuffer);
      authId = (char *)malloc(authIdLen + 1);
      memset( authId, '\0', (authIdLen + 1 ));
      memcpy(authId, (char *)(recordDataBuffer + sizeof(sqluint16)), authIdLen);
      authId[authIdLen] = '\0';
      printf("      authorization ID of the application: %s\n", authId);
      free(authId);
      authId = NULL;
      authIdLen = 0;
      break;
    default:
      printf( "    Unknown simple log record: %d %lu\n",
              lrh->recordType, recordDataSize);
      break;
  }

  return 0;
} /* SimpleLogRecordDisplay */

/***************************************************************************/
/* ComplexLogRecordDisplay                                                 */
/* Prints a detailed information of the log record                         */
/***************************************************************************/
int ComplexLogRecordDisplay( sqluint16 recordType,
                             sqluint16 recordFlag,
                             char      *recordHeaderBuffer,
                             sqluint32 recordHeaderSize,
                             sqluint8  componentIdentifier,
                             char      *recordDataBuffer,
                             sqluint32 recordDataSize)
{
  int      rc = 0;
  sqluint8 functionIdentifier = 0;
  /* for insert, delete, undo delete */

  struct RID recid = { 0 };
  sqluint16 subRecordLen = 0;
  sqluint16 subRecordOffset = 0;
  char *subRecordBuffer = NULL;

  /* for update */
  struct RID newRecid = { 0 };
  sqluint16 newSubRecordLen = 0;
  sqluint16 newSubRecordOffset = 0;
  char      *newSubRecordBuffer = NULL;
  struct RID oldRecid = { 0 };
  sqluint16 oldSubRecordLen = 0;
  sqluint16 oldSubRecordOffset = 0;
  char      *oldSubRecordBuffer = NULL;

  /* for alter table attributes */
  sqluint64 alterBitMask = 0;
  sqluint64 alterBitValues = 0;

  char ridString[14];

  switch( recordType )
  {
    case 0x004E:
      printf("\n    Record type: Normal\n");
      break;
    case 0x0043:
      printf("\n    Record type: Compensation\n");
      break;
    default:
      printf("\n    Unknown complex log record type: %c\n", recordType);
      break;
  }

  switch (componentIdentifier)
  {
    case 1:
      printf("      component ID: DMS log record\n");
      break;
    default:
      printf("      unknown component ID: %d\n", componentIdentifier);
      break;
  }
  functionIdentifier = *(sqluint8 *) (recordHeaderBuffer + 1);
  switch (functionIdentifier)
  {
    case 161:
      printf("      function ID: Delete Record\n");
      subRecordLen = *((sqluint16*)(recordDataBuffer + sizeof(sqluint16)));
      recid = *( (struct RID*)( recordDataBuffer +
                                3 * sizeof(sqluint16) ) );
      subRecordOffset = *( (sqluint16 *) ( recordDataBuffer +
                                         3 * sizeof(sqluint16) +
                                         sizeof(struct RID) ) );
      printf("        RID: " );
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 112:                                                   
      printf("      function ID: Undo Update Record\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16) );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16));
      subRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                         3 * sizeof(sqluint16) +
                                         sizeof(struct RID) );
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 110:
      printf("      function ID: Undo Insert Record\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16) );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16));
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      break;                                                   
    case 111:
      printf("      function ID: Undo Delete Record\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16) );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16));
      subRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                         3 * sizeof(sqluint16) +
                                         sizeof(struct RID) );
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 162:
      printf("      function ID: Insert Record\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16)  );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                         3 * sizeof(sqluint16) +
                                         sizeof(struct RID) );
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 163:
      printf("      function ID: Update Record\n");
      oldSubRecordLen = *(sqluint16 *) ( recordDataBuffer +
                                         7 * sizeof(sqluint16) +
                                         sizeof(sqluint16) );
      newSubRecordLen = *(sqluint16 *) ( recordDataBuffer +
                                         3 * sizeof(sqluint16) +
                                         sizeof(struct RID) +
                                         sizeof(sqluint16) +
                                         oldSubRecordLen +
                                         recordHeaderSize +
                                         3 * sizeof(sqluint16) +
                                         sizeof(struct RID) +
                                         2 * sizeof(sqluint16));
      
      oldRecid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16));
      oldSubRecordOffset = *(sqluint16 *) ( recordDataBuffer  +
                                            3 * sizeof(sqluint16) +
                                            sizeof(struct RID) );
      newSubRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                           3 * sizeof(sqluint16) +
                                           sizeof(struct RID) +
                                           sizeof(sqluint16) +
                                           oldSubRecordLen +
                                           recordHeaderSize +
                                           3 * sizeof(sqluint16) +
                                           sizeof(struct RID) +
                                           sizeof(sqluint16) );
      printf("        oldRID:");
      RidToString( &oldRecid, ridString );
      printf("%s\n", ridString );
      printf("        old subrecord length: %u\n", oldSubRecordLen);
      printf("        old subrecord offset: %u\n", oldSubRecordOffset);
      oldSubRecordBuffer = recordDataBuffer +
                           3 * sizeof(sqluint16) +
                           sizeof(struct RID) +
                           sizeof(sqluint16);
      rc = LogSubRecordDisplay(oldSubRecordBuffer, oldSubRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      printf("        newRID: " );
      RidToString( &newRecid, ridString );
      printf("%s\n", ridString );
      printf("        new subrecord length: %u\n", newSubRecordLen);
      printf("        new subrecord offset: %u\n", newSubRecordOffset);
      newSubRecordBuffer = recordDataBuffer +
                           3 * sizeof(sqluint16) +
                           sizeof(struct RID) +
                           sizeof(sqluint16) +
                           oldSubRecordLen +
                           recordHeaderSize +
                           3 * sizeof(sqluint16) +
                           sizeof(struct RID) +
                           sizeof(sqluint16);
      rc = LogSubRecordDisplay(newSubRecordBuffer, newSubRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;

    case 165:
      printf("      function ID: Insert Record to Empty Page\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16)  );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                         6 * sizeof(sqluint16) +
                                         sizeof(struct RID) );
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 6 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;

    case 164:
      printf("      function ID: Delete Record to Empty Page\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16)  );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                         6 * sizeof(sqluint16) +
                                         sizeof(struct RID) );
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 6 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;

    case 166:
      printf("      function ID: Rollback delete Record to Empty Page\n");
      subRecordLen = *(sqluint16 *) ( recordDataBuffer + sizeof(sqluint16)  );
      recid = *(struct RID *) (recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *(sqluint16 *) ( recordDataBuffer +
                                         6 * sizeof(sqluint16) +
                                         sizeof(struct RID) );
      printf("        RID: ");
      RidToString( &recid, ridString );
      printf("%s\n", ridString );
      printf("        subrecord length: %u\n", subRecordLen);
      printf("        subrecord offset: %u\n", subRecordOffset);
      subRecordBuffer = recordDataBuffer + 6 * sizeof(sqluint16) +
                        sizeof(struct RID) + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;

    case 124:
      printf("      function ID:  Alter Table Attribute\n");
      alterBitMask = *(sqluint64 *) (recordDataBuffer);
      alterBitValues = *(sqluint64 *) (recordDataBuffer + sizeof(sqluint64));
      if (alterBitMask & 0x00000001)
      {
          /* Alter the value of the 'propagation' attribute: */
          printf("        Propagation attribute is changed to: ");
          if (alterBitValues & 0x00000001)
          {
              printf("ON\n");
          }
          else
          {
              printf("OFF\n");
          }
      }
      if (alterBitMask & 0x00000002)
      {
          /* Alter the value of the 'pending' attribute: */
          printf("        Pending attribute is changed to: ");
          if (alterBitValues & 0x00000002)
          {
              printf("ON\n");
          }
          else
          {
              printf("OFF\n");
          }
      }
      if (alterBitMask & 0x00010000)
      {
          /* Alter the value of the 'append mode' attribute: */
          printf("        Append Mode attribute is changed to: ");
          if (alterBitValues & 0x00010000)
          {
              printf("ON\n");
          }
          else
          {
              printf("OFF\n");
          }
      }
      if (alterBitMask & 0x00200000)
      {
          /* Alter the value of the 'LF Propagation' attribute: */
          printf("        LF Propagation attribute is changed to: ");
          if (alterBitValues & 0x00200000)
          {
              printf("ON\n");
          }
          else
          {
              printf("OFF\n");
          }
      }
      if (alterBitMask & 0x00400000)
      {
          /* Alter the value of the 'LOB Propagation' attribute: */
          printf("        LOB Propagation attribute is changed to: ");
          if (alterBitValues & 0x00400000)
          {
              printf("ON\n");
          }
          else
          {
              printf("OFF\n");
          }
      }
      break;
    default:
      printf("      unknown function identifier: %u\n", functionIdentifier);
      break;
  }

  return 0;
} /* ComplexLogRecordDisplay */

/***************************************************************************/
/* LogSubRecordDisplay                                                     */
/* Prints the sub records for the log                                      */
/***************************************************************************/
int LogSubRecordDisplay( char      *recordBuffer,
                         sqluint16 recordSize )
{
  int       rc = 0;
  sqluint8  recordType = 0;
  sqluint8  updatableRecordType = 0;
  sqluint16 userDataFixedLength = 0;
  char      *userDataBuffer = NULL;
  sqluint16 userDataSize = 0;

  recordType = *(sqluint8 *) (recordBuffer);
  if ((recordType != 0) && (recordType != 4) && (recordType != 16))
  {
    printf("        Unknown subrecord type: %x\n", recordType);
  }
  else if (recordType == 4)
  {
    printf("        subrecord type: Special control\n");
  }
  else
  {
    /* recordType == 0 or recordType == 16
     * record Type 0 indicates a normal record
     * record Type 16, for the purposes of this program, should be treated
     * as type 0
     */
    printf("        subrecord type: Updatable, ");
    updatableRecordType = *(sqluint8 *) (recordBuffer + sizeof(sqluint32));
    if (updatableRecordType != 1)
    {
      printf("Internal control\n");
    }
    else
    {
      printf("Formatted user data\n");
      userDataFixedLength =
                     *(sqluint16 *) ( recordBuffer + sizeof(sqluint16) +
                                      sizeof(sqluint32));
      printf("        user data fixed length: %u\n", userDataFixedLength);
      userDataBuffer = recordBuffer + 8;
      userDataSize = recordSize - 8;
      rc = UserDataDisplay(userDataBuffer, userDataSize);
      CHECKRC(rc, "UserDataDisplay");
    }
  }

  return 0;
} /* LogSubRecordDisplay */

/***************************************************************************/
/* UserDataDisplay                                                         */
/* Displays the user data section                                          */
/***************************************************************************/
int UserDataDisplay(char *dataBuffer, sqluint16 dataSize)
{
  int       rc = 0;
  sqluint16 line = 0;
  sqluint16 col = 0;
  const int rowLength = 10;

  printf("        user data:\n");

  for (line = 0; line * rowLength < dataSize; line++)
  {
    printf("        ");
    for (col = 0; col < rowLength; col++)
    {
      if (line * rowLength + col < dataSize)
      {
          printf("%02X ", (unsigned char)dataBuffer[line * rowLength + col]);
      }
      else
      {
          printf("   ");
      }
    }
    printf("*");
    for (col = 0; col < rowLength; col++)
    {
      if (line * rowLength + col < dataSize)
      {
          if( isalpha(dataBuffer[line * rowLength + col]) ||
              isdigit(dataBuffer[line * rowLength + col]))
          {
              printf("%c", dataBuffer[line * rowLength + col]);
          }
          else
          {
              printf(".");
          }
      }
      else
      {
          printf(" ");
      }
    }
    printf("*");
    printf("\n");
  }

  return 0;
} /* UserDataDisplay */

/***************************************************************************/
/* DbCreate                                                                */
/* Create the specified database                                           */
/***************************************************************************/
int DbCreate(char existingDbAlias[], char newDbAlias[])
{
  struct sqlca        sqlca = { 0 };
  char                dbName[SQL_DBNAME_SZ + 1] = { 0 };
  char                dbLocalAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char                dbPath[SQL_PATH_SZ + 1] = { 0 };
  struct sqledbdesc   dbDescriptor = { 0 };
  SQLEDBTERRITORYINFO territoryInfo = { 0 };
  db2CfgParam         cfgParameters[2] = { 0 };
  db2Cfg              cfgStruct = { 0 };

  printf
    ("\n  Create '%s' empty database with the same code set as '%s' database.\n",
     newDbAlias, existingDbAlias);

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_TERRITORY;
  cfgParameters[0].ptrvalue = (char *)malloc((SQL_LOCALE_LEN + 1) *
                                             sizeof(char));
  memset(cfgParameters[0].ptrvalue, '\0', SQL_LOCALE_LEN + 1);
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_DBTN_CODESET;
  cfgParameters[1].ptrvalue = (char *)malloc((SQL_CODESET_LEN + 1) *
                                             sizeof(char));
  memset(cfgParameters[1].ptrvalue, '\0', SQL_CODESET_LEN + 1);

  /* initialize cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = existingDbAlias;

  /* get database configuration */
  db2CfgGet( db2Version1010,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("server log path -- get");

  /* create a new database */
  strcpy(dbName, newDbAlias);
  strcpy(dbLocalAlias, newDbAlias);
  strcpy(dbPath, "");

  strcpy(dbDescriptor.sqldbdid, SQLE_DBDESC_2);
  dbDescriptor.sqldbccp = 0;
  dbDescriptor.sqldbcss = SQL_CS_NONE;

  strcpy(dbDescriptor.sqldbcmt, "");
  dbDescriptor.sqldbsgp = 0;
  dbDescriptor.sqldbnsg = 10;
  dbDescriptor.sqltsext = -1;
  dbDescriptor.sqlcatts = NULL;
  dbDescriptor.sqlusrts = NULL;
  dbDescriptor.sqltmpts = NULL;

  strcpy(territoryInfo.sqldbcodeset, (char *)cfgParameters[0].ptrvalue);
  strcpy(territoryInfo.sqldblocale, (char *)cfgParameters[1].ptrvalue);

  /* create database */
  sqlecrea( dbName,
            dbLocalAlias,
            dbPath,
            &dbDescriptor,
            &territoryInfo,
            '\0',
            NULL,
            &sqlca );
  DB2_API_CHECK("Database -- Create");

  /* free the allocated memory */
  free(cfgParameters[0].ptrvalue);
  free(cfgParameters[1].ptrvalue);
  cfgParameters[0].ptrvalue = NULL;
  cfgParameters[1].ptrvalue = NULL;

  return 0;
} /* DbCreate */

/***************************************************************************/
/* DbDrop                                                                  */
/* Drops and uncatalogs the specified database alias                       */
/***************************************************************************/
int DbDrop(char dbAlias[])
{
  struct sqlca sqlca = { 0 };

  printf("\n  Drop the '%s' database.\n", dbAlias);

  /* drop and uncatalog the database */
  sqledrpd(dbAlias, &sqlca);
  DB2_API_CHECK("Database -- Drop");

  return 0;
} /* DbDrop */
