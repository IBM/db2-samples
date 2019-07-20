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
** SOURCE FILE NAME: tbast.c                                      
**                                                                        
** SAMPLE:  How to use staging table for updating deferred AST 
**          
**         This sample:
**         1. Creates a refresh-deferred summary table 
**         2. Creates a staging table for this summary table 
**         3. Applies contents of staging table to AST
**         4. Restores the data in a summary table  
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLGetData -- Get Data From a Column                
**
** OUTPUT FILE: tbast.out (available in the online documentation)
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

int CreateStagingTable(SQLHANDLE);
int PropagateStagingToAst(SQLHANDLE);
int RestoreSummaryTable(SQLHANDLE);
int DisplayTable(SQLHANDLE,char *);
int DropTables(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS THE USAGE OF STAGING TABLE TO UPDATE"); 
  printf("\nREFRESH DEFERRED AST AND RESTORE DATA IN A SUMMARY TABLE\n");
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
  
  /* create a base table, summary table, staging table */
  rc = CreateStagingTable(hdbc);
  if (rc != 0)
  {
    return rc;
  }
 
  printf("\n-----------------------------------------------------------\n");

  /* to show the propagation of changes of base table to
     summary tables through the staging table */
  printf("To show the propagation of changes from base table to\n");
  printf("summary tables through the staging table:\n");

  rc = PropagateStagingToAst(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  printf("\n------------------------------------------------------------\n");
  
  /* to show restoring of data in a summary table */

  printf("\nTo show restoring of data in a summary table\n");
  rc = RestoreSummaryTable(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* drop the created tables */
  printf("\nDrop the created tables\n");

  rc = DropTables(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* creates base table, summary table and staging table */
int CreateStagingTable(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE TABLE T (C1 SMALLINT NOT NULL, "
                              "                C2 SMALLINT NOT NULL, "
                              "                C3 SMALLINT, C4 SMALLINT)";
  
  SQLCHAR *stmt2 = (SQLCHAR *)"CREATE SUMMARY TABLE D_AST AS "
                              "(SELECT C1, C2, COUNT(*) AS COUNT "
                              "FROM T GROUP BY C1, C2) DATA "
                              "INITIALLY DEFERRED REFRESH DEFERRED"; 

  SQLCHAR *stmt3 = (SQLCHAR *)"CREATE TABLE G FOR D_AST PROPAGATE "
                              "IMMEDIATE";

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CREATE BASE TABLE, SUMMARY TABLE, STAGING TABLE:\n");

  printf("\nCreating the base table T\n");
 
  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE T\n");
  printf("      (C1 SMALLINT NOT NULL, C2 SMALLINT NOT NULL, \n");
  printf("       C3 SMALLINT, C4 SMALLINT)\n");
  
  /* create base table  */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create summary table */
  printf("\nCreating summary table D_AST\n");
  printf("\n  Directly execute the statement\n");
  printf("    CREATE SUMMARY TABLE D_AST AS (SELECT C1, C2, COUNT(*)\n"); 
  printf("    AS COUNT FROM T GROUP BY C1, C2) DATA INITIALLY\n");
  printf("    DEFERRED REFRESH DEFERRED\n"); 
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create staging table */
  printf("\nCreating the staging table G\n");
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE G FOR D_AST PROPAGATE IMMEDIATE\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CreateStagingTable */

/* show how to propagate the changes from base table to
   summary tables through the staging table */ 
int PropagateStagingToAst(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt1 = (SQLCHAR *)"SET INTEGRITY FOR G IMMEDIATE CHECKED ";

  SQLCHAR *stmt2 = (SQLCHAR *)"REFRESH TABLE D_AST NOT INCREMENTAL ";

  SQLCHAR *stmt3 = (SQLCHAR *)"INSERT INTO T VALUES(1,1,1,1), (2,2,2,2), "
                              "                    (1,1,1,1), (3,3,3,3)";
  
  SQLCHAR *stmt4 = (SQLCHAR *)"REFRESH TABLE D_AST INCREMENTAL" ;

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO PROPAGATE THE CHANGES FROM BASE TABLE TO SUMMARY TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nBring staging table out of pending state\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR G IMMEDIATE CHECKED\n");   
    
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nRefresh summary table, get it out of pending state.\n"); 
  printf("\n  Directly execute the statement\n");
  printf("    REFRESH TABLE D_AST NOT INCREMENTAL\n"); 
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nInsert data into base table T\n");
  printf("\n  Directly execute the statement\n");
  printf("    INSERT INTO T VALUES(1,1,1,1), (2,2,2,2), \n");
  printf("                        (1,1,1,1), (3,3,3,3)\n\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("Display the contents of staging table G.\n"); 
  printf("The Staging table contains incremental changes to base table.\n"); 
  DisplayTable(hdbc, "G");
  
  printf("\nRefresh the summary table\n");
  printf("\n  Directly execute the statement\n");
  printf("    REFRESH TABLE D_AST INCREMENTAL\n");  
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nDisplay the contents of staging table G\n"); 
  printf("   NOTE: The staging table is pruned after AST is\n"); 
  printf("         refreshed. The contents are propagated to AST\n");
  printf("         from the staging table\n");
  DisplayTable(hdbc, "G");

  printf("Display the contents of AST\n");
  printf("Summary table has the changes propagated from staging table\n");
  DisplayTable(hdbc, "D_AST");
 
  return rc;
} /* PropageStagingToAst */

/* shows how to restore the data in a summary table */ 
int RestoreSummaryTable(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt1 = (SQLCHAR *) 
    "SET INTEGRITY FOR G OFF"; 

  SQLCHAR *stmt2 = (SQLCHAR *) 
    "SET INTEGRITY FOR D_AST OFF CASCADE IMMEDIATE ";

  SQLCHAR *stmt3 = (SQLCHAR *) 
    "SET INTEGRITY FOR G IMMEDIATE CHECKED PRUNE"; 

  SQLCHAR *stmt4 = (SQLCHAR *) 
    "SET INTEGRITY FOR G STAGING IMMEDIATE UNCHECKED";

  SQLCHAR *stmt5 = (SQLCHAR *) 
    "SET INTEGRITY FOR D_AST MATERIALIZED QUERY IMMEDIATE UNCHECKED"; 
  
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO RESTORE DATA IN A SUMMARY TABLE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nBlock all modifications to the summary table\n");
  printf("by setting the integrity to off\n");
  printf("  (G is placed in pending and G.CC=N)\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR G OFF\n");
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nExport the query definition in summary table and load\n");
  printf("directly back to the summary table.\n");
  printf("  (D_AST and G both in pending)\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR D_AST OFF CASCADE IMMEDIATE\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nPrune staging table and place it in normal state\n");
  printf("  (G.CC=F)\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR G IMMEDIATE CHECKED PRUNE\n"); 
  
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
 
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nChanging staging table state to U\n");
  printf("  (G.CC to U)\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR G STAGING IMMEDIATE UNCHECKED\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);   

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\nPlace D_AST in normal and D_AST.CC to U\n");
  printf("\n  Directly execute the statement\n");
  printf("    SET INTEGRITY FOR D_AST MATERIALIZED QUERY\n"); 
  printf("    IMMEDIATE UNCHECKED\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt5, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);   

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* RestoreSummaryTable */ 

/* displays the contents of the table being passed as the argument */
int DisplayTable(SQLHANDLE hdbc, char *table)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  char tbl[10];

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  c1; /* variable to get data from the c1 column */

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  c2; /* variable to get data from the c2 column */

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  count; /* variable to get data from the count column */
  
  /* SQL SELECT statement to be executed */
  SQLCHAR *stmt1 = (SQLCHAR *)"SELECT c1, c2, count FROM G";

  SQLCHAR *stmt2 = (SQLCHAR *) "SELECT c1, c2, count FROM D_AST" ;

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO DISPLAY THE CONTENTS OF THE TABLE:\n\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  strcpy(tbl, table);

  if(!strcmp(tbl, "G"))
  {
    printf("  Directly execute the statement\n");
    printf("    SELECT c1, c2, count FROM G\n\n");
    
    cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);     

  }
  else if(!strcmp(tbl, "D_AST"))
  {
    printf("  Directly execute the statement\n");
    printf("    SELECT c1, c2, count FROM D_AST\n\n");

    cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);     
  }
  
  printf("  C1    C2    COUNT \n");
  printf("  ------------------\n");
  
  /* fetch each row, and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)

  {
    printf("\n  Data not found.\n");
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* use SQLGetData to get the results */
    /* get data from column 1 */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_SHORT,
                       &c1.val,
                       0,
                       &c1.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* use SQLGetData to get the results */
    /* get data from column 2 */
    cliRC = SQLGetData(hstmt,
                       2,
                       SQL_C_SHORT,
                       &c2.val,
                       0,
                       &c2.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* use SQLGetData to get the results */
    /* get data from column 3 */
    cliRC = SQLGetData(hstmt,
                       3,
                       SQL_C_SHORT,
                       &count.val,
                       0,
                       &count.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("  %d     %d       %d  \n", c1.val, c2.val, count.val);

     /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  } 
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n");

  return rc;
} /* DisplayTable */

/* Drops the staging table, summary table and base table */
int DropTables(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  printf("Dropping a base table implicitly drops summary table defined\n");
  printf("on it which in turn cascades to dropping its staging table.\n");
  
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO DROP A TABLE:\n\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Directly execute the statement\n");
  printf("    DROP TABLE T\n");

  /* create base table  */
  cliRC = SQLExecDirect(
            hstmt,
            (UCHAR *)
            "DROP TABLE T",
            SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DropTables */
