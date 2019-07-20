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
** SOURCE FILE NAME: xmltotable.c
**
** SAMPLE USAGE SCENARIO:Purchase order XML document contains detailed
** information about all the orders. It will also have the detail of the
** customer with each order.
**
** PROBLEM: The document has some redundant information as customer info
** and product info is repeated in each order for example
** Customer info is repeated for each order from same customer.
** Product info will be repeated for each order of same product from different customers.
**
** SOLUTION: The sample database has tables with both relational and XML data to remove
** this redundant information. These relational tables will be used to store
** the customer info and product info in the relational table having XML data
** and id value. Purchase order will be stored in another table and it will
** reference the customerId and productId to refer the customer and product
** info respectively.
**
** To achieve the above goal this sample will shred the data for purchase order XML
** document and insert it into the tables.
**
** The sample will follow the following steps
**
** 1. Get the relevant data in XML format from the purchase order XML document (use XMLQuery)
** 2. Shred the XML doc into the relational table. (Use XMLTable)
** 3. Select the relevant data from the table and insert into the target relational table.
**
** EXTERNAL DEPENDENCIES:
**     For successful precompilation, the sample database must exist
**     (see DB2's db2sampl command).
**     XML Document purchaseorder.xml must exist in the same directory as of this sample
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare Statement
**         SQLBindCol -- Bind Out a Column to a Variable
**         SQLFetch -- Fetch a Column
**         SQLBindParameter -- Bind in a Parameter
**
** XML FUNCTIONS USED:
**         XMLCOLUMN
**         XMLELEMENT
**         XMLTABLE
**         XMLDOCUMENT
**         XMLATTRIBTES
**         XMLCONCAT
**         XQUERY
**
** OUTPUT FILE: xmltotable.out (available in the online documentation)
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

int shred_PO(SQLHANDLE hdbc);
int displaycontent(SQLHANDLE hdbc);
int cleanUp(SQLHANDLE hdbc);

int main(int argc, char *argv[])
{
  int rc = 0;
  SQLRETURN cliRC = SQL_SUCCESS;
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

  printf("\nTHIS SAMPLE WILL SHOW HOW TO STORE THE DATA IN RELATIONAL TABLE FROM XML DOCUMENT");
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
 
  /* call the shred_PO function to store the data in relational table */
  shred_PO(hdbc);
  
  /* Display the contents */
  displaycontent(hdbc);

  /* Clean up the data inserted */
  cleanUp(hdbc); 
 
  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);
  return rc;
}/*main*/

int displaycontent(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt;
  SQLCHAR *stmt;
  sqlint32 cid;
  SQLVARCHAR xmldata[1000];
 
  /* allocate a statement handles */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  stmt = (SQLCHAR *) "SELECT cid, info FROM CUSTOMER ORDER BY cid";
  
  printf("\n%s\n",stmt);
  /* Directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &cid, 4, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 

  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, &xmldata, 1000, NULL);
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
    printf("CID = %d \n INFO= %s \n\n",cid, xmldata);

    /* Fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* allocate a statement handles */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);
 
  stmt = (SQLCHAR *) "SELECT poid,porder FROM purchaseorder ORDER BY poid"; 
  printf("\n%s\n",stmt); 
  
  /* Directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &cid, 4, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, &xmldata, 1000, NULL);
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
    printf("POID = %d \n PORDER= %s \n\n",cid, xmldata);

    /* Fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
 

  /* Free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

} /* displaycontent */

int cleanUp(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt;
  SQLCHAR *stmt;
 
  /* allocate a statement handles */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  stmt = (SQLCHAR *) "DELETE FROM CUSTOMER WHERE CID IN (10,11)";
  printf("\n%s\n",stmt);
 
  /* Directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  stmt = (SQLCHAR *) "DELETE FROM PURCHASEORDER WHERE POID IN (110,111)";
  printf("\n%s\n",stmt);

  /* Directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
} /* cleanUp */

int shred_PO(SQLHANDLE hdbc) 
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  int num_record_customer=0;
  int num_record_po=0;
  SQLCHAR *data=(SQLCHAR *) "purchaseorder.xml"; /* file name with XML data */
  SQLHANDLE hstmt1; /* statement handle */
  SQLHANDLE hstmt2; /* statement handle */
  SQLVARCHAR xmldata[3000];
  SQLCHAR cursorName[20];
  SQLUINTEGER fileOption = SQL_FILE_READ;
  SQLSMALLINT cursorLen;
  SQLCHAR *stmt1;
  SQLCHAR *stmt2;
  SQLCHAR *stmt;
  FILE *testfile; 
  /* allocate a statement handles */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2); 
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  /* execute the create statement to create PO table */ 
  stmt= (SQLCHAR *) "CREATE TABLE PO(id INT GENERATED ALWAYS AS IDENTITY,purchaseorder XML)";
  cliRC = SQLExecDirect(hstmt1, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* insert the XML document in PO table */
  stmt=(SQLCHAR *) "insert into PO(purchaseorder) values(cast(?  as XML))";
  cliRC = SQLPrepare(hstmt1, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
 
  /* bind the file "purchaseorder.xml" to the XML parameter */
  /* C data type should be one of SQL_BLOB, SQL_CLOB or SQL_DBCLOB while binding file to a parameter */
  testfile = fopen("purchaseorder.xml" , "r" );
  if ( testfile == NULL )
  {
     printf("fopen() error.\n");
     printf("Error accessing file: purchaseorder.xml \n");
     exit(0);
  }

  cliRC = SQLBindFileToParam(hstmt1,
                           1,
                           SQL_BLOB,
                           data, 
                           NULL, 
                           &fileOption,
                           17,
                           NULL);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  cliRC=SQLExecute(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC); 
  
  /* run the XQuery to find out the purchaseorder with status shipped */
  stmt= (SQLCHAR *) "db2-fn:xmlcolumn("
                    "'PO.PURCHASEORDER')/PurchaseOrders/PurchaseOrder[@Status='shipped']";
  printf(" Run the following XQuery to find out all the purchaseorder with status shipped...\n");
  printf("db2-fn:xmlcolumn('");
  printf(" PO.PURCHASEORDER')/PurchaseOrders/PurchaseOrder[@Status='shipped']\n\n");
  
  /* set the statement handle attribute SQL_ATTR_XQUERY_STATEMENT to 
  indicate that statement is XQuery statement. This is equivalent to prefixing the Xquery
  expression with XQUERY keyword */
  cliRC=SQLSetStmtAttr(hstmt1, SQL_ATTR_XQUERY_STATEMENT, (SQLPOINTER) SQL_TRUE, 0);
  
  /* directly execute the XQUERY statement */
  cliRC = SQLExecDirect(hstmt1, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
 
  /* reset the statement handle attribute SQL_ATTR_XQUERY_STATEMENT to false
     so that statement handle can be used to run subsequent SQL statements */ 
  cliRC=SQLSetStmtAttr(hstmt1, SQL_ATTR_XQUERY_STATEMENT, (SQLPOINTER) SQL_FALSE, 0);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

  /* bind the first column to a variable of type SQLVARCHAR 
     XML column can be bound to any of the following C data type 
     SQL_C_CHAR, SQL_C_WCHAR, SQL_C_DBCHAR, SQL_C_BINARY. Binding the data
     to SQL_C_CHAR, SQL_C_WCHAR will convert the XML value to the application 
     character codepage. This may result in a loss of data if any characters in 
     the source data cannot be represented. SQL_C_BINARY will be recommended in 
     such cases to avoid any codepage issues */
  cliRC= SQLBindCol(hstmt1,1,SQL_C_CHAR,&xmldata,1000,NULL);
  
  /* fetch the first row */ 
  cliRC = SQLFetch(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  
   /* insert into the customer table */
   /* XMLTable function will be used to create a table from XML document */
   /* select the data from the table and insert it into the customer table */
  stmt1 = (SQLCHAR *)"INSERT INTO customer(CID,info,history)"
                     " SELECT T.CustID,xmldocument("
                     " XMLELEMENT(NAME \"customerinfo\",XMLATTRIBUTES (T.CustID as \"Cid\"),"
                     " XMLCONCAT(XMLELEMENT(NAME \"name\", T.Name ),T.Addr,"
                     " XMLELEMENT(NAME \"phone\", XMLATTRIBUTES(T.Type as \"type\"), T.Phone)"
                     " ))), xmldocument(T.History)"
                     " FROM XMLTABLE( '$d/PurchaseOrder' PASSING cast(? as XML)  AS \"d\""
                     " COLUMNS CustID BIGINT PATH  '@CustId',"
                     " Addr      XML                 PATH './Address',"
                     " Name     VARCHAR(20)       PATH './name',"
                     " Country  VARCHAR(20)  PATH './Address/@country',"
                     " Phone    VARCHAR(20)  PATH './phone',"
                     " Type     VARCHAR(20) PATH './phone/@type',"
                     " History XML PATH './History') as T"
                     " WHERE T.CustID NOT IN (SELECT CID FROM customer)";

  
   stmt2 = (SQLCHAR *) "INSERT INTO purchaseOrder(poid, orderdate, custid,status, porder, comments)"
                       " SELECT poid, orderdate, custid, status,xmldocument(XMLELEMENT(NAME \"PurchaseOrder\","
                                                         " XMLATTRIBUTES(T.Poid as \"PoNum\", T.OrderDate as \"OrderDate\","
                                                          "  T.Status as \"Status\"),"
                                                  "T.itemlist)), comment"
                       " FROM XMLTable ('$d/PurchaseOrder' PASSING cast(? as XML)  as \"d\""
                       " COLUMNS poid BIGINT PATH '@PoNum',"
                       " orderdate date PATH '@OrderDate',"
                       " CustID BIGINT PATH '@CustId',"
                       " status varchar(10) PATH '@Status',"
                       " itemlist XML PATH './itemlist',"
                       " comment varchar(1024) PATH './comments') as T";


  
  printf("Insert into customer table using following insert statement.....\n\n");
  printf("%s", stmt1);
  printf("Insert into purchaseorder using the following insert statement.....\n\n");
  printf("%s\n", stmt2);

  /* iterate for all the rows, insert the data into the relational table */
  while(cliRC != SQL_NO_DATA_FOUND) 
  {
    /* insert into the customer table */
    /* XMLTable function will be used to create a table from XML document */
    /* select the data from the table and insert it into the customer table */ 
    printf("Inserting into customer table ....\n");
    
    cliRC = SQLPrepare(hstmt2, stmt1, SQL_NTS);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
    
    /* bind the parameter SQL type will be SQL_XML */
    cliRC = SQLBindParameter(hstmt2,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR, 
                           SQL_XML, 
                           0,
                           0,
                           &xmldata,
                           1000,
                           NULL);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
    cliRC=SQLExecute(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
    num_record_customer++;

    /* insert into he purchaseorder table */ 
    printf("Inserting into purchaseorder table ....\n"); 
    cliRC = SQLPrepare(hstmt2, stmt2, SQL_NTS);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
    
    /* bind the XML parameter, SQL type will be SQL_XML, C type SQL_C_CHAR */
    cliRC = SQLBindParameter(hstmt2,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_XML,
                           0,
                           0,
                           &xmldata,
                           1000,
                           NULL);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
    cliRC=SQLExecute(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC); 
    num_record_po++; 
    cliRC = SQLFetch(hstmt1);
 } /* While loop */

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC); 

  /* drop the table PO */
  stmt=(SQLCHAR *) "DROP TABLE PO";
  cliRC = SQLExecDirect(hstmt1, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  printf("\nNumber of record inserted into customer table = %d\n",num_record_customer);
  printf("Number of record inserted into purchaseorder table = %d\n",num_record_po); 

}/* PO_shred */
