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
** SOURCE FILE NAME: dbnative.c
**
** SAMPLE: How to translate a statement that contains an ODBC escape clause
**         to a data source-specific format
**
** CLI FUNCTION USED:
**         SQLNativeSql -- Get Native SQL Text
**
** OUTPUT: dbnative.out (available in the online documentation)
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
  /* SQL SELECT statement to be executed */
  SQLCHAR inODBCStmt[] =
    "SELECT * FROM employee WHERE hiredate={d '1994-03-29'}";
  SQLCHAR odbcEscapeClause[] = "{d '1994-03-29'}";
  SQLCHAR outDbStmt[1024];
  SQLINTEGER dbStmtLen;

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO TRANSLATE A STATEMENT\n");
  printf("THAT CONTAINS AN ODBC ESCAPE CLAUSE TO\n");
  printf("A DATA SOURCE-SPECIFIC FORMAT.\n");

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER) SQL_AUTOCOMMIT_ON);
  if (rc != 0)
  {
    return rc;
  }

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTION\n");
  printf("  SQLNativeSql\n");
  printf("TO:\n");
  printf("  translate the statement\n");
  printf("    %s\n", inODBCStmt);
  printf("  that contains the ODBC escape clause %s\n", odbcEscapeClause);
  printf("  to a data source-specific format.\n");

  /* get the native SQL text */
  SQLNativeSql(hdbc, inODBCStmt, SQL_NTS, outDbStmt, 1024, &dbStmtLen);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  if (dbStmtLen == SQL_NULL_DATA)
  {
    printf("\n  Invalid ODBC statement\n");
  }
  else
  {
    printf("\n  the data source specific format is:\n"
           "    %s\n", outDbStmt);
  }

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

