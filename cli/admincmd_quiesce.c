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
** SOURCE FILE NAME: admincmd_quiesce.c                                     
**                                                                        
** SAMPLE: How to quiesce tablespaces and database using ADMIN_CMD() routines.
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle   -- Allocate Handle
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLExecute       -- Execute a Statement
**         SQLFreeHandle    -- Free Handle Resources
**         SQLPrepare       -- Prepare a Statement
**
** OUTPUT FILE: admincmd_quiesce.out (available in the online documentation)
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
  SQLHANDLE hstmt1, hstmt2, hstmt3, hstmt4; /* statement handle */

  /* statement to be used to prepare embedded SQL statements */
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD (?)";
  
  char inparam[300] = {0}; /* parameter to be 
                              passed to the stored procedure */      
  
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO QUIESCE TABLESPACES ");
  printf("AND THE DATABASE USING ADMIN_CMD.\n");
  
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

  /* quiesce tablespaces for empoyee table */
  strcpy(inparam, "QUIESCE TABLESPACES FOR TABLE employee EXCLUSIVE");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt1, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt1,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0,
                           inparam,
                           300,
                           NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
   
  printf("The quiesce tablespaces for employee table done successfully\n");
  
  /* quiesce reset of tablespaces of employee table */
  strcpy(inparam, "QUIESCE TABLESPACES FOR TABLE employee RESET");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt2, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
 
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt2,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0,
                           inparam,
                           300,
                           NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
   
  printf("The quiesce reset of tablespaces done successfully.\n");

  /* quiesce database  */
  strcpy(inparam, "QUIESCE DATABASE IMMEDIATE");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt3, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt3,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0,
                           inparam,
                           300,
                           NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
   
  printf("The quiesce database done successfully.\n");

  /* unquiesce database */
  strcpy(inparam, "UNQUIESCE DB");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt4, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt4,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0,
                           inparam,
                           300,
                           NULL);
  STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt4);
  STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);
   
  printf("The unquiesce database done successfully\n");
 
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
} /* end of main */

