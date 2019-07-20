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
** SOURCE FILE NAME: tbumqt.c                                      
**                                                                        
** SAMPLE:  How to use user materialized query tables (summary tables).
**
**         This sample:
**         1. Creates User Maintained Query Table(UMQT) for the EMPLOYEE
**            table.
**         2. Shows the usage and update mechanisms for UMQTs.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetData -- Get Data From a Column                
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: tbumqt.out (available in the online documentation)
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

int CreateMQT(SQLHANDLE);
int SetIntegrity(SQLHANDLE);
int ShowTableContents(SQLHANDLE);
int DropTables(SQLHANDLE);
int UpdateUserMQT(SQLHANDLE);
int SetRegisters(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS THE USAGE OF USER MAINTAINED MATERIALIZED");
  printf("\nQUERY TABLES(MQTs).\n");

  printf("\n-----------------------------------------------------------\n");

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
  
  /* create Summary Tables */
  rc = CreateMQT(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* bring the summary tables out of check-pending state */
  rc = SetIntegrity(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* populate the base table and update the contents of the summary tables */
  rc = UpdateUserMQT(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* set registers to optimize query processing by routing queries to UMQT */
  rc = SetRegisters(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* issue a select statement that is routed to the summary tables */
  rc = ShowTableContents(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  rc = DropTables(hdbc);
  if (rc != 0)
  {
    return rc;
  }
  
  printf("\n-----------------------------------------------------------\n");

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* create user maintained query table */
int CreateMQT(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE SUMMARY TABLE adefuser AS (SELECT "
                              "workdept, count(*) AS no_of_employees "
                              "FROM employee GROUP BY workdept) "
                              "DATA INITIALLY DEFERRED REFRESH DEFERRED "
                              "MAINTAINED BY USER ";
  
  SQLCHAR *stmt2 = (SQLCHAR *)"CREATE SUMMARY TABLE aimdusr AS (SELECT "
                              "workdept, count(*) AS no_of_employees "
                              "FROM employee GROUP BY workdept) "
                              "DATA INITIALLY DEFERRED REFRESH IMMEDIATE "
                              "MAINTAINED BY USER";

  printf("\n Creating UMQT on EMPLOYEE table...\n");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CREATE USER MAINTAINED QUERY TABLE:\n\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("To create a UMQT with deferred refresh\n");
  printf("\n  Directly execute the statement\n");
  printf("    CREATE SUMMARY TABLE adefuser AS \n");
  printf("      (SELECT workdept, count(*) AS no_of_employees \n");
  printf("         FROM employee GROUP BY workdept)\n");
  printf("      DATA INITIALLY DEFERRED REFRESH DEFERRED\n");
  printf("      MAINTAINED BY USER");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n\nCREATE SUMMARY TABLE to create a UMQT with immediate");
  printf("\nrefresh option is not supported\n\n");
  printf("  Directly execute the statement\n");
  printf("    CREATE SUMMARY TABLE aimdusr AS \n");
  printf("      (SELECT workdept, count(*) AS no_of_employees \n");
  printf("         FROM employee GROUP BY workdept)\n");
  printf("      DATA INITIALLY DEFERRED REFRESH IMMEDIATE\n");
  printf("      MAINTAINED BY USER\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  if (cliRC != SQL_SUCCESS)
  {
    /* to display the expected error */
    printf("\n-- The following error report is expected! --");
    rc = HandleInfoPrint(SQL_HANDLE_STMT, hstmt, cliRC, __LINE__, __FILE__);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  return 0;
} /* CreateMQT */

/* set integrity for the UMQT */
int SetIntegrity(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)"SET INTEGRITY FOR adefuser "
                             "ALL IMMEDIATE UNCHECKED ";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SET INTEGRITY FOR UMQT:\n\n");

  printf("To bring the MQTs out of check pending state\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR adefuser ALL IMMEDIATE UNCHECKED\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  return rc; 
} /* SetIntegrity */

/* to insert values into the UMQT */
int UpdateUserMQT(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
     
  SQLCHAR *stmt = (SQLCHAR *)"INSERT INTO adefuser "
                             "(SELECT workdept, count(*) AS "
                             "no_of_employees FROM employee "
                             "GROUP BY workdept)";
  
  printf("\n-----------------------------------------------------------\n");
  printf("\nadefuser must be updated manually by the user \n");

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO UPDATE THE UMQT:\n");

  printf("\n  Directly execute the statement\n");
  printf("    INSERT INTO adefuser \n");
  printf("      (SELECT workdept, count(*) AS no_of_employees\n");
  printf("         FROM employee GROUP BY workdept)\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  return rc; 
} /* UpdateUserMQT */

/* to set the special registers */
int SetRegisters(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
     
  SQLCHAR *stmt1 = (SQLCHAR *)"SET CURRENT MAINTAINED TABLE TYPES "
                              "FOR OPTIMIZATION USER ";

  SQLCHAR *stmt2 = (SQLCHAR *)"SET CURRENT MAINTAINED TABLE "
                              "TYPES FOR OPTIMIZATION USER";

  /* The CURRENT REFRESH AGE special register must be set to a value other
     than zero for the specified table types to be considered when 
     optimizing the processing of dynamic SQL queries. */
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SET REGISTERS:\n\n");

  printf("The following registers must be set to route queries to UMQT\n");
  printf("\n  Directly execute the statement");
  printf("\n    SET CURRENT REFRESH AGE ANY\n");
  printf("\nIndicates that any table types specified by ");
  printf("CURRENT MAINTAINED \n");
  printf("TABLE TYPES FOR OPTIMIZATION, and MQTs defined with REFRESH \n");
  printf("IMMEDIATE option, can be used to optimize the \n");
  printf("processing of a query. \n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION USER \n\n");
  printf("Specifies that user-maintained refresh-deferred materialized \n");
  printf("query tables can be considered to optimize the processing of \n");
  printf("dynamic SQL queries. \n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* SetRegisters */

/* to display the contents of the table */
int ShowTableContents(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
     
  SQLCHAR *stmt1 = (SQLCHAR *)"SELECT workdept, count(*) AS "
                              "no_of_employees FROM employee "
                              "GROUP BY workdept";

  SQLCHAR *stmt2 = (SQLCHAR *)"SELECT  workdept, no_of_employees "
                              "FROM adefuser"; 

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  workdept; /* variable to get data from the workdept column */

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  no_of_employees; /* variable to get data from the count(*) */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO DISPLAY CONTENTS OF THE TABLE:\n\n");
  
  printf("On EMPLOYEE table. This is routed to the UMQT adefuser\n");
  printf("\n  Directly execute the statement\n");
  printf("    SELECT workdept, count(*) AS no_of_employees \n");
  printf("      FROM employee GROUP BY workdept\n\n");
  printf("  DEPT CODE   NO. OF EMPLOYEES     \n");
  printf("  ----------  ----------------\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* get data from column 1 */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       workdept.val,
                       15,
                       &workdept.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_SHORT,
                       &no_of_employees.val,
                       0,
                       &no_of_employees.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* display */
    printf("    %7s %17d \n", workdept.val, no_of_employees.val);
    
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n\nA SELECT query on adefuser yields similar results\n");
  printf("\n  Directly execute the statement\n");
  printf("    SELECT workdept,no_of_employees FROM adefuser \n\n");
  printf("  DEPT CODE   NO. OF EMPLOYEES     \n");
  printf("  ----------  ----------------\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* get data from column 1 */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       workdept.val,
                       15,
                       &workdept.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_SHORT,
                       &no_of_employees.val,
                       0,
                       &no_of_employees.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* display */
    printf("    %7s %17d \n", workdept.val, no_of_employees.val);
    
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  return rc;
} /* ShowTableContents */

/* to drop the table */
int DropTables(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt = (SQLCHAR *)"DROP TABLE adefuser";

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO DROP USER MAINTAINED QUERY TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nDropping tables...\n");
  printf("\n  Directly execute the statement\n");
  printf("    DROP TABLE adefuser\n");
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DropTables */
