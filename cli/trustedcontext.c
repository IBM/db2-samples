/*****************************************************************************
**   (c) Copyright IBM Corp. 2007 All rights reserved.
**   
**   The following sample of source code ("Sample") is owned by International 
**   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
**   copyrighted and licensed, not sold. You may use, copy, modify, and 
**   distribute the Sample in any form without payment to IBM, for the purpose of 
**   assisting you in the development of your applications.
**   
**   The Sample code is provided to you on an "AS IS" basis, without warranty of 
**   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
**   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
**   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
**   not allow for the exclusion or limitation of implied warranties, so the above 
**   limitations or exclusions may not apply to you. IBM shall not be liable for 
**   any damages you suffer as a result of using, copying, modifying or 
**   distributing the Sample, even if IBM has been advised of the possibility of 
**   such damages.
*****************************************************************************
**                                                            
**  SAMPLE FILE NAME: trustedcontext.c
**                                                                          
**  PURPOSE:  To demonstrate 
**                1. Creating a trusted context object.
**                2. How to establish an explicit trusted connection.
**                3. Authorizing switching of the user on a trusted connection.
**                4. Acquiring trusted context-specific privileges through Role inheritance.
**                5. Altering a trusted context object.
**                6. Dropping a trusted context object.
**                                                                          
**  PREREQUISITES: 
**                1. a) Update the configuration parameter SVCENAME.
**                      db2 "update dbm cfg using svcename <TCP/IP port num>"
**                   b) Set communication protocol to TCP/IP.
**                      db2set DB2COMM=TCPIP
**                   c) Database "testdb" must be cataloged at a TCP/IP node. 
**                      1) Cataloging a TCP/IP node
**                         db2 catalog tcpip node <node_name> remote <server_name> server <TCP/IP_port_num>
**                      2) Cataloging a database as "testdb" on that TCP/IP node.
**                         db2 catalog database <dbname> as testdb at node <node_name>
**                   d) Stop and start the DB2 instance.
**                      db2 terminate;
**                      db2stop;
**                      db2start;
**                2. The following users with corresponding passwords must exist 
**                    a) A user with SECADM authority on database.
**	               		   padma with "padma123"  
**                       Grant SECADM authority to user "padma" using the below commands: 
**                         db2 "CONNECT TO testdb" 
**                         db2 "GRANT SECADM ON DATABASE TO USER padma"
**                         db2 "CONNECT RESET"
**                    b) A valid system authorization ID and password.
**                         bob with "bob123"          
**                    c) Normal Users without SYSADM and DBADM authorities.
**                         joe with "joe123"
**                         pat with "pat123"
**                         mit with "mit123"
**                                                                                                  
**  EXECUTION: i)  bldapp trustedcontext  (build the sample)
**             ii) trustedcontext <serverName> <userid> <password>
**                 eg: trustedcontext db2aix.ibm.com padma padma123
**                 userid and password that are passed must have the SECADM authority.
**                                                                          
**  INPUTS:    NONE
**                                                                          
**  OUTPUTS:   Successful establishment of a trusted connection and switching of the user.
**                                                                          
**  OUTPUT FILE:  trustedcontext.out (available in the online documentation)      
**                                     
**  SQL Statements USED:
**         CREATE TRUSTED CONTEXT
**         ALTER TRUSTED CONTEXT
**         GRANT
**         CREATE TABLE 
**         CREATE ROLE
**         INSERT
**         UPDATE
**         DROP ROLE
**         DROP TRUSTED CONTEXT
**         DROP TABLE
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol     -- Bind a Column to an Application Variable or
**                           LOB locator
**         SQLConnect     -- Connect to a Data Source
**         SQLSetConnectAttr -- Set connection attributes
**         SQLGetConnectAttr -- Get connection attributes
**         SQLFetch       -- Fetch next row
**         SQLDisconnect  -- Disconnect from a Data Source
**         SQLEndTran     -- End Transactions of a Connection
**         SQLExecDirect  -- Execute a Statement Directly
**         SQLFreeHandle  -- Free Handle Resources
**  
** *************************************************************************
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
** *************************************************************************
**
**  SAMPLE DESCRIPTION                                                      
**
****************************************************************************
**  1. Connect to the database and create the trusted context object and roles.
**  2. Establish the explicit trusted connection and grant privileges to the roles.      
**  3. Switch the current user on the connection to a different user 
**     with and without authentication.
**  4. Switch the current user on the connection to an invalid user.
**  5. Alter the trusted context object after disabling it.
**  6. Drop the objects created for trusted context and roles.
****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>
#include "utilcli.h" 

int main(int argc, char *argv[])
{

  SQLRETURN cliRC = SQL_SUCCESS;
  SQLHANDLE henv;
  SQLHANDLE hdbc = 0,hdbc1 = 0;
  SQLHANDLE hstmt,hstmt1,hstmt3,hstmt4;
  SQLCHAR stmt[500],sqlid[128];
  char dbName[9] = "testdb";
  int rc;

  /* Trusted context related variables */
  SQLCHAR authid[ MAX_UID_LENGTH] = "bob";
  SQLCHAR authid_pwd[MAX_PWD_LENGTH] = "bob123";
  SQLCHAR user1[ MAX_UID_LENGTH] = "joe";
  SQLCHAR user1_pwd[MAX_PWD_LENGTH] = "joe123";
  SQLCHAR user2[ MAX_UID_LENGTH] = "pat";
  SQLCHAR user2_pwd[MAX_PWD_LENGTH] = "pat123";
  SQLCHAR user3[ MAX_UID_LENGTH] = "mit";
  SQLCHAR user3_pwd[MAX_PWD_LENGTH] = "mit123";
    
  SQLCHAR tc_name[5] = "ctx1";
 
  /* Reading input arguments */
  SQLCHAR ServerName[MAX_UID_LENGTH]; 
  SQLCHAR UserId[MAX_UID_LENGTH];
  SQLCHAR Passwd[MAX_PWD_LENGTH];
  strcpy(ServerName,argv[1]);
  strcpy(UserId,argv[2]);
  strcpy(Passwd,argv[3]);
    
  /*-----------------------------------------------------------------*/
  /* set up the required CLI environment                             */
  /*-----------------------------------------------------------------*/
  /* allocate the environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  ENV_HANDLE_CHECK(henv, cliRC) ;

  /* allocate the database handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC) ;

  /* connect to a data source */
  cliRC = SQLConnect( hdbc,
                      (SQLCHAR *)dbName,
                      SQL_NTS,
                      UserId,
                      SQL_NTS,
                      Passwd,
                      SQL_NTS);

  DBC_HANDLE_CHECK(hdbc, cliRC);
  printf("\n---------------------------------------------------------------\n");
  printf("\tConnected to databse testdb using %s user\t",UserId);
  printf("\n---------------------------------------------------------------\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate the statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /*---------------------------------------------------------------*/
  /*        Create roles and trusted context object                */
  /*---------------------------------------------------------------*/
  /* Creating roles */
  strcpy((char *)stmt, "\n CREATE ROLE tc_role");
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("\n Created role tc_role ");
 
  strcpy((char *)stmt, "\n CREATE ROLE def_role");
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("\n Created role def_role \n");
 
  /* Creating a trusted context named 'ctx1' */
  strcpy((char *)stmt, " CREATE TRUSTED CONTEXT ");
  strcat((char *)stmt, (char *)tc_name);
  strcat((char *)stmt, " BASED UPON CONNECTION USING SYSTEM AUTHID  ");
  strcat((char *)stmt, authid);
  strcat((char *)stmt, " ATTRIBUTES (ADDRESS '" );
  strcat((char *)stmt, ServerName);
  strcat((char *)stmt, "' ) ");
  strcat((char *)stmt, "DEFAULT ROLE def_role");
  strcat((char *)stmt, " ENABLE  ");
  strcat((char *)stmt, "WITH USE FOR ");
  strcat((char *)stmt, user1);
  strcat((char *)stmt, " WITH AUTHENTICATION, ");
  strcat((char *)stmt, user2) ;
  strcat((char *)stmt, " ROLE tc_role ");
  strcat((char *)stmt, "WITHOUT AUTHENTICATION ");
  printf("%s\n",stmt);

  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("\n The trusted context object created \n");
  
  /* closing statement handle and database handle */
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  SQLFreeHandle(SQL_HANDLE_DBC, hdbc);

  /*---------------------------------------------------------------*/
  /*        Establishing an explicit trusted connection            */
  /*---------------------------------------------------------------*/
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC);
 
  /* set SQL_ATTR_USE_TRUSTED_CONTEXT to SQL_TRUE to enable explicit trusted connection */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_USE_TRUSTED_CONTEXT,
                            (SQLPOINTER)SQL_TRUE,
                            SQL_IS_INTEGER);
  DBC_HANDLE_CHECK(hdbc, cliRC);
 
  /* Check the connection type */
  cliRC = SQLGetConnectAttr(hdbc,SQL_ATTR_USE_TRUSTED_CONTEXT,&rc,0,NULL);
  DBC_HANDLE_CHECK(hdbc, cliRC);
   
  /* Connect to database using system auth id */
  cliRC = SQLConnect( hdbc,
                      (SQLCHAR *)dbName,
                      SQL_NTS,
                      authid,
                      SQL_NTS,
                      authid_pwd,
                      SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  if ( cliRC == SQL_SUCCESS)
  {
     printf("\n Established explicit trusted connection\n");
  }
  else if ( cliRC == SQL_SUCCESS_WITH_INFO)
  {
     printf("\n Failed to establish explicit trusted connection\n");
	 return 0;
  }
  else
  {
    printf("\n Error or Invalid Handle \n");
    return 0;
  }
  
  printf("---------------------------------------------------------------\n");
  printf("\tConnection established for %s user(system authid) \n",authid);
  printf("---------------------------------------------------------------\n");

  /* check the special register SYSTEM_USER to findout
     the user who is currently connected to the database*/
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  strcpy((char *)stmt, "VALUES SYSTEM_USER");
  cliRC = SQLExecDirect(hstmt3,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  printf("%s \n",  stmt);
  /* Bind an application variable to the result */
  cliRC = SQLBindCol(hstmt3,
                     1,
                     SQL_C_CHAR,
                     &sqlid,
                     255,
                     NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* fetch result and display */
  cliRC = SQLFetch(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  else
  {
    printf("\n Current user connected to database:  %s \n",sqlid);
  }
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt3);
  
  /* Compare the result with user id */
  if (strcmp(sqlid,authid))
  {
    printf("\n Connected as %s",sqlid);
    printf("\n Trusted connection worked for %s", authid);
  }
  else
  {
     printf("\n Trusted Conection failed ");
  }  

  printf("\n\n Create a table and grant privileges on it to the roles created \n");
  strcpy((char *)stmt, "CREATE TABLE tcschema.trusted_table(i1 int,i2 int) ");
    
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  printf("Table created succesfully \n");
  printf("\n Populating the table with data\n");
  
  strcpy((char *)stmt, "INSERT INTO tcschema.trusted_table VALUES(20,30) ");
  printf("%s \n",  stmt);
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  strcpy((char *)stmt, "INSERT INTO tcschema.trusted_table VALUES(40,50) ");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  
  /* Granting privileges to the roles on the table*/
  printf("\n Granting privileges to the roles on the table tcschema.trusted_table \n");

  strcpy((char *)stmt,"GRANT INSERT ON TABLE tcschema.trusted_table TO ROLE def_role ");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("%s \n",  stmt);
  strcpy((char *)stmt,"GRANT UPDATE ON TABLE tcschema.trusted_table TO ROLE tc_role ");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("%s \n",  stmt);
  
  printf("Granted privileges to roles def_role and tc_role on table tcschema.trusted_table\n"); 
  
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt);

  /*------------------------------------------------------------------------*/
  /* Switch to new user user1 under a trusted connection by providing 
     authentication information. user1 is explicitly defined as a user 
     of the trusted context.                                                */
  /*------------------------------------------------------------------------*/
  printf("---------------------------------------------------------------\n");
  printf("\tSwitching to %s user by providing authentication information.\n",user1);
  printf("---------------------------------------------------------------\n");

  /* set SQL_ATTR_TRUSTED_CONTEXT_USERID to user id to switch to
     and SQL_ATTR_TRUSTED_CONTEXT_PASSWORD to password of that user */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_TRUSTED_CONTEXT_USERID,
                            user1,
                            SQL_IS_POINTER);
  DBC_HANDLE_CHECK(hdbc,cliRC);
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_TRUSTED_CONTEXT_PASSWORD,
                            user1_pwd,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc,cliRC);
  printf("Switching the user id to user1 is successful \n");

  /*--------------------------------------------------------------------*/
  /*                Working with role inheritance                       */
  /*--------------------------------------------------------------------*/
  printf("\n Working with role inheritance ... \n");
 
  /* user1 will inherit the default privileges */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* check the special register SYSTEM_USER to findout
     the user who is currently connected to the database*/
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  strcpy((char *)stmt, "VALUES SYSTEM_USER");
  cliRC = SQLExecDirect(hstmt3,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  printf("%s \n",  stmt);
  /* Bind an application variable to the result */
  cliRC = SQLBindCol(hstmt3,
                     1,
                     SQL_C_CHAR,
                     &sqlid,
                     255,
                     NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* fetch result and display */
  cliRC = SQLFetch(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  else
  {
    printf("\n Current user connected to database:  %s \n",sqlid);
  }
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt3);
  
  /* Compare the result with user id */
  if (strcmp(sqlid,user1))
  {
    printf("\n Connected as %s",sqlid);
    printf("\n Success on switch user for %s by providing authentication information", user1);
  }
  else
  {
     printf("\n Switch user failed ");
  }  

  printf("\n\n Perform insert as the user has inherited default role privileges \n");   
  strcpy((char *)stmt, "INSERT INTO tcschema.trusted_table VALUES(100,200) ");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("%s \n",  stmt);

  strcpy((char *)stmt, "INSERT INTO tcschema.trusted_table VALUES(200,250) ");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("%s \n",  stmt);
  
  printf(" User has inherited trusted context-specific default role privileges ");
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt);

  printf("\n-------------------------------------------------------------------------\n");
  printf("\t Connect to database using %s not from trusted connection and \n", user2);
  printf("\t try to update the table tcschema.trusted_table which is not allowed \n");
  printf("-------------------------------------------------------------------------\n");

  /* Connect to database not from trusted connection and try to perform update on the table */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc1);
  ENV_HANDLE_CHECK(henv, cliRC) ;
 
  /* connect to database */
  cliRC = SQLConnect( hdbc1,
                      (SQLCHAR *)dbName,
                      SQL_NTS,
                      user2,
                      SQL_NTS,
                      user2_pwd,
                      SQL_NTS);
  DBC_HANDLE_CHECK(hdbc1, cliRC);

  printf("\n connected to database testdb not from trusted connection ");
  printf("\n perform Update on table...");
  strcpy((char *)stmt, "UPDATE tcschema.trusted_table set i1=40 ");
  cliRC = SQLExecDirect(hstmt4,stmt,SQL_NTS);
  if (cliRC != SQL_SUCCESS)
  {
      printf("\n\n Not allowed to update");
	  printf("\n This is an expected error \n");
      rc = HandleInfoPrint(SQL_HANDLE_STMT, hstmt,     cliRC, __LINE__, __FILE__);
      if (rc == 2) StmtResourcesFree(hstmt);
      if (rc != 0) TransRollback(hdbc);
  }

  /* Free the handles used*/
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt4);
  SQLFreeHandle(SQL_HANDLE_DBC, hdbc1);

  printf("\n-------------------------------------------------------------------------\n");
  printf("\tSwitching  to %s user without providing authentication information. \n", user2);
  printf("-------------------------------------------------------------------------\n");

  /* Switch to another user without providing authentication information.
     Can update the table as user2 has UPDATE privilege on the table.  */

  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_TRUSTED_CONTEXT_USERID,
                            user2,
                            SQL_IS_POINTER);
   DBC_HANDLE_CHECK(hdbc,cliRC);

   printf("Switching to user %s is successful \n",user2);
   printf("As the tc_role has UPDATE privilege on tcschema.trusted_table\t");
   printf("\n %s is also able to work on that table\n",user2);
   printf(" Update table tcschema.trusted_table\n");
 
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
   STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);
  
  /* check the special register SYSTEM_USER to findout
     the user who is currently connected to the database*/
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  strcpy((char *)stmt, "VALUES SYSTEM_USER");
  cliRC = SQLExecDirect(hstmt3,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  printf("%s \n",  stmt);
  /* Bind an application variable to the result */
  cliRC = SQLBindCol(hstmt3,
                     1,
                     SQL_C_CHAR,
                     &sqlid,
                     255,
                     NULL);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

  /* fetch result and display */
  cliRC = SQLFetch(hstmt3);
  STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  else
  {
    printf("\n Current user connected to database:  %s \n",sqlid);
  }
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt3);
  
  /* Compare the result with user id */
  if (strcmp(sqlid,user2))
  {
    printf("\n Connected as %s",sqlid);
    printf("\n Success on switch user for %s without providing authentication information", sqlid);
  }
  else
  {
     printf("Switch user failed ");
  }  

   strcpy((char *)stmt, "UPDATE tcschema.trusted_table set i1=60 ");
   cliRC = SQLExecDirect(hstmt1,stmt,SQL_NTS);
   STMT_HANDLE_CHECK(hstmt1, hdbc, cliRC);

   printf("\n\n Updated table tcschema.trusted_table\n");
   printf(" User has inherited trusted context-specific privileges \n\n");

   SQLFreeHandle(SQL_HANDLE_STMT,hstmt1);
   SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   
   /*------------------------------------------------------------------------*/
   /* Switch to user authid under a trusted connection to drop 
    * the objects created.                                                   */
   /*------------------------------------------------------------------------*/
   printf("---------------------------------------------------------------\n");
   printf("\tSwitching to %s user by providing authentication information.\n",authid);
   printf("---------------------------------------------------------------\n");

   /* set SQL_ATTR_TRUSTED_CONTEXT_USERID to user id to switch to
    *      and SQL_ATTR_TRUSTED_CONTEXT_PASSWORD to password of that user */
   cliRC = SQLSetConnectAttr(hdbc,
                             SQL_ATTR_TRUSTED_CONTEXT_USERID,
                             authid,
                             SQL_IS_POINTER);
   DBC_HANDLE_CHECK(hdbc,cliRC);
   cliRC = SQLSetConnectAttr(hdbc,
                             SQL_ATTR_TRUSTED_CONTEXT_PASSWORD,
                             authid_pwd,
                             SQL_NTS);
   DBC_HANDLE_CHECK(hdbc,cliRC);
   printf("Switching of the user is successful \n");

   /* check the special register SYSTEM_USER to findout
    *      the user who is currently connected to the database*/
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt3);
   STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

   strcpy((char *)stmt, "VALUES SYSTEM_USER");
   cliRC = SQLExecDirect(hstmt3,stmt,SQL_NTS);
   STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
   printf("%s \n",  stmt);
   /* Bind an application variable to the result */
   cliRC = SQLBindCol(hstmt3,
                      1,
                      SQL_C_CHAR,
                      &sqlid,
                      255,
                      NULL);
   STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);

   /* fetch result and display */
   cliRC = SQLFetch(hstmt3);
   STMT_HANDLE_CHECK(hstmt3, hdbc, cliRC);
   if (cliRC == SQL_NO_DATA_FOUND)
   {
        printf("\n  Data not found.\n");
   }
   else
   {
        printf("\n Current user connected to database:  %s \n",sqlid);
   }
   SQLFreeHandle(SQL_HANDLE_STMT,hstmt3);

   /* Compare the result with user id */
   if (strcmp(sqlid,authid))
   {
       printf("\n Connected as %s",sqlid);
       printf("\n Success on switch user for %s by providing authentication information", authid);
   }                                          
   else
   {
       printf("\n Switch user failed ");
   }
   SQLFreeHandle(SQL_HANDLE_STMT,hstmt3);
   
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt4);
   STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);
   /* drop the table tcschema.trusted_table */
   strcpy((char *)stmt, "DROP table tcschema.trusted_table");
   cliRC = SQLExecDirect(hstmt4,stmt,SQL_NTS);
   STMT_HANDLE_CHECK(hstmt4, hdbc, cliRC);

   printf("\n Dropped the table tcschema.trusted_table\n");

   SQLFreeHandle(SQL_HANDLE_STMT,hstmt4);
   SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /*----------------------------------------------------------------*/
   /*  Switching to an invalid user                                 */
   /*----------------------------------------------------------------*/
   printf("\n---------------------------------------------------------------\n");
   printf("\tSwitching to %s user who is not a user of trusted context \n",user3);
   printf("---------------------------------------------------------------\n");
   cliRC = SQLSetConnectAttr(hdbc,
                             SQL_ATTR_TRUSTED_CONTEXT_USERID,
                             user3,
                             SQL_IS_POINTER);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   cliRC = SQLSetConnectAttr(hdbc,
                             SQL_ATTR_TRUSTED_CONTEXT_PASSWORD,
                             user3_pwd,
                             SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   
   strcpy((char *)stmt, "UPDATE tcschema.trusted_table set i2=900 ");
   cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
   if (cliRC != SQL_SUCCESS)   
   {
	   printf("\n This is an expected error \n");
       rc = HandleInfoPrint(SQL_HANDLE_STMT, hstmt,     cliRC, __LINE__, __FILE__); 
       if (rc == 2) StmtResourcesFree(hstmt);           
       if (rc != 0) TransRollback(hdbc);                
   }

  /* closing statement handle and database handle */
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  
  /*---------------------------------------------------------------*/
  /*       Altering the  trusted context definition                */
  /*---------------------------------------------------------------*/
  
  printf("---------------------------------------------------------------\n");
  printf("\tAltering the  trusted context object\n");
  printf("---------------------------------------------------------------\n");
    
  printf("Connect to databse using %s \n", UserId);
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, cliRC) ;
 
  /* connect to database */
  cliRC = SQLConnect( hdbc,
                      (SQLCHAR *)dbName,
                      SQL_NTS,
                      UserId,
                      SQL_NTS,
                      Passwd,
                      SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("Disable the role tc_role using ALTER\n");

  strcpy((char *)stmt, "ALTER TRUSTED CONTEXT ctx1 ALTER DEFAULT ROLE tc_role DISABLE ") ;
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("Trusted context has been DISABLED for the role tc_role: \n\t %s \n",stmt);
 
  printf("---------------------------------------------------------------\n");
  printf("\t Drop the objects\n");
  printf("---------------------------------------------------------------\n");
 
  /* Drop the roles and trusted context 'ctx1' */
  strcpy((char *)stmt,"DROP TRUSTED CONTEXT ctx1 ");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* Drop the Roles */
  strcpy((char *)stmt, "DROP ROLE tc_role");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  strcpy((char *)stmt, "DROP ROLE def_role");
  cliRC = SQLExecDirect(hstmt,stmt,SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("The roles def_role, tc_role and trusted context ctx1 have been dropped\n");

  SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);
  
  /* closing statement handle and database handle */
  SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
 
  return 0;
}


