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
** SOURCE FILE NAME: dbmcon.c                                       
**                                                                        
** SAMPLE: How to use multiple databases
**
**         This sample program requires that you create a second database
**         as follows:
**         - locally:
**             db2 create db sample2
**         - remotely:
**             db2 attach to node_name
**             db2 create db sample2
**             db2 detach
**             db2 catalog db sample2 as sample2 at node node_name
**
**         In the case where another name is used for the second database,
**         it can be specified in the command line arguments as follows:
**             dbmcon [dbAlias1 dbAlias2 [user1 pswd1 [user2 pswd2]]
**
**         If you do not have the appropriate privileges for autobinding,
**         you may need to rebind the CLI bind files after creating the
**         second database.  Issue the following command at the command line
**         prompt from the bnd subdirectory of the instance:
**             db2 bind @db2cli.lst blocking all grant public
**
**         The second database can be dropped as follows:
**         - locally:
**             db2 drop db sample2
**         - remotely:
**             db2 attach to node_name
**             db2 drop db sample2
**             db2 detach
**             db2 uncatalog db sample
**
**         This sample also requires that the TCPIP listener is running. To
**         ensure this, do the following:
**         1. Set the environment variable DB2COMM to TCPIP as follows: 
**         "db2set DB2COMM=TCPIP"
**         2. Update the database manager configuration file with the TCP/IP 
**         service name as specified in the services file:
**         "db2 update dbm cfg using SVCENAME <TCP/IP service name>"
**         You must do a "db2stop" and "db2start" for this setting to take
**         effect.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLSetConnectAttr -- Set Connection Attributes
**
** OUTPUT FILE: dbmcon.out (available in the online documentation)
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
#include "utilcli.h"

int TwoConnType1Use(SQLHANDLE, char *, char *, char *, char *,
                    char *, char *);
int TwoConnType2TwoPhaseUse(SQLHANDLE, char *, char *, char *,
                            char *, char *, char *);

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE henv; /* environment handle */

  char dbAlias1[SQL_MAX_DSN_LENGTH + 1];
  char user1[MAX_UID_LENGTH + 1];
  char pswd1[MAX_PWD_LENGTH + 1];

  char dbAlias2[SQL_MAX_DSN_LENGTH + 1];
  char user2[MAX_UID_LENGTH + 1];
  char pswd2[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck3(argc,
                         argv,
                         dbAlias1,
                         dbAlias2,
                         user1,
                         pswd1,
                         user2,
                         pswd2);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO USE MULTIPLE DATABASES.\n");

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

  /* perform transactions on two connections using Type 1 connect */
  rc = TwoConnType1Use(henv, dbAlias1, dbAlias2, user1, pswd1, user2, pswd2);

  /* perform transactions on two connections
     using a Type 2 connection with two-phase commit */
  rc = TwoConnType2TwoPhaseUse(henv,
                               dbAlias1,
                               dbAlias2,
                               user1,
                               pswd1,
                               user2,
                               pswd2);

  /* free the environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  ENV_HANDLE_CHECK(henv, cliRC);

  return 0;
} /* main */

/* connect to two databases using a Type 1 connection */
int TwoConnType1Use(SQLHANDLE henv,
                    char dbAlias1[],
                    char dbAlias2[],
                    char user1[],
                    char pswd1[],
                    char user2[],
                    char pswd2[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hdbc1, hdbc2; /* connection handles */
  SQLHANDLE hstmt1, hstmt2, hstmt3, hstmt4; /* statement handles */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLConnect\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM TRANSACTIONS ON TWO CONNECTIONS\n");
  printf("USING TYPE 1 CONNECT:\n");

  /* allocate the first database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* allocate the second database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* set TYPE 1 CONNECT for the both connections */
  printf("\n  Set TYPE 1 CONNECT for both connections.\n");
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_CONNECTTYPE,
                            (SQLPOINTER)SQL_CONCURRENT_TRANS,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_CONNECTTYPE,
                            (SQLPOINTER)SQL_CONCURRENT_TRANS,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Connect to '%s' database.\n", dbAlias1);

  /* connect to the first database */
  cliRC = SQLConnect(hdbc1,
                     (SQLCHAR *)dbAlias1,
                     SQL_NTS,
                     (SQLCHAR *)user1,
                     SQL_NTS,
                     (SQLCHAR *)pswd1,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Connect to '%s' database.\n", dbAlias2);

  /* connect to the second database */
  cliRC = SQLConnect(hdbc2,
                     (SQLCHAR *)dbAlias2,
                     SQL_NTS,
                     (SQLCHAR *)user2,
                     SQL_NTS,
                     (SQLCHAR *)pswd2,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /*********   Start using the connections  ************************/

  /* set AUTOCOMMIT OFF for the both connections */
  printf("\n  Enable transactions for connection 1.\n");
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Enable transactions for connection 2.\n");
  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* allocate the handle for statement 1 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc1, &hstmt1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* allocate the handle for statement 2 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc1, &hstmt2);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* allocate the handle for statement 3 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc2, &hstmt3);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* allocate the handle for statement 4 */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc2, &hstmt4);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Perform statements on both connections.\n");
  printf("\n  executing statement 1 on connection 1...\n");

  /* execute statement 1 on connection 1 */
  cliRC = SQLExecDirect(hstmt1,
                        (SQLCHAR *)"CREATE TABLE table1(col1 INTEGER)",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt1, henv, cliRC);

  printf("  executing statement 2 on connection 1...\n");

  /* execute statement 2 on connection 1 */
  cliRC = SQLExecDirect(hstmt2, (SQLCHAR *)"DROP TABLE table1", SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt2, henv, cliRC);

  printf("  commit the transaction on connection 1\n");

  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("\n  executing statement 3 on connection 2...\n");

  /* execute statement 3 on connection 2 */
  cliRC = SQLExecDirect(hstmt3,
                        (SQLCHAR *)"CREATE TABLE table1(col1 INTEGER)",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt3, henv, cliRC);

  printf("  executing statement 4 on connection 2...\n");

  /* execute statement 4 on connection 2 */
  cliRC = SQLExecDirect(hstmt4, (SQLCHAR *)"DROP TABLE table1", SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt4, henv, cliRC);

  printf("  commit the transaction on connection 2\n");

  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc2, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* free the handle for statement 1 */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  MC_STMT_HANDLE_CHECK(hstmt1, henv, cliRC);

  /* free the handle for statement 2 */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  MC_STMT_HANDLE_CHECK(hstmt2, henv, cliRC);

  /* free the handle for statement 3 */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
  MC_STMT_HANDLE_CHECK(hstmt3, henv, cliRC);

  /* free the handle for statement 4 */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt4);
  MC_STMT_HANDLE_CHECK(hstmt4, henv, cliRC);

  /*********   Stop using the connections  *************************/

  printf("\n  Disconnect from '%s' database.\n", dbAlias1);

  /* disconnect from the first database */
  cliRC = SQLDisconnect(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Disconnect from '%s' database.\n", dbAlias2);

  /* disconnect from the second database */
  cliRC = SQLDisconnect(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* free the handle for connection 1 */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* free the handle for connection 2 */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  return 0;
} /* TwoConnType1Use */

/* connect to two databases using a Type 2 connection with 
   two-phase commit */
int TwoConnType2TwoPhaseUse(SQLHANDLE henv,
                            char dbAlias1[],
                            char dbAlias2[],
                            char user1[],
                            char pswd1[],
                            char user2[],
                            char pswd2[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hdbc1, hdbc2; /* connection handles */
  SQLHANDLE hstmt1, hstmt2, hstmt3, hstmt4; /* statement handles */
  SQLHANDLE hstmt5, hstmt6, hstmt7, hstmt8; /* statement handles */

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  rownumber; /* variable to be bound to the ROW column */

  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[10];
  }
  value; /* variable to be bound to the VALUE column */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLConnect\n");
  printf("  SQLExecDirect\n");
  printf("  SQLEndTran\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO PERFORM TRANSACTIONS ON TWO CONNECTIONS\n");
  printf("USING TYPE 2 CONNECT WITH TWO-PHASE COMMIT:\n");

  /* allocate the first database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* allocate the second database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* set TYPE 2 CONNECT with two-phase commit for the both connections */
  printf("\n  Set TYPE 2 CONNECT two-phase commit for both connections.\n");
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_CONNECTTYPE,
                            (SQLPOINTER)SQL_COORDINATED_TRANS,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_SYNC_POINT,
                            (SQLPOINTER)SQL_TWOPHASE,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_CONNECTTYPE,
                            (SQLPOINTER)SQL_COORDINATED_TRANS,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);
  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_SYNC_POINT,
                            (SQLPOINTER)SQL_TWOPHASE,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Connect to '%s' database on connection 1.\n", dbAlias1);

  /* connect to the first database */
  cliRC = SQLConnect(hdbc1,
                     (SQLCHAR *)dbAlias1,
                     SQL_NTS,
                     (SQLCHAR *)user1,
                     SQL_NTS,
                     (SQLCHAR *)pswd1,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Connect to '%s' database on connection 2.\n", dbAlias2);

  /* connect to the second database */
  cliRC = SQLConnect(hdbc2,
                     (SQLCHAR *)dbAlias2,
                     SQL_NTS,
                     (SQLCHAR *)user2,
                     SQL_NTS,
                     (SQLCHAR *)pswd2,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /*********   Start using the connections  ************************/

  /* set AUTOCOMMIT OFF for both connections */
  printf("\n  Turn auto-commit OFF for connection 1.\n");
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Turn auto-commit OFF for connection 2.\n");
  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* allocate all statement handles */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc1, &hstmt1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc2, &hstmt2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc1, &hstmt3);
  DBC_HANDLE_CHECK(hdbc1, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc2, &hstmt4);
  DBC_HANDLE_CHECK(hdbc2, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc1, &hstmt5);
  DBC_HANDLE_CHECK(hdbc1, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc2, &hstmt6);
  DBC_HANDLE_CHECK(hdbc2, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc1, &hstmt7);
  DBC_HANDLE_CHECK(hdbc1, cliRC);
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc2, &hstmt8);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Perform statements on both connections:\n");
  printf("\n  Create table1 on connection 1.\n");

  /* create a table on connection 1 */
  cliRC = SQLExecDirect(hstmt1,
                        (SQLCHAR *)"CREATE TABLE table1(row INTEGER, value CHAR(10))",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt1, henv, cliRC);

  printf("  Create table1 on connection 2.\n");

  /* create a table on connection 2 */
  cliRC = SQLExecDirect(hstmt2,
                        (SQLCHAR *)"CREATE TABLE table1(row INTEGER, value CHAR(10))",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt2, henv, cliRC);

  printf("    Commit the transaction.\n");

  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* insert values into both tables */
  printf("\n  Insert values (1, 'abc') into table1 on connection 1.\n");
  cliRC = SQLExecDirect(hstmt3,
                        (SQLCHAR *)"INSERT INTO table1 VALUES (1, 'abc')",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt3, henv, cliRC);

  printf("  Insert values (1, 'def') into table1 on connection 2.\n");
  cliRC = SQLExecDirect(hstmt4,
                        (SQLCHAR *)"INSERT INTO table1 VALUES (1, 'def')",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt4, henv, cliRC);
  
  printf("    Commit the transaction.\n");
  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("\n  Check values inserted on both connections:\n");

  /* check values successfully inserted on connection 1 */
  cliRC = SQLExecDirect(hstmt5,
                        (SQLCHAR *)"SELECT * FROM table1",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt5, henv, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt5,
                     1,
                     SQL_C_SHORT,
                     &rownumber.val,
                     0,
                     &rownumber.ind);
  MC_STMT_HANDLE_CHECK(hstmt5, henv, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt5,
                     2,
                     SQL_C_CHAR,
                     value.val,
                     10,
                     &value.ind);
  MC_STMT_HANDLE_CHECK(hstmt5, henv, cliRC);

  printf("\n  CONNECTION 1");
  printf("\n  Fetch each row and display.\n");
  printf("    ROW #    VALUE     \n");
  printf("    -------- -------------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt5);
  MC_STMT_HANDLE_CHECK(hstmt5, henv, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-8d %-10.10s \n", rownumber.val, value.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt5);
    MC_STMT_HANDLE_CHECK(hstmt5, henv, cliRC);
  }

  /* Check values successfully inserted on connection 2 */
  cliRC = SQLExecDirect(hstmt6,
                        (SQLCHAR *)"SELECT * FROM table1",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt6, henv, cliRC);

  /* bind column 1 to variable */
  cliRC = SQLBindCol(hstmt6,
                     1,
                     SQL_C_SHORT,
                     &rownumber.val,
                     0,
                     &rownumber.ind);
  MC_STMT_HANDLE_CHECK(hstmt6, henv, cliRC);

  /* bind column 2 to variable */
  cliRC = SQLBindCol(hstmt6,
                     2,
                     SQL_C_CHAR,
                     value.val,
                     10,
                     &value.ind);
  MC_STMT_HANDLE_CHECK(hstmt6, henv, cliRC);

  printf("\n  CONNECTION 2\n");
  printf("  Fetch each row and display.\n");
  printf("    ROW #    VALUE     \n");
  printf("    -------- -------------\n");

  /* fetch each row and display */
  cliRC = SQLFetch(hstmt6);
  MC_STMT_HANDLE_CHECK(hstmt6, henv, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    %-8d %-10.10s \n", rownumber.val, value.val);

    /* fetch next row */
    cliRC = SQLFetch(hstmt6);
    MC_STMT_HANDLE_CHECK(hstmt6, henv, cliRC);
  }

  printf("\n  Drop table1 on connection 1.\n");

  cliRC = SQLExecDirect(hstmt7,
                        (SQLCHAR *)"DROP TABLE table1",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt7, henv, cliRC);

  printf("  Drop table1 on connection 2.\n");

  cliRC = SQLExecDirect(hstmt8,
                        (SQLCHAR *)"DROP TABLE table1",
                        SQL_NTS);
  MC_STMT_HANDLE_CHECK(hstmt8, henv, cliRC);
  
  printf("    Commit the transaction.\n");
  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  
  /* free all statement handles */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  MC_STMT_HANDLE_CHECK(hstmt1, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  MC_STMT_HANDLE_CHECK(hstmt2, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt3);
  MC_STMT_HANDLE_CHECK(hstmt3, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt4);
  MC_STMT_HANDLE_CHECK(hstmt4, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt5);
  MC_STMT_HANDLE_CHECK(hstmt5, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt6);
  MC_STMT_HANDLE_CHECK(hstmt6, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt7);
  MC_STMT_HANDLE_CHECK(hstmt7, henv, cliRC);
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt8);
  MC_STMT_HANDLE_CHECK(hstmt8, henv, cliRC);

  /*********   Stop using the connections  *************************/

  printf("\n  Disconnect from '%s' database.\n", dbAlias1);

  /* disconnect from the first database */
  cliRC = SQLDisconnect(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Disconnect from '%s' database.\n", dbAlias2);

  /* disconnect from the second database */
  cliRC = SQLDisconnect(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* free the handle for connection 1 */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* free the handle for connection 2 */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  return 0;
} /* TwoConnType2TwoPhaseUse */

