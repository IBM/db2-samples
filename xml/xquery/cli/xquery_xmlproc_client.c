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
** SOURCE FILE NAME: xquery_xmlproc_client.c
**
** SAMPLE: Call the stored procedure implemented in xquery_xmlproc.c
**
**         To run this sample, peform the following steps:
**         (1) see and complete the instructions in xquery_xmlproc.c for building
**             the shared library
**         (2) compile xquery_xmlproc_client.c (nmake xquery_xmlproc_client (Windows)
**             or make xquery_xmlproc_client(UNIX), or bldapp xquery_xmlproc_client 
**             for the Microsoft Visual C++ compiler on Windows)
**         (3) run xquery_xmlproc_client (xquery_xmlproc_client)
**
**         xquery_xmlproc_client.c uses a function to call stored procedure defined
**         in xquery_xmlproc.c.
**
**         callxquery_proc: Calls the stored procedure defined in 
**             xquery_xmlproc.c and returns the details of the customers
**             with excess amount paid by them.
**
**               Parameter types used:
**                              IN  XML AS CLOB(5000)
**                              IN  XML AS CLOB(5000)
**                              OUT INTEGER 
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare a Statement
**
** EXTERNAL DEPENDENCIES:
**      Ensure that the stored procedures called from this program have
**      been built and cataloged with the database (see the instructions in
**      xquery_xmlproc.c).
**
** OUTPUT FILE: xquery_xmlproc_client.out (available in the online documentation)
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
#include <sqludf.h>
#include "utilcli.h"   

int callxquery_proc(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

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
                  SQL_AUTOCOMMIT_OFF);
  if (rc != 0)
  {
    return rc;
  }
 
  /********************************************************\
  * calling   stored procedure                     *
  \********************************************************/
  rc = callxquery_proc(hdbc);

  /* rollback any changes to the database made by this sample */
  printf("\nRoll back the transaction.\n");

  /* end transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */


/* call the Supp_XML_Proc_CLI stored procedure */
int callxquery_proc(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  SQLHANDLE hstmt; /* statement handle */
  int rc = 0;
  char temp[5000]="";

  struct inXML_t
  {
      sqluint32 length;
      char      data[5000];
  } inXML;

  struct outXML_t
  {
      sqluint32 length;
      char      data[5000];
  } outXML;

  char procName[] = "Supp_XML_Proc_CLI";
  SQLCHAR *stmt = (SQLCHAR *)"CALL Supp_XML_Proc_CLI(?,?)";

  strcpy( inXML.data, "<Suppliers> <Supplier id=\"100\">"
                      "<Products> <Product id=\"100-100-01\"><ExtendedDate>2006-01-02"
                      "</ExtendedDate></Product> <Product id= \"100-101-01\"><Extended"
                      "Date>2006-08-02</ExtendedDate></Product></Products> </Supplier>"
                      "<Supplier id=\"101\"> <Products><Product id=\"100-103-01\"> "
                      "<ExtendedDate>2006-09-22</ExtendedDate> </Product> </Products> "
                      "</Supplier> </Suppliers>");
  inXML.length=strlen(inXML.data);

  printf("\n ******************************************************************************\n");
  printf("\n CALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the parameters to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_XML,
                           5000,
                           0,
                           &(inXML.data),
                           5000,
                           (SQLINTEGER *)&(inXML.length));

  STMT_HANDLE_CHECK(hstmt,hdbc,cliRC);

  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_XML,
                           5000,
                           0,
                           &(outXML.data),
                           5000,
                           (SQLINTEGER*)&(outXML.length));
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);

  /* place the results into application variables */
  strncpy(temp, outXML.data, outXML.length);
  temp[outXML.length] = '\n';

  printf("\n Stored procedure Returned: \n");

  printf("\n Customers are: \n  %s", temp);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
}  /* end callxquery_proc */



