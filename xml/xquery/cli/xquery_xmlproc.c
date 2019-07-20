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
** SOURCE FILE NAME: xquery_xmlproc.c
**
** SAMPLE: Code implementation of Supp_XML_Proc_CLI stored procedure
**
**         The stored procedure defined in this program is called by the
**         client application xquery_xmlproc_client.c. Before building and running
**         xquery_xmlproc_client.c, build the shared library by completing the 
**         following steps:
**
** BUILDING THE SHARED LIBRARY:
** 1. Ensure the Database Manager Configuration file has the keyword
**    KEEPFENCED set to "no". This allows shared libraries to be unloaded
**    while you are developing stored procedures. You can view the file's
**    settings by issuing the command: "db2 get dbm cfg". You can set
**    KEEPFENCED to "no" with this command: "db2 update dbm cfg using
**    KEEPFENCED no". NOTE: Setting KEEPFENCED to "no" reduces performance
**    the performance of accessing stored procedures, because they have
**    to be reloaded into memory each time they are called. If this is a
**    concern, set KEEPFENCED to "yes", stop and then restart DB2 before
**    building the shared library, by entering "db2stop" followed by
**    "db2start". This forces DB2 to unload shared libraries and enables
**    the build file or the makefile to delete a previous version of the
**    shared library from the "sqllib/function" directory.
** 2. To build the shared library, enter "bldrtn xquery_xmlproc", or use the
**    makefile: "make xquery_xmlproc"(UNIX) or "nmake xquery_xmlproc"(Windows).
**
** CATALOGING THE STORED PROCEDURES
** 1. The stored procedures are cataloged automatically when you build
**    the client application "xquery_xmlproc_client" using the appropriate 
**    "make" utility for your Operating System and the "makefile" provided with
**    these samples. If you wish to catalog or recatalog them manually, enter
**    "spcat_xquery". The spcat_xquery script (UNIX) or spcat_xquery.bat batch 
**    file (Windows) connects to the database, runs xquery_xmlproc_drop.db2 to
**    uncatalog the stored procedures if they were previously cataloged, then 
**    runs xquery_xmlproc_create.db2 which catalogs the stored procedures, 
**    then disconnects from the database.
**
** CALLING THE STORED PROCEDURES IN THE SHARED LIBRARY:
** 1. Compile the xquery_xmlproc_client program with "bldapp xquery_xmlproc_client" 
**    or use the makefile: "make xquery_xmlproc_client" (UNIX) or 
**    "nmake xquery_xmlproc_client" (Windows).
** 2. Run xquery_xmlproc_client: "xquery_xmlproc_client" (if calling remotely add
**    the parameters for database, user ID and password.)
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare a Statement
**         SQLSetConnectAttr -- Set Connection Attributes
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

/* macros for handle checking */
#define SRV_HANDLE_CHECK(htype, hndl, CLIrc, henv, hdbc)                  \
if (CLIrc == SQL_INVALID_HANDLE)                                          \
{                                                                         \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}                                                                         \
if (CLIrc == SQL_ERROR)                                                   \
{                                                                         \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}

#define                                                                   \
SRV_HANDLE_CHECK_SETTING_SQLST(htype, hndl, CLIrc, henv, hdbc, sqlstate)  \
if (CLIrc == SQL_INVALID_HANDLE)                                          \
{                                                                         \
  memset(sqlstate, '0', 6);                                               \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}                                                                         \
if (CLIrc == SQL_ERROR)                                                   \
{                                                                         \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}

#define                                                                   \
SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(htype,                             \
                                       hndl,                              \
                                       CLIrc,                             \
                                       henv,                              \
                                       hdbc,                              \
                                       outReturnCode,                     \
                                       outErrorMsg,                       \
                                       inMsg)                             \
if (CLIrc == SQL_INVALID_HANDLE)                                          \
{                                                                         \
  *outReturnCode =  0;                                                    \
  strcpy(outErrorMsg, inMsg);                                             \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}                                                                         \
if (CLIrc == SQL_ERROR)                                                   \
{                                                                         \
  *outReturnCode =  -1;                                                   \
  strcat(outErrorMsg, inMsg);                                             \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}

#define                                                                   \
SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(htype,                             \
                                       hndl,                              \
                                       CLIrc,                             \
                                       henv,                              \
                                       hdbc,                              \
                                       sqlstate,                          \
                                       outMsg,                            \
                                       inMsg)                             \
if (CLIrc == SQL_INVALID_HANDLE)                                          \
{                                                                         \
  memset(sqlstate, '0', 6);                                               \
  strcpy(outMsg, inMsg);                                                  \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}                                                                         \
if (CLIrc != 0 && CLIrc != SQL_NO_DATA_FOUND )                            \
{                                                                         \
  SetErrorMsg(htype, hndl, henv, hdbc, outMsg, inMsg);                    \
  StpCleanUp(henv, hdbc);                                                 \
  return (0);                                                             \
}

void StpCleanUp(SQLHANDLE henv, SQLHANDLE hdbc)
{
  /* disconnect from a data source */
  SQLDisconnect(hdbc);

  /* free the database handle */
  SQLFreeHandle(SQL_HANDLE_DBC, hdbc);

  /* free the environment handle */
  SQLFreeHandle(SQL_HANDLE_ENV, henv);
}

void SetErrorMsg(SQLSMALLINT htype,
                    SQLHANDLE hndl,
                    SQLHANDLE henv,
                    SQLHANDLE hdbc,
                    char *outMsg,
                    char *inMsg)
{
  SQLCHAR message[SQL_MAX_MESSAGE_LENGTH + 1];
  SQLCHAR sqlstate[SQL_SQLSTATE_SIZE + 1];
  SQLINTEGER sqlcode;
  SQLSMALLINT length;
  SQLGetDiagRec(htype,
                hndl,
                1,
                sqlstate,
                &sqlcode,
                message,
                SQL_MAX_MESSAGE_LENGTH + 1,
                &length);
  sprintf(outMsg, "%ld: ", sqlcode);
  strcat(outMsg, inMsg);
}

/**************************************************************************
**  Stored procedure: xquery_proc
**
**  Scenario: 
**         Some of the suppliers have extended the promotional price date for
**         their products. Getting all the customer's Information who purchased
**         these products in the extended period will help the financial department
**         to return the excess amount paid by those customers. The supplier
**         information along with extended date's for the products is provided
**         in an XML document and the customer wants to have the information
**         of all the customers who has paid the excess amount by purchasing those
**         products in the extended period.
**
**         This procedure will return an XML document containing customer info
**         along with the the excess amount paid by them.
**
**            Shows how to:
**             - define XML type parameters in a Stored Procedure
**
**   Parameters:
**
**   IN:      inXML - Products information with extended promodate as 
**                    an XML document 
**   OUT:     outXML - Customers information with excess amount to be paid
**                     to them as an XML document
**
**            When the PARAMETER STYLE SQL clause is specified
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script xquery_xmlproc_create.db2), in addition to the
**            parameters passed at procedure invocation time, the
**            following parameters are passed to the routine
**            in the following order:
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**            See the actual parameter declarations below to see
**            the recommended datatypes and sizes for them.
**
**            CODE TIP:
**            --------
**            As an alternative to coding the non-functional parameters
**            required with parameter style SQL (sqlstate, routine-name,
**            specific-name, diagnostic-message), you can use a macro:
**            SQLUDF_TRAIL_ARGS. This macro is defined in DB2 include
**            file sqludf.h
**
**************************************************************************/

SQL_API_RC SQL_API_FN xquery_proc  (  SQLUDF_CLOB* inXML,
                                      SQLUDF_CLOB* outXML,
                                      sqlint16 *inXML_ind,
                                      sqlint16 *outXML_ind,
                                      char sqlstate[6],
                                      char qualName[28],
                                      char specName[19],
                                      char diagMsg[71])
{
  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt,hstmt1,hstmt2,hstmt3,hstmt4,hstmt5;
  SQLRETURN cliRC;
  SQLCHAR stmt1[1000],stmt2[1000],stmt3[1000],stmt4[1000];
  SQLCHAR stmt5[1000],stmt6[1000],stmt7[1000],stmt8[1000];
  SQLCHAR prodid[12],partid[12];
  SQLREAL originalPrice,promoPrice,excessamount;
  SQLCHAR oldPromoDate[11],newPromoDate[11];
  SQLBIGINT custid;
  SQLINTEGER quantity;

  /* Initialize output parameters to NULL*/
  memset(outXML->data,'\0',5000);
  *outXML_ind=-1;

  /* Initialize the application variables */
  originalPrice=0;
  promoPrice =0;
  excessamount =0;
  custid=0;
  quantity=0;
  memset(partid, '\0', 12);
  memset(prodid, '\0', 12);
  memset(oldPromoDate, '\0', 11);
  memset(newPromoDate, '\0', 11);

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK(SQL_HANDLE_ENV, henv, cliRC, henv, hdbc);

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK(SQL_HANDLE_ENV, henv, cliRC, henv, hdbc);

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle for hstmt */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle for hstmt1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle for hstmt3 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle for hstmt4 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt4);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle for hstmt5 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt5);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* create the table temp_table1 for storing intermediate results */
  strcpy((char *)stmt1,"CREATE TABLE temp_table1(custid INT,partid VARCHAR(12),"
                                                 "excessamount DECIMAL(5,2))");
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "CREATE statement(temp_table1) failed.");

  /* create the table temp_table2 */  
  strcpy((char *)stmt2,"CREATE TABLE temp_table2(cid INT,total DECIMAL(5,2))");
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "CREATE statement(temp_table2) failed.");
  /* an XQUERY statement to restructure all the PurchaseOrders
     into the following form
     <items>
       <item OrderDate="YYYY-MM-DD">
         <custid>XXXX</custid>
         <partid>XXX-XXX-XX</partid>
         <quantity>XX</quantity>
       </item>................<item>...............</item>
       <item>.................</itemm
     </items>
     store the above XML document in an application variable "orders" */
  sprintf((char *) stmt3,"XQUERY let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"porders\"\","
                   "( XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", p.custid), p.porder))) "
                   "FROM PURCHASEORDER as p\") return <items>{for $i in $po for $j in "
                   "$po[custid=$i/custid]/PurchaseOrder[@PoNum=$i/PurchaseOrder/@PoNum]/item "
                   "return <item>{$i/PurchaseOrder/@OrderDate}{$i/custid}{$j/partid}"
                   "{$j/quantity}</item>}</items>");
  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt3, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "Prepare statement failed.");

    /* execute the statement */
   cliRC = SQLExecute(hstmt);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "XQUERY statement failed.");
   /* bind column to a variable*/
   cliRC = SQLBindCol(hstmt,
                      1,
                      SQL_C_CHAR,
                      &(outXML->data),
                      5000,
                      (SQLINTEGER*)&(outXML->length));
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);
   /* fetch the data */
   cliRC = SQLFetch(hstmt);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   /* select the oldpromodate, newpromodate, price and promoprice
      for the products for which the promodate is extended
      using input XML document */
   strcpy((char *)stmt4, "SELECT Pid,PromoEnd,Price,PromoPrice,XMLCAST(XMLQUERY("
                   "'$info/Suppliers/Supplier/Products/Product[@id=$pid]/ExtendedDate' "
                   "passing cast(? as XML) as \"info\",  pid as \"pid\") as DATE) FROM "
                   "product WHERE XMLEXISTS('for $prod in $info//Product[@id=$pid] return"
                   " $prod' passing by ref cast(? as XML) as \"info\", pid as \"pid\")");
   /* prepare the statement */
   cliRC = SQLPrepare(hstmt1, stmt4, SQL_NTS);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "Prepare statement failed.");
   cliRC = SQLBindParameter(hstmt1,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_CHAR,
                               SQL_XML,
                               5000,
                               0,
                               &(inXML->data),
                               inXML->length,
                               (SQLINTEGER *)&(inXML->length));
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt1,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter1");
   cliRC = SQLBindParameter(hstmt1,
                               2,
                               SQL_PARAM_INPUT,
                               SQL_C_CHAR,
                               SQL_XML,
                               5000,
                               0,
                               &(inXML->data),
                               inXML->length,
                               (SQLINTEGER *)&(inXML->length));
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt1,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter2");
   /* execute the statement */
   cliRC = SQLExecute(hstmt1);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt1,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
   cliRC = SQLBindCol(hstmt1, 1, SQL_C_CHAR, prodid, 12, NULL);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindCol");
   cliRC = SQLBindCol(hstmt1, 2, SQL_C_CHAR, oldPromoDate, 11, NULL);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindCol");
   cliRC = SQLBindCol(hstmt1, 3, SQL_C_FLOAT, &originalPrice, 0, NULL);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindCol");
   cliRC = SQLBindCol(hstmt1, 4, SQL_C_FLOAT, &promoPrice , 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindCol");
   cliRC = SQLBindCol(hstmt1, 5, SQL_C_CHAR, newPromoDate, 11, NULL);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindCol");
   /* fetch a row */
   cliRC = SQLFetch(hstmt1);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt1, cliRC, henv, hdbc);
   while (cliRC != SQL_NO_DATA_FOUND)
   {
       /* finding out the toatal quantity of the product purchased by a customer
          if that order is made in between oldpromodate and extended promodate.
          this query will return the custid, product id and total quantity of
          that product purchased in all his orders. */

       strcpy( (char *)stmt5,"WITH temp1 AS (SELECT cid,partid,quantity,orderdate "
               "FROM XMLTABLE('$od//item' passing cast(? as XML) as \"od\" COLUMNS cid BIGINT path "
               "'./custid', partid VARCHAR(20) path './partid', orderdate DATE path"
               "'./@OrderDate',quantity BIGINT path './quantity') as temp2) "
               "SELECT  temp1.cid, temp1.partid, sum(temp1.quantity) as quantity "
               "FROM temp1 WHERE partid=? and orderdate>cast(? as DATE) and orderdate<cast(? "
               "as DATE) group by temp1.cid,temp1.partid");
       cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
       SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);
       /* prepare the statement */
       cliRC = SQLPrepare(hstmt2, stmt5, SQL_NTS);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "Prepare statement failed.");
       /* bind the parameter to the statement */
       cliRC = SQLBindParameter(hstmt2,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_CHAR,
                               SQL_XML,
                               5000,
                               0,
                               &(outXML->data),
                               outXML->length,
                               (SQLINTEGER *)&(outXML->length));
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindParameter1");
       cliRC = SQLBindParameter(hstmt2, 2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           12,
                           0,
                           prodid,
                           12,
                           NULL);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindParameter2");
       cliRC = SQLBindParameter(hstmt2, 3,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           11,
                           0,
                           oldPromoDate,
                           11,
                           NULL);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindParameter3");
       cliRC = SQLBindParameter(hstmt2,4,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           11,
                           0,
                           newPromoDate,
                           11,
                           NULL);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindParameter4");
       /* execute the statement */
       cliRC = SQLExecute(hstmt2);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt2,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
       /* bind columns */
       cliRC = SQLBindCol(hstmt2, 1, SQL_C_SBIGINT, &custid, 0, NULL);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);
       cliRC = SQLBindCol(hstmt2, 2, SQL_C_CHAR, partid, 12, NULL);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);
       cliRC = SQLBindCol(hstmt2, 3, SQL_C_LONG, &quantity, 0, NULL);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);
       /* fetch a row */
       cliRC = SQLFetch(hstmt2);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);

       while (cliRC != SQL_NO_DATA_FOUND)
       {
           excessamount = ((originalPrice - promoPrice)*quantity);
           strcpy((char *)stmt6, "INSERT INTO temp_table1(custid,partid,excessamount) "
                                                                      "values(?,?,?)");
           /* prepare the statement */
           cliRC = SQLPrepare(hstmt3, stmt6, SQL_NTS);
           SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                              hstmt3,
                                              cliRC,
                                              henv,
                                              hdbc,
                                              sqlstate,
                                              diagMsg,
                                              "INSERT statement failed.");
           /* bind the parameter to the statement */
           cliRC = SQLBindParameter(hstmt3,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_SBIGINT,
                               SQL_BIGINT,
                               0,
                               0,
                               &custid,
                               0,
                               NULL);
           SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt3,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter");
           cliRC = SQLBindParameter(hstmt3, 2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           12,
                           0,
                           partid,
                           12,
                           NULL);
           SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt3,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindParameter");
           cliRC = SQLBindParameter(hstmt3,
                               3 ,
                               SQL_PARAM_INPUT,
                               SQL_C_FLOAT,
                               SQL_REAL,
                               0,
                               0,
                               &excessamount,
                               0,
                               NULL);
           SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt3,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter");
           cliRC = SQLExecute(hstmt3);
           SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt3,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "INSERT statement failed.");
           cliRC = SQLFetch(hstmt2);
           SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);
       }
       cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

       cliRC = SQLFetch(hstmt1);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);
   }
   strcpy((char *)stmt7, "INSERT INTO temp_table2( SELECT custid, sum(excessamount) "
                         "FROM temp_table1 GROUP BY custid)");
   cliRC = SQLPrepare(hstmt4, stmt7, SQL_NTS);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                              hstmt4,
                                              cliRC,
                                              henv,
                                              hdbc,
                                              sqlstate,
                                              diagMsg,
                                              "INSERT statement failed.");
   cliRC = SQLExecute(hstmt4);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt4,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "INSERT statement failed.");
 
  /* format the results into an XML document of the following form
     <Customers>
        <Customer>
            <Custid>XXXX</Custid>
            <Total>XXXX.XXXX</Total>
            <customerinfo Cid="xxxx">
                 <name>xxxx xxx</name>
                 <addr country="xxx>........
                 </addr>
                 <phone type="xxxx">.........
                 </phone>
            </customerinfo>
        </Customer>............
     </Customers> */
   strcpy((char *)stmt8,"XQUERY let $res:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME "
                    "\"\"Customer\"\",( XMLCONCAT(XMLELEMENT(NAME \"\"Custid\"\", t.cid),"
                    "XMLELEMENT( NAME \"\"Total\"\", t.total),c.info))) "
                    "FROM temp_table2 AS t,customer AS c WHERE t.cid = c.cid\") "
                    "return <Customers>{$res}</Customers>");
   cliRC = SQLPrepare(hstmt5, stmt8, SQL_NTS);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt5,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "Prepare statement failed.");
    /* execute the statement */
    cliRC = SQLExecute(hstmt5);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt5,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
    cliRC = SQLBindCol(hstmt5,
                      1,
                      SQL_C_CHAR,
                      &(outXML->data),
                      5000,
                      (SQLINTEGER*)&(outXML->length));
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt5, cliRC, henv, hdbc);

   /* fetch a row */
   cliRC = SQLFetch(hstmt5);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt5, cliRC, henv, hdbc);

   *outXML_ind=-0;

   /* drop the temporary tables */
   strcpy((char *)stmt1,"DROP TABLE temp_table1");
   cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "DROP statement failed.");

  /* create the table temp_table2 */
  strcpy((char *)stmt2,"DROP TABLE temp_table2");
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "DROP statement failed.");

   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt4);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt5);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   /* disconnect from the data source */
   cliRC = SQLDisconnect(hdbc);
   SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

   /* free the database handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
   SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

   /* free the environment handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
   SRV_HANDLE_CHECK(SQL_HANDLE_ENV, henv, cliRC, henv, hdbc);

  return (0);
} /* end of the procedure */
