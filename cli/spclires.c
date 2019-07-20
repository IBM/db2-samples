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
** SOURCE FILE NAME: spclires.c
**
** SAMPLE: Contrast stored procedure multiple result set handling methods
**
**         This sample contrast how SQLMoreResults and SQLNextResult handle
**         multiple result sets returned from a stored procedure.
**
**         To run this sample, you must:
**         (1) complete the steps documented in spserver.c (this creates
**             and registers the TWO_RESULT_SETS stored procedure needed
**             by spclires.c)
**         (2) compile spclires.c (nmake spclires (Windows) or make spclires
**             (UNIX), or bldapp spclires for the Microsoft Visual C++
**             compiler on Windows)
**         (3) run spclires (spclires)
**
**         SQLMoreResults and SQLNextResult are used to retrieve multiple
**         result sets from stored procedures.  The main difference between
**         these two functions is that SQLMoreResults requires closing the
**         cursor for one result set before accessing another result set
**         thereby leaving the initial result set inaccessible,
**         while SQLNextResult allows cursors on both result sets to be
**         open at the same time, meaning both result sets remain available.
**         This difference between the two functions is because 
**         SQLMoreResults accepts only one statement handle as an argument
**         while SQLNextResult allows two statement handles.
**
**         This sample calls the "TWO_RESULT_SETS" stored procedure defined
**         in spserver.c.  It shows how calling SQLMoreResults yields fewer
**         rowsets than SQLNextResult because SQLMoreResults must discard
**         remaining rowsets from the first result set in order to fetch
**         from the second result set.  SQLNextResult is able to place the
**         cursor needed for the second result set on the second statement
**         handle, leaving both result sets accessible.
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLMoreResults -- Determine if There Are More Result Sets
**         SQLNextResult -- Associate Next Result Set with Another
**                          Statement Handle
**         SQLNumResultCols -- Get Number of Result Columns
**         SQLPrepare -- Prepare a Statement
**
** OUTPUT FILE: spclires.out (available in the online documentation)
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
#include "utilcli.h"

int main(int argc, char * argv[])
{
  SQLRETURN sqlrc = SQL_SUCCESS; /* sql return code */
  short rc = 0; 
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
    	
  printf("\nCONTRAST STORED PROCEDURE MULTIPLE RESULT SET HANDLING METHODS.");
  printf("\n\n");
  
  /* allocate an environment handle */
  sqlrc = SQLAllocHandle( SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv );
  rc = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  if (rc != SQL_SUCCESS)
  {
    printf("Cannot allocate database connection handle!\n");
    return(1); 		
  }
  /* connect to the Sample database */
  rc = SQLConnect(hdbc,                                                                                                       
                  (SQLCHAR *) "SAMPLE", /* connect to this database */
                  SQL_NTS,
                  NULL, /* use default user ID */
                  SQL_NTS, /* use default password */
                  NULL,
                  SQL_NTS);	

  /* check to see if connect successful */
  /* if not, print out an error message */
  if (rc != SQL_SUCCESS)
  {
    printf("\nArgc : %d", argc);
    printf("Connection failed!\n");

    DBC_HANDLE_CHECK(hdbc, rc);
    /* connection handle checking */
  }

  /* if connect sucessful, call MoreResults() */  
  else
  {	  
    printf("Connected to sample.\n");
    printf("-----------------------------------------------------------\n");

    /*  process result sets using SQLMoreResults */
    rc = MoreResults(hdbc);

    /* if call to MoreResults() failed, display error message */
    if (rc != SQL_SUCCESS)
    {
      printf("MoreResults call failed.\n");
      /* connection handle checking */
      DBC_HANDLE_CHECK(hdbc, rc);
    }

    /* process result sets using SQLNextResult on the same connection */
    rc = NextResults(hdbc);

    /* if call to NextResults() failed, display error message */
    if (rc != SQL_SUCCESS)
    {
      printf("NextResults call failed.\n");

      /* connection handle checking */
      DBC_HANDLE_CHECK(hdbc, rc);
    }

    /* disconnect from database */
    rc = SQLDisconnect(hdbc);
    printf("\nDisconnecting from sample...\n");

    /* if disconnect failed, display error message */
    if (rc != SQL_SUCCESS)
    {
      printf("Disconnect from database failed!\n");

      /* connection handle checking */
      DBC_HANDLE_CHECK(hdbc, rc);
    }

    /* if disconnect successful */
    else 	
    {
      printf("Disconnected from sample.\n");
      /* free the handle connecttion */
      rc = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
      if (rc != SQL_SUCCESS)
      {
        printf("Freeing the connection handle failed!\n");
        /* connection handle checking */
        DBC_HANDLE_CHECK(hdbc, rc);
      }
      else
      {
        /* free the environment handle */
        rc = SQLFreeHandle(SQL_HANDLE_ENV, henv);
        if (rc != SQL_SUCCESS)
        {
          printf("Freeing the environment handle failed!");
          /* environment handle checking */ 
          ENV_HANDLE_CHECK(henv, rc);
        }
      }
    }
  }
  return (rc);
}

/* process the result sets from the TWO_RESULT_SETS 
   stored procedure with SQLMoreResults */
int MoreResults(SQLHANDLE hdbc)
{
  int i; /* index to keep track of the number of rows for fetching */
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle for Result Set 1 */
  SQLHANDLE hstmt2; /* statement handle for Result Set 2 */
  
  /* name of stored procedure to be called */
  char procName[] = "TWO_RESULT_SETS";
  /* SQL statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"CALL TWO_RESULT_SETS (?)";
  SQLDOUBLE inSalary, outSalary;
  SQLSMALLINT numCols; /* number of columns returned */
  SQLCHAR outName[40];
  SQLCHAR outJob[10];
  
  /* set a value for the inSalary variable which will be passed to the 
     TWO_RESULT_SETS stored procedure */
  /* TWO_RESULT_SETS returns one result set containing salaries greater than
     inSalary and a second result set with salaries less than inSalary */
  inSalary = 16502.83;
  printf("USE SQLMORERESULTS TO PROCESS RESULT SETS:\n\n");
  printf("   Call the TWO_RESULT_SETS stored procedure.\n\n");
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);    

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind variable to the first parameter marker */
  cliRC = SQLBindParameter(hstmt,
                           1, 
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE, 
                           SQL_DOUBLE,
                           0,
                           0,
                           &inSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    
  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* determine the number of columns returned after execution */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind columns to variables after execution*/
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, outName, 40, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, outJob, 10, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  cliRC = SQLBindCol(hstmt, 3, SQL_C_DOUBLE, &outSalary, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch the first row from Result Set 1 */
  cliRC = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("   Fetch the first 2 rows of RESULT SET 1 ");
  printf("(salary > 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");   

  /* use an index to fetch the first two first rows of Result Set 1 */
  for (i = 1; i <= 2; i++)
  {
    if (cliRC != SQL_NO_DATA_FOUND)
    {
      printf("%15s,%10s,    %.2lf\n", outName, outJob, outSalary);
      cliRC = SQLFetch(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }
  } /* end of loop */

  cliRC = SQLMoreResults(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("\n   SQLMoreResults shows that there are more ");
  printf("result sets to process.\n");
  printf("\n   Now process Result Set 2 (remaining results of\n");
  printf("     Result Set 1 discarded to fetch from Result Set 2):\n\n");
    
  /* fetch the first four rows of ResultSet2 */
    
  cliRC = SQLFetch(hstmt);
  printf("   Fetch the first 4 rows of RESULT SET 2 (salary < 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");
  /* use index "i" to run the loop 4 times */
  for (i = 1; i <= 4; i++)
  {
    /* if there is data to retrieve, fetch it */
    if (cliRC != SQL_NO_DATA_FOUND)
    {
      printf("%15s,%10s,    %.2lf\n", outName, outJob, outSalary);    
      cliRC = SQLFetch(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }
  } /* end loop */
 
  /* fetch the remaining rowsets of Result Set 2 */
  /* starting from the 5th row */
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  printf("\n   Continue fetching from RESULT SET 2 (salary < 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");

  /* continue fetching from Result Set 2 until there is no
     more data found */
  while(cliRC != SQL_NO_DATA_FOUND)
  {
    printf("%15s,%10s,    %.2lf\n", outName, outJob, outSalary);
   
    /* fetch the next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  } /* end loop */

  /* an attempt to return to Result Set 1 by calling SQLMoreResults()
     fails because SQLMoreResults can only process sequentially with
     one cursor open at a time */
  cliRC = SQLMoreResults(hstmt);
  if (cliRC != SQL_SUCCESS)
  {
    printf("\n   ATTEMPT TO RESUME PROCESSING RESULT SET 1 FAILS:\n");
    printf("     SQLMoreResults processes sequentially,\n");
    printf("     with only one cursor open at one time.\n");
    printf("-----------------------------------------------------------\n");
  }

  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);    
  return rc;
} /* end callTwoResultSets */

/* process the result sets from the TWO_RESULT_SETS 
   stored procedure with SQLNextResult */
int NextResults(SQLHANDLE hdbc)
{
  /* use indexes to keep track of the number of rows being fetched:
     TableIndex1 for Result Set 1 and TableIndex2 for Result Set 2 */
  int TableIndex1, TableIndex2;
  SQLRETURN cliRC = SQL_SUCCESS;
  SQLRETURN cliRC1 = SQL_SUCCESS;
  SQLRETURN cliRC2 = SQL_SUCCESS;	
  int rc = 0;
  SQLHANDLE hstmt; /* statement handle for Result Set 1 */
  SQLHANDLE hstmt2; /*statement handle for Result Set 2 */ 

  /* name of the stored procedure to be called */
  char procName[] = "TWO_RESULT_SETS";
  /* SQL statement to be executed */
  SQLCHAR *stmt = (SQLCHAR *)"CALL TWO_RESULT_SETS (?)";
  SQLDOUBLE inSalary, outSalary1, outSalary2; 
  SQLSMALLINT numCols; /* number of columns returned */ 
  SQLCHAR outName1[40], outName2[40];
  SQLCHAR outJob1[10], outJob2[10];

  /* set a value for the inSalary variable which will be passed to the 
     TWO_RESULT_SETS stored procedure */
  /* TWO_RESULT_SETS returns one result set containing salaries greater than
     inSalary and a second result set with salaries less than inSalary */
  inSalary = 16502.83;
  printf("USE SQLNEXTRESULT TO PROCESS RESULT SETS:\n\n");
  printf("   Call the TWO_RESULT_SETS stored procedure.\n\n");
 
  /* allocate statement handle for the first result set */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* allocate statement handle for the second result set */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt2);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind variable to the first parameter marker */
  cliRC = SQLBindParameter(hstmt,
                           1,
                           SQL_PARAM_INPUT,
                           SQL_C_DOUBLE,
                           SQL_DOUBLE,
                           0,
                           0,
                           &inSalary,
                           0,
                           NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* use SQLNextResult to push Result Set 2 onto the second statement handle */
  cliRC = SQLNextResult(hstmt, hstmt2); /* open second cursor */
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* determine the number of columns returned after execution */
  cliRC = SQLNumResultCols(hstmt, &numCols);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind columns to variables after execution of Result Set 1 */
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, outName1, 40, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  cliRC = SQLBindCol(hstmt, 2, SQL_C_CHAR, outJob1, 10, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  cliRC = SQLBindCol(hstmt, 3, SQL_C_DOUBLE, &outSalary1, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind columns to variables after execution of Result Set 2 */
  cliRC = SQLBindCol(hstmt2, 1, SQL_C_CHAR, outName2, 40, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  cliRC = SQLBindCol(hstmt2, 2, SQL_C_CHAR, outJob2, 10, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  cliRC = SQLBindCol(hstmt2, 3, SQL_C_DOUBLE, &outSalary2, 0, NULL);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  /* fetch the first row from Result Set 1 */
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  /* fetch the first row from Result Set 2 */
  cliRC2 = SQLFetch(hstmt2); 
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);

  printf("   Fetch the first 2 rows of RESULT SET 1 ");
  printf("(salary > 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");

  /* this loop will run twice and return 2 rows */ 
  for (TableIndex1 = 1; TableIndex1 <= 2; TableIndex1++)
  {
    if (cliRC != SQL_NO_DATA_FOUND)
    {
      printf("%15s,%10s,    %.2lf\n", outName1, outJob1, outSalary1);
      cliRC = SQLFetch(hstmt);
      STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
    }
  } /* end loop */

  /* fetch the first four rows of Result Set 2*/
  printf("\n   SQLNextResult stops fetching from Result Set 1\n");
  printf("     (leaving the cursor open) and opens the cursor");
  printf(" for Result Set 2:\n\n");
  printf("   Fetch the first 4 rows of RESULT SET 2 (salary < 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");

  /* this loop will run 4 times and return 4 rows */
  for (TableIndex1 = 1; TableIndex1 <= 4; TableIndex1++)
  {
    if (cliRC2 != SQL_NO_DATA_FOUND)
    {
      printf("%15s,%10s,    %.2lf\n", outName2, outJob2, outSalary2);
      cliRC2 = SQLFetch(hstmt2);
      STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
    }
  } /* end loop */

  printf("\n   ATTEMPT TO RESUME PROCESSING RESULT SET 1 SUCCEEDS:\n");
  printf("     SQLNextResult allows two cursors to be open concurrently.\n");

  printf("\n   Continue fetching from RESULT SET 1 (salary > 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");

  /* this loop will run until no data is available in Result Set1 */
  while (cliRC != SQL_NO_DATA_FOUND)
  {
    printf("%15s,%10s,    %.2lf\n", outName1, outJob1, outSalary1);
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  } /* end loop */
    
  printf("\n   Continue fetching from RESULT SET 2 (salary < 16502.83):\n");
  printf("\n          Name,      JOB,      Salary    \n");
  printf("          -----      ----      ------    \n");

  /* continue fetching from Result Set 2 until there is no
     more data found */
  while (cliRC2 != SQL_NO_DATA_FOUND)
  {
    printf("%15s,%10s,    %.2lf\n", outName2, outJob2, outSalary2);
    cliRC2 = SQLFetch(hstmt2);
    STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  } /* end loop */
    
  printf("-----------------------------------------------------------\n");
   
  /* free statement handle 1 */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* free statement handle 2 */
  cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt2);
  STMT_HANDLE_CHECK(hstmt2, hdbc, cliRC);
  return rc;
} /* end callGetNextResults() */
