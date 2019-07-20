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
** SOURCE FILE NAME: xmlindex.c
**
** SAMPLE: How to create an index on xml column
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: xmlindex.out (available in the online documentation)
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

  printf("\nTHIS SAMPLE SHOWS HOW TO CREATE INDEX ON XML COLUMNS.\n");

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

  /* create index on XML column */
  printf("create index on XML column\n");
  rc = CreateTableWithData(hdbc); 
  rc = CreateIndexonAttribute(hdbc); 
  rc = CreateIndexwithSelfForwardaxis(hdbc);
  rc = CreateIndexonTextNode(hdbc);
  rc = CreateIndexwith2Paths(hdbc);
  rc = CreateIndexWithNamespace(hdbc);
  rc = CreateIndexWithDifferentTypes(hdbc);
  rc = CreateIndexToUseAnding(hdbc);
  rc = CreateIndexToUseAndingOrOring(hdbc);
  rc = CreateIndexWithDateType(hdbc);
  rc = CreateIndexWithCommentNode(hdbc);
  rc = droptable(hdbc);

  /* terminate the application by calling a helper
    utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
}

int CreateTableWithData(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   char stmt1[ARRAY_SIZE];
   char stmt2[ARRAY_SIZE];
   char stmt3[ARRAY_SIZE];

   /* create a table called company */
   SQLCHAR *stmt = (SQLCHAR *) "CREATE TABLE COMPANY(ID int, " 
                               "                     DOCNAME VARCHAR(20), "
                               "                     DOC XML)";
   /* drop the index */
   SQLCHAR *drop_index = (SQLCHAR *) "DROP INDEX \"EMPINDEX\"";

   /* insert row1 into table */
   SQLCHAR *row1 = (SQLCHAR *) "INSERT INTO COMPANY VALUES(1, 'doc1', " 
                       " xmlparse (document '<company name=\"Company1\"> "
                       " <emp id=\"31201\" salary=\"60000\" gender= "
                       " \"Female\" DOB=\"10-10-80\"><name><first>Laura "
                       " </first><last>Brown</last></name>"
                       " <dept id=\"M25\">Finance</dept><!-- good --> "
                       "</emp></company>'))";

   /* insert row2 into table */
   SQLCHAR *row2 = (SQLCHAR *)"INSERT INTO COMPANY VALUES(2, 'doc', xmlparse "
                              " ( document '<company name=\"Company2\"> "
                              " <emp id=\"31664\" salary=\"60000\" gender= "
                              " \"Male\" DOB=\"09-12-75\"><name><first>Chris " 
                              " </first><last>Murphy</last></name><dept id= "
                              " \"M55\">Marketing</dept></emp><emp id=\"42366\" "
                              " salary=\"50000\" gender=\"Female\" DOB= "
                              " \"08-21-70\"> <name><first>Nicole</first><last>"
                              "Murphy</last></name><dept id=\"K55\">Sales</dept> "
                              "</emp></company>'))";

   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO PERFORM INDEX IN DIFFERENT WAYS :\n");

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
   printf("create the table called company\n");
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("Insert row1 into the table\n");

   cliRC = SQLExecDirect(hstmt, row1, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  

   printf("Insert row2 into table \n");
   cliRC = SQLExecDirect(hstmt, row2, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
   strcpy(stmt1, "COMMIT");
   cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt1, SQL_NTS);
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

int CreateIndexonAttribute(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex1 on company(doc)" 
                   "GENERATE KEY USING XMLPATTERN '/company/emp/@*' "
                   "AS SQL VARCHAR(15)"; 

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp[@id='42366'] "
                         "return $i/name"; 


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO PERFORM INDEX ON ATTRIBUTE.\n");

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
 
   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("-------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }
 
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

int droptable(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */

   char stmt1[1000];

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* drop table */
   strcpy(stmt1, "DROP table \"COMPANY\"");
   cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt1, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* end the transactions on the connection */ 
   cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   printf("  Transaction rolled back.\n"); 

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;

}

int CreateIndexwithSelfForwardaxis(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex2 on company(doc)"
                   " GENERATE KEY USING XMLPATTERN '//@salary' "
                   "AS SQL DOUBLE";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')"
                   "/company/emp[@salary > 35000] return <salary> {$i/@salary} </salary>";


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO PERFORM INDEX WITH SELF OR DESCENDENT FORWARD AXIS:\n");
  
   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, (SQLCHAR * )xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }

   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("----------------------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }
  
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}

int CreateIndexonTextNode(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex3 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '/company/emp/dept/text()' "
                   "AS SQL VARCHAR(30)";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp[dept/text()="
                         "'Finance' or dept/text()='Marketing'] return $i/name";


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO PERFORM INDEX ON TEXT NODE\n");
   
   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }

   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("----------------------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }
  
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}

int CreateIndexwith2Paths(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLHANDLE hstmt1; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex4 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '//@id' "
                   "AS SQL VARCHAR(25)";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp[@id='31201'] "
                         "return $i/name";
   SQLCHAR *xquerystmt1 = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp/dept[@id='K55']"
                         "  return $i/name ";

   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO PERFORM INDEX WHEN 2 PATHS ARE QUALIFIED BY XMLPATTERN.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("----------------------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }

   cliRC = SQLExecDirect(hstmt1, xquerystmt1, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt1, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt1);
   STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("----------------------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt1);
     STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
   }
  
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
   STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
 return rc;

}

int CreateIndexWithNamespace(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex5 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN 'declare default "
                   "element namespace \"http://www.mycompany.com/\";"
                   "declare namespace m=\"http://www.mycompanyname.com/\";"
                   " /company/emp/@m:id' AS SQL VARCHAR(30)";

   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO CREATE INDEX WITH NAMESPACE.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}

int CreateIndexWithDifferentTypes(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];

  SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex6 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '/companyt/emp/@id'"
                   " AS SQL VARCHAR(10)";

  SQLCHAR *stmt1 = (SQLCHAR *)"CREATE INDEX empindex7 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '/companyt/emp/@id'"
                   " AS SQL DOUBLE";

   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO CREATE INDEX WITH DIFFERENT DATA TYPES.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;

}

int CreateIndexToUseAnding(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex8 on company(doc)"
                   " GENERATE KEY USING XMLPATTERN '/company/emp/" 
                   "name/last' AS SQL VARCHAR(100)";
   SQLCHAR *stmt2 = (SQLCHAR *)"CREATE INDEX deptindex on company(doc)"
                   " GENERATE KEY  USING XMLPATTERN '/company/emp/"
                   "dept/text()' AS SQL VARCHAR(30) ";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp[name/last='Murphy'"
                         " and dept/text()='Sales'] return $i/name";


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLFreeHandle\n");
   printf(" CREATE INDEX TO USE JOINS.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
 
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("----------------------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   } 
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}

int CreateIndexToUseAndingOrOring(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex9 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '/company/emp/"
                   "@salary' AS SQL DOUBLE";


   SQLCHAR *stmt2 = (SQLCHAR *)"CREATE INDEX empindex10 on company(doc)"
                   " GENERATE KEY USING XMLPATTERN '/company/emp/dept'"
                   " AS SQL VARCHAR(25) ";

   SQLCHAR *stmt3 = (SQLCHAR *)"CREATE INDEX empindex11 on company(doc)"
                    "GENERATE KEY USING XMLPATTERN '/company/emp/name/"
                    "last' AS SQL VARCHAR(25) ";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp[@salary > 50000"
                         " and dept = 'Finance'] /name [last = 'Brown'] "
                         "return $i/last";


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO CREATE INDEX TO USE ANDING OR ORING.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);


   cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("-----------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }
  
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}

int CreateIndexWithDateType(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex12 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '/company/emp/@DOB'"
                   " as SQL DATE";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn"
                         "('COMPANY.DOC')/company/emp[@DOB < '11-11-78']"
                         " return $i/name";


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO CREATE INDEX WITH DATE DATA TYPE.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("---------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }
  
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}

int CreateIndexWithCommentNode(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLVARCHAR xmldata[3000];
   char stmt1[1000];

   SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX empindex13 on company(doc)"
                   "GENERATE KEY USING XMLPATTERN '/company//comment()'"
                   " AS SQL VARCHAR HASHED";

   SQLCHAR *xquerystmt = (SQLCHAR *)"XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')"
                                   "/company/emp[comment()=' good '] return $i/name";


   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO CREATE INDEX ON COMMENT NODE.\n");

   printf("\n  Transactions enabled.\n");

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* create unique index */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* example query using above index */
   cliRC = SQLExecDirect(hstmt, xquerystmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Bind column 1 to variable */
   cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* Fetch each row and display */
   cliRC = SQLFetch(hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   if (cliRC == SQL_NO_DATA_FOUND)
   {
     printf("\n  Data not found.\n");
   }
   while (cliRC != SQL_NO_DATA_FOUND)
   {
     /* Print the data */
     printf("-----------------------------------------------------------------\n");
     printf("%s \n",xmldata);

     /* Fetch next row */
     cliRC = SQLFetch(hstmt);
     STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   }
  
   
   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

 return rc;
}
