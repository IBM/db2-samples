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
** SOURCE FILE NAME: clihandl.c
**
** SAMPLE: How to allocate and free handles
**
**    CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLFreeHandle -- Free Handle Resources
**
** OUTPUT FILE: clihandl.out (available in the online documentation)
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

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return 1;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO ALLOCATE AND FREE HANDLES.\n");

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLConnect\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO ALLOCATE AND FREE HANDLES:\n");

  printf("\n  Allocate an environment handle.\n");

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

  printf("\n  Allocate a database connection handle.\n");

  /* allocate a database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC);

  printf("\n  Connecting to the database %s...\n", dbAlias);

  /* connect to the database */
  cliRC = SQLConnect(hdbc,
                     (SQLCHAR *)dbAlias, SQL_NTS,
                     (SQLCHAR *)user,
                     SQL_NTS,
                     (SQLCHAR *)pswd,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Connected to the database %s.\n", dbAlias);

  printf("\n  Allocate a statement handle.\n");

  /* allocate one or more statement handles */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /*********   Start using the statement handles *******************/

  /******      Insert any transaction processing here    ***********/

  /*********   Stop using the statement handles ********************/

  printf("  Free the statement handle.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Disconnecting from the database %s...\n", dbAlias);

  /* disconnect from the database */
  cliRC = SQLDisconnect(hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Disconnected from the database %s.\n", dbAlias);

  printf("\n  Free the connection handle.\n");

  /* free the connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Free the environment handle.\n");

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  ENV_HANDLE_CHECK(henv, cliRC);

  return 0;
} /* main */

