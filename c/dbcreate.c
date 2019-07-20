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
** SOURCE FILE NAME: dbcreate.c
**
** SAMPLE: Create and drop databases
**
** DB2 APIs USED:
**         sqlecrea -- CREATE DATABASE
**         sqledrpd -- DROP DATABASE
**      
** STRUCTURES USED:
**         sqlca
**         SQLEDBTERRITORYINFO
**         sqledbdesc
**
** OUTPUT FILE: dbcreate.out (available in the online documentation)
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
#include <sqle819a.h>
#include <sqlutil.h>
#include <sqlenv.h>
#include "utilapi.h"

int DbCreate(void);
int DbDrop(void);

int main(int argc, char *argv[])
{
  int rc = 0;
  char nodeName[SQL_INSTNAME_SZ + 1];
  char user[USERID_SZ + 1];
  char pswd[PSWD_SZ + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck2(argc, argv, nodeName, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO CREATE/DROP A DATABASE.\n");

  /* attach to a local or remote instance */
  rc = InstanceAttach(nodeName, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  rc = DbCreate();
  rc = DbDrop();

  /* detach from the local or remote instance */
  rc = InstanceDetach(nodeName);
  if (rc != 0)
  {
    return rc;
  }

  return 0;
} /* main */

int DbCreate(void)
{
  struct sqlca sqlca;
  char dbName[SQL_DBNAME_SZ + 1];
  char dbLocalAlias[SQL_ALIAS_SZ + 1];
  char dbPath[SQL_PATH_SZ + 1];
  struct sqledbdesc dbDescriptor;
  SQLEDBTERRITORYINFO territoryInfo;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  sqlecrea -- CREATE DATABASE\n");
  printf("TO CREATE A NEW DATABASE:\n");

  /* create a new database */
  strcpy(dbName, "dbcreate");
  strcpy(dbLocalAlias, "dbcreate");
  strcpy(dbPath, "");

  strcpy(dbDescriptor.sqldbdid, SQLE_DBDESC_2);
  dbDescriptor.sqldbccp = 0;
  dbDescriptor.sqldbcss = SQL_CS_USER;
  memcpy(dbDescriptor.sqldbudc, sqle_819_500, SQL_CS_SZ);
  strcpy(dbDescriptor.sqldbcmt, "comment for database");
  dbDescriptor.sqldbsgp = 0;
  dbDescriptor.sqldbnsg = 10;
  dbDescriptor.sqltsext = -1;
  dbDescriptor.sqlcatts = NULL;
  dbDescriptor.sqlusrts = NULL;
  dbDescriptor.sqltmpts = NULL;

  strcpy(territoryInfo.sqldbcodeset, "ISO8859-1");
  strcpy(territoryInfo.sqldblocale, "C");

  printf("\n  Create a [remote] database and catalog it locally:\n");
  printf("    database name       : %s\n", dbName);
  printf("    local database alias: %s\n", dbLocalAlias);

  /* create database */
  sqlecrea(dbName,
           dbLocalAlias,
           dbPath,
           &dbDescriptor,
           &territoryInfo,
           '\0',
           NULL,
           &sqlca);
  DB2_API_CHECK("Database -- Create");

  return 0;
} /* DbCreate */

int DbDrop(void)
{
  struct sqlca sqlca;
  char dbLocalAlias[SQL_ALIAS_SZ + 1];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  sqledrpd -- DROP DATABASE\n");
  printf("TO DROP A DATABASE:\n");

  /* drop a database  */
  strcpy(dbLocalAlias, "dbcreate");
  printf("\n  Drop a [remote] database and uncatalog it locally.\n");
  printf("    local database alias: %s\n", dbLocalAlias);

  /* drop database */
  sqledrpd(dbLocalAlias, &sqlca);
  DB2_API_CHECK("Database -- Drop");

  return 0;
} /* DbDrop */

