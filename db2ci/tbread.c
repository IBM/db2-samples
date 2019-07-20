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
** SOURCE FILE NAME: tbread.c
**
** SAMPLE: How to read data from tables
**
** DB2CI FUNCTIONS USED:
**         OCIHandleAlloc -- Allocate Handle
**         OCIDefineByPos -- Bind a Column to an Application Variable or
**                       LOB locator
**         OCIBindByPos -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         OCIAttrGet -- Return a Column Attribute
**         OCIStmtPrepare -- Prepare a statement
**         OCIStmtExecure -- Execute a Statement
**         OCIStmtFetch -- Fetch Next Row.
**         OCIStmtFetch2 - Fetch next rowset.
**         OCIHandleFree -- Free Handle Resources
**
** OUTPUT FILE: tbread.out (available in the online documentation)
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
#include <string.h>
#include <stdlib.h>
#include <db2ci.h>
#include "utilci.h" /* Header file for DB2CI sample code */

#define ROWSET_SIZE 5

int TbBasicSelectUsingFetch( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp );
int TbSelectWithParam( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp );
int TbSelectWithUnknownOutCols( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp );

int main(int argc, char *argv[])
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIEnv * envhp; /* environment handle */
  OCISvcCtx * svchp; /* connection handle */
  OCIError * errhp; /* error handle */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO READ TABLES.\n");

  /* initialize the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppInit(dbAlias,
                  user,
                  pswd,
                  &envhp,
                  &svchp,
                  &errhp );
  if (rc != 0)
  {
    return rc;
  }

  /* basic SELECT */
  rc = TbBasicSelectUsingFetch( envhp, svchp, errhp );

  /* SELECT with parameter markers */
  rc = TbSelectWithParam( envhp, svchp, errhp );

  /* SELECT with unknown output columns */
  rc = TbSelectWithUnknownOutCols(envhp, svchp, errhp );

  /* terminate the DB2CI application by calling a helper
     utility function defined in utilci.c */
  rc = CIAppTerm(&envhp, &svchp, errhp, dbAlias);

  return rc;
} /* main */

/* perform a basic SELECT operation using OCIDefineByPos */
int TbBasicSelectUsingFetch( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */
  OCIDefine * defnhp1 = NULL; /* define handle */
  OCIDefine * defnhp2 = NULL; /* define handle */
  /* SQL SELECT statement to be executed */
  char *stmt = (char *)"SELECT deptnumb, location FROM org";

  struct
  {
    sb2 ind;
    sb2 val;
    ub2 length;
    ub2 rcode;
  }
  deptnumb; /* variable to be bound to the DEPTNUMB column */

  struct
  {
    sb2 ind;
    char val[15];
    ub2 length;
    ub2 rcode;
  }
  location; /* variable to be bound to the LOCATION column */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCIDefineByPos\n");
  printf("  OCIStmtFetch\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A BASIC SELECT USING OCIDefineByPos:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* define column 1 to variable */
  ciRC = OCIDefineByPos(
      hstmt,
      &defnhp1,
      errhp,
      1,
      &deptnumb.val,
      sizeof( sb2 ),
      SQLT_INT,
      &deptnumb.ind,
      &deptnumb.length,
      &deptnumb.rcode,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* define column 2 to variable */
  ciRC = OCIDefineByPos(
      hstmt,
      &defnhp2,
      errhp,
      2,
      location.val,
      sizeof( location.val ),
      SQLT_STR,
      &location.ind,
      &location.length,
      &location.rcode,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Fetch each row and display.\n");
  printf("    DEPTNUMB LOCATION     \n");
  printf("    -------- -------------\n");

  /* fetch each row and display */
  ciRC = OCIStmtFetch(
      hstmt,
      errhp,
      1,
      OCI_FETCH_NEXT,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  if (ciRC == OCI_NO_DATA )
  {
    printf("\n  Data not found.\n");
  }
  while (ciRC != OCI_NO_DATA )
  {
    printf("    %-8d %-14.14s \n", deptnumb.val, location.val);

    /* fetch next row */
    ciRC = OCIStmtFetch(
        hstmt,
        errhp,
        1,
        OCI_FETCH_NEXT,
        OCI_DEFAULT );
    ERR_HANDLE_CHECK(errhp, ciRC);
  }

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbBasicSelectUsingFetch */

/* perform a SELECT that contains parameter markers */
int TbSelectWithParam( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */
  OCIDefine * defnhp1 = NULL; /* define handle */
  OCIDefine * defnhp2 = NULL; /* define handle */
  OCIBind * hBind = NULL; /* bind handle */

  char *stmt = (char *)
    "SELECT deptnumb, location FROM org WHERE division = :1";

  char divisionParam[15];

  struct
  {
    sb2 ind;
    sb2 val;
    ub2 length;
    ub2 rcode;
  }
  deptnumb; /* variable to be bound to the DEPTNUMB column */

  struct
  {
    sb2 ind;
    char val[15];
    ub2 length;
    ub2 rcode;
  }
  location; /* variable to be bound to the LOCATION column */

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCIBindByPos\n");
  printf("  OCIDefineByPos\n");
  printf("  OCIStmtFetch\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A SELECT WITH PARAMETERS:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Prepare the statement\n");
  printf("    %s\n", stmt);

  /* prepare the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Bind divisionParam to the statement\n");
  printf("    %s\n", stmt);

  /* bind divisionParam to the statement */
  ciRC = OCIBindByPos(
      hstmt,
      &hBind,
      errhp,
      1,
      divisionParam,
      sizeof( divisionParam ),
      SQLT_STR,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* execute the statement for divisionParam = Eastern */
  printf("\n  Execute the prepared statement for\n");
  printf("    divisionParam = 'Eastern'\n");
  strcpy(divisionParam, "Eastern");

  /* execute the statement */
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* bind column 1 to variable */
  ciRC = OCIDefineByPos(
      hstmt,
      &defnhp1,
      errhp,
      1,
      &deptnumb.val,
      sizeof( sb2 ),
      SQLT_INT,
      &deptnumb.ind,
      &deptnumb.length,
      &deptnumb.rcode,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  /* bind column 2 to variable */
  ciRC = OCIDefineByPos(
      hstmt,
      &defnhp2,
      errhp,
      2,
      location.val,
      sizeof( location.val ),
      SQLT_STR,
      &location.ind,
      &location.length,
      &location.rcode,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Fetch each row and display.\n");
  printf("    DEPTNUMB LOCATION     \n");
  printf("    -------- -------------\n");

  /* fetch each row and display */
  ciRC = OCIStmtFetch(
      hstmt,
      errhp,
      1,
      OCI_FETCH_NEXT,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  if (ciRC == OCI_NO_DATA )
  {
    printf("\n  Data not found.\n");
  }
  while (ciRC != OCI_NO_DATA )
  {
    printf("    %-8d %-14.14s \n", deptnumb.val, location.val);

    /* fetch next row */
    ciRC = OCIStmtFetch(
        hstmt,
        errhp,
        1,
        OCI_FETCH_NEXT,
        OCI_DEFAULT );
    ERR_HANDLE_CHECK(errhp, ciRC);
  }

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbSelectWithParam */

/* perform a SELECT where the number of columns in the
   result set is not known */
int TbSelectWithUnknownOutCols( OCIEnv * envhp, OCISvcCtx * svchp, OCIError * errhp )
{
  sb4 ciRC = OCI_SUCCESS;
  int rc = 0;
  OCIStmt * hstmt; /* statement handle */
  /* SQL SELECT statement to be executed */
  char *stmt = (char *)"SELECT * FROM org";
  ub4 i, j; /* indices */
  ub4 nResultCols;
  void * hCol;
  char * colName;
  ub4 colNameLen;
  ub2 colSize;
  ub2 colDisplaySize[MAX_COLUMNS];

  struct
  {
    OCIDefine * defnhp;
    char *buff;
    sb2 ind;
    ub2 length;
    ub2 rcode;
  }
  outData[MAX_COLUMNS]; /* variable to read the results */

  memset( outData, 0, sizeof( outData ));

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2CI FUNCTIONS\n");
  printf("  OCIHandleAlloc\n");
  printf("  OCIStmtPrepare\n");
  printf("  OCIStmtExecute\n");
  printf("  OCIAttrGet\n");
  printf("  OCIParamGet\n");
  printf("  OCIDefineByPos\n");
  printf("  OCIStmtFetch\n");
  printf("  OCIHandleFree\n");
  printf("TO PERFORM A SELECT WITH UNKNOWN OUTPUT COLUMNS\n");
  printf("AT COMPILE TIME:\n");

  /* allocate a statement handle */
  ciRC = OCIHandleAlloc( (dvoid *)envhp, (dvoid **)&hstmt, OCI_HTYPE_STMT, 0, NULL );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s.\n", stmt);

  /* directly execute the statement */
  ciRC = OCIStmtPrepare(
      hstmt,
      errhp,
      (OraText *)stmt,
      strlen( stmt ),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);
  ciRC = OCIStmtExecute(
      svchp,
      hstmt,
      errhp,
      0,
      0,
      NULL,
      NULL,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("\n  Identify the output columns, then \n");
  printf("  fetch each row and display.\n");

  /* identify the number of output columns */
  ciRC = OCIAttrGet( hstmt, OCI_HTYPE_STMT, (dvoid *)&nResultCols, NULL, OCI_ATTR_PARAM_COUNT, errhp );
  ERR_HANDLE_CHECK(errhp, ciRC);

  printf("    ");
  for (i = 0; i < nResultCols; i++)
  {
    /* return a set of attributes for a column */
    ciRC = OCIParamGet( hstmt, OCI_HTYPE_STMT, errhp, &hCol, i + 1 );
    ERR_HANDLE_CHECK(errhp, ciRC);

    ciRC = OCIAttrGet( hCol, OCI_DTYPE_PARAM, &colName, &colNameLen, OCI_ATTR_NAME, errhp );
    ERR_HANDLE_CHECK(errhp, ciRC);

    ciRC = OCIAttrGet( hCol, OCI_DTYPE_PARAM, &colSize, NULL, OCI_ATTR_DATA_SIZE, errhp );
    ERR_HANDLE_CHECK(errhp, ciRC);
    colSize = max( colSize, 32 );

    /* set "column display size" to the larger of "column data display size"
       and "column name length" and add one space between columns. */
    colDisplaySize[i] = max(colSize, colNameLen) + 1;

    /* print the column name */
    printf("%-*.*s",
           (int)colDisplaySize[i], (int)colDisplaySize[i], colName);

    /* set "output data buffer length" to "column data display size"
       and add one byte for null the terminator */
    outData[i].length = colDisplaySize[i];

    /* allocate memory to bind a column */
    outData[i].buff = (char *)malloc((int)outData[i].length);

    /* bind columns to program variables, converting all types to CHAR */
    ciRC = OCIDefineByPos(
        hstmt,
        &outData[i].defnhp,
        errhp,
        i + 1,
        outData[i].buff,
        outData[i].length,
        SQLT_STR,
        &outData[i].ind,
        &outData[i].length,
        &outData[i].rcode,
        OCI_DEFAULT );
    ERR_HANDLE_CHECK(errhp, ciRC);
  }

  printf("\n    ");
  for (i = 0; i < nResultCols; i++)
  {
    for (j = 1; j < (int)colDisplaySize[i]; j++)
    {
      printf("-");
    }
    printf(" ");
  }
  printf("\n");

  /* fetch each row and display */
  ciRC = OCIStmtFetch(
      hstmt,
      errhp,
      1,
      OCI_FETCH_NEXT,
      OCI_DEFAULT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  if (ciRC == OCI_NO_DATA )
  {
    printf("\n  Data not found.\n");
  }
  while (ciRC != OCI_NO_DATA )
  {
    printf("    ");
    for (i = 0; i < nResultCols; i++) /* for all columns in this row  */
    { /* check for NULL data */
      if (outData[i].ind == -1 )
      {
        printf("%-*.*s",
               (int)colDisplaySize[i], (int)colDisplaySize[i], "NULL");
      }
      else
      { /* print outData for this column */
        printf("%-*.*s",
               (int)colDisplaySize[i],
               (int)colDisplaySize[i],
               outData[i].buff);
      }
    }
    printf("\n");

    /* fetch next row */
    ciRC = OCIStmtFetch(
        hstmt,
        errhp,
        1,
        OCI_FETCH_NEXT,
        OCI_DEFAULT );
    ERR_HANDLE_CHECK(errhp, ciRC);
  }

  /* free data buffers */
  for (i = 0; i < nResultCols; i++)
  {
    free(outData[i].buff);
  }

  /* free the statement handle */
  ciRC = OCIHandleFree( hstmt, OCI_HTYPE_STMT );
  ERR_HANDLE_CHECK(errhp, ciRC);

  return rc;
} /* TbSelectWithUnknownOutCols */
