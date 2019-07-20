/*****************************************************************************
**  (c) Copyright IBM Corp. 2007 All rights reserved.
**
**  The following sample of source code ("Sample") is owned by International
**  Business Machines Corporation or one of its subsidiaries ("IBM") and is
**  copyrighted and licensed, not sold. You may use, copy, modify, and
**  distribute the Sample in any form without payment to IBM, for the purpose of
**  assisting you in the development of your applications.
**
**  The Sample code is provided to you on an "AS IS" basis, without warranty of
**  any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
**  IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
**  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
**  not allow for the exclusion or limitation of implied warranties, so the above
**  limitations or exclusions may not apply to you. IBM shall not be liable for
**  any damages you suffer as a result of using, copying, modifying or
**  distributing the Sample, even if IBM has been advised of the possibility of
**  such damages.
*****************************************************************************
**                                                                           
** SAMPLE FILE NAME : ssv_backup_db.c                                        
**                                                                           
** PURPOSE         : This sample demonstrates performing a database backup   
**                   in a massively parallel processing (MPP) environment.   
**                                                                           
** USAGE SCENARIO  : This sample demonstrates different options of           
**                   performing database BACKUP in an MPP environment.       
**                   In an MPP environment, you can back up a database on    
**                   a single database partition, on several database        
**                   partitions at once, or on all database partitions at    
**                   once.  This command can be run from any database        
**                   partition (catalog or non-catalog). It will backup the  
**                   database partition that is mentioned in the             
**                   DBPARTITIONNUM clause.                                  
**                                                                           
** PREREQUISITE     : MPP setup with 3 database partitions:                  
**                      NODE 0: Catalog Node                                 
**                      NODE 1: Non-catalog node                             
**                      NODE 2: Non-catalog node                             
**                                                                           
** EXECUTION        : ssv_backup_db <path to store Backup images>            
**                                                                           
** INPUTS           : <store path> : Path to store backup images.            
**                                                                           
** OUTPUT           : Successful Backup of database on different database    
**                    partitions.                                            
**                                                                           
** OUTPUT FILE      : ssv_backup_db.out                                      
**                    (available in the online documentation)                
**                                                                           
** DB2 APIs USED    :db2Backup -- BACKUP DATABASE                            
**                                                                           
*****************************************************************************
**For more information on the sample programs, see the README file.          
**For information on using SQL statements, see the SQL Reference.            
**                                                                           
**For the latest information on programming, building, and running DB2       
**applications, visit the DB2 application development website:               
**http:**www.software.ibm.com*data*db2*udb*ad                                
*****************************************************************************

*****************************************************************************
** SAMPLE DESCRIPTION                                                        
*****************************************************************************
** 1. Back up the database on a set of specified database partitions.        
** 2. Back up the database on all database partitions.                       
*****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlenv.h>
#include <sqlutil.h>
#include <db2ApiDf.h>
#include "utilemb.h"

/* function declarations */ 
int BackupDatabaseOnAllPartitions(char *, char *, char *, char *);
int BackupDatabaseOnASetOfPartitions(char *, char *, char *, char *);

int main(int argc, char *argv[])
{
  int rc = 0;
  char dbAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char user[USERID_SZ + 1] = { 0 };
  char pswd[PSWD_SZ + 1] = { 0 };
  char workingPath[SQL_PATH_SZ + 1] = { 0 };

  printf("\nTHIS SAMPLE SHOWS HOW TO PERFORM DATABASE BACKUP ");
  printf("IN AN MPP ENVIRONMENT.\n");

/*****************************************************************************/
/*   SETUP                                                                   */
/*****************************************************************************/

  /* Check the command line arguments */
  switch (argc)
  {
    case 2:
      strcpy(workingPath, argv[1]);
      strcpy(dbAlias, "SAMPLE");
      strcpy(user, "");
      strcpy(pswd, "");
      break;

    case 3:
      strcpy(workingPath, argv[2]);
      strcpy(dbAlias, argv[1]);
      strcpy(user, "");
      strcpy(pswd, "");
      break;

    case 5:
      strcpy(workingPath, argv[4]);
      strcpy(dbAlias, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      break;

    default:
      printf("\nUSAGE: %s "
             "[dbAlias [user pswd]] "
             "<workingPath>\n",
             argv[0]);
      printf("       The workingPath mentioned above has to be absolute &"
             " must exist.\n");
      rc = 1;
      break;
  }
  if (rc != 0)
  {
    return rc;
  }

/*****************************************************************************/
/* 1. Back up the database on a set of specified database partitions.        */
/*****************************************************************************/
  rc = BackupDatabaseOnASetOfPartitions(dbAlias, user, pswd, workingPath);

  if (rc != 0)
  {
    printf("\n Backup failed. ");
    return rc;
  }
/*****************************************************************************/
/* 2. Back up the database on all database partitions.                       */
/*****************************************************************************/
  rc = BackupDatabaseOnAllPartitions(dbAlias, user, pswd, workingPath);

  if (rc != 0)
  {
    printf("\n Backup failed. ");
    return rc;
  }

  return 0;
} /* end main */


/*****************************************************************************/
/* Function: BackupDatabaseOnASetOfPartitions		                       */
/* Back up the database on a set of specified database partitions.           */
/*****************************************************************************/
int BackupDatabaseOnASetOfPartitions(char dbAlias[], 
                                char user[], 
                                char pswd[],
                                char workingPath[])
{
  int rc = 0;
  struct sqlca sqlca = { 0 };
  db2BackupStruct backupStruct = { 0 };
  db2BackupMPPOutputStruct backupMPPOutputStruct[2] = { 0, 0 };
  db2MediaListStruct mediaListStruct = { 0 };

  printf("\n********************************************************\n");
  printf("*** BACK UP THE DATABASE ON DATABASE PARTITIONS 0 & 1***\n");
  printf("********************************************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2Backup -- Backup Database\n");
  printf("TO BACK UP THE DATABASE.\n");

  backupStruct.piDBAlias = dbAlias;
  backupStruct.piUsername = user;
  backupStruct.piPassword = pswd;
  backupStruct.piVendorOptions = NULL;
  backupStruct.iVendorOptionsSize = 0;
  backupStruct.iCallerAction = DB2BACKUP_BACKUP;
 
  /* DB2BACKUP_MPP & DB2BACKUP_DB specifies database level backup in an     */
  /* MPP environment.                                                       */
  backupStruct.iOptions = DB2BACKUP_MPP | DB2BACKUP_OFFLINE | DB2BACKUP_DB;

  /* DB2_NODE_LIST specifies that the backup will be performed on the list  */
  /* of database partitions supplied as parameters.                         */
  backupStruct.iAllNodeFlag = DB2_NODE_LIST;

  /* Total number of database partitions that will take part in backup.     */
  backupStruct.iNumNodes = 2;
  backupStruct.piNodeList = 
    (SQL_PDB_NODE_TYPE *)malloc(2 * sizeof(SQL_PDB_NODE_TYPE));

    if (backupStruct.piNodeList == NULL)
  {
    printf("\nInsufficient memory.\n");
    return 1;
  }

  /* Node 0 & Node 1 will be backed up.*/
  backupStruct.piNodeList[0] = 0;
  backupStruct.piNodeList[1] = 1;

  backupStruct.iNumMPPOutputStructs = 2;
  backupStruct.poMPPOutputStruct = backupMPPOutputStruct;

  /*******************************/
  /*    BACK UP THE DATABASE    */
  /*******************************/
  printf("\n    Backing up the '%s' database...\n", dbAlias);

  mediaListStruct.locations = &workingPath;
  mediaListStruct.numLocations = 1;
  mediaListStruct.locationType = SQLU_LOCAL_MEDIA;

  backupStruct.piMediaList = &mediaListStruct;

  /* The API db2Backup creates a backup copy of a database.            */
  /* This API automatically establishes a connection to the specified  */
  /* database. (This API can also be used to create a backup copy of a */
  /* table space).                                                     */
  db2Backup(db2Version970, &backupStruct, &sqlca);
  DB2_API_CHECK("Database -- Backup");

  printf("  Backup finished.\n");
  printf("    - backup image path      : %s\n", mediaListStruct.locations[0]);
  printf("    - backup image time stamp: %s\n", backupStruct.oTimestamp);

  free (backupStruct.piNodeList);

  return rc;

} /* BackupDatabaseOnASetOfPartitions */


/*****************************************************************************/
/* Function: BackupDatabaseOnAllPartitions			                 */
/* Back up the database on all database partitions.                          */
/*****************************************************************************/
int BackupDatabaseOnAllPartitions(char dbAlias[], 
                             char user[], 
                             char pswd[],
                             char workingPath[])
{
  int rc = 0;
  struct sqlca sqlca = { 0 };
  db2BackupStruct backupStruct = { 0 };
  db2BackupMPPOutputStruct backupMPPOutputStruct[3] = { 0, 0, 0 };
  db2MediaListStruct mediaListStruct = { 0 };

  printf("\n*******************************************************\n");
  printf("*** BACK UP THE DATABASE ON ALL DATABASE PARTITIONS ***\n");
  printf("*******************************************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2Backup -- Backup Database\n");
  printf("TO BACK UP THE DATABASE.\n");

  backupStruct.piDBAlias = dbAlias;
  backupStruct.piUsername = user;
  backupStruct.piPassword = pswd;
  backupStruct.piVendorOptions = NULL;
  backupStruct.iVendorOptionsSize = 0;
  backupStruct.iCallerAction = DB2BACKUP_BACKUP;

  /* DB2BACKUP_MPP & DB2BACKUP_DB specifies database level backup in an     */
  /* MPP environment.                                                       */
  backupStruct.iOptions = DB2BACKUP_MPP | DB2BACKUP_OFFLINE | DB2BACKUP_DB;

  /* DB2_ALL_NODES specifies that the backup will be performed on all       */
  /* database partitions                                                    */
  backupStruct.iAllNodeFlag = DB2_ALL_NODES;
  backupStruct.piNodeList = NULL;  /* NULL for full backup  */

  /* Total number of database partitions that will take part in backup. */
  backupStruct.iNumMPPOutputStructs = 3;
  backupStruct.poMPPOutputStruct = backupMPPOutputStruct;

  /*******************************/
  /*    BACK UP THE DATABASE    */
  /*******************************/
  printf("\n    Backing up the '%s' database...\n", dbAlias);

  mediaListStruct.locations = &workingPath;
  mediaListStruct.numLocations = 1;
  mediaListStruct.locationType = SQLU_LOCAL_MEDIA;

  backupStruct.piMediaList = &mediaListStruct;

  /* The API db2Backup creates a backup copy of a database.            */
  /* This API automatically establishes a connection to the specified  */
  /* database. (This API can also be used to create a backup copy of a */
  /* table space).                                                     */
  db2Backup(db2Version970, &backupStruct, &sqlca);
  DB2_API_CHECK("Database -- Backup");

  printf("  Backup finished.\n");
  printf("    - backup image path      : %s\n", mediaListStruct.locations[0]);
  printf("    - backup image time stamp: %s\n", backupStruct.oTimestamp);

  return rc;

} /* BackupDatabaseOnAllPartitions */
