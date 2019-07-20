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
** SOURCE FILE NAME: dbconn.c
**
** SAMPLE: How to connect to and disconnect from a database
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBrowseConnect -- Get Required Attributes to Connect
**                             to a Data Source
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLDriverConnect -- Connect to a Data Source (Expanded)
**         SQLFreeHandle -- Free Handle Resources
**
** OUTPUT FILE: dbconn.out (available in the online documentation)
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

int DbBasicConnect(SQLHANDLE, char *, char *, char *);
int DbDriverConnect(SQLHANDLE, char *, char *, char *);
int DbBrowseConnect(SQLHANDLE, char *, char *, char *);

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
    return 1;
  }

  printf("\nTHIS SAMPLE SHOWS ");
  printf("HOW TO CONNECT TO AND DISCONNECT FROM A DATABASE.\n");

  /* allocate an environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  if (cliRC != SQL_SUCCESS)
  {
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  cliRC = %d\n", cliRC);
    printf("  line  = %d\n", __LINE__);
    printf("  file  = %s\n", __FILE__);
    return 1;
  }
  
  /* set attribute to enable application to run as ODBC 3.0 application */
  cliRC = SQLSetEnvAttr(henv,
                     SQL_ATTR_ODBC_VERSION,
                     (void *)SQL_OV_ODBC3,
                     0);
  ENV_HANDLE_CHECK(henv, cliRC);

  /* connect to a database with SQLConnect() */
  /* this is the basic connection */
  rc = DbBasicConnect(henv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  /* connect to a database with SQLDriverConnect() */
  rc = DbDriverConnect(henv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  /* connect to a database with SQLBrowseConnect() */
  rc = DbBrowseConnect(henv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  ENV_HANDLE_CHECK(henv, cliRC);

  return 0;
} /* main */

/* connect to a database with a basic connection using SQLConnect() */
int DbBasicConnect(SQLHANDLE henv,
                   char db1Alias[],
                   char user[],
                   char pswd[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hdbc; /* connection handle */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLConnect\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CONNECT TO AND DISCONNECT FROM A DATABASE:\n");

  /* allocate a database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC);

  printf("\n  Connecting to the database %s ...\n", db1Alias);

  /* connect to the database */
  cliRC = SQLConnect(hdbc,
                     (SQLCHAR *)db1Alias,
                     SQL_NTS,
                     (SQLCHAR *)user,
                     SQL_NTS,
                     (SQLCHAR *)pswd,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("  Connected to the database %s.\n", db1Alias);

  /*********   Start using the connection  *************************/

  /*********   Stop using the connection  **************************/

  printf("\n  Disconnecting from the database %s...\n", db1Alias);

  /* disconnect from the database */
  cliRC = SQLDisconnect(hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Disconnected from the database %s.\n", db1Alias);

  /* free the connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  return 0;
} /* DbBasicConnect */

/* connect to a database with additional connection parameters
   using SQLDriverConnect() */
int DbDriverConnect(SQLHANDLE henv,
                    char db1Alias[],
                    char user[],
                    char pswd[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hdbc; /* connection handle */
  SQLCHAR connStr[255];

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLDriverConnect\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CONNECT TO AND DISCONNECT FROM A DATABASE:\n");

  /* allocate a database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC);

  printf("\n  Connecting to the database %s ...\n", db1Alias);
  sprintf((char *)connStr,
          "DSN=%s; UID=%s; PWD=%s; AUTOCOMMIT=0; CONNECTTYPE=1;",
          db1Alias, user, pswd);

  /* connect to a data source */
  cliRC = SQLDriverConnect(hdbc,
                           (SQLHWND)NULL,
                           connStr,
                           SQL_NTS,
                           NULL,
                           0,
                           NULL,
                           SQL_DRIVER_NOPROMPT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Connected to the database %s.\n", db1Alias);

  /*********   Start using the connection  *************************/
  
  /*********   Stop using the connection  **************************/

  printf("\n  Disconnecting from the database %s...\n", db1Alias);

  /* disconnect from the database */
  cliRC = SQLDisconnect(hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Disconnected from the database %s.\n", db1Alias);

  /* free the connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  return 0;
} /* DbDriverConnect */

/* connect to a database iteratively using SQLBrowseConnect() */
int DbBrowseConnect(SQLHANDLE henv,
                    char db1Alias[],
                    char user[],
                    char pswd[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hdbc; /* connection handle */
  SQLCHAR connInStr[255]; /* browse request connection string */
  SQLCHAR outStr[1025]; /* browse result connection string*/
  SQLSMALLINT indicator; /* number of bytes to return */
  int count = 1;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS:\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLBrowseConnect\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CONNECT TO AND DISCONNECT FROM A DATABASE:\n");

  /* allocate a database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC);

  /* connect to the database */
  printf("\n  Connecting to the database %s ...\n", db1Alias);
  sprintf((char *)connInStr,
          "DSN=%s; UID=%s; PWD=%s; AUTOCOMMIT=0;", db1Alias, user, pswd);

  /*********   Start using the connection  *************************/

  cliRC = SQL_NEED_DATA;
  while (cliRC == SQL_NEED_DATA)
  {
    /* get required attributes to connect to data source */
    cliRC = SQLBrowseConnect(hdbc,
                             connInStr,
                             SQL_NTS,
                             outStr,
                             sizeof(outStr),
                             &indicator);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("  So far, have connected %d times to database %s\n", 
           count++, db1Alias);
    printf("  Resulting connection string: %s\n", outStr);

    /* if inadequate connection information was provided, exit
       the program */
    if (cliRC == SQL_NEED_DATA)
    {
      printf("  You can provide other connection information "
             "here by setting connInStr\n");
      break;
    }

    /* if the connection was successful, output confirmation */
    if (cliRC == SQL_SUCCESS)
    {
      printf("  Connected to the database %s.\n", db1Alias);
    }
  }

  /*********   Stop using the connection  **************************/

  printf("\n  Disconnecting from the database %s...\n", db1Alias);

  /* disconnect from the database */
  cliRC = SQLDisconnect(hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Disconnected from the database %s.\n", db1Alias);

  /* free the connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  return 0;
} /* DbBrowseConnect */

