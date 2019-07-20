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
** SOURCE FILE NAME: xquery.c
**
** SAMPLE: How to run a nested XQuery and shows how to pass parameters to
**         sqlquery function.
**
** CLI FUNCTIONS USED:
**                SQLAllocHandle
**                SQLExecDirect
**                SQLBindCol
**                SQLFetch
**                SQLFreeHandle
**
** SQL/XML FUNCTIONS USED:
**                xmlcolumn
**                sqlquery
**
** XQUERY EXPRESSION USED
**           FLWOR Expression
**
**                  
** OUTPUT FILE: xquery.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference.
**
** For information on using XQuery statements, see the XQuery Reference
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

/* Functions used in the sample */

/* The PO_orderbycity function restructures the purchaseorders according to the city. */
int PO_orderbycity(SQLHANDLE hdbc);

/* The Customer_orderbyproduct restructures the purchaseorder according to the product */
int Customer_orderbyproduct(SQLHANDLE hdbc);

/* The PO_orderbyProvCityStreet function restructures the purchaseorder data according to provience, city and street */
int PO_orderbyProvCityStreet(SQLHANDLE hdbc);

/* This CustomerPO function combines the data from customer and product table to create a purchaseorder*/ 
int CustomerPO(SQLHANDLE hdbc);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  char id[10];
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE DEMONSTRATES HOW THE NESTED XQUERIES CAN BE RUN USING CLI");
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
  printf("-------------------------------------------------------------\n");
  printf("RESTRUCTURE THE PURCHASEORDERS ACCORDING TO THE CITY....\n");
  rc=PO_orderbycity(hdbc);
  
  printf("-------------------------------------------------------------\n");
  printf("RESTRUCTURE THE PURCHASEORDER ACCORDING TO THE PRODUCT.....\n");
  rc=Customer_orderbyproduct(hdbc);

  printf("-------------------------------------------------------------\n");
  printf("RESTRUCTURE THE PURCHASEORDER DATA ACCORDING TO PROVIENCE, CITY AND STREET..\n");
  rc=PO_orderbyProvCityStreet(hdbc);
 
  printf("-------------------------------------------------------------\n");
  printf("COMBINE THE DATA FROM PRODUCT AND CUSTOMER TABLE TO CREATE A PURCHASEORDER..\n");
  rc=CustomerPO(hdbc);
} /* main */

int Customer_orderbyproduct(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[5000];

  /* XQUERY statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"XQUERY let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"pos\"\","

                                                        "( XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", c.custid),"
                                                                     "XMLELEMENT(NAME \"\"order\"\", c.porder)"
                                                       " ) ))"
                                     " FROM purchaseorder AS c\" )"
                  " for $partid in fn:distinct-values(db2-fn:xmlcolumn('PURCHASEORDER.PORDER')/PurchaseOrder/item/partid)"
                    " order by $partid"
                    " return"
                    " <Product name='{$partid}'>"
                     " <Customers>"
                       " {"
                         " for  $id in fn:distinct-values($po[order/PurchaseOrder/item/partid=$partid]/custid)"
                         " let  $order:=<quantity>"
                         " {fn:sum($po[custid=$id]/order/PurchaseOrder/item[partid=$partid]/quantity)}"
                         " </quantity>,"
                       " $cust:=db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[@Cid=$id]"
                     " order by $id"
                     " return"
                     " <customer id='{$id}'>"
                       " {$order}"
                       " {$cust}"
                     " </customer>"
                     " }"
                  " </Customers>"
                 "</Product>";

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 2000, NULL);
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
    /* Print the data */
    printf("%s \n\n",xmldata);

    /* Fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
 
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* Customer_orderbyproduct */

int PO_orderbycity(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt, hstmt1; /* statement handles */
  SQLVARCHAR xmldata[3000];
  
  /* XQUERY statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"XQUERY "
            " for $city in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo/addr/city)"
            " order by $city"
             " return"
               " <city name='{$city}'>"
               "{"
                 " for  $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[addr/city=$city]"
                 " let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"pos\"\","
                                              " (XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", c.custid),"
                                                           "XMLELEMENT(NAME \"\"order\"\", c.porder)"
                                                               "    ) ))"
                                   " FROM purchaseorder AS c\")"
         " let $id:=$cust/@Cid,"
             " $order:=$po/pos[custid=$id]/order"
         " order by $cust/@Cid"
         " return"
         " <customer id='{$id}'>"
          " {$cust/name}"
          " {$cust/addr}"
          " {$order}"
         " </customer>}"
        " </city>";
 
    SQLCHAR *stmt1 = (SQLCHAR *)"XQUERY "
          "for $city in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO') /customerinfo/addr/city)"
          " order by $city "
          "return"
             "<city name='{$city}'>"
            "{"
              "for  $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo [addr/city=$city]"
              "let $po:=db2-fn:sqlquery(\"SELECT porder FROM PURCHASEORDER WHERE custid=parameter(1)\",$cust/@Cid),"
               " $order:=$po/order"
              " order by $cust/@Cid"
              " return"
                " <customer id = '{$cust/@Cid}'>"
                  " {$cust/name}"
                  " {$cust/Addr}"
                  " {$order}"
                " </customer>}"
             " </city>";

                       
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 2000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* fetch the result and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* Print the data */
    printf("%s \n\n",xmldata);

    /* Fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n\nThe following query shows how to pass parameters to");
  printf(" sqlquery function which is an enhancement in Viper2");
  printf("\n--------------------------------------------------");
  printf("\n  Directly execute the statement\n");
  printf("    %s\n\n", stmt1);

  cliRC = SQLExecDirect(hstmt1, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt1, 1, SQL_C_CHAR, &xmldata, 1000, NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* fetch the result and display */
  cliRC = SQLFetch(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* Print the data */
    printf("%s \n\n",xmldata);

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

} /* PO_orderbycity */

int PO_orderbyProvCityStreet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[5000];

  /* XQUERY statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"XQUERY " 
     " let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"pos\"\","
                                          "( XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", c.custid),"
                                          "XMLELEMENT(NAME \"\"order\"\", c.porder)"
                                                       ") ))"
                                           " FROM PURCHASEORDER as c ORDER BY poid\"),"
       " $addr:=db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo/addr"
       " for $prov in distinct-values($addr/prov-state)"
       " return"
       " <province name='{$prov}'>"
       " {"
         " for $city in fn:distinct-values($addr[prov-state=$prov]/city)"
         " order by $city"
         " return"
         " <city name='{$city}'>"
         " {"
           " for $s in fn:distinct-values($addr/street) where $addr/city=$city"
           " order by $s"
           " return"
           " <street name='{$s}'>"
           " {"
             " for $info in $addr[prov-state=$prov and city=$city and street=$s]/.."
             " order by $info/@Cid"
             " return"
             " <customer id='{$info/@Cid}'>"
             " {$info/name}"
             " {"
               " let $id:=$info/@Cid, $order:=$po[custid=$id]/order"
               " return $order"
             " }"
            " </customer>"
           " }"
           " </street>"
         " }"
          " </city>"
       " }"
       " </province>";
 
 
   /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 5000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch the result and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
    printf("%s \n\n",xmldata);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* PO_orderbyProvCityStreet */ 


int CustomerPO(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLVARCHAR xmldata[3000];

  /* XQUERY statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"XQUERY "
                                        "<PurchaseOrder>"
                    "{"
                        " for $ns1_customerinfo0 in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo"
                        " where ($ns1_customerinfo0/@Cid=1001)"
                        " return"
                        " <customer customerid='{ fn:string( $ns1_customerinfo0/@Cid)}'>"
                        " {$ns1_customerinfo0/name}"
                            " <address>"
                              " {$ns1_customerinfo0/addr/street}"
                              " {$ns1_customerinfo0/addr/city}"
                              " {"
                                 " if($ns1_customerinfo0/addr/@country=\"US\")"
                                 " then"
                                  " $ns1_customerinfo0/addr/prov-state"
                                  " else()"
                              " }"
                               " {"
                   " fn:concat ($ns1_customerinfo0/addr/pcode-zip/text(),\",\",fn:upper-case($ns1_customerinfo0/addr/@country))}"
                           " </address>"
                          " </customer>"
                        " }"
                        " {"
                         " for $ns2_product0 in db2-fn:xmlcolumn('PRODUCT.DESCRIPTION')/product"
                         " where ($ns2_product0/@pid=\"100-100-01\")"
                         " return"
                         " $ns2_product0"
                     " }"
                   " </PurchaseOrder>";

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata, 3000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch the result and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
    printf("%s \n\n",xmldata);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;

} /* CustomerPO */


