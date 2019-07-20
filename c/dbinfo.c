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
** SOURCE FILE NAME: dbinfo.c
**
** SAMPLE: Set and get information at the database level
**          
** DB2 API USED:    
**         db2CfgGet -- Get Configuration
**         db2CfgSet -- Set Configuration

** STRUCTURES USED:
**         sqlca 
**
** OUTPUT FILE: dbinfo.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
**
** For information on using SQL statements, see the SQL Reference.
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
#include <sqlenv.h>
#include <db2ApiDf.h>
#include "utilapi.h"

int LocalOrRemoteDbConfigSetGet(char *);
int LocalOrRemoteDbConfigDefaultsSetGet(char *);

/* support functions */
int LocalOrRemoteDbConfigSave(db2Cfg);
int LocalOrRemoteDbConfigRestore(db2Cfg);

int main(int argc, char *argv[])
{
  int rc = 0;
  char dbAlias[SQL_ALIAS_SZ + 1];
  char nodeName[SQL_INSTNAME_SZ + 1];
  char user[USERID_SZ + 1];
  char pswd[PSWD_SZ + 1];
  db2CfgParam cfgParameters[2]; /* to save the DB Config. */
  db2Cfg cfgStruct;

  /* check the command line arguments */
  rc = CmdLineArgsCheck3(argc, argv, dbAlias, nodeName, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO SET/GET INFO AT DATABASE LEVEL.\n");

  /* attach to a local or remote instance */
  rc = InstanceAttach(nodeName, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  /* initialize cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  /* save DB. Config. */
  rc = LocalOrRemoteDbConfigSave(cfgStruct);

  if (rc != 0)
  {
    return rc;
  }

  /* work with DB. Config. */
  rc = LocalOrRemoteDbConfigSetGet(dbAlias);
  rc = LocalOrRemoteDbConfigDefaultsSetGet(dbAlias);

  /* restore DB Config. */
  rc = LocalOrRemoteDbConfigRestore(cfgStruct);

  /* detach from the local or remote instance */
  rc = InstanceDetach(nodeName);
  if (rc != 0)
  {
    return rc;
  }

  return 0;
} /* end main */

int LocalOrRemoteDbConfigSave(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  /* initialize paramArray */
  cfgStruct.paramArray[0].flags = 0;
  cfgStruct.paramArray[0].token = SQLF_DBTN_TSM_OWNER;
  cfgStruct.paramArray[0].ptrvalue = (char *)malloc(sizeof(char) * 65);
  cfgStruct.paramArray[1].flags = 0;
  cfgStruct.paramArray[1].token = SQLF_DBTN_MAXAPPLS;
  cfgStruct.paramArray[1].ptrvalue = (char *)malloc(sizeof(sqluint16));

  printf("\n**** SAVE DB CONFIG. FOR: %s ****\n", cfgStruct.dbname);

  /* get database configuration */
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Save");

  return 0;
} /* LocalOrRemoteDbConfigSave */

int LocalOrRemoteDbConfigRestore(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  printf("\n*** RESTORE DB CONFIG. FOR: %s ***\n", cfgStruct.dbname);

  /* update database configuration */
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Restore");

  free(cfgStruct.paramArray[0].ptrvalue);
  free(cfgStruct.paramArray[1].ptrvalue);

  return 0;
} /* LocalOrRemoteDbConfigRestore */

int LocalOrRemoteDbConfigSetGet(char *dbAlias)
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgGet -- GET CONFIGURATION\n");
  printf("  db2CfgSet -- SET CONFIGURATION\n");
  printf("TO SET/GET DATABASE CONFIGURATION PARAMETERS:\n");

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_TSM_OWNER;
  cfgParameters[0].ptrvalue = (char *)malloc(sizeof(char) * 65);
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[1].ptrvalue = (char *)malloc(sizeof(sqluint16));

  /* set two DB Config. fields  */
  strcpy(cfgParameters[0].ptrvalue, "tsm_owner");
  *(sqluint16 *)(cfgParameters[1].ptrvalue) = 50;
  printf("\n  Set the DB Config. fields for the \"%s\" database:\n",
         dbAlias);
  printf("    TSM owner = %s\n", cfgParameters[0].ptrvalue);
  printf("    maxappls  = %u\n", 
         *(sqluint16 *)(cfgParameters[1].ptrvalue));

  /* initialize cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  /* set database configuration */
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Set");

  /* get two DB Configuration parameters */
  strcpy(cfgParameters[0].ptrvalue, "");
  *(sqluint16 *)(cfgParameters[1].ptrvalue) = 0;

  printf("  Get two DB Config. fields for the \"%s\" database:\n",
         dbAlias);

  /* get database configuration */
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Get");

  printf("    TSM owner = %s\n", cfgParameters[0].ptrvalue);
  printf("    maxappls  = %u\n",
         *(sqluint16 *)(cfgParameters[1].ptrvalue));

  /* free the memory allocated */
  free(cfgParameters[0].ptrvalue);
  free(cfgParameters[1].ptrvalue);

  return 0;
} /* LocalOrRemoteDbConfigSetGet */

int LocalOrRemoteDbConfigDefaultsSetGet(char *dbAlias)
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- SET CONFIGURATION\n");
  printf("  db2CfgGet -- GET CONFIGURATION\n");
  printf("TO SET/GET DATABASE CONFIGURATION DEFAULTS:\n");

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_TSM_OWNER;
  cfgParameters[0].ptrvalue = (char *)malloc(sizeof(char) * 65);
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[1].ptrvalue = (char *)malloc(sizeof(sqluint16));

  /* set all DB Config. defaults */
  printf("\n  Set all database configuration defaults");
  printf(" for the \"%s\" database.\n", dbAlias);
         

  /* set cfgStruct */
  cfgStruct.numItems = 0;
  cfgStruct.paramArray = NULL;
  cfgStruct.flags = db2CfgDatabase | db2CfgReset | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  /* reset database configuration */
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. defaults -- Set");

  /* get two DB Configuration defaults */
  strcpy(cfgParameters[0].ptrvalue, "");
  *(sqluint16 *)(cfgParameters[1].ptrvalue) = 0;

  printf("  Get two database configuration defaults");
  printf(" for the \"%s\" database:\n", dbAlias);

  /* set cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgGetDefaults;
  cfgStruct.dbname = dbAlias;

  /* get database configuration defaults */
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. Defaults -- Get");

  printf("    TSM owner = %s\n", cfgParameters[0].ptrvalue);
  printf("    maxappls  = %u\n",
         *(sqluint16 *)(cfgParameters[1].ptrvalue));

  /* free the memory allocated */
  free(cfgParameters[0].ptrvalue);
  free(cfgParameters[1].ptrvalue);

  return 0;
} /* LocalOrRemoteDbConfigDefaultsSetGet */

