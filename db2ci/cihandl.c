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
** SOURCE FILE NAME: cihandl.c
**
** SAMPLE: How to allocate and free handles
**
**    DB2CI FUNCTIONS USED:
**         OCIHandleAlloc -- Allocate Handle
**         OCILogon -- Connect to a Data Source
**         OCILogoff -- Disconnect from a Data Source
**         OCIHandleFree -- Free Handle Resources
**         OCIEnvCreate -- Allocate an environment handle.
**         OCITerminate -- Terminates OCI
**
** OUTPUT FILE: cihandl.out (available in the online documentation)
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

int main(int argc, char *argv[])
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIEnv * henv; /* environment handle */
  OCISvcCtx * hdbc; /* connection handle */
  OCIStmt * hstmt; /* statement handle */
  OCIError * errhp; /* error handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return 1;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO ALLOCATE AND FREE HANDLES.\n");

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIEnvCreate\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCILogon\n");
  printf("  OCILogoff\n");
  printf("  OCIHandleFree\n");
  printf("  OCITerminate\n");
  printf("TO ALLOCATE AND FREE HANDLES:\n");

  printf("\n  Allocate an environment handle.\n");

  /* allocate an environment handle */
  ciRC = OCIEnvCreate( (OCIEnv **)&henv, OCI_OBJECT, NULL, NULL, NULL, NULL, 0, NULL );
  if (ciRC != OCI_SUCCESS)
  {
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  ciRC = %d\n", ciRC);
    printf("  line  = %d\n", __LINE__);
    printf("  file  = %s\n", __FILE__);
    return 1;
  }


  /* allocate an error handle */
  ciRC = OCIHandleAlloc( henv, (dvoid *)&errhp, OCI_HTYPE_ERROR, 0, NULL );
  ENV_HANDLE_CHECK(henv, ciRC);

  printf("\n  Allocate a database connection handle.\n");

  /* allocate a database connection handle */

  ciRC = OCIHandleAlloc( henv, (dvoid *)&hdbc, OCI_HTYPE_SVCCTX, 0, NULL );
  ENV_HANDLE_CHECK(henv, ciRC);

  printf("\n  Connecting to the database %s...\n", dbAlias);

  /* connect to the database */
  ciRC = OCILogon( henv,
                   errhp,
                   &hdbc,
                     (OraText *)user,
                     strlen( (char *)user ),
                     (OraText *)pswd,
                     strlen( (char *)pswd ),
                     (OraText *)dbAlias,
                     strlen( (char *)dbAlias ));
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Connected to the database %s.\n", dbAlias);

  printf("\n  Allocate a statement handle.\n");

  /* allocate one or more statement handles */
  ciRC = OCIHandleAlloc( henv, (dvoid *)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ENV_HANDLE_CHECK(henv, ciRC);

  /*********   Start using the statement handles *******************/

  /******      Insert any transaction processing here    ***********/

  /*********   Stop using the statement handles ********************/

  printf("  Free the statement handle.\n");

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ENV_HANDLE_CHECK(henv, ciRC);

  printf("\n  Disconnecting from the database %s...\n", dbAlias);

  /* disconnect from the database */
  ciRC = OCILogoff( hdbc, errhp );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Disconnected from the database %s.\n", dbAlias);

  printf("\n  Free the connection handle.\n");

  /* free the connection handle */
  ciRC = OCIHandleFree( hdbc, OCI_HTYPE_SVCCTX );
  ENV_HANDLE_CHECK(henv, ciRC);

  printf("\n  Free the environment handle.\n");

  /* free the environment handle */
  ciRC = OCIHandleFree( henv, OCI_HTYPE_ENV );
  ENV_HANDLE_CHECK(henv, ciRC);
  (void)OCITerminate( OCI_DEFAULT );

  return 0;
} /* main */

