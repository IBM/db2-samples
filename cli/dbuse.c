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
** SOURCE FILE NAME: dbuse.c
**
** SAMPLE: How to use a database
**
**         This sample demonstrates how to execute different types of SQL
**         statements in various ways, including executing compound SQL and
**         binding parameters.  It also shows numerous ways descriptors
**         can be used.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLCopyDesc -- Copy Descriptor Information Between Handles
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetDescField -- Get Single Field Settings of Descriptor Record
**         SQLGetDescRec -- Get Mulitple Field Settings of Descriptor Record
**         SQLGetStmtAttr -- Get Current Setting of a Statement Attribute
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLPrepare -- Prepare a Statement
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetDescField -- Set a Single Field of a Descriptor Record
**         SQLSetDescRec -- Set Multiple Descriptor Fields for a Column
**                          or Parameter Data
**         SQLSetStmtAttr -- Set Options Related to a Statement
**
** OUTPUT FILE: dbuse.out (available in the online documentation)
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

int StmtExecDirect(SQLHANDLE);
int ConnExecTransact(SQLHANDLE);
int StmtBindParam(SQLHANDLE);
int StmtExecute(SQLHANDLE);
int StmtExecCompound(SQLHANDLE);
int DescSetGetRec(SQLHANDLE);
int DescSetGetField(SQLHANDLE);
int DescCopy(SQLHANDLE);
int DropTempTables(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO USE A DATABASE.\n");

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

  /* directly execute SQL statements using SQLExecDirect */
  rc = StmtExecDirect(hdbc);

  /* perform transactions on one connection */
  rc = ConnExecTransact(hdbc);

  /* bind parameters to an SQL statement */
  rc = StmtBindParam(hdbc);

  /* prepare and execute an SQL statement */
  rc = StmtExecute(hdbc);

  /* execute a compound SQL statement */
  rc = StmtExecCompound(hdbc);

  /* using descriptors */
  /* get and set multiple fields of descriptor records */
  rc = DescSetGetRec(hdbc);
  /* get and set a single field of descriptor records */
  rc = DescSetGetField(hdbc);
  /* copy descriptors */
  rc = DescCopy(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* directly execute SQL statements using SQLExecDirect */
int StmtExecDirect(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE table1(col1 INTEGER)";
  SQLCHAR *stmt2 = (SQLCHAR *)"DROP TABLE table1";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO EXECUTE SQL STATEMENTS DIRECTLY:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute %s.\n", stmt1);

  /* directly execute statement 1 */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Directly execute %s.\n", stmt2);

  /* directly execute statement 2 */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* StmtExecDirect */

/* perform transactions on one connection */
int ConnExecTransact(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE table1(col1 INTEGER)";
  SQLCHAR *stmt2 = (SQLCHAR *)"CREATE TABLE table2(col1 INTEGER)";
  SQLCHAR *stmt3 = (SQLCHAR *)"DROP TABLE table1";
  SQLCHAR *stmt4 = (SQLCHAR *)"DROP TABLE table2";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A TRANSACTION ON ONE CONNECTION:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Perform a transaction on this connection\n");

  printf("    executing %s...\n", stmt1);

  /* directly execute statement 1 */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("    executing %s...\n", stmt2);

  /* directly execute statement 2 */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Committing the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction committed.\n");

  printf("\n  Perform another transaction on this connection\n");

  printf("    executing %s...\n", stmt3);

  /* directly execute statement 3 */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* directly execute statement 4 */
  printf("    executing %s...\n", stmt4);
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Committing the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction committed.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* ConnExecTransact */

/* bind parameters to an SQL statement */
int StmtBindParam(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statement to be executed, containing parameter markers */
  SQLCHAR *stmt = (SQLCHAR *)
    "DELETE FROM org WHERE deptnumb = ? AND division = ? ";
  SQLSMALLINT parameter1 = 0;

  char parameter2[20];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO BIND PARAMETERS TO AN SQL STATEMENT:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Bind parameter1 and parameter2 to the statement\n");
  printf("    %s\n", stmt);

  /* bind parameter1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_SHORT,
                           SQL_SMALLINT,
                           0,
                           0,
                           &parameter1,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           20,
                           0,
                           parameter2,
                           20,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement for parameter1 = 15 and parameter2 = 'Eastern' */
  printf("\n  Execute the statement for\n");
  printf("    parameter1 = 15 and parameter2 = 'Eastern'\n");
  parameter1 = 15;
  strcpy(parameter2, "Eastern");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement for parameter1 = 84 and parameter2 = 'Western' */
  printf("\n  Execute the statement for\n");
  printf("    parameter1 = 84 and parameter2 = 'Western'\n");
  parameter1 = 84;
  strcpy(parameter2, "Western");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* StmtBindParam */

/* prepare and execute an SQL statement with bound parameters */
int StmtExecute(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statement to be executed, containing a parameter marker */
  SQLCHAR *stmt = (SQLCHAR *)"DELETE FROM org WHERE deptnumb = ? ";
  SQLSMALLINT parameter1 = 0;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO EXECUTE A PREPARED SQL STATEMENT:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameter1 to the statement\n");
  printf("    %s\n", stmt);

  /* bind parameter1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_SHORT,
                           SQL_SMALLINT,
                           0,
                           0,
                           &parameter1,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement for parameter1 = 15 */
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = 15\n");
  parameter1 = 15;

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement for parameter1 = 84 */
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = 84\n");
  parameter1 = 84;

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* StmtExecute */

/* execute a compound SQL statement */
int StmtExecCompound(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt, compnd_hstmt[4]; /* statement handles */
  /* compound SQL statement to be executed */
  SQLCHAR *compnd_stmt[] =
  {
    (SQLCHAR *)"INSERT INTO awards (id, award) "
      "SELECT id, 'Sales Merit' from staff "
      "WHERE job = 'Sales' AND (comm/100 > years)",

    (SQLCHAR *)"INSERT INTO awards (id, award) "
      "SELECT id, 'Clerk Merit' from staff "
      "WHERE job = 'Clerk' AND (comm/50 > years)",

    (SQLCHAR *)"INSERT INTO awards (id, award) "
      "SELECT id, 'Best ' concat job FROM STAFF "
      "WHERE comm = (SELECT max(comm) FROM staff WHERE job = 'Clerk')",

    (SQLCHAR *)"INSERT INTO awards (id, award) "
      "SELECT id, 'Best ' concat job FROM STAFF "
      "WHERE comm = (SELECT max(comm) FROM STAFF WHERE job = 'Sales')",
  };

  SQLINTEGER i;
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLPrepare\n");
  printf("  SQLExecute\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO EXECUTE A COMPOUND SQL STATEMENT:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute a statement - create the table AWARDS */
  cliRC = SQLExecDirect(hstmt,
                        (SQLCHAR *)
                        "CREATE TABLE AWARDS (ID INTEGER, AWARD CHAR(12))",
                        SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the 4 substatements of the compound SQL statement */
  for (i = 0; i < 4; i++)
  {
    /* allocate a statement handle */
    cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &compnd_hstmt[i]);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    /* prepare a statement */
    cliRC = SQLPrepare(compnd_hstmt[i], compnd_stmt[i], SQL_NTS);
    STMT_HANDLE_CHECK(compnd_hstmt[i], hdbc, cliRC);
  }

  /* begin the COMPOUND statement */
  printf("\n  Directly execute:\n");
  printf("    BEGIN COMPOUND NOT ATOMIC STATIC\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt,
                        (SQLCHAR *)"BEGIN COMPOUND NOT ATOMIC STATIC",
                        SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the 4 sub-statements of the compound SQL statement */
  for (i = 0; i < 4; i++)
  {
    printf("\n  Execute the sub-statement %d\n", i + 1);
    printf("    of the COMPOUND statement\n");

    /* execute the statement */
    cliRC = SQLExecute(compnd_hstmt[i]);
    STMT_HANDLE_CHECK(compnd_hstmt[i], hdbc, cliRC);
  }

  printf("\n  Directly execute:"
         "\n    END COMPOUND COMMIT\n");

  /* directly execute a statement - end the COMPOUND statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)"END COMPOUND COMMIT", SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  for (i = 0; i < 4; i++)
  {
    /* free the statement handles */
    cliRC = SQLFreeHandle(SQL_HANDLE_STMT, compnd_hstmt[i]);
    STMT_HANDLE_CHECK(compnd_hstmt[i], hdbc, cliRC);
  }

  /* directly execute a statement - drop the table AWARDS */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)"DROP TABLE AWARDS", SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* StmtExecCompound */

/* get and set multiple fields of descriptor records */
int DescSetGetRec(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  SQLRETURN rc = 0;
  SQLHANDLE hstmt, hstmt1; 
  SQLHANDLE hIRD, hARD; /* descriptor handles */
  SQLINTEGER indicator;
  SQLSMALLINT i;
  SQLCHAR colname[20];
  SQLSMALLINT namelen;
  SQLSMALLINT type;
  SQLSMALLINT subtype;
  SQLINTEGER width, length, datalen, nameleng;
  SQLSMALLINT precision, scale, nullable;
  SQLSMALLINT num_cols;
  SQLSMALLINT id_no;
  SQLCHAR thename[20];
  struct sqlca sqlca;
  char sp2[] = "  ", sp4[] = "    ";
  /* SQL SELECT statements to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT id,name FROM staff where dept = 10 ";
  SQLCHAR *stmt1 = (SQLCHAR *)"SELECT id,name FROM staff where dept = 10 ";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLGetDescRec\n");
  printf("  SQLSetDescRec\n");
  printf("Other CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLGetStmtAttr\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET AND SET MULTIPLE FIELDS OF DESCRIPTOR RECORDS:\n");

  /* set AUTOCOMMIT on */
  rc = SQLSetConnectAttr(hdbc,
                         SQL_ATTR_AUTOCOMMIT,
                         (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                         SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, rc);

  /* allocate a statement handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, rc);

  /* allocate another statement handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, rc);

  printf("\n%sPrepare the statement\n", sp2);
  printf("%s%s\n", sp4, stmt);

  /* prepare a statement */
  rc = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  /* execute a statement */
  rc = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  /* get the handle for the implicitly allocated descriptor */
  rc = SQLGetStmtAttr(hstmt,
                      SQL_ATTR_IMP_ROW_DESC,
                      &hIRD,
                      SQL_IS_INTEGER,
                      &indicator);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  /* get information for each column in the result set */
  rc = SQLNumResultCols(hstmt, &num_cols);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  printf("\n%sRecord field/Column information within descriptor:\n", sp2);
  for (i = 1; i <= num_cols; i++)
  {
    /* get multiple field settings of the descriptor record */
    rc = SQLGetDescRec(hIRD,
                       i,
                       colname,
                       sizeof(colname),
                       &namelen,
                       &type,
                       &subtype,
                       &width,
                       &precision,
                       &scale,
                       &nullable);
    if (rc == SQL_SUCCESS)
    {
      printf("%sColumn = %d:\n", sp2, i);
      printf("%sName      = %s\n", sp4, colname);
      printf("%sData type = %d\n", sp4, type);
      printf("%sSub type  = %d\n", sp4, subtype);
      printf("%sWidth     = %d\n", sp4, width);
      printf("%sPrecision = %d\n", sp4, precision);
      printf("%sScale     = %d\n", sp4, scale);
      printf("%sNullable  = %d\n", sp4, nullable);
    }
    STMT_HANDLE_CHECK(hstmt, hdbc, rc);
  }

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  strcpy((char *)colname, "Yes");
  type = 0;
  subtype = 0;
  width = 0;
  precision = 0;
  scale = 0;
  nullable = 0;

  /* prepare the statement */
  rc = SQLPrepare(hstmt1, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* get the handle for the implicitly allocated descriptor */
  rc = SQLGetStmtAttr(hstmt1, SQL_ATTR_APP_ROW_DESC, &hARD, 0, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* set record/column values via a descriptor */
  type = SQL_SMALLINT;
  length = 2;

  /* set multiple descriptor fields for a column or parameter data */
  rc = SQLSetDescRec(hARD, 1, type, 0, length, 0, 0, &id_no, &datalen, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  type = SQL_CHAR;
  length = 20;

  /* set multiple descriptor fields for a column or parameter data */
  rc = SQLSetDescRec(hARD,
                     2,
                     type,
                     0,
                     length,
                     0,
                     0,
                     thename,
                     &nameleng,
                     NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  printf("\n%sAfter setting record:\n", sp2);

  /* execute the  statement */
  rc = SQLExecute(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  for (i = 1; i <= num_cols; i++)
  {
    /* get the record/column value after setting */
    rc = SQLGetDescRec(hARD,
                       i,
                       colname,
                       sizeof(colname),
                       &namelen,
                       &type,
                       &subtype,
                       &width,
                       &precision,
                       &scale,
                       &nullable);
    STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

    if (rc == SQL_SUCCESS)
    {
      printf("%sColumn = %d:\n", sp2, i);
      printf("%sName      = %s\n", sp4, colname);
      printf("%sData type = %d\n", sp4, type);
      printf("%sSub type  = %d\n", sp4, subtype);
      printf("%sWidth     = %d\n", sp4, width);
      printf("%sPrecision = %d\n", sp4, precision);
      printf("%sScale     = %d\n", sp4, scale);
      printf("%sNullable  = %d\n", sp4, nullable);
    }
  }

  /* get the result set and print it without using SQLBindCol */
  rc = SQLFetch(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  if (rc == SQL_SUCCESS)
  {
    printf("\n%sResult set after using SetDescRec\n", sp2);
    printf("%s-ID- ---NAME----\n", sp4);
  }
  while (rc == SQL_SUCCESS)
  {
    printf("%s%d  %s\n", sp4, id_no, thename);

    /* fetch next row */
    rc = SQLFetch(hstmt1);
  }
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  return rc;
} /* DescSetGetRec */

/* copy fields of a source descriptor to a target descriptor */
int DescCopy(SQLHANDLE hdbc)
{
  SQLRETURN rc = SQL_SUCCESS;
  SQLRETURN rc2 = SQL_SUCCESS;
  SQLHANDLE hstmt1, hstmt2;
  SQLHANDLE hARD, hAPD, hIRD, hIPD; /* descriptor handles */
  SQLCHAR *stmt1 = (SQLCHAR *) 
    "CREATE TABLE DESCTABLE (SOURCE_COL1 char(10), SOURCE_COL2 integer)";
  SQLCHAR *stmt2 = (SQLCHAR *)
    "CREATE TABLE DESCTABLECOPY (TARGET_COL1 char(10), TARGET_COL2 integer)";
  SQLCHAR *stmt3 = (SQLCHAR *) "INSERT INTO DESCTABLE VALUES ('column 1', 1)";
  SQLCHAR *stmt4 = (SQLCHAR *) "INSERT INTO DESCTABLE VALUES ('column 2', 2)";
  SQLCHAR *stmt5 = (SQLCHAR *) "SELECT * FROM DESCTABLE";
  SQLCHAR *stmt6 = (SQLCHAR *) "INSERT INTO DESCTABLECOPY VALUES (?,?)";
  SQLCHAR *stmt7 = (SQLCHAR *) "SELECT * FROM DESCTABLECOPY";
  SQLCHAR sourcecol1[11], targetcol1[11];
  SQLINTEGER sourcecol2, targetcol2;
  SQLINTEGER indicator;
  SQLINTEGER rowCount = 0;
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLCopyDesc\n");
  printf("Other CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLGetStmtAttr\n");
  printf("  SQLPrepare\n");
  printf("  SQLExecute\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO COPY DESCRIPTORS:\n");

  /* set AUTOCOMMIT on */
  rc = SQLSetConnectAttr(hdbc,
                         SQL_ATTR_AUTOCOMMIT,
                         (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                         SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, rc);

  /* allocate a statement handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, rc);

  /* allocate a statement handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  DBC_HANDLE_CHECK(hdbc, rc);
  
  /* create a temporary source table to copy from */
  rc = SQLExecDirect(hstmt1, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("\n  Create source table DESCTABLE to copy from:\n");
  printf("    CREATE TABLE DESCTABLE ");
  printf("(SOURCE_COL1 char(10), SOURCE_COL2 integer)\n");

  /* create a temporary target table to copy into from the source table */
  rc = SQLExecDirect(hstmt2, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  printf("\n  Create target table DESCTABLECOPY to copy into from ");
  printf("source DESCTABLE:\n");
  printf("    CREATE TABLE DESCTABLECOPY ");
  printf("(TARGET_COL1 char(10), TARGET_COL2 integer)\n");
  
  /* insert 2 rows of data into the source table */
  rc = SQLExecDirect(hstmt1, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("\n  Insert the following row into the source table DESCTABLE:\n");
  printf("    SOURCE_COL1: column 1     SOURCE_COL2: 1\n");
  
  rc = SQLExecDirect(hstmt1, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("\n  Insert the following row into the source table DESCTABLE:\n");
  printf("    SOURCE_COL1: column 2     SOURCE_COL2: 2\n");
  
  /* select the rows from the source table */
  rc = SQLExecDirect(hstmt1, stmt5, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  
  /* bind the columns of the source table */
  SQLBindCol(hstmt1, 1, SQL_C_CHAR, sourcecol1, 11, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  
  SQLBindCol(hstmt1, 2, SQL_C_LONG, &sourcecol2, 0, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* get the ARD of the source */
  rc = SQLGetStmtAttr(hstmt1,
		      SQL_ATTR_APP_ROW_DESC,
		      &hARD,
		      SQL_IS_INTEGER,
		      &indicator);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  /* get the IRD of the source */
  rc = SQLGetStmtAttr(hstmt1,
		      SQL_ATTR_IMP_ROW_DESC,
		      &hIRD,
		      SQL_IS_INTEGER,
		      &indicator);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  
  /* explicitly allocate an application descriptor */
  rc = SQLAllocHandle(SQL_HANDLE_DESC, hdbc, &hAPD);
  DBC_HANDLE_CHECK(hdbc, rc);
  
  /* get reference to implicit IPD on hstmt2 */
  rc = SQLGetStmtAttr(hstmt2,
		      SQL_ATTR_IMP_PARAM_DESC,
		      &hIPD,
		      SQL_IS_INTEGER,
		      &indicator);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* copy source ARD to target APD */
  rc = SQLCopyDesc(hARD, hAPD);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("\n  Copy the source ARD to the target APD.\n");

  /* copy source IRD to target IPD */
  rc = SQLCopyDesc(hIRD, hIPD);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("  Copy the source IRD to the target IPD.\n");

  rc = SQLPrepare(hstmt2, stmt6, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);

  /* override hstmt2's implicit APD with
     the explicitly allocated application descriptor */
  rc = SQLSetStmtAttr(hstmt2,
		      SQL_ATTR_APP_PARAM_DESC,
		      (SQLPOINTER)hAPD,
		      SQL_IS_POINTER);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  printf("\n  Override the implicit APD with the explicitly allocated \n");
  printf("    application descriptor.\n");
  
  /* fetch rows from the source table and insert into the target table */
  rc = SQLFetch(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("\n  Fetch the rows from the source table:\n");
  printf("    SELECT * FROM DESCTABLE\n");
  printf("  And insert into the target table:\n");
  printf("    INSERT INTO DESCTABLECOPY VALUES (?,?)\n");
  while (rc == SQL_SUCCESS && rc2 == SQL_SUCCESS)
  {
    printf("\n    SOURCE_COL1: %s     SOURCE_COL2: %d\n",
           sourcecol1, sourcecol2);
    
    /* insert the row from the source table into the target table */
    rc2 = SQLExecute(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, rc2);
    rc = SQLFetch(hstmt1);
  }

  /* bind the columns for the target table */
  SQLBindCol(hstmt2, 1, SQL_C_CHAR, targetcol1, 11, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  SQLBindCol(hstmt2, 2, SQL_C_LONG, &targetcol2, 0, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);

  /* select the rows from the target table */
  rc = SQLExecDirect(hstmt2, stmt7, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  printf("\n  Select the rows now in the target table:\n");
  printf("    SELECT * FROM DESCTABLECOPY\n");
  
  /* fetch the rows from the target table */
  rc = SQLFetch(hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  while (rc == 0)
  {
    printf("\n    TARGET_COL1: %s     TARGET_COL2: %d\n",
	   targetcol1, targetcol2);
    rc = SQLFetch(hstmt2);
  }
  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, rc);

  /* drop temporary tables */
  rc = DropTempTables(hdbc);
  
  SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);

  return rc;
} /* DescCopy */

/* helper function that drops the temporary tables
   used by the DescCopy function */
int DropTempTables (SQLHANDLE hdbc)
{
  SQLRETURN rc = 0;
  SQLHANDLE hstmt1, hstmt2;
  SQLCHAR *stmt1 = (SQLCHAR *) "DROP TABLE DESCTABLE";
  SQLCHAR *stmt2 = (SQLCHAR *) "DROP TABLE DESCTABLECOPY";

  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, rc);
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  DBC_HANDLE_CHECK(hdbc, rc);

  /* drop desctable */
  rc = SQLExecDirect(hstmt1, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  printf("\n  Drop the source table DESCTABLE.\n");

  /* drop desctablecopy */
  rc = SQLExecDirect(hstmt2, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  printf("\n  Drop the target table DESCTABLECOPY.\n");

  SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);
  SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, rc);
  
  return rc;
} /* DropTempTables */

/* get and set a single field of descriptor records */
int DescSetGetField(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  SQLRETURN rc = 0;
  SQLHANDLE hstmt, hstmt1;
  SQLHANDLE hIPD, hIRD, hIRD1, hARD; /* descriptor handles */
  SQLSMALLINT descFieldAllocType;
  SQLSMALLINT descFieldParameterType;
  /* SQL SELECT statements to be executed */
  SQLCHAR *stmt = (SQLCHAR *)
    "SELECT deptnumb, location FROM org WHERE division = ?";
  SQLCHAR *stmt1 = (SQLCHAR *)
    "SELECT deptnumb,location FROM org WHERE division = 'Western'";
  char divisionParam[15];

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  deptnumb; /* variable to be bound to the DEPTNUMB column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  location; /* variable to be bound to the LOCATION column */

  static char ALLOCTYPES[][21] =
  {
    "- No 0 Value-",
    "SQL_DESC_ALLOC_AUTO",
    "SQL_DESC_ALLOC_USER"
  };

  static char PARAMTYPE[][24] =
  {
    "- No 0 Value-",
    "SQL_PARAM_INPUT",
    "SQL_PARAM_INPUT_OUTPUT",
    "- No 3 Value -",
    "SQL_PARAM_OUTPUT"
  };

  int colCount;
  SQLCHAR descFieldTypeName[25];
  SQLCHAR descFieldLabel[25];
  SQLSMALLINT dept_no;
  char loc[15];
  char sp2[] = "  ", sp4[] = "    ";
  SQLINTEGER indicator;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLGetDescField\n");
  printf("  SQLSetDescField\n");
  printf("Other CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLGetStmtAttr\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET AND SET A SINGLE FIELD OF DESCRIPTOR RECORDS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate another statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* get the handle for the implicitly allocated descriptor */
  cliRC = SQLGetStmtAttr(hstmt,
                         SQL_ATTR_IMP_PARAM_DESC,
                         &hIPD,
                         SQL_IS_POINTER,
                         NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* see how the header field SQL_DESC_ALLOC_TYPE is set */
  cliRC = SQLGetDescField(hIPD,
                          0, /* ignored for header fields */
                          SQL_DESC_ALLOC_TYPE,
                          &descFieldAllocType, /* result */
                          SQL_IS_SMALLINT,
                          NULL); /* ignored */
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* print the descriptor information */
  printf("\n  The IPD header descriptor field\n");
  printf("    SQL_DESC_ALLOC_TYPE is %s\n", ALLOCTYPES[descFieldAllocType]);

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt);

  /* prepare a statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind divisionParam to the statement\n");
  printf("    %s\n", stmt);

  /* bind divisionParam to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           15,
                           0,
                           divisionParam,
                           15,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* see how the field SQL_DESC_PARAMETER_TYPE is set */
  cliRC = SQLGetDescField(hIPD,
                          1, /* look at the parameter */
                          SQL_DESC_PARAMETER_TYPE,
                          &descFieldParameterType, /* result */
                          SQL_IS_SMALLINT,
                          NULL); /* ignored */
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* print the descriptor information */
  printf("\n  The IPD record descriptor field\n");
  printf("    SQL_DESC_PARAMETER_TYPE is %s\n",
         PARAMTYPE[descFieldParameterType]);

  /* execute the statement for divisionParam = Eastern */
  printf("\n  Execute the prepared statement for\n");
  printf("    divisionParam = 'Eastern'\n");
  strcpy(divisionParam, "Eastern");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column DEPTNUMB to deptnumb variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_SHORT, &deptnumb.val, 0, &deptnumb.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column LOCATION to location variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, location.val, 15, &location.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row, and display */
  printf("\n  Fetch each row and display.\n");
  printf("    DEPTNUMB LOCATION     \n");
  printf("    -------- -------------\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-8d %-14.14s\n", deptnumb.val, location.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* get the handle for the implicitly allocated descriptor */
  cliRC = SQLGetStmtAttr(hstmt,
                         SQL_ATTR_IMP_ROW_DESC,
                         &hIRD,
                         SQL_IS_POINTER,
                         NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* print out some implementation row descriptor fields
     from the last SQLFetch call above */
  for (colCount = 1; colCount <= 2; colCount++)
  {
    printf("\n  Information for column %i\n", colCount);

    /* see how the descriptor record field SQL_DESC_TYPE_NAME is set */
    rc = SQLGetDescField(hIRD,
                         (SQLSMALLINT)colCount,
                         SQL_DESC_TYPE_NAME, /* record field */
                         descFieldTypeName, /* result */
                         25,
                         NULL); /* ignored */
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("    IRD record descriptor field\n");
    printf("      SQL_DESC_TYPE_NAME is %s\n", descFieldTypeName);

    /* see how the descriptor record field SQL_DESC_LABEL is set */
    rc = SQLGetDescField(hIRD,
                         (SQLSMALLINT)colCount,
                         SQL_DESC_LABEL, /* record field */
                         descFieldLabel, /* result */
                         25,
                         NULL); /* ignored */
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("    IRD record descriptor field\n");
    printf("      SQL_DESC_LABEL is %s\n", descFieldLabel);

  }
  printf("\n%sPrepare the statement\n", sp2);
  printf("%s%s\n", sp4, stmt1);

  /* prepare a statement */
  cliRC = SQLPrepare(hstmt1, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* get the handle for the implicitly allocated descriptor */
  cliRC = SQLGetStmtAttr(hstmt1,
                         SQL_ATTR_APP_ROW_DESC,
                         &hARD,
                         SQL_IS_INTEGER,
                         &indicator);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column to variables */
  cliRC = SQLBindCol(hstmt1, 2, SQL_C_CHAR, location.val, 15, &indicator);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* set a single field of a descriptor record */
  rc = SQLSetDescField(hARD,
                       1,
                       SQL_DESC_TYPE,
                       (SQLPOINTER)SQL_SMALLINT,
                       SQL_IS_SMALLINT);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* set a single field of a descriptor record */
  rc = SQLSetDescField(hARD,
                       1,
                       SQL_DESC_DATA_PTR,
                       &dept_no, /* value set to the field */
                       SQL_IS_SMALLINT);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* set a single field of a descriptor record */
  rc = SQLSetDescField(hARD,
                       2,
                       SQL_DESC_TYPE,
                       (SQLPOINTER)SQL_CHAR,
                       SQL_IS_SMALLINT);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* set a single field of a descriptor record */
  rc = SQLSetDescField(hARD,
                       2,
                       SQL_DESC_LENGTH,
                       (SQLPOINTER)15,
                       SQL_IS_INTEGER);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* set a single field of a descriptor record */
  rc = SQLSetDescField(hARD, 2, SQL_DESC_DATA_PTR, (SQLPOINTER)loc, 15);
  STMT_HANDLE_CHECK(hstmt1, hdbc, rc);

  /* fetch each row, and display */
  printf("\n%sFetch rows and display after using SetDescField.\n", sp2);
  printf("%sDEPTNUMB LOCATION     \n", sp4);
  printf("%s-------- -------------\n", sp4);

  /* fetch next row */
  cliRC = SQLFetch(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  if (cliRC == SQL_SUCCESS_WITH_INFO)
  {
    printf("\n  SUCCESS_WITH_INFO\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("%s%-8d %s\n", sp4, dept_no, loc);

    /* fetch next row */
    cliRC = SQLFetch(hstmt1);
  }
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free another statement1 handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DescSetGetField */

