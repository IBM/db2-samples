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
** SOURCE FILE NAME: tbcompress.c                                      
**                                                                        
** SAMPLE: How to create tables with null and default value compression 
**         option 
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**                                                                        
** OUTPUT FILE: tbcompress.out (available in the online documentation)
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

int TbCreate(SQLHANDLE);
int TbCompress(SQLHANDLE);
int TbDrop(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* checks the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO USE NULL AND DEFAULT VALUE\n");
  printf("COMPRESSION OPTION AT TABLE LEVEL AND COLUMN LEVEL.\n");

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

  /* create the table */ 
  rc = TbCreate(hdbc);

  /* enable the compression option at table level */ 
  rc = TbCompress(hdbc);

  /* drop the table */
  rc = TbDrop(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* create the comp_tab table */ 
int TbCreate(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = 
    (SQLCHAR *)"CREATE TABLE COMP_TAB(Col1 INT NOT NULL WITH DEFAULT, "
               "Col2 CHAR(7), "
               "Col3 VARCHAR(7) NOT NULL, "
               "Col4 DOUBLE)";

  printf("\n-----------------------------------------------------------");
  printf("\nCreating table COMP_TAB\n\n");
  printf("USE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO CREATE A TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create the table */
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE COMP_TAB(Col1 INT NOT NULL WITH DEFAULT,\n");
  printf("                          Col2 CHAR(7),\n");
  printf("                          Col3 VARCHAR(7) NOT NULL,\n");
  printf("                          Col4 DOUBLE)\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbCreate */

/* how to enable the compress option on table level */
int TbCompress(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt1 = (SQLCHAR *)"ALTER TABLE COMP_TAB ACTIVATE "
                              "VALUE COMPRESSION";
  SQLCHAR *stmt2 = (SQLCHAR *)"ALTER TABLE COMP_TAB ALTER Col1 COMPRESS "
                              "SYSTEM DEFAULT";
  SQLCHAR *stmt3 = (SQLCHAR *)"ALTER TABLE COMP_TAB DEACTIVATE "
                              "VALUE COMPRESSION";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO ALTER A TABLE FOR COMPRESSION OPTION:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n To activate VALUE COMPRESSION at table level and COMPRESS \n");
  printf(" SYSTEM DEFAULT at column level \n\n");

  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE COMP_TAB ACTIVATE VALUE COMPRESSION \n\n");
  printf(" Rows will be formatted using the new row format on subsequent\n");
  printf(" insert, load and update operation, and NULL values will not be\n");
  printf(" taking up space if applicable.\n\n");

  /* If the table COMP_TAB does not have many NULL values, enabling
     compression will result in using more disk space than using
     the old row format */

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  printf("\n To save more disk space on system default value for column\n");
  printf(" Col1, enter\n");
  
  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE COMP_TAB ALTER Col1 COMPRESS SYSTEM DEFAULT\n");
  printf("\n On subsequent insert, load, and update operations,numerical\n");
  printf(" 0 value (occupying 4 bytes of storage) for column Col1 will\n");
  printf(" not be saved on disk.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n\n To switch the table to use the old format, enter\n");
  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE COMP_TAB DEACTIVATE VALUE COMPRESSION\n\n");
  printf(" Rows inserted, loaded or updated after the ALTER statement\n");
  printf(" will have old row format.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbCompress */

/* drop the table comp_tab */
int TbDrop(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)"DROP TABLE COMP_TAB";

  printf("\n-----------------------------------------------------------");
  printf("\nDropping table COMP_TAB\n\n");
  printf("USE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO DROP A TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* drop the table */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* TbDrop */
