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
** SOURCE FILE NAME: tbconstr.c                                       
**                                                                        
** SAMPLE: How to create, use and drop constraints associated with tables
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLForeignKeys -- Get the List of Foreign Key Columns
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrimaryKeys -- Get Primary Key Columns of a Table
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSpecialColumns -- Get Special (Row Identifier) Columns
**         SQLStatistics -- Get Index and Statistics Information
**                          for a Base Table
**
** OUTPUT FILE: tbconstr.out (available in the online documentation)
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

int CnDefine(SQLHANDLE);
int CnListPrimaryKeys(SQLHANDLE);
int CnListForeignKeys(SQLHANDLE);
int CnListSpecialColumns(SQLHANDLE);
int CnListIndexColumns(SQLHANDLE);
int CnCleanUp(SQLHANDLE);
int Cn_NOT_NULL_Show(SQLHANDLE);
int Cn_UNIQUE_Show(SQLHANDLE);
int Cn_PRIMARY_KEY_Show(SQLHANDLE);
int Cn_CHECK_Show(SQLHANDLE);
int Cn_CHECK_INFO_Show(SQLHANDLE);
int Cn_WITH_DEFAULT_Show(SQLHANDLE);
int Cn_FK_OnInsertShow(SQLHANDLE);
int Cn_FK_ON_UPDATE_NO_ACTION_Show(SQLHANDLE);
int Cn_FK_ON_UPDATE_RESTRICT_Show(SQLHANDLE);
int Cn_FK_ON_DELETE_CASCADE_Show(SQLHANDLE);
int Cn_FK_ON_DELETE_SET_NULL_Show(SQLHANDLE);
int Cn_FK_ON_DELETE_NO_ACTION_Show(SQLHANDLE);
int Cn_FK_ON_DELETE_RESTRICT_Show(SQLHANDLE);

/* support functions */
int FK_TwoTablesCreate(SQLHANDLE);
int FK_TwoTablesDisplay(SQLHANDLE);
int FK_TwoTablesDrop(SQLHANDLE);
int FK_Create(SQLHANDLE, char *);
int FK_Drop(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO WORK WITH CONSTRAINTS.\n");

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias, user, pswd, &henv, &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_ON);
  if (rc != 0)
  {
    return rc;
  }

  /* create tables that have constraints */
  rc = CnDefine(hdbc);

  /* list the primary keys of a specified table */
  rc = CnListPrimaryKeys(hdbc);

  /* list the foreign keys for a specified table */
  rc = CnListForeignKeys(hdbc);

  /* list the special (row identifier) columns for a specified table */
  rc = CnListSpecialColumns(hdbc);

  /* list the index columns for a specified table */
  rc = CnListIndexColumns(hdbc);

  /* clean up the tables created in CnDefine */
  rc = CnCleanUp(hdbc);

  /* show a NOT NULL constraint */
  rc = Cn_NOT_NULL_Show(hdbc);

  /* show a UNIQUE constraint */
  rc = Cn_UNIQUE_Show(hdbc);

  /* show a PRIMARY KEY constraint */
  rc = Cn_PRIMARY_KEY_Show(hdbc);

  /* show a CHECK constraint */
  rc = Cn_CHECK_Show(hdbc);

  /* show INFORMATIONAL constraint */ 
  rc = Cn_CHECK_INFO_Show(hdbc);

  /* show a 'WITH DEFAULT' constraint */
  rc = Cn_WITH_DEFAULT_Show(hdbc);

  printf("\n#####################################################\n"
         "#    Create tables for FOREIGN KEY sample functions #\n"
         "#####################################################\n");
  
  /* create tables for FOREIGN KEY sample functions  */
  rc = FK_TwoTablesCreate(hdbc);

  /* show how a FOREIGN KEY works on insert */
  rc = Cn_FK_OnInsertShow(hdbc);

  /* show 'ON UPDATE NO ACTION' foreign key constraint */
  rc = Cn_FK_ON_UPDATE_NO_ACTION_Show(hdbc);

  /* show 'ON UPDATE RESTRICT' foreign key constraint */
  rc = Cn_FK_ON_UPDATE_RESTRICT_Show(hdbc);

  /* show an 'ON DELETE CASCADE' foreign key constraint */
  rc = Cn_FK_ON_DELETE_CASCADE_Show(hdbc);

  /* show an 'ON DELETE SET NULL' foreign key constraint */
  rc = Cn_FK_ON_DELETE_SET_NULL_Show(hdbc);

  /* show an 'ON DELETE NO ACTION' foreign key constraint */
  rc = Cn_FK_ON_DELETE_NO_ACTION_Show(hdbc);
  
  printf("\n########################################################\n"
         "# Drop tables created for FOREIGN KEY sample functions #\n"
         "########################################################\n");

  /* drop tables created for FOREIGN KEY sample functions */
  rc = FK_TwoTablesDrop(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* create tables that have constraints */
int CnDefine(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL CREATE TABLE statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)
    "CREATE TABLE sch.dept(deptno CHAR(3) NOT NULL PRIMARY KEY, "
    "                      deptname VARCHAR(32))";

  SQLCHAR *stmt2 = (SQLCHAR *)
    "CREATE TABLE sch.emp(empno CHAR(7) NOT NULL PRIMARY KEY, "
    "                     deptno CHAR(3) NOT NULL, "
    "                     sex CHAR(1) WITH DEFAULT 'M', "
    "                     salary DECIMAL(7,2) WITH DEFAULT, "
    "  CONSTRAINT check1 CHECK(sex IN('M', 'F')), "
    "  CONSTRAINT check2 CHECK(salary < 70000.00), "
    "  CONSTRAINT fk1 FOREIGN KEY (deptno) REFERENCES sch.dept(deptno))";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CREATE TABLES WITH CONSTRAINTS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create the first table */
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE sch.dept(");
  printf("deptno CHAR(3) NOT NULL PRIMARY KEY,\n");
  printf("                          deptname VARCHAR(32))\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* create the second table */
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE sch.emp(");
  printf("empno CHAR(7) NOT NULL PRIMARY KEY,\n");
  printf("                         ");
  printf("deptno CHAR(3) NOT NULL,\n");
  printf("                         ");
  printf("sex CHAR(1) WITH DEFAULT 'M',\n");
  printf("                         ");
  printf("salary DECIMAL(7,2) WITH DEFAULT,\n");
  printf("      CONSTRAINT check1 CHECK(sex IN('M', 'F')),\n");
  printf("      CONSTRAINT check2 CHECK(salary < 70000.00),\n");
  printf("      CONSTRAINT fk1 ");
  printf("FOREIGN KEY (deptno) REFERENCES sch.dept(deptno))\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CnDefine */

/* drop the tables created in the CnDefine function */
int CnCleanUp(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL DROP statements to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)"DROP TABLE sch.dept";
  SQLCHAR *stmt2 = (SQLCHAR *)"DROP TABLE sch.emp";

  printf("\nDrop the tables created in CnDefine.\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* drop the first table */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the second table */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CnCleanUp */

/* list the primary keys of a specified table */
int CnListPrimaryKeys(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* specifications of the table to look for */
  SQLCHAR tbSchema[] = "SCH";
  SQLCHAR tbName[] = "DEPT";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  pkColumnName, pkName;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  pkColumnPos;

  SQLINTEGER rowNb = 0;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrimaryKeys\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO LIST THE PRIMARY KEYS FOR A SPECIFIED TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLPrimaryKeys */
  printf("\n  Call SQLPrimaryKeys for the table %s.%s\n",
         tbSchema, tbName);

  /* get the primary key columns of a table */
  cliRC = SQLPrimaryKeys(hstmt, NULL, 0, tbSchema, SQL_NTS, tbName, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt,
                     4,
                     SQL_C_CHAR,
                     (SQLPOINTER)pkColumnName.val,
                     129,
                     &pkColumnName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt,
                     5,
                     SQL_C_SHORT,
                     (SQLPOINTER)&pkColumnPos.val,
                     0,
                     &pkColumnPos.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt,
                     6,
                     SQL_C_CHAR,
                     (SQLPOINTER)pkName.val,
                     129,
                     &pkName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row, and display */
  printf("\n  Fetch each row and display.\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\nData not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    rowNb = rowNb + 1;
    printf("  ------- row number %lu --------\n", rowNb);
    printf("  Primary Key Name: %s\n", pkName.val);
    printf("  Primary Key Column Name: %s\n", pkColumnName.val);
    printf("  Primary Key Column Position: %d\n", pkColumnPos.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CnListPrimaryKeys */

/* list the foreign keys for a specified table */
int CnListForeignKeys(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* specifications of the table to look for */
  SQLCHAR tbSchema[] = "SCH";
  SQLCHAR tbName[] = "DEPT";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  pkTableSch, pkTableName, pkColumnName, pkName;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  fkTableSch, fkTableName, fkColumnName, fkName;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  deleteRule, updateRule;

  SQLINTEGER rowNb = 0;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLForeignKeys\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO LIST THE FOREIGN KEYS FOR A SPECIFIED TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLForeignKeys */
  printf("\n  Call SQLForeignKeys for the table %s.%s\n",
         tbSchema, tbName);

  /* get the list of foreign key columns */
  cliRC = SQLForeignKeys(hstmt,
                         NULL,
                         0,
                         tbSchema,
                         SQL_NTS,
                         tbName,
                         SQL_NTS,
                         NULL,
                         0,
                         NULL,
                         SQL_NTS,
                         NULL,
                         SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt,
                     2,
                     SQL_C_CHAR,
                     (SQLPOINTER)pkTableSch.val,
                     129,
                     &pkTableSch.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_CHAR,
                     (SQLPOINTER)pkTableName.val,
                     129,
                     &pkTableName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt,
                     4,
                     SQL_C_CHAR,
                     (SQLPOINTER)pkColumnName.val,
                     129,
                     &pkColumnName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt,
                     6,
                     SQL_C_CHAR,
                     (SQLPOINTER)fkTableSch.val,
                     129,
                     &fkTableSch.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_CHAR,
                     (SQLPOINTER)fkTableName.val,
                     129,
                     &fkTableName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 8 to variable */
  cliRC = SQLBindCol(hstmt,
                     8,
                     SQL_C_CHAR,
                     (SQLPOINTER)fkColumnName.val,
                     129,
                     &fkColumnName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 10 to variable */
  cliRC = SQLBindCol(hstmt,
                     10,
                     SQL_C_SHORT,
                     (SQLPOINTER)&updateRule.val,
                     0,
                     &updateRule.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 11 to variable */
  cliRC = SQLBindCol(hstmt,
                     11,
                     SQL_C_SHORT,
                     (SQLPOINTER)&deleteRule.val,
                     0,
                     &deleteRule.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 12 to variable */
  cliRC = SQLBindCol(hstmt,
                     12,
                     SQL_C_CHAR,
                     (SQLPOINTER)fkName.val,
                     129,
                     &fkName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 13 to variable */
  cliRC = SQLBindCol(hstmt,
                     13,
                     SQL_C_CHAR,
                     (SQLPOINTER)pkName.val,
                     129,
                     &pkName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Fetch each row and display.\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    rowNb = rowNb + 1;
    printf("  ------- row number %lu --------\n", rowNb);
    printf("  Foreign Key Name: %s\n", fkName.val);
    printf("  Primary Key Name: %s\n", pkName.val);
    printf("  Foreign Key Column: %s.%s.%s\n",
           fkTableSch.val, fkTableName.val, fkColumnName.val);
    printf("  Primary Key Column: %s.%s.%s\n",
           pkTableSch.val, pkTableName.val, pkColumnName.val);

    printf("  Update Rule: ");
    switch (updateRule.val)
    {
      case SQL_RESTRICT:
        printf("RESTRICT\n"); /* always for IBM DBMSs */
        break;
      case SQL_CASCADE:
        printf("CASCADE\n"); /* non-IBM only */
        break;
      default:
        printf("SET NULL\n");
        break;
    }

    printf("  Delete Rule: ");
    switch (deleteRule.val)
    {
      case SQL_RESTRICT:
        printf("RESTRICT\n"); /* always for IBM DBMSs */
        break;
      case SQL_CASCADE:
        printf("CASCADE\n"); /* non-IBM only */
        break;
      case SQL_NO_ACTION:
        printf("NO ACTION\n"); /* non-IBM only */
        break;
      default:
        printf("SET NULL\n");
        break;
    }

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CnListForeignKeys */

/* list the special (row identifier) columns for a specified table */
int CnListSpecialColumns(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  colName, colType;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[255];
  }
  colRemarks;

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  colPrecision;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  colScale;

  /* specifications of the table to look for */
  SQLCHAR tbSchema[] = "SCH";
  SQLCHAR tbName[] = "DEPT";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLSpecialColumns\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO LIST SPECIAL (ROW IDENTIFIER) COLUMNS FOR A SPECIFIED TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLSpecialColumns */
  printf("\n  Call SQLSpecialColumns for the table %s.%s\n",
         tbSchema, tbName);

  /* get special columns */
  cliRC = SQLSpecialColumns(hstmt,
                            SQL_BEST_ROWID,
                            NULL,
                            0,
                            tbSchema,
                            SQL_NTS,
                            tbName,
                            SQL_NTS,
                            SQL_SCOPE_CURROW,
                            SQL_NULLABLE);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, colName.val, 129, &colName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, colType.val, 129, &colType.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt,
                     5,
                     SQL_C_LONG,
                     (SQLPOINTER)&colPrecision.val,
                     sizeof(colPrecision.val),
                     &colPrecision.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_SHORT,
                     (SQLPOINTER)&colScale.val,
                     sizeof(colScale.ind),
                     &colScale.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Fetch each row and display.\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-10.10s", colName.val);

    printf(", %s", colType.val);

    if (colPrecision.ind != SQL_NULL_DATA)
    {
      printf(" (%ld", colPrecision.val);
    }
    else
    {
      printf("(\n");
    }

    if (colScale.ind != SQL_NULL_DATA)
    {
      printf(", %d)\n", colScale.val);
    }
    else
    {
      printf(")\n");
    }

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CnListSpecialColumns */

/* list the index columns for a specified table */
int CnListIndexColumns(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* specifications of the table to look for */
  SQLCHAR tbSchema[] = "SCH";
  SQLCHAR tbName[] = "DEPT";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  columnName, indexName;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  type;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLStatistics\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO LIST INDEX COLUMNS FOR A SPECIFIED TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLStatistics */
  printf("\n  Call SQLStatistics for the table %s.%s\n", tbSchema, tbName);

  /* get index and statistics information for a base table */
  cliRC = SQLStatistics(hstmt,
                        NULL,
                        0,
                        tbSchema,
                        SQL_NTS,
                        tbName,
                        SQL_NTS,
                        SQL_INDEX_UNIQUE,
                        SQL_QUICK);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt,
                     6,
                     SQL_C_CHAR,
                     (SQLPOINTER)indexName.val,
                     129,
                     &indexName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_SHORT,
                     (SQLPOINTER)&type.val,
                     0,
                     &type.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 9 to variable */
  cliRC = SQLBindCol(hstmt,
                     9,
                     SQL_C_CHAR,
                     (SQLPOINTER)columnName.val,
                     129,
                     &columnName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Fetch each row and display.\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    if (type.val != SQL_TABLE_STAT)
    {
      printf("    Column    : %-10s\n", columnName.val);
      printf("    Index Name: %s\n", indexName.val);
    }

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CnListIndexColumns */

/* show how to use a NOT NULL constraint */
int Cn_NOT_NULL_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  /* create table */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE emp_sal(lastname VARCHAR(10) "
                              "NOT NULL, firstname VARCHAR(10), "
                              "salary DECIMAL(7, 2))";

  /* insert into the table */
  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO emp_sal "
                              "  VALUES(NULL, 'PHILIP', 17000.00)";
  
  /* drop table */ 
  SQLCHAR *stmt3 = (SQLCHAR *)"DROP TABLE emp_sal";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW A 'NOT NULL' CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create table */
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE emp_sal(lastname VARCHAR(10) NOT NULL,\n"
         "                         firstname VARCHAR(10),\n"
         "                         salary DECIMAL(7, 2))\n");
   
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO emp_sal VALUES(NULL, 'PHILIP', 17000.00)\n");
   
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    DROP TABLE emp_sal\n");
   
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* Cn_NOT_NULL_Show */
 
/* show how to use UNIQUE constraint */
int Cn_UNIQUE_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  /* create table */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE emp_sal ("
                              "lastname VARCHAR(10) NOT NULL, "
                              "firstname VARCHAR(10) NOT NULL, "
                              "salary DECIMAL(7, 2), "
                              "CONSTRAINT unique_cn UNIQUE "
                              "(lastname, firstname))";
  
  /* insert into the table */
  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO emp_sal VALUES "
                              "('SMITH', 'PHILIP', 17000.00), "
                              "('SMITH', 'PHILIP', 21000.00)";
  
  /* drop constraint */
  SQLCHAR *stmt3 = (SQLCHAR *)"ALTER TABLE emp_sal "
                              "DROP CONSTRAINT unique_cn";
  
  /* drop table */
  SQLCHAR *stmt4 = (SQLCHAR *)"DROP TABLE emp_sal";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW A 'UNIQUE' CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE emp_sal(lastname VARCHAR(10) NOT NULL,\n"
         "                         firstname VARCHAR(10) NOT NULL,\n"
         "                         salary DECIMAL(7, 2),\n"
         "    CONSTRAINT unique_cn UNIQUE(lastname, firstname))\n");
   
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO emp_sal VALUES('SMITH', 'PHILIP', 17000.00),\n"
         "                              ('SMITH', 'PHILIP', 21000.00) \n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    ALTER TABLE emp_sal DROP CONSTRAINT unique_cn\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 

  printf("\n    DROP TABLE emp_sal\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;
} /* Cn_UNIQUE_Show */

/* show how to use PRIMARY key constraint */
int Cn_PRIMARY_KEY_Show(SQLHANDLE hdbc)
{
  
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  /* create table */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE emp_sal( "
                              "lastname VARCHAR(10) NOT NULL, "
                              "firstname VARCHAR(10) NOT NULL, " 
                              "salary DECIMAL(7, 2), "
                              "CONSTRAINT pk_cn PRIMARY KEY "
                              "(lastname, firstname))";

  /* insert into the table */
  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO emp_sal VALUES "
                              "('SMITH', 'PHILIP', 17000.00), "
                              "('SMITH', 'PHILIP', 21000.00)";

  /* drop constraint */
  SQLCHAR *stmt3 = (SQLCHAR *)"ALTER TABLE emp_sal DROP CONSTRAINT pk_cn";

  /* drop table */
  SQLCHAR *stmt4 = (SQLCHAR *)"DROP TABLE emp_sal";
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW A 'PRIMARY KEY' CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE emp_sal(lastname VARCHAR(10) NOT NULL,\n"
         "                         firstname VARCHAR(10) NOT NULL,\n"
         "                         salary DECIMAL(7, 2),\n"
         "    CONSTRAINT pk_cn PRIMARY KEY(lastname, firstname))\n");
   
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO emp_sal VALUES('SMITH', 'PHILIP', 17000.00),\n"
         "                              ('SMITH', 'PHILIP', 21000.00) \n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    ALTER TABLE emp_sal DROP CONSTRAINT pk_cn\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 

  printf("\n    DROP TABLE emp_sal\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;
} /* Cn_PRIMARY_KEY_Show */

/* show how to use CHECK constraint */
int Cn_CHECK_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  /* create table */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE emp_sal(lastname VARCHAR(10), "
                              "                     firstname VARCHAR(10),"
                              "                     salary DECIMAL(7, 2), "
                              "CONSTRAINT check_cn CHECK(salary < 25000.00))";

  /* insert table */    
  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO emp_sal VALUES "
                              "('SMITH', 'PHILIP', 27000.00)";
  
  /* drop constraint */
  SQLCHAR *stmt3 = (SQLCHAR *)"ALTER TABLE emp_sal "
                              "DROP CONSTRAINT check_cn";

  /* drop table */
  SQLCHAR *stmt4 = (SQLCHAR *)"DROP TABLE emp_sal";  

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW A 'CHECK' CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE emp_sal(lastname VARCHAR(10),\n"
         "                         firstname VARCHAR(10),\n"
         "                         salary DECIMAL(7, 2),\n"
         "    CONSTRAINT check_cn CHECK(salary < 25000.00))\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO emp_sal VALUES('SMITH', 'PHILIP', 27000.00)\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    ALTER TABLE emp_sal DROP CONSTRAINT check_cn\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 

  printf("\n    DROP TABLE emp_sal\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;
} /* Cn_CHECK_Show */

/* show how to use INFORMATIONAL constraint */ 
int Cn_CHECK_INFO_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  /* create table */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE empl( "
                              "  empno INTEGER NOT NULL PRIMARY KEY, "
                              "  name VARCHAR(10), "
                              "  firstname VARCHAR(20), "
                              "  salary INTEGER "
                              "CONSTRAINT minsalary "
                              "  CHECK (salary >= 25000)"
                              "  NOT ENFORCED"
                              "  ENABLE QUERY OPTIMIZATION)";
  
   /* insert into the table */
   SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO empl "
                               "VALUES(1, 'SMITH', 'PHILIP', 1000)";
   
   /* alter the constraint to make it ENFORCED by database manager */
   SQLCHAR *stmt3 = (SQLCHAR *)"ALTER TABLE empl "
                               "ALTER CHECK minsalary ENFORCED"; 

  /* delete entries from empl table */
  SQLCHAR *stmt4 = (SQLCHAR *)"DELETE FROM empl";

  /* drop the table */
  SQLCHAR *stmt5 = (SQLCHAR *)"DROP TABLE empl";
 
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW AN 'INFORMATIONAL' CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  /* create table */ 
  printf("\n  Directly execute the statement\n"); 
  printf("    CREATE TABLE empl(empno INTEGER NOT NULL PRIMARY KEY,\n"
         "                     name VARCHAR(10),\n"
         "                     firstname VARCHAR(20),\n"
         "                     salary INTEGER CONSTRAINT minsalary\n"
         "                            CHECK (salary >= 25000)\n"
         "                            NOT ENFORCED\n"
         "                            ENABLE QUERY OPTIMIZATION)\n");     
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* insert data that doesn't satisfy the constraint 'minsalary'. 
     database manager does not enforce the constraint for IUD operations */
  printf("\nTO SHOW NOT ENFORCED OPTION\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)\n\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* alter the constraint to make it ENFORCED by database manager */ 
  printf("Alter the constraint to make it ENFORCED by database manager\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    ALTER TABLE empl ALTER CHECK minsalary ENFORCED\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* delete entries from empl table */
  printf("\n    DELETE FROM empl\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
 
  /* alter the constraint to make it ENFORCED by database manager */ 
  printf("\n\nTO SHOW ENFORCED OPTION\n");
 
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    ALTER TABLE empl ALTER CHECK minsalary ENFORCED\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* insert table with data not conforming to the constraint 'minsalary'
     database manager enforces the constraint for IUD operations */
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
 
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 

  printf("\n    DROP TABLE empl\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt5, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;
}  /* Cn_CHECK_INFO_Show */

/* show how to use  WITH DEFAULT constraint */
int Cn_WITH_DEFAULT_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  salary; /* variable to get data from the SALARY column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  firstname; /* variable to get data from the FIRSTNAME column */
  
  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  lastname; /* variable to get data from the FIRSTNAME column */
  
  /* create table */
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE emp_sal(lastname VARCHAR(10),"
                              "firstname VARCHAR(10), salary DECIMAL(7, 2) "
                              "WITH DEFAULT 17000.00)";
  /* insert into the table */
  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO emp_sal(lastname, firstname)"
                             "  VALUES('SMITH', 'PHILIP'),"
                             "        ('PARKER', 'JOHN'),"
                             "        ('PEREZ', 'MARIA')";

  /* display the contents of the table */
  SQLCHAR *stmt3 = (SQLCHAR *)"SELECT firstname, lastname, salary"
                              "  FROM emp_sal";

  /* drop the table */
  SQLCHAR *stmt4 = (SQLCHAR *)"DROP TABLE emp_sal";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLGetData\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW A 'WITH DEFAULT' CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  /* create table */ 
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  printf("\n  Directly execute the statement\n"); 
  printf("    CREATE TABLE emp_sal(lastname VARCHAR(10),\n"
         "                         firstname VARCHAR(10),\n"
         "                         "
         "salary DECIMAL(7, 2) WITH DEFAULT 17000.00)\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
 
  /* insert table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO emp_sal(lastname, firstname)\n"
         "      VALUES('SMITH', 'PHILIP'),\n"
         "            ('PARKER', 'JOHN'),\n"
         "            ('PEREZ', 'MARIA')\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);   
   
  /* display the contents of the table */

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  printf("\n    SELECT firstname, lastname, salary FROM emp_sal\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("    FIRSTNAME  LASTNAME   SALARY  \n");
  printf("    ---------- ---------- --------\n");

  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* use SQLGetData to get the results */
    /* get data from column 1 */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       lastname.val,
                       15,
                       &lastname.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_CHAR,
                       firstname.val,
                       15,
                       &firstname.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 3 */
    cliRC = SQLGetData(hstmt,
                       3,
                       SQL_C_SHORT,
                       &salary.val,
                       0,
                       &salary.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* display */
    printf("    %-10s %-10s %-7.2f\n", firstname.val, 
      lastname.val, (float)salary.val);
    
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 

  printf("\n    DROP TABLE emp_sal\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;
} /* Cn_WITH_DEFAULT_Show */ 

/* display the contents of two tables */ 
int FK_TwoTablesDisplay(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[4];
  }
  deptno; /* variable to get data from the DEPTNO column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  deptname; /* variable to get data from the DEPTNAME column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[5];
  }
  empno; /* variable to get data from the EMPNO column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  empname; /* variable to get data from the EMPNAME column */
  
  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[4];
  }
  dept_no; /* variable to get data from the DEPT_NO column */

  
  SQLCHAR *stmt1 = (SQLCHAR *)"SELECT deptno, deptname FROM tab_dept" ;
  SQLCHAR *stmt2 = (SQLCHAR *)"SELECT empno, empname, dept_no FROM empl";
 
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLGetData\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO DISPLAY THE CONTENTS OF THE TABLES:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 
  printf("\n    SELECT deptno, deptname FROM tab_dept\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("    DEPTNO  DEPTNAME      \n");
  printf("    ------- --------------\n");

  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* use SQLGetData to get the results */
    /* get data from column 1 */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       &deptno.val,
                       4,
                       &deptno.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_CHAR,
                       deptname.val,
                       15,
                       &deptname.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("    %-7s %-20s\n", deptno.val, deptname.val);
       
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC); 
  printf("\n    SELECT empno, empname, dept_no FROM empl\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("    EMPNO EMPNAME    DEPT_NO\n");
  printf("    ----- ---------- -------\n");

  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* use SQLGetData to get the results */
    /* get data from column 1 */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       &empno.val,
                       5,
                       &empno.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_CHAR,
                       empname.val,
                       15,
                       &empname.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 3 */
    cliRC = SQLGetData(hstmt,
                       3,
                       SQL_C_CHAR,
                       &dept_no.val,
                       4,
                       &dept_no.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("    %-5s %-10s", empno.val, empname.val);
    if (strcmp((char *) dept_no.val, "\0"))
    {
      printf(" %-3s\n", dept_no.val);
    }
    else
    {
      printf(" -\n");
    }

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    strcpy((char *)dept_no.val,"\0");
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* FK_TwoTablesDisplay */

/* to create foreign key */ 
int FK_Create(SQLHANDLE hdbc, char *ruleClause)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  char stmt[384]; /* sql statement */

  sprintf(stmt, "ALTER TABLE empl ADD CONSTRAINT fk_dept "
                   "  FOREIGN KEY(dept_no) "
                   "  REFERENCES tab_dept(deptno) "
                   "  %s ", ruleClause);
  
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO ADD A FOREIGN KEY CONSTRAINT TO THE TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE empl ADD CONSTRAINT fk_dept \n"
         "      FOREIGN KEY(dept_no) \n"
         "      REFERENCES tab_dept(deptno) \n"
         "      %s ", ruleClause);
   
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;

} /* FK_Create */

/* drop foreign key */
int FK_Drop(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)"ALTER TABLE empl DROP CONSTRAINT fk_dept";
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO DROP AN FOREIGN KEY CONSTRAINT:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    ALTER TABLE empl DROP CONSTRAINT fk_dept\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc;
} /* FK_Drop */

/* create two tables */
int FK_TwoTablesCreate(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE tab_dept(deptno CHAR(3) NOT NULL,"
                              "                  deptname VARCHAR(20), "
                              "CONSTRAINT pk_dept PRIMARY KEY(deptno))";
  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO tab_dept "
                              "  VALUES('A00', 'ADMINISTRATION'), "
                              "        ('B00', 'DEVELOPMENT'), "
                              "        ('C00', 'SUPPORT') ";
  SQLCHAR *stmt3 = (SQLCHAR *)"CREATE TABLE empl(empno CHAR(4), "
                              "                 empname VARCHAR(10),"
                              "                 dept_no CHAR(3))";
 
  SQLCHAR *stmt4 = (SQLCHAR *)"INSERT INTO empl "
                              "VALUES('0010', 'Smith', 'A00'), "
                              "      ('0020', 'Ngan', 'B00'), "
                              "      ('0030', 'Lu', 'B00'), "
                              "      ('0040', 'Wheeler', 'B00'), "
                              "      ('0050', 'Burke', 'C00'), "
                              "      ('0060', 'Edwards', 'C00'), "
                              "      ('0070', 'Lea', 'C00')  ";

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO CREATE TWO TABLES:\n");
   
  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE tab_dept(deptno CHAR(3) NOT NULL,\n"
         "                      deptname VARCHAR(20),\n"
         "                      CONSTRAINT pk_dept PRIMARY KEY(deptno))\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO tab_dept VALUES('A00', 'ADMINISTRATION'),\n"
         "                           ('B00', 'DEVELOPMENT'),\n"
         "                           ('C00', 'SUPPORT')\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    CREATE TABLE empl(empno CHAR(4),\n"
         "                     empname VARCHAR(10),\n"
         "                     dept_no CHAR(3))\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO empl VALUES('0010', 'Smith', 'A00'),\n"
         "                          ('0020', 'Ngan', 'B00'),\n"
         "                          ('0030', 'Lu', 'B00'),\n"
         "                          ('0040', 'Wheeler', 'B00'),\n"
         "                          ('0050', 'Burke', 'C00'),\n"
         "                          ('0060', 'Edwards', 'C00'),\n"
         "                          ('0070', 'Lea', 'C00')\n");
   
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  return rc; 
} /* FK_TwoTablesCreate */

/* drop tables created for FOREIGN KEY sample functions */
int FK_TwoTablesDrop(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"DROP TABLE tab_dept";

  SQLCHAR *stmt2 = (SQLCHAR *)"DROP TABLE empl";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO DROP THE TABLES:\n");
   
  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    DROP TABLE tab_dept\n");
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    DROP TABLE empl\n");
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
 
  return rc;
} /* FK_TwoTablesDrop */

/* show how to use FOREIGN key works on insert */
int Cn_FK_OnInsertShow(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"INSERT INTO tab_dept VALUES('D00', 'SALES')";

  SQLCHAR *stmt2 = (SQLCHAR *)"INSERT INTO empl"
                              "  VALUES('0080', 'Pearce', 'E03')";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW HOW A FOREIGN KEY WORKS ON INSERT:\n");

  /* display initial tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* create foreign key */
  rc = FK_Create(hdbc,"");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* insert parent table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO tab_dept VALUES('D00', 'SALES')\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* insert child table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    INSERT INTO empl VALUES('0080', 'Pearce', 'E03')\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* display final tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* rollback transaction */  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK); 
  DBC_HANDLE_CHECK(hdbc, rc); 

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* drop foreign key */
  rc = FK_Drop(hdbc);

  return rc;
} /* Cn_FK_OnInsertShow */

/* show how to use 'ON UPDATE NO ACTION' foreign key constraint */
int  Cn_FK_ON_UPDATE_NO_ACTION_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"UPDATE tab_dept SET deptno = 'E01' "
                              "  WHERE deptno = 'A00'";

  SQLCHAR *stmt2 = (SQLCHAR *)"UPDATE tab_dept SET deptno = "
                              "  CASE "
                              "    WHEN deptno = 'A00' THEN 'B00' "
                              "    WHEN deptno = 'B00' THEN 'A00' "
                              "  END "
                              "  WHERE deptno = 'A00' OR deptno = 'B00' ";

  SQLCHAR *stmt3 = (SQLCHAR *)"UPDATE empl SET dept_no = 'G11' "
                              "  WHERE empname = 'Wheeler' ";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW AN 'ON UPDATE NO ACTION' FOREIGN KEY:\n");
  
  /* display initial tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* create foreign key */
  rc = FK_Create(hdbc, "ON UPDATE NO ACTION");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* update parent table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    UPDATE tab_dept SET deptno = 'E01' WHERE deptno = 'A00'\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  printf("\n    UPDATE tab_dept SET deptno =\n"
         "      CASE\n"
         "        WHEN deptno = 'A00' THEN 'B00'\n"
         "        WHEN deptno = 'B00' THEN 'A00'\n"
         "      END\n"
         "      WHERE deptno = 'A00' OR deptno = 'B00'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* update child table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  printf("    UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

    /* display final tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* rollback transaction */  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK); 
  DBC_HANDLE_CHECK(hdbc, rc); 

  /* drop foreign key */
  rc = FK_Drop(hdbc);

  return rc;
} /* Cn_FK_ON_UPDATE_NO_ACTION_Show */

/* show how to use 'ON UPDATE RESTRICT' foreign key constraint */
int Cn_FK_ON_UPDATE_RESTRICT_Show(SQLHANDLE hdbc)
{
  
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"UPDATE tab_dept SET deptno = 'E01' "
                              "  WHERE deptno = 'A00' ";
  
  SQLCHAR *stmt2 = (SQLCHAR *)"UPDATE tab_dept SET deptno = "
                              "  CASE "
                              "    WHEN deptno = 'A00' THEN 'B00' "
                              "    WHEN deptno = 'B00' THEN 'A00' "
                              "  END "
                              "  WHERE deptno = 'A00' OR deptno = 'B00' ";

  SQLCHAR *stmt3 = (SQLCHAR *)"UPDATE empl SET dept_no = 'G11' "
                              "  WHERE empname = 'Wheeler' ";
    
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW AN 'ON UPDATE RESTRICT' FOREIGN KEY:\n");  
  
  /* display initial tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* create foreign key */
  rc = FK_Create(hdbc, "ON UPDATE RESTRICT");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* update parent table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    UPDATE tab_dept SET deptno = 'E01' WHERE deptno = 'A00'\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    UPDATE tab_dept SET deptno =\n"
         "      CASE\n"
         "        WHEN deptno = 'A00' THEN 'B00'\n"
         "        WHEN deptno = 'B00' THEN 'A00'\n"
         "      END\n"
         "      WHERE deptno = 'A00' OR deptno = 'B00'\n");


  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* update child table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  printf("    UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* display final tables content */
  rc = FK_TwoTablesDisplay(hdbc);

  /* rollback transaction */  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK); 
  DBC_HANDLE_CHECK(hdbc, rc); 

  /* drop foreign key */
  rc = FK_Drop(hdbc);

  return rc;
} /* Cn_FK_ON_UPDATE_RESTRICT_Show */

/* show how to use 'ON DELETE CASCADE' foreign key constraint */
int Cn_FK_ON_DELETE_CASCADE_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"DELETE FROM tab_dept WHERE deptno = 'C00' ";
  SQLCHAR *stmt2 = (SQLCHAR *)"DELETE FROM empl WHERE empname = 'Wheeler' ";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW AN 'ON DELETE CASCADE' FOREIGN KEY:\n");
    
  /* display initial tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* create foreign key */
  rc = FK_Create(hdbc, "ON DELETE CASCADE");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* delete parent table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    DELETE FROM tab_dept WHERE deptno = 'C00'\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* display content of tables */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* delete child table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    DELETE FROM empl WHERE empname = 'Wheeler'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* display final tables content */
  rc = FK_TwoTablesDisplay(hdbc);

  /* rollback transaction */  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK); 
  DBC_HANDLE_CHECK(hdbc, rc); 

  /* drop foreign key */
  rc = FK_Drop(hdbc);

  return rc;
} /* Cn_FK_ON_DELETE_CASCADE_Show */

/* show how to use 'ON DELETE SET NULL' foreign key constraint */
int Cn_FK_ON_DELETE_SET_NULL_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"DELETE FROM tab_dept WHERE deptno = 'C00' ";
  SQLCHAR *stmt2 = (SQLCHAR *)"DELETE FROM empl WHERE empname = 'Wheeler' ";
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW AN 'ON DELETE SET NULL' FOREIGN KEY:\n");
    
  /* display initial tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* create foreign key */
  rc = FK_Create(hdbc, "ON DELETE SET NULL");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* delete parent table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    DELETE FROM tab_dept WHERE deptno = 'C00'\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* display content of tables */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* delete child table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    DELETE FROM empl WHERE empname = 'Wheeler'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* display final tables content */
  rc = FK_TwoTablesDisplay(hdbc);

  /* rollback transaction */  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK); 
  DBC_HANDLE_CHECK(hdbc, rc); 
  
  /* drop foreign key */
  rc = FK_Drop(hdbc);

  return rc;
} /* Cn_FK_ON_DELETE_SET_NULL_Show */

/* show how to use 'ON DELETE NO ACTION' foreign key constraint */
int  Cn_FK_ON_DELETE_NO_ACTION_Show(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"DELETE FROM tab_dept WHERE deptno = 'C00' ";
  SQLCHAR *stmt2 = (SQLCHAR *)"DELETE FROM empl WHERE empname = 'Wheeler' ";
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO SHOW AN 'ON DELETE NO ACTION' FOREIGN KEY:\n");
  
  /* display initial tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* create foreign key */
  rc = FK_Create(hdbc, "ON DELETE NO ACTION");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* delete parent table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    DELETE FROM tab_dept WHERE deptno = 'C00'\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  
  /* display the expected error */
  printf("\n-- The following error report is expected! --");
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* delete child table */
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n    DELETE FROM empl WHERE empname = 'Wheeler'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  
  /* display final tables content */
  rc = FK_TwoTablesDisplay(hdbc);
  
  /* rollback transaction */  
  rc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK); 
  DBC_HANDLE_CHECK(hdbc, rc); 
  
  /* drop foreign key */
  rc = FK_Drop(hdbc);

  return rc;
} /* Cn_FK_ON_DELETE_NO_ACTION_Show */
