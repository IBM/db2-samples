/***************************************************************************/
//  (c) Copyright IBM Corp. 2007 All rights reserved.
//
//  The following sample of source code ("Sample") is owned by International
//  Business Machines Corporation or one of its subsidiaries ("IBM") and is
//  copyrighted and licensed, not sold. You may use, copy, modify, and
//  distribute the Sample in any form without payment to IBM, for the purpose of
//  assisting you in the development of your applications.
//
//  The Sample code is provided to you on an "AS IS" basis, without warranty of
//  any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
//  IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
//  not allow for the exclusion or limitation of implied warranties, so the above
//  limitations or exclusions may not apply to you. IBM shall not be liable for
//  any damages you suffer as a result of using, copying, modifying or
//  distributing the Sample, even if IBM has been advised of the possibility of
//  such damages.
/***************************************************************************/
/*                                                                         */
/* SAMPLE FILE NAME: ssv_db_cfg.c                                          */
/*                                                                         */
/* PURPOSE         : This sample demonstrates updating & resetting         */
/*                   database configuration parameters in a Massively      */
/*                   Parallel Processing (MPP) environment.                */
/*                                                                         */
/* USAGE SCENARIO  : This sample demonstrates different options of         */
/*                   updating & resetting database configuration parameters*/
/*                   in an MPP environment. In an MPP environment, database*/
/*                   configuration parameters can either be updated or     */
/*                   resetted on a single database partition or on all     */
/*                   database partitions at once. The sample will use the  */
/*                   DB CFG parameter 'MAXAPPLS', to demonstrate different */
/*                   UPDATE & RESET db cfg command options.                */
/*                                                                         */
/* PREREQUISITE    : MPP setup with 3 database partitions:                 */
/*                     NODE 0: Catalog Node                                */
/*                     NODE 1: Non-catalog node                            */
/*                     NODE 2: Non-catalog node                            */
/*                                                                         */
/* EXECUTION       : ssv_db_cfg [dbalias [username password]]              */
/*                                                                         */
/* INPUTS          : NONE                                                  */
/*                                                                         */
/* OUTPUT          : Successful update of database configuration           */
/*                   parameters on different database partitions.          */
/*                                                                         */
/* OUTPUT FILE     : ssv_db_cfg.out                                        */
/*                   (available in the online documentation)               */
/***************************************************************************/
/*For more information about the command line processor (CLP) scripts,     */
/*see the README file.                                                     */
/*For information on using SQL statements, see the SQL Reference.          */
/*                                                                         */
/*For the latest information on programming, building, and running DB2     */
/*applications, visit the DB2 application development website:             */
/*http://www.software.ibm.com/data/db2/udb/ad                              */
/***************************************************************************/

/***************************************************************************/
/* SAMPLE DESCRIPTION                                                      */
/***************************************************************************/
/* 1. Update DB CFG parameter on all database partitions at once.          */
/* 2. Update DB CFG parameter on specified database partition              */
/* 3. Reset DB CFG parameter on specified database partition               */
/* 4. Reset DB CFG parameter on all database partitions at once            */
/***************************************************************************/

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

  char inparam[300] = {0}; /* parameter to be passed 
                              to the stored procedure */      

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

/***************************************************************************/
/*   SETUP                                                                 */
/***************************************************************************/
  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO UPDATE DB CFG PARAMETERS IN AN "
         "MPP ENVIRONMENT.\n");

  /* initialize the CLI application by calling a helper  */
  /* utility function defined in utilcli.c               */
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

/***************************************************************************/
/* 1. Update DB CFG parameter on all database partitions at once           */
/***************************************************************************/

  printf(
    "\n****************************************************************\n");
  printf(
    "** UPDATE DB CFG PARAMETER 'MAXAPPLS' ON ALL DATABASE PARTITIONS **");
  printf(
    "\n****************************************************************\n");

  /* update the Database configuration Parameter MAXAPPLS to 50 on all  */
  /* database partitions at once                                        */
  strcpy(inparam, "UPDATE DB CFG FOR SAMPLE USING MAXAPPLS 50");
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

  printf("\nThe DB CFG parameter is updated successfully on all "
         "database partitions.\n");

/***************************************************************************/
/* 2. Update DB CFG parameter on specified database partition              */
/***************************************************************************/

  printf(
    "\n****************************************************************\n");
  printf(
    "** UPDATE DB CFG PARAMETER 'MAXAPPLS' ON DATABASE PARTITION 1 **\n");
  printf(
    "******************************************************************\n");

  /* update the Database configuration Parameter MAXAPPLS to 100 on */
  /* database partition 1                                           */
  strcpy(inparam, 
         "UPDATE DB CFG FOR SAMPLE DBPARTITIONNUM 1 USING MAXAPPLS 100");
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

  printf("\nThe DB CFG parameter is updated successfully on "
         "database partition 1.\n");

/***************************************************************************/
/* 3. Reset DB CFG parameter on specified database partition               */
/***************************************************************************/

  printf(
    "\n*****************************************************************\n");
  printf(
    "** RESET DB CFG PARAMETER 'MAXAPPLS' ON DATABASE PARTITION 1  **\n");
  printf(
    "*******************************************************************\n");

  /* reset the Database configuration Parameter MAXAPPLS  */
  /* on database partition 1                              */
  strcpy(inparam, "RESET DB CFG FOR SAMPLE DBPARTITIONNUM 1");
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

  printf("\nThe DB CFG parameter is resetted successfully on "
         "database partition 1.\n");

/***************************************************************************/
/* 4. Reset DB CFG parameter on all database partitions at once            */
/***************************************************************************/

  printf(
    "\n*****************************************************************\n");
  printf(
    "** RESET DB CFG PARAMETER 'MAXAPPLS' ON ALL DATABASE PARTITIONS **\n");
  printf(
    "*******************************************************************\n");

  /* reset the Database configuration Parameter MAXAPPLS on */
  /* all database partitions                                */
  strcpy(inparam, "RESET DB CFG FOR SAMPLE");
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

  printf("\nThe DB CFG parameter is resetted successfully on all "
         "database partitions.\n");

/***************************************************************************/
/* CLEANUP                                                                 */
/***************************************************************************/

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
