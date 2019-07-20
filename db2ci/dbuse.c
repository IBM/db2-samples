/****************************************************************************
** (c) Copyright IBM Corp. 2009 All rights reserved.
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
** SOURCE FILE NAME: dbuse.c
**
** SAMPLE: How to use a database
**
**         This sample demonstrates how to execute different types of SQL
**         statements in various ways, including executing compound SQL and
**         binding parameters.  It also shows numerous ways descriptors
**         can be used.
**
** DB2CI FUNCTIONS USED:
**         OCIEnvCreate - Allocates an environment handle.
**         OCIHandleAlloc -- Allocate Handle
**         OCIDefineByPos -- Bind a Column to an Application Variable or
**                       LOB locator
**         OCIBindByPos -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         OCITransRollback -- End Transactions of a Connection
**         OCIStmtPrepare - Prepares an SQL statement
**         OCIStmtExecute -- Execute a Statement
**         OCIStmtFetch -- Fetch Next Row
**         OCIHandleFree -- Free Handle Resources
**         OCITerminate - Ends the OCI processing
**         OCIAttrGet -- Get Number of Result Columns
**         OCIAttrSet -- Set Connection Attributes
**
** OUTPUT FILE: dbuse.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
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
#include <db2ci.h>
#include "utilci.h" /* Header file for DB2CI sample code */

int ConnExecTransact( OCIEnv * henv, OCISvcCtx * ctxh, OCIError * errhp );
int StmtBindByPos( OCIEnv * henv, OCISvcCtx * ctxh, OCIError * errhp );
int StmtExecute( OCIEnv * henv, OCISvcCtx * ctxh, OCIError * errhp );

int main(int argc, char *argv[])
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIEnv * henv = NULL; /* environment handle */
  OCISvcCtx * svchp = NULL; /* connection handle */
  OCIError * errhp = NULL; /* error handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO USE A DATABASE.\n");

  /* initialize the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &svchp,
                  &errhp );
  if (rc != 0)
  {
    return rc;
  }

  /* perform transactions on one connection */
  rc = ConnExecTransact(henv, svchp, errhp);

  /* bind parameters to an SQL statement */
  rc = StmtBindByPos(henv, svchp, errhp);

  /* prepare and execute an SQL statement */
  rc = StmtExecute(henv, svchp, errhp);

  /* terminate the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppTerm(&henv, &svchp, errhp, dbAlias);

  return rc;
} /* main */

/* perform transactions on one connection */
int ConnExecTransact( OCIEnv * henv, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt *  hstmt; /* statement handle */
  /* SQL statements to be executed */
  char *stmt1 = (char *)"CREATE TABLE table1(col1 INTEGER)";
  char *stmt2 = (char *)"CREATE TABLE table2(col1 INTEGER)";
  char *stmt3 = (char *)"DROP TABLE table1";
  char *stmt4 = (char *)"DROP TABLE table2";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransCommit\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A TRANSACTION ON ONE CONNECTION:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Perform a transaction on this connection\n");

  printf("    executing %s...\n", stmt1);

  /* directly execute statement 1 */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt1,
      strlen( stmt1 ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("    executing %s...\n", stmt2);

  /* directly execute statement 2 */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt2,
      strlen( stmt2 ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Committing the transaction...\n");

  /* end the transactions on the connection */
  ciRC = OCITransCommit( svchp, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction committed.\n");

  printf("\n  Perform another transaction on this connection\n");

  printf("    executing %s...\n", stmt3);

  /* directly execute statement 3 */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt3,
      strlen( stmt3 ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* directly execute statement 4 */
  printf("    executing %s...\n", stmt4);
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt4,
      strlen( stmt4 ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Committing the transaction...\n");

  /* end the transactions on the connection */
  ciRC = OCITransCommit( svchp, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction committed.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* ConnExecTransact */

/* bind parameters to an SQL statement */
int StmtBindByPos( OCIEnv * henv, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIBind * hBind1 = NULL;
  OCIBind * hBind2 = NULL;
  OCIStmt * hstmt; /* statement handle */
  /* SQL statement to be executed, containing parameter markers */
  char *stmt = (char *)
    "DELETE FROM org WHERE deptnumb = :1 AND division = :2 ";
  sb2 parameter1 = 0;

  char parameter2[20];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIBindByPos\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO BIND PARAMETERS TO AN SQL STATEMENT:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* prepare the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );

  printf("\n  Bind parameter1 and parameter2 to the statement\n");
  printf("    %s\n", stmt);

  /* bind parameter1 to the statement */
  ciRC = OCIBindByPos(
      hstmt,
      &hBind1,
      errhp,
      1,
      &parameter1,
      sizeof( sb2 ),
      SQLT_INT,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* bind parameter2 to the statement */
  ciRC = OCIBindByPos(
      hstmt,
      &hBind2,
      errhp,
      2,
      parameter2,
      20,
      SQLT_STR,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* execute the statement for parameter1 = 15 and parameter2 = 'Eastern' */
  printf("\n  Execute the statement for\n");
  printf("    parameter1 = 15 and parameter2 = 'Eastern'\n");
  parameter1 = 15;
  strcpy(parameter2, "Eastern");

  /* directly execute the statement */
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* execute the statement for parameter1 = 84 and parameter2 = 'Western' */
  printf("\n  Execute the statement for\n");
  printf("    parameter1 = 84 and parameter2 = 'Western'\n");
  parameter1 = 84;
  strcpy(parameter2, "Western");

  /* directly execute the statement */
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  ciRC = OCITransRollback( svchp, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* StmtBindByPos */

/* prepare and execute an SQL statement with bound parameters */
int StmtExecute( OCIEnv * henv, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIBind * hBind1 = NULL;
  OCIStmt * hstmt; /* statement handle */
  /* SQL statement to be executed, containing a parameter marker */
  char *stmt = (char *)"DELETE FROM org WHERE deptnumb = :deptnumb ";
  sb2 parameter1 = 0;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIBindByName\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO EXECUTE A PREPARED SQL STATEMENT:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt);

  /* prepare the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Bind parameter1 to the statement\n");
  printf("    %s\n", stmt);

  /* bind parameter1 to the statement */
  ciRC = OCIBindByName(
      hstmt,
      &hBind1,
      errhp,
      ":deptnumb",
      strlen( ":deptnumb" ),
      &parameter1,
      sizeof( sb2 ),
      SQLT_INT,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* execute the statement for parameter1 = 15 */
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = 15\n");
  parameter1 = 15;

  /* execute the statement */
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* execute the statement for parameter1 = 84 */
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = 84\n");
  parameter1 = 84;

  /* execute the statement */
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end the transactions on the connection */
  ciRC = OCITransRollback( svchp, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("    Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* StmtExecute */

