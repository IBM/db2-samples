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
** SOURCE FILE NAME: getmessage.sqc 
**
** SAMPLE : How to get error message in the required locale with token
**          replacement. The tokens can be programatically obtained by
**          invoking Sqlaintp using JNI.
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol     -- Bind a Column to an Application Variable or
**                           LOB locator
**         SQLExecute     -- Execute a Statement
**         SQLFetch       -- Fetch Next Row
**         SQLFreeHandle  -- Free Handle Resources
**
** OUTPUT FILE: getmessage.out (available in the online documentation)
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

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLHANDLE hstmt; /* statement handles */
  
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* SQL SELECT statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT SYSPROC.SQLERRM ('sql551', 'USERA;"
                             " UPDATE; SYSCAT.TABLES', ';', 'en_US', 1)"
                             " FROM SYSIBM.SYSDUMMY1";

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[1024];
  }
  message; /* variable to be bound to the LOCATION column */

  printf("How to get error message in the required locale with token\n");
  printf("  replacement. The tokens can be programatically obtained\n");
  printf("  by onvoking Sqlaintp API.\n\n");

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

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

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* Suppose:
       'sql551' is sqlcode 
       'USERA', 'UPDATE', 'SYSCAT.TABLES' are tokens 
       ';' is the delimiter for tokens. 
       'en_US' is the locale 
     If the above information is passed to the scalar function SQLERRM,
     a message is returned in the specified LOCALE */

  printf("Executing\n"); 
  printf("     SELECT SYSPROC.SQLERRM('sql551',\n" );
  printf("                            'USERA;UPDATE;SYSCAT.TABLES',\n");
  printf("                            ';',\n"); 
  printf("                            'en_US',\n"); 
  printf("                            1)\n"); 
  printf("       FROM SYSIBM.SYSDUMMY1;\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter value to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, message.val, 1024, &message.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  if(cliRC != SQL_NO_DATA_FOUND)
  {
    printf("The Message is \n %s", message.val); 
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
  utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */

