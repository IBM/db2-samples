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
** SOURCE FILE NAME: sqlxquery.c
**
** SAMPLE: How to run SQL/XML Queries   
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
**                XMLQUERY              
**                XMLEXISTS
**
** SQL STATEMENT USED:
**                SELECT 
**
**                
** OUTPUT FILE: sqlxquery.out (available in the online documentation)
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

/* The firstPO1 function returns the first item in the purchase order for customer custname passed as an argument*/
int firstPO1(SQLHANDLE hdbc,char *custname);

/* The firstPO2 function returns the first item in the purchaseorder when 
   Name is from the sequence (X,Y,Z)
   or the customer id is from the sequence (1000,1002,1003)  */
int firstPO2(SQLHANDLE hdbc);

/* The sortCust_PO function sort the customers according to the number of purchaseorders */
int sortCust_PO(SQLHANDLE hdbc);

/* The numPO function returns the number of purchaseorder having specific partid
   for the specific customer passed as an argument to the function*/ 
int numPO(SQLHANDLE hdbc,char *name, char *partid);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLINTEGER cid;
  SQLINTEGER price;
  char custname[20];
  sqlint32 count;
  char name[20];
  char partid[20];

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE DEMONSTRATES HOW THE SQL/XML  QUERIES CAN BE RUN USING CLI");
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
  strcpy(custname,"Robert Shoemaker");
  rc=firstPO1(hdbc,custname);
  
  rc=firstPO2(hdbc);
  
  rc=sortCust_PO(hdbc);
  
  strcpy(name,"Robert Shoemaker");
  strcpy(partid,"100-101-01");
  rc=numPO(hdbc,name,partid);
} /* main */

int firstPO1(SQLHANDLE hdbc,char *custname)
{

  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];
  SQLCHAR *stmt = (SQLCHAR *)"SELECT XMLQUERY('$p/PurchaseOrder/item[1]' PASSING p.porder AS \"p\")"
           " FROM purchaseorder AS p, customer AS c"
           " WHERE XMLEXISTS('$custinfo/customerinfo[name=$c and @Cid = $cid]'"
           " PASSING c.info AS \"custinfo\", p.custid AS \"cid\", cast(? as varchar(20)) as \"c\")";

  printf("\n SELECT FIRST PURCHASEORDER OF THE A CUSTOMER USING SQL/XML QUERY\n");
  printf("CUSTOMER NAME: %s",custname);

  printf("\n%s\n",stmt);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  cliRC = SQLPrepare(hstmt,(SQLCHAR *)stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* Bind the parameter marker */
  printf("\nBind the parameter markers with the value %s", custname);
  SQLBindParameter(hstmt,1,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_CHAR,20,0,custname,20,NULL);
    
  printf("\nExecute the Statement.....\n\n");
  cliRC = SQLExecute(hstmt);
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
    printf("%s \n",xmldata);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return 0;
} /* firstPO1 */

int firstPO2(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata1[3000];
  SQLVARCHAR xmldata2[3000];
  SQLVARCHAR name[3000];
  sqlint32 cid; 
  SQLCHAR *stmt=(SQLCHAR *)"SELECT cid, XMLQUERY('$custinfo/customerinfo/name' passing c.info as \"custinfo\"),"
                                       "XMLQUERY('$p/PurchaseOrder/item[1]' passing p.porder as \"p\"),"
                                       "XMLQUERY('$x/history' passing c.history as \"x\")"
                            " FROM purchaseorder as p,customer as c"
                            " WHERE xmlexists('$custinfo/customerinfo[name=(X,Y,Z)"
                                               " or @Cid=(1000,1002,1003) and @Cid=$cid ]'"
                                              " passing c.info as \"custinfo\", p.custid as \"cid\")";
 
  printf("\n*******************************************************************************");
  printf("\nUSE THE SQL/XML STATEMENT:\n");
  printf("TO RETURN THE FIRST PURCHASEORDER OF THE CUSTOMERS BASED ON THE FOLLOWING CONDITIONS");
  printf("\n1. Customer name in the sequence (X, Y, Z) or");
  printf("\n2. Customer id in the sequence (1000,1002,1003)");
  printf("\n%s\n",stmt);
  
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* Directly execute the statement */
  printf("\n  Directly execute the statement\n");
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &cid, 4, NULL);
 
  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, &name, 1000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */ 
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, &xmldata1, 1000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, &xmldata2, 1000, NULL);
  
  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("cid: %d \n name: %s\n",cid,name);
    printf("First PurchaseOrder: %s  \n History:  %s \n\n",xmldata1,xmldata2);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return rc;
} /* firstPO2 */

int sortCust_PO(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER count; 
  SQLVARCHAR xmldata[3000];
  SQLCHAR *stmt = (SQLCHAR *)"WITH count_table AS ( SELECT count(poid) as c,custid"
                " FROM purchaseorder,customer"
                " WHERE cid=custid group by custid )"
            " SELECT c, xmlquery('$s/customerinfo[@Cid=$id]/name'"
                               " passing customer.info as \"s\", count_table.custid as \"id\")"
            " FROM customer,count_table"
            " WHERE custid=cid ORDER BY c";

  printf("\n**************************************************");
  printf("\nRETURN ALL THE CUSTOMER NAMES AND SORT THEN ACCORDING TO THE NUMBER OF PURCHASE ORDERS");
  printf("\n%s",stmt);
 
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the statement */
  printf("\n  Directly execute the statement\n");
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &count, 4, NULL); 
  
  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, &xmldata, 1000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nCount        name\n");
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("%d, %s \n",count,xmldata);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return rc;
} /* sortCust_PO */

int numPO(SQLHANDLE hdbc,char *name, char *partid)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  int num;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];
  SQLCHAR *stmt = (SQLCHAR *)"WITH cid_table AS (SELECT Cid FROM customer"
                " WHERE XMLEXISTS('$custinfo/customerinfo[name=$name]'"
                      " PASSING customer.info AS \"custinfo\", cast(? as varchar(20)) as \"name\"))"
                " SELECT count(poid) FROM purchaseorder,cid_table"
                " WHERE XMLEXISTS('$po/itemlist/item[partid=$id]'"
                       " PASSING purchaseorder.porder AS \"po\", cast(? as varchar(20)) as \"id\")"
                " AND purchaseorder.custid=cid_table.cid";
 
  printf("********************************************************\n");
  printf("RETURN THE NUMBER OF PURCHASEORDER FOR CUSTOMER %s  WITH THE PARTID %s", name, partid);
  printf(" USING  SQL/XML QUERY\n");
  printf("\n%s",stmt); 
  printf("\nCUSTOMER NAME: %s, PART ID: %s",name,partid);
  
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  cliRC = SQLPrepare(hstmt,(SQLCHAR *)stmt,SQL_NTS);
  
  /* Bind first parameter */
  printf("\nBind the first parameter markers with the value %s\n",name);
  SQLBindParameter(hstmt,1,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_CHAR,20,0,name,20,NULL);
  
  /* Bind second parameter */
  printf("\nBind the second parameter markers with the value %s\n" , partid);
  SQLBindParameter(hstmt,2,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_CHAR,20,0,partid,20,NULL);

  printf("\nExecute the Statement.....");
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &num, 4, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  else 
    printf("\nCount : %d \n",num);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  return 0;
} /* numPO */
