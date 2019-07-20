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
** SOURCE FILE NAME: getdbmcfgparams.c                                      
**                                                                        
** SAMPLE: How to get DBM CFG Parameters 
**         This sample should be run using the following steps:
**
**         1. Create the "sample" database using db2sampl command
**
**         2. Compile the program with the following command:
**            bldapp getdbmcfgparams
**
**         3. Run this sample with the following command:
**            getdbmcfgparams <configuration parameter names>
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle    -- Allocate Handle
**         SQLBindCol        -- Bind a Column to an Application Variable or
**                              LOB locator
**         SQLBindParameter  -- Bind a Parameter Marker to a Buffer or
**                              LOB locator
**         SQLExecDirect     -- Execute a Statement Directly
**         SQLFetch          -- Fetch Next Row
**         SQLFreeHandle     -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: getdbmcfgparams.out (available in the online documentation)
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
  int rc = 0, i;
  SQLHANDLE henv;  /* environment handle */
  SQLHANDLE hdbc;  /* connection handle */
  SQLHANDLE hstmt; /* statement handle */
  char stmt[300];  /* SQL SELECT statement to be executed */
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[32];
  }
  name; /* variable to be bound to the NAME column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[1024];
  }
  value; /* variable to be bound to the VALUE column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[1024];
  }
  deferred_value; /* variable to be bound to the DEFERRED_VALUE column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[128];
  }
  datatype; /* variable to be bound to the DATATYPE column */

  /* initializing the database name */
  strcpy(dbAlias, "sample");
  strcpy(user, "");
  strcpy(pswd, "");
  
  if (argc < 2 )
  {
    printf("\n Usage : getdbmcfgparams <configuration parameter names>\n");
    rc = -1;
    return rc;
  } 
  
  printf("\nTHIS SAMPLE SHOWS HOW TO GET DB CFG PARAMETERS ");
  printf("USING THE VIEW SYSIBMADM.DBMCFG.\n");

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

  /* SELECT NAME, VALUE, DEFERRED_VALUE, DATATYPE
     FROM  SYSIBMADM.DBMCFG WHERE NAME IN ( LIST) */
  strcpy(stmt, "SELECT NAME, VALUE, DEFERRED_VALUE, DATATYPE");
  strcat(stmt, " FROM SYSIBMADM.DBMCFG WHERE NAME IN (");
  
  i = 1;
  strcat(stmt, " '");
  strcat(stmt, argv[i]);
  strcat(stmt, "'");

  for (i = 2; i < argc; i++)
  {
    strcat(stmt, ", '");
    strcat(stmt, argv[i]);
    strcat(stmt, "'");
  }
  strcat(stmt, " )");

  printf("\n-----------------------------------------------------------\n");
  printf("\n%s\n", stmt); 
  printf("\n-----------------------------------------------------------");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter name to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, name.val, 32, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind parameter value to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, value.val, 1024, &value.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind deferred value to variable */
  cliRC = SQLBindCol(hstmt,
                     3, 
                     SQL_C_CHAR, 
                     deferred_value.val, 
                     1024, 
                     &deferred_value.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind datatype to variable */
  cliRC = SQLBindCol(hstmt, 
                     4, 
                     SQL_C_CHAR, 
                     datatype.val, 
                     128, 
                     &datatype.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  while (cliRC != SQL_NO_DATA_FOUND)
  {
    /* display each row */
    printf("\n");
    printf("Parameter Name           = %s\n", name.val);
    printf("Parameter Value          = %s\n", value.val);
    printf("Parameter Deferred Value = %s\n", deferred_value.val);
    printf("Parameter Data Type      = %s\n", datatype.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end of main */
 
