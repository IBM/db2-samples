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
** SOURCE FILE NAME: tbcompress.c
**
** SAMPLE: How to create tables with null and default value compression
**         option
**
** DB2CI FUNCTIONS USED:
**         OCIHandleAlloc -- Allocate Handle
**         OCIStmtPrepare - Prepare an SQL statement
**         OCIStmtExecute - Execute an SQL statement
**         OCIStmtFetch -- Fetch Next Row
**         OCIHandleFree -- Free Handle Resources
**
** OUTPUT FILE: tbcompress.out (available in the online documentation)
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
int TbCompress( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp );
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

  /* checks the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO USE NULL AND DEFAULT VALUE\n");
  printf("COMPRESSION OPTION AT TABLE LEVEL AND COLUMN LEVEL.\n");

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

  /* create the table */
  rc = TbCreate( envhp, svchp, errhp );

  /* enable the compression option at table level */
  rc = TbCompress( envhp, svchp, errhp );

  /* drop the table */
  rc = TbDrop( envhp, svchp, errhp );

  /* terminate the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppTerm(&envhp, &svchp, errhp, dbAlias);

  return rc;
} /* main */

/* create the comp_tab table */
int TbCreate( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */

  char *stmt =
    (char *)"CREATE TABLE COMP_TAB(Col1 INT NOT NULL WITH DEFAULT, "
               "Col2 CHAR(7), "
               "Col3 VARCHAR(7) NOT NULL, "
               "Col4 DOUBLE)";

  printf("\n-----------------------------------------------------------");
  printf("\nCreating table COMP_TAB\n\n");
  printf("USE THE DB2CI FUNCTIONS\n");
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
  printf("    CREATE TABLE COMP_TAB(Col1 INT NOT NULL WITH DEFAULT,\n");
  printf("                          Col2 CHAR(7),\n");
  printf("                          Col3 VARCHAR(7) NOT NULL,\n");
  printf("                          Col4 DOUBLE)\n");

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

/* how to enable the compress option on table level */
int TbCompress( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */

  char *stmt1 = (char *)"ALTER TABLE COMP_TAB ACTIVATE "
                              "VALUE COMPRESSION";
  char *stmt2 = (char *)"ALTER TABLE COMP_TAB ALTER Col1 COMPRESS "
                              "SYSTEM DEFAULT";
  char *stmt3 = (char *)"ALTER TABLE COMP_TAB DEACTIVATE "
                              "VALUE COMPRESSION";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCIHandleFree\n");
  printf("TO SHOW HOW TO ALTER A TABLE FOR COMPRESSION OPTION:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n To activate VALUE COMPRESSION at table level and COMPRESS \n");
  printf(" SYSTEM DEFAULT at column level \n\n");

  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE COMP_TAB ACTIVATE VALUE COMPRESSION \n\n");
  printf(" Rows will be formatted using the new row format on subsequent\n");
  printf(" insert, load and update operation, and NULL values will not be\n");
  printf(" taking up space if applicable.\n\n");

  /* If the table COMP_TAB does not have many NULL values, enabling
     compression will result in using more disk space than using
     the old row format */

  /* directly execute the statement */
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

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n To save more disk space on system default value for column\n");
  printf(" Col1, enter\n");

  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE COMP_TAB ALTER Col1 COMPRESS SYSTEM DEFAULT\n");
  printf("\n On subsequent insert, load, and update operations,numerical\n");
  printf(" 0 value (occupying 4 bytes of storage) for column Col1 will\n");
  printf(" not be saved on disk.\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* directly execute the statement */
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

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n\n To switch the table to use the old format, enter\n");
  printf("\n  Directly execute the statement\n");
  printf("    ALTER TABLE COMP_TAB DEACTIVATE VALUE COMPRESSION\n\n");
  printf(" Rows inserted, loaded or updated after the ALTER statement\n");
  printf(" will have old row format.\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* directly execute the statement */
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

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbCompress */

/* drop the table comp_tab */
int TbDrop( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */

  char *stmt = (char *)"DROP TABLE COMP_TAB";

  printf("\n-----------------------------------------------------------");
  printf("\nDropping table COMP_TAB\n\n");
  printf("USE THE DB2CI FUNCTIONS\n");
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
