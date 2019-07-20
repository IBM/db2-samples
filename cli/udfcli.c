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
** SOURCE FILE NAME: udfcli.c                                       
**                                                                        
** SAMPLE: How to work with different types of user-defined functions (UDFs)
**
**         This client application uses the UDFs defined in udfsrv.c.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLCloseCursor -- Close Cursor and Discard Pending Results
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: udfcli.out (available in the online documentation)
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
#include "utilcli.h" /* header file for CLI sample code */

int ExternalScalarUDFUse(SQLHANDLE);
int ExternalScratchpadScalarUDFUse(SQLHANDLE);
int ExternalClobScalarUDFUse(SQLHANDLE);
int ExternalScalarUDFReturningErrorUse(SQLHANDLE);
int SourcedScalarUDFUse(SQLHANDLE);
int SourcedColumnUDFUse(SQLHANDLE);
int ExternalTableUDFUse(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO WORK WITH UDFs.\n");

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

  rc = ExternalScalarUDFUse(hdbc);
  rc = ExternalScratchpadScalarUDFUse(hdbc);
  rc = ExternalClobScalarUDFUse(hdbc);
  rc = ExternalScalarUDFReturningErrorUse(hdbc);
  rc = SourcedColumnUDFUse(hdbc);
  rc = ExternalTableUDFUse(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* register and use a scalar UDF */
int ExternalScalarUDFUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmtDrop = (SQLCHAR *)"DROP FUNCTION ScalarUDF";
  SQLCHAR *stmtRegister =
    (SQLCHAR *)"  CREATE FUNCTION ScalarUDF(CHAR(5), DOUBLE) "
               "    RETURNS DOUBLE "
               "    EXTERNAL NAME 'udfsrv!ScalarUDF' "
               "    FENCED "
               "    CALLED ON NULL INPUT "
               "    NOT VARIANT "
               "    NO SQL "
               "    PARAMETER STYLE DB2SQL "
               "    LANGUAGE C "
               "    NO EXTERNAL ACTION";
  SQLCHAR *stmtSelect =
    (SQLCHAR *)"  SELECT name, job, salary, ScalarUDF(job, salary)"
               "    FROM staff "
               "    WHERE name LIKE 'S%'";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  name, job;

  struct
  {
    SQLINTEGER ind;
    SQLDOUBLE val;
  }
  salary, newSalary;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO WORK WITH SCALAR UDFS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);

  printf("\n  Register the scalar UDF.\n");

  /* directly execute the UDF registration */
  cliRC = SQLExecDirect(hstmt, stmtRegister, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Use the scalar UDF:\n");
  printf("    SELECT name, job, salary, ScalarUDF(job, salary)\n");
  printf("      FROM staff\n");
  printf("      WHERE name LIKE 'S%%'\n");

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmt, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to a variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, name.val, 15, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to a variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, job.val, 15, &job.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to a variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_DOUBLE,
                     &salary.val,
                     sizeof(salary.val),
                     &salary.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to a variable */
  cliRC = SQLBindCol(hstmt,
                     4,
                     SQL_C_DOUBLE,
                     &newSalary.val,
                     sizeof(newSalary.val),
                     &newSalary.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    NAME       JOB     SALARY   NEW_SALARY\n");
  printf("    ---------- ------- -------- ----------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-10s %-7s %-7.2f %-7.2f\n",
           name.val, job.val, salary.val, newSalary.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* ExternalScalarUDFUse */

/* register and use a scalar UDF with a scratchpad */
int ExternalScratchpadScalarUDFUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmtDrop = (SQLCHAR *)"DROP FUNCTION ScratchpadScUDF";
  SQLCHAR *stmtRegister =
    (SQLCHAR *)"  CREATE FUNCTION ScratchpadScUDF() "
               "    RETURNS INTEGER "
               "    EXTERNAL NAME 'udfsrv!ScratchpadScUDF' "
               "    FENCED "
               "    SCRATCHPAD 10 "
               "    FINAL CALL "
               "    VARIANT "
               "    NO SQL "
               "    PARAMETER STYLE DB2SQL "
               "    LANGUAGE C "
               "    NO EXTERNAL ACTION";
  SQLCHAR *stmtSelect =
    (SQLCHAR *)"  SELECT ScratchpadScUDF(), name, job "
               "    FROM staff "
               "    WHERE name LIKE 'S%'";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  name, job;

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  counter;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO WORK WITH SCALAR UDFs AND SCRATCHPADS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);

  printf("\n  Register the scalar UDF.\n");

  /* directly execute the registration */
  cliRC = SQLExecDirect(hstmt, stmtRegister, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Use the SCRATCHPAD scalar UDF:\n");
  printf("    SELECT ScratchpadScUDF(), name, job\n");
  printf("      FROM staff\n");
  printf("      WHERE name LIKE 'S%%'\n");

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmt, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to a variable */
  cliRC = SQLBindCol(hstmt,
                     1,
                     SQL_C_LONG,
                     &counter.val,
                     sizeof(counter.val),
                     &counter.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to a variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, name.val, 15, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to a variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, job.val, 15, &job.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    COUNTER NAME       JOB    \n");
  printf("    ------- ---------- -------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %7d %-10s %-7s\n", counter.val, name.val, job.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* ExternalScratchpadScalarUDFUse */

/* register and use a scalar UDF with CLOB data */
int ExternalClobScalarUDFUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmtDrop = (SQLCHAR *)"DROP FUNCTION ClobScalarUDF";
  SQLCHAR *stmtRegister =
    (SQLCHAR *)"  CREATE FUNCTION ClobScalarUDF(CLOB(5K)) "
               "    RETURNS INTEGER "
               "    EXTERNAL NAME 'udfsrv!ClobScalarUDF' "
               "    FENCED "
               "    NOT VARIANT "
               "    NO SQL "
               "    PARAMETER STYLE DB2SQL "
               "    LANGUAGE C "
               "    NO EXTERNAL ACTION";

  SQLCHAR *stmtSelect =
    (SQLCHAR *)"  SELECT empno, resume_format, ClobScalarUDF(resume)"
               "    FROM emp_resume "
               "    WHERE resume_format = 'ascii'";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  empno, resume_format;

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  numWords;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO WORK WITH SCALAR UDFS AND CLOB DATA:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);

  printf("\n  Register the scalar UDF.\n");

  /* directly execute the registration */
  cliRC = SQLExecDirect(hstmt, stmtRegister, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Use the scalar UDF with CLOB:\n");
  printf("    SELECT empno, resume_format, ClobScalarUDF(resume)\n");
  printf("      FROM emp_resume\n");
  printf("      WHERE resume_format = 'ascii'\n");

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmt, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to a variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, empno.val, 15, &empno.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to a variable */
  cliRC = SQLBindCol(hstmt,
                     2,
                     SQL_C_CHAR,
                     resume_format.val,
                     15,
                     &resume_format.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to a variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_LONG,
                     &numWords.val,
                     sizeof(numWords.val),
                     &numWords.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    EMPNO   RESUME_FORMAT NUM.WORDS\n");
  printf("    ------- ------------- ---------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-7s %-13s %ld\n",
           empno.val, resume_format.val, numWords.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* ExternalClobScalarUDFUse */

/* register and try to use a scalar UDF that generates an error */
int ExternalScalarUDFReturningErrorUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmtDrop = (SQLCHAR *)"DROP FUNCTION ScUDFReturningErr";
  SQLCHAR *stmtRegister =
    (SQLCHAR *)"  CREATE FUNCTION ScUDFReturningErr(DOUBLE, DOUBLE) "
               "    RETURNS DOUBLE "
               "    EXTERNAL NAME 'udfsrv!ScUDFReturningErr' "
               "    FENCED "
               "    NOT VARIANT "
               "    NO SQL "
               "    PARAMETER STYLE DB2SQL"
               "    LANGUAGE C "
               "    NO EXTERNAL ACTION";

  SQLCHAR *stmtSelect =
    (SQLCHAR *)"  SELECT name, job, ScUDFReturningErr(salary, 0.00) "
               "    FROM staff "
               "    WHERE name LIKE 'S%'";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  name, job;

  struct
  {
    SQLINTEGER ind;
    SQLDOUBLE val;
  }
  comm;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO WORK WITH SCALAR UDFS THAT RETURN ERRORS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);

  printf("\n  Register the scalar UDF.\n");

  /* directly execute the registration */
  cliRC = SQLExecDirect(hstmt, stmtRegister, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Use the scalar UDF that returns error:\n");
  printf("    SELECT name, job, ScUDFReturningErr(salary, 0.00)\n");
  printf("      FROM staff\n");
  printf("      WHERE name LIKE 'S%%'\n");

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmt, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to a variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, name.val, 15, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to a variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, job.val, 15, &job.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to a variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_DOUBLE,
                     &comm.val,
                     sizeof(comm.val),
                     &comm.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    NAME       JOB     COMM    \n");
  printf("    ---------- ------- --------\n");
  printf("\n-- The following error report is expected! --");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-10s %-7s %-7.2f\n", name.val, job.val, comm.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return 0;
} /* ExternalScalarUDFReturningErrorUse */

/* use a sourced column UDF */
int SourcedColumnUDFUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmt1 =
    (SQLCHAR *)"CREATE DISTINCT TYPE CNUM AS INTEGER WITH COMPARISONS";
  SQLCHAR *stmt2 = (SQLCHAR *)
    "CREATE FUNCTION MAX(CNUM) RETURNS CNUM source sysibm.max(integer)";
  SQLCHAR *stmt3 =
    (SQLCHAR *)"CREATE TABLE CUSTOMER_TABLE(CustNum CNUM NOT NULL, "
               "                      CustName CHAR(30) NOT NULL)";
  SQLCHAR *stmt4 = (SQLCHAR *)
    "INSERT INTO CUSTOMER_TABLE VALUES(CAST(1 AS CNUM), 'JOHN WALKER'), "
    "                           (CAST(2 AS CNUM), 'BRUCE ADAMSON'), "
    "                           (CAST(3 AS CNUM), 'SALLY KWAN')";
  SQLCHAR *stmt5 =
    (SQLCHAR *)"SELECT CAST(MAX(CustNum) AS INTEGER) FROM CUSTOMER_TABLE";
  SQLCHAR *stmt6 = (SQLCHAR *)"DROP TABLE CUSTOMER_TABLE";
  SQLCHAR *stmt7 = (SQLCHAR *)"DROP FUNCTION MAX(CNUM)";
  SQLCHAR *stmt8 = (SQLCHAR *)"DROP DISTINCT TYPE CNUM";

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  maxCustNum;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO WORK WITH SOURCED COLUMN UDFS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute \n");
  printf("    CREATE DISTINCT TYPE CNUM AS INTEGER WITH COMPARISONS\n");

  /* create a distinct type */
  cliRC = SQLExecDirect(hstmt, stmt1, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Directly execute \n");
  printf("    CREATE FUNCTION MAX(CNUM) RETURNS CNUM ");
  printf("source sysibm.max(integer)\n");

  /* create a sourced UDF */
  cliRC = SQLExecDirect(hstmt, stmt2, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Directly execute \n");
  printf("    CREATE TABLE CUSTOMER_TABLE(CustNum CNUM NOT NULL,\n");
  printf("                          CustName CHAR(30) NOT NULL)\n");

  /* create a table that uses the distinct type */
  cliRC = SQLExecDirect(hstmt, stmt3, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* insert values into the table */
  printf("\n  Directly execute \n");
  printf("    INSERT INTO CUSTOMER_TABLE VALUES");
  printf("(CAST(1 AS CNUM), 'JOHN WALKER'),\n");
  printf("                               ");
  printf("(CAST(2 AS CNUM), 'BRUCE ADAMSON'),\n");
  printf("                               ");
  printf("(CAST(3 AS CNUM), 'SALLY KWAN')\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt4, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Use the sourced column UDF:\n");
  printf("    SELECT FROM CUSTOMER_TABLE CAST(MAX(CUSTNUM) AS INTEGER)\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt5, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the column to a variable */
  cliRC = SQLBindCol(hstmt,
                     1,
                     SQL_C_LONG,
                     &maxCustNum.val,
                     sizeof(maxCustNum.val),
                     &maxCustNum.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch the result.\n");

  /* fetch the result */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  else
  {
    printf("    Max(CustNum) is: %-8d \n", maxCustNum.val);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the table */
  printf("\n  Directly execute \n");
  printf("    %s\n", stmt6);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt6, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the sourced UDF */
  printf("\n  Directly execute \n");
  printf("    %s\n", stmt7);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt7, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* drop the distinct type */
  printf("\n  Directly execute \n");
  printf("    %s\n", stmt8);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt8, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* SourcedColumnUDFUse */

/* register and use a table UDF */
int ExternalTableUDFUse(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  /* SQL statements to be executed */
  SQLCHAR *stmtDrop = (SQLCHAR *)"DROP FUNCTION TableUDF";
  SQLCHAR *stmtRegister =
    (SQLCHAR *)"  CREATE FUNCTION TableUDF(DOUBLE) "
               "    RETURNS TABLE(name VARCHAR(20), "
               "                  job VARCHAR(20), "
               "                  salary DOUBLE) "
               "    EXTERNAL NAME 'udfsrv!TableUDF' "
               "    LANGUAGE C "
               "    PARAMETER STYLE DB2SQL "
               "    NOT DETERMINISTIC "
               "    FENCED "
               "    NO SQL "
               "    NO EXTERNAL ACTION "
               "    SCRATCHPAD 10 "
               "    FINAL CALL "
               "    DISALLOW PARALLEL "
               "    NO DBINFO ";
  SQLCHAR *stmtSelect = (SQLCHAR *)
    (SQLCHAR *)"  SELECT udfTable.name, udfTable.job, udfTable.salary "
               "    FROM TABLE(TableUDF(1.5)) AS udfTable";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[15];
  }
  name, job;

  struct
  {
    SQLINTEGER ind;
    SQLDOUBLE val;
  }
  salary;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLFreeHandle\n");
  printf("TO WORK WITH TABLE UDFS:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);

  printf("\n  Register the table UDF.\n");

  /* directly execute the registration */
  cliRC = SQLExecDirect(hstmt, stmtRegister, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Use the table UDF:\n");
  printf("    SELECT udfTable.name, udfTable.job, udfTable.salary\n");
  printf("      FROM TABLE(TableUDF(1.5)) AS udfTable\n");

  /* directly execute the SELECT statement */
  cliRC = SQLExecDirect(hstmt, stmtSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to a variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, name.val, 15, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to a variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, job.val, 15, &job.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to a variable */
  cliRC = SQLBindCol(hstmt,
                     3,
                     SQL_C_DOUBLE,
                     &salary.val,
                     sizeof(salary.val),
                     &salary.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    NAME           JOB     SALARY   \n");
  printf("    ----------     ------- ---------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-14s %-7s", name.val, job.val);
    if (salary.ind >= 0)
    {
      printf(" %7.2f", salary.val);
    }
    else
    {
      printf(" %-8s", "-");
    }
    printf("\n");

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* directly execute the DROP statement */
  cliRC = SQLExecDirect(hstmt, stmtDrop, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return 0;
} /* ExternalTableUDFUse */

