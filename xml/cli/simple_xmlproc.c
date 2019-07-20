/*************************************************************************
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
***************************************************************************
**
** SOURCE FILE NAME: simple_xmlproc.c
**
** SAMPLE: Code implementation of a stored procedure Simple_XML_Proc_CLI
**
**         The stored procedures defined in this program is called by the client
**         application simple_xmlproc_client.c. Before building and running
**         simple_xmlproc_client.c, build the shared library by completing the
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
** 2. To build the shared library, enter "bldrtn simple_xmlproc", or use the
**    makefile: "make simple_xmlproc" (UNIX) or "nmake simple_xmlproc" (Windows).
**
** CATALOGING THE STORED PROCEDURES
** 1. The stored procedures are cataloged automatically when you build
**    the client application "simple_xmlproc_client" using the appropriate "make"
**    utility for your Operating System and the "makefile" provided with these
**    samples. If you wish to catalog or recatalog them manually, enter
**    "spcat_xml". The spcat_xml script (UNIX) or spcat_xml.bat batch file (Windows)
**    connects to the database, runs simple_xmlproc_drop.db2 to uncatalog the stored
**    procedures if they were previously cataloged, then runs simple_xmlproc_create.db2
**    which catalogs the stored procedures, then disconnects from the database.
**
** CALLING THE STORED PROCEDURES IN THE SHARED LIBRARY:
** 1. Compile the simple_xmlproc_client program with "bldapp simple_xmlproc_client" or use the
**    makefile: "make simple_xmlproc_client" (UNIX) or "nmake simple_xmlproc_client" (Windows).
** 2. Run simple_xmlproc_client: "simple_xmlproc_client" (if calling remotely add the parameters
**    for database, user ID and password.)
**
** DESCRIPTION OF FUNCTION SIMPLE_PROC:
**           This function will take Customer Information ( of type XML)  as input ,
**           finds whether the customer with Cid in Customer Information exists in the
**           customer table or not, if not this will insert the customer information
**           into the customer table with same Customer id, and returns all the customers 
**           from the same city of the input customer information in XML format to the caller 
**           along with location as an output parameter in XML format.
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
If (CLIrc == SQL_INVALID_HANDLE)                                          \
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
**  Stored procedure: simple_proc
**
**  Purpose:
**           This sample will take Customer Information ( of type XML)  as input ,
**           finds whether the customer with Cid in Customer Information exists in the
**           customer table or not, if not this will insert the customer information
**           into the customer table with same Customer id, and returns all the customers
**           from the same city of the input customer information in XML format to the caller
**           along with location as an output parameter in XML format.
**
**  Shows how to:
**             - define XML type parameters in a Stored Procedure
**             - return a result set to the client
**
**   Parameters:
**
**   IN:      inXML - Customer information an XML document
**   OUT:     outXML - Location of input customer as an XML document
**            Returns Customers from that city to caller.
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

SQL_API_RC SQL_API_FN simple_proc ( SQLUDF_CLOB* inXML,
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
  SQLCHAR stmt[1024],stmt1[1024],stmt2[1024],stmt3[1024],stmt4[1024],stmt5[1024];
  SQLINTEGER custid,quantity,count;
  char city[100];

  /* Initialize output parameters to NULL*/
  memset(outXML->data,'\0',5000);
  *outXML_ind=-1;
 
  /* intilize the application variables */
  quantity=0;
  count=0;
  custid=0;

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

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt4);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);
 
  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt5);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  /* find whether the customer with that Info exists in the customer table */
  strcpy((char *)stmt,"SELECT COUNT(*) FROM customer WHERE "
                      "XMLEXISTS('$info/customerinfo[@Cid=$id]' "
                      "PASSING by ref cast(? as XML)  AS \"info\", cid as \"id\")");
  
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SELECT statement stmt failed.");
  /* bind the input XML document */
  cliRC = SQLBindParameter(hstmt,
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
                                             hstmt,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter1");

   /* execute the statement */
   cliRC = SQLExecute(hstmt);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
 
   /* bind the column to an application variable */   
   cliRC = SQLBindCol(hstmt,
                      1,
                      SQL_C_LONG,
                      &count,
                      0,
                      NULL);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);
   /* fetch a row */
   cliRC = SQLFetch(hstmt);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

   /* if customer doesn't exist ...... insert into the table */
   if(count < 1 )
   {
      /* get the custid from the customer information */
      strcpy((char *)stmt1,"SELECT XMLCAST( XMLQUERY('$info/customerinfo/@Cid' "
	                   "passing by ref cast(? as XML) as \"info\") as "
		           "BIGINT) FROM SYSIBM.SYSDUMMY1");
      cliRC = SQLPrepare(hstmt1, stmt1, SQL_NTS);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SELECT statement stmt failed.");
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

      cliRC = SQLExecute(hstmt1);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt1,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
       /* get customer id into custid */
       cliRC = SQLBindCol(hstmt1,
                      1,
                      SQL_C_LONG,
                      &custid,
                      0,
                      NULL);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt1, cliRC, henv, hdbc);
       /* fetch a row */
       cliRC = SQLFetch(hstmt1);
       SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt1, cliRC, henv, hdbc);
 
       /* insert into customer table with that custid */
       strcpy((char *)stmt2,"INSERT INTO customer(Cid, Info) VALUES (?,?)");
       cliRC = SQLPrepare(hstmt2, stmt2, SQL_NTS);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SELECT statement stmt failed.");
       /* bind the parameter to the statement */
       cliRC = SQLBindParameter(hstmt2,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           &custid,
                           0,
                           NULL);
       SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SQLBindParameter1");
       cliRC = SQLBindParameter(hstmt2,
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
                                             hstmt2,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter1");

       cliRC = SQLExecute(hstmt2);
       SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt2,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
    } 
    /* find the city of the customer and assign it to an application variable */
    strcpy((char *)stmt3,"SELECT XMLCAST( XMLQUERY('$info/customerinfo//city' "
                         "passing by ref cast(? as XML) as \"info\") as "
                         "VARCHAR(100)) FROM SYSIBM.SYSDUMMY1");
    cliRC = SQLPrepare(hstmt3, stmt3, SQL_NTS);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt3,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SELECT statement stmt failed.");
    cliRC = SQLBindParameter(hstmt3,
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
                                             hstmt3,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter1");

    cliRC = SQLExecute(hstmt3);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt3,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "SELECT statement failed.");
    /* bind a column to an application variable */
    cliRC = SQLBindCol(hstmt3, 1, SQL_C_CHAR, city, 100, NULL);
    SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt3, cliRC, henv, hdbc);

    /* fetch each row */
    cliRC = SQLFetch(hstmt3);
    SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt3, cliRC, henv, hdbc);

    /* Location of the input information as XML output */
    strcpy((char *)stmt4,"SELECT XMLQUERY('let $city:=$info/customerinfo//city "
                         "let $prov:=$info/customerinfo//prov-state return <Location> "
                         "{$city}{$prov} </Location>' passing by ref cast(? as XML) as "
                         "\"info\") FROM SYSIBM.SYSDUMMY1");
    cliRC = SQLPrepare(hstmt4, stmt4, SQL_NTS);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt4,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "statement stmt4 failed.");
    cliRC = SQLBindParameter(hstmt4,
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
                                             hstmt4,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqlstate,
                                             diagMsg,
                                             "SQLBindParameter1");

    cliRC = SQLExecute(hstmt4);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                          hstmt4,
                                          cliRC,
                                          henv,
                                          hdbc,
                                          sqlstate,
                                          diagMsg,
                                          "EXECUTE statement failed.");
    /* bind a column to an application variable */
    cliRC = SQLBindCol(hstmt4,
                      1,
                      SQL_C_CHAR,
                      &(outXML->data),
                      5000,
                      (SQLINTEGER*)&(outXML->length));
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt4, cliRC, henv, hdbc);

   /* fetch a row */
   cliRC = SQLFetch(hstmt4);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt4, cliRC, henv, hdbc);

   *outXML_ind = 0;

   /* findout all he customers from that city and return as an XML to caller */
   strcpy((char *)stmt5,"XQUERY for $cust in db2-fn:xmlcolumn"
                        "(\"CUSTOMER.INFO\")/customerinfo/addr[city=\"");
   strcat((char *)stmt5, city);
   strcat((char *)stmt5, "\"] order by xs:double($cust/../@Cid) return <Customer>{$cust/../@Cid}{$cust/../name}</Customer>");

   cliRC = SQLPrepare(hstmt5, stmt5, SQL_NTS);
   SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt5,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "XQUERY statement failed.");
    cliRC = SQLExecute(hstmt5);
    SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt5, cliRC, henv, hdbc); 
 
   /* free the handles */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt1, cliRC, henv, hdbc);
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt2, cliRC, henv, hdbc);
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt3, cliRC, henv, hdbc);
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt4);
   SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt4, cliRC, henv, hdbc);

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
}
