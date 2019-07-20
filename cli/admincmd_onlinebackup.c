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
** SOURCE FILE NAME: admincmd_onlinebackup.c                                     
**                                                                        
** SAMPLE: How to perform online backup using ADMIN_CMD() routines. 
**
**         This sample should be run using the following steps:
**
**         1.Create and populate the "sample" database with the following command:
**         db2sampl
**
**         2.Set the DB CFG parameter LOGARCHMETH1 LOGRETAIN 
**    
**         3.Set the DB CFG parameter LOGARCHMETH2 OFF 
**
**         4.Do an offline BACKUP of SAMPLE database
**
**         5.Compile the program with the following command:
**         bldapp admincmd_onlinebackup 
**
**         6.Run this sample with the following command:
**             admincmd_onlinebackup <path for backup>
**         The path being given for backup should be an absolute path.
**
** Note:   User needs either SYSADM, SYSCTRL or SYSMAINT authorization to set
**         the DB CFG parameters & for backing up the database.
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare a Statement
**
** OUTPUT FILE: admincmd_onlinebackup.out (available in the online 
**                                         documentation)
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
#include <sqlutil.h>
#include <sqlenv.h>
#include <db2ApiDf.h>
#include "utilcli.h" /* Header file for CLI sample code */

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv;  /* environment handle */
  SQLHANDLE hdbc;  /* connection handle */
  SQLHANDLE hstmt; /* statement handles */
  
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD (?)"; /* statement */
  char inparam[300] = {0}; /* parameter to be passed  */
                           /* to the stored procedure */      
  char backup_time[SQLU_TIME_STAMP_LEN + 1] = { 0 };
  
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];
  char path[SQL_PATH_SZ + 1] = { 0 };

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
      printf("\n Missing input arguments. Enter the path for backup \n");
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
  
  printf("\nTHIS SAMPLE SHOWS HOW TO DO ONLINE BACKUP USING ADMIN_CMD.\n");

  /* initialize the CLI application by calling a helper */
  /* utility function defined in utilcli.c              */
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
 
  /* execute backup database */
  sprintf(inparam, "BACKUP DB SAMPLE To %s", path);

  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   
  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, backup_time, 15, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if(cliRC != SQL_NO_DATA_FOUND) 
  {
    /* display each row */
    printf("\n");
    printf("Backup_Time = %s\n", backup_time);
  }
  else
  {
    printf("\n");
    printf("NO DATA FOUND\n");  
  }

  printf("\nThe onlinebackup completed successfully\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
  utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */
