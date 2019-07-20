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
** SOURCE FILE NAME: tbonlineinx.c                                      
**                                                                        
** SAMPLE:  How to create and reorg indexes on a table
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetData -- Get Data From a Column                
**         SQLSetConnectAttr -- Set Connection Attributes
**
** DB2 APIs USED:
**         db2Reorg -- Reorganize a Table or Index
**
** SQL STRUCTURES USED:
**         sqlca
**         db2ReorgStruct 
**
** OUTPUT FILE: tbonlineinx.out (available in the online documentation)
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
#include <db2ApiDf.h>
#include "utilcli.h" /* Header file for CLI sample code */

int CreateIndex(SQLHANDLE);
int ReorgIndex(SQLHANDLE);
int DropIndex(SQLHANDLE);
int SchemaNameGet(SQLHANDLE);

char schemaName[10];
char tableName[10];

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

  printf("\nTHIS SAMPLE SHOWS HOW TO CREATE AND REORG ONLINE INDEXES\n");
  printf("ON TABLES.\n");
  
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
  
  /* create online index on a table */
  rc = CreateIndex(hdbc);
  if (rc != 0)
  {
    return rc;
  }  

  /* reorg online index on a table */
  rc = ReorgIndex(hdbc);
  if (rc != 0)
  {
    return rc;
  }
  
  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* to create an index on a table with different levels
   of access to the table like read-write, read-only, no access */
int CreateIndex(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt_inx = (SQLCHAR *)"CREATE INDEX INDEX1 ON "
                                 "EMPLOYEE (LASTNAME ASC)";
   
  SQLCHAR *stmt_lsm = (SQLCHAR *)"LOCK TABLE EMPLOYEE IN SHARE MODE";

  SQLCHAR *stmt_lem = (SQLCHAR *)"LOCK TABLE EMPLOYEE IN EXCLUSIVE MODE";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CREATE INDEX WITH DIFFERENT LEVELS OF ACCESS:\n");
  
  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create an online index with read-write access to the table */
  printf("\nTo create an index on a table allowing read-write access\n");
  printf("to the table, use the following SQL command:\n\n");
  printf("  Directly execute the statement\n");
  printf("    CREATE INDEX INDEX1 ON EMPLOYEE (LASTNAME ASC)\n");
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create index index1 */
  cliRC = SQLExecDirect(hstmt, stmt_inx, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  rc = DropIndex(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  /* create an index on a table while allowing only read access to it */
  printf("\nTo create an index on a table allowing only read access\n");
  printf("to the table, use the following two SQL commands:\n\n"); 
  printf("  Directly execute the statements\n");
  printf("    LOCK TABLE EMPLOYEE IN SHARE MODE\n");
  printf("    CREATE INDEX INDEX1 ON EMPLOYEE (LASTNAME ASC)\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* lock table in share mode */
  cliRC = SQLExecDirect(hstmt, stmt_lsm, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create index index1 */
  cliRC = SQLExecDirect(hstmt, stmt_inx, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  rc = DropIndex(hdbc);
  if (rc != 0)
  {
    return rc;
  }
 
  /* create an online index allowing no access to the table */
  printf("\nTo create an index on a table allowing no access to the \n");
  printf("table (only uncommitted readers allowed), use the \n");
  printf("following two SQL statements:\n\n");
  printf("  Directly execute the statements\n");
  printf("    LOCK TABLE EMPLOYEE IN EXCLUSIVE MODE\n");
  printf("    CREATE INDEX INDEX1 ON EMPLOYEE (LASTNAME ASC)\n");
  
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* lock table in exclusive mode */
  cliRC = SQLExecDirect(hstmt, stmt_lem, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* create index index1 */
  cliRC = SQLExecDirect(hstmt, stmt_inx, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CreateIndex */

/* to reorg an index on a table with different levels of 
   access to the table like read-write, read-only, no access */
int ReorgIndex(SQLHANDLE hdbc)
{
  int rc = 0;
  struct sqlca sqlca;
  char fullTableName[258];
  db2ReorgStruct paramStruct;
  db2Uint32 versionNumber = db2Version970;

  printf("\n-----------------------------------------------------------");

  printf("\nUSE THE DB2 API:\n");
  printf("  db2Reorg -- Reorganize a Table or Index\n");
  printf("TO REORGANIZE A TABLE OR INDEX.\n");  

  /* get fully qualified name of the table */
  strcpy(tableName, "EMPLOYEE");

  rc = SchemaNameGet(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  strcpy(fullTableName, schemaName);
  strcat(fullTableName, ".");
  strcat(fullTableName, tableName);

  printf("  Reorganize all indexes defined on table : %s\n", fullTableName);

  /* setup parameters */
  memset(&paramStruct, '\0', sizeof(paramStruct));
  paramStruct.reorgObject.tableStruct.pTableName = fullTableName;
  paramStruct.reorgObject.tableStruct.pOrderByIndex = NULL;
  paramStruct.reorgObject.tableStruct.pSysTempSpace = NULL;
  paramStruct.reorgType = DB2REORG_OBJ_INDEXESALL;
  paramStruct.nodeListFlag = DB2_ALL_NODES;
  paramStruct.numNodes = 0;
  paramStruct.pNodeList = NULL;

  printf("  \nReorganize the indexes on a table allowing read-write\n");
  printf("  access to the table (set reorgFlags to DB2REORG_ALLOW_WRITE)\n");

  paramStruct.reorgFlags = DB2REORG_ALLOW_WRITE;

  /* reorganize index */
  rc = db2Reorg(versionNumber, &paramStruct, &sqlca);
  DB2_API_CHECK("index -- reorganize");

  printf("  \nReorganize the indexes on a table allowing read-only\n");
  printf("  access to the table (set reorgFlags to DB2REORG_ALLOW_READ)\n");

  paramStruct.reorgFlags = DB2REORG_ALLOW_READ;

  /* reorganize index */
  rc = db2Reorg(versionNumber, &paramStruct, &sqlca);
  DB2_API_CHECK("index -- reorganize");

  printf("  \nReorganize the indexes on a table allowing no access\n");
  printf("  to the table (set reorgFlags to DB2REORG_ALLOW_NONE)\n");

  paramStruct.reorgFlags = DB2REORG_ALLOW_NONE;

  /* reorganize index */
  rc = db2Reorg(versionNumber, &paramStruct, &sqlca);
  DB2_API_CHECK("index -- reorganize");

  rc = DropIndex(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  return rc;
} /* ReorgIndex */

/* to drop the index on a table */
int DropIndex(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  
  SQLCHAR *stmt = (SQLCHAR *) " DROP INDEX index1 ";

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("TO DROP THE INDEX:\n");
  
  /* drop the indexes */
  printf("\n  Directly execute the statement\n");
  printf("    DROP INDEX index1\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* drop the index */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 
  
  printf("\n-----------------------------------------------------------");

  return rc;
} /* DropIndex */

/* gets the schema name of the table */
int SchemaNameGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)"SELECT tabschema FROM syscat.tables "
                             "WHERE tabname = 'EMPLOYEE' ";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  tabschema; /* variable to be bound to the tabschema column */

  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("  SQLGetData\n");
  printf("TO GET SCHEMA NAME OF THE TABLE\n\n");

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

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* get data from column */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_CHAR,
                       tabschema.val,
                       10,
                       &tabschema.ind);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  strcpy(schemaName, (char *)tabschema.val);
   
  /* get rid of spaces from the end of schemaName */
  strtok(schemaName, " ");
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* SchemaNameGet */
