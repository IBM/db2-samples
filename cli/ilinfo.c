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
** SOURCE FILE NAME: ilinfo.c                                      
**                                                                        
** SAMPLE: How to get information at the installation image level
**
** CLI FUNCTIONS USED:
**         SQLGetFunctions -- Get Functions
**         SQLGetInfo -- Get General Information
**
** OUTPUT FILE: ilinfo.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference.
**
** For information on using SQL statements, see the SQL Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>
#include "utilcli.h" /* Header file for CLI sample code */

int ServerImageInfoGet(SQLHANDLE);
int ClientImageInfoGet(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO GET INFORMATION \n");
  printf("AT THE INSTALLATION IMAGE LEVEL.\n");
  
  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_ON);
  if (rc != 0)
  {
    return rc;
  }

  /* get server information */
  rc = ServerImageInfoGet(hdbc);
  /* get client information */
  rc = ClientImageInfoGet(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* get the name and version of the server */
int ServerImageInfoGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLUSMALLINT supported; /* to check if SQLGetInfo() is supported */
  SQLCHAR imageInfoBuf[255]; /* buffer for image information */
  SQLSMALLINT imageInfoInt; /* integer to get image information */
  SQLSMALLINT outlen;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLGetFunctions\n");
  printf("  SQLGetInfo\n");
  printf("TO GET:\n");

  /* check to see if SQLGetInfo is supported */
  cliRC = SQLGetFunctions(hdbc, SQL_API_SQLGETINFO, &supported);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  if (supported == SQL_TRUE)
  {
    /* get server name information */
    cliRC = SQLGetInfo(hdbc, SQL_DBMS_NAME, imageInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("\n  Server DBMS Name   : %s\n", imageInfoBuf);

    /* get server version information */
    cliRC = SQLGetInfo(hdbc, SQL_DBMS_VER, imageInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("  Server DBMS Version: %s\n", imageInfoBuf);
  }
  else
    printf("\n  SQLGetInfo is not supported!\n");

  return 0;
} /* ServerImageInfoGet */

/* get the name, version and conformance level of the client */
int ClientImageInfoGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLUSMALLINT supported; /* to check if SQLGetInfo is supported */
  SQLCHAR imageInfoBuf[255]; /* buffer for image information */
  SQLSMALLINT imageInfoInt; /* integer to get image information */
  SQLSMALLINT outlen;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLGetFunctions\n");
  printf("  SQLGetInfo\n");
  printf("TO GET:\n");

  /* check to see if SQLGetInfo is supported */
  cliRC = SQLGetFunctions(hdbc, SQL_API_SQLGETINFO, &supported);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  if (supported == SQL_TRUE)
  {
    /* get client driver name information */
    cliRC = SQLGetInfo(hdbc, SQL_DRIVER_NAME, imageInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("\n  Client CLI Driver Name   : %s", imageInfoBuf);

    /* get client driver version information */
    cliRC = SQLGetInfo(hdbc, SQL_DRIVER_VER, imageInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("\n  Client CLI Driver Version: %s", imageInfoBuf);

    /* get client driver level information */
    cliRC = SQLGetInfo(hdbc,
                       SQL_ODBC_SQL_CONFORMANCE,
                       &imageInfoInt,
                       sizeof(imageInfoInt),
                       &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    switch (imageInfoInt)
    {
      case SQL_OSC_MINIMUM:
        strcpy((char *)imageInfoBuf, "Minimum Grammar");
        break;
      case SQL_OSC_CORE:
        strcpy((char *)imageInfoBuf, "Core Grammar");
        break;
      case SQL_OSC_EXTENDED:
        strcpy((char *)imageInfoBuf, "Extended Grammar");
        break;
      default:
        break;
    }
    printf("\n  Client CLI Driver - \n");
    printf("    ODBC CLI Conformance Level: %s\n", imageInfoBuf);
  }
  else
    printf("\n  SQLGetInfo is not supported!\n");

  return 0;
} /* ClientImageInfoGet */

