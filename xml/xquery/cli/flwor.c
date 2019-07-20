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
** SOURCE FILE NAME: flwor.c
**
** SAMPLE: How to use XQuery FLWOR expressions 
**
** CLI FUNCTIONS USED:
**                SQLAllocHandle
**                SQLExecDirect
**                SQLBindCol
**                SQLFetch
**                SQLFreeHandle
**                SQLPrepare
**                SQLBindParameter
**           
** SQL/XML FUNCTIONS USED:
**                xmlcolumn
**                xmlquery
**
** XQuery function used:
**                data
**                string 
**
** OUTPUT FILE: flwor.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference.
**
** For information on using SQL statements, see the SQL Reference.
**
** For information on using XQuery statements, see the XQuery Reference

** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>
#include "utilcli.h" /* Header file for CLI sample code */

/* The orderCustDetails method returns customer information in alphabetical order by customer name */ 
int OrderCustDetails(SQLHANDLE hdbc);

/* The conditionalCustDetails1 returns information for customers whose customer ID is greater than 
   the cid value passed as an argument */
int conditionalCustDetails1(SQLHANDLE hdbc,sqlint32 cid);

/* The conditionalCustDetails2 method returns information for customers whose customer ID is greater than 
   the cid value passed to the function and who dont live in the country passed as an argument */
int conditionalCustDetails2(SQLHANDLE hdbc,int cid, char *country);

/* The maxpriceproduct function returns the product details with maximun price */
int maxpriceproduct(SQLHANDLE hdbc);

/* The basicproduct function returns the product with basic attribute value true 
   if the price is less then price parameter otherwiese false */
int basicproduct(SQLHANDLE hdbc,float price);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLINTEGER cid;
  float price; 
  char country[10]; 
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE DEMONSTRATES HOW THE SIMPLE FLWOR EXPRESSION QUERIES CAN BE USED IN CLI");
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
  
  /* Set the attribute SQL_ATTR_XML_DECLARATION to skip the XML declaration from XML Data */
  rc=SQLSetConnectAttr(hdbc, SQL_ATTR_XML_DECLARATION, (SQLPOINTER)SQL_XML_DECLARATION_NONE, SQL_NTS);
  printf("%d", rc); 
  if (rc != 0)
  {
    return rc;
  }
   

  printf("*******************************************************************\n");
  printf("Return customer information in alphabetical order by customer name.....\n\n");
  rc=OrderCustDetails(hdbc);
  
  printf("*******************************************************************\n\n");
  printf("Return the product information with maximum price......\n\n");
  rc=maxpriceproduct(hdbc);

  cid=1002;
  printf("*******************************************************************\n");
  printf("Return the information for customer whose customer ID is greater then %d.....\n\n", cid);
  rc=conditionalCustDetails1(hdbc,cid);
  
  cid=1000;
  strcpy(country,"US");
  printf("*******************************************************************\n");
  printf("Return the customer information with customer ID greater then %d and",cid); 
  printf(" who dont live in country %s.....\n\n", country);
  rc=conditionalCustDetails2(hdbc,cid,country);
  
  price=10; 
  printf("*******************************************************************\n\n");
  printf("Return the product with basic price %f........\n\n", price);
  rc=basicproduct(hdbc,price);
  return rc;
} /* main */

int OrderCustDetails(SQLHANDLE hdbc)
{

  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];

  /* query to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"for $custinfo in db2-fn:xmlcolumn('CUSTOMER.INFO')"
                             "/customerinfo[addr/@country=\"Canada\"]"
                             " order by $custinfo/name,fn:number($custinfo/@Cid)"
                             " return $custinfo";

  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

    /* Set the attribute SQL_ATTR_XQUERY_STATEMENT to indicate that the query is an XQuery */
  rc = SQLSetStmtAttr(hstmt, SQL_ATTR_XQUERY_STATEMENT, (SQLPOINTER)SQL_TRUE, SQL_NTS);

  if (rc != 0)
  {
    return rc;
  }

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
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
    printf("%s \n\n",xmldata);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* OrderCustDetails */

int conditionalCustDetails1(SQLHANDLE hdbc,sqlint32 cid)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];
  
  /* SQL/XML statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *) "select xmlquery('"
                              " for $customer in $cust/customerinfo"
                              " where ($customer/@Cid > $id)"
                              " order by $customer/@Cid "
                              " return <customer id=\"{$customer/@Cid}\">"
                              " {$customer/name} {$customer/addr} </customer>'"
                              " passing by ref customer.info as \"cust\", cast(? as integer) as \"id\")"
                              " from customer order by cid";
 
                             
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    %s\n", stmt);
  cliRC = SQLPrepare(hstmt,(SQLCHAR *)stmt,SQL_NTS); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* Bind the parameter value */ 
  printf("\nBind the parameter markers with the value %d", cid);
  SQLBindParameter(hstmt,1,SQL_PARAM_INPUT,SQL_C_LONG,SQL_INTEGER,4,0,&cid,4,NULL); 

  printf("\nExecute the Statement.....\n");
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 3000, NULL);
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
    if(strcmp((char *)xmldata,"")!=0)
    printf("%s \n\n",xmldata);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return rc;
} /* conditionalCustDetails1 */

int conditionalCustDetails2(SQLHANDLE hdbc,int cid, char *country)
{

  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];

  /* SQL/XML statement to be executed */

  SQLCHAR *stmt = (SQLCHAR *) "SELECT XMLQUERY('"
                               " for $customer in db2-fn:xmlcolumn(\"CUSTOMER.INFO\")/customerinfo"
                               " where ($customer/@Cid > $id) and ($customer/addr/@country !=$c)"
                               " order by $customer/@Cid"
                               " return <customer id=\"{fn:string($customer/@Cid)}\">"
                               " {$customer/name}"
                               " <address>{$customer/addr/street}"
                               " {$customer/addr/city} </address></customer>'"
                               " passing by ref cast(? as integer) as \"id\","
                               " cast(? as varchar(10)) as \"c\")"
                               " FROM  SYSIBM.SYSDUMMY1"; 

  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    %s\n", stmt);
  cliRC = SQLPrepare(hstmt,(SQLCHAR *)stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* Bind the first parameter marker */ 
  printf("\nBind the first parameter marker with the value %d\n", cid);
  SQLBindParameter(hstmt,1,SQL_PARAM_INPUT,SQL_C_LONG,SQL_INTEGER,4,0,&cid,4,NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind the second parameter marker */
  printf("\nBind the second parameter parameter  with the value %s", country);
  SQLBindParameter(hstmt,2,SQL_PARAM_INPUT,SQL_C_CHAR, SQL_CHAR, 10,0,country,10,NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nExecute the Statement.....\n\n");
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 3000, NULL);
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
    printf("%s \n\n",xmldata);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return rc;
} /* conditionalCustDetails2 */

int maxpriceproduct(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];

  /* query to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"XQUERY "
                   " let $prod := for $product in db2-fn:xmlcolumn('PRODUCT.DESCRIPTION')/product/description"
                   " order by fn:number($product/price) descending return $product"
                   " return <product> {$prod[1]/name} </product>";

  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* Set the attribute SQL_ATTR_XQUERY_STATEMENT to indicate that the query is an XQuery */
  rc = SQLSetStmtAttr(hstmt, SQL_ATTR_XQUERY_STATEMENT, (SQLPOINTER)SQL_TRUE, SQL_NTS);
  printf("%d", rc);

  if (rc != 0)
  {
    return rc;
  }
 
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
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
   else 
   printf("%s \n\n",xmldata);

  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return rc;
} /* maxpriceproduct */

int basicproduct(SQLHANDLE hdbc,float price)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];

  /* SQL/XML statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *) "select xmlquery('"
                              "for $prod in db2-fn:xmlcolumn(\"PRODUCT.DESCRIPTION\")/product/description"
                              " order by $prod/name "
                              " return ( if ($prod/price < $price)"
                              " then <product basic = \"true\">{fn:data($prod/name)}</product>"
                              " else <product basic = \"false\">{fn:data($prod/name)}</product>)'"
                              " passing by ref cast(? as float) as \"price\")"
                              " from SYSIBM.SYSDUMMY1";


  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("    %s\n", stmt);
  cliRC = SQLPrepare(hstmt,(SQLCHAR *)stmt,SQL_NTS);
  
  /* Bind the parameter marker */ 
  printf("\nBind the parameter marker with the value %f", price);
  SQLBindParameter(hstmt,1,SQL_PARAM_INPUT,SQL_C_FLOAT,SQL_REAL,8,0,&price,8,NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nExecute the Statement.....");
  cliRC = SQLExecute(hstmt);
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
    printf("%s \n\n",xmldata);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* Free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return rc;
} /* basicproduct */

