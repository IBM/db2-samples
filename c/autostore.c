/*****************************************************************************
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
** SOURCE FILE NAME: autostore.c 
**    
** SAMPLE: How to use automatic storage capability for a database. 
**
**         This sample demonstrates:
**
**         1. How to create an automatic storage database with two 
**            storage paths
**         2. How to backup the above database
**         3. How to restore an automatic storage database into a different
**            set of storage paths
**           
** DB2 API USED:
**         db2Backup -- BACKUP DATABASE
**         db2Restore -- RESTORE DATABASE
**         db2CfgSet -- SET DATABASE CONFIGURATION                 
**         db2CfgGet -- GET DATABASE CONFIGURATION                 
**         sqlecrea -- CREATE DATABASE
**         sqledrpd -- DROP DATABASE
**      
** OUTPUT FILE: autostore.out (available in the online documentation)
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
#include <sqlenv.h>
#include <sqlutil.h>
#include <db2ApiDf.h>
#include "utilemb.h"

/* function declarations */ 
int CreateDatabase(char *, char *, char *, char *);
int BackupDatabase(char *, char *, char *, char *);
int DropDatabase(char *);
int RestoreDatabase(char *, char *, char *, char *, char *,
                    char *, char *, char *, char *);
int ServerWorkingPathGet(char *, char *);
int DbBackup(char *, char *, char *, char *, db2BackupStruct *);

char backupTimestamp[SQLU_TIME_STAMP_LEN + 1] = { 0 };

int main(int argc, char *argv[])
{
  int rc = 0;
  char dbAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char restoredDbAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char user[USERID_SZ + 1] = { 0 };
  char pswd[PSWD_SZ + 1] = { 0 };
  char storPath1[SQL_PATH_SZ + 1] = { 0 };
  char storPath2[SQL_PATH_SZ + 1] = { 0 };
  char storPath3[SQL_PATH_SZ + 1] = { 0 };
  char storPath4[SQL_PATH_SZ + 1] = { 0 };
  char serverWorkingPath[SQL_PATH_SZ + 1] = { 0 };

  /* check and assign the values for the respective variables as 
     passed from the command line arguments */
  switch (argc)
  {
    case 5:
      strcpy(storPath1, argv[1]);
      strcpy(storPath2, argv[2]);
      strcpy(storPath3, argv[3]);
      strcpy(storPath4, argv[4]);
      strcpy(dbAlias, "AUTODB");
      strcpy(restoredDbAlias, "RESTDB"); 
      strcpy(user, "");
      strcpy(pswd, "");
      break;

    case 7:
      strcpy(storPath1, argv[3]);
      strcpy(storPath2, argv[4]);
      strcpy(storPath3, argv[5]);
      strcpy(storPath4, argv[6]);
      strcpy(dbAlias, argv[1]);
      strcpy(restoredDbAlias, argv[2]);
      strcpy(user, "");
      strcpy(pswd, "");
      break;

    case 9:
      strcpy(storPath1, argv[5]);
      strcpy(storPath2, argv[6]);
      strcpy(storPath3, argv[7]);
      strcpy(storPath4, argv[8]);
      strcpy(dbAlias, argv[1]);
      strcpy(restoredDbAlias, argv[2]);
      strcpy(user, argv[3]);
      strcpy(pswd, argv[4]);
      break;

    default:
      printf("\nUSAGE: %s "
             "[dbAlias restoredDbAlias [user pswd]] "
             "storPath1 storPath2 storPath3 storPath4\n",
             argv[0]);
      printf("       The storage paths mentioned above have to be absolute\n");
      rc = 1;
      break;
  }
  if (rc != 0)
  {
    return rc;
  }

  /* call the function to create the database */
  rc = CreateDatabase(dbAlias, storPath1, storPath2, storPath3);
  if (rc != 0)
  {
    printf("There is an ERROR while creating the database %s\n", dbAlias);
    exit (1);
  }

  /* get the server working path */
  rc = ServerWorkingPathGet(dbAlias, serverWorkingPath);
  if (rc != 0)
  {
    printf("There is an ERROR while getting the server working path.\n");
    exit (1);
  }

  /* call the function to Backup the database */
  rc = BackupDatabase(dbAlias, user, pswd, serverWorkingPath);
  if (rc != 0)
  {
    printf("There is an ERROR while backing up the database %s\n", dbAlias);
    exit (1);
  }

  /* call the function to Drop the database */
  rc = DropDatabase(dbAlias);
  if (rc != 0)
  {
    printf("There is an ERROR while dropping the database %s\n", dbAlias);
    exit (1);
  }

  /* call the function to restore the database */
  rc = RestoreDatabase(dbAlias,
                       user, 
                       pswd,
                       restoredDbAlias,
                       serverWorkingPath,
                       backupTimestamp,
                       storPath2, 
                       storPath3, 
                       storPath4);
  if (rc != 0)
  {
    printf("There is an ERROR while restoring the database %s\n", dbAlias);
    exit (1);
  }

  return (0);
  } /* main */

/***************************************************************************/
/* CreateDatabase                                                          */
/* Create an automatic storage database with two specified storage         */
/* paths, namely, storPath1, storPath2) and database path on storPath3     */
/* This function executes the following CLP command:                       */
/*   CREATE DB <dbName> ON storPath1, storPath2 DBPATH ON storPath3        */
/***************************************************************************/
int CreateDatabase(char dbName[], 
                   char storPath1[], 
                   char storPath2[],
                   char storPath3[])
{
  int rc = 0;
  struct sqlca sqlca;
  char dbLocalAlias[SQL_ALIAS_SZ + 1];
  char dbPath[SQL_PATH_SZ + 1];
  struct sqleAutoStorageCfg storageCfg;
  struct sqledbdesc dbDesc;
  struct sqledbdescext dbDescExt;
  char * storagePaths[2];
  SQLEDBTERRITORYINFO territoryInfo;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  sqlecrea -- CREATE DATABASE\n");
  printf("TO CREATE A NEW DATABASE:\n");

  /* setup storage paths and automatic storage information */
  storagePaths[0]= (char *) malloc(sizeof(char)*(SQL_PATH_SZ + 1));
  storagePaths[1]= (char *) malloc(sizeof(char)*(SQL_PATH_SZ + 1));

  if (storagePaths[0] == NULL || storagePaths[1] == NULL)
  {
    printf("ERROR: Unable to allocate memory for the storage paths.\n\n");
    return (1);
  }

  /* storPath1 and storPath2 points to the storage paths that will be used 
     for automatic storage. */
  strcpy(storagePaths[0], storPath1);
  strcpy(storagePaths[1], storPath2); 

  storageCfg.sqlNumStoragePaths = 2;
  storageCfg.sqlStoragePaths = storagePaths;
  storageCfg.sqlEnableAutoStorage = SQL_AUTOMATIC_STORAGE_YES;
              /* This parameter enables the Automatic Storage capalility */

  /* initialize sqledbdesc structure */
  strcpy(dbDesc.sqldbdid, SQLE_DBDESC_2);
  dbDesc.sqldbccp = 0;
  dbDesc.sqldbcss = SQL_CS_NONE;

  strcpy(dbDesc.sqldbcmt, "");
  dbDesc.sqldbsgp = 0;
  dbDesc.sqldbnsg = 10;
  dbDesc.sqltsext = -1;
  dbDesc.sqlcatts = NULL;
  dbDesc.sqlusrts = NULL;
  dbDesc.sqltmpts = NULL; 

  /* initialize sqledbdescext structure */
  dbDescExt.sqlPageSize = SQL_PAGESIZE_4K;
  dbDescExt.sqlAutoStorage = &storageCfg;
  dbDescExt.sqlcattsext = NULL; 
  dbDescExt.sqlusrtsext = NULL;
  dbDescExt.sqltmptsext = NULL;
  dbDescExt.reserved = NULL;
  
  strcpy(territoryInfo.sqldbcodeset, "ISO8859-1");
  strcpy(territoryInfo.sqldblocale, "C");

  strcpy(dbLocalAlias, dbName);

  /* specify the database path */
  strcpy(dbPath, storPath3);
 
  /* create database */ 
  sqlecrea(dbName,  
           dbLocalAlias,     
           dbPath,       
           &dbDesc,     
           &territoryInfo,    
           '\0',         
           (void *)&dbDescExt,   
           &sqlca );        

  DB2_API_CHECK("Create Database");
  return rc;
} /* CreateDatabase */

/***************************************************************************/
/* BackupDatabase			                                   */
/* Backup the specified database                                           */
/***************************************************************************/
int BackupDatabase(char dbAlias[], 
                   char user[], 
                   char pswd[],
                   char serverWorkingPath[])
{
  int rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam cfgParameters[1] = { 0 };
  db2Cfg cfgStruct = { 0 };
  db2BackupStruct backupStruct = { 0 };

  printf("\n****************************\n");
  printf("*** BACK UP THE DATABASE ***\n");
  printf("****************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- Set Configuration\n");
  printf("  db2Backup -- Backup Database\n");
  printf("TO BACK UP THE DATABASE.\n");

  printf("\n    Update \'%s\'  database configuration:\n", dbAlias);
  printf("    - Disable the database configuration parameter LOGARCHMETH1\n");
  printf("        i.e., set LOGARCHMETH1 = OFF\n");

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGARCHMETH1;
  cfgParameters[0].ptrvalue = "OFF";

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  /* set database configuration */
  db2CfgSet(db2Version1010, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("Db Log Retain -- Disable");

  /******************************/
  /*    BACKUP THE DATABASE     */
  /******************************/

  rc = DbBackup(dbAlias, user, pswd, serverWorkingPath, &backupStruct);

  strcpy(backupTimestamp, backupStruct.oTimestamp);
  return rc;

} /* BackupDatabase */

/***************************************************************************/
/* DbBackup                                                                */
/* Performs the database backup                                            */
/***************************************************************************/
int DbBackup(char dbAlias[],
             char user[],
             char pswd[],
             char serverWorkingPath[],
             db2BackupStruct *backupStruct)
{
  struct sqlca sqlca = { 0 };
  db2TablespaceStruct tablespaceStruct = { 0 };
  db2MediaListStruct mediaListStruct = { 0 };

  /*******************************/
  /*    BACK UP THE DATABASE    */
  /*******************************/
  printf("\n    Backing up the '%s' database...\n", dbAlias);

  tablespaceStruct.tablespaces = NULL;
  tablespaceStruct.numTablespaces = 0;

  mediaListStruct.locations = &serverWorkingPath;
  mediaListStruct.numLocations = 1;
  mediaListStruct.locationType = SQLU_LOCAL_MEDIA;

  backupStruct->piDBAlias = dbAlias;
  backupStruct->piTablespaceList = &tablespaceStruct;
  backupStruct->piMediaList = &mediaListStruct;
  backupStruct->piUsername = NULL;
  backupStruct->piPassword = NULL;
  backupStruct->piVendorOptions = NULL;
  backupStruct->iVendorOptionsSize = 0;
  backupStruct->iCallerAction = DB2BACKUP_BACKUP;
  backupStruct->iBufferSize = 16;        /*  16 x 4KB */
  backupStruct->iNumBuffers = 2;
  backupStruct->iParallelism = 1;
  backupStruct->iOptions = DB2BACKUP_OFFLINE | DB2BACKUP_DB;

  /* The API db2Backup creates a backup copy of a database.
     This API automatically establishes a connection to the specified
     database. (This API can also be used to create a backup copy of a
     table space). */
  db2Backup(db2Version1010, backupStruct, &sqlca);
  DB2_API_CHECK("Database -- Backup");

  while (sqlca.sqlcode != 0)
  {
    /* continue the backup operation */

    /* depending on the sqlca.sqlcode value, user action may be */
    /* required, such as mounting a new tape */

    printf("\n    Continuing the backup operation...\n");

    backupStruct->iCallerAction = DB2BACKUP_CONTINUE;

    db2Backup(db2Version1010, backupStruct, &sqlca);

    DB2_API_CHECK("Database -- Backup");
  }

  printf("  Backup finished.\n");
  printf("    - backup image size      : %d MB\n", backupStruct->oBackupSize);
  printf("    - backup image path      : %s\n",
         mediaListStruct.locations[0]);

  printf("    - backup image time stamp: %s\n", backupStruct->oTimestamp);
  return 0;
} /* DbBackup */

/***************************************************************************/
/* RestoreDatabase                                                         */
/* Restore an automatic storage database to a set of specified storage     */
/* paths: storPath3, storPath4	                                           */
/* This function executes the following CLP command:                       */
/*   RESTORE DB <dbName> ON storPath3, storPath4                           */ 
/***************************************************************************/
int RestoreDatabase(char dbAlias[],
                    char user[], 
                    char pswd[],
                    char restoredDbAlias[],
                    char serverWorkingPath[],
                    char restoreTimestamp[],
                    char storPath2[], 
                    char storPath3[], 
                    char storPath4[])
{
  int rc = 0;
  struct sqlca sqlca = { 0 };
  char * storagePaths[2];
  db2RestoreStruct restoreStruct = { 0 };
  db2TablespaceStruct rtablespaceStruct = { 0 };
  db2MediaListStruct rmediaListStruct = { 0 };
  db2StoragePathsStruct storagePathsStruct = { 0 };
  
  /******************************/
  /*    RESTORE THE DATABASE    */
  /******************************/
  storagePaths[0]= (char *) malloc (sizeof(char)* (SQL_PATH_SZ + 1));
  storagePaths[1]= (char *) malloc (sizeof(char)* (SQL_PATH_SZ + 1));

  if (storagePaths[0] == NULL || storagePaths[1] == NULL)
  {
    printf("ERROR: Unable to allocate memory for storage paths.\n\n");
    return (1);
  }

  printf("\n****************************\n");
  printf("*** RESTORE THE DATABASE ***\n");
  printf("******************************\n");
  printf("\nUSE THE DB2 API:\n");
  printf("  db2Restore -- Restore Database\n");
  printf("TO RESTORE THE DATABASE.\n");

  printf("\n    Restoring a database ...\n");
  printf("    - source image alias     : %s\n", dbAlias);
  printf("    - source image time stamp: %s\n", restoreTimestamp);
  printf("    - target database        : %s\n", restoredDbAlias);
 
  rtablespaceStruct.tablespaces = NULL;
  rtablespaceStruct.numTablespaces = 0;
  rmediaListStruct.locations = &serverWorkingPath;
  rmediaListStruct.numLocations = 1;
  rmediaListStruct.locationType = SQLU_LOCAL_MEDIA;
  restoreStruct.piSourceDBAlias = dbAlias;
  restoreStruct.piTargetDBAlias = restoredDbAlias;
  restoreStruct.piTimestamp = restoreTimestamp;
  restoreStruct.piTargetDBPath = NULL;
  restoreStruct.piReportFile = NULL;
  restoreStruct.piTablespaceList = &rtablespaceStruct;
  restoreStruct.piMediaList = &rmediaListStruct;
  restoreStruct.piUsername = user;
  restoreStruct.piPassword = pswd;
  restoreStruct.piNewLogPath = NULL;
  restoreStruct.piVendorOptions = NULL;
  restoreStruct.iVendorOptionsSize = 0;
  restoreStruct.iParallelism = 1;
  restoreStruct.iBufferSize = 1024;     /*  1024 x 4KB */
  restoreStruct.iNumBuffers = 2;
  restoreStruct.piTargetDBPath = storPath4 ;
 
  /* The database is will be restored on new storage paths 'storPath3' 
     and 'storPath4'. */
  strcpy( storagePaths[0], storPath3 );
  strcpy( storagePaths[1], storPath4 );
 
  storagePathsStruct.numStoragePaths = 2;
  storagePathsStruct.storagePaths = storagePaths;
 
  restoreStruct.piStoragePaths = &storagePathsStruct;
  restoreStruct.iCallerAction = DB2RESTORE_RESTORE;
  restoreStruct.iOptions =
    DB2RESTORE_OFFLINE | DB2RESTORE_DB | DB2RESTORE_NODATALINK |
    DB2RESTORE_NOROLLFWD;

  /* The API db2Restore is used to restore a database that has been backed
     up using the API db2Backup. */
  db2Restore(db2Version1010, &restoreStruct, &sqlca);
  DB2_API_CHECK("database restore -- start");

  while (sqlca.sqlcode != 0)
  {
    /* continue the restore operation */
    printf("\n    Continuing the restore operation...\n");

    /* depending on the sqlca.sqlcode value, user action may be
       required, such as mounting a new tape */

    restoreStruct.iCallerAction = DB2RESTORE_CONTINUE;

    /* restore the database */
    db2Restore(db2Version1010, &restoreStruct, &sqlca);
    DB2_API_CHECK("database restore -- continue");
  }

  printf("\n    Restore finished.\n");
  return 0;
} /* RestoreDatabase */

/***************************************************************************/
/* DropDatabase                                                            */
/* Drop the specified database                                             */
/***************************************************************************/
int DropDatabase(char dbLocalAlias[])
{
  struct sqlca sqlca;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  sqledrpd -- DROP DATABASE\n");
  printf("TO DROP A DATABASE:\n");

  /* drop a database  */
  printf("\n    Drop a [remote] database and uncatalog it locally.\n");
  printf("    local database alias: %s\n", dbLocalAlias);

  /* drop the database */
  sqledrpd(dbLocalAlias, &sqlca);
  DB2_API_CHECK("Database -- Drop");

  return 0;
} /* DropDatabase */

/***************************************************************************/
/* ServerWorkingPathGet                                                    */
/* Get the server working directory path where the backup images are kept  */
/***************************************************************************/
int ServerWorkingPathGet(char dbAlias[], char serverWorkingPath[])
{
  int rc = 0;
  struct sqlca sqlca;
  db2CfgParam cfgParameters[1];
  db2Cfg cfgStruct;
  char serverLogPath[SQL_PATH_SZ + 1];
  char dbAlias_upper[SQL_ALIAS_SZ + 1] = { 0 };
  int len = 0;
  int ctr = 0;

  /* initialize cfgParameters */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGPATH;
  cfgParameters[0].ptrvalue =
    (char *)malloc((SQL_PATH_SZ + 1) * sizeof(char));

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = dbAlias;

  /* get database configuration */
  db2CfgGet(db2Version1010, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("server log path -- get");

  strcpy(serverLogPath, cfgParameters[0].ptrvalue);
  free(cfgParameters[0].ptrvalue);

  /* get server working path */
  /* for example, if the serverLogPath = "C:\DB2\NODE0001\....". */
  /* keep for serverWorkingPath "C:\DB2" only. */

  for (ctr = 0; ctr < strlen (dbAlias); ctr++)
  {
    dbAlias_upper[ctr] = toupper (dbAlias[ctr]);
  }
  dbAlias_upper[ctr] = '\0';  /* terminate the constructed string */

  len = (int)(strstr(serverLogPath, "NODE") - serverLogPath - 1);
  memcpy( serverWorkingPath, serverLogPath, len );
  serverWorkingPath[len] = '\0';

  return 0;
} /* ServerWorkingPathGet */
