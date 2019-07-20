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
** SOURCE FILE NAME: dbinfo.c
**
** SAMPLE: How to get and set information at the database level
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetConnectAttr -- Get Current Attribute Setting
**         SQLGetFunctions -- Get Functions
**         SQLGetInfo -- Get General Information
**         SQLGetStmtAttr -- Get Setting of a Statement Attribute
**
** OUTPUT FILE: dbinfo.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference.
**
** For information on using SQL statements, see the SQL Reference.
**
** For the latest information on programming, compiling, and running DB2
** applications, refer to the DB2 application development website at
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>
#include "utilcli.h" /* Header file for CLI sample code */

int DbNameGet(SQLHANDLE);
int ConnectionAttrGet(SQLHANDLE);
int SupportedFunctionsGet(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO GET AND SET DATABASE INFORMATION.\n");

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

  /* get the database alias and name */
  rc = DbNameGet(hdbc);
  /* get connection and statement attribute settings */
  rc = ConnectionAttrGet(hdbc);
  /* determine which CLI functions are supported */
  rc = SupportedFunctionsGet(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);
  return rc;
} /* main */

/* retrieve the database name and alias using SQLGetInfo */
int DbNameGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLUSMALLINT supported; /* to check if SQLGetInfo() is supported */
  SQLCHAR dbInfoBuf[255]; /* buffer for database info */
  SQLSMALLINT outlen;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLGetFunctions\n");
  printf("  SQLGetInfo\n");
  printf("TO GET:\n");

  /* check to see if SQLGetInfo() is supported */
  cliRC = SQLGetFunctions(hdbc, SQL_API_SQLGETINFO, &supported);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  if (supported == SQL_TRUE)
  {
    /* get general information */
    cliRC = SQLGetInfo(hdbc, SQL_DATA_SOURCE_NAME, dbInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("\n  Client Database Alias: %s\n", dbInfoBuf);

    /* get general information */
    cliRC = SQLGetInfo(hdbc, SQL_DATABASE_NAME, dbInfoBuf, 255, &outlen);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf("  Server Database Name : %s\n", dbInfoBuf);
  }
  else
    printf("\n  SQLGetInfo is not supported!\n");

  return 0;
} /* DbNameGet */

/* retrieve connection and statement attributes */
int ConnectionAttrGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER cursor_hold, autocommit;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLGetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLGetStmtAttr\n");
  printf("  SQLFreeHandle\n");
  printf("TO GET:\n");

  /* get the current setting for the AUTOCOMMIT attribute */
  cliRC = SQLGetConnectAttr(hdbc, SQL_AUTOCOMMIT, &autocommit, 0, NULL);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  A connection attribute...\n");
  printf("    Autocommit is: ");
  printf(autocommit == SQL_AUTOCOMMIT_ON ? "ON\n" : "OFF\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* get the current setting for the CURSOR_HOLD statement attribute */
  cliRC = SQLGetStmtAttr(hstmt, SQL_CURSOR_HOLD, &cursor_hold, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("  A statement attribute...\n");
  printf("    Cursor With Hold is: ");
  printf(cursor_hold == SQL_CURSOR_HOLD_ON ? "ON\n" : "OFF\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return 0;
} /* ConnectionAttrGet */

typedef struct
{
  SQLUSMALLINT id;
  char *name;
}
functionInfo;

/* list of CLI functions to check if supported */
functionInfo functions[] =
{
  {SQL_API_SQLALLOCCONNECT, "SQLALLOCCONNECT"},
  {SQL_API_SQLALLOCENV, "SQLALLOCENV"},
  {SQL_API_SQLALLOCHANDLE, "SQLALLOCHANDLE"},
  {SQL_API_SQLALLOCSTMT, "SQLALLOCSTMT"},
  {SQL_API_SQLBINDCOL, "SQLBINDCOL"},
  {SQL_API_SQLBINDFILETOCOL, "SQLBINDFILETOCOL"},
  {SQL_API_SQLBINDFILETOPARAM, "SQLBINDFILETOPARAM"},
  {SQL_API_SQLBINDPARAMETER, "SQLBINDPARAMETER"},
  {SQL_API_SQLBROWSECONNECT, "SQLBROWSECONNECT"},
  {SQL_API_SQLCANCEL, "SQLCANCEL"},
  {SQL_API_SQLCLOSECURSOR, "SQLCLOSECURSOR"},
  {SQL_API_SQLCOLATTRIBUTE, "SQLCOLATTRIBUTE"},
  {SQL_API_SQLCOLATTRIBUTES, "SQLCOLATTRIBUTES"},
  {SQL_API_SQLCOLUMNPRIVILEGES, "SQLCOLUMNPRIVILEGES"},
  {SQL_API_SQLCOLUMNS, "SQLCOLUMNS"},
  {SQL_API_SQLCONNECT, "SQLCONNECT"},
  {SQL_API_SQLCOPYDESC, "SQLCOPYDESC"},
  {SQL_API_SQLDATASOURCES, "SQLDATASOURCES"},
  {SQL_API_SQLDESCRIBECOL, "SQLDESCRIBECOL"},
  {SQL_API_SQLDESCRIBEPARAM, "SQLDESCRIBEPARAM"},
  {SQL_API_SQLDISCONNECT, "SQLDISCONNECT"},
  {SQL_API_SQLDRIVERCONNECT, "SQLDRIVERCONNECT"},
  {SQL_API_SQLENDTRAN, "SQLENDTRAN"},
  {SQL_API_SQLERROR, "SQLERROR"},
  {SQL_API_SQLEXECDIRECT, "SQLEXECDIRECT"},
  {SQL_API_SQLEXECUTE, "SQLEXECUTE"},
  {SQL_API_SQLEXTENDEDBIND, "SQLEXTENDEDBIND"},
  {SQL_API_SQLEXTENDEDFETCH, "SQLEXTENDEDFETCH"},
  {SQL_API_SQLEXTENDEDPREPARE, "SQLEXTENDEDPREPARE"},
  {SQL_API_SQLFETCH, "SQLFETCH"},
  {SQL_API_SQLFETCHSCROLL, "SQLFETCHSCROLL"},
  {SQL_API_SQLFOREIGNKEYS, "SQLFOREIGNKEYS"},
  {SQL_API_SQLFREECONNECT, "SQLFREECONNECT"},
  {SQL_API_SQLFREEENV, "SQLFREEENV"},
  {SQL_API_SQLFREEHANDLE, "SQLFREEHANDLE"},
  {SQL_API_SQLFREESTMT, "SQLFREESTMT"},
  {SQL_API_SQLGETCONNECTATTR, "SQLGETCONNECTATTR"},
  {SQL_API_SQLGETCONNECTOPTION, "SQLGETCONNECTOPTION"},
  {SQL_API_SQLGETCURSORNAME, "SQLGETCURSORNAME"},
  {SQL_API_SQLGETDATA, "SQLGETDATA"},
  {SQL_API_SQLGETDESCFIELD, "SQLGETDESCFIELD"},
  {SQL_API_SQLGETDESCREC, "SQLGETDESCREC"},
  {SQL_API_SQLGETDIAGFIELD, "SQLGETDIAGFIELD"},
  {SQL_API_SQLGETDIAGREC, "SQLGETDIAGREC"},
  {SQL_API_SQLGETENVATTR, "SQLGETENVATTR"},
  {SQL_API_SQLGETFUNCTIONS, "SQLGETFUNCTIONS"},
  {SQL_API_SQLGETINFO, "SQLGETINFO"},
  {SQL_API_SQLGETLENGTH, "SQLGETLENGTH"},
  {SQL_API_SQLGETPOSITION, "SQLGETPOSITION"},
  {SQL_API_SQLGETSQLCA, "SQLGETSQLCA"},
  {SQL_API_SQLGETSTMTATTR, "SQLGETSTMTATTR"},
  {SQL_API_SQLGETSTMTOPTION, "SQLGETSTMTOPTION"},
  {SQL_API_SQLGETSUBSTRING, "SQLGETSUBSTRING"},
  {SQL_API_SQLGETTYPEINFO, "SQLGETTYPEINFO"},
  {SQL_API_SQLMORERESULTS, "SQLMORERESULTS"},
  {SQL_API_SQLNATIVESQL, "SQLNATIVESQL"},
  {SQL_API_SQLNEXTRESULT, "SQLNEXTRESULT"},
  {SQL_API_SQLNUMPARAMS, "SQLNUMPARAMS"},
  {SQL_API_SQLNUMRESULTCOLS, "SQLNUMRESULTCOLS"},
  {SQL_API_SQLPARAMDATA, "SQLPARAMDATA"},
  {SQL_API_SQLPARAMOPTIONS, "SQLPARAMOPTIONS"},
  {SQL_API_SQLPREPARE, "SQLPREPARE"},
  {SQL_API_SQLPRIMARYKEYS, "SQLPRIMARYKEYS"},
  {SQL_API_SQLPROCEDURECOLUMNS, "SQLPROCEDURECOLUMNS"},
  {SQL_API_SQLPROCEDURES, "SQLPROCEDURES"},
  {SQL_API_SQLPUTDATA, "SQLPUTDATA"},
  {SQL_API_SQLROWCOUNT, "SQLROWCOUNT"},
  {SQL_API_SQLSETCOLATTRIBUTES, "SQLSETCOLATTRIBUTES"},
  {SQL_API_SQLSETCONNECTATTR, "SQLSETCONNECTATTR"},
  {SQL_API_SQLSETCONNECTION, "SQLSETCONNECTION"},
  {SQL_API_SQLSETCONNECTOPTION, "SQLSETCONNECTOPTION"},
  {SQL_API_SQLSETCURSORNAME, "SQLSETCURSORNAME"},
  {SQL_API_SQLSETDESCFIELD, "SQLSETDESCFIELD"},
  {SQL_API_SQLSETDESCREC, "SQLSETDESCREC"},
  {SQL_API_SQLSETENVATTR, "SQLSETENVATTR"},
  {SQL_API_SQLSETPARAM, "SQLSETPARAM"},
  {SQL_API_SQLSETPOS, "SQLSETPOS"},
  {SQL_API_SQLSETSTMTATTR, "SQLSETSTMTATTR"},
  {SQL_API_SQLSETSTMTOPTION, "SQLSETSTMTOPTION"},
  {SQL_API_SQLSPECIALCOLUMNS, "SQLSPECIALCOLUMNS"},
  {SQL_API_SQLSTATISTICS, "SQLSTATISTICS"},
  {SQL_API_SQLTABLEPRIVILEGES, "SQLTABLEPRIVILEGES"},
  {SQL_API_SQLTABLES, "SQLTABLES"},
  {SQL_API_SQLTRANSACT, "SQLTRANSACT"},
  {0, (char *)0}
};

/* determine which CLI functions are supported */
int SupportedFunctionsGet(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLUSMALLINT supported;
  int i;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTION\n");
  printf("  SQLGetFunctions\n");
  printf("TO LIST THE SUPPORTED CLI FUNCTIONS:\n");

  printf("\n  List the supported CLI functions:\n");

  i = 0;
  while (functions[i].id != 0)
  {
    /* get functions */
    cliRC = SQLGetFunctions(hdbc, functions[i].id, &supported);
    DBC_HANDLE_CHECK(hdbc, cliRC);

    printf((supported ? "    %-20s is supported\n" :
                        "    %-20s is not supported\n"), functions[i].name);
    i++;
  }

  return 0;
} /* SupportedFunctionsGet */

