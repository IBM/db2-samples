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
** SOURCE FILE NAME: dtudt.c                                      
**                                                                        
** SAMPLE: How to create, use, and drop user-defined distinct types.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: dtudt.out (available in the online documentation)
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

int UDTCreate(SQLHANDLE);
int UDTUse(SQLHANDLE);
int UDTDrop(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO CREATE, USE, AND DROP UDTs.\n");

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

  rc = UDTCreate(hdbc);
  rc = UDTUse(hdbc);
  rc = UDTDrop(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* create user-defined distinct types by issuing the
   CREATE DISTINCT TYPE SQL statement */
int UDTCreate(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)
    "CREATE DISTINCT TYPE UDT1 AS INTEGER WITH COMPARISONS";
  SQLCHAR *stmt2 = (SQLCHAR *)
    "CREATE DISTINCT TYPE UDT2 AS CHAR(2) WITH COMPARISONS";
  SQLCHAR *stmt3 = (SQLCHAR *)
    "CREATE DISTINCT TYPE UDT3 AS DECIMAL(7,2) WITH COMPARISONS";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CREATE USER-DEFINED DISTINCT TYPES:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create UDT1 */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt1);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* create the UDT2 */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt2);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* create the UDT3 */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt3);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* UDTCreate */

/* use user-defined distinct types */
int UDTUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)
    "CREATE TABLE DTUDT (Col1 UDT1, Col2 UDT2, Col3 UDT3)";
  SQLCHAR *stmt2 = (SQLCHAR *)
    "INSERT INTO DTUDT "
    "  VALUES(CAST(77 AS UDT1), "
    "         CAST('ab' AS UDT2), "
    "         CAST(111.77 AS UDT3))";

  SQLCHAR *stmt3 = (SQLCHAR *)"DROP TABLE DTUDT ";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO USE USER-DEFINED DISTINCT TYPES:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create the test table */
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE DTUDT (Col1 UDT1, Col2 UDT2, Col3 UDT3)\n");

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* insert values in the test table */
  printf("\n  Directly execute the statement\n");
  printf("    INSERT INTO DTUDT VALUES\n");
  printf("      VALUES(CAST(77 AS UDT1),\n");
  printf("             CAST('ab' AS UDT2),\n");
  printf("             CAST(111.77 AS UDT3))\n");

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the test table */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt3);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* UDTUse */

/* drop user-defined distinct types by issuing the
   DROP DISTINCT TYPE SQL statement */
int UDTDrop(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)"DROP DISTINCT TYPE UDT1";
  SQLCHAR *stmt2 = (SQLCHAR *)"DROP DISTINCT TYPE UDT2";
  SQLCHAR *stmt3 = (SQLCHAR *)"DROP DISTINCT TYPE UDT3";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO DROP USER-DEFINED DISTINCT TYPES:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* drop UDT1 */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt1);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop UDT2 */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt2);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop UDT3 */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt3);

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* UDTDrop */

