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
** SOURCE FILE NAME: tbread.c                                      
**                                                                        
** SAMPLE: How to read data from tables
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLColAttribute -- Return a Column Attribute
**         SQLDescribeCol -- Return a Set of Attributes for a Column
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFetchScroll -- Fetch Rowset and Return Data
**                           for All Bound Columns 
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetData -- Get Data From a Column
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLPrepare -- Prepare a Statement
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetPos -- Set the Cursor Position in a Rowset
**         SQLSetStmtAttr -- Set Options Related to a Statement
**         SQLTables -- Get Table Information
**
** OUTPUT FILE: tbread.out (available in the online documentation)
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

#define ROWSET_SIZE 5

int TbBasicSelectUsingFetchAndBindCol(SQLHANDLE);
int TbBasicSelectUsingFetchAndGetData(SQLHANDLE);
int SysTbSelect(SQLHANDLE);
int TbSelectWithParam(SQLHANDLE);
int TbSelectWithUnknownOutCols(SQLHANDLE);
int TbSelectUsingFetchScrollColWise(SQLHANDLE);
int TbSelectUsingFetchScrollRowWise(SQLHANDLE);
int TbSelectUsingQuerySampling(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO READ TABLES.\n");

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

  /* two basic SELECTs */
  rc = TbBasicSelectUsingFetchAndBindCol(hdbc);
  rc = TbBasicSelectUsingFetchAndGetData(hdbc);

  /* SELECT on system tables */
  rc = SysTbSelect(hdbc);

  /* SELECT with parameter markers */
  rc = TbSelectWithParam(hdbc);

  /* SELECT with unknown output columns */
  rc = TbSelectWithUnknownOutCols(hdbc);

  /* SELECT using SQLFetchScroll with column-wise binding */
  rc = TbSelectUsingFetchScrollColWise(hdbc);

  /* SELECT using SQLFetchScroll with row-wise binding */
  rc = TbSelectUsingFetchScrollRowWise(hdbc);

  /* SELECT using query sampling on a table */
  rc = TbSelectUsingQuerySampling(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* perform a basic SELECT operation using SQLBindCol */
int TbBasicSelectUsingFetchAndBindCol(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL SELECT statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT deptnumb, location FROM org";

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

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A BASIC SELECT USING SQLBindCol:\n");

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
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_SHORT, &deptnumb.val, 0, &deptnumb.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, location.val, 15, &location.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    DEPTNUMB LOCATION     \n");
  printf("    -------- -------------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-8d %-14.14s \n", deptnumb.val, location.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbBasicSelectUsingFetchAndBindCol */

/* perform a basic SELECT operation using SQLGetData */
int TbBasicSelectUsingFetchAndGetData(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL SELECT statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT deptnumb, location FROM org";

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  deptnumb; /* variable to get data from the DEPTNUMB column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  location; /* variable to get data from the LOCATION column */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A BASIC SELECT USING SQLGetData:\n");

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
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    DEPTNUMB LOCATION     \n");
  printf("    -------- -------------\n");

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
                       SQL_C_SHORT,
                       &deptnumb.val,
                       0,
                       &deptnumb.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_CHAR,
                       location.val,
                       15,
                       &location.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* display */
    printf("    %-8d %-14.14s \n", deptnumb.val, location.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbBasicSelectUsingFetchAndGetData */

/* perform a SELECT on system catalog tables */
int SysTbSelect(SQLHANDLE hdbc)
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

  SQLCHAR tbSchemaPattern[] = "%";
  SQLCHAR tbNamePattern[] = "ST%"; /* all the tables starting with ST */

  printf("\n-----------------------------------------------------------");
  printf("\nThere are some CLI functions, called schema or catalog \n");
  printf("functions, that return information stored in the system \n");
  printf("catalog tables by basically performing a SELECT on the \n");
  printf("SYSTEM CATALOG TABLES.\n");
  printf("They are:\n");
  printf("  SQLColumnPrivileges\n");
  printf("  SQLColumns\n");
  printf("  SQLForeignKeys\n");
  printf("  SQLPrimaryKeys\n");
  printf("  SQLProcedureColumns\n");
  printf("  SQLProcedures\n");
  printf("  SQLSpecialColumns\n");
  printf("  SQLStatistics\n");
  printf("  SQLTablePrivileges\n");
  printf("  SQLTables\n\n");

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLTables\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO USE THE CLI CATALOG FUNCTION SQLTables:\n");

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
  printf("\n  Call SQLTables.\n");

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

  printf("\n  Fetch each row and display.\n");
  printf("    TABLE SCHEMA   TABLE_NAME     TABLE_TYPE\n");
  printf("    -------------- -------------- ----------\n");

  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-14s %-14s %-11s\n", tbSchema.val, tbName.val, tbType.val);
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
} /* SysTbSelect */

/* perform a SELECT that contains parameter markers */
int TbSelectWithParam(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)
    "SELECT deptnumb, location FROM org WHERE division = ?";

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

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A SELECT WITH PARAMETERS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt);

  /* prepare the statement */
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

  /* execute the statement for divisionParam = Eastern */
  printf("\n  Execute the prepared statement for\n");
  printf("    divisionParam = 'Eastern'\n");
  strcpy(divisionParam, "Eastern");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_SHORT, &deptnumb.val, 0, &deptnumb.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, location.val, 15, &location.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    DEPTNUMB LOCATION     \n");
  printf("    -------- -------------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-8d %-14.14s \n", deptnumb.val, location.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbSelectWithParam */

/* perform a SELECT where the number of columns in the
   result set is not known */
int TbSelectWithUnknownOutCols(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL SELECT statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT * FROM org";
  SQLSMALLINT i, j; /* indices */
  SQLSMALLINT nResultCols; /* variable for SQLNumResultCols */
  SQLCHAR colName[32]; /* variables for SQLDescribeCol  */
  SQLSMALLINT colNameLen;
  SQLSMALLINT colType;
  SQLUINTEGER colSize;
  SQLSMALLINT colScale;
  SQLINTEGER colDataDisplaySize; /* maximum size of the data */
  SQLINTEGER colDisplaySize[MAX_COLUMNS]; /* maximum size of the column */

  struct
  {
    SQLCHAR *buff;
    SQLINTEGER len;
    SQLINTEGER buffLen;
  }
  outData[MAX_COLUMNS]; /* variable to read the results */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLNumResultCols\n");
  printf("  SQLDescribeCol\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A SELECT WITH UNKNOWN OUTPUT COLUMNS\n");
  printf("AT COMPILE TIME:\n");

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
  printf("    %s.\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Identify the output columns, then \n");
  printf("  fetch each row and display.\n");

  /* identify the number of output columns */
  cliRC = SQLNumResultCols(hstmt, &nResultCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("    ");
  for (i = 0; i < nResultCols; i++)
  {
    /* return a set of attributes for a column */
    cliRC = SQLDescribeCol(hstmt,
                           (SQLSMALLINT)(i + 1),
                           colName,
                           sizeof(colName),
                           &colNameLen,
                           &colType,
                           &colSize,
                           &colScale,
                           NULL);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get the display size for a column */
    cliRC = SQLColAttribute(hstmt,
                            (SQLSMALLINT)(i + 1),
                            SQL_DESC_DISPLAY_SIZE,
                            NULL,
                            0,
                            NULL,
                            &colDataDisplaySize);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* set "column display size" to the larger of "column data display size"
       and "column name length" and add one space between columns. */
    colDisplaySize[i] = max(colDataDisplaySize, colNameLen) + 1;

    /* print the column name */
    printf("%-*.*s",
           (int)colDisplaySize[i], (int)colDisplaySize[i], colName);

    /* set "output data buffer length" to "column data display size"
       and add one byte for null the terminator */
    outData[i].buffLen = colDataDisplaySize + 1;

    /* allocate memory to bind a column */
    outData[i].buff = (SQLCHAR *)malloc((int)outData[i].buffLen);

    /* bind columns to program variables, converting all types to CHAR */
    cliRC = SQLBindCol(hstmt,
                       (SQLSMALLINT)(i + 1),
                       SQL_C_CHAR,
                       outData[i].buff,
                       outData[i].buffLen,
                       &outData[i].len);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  printf("\n    ");
  for (i = 0; i < nResultCols; i++)
  {
    for (j = 1; j < (int)colDisplaySize[i]; j++)
    {
      printf("-");
    }
    printf(" ");
  }
  printf("\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    ");
    for (i = 0; i < nResultCols; i++) /* for all columns in this row  */
    { /* check for NULL data */
      if (outData[i].len == SQL_NULL_DATA)
      {
        printf("%-*.*s",
               (int)colDisplaySize[i], (int)colDisplaySize[i], "NULL");
      }
      else
      { /* print outData for this column */
        printf("%-*.*s",
               (int)colDisplaySize[i],
               (int)colDisplaySize[i],
               outData[i].buff);
      }
    } 
    printf("\n");

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free data buffers */
  for (i = 0; i < nResultCols; i++)
  {
    free(outData[i].buff);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbSelectWithUnknownOutCols */

/* perform a SELECT using scrollable cursors and column-wise binding */
int TbSelectUsingFetchScrollColWise(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  int i;
  SQLHANDLE hstmt; /* statement handle */
  SQLHANDLE hstmtTable; /* to create a test table */
  SQLINTEGER rowNb;
  SQLCHAR stmtInsert[100];
  SQLUINTEGER rowsFetchedNb;
  SQLUSMALLINT rowStatus[ROWSET_SIZE];
  static char ROWSTATVALUE[][26] =
  {
    "SQL_ROW_SUCCESS", \
    "SQL_ROW_SUCCESS_WITH_INFO", \
    "SQL_ROW_ERROR", \
    "SQL_ROW_NOROW"
  };

  struct
  {
    SQLINTEGER ind[ROWSET_SIZE];
    SQLCHAR val[ROWSET_SIZE][15];
  }
  col1, col2; /* variables to be bound to columns */

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val[4];
  }
  bookmark;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLSetStmtAttr\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetchScroll\n");
  printf("  SQLSetPos\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO DEMONSTRATE SCROLLABLE CURSORS USING COLUMN-WISE BINDING:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtTable);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create a table with 30 rows */
  printf("\n  Create a test table with 2 columns and 30 rows.\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(
            hstmtTable,
            (UCHAR *)
            "CREATE TABLE fetchScrollTable (col1 CHAR(14), col2 CHAR(14))",
            SQL_NTS);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  for (rowNb = 1; rowNb <= 30; rowNb++)
  {
    sprintf(
      (char *)stmtInsert,
      "INSERT INTO fetchScrollTable VALUES ('row%d_col1', 'row%d_col2')",
      rowNb,
      rowNb);

    /* directly execute the statement */
    cliRC = SQLExecDirect(hstmtTable, stmtInsert, SQL_NTS);
    STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);
  }

  /* allocate a statement handle for SQLFetchScroll */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Set the required statement attributes.\n");

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROW_ARRAY_SIZE,
                         (SQLPOINTER)ROWSET_SIZE,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROW_BIND_TYPE,
                         SQL_BIND_BY_COLUMN,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROWS_FETCHED_PTR,
                         &rowsFetchedNb,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_CURSOR_TYPE,
                         (SQLPOINTER)SQL_CURSOR_STATIC,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_USE_BOOKMARKS,
                         (SQLPOINTER)SQL_UB_VARIABLE,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROW_STATUS_PTR,
                         (SQLPOINTER)rowStatus,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* select everything from the test table */
  printf("\n  Select all 30 rows from the test table.\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt,
                        (SQLCHAR *)"SELECT * FROM fetchScrollTable",
                        SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, col1.val, 15, col1.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, col2.val, 15, col2.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_ABSOLUTE at row 15 */
  printf("  SQLFetchScroll with SQL_FETCH_ABSOLUTE at row 15.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_NEXT */
  printf("  SQLFetchScroll with SQL_FETCH_NEXT.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_NEXT, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_PRIOR */
  printf("  SQLFetchScroll with SQL_FETCH_PRIOR.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_PRIOR, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_FIRST */
  printf("  SQLFetchScroll with SQL_FETCH_FIRST.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_FIRST, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_LAST */
  printf("  SQLFetchScroll with SQL_FETCH_LAST.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_LAST, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_RELATIVE offset 3 */
  printf("  SQLFetchScroll with SQL_FETCH_RELATIVE offset 3.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_RELATIVE, 3);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* set the bookmark at row 17 */
  printf("\n  Set the bookmark at row 17.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the cursor position in a rowset */
  cliRC = SQLSetPos(hstmt, 3, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get data from a column */
  cliRC = SQLGetData(hstmt, 0, SQL_C_LONG, bookmark.val, 4, &bookmark.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_FETCH_BOOKMARK_PTR,
                         (SQLPOINTER)bookmark.val,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_BOOKMARK offset 4 */
  printf("  SQLFetchScroll with SQL_FETCH_BOOKMARK offset 4.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_BOOKMARK, 4);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", col1.val[i], col2.val[i]);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the test table */
  printf("\n  Drop the test table.\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtTable,
                        (SQLCHAR *)"DROP TABLE fetchScrollTable ",
                        SQL_NTS);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtTable);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  return rc;
} /* TbSelectUsingFetchScrollColWise */

/* perform a SELECT using scrollable cursors and row-wise binding */
int TbSelectUsingFetchScrollRowWise(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLHANDLE hstmtTable; /* to create a test table */
  SQLINTEGER rowNb;
  SQLCHAR stmtInsert[100];
  SQLUINTEGER rowsFetchedNb;
  SQLUSMALLINT rowStatus[ROWSET_SIZE];
  static char ROWSTATVALUE[][26] =
  {
    "SQL_ROW_SUCCESS", \
    "SQL_ROW_SUCCESS_WITH_INFO", \
    "SQL_ROW_ERROR", \
    "SQL_ROW_NOROW"
  };
  int i;

  struct
  {
    SQLINTEGER col1_ind;
    SQLCHAR col1_val[15];
    SQLINTEGER col2_ind;
    SQLCHAR col2_val[15];
  }
  rowset[ROWSET_SIZE]; /* variables to be bound to columns */

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val[4];
  }
  bookmark;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLSetStmtAttr\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetchScroll\n");
  printf("  SQLSetPos\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO DEMONSTRATE SCROLLABLE CURSORS USING ROW-WISE BINDING:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtTable);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create a table with 30 rows */
  printf("\n  Create a test table with 2 columns and 30 rows.\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(
            hstmtTable,
            (SQLCHAR *)
            "CREATE TABLE fetchScrollTable (col1 CHAR(14), col2 CHAR(14))",
            SQL_NTS);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  for (rowNb = 1; rowNb <= 30; rowNb++)
  {
    sprintf(
      (char *)stmtInsert,
      "INSERT INTO fetchScrollTable VALUES ('row%d_col1', 'row%d_col2')",
      rowNb,
      rowNb);

    /* directly execute the statement */
    cliRC = SQLExecDirect(hstmtTable, stmtInsert, SQL_NTS);
    STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);
  }

  /* allocate a statement handle for SQLFetchScroll */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Set the required statement attributes.\n");

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROW_ARRAY_SIZE,
                         (SQLPOINTER)ROWSET_SIZE,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROW_BIND_TYPE,
                         (SQLPOINTER)(sizeof(rowset) / ROWSET_SIZE),
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROWS_FETCHED_PTR,
                         &rowsFetchedNb,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_CURSOR_TYPE,
                         (SQLPOINTER)SQL_CURSOR_STATIC,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_USE_BOOKMARKS,
                         (SQLPOINTER)SQL_UB_VARIABLE,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_ROW_STATUS_PTR,
                         (SQLPOINTER)rowStatus,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* select everything from the test table */
  printf("\n  Select all 30 rows from the test table.\n");

  /* execute the statement directly */
  cliRC = SQLExecDirect(hstmt,
                        (SQLCHAR *)"SELECT * FROM fetchScrollTable",
                        SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt,
                     1,
                     SQL_C_CHAR,
                     (SQLPOINTER)rowset[0].col1_val,
                     15,
                     &rowset[0].col1_ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt,
                     2,
                     SQL_C_CHAR,
                     (SQLPOINTER)rowset[0].col2_val,
                     15,
                     &rowset[0].col2_ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_ABSOLUTE at row 15 */
  printf("  SQLFetchScroll with SQL_FETCH_ABSOLUTE at row 15.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }

  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_NEXT */
  printf("  SQLFetchScroll with SQL_FETCH_NEXT.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_NEXT, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n    Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_PRIOR */
  printf("  SQLFetchScroll with SQL_FETCH_PRIOR.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_PRIOR, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_FIRST */
  printf("  SQLFetchScroll with SQL_FETCH_FIRST.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_FIRST, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_LAST */
  printf("  SQLFetchScroll with SQL_FETCH_LAST.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_LAST, 0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* fetch the rowset: row15, row16, row17, row18, row19 */
  printf("\n  Fetch the rowset: row15, row16, row17, row18, row19.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_RELATIVE offset 3 */
  printf("  SQLFetchScroll with SQL_FETCH_RELATIVE offset 3.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_RELATIVE, 3);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* set the bookmark at row 17 */
  printf("\n  Set the bookmark at row 17.\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_ABSOLUTE, 15);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the cursor position in a rowset */
  cliRC = SQLSetPos(hstmt, 3, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get data from a column */
  cliRC = SQLGetData(hstmt, 0, SQL_C_LONG, bookmark.val, 4, &bookmark.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the required statement attributes */
  cliRC = SQLSetStmtAttr(hstmt,
                         SQL_ATTR_FETCH_BOOKMARK_PTR,
                         (SQLPOINTER)bookmark.val,
                         0);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* call SQLFetchScroll with SQL_FETCH_BOOKMARK offset 4 */
  printf("  SQLFetchScroll with SQL_FETCH_BOOKMARK offset 4.\n");
  printf("    COL1          COL2         \n");
  printf("    ------------  -------------\n");

  /* fetch the rowset and return data for all bound columns */
  cliRC = SQLFetchScroll(hstmt, SQL_FETCH_BOOKMARK, 4);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  for (i = 0; i < rowsFetchedNb; i++)
  {
    printf("    %-14s%-14s\n", rowset[i].col1_val, rowset[i].col2_val);
  }
  /* output the row status array if the complete rowset was not returned */
  if (rowsFetchedNb != ROWSET_SIZE)
  {
    printf("    Previous rowset was not full:\n");
    for (i = 0; i < ROWSET_SIZE; i++)
    {
      printf("      Row Status Array[%i] = %s\n",
             i, ROWSTATVALUE[rowStatus[i]]);
    }
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the test table */
  printf("\n  Drop the test table.\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtTable,
                        (SQLCHAR *)"DROP TABLE fetchScrollTable ",
                        SQL_NTS);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtTable);
  STMT_HANDLE_CHECK(hstmtTable, hdbc, cliRC);

  return rc;
} /* TbSelectUsingFetchScrollRowWise */

/* perform a SELECT using Query sampling on a table 
   with different methods */
int TbSelectUsingQuerySampling(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLDOUBLE val;
  } 
  salary; /* variable to get the salary information */

  SQLCHAR *stmt1 = (SQLCHAR *)"SELECT AVG(salary) FROM employee";
  SQLCHAR *stmt2 = (SQLCHAR *)"SELECT AVG(salary) FROM employee "
                              "TABLESAMPLE BERNOULLI(25) REPEATABLE(5)";
  SQLCHAR *stmt3 = (SQLCHAR *)"SELECT AVG(salary) FROM employee "
                              "TABLESAMPLE SYSTEM(50) REPEATABLE(1234)";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS:\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM A SELECT USING QUERY SAMPLING.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nCOMPUTING AVG(salary) WITHOUT SAMPLING \n");

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt1);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);

  printf("\n  Results:\n");
  printf("    AVG SALARY\n");
  printf("    ----------\n");

  /* bind column salary to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_DOUBLE, &salary.val, 0, &salary.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch the avg(salary) value and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("     %.2f \n", salary.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nCOMPUTING AVG(salary) WITH QUERY SAMPLING");
  printf("\n  - ROW LEVEL SAMPLING ");
  printf("\n  - BLOCK LEVEL SAMPLING \n");
  printf("\n  ROW LEVEL SAMPLING : USE THE KEYWORD 'BERNOULLI'\n");
  printf("\nFOR A SAMPLING PERCENTAGE OF P, EACH ROW OF THE TABLE IS\n");
  printf("SELECTED FOR THE INCLUSION IN THE RESULT WITH A PROBABILITY\n");
  printf("OF P/100, INDEPENDENTLY OF THE OTHER ROWS IN T\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt2);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);

  /* bind column salary to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_DOUBLE, &salary.val, 0, &salary.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Results:\n");
  printf("    AVG SALARY\n");
  printf("    ----------\n");

  /* fetch the avg(salary) value and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("     %.2f \n", salary.val);
    
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }    

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  printf("\n\n  BLOCK LEVEL SAMPLING : USE THE KEYWORD 'SYSTEM'\n");
  printf("\nFOR A SAMPLING PERCENTAGE OF P, EACH ROW OF THE TABLE IS\n");
  printf("SELECTED FOR INCLUSION IN THE RESULT WITH A PROBABILITY\n");
  printf("OF P/100, NOT NECESSARILY INDEPENDENTLY OF THE OTHER ROWS\n");
  printf("IN T, BASED UPON AN IMPLEMENTATION-DEPENDENT ALGORITHM\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt3);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);

  /* bind column salary to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_DOUBLE, &salary.val, 0, &salary.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Results:\n");
  printf("    AVG SALARY\n");
  printf("    ----------\n");

  /* fetch the avg(salary) value and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("     %.2f \n", salary.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nREPEATABLE CLAUSE ENSURES THAT REPEATED EXECUTIONS OF THAT\n");
  printf("TABLE REFERENCE WILL RETURN IDENTICAL RESULTS FOR THE SAME \n");
  printf("VALUE OF THE REPEAT ARGUMENT (IN PARENTHESIS). \n");

  return 0;
} /* TbSelectUsingQuerySampling */
