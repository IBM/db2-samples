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
** SOURCE FILE NAME: tbmod.c
**
** SAMPLE: How to modify table data
**
** CI FUNCTIONS USED:
**         OCIHandleAlloc -- Allocate Handle
**         OCIBindByPos     -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         OCITransCommit/OCITransRollback -- End Transactions of a Connection
**         OCIStmtExecute -- Execute a Statement
**         OCIStmtFetch -- Fetch Next Row
**         OCIHandleFree -- Free Handle Resources
**         OCIStmtPrepare -- Prepare a Statement
**         OCIAttrSet -- Set Connection Attributes
**
** OUTPUT FILE: tbmod.out (available in the online documentation)
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
#include "utilci.h" /* Header file for CI sample code */


/* methods to perform INSERT */
int TbBasicInsert( OCIEnv * envhp, OCISvcCtx * stmthp, OCIError * errhp );
int TbInsertWithParam( OCIEnv * envhp, OCISvcCtx * stmthp, OCIError * errhp );

/* methods to perform UPDATE */
int TbBasicUpdate( OCIEnv * envhp, OCISvcCtx * stmthp, OCIError * errhp );
int TbUpdateWithParam( OCIEnv * envhp, OCISvcCtx * stmthp, OCIError * errhp );

/* methods to perform DELETE */
int TbBasicDelete( OCIEnv * envhp, OCISvcCtx * stmthp, OCIError * errhp );
int TbDeleteWithParam( OCIEnv * envhp, OCISvcCtx * stmthp, OCIError * errhp );

int main(int argc, char *argv[])
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIEnv *  henv; /* environment handle */
  OCISvcCtx * hdbc; /* connection handle */
  OCIError * errhp; /* error handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO MODIFY TABLE DATA.\n");

  /* initialize the CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  &errhp );
  if (rc != 0)
  {
    return rc;
  }

  /* methods to perform INSERT */
  rc = TbBasicInsert( henv, hdbc, errhp );
  rc = TbInsertWithParam( henv, hdbc, errhp );

  /* methods to perform UPDATE */
  rc = TbBasicUpdate(henv, hdbc, errhp );
  rc = TbUpdateWithParam(henv, hdbc, errhp);

  /* methods to perform DELETE */
  rc = TbBasicDelete(henv, hdbc, errhp );
  rc = TbDeleteWithParam(henv, hdbc, errhp);

  /* terminate the CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppTerm(&henv, &hdbc, errhp, (char *)dbAlias);

  return rc;
} /* main */

/* perform a basic INSERT operation */
int TbBasicInsert( OCIEnv * henv, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt *  hstmt; /* statement handle */

  /* SQL INSERT statement to be executed */
  char *stmt = (char *)
    "INSERT INTO org(deptnumb, location) "
    "  VALUES(120, 'Toronto'), (130, 'Vancouver'), (140, 'Ottawa')";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A BASIC INSERT:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Directly execute the statement\n");
  printf("    INSERT INTO org(deptnumb, location)\n");
  printf("      VALUES(120, 'Toronto'),\n");
  printf("            (130, 'Vancouver'),\n");
  printf("            (140, 'Ottawa')\n");

  /* directly execute the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      hdbc,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  ciRC = OCITransRollback( hdbc, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbBasicInsert */

/* perform an INSERT operation with an SQL statement
   that contains parameter markers */
int TbInsertWithParam( OCIEnv * henv, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIBind * hBind1 = NULL;
  OCIBind * hBind2 = NULL;
  OCIStmt *  hstmt; /* statement handle */
  /* SQL INSERT statement with parameter markers to be executed */
  char *stmt = (char *)
    "INSERT INTO org(deptnumb, location) VALUES(:1, :2)";
  sb2 parameter1[] = { 120, 130, 140 };
  char parameter2[][20] = { "Toronto", "Vancouver", "Ottawa" };
  int row_array_size = 3;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CI FUNCTIONS\n");
  printf("  OCIHandleHandle\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIBindByPos\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO SHOW HOW TO EXECUTE AN INSERT STATEMENT\n");
  printf("WITH PARAMETERS:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Prepare the statement\n");
  printf("    INSERT INTO org(deptnumb, location) VALUES(:1, :2)\n");

  /* prepare the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Bind parameter1 and parameter2 to the statement.\n");

  /* bind parameter1 to the statement */
  ciRC = OCIBindByPos(
      hstmt,
      &hBind1,
      errhp,
      1,
      parameter1,
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

  /* execute the statement for a set of values */
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = { 120, 130, 140 }\n");
  printf("    parameter2 = { 'Toronto', 'Vancouver', 'Ottawa' }\n");

  /* execute the statement */
  ciRC = OCIStmtExecute(
      hdbc,
      hstmt,
      errhp,
      3,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  ciRC = OCITransRollback( hdbc, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbInsertWithParam */

/* perform a basic UDPATE operation */
int TbBasicUpdate( OCIEnv * henv, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */
  /* SQL UPDATE statement to be executed */
  char * stmt = (char *)
    "UPDATE org SET location = 'Toronto' WHERE deptnumb < 50";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A BASIC UPDATE:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Directly execute the statement\n");
  printf("    UPDATE org SET location = 'Toronto' WHERE deptnumb < 50\n");

  /* directly execute the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      hdbc,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  ciRC = OCITransRollback( hdbc, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbBasicUpdate */

/* perform an UPDATE operation with an SQL statement
   that contains parameter markers */
int TbUpdateWithParam( OCIEnv * henv, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIBind * hBind1 = NULL;
  OCIBind * hBind2 = NULL;
  OCIStmt * hstmt; /* statement handle */
  /* SQL UPDATE statement with parameter markers to be executed */
  char *stmt = (char *)
    "UPDATE org SET location =  :1 WHERE deptnumb < :2";
  char parameter1[20];
  sb2 parameter2;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIBindByPos\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO SHOW HOW TO EXECUTE AN UPDATE STATEMENT\n");
  printf("WITH PARAMETERS:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Prepare the statement\n");
  printf("    UPDATE org SET location = :1 WHERE deptnumb < :2\n");

  /* prepare the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Bind parameter1 and parameter2 to the statement.\n");

  /* bind parameter1 to the statement */
  ciRC = OCIBindByPos(
      hstmt,
      &hBind1,
      errhp,
      1,
      parameter1,
      20,
      SQLT_STR,
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
      &parameter2,
      sizeof( sb2 ),
      SQLT_INT,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* execute the statement for a set of values  */
  strcpy((char *)parameter1, "Toronto");
  parameter2 = 50;

  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = %s\n", parameter1);
  printf("    parameter2 = %d\n", parameter2);

  /* execute the statement */
  ciRC = OCIStmtExecute(
      hdbc,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  ciRC = OCITransRollback( hdbc, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbUpdateWithParam */

/* perform a basic DELETE operation */
int TbBasicDelete( OCIEnv * henv, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */
  /* SQL DELETE statement to be executed */
  char *stmt = (char *)"DELETE FROM org WHERE deptnumb < 50";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A BASIC DELETE:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)henv, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      hdbc,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  ciRC = OCITransRollback( hdbc, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbBasicDelete */

/* perform a DELETE operation with an SQL statement
   that contains parameter markers */
int TbDeleteWithParam( OCIEnv * henv, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIBind * hBind = NULL;
  OCIStmt * hstmt; /* statement handle */
  /* SQL DELETE statement with parameter markers to be executed */
  char *stmt = (char *)"DELETE FROM org WHERE deptnumb < :deptnumb";
  sb2 parameter1;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIBindByName\n");
  printf("  OCIStmtExecute\n");
  printf("  OCITransRollback\n");
  printf("  OCIHandleFree\n");
  printf("TO SHOW HOW TO EXECUTE A DELETE STATEMENT\n");
  printf("WITH NAMED PARAMETERS:\n");

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

  printf("\n  Bind parameter1 to the statement.\n");

  /* bind parameter1 to the statement */
  ciRC = OCIBindByName(
      hstmt,
      &hBind,
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

  /* execute the statement for parameter1 = 50  */
  parameter1 = 50;
  printf("\n  Execute the prepared statement for\n");
  printf("    parameter1 = %d\n", parameter1);

  /* execute the statement */
  ciRC = OCIStmtExecute(
      hdbc,
      hstmt,
      errhp,
      1,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  ciRC = OCITransRollback( hdbc, errhp, OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbDeleteWithParam */

