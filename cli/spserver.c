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
** SOURCE FILE NAME: spserver.c
**
** SAMPLE: Code implementations of various types of stored procedures
**
**         The stored procedures defined in this program are called by the
**         client application spclient.c. Before building and running
**         spclient.c, build the shared library by completing the following
**         steps:
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
** 2. To build the shared library, enter "bldrtn spserver", or use the 
**    makefile: "make spserver" (UNIX) or "nmake spserver" (Windows).
**
** CATALOGING THE STORED PROCEDURES
** 1. The stored procedures are cataloged automatically when you build
**    the client application "spclient" using the appropriate "make" utility
**    for your Operating System and the "makefile" provided with these 
**    samples. If you wish to catalog or recatalog them manually, enter 
**    "spcat". The spcat script (UNIX) or spcat.bat batch file (Windows) 
**    connects to the database, runs spdrop.db2 to uncatalog the stored 
**    procedures if they were previously cataloged, then runs spcreate.db2 
**    which catalogs the stored procedures, then disconnects from the 
**    database.
**
** CALLING THE STORED PROCEDURES IN THE SHARED LIBRARY:
** 1. Compile the spclient program with "bldapp spclient" or use the 
**    makefile: "make spclient" (UNIX) or "nmake spclient" (Windows).
** 2. Run spclient: "spclient" (if calling remotely add the parameters for
**    database, user ID and password.)
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
**         SQLGetCursorName -- Get Cursor Name
**         SQLGetLength -- Retrieve Length of a String Value
**         SQLGetPosition -- Return Starting Position of String
**         SQLGetSubString -- Retrieve Portion of a String Value
**         SQLPrepare -- Prepare a Statement
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetParam -- Bind a Parameter Marker to a Buffer or LOB locator
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

/* declare function prototypes for this stored procedure library */

SQL_API_RC SQL_API_FN outlanguage(char *, 
                                  sqlint16 *, 
                                  SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN out_param(double *, 
                                sqlint16 *,
                                SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN in_params(double *, 
                                double *,
                                double *,
                                char *,
                                sqlint16 *,
                                sqlint16 *,
                                sqlint16 *, 
                                sqlint16 *,
                                SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN inout_param(double *inoutMedian, 
                                  sqlint16 *, 
                                  SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN extract_from_clob(char *, 
                                        char *, 
                                        sqlint16 *, 
                                        sqlint16 *,
                                        SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN dbinfo_example(char *, 
                                     double *, 
                                     char *, 
                                     char *,
                                     sqlint16 *, 
                                     sqlint16 *, 
                                     sqlint16 *,
                                     sqlint16 *, 
                                     SQLUDF_TRAIL_ARGS,
                                     struct sqludf_dbinfo *);
SQL_API_RC SQL_API_FN main_example(int, 
                                   char **);
SQL_API_RC SQL_API_FN all_data_types(sqlint16 *, 
                                     sqlint32 *,
                                     sqlint64 *,
                                     float *,
                                     double *, 
                                     char *, 
                                     char *,
                                     char *, 
                                     char *, 
                                     char *, 
                                     sqlint16 *,
                                     sqlint16 *, 
                                     sqlint16 *, 
                                     sqlint16 *,
                                     sqlint16 *,
                                     sqlint16 *, 
                                     sqlint16 *,
                                     sqlint16 *, 
                                     sqlint16 *, 
                                     sqlint16 *,
                                     SQLUDF_TRAIL_ARGS );
SQL_API_RC SQL_API_FN one_result_set_to_caller(double *,
                                               sqlint16 *, 
                                               SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN two_result_sets(double *,
                                      sqlint16 *, 
                                      SQLUDF_TRAIL_ARGS);
SQL_API_RC SQL_API_FN general_example(sqlint32 *, 
                                      sqlint32 *,
                                      char *);
SQL_API_RC SQL_API_FN general_with_nulls_example(sqlint32 *, 
                                                 sqlint32 *, 
                                                 char *, 
                                                 sqlint16 *);

/*  a description of each stored procedure and its parameters is 
     provided with the code body of each routine in this file 
     (see below) 
     Note: Pointer variables start with 'p' as a naming convention */ 

/**************************************************************************
**  Stored procedure:  outlanguage                                         
**                                                                          
**  Purpose:  Returns the code implementation language of                  
**            stored procedure 'outlanguage' (as it appears in the
**            database catalog) in an output parameter.
**
**            Shows how to:
**             - define an OUT parameter in PARAMETER STYLE SQL
**             - define a NULL indicator for the parameter
**             - execute an SQL statement
**             - how to set a Null indicator when parameter is
**               not null
**
**   Parameters:
**
**   IN:      (none)
**   OUT:     outLanguage - the code language of this routine
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**   
**              SQL_API_RC SQL_API_FN outlanguage(
**                                      char outLanguage[9],
**                                      sqlint16 *poutLanguageNullInd,
**                                      SQLUDF_TRAIL_ARGS)
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
**************************************************************************/

SQL_API_RC SQL_API_FN outlanguage(char outLanguage[9], /* CHAR(8) */
                                  sqlint16 *poutLanguageNullInd,
                                  SQLUDF_TRAIL_ARGS )
{
  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt;
  SQLRETURN cliRC;
  SQLCHAR stmt[100];

  /* initialize strings used for output parameters to NULL */
  memset(outLanguage, '\0', 9);
  *poutLanguageNullInd = -1;

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

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

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK(SQL_HANDLE_DBC, hdbc, cliRC, henv, hdbc);

  strcpy((char *)stmt, "SELECT LANGUAGE FROM sysibm.sysprocedures ");
  strcat((char *)stmt, "WHERE procname = 'OUT_LANGUAGE' ");

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, outLanguage, 9, NULL);
  SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

  /* fetch each row */
  cliRC = SQLFetch(hstmt);
  SRV_HANDLE_CHECK(SQL_HANDLE_STMT, hstmt, cliRC, henv, hdbc);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
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

  /* set NULL indicator for parameter 'outLanguage' to 0 to
     indicate that output parameter 'outLanguage' is not NULL
     When the value to be returned is intended to be a NULL,
     set the null indicator for that parameter to -1  */
  *poutLanguageNullInd = 0;

  return (0);
} /* end outlanguage function */

/*************************************************************************
**  Stored procedure:  out_param
**
**  Purpose:  Sorts table STAFF by salary, locates and returns
**            the median salary
**
**            Shows how to:
**             - define OUT parameters in PARAMETER STYLE SQL
**             - execute SQL to declare and work with a cursor
**             - how to set a Null indicator when parameter is
**               not null
**             - define the extra parameters associated with
**               PARAMETER STYLE SQL 
**
**  Parameters:
**
**   IN:      (none)
**   OUT:     poutMedianSalary - median salary in table STAFF
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**    
**              SQL_API_RC SQL_API_FN out_param(
**                                      double *poutMedianSalary, 
**                                      sqlint16 *poutMedianSalaryNullInd,
**                                      SQLUDF_TRAIL_ARGS)
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN out_param(double *poutMedianSalary, 
                                sqlint16 *poutMedianSalaryNullInd,
                                SQLUDF_TRAIL_ARGS)
{
  SQLHANDLE henv, hdbc = 0, hstmt1, hstmt2;
  SQLRETURN cliRC;
  SQLCHAR stmt1[100] = {0}; 
  SQLCHAR stmt2[100] = {0}; 

  sqlint16 numRecords;
  double medianSalary;
  int counter;

  /* initialize output parameter */
  *poutMedianSalary = 0;
  *poutMedianSalaryNullInd = -1;

  counter = 0;
  
  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLSetConnectAttr");

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLConnect");

  /* allocate statement handle 1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 2 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  strcpy((char *)stmt1, "SELECT count(*) FROM staff ");

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt1, stmt1, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");

  strcpy((char *)stmt2, "SELECT CAST(salary AS DOUBLE) FROM staff ");
  strcat((char *)stmt2, "order by salary");

  /* directly execute a statement */
  cliRC = SQLExecDirect(hstmt2, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt2 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt1, 1, SQL_C_SHORT, &numRecords, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_DOUBLE, &medianSalary, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* fetch number of rows in "staff" table */
  cliRC = SQLFetch(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");

  for (counter = 0; counter < (numRecords / 2 + 1); counter++)
  {
    /* fetch next row */
    cliRC = SQLFetch(hstmt2);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                           hstmt2,
                                           cliRC,
                                           henv,
                                           hdbc,
                                           sqludf_sqlstate,
                                           sqludf_msgtext,
                                           "SQLFetch");
  }

  /* set value of OUT parameter to the variable */
  *poutMedianSalary = medianSalary;
  *poutMedianSalaryNullInd = 0;

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLDisconnect");

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");
  return (0);
} /* end out_param function */

/**************************************************************************
**  Stored procedure:  in_params
**
**  Purpose:  Updates salaries of employees in department indepartment
**            using inputs pinLowSal, pinMedSal, pinHighSal as
**            salary raise or adjustment values.
**
**            Shows how to:
**             - define IN parameters using PARAMETER STYLE SQL
**             - define and use NULL indicators for parameters
**             - define the extra parameters associated with
**               PARAMETER STYLE SQL
**
**  Parameters:
**
**   IN:      pinLowSal     - new salary for low salary employees
**            pinMedSal     - new salary for mid salary employees
**            pinHighSal    - new salary for high salary employees
**            inDepartment - department to use in SELECT predicate
**   OUT:     (none)
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**    
**              SQL_API_RC SQL_API_FN in_params(
**                                      double *pinLowSal,
**                                      double *pinMedSal,
**                                      double *pinHighSal,
**                                      char inDepartment[4],
**                                      sqlint16 *pinLowSalNullInd,
**                                      sqlint16 *pinMedSalNullInd,
**                                      sqlint16 *pinHighSalNullInd,
**                                      sqlint16 *pinDeptNullInd,
**                                      SQLUDF_TRAIL_ARGS)
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN  in_params(double *pinLowSal,
                                 double *pinMedSal,
                                 double *pinHighSal,
                                 char inDepartment[4], /* CHAR(3) */
                                 sqlint16 *pinLowSalNullInd,
                                 sqlint16 *pinMedSalNullInd,
                                 sqlint16 *pinHighSalNullInd,
                                 sqlint16 *pinDepartmentNullInd,
                                 SQLUDF_TRAIL_ARGS )
{
  SQLHANDLE henv, hdbc = 0, hstmt1, hstmt2;
  SQLRETURN cliRC;
  SQLCHAR stmt1[100] = {0}; 
  SQLCHAR stmt2[100] = {0}; 
  double lowSal;
  double medSal;
  double highSal;
  double salary;
  double tmp;
  SQLCHAR cursorName[129] = {0}; 
  SQLSMALLINT cursorNameLen;

  lowSal = *pinLowSal;
  medSal = *pinMedSal;
  highSal = *pinHighSal;

  if ((*pinLowSalNullInd) < 0 || 
      (*pinMedSalNullInd) < 0 ||  
      (*pinHighSalNullInd) < 0 ||
      (*pinDepartmentNullInd) < 0)
  {
    /* set custom SQLSTATE to return to client. */
    strcpy(sqludf_sqlstate, "38100");

    /* set custom message to return to client.
       Keep the custom message short to avoid truncation. */
    strcpy(sqludf_msgtext, "Received null input");
    return (0);
  }

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                              */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLSetConnectAttr");

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLConnect");

  /* allocate statement handle 1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 2 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  strcpy((char *)stmt1, "SELECT CAST(salary AS DOUBLE) FROM employee ");
  strcat((char *)stmt1, "WHERE workdept = ? FOR UPDATE OF salary");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt1, stmt1, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt1, 1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           4,
                           0,
                           inDepartment,
                           4,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindParameter");

  /* execute the statement */
  cliRC = SQLExecute(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt1, 1, SQL_C_DOUBLE, &salary, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* get the cursor of the SELECT statement's handle */
  cliRC = SQLGetCursorName(hstmt1, cursorName, sizeof( cursorName ), &cursorNameLen);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLGetCursorName");

  sprintf((char *)stmt2, 
   "UPDATE employee SET salary = ?  WHERE CURRENT OF %s ", cursorName);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt2, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "UPDATE  statement stmt2 failed.");

  /* fetch first row */
  cliRC = SQLFetch(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    /* set custom SQLSTATE and Message to return to client.  */
    strcpy(sqludf_sqlstate, "38200");
    strcpy(sqludf_msgtext, " 100: No Data Found");

    /* free resources before returning */
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
    StpCleanUp(henv, hdbc);
    return (0);
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    if (salary < lowSal)
    {
      /* bind the parameter to the statement */
      cliRC = SQLBindParameter(hstmt2,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_DOUBLE,
                               SQL_DOUBLE,
                               0,
                               0,
                               &lowSal,
                               0,
                               NULL);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt2,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqludf_sqlstate,
                                             sqludf_msgtext,
                                             "SQLBindParameter");

      /* execute the statement */
      cliRC = SQLExecute(hstmt2);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(
        SQL_HANDLE_STMT,
        hstmt2,
        cliRC,
        henv,
        hdbc,
        sqludf_sqlstate,
        sqludf_msgtext,
        "UPDATE statement stmt2 failed.");
    }
    else if (salary < medSal)
    {
      /* bind the parameter to the statement */
      cliRC = SQLBindParameter(hstmt2,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_DOUBLE,
                               SQL_DOUBLE,
                               0,
                               0,
                               &medSal,
                               0,
                               NULL);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt2,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqludf_sqlstate,
                                             sqludf_msgtext,
                                             "SQLBindParameter");
      /* execute the statement */
      cliRC = SQLExecute(hstmt2);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(
        SQL_HANDLE_STMT,
        hstmt2,
        cliRC,
        henv,
        hdbc,
        sqludf_sqlstate,
        sqludf_msgtext,
        "UPDATE statement stmt2 failed.");
    }
    else if (salary < highSal)
    {
      /* bind the parameter to the statement */
      cliRC = SQLBindParameter(hstmt2,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_DOUBLE,
                               SQL_DOUBLE,
                               0,
                               0,
                               &highSal,
                               0,
                               NULL);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt2,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqludf_sqlstate,
                                             sqludf_msgtext,
                                             "SQLBindParameter");

      /* execute the statement */
      cliRC = SQLExecute(hstmt2);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(
        SQL_HANDLE_STMT,
        hstmt2,
        cliRC,
        henv,
        hdbc,
        sqludf_sqlstate,
        sqludf_msgtext,
        "UPDATE statement stmt2 failed.");
    }
    else
    {
      tmp = salary * 1.1;

      /* bind the parameter to the statement */
      cliRC = SQLBindParameter(hstmt2,
                               1,
                               SQL_PARAM_INPUT,
                               SQL_C_DOUBLE,
                               SQL_DOUBLE,
                               0,
                               0,
                               &tmp,
                               0,
                               NULL);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                             hstmt2,
                                             cliRC,
                                             henv,
                                             hdbc,
                                             sqludf_sqlstate,
                                             sqludf_msgtext,
                                             "SQLBindParameter");
      /* execute the statement */
      cliRC = SQLExecute(hstmt2);
      SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(
         SQL_HANDLE_STMT,
         hstmt2,
         cliRC,
         henv,
         hdbc,
         sqludf_sqlstate,
         sqludf_msgtext,
         "UPDATE statement stmt2 failed.");
    }

    /* fetch next row */
    cliRC = SQLFetch(hstmt1);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                           hstmt1,
                                           cliRC,
                                           henv,
                                           hdbc,
                                           sqludf_sqlstate,
                                           sqludf_msgtext,
                                           "SQLFetch");
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLDisconnect");

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  return (0);
} /* end in_params function */

/**************************************************************************
**  Stored procedure:  inout_param
**
**  Purpose:  Calculates the median salary of all salaries above
**            the input median salary.
**
**            Shows how to:
**             - define an INOUT parameter using PARAMETER STYLE SQL
**             - define and use NULL indicators for parameters
**             - define the extra parameters associated with
**               PARAMETER STYLE SQL
**
**  Parameters:
**
**   IN/OUT:  pinOutMedian - median salary
**                          input value used in SELECT predicate
**                          output set to median salary found
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**    
**              SQL_API_RC SQL_API_FN inout_param(
                                        double *pinOutMedian,  
**                                      sqlint16 *pinOutMedianNullInd, 
**                                      SQLUDF_TRAIL_ARGS)
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN inout_param(double *pinOutMedian,
                                  sqlint16 *pinOutMedianNullInd,
                                  SQLUDF_TRAIL_ARGS)
{
  SQLHANDLE henv, hdbc = 0, hstmt1, hstmt2;
  SQLRETURN cliRC;
  SQLCHAR stmt1[100] = {0};
  SQLCHAR stmt2[100] = {0};
  sqlint16 numRecords;
  double medianSalary;
  double tmpSalary;
  int counter;
  counter = 0;
  numRecords = 0;

  if ((*pinOutMedianNullInd) < 0)
  {
    /* NULL value was received as input, so return NULL output 
       the index of the null indicator array corresponds to the
       explicit parameter of the stored procedure */
    *pinOutMedianNullInd = -1;
    
    /* set custom sqlstate to return to client. */
    strcpy(sqludf_sqlstate, "38100");   
    strcpy(sqludf_msgtext, "Received null input");
    return (0);
  }
  
  if ((*pinOutMedian) < 0)
  {
    *pinOutMedianNullInd = -1;

    /* set custom sqlstate to return to client. */
    strcpy(sqludf_sqlstate, "38100");

    strcpy(sqludf_msgtext, "Received invalid input");
    return (0);
  }
  else
  {
    /* the stored procedure will return values, 
       so set the null indicators accordingly */
    *pinOutMedianNullInd = 0;
  }

  medianSalary = *pinOutMedian;
  
  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                              */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLSetConnectAttr");

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLConnect");

  /* allocate statement handle 1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 2 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  strcpy((char *)stmt1, "SELECT count(*) FROM staff ");
  strcat((char *)stmt1, "WHERE salary > ? ");

  strcpy((char *)stmt2, "SELECT CAST(salary AS DOUBLE) FROM staff ");
  strcat((char *)stmt2, "where salary > ? order by salary ");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt1, stmt1, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt2, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt2 failed.");

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt1,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &medianSalary,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindParameter");

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt2,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &medianSalary,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindParameter");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt1, 1, SQL_C_SHORT, &numRecords, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_DOUBLE, &tmpSalary, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* execute the statement */
  cliRC = SQLExecute(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");

  /* fetch next row */
  cliRC = SQLFetch(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");

  if (numRecords == 0)
  {
     *pinOutMedianNullInd = -1;

    /* return the custom error state and error message to client */
    strcpy(sqludf_sqlstate ,"38200");
    strcpy(sqludf_msgtext, " 100: No Data Found");

    /* free resources before returning */
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
    StpCleanUp(henv, hdbc);
    return (0);
  }

  /* execute the statement */
  cliRC = SQLExecute(hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt2 failed.");

  for (counter = 0; counter < (numRecords / 2 + 1); counter++)
  {
    /* fetch next row */
    cliRC = SQLFetch(hstmt2);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                           hstmt2,
                                           cliRC,
                                           henv,
                                           hdbc,
                                           sqludf_sqlstate,
                                           sqludf_msgtext,
                                           "SQLFetch");
  }

  /* set the value of the INOUT parameter to the median salary */
  *pinOutMedian = tmpSalary;

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLDisconnect");

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");
  return (0);

} /* end inout_param function */

/**************************************************************************
**  Stored procedure:  extract_from_clob
**
**  Purpose:  Extracts department information from a large object (LOB) 
**            resume of employee data returns this information
**            to the caller in output parameter outDeptInfo
**
**            Shows how to:
**             - define IN and OUT parameters in STYLE SQL 
**             - define a local lob locator variable
**             - locate information within a formatted lob
**             - extract information from within a clob and copy it
**               to a variable
**
**  Parameters:
**  
**   IN:      inEmpNumber - employee number
**   OUT:     outDeptInfo - department information section of the 
**            employee's resume     
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**
**              SQL_API_RC SQL_API_FN extract_from_clob(
**                                      char inEmpNumber[7],
**                                      char outDeptInfo[1001],
**                                      sqlint16 *pinEmpNumberNullInd,
**                                      sqlint16 *poutDeptInfoNullInd,
**                                      SQLUDF_TRAIL_ARGS)
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN extract_from_clob(
                        char inEmpNumber[7],    /* CHAR(6) */
                        char outDeptInfo[1001], /*  VARCHAR(1000) */
                        sqlint16 *pinEmpNumberNullInd,
                        sqlint16 *poutDeptInfoNullInd,
                        SQLUDF_TRAIL_ARGS)
{
  SQLHANDLE henv, hdbc = 0;
  SQLRETURN cliRC;

  SQLHANDLE hstmtClobSelect, hstmtLocUse, hstmtLocFree;
  SQLCHAR *stmtClobSelect =
    (SQLCHAR *)"SELECT resume FROM emp_resume "
    "WHERE empno = ?  AND resume_format = 'ascii'";

  SQLCHAR *stmtLocFree = (SQLCHAR *)"FREE LOCATOR ?";
  SQLINTEGER clobLoc;           /* LOB locator used for resume */
  SQLINTEGER pcbValue;
  SQLINTEGER clobPieceLen, clobLen;
  SQLUINTEGER clobPieceBegin, clobPieceEnd;

  /* initialize strings used for output parameters to NULL */
  memset(outDeptInfo, '\0', 1001);

  /* set the null indicator */
  *poutDeptInfoNullInd = -1;

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* --------------- fetch CLOB data --------------------------------------*/

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtClobSelect);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmtClobSelect,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           7,
                           0,
                           inEmpNumber,
                           7,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtClobSelect,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtClobSelect, stmtClobSelect, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(
    SQL_HANDLE_STMT,
    hstmtClobSelect,
    cliRC,
    henv,
    hdbc,
    sqludf_sqlstate,
    sqludf_msgtext,
    "SELECT statement stmtClobSelect failed.")
  
  /* bind CLOB column to LOB locator */
  cliRC = SQLBindCol(hstmtClobSelect,
                     1,
                     SQL_C_CLOB_LOCATOR,
                     &clobLoc,
                     0,
                     &pcbValue);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtClobSelect,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* fetch the CLOB data */
  cliRC = SQLFetch(hstmtClobSelect);
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    /* set custom SQLSTATE and Message to return to client.  */
    strcpy(sqludf_sqlstate, "38200");
    strcpy(sqludf_msgtext, " 100: No Data Found");
    
    StpCleanUp(henv, hdbc);
    return (0);
  }

  /* ---------------- work with the LOB locator ---------------------------*/

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtLocUse);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* get the length of the whole CLOB data */
  cliRC = SQLGetLength(hstmtLocUse,
                       SQL_C_CLOB_LOCATOR,
                       clobLoc,
                       &clobLen,
                       NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocUse,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* get the starting postion of the piece of CLOB data */
  cliRC = SQLGetPosition(hstmtLocUse,
                         SQL_C_CLOB_LOCATOR,
                         clobLoc,
                         0,
                         (SQLCHAR *)"Department Information",
                         strlen("Department Information"),
                         1,
                         &clobPieceBegin,
                         NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocUse,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* get the ending postion of the piece of CLOB data */
  cliRC = SQLGetPosition(hstmtLocUse,
                         SQL_C_CLOB_LOCATOR,
                         clobLoc,
                         0,
                         (SQLCHAR *)"Education",
                         strlen("Education"),
                         1,
                         &clobPieceEnd,
                         NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocUse,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* read the piece of CLOB data in outDeptInfo */
  cliRC = SQLGetSubString(hstmtLocUse,
                          SQL_C_CLOB_LOCATOR,
                          clobLoc,
                          clobPieceBegin,
                          clobPieceEnd - clobPieceBegin,
                          SQL_C_CHAR,
                          outDeptInfo,
                          clobPieceEnd - clobPieceBegin + 1,
                          &clobPieceLen,
                          NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocUse,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* ---------------- free the LOB locator -------------------------------*/

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtLocFree);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* bind a parameter marker to a buffer or LOB locator */
  cliRC = SQLSetParam(hstmtLocFree,
                      1,
                      SQL_C_CLOB_LOCATOR,
                      SQL_CLOB_LOCATOR,
                      0,
                      0,
                      &clobLoc,
                      NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocFree,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtLocFree, stmtLocFree, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocFree,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);
   
   /* set the null indicator */
   *poutDeptInfoNullInd = 0;

  /* ------------------ terminate the stored procedure --------------------*/

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtClobSelect);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtClobSelect,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtLocUse);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocUse,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtLocFree);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmtLocFree,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* disconnect from a data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  return (0);
} /* end extract_from_clob procedure */

/**************************************************************************
**  Stored procedure:  dbinfo_example
**
**  Purpose:  This routine takes in a job type and returns the
**            average salary of all employees with that job, as
**            well as information about the database (name,
**            version of database).  The database information
**            is retrieved from the dbinfo object.
**
**            Shows how to:
**             - define IN/ OUT parameters in PARAMETER STYLE SQL
**             - declare a parameter pointer to the dbinfo structure
**             - retrieve values from the dbinfo structure
**
**  Parameters:
**
**   IN:      inJob  - a job type, used in a SELECT predicate 
**   OUT:     poutSalary - average salary of employees with job specified 
**            by injob
**            outDbName - database name retrieved from DBINFO
**            outDbVersion - database version retrieved from DBINFO
**            sqludf_dbinfo - pointer to DBINFO structure
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**    
**              SQL_API_RC SQL_API_FN dbinfo_example(
**                                      char inJob[9],    
**                                      double *poutSalary,   
**                                      char outDbName[129],  
**                                      char outDbVersion[9], 
**                                      sqlint16 *pinJobNullInd,
**                                      sqlint16 *poutSalaryNullInd,
**                                      sqlint16 *poutDbNameNullInd,
**                                      sqlint16 *poutDbVersionNullInd,
**                                      SQLUDF_TRAIL_ARGS,
**                                      struct sqludf_dbinfo * poutDbInfo)                                 
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN dbinfo_example(
                        char inJob[9],          /* CHAR(8) */ 
                        double *poutSalary,     
                        char outDbName[129],    /* CHAR(128) */
                        char outDbVersion[9],   /* CHAR(8) */
                        sqlint16 *pinJobNullInd,
                        sqlint16 *poutSalaryNullInd,
                        sqlint16 *poutDbNameNullInd,
                        sqlint16 *poutDbVersionNullInd, 
                        SQLUDF_TRAIL_ARGS,
                        struct sqludf_dbinfo *poutDbInfo)
{
  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt;
  SQLRETURN cliRC;
  SQLCHAR stmt[100] = {0}; 

  /* initialize output parameters and NULL indicators */
  memset(outDbName, '\0', 129);
  memset(outDbVersion, '\0', 9);
  *poutSalary = 0;
  *poutSalaryNullInd = -1;
  *poutDbNameNullInd = -1;
  *poutDbVersionNullInd = -1;

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  strcpy((char *)stmt, "SELECT AVG(salary) FROM employee WHERE job = ?");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt failed.");

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           9,
                           0,
                           inJob,
                           9,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_DOUBLE, poutSalary, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  *poutSalaryNullInd = 0;

  /* copy values from the DBINFO structure into the output parameters.
     You must explicitly null-terminate the strings. */
  strncpy(outDbName, (char *)(poutDbInfo->dbname), poutDbInfo->dbnamelen);
  outDbName[poutDbInfo->dbnamelen] = '\0';
  *poutDbNameNullInd = 0;

  strncpy(outDbVersion, (char *)(poutDbInfo->ver_rel), 8);
  outDbVersion[8] = '\0';
  *poutDbVersionNullInd = 0;

  /* terminate the stored procedure */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);

  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* disconnect from a data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  return (0);
} /* end dbinfo_example function */

/**************************************************************************
**  Stored procedure:   main_example
**                              
**  Purpose:  Returns the average salary of employees in table
**            employee that have the job specified by argv[1]
**
**            Shows how to:
**             - use standard argc and argv parameters to a main
**               C routine to pass parameters in and out
**             - define IN parameters using PARAMETER STYLE SQL
**             - define and use NULL indicators for parameters
**             - define the extra parameters associated with
**               PARAMETER STYLE SQL
**
**  Parameters:
**
**   IN:      argc    - count of the number of parameters
**            argv[1] - job type (char[8])
**   OUT:     argv[2] - average salary of employees with that job (double)
**                      
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN main_example(int argc, char **argv)
{
  
  /* note:
     argv[0]: program name
     argv[1]: job type (char[8], input) 
     argv[2]: average salary (double, output)
     argv[3]: null indicator for job type 
     argv[4]: null indicator for average salary
     argv[5]: sqlstate (char[6], output)
     argv[6]: qualName (char[28], output)
     argv[7]: specName (char[19], output)
     argv[8]: diagMsg (char[71], output) */

  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt;
  SQLRETURN cliRC;
  SQLCHAR stmt[100] = {0}; 
  double *poutSalary = NULL;
  char inJob[9];
  char sqlstate[SQLUDF_SQLSTATE_LEN + 1];
  char diagMsg[SQLUDF_MSGTEXT_LEN + 1];

  /* initialize ouput null indicator */
  *(sqlint16 *)argv[4] = -1;

  /* check the null indicator variable for the input parameter  */
  if ( *(sqlint16 *)argv[3] < 0)
  {
    /* set custom SQLSTATE to return to client.  */
    strcpy((char *)argv[5], "38100");

    /* set custom message to return to client. Note that although the
      OUT parameter is declared as CHAR(70), DB2 prepends the
      procedure name and shared library entry point to the message.
      Keep the custom message short to avoid truncation. */
    strcpy((char *)argv[8], "Received null input");
    
    /* set the null indicator variable for the output parameter
       to indicate a null value */
    *(sqlint16 *)argv[4] = -1;
    
    return (0);
  }
    
  /* argv[0] contains the procedure name, so parameters start at argv[1] */
  strcpy(inJob, (char *)argv[1]);
  poutSalary = (double *)argv[2];
  
  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                              */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  strcpy((char *)stmt, "SELECT AVG(salary) FROM employee WHERE job = ?");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SELECT statement stmt failed.");

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           9,
                           0,
                           inJob,
                           9,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* execute the statement */
 cliRC = SQLExecute(hstmt);
 SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqlstate,
                                         diagMsg,
                                         "SELECT statement stmt failed.");

  /* bind column to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_DOUBLE, poutSalary, 0, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* fetch next row */
  cliRC = SQLFetch(hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* set the null indicator variable for the output parameter
   to indicate a non-null value */
  *(sqlint16 *)argv[4] = 0;

  /* terminate the stored procedure */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* disconnect from a data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqlstate);

  return (0);
} /* end main_example function */

/*************************************************************************
**  CLI stored procedures do not provide direct support for DECIMAL
**  data type.
**  The following programming languages can be used to directly  
**  manipulate DECIMAL type: 
**          - JDBC
**          - SQLJ
**          - SQL routines
**          - .NET common language runtime languages (C#, Visual Basic) 
**  Please see the SpServer implementation for one of the above 
**  language to see this functionality.
***************************************************************************/

/**************************************************************************
**  Stored procedure:  all_data_types 
**
**  Purpose:  Take each parameter and set it to a new output value.
**            This sample shows only a subset of DB2 supported data types.
**            For a full listing of DB2 data types, please see the SQL 
**            Reference. 
**
**            Shows how to:
**             - define INOUT/OUT parameters in PARAMETER STYLE SQL 
**             - declare variables and assign values to them
**             - assign output values to INOUT/OUT parameters
**
**  Parameters:
**  
**   INOUT:   pinOutSmall, pinOutInt, pinOutBig, pinOutReal, poutDouble
**   OUT:     outChar, outChars, outVarchar, outDate, outTime
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
**            CODE TIP:
**            --------
**            As an alternative to coding the non-functional parameters 
**            required with parameter style SQL (sqlstate, routine-name, 
**            specific-name, diagnostic-message), you can use a macro:
**            SQLUDF_TRAIL_ARGS. This macro is defined in DB2 include
**            file sqludf.h
**   
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**            SQL_API_RC SQL_API_FN all_data_types(
**                                    sqlint16 *pinOutSmall,
**                                    sqlint32 *pinOutInt,
**                                    sqlint64 *pinOutBig,
**                                    float *pinOutReal,
**                                    double *pinOutDouble,
**                                    char outChar[2],
**                                    char outChars[16],
**                                    char outVarchar[13],
**                                    char outDate[11],
**                                    char outTime[9],
**                                    sqlint16 *pinOutSmallNullind,
**                                    sqlint16 *pinOutIntNullind,
**                                    sqlint16 *pinOutBigNullind,
**                                    sqlint16 *pinOutRealNullind,
**                                    sqlint16 *pinOutDoubleNullind,
**                                    sqlint16 *poutCharNullind,
**                                    sqlint16 *poutCharsNullind,
**                                    sqlint16 *poutVarcharNullind,
**                                    sqlint16 *poutDateNullind,
**                                    sqlint16 *poutTimeNullind,
**                                    SQLUDF_TRAIL_ARGS)
**    
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN all_data_types(sqlint16 *pinOutSmall,
                                     sqlint32 *pinOutInt,
                                     sqlint64 *pinOutBig,
                                     float *pinOutReal,
                                     double *pinOutDouble,
                                     char outChar[2],      /* CHAR(1) */ 
                                     char outChars[16],    /* CHAR(15) */
                                     char outVarchar[13],  /* VARCHAR(12) */
                                     char outDate[11],     /* DATE */
                                     char outTime[9],      /* TIME */
                                     sqlint16 *pinOutSmallNullind,
                                     sqlint16 *pinOutIntNullind,
                                     sqlint16 *pinOutBigNullind,
                                     sqlint16 *pinOutRealNullind,
                                     sqlint16 *pinOutDoubleNullind,
                                     sqlint16 *poutCharNullind,
                                     sqlint16 *poutCharsNullind,
                                     sqlint16 *poutVarcharNullind,
                                     sqlint16 *poutDateNullind,
                                     sqlint16 *poutTimeNullind,
                                     SQLUDF_TRAIL_ARGS)
                                     
{
  SQLHANDLE henv, hdbc = 0;
  SQLHANDLE hstmt1, hstmt2, hstmt3, hstmt4, hstmt5;
  SQLCHAR stmt1[100] = {0}; 
  SQLCHAR stmt2[100] = {0};  
  SQLCHAR stmt3[100] = {0};  
  SQLCHAR stmt4[100] = {0};  
  SQLCHAR stmt5[100] = {0}; 
  SQLRETURN cliRC;
  char firstName[13]; /* VARCHAR(12) */

  /* initialize the OUT parameters and Null indicators */
  memset(outChar, '\0', 2);
  memset(outChars, '\0', 16);
  memset(outVarchar, '\0', 13);
  memset(outDate, '\0', 11);
  memset(outTime, '\0', 9);
  *poutCharNullind = -1;
  *poutCharsNullind = -1;
  *poutVarcharNullind = -1;
  *poutDateNullind = -1;
  *poutTimeNullind = -1;
  
  if (*pinOutSmall == 0)
  {
    *pinOutSmall = 1;
  }
  else
  {
    *pinOutSmall = (*pinOutSmall / 2);
  }

  if (*pinOutInt == 0)
  {
    *pinOutInt = 1;
  }
  else
  {
    *pinOutInt = (*pinOutInt / 2);
  }

  if (*pinOutBig == 0)
  {
    *pinOutBig = 1;
  }
  else
  {
    *pinOutBig = (*pinOutBig / 2);
  }

  if (*pinOutReal == 0)
  {
    *pinOutReal = 1;
  }
  else
  {
    *pinOutReal = (*pinOutReal / 2);
  }

  if (*pinOutDouble == 0)
  {
    *pinOutDouble = 1;
  }
  else
  {
    *pinOutDouble = (*pinOutDouble / 2);
  }

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLSetConnectAttr");

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle. 
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLConnect");

  /* allocate statement handle 1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 2 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 3 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 4 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt4);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  /* allocate statement handle 5 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt5);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLAllocHandle");

  strcpy((char *)stmt1, "SELECT midinit from employee  ");
  strcat((char *)stmt1, "WHERE empno = '000180'");

  strcpy((char *)stmt2, "SELECT lastname from employee  ");
  strcat((char *)stmt2, "WHERE empno = '000180'");

  strcpy((char *)stmt3, "SELECT firstnme from employee  ");
  strcat((char *)stmt3, "WHERE empno = '000180'");

  strcpy((char *)stmt4, "values CURRENT DATE  ");

  strcpy((char *)stmt5, "values CURRENT TIME  ");

  /* directly execute statement 1 */
  cliRC = SQLExecDirect(hstmt1, stmt1, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt1, 1, SQL_C_CHAR, outChar, 2, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* fetch next row */
  cliRC = SQLFetch(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");
  *poutCharNullind = 0;

  /* directly execute statement 2 */
  cliRC = SQLExecDirect(hstmt2, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt2 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_CHAR, outChars, 16, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* fetch next row */
  cliRC = SQLFetch(hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");

  *poutCharsNullind = 0;

  /* directly execute statement 3 */
  cliRC = SQLExecDirect(hstmt3, stmt3, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt3,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt3 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt3, 1, SQL_C_CHAR, outVarchar, 13, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt3,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* fetch next row */
  cliRC = SQLFetch(hstmt3);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt3,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");

  *poutVarcharNullind = 0;

  /* directly execute statement 4 */
  cliRC = SQLExecDirect(hstmt4, stmt4, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt4,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt4 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt4, 1, SQL_C_CHAR, outDate, 11, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt4,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* fetch next row */
  cliRC = SQLFetch(hstmt4);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt4,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");

  *poutDateNullind = 0;

  /* directly execute statement 5 */
  cliRC = SQLExecDirect(hstmt5, stmt5, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt5,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt5 failed.");

  /* bind a column to an application variable */
  cliRC = SQLBindCol(hstmt5, 1, SQL_C_CHAR, outTime, 9, NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt5,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLBindCol");

  /* fetch next row */
  cliRC = SQLFetch(hstmt5);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt5,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFetch");
  
  *poutTimeNullind = 0;
  
  /* end the stored procedure */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt3,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt4);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt4,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt5);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt5,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLDisconnect");

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SQLFreeHandle");

  return (0);
} /* end all_data_types procedure */

/**************************************************************************
**  Stored procedure:  one_result_set_to_caller
**
**  Purpose:  Returns a result set to the caller of employees with salaries
**            greater than the value of input parameter pinSalary.
**
**            Shows how to:
**             - define IN and OUT parameters in STYLE SQL
**             - define and use NULL indicators for parameters
**             - define the extra parameters associated with
**               PARAMETER STYLE SQL
**             - return a result set to the client
**
**  Parameters:
** 
**   IN:      pinSalary - salary
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
**
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
**            TIP EXAMPLE:
**            ------------
**            The following stored procedure prototype is equivalent 
**            to the actual prototype implementation for this stored 
**            procedure. It is simpler to implement. See stored 
**            procedure sample TwoResultSets in this file to see the
**            SQLUDF_TRAIL_ARGS macro in use.
**
**            SQL_API_RC SQL_API_FN one_result_set_to_caller(
**                                    double *pinSalary,
**                                    sqlint16 *pinSalaryNullInd,
**                                    SQLUDF_TRAIL_ARGS)
**    
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
*************************************************************************/

SQL_API_RC SQL_API_FN one_result_set_to_caller(double *pinSalary,
                                               sqlint16 *pinSalaryNullInd,
                                               SQLUDF_TRAIL_ARGS)
{
  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt;
  SQLRETURN cliRC;
  SQLCHAR stmt[100] = {0};

  if ((*pinSalaryNullInd) < 0)
  {
    /* set custom SQLSTATE to return to client.  */
    strcpy(sqludf_sqlstate, "38100");

    /* set custom message to return to client. Note that although the
       OUT parameter is declared as CHAR(70), DB2 prepends the
       procedure name and shared library entry point to the message.
       Keep the custom message short to avoid truncation. */
    strcpy(sqludf_msgtext, "Received null input");

    return (0);
  }
  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                              */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.    
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  strcpy((char *)stmt, "SELECT name, job, CAST(salary AS DOUBLE) AS salary");
  strcat((char *)stmt, " FROM staff WHERE salary > ? ORDER BY salary");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt failed.");
 
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           pinSalary,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
    SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt failed.");
  
  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);
  return (0);
} /* end one_result_set_to_caller function */

/**************************************************************************
**  Stored procedure:  two_result_sets
**
**  Purpose:  Return two result sets to the caller. One result set
**            consists of employee data of all employees with
**            salaries less than pinMedianSalary.  The other result set
**            contains employee data for employees with salaries
**            greater than pinMedianSalary.
**
**            Shows how to:
**              - define IN and OUT parameters in STYLE SQL
**              - define and use NULL indicators for parameters
**              - define the extra parameters associated with
**                PARAMETER STYLE SQL
**              - return more than 1 result set to the client
**
**  Parameters:
** 
**   IN:      pinMedianSalary - salary
**
**            When the PARAMETER STYLE SQL clause is specified 
**            in the CREATE PROCEDURE statement for the procedure
**            (see the script spcreate.db2), in addition to the 
**            parameters passed at procedure invocation time, the 
**            following parameters are passed to the routine
**            in the following order:
**
**             - one null indicator for each IN/INOUT/OUT parameter
**               is specified in the same order as the corresponding
**               parameter declarations.
**             - sqlstate: to be returned to the caller to indicate 
**               state (output)
**             - routine-name: qualified name of the routine (input)
**             - specific-name: the specific name of the routine (input)
**             - diagnostic-message: an optional text string returned to the
**               caller (output)
** 
**             CODE TIP:
**             ========
**             See the parameter declarations in stored procedure
**             example OutLanguage for datatypes and sizes for these.
**
**             In this example we use macro SQLUDF_TRAIL_ARGS
**             (defined in sqludf.h - this file must be included)
**             to replace the 4 'extra' parameters:
**               sqlstate, qualified routine name, specific name of
**               routine, diagnostic string.
**
**             When referencing the 'extra' parameters, use the
**             parameter names provided in the macro definition in
**             sqludf.h:
**
**                sqludf_sqlstate
**                sqludf_fname
**                sqludf_fspecname
**                sqludf_msgtext
**
**   Note: With parameter style SQL it is mandatory to declare either the 
**         four non-functional parameters (sqlstate, routine-name, 
**         specific-name, diagnostic-message) or SQLUDF_TRAIL_ARGS macro.
**
***************************************************************************/

SQL_API_RC SQL_API_FN two_result_sets(double *pinSalary,
                                      sqlint16 *pinSalaryNullInd,
                                      SQLUDF_TRAIL_ARGS)
{
  SQLHANDLE henv, hdbc = 0, hstmt1, hstmt2;
  SQLRETURN cliRC;
  SQLCHAR stmt1[100] = {0};
  SQLCHAR stmt2[100] = {0};

  if (*pinSalaryNullInd < 0)
  {
    /* set custom SQLSTATE to return to client.  */
    strcpy(sqludf_sqlstate, "38100");

    /* set custom message to return to client. Note that although the
       OUT parameter is declared as CHAR(70), DB2 prepends the
       procedure name and shared library entry point to the message.
       Keep the custom message short to avoid truncation. */
    strcpy(sqludf_msgtext, "Received null input");
  }

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate statement handle 1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* allocate statement handle 2 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* statement for first result set:
     staff with a salary greater than the IN parameter */
  strcpy((char *)stmt1,
         "SELECT name, job, CAST(salary AS DOUBLE) AS salary");
  strcat((char *)stmt1, " FROM staff WHERE salary > ? ORDER BY salary");

  /* statement for second result set:
     staff with a salary less than the IN parameter */
  strcpy((char *)stmt2,
         "SELECT name, job, CAST(salary AS DOUBLE) AS salary");
  strcat((char *)stmt2, " FROM staff WHERE salary < ? ");
  strcat((char *)stmt2, "ORDER BY salary DESC");

  /* prepare statement 1 */
  cliRC = SQLPrepare(hstmt1, stmt1, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");
  
  /* prepare statement 2 */
  cliRC = SQLPrepare(hstmt2, stmt2, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt2 failed.");
  
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt1,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           pinSalary,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt1,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt2,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           pinSalary,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_STMT,
                                 hstmt2,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* execute statement 1 */
  cliRC = SQLExecute(hstmt1);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt1,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt1 failed.");
  
  /* execute statement 2 */
  cliRC = SQLExecute(hstmt2);
  SRV_HANDLE_CHECK_SETTING_SQLST_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt2,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         sqludf_sqlstate,
                                         sqludf_msgtext,
                                         "SELECT statement stmt2 failed.");
  
  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_DBC,
                                 hdbc,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLST(SQL_HANDLE_ENV,
                                 henv,
                                 cliRC,
                                 henv,
                                 hdbc,
                                 sqludf_sqlstate);

  return (0);
} /* end two_result_sets function */

/**************************************************************************
**  Stored procedure:  general_example
**
**  Purpose:  Return a result set to the caller that identifies those
**            employees with an education level equal to the value of
**            input parameter pinEdLevel.
**
**            Shows how to:
**             - define IN and OUT parameters in STYLE GENERAL
**             - execute SQL to declare and work with a cursor 
**             - return a result set to the client
**
**  Parameters:
** 
**   IN:      pinEdLevel - education level of the employee
**   OUT:     poutReturnCode - sqlcode of error (if one is raised)
**            outErrorMsg - text information returned to the client to
**            locate the error, if any
**
**            When PARAMETER STYLE GENERAL clause is specified in the 
**            CREATE PROCEDURE statement for the procedure 
**            (see the script spcreate.db2), only the parameters passed
**            during invocation are passed to the routine. With 
**            PARAMETER STYLE GENERAL, there is no concept of null. You  
**            cannot assess the nullability of variable, nor can you set  
**            a value to an SQL equivalent to NULL.
**            
***************************************************************************/

SQL_API_RC SQL_API_FN general_example(sqlint32 *pinEdlevel, 
                                      sqlint32 *poutReturnCode, 
                                      char outErrorMsg[33]) /* CHAR(32) */
{
  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt;
  SQLRETURN cliRC;
  SQLCHAR stmt[100] = {0}; 
  
  /* initialize output parameters  */
  *poutReturnCode = 0;
  memset(outErrorMsg, '\0', 33);
  
  if ((*pinEdlevel > 25) || (*pinEdlevel < 0))
  {
    /* set the output error code and message */
    *poutReturnCode = -1;
    strcpy(outErrorMsg, "Received invalid input");
    
    return (0);   
  }   

  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                              */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLAllocHandle");

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLAllocHandle");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLSetConnectAttr");

  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.    
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLConnect");

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLAllocHandle");

  strcpy((char *)stmt, "SELECT firstnme, lastname, workdept ");
  strcat((char *)stmt, "FROM employee WHERE edlevel = ? ORDER BY workdept");
 
  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLPrepare");

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           pinEdlevel,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLBindParameter");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hstmt,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLExecute");

  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLDisconnect");

  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLFreeHandle");

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode, 
                                         outErrorMsg,
                                         "SQLFreeHandle");
  return (0);
  
} /* end general_example function */

/**************************************************************************
**  Stored procedure:  general_with_nulls_example
**
**  Purpose:  Returns a result set to the caller that contains sales 
**            information for a particular business quarter, as specified 
**            by input parameter pinQuarter.
**
**            Shows how to:
**             - define IN and OUT parameters in STYLE GENERAL WITH NULLS
**             - define and use NULL indicators for parameters
**             - execute SQL to declare and use a cursor 
**             - return a result set to the client
**
**  Parameters:
** 
**   IN:      pinQuarter - quarter of the year for which sales 
**            information is returned
**   OUT:     poutReturnCode - sqlcode of error (if one is raised)
**            outErrorMsg - text information returned to the client to
**            locate the error, if any
**
**            When PARAMETER STYLE GENERAL WITH NULLS is defined
**            for the routine (see routine registration script 
**            spcreate.db2), in addition to the parameters passed during
**            invocation, a vector containing a null indicator for each
**            parameter in the CALL statement is passed to the routine.
** 
***************************************************************************/
SQL_API_RC SQL_API_FN 
general_with_nulls_example(sqlint32 *pinQuarter, 
                           sqlint32 *poutReturnCode, 
                           char outErrorMsg[33],    /* CHAR(32) */
                           sqlint16 nullInds[3])
{

  SQLHANDLE henv;
  SQLHANDLE hdbc = 0;
  SQLHANDLE hstmt;
  SQLRETURN cliRC;
  SQLCHAR stmt[100] = {0}; 

  /* note: nullInds[0] corresponds to inQuarter
           nullInds[1] corresponds to poutReturnCode
           nullInds[2] corresponds to outErrorMsg  */

  /* initialize output parameters and their corresponding null indicators */
  *poutReturnCode = 0;
  memset(outErrorMsg, '\0', 33);
  nullInds[1] = 0;
  nullInds[2] = -1;
  

  if (nullInds[0] < 0)
  {
    /* set the output error code and message */
    *poutReturnCode = -1;
    strcpy(outErrorMsg, "Received null input");  

    /* received null inputs, so set the output null indicators accordingly */  
    nullInds[1] = 0;
    nullInds[2] = 0;
   
    return (0);
  }

  if ((*pinQuarter) < 1 || (*pinQuarter) > 4)
  {
    /* set the output error code and message */
    *poutReturnCode = -1;
    strcpy(outErrorMsg, "Received invalid input");
    
    /* set the output null indicators to indicate the output parameters
       are not null */
    nullInds[1] = 0;
    nullInds[2] = 0;
    
    return (0);   
  }   
     
  /* initialize output parameters  */
  *poutReturnCode = 0;
   
  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/

  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLAllocHandle");
  
  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_ENV,
                                         henv,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLAllocHandle");
  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLSetConnectAttr");
  /* issue NULL Connect, because in CLI a statement handle is
     required and thus a connection handle and environment handle.    
     A connection is not established; rather the current
     connection from the calling application is used. */

  /* connect to a data source */
  cliRC = SQLConnect(hdbc, NULL, SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLConnect");
  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLAllocHandle");
       
  strcpy((char *)stmt, "SELECT sales_person, region, sales FROM sales");
  strcat((char *)stmt, " WHERE quarter(sales_date) = ?");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SELECT statement stmt failed.");
  
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           pinQuarter,
                           0,
                           NULL);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLBindParameter");
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_STMT,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SELECT statement stmt failed.");
  
  /* disconnect from the data source */
  cliRC = SQLDisconnect(hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLDisconnect");
  
  /* free the database handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLFreeHandle");
  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  SRV_HANDLE_CHECK_SETTING_SQLRC_AND_MSG(SQL_HANDLE_DBC,
                                         hdbc,
                                         cliRC,
                                         henv,
                                         hdbc,
                                         poutReturnCode,
                                         outErrorMsg,
                                         "SQLFreeHandle");
  return (0);
} /* end general_with_nulls_example function */
