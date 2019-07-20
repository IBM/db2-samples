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
** SOURCE FILE NAME: admincmd_export.c                                     
**                                                                        
** SAMPLE: How to export data using ADMIN_CMD() routines.
** 
**         This sample should be run using the following steps:
**         1. Compile the program with the following command:
**            bldapp admincmd_export 
**
**         2. The sample should be run using the following command:
**            admincmd_export <path for export>
**            The fenced user id must be able to create or overwrite files in
**            the target export directory specified. This directory must 
**            be a full path on the server. The path must include '\' or '/'
**            in the end according to the platform.  The file for export must
**            exist before the sample is run. 
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
** OUTPUT FILE: admincmd_export.out (available in the online documentation)
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
  SQLHANDLE henv;                   /* environment handle */
  SQLHANDLE hdbc;                   /* connection handle */
  SQLHANDLE hstmt1, hstmt2, hstmt3; /* statement handles */
  
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD (?)"; /* statement */
  char inparam[300] = {0}; /* parameter to be passed 
                              to the stored procedure */      

  SQLINTEGER rows_exported;
  SQLCHAR msg_retrieval[512] = {0}; 
  SQLCHAR msg_removal[512] = {0};

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[9];
  }
  sqlcode; /* variable to be bound to the SQLCODE column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[1024];
  }
  msg; /* variable to be bound to the MSG column */

  /* intilazing the database name */
  strcpy(dbAlias, "sample");
  strcpy(user, "");
  strcpy(pswd, "");

  if (argc < 2 )
  {
    printf("\n Usage: admincmd_export <absolute path for export>\n");
    rc = -1;
    return rc;
  } 
  
  printf("\nTHIS SAMPLE SHOWS HOW TO DO EXPORT USING ADMIN_CMD.\n");

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

  /* argv[1] is the absolute path where the exported file will be stored */
  sprintf(inparam, "EXPORT TO %sorg_ex.ixf ", argv[1]);
  strcat(inparam, "OF IXF MESSAGES ON SERVER SELECT * FROM org");

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
  
   /* execute export command */
  cliRC = SQLExecute(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
   
  /* the numbers of rows being exported */
  /* bind row_exported to a variable */
  cliRC = SQLBindCol(hstmt1, 1, SQL_C_SBIGINT, &rows_exported, 0, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* retrieve the select stmt for message retrival */ 
  /* containing SYSPROC.ADMIN_GET_MSGS */
  /* bind msg_retrieval to variable */
  cliRC = SQLBindCol(hstmt1, 2, SQL_C_CHAR, msg_retrieval, 512, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* retrieve the stmt for message cleanup */
  /* containing CALL of SYSPROC.ADMIN_REMOVE_MSGS */
  /* bind msg_removal 3 to variable */
  cliRC = SQLBindCol(hstmt1, 3, SQL_C_CHAR, msg_removal, 512, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt1); 
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  if (cliRC != SQL_NO_DATA_FOUND) 
  {
    /* display the record returned by export */
    printf("\n");
    printf("Total number of rows exported   : %d\n", rows_exported);
    printf("SQL for retrieving the messages : %s\n", msg_retrieval); 
    printf("SQL for removing the messages   : %s\n", msg_removal);
  }
  else
  {
    printf("\n");
    printf("NO DATA FOUND\n");  
  }

  printf("\nExecuting %s\n", msg_retrieval);  
 
  /* retrieval of error message and error code*/  
  cliRC = SQLExecDirect(hstmt2, msg_retrieval, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind sqlcode to variable */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_CHAR, sqlcode.val, 32, &sqlcode.ind);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind error message to variable */
  cliRC = SQLBindCol(hstmt2, 2, SQL_C_CHAR, msg.val, 1024, &msg.ind);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* fetch and display each row */
  cliRC = SQLFetch(hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* display each row */
    printf("\n");
    printf("SQLCODE : %s\n", sqlcode.val);
    printf("MSG     : %s\n", msg.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  }

  printf("\nExecuting %s\n", msg_removal);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt3, msg_removal, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* removal of messages in server*/
  /* execute the statement */
  cliRC = SQLExecute(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC); 

  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
  utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */
