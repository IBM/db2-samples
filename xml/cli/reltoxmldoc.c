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
** SOURCE FILE NAME: reltoxmldoc.c
**
** SAMPLE: Purchase order database uses relational tables to store the orders of
**         different customers. This data can be returned as an XML object to the
**         application. The XML object can be created using the XML constructor
**         functions on the server side.
**         To achieve this, the user can
**           1. Create a stored procedure to implement the logic to create the XML
**              object using XML constructor functions.
**           2. Register the above stored procedure to the database.
**           3. Call the procedure whenever all the PO data is needed instead of using complex joins.
**
**         To run this sample, peform the following steps:
**           1. create and populate the SAMPLE database 
**           2. create stored procedure reltoxmlproc by executing
**		db2 -td@ -f reltoxmlproc.db2
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLPrepare -- Prepare a Statement
**
** SQL/XML FUNCTIONS USED:
**         XMLELEMENT
**         XMLATTRIBUTES
**         XMLCONCAT
**         XMLNAMESPACES
**         XMLCOMMENT
**
** EXTERNAL DEPENDENCIES:
**      Ensure that the stored procedures called from this program have
**      been built and cataloged with the database.
**
** OUTPUT FILE: reltoxmldoc.out (available in the online documentation)
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

int SelectFromRelationalTable(SQLHANDLE);
int callRelToXmlProc(SQLHANDLE);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  double medSalary = 0;
  char language[9];

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
  rc = SelectFromRelationalTable(hdbc);

  printf("CALL STORED PROCEDURE RELTOXMLPROC.\n");
  /********************************************************/
  /* call RELTOXMLPROC stored procedure                   */
  /********************************************************/
  rc = callRelToXmlProc(hdbc);

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


/* perform a basic SELECT operation using SQLBindCol */
int SelectFromRelationalTable(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLINTEGER CustId;         /* variable to be bound to the CustId column */
  SQLINTEGER PoNum;          /* variable to be bound to the PoNum column */
  SQLVARCHAR OrderDate[11];  /* variable to be bound to OrderDate Comment column */
  SQLVARCHAR Status[30];     /* variable to be bound to the Status column */
  SQLVARCHAR ProdId[10];     /* variable to be bound to the ProdId column */
  SQLDOUBLE Price;           /* variable to be bound to the Price column */
  SQLVARCHAR Name[30];       /* Variable to be bound to the Name column */
  SQLVARCHAR Street[20];     /* Variable to be bound to the Street column */
  SQLVARCHAR City[20];       /* Variable to be bound to the City column */
  SQLVARCHAR Province[20];   /* Variable to be bound to the Province column */
  SQLINTEGER PostalCode;     /* Variable to be bound to the PostalCode column */
  SQLVARCHAR Comment[200];   /* Variable to be bound to the Comment column */
  SQLCHAR stmt[500] = {0}; 
  
  /* The SQL statement that has to be executed is copied to stmt */
  /* using the strcpy and strcat functions */
  strcpy((char *)stmt, "SELECT po.CustID, po.PoNum, po.OrderDate, po.Status, ");
  strcat((char *)stmt, "count(l.ProdID) as Items, sum(p.Price) as total, po.Comment, ");
  strcat((char *)stmt, "c.Name, c.Street, c.City, c.Province, c.PostalCode ");
  strcat((char *)stmt, "FROM PurchaseOrder_relational as po,CustomerInfo_relational as c, ");
  strcat((char *)stmt, "Lineitem_relational as l, Products_relational as p ");
  strcat((char *)stmt, "WHERE po.CustID = c.CustID and po.PoNum = l.PoNum ");
  strcat((char *)stmt, "and l.ProdID = p.ProdID ");
  strcat((char *)stmt, "GROUP BY po.PoNum,po.CustID,po.OrderDate,po.Status,c.Name, ");
  strcat((char *)stmt, "c.Street, c.City,c.Province, c.PostalCode,po.Comment ");
  strcat((char *)stmt, "ORDER BY po.CustID,po.OrderDate");
  
  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n\n");
  printf("  SELECT po.CustID, po.PoNum, po.OrderDate, po.Status,\n");
  printf("         count(l.ProdID) as Items, sum(p.Price) as total,\n");
  printf("         po.Comment, c.Name, c.Street, c.City, c.Province, c.PostalCode\n");
  printf("    FROM PurchaseOrder_relational as po, CustomerInfo_relational as c,\n");
  printf("         Lineitem_relational as l, Products_relational as p\n");
  printf("    WHERE po.CustID = c.CustID and po.PoNum = l.PoNum and l.ProdID = p.ProdID\n");
  printf("    GROUP BY po.PoNum,po.CustID,po.OrderDate,po.Status,c.Name,\n");
  printf("             c.Street, c.City,c.Province, c.PostalCode,po.Comment\n");
  printf("    ORDER BY po.CustID,po.OrderDate\n");
 
  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &CustId, 0, NULL );
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_LONG, &PoNum, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, &OrderDate, 11, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, &Status, 30, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 5 to variable */
  cliRC = SQLBindCol(hstmt, 5, SQL_C_CHAR, &ProdId, 10, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 6 to variable */
  cliRC = SQLBindCol(hstmt, 6, SQL_C_DOUBLE, &Price, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 7 to variable */
  cliRC = SQLBindCol(hstmt, 7, SQL_C_CHAR, &Comment, 200, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 8 to variable */
  cliRC = SQLBindCol(hstmt, 8, SQL_C_CHAR, &Name, 30, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 9 to variable */
  cliRC = SQLBindCol(hstmt, 9, SQL_C_CHAR, &Street, 20, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
  /* bind column 10 to variable */
  cliRC = SQLBindCol(hstmt, 10, SQL_C_CHAR, &City, 20, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 11 to variable */
  cliRC = SQLBindCol(hstmt, 11, SQL_C_CHAR, &Province, 20, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* bind column 12 to variable */
  cliRC = SQLBindCol(hstmt, 12, SQL_C_LONG, &PostalCode, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Fetch each row and display.\n");
  printf("    CUSTOMER_ID PO_NO    ORDER_DATE   STATUS               TOTAL_PROD         PRICE   COMMENT");
  printf("                NAME         STREET         CITY           PROVINCE         POSTAL_CODE\n");
  printf("    ------------------- ---------------------------------------------------------------------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-8d %-8d %-11s %-30s %-10s %f %-200s %-30s %-20s %-20s %-20s %d\n", 
      CustId, PoNum, OrderDate, Status, ProdId, Price, Comment, Name, Street, City, Province, PostalCode);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* SelectFromRelationalTable */


/* call the RELTOXMLPROC stored procedure */
int callRelToXmlProc(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  char procName[] = "RELTOXMLPROC"; 
  SQLCHAR *stmt = (SQLCHAR *)"CALL RELTOXMLPROC ()";
  SQLSMALLINT numCols;
  SQLUINTEGER PoNum;
  SQLUINTEGER CustId;
  SQLCHAR OrderDate[11];
  SQLVARCHAR PurchaseOrder[2000];


  printf("CALL stored procedure: %s\n", procName);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* get number of result columns */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Result set returned %d columns\n", numCols);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_LONG, &PoNum, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt, 2, SQL_C_LONG, &CustId, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 3 to variable */
  cliRC = SQLBindCol(hstmt, 3, SQL_C_CHAR, &OrderDate, 11, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column 4 to variable */
  cliRC = SQLBindCol(hstmt, 4, SQL_C_CHAR, &PurchaseOrder,3000, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("Stored procedure returned successfully.\n");

  /* fetch result set returned from stored procedure */
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\nFirst result set returned from %s", procName);
  printf("\n------PoNum------,  --CustId--, ---OrderDate--, --PurchaseOrder--  \n");
  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    printf("%17d, %11d, %11s,    %s\n\n\n", PoNum, CustId, OrderDate, PurchaseOrder);

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free the statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* end callRelToXmlProc */
