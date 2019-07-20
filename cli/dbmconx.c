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
** SOURCE FILE NAME: dbmconx.c                                       
**                                                                        
** SAMPLE: How to use multiple databases with embedded SQL.
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
**             dbmconx [dbAlias1 dbAlias2 [user1 pswd1 [user2 pswd2]]
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
** OUTPUT FILE: dbmconx.out (available in the online documentation)
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
#include "dbmconx1.h"
#include "dbmconx2.h"

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

  printf("\nTHIS SAMPLE SHOWS HOW TO USE MULTIPLE DATABASES");
  printf("\nIN CONJUNCTION WITH EMBEDDED SQL.\n");

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

  /* perform transactions on two connections using Type 2 connect
     with two-phase commit */
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

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE SQL STATEMENTS\n");
  printf("  CREATE TABLE\n");
  printf("  DROP TABLE\n");
  printf("AND THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLConnect\n");
  printf("  SQLSetConnection\n");
  printf("  SQLEndTran\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO MIX CLI WITH EMBEDDED SQL\n");
  printf("ON TWO CONNECTIONS USING TYPE 1 CONNECT:\n");

  /* allocate the first database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* allocate the second database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Set TYPE 1 CONNECT for both connections.\n");

  /* set Type 1 CONNECT for the first connection */
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_CONNECTTYPE,
                            (SQLPOINTER)SQL_CONCURRENT_TRANS,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* set Type 1 CONNECT for the second connection */
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

  printf("\n  Enable transactions for connection 1.\n");

  /* set AUTOCOMMIT OFF for the first connection */
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Enable transactions for connection 2.\n");

  /* set AUTOCOMMIT OFF for the second connection */
  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Perform statements on the first connection.\n");

  /* perform statements on the first connection */
  cliRC = SQLSetConnection(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  rc = FirstDbCreateTable();
  rc = FirstDbDropTable();

  printf("  Commit the transaction on connection 1\n");

  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("\n  Perform statements on the second connection.\n");

  /* perform statements on the second connection */
  cliRC = SQLSetConnection(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  rc = SecondDbCreateTable();
  rc = SecondDbDropTable();

  printf("  Commit the transaction on connection 2\n");

  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc2, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /*********   Stop using the connections  *************************/

  printf("\n  Disconnect from '%s' database.\n", dbAlias1);

  /* disconnect from the first database */
  cliRC = SQLDisconnect(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Disconnect from '%s' database.\n", dbAlias2);

  /* disconnect from the second database */
  cliRC = SQLDisconnect(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* free the first connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* free the second connection handle */
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

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE SQL STATEMENTS\n");
  printf("  CREATE TABLE\n");
  printf("  DROP TABLE\n");
  printf("AND THE CLI FUNCTIONS\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLConnect\n");
  printf("  SQLEndTran\n");
  printf("  SQLDisconnect\n");
  printf("  SQLFreeHandle\n");
  printf("TO MIX CLI WITH EMBEDDED SQL\n");
  printf("ON TWO CONNECTIONS USING TYPE 2 CONNECT WITH TWO-PHASE COMMIT:\n");
  
  /* allocate the first database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* allocate the second database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Set TYPE 2 CONNECT two-phase commit for both connections.\n");

  /* set TYPE 2 CONNECT with two-phase commit for the first connection */
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

  /* set TYPE 2 CONNECT with two-phase commit for the second connection */
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

  printf("\n  Enable transactions for connection 1.\n");

  /* set AUTOCOMMIT OFF for the first connection */
  cliRC = SQLSetConnectAttr(hdbc1,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Enable transactions for connection 2.\n");

  /* set AUTOCOMMIT OFF for the second connection */
  cliRC = SQLSetConnectAttr(hdbc2,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  printf("\n  Perform statements on the first connection.\n");

  /* perform statements on the first connection */
  cliRC = SQLSetConnection(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  rc = FirstDbCreateTable();

  printf("  Perform statements on the second connection.\n");
  
  /* perform statements on the second connection */
  cliRC = SQLSetConnection(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  rc = SecondDbCreateTable();

  printf("\n  Commit the transaction.\n");
  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("\n  Perform statements on the first connection.\n");

  /* perform statements on the first connection */
  cliRC = SQLSetConnection(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);
  
  rc = FirstDbDropTable();

  printf("  Perform statements on the second connection.\n");

  /* perform statements on the second connection */
  cliRC = SQLSetConnection(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  rc = SecondDbDropTable();

  printf("\n  Commit the transaction.\n");
  /* end the transaction */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc1, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc1, cliRC);


  /*********   Stop using the connections  *************************/

  printf("\n  Disconnect from '%s' database.\n", dbAlias1);

  /* disconnect from the first database */
  cliRC = SQLDisconnect(hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("  Disconnect from '%s' database.\n", dbAlias2);

  /* disconnect from the second database */
  cliRC = SQLDisconnect(hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  /* free the first connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc1);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  /* free the second connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, hdbc2);
  DBC_HANDLE_CHECK(hdbc2, cliRC);

  return 0;
} /* TwoConnType2TwoPhaseUse */

