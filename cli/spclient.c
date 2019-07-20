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
** SOURCE FILE NAME: spclient.c
**
** SAMPLE: Call the set of stored procedues implemented in spserver.c
**
**         To run this sample, peform the following steps:
**         (1) create and populate the SAMPLE database (db2sampl)
**         (2) see and complete the instructions in spserver.c for building
**             the shared library
**         (3) compile spclient.c (nmake spclient (Windows) or make spclient
**             (UNIX), or bldapp spclient for the Microsoft Visual C++
**             compiler on Windows)
**         (5) run spclient (spclient)
**
**         spclient.c uses twelve functions to call stored procedures defined
**         in spserver.c.
**
**         (1) callOutLanguage: Calls a stored procedure that returns the 
**             language of the stored procedure library
**               Parameter types used: OUT CHAR(8)
**         (2) callOutParameter: Calls a stored procedure that returns 
**             median salary of employee salaries
**               Parameter types used: OUT DOUBLE
**         (3) callInParameters: Calls a stored procedure that accepts 3 
**             salary values and updates employee salaries based on these 
**             values
**               Parameter types used: IN DOUBLE
**                                     IN DOUBLE
**                                     IN DOUBLE
**                                     IN CHAR(3)
**         (4) callInoutParameter: Calls a stored procedure that accepts an 
**             input value and returns the median salary of employees who 
**             make more than the input value. Demonstrates how to use null
**             indicator in a client application. The stored procedure has 
**             to be implemented in the following parameter styles for it to 
**             be compatible with this client application.
**             Parameter style for a C stored procedure: SQL
**             Parameter style for a Java(JDBC/SQLJ) stored procedure: JAVA
**             Parameter style for an SQL stored procedure: SQL
**                Parameter types used: INOUT DOUBLE
**         (5) callClobExtract: Calls a stored procedure that extracts and 
**             returns a portion of a CLOB data type
**                Parameter types used: IN CHAR(6)
**                                      OUT VARCHAR(1000)
**         (6) callDBINFO: Calls a stored procedure that receives a DBINFO
**             structure and returns elements of the structure to the client
**                Parameter types used: IN CHAR(8)
**                                      OUT DOUBLE
**                                      OUT CHAR(128)
**                                      OUT CHAR(8)
**         (7) callProgramTypeMain: Calls a stored procedure implemented 
**             with PROGRAM TYPE MAIN parameter style
**               Parameter types used: IN CHAR(8)
**                                     OUT DOUBLE
**         (8) callAllDataTypes: Calls a stored procedure that uses a 
**             variety of common data types (not GRAPHIC, VARGRAPHIC, BLOB, 
**             DECIMAL, CLOB, DBCLOB). This sample shows only a subset of 
**             DB2 supported data types. For a full listing of DB2 data 
**             types, please see the SQL Reference.
**               Parameter types used: INOUT SMALLINT
**                                     INOUT INTEGER
**                                     INOUT BIGINT
**                                     INOUT REAL
**                                     INOUT DOUBLE
**                                     OUT CHAR(1)
**                                     OUT CHAR(15)
**                                     OUT VARCHAR(12)
**                                     OUT DATE
**                                     OUT TIME
**         (9) callOneResultSet: Calls a stored procedure that return 
**             a result set to the client application
**               Parameter types used: IN DOUBLE
**         (10) callTwoResultSets: Calls a stored procedure that returns 
**             two result sets to the client application
**               Parameter types used: IN DOUBLE
**         (11) callGeneralExample: Call a stored procedure inplemented
**              with PARAMETER STYLE GENERAL 
**               Parameter types used: IN INTEGER
**                                     OUT INTEGER
**                                     OUT CHAR(33) 
**         (12) callGeneralWithNullsExample: Calls a stored procedure 
**              implemented with PARAMETER STYLE GENERAL WITH NULLS
**               Parameter types used: IN INTEGER
**                                     OUT INTEGER
**                                     OUT CHAR(33)
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLCloseCursor -- Close Cursor and Discard Pending Results
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetDiagRec -- Get Multiple Fields Settings of Diagnostic Record
**         SQLMoreResults -- Determine if There Are More Result Sets
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLPrepare -- Prepare a Statement
**
** EXTERNAL DEPENDENCIES:
**      Ensure that the stored procedures called from this program have
**      been built and cataloged with the database (see the instructions in
**      spserver.c).
**
** OUTPUT FILE: spclient.out (available in the online documentation)
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

int callOutLanguage(SQLHANDLE, char *);
int callOutParameter(SQLHANDLE, double *);
int callInParameters(SQLHANDLE);
int callInoutParameter(SQLHANDLE, double);
int callClobExtract(SQLHANDLE);
int callDBINFO(SQLHANDLE);
int callProgramTypeMain(SQLHANDLE);
int callAllDataTypes(SQLHANDLE);
int callOneResultSet(SQLHANDLE, double);
int callTwoResultSets(SQLHANDLE, double);
int callGeneralExample(SQLHANDLE, int);
int callGeneralWithNullsExample(SQLHANDLE, int);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  double medSalary = 0;
  char language[9];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("HOW TO CALL VARIOUS STORED PROCEDURES.\n");
  
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
  /* we assume that all the remaining stored procedures are also written in
     the same language as 'language' and set the following variables accordingly.
     This would help us in invoking only those stored procedures that are 
     supported in that particular language. */
  
  /********************************************************\
  * call OUT_LANGUAGE stored procedure                     *
  \********************************************************/
  rc = callOutLanguage(hdbc, language);

  /* we assume that all the remaining stored procedures are also written in
     the same language as 'language' and set the following variables accordingly.
     This would help us in invoking only those stored procedures that are 
     supported in that particular language. */
  

  /********************************************************\
  * call OUT_PARAM stored procedure                        *
  \********************************************************/
  rc = callOutParameter(hdbc, &medSalary);

  /********************************************************\
  * call IN_PARAMS stored procedure                        *
  \********************************************************/
  rc = callInParameters(hdbc);

  /********************************************************\
  * call INOUT_PARAM stored procedure                      *
  \********************************************************/

  printf("\nCALL stored procedure INOUT_PARAM \n");
  printf("using the median returned by the call to OUT_PARAM\n");
  rc = callInoutParameter(hdbc, medSalary);

  /********************************************************\
  * call INOUT_PARAM stored procedure again twice in order *
  * to depict NULL value and NOT FOUND error conditions    * 
  * Any negative value passed to the function              *       
  * "callInoutParameter" would be considered invalid and   *
  * hence the stored procedure would be called with        *  
  * NULL input.                                            *
  \********************************************************/
  printf("\nCALL stored procedure INOUT_PARAM again\n");
  printf("using a NULL input value\n");
  printf("\n-- The following error report is expected! --\n");
  rc = callInoutParameter(hdbc, -99999);

  printf("\nCALL stored procedure INOUT_PARAM again \n");
  printf("using a value that returns a NOT FOUND error from the "
         "stored procedure\n");
  printf("\n-- The following error report is expected! --\n");
  rc = callInoutParameter(hdbc, 99999.99);

  /********************************************************\
  * call CLOB_EXTRACT stored procedure                     *
  \********************************************************/
  rc = callClobExtract(hdbc);

  if (strncmp(language, "C", 1) != 0)
  {
    /**********************************************************\
    * Stored procedures of PROGRAM TYPE MAIN or those          *
    * containing  DBINFO clause have only been implemented by  *
    * LANGUAGE C stored procedures. If language != "C",        *
    * since there is no corresponding sample, we do nothing.   *
    \**********************************************************/
  }
  else
  {
    /********************************************************\
    * call DBINFO_EXAMPLE stored procedure                   *
    \********************************************************/
    rc = callDBINFO(hdbc);

    /********************************************************\
    * call MAIN_EXAMPLE stored procedure                     *
    \********************************************************/
    rc = callProgramTypeMain(hdbc);
  }

  /**********************************************************************\
  *   CLI stored procedures do not provide direct support for DECIMAL    *
  *   data type.                                                         *
  *   The following programming languages can be used to directly        *  
  *   manipulate DECIMAL type:                                           *
  *           - JDBC                                                     * 
  *           - SQLJ                                                     *
  *           - SQL routines                                             *
  *           - .NET common language runtime languages (C#, Visual Basic)* 
  *   Please see the SpServer implementation for one of the above        * 
  *   languages to see this functionality.                               *
  \**********************************************************************/  

  /********************************************************\
  * call ALL_DATA_TYPES stored procedure                   *
  \********************************************************/
  rc = callAllDataTypes(hdbc);

  /********************************************************\
  * call ONE_RESULT_SET stored procedure                   *
  \********************************************************/
  rc = callOneResultSet(hdbc, medSalary);

  /********************************************************\
  * call TWO_RESULT_SETS stored procedure                  *
  \********************************************************/
  rc = callTwoResultSets(hdbc, medSalary);

  /********************************************************\
  * call GENERAL_EXAMPLE stored procedure                  *
  \********************************************************/
  rc = callGeneralExample(hdbc, 16);

  /********************************************************\
  * call GENERAL_WITH_NULLS_EXAMPLE stored procedure       *
  \********************************************************/
  rc = callGeneralWithNullsExample(hdbc, 2);

  /********************************************************\
  * call GENERAL_WITH_NULLS_EXAMPLE stored procedure again *
  * GENERAL_WITH_NULLS_EXAMPLE to depict NULL value        * 
  * Any negative value passed to the function              *       
  * "callGeneralWithNullsExample" would be considered      *
  * invalid and  hence the stored procedure would be       *  
  * called with NULL input.                                *
  \********************************************************/
  printf("\nCALL stored procedure GENERAL_WITH_NULLS_EXAMPLE again\n");
  printf("using a NULL input value\n");
  printf("\n-- The following error report is expected! --\n");
  rc = callGeneralWithNullsExample(hdbc, -99999);
 
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

/* call the OUT_LANGUAGE stored procedure */
int callOutLanguage(SQLHANDLE hdbc, char *outLanguage)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  char procName[] = "OUT_LANGUAGE";
  SQLCHAR *stmt = (SQLCHAR *)"CALL OUT_LANGUAGE (?)";

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           9,
                           0,
                           outLanguage,
                           9,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* display the language of the stored procedures */
  printf("Stored procedures are implemented in LANGUAGE: %s\n", outLanguage);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callOutLanguage */

/* call the OUT_PARAM stored procedure */
int callOutParameter(SQLHANDLE hdbc, double *pOutMedSalary)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER outSqlrc;
  char outMsg[33];
  char procName[] = "OUT_PARAM";
  SQLCHAR *stmt = (SQLCHAR *)"CALL OUT_PARAM (?)";

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_OUTPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           pOutMedSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* display the median salary returned as an output parameter */
  printf("Median salary returned from OUT_PARAM = %8.2f\n",
          *pOutMedSalary);
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callOutParameter */

/* call the IN_PARAMS stored procedure */
int callInParameters(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmtSelect; /* statement handle */
  SQLHANDLE hstmtCall; /* statement handle */

  char procName[] = "IN_PARAMS";
  SQLCHAR stmtSelect[256] = {0};
  SQLCHAR *stmtCall = (SQLCHAR *)"CALL IN_PARAMS (?, ?, ?, ?)";
   
  double sumOfSalaries;
  
  /* declare variables for passing data to IN_PARAMS */
  double inLowSal, inMedSal, inHighSal;
  char inDept[4];

  inLowSal = 15000;
  inMedSal = 20000;
  inHighSal = 25000;
  strcpy(inDept, "E11");
  strcpy(procName, "IN_PARAMS");

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle for SELECT */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtSelect);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle for CALL */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtCall);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* select values from the employee table */
  strcpy((char *)stmtSelect,
         "SELECT SUM(salary) FROM employee WHERE workdept = '");
  strcat((char *)stmtSelect, inDept);
  strcat((char *)stmtSelect, "'");

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmtSelect, 1, SQL_C_DOUBLE, &sumOfSalaries, 0, NULL);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* bind selected column to variable */
  cliRC = SQLExecDirect(hstmtSelect, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* fetch the result */
  cliRC = SQLFetch(hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  printf(
    "Sum of salaries for dept. %s = %8.2f before calling procedure %s\n",
    inDept, sumOfSalaries, procName);

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmtCall, stmtCall, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmtCall,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inLowSal,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmtCall,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inMedSal,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  /* bind parameter 3 to the statement */
  cliRC = SQLBindParameter(hstmtCall,
                           3,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inHighSal,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  /* bind parameter 4 to the statement */
  cliRC = SQLBindParameter(hstmtCall,
                           4,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           4,
                           0,
                           inDept,
                           4,
                           NULL);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmtCall);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* display the sum salaries for the affected department */

  /* execute the SELECT */
  cliRC = SQLExecDirect(hstmtSelect, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);
    
  /* fetch the sum of salaries */
  cliRC = SQLFetch(hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  printf(
    "Sum of salaries for dept. %s = %8.2f after calling procedure %s\n",
    inDept, sumOfSalaries, procName);
    
  /* free the SELECT statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtSelect);
  STMT_HANDLE_CHECK(hstmtSelect, hdbc, cliRC);

  /* free the CALL statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtCall);
  STMT_HANDLE_CHECK(hstmtCall, hdbc, cliRC);

  return rc;
} /* end callInParameters */

/* call the INOUT_PARAM stored procedure */
int callInoutParameter(SQLHANDLE hdbc, double initialMedSalary)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER medSalaryInd, sqlrcInd, msgInd;
  char procName[] = "INOUT_PARAM";
  SQLCHAR *stmt = (SQLCHAR *)"CALL INOUT_PARAM (?)";
  SQLDOUBLE inoutMedSalary = 0;

  printf("CALL stored procedure: %s\n", procName);

  /* pass null indicators */
  if (initialMedSalary < 0)
  {
    /* salary was negative, indicating a probable error,
       so pass a null value to the stored procedure instead
       by setting medSalaryInd to a negative value */
    medSalaryInd = -1;
  }
  else
  {
    /* salary was positive, so pass the value of initialMedSalary
       to the stored procedure by setting medSalaryInd to 0 */
    inoutMedSalary = initialMedSalary;
    medSalaryInd = 0;
  }

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT_OUTPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inoutMedSalary,
                           0,
                           &medSalaryInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* check that the stored procedure executed successfully */
  if (cliRC == 0 && medSalaryInd >= 0)
  {
    printf("Stored procedure returned successfully.\n");
    printf("Median salary returned from INOUT_PARAM = %8.2f\n",
           inoutMedSalary);
  }
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callInoutParameter */

/* call the CLOB_EXTRACT stored procedure */
int callClobExtract(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt;
  char procName[] = "CLOB_EXTRACT";
  SQLCHAR stmt[] = "CALL CLOB_EXTRACT (?, ?)";
  char inEmpNumber[7];
  char outDeptInfo[1001];

  printf("\nCALL stored procedure:  %s\n", procName);
  strcpy(inEmpNumber, "000140");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           7,
                           0,
                           inEmpNumber,
                           7,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           1001,
                           0,
                           outDeptInfo,
                           1001,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* display the section of the resume returned from the CLOB */
  printf("Resume section returned from CLOB_EXTRACT = \n%s\n",
          outDeptInfo);
  
  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callClobExtract */

/* call the DBINFO_EXAMPLE stored procedure */
int callDBINFO(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER outSqlrc;
  char procName[] = "DBINFO_EXAMPLE";
  SQLCHAR *stmt = (SQLCHAR *)"CALL DBINFO_EXAMPLE (?, ?, ?, ?)";
  SQLCHAR inJob[9] = {0};
  SQLDOUBLE outSalary;

  /* name of database from DBINFO structure */
  SQLCHAR outDbname[129] = {0}; 

  /* version of database from DBINFO structure */
  SQLCHAR outDbVersion[9] = {0}; 

  strcpy((char *)inJob, "MANAGER");

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
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
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_OUTPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &outSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 3 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           3,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           129,
                           0,
                           outDbname,
                           129,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 4 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           4,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           9,
                           0,
                           (char *)outDbVersion,
                           9,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");
  printf("Average salary for job %s = %9.2lf\n", inJob, outSalary);
  printf("Database name from DBINFO structure = %s\n", outDbname);
  printf("Database version from DBINFO structure = %s\n", outDbVersion);
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callDBINFO */

/* call the MAIN_EXAMPLE stored procedure */
int callProgramTypeMain(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER outSqlrc;
  char procName[] = "MAIN_EXAMPLE";
  SQLCHAR *stmt = (SQLCHAR *)"CALL MAIN_EXAMPLE (?, ?)";
  SQLCHAR inJob[9];
  SQLDOUBLE outSalary;

  strcpy((char *)inJob, "DESIGNER");
  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
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
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_OUTPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &outSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");
  printf("Average salary for job %s = %9.2lf\n", inJob, outSalary);
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callProgramTypeMain */

/* call ALL_DATA_TYPES stored procedure */
int callAllDataTypes(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char outMsg[33];
  char procName[] = "ALL_DATA_TYPES";
  SQLCHAR *stmt =
    (SQLCHAR *)"CALL ALL_DATA_TYPES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
  SQLSMALLINT inoutSmallint;
  SQLINTEGER inoutInteger;
  SQLBIGINT inoutBigint;
  SQLREAL inoutReal;
  SQLDOUBLE inoutDouble;
  SQLCHAR outChar[2] = {0};
  SQLCHAR outChars[16]= {0};
  SQLCHAR outVarchar[13]= {0};
  SQLCHAR outDate[11] = {0};
  SQLCHAR outTime[9] = {0};

  inoutSmallint = 32000;
  inoutInteger = 2147483000;
  inoutBigint = 2147480000;
  /* maximum value of BIGINT is 9223372036854775807 */
  inoutReal = 100000;
  inoutDouble = 2500000;

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT_OUTPUT,
                           SQL_C_SHORT,
                           SQL_SMALLINT,
                           0,
                           0,
                           &inoutSmallint,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT_OUTPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           &inoutInteger,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 3 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           3,
                           SQL_PARAM_INPUT_OUTPUT,
                           SQL_C_SBIGINT,
                           SQL_BIGINT,
                           0,
                           0,
                           &inoutBigint,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 4 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           4,
                           SQL_PARAM_INPUT_OUTPUT,
                           SQL_C_FLOAT,
                           SQL_REAL,
                           0,
                           0,
                           &inoutReal,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 5 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           5,
                           SQL_PARAM_INPUT_OUTPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inoutDouble,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 6 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           6,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           2,
                           0,
                           outChar,
                           2,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 7 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           7,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           16,
                           0,
                           outChars,
                           16,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 8 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           8,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           13,
                           0,
                           outVarchar,
                           13,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 9 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           9,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_TYPE_DATE,
                           11,
                           0,
                           outDate,
                           11,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 10 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           10,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_TYPE_TIME,
                           9,
                           0,
                           outTime,
                           9,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");
  printf("Value of SMALLINT = %d\n", inoutSmallint);
  printf("Value of INTEGER = %ld\n", inoutInteger);
  printf("Value of BIGINT = %lld\n", inoutBigint);
  printf("Value of REAL = %.2f\n", inoutReal);
  printf("Value of DOUBLE = %.2lf\n", inoutDouble);
  printf("Value of CHAR(1) = %s\n", outChar);
  printf("Value of CHAR(15) = %s\n", outChars);
  printf("Value of VARCHAR(12) = %s\n", outVarchar);
  printf("Value of DATE = %s\n", outDate);
  printf("Value of TIME = %s\n\n", outTime);
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callAllDataTypes */

/* call the ONE_RESULT_SET stored procedure */
int callOneResultSet(SQLHANDLE hdbc, double medSalary)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char procName[] = "ONE_RESULT_SET"; 
  SQLCHAR *stmt = (SQLCHAR *)"CALL ONE_RESULT_SET (?)";
  SQLDOUBLE inSalary, outSalary;
  SQLSMALLINT numCols;
  SQLCHAR outName[40] = {0};
  SQLCHAR outJob[10] = {0};

  inSalary = medSalary;

  printf("CALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get number of result columns */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Result set returned %d columns\n", numCols);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, outName, 40, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, outJob, 10, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_DOUBLE, &outSalary, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nFirst result set returned from %s", procName);
  printf("\n------Name------,  --JOB--, ---Salary--  \n");
  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    printf("%16s,%9s,    %.2lf\n", outName, outJob, outSalary);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callOneResultSet */

/* call the TWO_RESULT_SETS stored procedure */
int callTwoResultSets(SQLHANDLE hdbc, double medSalary)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char procName[] = "TWO_RESULT_SETS";
  SQLCHAR *stmt = (SQLCHAR *)"CALL TWO_RESULT_SETS (?)";
  SQLDOUBLE inSalary, outSalary;
  SQLSMALLINT numCols;
  SQLCHAR outName[40] = {0};
  SQLCHAR outJob[10] = {0};

  inSalary = medSalary;

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get number of result columns */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Result set returned %d columns\n", numCols);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, outName, 40, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, outJob, 10, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_DOUBLE, &outSalary, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* fetch first result set returned from stored procedure */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nFirst result set returned from %s", procName);
  printf("\n------Name------,  --JOB--, ---Salary--  \n");
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("%16s,%9s,    %.2lf\n", outName, outJob, outSalary);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* determine if there are more result sets */
  cliRC = SQLMoreResults(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get next result set until no more result sets are available */
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* fetch second result set returned from stored procedure */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("\nNext result set returned from %s", procName);
    printf("\n------Name------,  --JOB--, ---Salary--  \n");
    while (cliRC != SQL_NO_DATA_FOUND)
    {
      printf("%16s,%9s,    %.2lf\n", outName, outJob, outSalary);

      /* fetch next row */
      cliRC = SQLFetch(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }

    /* determine if there are more result sets */
    cliRC = SQLMoreResults(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
 
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callTwoResultSets */

/* call the GENERAL_EXAMPLE stored procedure */
int callGeneralExample(SQLHANDLE hdbc, int inedlevel)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER outSqlrc;
  char procName[] = "GENERAL_EXAMPLE"; 
  SQLCHAR *stmt = (SQLCHAR *)"CALL GENERAL_EXAMPLE (?, ?, ?)";
  SQLSMALLINT numCols;
  SQLCHAR outMsg[33] = {0};
  SQLCHAR firstnme[12] = {0};
  SQLCHAR lastname[15] = {0};
  SQLCHAR workdept[4] = {0};

  printf("\nCALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           &inedlevel,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_OUTPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           &outSqlrc,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 3 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           3,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           33,
                           0,
                           outMsg,
                           33,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get number of result columns */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Result set returned %d columns\n", numCols);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, firstnme, 12, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, lastname, 15, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, workdept, 4, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* check that the stored procedure executed successfully */
  if (outSqlrc == 0)
  {
    printf("Stored procedure returned successfully.\n");

    /* fetch result set returned from stored procedure */
    cliRC = SQLFetch(hstmt); 
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("\nThe result set returned from %s", procName);
    printf("\n-----FIRSTNME-------LASTNAME-----WORKDEPT--\n");
    while (cliRC != SQL_NO_DATA_FOUND) 
    {
      printf("%12s,       %-10s, %3s\n", firstnme, lastname, workdept);

      /* fetch next row */
      cliRC = SQLFetch(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }
  }
  else
  {
    printf("Stored procedure returned SQLCODE %d\n", outSqlrc);
    printf("With Error: \"%s\".\n", outMsg);
  }

  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callGeneralExample */

/* call the GENERAL_WITH_NULLS_EXAMPLE stored procedure */
int callGeneralWithNullsExample (SQLHANDLE hdbc, int inquarter)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER outSqlrc;
  SQLINTEGER inquarterInd;
  SQLINTEGER sqlrcInd;
  SQLINTEGER msgInd;
  char procName[] = "GENERAL_WITH_NULLS_EXAMPLE"; 
  SQLCHAR *stmt = (SQLCHAR *)"CALL GENERAL_WITH_NULLS_EXAMPLE (?, ?, ?)";
  SQLSMALLINT numCols;
  SQLCHAR outMsg[33] = {0};
  SQLCHAR sales_person[15] = {0};
  SQLCHAR region[15] = {0};
  
  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }sales;

  printf("\nCALL stored procedure: %s\n", procName);

  /* INOUT_PARAM is PS GENERAL WITH NULLS, so pass null indicators */
  if (inquarter < 0)
  {
    /* inquarter was negative, indicating a probable error,
       so pass a null value to the stored procedure instead
       by setting medSalaryInd to a negative value */
    inquarterInd = -1;
    sqlrcInd = -1;
    msgInd = -1;
  }
  else
  {
    /* inquarter was positive, so pass the value of inquarter
       to the stored procedure by setting inquarterInd to 0 */
    inquarterInd = 0;
    sqlrcInd = 0;
    msgInd = 0;
  }

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 1 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           &inquarter,
                           0,
                           &inquarterInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 2 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_OUTPUT,
                           SQL_C_LONG,
                           SQL_INTEGER,
                           0,
                           0,
                           &outSqlrc,
                           0,
                           &sqlrcInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter 3 to the statement */
  cliRC = SQLBindParameter(hstmt,
                           3,
                           SQL_PARAM_OUTPUT,
                           SQL_C_CHAR,
                           SQL_CHAR,
                           33,
                           0,
                           outMsg,
                           33,
                           &msgInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get number of result columns */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Result set returned %d columns\n", numCols);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, sales_person, 15, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, region, 15, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_SHORT, &sales.val, 0, &sales.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* check that the stored procedure executed successfully */
  if (outSqlrc == 0)
  {
    printf("Stored procedure returned successfully.\n");

    /* fetch result set returned from stored procedure */
    cliRC = SQLFetch(hstmt); 
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    printf("\nThe result set returned from %s", procName);
    printf("\n---SALES_PERSON---REGION-----------SALES--\n");
    while (cliRC != SQL_NO_DATA_FOUND) 
    {
      printf("  %-10s,    %-15s", sales_person, region);
      if (sales.ind > 0)
      {  
        printf(",  %-1d\n", sales.val);
      }
      else
      {
        printf(",  - \n");
      } 

      /* fetch next row */
      cliRC = SQLFetch(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }
  }
  else
  {
    printf("Stored procedure returned return code of %d\n", outSqlrc);
    printf("With Error: \"%s\".\n", outMsg);
  }

  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callGeneralWithNullsExample */
