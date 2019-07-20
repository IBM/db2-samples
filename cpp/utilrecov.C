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
** SOURCE FILE NAME: utilrecov.C
**
** SAMPLE: Utilities for the backup, restore and log file samples
**
**         This set of utilities gets the server working path, prunes
**         recovery history file, creates a database, backup a database,
**         drop a database, saves and restores log retain values, displays
**         the log buffer files.
**
** DB2 APIs USED:
**         db2CfgGet -- Get Configuration
**         db2CfgSet -- Set Configuration
**         db2Prune -- Prune Recovery History File
**         db2Backup -- Backup Database
**         sqledrpd -- Drop and uncatalog a database
**         sqlecrea -- creates a database
**
** STRUCTURES USED:
**         sqlca
**         sqledbdesc
**         db2PruneStruct
**         db2HistoryData
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C++ applications, see the Application
** Development Guide.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/
#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
#include <sqlenv.h>
#include <sqlutil.h>
#include <sqlca.h>
#include <db2ApiDf.h>
#include <string.h>
#include <ctype.h>
#include <sqludf.h>
#include "utilapi.h"
#include "utilemb.h"
#if ((__cplusplus >= 199711L) && !defined DB2HP && !defined DB2AIX) || \
    (DB2LINUX && (__LP64__ || (__GNUC__ >= 3)) )
   #include <iostream>
   using namespace std;
#else
   #include <iostream.h>
#endif

#define ADD_BYTES 2
#define CHECKRC(x,y)                                   \
    if ((x) != 0)                                      \
    {                                                  \
       printf("Non-zero rc from function %s.\n", (y)); \
       return (x);                                     \
    }

#define MIN(x,y)                                       \
    ((x)<(y)?(x):(y))

class UtilRecov
{
  public:
    int ServerWorkingPathGet(DbEmb *, char *);
    int DbLogArchMeth1ValueSave(DbEmb *, char *);
    int DbLogArchMeth1ValueRestore(DbEmb *, char *);
    int DbRecoveryHistoryFilePrune(DbEmb *);
    int DbBackup(DbEmb *, char *, db2BackupStruct *);
    int DbCreate(char *, char *);
    int DbDrop(char *);
};

class UtilLog
{
  public:
    int LogBufferDisplay(char *, sqluint32, int);
    int LogRecordDisplay(char *, sqluint32, sqluint16, sqluint16);
    int SimpleLogRecordDisplay(sqluint16, sqluint16, char *, sqluint32);
    int ComplexLogRecordDisplay(sqluint16, sqluint16, char *, sqluint32,
                                sqluint8, char *, sqluint32);
    int LogSubRecordDisplay(char *, sqluint16);
    int UserDataDisplay(char *, sqluint16);
};

class RID
{
  private:
    char ridParts[6];
    char ridString[14];

    void toString();

  public:
    int size() { return 6; };
    void set(char * buf );
    char *getString();
};

void RID::toString()
{
    char *ptrBuf = this->ridParts;

    sprintf( ridString, "x%2.2X%2.2X%2.2X%2.2X%2.2X%2.2X",
             *ptrBuf, *(ptrBuf+1), *(ptrBuf+2),
             *(ptrBuf+3), *(ptrBuf+4), *(ptrBuf+5) );
}

void RID::set( char *buf )
{
    strncpy( this->ridParts, buf, this->size() );
}

char* RID::getString()
{
    this->toString();
    return ridString;
}

//**************************************************************************
// ServerWorkingPathGet
// Get the server working directory path where the backup images are kept
//**************************************************************************
int UtilRecov::ServerWorkingPathGet( DbEmb *db,
                                     char serverWorkingPath[] )
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  char         serverLogPath[SQL_PATH_SZ + 1] = { 0 };
  char         dbAlias_upper[SQL_ALIAS_SZ + 1] = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };
  int          len = 0;
  int          ctr = 0;
  char node[5]="NODE";

  // initialize cfgParameters
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGPATH;
  cfgParameters[0].ptrvalue = new char[SQL_PATH_SZ + 1];

  // initialize cfgStruct
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = db->getAlias();

  cout << "\nUSE THE DB2 API:\n" << endl;
  cout << "  db2CfgGet -- GET CONFIGURATION\n";
  cout << "TO GET THE DATABASE CONFIGURATION AND DETERMINE\n";
  cout << "THE SERVER WORKING PATH.\n" << endl;

  // get database configuration
  db2CfgGet( db2Version1010, (void *)&cfgStruct, &sqlca );
  DB2_API_CHECK("server log path -- get");

  strncpy( serverLogPath, cfgParameters[0].ptrvalue, SQL_PATH_SZ );
  delete [] cfgParameters[0].ptrvalue;

  // choose server working path
  // Let's say serverLogPath = "C:\DB2\NODE0001\....".
  // Keep for serverWorkingPath "C:\DB2" only.

  for (ctr = 0; ctr < strlen (node); ctr++)
  {
    dbAlias_upper[ctr] = toupper (node[ctr]);
  }
  dbAlias_upper[ctr] = '\0';  /* terminate the constructed string */

  len = (int)(strstr(serverLogPath, dbAlias_upper) - serverLogPath - 1);
  memcpy( serverWorkingPath, serverLogPath, len );
  serverWorkingPath[len] = '\0';

  return 0;
} // UtilRecov::ServerWorkingPathGet


//**************************************************************************
// DbLogArchMeth1ValueSave
// Save LOGARCHMETH1 value for the database
//**************************************************************************
int UtilRecov::DbLogArchMeth1ValueSave( DbEmb     *db,
                                     char *pLogArchMeth1Value )
{
  int          rc = 0;
  struct sqlca sqlca =  { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  // save log arch meth value
  cout << "\n******* Save LOGARCHMETH1 for '" << db->getAlias()
    << "' database. *******" << endl;
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGARCHMETH1;
  cfgParameters[0].ptrvalue = pLogArchMeth1Value;

  // initialize cfgStruct
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = db->getAlias();

  // get database configuration
  db2CfgGet(db2Version1010, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("log arch meth1  value -- save");

  return 0;
} // UtilRecov::DbLogArchMeth1ValueSave

//**************************************************************************
// DbLogArchMeth1ValueRestore
// Restore the LOGARCHMETH1 value for the database
//**************************************************************************
int UtilRecov::DbLogArchMeth1ValueRestore( DbEmb     *db,
                                        char *pLogArchMeth1Value )
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  // restore the log arch meth1 value
  cout << "\n***** Restore LOGARCHMETH1 for '" << db->getAlias()
    << "' database. *****" << endl;
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_LOGARCHMETH1;
  cfgParameters[0].ptrvalue = (char *)pLogArchMeth1Value;

  // initialize cfgStruct
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = db->getAlias();

  // set database configuration
  db2CfgSet(db2Version1010, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("log arch meth1 value -- restore");

  return 0;
} // UtilRecov::DbLogArchMeth1ValueRestore


//**************************************************************************
// DbRecoveryHistoryFilePrune
// Prunes the recovery history file by calling db2Prune API
//**************************************************************************
int UtilRecov::DbRecoveryHistoryFilePrune( DbEmb *db )
{
  int                   rc = 0;
  struct sqlca          sqlca = { 0 };
  struct db2PruneStruct histPruneParam = { 0 };
  char                  timeStampPart[SQLU_TIME_STAMP_LEN + 1] = { 0 };

  cout << "\n***************************************\n";
  cout << "*** PRUNE THE RECOVERY HISTORY FILE ***\n";
  cout << "***************************************\n";
  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  db2Prune -- PRUNE RECOVERY HISTORY FILE" << endl;
  cout << "AND THE SQL STATEMENTS:" << endl;
  cout << "  CONNECT" << endl;
  cout << "  CONNECT RESET" << endl;
  cout << "TO PRUNE THE RECOVERY HISTORY FILE." << endl;

  // connect to the database
  rc = db->Connect();
  CHECKRC(rc, "db->Connect");

  // prune the recovery history file
  cout << "\n  Prune the recovery history file for '" << db->getAlias()
    << "' database." << endl;
  histPruneParam.piString = timeStampPart;
  strcpy(timeStampPart, "2010");        // year 2010
  histPruneParam.iAction = DB2PRUNE_ACTION_HISTORY;
  histPruneParam.iOptions = DB2PRUNE_OPTION_FORCE;

  // Prune Recovery History File
  db2Prune(db2Version1010, &histPruneParam, &sqlca);
  DB2_API_CHECK("recovery history file -- prune");

  // disconnect from the database
  rc = db->Disconnect();
  CHECKRC(rc, "db->Disconnect");

  return 0;
} // UtilRecov::DbRecoveryHistoryFilePrune

//**************************************************************************
// DbBackup
// Performs the database backup
//**************************************************************************
int UtilRecov::DbBackup( DbEmb           *db,
                         char            serverWorkingPath[],
                         db2BackupStruct *backupStruct)

{
  struct sqlca        sqlca = { 0 };
  db2TablespaceStruct tablespaceStruct = { 0 };
  db2MediaListStruct  mediaListStruct = { 0 };

  //******************************
  //    BACK UP THE DATABASE
  //******************************
  cout << "\n  Backing up the \'" << db->getAlias() << "\' database...\n";

  tablespaceStruct.tablespaces = NULL;
  tablespaceStruct.numTablespaces = 0;

  mediaListStruct.locations = &serverWorkingPath;
  mediaListStruct.numLocations = 1;
  mediaListStruct.locationType = SQLU_LOCAL_MEDIA;

  backupStruct->piDBAlias = db->getAlias();
  backupStruct->piTablespaceList = &tablespaceStruct;
  backupStruct->piMediaList = &mediaListStruct;
  backupStruct->piUsername = db->getUser();
  backupStruct->piPassword = db->getPswd();
  backupStruct->piVendorOptions = NULL;
  backupStruct->iVendorOptionsSize = 0;
  backupStruct->iCallerAction = DB2BACKUP_BACKUP;
  backupStruct->iBufferSize = 16;        /*  16 x 4KB */
  backupStruct->iNumBuffers = 2;
  backupStruct->iParallelism = 1;
  backupStruct->iOptions = DB2BACKUP_OFFLINE | DB2BACKUP_DB;

  // The API db2Backup creates a backup copy of a database.
  // This API automatically establishes a connection to the specified
  // database. (This API can also be used to create a backup copy of a
  //  table space).
  db2Backup(db2Version1010, backupStruct, &sqlca);
  DB2_API_CHECK("Database -- Backup");

  while (sqlca.sqlcode != 0)
  {
    // continue the backup operation

    // depending on the sqlca.sqlcode value, user action may be
    // required, such as mounting a new tape

    cout << "\n  Continuing the backup process..." << endl;

    backupStruct->iCallerAction = DB2BACKUP_CONTINUE;

    db2Backup(db2Version1010, backupStruct, &sqlca);

    DB2_API_CHECK("Database -- Backup");
  }

  cout << "  Backup finished." << endl;
  cout << "    - backup image size     : "
    << backupStruct->oBackupSize << " MB" << endl;
  cout << "    - backup image path     : "
    << mediaListStruct.locations[0] << endl;
  cout << "    - backup image timestamp: "
    << backupStruct->oTimestamp << endl;

  return 0;
} // UtilRecov::DbBackup

//**************************************************************************
// DbCreate
// Create the specified database
//**************************************************************************
int UtilRecov::DbCreate( char existingDbAlias[],
                         char newDbAlias[] )
{
  struct sqlca        sqlca = { 0 };
  char                dbName[SQL_DBNAME_SZ + 1] = { 0 };
  char                dbLocalAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char                dbPath[SQL_PATH_SZ + 1] = { 0 };
  struct sqledbdesc   dbDescriptor = { 0 };
  SQLEDBTERRITORYINFO territoryInfo = { 0 };
  struct db2CfgParam  cfgParameters[2] = { 0 };
  struct db2Cfg       cfgStruct = { 0 };

  cout << "\n  Create '" << newDbAlias
    << "' empty db. with the same codeset as '" << existingDbAlias
    << "' db." << endl;

  // initialize cfgParameters
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_TERRITORY;
  cfgParameters[0].ptrvalue = new char[SQL_LOCALE_SIZE + 1];
  memset(cfgParameters[0].ptrvalue, '\0', SQL_LOCALE_SIZE + 1);
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_DBTN_CODESET;
  cfgParameters[1].ptrvalue = new char[SQL_CODESET_SIZE + 1];
  memset(cfgParameters[1].ptrvalue, '\0', SQL_CODESET_SIZE + 1);

  // initialize cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = existingDbAlias;

  // get two database configuration parameters
  db2CfgGet(db2Version1010, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Get");

  // create a new database
  strcpy(dbName, newDbAlias);
  strcpy(dbLocalAlias, newDbAlias);
  strcpy(dbPath, "");

  strcpy(dbDescriptor.sqldbdid, SQLE_DBDESC_2);
  dbDescriptor.sqldbccp = 0;
  dbDescriptor.sqldbcss = SQL_CS_NONE;

  strcpy(dbDescriptor.sqldbcmt, "");
  dbDescriptor.sqldbsgp = 0;
  dbDescriptor.sqldbnsg = 10;
  dbDescriptor.sqltsext = -1;
  dbDescriptor.sqlcatts = NULL;
  dbDescriptor.sqlusrts = NULL;
  dbDescriptor.sqltmpts = NULL;

  strcpy(territoryInfo.sqldbcodeset, (char *)cfgParameters[1].ptrvalue);
  strcpy(territoryInfo.sqldblocale, (char *)cfgParameters[0].ptrvalue);

  // create database
  sqlecrea(dbName,
           dbLocalAlias,
           dbPath, &dbDescriptor, &territoryInfo, '\0', NULL, &sqlca);

  DB2_API_CHECK("Database -- Create");

  // release the allocated memory
  delete [] cfgParameters[0].ptrvalue;
  delete [] cfgParameters[1].ptrvalue;

  return 0;
} // UtilRecov::DbCreate

//**************************************************************************
// DbDrop
// Drops and uncatalogs the specified database alias
//**************************************************************************
int UtilRecov::DbDrop( char dbAlias[] )
{
  struct sqlca sqlca = { 0 };

  cout << "\n  Drop the '" << dbAlias << "' database." << endl;

  // drop and uncatalog the database
  sqledrpd(dbAlias, &sqlca);
  DB2_API_CHECK("Database -- Drop");

  return 0;
} // UtilRecov::DbDrop

//*************************************************************************
// LogBufferDisplay
// Displays the log buffer
//*************************************************************************
int UtilLog::LogBufferDisplay( char      *logBuffer,
                               sqluint32 numLogRecords,
			       int conn)
{
  int       rc = 0;
  sqluint32 logRecordNb = 0;
  sqluint32 recordSize = 0;
  sqluint16 recordType = 0;
  sqluint16 recordFlag = 0;
  char      *recordBuffer = NULL;
  int headerSize = 0;
  
  // initialize the recordBuffer
  if (logBuffer == NULL)
  {
    if (numLogRecords == 0)
    {
      /* there's nothing to do */
      return 0;
    }
    else
    {
      /* we can't display NULL log records */
      return 1;
    }
  }

  // If there is no connection to the database or if the iFilterOption
  // is OFF, the 8-byte LRI 'db2LRI' is prefixed to the log records.
  // If there is a connection to the database and the iFilterOption is
  // ON, the db2ReadLogFilterData structure will be prefixed to all
  // log records returned by the db2ReadLog API ( for compressed and
  // uncompressed data )

  if (conn == 0)                                                  
  {
    headerSize = 2*sizeof(db2LRI);
  }
  else
  {
    headerSize = sizeof(db2ReadLogFilterData);
  }                                                               
  recordBuffer = logBuffer;  

  for (logRecordNb = 0; logRecordNb < numLogRecords; logRecordNb++)
  {
    if (conn == 1)                                                
    {
      db2ReadLogFilterData  *filterData = (db2ReadLogFilterData *)recordBuffer;
      cout << "\nRLOG_FILTERDATA:\n" << endl;
      cout << "    recordLRIPart1: " << filterData->recordLRIType1.part1 << endl;
      cout << "    recordLRIPart2: " << filterData->recordLRIType1.part2 << endl;
      cout << "    realLogRecLen: " << filterData->realLogRecLen << endl;
      cout << "    sqlcode: " << filterData->sqlcode << endl;
    }

    recordBuffer += headerSize;  
    
    recordSize = *(sqluint32 *) (recordBuffer);
    recordType = *(sqluint16 *) (recordBuffer + sizeof(sqluint32));
    recordFlag = *(sqluint16 *) (recordBuffer + sizeof(sqluint32) +
                 sizeof(sqluint16));

    cout << "    recordSize: " 
      << recordSize << endl;

    cout << "    recordType: "
      << recordType << endl;

    cout << "    recordFlag: "
      << recordFlag << endl;
    
    rc = LogRecordDisplay(recordBuffer, recordSize, recordType, recordFlag);
    CHECKRC(rc, "LogRecordDisplay");

    // update the recordBuffer
    recordBuffer += recordSize;
  }

  return 0;
} // UtilLog::LogBufferDisplay

//**************************************************************************
// LogRecordDisplay
// Displays the log records
//**************************************************************************
int UtilLog::LogRecordDisplay( char      *recordBuffer,
                               sqluint32 recordSize,
                               sqluint16 recordType,
                               sqluint16 recordFlag )
{
  int       rc = 0;
  sqluint32 logManagerLogRecordHeaderSize = 0;
  char      *recordDataBuffer = NULL;
  sqluint32 recordDataSize = 0;
  char      *recordHeaderBuffer = NULL;
  sqluint8  componentIdentifier = 0;
  sqluint32 recordHeaderSize = 0;

  // determine the logManagerLogRecordHeaderSize
  logManagerLogRecordHeaderSize = 40;

  if( recordType == 0x0043 )  // compensation
  {
    logManagerLogRecordHeaderSize += 8; //V10 Extra Log stream ID 
    logManagerLogRecordHeaderSize += sizeof(db2Uint64);
    if( recordFlag & 0x0002 )    // propagatable
    {
      logManagerLogRecordHeaderSize += sizeof(db2Uint64);
    }
  }

  switch (recordType)
  {
    case 0x008A:                // Local Pending List
    case 0x0084:                // Normal Commit
    case 0x0041:                // Normal Abort
      recordDataBuffer = recordBuffer + logManagerLogRecordHeaderSize;
      recordDataSize = recordSize - logManagerLogRecordHeaderSize;
      rc = SimpleLogRecordDisplay( recordType,
                                   recordFlag,
                                   recordDataBuffer,
                                   recordDataSize );
      CHECKRC(rc, "SimpleLogRecordDisplay");
      break;
    case 0x004E:                // Normal
    case 0x0043:                // Compensation
      recordHeaderBuffer = recordBuffer + logManagerLogRecordHeaderSize;
      componentIdentifier = *(sqluint8 *) recordHeaderBuffer;
      switch (componentIdentifier)
      {
        case 1:                 // Data Manager Log Record
          recordHeaderSize = 6;
          break;
        default:
          cout << "    Unknown complex log record: " << recordSize
            << " " << recordType << " " << componentIdentifier << endl;
          return 1;
      }
      recordDataBuffer = recordBuffer +
        logManagerLogRecordHeaderSize + recordHeaderSize;
      recordDataSize = recordSize -
        logManagerLogRecordHeaderSize - recordHeaderSize;
      rc = ComplexLogRecordDisplay( recordType,
                                    recordFlag,
                                    recordHeaderBuffer,
                                    recordHeaderSize,
                                    componentIdentifier,
                                    recordDataBuffer,
                                    recordDataSize );
      CHECKRC(rc, "ComplexLogRecordDisplay");
      break;
    default:
      cout << "    Unknown log record: " << recordSize << " "
        << (char)recordType << endl;
      break;
  }

  return 0;
} // UtilLog::LogRecordDisplay

//**************************************************************************
// SimpleLogRecordDisplay
// Prints the minimum details of the log record
//**************************************************************************
int UtilLog::SimpleLogRecordDisplay( sqluint16 recordType,
                                     sqluint16 recordFlag,
                                     char      *recordDataBuffer,
                                     sqluint32 recordDataSize )
{
  int       rc = 0;
  sqluint32 timeTransactionCommited = 0;
  sqluint16 authIdLen = 0;
  char      *authId = NULL;

  switch (recordType)
  {
    case 138:
      cout << "\n    Record type: Local pending list" << endl;
      timeTransactionCommited = *(sqluint32 *) (recordDataBuffer);
      authIdLen = *(sqluint16 *) (recordDataBuffer + 2*sizeof(sqluint32));
      authId = (char *)malloc(authIdLen + 1);
      memset(authId, '\0', (authIdLen + 1 ));
      memcpy(authId, (char *)(recordDataBuffer + 2*sizeof(sqluint32) +
                              sizeof(sqluint16)), authIdLen);
      authId[authIdLen] = '\0';
      cout << "      UTC transaction committed(in secs since 70-01-01)" << ": "
        << dec << timeTransactionCommited << endl;
      cout << "      authorization ID of the application: " << authId << endl;
      break;
    case 132:
      cout << "\n    Record type: Normal commit" << endl;
      timeTransactionCommited = *(sqluint32 *) (recordDataBuffer);
      authIdLen = *(sqluint16 *) (recordDataBuffer + 2*sizeof(sqluint32));
      authId = (char *)malloc(authIdLen + 1);
      memset( authId, '\0', (authIdLen + 1 ));
      memcpy(authId, (char *)(recordDataBuffer + 2*sizeof(sqluint32) +
                              sizeof(sqluint16)), authIdLen);
      authId[authIdLen] = '\0';
      cout << "      UTC transaction committed(in secs since 70-01-01)" << ": "
        << dec << timeTransactionCommited << endl;
      cout << "      authorization ID of the application: " << authId << endl;
      break;
    case 65:
      cout << "\n    Record type: Normal abort" << endl;
      authIdLen = *(sqluint16 *) (recordDataBuffer);
      authId = (char *)malloc(authIdLen + 1);
      memset( authId, '\0', (authIdLen + 1 ));
      memcpy(authId, (char *)(recordDataBuffer + sizeof(sqluint16)), authIdLen);
      authId[authIdLen] = '\0';
      cout << "      authorization ID of the application: " << authId << endl;
      break;
    default:
      cout << "    Unknown simple log record: "
        << (char)recordType << " " << recordDataSize << endl;
      break;
  }

  return 0;

} // UtilLog::SimpleLogRecordDisplay

//**************************************************************************
// ComplexLogRecordDisplay
// Prints a detailed information of the log record
//**************************************************************************
int UtilLog::ComplexLogRecordDisplay( sqluint16 recordType,
                                      sqluint16 recordFlag,
                                      char      *recordHeaderBuffer,
                                      sqluint32 recordHeaderSize,
                                      sqluint8  componentIdentifier,
                                      char      *recordDataBuffer,
                                      sqluint32 recordDataSize )
{
  int rc = 0;
  sqluint8 functionIdentifier = 0;

  // for insert, delete, undo delete
  RID       recid;
  sqluint16 subRecordLen = 0;
  sqluint16 subRecordOffset = 0;
  char      *subRecordBuffer = NULL;

  // for update
  RID       newRID;
  sqluint16 newSubRecordLen = 0;
  sqluint16 newSubRecordOffset = 0;
  char      *newSubRecordBuffer = NULL;
  RID       oldRID;
  sqluint16 oldSubRecordLen = 0;
  sqluint16 oldSubRecordOffset = 0;
  char      *oldSubRecordBuffer = NULL;

  // for alter table attributes
  sqluint64 alterBitMask = 0;
  sqluint64 alterBitValues = 0;

  switch( recordType )
  {
    case 0x004E:
      cout << "\n    Record type: Normal" << endl;
      break;
    case 0x0043:
      cout << "\n    Record type: Compensation." << endl;
      break;
    default:
      cout << "\n    Unknown complex log record type: " << recordType
        << endl;
      break;
  }

  switch (componentIdentifier)
  {
    case 1:
      cout << "      component ID: DMS log record" << endl;
      break;
    default:
      cout << "      unknown component ID: " << componentIdentifier << endl;
      break;
  }

  functionIdentifier = *(sqluint8 *) (recordHeaderBuffer + 1);
  switch (functionIdentifier)
  {
    case 161:
      cout << "      function ID: Delete Record" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                           recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        recid.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay( subRecordBuffer, subRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 112:                                                     
      cout << "      function ID: Undo Update Record" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                           recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        recid.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay( subRecordBuffer, subRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 110:
      cout << "      function ID: Undo Insert Record" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      break; 
    case 111:
      cout << "      function ID: Undo Delete Record" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                                          recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        recid.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay(subRecordBuffer, subRecordLen);
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 162:
      cout << "      function ID: Insert Record" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                                          recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) + recid.size() +
                        sizeof(sqluint16);
      rc = LogSubRecordDisplay( subRecordBuffer, subRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 163:
      cout << "      function ID: Update Record" << endl;
      newSubRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      oldSubRecordLen = recordDataSize + 6 -       //NEW
                        2 * 20 -
                        newSubRecordLen;         
      oldRID.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      oldSubRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                               oldRID.size() ) );
      
      newRID.set( recordDataBuffer + 3 * sizeof(sqluint16) +
                  oldRID.size() + sizeof(sqluint16) + oldSubRecordLen +
                  recordHeaderSize + sizeof(sqluint16) );

      newSubRecordOffset = *(sqluint16 *)( recordDataBuffer      +
                                           3 * sizeof(sqluint16) +
                                           oldRID.size()         +
                                           sizeof(sqluint16)     +
                                           oldSubRecordLen       +
                                           recordHeaderSize      +
                                           newRID.size()         +
                                           sizeof(sqluint16) );
      cout << "        oldRID: " << dec << oldRID.getString() << endl;
      cout << "        old subrecord length: " << oldSubRecordLen << endl;
      cout << "        old subrecord offset: " << oldSubRecordOffset << endl;
      oldSubRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                           oldRID.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay( oldSubRecordBuffer, oldSubRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      cout << "        newRID: " << dec << newRID.getString() << endl;
      cout << "        new subrecord length: " << newSubRecordLen << endl;
      cout << "        new subrecord offset: " << newSubRecordOffset << endl;
      newSubRecordBuffer = recordDataBuffer      +
                           3 * sizeof(sqluint16) +
                           oldRID.size()         +
                           sizeof(sqluint16)     +
                           oldSubRecordLen       +
                           recordHeaderSize      +
                           3 * sizeof(sqluint16) +
                           newRID.size()         +
                           sizeof(sqluint16) ;
      rc = LogSubRecordDisplay( newSubRecordBuffer, newSubRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 165:
      cout << "      function ID: Insert Record to Empty Page" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                           recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        recid.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay( subRecordBuffer, subRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 164:
      cout << "      function ID: Delete Record to Empty Page" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                           recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        recid.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay( subRecordBuffer, subRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 166:
      cout << "      function ID: Rollback delete Record to Empty Page" << endl;
      subRecordLen = *( (sqluint16 *)( recordDataBuffer + sizeof(sqluint16) ) );
      recid.set( recordDataBuffer + 3 * sizeof(sqluint16) );
      subRecordOffset = *( (sqluint16 *)( recordDataBuffer + 3 * sizeof(sqluint16) +
                           recid.size() ) );
      cout << "        RID: " << dec << recid.getString() << endl;
      cout << "        subrecord length: " << subRecordLen << endl;
      cout << "        subrecord offset: " << subRecordOffset << endl;
      subRecordBuffer = recordDataBuffer + 3 * sizeof(sqluint16) +
                        recid.size() + sizeof(sqluint16);
      rc = LogSubRecordDisplay( subRecordBuffer, subRecordLen );
      CHECKRC(rc, "LogSubRecordDisplay");
      break;
    case 124:
      cout << "      function ID:  Alter Table Attribute" << endl;
      alterBitMask = *(sqluint64 *) (recordDataBuffer);
      alterBitValues = *( (sqluint64 *)(recordDataBuffer + sizeof(sqluint64) ) );
      if( alterBitMask & 0x00000001 )
      {
        // Propagation attribute altered
        cout << "        Propagation attribute is changed to ";
        if (alterBitValues & 0x00000001)
        {
          cout << "ON" << endl;
        }
        else
        {
          cout << "OFF" << endl;
        }
      }
      if (alterBitMask & 0x00000002)
      {
        // Check Pending attribute altered
        cout << "        Check Pending attr. changed to: ";
        if (alterBitValues & 0x00000002)
        {
          cout << "ON" << endl;
        }
        else
        {
          cout << "OFF" << endl;
        }
      }
      if (alterBitMask & 0x00010000)
      {
        // Append Mode attribute altered
        cout << "        Append Mode attr. changed to: ";
        if (alterBitValues & 0x00010000)
        {
          cout << "ON" << endl;
        }
        else
        {
          cout << "OFF" << endl;
        }
      }
      if (alterBitMask & 0x00200000)
      {
        // LF Propagation attribute altered
        cout << "        LF Propagation attribute is changed to ";
        if (alterBitValues & 0x00200000)
        {
          cout << "ON" << endl;
        }
        else
        {
          cout << "OFF" << endl;
        }
      }
      if (alterBitMask & 0x00400000)
      {
        // LOB Propagation attribute altered
        cout << "        LOB Propagation attr.changed to: ";
        if (alterBitValues & 0x00400000)
        {
          cout << "ON" << endl;
        }
        else
        {
          cout << "OFF" << endl;
        }
      }
      break;
    default:
      cout << "      unknown function identifier: "
        << functionIdentifier << endl;
      break;
  }

  return 0;
} // UtilLog::ComplexLogRecordDisplay

/***************************************************************************/
/* LogSubRecordDisplay                                                     */
/* Prints the sub records for the log                                      */
/***************************************************************************/
int UtilLog::LogSubRecordDisplay( char      *recordBuffer,
                                  sqluint16 recordSize )
{
  int       rc = 0;
  sqluint8  recordType = 0;
  sqluint8  updatableRecordType = 0;
  sqluint16 userDataFixedLength = 0;
  char      *userDataBuffer = NULL;
  sqluint16 userDataSize = 0;

  recordType = *(sqluint8 *) (recordBuffer);
  if ((recordType != 0) && (recordType != 4) && (recordType != 16))
  {
    cout << "        Unknown subrecord type." << endl;
  }
  else if (recordType == 4)
  {
    cout << "        subrecord type: Special control" << endl;
  }
  else
    // recordType == 0 or recordType == 16
    // record Type 0 indicates a normal record
    // record Type 16, for the purposes of this program, should be treated
    // as type 0
  {
    cout << "        subrecord type: Updatable, ";
    updatableRecordType = *(sqluint8 *) (recordBuffer + 4);
    if (updatableRecordType != 1)
    {
      cout << "Internal control" << endl;
    }
    else
    {
      cout << "Formatted user data" << endl;
      userDataFixedLength = *(sqluint16 *) (recordBuffer + 6);
      cout << "        user data fixed length: "
        << dec << userDataFixedLength << endl;
      userDataBuffer = recordBuffer + 8;
      userDataSize = recordSize - 8;
      rc = UserDataDisplay(userDataBuffer, userDataSize);
      CHECKRC(rc, "UserDataDisplay");
    }
  }
  return 0;
} // UtilLog::LogSubRecordDisplay

//**************************************************************************
// UserDataDisplay
// Displays the user data section
//**************************************************************************
int UtilLog::UserDataDisplay( char      *dataBuffer,
                              sqluint16 dataSize )
{
  int       rc = 0;
  sqluint16 line = 0;
  sqluint16 col = 0;
  const int rowLength = 10;

  cout << "        user data:" << endl;

  for (line = 0; line * rowLength < dataSize; line = line + 1)
  {
    cout << "        ";
    for (col = 0; col < rowLength; col = col + 1)
    {
      if (line * rowLength + col < dataSize)
      {
        cout.fill('0');
        cout.width(2);
        cout.setf(ios::uppercase);
        cout << hex << (int)(dataBuffer[line * rowLength + col] & 0x0ff) <<
          " ";
      }
      else
      {
        cout << "   ";
      }
    }
    cout << "*";
    for (col = 0; col < rowLength; col = col + 1)
    {
      if (line * rowLength + col < dataSize)
      {
        if (isalpha(dataBuffer[line * rowLength + col]) ||
            isdigit(dataBuffer[line * rowLength + col]))
        {
          cout << dataBuffer[line * rowLength + col];
        }
        else
        {
          cout << ".";
        }
      }
      else
      {
        cout << " ";
      }
    }
    cout << "*" << endl;
  }
  cout.setf(ios::dec);

  return 0;
} // UtilLog::UserDataDisplay
