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
** SOURCE FILE NAME: utilcli.c   
**
** SAMPLE: Utility functions used by DB2 CLI samples
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLColAttribute -- Return a Column Attribute
**         SQLConnect -- Connect to a Data Source
**         SQLDescribeCol -- Return a Set of Attributes for a Column
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLEndTran -- End Transactions of a Connection
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLFreeStmt -- Free (or Reset) a Statement Handle
**         SQLGetDiagRec -- Get Multiple Field Settings of Diagnostic Record
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLSetConnectAttr -- Set Connection Attributes
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
#include <stdlib.h>
#include <string.h>
#include <sqlcli1.h>
#include <sqlutil.h>
#include <sqlenv.h>
#include "utilcli.h"

/* local functions for utilcli.c */
void HandleLocationPrint(SQLRETURN, int, char *);
void HandleDiagnosticsPrint(SQLSMALLINT, SQLHANDLE);

/* funtion used in DB2_API_CHECK */
void SqlInfoPrint(char *, struct sqlca*, int, char*);

/* outputs to screen unexpected occurrences with CLI functions */
int HandleInfoPrint(SQLSMALLINT htype, /* handle type identifier */
                    SQLHANDLE hndl, /* handle used by the CLI function */
                    SQLRETURN cliRC, /* return code of the CLI function */
                    int line,
                    char *file)
{
  int rc = 0;

  switch (cliRC)
  {
    case SQL_SUCCESS:
      rc = 0;
      break;
    case SQL_INVALID_HANDLE:
      printf("\n-CLI INVALID HANDLE-----\n");
      HandleLocationPrint(cliRC, line, file);
      rc = 1;
      break;
    case SQL_ERROR:
      printf("\n--CLI ERROR--------------\n");
      HandleLocationPrint(cliRC, line, file);
      HandleDiagnosticsPrint(htype, hndl);
      rc = 2;
      break;
    case SQL_SUCCESS_WITH_INFO:
      rc = 0;
      break;
    case SQL_STILL_EXECUTING:
      rc = 0;
      break;
    case SQL_NEED_DATA:
      rc = 0;
      break;
    case SQL_NO_DATA_FOUND:
      rc = 0;
      break;
    default:
      printf("\n--default----------------\n");
      HandleLocationPrint(cliRC, line, file);
      rc = 3;
      break;
  }

  return rc;
} /* HandleInfoPrint */

void HandleLocationPrint(SQLRETURN cliRC, int line, char *file)
{
  printf("  cliRC = %d\n", cliRC);
  printf("  line  = %d\n", line);
  printf("  file  = %s\n", file);
} /* HandleLocationPrint */

void HandleDiagnosticsPrint(SQLSMALLINT htype, /* handle type identifier */
                            SQLHANDLE hndl /* handle */ )
{
  SQLCHAR message[SQL_MAX_MESSAGE_LENGTH + 1];
  SQLCHAR sqlstate[SQL_SQLSTATE_SIZE + 1];
  SQLINTEGER sqlcode;
  SQLSMALLINT length, i;

  i = 1;

  /* get multiple field settings of diagnostic record */
  while (SQLGetDiagRec(htype,
                       hndl,
                       i,
                       sqlstate,
                       &sqlcode,
                       message,
                       SQL_MAX_MESSAGE_LENGTH + 1,
                       &length) == SQL_SUCCESS)
  {
    printf("\n  SQLSTATE          = %s\n", sqlstate);
    printf("  Native Error Code = %d\n", sqlcode);
    printf("%s\n", message);
    i++;
  }

  printf("-------------------------\n");
} /* HandleDiagnosticsPrint */

/* free statement handles and print unexpected occurrences */
/* this function is used in STMT_HANDLE_CHECK */
int StmtResourcesFree(SQLHANDLE hstmt)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  /* free the statement handle */
  cliRC = SQLFreeStmt(hstmt, SQL_UNBIND);
  rc = HandleInfoPrint(SQL_HANDLE_STMT, hstmt, cliRC, __LINE__, __FILE__);
  if (rc != 0)
  {
    return 1;
  }

  /* free the statement handle */
  cliRC = SQLFreeStmt(hstmt, SQL_RESET_PARAMS);
  rc = HandleInfoPrint(SQL_HANDLE_STMT, hstmt, cliRC, __LINE__, __FILE__);
  if (rc != 0)
  {
    return 1;
  }

  /* free the statement handle */
  cliRC = SQLFreeStmt(hstmt, SQL_CLOSE);
  rc = HandleInfoPrint(SQL_HANDLE_STMT, hstmt, cliRC, __LINE__, __FILE__);
  if (rc != 0)
  {
    return 1;
  }

  return 0;
} /* StmtResourcesFree */

/* rollback transactions on a single connection */
/* this function is used in HANDLE_CHECK */
void TransRollback(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  rc = HandleInfoPrint(SQL_HANDLE_DBC, hdbc, cliRC, __LINE__, __FILE__);
  if (rc == 0)
  {
    printf("  The transaction rolled back.\n");
  }
} /* TransRollback */

/* rollback transactions on mutiple connections */
/* this function is used in HANDLE_CHECK */
void MultiConnTransRollback(SQLHANDLE henv)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  printf("\n  Rolling back the transactions...\n");

  /* end transactions on the connection */
  cliRC = SQLEndTran(SQL_HANDLE_ENV, henv, SQL_ROLLBACK);
  rc = HandleInfoPrint(SQL_HANDLE_ENV, henv, cliRC, __LINE__, __FILE__);
  if (rc == 0)
  {
    printf("  The transactions are rolled back.\n");
  }
} /* MultiConnTransRollback */

/* check command line arguments */
int CmdLineArgsCheck1(int argc,
                      char *argv[],
                      char dbAlias[],
                      char user[],
                      char pswd[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(dbAlias, "sample");
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 2:
      strcpy(dbAlias, argv[1]);
      strcpy(user, "");
      strcpy(pswd, "");
      break;
    case 4:
      strcpy(dbAlias, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      break;
    default:
      printf("\nUSAGE: %s [dbAlias [userid  passwd]]\n", argv[0]);
      rc = 1;
      break;
  } /* endswitch */

  return rc;
} /* CmdLineArgsCheck1 */

/* check command line arguments */
int CmdLineArgsCheck2(int argc,
                      char *argv[],
                      char dbAlias[],
                      char user[],
                      char pswd[],
                      char remoteNodeName[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(dbAlias, "sample");
      strcpy(user, "");
      strcpy(pswd, "");
      strcpy(remoteNodeName, "");
      break;
    case 2:
      strcpy(dbAlias, argv[1]);
      strcpy(user, "");
      strcpy(pswd, "");
      strcpy(remoteNodeName, "");
      break;
    case 4:
      strcpy(dbAlias, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      strcpy(remoteNodeName, "");
      break;
    case 5:
      strcpy(dbAlias, argv[1]);
      strcpy(user, argv[2]);
      strcpy(pswd, argv[3]);
      strcpy(remoteNodeName, argv[4]);
      break;
    default:
      printf("\nUSAGE: %s [dbAlias [userid passwd [remoteNodeName]]]\n",
             argv[0]);
      rc = 1;
      break;
  } /* endswitch */

  return rc;
} /* CmdLineArgsCheck2 */

/* check command line arguments */
int CmdLineArgsCheck3(int argc,
                      char *argv[],
                      char dbAlias1[],
                      char dbAlias2[],
                      char user1[],
                      char pswd1[],
                      char user2[],
                      char pswd2[])
{
  int rc = 0;

  switch (argc)
  {
    case 1:
      strcpy(dbAlias1, "sample");
      strcpy(dbAlias2, "sample2");
      strcpy(user1, "");
      strcpy(pswd1, "");
      strcpy(user2, "");
      strcpy(pswd2, "");
      break;
    case 3:
      strcpy(dbAlias1, argv[1]);
      strcpy(dbAlias2, argv[2]);
      strcpy(user1, "");
      strcpy(pswd1, "");
      strcpy(user2, "");
      strcpy(pswd2, "");
      break;
    case 5:
      strcpy(dbAlias1, argv[1]);
      strcpy(dbAlias2, argv[2]);
      strcpy(user1, argv[3]);
      strcpy(pswd1, argv[4]);
      strcpy(user2, argv[3]);
      strcpy(pswd2, argv[4]);
      break;
    case 7:
      strcpy(dbAlias1, argv[1]);
      strcpy(dbAlias2, argv[2]);
      strcpy(user1, argv[3]);
      strcpy(pswd1, argv[4]);
      strcpy(user2, argv[5]);
      strcpy(pswd2, argv[6]);
      break;
    default:
      printf("\nUSAGE: %s "
             "[dbAlias1 dbAlias2 [user1 pswd1 [user2 pswd2]]]\n",
             argv[0]);
      rc = 1;
      break;
  }

  return rc;
} /* CmdLineArgsCheck3 */

/* initialize a CLI application by:
     o  allocating an environment handle
     o  allocating a connection handle
     o  setting AUTOCOMMIT
     o  connecting to the database */
int CLIAppInit(char dbAlias[],
               char user[],
               char pswd[],
               SQLHANDLE *pHenv,
               SQLHANDLE *pHdbc,
               SQLPOINTER autocommitValue)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  /* allocate an environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, pHenv);
  if (cliRC != SQL_SUCCESS)
  {
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  cliRC             = %d\n", cliRC);
    printf("  line              = %d\n", __LINE__);
    printf("  file              = %s\n", __FILE__);
    return 1;
  }

  /* set attribute to enable application to run as ODBC 3.0 application */
  cliRC = SQLSetEnvAttr(*pHenv,
                     SQL_ATTR_ODBC_VERSION,
                     (void *)SQL_OV_ODBC3,
                     0);
  ENV_HANDLE_CHECK(*pHenv, cliRC);

  /* allocate a database connection handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, *pHenv, pHdbc);
  ENV_HANDLE_CHECK(*pHenv, cliRC);
  
  /* set AUTOCOMMIT off or on */
  cliRC = SQLSetConnectAttr(*pHdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            autocommitValue,
                            SQL_NTS);
  DBC_HANDLE_CHECK(*pHdbc, cliRC);

  printf("\n  Connecting to %s...\n", dbAlias);

  /* connect to the database */
  cliRC = SQLConnect(*pHdbc,
                     (SQLCHAR *)dbAlias,
                     SQL_NTS,
                     (SQLCHAR *)user,
                     SQL_NTS,
                     (SQLCHAR *)pswd,
                     SQL_NTS);
  DBC_HANDLE_CHECK(*pHdbc, cliRC);
  printf("  Connected to %s.\n", dbAlias);

  return 0;
} /* CLIAppInit */

/* terminate a CLI application by:
     o  disconnecting from the database
     o  freeing the connection handle
     o  freeing the environment handle */
int CLIAppTerm(SQLHANDLE * pHenv, SQLHANDLE * pHdbc, char dbAlias[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  printf("\n  Disconnecting from %s...\n", dbAlias);

  /* disconnect from the database */
  cliRC = SQLDisconnect(*pHdbc);
  DBC_HANDLE_CHECK(*pHdbc, cliRC);

  printf("  Disconnected from %s.\n", dbAlias);

  /* free connection handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_DBC, *pHdbc);
  DBC_HANDLE_CHECK(*pHdbc, cliRC);

  /* free environment handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_ENV, *pHenv);
  ENV_HANDLE_CHECK(*pHenv, cliRC);

  return 0;
} /* CLIAppTerm */

/* output result sets */
int StmtResultPrint(SQLHANDLE hstmt, SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  SQLSMALLINT i; /* index */
  SQLSMALLINT nResultCols; /* variable for SQLNumResultCols */
  SQLCHAR colName[32]; /* variables for SQLDescribeCol  */
  SQLSMALLINT colNameLen;
  SQLSMALLINT colType;
  SQLUINTEGER colSize;
  SQLSMALLINT colScale;
  SQLINTEGER colDataDisplaySize; /* maximum size of the data */
  SQLINTEGER colDisplaySize[MAX_COLUMNS]; /* maximum size of the column */

  struct
  {
    SQLCHAR *buff;
    SQLINTEGER len;
    SQLINTEGER buffLen;
  }
  outData[MAX_COLUMNS]; /* variable to read the results */

  /* identify the output columns */
  cliRC = SQLNumResultCols(hstmt, &nResultCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n");
  for (i = 0; i < nResultCols; i++)
  {

    /* return a set of attributes for a column */
    cliRC = SQLDescribeCol(hstmt,
                           (SQLSMALLINT)(i + 1),
                           colName,
                           sizeof(colName),
                           &colNameLen,
                           &colType,
                           &colSize,
                           &colScale,
                           NULL);

    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    
    /* get display size for column */
    cliRC = SQLColAttribute(hstmt,
                            (SQLSMALLINT)(i + 1),
                            SQL_DESC_DISPLAY_SIZE,
                            NULL,
                            0,
                            NULL,
                            &colDataDisplaySize);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* set "column display size" to max of "column data display size",
       and "column name length", plus at least one space between columns */
    colDisplaySize[i] = max(colDataDisplaySize, colNameLen) + 1;

    /* print the column name */
    printf("%-*.*s",
           (int)colDisplaySize[i], (int)colDisplaySize[i], colName);

    /* set "output data buffer length" to "column data display size"
       plus one byte for the null terminator */
    outData[i].buffLen = colDataDisplaySize + 1;

    /* allocate memory to bind column */
    outData[i].buff = (SQLCHAR *)malloc((int)outData[i].buffLen);

    /* bind columns to program variables, converting all types to CHAR */
    cliRC = SQLBindCol(hstmt,
                       (SQLSMALLINT)(i + 1),
                       SQL_C_CHAR,
                       outData[i].buff,
                       outData[i].buffLen,
                       &outData[i].len);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  printf("\n");
  /* fetch each row and display */
  cliRC = SQLFetch(hstmt);
  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  
  while (cliRC == SQL_SUCCESS || cliRC == SQL_SUCCESS_WITH_INFO)
  {
    for (i = 0; i < nResultCols; i++)
    {
      /* check for NULL data */
      if (outData[i].len == SQL_NULL_DATA)
      {
        printf("%-*.*s",
               (int)colDisplaySize[i], (int)colDisplaySize[i], "NULL");
      }
      else
      {
        /* print outData for this column */
        printf("%-*.*s",
               (int)colDisplaySize[i],
               (int)colDisplaySize[i], outData[i].buff);
      }
    } /* for all columns in this row  */

    printf("\n");

    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  } /* while rows to fetch */

  /* free data buffers */
  for (i = 0; i < nResultCols; i++)
  {
    free(outData[i].buff);
  }

  return rc;
} /* StmtResultPrint */

/* prints the warning/error details including file name, line number,
   sqlcode and SQLSTATE. */
void SqlInfoPrint(char *appMsg, struct sqlca *pSqlca, int line, char *file)
{
  int rc = 0;
  char sqlInfo[1024];  /* string to store all the error information */
  char sqlInfoToken[1024]; /* string to store tokens of information */
  char sqlstateMsg[1024];  /* string to store SQLSTATE message*/
  char errorMsg[1024];  /* string to store error message */

  if (pSqlca->sqlcode != 0 && pSqlca->sqlcode != 100)
  {
    strcpy(sqlInfo, "");

    if (pSqlca->sqlcode < 0)
    {
      sprintf(sqlInfoToken,
              "\n---- error report -----------------------------\n");
      strcat(sqlInfo, sqlInfoToken);
    }
    else
    {
      sprintf(sqlInfoToken,
              "\n---- warning report ---------------------------\n");
      strcat(sqlInfo, sqlInfoToken);
    } /* endif */

    sprintf(sqlInfoToken, "\napplication message = %s\n", appMsg);
    strcat(sqlInfo, sqlInfoToken);
    sprintf(sqlInfoToken, "line                = %d\n", line);
    strcat(sqlInfo, sqlInfoToken);
    sprintf(sqlInfoToken, "file                = %s\n", file);
    strcat(sqlInfo, sqlInfoToken);
    sprintf(sqlInfoToken, "SQLCODE             = %d\n\n", pSqlca->sqlcode);
    strcat(sqlInfo, sqlInfoToken);

    /* get error message */
    rc = sqlaintp(errorMsg, 1024, 80, pSqlca);
    if (rc > 0) /* return code is the length of the errorMsg string */
    {
      sprintf(sqlInfoToken, "%s\n", errorMsg);
      strcat(sqlInfo, sqlInfoToken);
    }

    /* get SQLSTATE message */
    rc = sqlogstt(sqlstateMsg, 1024, 80, pSqlca->sqlstate);
    if (rc > 0)
    {
      sprintf(sqlInfoToken, "%s\n", sqlstateMsg);
      strcat(sqlInfo, sqlInfoToken);
    }

    if (pSqlca->sqlcode < 0)
    {
      sprintf(sqlInfoToken,
              "---- end error report ------------------------\n");
      strcat(sqlInfo, sqlInfoToken);
      printf("%s", sqlInfo);
    }
    else
    {
      sprintf(sqlInfoToken,
              "---- end warning report ----------------------\n");
      strcat(sqlInfo, sqlInfoToken);
      printf("%s", sqlInfo);
    } /* endif */
  } /* endif */
} /* SqlInfoPrint */
