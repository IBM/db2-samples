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
** SOURCE FILE NAME: tbinfo.c                                      
**                                                                        
** SAMPLE: How to get information about tables from the system catalog tables
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLColumnPrivileges -- Get Privileges Associated with
**                                the Columns of a Table
**         SQLColumns -- Get Column Information for a Table
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLStatistics -- Get Index and Statistics Information
**                          for a Base Table
**         SQLTablePrivileges -- Get Privileges Associated with a Table
**         SQLTables -- Get Table Information
**                                                                        
** OUTPUT FILE: tbinfo.out (available in the online documentation)
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

int TbListTables(SQLHANDLE);
int TbListColumns(SQLHANDLE);
int TbListRowsAndPages(SQLHANDLE);
int TbListTablePrivileges(SQLHANDLE);
int TbListColumnPrivileges(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO GET INFORMATION ABOUT TABLES.\n");

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

  /* list tables that meet specified criteria */
  rc = TbListTables(hdbc);
  /* list columns that meet specified criteria */
  rc = TbListColumns(hdbc);
  /* get the number of rows and pages that meet specified criteria */
  rc = TbListRowsAndPages(hdbc);
  /* get the privileges for tables that meet specified criteria */
  rc = TbListTablePrivileges(hdbc);
  /* get the column privileges that meet specified criteria */
  rc = TbListColumnPrivileges(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* list tables that meet specified criteria */
int TbListTables(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  tbQualifier, tbSchema, tbName, tbType;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[255];
  }
  tbRemarks;

  /* criteria to look for */
  SQLCHAR tbSchemaPattern[] = "%"; /* all the schemas */
  SQLCHAR tbNamePattern[] = "ST%"; /* all the tables starting with ST */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLTables\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO LIST TABLES THAT MEET SPECIFIED CRITERIA:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLTables */
  printf("\n  Call SQLTables for:\n");
  printf("    schemaPattern = %s\n", tbSchemaPattern);
  printf("    namePattern = %s\n", tbNamePattern);

  /* get table information */
  cliRC = SQLTables(hstmt,
                    NULL,
                    0,
                    tbSchemaPattern,
                    SQL_NTS,
                    tbNamePattern,
                    SQL_NTS,
                    NULL,
                    0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt,
                     1,
                     SQL_C_CHAR,
                     tbQualifier.val,
                     129,
                     &tbQualifier.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt,
                     2,
                     SQL_C_CHAR,
                     tbSchema.val,
                     129,
                     &tbSchema.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_CHAR,
                     tbName.val,
                     129,
                     &tbName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt,
                     4,
                     SQL_C_CHAR,
                     tbType.val,
                     129,
                     &tbType.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt,
                     5,
                     SQL_C_CHAR,
                     tbRemarks.val,
                     255,
                     &tbRemarks.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Fetch each row and display.\n");
  printf("    TABLE SCHEMA   TABLE_NAME     TABLE_TYPE\n");
  printf("    -------------- -------------- ----------\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-14s %-14s %-11s\n",
           tbSchema.val, tbName.val, tbType.val);
    if (tbRemarks.ind > 0)
    {
      printf("    (Remarks) %s\n", tbRemarks.val);
    }

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbListTables */

/* list columns that meet specified criteria */
int TbListColumns(SQLHANDLE hdbc)
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
  colLength;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  colScale, colNullable;

  /* criteria to look for */
  SQLCHAR tbSchemaPattern[] = "%";
  SQLCHAR tbNamePattern[] = "STAFF";
  SQLCHAR colNamePattern[] = "%";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLColumns\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO LIST COLUMNS THAT MEET SPECIFIED CRITERIA:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLColumns */
  printf("\n  Call SQLColumns for:\n");
  printf("    tbSchemaPattern = %s\n", tbSchemaPattern);
  printf("    tbNamePattern = %s\n", tbNamePattern);
  printf("    colNamePattern = %s\n", colNamePattern);

  /* get column information for a table */
  cliRC = SQLColumns(hstmt,
                     NULL,
                     0,
                     tbSchemaPattern,
                     SQL_NTS,
                     tbNamePattern,
                     SQL_NTS,
                     colNamePattern,
                     SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, colName.val, 129, &colName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt, 6, SQL_C_CHAR, colType.val, 129, &colType.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_LONG,
                     (SQLPOINTER)&colLength.val,
                     sizeof(colLength.val),
                     &colLength.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 9 to variable */
  cliRC = SQLBindCol(hstmt,
                     9,
                     SQL_C_SHORT,
                     (SQLPOINTER)&colScale.val,
                     sizeof(colScale.val),
                     &colScale.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 11 to variable */
  cliRC = SQLBindCol(hstmt,
                     11,
                     SQL_C_SHORT,
                     (SQLPOINTER)&colNullable.val,
                     sizeof(colNullable.val),
                     &colNullable.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 12 to variable */
  cliRC = SQLBindCol(hstmt,
                     12,
                     SQL_C_CHAR,
                     colRemarks.val,
                     255,
                     &colRemarks.ind);
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
    if (colNullable.val == SQL_NULLABLE)
    {
      printf(",     NULLABLE");
    }
    else
    {
      printf(", NOT NULLABLE");
    }

    printf(", %s", colType.val);

    if (colLength.ind != SQL_NULL_DATA)
    {
      printf(" (%ld", colLength.val);
    }
    else
    {
      printf("(");
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
} /* TbListColumns */

/* get the number of rows and pages that meet specified criteria */
int TbListRowsAndPages(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  tbCardinality, tbPages;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  infoType;

  /* criteria to look for */
  SQLCHAR tbSchema[] = "SYSCAT";
  SQLCHAR tbName[] = "TABLES";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLStatistics\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO GET THE NUMBER OF ROWS AND PAGES\n");
  printf("THAT MEET SPECIFIED CRITERIA:\n");

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
  printf("\n  Call SQLStatistics for:\n");
  printf("    tbSchema = %s\n", tbSchema);
  printf("    tbName = %s\n", tbName);

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

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_SHORT,
                     (SQLPOINTER)&infoType.val,
                     sizeof(infoType.val),
                     &infoType.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 11 to variable */
  cliRC = SQLBindCol(hstmt,
                     11,
                     SQL_C_LONG,
                     (SQLPOINTER)&tbCardinality.val,
                     sizeof(tbCardinality.val),
                     &tbCardinality.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 12 to variable */
  cliRC = SQLBindCol(hstmt,
                     12,
                     SQL_C_LONG,
                     (SQLPOINTER)&tbPages.val,
                     sizeof(tbPages.val),
                     &tbPages.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Display the number of rows and pages.\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    if (infoType.val == SQL_TABLE_STAT)
    {
      if (tbCardinality.ind == SQL_NULL_DATA)
      {
        printf("    Number of rows = (Unavailable)\n");
      }
      else
      {
        printf("    Number of rows = %u\n", tbCardinality.val);
      }
      if (tbPages.ind == SQL_NULL_DATA)
      {
        printf("    Number of pages used to store the table =");
        printf("(Unavailable)\n");
      }
      else
      {
        printf("    Number of pages used to store the table = %u\n",
               tbCardinality.val);
      }
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
} /* TbListRowsAndPages */

/* get the privileges for tables that meet specified criteria */
int TbListTablePrivileges(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  tbSchema, tbName, grantor, grantee, privilege;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[4];
  }
  is_grantable;

  /* criteria look for */
  SQLCHAR tbSchemaPattern[] = "%";
  SQLCHAR tbNamePattern[] = "ORG";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLTablePrivileges\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET PRIVILEGES FOR TABLES THAT MEET SPECIFIED CRITERIA:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLTablePrivileges */
  printf("\n  Call SQLTablePrivileges for:\n");
  printf("    tbSchemaPattern = %s\n", tbSchemaPattern);
  printf("    tbNamePattern = %s\n", tbNamePattern);

  /* get privileges associated with a table */
  cliRC = SQLTablePrivileges(hstmt,
                             NULL,
                             0,
                             tbSchemaPattern,
                             SQL_NTS,
                             tbNamePattern,
                             SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, tbSchema.val, 129, &tbSchema.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, tbName.val, 129, &tbName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt,
                     4,
                     SQL_C_CHAR,
                     (SQLPOINTER)grantor.val,
                     129,
                     &grantor.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt,
                     5,
                     SQL_C_CHAR,
                     (SQLPOINTER)grantee.val,
                     129,
                     &grantee.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt,
                     6,
                     SQL_C_CHAR,
                     (SQLPOINTER)privilege.val,
                     129,
                     &privilege.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_CHAR,
                     (SQLPOINTER)is_grantable.val,
                     4,
                     &is_grantable.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Current User's Privileges \n");
  printf("    Table Grantor  Grantee      Privilege  Grantable\n");
  printf("    ----- -------- ------------ ---------- ---------\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-5s", tbName.val);
    printf(" %-8s", grantor.val);
    printf(" %-12s", grantee.val);
    printf(" %-10s", privilege.val);
    printf(" %-3s\n", is_grantable.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  } /* endwhile */

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbListTablePrivileges */

/* get the column privileges that meet specified criteria */
int TbListColumnPrivileges(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLHANDLE hstmtTable;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  colName, grantor, grantee, privilege;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[4];
  }
  is_grantable;

  /* criteria to look for */
  SQLCHAR tbSchema[] = "SCHEMA";
  SQLCHAR tbName[] = "TABLE_NAME";
  SQLCHAR colNamePattern[] = "%";

  SQLCHAR stmt[100];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLTablePrivileges\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET COLUMN PRIVILEGES THAT MEET SPECIFIED CRITERIA:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtTable);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create a test table */
  sprintf((char *)stmt, "CREATE TABLE %s.%s (COL1 CHAR(10))",
                        tbSchema, tbName);

  printf("\n  Directly execute\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtTable, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* call SQLColumnPrivileges */
  printf("\n  Call SQLColumnPrivileges for:\n");
  printf("    tbSchema = %s\n", tbSchema);
  printf("    tbName = %s\n", tbName);

  /* get privileges associated with the columns of a table */
  cliRC = SQLColumnPrivileges(hstmt,
                              NULL,
                              0,
                              tbSchema,
                              SQL_NTS,
                              tbName,
                              SQL_NTS,
                              colNamePattern,
                              SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, colName.val, 129, &colName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt,
                     5,
                     SQL_C_CHAR,
                     (SQLPOINTER)grantor.val,
                     129,
                     &grantor.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt,
                     6,
                     SQL_C_CHAR,
                     (SQLPOINTER)grantee.val,
                     129,
                     &grantee.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_CHAR,
                     (SQLPOINTER)privilege.val,
                     129,
                     &privilege.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 8 to variable */
  cliRC = SQLBindCol(hstmt,
                     8,
                     SQL_C_CHAR,
                     (SQLPOINTER)is_grantable.val,
                     4,
                     &is_grantable.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Current User's Privileges for table %s.%s\n", tbSchema,
         tbName);
  printf("    Column  Grantor  Grantee      Privilege  Grantable\n");
  printf("    ------- -------- ------------ ---------- ---------\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-7s", colName.val);
    printf(" %-8s", grantor.val);
    printf(" %-12s", grantee.val);
    printf(" %-10s", privilege.val);
    printf(" %-3s\n", is_grantable.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  } /* endwhile */

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the test table */
  sprintf((char *)stmt, "DROP TABLE %s.%s", tbSchema, tbName);

  printf("\n  Directly execute\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtTable, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtTable);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  return rc;
} /* TbListColumnPrivileges */

