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
** SOURCE FILE NAME: utilsnap.c
**
** SAMPLE: Utilities for the snapshot monitor samples
**
**         This set of utilities sets the monitor switches, sets the 
**         configuration parameter for instance level throttling, parses
**         the self-describing data stream, and prints logical data groups
**         and their data elements to stdout. Snapshot monitor samples
**         that use these utilities include clisnap, insnap, and dbsnap.
**
** DB2 APIs USED:
**         db2CfgSet -- Set Configuration
**         db2GetSnapshotSize -- Get buffer size for db2GetSnapshot
**         db2GetSnapshot -- GET SNAPSHOT
**         db2MonitorSwitches -- GET/UPDATE MONITOR SWITCHES
**
** STRUCTURES USED:
**         db2Cfg
**         db2CfgParam
**         sqlca
**         sqlma
**         sqlm_collected
**         sqlm_header_info
**         sqlm_recording_group
**
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
#include <string.h>
#include <sqlutil.h>
#include <sqlenv.h>
#include <sqlmon.h>
#include <db2ApiDf.h>
#include "utilapi.h"

#define sqlmCheckRC(rc) \
{\
  if ( rc ) \
  { \
     printf( "Addsnapshot returned error=%d sqlcode =%d\n", rc, sqlca.sqlcode );\
  } \
  if (sqlca.sqlcode != 0L) \
  { \
    SqlInfoPrint("db2AddSnapshotRequest", &sqlca, __LINE__, __FILE__); \
    if (sqlca.sqlcode < 0L) \
    { \
      printf("\n%s",DASHES); \
      printf("\ndb2GetSnapshotSize SQLCODE is %d. Exiting.", sqlca.sqlcode); \
      printf("\n%s\n",DASHES); \
      return((int)sqlca.sqlcode); \
    } \
  } \
}

#define SNAPSHOT_BUFFER_UNIT_SZ 1024
#define NUMELEMENTS 983
#define BLANKS "                                                                             "
#define DASHES "----------------------------------------------------------------------"

int FreeMemory(struct sqlma *ma_ptr, char *buffer_ptr);
int GetSnapshot(struct sqlma *ma_ptr);
int InitElementNames(void);
sqlm_header_info *ParseMonitorStream(char *prefix, char *pStart, char *pEnd);
int TurnOnAllMonitorSwitches(void);

/* an array for the defined names of all monitor elements (from sqlmon.h) */
char *elementName[NUMELEMENTS];

/***************************************************************************/
/* FreeMemory                                                              */
/* General cleanup routine to release memory buffers.                      */
/***************************************************************************/
int FreeMemory(struct sqlma *ma_ptr, char *buffer_ptr)
{
  int rc = 0;

  printf("\n%s",DASHES);
  printf("\nFreeing allocated memory.");
  printf("\n%s\n",DASHES);

  /* free output buffer */
  if (buffer_ptr != NULL)
     free(buffer_ptr);

  /* free sqlma */
  if (ma_ptr != NULL)
     free(ma_ptr);

  return rc;
}  /* FreeMemory */
/***************************************************************************/
/* GetSnapshotNew                                                          */
/* This function is called from one of insnapNew, clisnapNew, or dbsnapNew */
/* the buffer used to contain the self-describing monitor data is          */
/* initialized (and later freed), the data structures used by the          */
/* db2GetSnapshot API are populated, and the snapshot is captured. The     */
/* snapshot monitor data buffer is then passed to the ParseMonitorStream   */
/* function, which parses and prints the data. Once the ParseMonitorStream */
/* is finished running, the resources used by the snapshot monitor samples */
/* are freed with the FreeMemory function.                                 */
/***************************************************************************/
int GetSnapshotNew(db2AddSnapshotRqstData *snapReq)
{
  int rc = 0;  /* return code */
  struct sqlm_collected collected;  /* returned sqlm_collected structure */
  struct sqlca sqlca;
  char *buffer_ptr = NULL;  /* buffer returned from db2GetSnapshot call */
  sqluint32 buffer_sz;  /* estimated buffer size */
  sqluint32 outputFormat;
  db2GetSnapshotData getSnapshotParam;
  db2GetSnapshotSizeData getSnapshotSizeParam;

  memset(&collected, '\0', sizeof(struct sqlm_collected));

  printf("\n%s",DASHES);
  printf("\nDetermining the size of the snapshot using db2GetSnapshotSize.");
  printf("\n%s\n",DASHES);

  /* call the db2GetSnapshotDataSize API to determine the size of the */
  /* buffer required to store the snapshot monitor data */
  /*    first, set the values of the db2GetSnapshotDataSize structure */
  getSnapshotSizeParam.piSqlmaData    = snapReq->pioRequestData;
  getSnapshotSizeParam.poBufferSize   = &buffer_sz;
  getSnapshotSizeParam.iVersion       = SQLM_CURRENT_VERSION;
  getSnapshotSizeParam.iNodeNumber    = SQLM_CURRENT_NODE;
  getSnapshotSizeParam.iSnapshotClass = SQLM_CLASS_DEFAULT;

  /*    second, call the db2GetSnapshotDataSize API */
  rc = db2GetSnapshotSize(db2Version970, &getSnapshotSizeParam, &sqlca);

  /* exit function if the db2GetSnapshotSize call returns a non-zero value */
  if (rc != 0)
  {
    printf("\n%s",DASHES);
    printf("\nReturn code from db2GetSnapshotSize is %d. Exiting.", rc);
    printf("\n%s\n",DASHES);
    FreeMemory(snapReq->pioRequestData, NULL);
    snapReq->pioRequestData = NULL;
    return(rc);
  }

  /* examine the sqlcode and react accordingly: */
  /*   if 0, then continue */
  /*   if positive, then print sqlca info and continue */
  /*   if negative, then print sqlca info, clear memory and exit function */
  if (sqlca.sqlcode != 0L)
  {
    SqlInfoPrint("db2GetSnapshotSize", &sqlca, __LINE__, __FILE__);
    if (sqlca.sqlcode < 0L)
    {
      printf("\n%s",DASHES);
      printf("\ndb2GetSnapshotSize SQLCODE is %d. Exiting.", sqlca.sqlcode);
      printf("\n%s\n",DASHES);
      FreeMemory(snapReq->pioRequestData, buffer_ptr);
      snapReq->pioRequestData = NULL;
      return((int)sqlca.sqlcode);
    }
  }

  /* exit function if the estimated buffer size is zero */
  if (buffer_sz == 0)
  {
    printf("\n%s",DASHES);
    printf("\nEstimated buffer size is zero. Exiting.");
    printf("\n%s\n",DASHES);
    FreeMemory(snapReq->pioRequestData, buffer_ptr);
    snapReq->pioRequestData = NULL;
    return(99);
  }

  /* allocate memory to a buffer to hold snapshot monitor data. */
  printf("\n%s",DASHES);
  printf("\nAllocating memory for snapshot monitor data.");
  printf("\n%s\n",DASHES);
  buffer_ptr = (char *) malloc(buffer_sz);
  if (buffer_ptr == NULL)
  {
    printf("\n%s",DASHES);
    printf("\nError allocating memory for buffer area. Exiting.");
    printf("\n%s\n",DASHES);
    FreeMemory( snapReq->pioRequestData, buffer_ptr);
    return(99);
  }
  /* clear the buffer */
  memset(buffer_ptr, '\0', buffer_sz);

  /* call the db2GetSnapshot API to capture a snapshot and store the */
  /* monitor data in the buffer pointed to by "buffer_ptr". */
  /*    first, set the values of the db2GetSnapshot structure */
  getSnapshotParam.piSqlmaData = snapReq->pioRequestData;
  getSnapshotParam.poCollectedData = &collected;
  getSnapshotParam.iBufferSize = buffer_sz;
  getSnapshotParam.poBuffer = buffer_ptr;
  getSnapshotParam.iVersion = SQLM_CURRENT_VERSION;
  getSnapshotParam.iStoreResult = 0;
  getSnapshotParam.iNodeNumber = SQLM_CURRENT_NODE;
  getSnapshotParam.poOutputFormat = &outputFormat;
  getSnapshotParam.iSnapshotClass = SQLM_CLASS_DEFAULT;
  /*    second, call the db2GetSnapshot API */
  printf("\n%s",DASHES);
  printf("\nCapturing snapshot using db2GetSnapshot.");
  printf("\n%s\n",DASHES);


  rc = db2GetSnapshot(db2Version970, &getSnapshotParam, &sqlca);

  while (sqlca.sqlcode == 1606)
  {
    /* deallocate memory assigned to the buffer */
    FreeMemory(NULL, buffer_ptr);

    printf("\n%s",DASHES);
    printf("\nBuffer size for snapshot data is too small.");
    printf("\nRe-allocating memory for snapshot monitor data.");
    printf("\n%s\n",DASHES);

   /* enlarge the buffer */
    buffer_sz = buffer_sz + SNAPSHOT_BUFFER_UNIT_SZ;

    /* allocate memory to a buffer to hold snapshot monitor data. */
    printf("\n%s",DASHES);
    printf("\nAllocating memory for snapshot monitor data.");
    printf("\n%s\n",DASHES);
    buffer_ptr = (char *) malloc(buffer_sz);
    if (buffer_ptr == NULL)
    {
      printf("\n%s",DASHES);
      printf("\nError allocating memory for buffer area. Exiting.");
      printf("\n%s\n",DASHES);
      FreeMemory(snapReq->pioRequestData, buffer_ptr);
      snapReq->pioRequestData = NULL;
      return(99);
    }
    /* clear the buffer */
    memset(buffer_ptr, '\0', buffer_sz);

    getSnapshotParam.iBufferSize = buffer_sz;
    getSnapshotParam.poBuffer = buffer_ptr;

    /* get snapshot */
    printf("\n%s",DASHES);
    printf("\nCapturing snapshot using db2GetSnapshot.");
    printf("\n%s\n",DASHES);
    rc = db2GetSnapshot(db2Version970, &getSnapshotParam, &sqlca);
  }
  
  /* exit function if the db2GetSnapshot call returns a non-zero value */
  if (rc != 0)
  {
    printf("\n%s",DASHES);
    printf("\nReturn code from db2GetSnapshot is %d. Exiting.", rc);
    printf("\n%s\n",DASHES);
    FreeMemory(snapReq->pioRequestData, buffer_ptr);
    snapReq->pioRequestData = NULL;
    return rc;
  }

  /* examine the sqlcode and react accordingly: */
  /*   if 0, then continue */
  /*   if positive, then print the sqlca info and continue */
  /*   if negative, then print the sqlca info and exit function */
  if (sqlca.sqlcode != 0L)
  {
    SqlInfoPrint("db2GetSnapshot", &sqlca, __LINE__, __FILE__);
    if (sqlca.sqlcode == 1611)
    {
      printf("For SQLCODE 1611, the system monitor will return the ");
      printf("contents of the\nSQLM_ELM_COLLECTED logical grouping, ");
      printf("including monitoring metadata\nand monitor switch settings.");
    }
    if (sqlca.sqlcode < 0L)
    {
      printf("\n%s",DASHES);
      printf("\ndb2GetSnapshot SQLCODE is %d. Exiting.", sqlca.sqlcode);
      printf("\n%s\n",DASHES);
      FreeMemory(snapReq->pioRequestData, buffer_ptr);
      snapReq->pioRequestData = NULL;
      return((int)sqlca.sqlcode);
    }
  }
  
  /* initialize the array of monitor element names */
  InitElementNames();

  /* parse and print the monitor data */
  printf("\n%s",DASHES);
  printf("\nSnapshot monitor data:\n\n");
  ParseMonitorStream(" ", buffer_ptr, NULL);
  printf("\n%s\n",DASHES);

  /* release memory before exiting */
  FreeMemory(snapReq->pioRequestData, buffer_ptr);
  snapReq->pioRequestData = NULL;
  return rc;
} /* GetSnapshot */

/***************************************************************************/
/* GetSnapshot                                                             */
/* This function is called from one of insnap, clisnap, or dbsnap. Here,   */
/* the buffer used to contain the self-describing monitor data is          */
/* initialized (and later freed), the data structures used by the          */
/* db2GetSnapshot API are populated, and the snapshot is captured. The     */
/* snapshot monitor data buffer is then passed to the ParseMonitorStream   */
/* function, which parses and prints the data. Once the ParseMonitorStream */
/* is finished running, the resources used by the snapshot monitor samples */
/* are freed with the FreeMemory function.                                 */
/***************************************************************************/
int GetSnapshot(struct sqlma *ma_ptr)
{
  int rc = 0;  /* return code */
  struct sqlm_collected collected;  /* returned sqlm_collected structure */
  struct sqlca sqlca;
  char *buffer_ptr = NULL;  /* buffer returned from db2GetSnapshot call */
  sqluint32 buffer_sz;  /* estimated buffer size */
  sqluint32 outputFormat;
  db2GetSnapshotData getSnapshotParam;
  db2GetSnapshotSizeData getSnapshotSizeParam;

  memset(&collected, '\0', sizeof(struct sqlm_collected));

  printf("\n%s",DASHES);
  printf("\nDetermining the size of the snapshot using db2GetSnapshotSize.");
  printf("\n%s\n",DASHES);

  /* call the db2GetSnapshotDataSize API to determine the size of the */
  /* buffer required to store the snapshot monitor data */
  /*    first, set the values of the db2GetSnapshotDataSize structure */
  getSnapshotSizeParam.piSqlmaData = ma_ptr;
  getSnapshotSizeParam.poBufferSize = &buffer_sz;
  getSnapshotSizeParam.iVersion = SQLM_CURRENT_VERSION;
  getSnapshotSizeParam.iNodeNumber = SQLM_CURRENT_NODE;
  getSnapshotSizeParam.iSnapshotClass = SQLM_CLASS_DEFAULT;
  /*    second, call the db2GetSnapshotDataSize API */
  rc = db2GetSnapshotSize(db2Version970, &getSnapshotSizeParam, &sqlca);

  /* exit function if the db2GetSnapshotSize call returns a non-zero value */
  if (rc != 0)
  {
    printf("\n%s",DASHES);
    printf("\nReturn code from db2GetSnapshotSize is %d. Exiting.", rc);
    printf("\n%s\n",DASHES);
    FreeMemory(ma_ptr, buffer_ptr);
    return(rc);
  }

  /* examine the sqlcode and react accordingly: */
  /*   if 0, then continue */
  /*   if positive, then print sqlca info and continue */
  /*   if negative, then print sqlca info, clear memory and exit function */
  if (sqlca.sqlcode != 0L)
  {
    SqlInfoPrint("db2GetSnapshotSize", &sqlca, __LINE__, __FILE__);
    if (sqlca.sqlcode < 0L)
    {
      printf("\n%s",DASHES);
      printf("\ndb2GetSnapshotSize SQLCODE is %d. Exiting.", sqlca.sqlcode);
      printf("\n%s\n",DASHES);
      FreeMemory(ma_ptr, buffer_ptr);
      return((int)sqlca.sqlcode);
    }
  }

  /* exit function if the estimated buffer size is zero */
  if (buffer_sz == 0)
  {
    printf("\n%s",DASHES);
    printf("\nEstimated buffer size is zero. Exiting.");
    printf("\n%s\n",DASHES);
    FreeMemory(ma_ptr, buffer_ptr);
    return(99);
  }

  /* allocate memory to a buffer to hold snapshot monitor data. */
  printf("\n%s",DASHES);
  printf("\nAllocating memory for snapshot monitor data.");
  printf("\n%s\n",DASHES);
  buffer_ptr = (char *) malloc(buffer_sz);
  if (buffer_ptr == NULL)
  {
    printf("\n%s",DASHES);
    printf("\nError allocating memory for buffer area. Exiting.");
    printf("\n%s\n",DASHES);
    FreeMemory(ma_ptr, buffer_ptr);
    return(99);
  }
  /* clear the buffer */
  memset(buffer_ptr, '\0', buffer_sz);

  /* call the db2GetSnapshot API to capture a snapshot and store the */
  /* monitor data in the buffer pointed to by "buffer_ptr". */
  /*    first, set the values of the db2GetSnapshot structure */
  getSnapshotParam.piSqlmaData = ma_ptr;
  getSnapshotParam.poCollectedData = &collected;
  getSnapshotParam.iBufferSize = buffer_sz;
  getSnapshotParam.poBuffer = buffer_ptr;
  getSnapshotParam.iVersion = SQLM_CURRENT_VERSION;
  getSnapshotParam.iStoreResult = 0;
  getSnapshotParam.iNodeNumber = SQLM_CURRENT_NODE;
  getSnapshotParam.poOutputFormat = &outputFormat;
  getSnapshotParam.iSnapshotClass = SQLM_CLASS_DEFAULT;
  /*    second, call the db2GetSnapshot API */
  printf("\n%s",DASHES);
  printf("\nCapturing snapshot using db2GetSnapshot.");
  printf("\n%s\n",DASHES);
  rc = db2GetSnapshot(db2Version970, &getSnapshotParam, &sqlca);

  while (sqlca.sqlcode == 1606)
  {
    /* deallocate memory assigned to the buffer */
    FreeMemory(NULL, buffer_ptr);

    printf("\n%s",DASHES);
    printf("\nBuffer size for snapshot data is too small.");
    printf("\nRe-allocating memory for snapshot monitor data.");
    printf("\n%s\n",DASHES);

   /* enlarge the buffer */
    buffer_sz = buffer_sz + SNAPSHOT_BUFFER_UNIT_SZ;

    /* allocate memory to a buffer to hold snapshot monitor data. */
    printf("\n%s",DASHES);
    printf("\nAllocating memory for snapshot monitor data.");
    printf("\n%s\n",DASHES);
    buffer_ptr = (char *) malloc(buffer_sz);
    if (buffer_ptr == NULL)
    {
      printf("\n%s",DASHES);
      printf("\nError allocating memory for buffer area. Exiting.");
      printf("\n%s\n",DASHES);
      FreeMemory(ma_ptr, buffer_ptr);
      return(99);
    }
    /* clear the buffer */
    memset(buffer_ptr, '\0', buffer_sz);

    getSnapshotParam.iBufferSize = buffer_sz;
    getSnapshotParam.poBuffer = buffer_ptr;

    /* get snapshot */
    printf("\n%s",DASHES);
    printf("\nCapturing snapshot using db2GetSnapshot.");
    printf("\n%s\n",DASHES);
    rc = db2GetSnapshot(db2Version970, &getSnapshotParam, &sqlca);
  }
  
  /* exit function if the db2GetSnapshot call returns a non-zero value */
  if (rc != 0)
  {
    printf("\n%s",DASHES);
    printf("\nReturn code from db2GetSnapshot is %d. Exiting.", rc);
    printf("\n%s\n",DASHES);
    FreeMemory(ma_ptr, buffer_ptr);
    return rc;
  }

  /* examine the sqlcode and react accordingly: */
  /*   if 0, then continue */
  /*   if positive, then print the sqlca info and continue */
  /*   if negative, then print the sqlca info and exit function */
  if (sqlca.sqlcode != 0L)
  {
    SqlInfoPrint("db2GetSnapshot", &sqlca, __LINE__, __FILE__);
    if (sqlca.sqlcode == 1611)
    {
      printf("For SQLCODE 1611, the system monitor will return the ");
      printf("contents of the\nSQLM_ELM_COLLECTED logical grouping, ");
      printf("including monitoring metadata\nand monitor switch settings.");
    }
    if (sqlca.sqlcode < 0L)
    {
      printf("\n%s",DASHES);
      printf("\ndb2GetSnapshot SQLCODE is %d. Exiting.", sqlca.sqlcode);
      printf("\n%s\n",DASHES);
      FreeMemory(ma_ptr, buffer_ptr);
      return((int)sqlca.sqlcode);
    }
  }
  
  /* initialize the array of monitor element names */
  InitElementNames();

  /* parse and print the monitor data */
  printf("\n%s",DASHES);
  printf("\nSnapshot monitor data:\n\n");
  ParseMonitorStream(" ", buffer_ptr, NULL);
  printf("\n%s\n",DASHES);

  /* release memory before exiting */
  FreeMemory(ma_ptr, buffer_ptr);

  return rc;
} /* GetSnapshot */

/***************************************************************************/
/* InitElementNames                                                        */
/* Initialize the array of element names based on the defines in sqlmon.h. */
/***************************************************************************/
int InitElementNames(void)
{
  int rc = 0;
  int arraySize = NUMELEMENTS * sizeof(elementName[0]);
  char * pArray = (char *) &elementName[0];

  /* zero the entire array to ensure unset values are null */
  strncpy(pArray,"",arraySize);
 
  /* set the individual element names (they are defined in sqlmon.h) */
  elementName[1] = "SQLM_ELM_DB2";
  elementName[2] = "SQLM_ELM_FCM";
  elementName[3] = "SQLM_ELM_FCM_NODE";
  elementName[4] = "SQLM_ELM_APPL_INFO";
  elementName[5] = "SQLM_ELM_APPL";
  elementName[6] = "SQLM_ELM_DCS_APPL_INFO";
  elementName[7] = "SQLM_ELM_DCS_APPL";
  elementName[8] = "SQLM_ELM_DCS_STMT";
  elementName[9] = "SQLM_ELM_SUBSECTION";
  elementName[10] = "SQLM_ELM_AGENT";
  elementName[11] = "SQLM_ELM_LOCK_WAIT";
  elementName[12] = "SQLM_ELM_DCS_DBASE";
  elementName[13] = "SQLM_ELM_DBASE";
  elementName[14] = "SQLM_ELM_ROLLFORWARD";
  elementName[15] = "SQLM_ELM_TABLE";
  elementName[16] = "SQLM_ELM_LOCK";
  elementName[17] = "SQLM_ELM_TABLESPACE";
  elementName[18] = "SQLM_ELM_BUFFERPOOL";
  elementName[19] = "SQLM_ELM_DYNSQL";
  elementName[20] = "SQLM_ELM_COLLECTED";
  elementName[21] = "SQLM_ELM_SWITCH_LIST";
  elementName[22] = "SQLM_ELM_UOW_SW";
  elementName[23] = "SQLM_ELM_STATEMENT_SW";
  elementName[24] = "SQLM_ELM_TABLE_SW";
  elementName[25] = "SQLM_ELM_BUFFPOOL_SW";
  elementName[26] = "SQLM_ELM_LOCK_SW";
  elementName[27] = "SQLM_ELM_SORT_SW";
  elementName[28] = "SQLM_ELM_TABLE_LIST";
  elementName[29] = "SQLM_ELM_TABLESPACE_LIST";
  elementName[30] = "SQLM_ELM_DYNSQL_LIST";
  elementName[31] = "SQLM_ELM_APPL_LOCK_LIST";
  elementName[32] = "SQLM_ELM_DB_LOCK_LIST";
  elementName[33] = "SQLM_ELM_STMT";
  elementName[34] = "SQLM_ELM_DBASE_REMOTE";
  elementName[35] = "SQLM_ELM_APPL_REMOTE";
  elementName[36] = "SQLM_ELM_APPL_ID_INFO";
  elementName[37] = "SQLM_ELM_STMT_TRANSMISSIONS";
  elementName[38] = "SQLM_ELM_TIMESTAMP_SW";
  elementName[39] = "SQLM_ELM_TABLE_REORG";
  elementName[40] = "SQLM_ELM_MEMORY_POOL";
  elementName[41] = "SQLM_ELM_TABLESPACE_QUIESCER";
  elementName[42] = "SQLM_ELM_TABLESPACE_CONTAINER";
  elementName[43] = "SQLM_ELM_TABLESPACE_RANGE";
  elementName[44] = "SQLM_ELM_TABLESPACE_RANGE_CONTAINER";
  elementName[45] = "SQLM_ELM_TABLESPACE_NODEINFO";
  elementName[46] = "SQLM_ELM_HEALTH_INDICATOR";
  elementName[47] = "SQLM_ELM_HEALTH_INDICATOR_HIST";
  elementName[48] = "SQLM_ELM_BUFFERPOOL_NODEINFO";
  elementName[49] = "SQLM_ELM_UTILITY";
  elementName[50] = "SQLM_ELM_HI_OBJ_LIST";
  elementName[51] = "SQLM_ELM_HI_OBJ_LIST_HIST";
  elementName[52] = "SQLM_ELM_PROGRESS";
  elementName[53] = "SQLM_ELM_PROGRESS_LIST";
  elementName[54] = "SQLM_ELM_HADR";
  elementName[55] = "SQLM_ELM_DETAIL_LOG";
  elementName[56] = "SQLM_ELM_ROLLBACK_PROGRESS";
  elementName[57] = "SQLM_ELM_DB_STORAGE_GROUP";
  elementName[58] = "SQLM_ELM_DB_STO_PATH_INFO";
  elementName[59] = "SQLM_ELM_MEMORY_POOL_LIST";
  elementName[59] = "SQLM_MAX_LOGICAL_ELEMENT";
  elementName[100] = "SQLM_ELM_EVENT_DB";
  elementName[101] = "SQLM_ELM_EVENT_CONN";
  elementName[102] = "SQLM_ELM_EVENT_TABLE";
  elementName[103] = "SQLM_ELM_EVENT_STMT";
  elementName[104] = "SQLM_ELM_EVENT_XACT";
  elementName[105] = "SQLM_ELM_EVENT_DEADLOCK";
  elementName[106] = "SQLM_ELM_EVENT_DLCONN";
  elementName[107] = "SQLM_ELM_EVENT_TABLESPACE";
  elementName[108] = "SQLM_ELM_EVENT_DBHEADER";
  elementName[109] = "SQLM_ELM_EVENT_START";
  elementName[110] = "SQLM_ELM_EVENT_CONNHEADER";
  elementName[111] = "SQLM_ELM_EVENT_OVERFLOW";
  elementName[112] = "SQLM_ELM_EVENT_BUFFERPOOL";
  elementName[113] = "SQLM_ELM_EVENT_SUBSECTION";
  elementName[114] = "SQLM_ELM_EVENT_LOG_HEADER";
  elementName[115] = "SQLM_ELM_EVENT_CONTROL";
  elementName[116] = "SQLM_ELM_EVENT_LOCK_LIST";
  elementName[117] = "SQLM_ELM_EVENT_DETAILED_DLCONN";
  elementName[118] = "SQLM_ELM_EVENT_CONNMEMUSE";
  elementName[119] = "SQLM_ELM_EVENT_DBMEMUSE";
  elementName[120] = "SQLM_ELM_EVENT_STMT_HISTORY";
  elementName[121] = "SQLM_ELM_EVENT_DATA_VALUE";
  elementName[122] = "SQLM_ELM_EVENT_ACTIVITY";
  elementName[123] = "SQLM_ELM_EVENT_ACTIVITYSTMT";
  elementName[124] = "SQLM_ELM_EVENT_ACTIVITYVALS";
  elementName[125] = "SQLM_ELM_EVENT_SCSTATS";
  elementName[126] = "SQLM_ELM_EVENT_WCSTATS";
  elementName[127] = "SQLM_ELM_EVENT_WLSTATS";
  elementName[128] = "SQLM_ELM_EVENT_QSTATS";
  elementName[129] = "SQLM_ELM_EVENT_HISTOGRAMBIN";
  elementName[130] = "SQLM_ELM_EVENT_THRESHOLD_VIOLATIONS";
  elementName[200] = "SQLM_ELM_TIME_STAMP";
  elementName[201] = "SQLM_ELM_STATUS_CHANGE_TIME";
  elementName[202] = "SQLM_ELM_GW_CON_TIME";
  elementName[203] = "SQLM_ELM_PREV_UOW_STOP_TIME";
  elementName[204] = "SQLM_ELM_UOW_START_TIME";
  elementName[205] = "SQLM_ELM_UOW_STOP_TIME";
  elementName[206] = "SQLM_ELM_STMT_START";
  elementName[207] = "SQLM_ELM_STMT_STOP";
  elementName[208] = "SQLM_ELM_LAST_RESET";
  elementName[209] = "SQLM_ELM_DB2START_TIME";
  elementName[210] = "SQLM_ELM_DB_CONN_TIME";
  elementName[211] = "SQLM_ELM_LAST_BACKUP";
  elementName[212] = "SQLM_ELM_LOCK_WAIT_START_TIME";
  elementName[213] = "SQLM_ELM_APPL_CON_TIME";
  elementName[214] = "SQLM_ELM_CONN_COMPLETE_TIME";
  elementName[215] = "SQLM_ELM_DISCONN_TIME";
  elementName[216] = "SQLM_ELM_EVENT_TIME";
  elementName[217] = "SQLM_ELM_START_TIME";
  elementName[218] = "SQLM_ELM_STOP_TIME";
  elementName[219] = "SQLM_ELM_RF_TIMESTAMP";
  elementName[220] = "SQLM_ELM_CONN_TIME";
  elementName[221] = "SQLM_ELM_FIRST_OVERFLOW_TIME";
  elementName[222] = "SQLM_ELM_LAST_OVERFLOW_TIME";
  elementName[223] = "SQLM_ELM_GW_EXEC_TIME";
  elementName[224] = "SQLM_ELM_AGENT_USR_CPU_TIME";
  elementName[225] = "SQLM_ELM_AGENT_SYS_CPU_TIME";
  elementName[226] = "SQLM_ELM_SS_USR_CPU_TIME";
  elementName[227] = "SQLM_ELM_SS_SYS_CPU_TIME";
  elementName[228] = "SQLM_ELM_USER_CPU_TIME";
  elementName[229] = "SQLM_ELM_TOTAL_EXEC_TIME";
  elementName[230] = "SQLM_ELM_SWITCH_SET_TIME";
  elementName[231] = "SQLM_ELM_ELAPSED_EXEC_TIME";
  elementName[232] = "SQLM_ELM_SELECT_TIME";
  elementName[233] = "SQLM_ELM_INSERT_TIME";
  elementName[234] = "SQLM_ELM_UPDATE_TIME";
  elementName[235] = "SQLM_ELM_DELETE_TIME";
  elementName[236] = "SQLM_ELM_CREATE_NICKNAME_TIME";
  elementName[237] = "SQLM_ELM_PASSTHRU_TIME";
  elementName[238] = "SQLM_ELM_STORED_PROC_TIME";
  elementName[239] = "SQLM_ELM_REMOTE_LOCK_TIME";
  elementName[240] = "SQLM_ELM_NETWORK_TIME_TOP";
  elementName[241] = "SQLM_ELM_NETWORK_TIME_BOTTOM";
  elementName[242] = "SQLM_ELM_TABLESPACE_REBALANCER_START_TIME";
  elementName[243] = "SQLM_ELM_TABLESPACE_REBALANCER_RESTART_TIME";
  elementName[244] = "SQLM_ELM_TABLESPACE_MIN_RECOVERY_TIME";
  elementName[245] = "SQLM_ELM_HI_TIMESTAMP";
  elementName[245] = "SQLM_MAX_TIME_STAMP";
  elementName[300] = "SQLM_ELM_SECONDS";
  elementName[301] = "SQLM_ELM_MICROSEC";
  elementName[302] = "SQLM_ELM_AGENT_ID";
  elementName[303] = "SQLM_ELM_SERVER_DB2_TYPE";
  elementName[304] = "SQLM_ELM_SERVER_PRDID";
  elementName[305] = "SQLM_ELM_SERVER_NNAME";
  elementName[306] = "SQLM_ELM_SERVER_INSTANCE_NAME";
  elementName[307] = "SQLM_ELM_NODE_NUMBER";
  elementName[308] = "SQLM_ELM_TIME_ZONE_DISP";
  elementName[309] = "SQLM_ELM_SERVER_VERSION";
  elementName[310] = "SQLM_ELM_APPL_STATUS";
  elementName[311] = "SQLM_ELM_CODEPAGE_ID";
  elementName[312] = "SQLM_ELM_STMT_TEXT";
  elementName[313] = "SQLM_ELM_APPL_NAME";
  elementName[314] = "SQLM_ELM_APPL_ID";
  elementName[315] = "SQLM_ELM_SEQUENCE_NO";
  elementName[316] = "SQLM_ELM_AUTH_ID";
  elementName[316] = "SQLM_ELM_PRIMARY_AUTH_ID";
  elementName[317] = "SQLM_ELM_CLIENT_NNAME";
  elementName[318] = "SQLM_ELM_CLIENT_PRDID";
  elementName[319] = "SQLM_ELM_INPUT_DB_ALIAS";
  elementName[320] = "SQLM_ELM_CLIENT_DB_ALIAS";
  elementName[321] = "SQLM_ELM_DB_NAME";
  elementName[322] = "SQLM_ELM_DB_PATH";
  elementName[323] = "SQLM_ELM_NUM_ASSOC_AGENTS";
  elementName[324] = "SQLM_ELM_COORD_NODE_NUM";
  elementName[325] = "SQLM_ELM_AUTHORITY_LVL";
  elementName[326] = "SQLM_ELM_EXECUTION_ID";
  elementName[327] = "SQLM_ELM_CORR_TOKEN";
  elementName[328] = "SQLM_ELM_CLIENT_PID";
  elementName[329] = "SQLM_ELM_CLIENT_PLATFORM";
  elementName[330] = "SQLM_ELM_CLIENT_PROTOCOL";
  elementName[331] = "SQLM_ELM_COUNTRY_CODE";
  elementName[331] = "SQLM_ELM_TERRITORY_CODE";
  elementName[332] = "SQLM_ELM_COORD_AGENT_PID";
  elementName[333] = "SQLM_ELM_GW_DB_ALIAS";
  elementName[334] = "SQLM_ELM_OUTBOUND_COMM_ADDRESS";
  elementName[335] = "SQLM_ELM_INBOUND_COMM_ADDRESS";
  elementName[336] = "SQLM_ELM_OUTBOUND_COMM_PROTOCOL";
  elementName[337] = "SQLM_ELM_DCS_DB_NAME";
  elementName[338] = "SQLM_ELM_HOST_DB_NAME";
  elementName[339] = "SQLM_ELM_HOST_PRDID";
  elementName[340] = "SQLM_ELM_OUTBOUND_APPL_ID";
  elementName[341] = "SQLM_ELM_OUTBOUND_SEQUENCE_NO";
  elementName[342] = "SQLM_ELM_DCS_APPL_STATUS";
  elementName[343] = "SQLM_ELM_HOST_CCSID";
  elementName[344] = "SQLM_ELM_OUTPUT_STATE";
  elementName[345] = "SQLM_ELM_COUNT";
  elementName[346] = "SQLM_ELM_ROWS_SELECTED";
  elementName[347] = "SQLM_ELM_SQL_STMTS";
  elementName[348] = "SQLM_ELM_FAILED_SQL_STMTS";
  elementName[349] = "SQLM_ELM_COMMIT_SQL_STMTS";
  elementName[350] = "SQLM_ELM_ROLLBACK_SQL_STMTS";
  elementName[351] = "SQLM_ELM_INBOUND_BYTES_RECEIVED";
  elementName[352] = "SQLM_ELM_OUTBOUND_BYTES_SENT";
  elementName[353] = "SQLM_ELM_OUTBOUND_BYTES_RECEIVED";
  elementName[354] = "SQLM_ELM_INBOUND_BYTES_SENT";
  elementName[355] = "SQLM_ELM_STMT_OPERATION";
  elementName[356] = "SQLM_ELM_SECTION_NUMBER";
  elementName[357] = "SQLM_ELM_LOCK_NODE";
  elementName[358] = "SQLM_ELM_CREATOR";
  elementName[359] = "SQLM_ELM_PACKAGE_NAME";
  elementName[360] = "SQLM_ELM_APPL_IDLE_TIME";
  elementName[361] = "SQLM_ELM_OPEN_CURSORS";
  elementName[362] = "SQLM_ELM_UOW_COMP_STATUS";
  elementName[363] = "SQLM_ELM_SEQUENCE_NO_HOLDING_LK";
  elementName[364] = "SQLM_ELM_ROLLED_BACK_AGENT_ID";
  elementName[365] = "SQLM_ELM_ROLLED_BACK_APPL_ID";
  elementName[366] = "SQLM_ELM_ROLLED_BACK_SEQUENCE_NO";
  elementName[367] = "SQLM_ELM_XID";
  elementName[368] = "SQLM_ELM_TPMON_CLIENT_USERID";
  elementName[369] = "SQLM_ELM_TPMON_CLIENT_WKSTN";
  elementName[370] = "SQLM_ELM_TPMON_CLIENT_APP";
  elementName[371] = "SQLM_ELM_TPMON_ACC_STR";
  elementName[372] = "SQLM_ELM_QUERY_COST_ESTIMATE";
  elementName[373] = "SQLM_ELM_QUERY_CARD_ESTIMATE";
  elementName[374] = "SQLM_ELM_FETCH_COUNT";
  /* ROWS_RETURNED is an alias of FETCH_COUNT    */
  /* elementName[374] = "SQLM_ELM_ROWS_RETURNED" */
  elementName[375] = "SQLM_ELM_GW_TOTAL_CONS";
  elementName[376] = "SQLM_ELM_GW_CUR_CONS";
  elementName[377] = "SQLM_ELM_GW_CONS_WAIT_HOST";
  elementName[378] = "SQLM_ELM_GW_CONS_WAIT_CLIENT";
  elementName[379] = "SQLM_ELM_GW_CONNECTIONS_TOP";
  elementName[380] = "SQLM_ELM_SORT_HEAP_ALLOCATED";
  elementName[381] = "SQLM_ELM_POST_THRESHOLD_SORTS";
  elementName[382] = "SQLM_ELM_PIPED_SORTS_REQUESTED";
  elementName[383] = "SQLM_ELM_PIPED_SORTS_ACCEPTED";
  elementName[384] = "SQLM_ELM_DL_CONNS";
  elementName[385] = "SQLM_ELM_REM_CONS_IN";
  elementName[386] = "SQLM_ELM_REM_CONS_IN_EXEC";
  elementName[387] = "SQLM_ELM_LOCAL_CONS";
  elementName[388] = "SQLM_ELM_LOCAL_CONS_IN_EXEC";
  elementName[389] = "SQLM_ELM_CON_LOCAL_DBASES";
  elementName[390] = "SQLM_ELM_AGENTS_REGISTERED";
  elementName[391] = "SQLM_ELM_AGENTS_WAITING_ON_TOKEN";
  elementName[392] = "SQLM_ELM_DB2_STATUS";
  elementName[393] = "SQLM_ELM_AGENTS_REGISTERED_TOP";
  elementName[394] = "SQLM_ELM_AGENTS_WAITING_TOP";
  elementName[395] = "SQLM_ELM_COMM_PRIVATE_MEM";
  elementName[396] = "SQLM_ELM_IDLE_AGENTS";
  elementName[397] = "SQLM_ELM_AGENTS_FROM_POOL";
  elementName[398] = "SQLM_ELM_AGENTS_CREATED_EMPTY_POOL";
  elementName[399] = "SQLM_ELM_AGENTS_TOP";
  elementName[400] = "SQLM_ELM_COORD_AGENTS_TOP";
  elementName[401] = "SQLM_ELM_MAX_AGENT_OVERFLOWS";
  elementName[402] = "SQLM_ELM_AGENTS_STOLEN";
  elementName[403] = "SQLM_ELM_PRODUCT_NAME";
  elementName[404] = "SQLM_ELM_COMPONENT_ID";
  elementName[405] = "SQLM_ELM_SERVICE_LEVEL";
  elementName[406] = "SQLM_ELM_POST_THRESHOLD_HASH_JOINS";
  elementName[407] = "SQLM_ELM_BUFF_FREE";
  elementName[408] = "SQLM_ELM_BUFF_FREE_BOTTOM";
  elementName[409] = "SQLM_ELM_MA_FREE";
  elementName[410] = "SQLM_ELM_MA_FREE_BOTTOM";
  elementName[411] = "SQLM_ELM_CE_FREE";
  elementName[412] = "SQLM_ELM_CE_FREE_BOTTOM";
  elementName[413] = "SQLM_ELM_RB_FREE";
  elementName[414] = "SQLM_ELM_RB_FREE_BOTTOM";
  elementName[416] = "SQLM_ELM_CONNECTION_STATUS";
  elementName[417] = "SQLM_ELM_TOTAL_BUFFERS_SENT";
  elementName[418] = "SQLM_ELM_TOTAL_BUFFERS_RCVD";
  elementName[419] = "SQLM_ELM_LOCKS_HELD";
  elementName[420] = "SQLM_ELM_LOCK_WAITS";
  elementName[421] = "SQLM_ELM_LOCK_WAIT_TIME";
  elementName[422] = "SQLM_ELM_LOCK_LIST_IN_USE";
  elementName[423] = "SQLM_ELM_DEADLOCKS";
  elementName[424] = "SQLM_ELM_LOCK_ESCALS";
  elementName[425] = "SQLM_ELM_X_LOCK_ESCALS";
  elementName[426] = "SQLM_ELM_LOCKS_WAITING";
  elementName[427] = "SQLM_ELM_TOTAL_SORTS";
  elementName[428] = "SQLM_ELM_TOTAL_SORT_TIME";
  elementName[429] = "SQLM_ELM_SORT_OVERFLOWS";
  elementName[430] = "SQLM_ELM_ACTIVE_SORTS";
  elementName[431] = "SQLM_ELM_POOL_DATA_L_READS";
  elementName[432] = "SQLM_ELM_POOL_DATA_P_READS";
  elementName[433] = "SQLM_ELM_POOL_DATA_WRITES";
  elementName[434] = "SQLM_ELM_POOL_INDEX_L_READS";
  elementName[435] = "SQLM_ELM_POOL_INDEX_P_READS";
  elementName[436] = "SQLM_ELM_POOL_INDEX_WRITES";
  elementName[437] = "SQLM_ELM_POOL_READ_TIME";
  elementName[438] = "SQLM_ELM_POOL_WRITE_TIME";
  elementName[439] = "SQLM_ELM_FILES_CLOSED";
  elementName[440] = "SQLM_ELM_DYNAMIC_SQL_STMTS";
  elementName[441] = "SQLM_ELM_STATIC_SQL_STMTS";
  elementName[442] = "SQLM_ELM_SELECT_SQL_STMTS";
  elementName[443] = "SQLM_ELM_DDL_SQL_STMTS";
  elementName[444] = "SQLM_ELM_UID_SQL_STMTS";
  elementName[445] = "SQLM_ELM_INT_AUTO_REBINDS";
  elementName[446] = "SQLM_ELM_INT_ROWS_DELETED";
  elementName[447] = "SQLM_ELM_INT_ROWS_UPDATED";
  elementName[448] = "SQLM_ELM_INT_COMMITS";
  elementName[449] = "SQLM_ELM_INT_ROLLBACKS";
  elementName[450] = "SQLM_ELM_INT_DEADLOCK_ROLLBACKS";
  elementName[451] = "SQLM_ELM_ROWS_DELETED";
  elementName[452] = "SQLM_ELM_ROWS_INSERTED";
  elementName[453] = "SQLM_ELM_ROWS_UPDATED";
  elementName[454] = "SQLM_ELM_BINDS_PRECOMPILES";
  elementName[455] = "SQLM_ELM_LOCKS_HELD_TOP";
  elementName[456] = "SQLM_ELM_NUM_NODES_IN_DB2_INSTANCE";
  elementName[457] = "SQLM_ELM_TOTAL_CONS";
  elementName[458] = "SQLM_ELM_APPLS_CUR_CONS";
  elementName[459] = "SQLM_ELM_APPLS_IN_DB2";
  elementName[460] = "SQLM_ELM_SEC_LOG_USED_TOP";
  elementName[461] = "SQLM_ELM_TOT_LOG_USED_TOP";
  elementName[462] = "SQLM_ELM_SEC_LOGS_ALLOCATED";
  elementName[463] = "SQLM_ELM_POOL_ASYNC_INDEX_READS";
  elementName[464] = "SQLM_ELM_POOL_DATA_TO_ESTORE";
  elementName[465] = "SQLM_ELM_POOL_INDEX_TO_ESTORE";
  elementName[466] = "SQLM_ELM_POOL_INDEX_FROM_ESTORE";
  elementName[467] = "SQLM_ELM_POOL_DATA_FROM_ESTORE";
  elementName[468] = "SQLM_ELM_DB_STATUS";
  elementName[469] = "SQLM_ELM_LOCK_TIMEOUTS";
  elementName[470] = "SQLM_ELM_CONNECTIONS_TOP";
  elementName[471] = "SQLM_ELM_DB_HEAP_TOP";
  elementName[472] = "SQLM_ELM_POOL_ASYNC_DATA_READS";
  elementName[473] = "SQLM_ELM_POOL_ASYNC_DATA_WRITES";
  elementName[474] = "SQLM_ELM_POOL_ASYNC_INDEX_WRITES";
  elementName[475] = "SQLM_ELM_POOL_ASYNC_READ_TIME";
  elementName[476] = "SQLM_ELM_POOL_ASYNC_WRITE_TIME";
  elementName[477] = "SQLM_ELM_POOL_ASYNC_DATA_READ_REQS";
  elementName[478] = "SQLM_ELM_POOL_LSN_GAP_CLNS";
  elementName[479] = "SQLM_ELM_POOL_DRTY_PG_STEAL_CLNS";
  elementName[480] = "SQLM_ELM_POOL_DRTY_PG_THRSH_CLNS";
  elementName[481] = "SQLM_ELM_DIRECT_READS";
  elementName[482] = "SQLM_ELM_DIRECT_WRITES";
  elementName[483] = "SQLM_ELM_DIRECT_READ_REQS";
  elementName[484] = "SQLM_ELM_DIRECT_WRITE_REQS";
  elementName[485] = "SQLM_ELM_DIRECT_READ_TIME";
  elementName[486] = "SQLM_ELM_DIRECT_WRITE_TIME";
  elementName[487] = "SQLM_ELM_INT_ROWS_INSERTED";
  elementName[488] = "SQLM_ELM_LOG_READS";
  elementName[489] = "SQLM_ELM_LOG_WRITES";
  elementName[490] = "SQLM_ELM_PKG_CACHE_LOOKUPS";
  elementName[491] = "SQLM_ELM_PKG_CACHE_INSERTS";
  elementName[492] = "SQLM_ELM_CAT_CACHE_LOOKUPS";
  elementName[493] = "SQLM_ELM_CAT_CACHE_INSERTS";
  elementName[494] = "SQLM_ELM_CAT_CACHE_OVERFLOWS";
  elementName[495] = "SQLM_ELM_CAT_CACHE_HEAP_FULL";
  elementName[496] = "SQLM_ELM_CATALOG_NODE";
  elementName[497] = "SQLM_ELM_TOTAL_SEC_CONS";
  elementName[498] = "SQLM_ELM_DB_LOCATION";
  elementName[499] = "SQLM_ELM_SERVER_PLATFORM";
  elementName[500] = "SQLM_ELM_CATALOG_NODE_NAME";
  elementName[501] = "SQLM_ELM_PREFETCH_WAIT_TIME";
  elementName[502] = "SQLM_ELM_APPL_SECTION_LOOKUPS";
  elementName[503] = "SQLM_ELM_APPL_SECTION_INSERTS";
  elementName[504] = "SQLM_ELM_TOTAL_HASH_JOINS";
  elementName[505] = "SQLM_ELM_TOTAL_HASH_LOOPS";
  elementName[506] = "SQLM_ELM_HASH_JOIN_OVERFLOWS";
  elementName[507] = "SQLM_ELM_HASH_JOIN_SMALL_OVERFLOWS";
  elementName[508] = "SQLM_ELM_UOW_LOCK_WAIT_TIME";
  elementName[509] = "SQLM_ELM_STMT_TYPE";
  elementName[510] = "SQLM_ELM_CURSOR_NAME";
  elementName[511] = "SQLM_ELM_UOW_LOG_SPACE_USED";
  elementName[512] = "SQLM_ELM_OPEN_REM_CURS";
  elementName[513] = "SQLM_ELM_OPEN_REM_CURS_BLK";
  elementName[514] = "SQLM_ELM_REJ_CURS_BLK";
  elementName[515] = "SQLM_ELM_ACC_CURS_BLK";
  elementName[516] = "SQLM_ELM_VERSION";
  elementName[517] = "SQLM_ELM_EVENT_MONITOR_NAME";
  elementName[518] = "SQLM_ELM_SQL_REQS_SINCE_COMMIT";
  elementName[520] = "SQLM_ELM_BYTE_ORDER";
  elementName[521] = "SQLM_ELM_PREP_TIME_WORST";
  elementName[522] = "SQLM_ELM_ROWS_READ";
  /* ROWS_FETCHED is an alias of ROWS_READ      */
  /* elementName[522] = "SQLM_ELM_ROWS_FETCHED" */
  elementName[523] = "SQLM_ELM_ROWS_WRITTEN";
  elementName[523] = "SQLM_ELM_ROWS_MODIFIED";
  elementName[524] = "SQLM_ELM_OPEN_LOC_CURS";
  elementName[525] = "SQLM_ELM_OPEN_LOC_CURS_BLK";
  elementName[526] = "SQLM_ELM_COORD_NODE";
  elementName[526] = "SQLM_ELM_COORD_PARTITION_NUM";
  elementName[527] = "SQLM_ELM_NUM_AGENTS";
  elementName[528] = "SQLM_ELM_ASSOCIATED_AGENTS_TOP";
  elementName[529] = "SQLM_ELM_APPL_PRIORITY";
  elementName[530] = "SQLM_ELM_APPL_PRIORITY_TYPE";
  elementName[531] = "SQLM_ELM_DEGREE_PARALLELISM";
  elementName[532] = "SQLM_ELM_STMT_SORTS";
  elementName[533] = "SQLM_ELM_STMT_USR_CPU_TIME";
  elementName[534] = "SQLM_ELM_STMT_SYS_CPU_TIME";
  elementName[535] = "SQLM_ELM_SS_NUMBER";
  elementName[536] = "SQLM_ELM_SS_STATUS";
  elementName[537] = "SQLM_ELM_SS_NODE_NUMBER";
  elementName[538] = "SQLM_ELM_SS_EXEC_TIME";
  elementName[539] = "SQLM_ELM_PREP_TIME_BEST";
  elementName[540] = "SQLM_ELM_NUM_COMPILATIONS";
  elementName[541] = "SQLM_ELM_TQ_NODE_WAITED_FOR";
  elementName[542] = "SQLM_ELM_TQ_WAIT_FOR_ANY";
  elementName[543] = "SQLM_ELM_TQ_ID_WAITING_ON";
  elementName[544] = "SQLM_ELM_TQ_TOT_SEND_SPILLS";
  elementName[545] = "SQLM_ELM_TQ_CUR_SEND_SPILLS";
  elementName[546] = "SQLM_ELM_TQ_MAX_SEND_SPILLS";
  elementName[547] = "SQLM_ELM_TQ_ROWS_READ";
  elementName[548] = "SQLM_ELM_TQ_ROWS_WRITTEN";
  elementName[549] = "SQLM_ELM_AGENT_PID";
  elementName[550] = "SQLM_ELM_LOCK_ESCALATION";
  elementName[551] = "SQLM_ELM_SUBSECTION_NUMBER";
  elementName[552] = "SQLM_ELM_LOCK_MODE";
  elementName[553] = "SQLM_ELM_LOCK_OBJECT_TYPE";
  elementName[554] = "SQLM_ELM_NUM_EXECUTIONS";
  elementName[555] = "SQLM_ELM_TABLE_NAME";
  elementName[556] = "SQLM_ELM_TABLE_SCHEMA";
  elementName[557] = "SQLM_ELM_TABLESPACE_NAME";
  elementName[558] = "SQLM_ELM_AGENT_ID_HOLDING_LK";
  elementName[559] = "SQLM_ELM_APPL_ID_HOLDING_LK";
  elementName[561] = "SQLM_ELM_TABLE_FILE_ID";
  elementName[562] = "SQLM_ELM_TABLE_TYPE";
  elementName[563] = "SQLM_ELM_OVERFLOW_ACCESSES";
  elementName[564] = "SQLM_ELM_PAGE_REORGS";
  elementName[565] = "SQLM_ELM_SQLCABC";
  elementName[566] = "SQLM_ELM_LOCK_STATUS";
  elementName[567] = "SQLM_ELM_LOCK_OBJECT_NAME";
  elementName[568] = "SQLM_ELM_RF_TYPE";
  elementName[569] = "SQLM_ELM_RF_LOG_NUM";
  elementName[570] = "SQLM_ELM_RF_STATUS";
  elementName[571] = "SQLM_ELM_TS_NAME";
  elementName[572] = "SQLM_ELM_BP_NAME";
  elementName[573] = "SQLM_ELM_STMT_NODE_NUMBER";
  elementName[574] = "SQLM_ELM_PARTIAL_RECORD";
  elementName[575] = "SQLM_ELM_SYSTEM_CPU_TIME";
  elementName[576] = "SQLM_ELM_SQLCA";
  elementName[577] = "SQLM_ELM_SQLCODE";
  elementName[578] = "SQLM_ELM_SQLERRML";
  elementName[579] = "SQLM_ELM_SQLERRMC";
  elementName[580] = "SQLM_ELM_SQLERRP";
  elementName[581] = "SQLM_ELM_SQLERRD";
  elementName[582] = "SQLM_ELM_SQLWARN";
  elementName[583] = "SQLM_ELM_SQLSTATE";
  elementName[584] = "SQLM_ELM_UOW_STATUS";
  elementName[585] = "SQLM_ELM_TOTAL_SYS_CPU_TIME";
  elementName[586] = "SQLM_ELM_TOTAL_USR_CPU_TIME";
  elementName[587] = "SQLM_ELM_LOCK_MODE_REQUESTED";
  elementName[588] = "SQLM_ELM_INACTIVE_GW_AGENTS";
  elementName[589] = "SQLM_ELM_NUM_GW_CONN_SWITCHES";
  elementName[590] = "SQLM_ELM_GW_COMM_ERRORS";
  elementName[591] = "SQLM_ELM_GW_COMM_ERROR_TIME";
  elementName[592] = "SQLM_ELM_GW_CON_START_TIME";
  elementName[593] = "SQLM_ELM_CON_RESPONSE_TIME";
  elementName[594] = "SQLM_ELM_CON_ELAPSED_TIME";
  elementName[595] = "SQLM_ELM_HOST_RESPONSE_TIME";
  elementName[596] = "SQLM_ELM_PKG_CACHE_NUM_OVERFLOWS";
  elementName[597] = "SQLM_ELM_PKG_CACHE_SIZE_TOP";
  elementName[598] = "SQLM_ELM_APPL_ID_OLDEST_XACT";
  elementName[599] = "SQLM_ELM_TOTAL_LOG_USED";
  elementName[600] = "SQLM_ELM_TOTAL_LOG_AVAILABLE";
  elementName[601] = "SQLM_ELM_STMT_ELAPSED_TIME";
  elementName[602] = "SQLM_ELM_UOW_ELAPSED_TIME";
  elementName[603] = "SQLM_ELM_SQLCAID";
  elementName[604] = "SQLM_ELM_SMALLEST_LOG_AVAIL_NODE";
  elementName[605] = "SQLM_ELM_DISCONNECTS";
  elementName[606] = "SQLM_ELM_CREATE_NICKNAME";
  elementName[607] = "SQLM_ELM_PASSTHRUS";
  elementName[608] = "SQLM_ELM_STORED_PROCS";
  elementName[609] = "SQLM_ELM_SP_ROWS_SELECTED";
  elementName[610] = "SQLM_ELM_DATASOURCE_NAME";
  elementName[611] = "SQLM_ELM_REMOTE_LOCKS";
  elementName[612] = "SQLM_ELM_BLOCKING_CURSOR";
  elementName[613] = "SQLM_ELM_OUTBOUND_BLOCKING_CURSOR";
  elementName[614] = "SQLM_ELM_INSERT_SQL_STMTS";
  elementName[615] = "SQLM_ELM_UPDATE_SQL_STMTS";
  elementName[616] = "SQLM_ELM_DELETE_SQL_STMTS";
  elementName[617] = "SQLM_ELM_UNREAD_PREFETCH_PAGES";
  elementName[618] = "SQLM_ELM_AGENT_STATUS";
  elementName[619] = "SQLM_ELM_NUM_TRANSMISSIONS";
  elementName[620] = "SQLM_ELM_OUTBOUND_BYTES_SENT_TOP";
  elementName[621] = "SQLM_ELM_OUTBOUND_BYTES_RECEIVED_TOP";
  elementName[622] = "SQLM_ELM_OUTBOUND_BYTES_SENT_BOTTOM";
  elementName[623] = "SQLM_ELM_OUTBOUND_BYTES_RECEIVED_BOTTOM";
  elementName[624] = "SQLM_ELM_MAX_DATA_SENT_128";
  elementName[625] = "SQLM_ELM_MAX_DATA_SENT_256";
  elementName[626] = "SQLM_ELM_MAX_DATA_SENT_512";
  elementName[627] = "SQLM_ELM_MAX_DATA_SENT_1024";
  elementName[628] = "SQLM_ELM_MAX_DATA_SENT_2048";
  elementName[629] = "SQLM_ELM_MAX_DATA_SENT_4096";
  elementName[630] = "SQLM_ELM_MAX_DATA_SENT_8192";
  elementName[631] = "SQLM_ELM_MAX_DATA_SENT_16384";
  elementName[632] = "SQLM_ELM_MAX_DATA_SENT_31999";
  elementName[633] = "SQLM_ELM_MAX_DATA_SENT_64000";
  elementName[634] = "SQLM_ELM_MAX_DATA_SENT_GT64000";
  elementName[635] = "SQLM_ELM_MAX_DATA_RECEIVED_128";
  elementName[636] = "SQLM_ELM_MAX_DATA_RECEIVED_256";
  elementName[637] = "SQLM_ELM_MAX_DATA_RECEIVED_512";
  elementName[638] = "SQLM_ELM_MAX_DATA_RECEIVED_1024";
  elementName[639] = "SQLM_ELM_MAX_DATA_RECEIVED_2048";
  elementName[640] = "SQLM_ELM_MAX_DATA_RECEIVED_4096";
  elementName[641] = "SQLM_ELM_MAX_DATA_RECEIVED_8192";
  elementName[642] = "SQLM_ELM_MAX_DATA_RECEIVED_16384";
  elementName[643] = "SQLM_ELM_MAX_DATA_RECEIVED_31999";
  elementName[644] = "SQLM_ELM_MAX_DATA_RECEIVED_64000";
  elementName[645] = "SQLM_ELM_MAX_DATA_RECEIVED_GT64000";
  elementName[646] = "SQLM_ELM_MAX_TIME_2_MS";
  elementName[647] = "SQLM_ELM_MAX_TIME_4_MS";
  elementName[648] = "SQLM_ELM_MAX_TIME_8_MS";
  elementName[649] = "SQLM_ELM_MAX_TIME_16_MS";
  elementName[650] = "SQLM_ELM_MAX_TIME_32_MS";
  elementName[651] = "SQLM_ELM_MAX_TIME_GT32_MS";
  elementName[652] = "SQLM_ELM_DEADLOCK_ID";
  elementName[653] = "SQLM_ELM_DEADLOCK_NODE";
  elementName[654] = "SQLM_ELM_PARTICIPANT_NO";
  elementName[655] = "SQLM_ELM_PARTICIPANT_NO_HOLDING_LK";
  elementName[656] = "SQLM_ELM_ROLLED_BACK_PARTICIPANT_NO";
  elementName[657] = "SQLM_ELM_SQLERRD1";
  elementName[658] = "SQLM_ELM_SQLERRD2";
  elementName[659] = "SQLM_ELM_SQLERRD3";
  elementName[660] = "SQLM_ELM_SQLERRD4";
  elementName[661] = "SQLM_ELM_SQLERRD5";
  elementName[662] = "SQLM_ELM_SQLERRD6";
  elementName[663] = "SQLM_ELM_EVMON_ACTIVATES";
  elementName[664] = "SQLM_ELM_EVMON_FLUSHES";
  elementName[665] = "SQLM_ELM_SQL_REQ_ID";
  elementName[666] = "SQLM_ELM_MESSAGE";
  elementName[667] = "SQLM_ELM_MESSAGE_TIME";
  elementName[668] = "SQLM_ELM_VECTORED_IOS";
  elementName[669] = "SQLM_ELM_PAGES_FROM_VECTORED_IOS";
  elementName[670] = "SQLM_ELM_BLOCK_IOS";
  elementName[671] = "SQLM_ELM_PAGES_FROM_BLOCK_IOS";
  elementName[672] = "SQLM_ELM_PHYSICAL_PAGE_MAPS";
  elementName[673] = "SQLM_ELM_LOCKS_IN_LIST";
  elementName[674] = "SQLM_ELM_REORG_PHASE";
  elementName[675] = "SQLM_ELM_REORG_MAX_PHASE";
  elementName[676] = "SQLM_ELM_REORG_CURRENT_COUNTER";
  elementName[677] = "SQLM_ELM_REORG_MAX_COUNTER";
  elementName[678] = "SQLM_ELM_REORG_TYPE";
  elementName[679] = "SQLM_ELM_REORG_STATUS";
  elementName[680] = "SQLM_ELM_REORG_COMPLETION";
  elementName[681] = "SQLM_ELM_REORG_START";
  elementName[682] = "SQLM_ELM_REORG_END";
  elementName[683] = "SQLM_ELM_REORG_PHASE_START";
  elementName[684] = "SQLM_ELM_REORG_INDEX_ID";
  elementName[685] = "SQLM_ELM_REORG_TBSPC_ID";
  elementName[686] = "SQLM_ELM_POOL_ID";
  elementName[687] = "SQLM_ELM_POOL_CUR_SIZE";
  elementName[688] = "SQLM_ELM_POOL_CONFIG_SIZE";
  elementName[688] = "SQLM_ELM_POOL_MAX_SIZE";
  elementName[689] = "SQLM_ELM_POOL_WATERMARK";
  elementName[690] = "SQLM_ELM_TABLESPACE_ID";
  elementName[691] = "SQLM_ELM_TABLESPACE_TYPE";
  elementName[692] = "SQLM_ELM_TABLESPACE_CONTENT_TYPE";
  elementName[693] = "SQLM_ELM_TABLESPACE_STATE";
  elementName[694] = "SQLM_ELM_TABLESPACE_PAGE_SIZE";
  elementName[695] = "SQLM_ELM_TABLESPACE_EXTENT_SIZE";
  elementName[696] = "SQLM_ELM_TABLESPACE_PREFETCH_SIZE";
  elementName[697] = "SQLM_ELM_TABLESPACE_CUR_POOL_ID";
  elementName[698] = "SQLM_ELM_TABLESPACE_NEXT_POOL_ID";
  elementName[699] = "SQLM_ELM_TABLESPACE_TOTAL_PAGES";
  elementName[700] = "SQLM_ELM_TABLESPACE_USABLE_PAGES";
  elementName[701] = "SQLM_ELM_TABLESPACE_USED_PAGES";
  elementName[702] = "SQLM_ELM_TABLESPACE_FREE_PAGES";
  elementName[703] = "SQLM_ELM_TABLESPACE_PAGE_TOP";
  elementName[704] = "SQLM_ELM_TABLESPACE_PENDING_FREE_PAGES";
  elementName[705] = "SQLM_ELM_TABLESPACE_REBALANCER_MODE";
  elementName[706] = "SQLM_ELM_TABLESPACE_REBALANCER_EXTENTS_REMAINING";
  elementName[707] = "SQLM_ELM_TABLESPACE_REBALANCER_EXTENTS_PROCESSED";
  elementName[708] = "SQLM_ELM_TABLESPACE_REBALANCER_LAST_EXTENT_MOVED";
  elementName[709] = "SQLM_ELM_TABLESPACE_REBALANCER_PRIORITY";
  elementName[710] = "SQLM_ELM_TABLESPACE_NUM_QUIESCERS";
  elementName[711] = "SQLM_ELM_TABLESPACE_STATE_CHANGE_OBJECT_ID";
  elementName[712] = "SQLM_ELM_TABLESPACE_STATE_CHANGE_TS_ID";
  elementName[713] = "SQLM_ELM_TABLESPACE_NUM_CONTAINERS";
  elementName[714] = "SQLM_ELM_TABLESPACE_NUM_RANGES";
  elementName[715] = "SQLM_ELM_QUIESCER_STATE";
  elementName[716] = "SQLM_ELM_QUIESCER_AGENT_ID";
  elementName[717] = "SQLM_ELM_QUIESCER_TS_ID";
  elementName[718] = "SQLM_ELM_QUIESCER_OBJ_ID";
  elementName[719] = "SQLM_ELM_QUIESCER_AUTH_ID";
  elementName[720] = "SQLM_ELM_CONTAINER_ID";
  elementName[721] = "SQLM_ELM_CONTAINER_TYPE";
  elementName[722] = "SQLM_ELM_CONTAINER_TOTAL_PAGES";
  elementName[723] = "SQLM_ELM_CONTAINER_USABLE_PAGES";
  elementName[724] = "SQLM_ELM_CONTAINER_STRIPE_SET";
  elementName[725] = "SQLM_ELM_CONTAINER_ACCESSIBLE";
  elementName[726] = "SQLM_ELM_CONTAINER_NAME";
  elementName[727] = "SQLM_ELM_RANGE_STRIPE_SET_NUMBER";
  elementName[728] = "SQLM_ELM_RANGE_NUMBER";
  elementName[729] = "SQLM_ELM_RANGE_OFFSET";
  elementName[730] = "SQLM_ELM_RANGE_MAX_PAGE_NUMBER";
  elementName[731] = "SQLM_ELM_RANGE_MAX_EXTENT";
  elementName[732] = "SQLM_ELM_RANGE_START_STRIPE";
  elementName[733] = "SQLM_ELM_RANGE_END_STRIPE";
  elementName[734] = "SQLM_ELM_RANGE_ADJUSTMENT";
  elementName[735] = "SQLM_ELM_RANGE_NUM_CONTAINERS";
  elementName[736] = "SQLM_ELM_RANGE_CONTAINER_ID";
  elementName[737] = "SQLM_ELM_CONSISTENCY_TOKEN";
  elementName[738] = "SQLM_ELM_PACKAGE_VERSION_ID";
  elementName[739] = "SQLM_ELM_LOCK_NAME";
  elementName[740] = "SQLM_ELM_LOCK_COUNT";
  elementName[741] = "SQLM_ELM_LOCK_HOLD_COUNT";
  elementName[742] = "SQLM_ELM_LOCK_ATTRIBUTES";
  elementName[743] = "SQLM_ELM_LOCK_RELEASE_FLAGS";
  elementName[744] = "SQLM_ELM_LOCK_CURRENT_MODE";
  elementName[745] = "SQLM_ELM_TABLESPACE_FS_CACHING";
  elementName[751] = "SQLM_ELM_BP_TBSP_USE_COUNT";
  elementName[752] = "SQLM_ELM_BP_PAGES_LEFT_TO_REMOVE";
  elementName[753] = "SQLM_ELM_BP_CUR_BUFFSZ";
  elementName[754] = "SQLM_ELM_BP_NEW_BUFFSZ";
  elementName[755] = "SQLM_ELM_SORT_HEAP_TOP";
  elementName[756] = "SQLM_ELM_SORT_SHRHEAP_ALLOCATED";
  elementName[757] = "SQLM_ELM_SORT_SHRHEAP_TOP";
  elementName[758] = "SQLM_ELM_SHR_WORKSPACE_SIZE_TOP";
  elementName[759] = "SQLM_ELM_SHR_WORKSPACE_NUM_OVERFLOWS";
  elementName[760] = "SQLM_ELM_SHR_WORKSPACE_SECTION_LOOKUPS";
  elementName[761] = "SQLM_ELM_SHR_WORKSPACE_SECTION_INSERTS";
  elementName[762] = "SQLM_ELM_PRIV_WORKSPACE_SIZE_TOP";
  elementName[763] = "SQLM_ELM_PRIV_WORKSPACE_NUM_OVERFLOWS";
  elementName[764] = "SQLM_ELM_PRIV_WORKSPACE_SECTION_LOOKUPS";
  elementName[765] = "SQLM_ELM_PRIV_WORKSPACE_SECTION_INSERTS";
  elementName[766] = "SQLM_ELM_CAT_CACHE_SIZE_TOP";
  elementName[767] = "SQLM_ELM_PARTITION_NUMBER";
  elementName[768] = "SQLM_ELM_NUM_TRANSMISSIONS_GROUP";
  elementName[769] = "SQLM_ELM_NUM_INDOUBT_TRANS";
  elementName[770] = "SQLM_ELM_UTILITY_DBNAME";
  elementName[771] = "SQLM_ELM_UTILITY_ID";
  elementName[772] = "SQLM_ELM_UTILITY_TYPE";
  elementName[773] = "SQLM_ELM_UTILITY_PRIORITY";
  elementName[774] = "SQLM_ELM_UTILITY_START_TIME";
  elementName[775] = "SQLM_ELM_UTILITY_DESCRIPTION";
  elementName[776] = "SQLM_ELM_POOL_ASYNC_INDEX_READ_REQS";
  elementName[777] = "SQLM_ELM_SESSION_AUTH_ID";
  elementName[778] = "SQLM_ELM_SQL_CHAINS";
  elementName[779] = "SQLM_ELM_POOL_TEMP_DATA_L_READS";
  elementName[780] = "SQLM_ELM_POOL_TEMP_DATA_P_READS";
  elementName[781] = "SQLM_ELM_POOL_TEMP_INDEX_L_READS";
  elementName[782] = "SQLM_ELM_POOL_TEMP_INDEX_P_READS";
  elementName[783] = "SQLM_ELM_MAX_TIME_1_MS";
  elementName[784] = "SQLM_ELM_MAX_TIME_100_MS";
  elementName[785] = "SQLM_ELM_MAX_TIME_500_MS";
  elementName[786] = "SQLM_ELM_MAX_TIME_GT500_MS";
  elementName[787] = "SQLM_ELM_LOG_TO_REDO_FOR_RECOVERY";
  elementName[788] = "SQLM_ELM_POOL_NO_VICTIM_BUFFER";
  elementName[789] = "SQLM_ELM_LOG_HELD_BY_DIRTY_PAGES";
  elementName[790] = "SQLM_ELM_PROGRESS_DESCRIPTION";
  elementName[791] = "SQLM_ELM_PROGRESS_START_TIME";
  elementName[792] = "SQLM_ELM_PROGRESS_WORK_METRIC";
  elementName[793] = "SQLM_ELM_PROGRESS_TOTAL_UNITS";
  elementName[794] = "SQLM_ELM_PROGRESS_COMPLETED_UNITS";
  elementName[795] = "SQLM_ELM_PROGRESS_SEQ_NUM";
  elementName[796] = "SQLM_ELM_PROGRESS_LIST_CUR_SEQ_NUM";
  elementName[797] = "SQLM_ELM_HADR_ROLE";
  elementName[798] = "SQLM_ELM_HADR_STATE";
  elementName[799] = "SQLM_ELM_HADR_SYNCMODE";
  elementName[800] = "SQLM_ELM_HADR_CONNECT_STATUS";
  elementName[801] = "SQLM_ELM_HADR_CONNECT_TIME";
  elementName[802] = "SQLM_ELM_HADR_HEARTBEAT";
  elementName[803] = "SQLM_ELM_HADR_LOCAL_HOST";
  elementName[804] = "SQLM_ELM_HADR_LOCAL_SERVICE";
  elementName[805] = "SQLM_ELM_HADR_REMOTE_HOST";
  elementName[806] = "SQLM_ELM_HADR_REMOTE_SERVICE";
  elementName[807] = "SQLM_ELM_HADR_TIMEOUT";
  elementName[808] = "SQLM_ELM_HADR_PRIMARY_LOG_FILE";
  elementName[809] = "SQLM_ELM_HADR_PRIMARY_LOG_PAGE";
  elementName[810] = "SQLM_ELM_HADR_PRIMARY_LOG_LSN";
  elementName[811] = "SQLM_ELM_HADR_STANDBY_LOG_FILE";
  elementName[812] = "SQLM_ELM_HADR_STANDBY_LOG_PAGE";
  elementName[813] = "SQLM_ELM_HADR_STANDBY_LOG_LSN";
  elementName[814] = "SQLM_ELM_HADR_LOG_GAP";
  elementName[815] = "SQLM_ELM_HADR_REMOTE_INSTANCE";
  elementName[816] = "SQLM_ELM_DATA_OBJECT_PAGES";
  elementName[817] = "SQLM_ELM_INDEX_OBJECT_PAGES";
  elementName[818] = "SQLM_ELM_LOB_OBJECT_PAGES";
  elementName[819] = "SQLM_ELM_LONG_OBJECT_PAGES";
  elementName[820] = "SQLM_ELM_LOCK_TIMEOUT_VAL";
  elementName[821] = "SQLM_ELM_LOG_WRITE_TIME";
  elementName[822] = "SQLM_ELM_LOG_READ_TIME";
  elementName[823] = "SQLM_ELM_NUM_LOG_WRITE_IO";
  elementName[824] = "SQLM_ELM_NUM_LOG_READ_IO";
  elementName[825] = "SQLM_ELM_NUM_LOG_PART_PAGE_IO";
  elementName[826] = "SQLM_ELM_NUM_LOG_BUFF_FULL";
  elementName[827] = "SQLM_ELM_NUM_LOG_DATA_IN_BUFF";
  elementName[828] = "SQLM_ELM_LOG_FILE_NUM_FIRST";
  elementName[829] = "SQLM_ELM_LOG_FILE_NUM_LAST";
  elementName[830] = "SQLM_ELM_LOG_FILE_NUM_CURR";
  elementName[831] = "SQLM_ELM_LOG_FILE_ARCHIVE";
  elementName[832] = "SQLM_ELM_NANOSEC";
  elementName[833] = "SQLM_ELM_STMT_HISTORY_ID";
  elementName[834] = "SQLM_ELM_STMT_LOCK_TIMEOUT";
  elementName[835] = "SQLM_ELM_STMT_ISOLATION";
  elementName[836] = "SQLM_ELM_COMP_ENV_DESC";
  elementName[837] = "SQLM_ELM_STMT_VALUE_TYPE";
  elementName[838] = "SQLM_ELM_STMT_VALUE_ISREOPT";
  elementName[839] = "SQLM_ELM_STMT_VALUE_ISNULL";
  elementName[840] = "SQLM_ELM_STMT_VALUE_DATA";
  elementName[841] = "SQLM_ELM_STMT_VALUE_INDEX";
  elementName[842] = "SQLM_ELM_STMT_FIRST_USE_TIME";
  elementName[843] = "SQLM_ELM_STMT_LAST_USE_TIME";
  elementName[844] = "SQLM_ELM_STMT_NEST_LEVEL";
  elementName[845] = "SQLM_ELM_STMT_INVOCATION_ID";
  elementName[846] = "SQLM_ELM_STMT_QUERY_ID";
  elementName[847] = "SQLM_ELM_STMT_SOURCE_ID";
  elementName[848] = "SQLM_ELM_STMT_PKGCACHE_ID";
  elementName[849] = "SQLM_ELM_INACT_STMTHIST_SZ";
  elementName[850] = "SQLM_ELM_NUM_DB_STORAGE_PATHS";
  elementName[851] = "SQLM_ELM_DB_STORAGE_PATH";
  elementName[852] = "SQLM_ELM_TABLESPACE_INITIAL_SIZE";
  elementName[853] = "SQLM_ELM_TABLESPACE_CURRENT_SIZE";
  elementName[854] = "SQLM_ELM_TABLESPACE_MAX_SIZE";
  elementName[855] = "SQLM_ELM_TABLESPACE_INCREASE_SIZE_PERCENT";
  elementName[856] = "SQLM_ELM_TABLESPACE_INCREASE_SIZE";
  elementName[857] = "SQLM_ELM_TABLESPACE_LAST_RESIZE_TIME";
  elementName[858] = "SQLM_ELM_TABLESPACE_USING_AUTO_STORAGE";
  elementName[859] = "SQLM_ELM_TABLESPACE_AUTO_RESIZE_ENABLED";
  elementName[860] = "SQLM_ELM_TABLESPACE_LAST_RESIZE_FAILED";
  elementName[861] = "SQLM_ELM_BP_ID";
  elementName[862] = "SQLM_ELM_REORG_LONG_TBSPC_ID";
  elementName[863] = "SQLM_ELM_DATA_PARTITION_ID";
  elementName[864] = "SQLM_ELM_PROGRESS_LIST_ATTR";
  elementName[865] = "SQLM_ELM_REORG_ROWSCOMPRESSED";
  elementName[866] = "SQLM_ELM_REORG_ROWSREJECTED";
  elementName[867] = "SQLM_ELM_CH_FREE";
  elementName[868] = "SQLM_ELM_CH_FREE_BOTTOM";
  elementName[869] = "SQLM_ELM_UTILITY_STATE";
  elementName[870] = "SQLM_ELM_UTILITY_INVOKER_TYPE";
  elementName[871] = "SQLM_ELM_POST_SHRTHRESHOLD_SORTS";
  elementName[872] = "SQLM_ELM_POST_SHRTHRESHOLD_HASH_JOINS";
  elementName[873] = "SQLM_ELM_ACTIVE_HASH_JOINS";
  elementName[874] = "SQLM_ELM_POOL_SECONDARY_ID";
  elementName[875] = "SQLM_ELM_FS_ID";
  elementName[876] = "SQLM_ELM_FS_TOTAL_SZ";
  elementName[877] = "SQLM_ELM_FS_USED_SZ";
  elementName[878] = "SQLM_ELM_STO_PATH_FREE_SZ";
  elementName[879] = "SQLM_ELM_POOL_XDA_L_READS";
  elementName[880] = "SQLM_ELM_POOL_XDA_P_READS";
  elementName[881] = "SQLM_ELM_POOL_XDA_WRITES";
  elementName[882] = "SQLM_ELM_POOL_TEMP_XDA_L_READS";
  elementName[883] = "SQLM_ELM_POOL_TEMP_XDA_P_READS";
  elementName[884] = "SQLM_ELM_POOL_ASYNC_XDA_READS";
  elementName[885] = "SQLM_ELM_POOL_ASYNC_XDA_WRITES";
  elementName[886] = "SQLM_ELM_POOL_ASYNC_XDA_READ_REQS";
  elementName[887] = "SQLM_ELM_XDA_OBJECT_PAGES";
  elementName[888] = "SQLM_ELM_XQUERY_STMTS";
  elementName[889] = "SQLM_ELM_TRUSTED_AUTH_ID";
  elementName[890] = "SQLM_ELM_HADR_PEER_WINDOW_END";
  elementName[891] = "SQLM_ELM_HADR_PEER_WINDOW";
  elementName[892] = "SQLM_ELM_BLOCKS_PENDING_CLEANUP";
  elementName[893] = "SQLM_ELM_AUTHORITY_BITMAP";
  elementName[894] = "SQLM_ELM_TOTAL_OLAP_FUNCS";
  elementName[895] = "SQLM_ELM_POST_THRESHOLD_OLAP_FUNCS";
  elementName[896] = "SQLM_ELM_ACTIVE_OLAP_FUNCS";
  elementName[897] = "SQLM_ELM_OLAP_FUNC_OVERFLOWS";
  elementName[898] = "SQLM_ELM_SERVICE_CLASS_ID";
  elementName[899] = "SQLM_ELM_SERVICE_SUPERCLASS_NAME";
  elementName[900] = "SQLM_ELM_SERVICE_SUBCLASS_NAME";
  elementName[901] = "SQLM_ELM_WORK_ACTION_SET_ID";
  elementName[902] = "SQLM_ELM_WORK_ACTION_SET_NAME";
  elementName[903] = "SQLM_ELM_DB_WORK_ACTION_SET_ID";
  elementName[904] = "SQLM_ELM_SC_WORK_ACTION_SET_ID";
  elementName[905] = "SQLM_ELM_WORK_CLASS_ID";
  elementName[906] = "SQLM_ELM_WORK_CLASS_NAME";
  elementName[907] = "SQLM_ELM_DB_WORK_CLASS_ID";
  elementName[908] = "SQLM_ELM_SC_WORK_CLASS_ID";
  elementName[909] = "SQLM_ELM_WORKLOAD_ID";
  elementName[910] = "SQLM_ELM_WORKLOAD_OCCURRENCE_ID";
  elementName[911] = "SQLM_ELM_WORKLOAD_NAME";
  elementName[912] = "SQLM_ELM_TEMP_TABLESPACE_TOP";
  elementName[913] = "SQLM_ELM_ROWS_RETURNED_TOP";
  elementName[914] = "SQLM_ELM_CONCURRENT_ACT_TOP";
  elementName[915] = "SQLM_ELM_CONCURRENT_CONNECTION_TOP";
  elementName[916] = "SQLM_ELM_COST_ESTIMATE_TOP";
  elementName[917] = "SQLM_ELM_STATISTICS_TIMESTAMP";
  elementName[918] = "SQLM_ELM_ACT_TOTAL";
  elementName[919] = "SQLM_ELM_WLO_COMPLETED_TOTAL";
  elementName[920] = "SQLM_ELM_CONCURRENT_WLO_TOP";
  elementName[921] = "SQLM_ELM_CONCURRENT_WLO_ACT_TOP";
  elementName[922] = "SQLM_ELM_TOP";
  elementName[923] = "SQLM_ELM_BOTTOM";
  elementName[924] = "SQLM_ELM_HISTOGRAM_TYPE";
  elementName[925] = "SQLM_ELM_BIN_ID";
  elementName[926] = "SQLM_ELM_ACTIVITY_ID";
  elementName[927] = "SQLM_ELM_ACTIVITY_SECONDARY_ID";
  elementName[928] = "SQLM_ELM_UOW_ID";
  elementName[929] = "SQLM_ELM_PARENT_ACTIVITY_ID";
  elementName[930] = "SQLM_ELM_PARENT_UOW_ID";
  elementName[931] = "SQLM_ELM_TIME_OF_VIOLATION";
  elementName[932] = "SQLM_ELM_ACTIVITY_COLLECTED";
  elementName[933] = "SQLM_ELM_ACTIVITY_TYPE";
  elementName[934] = "SQLM_ELM_THRESHOLD_PREDICATE";
  elementName[935] = "SQLM_ELM_THRESHOLD_ACTION";
  elementName[936] = "SQLM_ELM_THRESHOLD_MAXVALUE";
  elementName[937] = "SQLM_ELM_THRESHOLD_QUEUESIZE";
  elementName[938] = "SQLM_ELM_COORD_ACT_COMPLETED_TOTAL";
  elementName[939] = "SQLM_ELM_COORD_ACT_ABORTED_TOTAL";
  elementName[940] = "SQLM_ELM_COORD_ACT_REJECTED_TOTAL";
  elementName[941] = "SQLM_ELM_COORD_ACT_LIFETIME_TOP";
  elementName[942] = "SQLM_ELM_ACT_EXEC_TIME";
  elementName[943] = "SQLM_ELM_TIME_CREATED";
  elementName[944] = "SQLM_ELM_TIME_STARTED";
  elementName[945] = "SQLM_ELM_TIME_COMPLETED";
  elementName[946] = "SQLM_ELM_SECTION_ENV";
  elementName[947] = "SQLM_ELM_ACTIVATE_TIMESTAMP";
  elementName[948] = "SQLM_ELM_NUM_THRESHOLD_VIOLATIONS";
  elementName[949] = "SQLM_ELM_ARM_CORRELATOR";
  elementName[950] = "SQLM_ELM_PREP_TIME";
  elementName[951] = "SQLM_ELM_QUEUE_SIZE_TOP";
  elementName[953] = "SQLM_ELM_QUEUE_ASSIGNMENTS_TOTAL";
  elementName[954] = "SQLM_ELM_QUEUE_TIME_TOTAL";
  elementName[955] = "SQLM_ELM_LAST_WLM_RESET";
  elementName[956] = "SQLM_ELM_THRESHOLD_DOMAIN";
  elementName[957] = "SQLM_ELM_THRESHOLD_NAME";
  elementName[958] = "SQLM_ELM_THRESHOLDID";
  elementName[959] = "SQLM_ELM_NUMBER_IN_BIN";
  elementName[960] = "SQLM_ELM_COORD_ACT_LIFETIME_AVG";
  elementName[961] = "SQLM_ELM_COORD_ACT_QUEUE_TIME_AVG";
  elementName[962] = "SQLM_ELM_COORD_ACT_EXEC_TIME_AVG";
  elementName[963] = "SQLM_ELM_COORD_ACT_EST_COST_AVG";
  elementName[964] = "SQLM_ELM_COORD_ACT_INTERARRIVAL_TIME_AVG";
  elementName[965] = "SQLM_ELM_REQUEST_EXEC_TIME_AVG";
  elementName[966] = "SQLM_ELM_STATS_CACHE_SIZE";
  elementName[967] = "SQLM_ELM_STATS_FABRICATIONS";
  elementName[968] = "SQLM_ELM_STATS_FABRICATE_TIME";
  elementName[969] = "SQLM_ELM_SYNC_RUNSTATS";
  elementName[970] = "SQLM_ELM_SYNC_RUNSTATS_TIME";
  elementName[971] = "SQLM_ELM_ASYNC_RUNSTATS";
  elementName[972] = "SQLM_ELM_POOL_LIST_ID";
  elementName[973] = "SQLM_ELM_IS_SYSTEM_APPL";
  elementName[974] = "SQLM_ELM_INSERT_TIMESTAMP";
  elementName[975] = "SQLM_ELM_DESTINATION_SERVICE_CLASS_ID";
  elementName[976] = "SQLM_ELM_SOURCE_SERVICE_CLASS_ID";
  elementName[977] = "SQLM_ELM_ACT_REMAPPED_IN";
  elementName[978] = "SQLM_ELM_ACT_REMAPPED_OUT";
  elementName[979] = "SQLM_ELM_AGG_TEMP_TABLESPACE_TOP";
  elementName[980] = "SQLM_ELM_NUM_REMAPS";
  elementName[981] = "SQLM_ELM_ACT_CPU_TIME_TOP";
  elementName[982] = "SQLM_ELM_ACT_ROWS_READ_TOP";

  return rc;
} /* InitElementNames */

/***************************************************************************/
/* ParseMonitorStream                                                      */
/* Parse the monitor data stream and print its contents. The data stream   */
/* is self-describing in that each unit of data (a logical data grouping   */
/* or a monitor element) is introduced with a "sqlm_header_info"           */
/* structure. This structure indicates the number of bytes taken up by the */
/* data, the type of the data, and the name of the applicable logical data */
/* group or monitor element. The monitor data stream starts with the       */
/* "SQLM_ELM_COLLECTED" logical data grouping, which encompasses the       */
/* entire data stream.                                                     */
/* The purpose of logical data groupings is to organize monitor data by    */
/* category. As such they contain sets of related monitor elements, and at */
/* times, other logical data groupings.                                    */
/* The monitor data stream is printed to standard out, such that the       */
/* logical data groupings and their monitor elements are indented          */
/* according to the degree to which they are nested in the data stream.    */
/*                                                                         */
/* Parameters:                                                             */
/*   prefix: contains space characters. This string prefixes logical group */
/*           names and monitor elements when they are printed, thus        */
/*           indicating the degree to which they are nested.               */
/*   pStart: the memory location indicating the start of the current       */
/*           logical grouping                                              */
/*   pEnd:   the memory location indicating the end of the current logical */
/*           grouping                                                      */
/***************************************************************************/
sqlm_header_info * ParseMonitorStream(char * prefix,
                                      char * pStart,
                                      char * pEnd)
{
  sqlm_header_info * pHeader = (sqlm_header_info *)pStart;
  char * pData;
  char * pElementName;
  char   elementNameBuffer[24];

  /* "pEnd" is NULL only when called at the "SQLM_ELM_COLLECTED" level, so */
  /* because this is the beginning of the monitor data stream, calculate */
  /* the memory location where the monitor data stream buffer ends */
  if (!pEnd)
    pEnd = pStart +                  /* start of monitor stream  */
           pHeader->size +           /* add size in the "collected" header */
           sizeof(sqlm_header_info); /* add size of header itself */

  /* parse and print the data for the current logical grouping */
  /* elements in the current logical grouping will be parsed until "pEnd" */
  while ((char*)pHeader < pEnd)
  {
    /* point to the data which appears immediately after the header */
    pData = (char*)pHeader + sizeof(sqlm_header_info);

    /* determine the actual element name */
    if (pHeader->element >= NUMELEMENTS  ||
        (!(pElementName = elementName[pHeader->element])))
    {
      /* if the element name is not defined, display the number */
      sprintf(elementNameBuffer,"Element Number %d",pHeader->element);
      pElementName = elementNameBuffer;
    }

    /* determine if the current unit of data is a nested logical grouping */
    if (pHeader->type == SQLM_TYPE_HEADER)
    {
      char newPrefix[80];
      char *pNewEnd;

      printf("%s Logical Grouping  %s   (size %d)\n",prefix, 
                                                     pElementName,
                                                     pHeader->size);

      /* indent the data for this logical group to indicate nesting */
      strncpy(newPrefix, BLANKS, strlen(prefix)+2);
      newPrefix[strlen(prefix)+2] = '\0';
      pNewEnd = pData + (pHeader->size);

      /* call ParseMonitorStream recursively to parse and print this */
      /* nested logical grouping */
      pHeader = ParseMonitorStream(newPrefix, pData, pNewEnd);
    }
    else
    {
      /* not a logical grouping, therefore print this monitor element */
      printf("%s Data  %s  (size %d)  ",prefix, pElementName, pHeader->size);

      if (pHeader->type == SQLM_TYPE_U32BIT)
      {
        /* print out the data (4 bytes long and unsigned) */
        unsigned int i = *(unsigned int*)pData;
        printf("%d  (0x%x)\n",i,i);
      }
      else if (pHeader->type == SQLM_TYPE_32BIT)
      {
        /* print out the data (4 bytes long and signed) */
        signed int i = *(signed int*)pData;
        printf("%d\n",i);
      }
      else if (pHeader->type == SQLM_TYPE_STRING)
      {
        /* print out the char string data */
        printf("\"%.*s\"\n",pHeader->size,pData);
      }
      else if (pHeader->type == SQLM_TYPE_U16BIT)
      {
        /* print out the data (4 bytes long and unsigned) */
        unsigned int i = *(unsigned short*)pData;
        printf("%d  (0x%x)\n",i,i);
      }
      else if (pHeader->type == SQLM_TYPE_16BIT)
      {
        /* print out the data (4 bytes long and signed) */
        signed int i = *(signed short*)pData;
        printf("%d\n",i);
      }
      else
      {
        /* must be either 8 bits or 64 bits (and signed / unsigned) */
        /* dump out the data in hex format */
        int i, j;
        printf("0x");
        for (i = 0; i<pHeader->size; i++)
        {
          j = (char)*(pData + i);
          printf("%.2x",j);
        }
        printf("\n");
      }

      /* increment past the data to the next header */
      pHeader = (sqlm_header_info *)(pData + pHeader->size);
    }
  }

  /* return the current memory location once the current logical grouping */
  /* has been parsed */
  return (pHeader);
} /* ParseMonitorStream */

/***************************************************************************/
/* TurnOnAllMonitorSwitches                                                */
/* Turn on all of the monitor switches.                                    */
/***************************************************************************/
int TurnOnAllMonitorSwitches(void)
{
  int rc = 0;
  struct sqlca sqlca;
  db2MonitorSwitchesData switchesData;
  struct sqlm_recording_group switchesList[SQLM_NUM_GROUPS];
  sqluint32 outputFormat;

  printf("\n%s",DASHES);
  printf("\nTurning on all the monitor switches using db2MonitorSwitches.");
  printf("\n%s\n",DASHES);
  
  /* call the db2MonitorSwitches API to update the monitor switch settings */
  /*    first, set the values of the sqlm_recording_group structure */
  switchesList[SQLM_UOW_SW].input_state = SQLM_ON;
  switchesList[SQLM_STATEMENT_SW].input_state = SQLM_ON;
  switchesList[SQLM_TABLE_SW].input_state = SQLM_ON;
  switchesList[SQLM_BUFFER_POOL_SW].input_state = SQLM_ON;
  switchesList[SQLM_LOCK_SW].input_state = SQLM_ON;
  switchesList[SQLM_SORT_SW].input_state = SQLM_ON;
  switchesList[SQLM_TIMESTAMP_SW].input_state = SQLM_ON;
  /*    second, set the values of the db2MonitorSwitchesData structure */
  switchesData.piGroupStates = switchesList;
  switchesData.poBuffer = NULL;
  switchesData.iVersion = SQLM_CURRENT_VERSION;
  switchesData.iBufferSize = 0;
  switchesData.iReturnData = 0;
  switchesData.iNodeNumber = SQLM_CURRENT_NODE;
  switchesData.poOutputFormat = &outputFormat;
  /*    third, call the db2MonitorSwitches API */
  db2MonitorSwitches(db2Version970, &switchesData, &sqlca);

  if (sqlca.sqlcode != 0L)
  {
    SqlInfoPrint("db2MonitorSwitches", &sqlca, __LINE__, __FILE__);
    if (sqlca.sqlcode < 0L)
    {
      printf("Negative sqlcode... exiting\n");
      return((int)sqlca.sqlcode);
    }
  }

  return rc;
} /* TurnOnAllMonitorSwitches */

/***************************************************************************/
/* UpdateUtilImpactLim                                                     */
/* Throttling is done to regulate the performance impact of online         */
/* utilities on the production workload.                                   */
/* Update UTIL_IMPACT_LIM DBM config parameter to set the percentage of    */
/* throttling intended for the utilities of an instance                    */
/***************************************************************************/
int UpdateUtilImpactLim(void)
{
  int rc = 0;
  struct sqlca sqlca;
  db2CfgParam cfgParameters[1];
  db2Cfg cfgStruct;
  unsigned utillim = 0;

  printf("\n%s\n",DASHES);
  printf("Updating the throttling parameter UTIL_IMPACT_LIM\n");
  printf("\nUSE THE DB2 API:\n");
  printf("  db2CfgSet -- Set Configuration \n");
  printf("  Set UTIL_IMPACT_LIM = 60\n");
  printf("\nNOTE: The DBM Cfg parameter for throttling is modified for\n");
  printf("      the current instance.");
  printf("\n%s\n",DASHES);
 
  /* call the db2CfgSet API to update UTIL_IMPACT_LIM cfg parameter */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_KTN_UTIL_IMPACT_LIM;
  cfgParameters[0].ptrvalue = (char *)&utillim;
     
  utillim = 60;
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgImmediate;
  cfgStruct.dbname = NULL;
 
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("UTIL_IMPACT_LIM -- Set");
 
  return rc;
} /* UpdateUtilImpactLim */
