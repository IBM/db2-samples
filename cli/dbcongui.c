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
** SOURCE FILE NAME: dbcongui.c
**
** SAMPLE: How to connect to a database with a graphical user interface (GUI)
**   
**         Note: The GUI feature is only supported on the Windows NT platform.
**               o You can still connnect to the database without the GUI
**                 feature on non-NT Windows platforms by providing four
**                 arguments (see below).
**               o You can still connect to the database without the GUI
**                 feature on UNIX platforms by providing either two or four
**                 arguments (see below).
**
**         This program demonstrates how SQLDriverConnect() can be used to
**         prompt a user for connection information through a GUI.  The
**         application behaves differently depending on how many arguments
**         you supply when calling it from the command line:
**
**           o If one command line argument (program name) is supplied, the
**             user will be prompted for the database alias, user ID, and
**             password by a window that appears.
**
**           o If two arguments (program name, database alias) are supplied,
**             the user will be prompted for the user ID and password by
**             a window that appears.
**
**           o If three arguments (program name, database alias, user ID) are
**             supplied, a usage message is displayed indicating how the
**             program should be called:
**               USAGE: dbcongui [dbAlias [userid  passwd]]
**
**           o If four arguments (program name, database alias, user ID,
**             password) are supplied, the program will establish a connection
**             to the target database without prompting the user for any
**             further information.
**
**         This sample also allows you to change the password through a GUI.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLDriverConnect -- Connect to a Data Source (Expanded)
**         SQLFreeHandle -- Free Handle Resources
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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sqlcli1.h>
#include "utilcli.h" /* header file for CLI sample code */

int main(int argc, char * argv[])
{
  SQLHWND sqlHWND; /* window handle */
  SQLCHAR inConnectionString[255]; /* connection string */
  SQLSMALLINT strLength1; /* length of inConnectionString */
  SQLCHAR outConnectionString[255];  
  SQLSMALLINT bufferLength;
  SQLSMALLINT strLength2[255];
  SQLUSMALLINT driveCompletion; /* indicate prompting information */
  short rc = 0; 
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* database connection handle */
  char dbAlias[SQL_MAX_DSN_LENGTH + 1] ;
  char user[MAX_UID_LENGTH + 1] ;
  char pswd[MAX_PWD_LENGTH + 1] ;
  
  printf("\nTHIS SAMPLE SHOWS ");
  printf("HOW TO CONNECT TO AND DISCONNECT FROM A DATABASE\n");
  printf("USING THE CLI FUNCTION SQLDRIVERCONNECT.\n");

  /* check the command line arguments */
  rc = CmdLineArgsCheck1( argc, argv, dbAlias, user, pswd );
  if ( rc != 0 )
  {    
    return( 1 ) ;     
  }
  else
  {  
    printf("\n----------------------------------------------------------");
    printf("\nUSE THE CLI FUNCTIONS\n");
    printf("  SQLAllocHandle\n");
    printf("  SQLDriverConnect\n");
    printf("  SQLFreeHandle\n");
    printf("TO CONNECT TO A DATABASE:\n\n");
    
    strcpy((char*)strLength2, "");
    sprintf((char*)outConnectionString, "%s","");
    bufferLength = SQL_MAX_OPTION_STRING_LENGTH;
    
    switch (argc)
    {    
      /* no arguments supplied to the program */
      case 1:
        sqlHWND =  0L;
        sprintf((char *)inConnectionString, "%s", "");
        strLength1 = 0;
        driveCompletion = SQL_DRIVER_PROMPT;
        printf("  You have entered the [program name].\n\n");
        printf("  On the Windows platform:\n");
        printf("  1) Choose the database alias you want to connect to\n");
        printf("     from the 'Database alias' pull-down menu.\n");
        printf("  2) [Optional] Enter your user ID and password ");
        printf("in the appropriate fields.\n");
        printf("  3) [Optional] If you want to change your password, ");
        printf("check the 'Change password'\n");
        printf("     checkbox and enter your new password.\n"); 
        printf("  4) [Optional] Select a connection mode.\n");
        printf("  5) Click on the 'OK' button to COMMIT or the ");   
        printf("'Cancel' button to cancel.\n\n");
        break;

      /* one argument (database alias) supplied to the program */
      case 2:
        sqlHWND =  0L;
        sprintf((char *)inConnectionString, "DSN=%s;UID=%s;PWD=%s",
                argv[1], "","");                             
        strLength1 = SQL_MAX_OPTION_STRING_LENGTH;             
        driveCompletion = SQL_DRIVER_COMPLETE;
        printf("  You have entered the [program name, database alias].\n ");
        printf("  On the Windows platform:\n");
        printf("  1) Enter your user ID and password ");
        printf("in the appropriate fields.\n");
        printf("  2) [Optional] If you want to change your password, ");
        printf("check the 'Change password'\n");
        printf("     checkbox and enter your new password.\n"); 
        printf("  3) [Optional] Select a connection mode.\n");
        printf("  4) Click on the 'OK' button to COMMIT or the ");   
        printf("'Cancel' button to cancel.\n\n");
        break;
  
      /* two arguments (database alias, user ID) supplied to the program */ 
      case 3:
        sqlHWND =  0L;         
        sprintf((char *)inConnectionString, "DSN=%s;UID=%s;PWD=%s",
                argv[1], argv[2], "");
        strLength1 = SQL_MAX_OPTION_STRING_LENGTH; 
        driveCompletion = SQL_DRIVER_COMPLETE_REQUIRED;
        break;
        
      /* three arguments (database alias, user ID, password)
         supplied to the program */
      case 4:
        sqlHWND =  0L;
        sprintf((char *)inConnectionString, "DSN=%s;UID=%s;PWD=%s", argv[1],
                argv[2], argv[3]);
        strLength1 = SQL_MAX_OPTION_STRING_LENGTH; 
        driveCompletion = SQL_DRIVER_NOPROMPT;                   
        printf("  You have entered the [program name, database alias, ");
        printf("userid, passwd].\n\n");
        printf("  All of the required information has been supplied, \n");
        printf("  so now connecting to the database without prompting.\n\n");
        break;
    } 
  }

        
  /* allocate an environment handle */
  rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  ENV_HANDLE_CHECK(henv, rc);
  
  /* set attribute to enable application to run as ODBC 3.0 application */
  rc = SQLSetEnvAttr(henv,
                     SQL_ATTR_ODBC_VERSION,
                     (void *)SQL_OV_ODBC3,
                     0);
  ENV_HANDLE_CHECK(henv, rc);

  /* allocate a database connection handle */
  rc = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  DBC_HANDLE_CHECK(hdbc, rc);
  
  /* connect to a database with SQLDriverConnect, which is an enhanced
     connection function that supports the ability to prompt the user for
     connection information */
  rc = SQLDriverConnect(hdbc,
                        (SQLHWND)sqlHWND,
                        inConnectionString,
                        strLength1,
                        outConnectionString,
                        bufferLength,
                        strLength2,
                        driveCompletion);

  if (rc != SQL_SUCCESS) /* connection failed */
  {
 
    printf("Connection failed!\n"); /* print out an error message */

    printf("\n--WARNING ---------------\n");
    printf("If you are running this program on a UNIX platform,\n");
    printf("you must provide as arguments to the program either:\n");
    printf("  o  the database alias\n");
    printf("  o  or the database alias and the userid and password\n");
    printf("The SQLDriverConnect() GUI options are not supported on UNIX plaforms.\n");
    printf("-------------------------\n");
    
    /* connection handle checking */
    DBC_HANDLE_CHECK(hdbc, rc);
  }
  else
  {       
    printf("Connected to the database...\n\n"); 
    rc = SQLDisconnect(hdbc); /* disconnect from the database */
    if (rc != SQL_SUCCESS) /* disconnect failed */
    {
      printf("Unable to disconnect.\n");
      DBC_HANDLE_CHECK(hdbc, rc);
    }
    else        
    {   
      printf("Disconnected from the database.\n");
     
      /* free the connection handle */
      rc = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
      if (rc != SQL_SUCCESS)
      {
        /* connection handle checking */
        DBC_HANDLE_CHECK(hdbc, rc);
      }
      else
      {
        /* free the environment handle */
        rc = SQLFreeHandle(SQL_HANDLE_ENV, henv);
        if (rc != SQL_SUCCESS)
        {
          /* environment handle checking */ 
          ENV_HANDLE_CHECK(henv, rc);
        }
      }
    }
  }
  return (rc);
}
