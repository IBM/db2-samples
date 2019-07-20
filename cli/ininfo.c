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
** SOURCE FILE NAME: ininfo.c                                      
**                                                                        
** SAMPLE: How to get information at the instance level
**                                                                        
** CLI FUNCTIONS USED:
**         SQLDataSources -- Get List of Data Sources
**         SQLGetFunctions -- Get Functions
**         SQLGetInfo -- Get General Information
**
** OUTPUT FILE: ininfo.out (available in the online documentation)
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

int CurrentClientInstanceNameGet(SQLHANDLE);
int DatabaseDirectoryOfCurrentClientInstanceGet(SQLHANDLE);

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

  printf("\nHOW TO GET INFORMATION AT THE INSTANCE LEVEL.\n");

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

  /* get the name of the current client instance */
  rc = CurrentClientInstanceNameGet(hdbc);
  /* get the name and comment of each cataloged database */
  rc = DatabaseDirectoryOfCurrentClientInstanceGet(henv);

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* get the name of the current client instance using SQLGetInfo */
int CurrentClientInstanceNameGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLUSMALLINT supported; /* to check if SQLGetInfo is supported */
  SQLCHAR instInfoBuf[255]; /* buffer for instance info */
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
    /* get client name information */ 
    cliRC = SQLGetInfo(hdbc, SQL_SERVER_NAME, instInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("\n  Current Client Instance Name: %s\n", instInfoBuf);
  }
  else
    printf("\n  SQLGetInfo is not supported!\n");

  return 0;
} /* CurrentClientInstanceNameGet */

/* get the name and comment of each database cataloged 
   in the current client instance */
int DatabaseDirectoryOfCurrentClientInstanceGet(SQLHANDLE henv)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLCHAR dbAliasBuf[SQL_MAX_DSN_LENGTH + 1];
  SQLCHAR dbCommentBuf[255];
  SQLSMALLINT aliasLen, commentLen;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTION\n");
  printf("  SQLDataSources\n");
  printf("TO GET:\n");

  /* list the available data sources  */
  printf("\n  The alias name and the comment\n");
  printf("  for every database cataloged \n");
  printf("  in the database directory \n");
  printf("  of the current client instance:\n\n");
  printf("  ALIAS NAME         Comment(Description)\n");
  printf("  ------------------ ---------------------------------\n");

  /* get list of data sources */
  cliRC = SQLDataSources(henv,
                         SQL_FETCH_FIRST,
                         dbAliasBuf,
                         SQL_MAX_DSN_LENGTH + 1,
                         &aliasLen,
                         dbCommentBuf,
                         255,
                         &commentLen);
  ENV_HANDLE_CHECK(henv, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("  %-17s %s\n", dbAliasBuf, dbCommentBuf);

    /* get list of data sources */
    cliRC = SQLDataSources(henv,
                           SQL_FETCH_NEXT,
                           dbAliasBuf,
                           SQL_MAX_DSN_LENGTH + 1,
                           &aliasLen,
                           dbCommentBuf,
                           255,
                           &commentLen);
    ENV_HANDLE_CHECK(henv, cliRC);
  }

  return 0;
} /* DatabaseDirectoryOfCurrentClientInstanceGet */

