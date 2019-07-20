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
** SOURCE FILE NAME: admincmd_contacts.c                                    
**                                                                        
** SAMPLE: How to add, update and drop contacts and contactgroups
**
**         This sample shows:
**           1. How to add a contact for a user with e-mail address
**           2. How to create a contactgroup with contact names
**           3. How to update the address for the sample user
**           4. How to update the contactgroup by adding a contact
**           5. How to read a contact list
**           6. How to read a contact group list
**           7. How to drop a contact from the list of contacts
**           8. How to drop a contactgroup from the list of groups
**
** Note: The Database Administration Server(DAS) should be running.     
**                                                                        
** CLI FUNCTIONS USED:
**         SQLAllocHandle   -- Allocate Handle
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLExecute       -- Execute a Statement
**         SQLFreeHandle    -- Free Handle Resources
**         SQLPrepare       -- Prepare a Statement
**
** OUTPUT FILE: admincmd_contacts.out (available in the online documentation)
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
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *) "CALL SYSPROC.ADMIN_CMD(?)";
  char str[300] = {0};
  char inparam[300] = {0}; /* parameter to be passed to the stored
                              procedure */
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];
  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[128];
  } name, mname, address;

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[5];
  } type;

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW  TO:\n");
  printf("  ADD, UPDATE AND DROP CONTACTS AND CONTACTGROUPS"
         " USING ADMIN_CMD.\n");
  
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

  /* allocate the handle for statement */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* add contact testuser1 of type email address testuser1@test.com */
  strcpy(inparam, "ADD CONTACT testuser1 TYPE EMAIL ADDRESS");
  strcat(inparam, " testuser1@test.com");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
      
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   
  printf("The contact is added successfully\n");

  /* add contact testuser2 of type email address testuser2@test.com */
  strcpy(inparam, "ADD CONTACT testuser2 TYPE EMAIL ADDRESS");
  strcat(inparam, " testuser2@test.com");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
      
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("The contact is added successfully\n");

  /* add contactgroup gname1 containing contact testuser1 */
  strcpy(inparam, "ADD CONTACTGROUP gname1 CONTACT testuser1");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* bind the parameter to the statement */     
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("The contactgroup is added successfully.\n");

  /* update contact testuser1 changing address to address@test.com */
  strcpy(inparam, "UPDATE CONTACT testuser1 USING ADDRESS address@test.com");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the parameter to the statement */     
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("The contact is updated successfully.\n");

  /* update contactgroup gname1 by dropping the contact testuser1 */
  strcpy(inparam, "UPDATE CONTACTGROUP gname1 ADD CONTACT testuser2");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the parameter to the statement */      
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("The contactgroup is updated successfully\n");
 
  /* message retrieval */
  strcpy(str, "SELECT NAME, MEMBERNAME, MEMBERTYPE"
              " FROM TABLE(SYSPROC.ADMIN_GET_CONTACTGROUPS())"
              " AS CONTACTGROUPS");

  printf("\nExecuting\n");  
  printf("  SELECT NAME, MEMBERNAME, MEMBERTYPE\n"
         "    FROM TABLE(SYSPROC.ADMIN_GET_CONTACTGROUPS())"
         " AS CONTACTGROUPS");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) str, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, name.val, 128, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, mname.val, 128, &mname.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, type.val, 5, &type.ind);
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
    printf("GROUPNAME     : %s\n", name.val);
    printf("MEMBERNAME    : %s\n", mname.val);
    printf("MEMBERTYPE    : %s\n", type.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
    cliRC = SQLCloseCursor(hstmt); 

  /* message retrieval */
  strcpy(str, "SELECT NAME, TYPE, ADDRESS"
              " FROM TABLE(SYSPROC.ADMIN_GET_CONTACTS())"
              " AS CONTACTS");

  printf("\nExecuting\n");  
  printf("  SELECT NAME, TYPE, ADDRESS\n"
         "    FROM TABLE(SYSPROC.ADMIN_GET_CONTACTS()) AS CONTACTS");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, (SQLCHAR *) str, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, name.val, 128, &name.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, type.val, 5, &type.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, address.val, 128, &address.ind);
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
    printf("NAME    : %s\n", name.val);
    printf("TYPE    : %s\n", type.val);
    printf("ADDRESS : %s\n", address.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);

  /* drop contactgroup gname1 */
  strcpy(inparam, "DROP CONTACTGROUP gname1");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* bind the parameter to the statement */     
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   
  printf("The contactgroup is dropped successfully\n");

  /* drop contact testuser1 */
  strcpy(inparam, "DROP CONTACT testuser1");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
      
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   
  printf("The contact is dropped successfully\n");

  /* drop contact testuser1 */
  strcpy(inparam, "DROP CONTACT testuser2");
  printf("\nCALL ADMIN_CMD('%s')\n", inparam);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
      
  /* bind the parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1 ,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_CLOB,
                           300,
                           0 ,
                           inparam,
                           300 ,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   
  printf("The contact is dropped successfully\n");
  
  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

