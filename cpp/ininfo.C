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
** SOURCE FILE NAME: ininfo.C
**
** SAMPLE: Set and get information at the instance level
**
** DB2 APIs USED:
**         db2CfgGet -- GET CONFIGURATION
**         db2CfgSet -- SET CONFIGURATION
**         sqlecadb -- CATALOG DATABASE
**         sqlectnd -- CATALOG NODE
**         sqledcgd -- CHANGE DATABASE COMMENT
**         db2DbDirCloseScan -- CLOSE DATABASE DIRECTORY SCAN
**         db2DbDirGetNextEntry -- GET NEXT DATABASE DIRECTORY ENTRY
**         db2DbDirOpenScan -- OPEN DATABASE DIRECTORY SCAN
**         sqlegdad -- ADD DCS DIRECTORY ENTRY
**         sqlegdcl -- CLOSE DCS DIRECTORY SCAN
**         sqlegdel -- DELETE DCS DIRECTORY ENTRY
**         sqlegdge -- GET DCS DIRECTORY ENTRY
**         sqlegdgt -- GET DCS DIRECTORY ENTRIES
**         sqlegdsc -- OPEN DCS DIRECTORY SCAN
**         sqlegins -- GET INSTANCE
**         sqlencls -- CLOSE NODE DIRECTORY SCAN
**         sqlengne -- GET NEXT NODE DIRECTORY ENTRY
**         sqlenops -- OPEN NODE DIRECTORY SCAN
**         sqlesdeg -- SET RUNTIME DEGREE
**         sqleuncn -- UNCATALOG NODE
**         sqleuncd -- UNCATALOG DATABASE
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
** For information on developing C++ applications, see the Application
** Development Guide.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, compiling, and running DB2
** applications, visit the DB2 application development website at
**       http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <string.h>
#include <stdlib.h>
#include <sqlutil.h>
#include <db2ApiDf.h>
#include <sqlenv.h>
#include "utilapi.h"
#if ((__cplusplus >= 199711L) && !defined DB2HP && !defined DB2AIX) || \
    (DB2LINUX && (__LP64__ || (__GNUC__ >= 3)) )
   #include <iostream>
   using namespace std;
#else
   #include <iostream.h>
#endif

class InInfo
{
  public:
    int CurrentLocalInstanceNameGet();
    int CurrentLocalNodeDirInfoSetGet();
    int CurrentLocalDatabaseDirInfoSetGet();
    int CurrentLocalDCSDirInfoSetGet();

    // support functions
    int LocalOrRemoteDbmConfigSave(db2Cfg);
    int LocalOrRemoteDbmConfigRestore(db2Cfg);

    int LocalOrRemoteDbmConfigSetGet();
    int LocalOrRemoteDbmConfigDefaultsSetGet();
    int LocalOrRemoteRunTimeDegreeSet();

  private:
    // helper functions
    void strnout(char *, int);
};

int InInfo::CurrentLocalInstanceNameGet()
{
  struct sqlca sqlca;
  char currentLocalInstanceName[SQL_INSTNAME_SZ + 1];

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  sqlegins -- GET INSTANCE" << endl;
  cout << "TO GET THE CURRENT LOCAL INSTANCE NAME:" << endl;

  // get local instance
  sqlegins(currentLocalInstanceName, &sqlca);
  DB2_API_CHECK("CurrentLocalInstanceName -- Get");

  cout << "\n  The current local instance name is: ";
  strnout(currentLocalInstanceName, SQL_INSTNAME_SZ);

  return 0;
} //InInfo::CurrentLocalInstanceNameGet

int InInfo::CurrentLocalNodeDirInfoSetGet()
{
  struct sqlca sqlca;
  struct sqle_node_struct newNode;
  struct sqle_node_tcpip TCPIPprotocol;
  unsigned short nodeDirHandle, nodeEntryNb, nbNodeEntries = 0;
  struct sqleninfo *nodeEntry;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqlectnd -- CATALOG NODE" << endl;
  cout << "  sqlenops -- OPEN NODE DIRECTORY SCAN" << endl;
  cout << "  sqlengne -- GET NEXT NODE DIRECTORY ENTRY" << endl;
  cout << "  sqlencls -- CLOSE NODE DIRECTORY SCAN" << endl;
  cout << "  sqleuncn -- UNCATALOG NODE" << endl;
  cout << "TO SET/GET THE LOCAL NODE DIRECTORY INFO.:" << endl;

  // --------------- catalog the new node ----------------------------
  strncpy(newNode.nodename, "newnode", SQL_NNAME_SZ + 1);
  strncpy(newNode.comment, "example of node comment", SQL_CMT_SZ + 1);
  newNode.struct_id = SQL_NODE_STR_ID;
  newNode.protocol = SQL_PROTOCOL_TCPIP;

  strncpy(TCPIPprotocol.hostname, "hostname", SQL_HOSTNAME_SZ + 1);
  strncpy(TCPIPprotocol.service_name,
          "servicename",
          SQL_SERVICE_NAME_SZ + 1);

  cout << "\n  Catalog the new node." << endl;
  cout << "\n    node name            : " << newNode.nodename << endl;
  cout << "    comment              : " << newNode.comment << endl;
  cout << "    structure identifier : SQL_NODE_STR_ID" << endl;
  cout << "    protocol             : SQL_PROTOCOL_TCPIP" << endl;
  cout << "    hostname             : " << TCPIPprotocol.hostname << endl;
  cout << "    service name         : " << TCPIPprotocol.service_name
       << endl;

  // catalog the node
  sqlectnd(&newNode, &TCPIPprotocol, &sqlca);
  DB2_API_CHECK("New Node -- Catalog");

  // ------------- read the node directory ---------------------------
  cout << "\n  Open the node directory." << endl;

  // open node directory scan
  sqlenops(&nodeDirHandle, &nbNodeEntries, &sqlca);
  DB2_API_CHECK("Node Directory -- Open");

  // read the node entries
  cout << "\n  Read the node directory." << endl;
  for (nodeEntryNb = 0; nodeEntryNb < nbNodeEntries; nodeEntryNb++)
  {
    // get next node directory entry
    sqlengne(nodeDirHandle, &nodeEntry, &sqlca);
    DB2_API_CHECK("Node Directory -- Read");

    // print out the node information on to the screen
    cout << "\n    node name            : ";
    strnout(nodeEntry->nodename, 8);
    cout << "    node comment         : ";
    strnout(nodeEntry->comment, 30);
    cout << "    node host name       : ";
    strnout(nodeEntry->hostname, 30);
    cout << "    node service name    : ";
    strnout(nodeEntry->service_name, 14);

    switch (nodeEntry->protocol)
    {
      case SQL_PROTOCOL_LOCAL:
        cout << "    node protocol        : LOCAL" << endl;
        break;
      case SQL_PROTOCOL_NPIPE:
        cout << "    node protocol        : NPIPE" << endl;
        break;
      case SQL_PROTOCOL_SOCKS:
        cout << "    node protocol        : SOCKS" << endl;
        break;
      case SQL_PROTOCOL_SOCKS4:
        cout << "    node protocol        : SOCKS4" << endl;
        break;
      case SQL_PROTOCOL_TCPIP:
        cout << "    node protocol        : TCP/IP" << endl;
        break;
      case SQL_PROTOCOL_TCPIP4:
        cout << "    node protocol        : TCP/IPv4" << endl;
        break;
      case SQL_PROTOCOL_TCPIP6:
        cout << "    node protocol        : TCP/IPv6" << endl;
        break;
      default:
        cout << "    node protocol        : " << endl;
        break;
    } //switch
  } //for

  // close node directory scan
  sqlencls(nodeDirHandle, &sqlca);
  DB2_API_CHECK("Node Directory -- Close");

  // ------------- uncatalog the new node ----------------------------
  cout << "\n  Uncatalog the node: " << newNode.nodename << endl;

  // uncatalog a node
  sqleuncn(newNode.nodename, &sqlca);
  DB2_API_CHECK("New Node -- Uncatalog");

  return 0;
} //InInfo::CurrentLocalNodeDirInfoSetGet

int InInfo::CurrentLocalDatabaseDirInfoSetGet()
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
  unsigned short dbAuthentication = SQL_AUTHENTICATION_SERVER;
  char *dbDirPath = NULL;
  db2Uint16 dbDirHandle = 0;
  db2Uint16 dbEntryNb = 0;
  char changedDbComment[] = "the changed db comment";
  db2Uint32 versionNumber = db2Version970;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqlecadb -- CATALOG DATABASE" << endl;
  cout << "  db2DbDirOpenScan -- OPEN DATABASE DIRECTORY SCAN" << endl;
  cout << "  db2DbDirGetNextEntry -- GET NEXT DATABASE DIRECTORY ENTRY" << endl;
  cout << "  sqledcgd -- CHANGE DATABASE COMMENT" << endl;
  cout << "  db2DbDirCloseScan -- CLOSE DATABASE DIRECTORY SCAN" << endl;
  cout << "  sqleuncd -- UNCATALOG DATABASE" << endl;
  cout << "TO SET/GET THE LOCAL DATABASE DIRECTORY INFO.:" << endl;

  // --------------- catalog the new database ------------------------
  cout << "\n  Catalog the new database." << endl;
  cout << "\n    database name        : " << dbName << endl;
  cout << "    database alias       : " << dbAlias << endl;
  cout << "    type                 : SQL_REMOTE" << endl;
  cout << "    node name            : " << nodeName << endl;
  cout << "    path                 : NULL" << endl;
  cout << "    comment              : " << dbComment << endl;
  cout << "    authentication       : SQL_AUTHENTICATION_SERVER" << endl;

  // catalog database
  sqlecadb(dbName,
           dbAlias,
           dbType,
           nodeName,
           dbPath,
           dbComment,
           dbAuthentication,
           NULL,
           &sqlca);

  // ignore warning SQL1100W = node not cataloged,
  // don't do the same in your code
  if (sqlca.sqlcode != 1100)
  {
    DB2_API_CHECK("Database -- Catalog");
  }

  // ------------- read the database directory -----------------------
  cout << "\n  Open the database directory." << endl;

  // open database directory scan
  dbDirOpenParmStruct.piPath = dbDirPath;
  dbDirOpenParmStruct.oHandle = dbDirHandle;
  db2DbDirOpenScan(versionNumber,
                   &dbDirOpenParmStruct,
                   &sqlca);

  DB2_API_CHECK("Database Directory -- Open");

  // read the database entries
  cout << "\n  Read the database directory." << endl;
  dbDirNextEntryParmStruct.iHandle = dbDirHandle;
  dbDirNextEntryParmStruct.poDbDirEntry = dbEntry;
  for (dbEntryNb = 1; dbEntryNb <= dbDirOpenParmStruct.oNumEntries; dbEntryNb++)
  {
    // get next database directory entry
    db2DbDirGetNextEntry(versionNumber,
                         &dbDirNextEntryParmStruct,
                         &sqlca);

    DB2_API_CHECK("Database Directory -- Read");

    dbEntry = dbDirNextEntryParmStruct.poDbDirEntry;

    // print out the database information on to the screen
    cout << "\n    database alias       : ";
    strnout(dbEntry->alias, 8);
    cout << "    database name        : ";
    strnout(dbEntry->dbname, 8);
#if (defined(DB2NT))
    cout << "    database drive       : ";
    strnout(dbEntry->drive, 12);
#else //UNIX
    cout << "    database drive       : ";
    strnout(dbEntry->drive, 215);
#endif
    cout << "    database subdirectory: ";
    strnout(dbEntry->intname, 8);
    cout << "    node name            : ";
    strnout(dbEntry->nodename, 8);
    cout << "    database release type: ";
    strnout(dbEntry->dbtype, 20);
    cout << "    database comment     : ";
    strnout(dbEntry->comment, 30);

    switch (dbEntry->type)
    {
      case SQL_INDIRECT:
        cout << "    database entry type  : indirect" << endl;
        break;
      case SQL_REMOTE:
        cout << "    database entry type  : remote" << endl;
        break;
      case SQL_HOME:
        cout << "    database entry type  : home" << endl;
        break;
      case SQL_DCE:
        cout << "    database entry type  : dce" << endl;
        break;
      default:
        break;
    }

    switch (dbEntry->authentication)
    {
      case SQL_AUTHENTICATION_SERVER:
        cout << "    authentication       : SERVER" << endl;
        break;
      case SQL_AUTHENTICATION_CLIENT:
        cout << "    authentication       : CLIENT" << endl;
        break;
      case SQL_AUTHENTICATION_DCS:
        cout << "    authentication       : DCS" << endl;
        break;
      default:
        break;
    } //switch
  } //for

  // change the database comment for the new database
  cout << "\n  Change the new database comment to:" << endl;
  cout << "    " << changedDbComment << endl;

  // change database comment
  sqledcgd(dbAlias, "", changedDbComment, &sqlca);
  DB2_API_CHECK("Database Comment -- Change");

  // close database directory scan
  dbDirCloseParmStruct.iHandle = dbDirHandle;
  db2DbDirCloseScan(versionNumber,
                    &dbDirCloseParmStruct,
                    &sqlca);

  DB2_API_CHECK("Database Directory -- Close");

  // ------------- uncatalog the new database ------------------------
  cout << "\n  Uncatalog the database cataloged as: " << dbAlias << endl;

  // uncatalog the database
  sqleuncd(dbAlias, &sqlca);
  DB2_API_CHECK("Database -- Uncatalog");

  return 0;
} //InInfo::CurrentLocalDatabaseDirInfoSetGet

int InInfo::CurrentLocalDCSDirInfoSetGet()
{
  struct sqlca sqlca;
  struct sql_dir_entry newDcsDbEntry;
  struct sql_dir_entry dcsDbEntry;
  short dcsDbEntryNb, nbDcsDbEntries = 0;
  struct sql_dir_entry *pAllDcsDbEntries;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqlegdad -- ADD DCS DIRECTORY ENTRY" << endl;
  cout << "  sqlegdsc -- OPEN DCS DIRECTORY SCAN" << endl;
  cout << "  sqlegdge -- GET DCS DIRECTORY ENTRY" << endl;
  cout << "  sqlegdgt -- GET DCS DIRECTORY ENTRIES" << endl;
  cout << "  sqlegdcl -- CLOSE DCS DIRECTORY SCAN" << endl;
  cout << "  sqlegdel -- DELETE DCS DIRECTORY ENTRY" << endl;
  cout << "TO SET/GET THE LOCAL DCS DIRECTORY INFO.:" << endl;

  // --------------- catalog the new DCS database --------------------
  strcpy(newDcsDbEntry.ldb, "dcsAlias");
  strcpy(newDcsDbEntry.tdb, "dcsDbName");
  strcpy(newDcsDbEntry.comment, "dcsDb comment");
  strcpy(newDcsDbEntry.ar, "appName");
  strcpy(newDcsDbEntry.parm, "");
  newDcsDbEntry.struct_id = SQL_DCS_STR_ID;

  cout << "\n  Catalog the new DCS database." << endl;
  cout << "\n    intermediate alias   : " << newDcsDbEntry.ldb << endl;
  cout << "    name                 : " << newDcsDbEntry.tdb << endl;
  cout << "    comment              : " << newDcsDbEntry.comment << endl;
  cout << "    client app. name     : " << newDcsDbEntry.ar << endl;

  // catalog DCS database
  sqlegdad(&newDcsDbEntry, &sqlca);
  DB2_API_CHECK("New DCS Database -- Catalog");

  // ------------- read the DCS database directory -------------------
  cout << "\n  Open the DCS database directory." << endl;

  // open DCS database directory
  sqlegdsc(&nbDcsDbEntries, &sqlca);
  DB2_API_CHECK("DCS Database Directory -- Open");

  // read a specific entry from the DCS database directory
  strcpy(dcsDbEntry.ldb, "dcsAlias");
  strcpy(dcsDbEntry.tdb, "");
  strcpy(dcsDbEntry.comment, "");
  strcpy(dcsDbEntry.ar, "");
  strcpy(dcsDbEntry.parm, "");
  dcsDbEntry.struct_id = SQL_DCS_STR_ID;

  cout << "\n  Read the entry for the DCS database: "
       << dcsDbEntry.ldb << endl;

  // get DCS directory entry for database
  sqlegdge(&dcsDbEntry, &sqlca);
  DB2_API_CHECK("DCS database entry -- read");

  cout << "\n    intermediate alias   : ";
  strnout(dcsDbEntry.ldb, 8);
  cout << "    name                 : ";
  strnout(dcsDbEntry.tdb, 18);
  cout << "    comment              : ";
  strnout(dcsDbEntry.comment, 30);
  cout << "    client app. name     : ";
  strnout(dcsDbEntry.ar, 32);
  cout << "    DCS parameters       : ";
  strnout(dcsDbEntry.parm, 48);
  cout << "    DCS release level    : 0x"
       << hex << dcsDbEntry.release << endl;

  if (nbDcsDbEntries > 0)
  {
    pAllDcsDbEntries = new sql_dir_entry[nbDcsDbEntries];

    cout << "\n  Read the DCS database directory." << endl;

    // get DCS database directory entries
    sqlegdgt(&nbDcsDbEntries, pAllDcsDbEntries, &sqlca);
    DB2_API_CHECK("DCS Database Directory -- Read");

    // print the DCS database entries
    for (dcsDbEntryNb = 0; dcsDbEntryNb < nbDcsDbEntries; dcsDbEntryNb++)
    {
      cout << "\n    intermediate alias   : ";
      strnout(pAllDcsDbEntries[dcsDbEntryNb].ldb, 8);
      cout << "    name                 : ";
      strnout(pAllDcsDbEntries[dcsDbEntryNb].tdb, 18);
      cout << "    comment              : ";
      strnout(pAllDcsDbEntries[dcsDbEntryNb].comment, 30);
      cout << "    client app. name     : ";
      strnout(pAllDcsDbEntries[dcsDbEntryNb].ar, 32);
      cout << "    DCS parameters       : ";
      strnout(pAllDcsDbEntries[dcsDbEntryNb].parm, 48);
      cout << "    DCS release level    : 0x"
           << hex << pAllDcsDbEntries[dcsDbEntryNb].release << endl;
    } //for
  }
  delete pAllDcsDbEntries;

  // close DCS directory scan
  sqlegdcl(&sqlca);
  DB2_API_CHECK("DCS Directory -- Close");

  // ------------- uncatalog the new DCS database --------------------
  strcpy(newDcsDbEntry.ldb, "dcsAlias");
  strcpy(newDcsDbEntry.tdb, "");
  strcpy(newDcsDbEntry.comment, "");
  strcpy(newDcsDbEntry.ar, "");
  strcpy(newDcsDbEntry.parm, "");
  newDcsDbEntry.struct_id = SQL_DCS_STR_ID;

  cout << "\n  Uncatalog the DCS database: " << newDcsDbEntry.ldb << endl;

  // uncatalog DCS database
  sqlegdel(&newDcsDbEntry, &sqlca);
  DB2_API_CHECK("New DCS database -- Uncatalog");

  return 0;
} //InInfo::CurrentLocalDCSDirInfoSetGet

int InInfo::LocalOrRemoteDbmConfigSave(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  // initialize paramArray
  cfgStruct.paramArray[0].flags = 0;
  cfgStruct.paramArray[0].token = SQLF_KTN_DFT_ACCOUNT_STR;
  cfgStruct.paramArray[0].ptrvalue = new char[SQL_ACCOUNT_STR_SZ + 1];
  cfgStruct.paramArray[1].flags = 0;
  cfgStruct.paramArray[1].token = SQLF_KTN_UDF_MEM_SZ;
  cfgStruct.paramArray[1].ptrvalue = (char *)new unsigned short;

  cout << "\n******* SAVE DATABASE MANAGER CONFIGURATION **********" << endl;

  // get database manager configuration
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Save");

  return 0;
} //InInfo::LocalOrRemoteDbmConfigSave

int InInfo::
LocalOrRemoteDbmConfigRestore(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  cout << "\n******  RESTORE DATABASE MANAGER CONFIGURATION ******" << endl;

  // update database manager configuration
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Restore");

  delete [] cfgStruct.paramArray[0].ptrvalue;
  delete [] cfgStruct.paramArray[1].ptrvalue;

  return 0;
} //InInfo::LocalOrRemoteDbmConfigRestore

int InInfo::LocalOrRemoteDbmConfigSetGet()
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  db2CfgSet -- SET CONFIGURATION" << endl;
  cout << "  db2CfgGet -- GET CONFIGURATION" << endl;
  cout << "TO SET/GET DATABASE MANAGER CONFIGURATION PARAMETERS:" << endl;

  // initialize cfgParameters
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_KTN_DFT_ACCOUNT_STR;
  cfgParameters[0].ptrvalue = new char[SQL_ACCOUNT_STR_SZ + 1];
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_KTN_UDF_MEM_SZ;
  cfgParameters[1].ptrvalue = (char *)new unsigned short;

  // set two Database Configuration parameters
  strcpy(cfgParameters[0].ptrvalue, "accounting string suffix");
  *(unsigned short *)(cfgParameters[1].ptrvalue) = 512;
  cout << "\n  Set the Database Manager Configuration parameters:" << endl;
  cout << "    dft_account_str = " << cfgParameters[0].ptrvalue << endl;
  cout << "    udf_mem_sz      = " << dec
       << *(unsigned short *)(cfgParameters[1].ptrvalue) << endl;

  // initialize cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgDelayed;
  cfgStruct.dbname = NULL;

  // set database manager configuration
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Set");

  // get two DBM Config. fields
  strcpy(cfgParameters[0].ptrvalue, "");
  *(unsigned short *)(cfgParameters[1].ptrvalue) = 0;

  cout << "\n  Get two Database Manager Configuration parameters:" << endl;

  // get database manager configuration
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. -- Get");

  cout << "    dft_account_str = " << cfgParameters[0].ptrvalue << endl;
  cout << "    udf_mem_sz      = "
       << *(unsigned short *)(cfgParameters[1].ptrvalue) << endl;

  // free the memory allocated
  delete [] cfgParameters[0].ptrvalue;
  delete [] cfgParameters[1].ptrvalue;

  return 0;
} //InInfo::LocalOrRemoteDbmConfigSetGet

int InInfo::LocalOrRemoteDbmConfigDefaultsSetGet()
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;
  char input;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  db2CfgSet -- SET CONFIGURATION" << endl;
  cout << "  db2CfgGet -- GET CONFIGURATION" << endl;
  cout << "TO SET/GET DATABASE MANAGER CONFIGURATION DEFAULTS:" << endl;

  // initialize cfgParameters
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_KTN_DFT_ACCOUNT_STR;
  cfgParameters[0].ptrvalue = new char[SQL_ACCOUNT_STR_SZ + 1];
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_KTN_UDF_MEM_SZ;
  cfgParameters[1].ptrvalue = (char *)new unsigned short;

  // get two DBM Config. defaults
  strcpy(cfgParameters[0].ptrvalue, "");
  *(unsigned short *)(cfgParameters[1].ptrvalue) = 0;

  // initialize cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgGetDefaults;
  cfgStruct.dbname = NULL;

  cout << "\n  Get two Database Manager Configuration defaults:" << endl;

  // get database manager configuration defaults
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DBM Config. Defaults -- Get");

  cout << "    dft_account_str = " << cfgParameters[0].ptrvalue << endl;
  cout << "    udf_mem_sz      = "
       << *(unsigned short *)(cfgParameters[1].ptrvalue) << endl;

  /* warning for reset of DBM Congif. */
  cout << endl;
  cout << "  Warning: We are now about to set all Database Manager\n"
          "  Configuration parameters to default using the API, db2CfgSet.\n"
          "  After running this API, some of the non-default user\n"
          "  settings and those set by the installation program will\n"
          "  be changed accordingly and will not be restored by\n"
          "  this program.  A text file, dbmcfg.TXT, will be generated\n"
          "  in the current directory for all the settings before\n"
          "  execution of this API.  The user is required to restore the\n"
          "  settings manually.\n";
  cout << endl;
  cout << "  Would you like to run this API?(y/n) ";

  // get user input
  cin >> input;
  if (input == 'y')
  {
    // save DBM Config. to a text file
    system("db2 get dbm cfg >dbmcfg.TXT");

    // set all DBM Config. defaults
    cout << "\n  Set all Database manager Configuration parameters";
    cout << " to default." << endl;

    // initialize cfgStruct
    cfgStruct.numItems = 0;
    cfgStruct.paramArray = NULL;
    cfgStruct.flags = db2CfgDatabaseManager | db2CfgReset | db2CfgDelayed;
    cfgStruct.dbname = NULL;

    // reset database manager configuration
    db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
    DB2_API_CHECK("DBM Config. defaults -- Set");

    cout << "\n  All Database Manager Configuration parameters";
    cout << "  are set to default." << endl;
  }

  // free the memory allocated
  delete [] cfgParameters[0].ptrvalue;
  delete [] cfgParameters[1].ptrvalue;

  return 0;
} //InInfo::LocalOrRemoteDbmConfigDefaultsSetGet

int InInfo::LocalOrRemoteRunTimeDegreeSet()
{
  struct sqlca sqlca;
  sqlint32 runTimeDegree;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  sqlesdeg -- SET RUNTIME DEGREE" << endl;
  cout << "TO SET THE RUN TIME DEGREE:" << endl;

  // set the run time degree
  runTimeDegree = 4;
  cout << "\n  Set the run time degree to the value: "
       << runTimeDegree << endl;

  // set runtime degree
  sqlesdeg(SQL_ALL_USERS, NULL, runTimeDegree, &sqlca);
  DB2_API_CHECK("Run Time Degree -- Set");

  return 0;
} //InInfo::LocalOrRemoteRunTimeDegreeSet

void InInfo::strnout(char *str, int n)
{
  for (int i = 0; (i < n) && (str[i] != '\0'); cout << str[i++]);
  cout << endl;

  return;
} //InInfo::strnout

int main(int argc, char *argv[])
{
  int rc = 0;
  CmdLineArgs check;
  InInfo info;
  Instance inst;
  db2CfgParam cfgParameters[2]; // to save the DBM Config.
  db2Cfg cfgStruct;

  // initialize cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabaseManager | db2CfgDelayed;
  cfgStruct.dbname = NULL;

  // check the command line arguments
  rc = check.CmdLineArgsCheck2(argc, argv, inst);
  if (rc != 0)
  {
    return rc;
  }

  cout << "\nTHIS SAMPLE SHOWS HOW TO SET/GET INFO AT INSTANCE LEVEL."
       << endl;

  // set/get info for the local instance that has as name
  // the value of the environment variable DB2INSTANCE
  rc = info.CurrentLocalInstanceNameGet();
  rc = info.CurrentLocalNodeDirInfoSetGet();
  rc = info.CurrentLocalDatabaseDirInfoSetGet();
  rc = info.CurrentLocalDCSDirInfoSetGet();

  // attach to a local or remote instance
  rc = inst.Attach();
  if (rc != 0)
  {
    return rc;
  }

  // save DBM Config.
  rc = info.LocalOrRemoteDbmConfigSave(cfgStruct);
  if (rc != 0)
  {
    return rc;
  }

  // work with DBM Config.
  rc = info.LocalOrRemoteDbmConfigSetGet();

  // restore DBM Config.
  rc = info.LocalOrRemoteDbmConfigRestore(cfgStruct);

  // work with DBM Config.
  rc = info.LocalOrRemoteDbmConfigDefaultsSetGet();

  // set the run time degree
  rc = info.LocalOrRemoteRunTimeDegreeSet();

  // detach from the local or remote instance
  rc = inst.Detach();
  if (rc != 0)
  {
    return rc;
  }

  return 0;
} //main

