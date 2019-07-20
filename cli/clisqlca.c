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
** SOURCE FILE NAME: clisqlca.c                                      
**                                                                        
** SAMPLE: How to retrieve SQLCA-equivalent information 
**
**         Before running this sample, issue the following commands at the
**         command line processor to ensure accurate statistics are returned:
**
**         (1) db2start
**         (2) db2 connect to sample
**         (3) db2 runstats on table <instance>.org with distribution
**             and indexes all
**             where <instance> is the name of your database instance
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect to a Data Source
**         SQLExecute -- Execute a Statement 
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetDiagField -- Get a Field of Diagnostic Data 
**         SQLPrepare -- Prepare a Statement
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetStmtAttr -- Set Options Related to a Statement
**
** OUTPUT FILE: clisqlca.out (available in the online documentation)
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
#include "utilcli.h" /* Header file for CLI sample code */

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt1 = (SQLCHAR *)"SELECT * FROM org";
  SQLINTEGER diagPtr;
  SQLSMALLINT strLenPtr;

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO RETRIEVE SQLCA-EQUIVALENT INFORMATION.\n");

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLConnect\n");
  printf("  SQLSetStmtAttr\n");
  printf("  SQLPrepare\n");
  printf("  SQLExecute\n");
  printf("  SQLGetDiagField\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO RETRIEVE INFORMATION EQUIVALENT TO SQLERRD(3) and SQLERRD(4):\n");

  /* allocate an environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  if (cliRC != SQL_SUCCESS)
  {
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  cliRC = %d\n", cliRC);
    printf("  line  = %d\n", __LINE__);
    printf("  file  = %s\n", __FILE__);
    return 1;
  }
  
  /* set attribute to enable application to run as ODBC 3.0 application */
  cliRC = SQLSetEnvAttr(henv,
                        SQL_ATTR_ODBC_VERSION,
                        (void *)SQL_OV_ODBC3,
                        0);
  ENV_HANDLE_CHECK(henv, cliRC);


  /* allocate a database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC);

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Connecting to the database %s...\n", dbAlias);

  /* connect to the database */
  cliRC = SQLConnect(hdbc,
                     (SQLCHAR *)dbAlias,
                     SQL_NTS,
                     (SQLCHAR *)user,
                     SQL_NTS,
                     (SQLCHAR *)pswd,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("  Connected to the database %s.\n", dbAlias);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Disable deferred prepare.\n");

  /* disable deferred prepare */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_DEFERRED_PREPARE,
                         (SQLPOINTER)SQL_DEFERRED_PREPARE_OFF,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the cursor type to use */
  cliRC = SQLSetStmtAttr (hstmt,
                          SQL_ATTR_CURSOR_TYPE,
                          (SQLPOINTER) SQL_CURSOR_STATIC,
                          0);

  /*********   Start using the statement handle *******************/

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt1);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  /*cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);*/

  printf("\n  Call SQLGetDiagField to retrieve sqlerrd(3):\n");

  /* get the SQLCA-equivalent information - sqlerrd(3)*/
  cliRC = SQLGetDiagField (SQL_HANDLE_STMT,
                           hstmt,
                           0,
                           SQL_DIAG_CURSOR_ROW_COUNT,
                           &diagPtr,
                           SQL_IS_INTEGER,
                           &strLenPtr);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("    Estimated number of rows that are returned: %d\n", diagPtr);
  
  printf("\n  Call SQLGetDiagField to retrieve sqlerrd(4):\n");
  /* get the SQLCA-equivalent information - sqlerrd(4)*/
  cliRC = SQLGetDiagField (SQL_HANDLE_STMT,
                           hstmt,
                           0,
                           SQL_DIAG_RELATIVE_COST_ESTIMATE,
                           &diagPtr,
                           SQL_IS_INTEGER,
                           &strLenPtr);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("    Estimated cost of prepare: %d\n", diagPtr);

  /*********   Stop using the statement handles ********************/

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Disconnecting from the database %s...\n", dbAlias);

  /* disconnect from the database */
  cliRC = SQLDisconnect(hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Disconnected from the database %s.\n", dbAlias);

  /* free the connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  ENV_HANDLE_CHECK(henv, cliRC);

  return 0;
} /* main */

