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
** SOURCE FILE NAME: tbtemp.c                                        
**                                                                        
** SAMPLE: How to use a declared temporary table
**          
**         This sample:
**         1. Creates a user temporary table space required for declared 
**            temporary tables
**         2. Creates and populates a declared temporary table 
**         3. Shows that the declared temporary table exists after a commit 
**            and shows the declared temporary table's use in a procedure
**         4. Shows that the temporary table can be recreated with the same 
**            name using the "with replace" option and without "not logged"
**            clause, to enable logging.
**         5. Shows the creation of an index on the temporary table.
**         6. Show the usage of "describe" command to obtain information
**            regarding the temporary table.
**         7. Shows the usage of db2RunStats API to to update statistics 
**            about the physical characteristics of a temp table and the 
**            associated indexes.
**         8. Shows that the temporary table is implicitly dropped with a  
**            disconnect from the database
**         9. Drops the user temporary table space
**  
**         The following objects are made and later removed:
**         1. a user temporary table space named usertemp1 
**         2. a declared global temporary table named temptb1
**         (If objects with these names already exist, an error message
**         will be printed out.)
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecDirect -- Execute a Statement Directly
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLSetConnectAttr -- Set Connection Attributes
**
** DB2 APIs USED:
**         db2RunStats
**
** STRUCTURES USED:
**         sqlca
** 
** OUTPUT FILE: tbtemp.out (available in the online documentation)
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
#include <db2ApiDf.h>
#include "utilcli.h" /* Header file for CLI sample code */

/* Prototypes:
    main
      |_CreateTablespace
      |_DeclareTempTable
      |   |_PopulateTempTable
      |   |_ShowTableContents
      |_ShowAfterCommit
      |   |_ShowTableContents
      |_RecreateTempTableWithLogging
      |   |_PopulateTempTable
      |   |_ShowTableContents
      |_CreateIndex
      |_UpdateStatistics
      |_DescribeTemporaryTable
      |   |_NumToAscii
      |_DropTablespace
*/

int CreateTablespace(SQLHANDLE);
int DeclareTempTable(SQLHANDLE);
int ShowAfterCommit(SQLHANDLE);
int RecreateTempTableWithLogging(SQLHANDLE);
int CreateIndex(SQLHANDLE);
int UpdateStatistics(SQLHANDLE, SQLHANDLE, char *, char *, char*);
int DescribeTemporaryTable(SQLHANDLE);
int PopulateTempTable(SQLHANDLE);
int ShowTableContents(SQLHANDLE);
int DropTablespace(SQLHANDLE);
char *NumToAscii(int);

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

  printf("\nTHIS SAMPLE SHOWS HOW TO USE DECLARED TEMPORARY TABLES.\n");

  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_OFF);
  if (rc != 0)
  {
    return rc;
  }

  /* make sure a user temporary table space exists before creating the
     table */
  rc = CreateTablespace(hdbc);

  /* show how to make a declared temporary table */
  rc = DeclareTempTable(hdbc);

  /* show that the temporary table exists in ShowAfterCommit() even though
     it was declared in DeclareTempTable(). The temporary table is
     accessible to the whole session as the connection still exists at this
     point. Show that the temporary table exists after a commit. */ 
  rc = ShowAfterCommit(hdbc);

  /* declare the temporary table again. The old one will be dropped and a
     new one will be made. */
  rc = RecreateTempTableWithLogging(hdbc);

  /* create an index for the global temporary table */
  rc = CreateIndex(hdbc);

  /* update temporary table statistics using db2RunStats */
  rc = UpdateStatistics(hdbc, henv, dbAlias, user, pswd);

  /* use the Describe Command to describe the temp table */
  rc = DescribeTemporaryTable(hdbc);

  /* disconnect from the database. This implicitly drops the temporary
     table. Alternatively, an explicit drop statement could have
     been used.*/
  printf("\n-----------------------------------------------------------");
  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  printf("\nTHE DECLARED TEMPORARY TABLE IS IMPLICITLY DROPPED.\n");

  /* connect to database*/
  printf("\n-----------------------------------------------------------");
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

  /* clean up - remove the table space that was created earlier.
     Note: The table space can only be dropped after the temporary table is
     dropped. */
  DropTablespace(hdbc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
} /* main */

/* create a user temporary table space for the temporary table.  A user 
   temporary table space is required for temporary tables. This type of  
   table space is not created at database creation time. */
int CreateTablespace(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = 
    (SQLCHAR *)"CREATE USER TEMPORARY TABLESPACE usertemp1 ";

  printf("\n-----------------------------------------------------------");
  printf("\nCreating user temporary tablespace USERTEMP1\n");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO MAKE A USER TEMPORARY TABLESPACE FOR THE TEMPORARY TABLE\n");
  printf("IN A DIRECTORY CALLED usertemp, RELATIVE TO THE DATABASE\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE USER TEMPORARY TABLESPACE usertemp1\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
}

/* declare a temporary table with the same columns as the one for the 
   database's department table. Populate the temporary table and
   show the contents. */
int DeclareTempTable(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)"DECLARE GLOBAL TEMPORARY TABLE temptb1 "
                             "LIKE department "
                             "NOT LOGGED ";

  /* declare the declared temporary table.  It is created empty. */
  printf("\n-----------------------------------------------------------");
  printf("\nCreating global temporary table TEMPTB1\n");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO MAKE A GLOBAL DECLARED TEMPORARY TABLE WITH THE SAME\n");
  printf("COLUMNS AS THE DEPARTMENT TABLE.\n");

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    DECLARE GLOBAL TEMPORARY TABLE temptb1\n");
  printf("      LIKE department NOT LOGGED\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  rc = PopulateTempTable(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  rc = ShowTableContents(hdbc);

  return rc;
} /* DeclareTempTable */

/* show that the temporary table still exists after the commit. All the
   rows will be deleted because the temporary table was declared, by default,
   with "on commit delete rows".  If "on commit preserve rows" was used,
   then the rows would have remained.  */
int ShowAfterCommit(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  printf("TO SHOW THAT THE TEMP TABLE EXISTS AFTER A COMMIT BUT WITH\n");
  printf("ALL ROWS DELETED\n");

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLEndTran\n");
  printf("TO END TRANSACTIONS OF A CONNECTION\n");

  /* end transactions on a connection */
  cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  rc = ShowTableContents(hdbc);

  return rc;
} /* ShowAfterCommit */

/* declare the temp table temptb1 again this time with logging option,
   thereby replacing the existing one. If the "with replace" option
   is not used, then an error will result if the table name is already
   associated with an existing temporary table. Populate and show the
   contents again. */
int RecreateTempTableWithLogging(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)"DECLARE GLOBAL TEMPORARY TABLE temptb1 "
                             "LIKE department WITH REPLACE "
                             "ON COMMIT PRESERVE ROWS";

  /* declare the temporary table again, this time without the
     NOT LOGGED clause. It is created empty. */
  printf("\n-----------------------------------------------------------");
  printf("\nCreating declare global temporary table TEMPTB1\n\n");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO REPLACE A GLOBAL DECLARED TEMPORARY TABLE WITH A NEW\n");
  printf("TEMPORARY TABLE OF THE SAME NAME WITH LOGGING ENABLED.\n");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    DECLARE GLOBAL TEMPORARY TABLE temptb1 LIKE department\n");
  printf("      WITH REPLACE\n");
  printf("      ON COMMIT PRESERVE ROWS\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  rc = PopulateTempTable(hdbc);
  if (rc != 0)
  {
    return rc;
  }

  rc = ShowTableContents(hdbc);

  return rc;
} /* RecreateTempTableWithLogging */

/* create Index command can be used on temporary tables to improve
   the performance of queries */
int CreateIndex(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = (SQLCHAR *)"CREATE INDEX session.tb1ind "
                             "ON session.temptb1(deptno DESC) "
                             "DISALLOW REVERSE SCANS";

  printf("\n-----------------------------------------------------------");
  printf("\n Indexes can be created for temporary tables. Indexing a table\n");
  printf(" optimizes query performance\n");

  printf("\n Following clauses in create index are not supported \n");
  printf(" for temporary tables:\n");
  printf("   SPECIFICATION ONLY\n");
  printf("   CLUSTER\n");
  printf("   EXTEND USING\n");
  printf("   Option SHRLEVEL will have no effect when creating indexes \n");
  printf("   on DGTTs and will be ignored \n");

  /* declare the temporary table. It is created empty. */
  printf("\nCreating index SESSION.TB1IND\n");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO CREATE INDEX FOR TEMPORARY TABLES\n");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    CREATE INDEX session.tb1ind ON session.temptb1(deptno DESC)\n");
  printf("    DISALLOW REVERSE SCANS\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* CreateIndex */

/* db2RunStats updates statistics about the characteristics of the temp
   table and/or any associated indexes. These characteristics include,
   among many others, number of records, number of pages, and average
   record length. */
int UpdateStatistics(SQLHANDLE hdbc, 
                     SQLHANDLE henv, 
                     char *dbAlias, char *user, char *pswd)
{
  int rc = 0;
  struct sqlca sqlca;
  char fullTableName[258];
  db2Uint32 versionNumber = db2Version970;
  db2RunstatsData runStatData;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE DB2 API:\n");
  printf("  db2Runstats -- Runstats\n");
  printf("TO UPDATE session.temptb1 STATISTICS.\n");

  strcpy(fullTableName, "session.temptb1");

  /* runstats table */
  runStatData.iSamplingOption = 0;
  runStatData.piTablename = ( unsigned char *) fullTableName;
  runStatData.piColumnList = NULL;
  runStatData.piColumnDistributionList = NULL;
  runStatData.piColumnGroupList = NULL;
  runStatData.piIndexList = NULL;
  runStatData.iRunstatsFlags = DB2RUNSTATS_ALL_INDEXES;
  runStatData.iNumColumns = 0;
  runStatData.iNumColdist = 0;
  runStatData.iNumColGroups = 0;
  runStatData.iNumIndexes = 0;
  runStatData.iParallelismOption = 0;
  runStatData.iTableDefaultFreqValues = 0;
  runStatData.iTableDefaultQuantiles = 0;
  runStatData.iUtilImpactPriority = 70;

  db2Runstats(versionNumber, &runStatData, &sqlca);
  if (sqlca.sqlcode < 0)
  {
    return 1;
  }

  return sqlca.sqlcode;
} /* UpdateStatistics */

/* use the Describe Command to describe the temporary table created.
   DESCRIBE TABLE command cannot be used with temp table. However,
   DESCRIBE statement can be used with SELECT statement to get
   table information. */
int DescribeTemporaryTable(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)"SELECT * FROM session.temptb1";

  SQLSMALLINT i; /* indices */
  SQLSMALLINT j; /* indices */
  SQLSMALLINT nResultCols; /* variable for SQLNumResultCols */
  SQLCHAR colName[32]; /* variables for SQLDescribeCol  */
  SQLSMALLINT colNameLen;
  SQLSMALLINT colType;
  SQLUINTEGER colSize;
  SQLSMALLINT colScale;
  SQLINTEGER colDataDisplaySize;

  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLNumResultCols\n");
  printf("  SQLDescribeCol\n");
  printf("  SQLFreeHandle\n");
  printf("TO DESCRIBE THE TEMPORARY TABLE CREATED\n");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s.\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* identify the number of output columns */
  cliRC = SQLNumResultCols(hstmt, &nResultCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n Column Information\n\n");
  printf(" colType          colSize  colName              colNameLen    \n");
  printf(" ---------------  -------  -------------------  -----------\n");

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

    /* get the display size for a column */
    cliRC = SQLColAttribute(hstmt,
                            (SQLSMALLINT)(i + 1),
                            SQL_DESC_DISPLAY_SIZE,
                            NULL,
                            0,
                            NULL,
                            &colDataDisplaySize);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    
    printf(" %4d %-10s  %6d   %-19s   %-14d\n", colType, NumToAscii(colType),
            colSize, colName, colNameLen); 
  }

  printf("\n");

  return rc;
}

/* convert colType returned by SQLDescribeCol() API to the 
   corresponding SQL data type */
char *NumToAscii(int colType)
{
  /* allocate memory for storing sql data type */
  char *dataTypeName = (char*)malloc(12 * sizeof(char));

  switch (colType)
  {
    case 1: 
      strcpy(dataTypeName, "CHARACTER");
      break;
    case 2: 
      strcpy(dataTypeName, "NUMERIC");
      break;
    case 3: 
      strcpy(dataTypeName, "DECIMAL");
      break;
    case 4: 
      strcpy(dataTypeName, "INTEGER");
      break;
    case 5: 
      strcpy(dataTypeName, "SMALLINT");
      break;
    case 6: 
      strcpy(dataTypeName, "FLOAT");
      break;
    case 7:
      strcpy(dataTypeName, "REAL");
      break;
    case 8:
      strcpy(dataTypeName, "DOUBLE");
      break;
    case 9:
      strcpy(dataTypeName, "DATETIME");
      break;
    case 12:
      strcpy(dataTypeName, "VARCHAR");
      break;
    default:  
      strcpy(dataTypeName, "UNKNOWN TYPE");
  }
  return dataTypeName;
} /* NumToAscii */

/* populate the temporary table with the department table's contents. */
int PopulateTempTable(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */
  SQLCHAR *stmt = 
    (SQLCHAR *)"INSERT INTO session.temptb1 "
               "(SELECT deptno, deptname, mgrno, admrdept, location "
               "FROM department) ";

  /* populating the temporary table is done the same way as a normal table
     except the qualifier "session" is required whenever the table name
     is referenced. */
  printf("TO POPULATE THE DECLARED TEMPORARY TABLE WITH DATA FROM\n");
  printf("THE DEPARTMENT TABLE\n");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    INSERT INTO session.temptb1\n");
  printf("      (SELECT deptno, deptname, mgrno, admrdept, location\n");
  printf("      FROM department)\n");

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return cliRC;
  
} /* PopulateTempTable */

/* use cursors to access each row of the declared temporary table and then
   print each row.  This function assumes that the declared temporary table
   exists. This access is the same as accessing a normal table except the 
   qualifier, "session", is required in the table name. */
int ShowTableContents(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)"SELECT * FROM session.temptb1";

  SQLSMALLINT i; /* indices */
  SQLSMALLINT j; /* indices */
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
  outData[MAX_COLUMNS]; /* structure to read the results */

  printf("\n  USE THE CLI FUNCTIONS\n");
  printf("    SQLSetConnectAttr\n");
  printf("    SQLAllocHandle\n");
  printf("    SQLExecDirect\n");
  printf("    SQLNumResultCols\n");
  printf("    SQLDescribeCol\n");
  printf("    SQLBindCol\n");
  printf("    SQLFetch\n");
  printf("    SQLFreeHandle\n");
  printf("  TO SHOW THE TABLE CONTENTS\n");

  /* set AUTOCOMMIT off */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("\n  Directly execute the statement\n");
  printf("    %s.\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("\n  Identify the output columns, then \n");
  printf("  fetch each row and display.\n");

  /* identify the number of output columns */
  cliRC = SQLNumResultCols(hstmt, &nResultCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  printf("    ");
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

    /* get the display size for a column */
    cliRC = SQLColAttribute(hstmt,
                           (SQLSMALLINT)(i + 1),
                           SQL_DESC_DISPLAY_SIZE,
                           NULL,
                           0,
                           NULL,
                           &colDataDisplaySize);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

    /* set "column display size" to the larger of "column data display size"
       and "column name length" and add one space between columns. */
    colDisplaySize[i] = max(colDataDisplaySize, colNameLen) + 1;

    /* print the column name */
    printf("%-*.*s", (int)colDisplaySize[i], 
                     (int)colDisplaySize[i], 
                     colName);

    /* set "output data buffer length" to "column data display size"
       and add one byte for null the terminator */
    outData[i].buffLen = colDataDisplaySize + 1;

    /* allocate memory to bind a column */
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
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  if (cliRC == SQL_NO_DATA_FOUND)
  {
    printf("\n  Data not found.\n");
  }
  
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("    ");
    for (i = 0; i < nResultCols; i++) /* for all columns in this row  */
    { /* check for NULL data */
      if (outData[i].len == SQL_NULL_DATA)
      {
        printf("%-*.*s",
                (int)colDisplaySize[i], (int)colDisplaySize[i], "-");
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
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
  /* free data buffers */
  for (i = 0; i < nResultCols; i++)
  {
    free(outData[i].buff);
  }

  return rc;
} /* ShowTableContents */

/* drop the user temporary table space.  This function assumes that the
   table space can be dropped.  If the declared temporary table still exists
   in the table space, then the table space cannot be dropped. */
int DropTablespace(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle */

  SQLCHAR *stmt = (SQLCHAR *)"DROP TABLESPACE USERTEMP1";

  printf("\n-----------------------------------------------------------");
  printf("\nDropping tablespace USERTEMP1\n");
  printf("\nUSE THE CLI FUNCTIONS\n");
  printf("  SQLSetConnectAttr\n");
  printf("  SQLAllocHandle\n");
  printf("  SQLExecDirect\n");
  printf("  SQLFreeHandle\n");
  printf("TO SHOW HOW TO DROP A TABLESPACE\n");

  /* set AUTOCOMMIT on */
  cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* drop the tablespace */
  printf("\n  Directly execute the statement\n");
  printf("    %s\n", stmt);

  /* directly execute the statement */
  cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  return rc;
} /* DropTablespace */
