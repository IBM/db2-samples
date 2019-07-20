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
** SOURCE FILE NAME: xmlinsert.c
**
** SAMPLE: This sample demonstrates different ways of inserting a XML document 
**         into a column of XML data type.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLPrepare -- Prepare a Statement
**         SQLExecute -- Execute a Statement
**         SQLFreeHandle -- Free Handle Resources
**
** OUTPUT FILE: xmlinsert.out (available in the online documentation)
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

/* Declare Global Variables to be used across functions */
int length;
int rc = 0;
char blobdata[500];
char clobdata[500];
char xmldata[500];
char invalidxmldata[500];
char invaliddata[500];

int CreateTables(SQLHANDLE);
int InsertXMLtype(SQLHANDLE);
int InsertBLOBtypeExplictParsing(SQLHANDLE);
int InsertBLOBtypeImplicitParsing(SQLHANDLE);
int InsertInvalidXMLdoc(SQLHANDLE);
int InsertfromXMLcolumn(SQLHANDLE);
int InsertfromVARCHARcolumn(SQLHANDLE);
int InsertfromVARCHARcolumnImplicitParsing(SQLHANDLE);
int InsertusingXMLCAST(SQLHANDLE);
int InsertDocUsingXMLfunctions(SQLHANDLE);
int InsertInvalidDocUsingXMLVALIDATE(SQLHANDLE);
int InsertusingXMLVALIDATE(SQLHANDLE);
int DropTables(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLHANDLE hstmt;
  SQLCHAR stmt[500] = {0};
  
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  strcpy(xmldata, "<product pid=\"10\"><description>"
                  "<name> Plastic Casing </name>"
                  "<details> Blue Color </details>"
                  "<price> 2.89 </price>"
                  "<weight> 0.23 </weight>");

  /* invalid xml data will not have the closing tags for */
  /* description and product */
  strcpy(invalidxmldata, xmldata);

  strcat(xmldata, "</description></product>");
  strcpy(blobdata, xmldata);
  strcpy(clobdata, xmldata);
  strcpy(invaliddata, "<INVALID> Not as per schema </INVALID>");

  length = strlen(xmldata);
  
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
                  (SQLPOINTER)SQL_AUTOCOMMIT_OFF);
  if (rc != 0)
  {
    return rc;
  }

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
 
  /* Call function to create Tables */
  rc = CreateTables(hdbc);

  /* Insert using variable of type XML */
  rc = InsertXMLtype(hdbc);
  
  /* Insert using variable of type BLOB with Explicit Parsing */
  rc = InsertBLOBtypeExplictParsing(hdbc);

  /* Insert using variable of type BLOB with Implicit Parsing */
  rc = InsertBLOBtypeImplicitParsing(hdbc);

  /* Insert using an INVALID XML document structure  */
  rc = InsertInvalidXMLdoc(hdbc); 

  /* Insert when source is from another column of type XML */
  rc = InsertfromXMLcolumn(hdbc);

  /* Insert when source is from another column of type VARCHAR */
  rc = InsertfromVARCHARcolumn(hdbc);

  /* Insert when source is a XML document from a column */
  /* of type VARCHAR, Using Implicit Parsing */
  rc = InsertfromVARCHARcolumnImplicitParsing(hdbc);

  /* Insert when source is a simple type, using XMLCAST */
  rc = InsertusingXMLCAST(hdbc);

  /* Insert document created using XML Functions */
  rc = InsertDocUsingXMLfunctions(hdbc);

  /* Inserting INVALID XML document using XMLVALIDATE */
  rc = InsertInvalidDocUsingXMLVALIDATE(hdbc); 

  /* Insert using XMLVALIDATE */
  rc = InsertusingXMLVALIDATE(hdbc);

  /* Call function to Drop tables */
  rc = DropTables(hdbc); 

  /* Rollback transaction */
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
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
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
  
  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CreateTables */

/* InsertXMLtype */
int InsertXMLtype(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[500];
  SQLHANDLE hstmt; /* statement handle */

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* inserting when source is from host variable of type XML */
  printf("\n Performing Insert when source is a variable of Type XML \n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                       "VALUES (8956, ?)");
  printf(" Statement Executing : %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind Paramenter to the Insert statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_BINARY,
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
} /* InsertXMLtype */

/* InsertBLOBtypeExplictParsing */
int InsertBLOBtypeExplictParsing(SQLHANDLE hdbc)
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

  printf("\n Performing Insert with BLOB type using Explicit Parsing\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                       "VALUES (323, XMLPARSE(DOCUMENT CAST(? as BLOB(1K))))");
  printf(" Statement Executing: %s\n", stmt);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind Paramenter to the Insert statement */
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
} /* InsertBLOBtypeExplictParsing */

/* InsertBLOBtypeImplicitParsing */
int InsertBLOBtypeImplicitParsing(SQLHANDLE hdbc)
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

  printf("\n Performing Insert with BLOB type using Implicit Parsing\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                        "VALUES(231, CAST( ? as BLOB(1K)))");
  printf(" Statement executing : %s\n", stmt);

  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind Paramenter to the Insert statement */
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
} /* InsertBLOBtypeImplicitParsing */

/* InsertInvalidXMLdoc */
int InsertInvalidXMLdoc(SQLHANDLE hdbc)
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

  printf("\n Performing Insert using an INVALID XML document\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                        "VALUES(674, ?)");
  printf(" Statement executing : %s\n", stmt);
  printf(" This Insert should fail as the XML document is INVALID\n");

  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind Paramenter to the Insert statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           500,
                           0,
                           &invalidxmldata,
                           500,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertInvalidXMLdoc */

/* InsertfromXMLcolumn */
int InsertfromXMLcolumn(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  char stmt[700];
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
  
  /* validate an XML document when target is from another column of type XML */
  /* add a number to POID to avoid unique constraint conflict */
  printf("\n Perform Insert by selecting XML doc from another column\n");
  strcpy(stmt, "INSERT INTO purchaseorder(poid, porder) "
                        "(SELECT poid+5, XMLVALIDATE(porder ACCORDING TO XMLSCHEMA ID PRODUCT) "
                        "FROM purchaseorder WHERE poid = 674)");
  printf(" Statement Executing : %s\n", stmt);
 
  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertfromXMLcolumn */

/* InsertfromVARCHARcolumn */
int InsertfromVARCHARcolumn(SQLHANDLE hdbc)
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

  printf(" Insert when source is a XML document from a column of type VARCHAR\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
               "(SELECT  id, XMLPARSE( DOCUMENT desc) FROM vartable WHERE "
               "id = 11111)");
  printf(" Statement Executing : %s\n", stmt);

  /* execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertfromVARCHARcolumn */

/* InsertfromVARCHARcolumnImplicitParsing */
int InsertfromVARCHARcolumnImplicitParsing(SQLHANDLE hdbc)
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

  /* insert when source is a XML document from a column */
  /* of type VARCHAR, Using Implicit Parsing */
  printf(" Insert when source is a XML document from a column of type VARCHAR, Using Implicit Parsing\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
               "(SELECT id, desc FROM vartable WHERE "
               "id = 22222)");
  printf(" Statement Executing : %s\n", stmt);

  /* execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertfromVARCHARcolumnImplicitParsing */

/* InsertusingXMLCAST */
int InsertusingXMLCAST(SQLHANDLE hdbc)
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

  printf("\n Performing Insert using a simple type\n");
  printf(" Using XMLCAST to typecast to XML\n");

  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                        "VALUES(125, XMLCAST(? as XML))");
  printf("\n Insert statement executing : %s\n", stmt);

  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind Paramenter to the Insert statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           500,
                           0,
                           &xmldata,
                           500,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertusingXMLCAST */

/* InsertDocUsingXMLfunctions */
int InsertDocUsingXMLfunctions(SQLHANDLE hdbc)
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

  /* use XML Functions to create a XML document */
  /* insert this document into the table */
  printf(" Use XML Functions to create a XML document\n");
  printf(" Insert this document into the table \n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder)"
               "(SELECT  id, XMLDOCUMENT( XMLELEMENT( NAME \"PORDER\","
               " XMLELEMENT( NAME \"ID\", XMLATTRIBUTES( v.id as PRODID)),"
               " XMLELEMENT( NAME \"DESC\", v.comment)))"
               " FROM vartable AS v WHERE ID = 33333)");

  cliRC = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertDocUsingXMLfunctions */

/* InsertInvalidDocUsingXMLVALIDATE */
int InsertInvalidDocUsingXMLVALIDATE(SQLHANDLE hdbc)
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

  printf(" Perform Insert using XMLVALIDATE with INVALID xml document\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                        "VALUES( 320, XMLVALIDATE(? ACCORDING TO XMLSCHEMA ID PRODUCT))");
  printf(" Statement Executing : %s\n", stmt);

  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind Paramenter to the Insert statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_BINARY,
                           SQL_CHAR,
                           500,
                           0,
                           &invaliddata,
                           500,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  EX_STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertInvalidDocUsingXMLVALIDATE */

/* InsertusingXMLVALIDATE */
int InsertusingXMLVALIDATE(SQLHANDLE hdbc)
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

  printf(" Perform Insert using XMLVALIDATE\n");
  strcpy(stmt, "INSERT INTO purchaseorder (poid, porder) "
                        "VALUES( 320, XMLVALIDATE(? ACCORDING TO XMLSCHEMA ID PRODUCT))");
  printf(" Statement Executing : %s\n", stmt);

  cliRC = SQLPrepare(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* bind Paramenter to the Insert statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_BINARY,
                           SQL_CHAR,
                           500,
                           0,
                           &xmldata,
                           500,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* InsertusingXMLVALIDATE */

/* Function to Drop tables */
int DropTables(SQLHANDLE hdbc)
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
  
  strcpy(stmt, "DROP TABLE VARTABLE");
 
  /* execute the statement */
  rc = SQLExecDirect(hstmt, (SQLCHAR *)stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DropTables */
