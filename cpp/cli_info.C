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
** SOURCE FILE NAME: cli_info.C
**
** SAMPLE: Set and get information at the client level
**
** DB2 APIs USED:
**         sqleseti -- SET CLIENT INFORMATION
**         sqleqryi -- QUERY CLIENT INFORMATION
**         sqlesetc -- SET CLIENT         
**         sqleqryc -- QUERY CLIENT
**
** STRUCTURES USED:
**         sqle_client_info 
**         sqle_conn_setting
**         sqlca
**
** OUTPUT FILE: cli_info.out (available in the online documentation)
*****************************************************************************
*
* For information on developing C++ applications, see the Application
* Development Guide.
*
* For more information on DB2 APIs, see the Administrative API Reference.
*
* For the latest information on programming, compiling, and running DB2 
* applications, visit the DB2 application development website: 
*     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <string.h>
#include <sqlenv.h>
#include "utilapi.h"
#if ((__cplusplus >= 199711L) && !defined DB2HP && !defined DB2AIX) || \
    (DB2LINUX && (__LP64__ || (__GNUC__ >= 3)) )
   #include <iostream>
   using namespace std; 
#else
   #include <iostream.h>
#endif

class ApInfo
{
  public:
    static int ClientAppNameSetGet();
    static int ClientUseridSetGet();
    static int ClientWorkstationSetGet();
    static int ClientSuffixForAccountingStringSetGet();
    static int ClientConnectionAttrsSetGet();
};

int ApInfo::ClientAppNameSetGet()
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];
  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqleseti -- SET CLIENT INFORMATION" << endl;
  cout << "  sqleqryi -- QUERY CLIENT INFORMATION" << endl;
  cout << "TO SET/GET THE CLIENT APPLICATION NAME:" << endl;

  // specify all the connections
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  // initialize clientAppInfo
  clientAppInfo[0].type = SQLE_CLIENT_INFO_APPLNAME;
  clientAppInfo[0].pValue =
    (char *)new char[SQLE_CLIENT_APPLNAME_MAX_LEN + 1];

  // set client application name
  strcpy(clientAppInfo[0].pValue, "ClientApplicationName");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  cout << "\n  Set the Client Application Name to the value:" << endl;
  cout << "    " << clientAppInfo[0].pValue << endl;

  // set client information
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Application Name -- set");

  // get client application name
  strcpy(clientAppInfo[0].pValue, "");
  cout << "  Get the Client Application Name." << endl;

  // query client information
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Application Name -- get");

  cout << "  The Client Application Name is:" << endl;
  cout << "    " << clientAppInfo[0].pValue << endl;

  // release the memory allocated
  delete [] clientAppInfo[0].pValue;

  return 0;
} //ApInfo::ClientAppNameSetGet

int ApInfo::ClientUseridSetGet()
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];
  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqleseti -- SET CLIENT INFORMATION" << endl;
  cout << "  sqleqryi -- QUERY CLIENT INFORMATION" << endl;
  cout << "TO SET/GET THE CLIENT USER ID:" << endl;

  // specify all the connections
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  // initialize clientAppInfo
  clientAppInfo[0].type = (unsigned short)SQLE_CLIENT_INFO_USERID;
  clientAppInfo[0].pValue = (char *)new char[SQLE_CLIENT_USERID_MAX_LEN + 1];

  // set client user ID
  strcpy(clientAppInfo[0].pValue, "ClientUserid");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  cout << "\n  Set the Client User ID to the value:" << endl;
  cout << "    " << clientAppInfo[0].pValue << endl;

  // set client information
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client User ID -- set");

  // get client user ID 
  strcpy(clientAppInfo[0].pValue, "");
  cout << "  Get the Client User ID." << endl;

  // query client information
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client User ID -- get");

  cout << "  The Client User ID is:" << endl;
  cout << "    " << clientAppInfo[0].pValue << endl;

  // release the memory allocated
  delete [] clientAppInfo[0].pValue;

  return 0;
} //ApInfo::ClientUseridSetGet

int ApInfo::ClientWorkstationSetGet()
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];
  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqleseti -- SET CLIENT INFORMATION" << endl;
  cout << "  sqleqryi -- QUERY CLIENT INFORMATION" << endl;
  cout << "TO SET/GET THE CLIENT WORKSTATION NAME:" << endl;

  // specify all the connections
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  // initialize clientAppInfo
  clientAppInfo[0].type = SQLE_CLIENT_INFO_WRKSTNNAME;
  clientAppInfo[0].pValue =
    (char *)new char[SQLE_CLIENT_WRKSTNNAME_MAX_LEN + 1];

  // set client workstation
  strcpy(clientAppInfo[0].pValue, "ClientWorkstation");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  cout << "\n  Set the Client Workstation Name to the value:";
  cout << "\n    " << clientAppInfo[0].pValue << endl;

  // set client information
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Workstation Name -- set");

  // get client workstation
  strcpy(clientAppInfo[0].pValue, "");
  cout << "  Get the Client Workstation Name." << endl;

  // query client information
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Workstation Name -- get");

  cout << "  The Client Workstation Name is:" << endl;
  cout << "    " << clientAppInfo[0].pValue << endl;

  // release the memory allocated
  delete [] clientAppInfo[0].pValue;

  return 0;
} //ApInfo::ClientWorkstationSetGet

int ApInfo::ClientSuffixForAccountingStringSetGet()
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];
  char clientAccStrSuffix[] = "ClientSuffixForAccountingString";
  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqleseti -- SET CLIENT INFORMATION" << endl;
  cout << "  sqleqryi -- QUERY CLIENT INFORMATION" << endl;
  cout << "TO SET/GET THE CLIENT SUFFIX FOR THE ACCOUNTING STRING:";
  cout << endl;

  // specify all the connections
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  // initialize clientAppInfo
  clientAppInfo[0].type = SQLE_CLIENT_INFO_ACCTSTR;
  clientAppInfo[0].pValue =
    (char *)new char[SQLE_CLIENT_APPLNAME_MAX_LEN + 1];

  // set client suffix for accounting string
  strcpy(clientAppInfo[0].pValue, "ClientSuffixForAccountingString");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  cout << "\n  Use the DB2 API sqleseti to set the Client Suffix";
  cout << "\n  for the Accounting String to the value:";
  cout << "\n    " << clientAppInfo[0].pValue << endl;

  // set client information
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Suffix for Accounting String -- set");

  // get client suffix for accounting string
  strcpy(clientAppInfo[0].pValue, "");
  cout << "  Get the Client Suffix for the Accounting String." << endl;

  // query client information
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Suffix for Accounting String -- get");

  cout << "  The Client Suffix for the Accounting String is:" << endl;
  cout << "    " << clientAppInfo[0].pValue << endl;

  // release the memory allocated
  delete [] clientAppInfo[0].pValue;

  return 0;
} //ApInfo::ClientSuffixForAccountingStringSetGet

int ApInfo::ClientConnectionAttrsSetGet()
{
  struct sqlca sqlca;
  struct sqle_conn_setting clientAppInfo[8];

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 APIs:" << endl;
  cout << "  sqlesetc -- SET CLIENT" << endl;
  cout << "  sqleqryc -- QUERY CLIENT" << endl;
  cout << "TO SET/GET THE CLIENT CONNECTION ATTRIBUTES:" << endl;

  // initialize clientAppInfo
  clientAppInfo[0].type = SQL_CONNECT_TYPE;
  clientAppInfo[1].type = SQL_RULES;
  clientAppInfo[2].type = SQL_DISCONNECT;
  clientAppInfo[3].type = SQL_SYNCPOINT;
  clientAppInfo[4].type = SQL_MAX_NETBIOS_CONNECTIONS;
  clientAppInfo[5].type = SQL_DEFERRED_PREPARE;
  clientAppInfo[6].type = SQL_CONNECT_NODE;
  clientAppInfo[7].type = SQL_ATTACH_NODE;

  clientAppInfo[0].value = SQL_CONNECT_2;
  clientAppInfo[1].value = SQL_RULES_STD;
  clientAppInfo[2].value = SQL_DISCONNECT_COND;
  clientAppInfo[3].value = SQL_SYNC_ONEPHASE;
  clientAppInfo[4].value = 16;
  clientAppInfo[5].value = SQL_DEFERRED_PREPARE_YES;
  clientAppInfo[6].value = 3;
  clientAppInfo[7].value = 3;

  // set client connection attributes
  cout << "\n  Set the Client Connection Attributes to the values:";
  cout << "\n    SQL_CONNECT_TYPE            = SQL_CONNECT_2";
  cout << "\n    SQL_RULES                   = SQL_RULES_STD";
  cout << "\n    SQL_DISCONNECT              = SQL_DISCONNECT_COND";
  cout << "\n    SQL_SYNCPOINT               = SQL_SYNC_ONEPHASE";
  cout << "\n    SQL_MAX_NETBIOS_CONNECTIONS = 16";
  cout << "\n    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_YES";
  cout << "\n    SQL_CONNECT_NODE            = 3";
  cout << "\n    SQL_ATTACH_NODE             = 3" << endl;

  // set client
  sqlesetc(&clientAppInfo[0], 8, &sqlca);
  DB2_API_CHECK("Client Connection Attributes -- set");

  // get client connection attributes

  // reset clientAppInfo
  clientAppInfo[0].value = SQL_CONNECT_1;
  clientAppInfo[1].value = SQL_RULES_DB2;
  clientAppInfo[2].value = SQL_DISCONNECT_EXPL;
  clientAppInfo[3].value = SQL_SYNC_TWOPHASE;
  clientAppInfo[4].value = 1;
  clientAppInfo[5].value = SQL_DEFERRED_PREPARE_NO;
  clientAppInfo[6].value = 1;
  clientAppInfo[7].value = 1;

  cout << "  Get the Client Connection Attributes." << endl;

  // query client
  sqleqryc(&clientAppInfo[0], 8, &sqlca);
  DB2_API_CHECK("Client Conn. Attrs. -- get");

  cout << "  The Client Connection Attributes are:" << endl;
  switch (clientAppInfo[0].value)
  {
    case SQL_CONNECT_1:
      cout << "    SQL_CONNECT_TYPE            = SQL_CONNECT_1";
      cout << endl;
      break;
    case SQL_CONNECT_2:
      cout << "    SQL_CONNECT_TYPE            = SQL_CONNECT_2";
      cout << endl;
      break;
    default:
      break;
  }

  switch (clientAppInfo[1].value)
  {
    case SQL_RULES_DB2:
      cout << "    SQL_RULES                   = SQL_RULES_DB2";
      cout << endl;
      break;
    case SQL_RULES_STD:
      cout << "    SQL_RULES                   = SQL_RULES_STD";
      cout << endl;
      break;
    default:
      break;
  }

  switch (clientAppInfo[2].value)
  {
    case SQL_DISCONNECT_EXPL:
      cout << "    SQL_DISCONNECT              = SQL_DISCONNECT_EXPL";
      cout << endl;
      break;
    case SQL_DISCONNECT_COND:
      cout << "    SQL_DISCONNECT              = SQL_DISCONNECT_COND";
      cout << endl;
      break;
    case SQL_DISCONNECT_AUTO:
      cout << "    SQL_DISCONNECT              = SQL_DISCONNECT_EXPL";
      cout << endl;
      break;
    default:
      break;
  }

  switch (clientAppInfo[3].value)
  {
    case SQL_SYNC_TWOPHASE:
      cout << "    SQL_SYNCPOINT               = SQL_SYNC_TWOPHASE" << endl;
      break;
    case SQL_SYNC_ONEPHASE:
      cout << "    SQL_SYNCPOINT               = SQL_SYNC_ONEPHASE" << endl;
      break;
    case SQL_SYNC_NONE:
      cout << "    SQL_SYNCPOINT               = SQL_SYNC_NONE" << endl;
      break;
    default:
      break;
  }
  cout << "    SQL_MAX_NETBIOS_CONNECTIONS = "
       << clientAppInfo[4].value << endl;

  switch (clientAppInfo[5].value)
  {
    case SQL_DEFERRED_PREPARE_NO:
      cout << "    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_NO"
           << endl;
      break;
    case SQL_DEFERRED_PREPARE_YES:
      cout << "    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_YES"
           << endl;
      break;
    case SQL_DEFERRED_PREPARE_ALL:
      cout << "    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_ALL"
           << endl;
      break;
    default:
      break;
  }
  cout << "    SQL_CONNECT_NODE            = "
       << clientAppInfo[6].value << endl;
  cout << "    SQL_ATTACH_NODE             = "
       << clientAppInfo[7].value << endl;

  return 0;
} //ApInfo::ClientConnectionAttrsSetGet

int main(int argc, char *argv[])
{
  int rc = 0;
  ApInfo info;

  // check command line arguments
  if (argc != 1)
  {
    cout << "\nUSAGE: " << argv[0] << endl;
    return 1;
  }

  cout << "\nHOW TO SET AND GET INFOMATION AT THE CLIENT LEVEL."
       << endl;

  rc = info.ClientAppNameSetGet();
  rc = info.ClientUseridSetGet();
  rc = info.ClientWorkstationSetGet();
  rc = info.ClientSuffixForAccountingStringSetGet();
  rc = info.ClientConnectionAttrsSetGet();

  return 0;
} //main

