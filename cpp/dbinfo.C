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
** SOURCE FILE NAME: dbinfo.C
**
** SAMPLE: Set and get information at the database level
**
** DB2 APIs USED:
**         db2CfgGet -- GET CONFIGURATION
**         db2CfgSet -- SET CONFIGURATION
**
** STRUCTURES USED:
**         sqlca 
**
** OUTPUT FILE: dbinfo.out (available in the online documentation)
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
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <string.h>
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

class DbInfo
{
  public:
    int LocalOrRemoteDbConfigSetGet(char *);
    int LocalOrRemoteDbConfigDefaultsSetGet(char *);

    // support functions
    int LocalOrRemoteDbConfigSave(db2Cfg);
    int LocalOrRemoteDbConfigRestore(db2Cfg);
};

int DbInfo::LocalOrRemoteDbConfigSave(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  // initialize paramArray
  cfgStruct.paramArray[0].flags = 0;
  cfgStruct.paramArray[0].token = SQLF_DBTN_TSM_OWNER;
  cfgStruct.paramArray[0].ptrvalue = new char[65];
  cfgStruct.paramArray[1].flags = 0;
  cfgStruct.paramArray[1].token = SQLF_DBTN_MAXAPPLS;
  cfgStruct.paramArray[1].ptrvalue = new char[sizeof(sqluint16)];

  cout << "\n**** SAVE DB CONFIG. FOR: " << cfgStruct.dbname << " ****"
       << endl;

  // get database configuration
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Save");

  return 0;
} //DbInfo::LocalOrRemoteDbConfigSave

int DbInfo::LocalOrRemoteDbConfigRestore(db2Cfg cfgStruct)
{
  struct sqlca sqlca;

  cout << "\n*** RESTORE DB CONFIG. FOR: " << cfgStruct.dbname << " ***"
       << endl;

  // set database configuration
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Restore");

  delete [] cfgStruct.paramArray[0].ptrvalue;
  delete [] cfgStruct.paramArray[1].ptrvalue;

  return 0;
} //DbInfo::LocalOrRemoteDbConfigRestore

int DbInfo::LocalOrRemoteDbConfigSetGet(char *dbAlias)
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  db2CfgGet -- GET CONFIGURATION" << endl;
  cout << "  db2CfgSet -- SET CONFIGURATION" << endl;
  cout << "TO SET/GET DATABASE CONFIGURATION PARAMETERS:" << endl;

  // initialize cfgParameters
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_TSM_OWNER;
  cfgParameters[0].ptrvalue = new char[65];
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[1].ptrvalue = new char[sizeof(sqluint16)];

  // set two database configuration parameters
  strcpy(cfgParameters[0].ptrvalue, "tsm_owner");
  *(sqluint16 *)(cfgParameters[1].ptrvalue) = 50;

  cout << "\n  Set the database configuration parameters for the \""
       << dbAlias << "\" database:" << endl;
  cout << "    TSM owner = " << cfgParameters[0].ptrvalue << endl;
  cout << "    maxappls  = "
       << *(sqluint16 *)(cfgParameters[1].ptrvalue) << endl;

  // initialize cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  // set database configuration
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Set");

  // get two database configuration parameters
  strcpy(cfgParameters[0].ptrvalue, "");
  *(sqluint16 *)(cfgParameters[1].ptrvalue) = 0;

  cout << "  Get two database configuration parameters for the \""
       << dbAlias << "\" database:" << endl;

  // get database configuration
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Config. -- Get");

  cout << "    TSM owner = " << cfgParameters[0].ptrvalue << endl;
  cout << "    maxappls  = " << *(sqluint16 *)(cfgParameters[1].ptrvalue)
       << endl;

  // free the memory allocated
  delete [] cfgParameters[0].ptrvalue;
  delete [] cfgParameters[1].ptrvalue;

  return 0;
} //DbInfo::LocalOrRemoteDbConfigSetGet

int DbInfo::LocalOrRemoteDbConfigDefaultsSetGet(char *dbAlias)
{
  struct sqlca sqlca;
  db2CfgParam cfgParameters[2];
  db2Cfg cfgStruct;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  db2CfgSet -- SET CONFIGURATION" << endl;
  cout << "  db2CfgGet -- GET CONFIGURATION" << endl;
  cout << "TO SET/GET DATABASE CONFIGURATION DEFAULTS:" << endl;

  // initialize cfgParameters
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_TSM_OWNER;
  cfgParameters[0].ptrvalue = new char[65];
  cfgParameters[1].flags = 0;
  cfgParameters[1].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[1].ptrvalue = new char[sizeof(sqluint16)];

  // set all database configuration defaults
  cout << "\n  Set all database configuration defaults for the \""
       << dbAlias << "\" database." << endl;

  // set cfgStruct
  cfgStruct.numItems = 0;
  cfgStruct.paramArray = NULL;
  cfgStruct.flags = db2CfgDatabase | db2CfgReset | db2CfgDelayed;
  cfgStruct.dbname = dbAlias;

  // reset database configuration
  db2CfgSet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Configuration defaults -- Set");

  // get two DB Config. defaults
  strcpy(cfgParameters[0].ptrvalue, "");
  *(sqluint16 *)(cfgParameters[1].ptrvalue) = 0;

  cout << "  Get two database configuration defaults for the \""
       << dbAlias << "\" database:" << endl;

  // set cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgGetDefaults;
  cfgStruct.dbname = dbAlias;

  // get database configuration defaults
  db2CfgGet(db2Version970, (void *)&cfgStruct, &sqlca);
  DB2_API_CHECK("DB Configuration Defaults -- Get");

  cout << "    TSM owner = " << cfgParameters[0].ptrvalue << endl;
  cout << "    maxappls  = " << *(sqluint16 *)(cfgParameters[1].ptrvalue)
       << endl;

  // free the memory allocated
  delete [] cfgParameters[0].ptrvalue;
  delete [] cfgParameters[1].ptrvalue;

  return 0;
} //DbInfo::LocalOrRemoteDbConfigDefaultsSetGet

int main(int argc, char *argv[])
{
  int rc = 0;
  CmdLineArgs check;
  DbInfo info;
  Db db;
  Instance inst;
  db2CfgParam cfgParameters[2]; // to save the DB Config.
  db2Cfg cfgStruct;

  // check the command line arguments
  rc = check.CmdLineArgsCheck3(argc, argv, db, inst);
  if (rc != 0)
  {
    return rc;
  }

  cout << "\nTHIS SAMPLE SHOWS HOW TO SET/GET INFO AT DATABASE LEVEL."
       << endl;

  // attach to a local or remote instance
  rc = inst.Attach();
  if (rc != 0)
  {
    return rc;
  }

  // initialize cfgStruct
  cfgStruct.numItems = 2;
  cfgStruct.paramArray = cfgParameters;
  cfgStruct.flags = db2CfgDatabase | db2CfgDelayed;
  cfgStruct.dbname = db.getAlias();

  // save DB. Config
  rc = info.LocalOrRemoteDbConfigSave(cfgStruct);
  if (rc != 0)
  {
    return rc;
  }

  // work with DB. Config
  rc = info.LocalOrRemoteDbConfigSetGet(db.getAlias());
  rc = info.LocalOrRemoteDbConfigDefaultsSetGet(db.getAlias());

  // restore DB Config
  rc = info.LocalOrRemoteDbConfigRestore(cfgStruct);

  // detach from the local or remote instance
  rc = inst.Detach();
  if (rc != 0)
  {
    return rc;
  }

  return 0;
} //main

