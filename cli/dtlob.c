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
** SOURCE FILE NAME: dtlob.c
**                                                                        
** SAMPLE: How to read and write LOB data
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindFileToCol -- Bind LOB File Reference to LOB Column
**         SQLBindFileToParam -- Bind LOB File Reference to LOB Parameter
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLCloseCursor -- Close Cursor and Discard Pending Results
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetData -- Get Data From a Column
**         SQLGetLength -- Retrieve Length of a String Value
**         SQLGetPosition -- Return Starting Position of String
**         SQLGetSubString -- Retrieve Portion of a String Value
**         SQLParamData -- Get Next Parameter for which a Data Value
**                         is Needed
**         SQLPrepare -- Prepare a Statement
**         SQLPutData -- Passing Data Value for a Parameter
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetParam -- Bind a Parameter Marker to a Buffer or LOB locator
**
** OUTPUT FILE: dtlob.out (available in the online documentation)
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
#include "utilcli.h" /* header file for CLI sample code */

int BlobReadAsAWhole(SQLHANDLE);
int BlobReadInPieces(SQLHANDLE);
int BlobWriteAsAWhole(SQLHANDLE);
int BlobWriteInPieces(SQLHANDLE);
int ClobReadASelectedPiece(SQLHANDLE);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO READ AND WRITE LOBs.\n");

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

  /* read all of the BLOB data at once */
  rc = BlobReadAsAWhole(hdbc);
  /* read the BLOB data piece by piece */
  rc = BlobReadInPieces(hdbc);
  /* write all of the BLOB data at once */
  rc = BlobWriteAsAWhole(hdbc);
  /* write the BLOB data piece by piece */
  rc = BlobWriteInPieces(hdbc);
  /* read a specific part of CLOB data */
  rc = ClobReadASelectedPiece(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* read all of the BLOB data at once */
int BlobReadAsAWhole(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT picture "
                             "  FROM emp_photo "
                             "  WHERE empno  = ? AND photo_format = ?";
  char empno[10], photo_format[10];
  SQLUINTEGER fileOption = SQL_FILE_OVERWRITE;
  SQLINTEGER fileInd = 0;
  SQLSMALLINT fileNameLength = 14;
  SQLCHAR fileNameBase[] = "photo1";
  SQLCHAR fileName[14] = "";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLBindFileToCol\n");
  printf("  SQLExecute\n");
  printf("  SQLFetch\n");
  printf("  SQLCloseCursor\n");
  printf("  SQLFreeHandle\n");
  printf("TO READ ALL OF THE BLOB DATA AT ONCE:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    SELECT picture\n");
  printf("      FROM emp_photo\n");
  printf("      WHERE empno  = ? AND photo_format = ?\n");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameters to the statement\n");

  /* bind the first parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           empno,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the second parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           photo_format,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind a file to the BLOB column */
  rc = SQLBindFileToCol(hstmt,
                        1,
                        fileName,
                        &fileNameLength,
                        &fileOption,
                        14,
                        NULL,
                        &fileInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* ----------------read data in a *.bmp file ------------------------*/

  printf("\n  Execute the prepared statement for\n");
  printf("    empno = '000140'\n");
  printf("    photo_format = 'bitmap'\n");
  strcpy(empno, "000140");
  strcpy(photo_format, "bitmap");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the value for the fileName */
  sprintf((char *)fileName, "%s.bmp", fileNameBase);

  printf("\n  Fetch BLOB data in the file '%s'.\n", fileName);

  /* fetch the result */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* ----------------read data in a *.gif file ------------------------*/

  printf("\n  Execute the prepared statement for\n");
  printf("    empno = '000140'\n");
  printf("    photo_format = 'gif'\n");
  strcpy(empno, "000140");
  strcpy(photo_format, "gif");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* set the value for the fileName */
  sprintf((char *)fileName, "%s.gif", fileNameBase);

  printf("\n  Fetch BLOB data in the file '%s'.\n", fileName);

  /* fetch the result */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* BlobReadAsAWhole */

/* read the BLOB data piece by piece */
int BlobReadInPieces(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)"SELECT picture "
                             "  FROM emp_photo "
                             "  WHERE empno  = ? AND photo_format = ?";
  char empno[10], photo_format[10];
  SQLCHAR fileNameBase[] = "photo2";
  char fileName[14] = "";
  FILE *pFile;
  SQLCHAR buffer[BUFSIZ];
  SQLINTEGER bufInd;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLFetch\n");
  printf("  SQLGetData\n");
  printf("  SQLFreeHandle\n");
  printf("TO READ BLOB DATA IN PIECES:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    SELECT picture\n");
  printf("      FROM emp_photo\n");
  printf("      WHERE empno  = ? AND photo_format = ?\n");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameters to the statement\n");

  /* bind the first parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           empno,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the second parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           photo_format,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* ----------------read data in a *.bmp file ------------------------*/

  printf("\n  Execute the prepared statement for\n");
  printf("    empno = '000140'\n");
  printf("    photo_format = 'bitmap'\n");
  strcpy(empno, "000140");
  strcpy(photo_format, "bitmap");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  sprintf(fileName, "%s.bmp", fileNameBase);
  printf("\n  Fetch BLOB data in the file %s.\n", fileName);

  /* fetch the result */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  /* open the file */
  pFile = fopen(fileName, "w+b");
  if (pFile == NULL)
  {
    printf(">---- ERROR Opening File -------");

    /* free the statement handle */
    cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    return 1;
  }

  /* get BUFSIZ bytes at a time */
  /* bufInd indicates number of bytes remaining */
  cliRC = SQLGetData(hstmt,
                     1,
                     SQL_C_BINARY,
                     (SQLPOINTER)buffer,
                     BUFSIZ,
                     &bufInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  while (cliRC == SQL_SUCCESS_WITH_INFO || cliRC == SQL_SUCCESS)
  {
    if (bufInd > BUFSIZ) /* full buffer */
    {
      fwrite(buffer, sizeof(char), BUFSIZ, pFile);
    }
    else /* partial buffer on last SQLGetData */
    {
      fwrite(buffer, sizeof(char), bufInd, pFile);
    }

    /* get data from a column */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_BINARY,
                       (SQLPOINTER)buffer,
                       BUFSIZ,
                       &bufInd);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the file */
  fflush(pFile);
  fclose(pFile);

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* ----------------read data in a *.gif file ------------------------*/

  printf("\n  Execute the prepared statement for\n");
  printf("    empno = '000140'\n");
  printf("    photo_format = 'gif'\n");
  strcpy(empno, "000140");
  strcpy(photo_format, "gif");

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  sprintf(fileName, "%s.gif", fileNameBase);
  printf("\n  Fetch BLOB data in the file %s.\n", fileName);

  /* fetch the result */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  /* open the file */
  pFile = fopen(fileName, "w+b");
  if (pFile == NULL)
  {
    printf(">---- ERROR Opening File -------");

    /* free the statement handle */
    cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    return 1;
  }

  /* get BUFSIZ bytes at a time */
  /* bufInd indicates number of bytes remaining */
  cliRC = SQLGetData(hstmt,
                     1,
                     SQL_C_BINARY,
                     (SQLPOINTER)buffer,
                     BUFSIZ,
                     &bufInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  while (cliRC == SQL_SUCCESS_WITH_INFO || cliRC == SQL_SUCCESS)
  {
    if (bufInd > BUFSIZ) /* full buffer */
    {
      fwrite(buffer, sizeof(char), BUFSIZ, pFile);
    }
    else /* partial buffer on last SQLGetData */
    {
      fwrite(buffer, sizeof(char), bufInd, pFile);
    }

    /* get data from a column */
    cliRC = SQLGetData(hstmt,
                       1,
                       SQL_C_BINARY,
                       (SQLPOINTER)buffer,
                       BUFSIZ,
                       &bufInd);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }

  /* close the file */
  fflush(pFile);
  fclose(pFile);

  /* close the cursor */
  cliRC = SQLCloseCursor(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* BlobReadInPieces */

/* write all of the BLOB data at once */
int BlobWriteAsAWhole(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)
    "INSERT INTO emp_photo(empno, photo_format, picture) VALUES(?, ?, ?)";
  SQLCHAR empno[10], photo_format[10];
  SQLUINTEGER fileOption = SQL_FILE_READ;
  SQLINTEGER fileInd = 0;
  SQLSMALLINT fileNameLength = 14;
  SQLCHAR fileNameBase[] = "photo1";
  SQLCHAR fileName[14] = "";

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLBindFileToParam\n");
  printf("  SQLExecute\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO WRITE ALL OF THE BLOB DATA AT ONCE:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    INSERT INTO emp_photo(empno, photo_format, picture) ");
  printf("VALUES(?, ?, ?)\n");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameters to the statement\n");

  /* bind the first parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           empno,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the second parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           photo_format,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the file parameter */
  rc = SQLBindFileToParam(hstmt,
                          3,
                          SQL_BLOB,
                          fileName,
                          &fileNameLength,
                          &fileOption,
                          14,
                          &fileInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* ----------------write data from a *.bmp file ------------------------*/

  strcpy((char *)empno, "000240");
  strcpy((char *)photo_format, "bitmap");
  sprintf((char *)fileName, "%s.bmp", fileNameBase);
  printf("\n  Execute the prepared statement for\n");
  printf("    empno = '000240'\n");
  printf("    photo_format = 'bitmap'\n");
  printf("    fileName = %s\n", fileName);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* BlobWriteAsAWhole */

/* write the BLOB data piece by piece */
int BlobWriteInPieces(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)
    "INSERT INTO emp_photo(empno, photo_format, picture) VALUES(?, ?, ?)";
  SQLCHAR empno[10], photo_format[10];
  SQLCHAR inputParam[] = "Photo Data";
  SQLINTEGER blobInd;
  SQLCHAR fileNameBase[] = "photo1";
  SQLCHAR fileName[14] = "";
  FILE *pFile;
  SQLCHAR buffer[BUFSIZ];
  size_t n = 0;
  size_t fileSize = 0;
  SQLPOINTER valuePtr;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLPrepare\n");
  printf("  SQLBindParameter\n");
  printf("  SQLExecute\n");
  printf("  SQLCancel\n");
  printf("  SQLParamData\n");
  printf("  SQLPutData\n");
  printf("  SQLEndTran\n");
  printf("  SQLFreeHandle\n");
  printf("TO WRITE BLOB DATA IN PIECES:\n");

  /* set AUTOCOMMIT OFF */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Transactions enabled.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Prepare the statement\n");
  printf("    INSERT INTO emp_photo(empno, photo_format, picture) ");
  printf("VALUES(?, ?, ?)\n");

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Bind parameters to the statement\n");

  /* bind the first parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           empno,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind the second parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           2,
                           SQL_PARAM_INPUT,
                           SQL_C_CHAR,
                           SQL_VARCHAR,
                           10,
                           0,
                           photo_format,
                           10,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* SQL_DATA_AT_EXEC indicates that a data-at-exectuion parameter is used,
     and when the statement is executed, the actual data for the parameter
     will be sent with SQLPutData */
  blobInd = SQL_DATA_AT_EXEC;

  /* bind the third parameter to the statement */
  cliRC = SQLBindParameter(hstmt,
                           3,
                           SQL_PARAM_INPUT,
                           SQL_C_BINARY,
                           SQL_BLOB,
                           BUFSIZ,
                           0,
                           (SQLPOINTER)inputParam,
                           BUFSIZ,
                           &blobInd);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* ----------------write data from a *.bmp file ------------------------*/

  strcpy((char *)empno, "000240");
  strcpy((char *)photo_format, "bitmap");
  sprintf((char *)fileName, "%s.bmp", fileNameBase);
  printf("\n  Execute the prepared statement for\n");
  printf("    empno = '000240'\n");
  printf("    photo_format = 'bitmap'\n");
  printf("    fileName = %s\n", fileName);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NEED_DATA)
  {
    pFile = fopen((char *)fileName, "rb");
    if (pFile == NULL)
    {
      printf(">---- ERROR Opening File -------");

      /* cancel the SQL_DATA_AT_EXEC state for hstmt */
      cliRC = SQLCancel(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }
    else
    {
      /* get next parameter for which a data value is needed */
      cliRC = SQLParamData(hstmt, (SQLPOINTER *)&valuePtr);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

      while (cliRC == SQL_NEED_DATA)
      { /* if more than 1 parameter used SQL_DATA_AT_EXEC then valuePtr would
	   have to be checked to determine which parameter needed data */
        while (feof(pFile) == 0)
        {
          n = fread(buffer, sizeof(char), BUFSIZ, pFile);

          /* passing data value for a parameter */
          cliRC = SQLPutData(hstmt, buffer, n);
          STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

          fileSize = fileSize + n;
          if (fileSize > 102400u)
          { /* BLOB column defined as 100K MAX */
            printf(">---- ERROR: File > 100K  -------");
            break;
          }
        }
        printf("\n  Written a total of %u bytes from %s\n",
               fileSize, fileName);

        /* get next parameter for which a data value is needed */
        cliRC = SQLParamData(hstmt, (SQLPOINTER *)&valuePtr);
        STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
      }
    }
  }

  printf("\n  Rolling back the transaction...\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("  Transaction rolled back.\n");

  /* free the statement handle */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* BlobWriteInPieces */

/* read a specific part of CLOB data */
int ClobReadASelectedPiece(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmtClobFetch, hstmtLocUse, hstmtLocFree;
  SQLCHAR *stmtClobSelect =
    (SQLCHAR *)"SELECT resume "
               "  FROM emp_resume "
               "  WHERE empno = '000140' AND resume_format = 'ascii'";
  SQLCHAR *stmtLocFree = (SQLCHAR *)"FREE LOCATOR ?";
  SQLINTEGER clobLoc; /* LOB locator for the piece you want to retrieve */
  SQLINTEGER pcbValue;
  SQLINTEGER clobPieceLen, clobLen;
  SQLUINTEGER clobPiecePos;
  SQLINTEGER ind;
  SQLCHAR *buffer;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLBindCol\n");
  printf("  SQLFetch\n");
  printf("  SQLGetLength\n");
  printf("  SQLGetPosition\n");
  printf("  SQLGetSubString\n");
  printf("  SQLSetParam\n");
  printf("  SQLFreeHandle\n");
  printf("TO READ A SELECTED PIECE OF CLOB DATA:\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* --------------- fetch CLOB data --------------------------------------*/

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtClobFetch);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    SELECT resume\n");
  printf("      FROM emp_resume\n");
  printf("      WHERE empno = '000140' AND resume_format = 'ascii'\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtClobFetch, stmtClobSelect, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtClobFetch, hdbc, cliRC);

  /* bind CLOB column to LOB locator */
  cliRC = SQLBindCol(hstmtClobFetch,
                     1,
                     SQL_C_CLOB_LOCATOR,
                     &clobLoc,
                     0,
                     &pcbValue);
  STMT_HANDLE_CHECK(hstmtClobFetch, hdbc, cliRC);

  printf("\n  Fetch the CLOB data (resume).\n");

  /* fetch the CLOB data */
  cliRC = SQLFetch(hstmtClobFetch);
  STMT_HANDLE_CHECK(hstmtClobFetch, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }

  /* ---------------- work with the LOB locator -----------------------------*/

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtLocUse);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Extract the piece of CLOB data.\n");

  /* get the length of the whole CLOB data */
  cliRC = SQLGetLength(hstmtLocUse,
                       SQL_C_CLOB_LOCATOR,
                       clobLoc,
                       &clobLen,
                       &ind);
  STMT_HANDLE_CHECK(hstmtLocUse, hdbc, cliRC);

  /* get the starting postion of the CLOB piece of data */
  cliRC = SQLGetPosition(hstmtLocUse,
                         SQL_C_CLOB_LOCATOR,
                         clobLoc,
                         0,
                         (SQLCHAR *)"Interests",
                         strlen("Interests"),
                         1,
                         &clobPiecePos,
                         &ind);
  STMT_HANDLE_CHECK(hstmtLocUse, hdbc, cliRC);

  /* allocate a buffer to read the piece of CLOB data */
  buffer = (SQLCHAR *)malloc(clobLen - clobPiecePos + 1);

  /* read the piece of CLOB data in buffer */
  cliRC = SQLGetSubString(hstmtLocUse,
                          SQL_C_CLOB_LOCATOR,
                          clobLoc,
                          clobPiecePos,
                          clobLen - clobPiecePos,
                          SQL_C_CHAR,
                          buffer,
                          clobLen - clobPiecePos + 1,
                          &clobPieceLen,
                          &ind);
  STMT_HANDLE_CHECK(hstmtLocUse, hdbc, cliRC);

  /* print the buffer */
  printf("\n  Print the piece of CLOB data.\n");
  printf("\n%s\n", buffer);

  free(buffer);

  /* ---------------- free the LOB locator ----------------------------------*/

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtLocFree);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* bind a parameter marker to a buffer or LOB locator */
  cliRC = SQLSetParam(hstmtLocFree,
                      1,
                      SQL_C_CLOB_LOCATOR,
                      SQL_CLOB_LOCATOR,
                      0,
                      0,
                      &clobLoc,
                      NULL);
  STMT_HANDLE_CHECK(hstmtLocFree, hdbc, cliRC);

  printf("\n  Free the LOB locator.\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmtLocFree, stmtLocFree, SQL_NTS);
  STMT_HANDLE_CHECK(hstmtLocFree, hdbc, cliRC);

  /* ------------------ free the statement handles ---------------------------*/

  /* free handle resources */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtClobFetch);
  STMT_HANDLE_CHECK(hstmtClobFetch, hdbc, cliRC);

  /* free handle resources */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtLocUse);
  STMT_HANDLE_CHECK(hstmtLocUse, hdbc, cliRC);

  /* free handle resources */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmtLocFree);
  STMT_HANDLE_CHECK(hstmtLocFree, hdbc, cliRC);

  return rc;
} /* ClobReadASelectedPiece */

