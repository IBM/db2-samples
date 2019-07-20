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
** SOURCE FILE NAME: tbload.c
**
** SAMPLE: How to insert data using the CLI LOAD utility 
**        
**         This program demonstrates usage of the CLI LOAD feature.  An array
**         of rows of size "ARRAY_SIZE" will be inserted "NUM_ITERATIONS"
**         times.  Execution of this program will write a text file called
**         cliloadmsg.txt to the current directory.  It contains messages
**         generated during program execution.
**         (Messages will be appended to the end of the file.)  
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB Locator
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare a Statement
**         SQLSetStmtAttr -- Set Options Related to a Statement
**
** OUTPUT FILE: tbload.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference.
**
** For information on using SQL statements, see the SQL Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlutil.h>
#include <sql.h>
#include <sqlenv.h>
#include <db2ApiDf.h>
#include <sqlcli.h>
#include <sqlcli1.h>
#include "utilcli.h"

#define MESSAGE_FILE "./cliloadmsg.txt"
#define SAMPLE_DATA "varchar data"
#define ARRAY_SIZE 10
#define NUM_ITERATIONS 3
#define TRUE 1
#define FALSE 0

int setCLILoadMode(SQLHANDLE, SQLHANDLE, int, db2LoadStruct*);
int terminateApp(SQLHANDLE, SQLHANDLE, SQLHANDLE, char *);

int main (int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLHANDLE hstmt;
  char statementText[1000];
  char *pTempBuffer = NULL;
  SQLINTEGER iBufferSize;
  SQLINTEGER iLoop;
  char *pColumnData = NULL;
  SQLINTEGER *pColumnSizes = NULL;
  db2LoadIn *pLoadIn = NULL;
  db2LoadOut *pLoadOut = NULL;
  db2LoadStruct *pLoadStruct = NULL;
  struct sqldcol *pDataDescriptor = NULL;
  char *pMessageFile = NULL;
  SQLINTEGER iRowsRead = 0;
  SQLINTEGER iRowsSkipped = 0;
  SQLINTEGER iRowsLoaded = 0;
  SQLINTEGER iRowsRejected = 0;
  SQLINTEGER iRowsDeleted = 0;
  SQLINTEGER iRowsCommitted = 0;

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO LOAD DATA USING THE CLI LOAD UTILITY\n");

  /* initialize the application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_OFF);
  if (rc != 0)
  {
    return rc;
  }
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLExecute\n");
  printf("  SQLPrepare\n");
  printf("  SQLSetStmtAttr\n");
  printf("TO INSERT DATA WITH THE CLI LOAD UTILITY:\n");
	
  cliRC= SQLAllocHandle(SQL_HANDLE_STMT,
		        hdbc,
			&hstmt) ;
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

/* Allocate load structures.
   NOTE that the memory belonging to the db2LoadStruct structure used
   in setting the SQL_ATTR_LOAD_INFO attribute *MUST* be accessible
   by *ALL* functions that call CLI functions for the duration of the
   CLI LOAD.  For this reason, it is recommended that the db2LoadStruct
   structure and all its embedded pointers be allocated dynamically,
   instead of declared statically. */

  pLoadIn = (db2LoadIn *)malloc(sizeof(db2LoadIn));
  if (pLoadIn == NULL)
  {
    printf("Error allocating pLoadIn!\n");
    cliRC = terminateApp (hstmt, hdbc, henv, dbAlias); 
    return -1;
  }
  
  pLoadOut = (db2LoadOut *)malloc(sizeof(db2LoadOut));
  if (pLoadOut == NULL)
  {
    printf("Error allocating pLoadOut!\n");
    cliRC = terminateApp (hstmt, hdbc, henv, dbAlias); 
    return -1;
  }
  
  pLoadStruct = (db2LoadStruct *)malloc(sizeof(db2LoadStruct));
  if (pLoadStruct == NULL)
  {
    printf("Error allocating pLoadStruct!\n");
    cliRC = terminateApp (hstmt, hdbc, henv, dbAlias); 
    return -1;
  }
  
  pDataDescriptor = (struct sqldcol *)malloc(sizeof(struct sqldcol));
  if (pDataDescriptor == NULL)
  {
    printf("Error allocating pDataDescriptor!\n");
    cliRC = terminateApp (hstmt, hdbc, henv, dbAlias); 
    return -1;
  }

  pMessageFile = (char *)malloc(256);
  if (pMessageFile == NULL)
  {
    printf("Error allocating pMessageFile!\n");
    cliRC = terminateApp (hstmt, hdbc, henv, dbAlias); 
    return -1;
  }

/* initialize load structures */

  memset(pDataDescriptor, 0, sizeof(struct sqldcol));
  memset(pLoadIn, 0, sizeof(db2LoadIn));
  memset(pLoadOut, 0, sizeof(db2LoadOut));
  memset(pLoadStruct, 0, sizeof(db2LoadStruct));

  pLoadStruct->piSourceList = NULL;
  pLoadStruct->piLobPathList = NULL;
  pLoadStruct->piDataDescriptor = pDataDescriptor;
  pLoadStruct->piFileTypeMod = NULL;
  pLoadStruct->piTempFilesPath = NULL;
  pLoadStruct->piVendorSortWorkPaths = NULL;
  pLoadStruct->piCopyTargetList = NULL;
  pLoadStruct->piNullIndicators = NULL;
  pLoadStruct->piLoadInfoIn = pLoadIn;
  pLoadStruct->poLoadInfoOut = pLoadOut;

  pLoadIn->iRestartphase = ' ';
  pLoadIn->iNonrecoverable = SQLU_NON_RECOVERABLE_LOAD;
  pLoadIn->iStatsOpt = (char)SQLU_STATS_NONE;
  pLoadIn->iSavecount = 0;
  pLoadIn->iCpuParallelism = 0;
  pLoadIn->iDiskParallelism = 0;
  pLoadIn->iIndexingMode = 0;
  pLoadIn->iDataBufferSize = 0;

  sprintf(pMessageFile, "%s", MESSAGE_FILE);
  pLoadStruct->piLocalMsgFileName = pMessageFile;
  pDataDescriptor->dcolmeth = SQL_METH_D;
    
/* drop and create table "loadtable" */
  sprintf(statementText, "DROP TABLE loadtable");
  cliRC= SQLExecDirect(hstmt,
		       (SQLCHAR *)statementText,
		       strlen(statementText));

  sprintf(statementText, "CREATE TABLE loadtable (Col1 VARCHAR(30))");
  printf("\n  %s\n", statementText);
  cliRC= SQLExecDirect(hstmt,
		       (SQLCHAR *)statementText,
		       strlen(statementText));
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

/* allocate a buffer to hold data to insert */

  iBufferSize = strlen(SAMPLE_DATA) * ARRAY_SIZE +
	        sizeof(SQLINTEGER) * ARRAY_SIZE;

  pTempBuffer = (char *)malloc(iBufferSize);
  memset(pTempBuffer, 0, iBufferSize);

  pColumnData = pTempBuffer;
  pColumnSizes = (SQLINTEGER *)(pColumnData +
                 strlen(SAMPLE_DATA) * ARRAY_SIZE);

/* initialize the array of rows */

  for (iLoop=0; iLoop<ARRAY_SIZE; iLoop++)
  {
    memcpy(pColumnData + iLoop * strlen(SAMPLE_DATA), SAMPLE_DATA,
           strlen((char *)SAMPLE_DATA));
    pColumnSizes[iLoop] = strlen((char *)SAMPLE_DATA);
   }

/* prepare the INSERT statement */

  sprintf(statementText, "INSERT INTO loadtable VALUES (?)");
  cliRC= SQLPrepare(hstmt,
		    (SQLCHAR *)statementText,
		    strlen(statementText));
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

/* set the array size */

  cliRC = SQLSetStmtAttr(hstmt,
		         SQL_ATTR_PARAMSET_SIZE,
			 (SQLPOINTER)ARRAY_SIZE,
			 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

/* bind the parameters */

  cliRC= SQLBindParameter(hstmt,
                          1,
                          SQL_PARAM_INPUT,
                          SQL_C_CHAR,
                          SQL_VARCHAR,
                          30,
                          0,
                          (SQLPOINTER)pColumnData,
                          strlen(SAMPLE_DATA),
                          pColumnSizes);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

/* turn CLI LOAD ON */

  cliRC= setCLILoadMode(hstmt, hdbc, TRUE, pLoadStruct);
  printf("\n  Turn CLI LOAD on\n\n");
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

/* insert the data */

  for (iLoop=0; iLoop<NUM_ITERATIONS; iLoop++)
  {
    printf("    Inserting %d rows..\n", ARRAY_SIZE);
    cliRC= SQLExecute(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

/* turn CLI LOAD OFF */

  cliRC= setCLILoadMode(hstmt, hdbc, FALSE, pLoadStruct);
  printf("\n  Turn CLI LOAD off\n");
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Load messages can be found in file [%s].\n", MESSAGE_FILE);
  printf("\n  Load report :\n");

  iRowsRead = pLoadOut->oRowsRead;
  printf("    Number of rows read      : %d\n", iRowsRead);
  iRowsSkipped = pLoadOut->oRowsSkipped;
  printf("    Number of rows skipped   : %d\n", iRowsSkipped);
  iRowsLoaded = pLoadOut->oRowsLoaded;
  printf("    Number of rows loaded    : %d\n", iRowsLoaded);
  iRowsRejected = pLoadOut->oRowsRejected;
  printf("    Number of rows rejected  : %d\n", iRowsRejected);
  iRowsDeleted = pLoadOut->oRowsDeleted;
  printf("    Number of rows deleted   : %d\n", iRowsDeleted);
  iRowsCommitted = pLoadOut->oRowsCommitted;
  printf("    Number of rows committed : %d\n", iRowsCommitted);

  terminateApp(hstmt, hdbc, henv, dbAlias);    
  return 0;

}

/* turn the CLI LOAD feature ON or OFF */
int setCLILoadMode(SQLHANDLE hstmt, SQLHANDLE hdbc, int fStartLoad, db2LoadStruct *pLoadStruct)
{
  int rc = 0;
  SQLRETURN cliRC = SQL_SUCCESS;

  if( fStartLoad )
  {
    cliRC= SQLSetStmtAttr(hstmt,
		          SQL_ATTR_USE_LOAD_API,
			  (SQLPOINTER)SQL_USE_LOAD_INSERT,
			  0);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    
    cliRC= SQLSetStmtAttr(hstmt,
		          SQL_ATTR_LOAD_INFO,
			  (SQLPOINTER)pLoadStruct,
			  0);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  else
  {
    cliRC= SQLSetStmtAttr(hstmt,
		          SQL_ATTR_USE_LOAD_API,
                          (SQLPOINTER)SQL_USE_LOAD_OFF,
			  0);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  return rc;
}

/* end the application */
int terminateApp (SQLHANDLE hstmt, SQLHANDLE hdbc, SQLHANDLE henv, char dbAlias[]) {
  char statementText[1000];
  int rc = 0; /* used in STMT_HANDLE_CHECK macro (defined in utilcli.h */
  SQLRETURN cliRC = SQL_SUCCESS;
  
  sprintf(statementText, "DROP TABLE loadtable");
  printf("\n  %s\n", statementText);
  cliRC = SQLExecDirect(hstmt,
		        (SQLCHAR *)statementText,
			strlen(statementText));
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  cliRC = SQLEndTran(SQL_HANDLE_DBC,
		     hdbc,
		     SQL_COMMIT);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  cliRC = SQLFreeHandle(SQL_HANDLE_STMT,
		        hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  cliRC = CLIAppTerm(&henv, &hdbc, dbAlias);

  return cliRC;
}

