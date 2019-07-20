/****************************************************************************
** (c) Copyright IBM Corp. 2009 All rights reserved.
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
** SOURCE FILE NAME: utilci.c
**
** SAMPLE: Utility functions used by DB2 CI samples
**
** CI FUNCTIONS USED:
**         OCIHandleAlloc -- Allocate Handle
**         OCIDefineByPos -- Bind a Column to an Application Variable or
**                       LOB locator
**         OCIAttrGet -- Return a Column Attribute
**         OCILogon -- Connect to a Data Source
**         OCILogoff -- Disconnect from a Data Source
**         OCITransCommit/OCITransRollback -- End Transactions of a Connection
**         OCIStmtFetch -- Fetch Next Row
**         OCIHandleFree -- Free Handle Resources
**         OCIErrorGet -- Get Multiple Field Settings of Diagnostic Record
**         OCIAttrSet -- Set Connection Attributes
*****************************************************************************
**
** For more information on the sample programs, see the README file.
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
#include <db2ci.h>
#include "utilci.h"

/* local functions for utilci.c */
void HandleLocationPrint(sb4, int, char *);
void HandleDiagnosticsPrint(ub4, dvoid *);

/* outputs to screen unexpected occurrences with CI functions */
int HandleInfoPrint(ub4 htype, /* handle type identifier */
                    void * hndl, /* handle used by the CI function */
                    sb4 ciRC, /* return code of the CI function */
                    int line,
                    char *file)
{
  int rc = 0;

  switch (ciRC)
  {
    case OCI_SUCCESS:
      rc = 0;
      break;
    case OCI_INVALID_HANDLE:
      printf("\n-CI INVALID HANDLE-----\n");
      HandleLocationPrint(ciRC, line, file);
      rc = 1;
      break;
    case OCI_ERROR:
      printf("\n--CI ERROR--------------\n");
      HandleLocationPrint(ciRC, line, file);
      HandleDiagnosticsPrint(htype, hndl);
      rc = 2;
      break;
    case OCI_SUCCESS_WITH_INFO:
      rc = 0;
      break;
    case OCI_NEED_DATA:
      rc = 0;
      break;
    case OCI_NO_DATA:
      rc = 0;
      break;
    default:
      printf("\n--default----------------\n");
      HandleLocationPrint(ciRC, line, file);
      rc = 3;
      break;
  }

  return rc;
} /* HandleInfoPrint */

void HandleLocationPrint( sb4 ciRC, int line, char *file)
{
  printf("  ciRC = %ld\n", (long)ciRC);
  printf("  line  = %d\n", line);
  printf("  file  = %s\n", file);
} /* HandleLocationPrint */

void HandleDiagnosticsPrint(ub4 htype, /* handle type identifier */
                            dvoid * hndl /* handle */ )
{
  char message[1024 + 1];
  char sqlstate[5 + 1];
  sb4 sqlcode;
  ub4 i = 1;

  /* get multiple field settings of diagnostic record */
  while (OCIErrorGet( hndl,
                      i,
                      (text *)sqlstate,
                      &sqlcode,
                      (text *)message,
                      sizeof( message ),
                      htype ) == OCI_SUCCESS)
  {
    printf("\n  SQLSTATE          = %s\n", sqlstate);
    printf("  Native Error Code = %d\n", sqlcode);
    printf("%s\n", message);
    i++;
  }

  printf("-------------------------\n");
} /* HandleDiagnosticsPrint */

/* rollback transactions on a single connection */
/* this function is used in HANDLE_CHECK */
void TransRollback( OCISvcCtx * svch, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on the connection */
  ciRC = OCITransRollback( svch, errhp, OCI_DEFAULT );
  rc = HandleInfoPrint(OCI_HTYPE_ERROR, errhp, ciRC, __LINE__, __FILE__);
  if (rc == 0)
  {
    printf("  The transaction rolled back.\n");
  }
} /* TransRollback */

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

/* initialize a CI application by:
     o  allocating an environment handle
     o  allocating a connection handle
     o  connecting to the database */
int CIAppInit(char dbAlias[],
               char user[],
               char pswd[],
               OCIEnv ** pHenv,
               OCISvcCtx ** pHdbc,
               OCIError ** errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;

  /* allocate an environment handle */
  ciRC = OCIEnvCreate( (OCIEnv **)pHenv, OCI_OBJECT, NULL, NULL, NULL, NULL, 0, NULL );
  if (ciRC != OCI_SUCCESS)
  {
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  ciRC             = %d\n", ciRC);
    printf("  line              = %d\n", __LINE__);
    printf("  file              = %s\n", __FILE__);
    return 1;
  }

  /* allocate an error handle */
  ciRC = OCIHandleAlloc( *pHenv, (dvoid *)errhp, OCI_HTYPE_ERROR, 0, NULL );
  ENV_HANDLE_CHECK(*pHenv, ciRC);

  /* allocate a database connection handle */
  ciRC = OCIHandleAlloc( *pHenv, (dvoid *)pHdbc, OCI_HTYPE_SVCCTX, 0, NULL );
  ENV_HANDLE_CHECK(*pHenv, ciRC);

  printf("\n  Connecting to %s...\n", dbAlias);

  /* connect to the database */
  ciRC = OCILogon( *pHenv,
                   *errhp,
                   pHdbc,
                     (OraText *)user,
                     strlen( (char *)user ),
                     (OraText *)pswd,
                     strlen( (char *)pswd ),
                     (OraText *)dbAlias,
                     strlen( (char *)dbAlias ));
  ERR_HANDLE_CHECK(*errhp, ciRC);
  printf("  Connected to %s.\n", dbAlias);

  return 0;
} /* CIAppInit */

/* terminate a CI application by:
     o  disconnecting from the database
     o  freeing the connection handle
     o  freeing the environment handle */
int CIAppTerm(OCIEnv ** pHenv, OCISvcCtx ** pHdbc, OCIError * errhp, char * dbAlias )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;

  printf("\n  Disconnecting from %s...\n", dbAlias);

  /* disconnect from the database */
  ciRC = OCILogoff( *pHdbc, errhp );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("  Disconnected from %s.\n", dbAlias);

  /* free connection handle */
  ciRC = OCIHandleFree( *pHdbc, OCI_HTYPE_SVCCTX );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* free error handle */
  ciRC = OCIHandleFree( errhp, OCI_HTYPE_ERROR );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* free environment handle */
  ciRC = OCIHandleFree( *pHenv, OCI_HTYPE_ENV );
  ERR_HANDLE_CHECK(errhp, ciRC);

  (void)OCITerminate( OCI_DEFAULT );

  return 0;
} /* CIAppTerm */

/* output result sets */
int StmtResultPrint(OCIStmt * hstmt, OCISvcCtx * hdbc, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;

  ub4 i; /* index */
  ub4 nResultCols;
  void * hCol;
  char * colName;
  ub4 colNameLen;
  ub4 colDisplaySize[MAX_COLUMNS]; /* maximum size of the column */
  OCIDefine * hDefine;

  struct
  {
    char *buff;
    ub2 len;
    ub2 buffLen;
    sb2 nullInd;
    ub2 rcode;
  }
  outData[MAX_COLUMNS]; /* variable to read the results */

  /* identify the output columns */
  ciRC = OCIAttrGet( hstmt, OCI_HTYPE_STMT, (dvoid *)&nResultCols, NULL, OCI_ATTR_PARAM_COUNT, errhp );
  ERR_HANDLE_CHECK( errhp, ciRC);

  printf("\n");
  for (i = 0; i < nResultCols; i++)
  {

    /* return a set of attributes for a column */
    ciRC = OCIParamGet( (dvoid *)hstmt, OCI_HTYPE_STMT, errhp, &hCol, i + 1 );
    ERR_HANDLE_CHECK( errhp, ciRC);

    ciRC = OCIAttrGet( hCol, OCI_DTYPE_PARAM, (dvoid *)&colName, &colNameLen, OCI_ATTR_NAME, errhp );
    ERR_HANDLE_CHECK( errhp, ciRC);

    /* set "column display size" to max of "column data display size",
       and "column name length", plus at least one space between columns */
    colDisplaySize[i] = max(32, colNameLen) + 1;

    /* print the column name */
    printf("%-*.*s",
           (int)colDisplaySize[i], (int)colDisplaySize[i], colName);

    /* set "output data buffer length" to "column data display size"
       plus one byte for the null terminator */
    outData[i].buffLen = 32 + 1;

    /* allocate memory to define column */
    outData[i].buff = (char *)malloc((int)outData[i].buffLen);

    /* bind columns to program variables, converting all types to CHAR */
    ciRC = OCIDefineByPos(
        hstmt,
        &hDefine,
        errhp,
        i + 1L,
        (dvoid *)outData[i].buff,
         outData[i].buffLen,
         SQLT_STR,
         &outData[i].nullInd,
         &outData[i].len,
         &outData[i].rcode,
         OCI_DEFAULT );
    ERR_HANDLE_CHECK( errhp, ciRC);
  }

  printf("\n");
  /* fetch each row and display */
  ciRC = OCIStmtFetch( hstmt, errhp, 1, OCI_FETCH_NEXT, OCI_DEFAULT );
  if (ciRC == OCI_NO_DATA)
  {
    printf("\n  Data not found.\n");
  }

  while (ciRC == OCI_SUCCESS || ciRC == OCI_SUCCESS_WITH_INFO)
  {
    for (i = 0; i < nResultCols; i++)
    {
      /* check for NULL data */
      if (outData[i].nullInd == -1 )
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
    ciRC = OCIStmtFetch( hstmt, errhp, 1, OCI_FETCH_NEXT, OCI_DEFAULT );
    ERR_HANDLE_CHECK( errhp, ciRC);
  } /* while rows to fetch */

  /* free data buffers */
  for (i = 0; i < nResultCols; i++)
  {
    free(outData[i].buff);
  }

  return rc;
} /* StmtResultPrint */
