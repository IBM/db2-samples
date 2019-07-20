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
** SOURCE FILE NAME: dbupgrade.C
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
** For information on developing C++ applications, see the Application
** Development Guide.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, compiling, and running DB2
** applications, visit the DB2 application development website at
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <db2ApiDf.h>
#include <sqlutil.h>
#include "utilapi.h"
#if ((__cplusplus >= 199711L) && !defined DB2HP && !defined DB2AIX) || \
    (DB2LINUX && (__LP64__ || (__GNUC__ >= 3)) )
   #include <iostream>
   using namespace std; 
#else
   #include <iostream.h>
#endif

class DbUpgrade
{
  public:
    int Upgrade(Db &);
  private:
    struct sqlca sqlca;
};

int DbUpgrade::Upgrade(Db & db)
{
  db2DatabaseUpgradeStruct DatabaseUpgradeParam = { 0 };

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  db2DatabaseUpgrade -- UPGRADE DATABASE" << endl;
  cout << "TO UPGRADE A DATABASE TO CURRENT FORMATS." << endl;

  cout << "\n  Upgrade the \"" << db.getAlias() << "\" database." << endl;

  DatabaseUpgradeParam.piDbAlias = db.getAlias();
  DatabaseUpgradeParam.piUserName = db.getUser();
  DatabaseUpgradeParam.piPassword = db.getPswd();
  DatabaseUpgradeParam.iDbAliasLen = SQL_ALIAS_SZ + 1;
  DatabaseUpgradeParam.iUserNameLen = USERID_SZ + 1;
  DatabaseUpgradeParam.iPasswordLen = PSWD_SZ + 1;

  // upgrade the database
  db2DatabaseUpgrade(db2Version970, &DatabaseUpgradeParam ,&sqlca);
  if (sqlca.sqlcode != SQLE_RC_MIG_OK)
  {
    DB2_API_CHECK("Database -- Upgrade");
  }

  return 0;
} //DbUpgrade::Upgrade

int main(int argc, char *argv[])
{
  int rc = 0;
  CmdLineArgs check;
  DbUpgrade dbUpgrade;
  Db db;

  // check the command line arguments
  rc = check.CmdLineArgsCheck1(argc, argv, db);
  if (rc != 0)
  {
    return rc;
  }

  cout << "\nTHIS SAMPLE SHOWS HOW TO UPGRADE A DATABASE." << endl;

  dbUpgrade.Upgrade(db);

  return 0;
} // main

