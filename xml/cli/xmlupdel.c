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
** SOURCE FILE NAME: xmlupdel.c
**
** SAMPLE: This sample demonstrates updation and deletion of XML data 
**         from tables.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLPrepare -- Prepare a Statement
**
** OUTPUT FILE: xmlupdel.out (available in the online documentation)
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
#include <sqlca.h>
#include "utilcli.h" /* header file for CLI sample code */

/* Global Variables */
int length;
char blobdata[500];
char clobdata[500];
char xmldata[500];

int CreateTables(SQLHANDLE);
int updateusingXMLtype(SQLHANDLE);
int updateusingBLOB(SQLHANDLE);
int updateusingBLOBimplicit(SQLHANDLE);
int updateusingVARCHARimpllicit(SQLHANDLE);
int updateusingVARCHARcolumn(SQLHANDLE);
int updateusingVARCHARcolumnimplicit(SQLHANDLE);
int updateusingVARCHARvalidate(SQLHANDLE);
int updateusingSELECTvalidate(SQLHANDLE);
int deleteXMLdoc(SQLHANDLE);
int DropTables(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLHANDLE hstmt;
  SQLCHAR stmt[500] = {0};
  SQLINTEGER CID;                 /* variable to be bound to the CID column */
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* Create a XML document that will be used to INSERT in the table */
  strcpy(xmldata, "<product pid=\"10\"><description>"
                  "<name> Plastic Casing </name>"
                  "<details> Blue Color </details>"
                  "<price> 2.89 </price>"
                  "<weight> 0.23 </weight>"
                  "</description></product>");

  strcpy(clobdata, xmldata);
  strcpy(blobdata, xmldata);
  length = strlen(xmldata) + 1;
 
  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }
  
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
 

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  /* Call function to create Tables */
  rc = CreateTables(hdbc);
  
  printf(" SET THE CURRENT IMPLICT REGISTER\n");
  strcpy((char *)stmt, "SET CURRENT IMPLICIT XMLPARSE OPTION = PRESERVE WHITESPACE");
   
  rc = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* perform update using variable of type XML */ 
  rc = updateusingXMLtype(hdbc);
  
  /* perform update using host variable of type BLOB */
  rc = updateusingBLOB(hdbc);
 
  /* update using variable of type BLOB, use Implicit Parsing */
  rc = updateusingBLOBimplicit(hdbc);

  /* update using variable of type VARCHAR */
  rc = updateusingVARCHARimpllicit(hdbc);

  /* update using another column of VARCHAR */
  rc = updateusingVARCHARcolumn(hdbc);

  /* update using another column of VARCHAR, implicit parsing */
  rc = updateusingVARCHARcolumnimplicit(hdbc);

  /* update using VARCHAR data and XMLVALIDATE */
  rc = updateusingVARCHARvalidate(hdbc);

  /* update using XML document returned by SELECT */
  rc = updateusingSELECTvalidate(hdbc);

  /* delete XML document from table */
  rc = deleteXMLdoc(hdbc);

  /* Call function to Drop tables */
  rc = DropTables(hdbc);

  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC); 
  
  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 
  
  /* terminate the CLI application by calling a helper
  utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */

/* Function to Create tables */
int CreateTables(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  strcpy(stmt, "CREATE TABLE vartable (id INT,"
               " desc VARCHAR(200), comment VARCHAR(25))");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  strcpy(stmt, "INSERT INTO vartable VALUES "
               "(11111, \'<NAME><FIRSTNAME> Neeraj </FIRSTNAME>"
               "<LASTNAME> Gaurav </LASTNAME></NAME>\', "
               "\'Final Year\')");

  /* Execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  strcpy(stmt, "INSERT INTO vartable VALUES "
               "(22222, '<product pid=\"80\">"
               "<description><name> Plastic Casing </name>"
               "<details> Green Color </details>"
               "<price> 7.89 </price>"
               "<weight> 6.23 </weight>"
               "</description></product>', "
               "'Last Product')");

  /* Execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  strcpy(stmt, "INSERT INTO vartable VALUES "
               "(33333, \'<NAME><FIRSTNAME> Neeraj </FIRSTNAME>"
               "<LASTNAME> Gaurav </LASTNAME></NAME>\', "
               "\'Final Year\')");

  /* Execute the statement */
  rc = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Inserting a row in PurchaseOrder */
  strcpy(stmt, "INSERT INTO PURCHASEORDER (POID, PORDER) "
                       "VALUES (1232, '<PORDER> 876 </PORDER>')");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CreateTables */

/* updateusingXMLtype */
int updateusingXMLtype(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Perform Update on the XML column using a variable of type XML\n");
  printf(" Bind uisng SQL_XML\n");
  strcpy(stmt, "UPDATE purchaseorder SET porder = "
                       "? WHERE poid = 1232");

  printf(" Statement Executed : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind Paramenter to the Update statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_XML,
                           length,
                           0,
                           &xmldata,
                           length,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingXMLtype */

/* updateusingBLOB */
int updateusingBLOB(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Performing update on the XML column of the table\n");
  printf(" Binding with data of type BLOB and EXPICIT PARSING\n");

  strcpy(stmt, "UPDATE purchaseorder SET porder = "
                       "XMLPARSE(DOCUMENT CAST(? AS BLOB(1K))) WHERE poid = 1232");
  printf(" Statement Executed : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind Paramenter to the Update statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_BINARY,
                           SQL_BLOB,
                           length,
                           0,
                           &blobdata,
                           length,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingBLOB */

/* updateusingBLOBimplicit */
int updateusingBLOBimplicit(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Perform Update on the XML column of the table\n");
  printf(" Binding with data of type BLOB and IMPLICT PARSING\n");

  strcpy(stmt, "UPDATE purchaseorder SET porder = "
                       "? WHERE poid = 1232");
  printf(" Statement Executed : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind Paramenter to the Update statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_BINARY,
                           SQL_BLOB,
                           length,
                           0,
                           &blobdata,
                           length,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingBLOBimplicit */

/* updateusingVARCHARimpllicit */
int updateusingVARCHARimpllicit(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Perform UPDATE on the XML column using VARCHAR and IMPLICIT PARSING\n");
  strcpy(stmt, "UPDATE purchaseorder SET porder = '<Product> <ProdId> 123 </ProdId></Product>'"
               " WHERE poid = 1232");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingVARCHARimpllicit */

/* updateusingVARCHARcolumn */
int updateusingVARCHARcolumn(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* UPDATE  the xml column using another column of varchar */
  printf(" UPDATE XML column from another column of type VARCHAR\n");
  strcpy(stmt, "UPDATE purchaseorder SET porder = (SELECT XMLPARSE( DOCUMENT desc PRESERVE WHITESPACE) "
               " FROM vartable WHERE id = 11111)"
               " WHERE poid = 1232");
  printf(" Statement Executing : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingVARCHARcolumn */

/* updateusingVARCHARcolumnimplicit */
int updateusingVARCHARcolumnimplicit(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* update when source is a XML document from a column */
  /* of type VARCHAR, Using Implicit Parsing */
  printf(" Upate when source is a XML document from a column of type VARCHAR, Using Implicit Parsing\n");
  strcpy(stmt, "UPDATE purchaseorder SET porder = "
               "(SELECT desc FROM vartable WHERE id = 33333)"
               " WHERE poid = 1232");
  printf(" Statement Executing : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingVARCHARcolumnimplicit */

/* updateusingVARCHARvalidate */
int updateusingVARCHARvalidate(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Perform update on the XML column using VARCHAR, also VALIDATE\n");
  strcpy(stmt, "UPDATE purchaseorder SET porder = "
                       "XMLVALIDATE (? ACCORDING TO XMLSCHEMA ID PRODUCT)"
                       " WHERE poid = 1232");
  printf(" Statement Executing : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind Paramenter to the Update statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           length,
                           0,
                           &xmldata,
                           length,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingVARCHARvalidate */

/* updateusingSELECTvalidate */
int updateusingSELECTvalidate(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" UPDATE using XML document returned by select using XMLVALIDATE\n");
  strcpy(stmt, " UPDATE purchaseorder SET porder = (SELECT "
                       " XMLVALIDATE( XMLPARSE( DOCUMENT desc) ACCORDING TO XMLSCHEMA ID product)"
                       " FROM vartable WHERE id = 22222) WHERE poid = 1232");
  printf(" Statement Executing : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* updateusingSELECTvalidate */

/* deleteXMLdoc */
int deleteXMLdoc(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf(" Delete porder for the XML DOC that have PID = 80\n");
  strcpy(stmt, "DELETE FROM purchaseorder WHERE "
               "XMLEXISTS('$p/product[@pid=\"80\"]' "
               "PASSING BY REF purchaseorder.porder AS \"p\")");
  printf(" Statement Executing : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* deleteXMLdoc */

/* Function to Drop tables */
int DropTables(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  strcpy(stmt, "DROP TABLE VARTABLE");

  /* Execute the statement */
  rc = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Cleaup PurchaseOrder table */
  strcpy(stmt, " DELETE FROM purchaseorder POID = 1232");

  /* Execute the statement */
  rc = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DropTables */

