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
** SOURCE FILE NAME: tbrunstats.c                                      
**                                                                        
** SAMPLE: How to perform runstats on a table
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** DB2 APIs USED:
**         db2Runstats -- Runstats
**
** STRUCTURES USED:
**         db2ColumnData
**         sqlca
**                                                                        
** OUTPUT FILE: tbrunstats.out (available in the online documentation)
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
#include <sqlcli1.h>
#include <db2ApiDf.h>
#include "utilcli.h" /* Header file for CLI sample code */

int TbRunstats(SQLHANDLE);
int SchemaNameGet(SQLHANDLE); /* support function */

char schemaName[10];
char tableName[10];

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handles */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* checks the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS ");
  printf("HOW TO PERFROM RUNSTATS ON A TABLE.\n");

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_ON);
  if (rc != 0)
  {
    return rc;
  }
  
  /* performs Runstats on the table */ 
  rc = TbRunstats(hdbc);
  
  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* gets the schema name of the table */
int SchemaNameGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *) "SELECT tabschema FROM syscat.tables "
                              "WHERE tabname = 'EMPLOYEE' ";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  tabschema; /* variable to be bound to the tabschema column */

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET SCHEMA NAME OF THE TABLE\n\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* get data from column */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       tabschema.val,
                       10,
                       &tabschema.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  strcpy(schemaName, (char *)tabschema.val);
  
  /* get rid of spaces from the end of schemaName */
  strtok(schemaName, " ");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* SchemaNameGet */

/* performs Runstats on the table */ 
int TbRunstats(SQLHANDLE hdbc)
{
  int rc = 0;
  struct sqlca sqlca;
  char fullTableName[258];
  db2Uint32 versionNumber = db2Version970;
  db2RunstatsData runStatData;
  db2ColumnData *columnList;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2Runstats -- Runstats\n");
  printf("TO UPDATE THE STATISTICS OF A TABLE.\n");

  /* get fully qualified name of the table */
  strcpy(tableName, "EMPLOYEE");

  /* get the schema name of the table */ 
  rc = SchemaNameGet(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  strcpy(fullTableName, schemaName);
  strcat(fullTableName, ".");
  strcat(fullTableName, tableName);

  printf("  Update statistics for the table: %s\n", fullTableName);

  /* allocate memory for db2ColumnData */
  columnList = (struct db2ColumnData *)malloc(sizeof(struct db2ColumnData));
  columnList->piColumnName = (unsigned char *)"empno";
  columnList->iColumnFlags = DB2RUNSTATS_COLUMN_LIKE_STATS;

  printf("\nPerforming runstats on table EMPLOYEE for column EMPNO\n");
  printf("with the following options:\n");
  printf("  Distribution statistics for all partitions\n");
  printf("  Frequent values for table set to 30\n");
  printf("  Quantiles for table set to -1 (NUM_QUANTILES as in DB Cfg)\n");
  printf("  Allow others to have read-only wmahile gathering statistics\n");

  /* runstats on table */
  runStatData.iSamplingOption = 0;
  runStatData.piTablename = (unsigned char *) fullTableName;
  runStatData.piColumnList = &columnList;
  runStatData.piColumnDistributionList = NULL;
  runStatData.piColumnGroupList = NULL;
  runStatData.piIndexList = NULL;
  runStatData.iRunstatsFlags = DB2RUNSTATS_KEY_COLUMNS | 
    DB2RUNSTATS_DISTRIBUTION | DB2RUNSTATS_ALLOW_READ;
  runStatData.iNumColumns = 1;
  runStatData.iNumColdist = 0;
  runStatData.iNumColGroups = 0;
  runStatData.iNumIndexes = 0;
  runStatData.iParallelismOption = 0;
  runStatData.iTableDefaultFreqValues = 30;
  runStatData.iTableDefaultQuantiles = -1;
  runStatData.iUtilImpactPriority = 30;

  /* call the db2Runstats API which updates statistics about the 
     characteristics of a table */
  db2Runstats(versionNumber, &runStatData, &sqlca);

  DB2_API_CHECK("table -- runstats");
  
  free(columnList);

  printf("\nMake sure to rebind all packages that use this table.\n");

  return rc;

} /* TbRunstats */
