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
** SOURCE FILE NAME: ilinfo.c
**
** SAMPLE: How to get information at the installation image level
**
** DB2CI FUNCTIONS USED:
**         OCIAttrGet -- Get attribute
**         OCIServerVersion - Server version
**         OCIClientVersion - Client version
**
** OUTPUT FILE: ilinfo.out (available in the online documentation)
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

int ServerImageInfoGet( OCISvcCtx * svchp, OCIError * errhp );
int ClientImageInfoGet( OCISvcCtx * svchp, OCIError * errhp );

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

  printf("\nTHIS SAMPLE SHOWS HOW TO GET INFORMATION \n");
  printf("AT THE INSTALLATION IMAGE LEVEL.\n");

  /* initialize the DB2CI application by calling a helper
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

  /* get server information */
  rc = ServerImageInfoGet(hdbc, errhp);
  /* get client information */
  rc = ClientImageInfoGet(hdbc, errhp);

  /* terminate the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppTerm(&henv, &hdbc, errhp, dbAlias);

  return rc;
} /* main */

/* get the name and version of the server */
int ServerImageInfoGet( OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  char imageInfoBuf[255]; /* buffer for image information */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIAttrGet\n");
  printf("  OCIServerVersion\n");
  printf("TO GET:\n");

  /* get server version information */
  ciRC = OCIServerVersion(
      svchp,
      errhp,
      imageInfoBuf,
      255,
      OCI_HTYPE_SVCCTX );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Server DBMS Version: %s\n", imageInfoBuf);

  return 0;
} /* ServerImageInfoGet */

/* get the name, version and conformance level of the client */
int ClientImageInfoGet( OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  sword major_version;
  sword minor_version;
  sword update_num;
  sword patch_num;
  sword port_update_num;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIClientVersion\n");
  printf("TO GET:\n");

  /* get client driver name information */
  OCIClientVersion(
    &major_version,
    &minor_version,
    &update_num,
    &patch_num,
    &port_update_num );

  printf("\n  Client DB2CI Driver Name   : %ld.%ld.%ld.%ld.%ld", (long)major_version, (long)minor_version, (long)update_num, (long)patch_num, (long)port_update_num );


  return 0;
} /* ClientImageInfoGet */

