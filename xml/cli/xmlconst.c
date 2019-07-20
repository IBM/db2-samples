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
** SOURCE FILE NAME: xmlconst.c
**
** SAMPLE: Shows how to create a unique index on XML columns
**
** NOTE : 
**        1) This sample demonstrate the how to enforce the
**           constraints on an XML value. There are some statement
**           in the samples which are expected to fail because of 
**           constraint violation so The sql error SQL803N and 
**           SQL20305N are expected.
**
**        2) Primary key, unique constraint, or unique index are not supported
**           for XML column in the Database Partitioning Feature available with
**           DB2 Enterprise Server Edition for Linux, UNIX, and Windows.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: xmlconst.out (available in the online documentation)
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
#include <sqlca.h>

#define ARRAY_SIZE 700

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handles */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO CREATE UNIQUE INDEX \n");

  /* initialize the application by calling a helper
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

  /* create index on XML columns */
  TbindexUniqueConstraint(hdbc);
  TbindexVarcharConstraint(hdbc);
  TbindexVarcharConstraint1(hdbc);
 
   /* terminate the application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;

} /* main */

int TbindexUniqueConstraint(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char stmt1[ARRAY_SIZE];
  SQLCHAR *stmt = (SQLCHAR *) "CREATE TABLE COMPANY(ID int,"
                              " DOCNAME VARCHAR(20),"
                              " DOC XML)";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM UNIQUE INDEX OPERATION :\n");
      
  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* execute create table statement directly */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* create unique index */
  printf("create unique index \n");

  strcpy(stmt1, " CREATE UNIQUE INDEX empindex on company(doc) GENERATE \
                KEY USING XMLPATTERN '/company/emp/@id' AS SQL  DOUBLE");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  printf("insert row1 into table \n");

  strcpy(stmt1, " INSERT INTO company values (1, 'doc1', xmlparse \
                (document '<company name=\"Company1\"><emp id=\"31201\" \
                salary=\"60000\" gender=\"Female\"><name><first>Laura \
                </first><last>Brown</last></name> <dept id=\"M25\"> \
                Finance</dept></emp></company>'))"); 
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  printf("insert row2 into table \n");
  printf("Unique violation error because of id=\"31201\" \n");

  strcpy(stmt1, "INSERT INTO company values (1, 'doc1', xmlparse \
                (document '<company name=\"Company1\"><emp id=\"31201\" \
                salary=\"60000\" gender=\"Female\"><name><first>Laura \
                </first><last>Brown</last></name><dept id=\"M25\">\
                     Finance</dept></emp> </company>'))"); 
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);


  /* execute create table statement directly */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* create unique index */
  printf("create unique index \n");

  strcpy(stmt1, "CREATE UNIQUE INDEX empindex on company(doc)\
         GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL DOUBLE");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("insert row1 into table \n");
  printf("No index entry is inserted because \"ABCDE\" cannot be cast");
  printf("to the DOUBLE data type. \n");

  strcpy(stmt1, " INSERT INTO company values (1, 'doc1', xmlparse \
                  (document '<company name=\"Company1\"><emp id=\"ABCDE\" \
                  salary=\"60000\" gender=\"Female\"><name><first>Laura \
                  </first><last>Brown</last></name><dept id=\"M25\"> \
                  Finance</dept></emp></company>'))");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("insert row2 into table \n");
  printf("The insert succeeds because no index entry is inserted since\n");
  printf("\"ABCDE\" cannot be cast to the DOUBLE data type.\n");

  strcpy(stmt1, "INSERT INTO company values (1, 'doc1', xmlparse \
                (document '<company name=\"Company1\"> \
                <emp id=\"ABCDE\" \
                salary=\"60000\" gender=\"Female\"><name><first>Laura \
                </first><last>Brown</last></name><dept id=\"M25\">Financei \
                </dept></emp> </company>'))");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;

}

int TbindexVarcharConstraint(SQLHANDLE hdbc)
{

  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char stmt1[ARRAY_SIZE];
  SQLCHAR *stmt = (SQLCHAR *) "CREATE TABLE COMPANY(ID int,"
                              "        DOCNAME VARCHAR(20),"
                              "                    DOC XML)";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM UNIQUE INDEX :\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* execute create table statement directly */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* create unique index */
  printf("create unique index \n");

  strcpy(stmt1, "CREATE UNIQUE INDEX empindex on company(doc)\
     GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(4)");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("insert row1 into table \n");
  printf("Insert statement succeeds because the length of \"312\" < 4.\n");

  strcpy(stmt1, "INSERT INTO company values (1, 'doc1', xmlparse \
                  (document '<company name=\"Company1\"><emp id=\"312\" \
                  salary=\"60000\" gender=\"Female\"><name><first>Laura \
                  </first><last>Brown</last></name> <dept id=\"M25\"> \
                  Finance</dept> </emp></company>'))");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("insert row2 into table \n");
  printf("Insert statement fails because the length of \"31202\" > 4.\n");
  strcpy(stmt1, " INSERT INTO company values (1, 'doc1', xmlparse \
                  (document '<company name=\"Company1\"><emp id=\"31202\" \
                  salary=\"60000\" gender=\"Female\"><name><first>Laura \
                  </first><last>Brown</last></name><dept id=\"M25\"> \
                  Finance</dept>  </emp></company>'))");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;

}

int TbindexVarcharConstraint1(SQLHANDLE hdbc)
{

  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char stmt1[ARRAY_SIZE];
  SQLCHAR *stmt = (SQLCHAR *) "CREATE TABLE COMPANY(ID int,"
                              "        DOCNAME VARCHAR(20),"
                              "                    DOC XML)";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM UNIQUE INDEX :\n");
   
  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* execute create table statement directly */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 

  printf("insert row1 into table \n");
  strcpy(stmt1, "INSERT INTO company values (1, 'doc1', xmlparse \
                  (document '<company name=\"Company1\"><emp id=\"312\" \
                  salary=\"60000\" gender=\"Female\"><name><first>Laura \
                  </first><last>Brown</last></name> <dept id=\"M25\"> \
                  Finance</dept> </emp></company>'))");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("insert row2 into table \n");
  strcpy(stmt1, " INSERT INTO company values (1, 'doc1', xmlparse \
                  (document '<company name=\"Company1\"><emp id=\"31202\" \
                  salary=\"60000\" gender=\"Female\"><name><first>Laura \
                  </first><last>Brown</last></name><dept id=\"M25\"> \
                  Finance</dept>  </emp></company>'))");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);


  /* create unique index */
  printf("create index with Varchar constraint fails ");
  printf("because the length of \"31202\" > 4\n");

  strcpy(stmt1, "CREATE UNIQUE INDEX empindex on company(doc)\
     GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(4)");
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
}
