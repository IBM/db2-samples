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
** SOURCE FILE NAME: dtinfo.c                                       
**                                                                        
** SAMPLE: How get information about data types
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetTypeInfo -- Get Data Type Information
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: dtinfo.out (available in the online documentation)
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
#include "utilcli.h" /* header file for CLI sample code */

int DtInfoGet(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO GET INFORMATION ABOUT DATA TYPES.\n");

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias, user, pswd, &henv, &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_ON);
  if (rc != 0)
  {
    return rc;
  }

  /* get data type information */
  rc = DtInfoGet(hdbc);
  
  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);
  
  return rc;
} /* main */

/* get information about supported data types */
int DtInfoGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  dtName;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  dtCode, dtNullable, dtCaseSens;

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  dtPrecision;

  SQLINTEGER count = 0;
  char truefalse[2][6] = { {"FALSE"}, {"TRUE"} };

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLGetTypeInfo\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET INFORMATION ABOUT SUPPORTED DATA TYPES:\n");

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
  printf("\n  Call SQLGetTypeInfo.\n");

  /* get data type information */
  cliRC = SQLGetTypeInfo(hstmt, SQL_ALL_TYPES);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt,
                     1,
                     SQL_C_CHAR,
                     (SQLPOINTER)dtName.val,
                     129,
                     &dtName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt,
                     2,
                     SQL_C_DEFAULT,
                     (SQLPOINTER)&dtCode.val,
                     sizeof(dtCode.val),
                     &dtCode.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_DEFAULT,
                     (SQLPOINTER)&dtPrecision.val,
                     sizeof(dtPrecision.val),
                     &dtPrecision.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt,
                     7,
                     SQL_C_DEFAULT,
                     (SQLPOINTER)&dtNullable.val,
                     sizeof(dtNullable.val),
                     &dtNullable.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 8 to variable */
  cliRC = SQLBindCol(hstmt,
                     8,
                     SQL_C_DEFAULT,
                     (SQLPOINTER)&dtCaseSens.val,
                     sizeof(dtCaseSens.val),
                     &dtCaseSens.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  printf("\n  Fetch each row and display.\n");
  printf("  ");
  printf("Datatype                  Datatype Precision  Nullab. Case\n");
  printf("  ");
  printf("Typename                   (int)                      Sensit.\n");
  printf("  ");
  printf("------------------------- -------- ---------- ------- -------\n");

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("  ");
    printf("%-25s ", dtName.val);
    printf("%8d ", dtCode.val);
    printf("%10ld ", dtPrecision.val);
    printf("%-7s ", truefalse[dtNullable.val]);
    printf("%-7s\n", truefalse[dtCaseSens.val]);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DtInfoGet */

