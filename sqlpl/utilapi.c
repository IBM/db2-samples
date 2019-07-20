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
** SOURCE FILE NAME: utilapi.c
**
** SAMPLE: Checks for and prints to the screen SQL warnings and errors
**
**         This utility file is compiled and linked in as an object module
**         with non-embedded SQL sample programs by the supplied makefile 
**         and build files.
**
** DB2 APIs USED:
**         sqlaintp -- Get Error Message   
**         sqlogstt -- Get SQLSTATE Message
**         sqleatin -- Attach to an Instance
**         sqledtin -- Detach from an Instance
**
** Included functions:
**         SqlInfoPrint - prints to the screen SQL warnings and errors
**         CmdLineArgsCheck1 - checks the command line arguments, version 1
**         CmdLineArgsCheck2 - checks the command line arguments, version 2
**         CmdLineArgsCheck3 - checks the command line arguments, version 3
**         CmdLineArgsCheck4 - checks the command line arguments, version 4
**         InstanceAttach - attach to instance
**         InstanceDetach - detach from instance
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on creating SQL procedures and developing C applications,
** see the Application Development Guide.
**
** For more information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <sqlenv.h>
#include <sqlda.h>
#include <sqlca.h>
#include <string.h>
#include <ctype.h>
#include "utilapi.h"

void SqlInfoPrint(char *appMsg, struct sqlca *pSqlca, int line, char *file)
{
  int rc = 0;
  char sqlInfo[1024];
  char sqlInfoToken[1024];
  char sqlstateMsg[1024];
  char errorMsg[1024];

  if (pSqlca->sqlcode != 0 && pSqlca->sqlcode != 100)
  {
    strcpy(sqlInfo, "");

    if (pSqlca->sqlcode < 0)
    {
      sprintf(sqlInfoToken,
              "\n---- error report -----------------------------\n");
      strcat(sqlInfo, sqlInfoToken);
    }
    else
    {
      sprintf(sqlInfoToken,
              "\n---- warning report ---------------------------\n");
      strcat(sqlInfo, sqlInfoToken);
    } /* endif */

    sprintf(sqlInfoToken, "\napplication message = %s\n", appMsg);
    strcat(sqlInfo, sqlInfoToken);
    sprintf(sqlInfoToken, "line                = %d\n", line);
    strcat(sqlInfo, sqlInfoToken);
    sprintf(sqlInfoToken, "file                = %s\n", file);
    strcat(sqlInfo, sqlInfoToken);
    sprintf(sqlInfoToken, "SQLCODE             = %ld\n\n", pSqlca->sqlcode);
    strcat(sqlInfo, sqlInfoToken);

    /* get error message */
    rc = sqlaintp(errorMsg, 1024, 80, pSqlca);
    if (rc > 0) /* return code is the length of the errorMsg string */
    {
      sprintf(sqlInfoToken, "%s\n", errorMsg);
      strcat(sqlInfo, sqlInfoToken);
    }

    /* get SQLSTATE message */
    rc = sqlogstt(sqlstateMsg, 1024, 80, pSqlca->sqlstate);
    if (rc > 0)
    {
      sprintf(sqlInfoToken, "%s\n", sqlstateMsg);
      strcat(sqlInfo, sqlInfoToken);
    }

    if (pSqlca->sqlcode < 0)
    {
      sprintf(sqlInfoToken,
              "---- end error report ------------------------\n");
      strcat(sqlInfo, sqlInfoToken);
      printf("%s", sqlInfo);
    }
    else
    {
      sprintf(sqlInfoToken,
              "---- end warning report ----------------------\n");
      strcat(sqlInfo, sqlInfoToken);
      printf("%s", sqlInfo);
    } /* endif */
  } /* endif */
} /* SqlInfoPrint */


int CmdLineArgsCheck1(int argc,
                      char *argv[],
                      char dbAlias[],
                      char user[],
                      char pswd[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(dbAlias, "sample");
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 2:
      strcpy(dbAlias, argv[1]);
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 4:
      strcpy(dbAlias, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      break;
    default:
      printf("\nUSAGE: %s [dbAlias [userid passwd]]\n",
             argv[0]);
      rc = 1;
      break;
  }

  return rc;
} /* CmdLineArgsCheck1 */

int CmdLineArgsCheck2(int argc,
                      char *argv[],
                      char nodeName[],
                      char user[],
                      char pswd[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(nodeName, "");
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 2:
      strcpy(nodeName, argv[1]);
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 4:
      strcpy(nodeName, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      break;
    default:
      printf("\nUSAGE: %s [nodeName [userid  passwd]]\n", argv[0]);
      rc = 1;
      break;
  } /* endswitch */

  return rc;
} /* CmdLineArgsCheck2 */

int CmdLineArgsCheck3(int argc,
                      char *argv[],
                      char dbAlias[],
                      char nodeName[],
                      char user[],
                      char pswd[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(dbAlias, "sample");
      strcpy(nodeName, "");
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 2:
      strcpy(dbAlias, argv[1]);
      strcpy(nodeName, "");
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 3:
      strcpy(dbAlias, argv[1]);
      strcpy(nodeName, argv[2]);
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 5:
      strcpy(dbAlias, argv[1]);
      strcpy(nodeName, argv[2]);
      strcpy(user, argv[3]);
      strcpy(pswd, argv[4]);
      break;
    default:
      printf("\nUSAGE: %s [dbAlias [nodeName [userid passwd]]]\n", argv[0]);
      rc = 1;
      break;
  } /* endswitch */

  return rc;
} /* CmdLineArgsCheck3 */

int CmdLineArgsCheck4(int argc,
                      char * argv[],
                      char dbAlias1[],
                      char dbAlias2[],
                      char user1[],
                      char pswd1[],
                      char user2[],
                      char pswd2[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(dbAlias1, "sample");
      strcpy(dbAlias2, "sample2");
      strcpy(user1, "");
      strcpy(pswd1, "");
      strcpy(user2, "");
      strcpy(pswd2, "");
      break;
    case 3:
      strcpy(dbAlias1, argv[1]);
      strcpy(dbAlias2, argv[2]);
      strcpy(user1, "");
      strcpy(pswd1, "");
      strcpy(user2, "");
      strcpy(pswd2, "");
      break;
    case 5:
      strcpy(dbAlias1, argv[1]);
      strcpy(dbAlias2, argv[2]);
      strcpy(user1, argv[3]);
      strcpy(pswd1, argv[4]);
      strcpy(user2, argv[3]);
      strcpy(pswd2, argv[4]);
      break;
    case 7:
      strcpy(dbAlias1, argv[1]);
      strcpy(dbAlias2, argv[2]);
      strcpy(user1, argv[3]);
      strcpy(pswd1, argv[4]);
      strcpy(user2, argv[5]);
      strcpy(pswd2, argv[6]);
      break;
    default:
      printf("\nUSAGE: %s "
             "[dbAlias1 dbAlias2 [user1 pswd1 [user2 pswd2]]]\n",
             argv[0]);
      rc = 1;
      break;
  }

  return rc;
} /* CmdLineArgsCheck4 */

int InstanceAttach(char nodeName[],
                   char user[],
                   char pswd[])
{
  struct sqlca sqlca;

  if (strlen(nodeName) > 0)
  {
    printf("\n\n##############  ATTACH TO THE INSTANCE: %s #######\n\n",
           nodeName);

    /* attach to an instance */
    sqleatin(nodeName, user, pswd, &sqlca);
    DB2_API_CHECK("instance -- attach");
  }

  return 0;
} /* CmdLineArgsCheck4 */


int InstanceDetach(char * nodeName)
{
  struct sqlca sqlca;

  if (strlen(nodeName) > 0)
  {
    printf("\n\n##############  DETACH FROM THE INSTANCE: %s #####\n\n",
           nodeName);

    /* detach from an instance */
    sqledtin(&sqlca);
    DB2_API_CHECK("instance -- detach");
  }

  return 0;
} /* InstanceDetach */

