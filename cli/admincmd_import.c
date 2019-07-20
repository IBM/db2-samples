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
** SOURCE FILE NAME: admincmd_import.c                               
**                                                                        
** SAMPLE: How to do import using ADMIN_CMD() routines.
**
**         1.Compile the program with the following command:
**           bldapp admincmd_import 
**
**         2.The sample should be run using the following command
**           admincmd_import <path for file to be imported>
**           The fenced user id must be able to read the source file 
**           specified. The absolute path of the file on the server must be
**           specified. The path must include '\' or '/' in the end according
**           to the platform. 
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
** OUTPUT FILE: admincmd_import.out (available in the online documentation)
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
#include <sqlenv.h>
#include "utilcli.h" /* Header file for CLI sample code */

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];
  char path[SQL_PATH_SZ + 1] = { 0 };

  SQLHANDLE henv;   /* environment handle */
  SQLHANDLE hdbc;   /* connection handle  */
  SQLHANDLE hstmt1; /* statement handle   */
  SQLHANDLE hstmt2; /* statement handle   */
  SQLHANDLE hstmt3; /* statement handle   */
  
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD (?)"; /* statement */
  char inparam[300] = {0}; /* parameter to be passed 
                              to the stored procedure */      

  /* following variables are to be used to bind to the table columns
     for SQLFetch function. */
  struct
  {
    SQLINTEGER ind;
    SQLBIGINT val;
  } rows_read, rows_skipped, rows_loaded,
    rows_rejected, rows_deleted, rows_committed;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[512];
  } msg_retrieval, msg_removal; 

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

  /* check the command line arguments */
  switch (argc)
  {
    case 2:
      strcpy(dbAlias, "sample");
      strcpy(user, "");
      strcpy(pswd, "");
      strcpy(path, argv[1]);
      break;
    case 3:
      strcpy(dbAlias, argv[1]);
      strcpy(user, "");
      strcpy(pswd, "");
      strcpy(path, argv[2]);
      break;
    case 5:
      strcpy(dbAlias, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      strcpy(path, argv[4]);
      break;
    default:
      printf("\n Missing input arguments. Enter the absolute path of the "
             "file to be imported \n");
      printf("\nUSAGE: %s "
             "[dbAlias [user pswd]] Path\n",
             argv[0]);
      rc = 1;
      break;
  }
  if (rc != 0)
  {
    return rc;
  } 

  printf("\nTHIS SAMPLE SHOWS HOW TO DO IMPORT USING ADMIN_CMD.\n");

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c              */
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

  /* execute import */
  sprintf(inparam, "IMPORT FROM %sorg_ex.ixf", path);
  strcat(inparam, " OF IXF MESSAGES ON SERVER CREATE INTO org_import");

  printf("\nCALL ADMIN_CMD('IMPORT FROM %sorg_ex.ixf\n", path);
  printf("                  OF IXF MESSAGES ON SERVER\n");
  printf("                  CREATE INTO org_import')\n");

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

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt1,
                     1,
                     SQL_C_SBIGINT,
                     &rows_read.val,
                     0,
                     &rows_read.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt1,
                     2,
                     SQL_C_SBIGINT,
                     &rows_skipped.val,
                     0,
                     &rows_skipped.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt1,
                     3,
                     SQL_C_SBIGINT,
                     &rows_loaded.val,
                     0,
                     &rows_loaded.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt1,
                     4,
                     SQL_C_SBIGINT,
                     &rows_rejected.val,
                     0,
                     &rows_rejected.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt1,
                     5,
                     SQL_C_SBIGINT,
                     &rows_deleted.val,
                     0,
                     &rows_deleted.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt1,
                     6,
                     SQL_C_SBIGINT,
                     &rows_committed.val,
                     0,
                     &rows_committed.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt1,
                     7,
                     SQL_C_CHAR,
                     msg_retrieval.val,
                     512,
                     &msg_retrieval.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 8 to variable */
  cliRC = SQLBindCol(hstmt1,
                     8,
                     SQL_C_CHAR,
                     msg_removal.val,
                     512,
                     &msg_removal.ind);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt1); 
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  if(cliRC != SQL_NO_DATA_FOUND) 
  {
    /* display each row */
    printf("\n");
    printf("Rows_read      = %d\n", rows_read.val);
    printf("Rows_skipped   = %d\n", rows_skipped.val);
    printf("Rows_loaded    = %d\n", rows_loaded.val);
    printf("Rows_rejected  = %d\n", rows_rejected.val);
    printf("Rows_deleted   = %d\n", rows_deleted.val);
    printf("Rows_committed = %d\n", rows_committed.val);
  }
  else
  {
    printf("\n");
    printf("NO DATA FOUND\n");  
  }

  /* message retrieval */
  printf("\nExecuting\n"
         "  %s\n" , msg_retrieval.val);  

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt2, msg_retrieval.val, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_CHAR, sqlcode.val, 32, &sqlcode.ind);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt2, 2, SQL_C_CHAR, msg.val, 1024, &msg.ind);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* fetch each row and display */
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
    printf("SQLCODE: %s\n", sqlcode.val);
    printf("MSG: %s\n", msg.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  }

  /* message removal */
  printf("\n%s\n", msg_removal.val);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt3, msg_removal.val, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
    
  /* execute the statement */
  cliRC = SQLExecute(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC); 

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
  utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */

