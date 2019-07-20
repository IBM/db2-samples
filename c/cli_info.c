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
** SOURCE FILE NAME: cli_info.c
**
** SAMPLE: Set and get information at the client level
**          
** DB2 APIs USED:
**         sqlesetc -- SET CLIENT
**         sqleseti -- SET CLIENT INFORMATION
**         sqleqryc -- QUERY CLIENT
**         sqleqryi -- QUERY CLIENT INFORMATION 
**
** STRUCTURES USED:
**         sqlca 
**         sqle_client_info 
**         sqle_conn_setting 
**         
** OUTPUT FILE: cli_info.out (available in the online documentation)
*****************************************************************************
*
* For information on developing C applications, see the Application
* Development Guide.
*
* For more information on DB2 APIs, see the Administrative API Reference.
*
* For the latest information on programming, compiling, and running DB2 
* applications, visit the DB2 application development website: 
*     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlenv.h>
#include "utilapi.h"

int ClientAppNameSetGet(void);
int ClientUseridSetGet(void);
int ClientWorkstationSetGet(void);
int ClientSuffixForAccountingStringSetGet(void);
int ClientConnectionAttrsSetGet(void);

int main(int argc, char *argv[])
{
  int rc = 0;

  /* check command line arguments */
  if (argc != 1)
  {
    printf("\nUSAGE: %s \n", argv[0]);
    return 1;
  }

  printf("\nHOW TO SET AND GET INFOMATION AT THE CLIENT LEVEL.\n");

  rc = ClientAppNameSetGet();
  rc = ClientUseridSetGet();
  rc = ClientWorkstationSetGet();
  rc = ClientSuffixForAccountingStringSetGet();
  rc = ClientConnectionAttrsSetGet();

  return 0;
} /* end main */

int ClientAppNameSetGet(void)
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];

  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqleseti -- SET CLIENT INFORMATION\n");
  printf("  sqleqryi -- QUERY CLIENT INFORMATION\n");
  printf("TO SET/GET THE CLIENT APPL. NAME:\n");

  /* specify all the connections */
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  /* initialize clientAppInfo */
  clientAppInfo[0].type = SQLE_CLIENT_INFO_APPLNAME;
  clientAppInfo[0].pValue =
    (char *)malloc(sizeof(char) *(SQLE_CLIENT_APPLNAME_MAX_LEN + 1));

  /* set client app. name */
  strcpy(clientAppInfo[0].pValue, "ClientApplicationName");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  printf("\n  Set the Client App. Name to the value:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* set client information */
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client App. Name -- set");

  /* get client app. name */
  strcpy(clientAppInfo[0].pValue, "");
  printf("  Get the Client App. Name.\n");

  /* query client information */
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client App. Name -- get");

  printf("  The Client App. Name is:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* free the memory allocated */
  free(clientAppInfo[0].pValue);

  return 0;
} /* ClientAppNameSetGet */

int ClientUseridSetGet(void)
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];

  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqleseti -- SET CLIENT INFORMATION\n");
  printf("  sqleqryi -- QUERY CLIENT INFORMATION\n");
  printf("TO SET/GET THE CLIENT USERID:\n");

  /* specify all the connections */
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  /* initialize clientAppInfo */
  clientAppInfo[0].type = (unsigned short)SQLE_CLIENT_INFO_USERID;
  clientAppInfo[0].pValue = (char *)malloc(SQLE_CLIENT_USERID_MAX_LEN + 1);

  /* set client user ID */
  strcpy(clientAppInfo[0].pValue, "ClientUserid");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  printf("\n  Set the Client User ID to the value:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* set client information */
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client User ID -- set");

  /* get client user ID */
  strcpy(clientAppInfo[0].pValue, "");
  printf("  Get the Client User ID.\n");

  /* query client information */
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client User ID -- get");

  printf("  The Client User ID is:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* free the memory allocated */
  free(clientAppInfo[0].pValue);

  return 0;
} /* ClientUseridSetGet */

int ClientWorkstationSetGet(void)
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];

  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqleseti -- SET CLIENT INFORMATION\n");
  printf("  sqleqryi -- QUERY CLIENT INFORMATION\n");
  printf("TO SET/GET THE CLIENT WORKSTATION NAME:\n");

  /* specify all the connections */
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  /* initialize clientAppInfo */
  clientAppInfo[0].type = SQLE_CLIENT_INFO_WRKSTNNAME;
  clientAppInfo[0].pValue =
    (char *)malloc(sizeof(char) *(SQLE_CLIENT_WRKSTNNAME_MAX_LEN + 1));

  /* set client workstation name*/
  strcpy(clientAppInfo[0].pValue, "ClientWorkstation");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  printf("\n  Set the Client Workstation Name to the value:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* set client information */
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Workstation Name -- set");

  /* get client workstation name */
  strcpy(clientAppInfo[0].pValue, "");
  printf("  Get the Client Workstation Name.\n");

  /* query client information */
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Workstation Name -- get");

  printf("  The Client Workstation Name is:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* free the memory allocated */
  free(clientAppInfo[0].pValue);

  return 0;
} /* ClientWorkstationSetGet */

int ClientSuffixForAccountingStringSetGet(void)
{
  struct sqlca sqlca;
  struct sqle_client_info clientAppInfo[1];

  char clientAccStrSuffix[] = "ClientSuffixForAccountingString";
  unsigned short dbAliasLen;
  char dbAlias[SQL_ALIAS_SZ + 1];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqleseti -- SET CLIENT INFORMATION\n");
  printf("  sqleqryi -- QUERY CLIENT INFORMATION\n");
  printf("TO SET/GET THE CLIENT SUFFIX FOR THE ACCOUNTING STRING:\n");

  /* specify all the connections */
  dbAliasLen = 0;
  strcpy(dbAlias, "");

  /* initialize clientAppInfo */
  clientAppInfo[0].type = SQLE_CLIENT_INFO_ACCTSTR;
  clientAppInfo[0].pValue =
    (char *)malloc(sizeof(char) *(SQLE_CLIENT_APPLNAME_MAX_LEN + 1));

  /* set client suffix for accounting string */
  strcpy(clientAppInfo[0].pValue, "ClientSuffixForAccountingString");
  clientAppInfo[0].length = strlen((char *)clientAppInfo[0].pValue);
  printf("\n  Use the DB2 API sqleseti to set\n");
  printf("  the Client Suffix for Accounting String to the value:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* set client information */
  sqleseti(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Suffix for Accounting String -- set");

  /* get client suffix for accounting string */
  strcpy(clientAppInfo[0].pValue, "");
  printf("  Get the Client Suffix for Accounting String.\n");

  /* query client information */
  sqleqryi(dbAliasLen, dbAlias, 1, &clientAppInfo[0], &sqlca);
  DB2_API_CHECK("Client Suffix for Accounting String -- get");

  printf("  The Client Suffix for Accounting String is:\n");
  printf("    %s\n", clientAppInfo[0].pValue);

  /* free the memory allocated */
  free(clientAppInfo[0].pValue);

  return 0;
} /* ClientSuffixForAccountingStringSetGet */

int ClientConnectionAttrsSetGet(void)
{
  struct sqlca sqlca;
  struct sqle_conn_setting clientAppInfo[8];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  sqlesetc -- SET CLIENT\n");
  printf("  sqleqryc -- QUERY CLIENT\n");
  printf("TO SET/GET THE CLIENT CONNECTION ATTRIBUTES:\n");

  /* initialize clientAppInfo */
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

  /* set client connection attributes */
  printf("\n  Set the Client Connection Attributes to the values:\n");
  printf("    SQL_CONNECT_TYPE            = SQL_CONNECT_2\n");
  printf("    SQL_RULES                   = SQL_RULES_STD\n");
  printf("    SQL_DISCONNECT              = SQL_DISCONNECT_COND\n");
  printf("    SQL_SYNCPOINT               = SQL_SYNC_ONEPHASE\n");
  printf("    SQL_MAX_NETBIOS_CONNECTIONS = 16\n");
  printf("    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_YES\n");
  printf("    SQL_CONNECT_NODE            = 3\n");
  printf("    SQL_ATTACH_NODE             = 3\n");

  /* set client */
  sqlesetc(&clientAppInfo[0], 8, &sqlca);
  DB2_API_CHECK("Client Connection Attributes -- set");

  /* get client connection attributes */

  /* reset clientAppInfo */
  clientAppInfo[0].value = SQL_CONNECT_1;
  clientAppInfo[1].value = SQL_RULES_DB2;
  clientAppInfo[2].value = SQL_DISCONNECT_EXPL;
  clientAppInfo[3].value = SQL_SYNC_TWOPHASE;
  clientAppInfo[4].value = 1;
  clientAppInfo[5].value = SQL_DEFERRED_PREPARE_NO;
  clientAppInfo[6].value = 1;
  clientAppInfo[7].value = 1;

  printf("  Get the Client Connection Attributes.\n");

  /* query client */
  sqleqryc(&clientAppInfo[0], 8, &sqlca);
  DB2_API_CHECK("Client Conn. Attrs. -- get");

  printf("  The Client Connection Attributes are:\n");
  switch (clientAppInfo[0].value)
  {
    case SQL_CONNECT_1:
      printf("    SQL_CONNECT_TYPE            = SQL_CONNECT_1\n");
      break;
    case SQL_CONNECT_2:
      printf("    SQL_CONNECT_TYPE            = SQL_CONNECT_2\n");
      break;
    default:
      break;
  }
  switch (clientAppInfo[1].value)
  {
    case SQL_RULES_DB2:
      printf("    SQL_RULES                   = SQL_RULES_DB2\n");
      break;
    case SQL_RULES_STD:
      printf("    SQL_RULES                   = SQL_RULES_STD\n");
      break;
    default:
      break;
  }
  switch (clientAppInfo[2].value)
  {
    case SQL_DISCONNECT_EXPL:
      printf("    SQL_DISCONNECT              = SQL_DISCONNECT_EXPL\n");
      break;
    case SQL_DISCONNECT_COND:
      printf("    SQL_DISCONNECT              = SQL_DISCONNECT_COND\n");
      break;
    case SQL_DISCONNECT_AUTO:
      printf("    SQL_DISCONNECT              = SQL_DISCONNECT_EXPL\n");
      break;
    default:
      break;
  }
  switch (clientAppInfo[3].value)
  {
    case SQL_SYNC_TWOPHASE:
      printf("    SQL_SYNCPOINT               = SQL_SYNC_TWOPHASE\n");
      break;
    case SQL_SYNC_ONEPHASE:
      printf("    SQL_SYNCPOINT               = SQL_SYNC_ONEPHASE\n");
      break;
    case SQL_SYNC_NONE:
      printf("    SQL_SYNCPOINT               = SQL_SYNC_NONE\n");
      break;
    default:
      break;
  }
  printf("    SQL_MAX_NETBIOS_CONNECTIONS = %d\n",
         clientAppInfo[4].value);
  switch (clientAppInfo[5].value)
  {
    case SQL_DEFERRED_PREPARE_NO:
      printf("    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_NO\n");
      break;
    case SQL_DEFERRED_PREPARE_YES:
      printf("    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_YES\n");
      break;
    case SQL_DEFERRED_PREPARE_ALL:
      printf("    SQL_DEFERRED_PREPARE        = SQL_DEFERRED_PREPARE_ALL\n");
      break;
    default:
      break;
  }
  printf("    SQL_CONNECT_NODE            = %d\n", clientAppInfo[6].value);
  printf("    SQL_ATTACH_NODE             = %d\n", clientAppInfo[7].value);

  return 0;
} /* ClientConnectionAttrsSetGet */

