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
** SOURCE FILE NAME: ininfo.c
**
** SAMPLE: Set and get information at the instance level
**
** DB2 APIs USED:
**         db2CfgGet -- GET CONFIGURATION
**         db2CfgSet -- SET CONFIGURATION
**         sqlegins -- GET INSTANCE
**         sqlectnd -- CATALOG NODE
**         sqlenops -- OPEN NODE DIRECTORY SCAN
**         sqlengne -- GET NEXT NODE DIRECTORY ENTRY
**         sqlencls -- CLOSE NODE DIRECTORY SCAN
**         sqleuncn -- UNCATALOG NODE
**         sqlecadb -- CATALOG DATABASE
**         db2DbDirOpenScan -- OPEN DATABASE DIRECTORY SCAN
**         db2DbDirGetNextEntry -- GET NEXT DATABASE DIRECTORY ENTRY
**         sqledcgd -- CHANGE DATABASE COMMENT
**         db2DbDirCloseScan -- CLOSE DATABASE DIRECTORY SCAN
**         sqleuncd -- UNCATALOG DATABASE
**         sqlegdad -- ADD DCS DIRECTORY ENTRY
**         sqlegdsc -- OPEN DCS DIRECTORY SCAN
**         sqlegdge -- GET DCS DIRECTORY ENTRY
**         sqlegdgt -- GET DCS DIRECTORY ENTRIES
**         sqlegdcl -- CLOSE DCS DIRECTORY SCAN
**         sqlegdel -- DELETE DCS DIRECTORY ENTRY
**         sqlesdeg -- SET RUNTIME DEGREE
**
** STRUCTURES USED:
**         sql_dir_entry
**         sqle_node_struct
**         sqle_node_tcpip
**         sqlca
**         sqledinfo
**         sqleninfo
**
** OUTPUT FILE: ininfo.out (available in the online documentation)
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
#include <sqlenv.h>
#include "utilapi.h"

int CurrentLocalInstanceNameGet(void);
int CurrentLocalNodeDirInfoSetGet(void);
int CurrentLocalDatabaseDirInfoSetGet(void);
int CurrentLocalDCSDirInfoSetGet(void);
int LocalOrRemoteDbmConfigSetGet(void);
int LocalOrRemoteDbmConfigDefaultsSetGet(void);
int LocalOrRemoteRunTimeDegreeSet(void);

/* support function */
int LocalOrRemoteDbmConfigSave(db2Cfg);
int LocalOrRemoteDbmConfigRestore(db2Cfg);

int main(int argc, char *argv[])
{
  int rc = 0;
  char nodeName[SQL_INSTNAME_SZ + 1];
  char user[USERID_SZ + 1];
  char pswd[PSWD_SZ + 1];
  db2CfgParam cfgParameters[2]; /* to save the DBM Config. */
  db2Cfg cfgStruct;

  /* initialize cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgDelayed;
  cfgStruct.dbname = NULL;

  /* check the command line arguments */
  rc = CmdLineArgsCheck2(argc, argv, nodeName, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO SET/GET INFO AT INSTANCE LEVEL.\n");

  /* set/get info for the local instance that has as name */
  /* the value of the environment variable DB2INSTANCE */

  rc = CurrentLocalInstanceNameGet();
  rc = CurrentLocalNodeDirInfoSetGet();
  rc = CurrentLocalDatabaseDirInfoSetGet();
  rc = CurrentLocalDCSDirInfoSetGet();

  /* attach to a local or remote instance */
  rc = InstanceAttach(nodeName, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  /* save DBM Config. */
  rc = LocalOrRemoteDbmConfigSave(cfgStruct);
  if (rc != 0)
  {
    return rc;
  }

  /* work with DBM Config. */
  rc = LocalOrRemoteDbmConfigSetGet();

  /* restore DBM Config. */
  rc = LocalOrRemoteDbmConfigRestore(cfgStruct);

  /* work with default DBM Config. */
  rc = LocalOrRemoteDbmConfigDefaultsSetGet();

  /* set the run time degree */
  rc = LocalOrRemoteRunTimeDegreeSet();

  /* detach from the local or remote instance */
  rc = InstanceDetach(nodeName);
  if (rc != 0)
  {
    return rc;
  }

  return 0;
} /* main */

int CurrentLocalInstanceNameGet(void)
{
  struct sqlca sqlca;
  char currentLocalInstanceName[SQL_INSTNAME_SZ + 1];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  sqlegins -- GET INSTANCE\n");
  printf("TO GET THE CURRENT LOCAL INSTANCE NAME:\n");

  /* get local instance */
  sqlegins(currentLocalInstanceName, &sqlca);
  DB2_API_CHECK("CurrentLocalInstanceName -- Get");

  printf("\n  The current local instance name is: %s\n",
         currentLocalInstanceName);

  return 0;
} /* CurrentLocalInstanceNameGet */

int CurrentLocalNodeDirInfoSetGet(void)
{
  struct sqlca sqlca;
  struct sqle_node_struct newNode;
  struct sqle_node_tcpip TCPIPprotocol;
  unsigned short nodeDirHandle, nodeEntryNb, nbNodeEntries = 0;
  struct sqleninfo *nodeEntry;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqlectnd -- CATALOG NODE\n");
  printf("  sqlenops -- OPEN NODE DIRECTORY SCAN\n");
  printf("  sqlengne -- GET NEXT NODE DIRECTORY ENTRY\n");
  printf("  sqlencls -- CLOSE NODE DIRECTORY SCAN\n");
  printf("  sqleuncn -- UNCATALOG NODE\n");
  printf("TO SET/GET THE LOCAL NODE DIRECTORY INFO.:\n");

  strncpy(newNode.nodename, "newnode", SQL_NNAME_SZ + 1);
  strncpy(newNode.comment, "example of node comment", SQL_CMT_SZ + 1);
  newNode.struct_id = SQL_NODE_STR_ID;
  newNode.protocol = SQL_PROTOCOL_TCPIP;

  strncpy(TCPIPprotocol.hostname, "hostname", SQL_HOSTNAME_SZ + 1);
  strncpy(TCPIPprotocol.service_name, "servicename",
          SQL_SERVICE_NAME_SZ + 1);

  printf("\n  Catalog the new node.\n");
  printf("\n    node name            : %s\n", newNode.nodename);
  printf("    comment              : %s\n", newNode.comment);
  printf("    structure identifier : SQL_NODE_STR_ID\n");
  printf("    protocol             : SQL_PROTOCOL_TCPIP\n");
  printf("    hostname             : %s\n", TCPIPprotocol.hostname);
  printf("    service name         : %s\n", TCPIPprotocol.service_name);

  /* catalog node */
  sqlectnd(&newNode, &TCPIPprotocol, &sqlca);
  DB2_API_CHECK("New Node -- Catalog");

  /* open node directory */
  printf("\n  Open the node directory.\n");

  /* open node directory scan */
  sqlenops(&nodeDirHandle, &nbNodeEntries, &sqlca);
  DB2_API_CHECK("Node Directory -- Open");

  /* read the node entries */
  printf("\n  Read the node directory.\n");
  for (nodeEntryNb = 0; nodeEntryNb < nbNodeEntries; nodeEntryNb++)
  {
    /* get next node directory entry */
    sqlengne(nodeDirHandle, &nodeEntry, &sqlca);
    DB2_API_CHECK("Node Directory -- Read");

    /* printing out the node information on to the screen */
    printf("\n    node name            : %.8s\n", nodeEntry->nodename);
    printf("    node comment         : %.30s\n", nodeEntry->comment);
    printf("    node host name       : %.30s\n", nodeEntry->hostname);
    printf("    node service name    : %.14s\n", nodeEntry->service_name);
    
    switch (nodeEntry->protocol)
    {
      case SQL_PROTOCOL_LOCAL:
        printf("    node protocol        : LOCAL\n");
        break;
      case SQL_PROTOCOL_NPIPE:
        printf("    node protocol        : NPIPE\n");
        break;
      case SQL_PROTOCOL_SOCKS:
        printf("    node protocol        : SOCKS\n");
        break;
      case SQL_PROTOCOL_SOCKS4:
        printf("    node protocol        : SOCKS4\n");
        break;
      case SQL_PROTOCOL_TCPIP:
        printf("    node protocol        : TCP/IP\n");
        break;
      case SQL_PROTOCOL_TCPIP4:
        printf("    node protocol        : TCP/IPv4\n");
        break;
      case SQL_PROTOCOL_TCPIP6:
        printf("    node protocol        : TCP/IPv6\n");
        break;
      default:
        printf("    node protocol        : \n");
        break;
    } /* end switch */
  } /* end for */

  /* close node directory */
  sqlencls(nodeDirHandle, &sqlca);
  DB2_API_CHECK("Node Directory -- Close");

  printf("\n  Uncatalog the node: %s\n", newNode.nodename);

  /* uncatalog node */
  sqleuncn(newNode.nodename, &sqlca);
  DB2_API_CHECK("New Node -- Uncatalog");

  return 0;
} /* CurrentLocalNodeDirInfoSetGet */

int CurrentLocalDatabaseDirInfoSetGet(void)
{
  struct sqlca sqlca;
  db2DbDirOpenScanStruct dbDirOpenParmStruct;
  db2DbDirCloseScanStruct dbDirCloseParmStruct;
  struct db2DbDirNextEntryStructV9 dbDirNextEntryParmStruct;
  struct db2DbDirInfoV9 *dbEntry = NULL;
  char dbName[] = "db_name";
  char dbAlias[] = "db_alias";
  unsigned char dbType = SQL_REMOTE;
  char nodeName[] = "nodename";
  char *dbPath = NULL;
  char dbComment[] = "example of database comment";
  db2Uint16 dbAuthentication = SQL_AUTHENTICATION_SERVER;
  char *dbDirPath = NULL;
  db2Uint16 dbDirHandle = 0;
  db2Uint16 dbEntryNb = 0;
  char changedDbComment[] = "the changed db comment";
  db2Uint32 versionNumber = db2Version970;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqlecadb -- CATALOG DATABASE\n");
  printf("  db2DbDirOpenScan -- OPEN DATABASE DIRECTORY SCAN\n");
  printf("  db2DbDirGetNextEntry -- GET NEXT DATABASE DIRECTORY ENTRY\n");
  printf("  sqledcgd -- CHANGE DATABASE COMMENT\n");
  printf("  db2DbDirCloseScan -- CLOSE DATABASE DIRECTORY SCAN\n");
  printf("  sqleuncd -- UNCATALOG DATABASE\n");
  printf("TO SET/GET THE LOCAL DATABASE DIRECTORY INFO.:\n");

  printf("\n  Catalog the new database.\n");
  printf("\n    database name        : %s\n", dbName);
  printf("    database alias       : %s\n", dbAlias);
  printf("    type                 : SQL_REMOTE\n");
  printf("    node name            : %s\n", nodeName);
  printf("    path                 : NULL\n");
  printf("    comment              : %s\n", dbComment);
  printf("    authentication       : SQL_AUTHENTICATION_SERVER\n");

  /* catalog database */
  sqlecadb(dbName,
           dbAlias,
           dbType,
           nodeName,
           dbPath,
           dbComment,
           dbAuthentication,
           NULL,
           &sqlca);

  /* ignore warning SQL1100W = node not cataloged, */
  /* don't do the same in your code */
  if (sqlca.sqlcode != 1100)
  {
    DB2_API_CHECK("Database -- Catalog");
  }

  printf("\n  Open the database directory.\n");

  /* open database directory scan */
  dbDirOpenParmStruct.piPath = dbDirPath;
  dbDirOpenParmStruct.oHandle = dbDirHandle;
  db2DbDirOpenScan(versionNumber,
                   &dbDirOpenParmStruct,
                   &sqlca);

  DB2_API_CHECK("Database Directory -- Open");

  /* read the database entries */
  printf("\n  Read the database directory.\n");
  dbDirNextEntryParmStruct.iHandle = dbDirHandle;
  dbDirNextEntryParmStruct.poDbDirEntry = dbEntry;
  for (dbEntryNb = 1; dbEntryNb <= dbDirOpenParmStruct.oNumEntries; dbEntryNb++)
  {
    /* get next database directory entry */
    db2DbDirGetNextEntry(versionNumber,
                         &dbDirNextEntryParmStruct,
                         &sqlca);

    DB2_API_CHECK("Database Directory -- Read");

    dbEntry = dbDirNextEntryParmStruct.poDbDirEntry;

    /* printing out the database information on to the screen */
    printf("\n    database alias       : %.8s\n", dbEntry->alias);
    printf("    database name        : %.8s\n", dbEntry->dbname);
#if(defined(DB2NT))
    printf("    database drive       : %.12s\n", dbEntry->drive);
#else /* UNIX */
    printf("    database drive       : %.215s\n", dbEntry->drive);
#endif
    printf("    database subdirectory: %.8s\n", dbEntry->intname);
    printf("    node name            : %.8s\n", dbEntry->nodename);
    printf("    database release type: %.20s\n", dbEntry->dbtype);
    printf("    database comment     : %.30s\n", dbEntry->comment);

    switch (dbEntry->type)
    {
      case SQL_INDIRECT:
        printf("    database entry type  : indirect\n");
        break;
      case SQL_REMOTE:
        printf("    database entry type  : remote\n");
        break;
      case SQL_HOME:
        printf("    database entry type  : home\n");
        break;
      case SQL_DCE:
        printf("    database entry type  : dce\n");
        break;
      default:
        break;
    }

    switch (dbEntry->authentication)
    {
      case SQL_AUTHENTICATION_SERVER:
        printf("    authentication       : SERVER\n");
        break;
      case SQL_AUTHENTICATION_CLIENT:
        printf("    authentication       : CLIENT\n");
        break;
      case SQL_AUTHENTICATION_DCS:
        printf("    authentication       : DCS\n");
        break;
      default:
        break;
    } /* end switch */
  } /* end for */

  /* change the database comment for the new database */
  printf("\n  Change the new database comment to:\n");
  printf("    %s\n", changedDbComment);

  /* change database comment */
  sqledcgd(dbAlias, "", changedDbComment, &sqlca);
  DB2_API_CHECK("Database Comment -- Change");

  /* close database directory */
  dbDirCloseParmStruct.iHandle = dbDirHandle;
  db2DbDirCloseScan(versionNumber,
                    &dbDirCloseParmStruct,
                    &sqlca);

  DB2_API_CHECK("Database Directory -- Close");

  printf("\n  Uncatalog the database cataloged as: %s\n", dbAlias);

  /* uncatalog database */
  sqleuncd(dbAlias, &sqlca);
  DB2_API_CHECK("Database -- Uncatalog");

  return 0;
} /* CurrentLocalDatabaseDirInfoSetGet */

int CurrentLocalDCSDirInfoSetGet(void)
{
  struct sqlca sqlca;
  struct sql_dir_entry newDcsDbEntry;
  struct sql_dir_entry dcsDbEntry;
  short dcsDbEntryNb, nbDcsDbEntries = 0;
  struct sql_dir_entry *pAllDcsDbEntries;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqlegdad -- ADD DCS DIRECTORY ENTRY\n");
  printf("  sqlegdsc -- OPEN DCS DIRECTORY SCAN\n");
  printf("  sqlegdge -- GET DCS DIRECTORY ENTRY\n");
  printf("  sqlegdgt -- GET DCS DIRECTORY ENTRIES\n");
  printf("  sqlegdcl -- CLOSE DCS DIRECTORY SCAN\n");
  printf("  sqlegdel -- DELETE DCS DIRECTORY ENTRY\n");
  printf("TO SET/GET THE LOCAL DCS DIRECTORY INFO.:\n");

  strcpy(newDcsDbEntry.ldb, "dcsAlias");
  strcpy(newDcsDbEntry.tdb, "dcsDbName");
  strcpy(newDcsDbEntry.comment, "dcsDb comment");
  strcpy(newDcsDbEntry.ar, "appName");
  strcpy(newDcsDbEntry.parm, "");
  newDcsDbEntry.struct_id = SQL_DCS_STR_ID;

  printf("\n  Catalog the new DCS database.\n");
  printf("\n    intermediate alias   : %s\n", newDcsDbEntry.ldb);
  printf("    name                 : %s\n", newDcsDbEntry.tdb);
  printf("    comment              : %s\n", newDcsDbEntry.comment);
  printf("    client app. name     : %s\n", newDcsDbEntry.ar);

  /* catalog DCS database */
  sqlegdad(&newDcsDbEntry, &sqlca);
  DB2_API_CHECK("New DCS Database -- Catalog");

  printf("\n  Open the DCS database directory.\n");

  /* open DCS database directory */
  sqlegdsc(&nbDcsDbEntries, &sqlca);
  DB2_API_CHECK("DCS Database Directory -- Open");

  /* read a specific entry from the DCS database directory */
  strcpy(dcsDbEntry.ldb, "dcsAlias");
  strcpy(dcsDbEntry.tdb, "");
  strcpy(dcsDbEntry.comment, "");
  strcpy(dcsDbEntry.ar, "");
  strcpy(dcsDbEntry.parm, "");
  dcsDbEntry.struct_id = SQL_DCS_STR_ID;

  printf("\n  Read the entry for the DCS database: %s\n", dcsDbEntry.ldb);

  /* get DCS directory entry for database */
  sqlegdge(&dcsDbEntry, &sqlca);
  DB2_API_CHECK("DCS database entry -- read");

  printf("\n    intermediate alias   : %.8s\n", dcsDbEntry.ldb);
  printf("    name                 : %.18s\n", dcsDbEntry.tdb);
  printf("    comment              : %.30s\n", dcsDbEntry.comment);
  printf("    client app. name     : %.32s\n", dcsDbEntry.ar);
  printf("    DCS parameters       : %.50s\n", dcsDbEntry.parm);
  printf("    DCS release level    : 0x%x\n", dcsDbEntry.release);

  if (nbDcsDbEntries > 0)
  {
    /* get DCS database directory entries */
    pAllDcsDbEntries =
      (struct sql_dir_entry *)malloc(nbDcsDbEntries *
                                     (sizeof(struct sql_dir_entry)));

    printf("\n  Read the DCS database directory.\n");

    /* get DCS directory entries */
    sqlegdgt(&nbDcsDbEntries, pAllDcsDbEntries, &sqlca);
    DB2_API_CHECK("DCS Database Directory -- Read");

    /* print the DCS database entries */
    for (dcsDbEntryNb = 0; dcsDbEntryNb < nbDcsDbEntries; dcsDbEntryNb++)
    {
      printf("\n    intermediate alias   : %.8s\n",
             pAllDcsDbEntries[dcsDbEntryNb].ldb);
      printf("    name                 : %.18s\n",
             pAllDcsDbEntries[dcsDbEntryNb].tdb);
      printf("    comment              : %.30s\n",
             pAllDcsDbEntries[dcsDbEntryNb].comment);
      printf("    client app. name     : %.32s\n",
             pAllDcsDbEntries[dcsDbEntryNb].ar);
      printf("    DCS parameters       : %.50s\n",
             pAllDcsDbEntries[dcsDbEntryNb].parm);
      printf("    DCS release level    : 0x%x\n",
             pAllDcsDbEntries[dcsDbEntryNb].release);
    } /* end for */
  }
  free(pAllDcsDbEntries);

  /* close DCS directory */
  sqlegdcl(&sqlca);
  DB2_API_CHECK("DCS Directory -- Close");

  strcpy(newDcsDbEntry.ldb, "dcsAlias");
  strcpy(newDcsDbEntry.tdb, "");
  strcpy(newDcsDbEntry.comment, "");
  strcpy(newDcsDbEntry.ar, "");
  strcpy(newDcsDbEntry.parm, "");
  newDcsDbEntry.struct_id = SQL_DCS_STR_ID;

  printf("\n  Uncatalog the DCS database: %s\n", newDcsDbEntry.ldb);

  /* uncatalog DCS database */
  sqlegdel(&newDcsDbEntry, &sqlca);
  DB2_API_CHECK("New DCS database -- Uncatalog");

  return 0;
} /* CurrentLocalDCSDirInfoSetGet */

int LocalOrRemoteDbmConfigSetGet(void)
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- SET CONFIGURATION\n");
  printf("  db2CfgGet -- GET CONFIGURATION\n");
  printf("TO SET/GET TWO DATABASE CONFIGURATION PARAMETERS:\n");

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_KTN_DFT_ACCOUNT_STR;
  cfgParameters[0].ptrvalue =
    (char *)malloc(sizeof(char) * (SQL_ACCOUNT_STR_SZ + 1));
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_KTN_UDF_MEM_SZ;
  cfgParameters[1].ptrvalue = (char *)malloc(sizeof(unsigned short));

  /* set two DBM Config. parameters */
  strcpy(cfgParameters[0].ptrvalue, "accounting string suffix");
  *(unsigned short *)(cfgParameters[1].ptrvalue) = 512;

  printf("\n  Set the Database Configuration parameters:\n");
  printf("    dft_account_str = %s\n", cfgParameters[0].ptrvalue);
  printf("    udf_mem_sz      = %d\n",
         *(unsigned short *)(cfgParameters[1].ptrvalue));

  /* initialize cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgDelayed;
  cfgStruct.dbname = NULL;

  /* set database manager configuration */
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Set");

  /* get two DBM Config. fields */
  strcpy(cfgParameters[0].ptrvalue, "");
  *(unsigned short *)(cfgParameters[1].ptrvalue) = 0;

  printf("\n  Get two Database Configuration parameters:\n");

  /* get database manager configuration */
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Get");

  printf("    dft_account_str = %s\n", cfgParameters[0].ptrvalue);
  printf("    udf_mem_sz      = %d\n",
         *(unsigned short *)(cfgParameters[1].ptrvalue));

  /* free the memory allocated */
  free(cfgParameters[0].ptrvalue);
  free(cfgParameters[1].ptrvalue);

  return 0;
} /* LocalOrRemoteDbmConfigSetGet */

int LocalOrRemoteDbmConfigDefaultsSetGet(void)
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;
  char input;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- SET CONFIGURATION\n");
  printf("  db2CfgGet -- GET CONFIGURATION\n");
  printf("TO SET/GET DATABASE MANAGER CONFIGURATION DEFAULTS:\n");

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_KTN_DFT_ACCOUNT_STR;
  cfgParameters[0].ptrvalue =
    (char *)malloc(sizeof(char) * (SQL_ACCOUNT_STR_SZ + 1));
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_KTN_UDF_MEM_SZ;
  cfgParameters[1].ptrvalue = (char *)malloc(sizeof(unsigned short));

  /* get two Database Manager Configuration defaults */
  strcpy(cfgParameters[0].ptrvalue, "");
  *(unsigned short *)(cfgParameters[1].ptrvalue) = 0;

  /* initialize cfgStruct */
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgGetDefaults;
  cfgStruct.dbname = NULL;

  printf("\n  Get two Database Manager Configuration defaults:\n");

  /* get database manager configuration defaults */
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. Defaults -- Get");

  printf("    dft_account_str = %s\n", cfgParameters[0].ptrvalue);
  printf("    udf_mem_sz      = %d\n",
         *(unsigned short *)(cfgParameters[1].ptrvalue));

  /* warning for reset of DBM Congif. */
  printf("\n  Warning: We are now about to set all Database Manager\n");
  printf("  Configuration parameters to default using the db2CfgSet API.\n");
  printf("  After running this API, some of the non-default user\n");
  printf("  settings and those set by the installation program will\n");
  printf("  be changed accordingly, and will not be restored by\n");
  printf("  this program.  A text file, dbmcfg.TXT, will be generated\n");
  printf("  in the current directory for all the settings before\n");
  printf("  execution of this API.  The user is required to restore the\n");
  printf("  settings manually.\n");
  printf("\n");
  printf("  Would you like to run this API?(y/n) ");

  /* get user input */
  input = getchar();
  if (input == 'y')
  {
    /* save DBM Config. to a text file */
    system("db2 get dbm cfg >dbmcfg.TXT");

    printf("\n  Set all Database Manger Configuration parameters");
    printf(" to default:\n");

    /* initialize cfgStruct */
    cfgStruct.numItems = 0;
    cfgStruct.paramArray = NULL;
    cfgStruct.flags = db2CfgDatabaseManager | db2CfgReset | db2CfgDelayed;
    cfgStruct.dbname = NULL;

    /* set all Database Manager Configuration defaults */
    db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
    DB2_API_CHECK("DBM Config. defaults -- Set");

    printf("\n  All Database manager Configuration parameters");
    printf(" are set to default.\n");
  }

  /* free the memory allocated */
  free(cfgParameters[0].ptrvalue);
  free(cfgParameters[1].ptrvalue);

  return 0;
} /* LocalOrRemoteDbmConfigDefaultsSetGet */

int LocalOrRemoteRunTimeDegreeSet(void)
{
  struct sqlca sqlca;
  sqlint32 runTimeDegree;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  sqlesdeg -- SET RUNTIME DEGREE\n");
  printf("TO SET THE RUN TIME DEGREE:\n");

  /* set the run time degree */
  runTimeDegree = 4;
  printf("\n  Set the run time degree to the value: %d\n", runTimeDegree);

  /* set runtimr degree */
  sqlesdeg(SQL_ALL_USERS, NULL, runTimeDegree, &sqlca);
  DB2_API_CHECK("Run Time Degree -- Set");

  return 0;
} /* LocalOrRemoteRunTimeDegreeSet */

int LocalOrRemoteDbmConfigSave(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  /* initialize paramArray */
  cfgStruct.paramArray[0].flags = 0;
  cfgStruct.paramArray[0].token = SQLF_KTN_DFT_ACCOUNT_STR;
  cfgStruct.paramArray[0].ptrvalue =
    (char *)malloc(sizeof(char) * (SQL_ACCOUNT_STR_SZ + 1));
  cfgStruct.paramArray[1].flags = 0;
  cfgStruct.paramArray[1].token = SQLF_KTN_UDF_MEM_SZ;
  cfgStruct.paramArray[1].ptrvalue =
    (char *)malloc(sizeof(unsigned short));

  /* get two Config. Parameters */
  strcpy(cfgStruct.paramArray[0].ptrvalue, "");
  strcpy(cfgStruct.paramArray[1].ptrvalue, "");

  printf("\n******* SAVE DATABASE MANAGER CONFIGURATION **********\n");

  /* get database manager configuration */
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Save");

  return 0;
} /* LocalOrRemoteDbmConfigSave */

int LocalOrRemoteDbmConfigRestore(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  printf("\n*******  RESTORE DATABASE MANAGER CONFIGURATION *******\n");

  /* set database manager configuration */
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Restore");

  free(cfgStruct.paramArray[0].ptrvalue);
  free(cfgStruct.paramArray[1].ptrvalue);

  return 0;
} /* LocalOrRemoteDbmConfigRestore */

