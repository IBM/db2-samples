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
** SOURCE FILE NAME: admincmd_autoconfigure.c                                     
**                                                                        
** SAMPLE: How to autoconfigure a database
**         
** CLI FUNCTIONS USED:
**         SQLAllocHandle   -- Allocate Handle
**         SQLBindCol       -- Bind a Column to an Application Variable or
**                             LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLExecute       -- Execute a Statement
**         SQLFetch         -- Fetch Next Row
**         SQLFreeHandle    -- Free Handle Resources
**         SQLPrepare       -- Prepare a Statement
**
** OUTPUT FILE: admincmd_autoconfigure.out (available in the online 
**                                          documentation)
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

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv;  /* environment handle */
  SQLHANDLE hdbc;  /* connection handle  */
  SQLHANDLE hstmt; /* statement handle   */
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD (?)";
  
  char inparam[300] = {0}; /* parameter to be passed to
                              the stored procedure */
  
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* declaring variables to store the columns values returned by ADMIN_CMD */
  SQLCHAR level[3] = {0};
  SQLCHAR name[128] = {0};
  SQLCHAR value[256] = {0}; 
  SQLCHAR recommended_value[256] = {0};
  SQLCHAR datatype[128] = {0};

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO AUTOCONFIGURE");
  printf(" USING ADMIN_CMD\n");
  
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
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* autoconfiguring the isolation level to RS */
  /* the default value of isolation level is RR */
  strcpy(inparam, "AUTOCONFIGURE USING ISOLATION RS APPLY DB ONLY");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0,
                           inparam,
                           300,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   
  /* bind level to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, level, 3, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter name to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, name, 128, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind value to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, value, 256, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind recommended value to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, recommended_value, 256, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* bind datatype to variable */
  cliRC = SQLBindCol(hstmt, 5, SQL_C_CHAR, datatype, 128, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    /* display each row */
    printf("\n");
    printf("Level             = %s\n", level);
    printf("Name              = %s\n", name);
    printf("Value             = %s\n", value);
    printf("Recommended_value = %s\n", recommended_value);
    printf("Datatype          = %s\n", datatype); 

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  printf("\nThe Autoconfiguration is done successfully.\n");
 
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */
