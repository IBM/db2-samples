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
** SOURCE FILE NAME: xmlread.c
**
** SAMPLE: This sample demonstrates to read XML data from a table.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare a Statement
**
** EXTERNAL DEPENDENCIES:
**      Ensure that the stored procedures called from this program have
**      been built and cataloged with the database.
**
** OUTPUT FILE: xmlread.out (available in the online documentation)
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
#include <sqlca.h>
#include "utilcli.h" /* header file for CLI sample code */

int ReadPurchaseOrder(SQLHANDLE);

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

  printf("PERFORMING SELECT FROM RELATIONAL TABLES\n");
  rc = ReadPurchaseOrder(hdbc);

  /* rollback any changes to the database made by this sample */
  printf("\nRoll back the transaction.\n");

  /* end transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* end main */


/* Read data*/
int ReadPurchaseOrder(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR stmt[500] = {0};
  SQLINTEGER CID;                 /* variable to be bound to the CID column */
  SQLINTEGER PID;                 /* variable to be bound to the POID column */

  struct
  {
    SQLINTEGER ind;
    SQLVARCHAR val[11];
  }
  OrderDate;                      /* variable to be bound to the OrderDate column */

  struct
  {
    SQLINTEGER ind;
    SQLVARCHAR val[30];
  } 
  Status;                        /* variable to be bound to the Status column */
  
  struct
  {
    SQLINTEGER ind;
    SQLVARCHAR val[200];
  }
  Comment;                       /* Variable to be bound to the Comment column */

  struct
  {
    SQLINTEGER ind;
    SQLVARCHAR val[2000];
  }
  POrder;                        /* Variable to be bound to the Porder column */

  

  printf("Execute the Select statement\n");
 
  strcpy((char *)stmt, "SELECT POID, CUSTID, STATUS, PORDER, "
                       "COMMENTS, ORDERDATE FROM PURCHASEORDER "
                       "ORDER BY CUSTID,POID");
  printf("%s\n", stmt);
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column POID to variable PID*/
  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &PID, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column CID to variable CID */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_LONG, &CID, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column STATUS to variable Status*/
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, &Status.val, 30, &Status.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column PORDER to variable POrder*/
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, &POrder.val, 3000, &POrder.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* bind column COMMENT to variable Comment*/
  cliRC = SQLBindCol(hstmt, 5, SQL_C_CHAR, &Comment.val, 200, &Comment.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 
  
  /* bind column ORDERDATE to variable OrderDate*/
  cliRC = SQLBindCol(hstmt, 6, SQL_C_CHAR, &OrderDate.val, 11, &OrderDate.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC); 
  

  /* fetch result returned from Select statement*/
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    printf("\n***** NEXT ROW ***** \n\n");
    printf(" CUSTOMER ID       : %d\n", CID);
    printf(" PURCHASE ORDER NO : %d\n", PID);
    if (Status.ind >= 0)
      {
        printf(" STATUS            : %s\n", Status.val);
      }
    else
      {
        printf(" STATUS            : NULL\n");
      }
    if (OrderDate.ind >=0)
      {
        printf(" ORDER DATE        : %s\n", OrderDate.val);
      }
    else
      {
        printf(" ORDER DATE        : NULL\n");
      }
    if (Comment.ind >=0)
      {
        printf(" COMMENT           : %s\n", Comment.val);
      }
    else
      {
        printf(" COMMENT           : NULL\n");
      }
    if (POrder.ind >=0)
      {
        printf(" PURCHASE ORDER    : %s\n", POrder.val);
      }
    else
      {
        printf(" PURCHASE ORDER    : NULL\n");
      }
    
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end ReadPurchaseOrder */
