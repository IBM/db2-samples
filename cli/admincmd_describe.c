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
** SOURCE FILE NAME: admincmd_describe.c                                     
**                                                                        
** SAMPLE: How to do describe table and indexes using ADMIN_CMD routines.
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle   -- Allocate Handle
**         SQLBindCol       -- Bind a Column to an Application Variable or
**                             LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLExecDirect    -- Execute a Statement Directly
**         SQLExecute       -- Execute a Statement
**         SQLFetch         -- Fetch Next Row
**         SQLFreeHandle    -- Free Handle Resources
**         SQLPrepare       -- Prepare a Statement
**
** OUTPUT FILE: admincmd_describe.out (available in the online documentation)
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
  SQLHANDLE hstmt1, hstmt2, hstmt3, hstmt4; /* statement handles */
  
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD (?)"; /* statement */
  SQLCHAR *stmt_inx_c = (SQLCHAR *)"CREATE INDEX INDEX1 ON "
                                 "EMPLOYEE (LASTNAME ASC)";
  SQLCHAR *stmt_inx_d = (SQLCHAR *) " DROP INDEX index1 ";

  char inparam[300] = {0} ; /* parameter to be passed 
                               to the stored procedure */      
  
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  SQLCHAR colname[128]= {0};
  SQLCHAR typeschema[128] = {0};
  SQLCHAR typename[256] = {0}; 
  SQLINTEGER length;
  SQLSMALLINT scale;
  SQLCHAR nullable[2] = {0};

  SQLCHAR indschema[128] = {0};
  SQLCHAR indname[128] = {0};
  SQLCHAR unique_rule[30] = {0};
  SQLSMALLINT colcount;
   
  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

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
  
  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
 
  printf("\n THIS SAMPLE SHOWS HOW TO EXECUTE DESCRIBE ");
  printf("TABLE AND INDEX\n");

  /* allocate the handle for statement */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, cliRC);
 
  /* allocate the handle for statement */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate the handle for statement */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate the handle for statement */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt4);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Executing ");
  printf("CREATE INDEX INDEX1 ON EMPLOYEE (LASTNAME ASC)\n");
  
  /* create index index1 */
  cliRC = SQLExecDirect(hstmt1, stmt_inx_c, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* execute describe table */
  strcpy(inparam, "DESCRIBE TABLE EMPLOYEE");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt2, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt2,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
   
  /* bind column name to variable */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_CHAR, colname, 128, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind type schema to variable */
  cliRC = SQLBindCol(hstmt2, 2, SQL_C_CHAR, typeschema, 128, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind type name to variable */
  cliRC = SQLBindCol(hstmt2, 3, SQL_C_CHAR, typename, 128, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind length to variable */
  cliRC = SQLBindCol(hstmt2, 4, SQL_C_SBIGINT, &length, 0, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind scale to variable */
  cliRC = SQLBindCol(hstmt2, 5, SQL_C_SHORT, &scale, 0, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
 
  /* bind nullable to variable */
  cliRC = SQLBindCol(hstmt2, 6, SQL_C_CHAR, nullable, 1, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  
  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt2); 
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    /* display each row */
    printf("\n");
    printf("Colname    = %s\n" ,colname);
    printf("Typeschema = %s\n", typeschema);
    printf("Typename   = %s\n", typename);
    printf("Length     = %d\n", length);
    printf("Scale      = %d\n", scale); 
    printf("Nullable   = %s\n", nullable); 
   
    /* fetch next row */
    cliRC = SQLFetch(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  }

  /* execute describe index */
  strcpy(inparam, "DESCRIBE INDEXES FOR TABLE EMPLOYEE");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt3, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt3,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
   
  /* bind index schema to variable */
  cliRC = SQLBindCol(hstmt3, 1, SQL_C_CHAR, indschema, 128, NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* bind index name  to variable */
  cliRC = SQLBindCol(hstmt3, 2, SQL_C_CHAR, indname, 128, NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* bind unique rule to variable */
  cliRC = SQLBindCol(hstmt3, 3, SQL_C_CHAR, unique_rule, 30, NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* bind column count to variable */
  cliRC = SQLBindCol(hstmt3, 4, SQL_C_SHORT, &colcount, 0, NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt3); 
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    /* display each row */
    printf("\n");
    printf("Indschema   = %s\n", indschema);
    printf("Indname     = %s\n", indname );
    printf("Unique_rule = %s\n", unique_rule);
    printf("Colcount    = %d\n", colcount);
  
    /* fetch next row */
    cliRC = SQLFetch(hstmt3);
    STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  }

  printf("\nExecuting ");
  printf(" DROP INDEX INDEX1 \n");
  
  /* drop index index1 */
  cliRC = SQLExecDirect(hstmt4, stmt_inx_d, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt4);
  STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
  utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */

