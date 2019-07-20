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
** SOURCE FILE NAME: tbmod.c                                     
**                                                                        
** SAMPLE: How to modify table data
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetCursorName -- Get Cursor Name
**         SQLPrepare -- Prepare a Statement
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetStmtAttr -- Set Options Related to a Statement
**
** OUTPUT FILE: tbmod.out (available in the online documentation)
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
#include <sqlca.h>

/* methods to perform INSERT */
int TbBasicInsert(SQLHANDLE);
int TbInsertWithParam(SQLHANDLE);

/* methods to perform UPDATE */
int TbBasicUpdate(SQLHANDLE);
int TbUpdateWithParam(SQLHANDLE);
int TbPositionedUpdateUsingCursor(SQLHANDLE);

/* methods to perform DELETE */
int TbBasicDelete(SQLHANDLE);
int TbDeleteWithParam(SQLHANDLE);
int TbPositionedDeleteUsingCursor(SQLHANDLE);

/* types of insert */
int TbStaticInsertUsingValues(SQLHANDLE);
int TbStaticInsertUsingFullselect(SQLHANDLE);

/* types of update */
int TbStaticUpdateWithoutSubqueries(SQLHANDLE);
int TbStaticUpdateUsingSubqueryInSetClause(SQLHANDLE);
int TbStaticUpdateUsingSubqueryInWhereClause(SQLHANDLE);
int TbStaticUpdateUsingCorrelatedSubqueryInSetClause(SQLHANDLE);
int TbStaticUpdateUsingCorrelatedSubqueryInWhereClause(SQLHANDLE);
int TbStaticPositionedUpdateWithoutSubqueries(SQLHANDLE);
int TbStaticPositionedUpdateUsingSubqueryInSetClause(SQLHANDLE);
int TbStaticPositionedUpdateUsingCorrelatedSubqueryInSetClause(SQLHANDLE);

/* types of delete */
int TbStaticDeleteWithoutSubqueries(SQLHANDLE);
int TbStaticDeleteUsingSubqueryInWhereClause(SQLHANDLE);
int TbStaticDeleteUsingCorrelatedSubqueryInWhereClause(SQLHANDLE);
int TbStaticPositionedDelete(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO MODIFY TABLE DATA.\n");

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

  /* methods to perform INSERT */
  rc = TbBasicInsert(hdbc);
  rc = TbInsertWithParam(hdbc);

  /* methods to perform UPDATE */
  rc = TbBasicUpdate(hdbc);
  rc = TbUpdateWithParam(hdbc);
  rc = TbPositionedUpdateUsingCursor(hdbc);

  /* methods to perform DELETE */
  rc = TbBasicDelete(hdbc);
  rc = TbDeleteWithParam(hdbc);
  rc = TbPositionedDeleteUsingCursor(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* perform a basic INSERT operation */
int TbBasicInsert(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  /* SQL INSERT statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)
    "INSERT INTO org(deptnumb, location) "
    "  VALUES(120, 'Toronto'), (130, 'Vancouver'), (140, 'Ottawa')";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A BASIC INSERT:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    INSERT INTO org(deptnumb, location)\n");
  printf("      VALUES(120, 'Toronto'),\n");
  printf("            (130, 'Vancouver'),\n");
  printf("            (140, 'Ottawa')\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbBasicInsert */

/* perform an INSERT operation with an SQL statement 
   that contains parameter markers */
int TbInsertWithParam(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL INSERT statement with parameter markers to be executed */
  SQLCHAR *stmt = (SQLCHAR *)
    "INSERT INTO org(deptnumb, location) VALUES(?, ?)";
  SQLSMALLINT parameter1[] = { 120, 130, 140 };
  char parameter2[][20] = { "Toronto", "Vancouver", "Ottawa" };
  int row_array_size = 3;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLSetStmtAttr\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO EXECUTE AN INSERT STATEMENT\n");
  printf("WITH PARAMETERS:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    INSERT INTO org(deptnumb, location) VALUES(?, ?)\n");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Set the statement attribute SQL_ATTR_PARAMSET_SIZE\n");
  printf("    to the number of rows to be processed: 3\n");
  
  /* set the number of rows to be processed */
  cliRC = SQLSetStmtAttr(hstmt,
		         SQL_ATTR_PARAMSET_SIZE,
			 (SQLPOINTER) row_array_size,
			 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameter1 and parameter2 to the statement.\n");

  /* bind parameter1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_SHORT,
                           SQL_SMALLINT,
                           0,
                           0,
                           parameter1,
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

  /* execute the statement for a set of values */
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = { 120, 130, 140 }\n");
  printf("    parameter2 = { 'Toronto', 'Vancouver', 'Ottawa' }\n");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbInsertWithParam */

/* perform a basic UDPATE operation */
int TbBasicUpdate(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL UPDATE statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)
    "UPDATE org SET location = 'Toronto' WHERE deptnumb < 50";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A BASIC UPDATE:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    UPDATE org SET location = 'Toronto' WHERE deptnumb < 50\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbBasicUpdate */

/* perform an UPDATE operation with an SQL statement 
   that contains parameter markers */
int TbUpdateWithParam(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL UPDATE statement with parameter markers to be executed */
  SQLCHAR *stmt = (SQLCHAR *)
    "UPDATE org SET location =  ? WHERE deptnumb < ?";
  SQLCHAR parameter1[20];
  SQLSMALLINT parameter2;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO EXECUTE AN UPDATE STATEMENT\n");
  printf("WITH PARAMETERS:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    UPDATE org SET location = ? WHERE deptnumb < ?\n");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameter1 and parameter2 to the statement.\n");

  /* bind parameter1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           20,
                           0,
                           parameter1,
                           20,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_SHORT,
                           SQL_SMALLINT,
                           0,
                           0,
                           &parameter2,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement for a set of values  */
  strcpy((char *)parameter1, "Toronto");
  parameter2 = 50;

  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = %s\n", parameter1);
  printf("    parameter2 = %d\n", parameter2);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbUpdateWithParam */

/* perform a positioned UPDATE operation using cursors */
int TbPositionedUpdateUsingCursor(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmtSelect;
  SQLHANDLE hstmtPositionedUpdate;
  /* SQL SELECT statement to be executed */
  SQLCHAR *stmtSelect = (SQLCHAR *)
    "SELECT * FROM org WHERE deptnumb < 50 FOR UPDATE";
  SQLCHAR stmtPositionedUpdate[200];
  SQLCHAR cursorName[20];
  SQLSMALLINT cursorLen;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLSetCursorName\n");
  printf("  SQLGetCursorName\n");
  printf("  SQLFetch\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO EXECUTE A POSITIONED UPDATE STATEMENT\n");
  printf("USING CURSORS:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate SELECT statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtSelect);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate positioned UPDATE statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtPositionedUpdate);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute\n");
  printf("    %s\n", stmtSelect);

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmtSelect, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* set the name of the cursor */
  rc = SQLSetCursorName(hstmtSelect, (SQLCHAR *)"CURSNAME", SQL_NTS);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* get the cursor name of the SELECT statement */
  cliRC = SQLGetCursorName(hstmtSelect, cursorName, 20, &cursorLen);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  printf("\n  Fetch each row and update it.\n");

  /* fetch each row and update it */
  cliRC = SQLFetch(hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* SQL UPDATE statement that will update the rows */
    sprintf((char *)stmtPositionedUpdate,
            "UPDATE org SET location = 'Toronto' WHERE CURRENT of %s",
            cursorName);

    /* directly execute the statement */
    cliRC = SQLExecDirect(hstmtPositionedUpdate,
                          stmtPositionedUpdate,
                          SQL_NTS);
    STMT_HANDLE_CHECK(hstmtPositionedUpdate, hdbc, cliRC);

    printf("    Row fetched and updated.\n");

    /* fetch next row */
    cliRC = SQLFetch(hstmtSelect);
    STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);
  }

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the SELECT statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* free the positioned UPDATE statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtPositionedUpdate);
  STMT_HANDLE_CHECK(hstmtPositionedUpdate, hdbc, cliRC);

  return rc;
} /* TbPositionedUpdateUsingCursor */

/* perform a basic DELETE operation */
int TbBasicDelete(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL DELETE statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"DELETE FROM org WHERE deptnumb < 50";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A BASIC DELETE:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbBasicDelete */

/* perform a DELETE operation with an SQL statement 
   that contains parameter markers */
int TbDeleteWithParam(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL DELETE statement with parameter markers to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"DELETE FROM org WHERE deptnumb < ?";
  SQLSMALLINT parameter1;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO EXECUTE A DELETE STATEMENT\n");
  printf("WITH PARAMETERS:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameter1 to the statement.\n");

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

  /* execute the statement for parameter1 = 50  */
  parameter1 = 50;
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = %d\n", parameter1);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbDeleteWithParam */

/* perform a positioned DELETE operation using cursors */
int TbPositionedDeleteUsingCursor(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmtSelect;
  SQLHANDLE hstmtPositionedDelete;
  /* SQL SELECT statement to be executed */
  SQLCHAR *stmtSelect = (SQLCHAR *)
    "SELECT * FROM org WHERE deptnumb < 50 FOR UPDATE";
  SQLCHAR stmtPositionedDelete[200];
  SQLCHAR cursorName[20];
  SQLSMALLINT cursorLen;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLGetCursorName\n");
  printf("  SQLFetch\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO EXECUTE A POSITIONED DELETE STATEMENT\n");
  printf("USING CURSORS:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate the SELECT statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtSelect);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate the positioned DELETE statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtPositionedDelete);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute\n");
  printf("    %s\n", stmtSelect);

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmtSelect, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* get the cursor name of the SELECT statement */
  cliRC = SQLGetCursorName(hstmtSelect, cursorName, 20, &cursorLen);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  printf("\n  Fetch each row and delete it.\n");

  /* fetch each row and delete it */
  cliRC = SQLFetch(hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* SQL DELETE statement that will DELETE the rows */
    sprintf((char *)stmtPositionedDelete,
            "DELETE FROM org WHERE CURRENT of %s", cursorName);

    /* directly execute the statement */
    cliRC = SQLExecDirect(hstmtPositionedDelete,
                          stmtPositionedDelete,
                          SQL_NTS);
    STMT_HANDLE_CHECK(hstmtPositionedDelete, hdbc, cliRC);

    printf("    Row fetched and deleted.\n");

    /* fetch next row */
    cliRC = SQLFetch(hstmtSelect);
    STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);
  }

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the SELECT statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* free the positioned DELETE statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtPositionedDelete);
  STMT_HANDLE_CHECK(hstmtPositionedDelete, hdbc, cliRC);

  return rc;
} /* TbPositionedDeleteUsingCursor */

