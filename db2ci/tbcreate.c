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
** SOURCE FILE NAME: tbcreate.c
**
** SAMPLE: How to create and drop tables
**
** DB2CI FUNCTIONS USED:
**         OCIHandleAlloc -- Allocate Handle
**         OCIStmtPrepare -- Prepare a SQL statement
**         OCIStmtExecute -- Execute a SQL statement
**         OCIHandleFree -- Free Handle Resources
**
** OUTPUT FILE: tbcreate.out (available in the online documentation)
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

int TbCreate( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp );
int TbDrop( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp );

int main(int argc, char *argv[])
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIEnv * envhp; /* environment handle */
  OCISvcCtx * svchp; /* connection handle */
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

  printf("\nTHIS SAMPLE SHOWS HOW TO CREATE AND DROP TABLES.\n");

  /* initialize the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppInit(dbAlias,
                  user,
                  pswd,
                  &envhp,
                  &svchp,
                  &errhp );
  if (rc != 0)
  {
    return rc;
  }

  /* create a table */
  rc = TbCreate( envhp, svchp, errhp );
  /* drop a table */
  rc = TbDrop( envhp, svchp, errhp );

  /* terminate the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppTerm(&envhp, &svchp, errhp, dbAlias);

  return rc;
} /* main */

/* create a table */
int TbCreate( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */

  char *stmt = (char *)"CREATE TABLE TBDEFINE(Col1 SMALLINT, "
                             "                      Col2 CHAR(7), "
                             "                      Col3 VARCHAR(7), "
                             "                      Col4 DEC(9,2), "
                             "                      Col5 DATE, "
                             "                      Col6 BLOB(5000), "
                             "                      Col7 CLOB(5000))";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCIHandleFree\n");
  printf("TO SHOW HOW TO CREATE A TABLE:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* create the table */
  printf("\n  Directly execute the statement\n");
  printf("    CREATE TABLE TBDEFINE(Col1 SMALLINT,\n");
  printf("                          Col2 CHAR(7),\n");
  printf("                          Col3 VARCHAR(7),\n");
  printf("                          Col4 DEC(9,2),\n");
  printf("                          Col5 DATE,\n");
  printf("                          Col6 BLOB(5000),\n");
  printf("                          Col7 CLOB(5000))\n");

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
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbCreate */

/* drop a table */
int TbDrop( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */

  char *stmt = (char *)"DROP TABLE TBDEFINE";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCIHandleFree\n");
  printf("TO SHOW HOW TO DROP A TABLE:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* drop the table */
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
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbDrop */

