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
** SOURCE FILE NAME: dbupgrade.c
**
** SAMPLE: Upgrade a database
**
** DB2 APIs USED:
**         db2DatabaseUpgrade -- UPGRADE DATABASE
**
** STRUCTURES USED:
**         sqlca
**
** OUTPUT FILE: dbupgrade.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlutil.h>
#include <db2ApiDf.h>
#include "utilapi.h"

int DbUpgrade(char *, char *, char *);

int main(int argc, char *argv[])
{
  int rc = 0;

  char dbAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char user[USERID_SZ + 1] = { 0 };
  char pswd[PSWD_SZ + 1] = { 0 };

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO UPGRADE A DATABASE.\n");

  rc = DbUpgrade(dbAlias, user, pswd);

  return 0;
} /* main */

int DbUpgrade(char dbAlias[], char user[], char pswd[])
{
  struct sqlca sqlca;
  db2DatabaseUpgradeStruct DatabaseUpgradeParam = { 0 };

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  db2DatabaseUpgrade -- UPGRADE DATABASE\n");
  printf("TO UPGRADE A DATABASE TO CURRENT FORMATS.\n");

  printf("\n  Upgrade the \"%s\" database.\n", dbAlias);

  DatabaseUpgradeParam.piDbAlias = dbAlias;
  DatabaseUpgradeParam.piUserName = user;
  DatabaseUpgradeParam.piPassword = pswd;
  DatabaseUpgradeParam.iDbAliasLen = SQL_ALIAS_SZ + 1;
  DatabaseUpgradeParam.iUserNameLen = USERID_SZ + 1;
  DatabaseUpgradeParam.iPasswordLen = PSWD_SZ + 1;

  /* upgrade the database */
  db2DatabaseUpgrade(db2Version970, &DatabaseUpgradeParam ,&sqlca); 
  if (sqlca.sqlcode != SQLE_RC_MIG_OK)
  {
    DB2_API_CHECK("Database -- Upgrade");
  }

  return 0;
} /* DbUpgrade */

