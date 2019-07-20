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
** SOURCE FILE NAME: spcall.c                                       
**
** SAMPLE: Call individual stored procedures
**
**         Call the stored procedure by issuing one of the following:
**         spcall <procname> <args> or spcall <schema>.<procname> <args>)
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol -- Bind a Column to an Application Variable or
**                       LOB locator
**         SQLBindParameter -- Bind a Parameter Marker to a Buffer or
**                             LOB locator
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLEndTran -- End Transactions of a Connection
**         SQLExecute -- Execute a Statement
**         SQLFetch -- Fetch Next Row
**         SQLFreeHandle -- Free Handle Resources
**         SQLPrepare -- Prepare a Statement
**         SQLProcedureColumns -- Get Input/Output Parameter Information
**                                for a Procedure
**         SQLSetConnectAttr -- Set Connection Attributes
**         SQLSetEnvAttr -- Set Environment Attribute
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

#define MAX_NUM_PARAMS 25
#define MAX_BUF_LEN 1024

#define MAIN_PANIC \
        sqlrc = SQLEndTran(SQL_HANDLE_ENV, henv, SQL_ROLLBACK); \
        ENV_HANDLE_CHECK(henv, sqlrc);

int main(int argc, char *argv[])
{
  int rc = 0;
  SQLHANDLE henv, hdbc, hstmt, hstmt1;
  SQLRETURN sqlrc;
  SQLCHAR sqlstmt[1024];
  char *procname;
  char **procargs;
  short input_args = 0;
  int separator = 0;
  char *temp_str = 0;

  /* variables for database name, user id, and password */
  SQLCHAR db[SQL_MAX_DSN_LENGTH + 1];
  SQLCHAR uid[MAX_UID_LENGTH + 1];
  SQLCHAR pwd[MAX_PWD_LENGTH + 1];

  SQLCHAR colNamePattern[] = "%";
  char colSchemaNamePattern[] = "%";
  struct
  {
    SQLINTEGER ind;
    SQLCHAR val[129];
  }
  colName, schemaName;

  struct
  {
    SQLINTEGER ind;
    SQLINTEGER val;
  }
  colLength, colOrdinal;

  struct
  {
    SQLINTEGER ind;
    SQLSMALLINT val;
  }
  colScale, colType, colDataType;

  char tempSchema[129] = "\0";
  SQLUSMALLINT ParameterNumber; /* ipar */
  /* fParamType of each parameter */
  SQLSMALLINT InputOutputType[MAX_NUM_PARAMS];
  SQLSMALLINT ValueType = SQL_C_CHAR; /* fCType */
  /* fSqlType of each parameter */
  SQLSMALLINT ParameterType[MAX_NUM_PARAMS]; 
  SQLUINTEGER ColumnSize; /* cbColDef */
  SQLSMALLINT DecimalDigits; /* ibScale */
  SQLPOINTER ParameterValuePtr; /* rgbValue */
  SQLINTEGER BufferLength = MAX_BUF_LEN; /* cbValueMax */
  SQLINTEGER StrLen_or_IndPtr[MAX_NUM_PARAMS]; /* pcbValue */
  /* fSqlType of each parameter */
  SQLCHAR ParameterName[MAX_NUM_PARAMS][129];
  sqlint32 longval;
  SQLCHAR bufs[MAX_NUM_PARAMS][MAX_BUF_LEN]; /* buffers for parameters */
  short i, has_out_parms = 0, invalid_cmd_line = 0, flen;
  /* number of procedure parameters does not include
     'spcall' and procedure name */ 
  int nparams = argc - 2; 
  char *field;

  db[0] = '\0';
  uid[0] = '\0';
  pwd[0] = '\0';

  /*************************************************************/
  /* parse command line arguments                              */
  /*************************************************************/

  if (argc < 2)
  {
    invalid_cmd_line = 1;
  }
  else
  {
    i = 1;
    while (*argv[i] == '-')
    {
      if (argc < i + 2)
      {
        invalid_cmd_line = 1;
        break;
      } /* if */
      switch (*(argv[i] + 1))
      {
        case 'd':
          flen = SQL_MAX_DSN_LENGTH;
          field = (char *)db;
          break;
        case 'u':
          flen = MAX_UID_LENGTH;
          field = (char *)uid;
          break;
        case 'p':
          flen = MAX_PWD_LENGTH;
          field = (char *)pwd;
          break;
        default:
          invalid_cmd_line = 1;
          break;
      } /* switch */
      strncpy(field, (const char *)argv[i + 1], flen);
      field[flen] = 0;
      i += 2;
      nparams -= 2;
    } /* while */
  } /* if */

  if (invalid_cmd_line)
  {
    printf("\nUSAGE: ");
    printf("spcall [-d <db name>] [-u <user name>] [-p <password>] ");
    printf("procname [input-arg1 input-arg2 ...]\n");

    return 1;
  }

  /* store the procedure name and its parameters */
  procname = argv[i];
  procargs = &argv[i + 1];

  /* change the procedure name to upper case */
  for (i = 0; i < strlen(procname); i++)
  {
    if (isalpha(procname[i]))
    {
      procname[i] = toupper(procname[i]);
    }
  }

  /* separate the schema name if specified */
  if ((temp_str = strstr(procname, ".")) != NULL)
  {
    separator = strlen(procname) - strlen(temp_str);
    strncpy(colSchemaNamePattern, procname, separator);
    procname = temp_str + 1;
  }

  /*************************************************************/
  /* set up the CLI environment                                 */
  /*************************************************************/

  /* allocate an environment handle */
  sqlrc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  if (sqlrc != SQL_SUCCESS)
  {
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  sqlrc = %d\n", sqlrc);
    printf("  line  = %d\n", __LINE__);
    printf("  file  = %s\n", __FILE__);
    return 1;
  }

  /* enable sending column names over the network */
  sqlrc = SQLSetEnvAttr(henv,
                        SQL_ATTR_USE_LIGHT_OUTPUT_SQLDA,
                        (SQLPOINTER)SQL_FALSE,
                        SQL_FALSE);
  ENV_HANDLE_CHECK(henv, sqlrc);
  
  /* set attribute to enable application to run as ODBC 3.0 application */
  sqlrc = SQLSetEnvAttr(henv,
                        SQL_ATTR_ODBC_VERSION,
                        (void *)SQL_OV_ODBC3,
                        0);
  ENV_HANDLE_CHECK(henv, sqlrc);

  /* connect to the database where the stored procedure will execute */

  /* allocate a database connection handle */
  sqlrc = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  ENV_HANDLE_CHECK(henv, sqlrc);

  /* set AUTOCOMMIT off */
  sqlrc = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, sqlrc);

  if (db[0] == '\0')
  {
    strcpy((char *)db, "sample");
  }

  printf("\n  Connecting to %s ...\n", db);

  /* connect to the database */
  sqlrc = SQLConnect(hdbc,
                     (SQLCHAR *)db,
                     SQL_NTS,
                     (SQLCHAR *)uid,
                     SQL_NTS,
                     (SQLCHAR *)pwd,
                     SQL_NTS);
  DBC_HANDLE_CHECK(hdbc, sqlrc);

  printf("  Connected to %s.\n", db);

  /*************************************************************/
  /* obtain the stored procedure's parameters                  */
  /*************************************************************/

  /* allocate a statement handle */
  sqlrc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* get input/output parameter information for a procedure */
  sqlrc = SQLProcedureColumns(hstmt,
                              NULL,
                              0, /* catalog name not used */
                              (unsigned char *)colSchemaNamePattern,
                              SQL_NTS, /* schema name not currently used */
                              (unsigned char *)procname,
                              SQL_NTS,
                              colNamePattern,
                              SQL_NTS); /* all columns */
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for the schema name */
  sqlrc = SQLBindCol(hstmt,
                     2,
                     SQL_C_CHAR,
                     schemaName.val,
                     129,
                     &schemaName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for the column name */
  sqlrc = SQLBindCol(hstmt, 4, SQL_C_CHAR, colName.val, 129, &colName.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for column type (IN, OUT, INOUT) */
  sqlrc = SQLBindCol(hstmt,
                     5,
                     SQL_C_SHORT,
                     (SQLPOINTER)&colType.val,
                     sizeof(colType.val),
                     &colType.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for data type (SQL data type) */
  sqlrc = SQLBindCol(hstmt,
                     6,
                     SQL_C_SHORT,
                     (SQLPOINTER)&colDataType.val,
                     sizeof(colDataType.val),
                     &colDataType.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for column size */
  sqlrc = SQLBindCol(hstmt,
                     8,
                     SQL_C_LONG,
                     (SQLPOINTER)&colLength.val,
                     sizeof(colLength.val),
                     &colLength.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for the scale of the parameter */
  sqlrc = SQLBindCol(hstmt,
                     10,
                     SQL_C_SHORT,
                     (SQLPOINTER)&colScale.val,
                     sizeof(colScale.val),
                     &colScale.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* bind the result column for parameter ordinal */
  sqlrc = SQLBindCol(hstmt,
                     18,
                     SQL_C_LONG,
                     (SQLPOINTER)&colOrdinal.val,
                     sizeof(colOrdinal.val),
                     &colOrdinal.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /*************************************************************/
  /* for each parameter of the stored procedure:               */
  /*   o  build the CALL statement                             */
  /*   o  configure the input/output parameters for the        */
  /*      CALL statement                                       */
  /*************************************************************/

  /* allocate a database connection handle */
  sqlrc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, sqlrc);

  strcpy((char *)sqlstmt, "CALL ");
  strcat((char *)sqlstmt, (const char *)procname);
  strcat((char *)sqlstmt, " (");

  ParameterNumber = 0;
  input_args = 0;

  /* fetch next row */
  sqlrc = SQLFetch(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  while (sqlrc != SQL_NO_DATA_FOUND)
  {
    if (ParameterNumber >= MAX_NUM_PARAMS)
    {
      printf("\nERROR: cannot handle more than %d parameters ...\n\n",
             MAX_NUM_PARAMS);
      MAIN_PANIC;
    }

    /* create the CALL statement parameter by parameter */
    strcat((char *)sqlstmt, " ?,");

    if (strlen(tempSchema) > 0)
    {
      if (strcmp((char *)schemaName.val, tempSchema))
      {
        printf("\nERROR: Procedure exists in multiple schemas ...\n\n");
        MAIN_PANIC;
      }
    }
    else
    {
      strncpy(tempSchema, (const char *)schemaName.val, schemaName.ind);
    }

    /* store the column name for printing the stored procedure output */
    strncpy((char *)ParameterName[ParameterNumber],
            (const char *)colName.val, colName.ind);
    ParameterName[ParameterNumber][colName.ind] = '\0';

    /* get the parameter type and data if input */
    InputOutputType[ParameterNumber] = colType.val;
    ParameterValuePtr = (SQLPOINTER)bufs[ParameterNumber];

    /* input parameters of the stored procedure must have
       corresponding command line parameters */
    if ((colType.val == SQL_PARAM_INPUT_OUTPUT) ||
        (colType.val == SQL_PARAM_INPUT))
    {
      /* check if all of the parameters were provided at the command line */
      if (input_args >= nparams)
      {
        printf("\nERROR: Too few parameters in the command line ...\n\n");
        MAIN_PANIC;
      }
      else
      /* map command line input parameter to the stored procedure
         input parameter */
      {
        strcpy((char *)bufs[ParameterNumber], procargs[input_args++]);
      }

      /* check for a NULL input parameter provided at the command line */
      if (strcmp((const char *)bufs[ParameterNumber], "NULL") == 0)
      {
        StrLen_or_IndPtr[ParameterNumber] = SQL_NULL_DATA;
      }
      else /* null-terminated string */
      {
        StrLen_or_IndPtr[ParameterNumber] = SQL_NTS;
      }
    }

    /* check if there is output to process */
    if ((colType.val == SQL_PARAM_INPUT_OUTPUT) ||
        (colType.val == SQL_PARAM_OUTPUT))
    {
      has_out_parms = 1;
    }

    /* SQL data type of the parameter */
    ParameterType[ParameterNumber] = colDataType.val;

    /* parameter output sizes */

    /* ColumnSize is only relevant for CHARACTER, DECIMAL, and NUMERIC */
    ColumnSize = colLength.val;
    /* DecimalDigits is only relevant for DECIMAL and NUMERIC */
    DecimalDigits = colScale.val; /* scale */

    /* bind the stored procedure parameter */
    sqlrc = SQLBindParameter(hstmt1,
                             (SQLUSMALLINT)(ParameterNumber + 1),
                             InputOutputType[ParameterNumber],
                             ValueType,
                             ParameterType[ParameterNumber],
                             ColumnSize,
                             DecimalDigits,
                             ParameterValuePtr,
                             BufferLength,
                             &(StrLen_or_IndPtr[ParameterNumber]));
    STMT_HANDLE_CHECK(hstmt1, hdbc, sqlrc);

    /* get the next stored procedure parameter */
    ParameterNumber++;

    /* fetch next row */
    sqlrc = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  } /* while */

  /*************************************************************/
  /* final processing for the stored procedure's parameters    */
  /*************************************************************/

  /* finished getting the stored procedure's parameters, so must 
     free the associated statement handle */
  sqlrc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, sqlrc);

  /* if the number of parameters supplied at the command line does not
     match those required by the stored procedure, then display an error */
  if (input_args != nparams)
  { /* too many args in the command line */
    printf(
      "\nWARNING: Wrong number of input parameters (expected %d)...\n\n",
       input_args);
  }

  /*************************************************************/
  /* invoke the stored procedure                               */
  /*************************************************************/

  /* generate the closing bracket (overwrite the last ',') */
  sqlstmt[strlen((const char *)sqlstmt) - 1] = ')';

  /* prepare the CALL statement */
  sqlrc = SQLPrepare(hstmt1, sqlstmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt1, hdbc, sqlrc);

  /* execute the CALL statement */
  sqlrc = SQLExecute(hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, sqlrc);

  /*************************************************************/
  /* print the stored procedure's output parameters if any.    */
  /*************************************************************/

  if (has_out_parms)
  {
    /* printf ("\n----- OUTPUT PARAMETERS -----"); */
    for (i = 0; i < ParameterNumber; i++)
    {
      if (InputOutputType[i] != SQL_PARAM_INPUT)
      {
        printf("\n%s: ", ParameterName[i]);
        switch (StrLen_or_IndPtr[i])
        {
          case SQL_NULL_DATA:
          {
            printf("NULL");
            break;
          }
          case SQL_NO_TOTAL:
          {
            printf("UNKNOWN LENGTH");
            break;
          }
          default:
          {
            switch (ParameterType[i])
            {
              case SQL_CHAR:
              case SQL_VARCHAR:
              case SQL_LONGVARCHAR:
              case SQL_INTEGER:
              case SQL_SMALLINT:
              case SQL_BIGINT:
              case SQL_FLOAT:
              case SQL_DECFLOAT:
              case SQL_DOUBLE:
              case SQL_REAL:
              case SQL_TYPE_DATE:
              case SQL_TYPE_TIME:
              case SQL_TYPE_TIMESTAMP:
              case SQL_DECIMAL:
              case SQL_NUMERIC:
                printf("%*.*s", StrLen_or_IndPtr[i], StrLen_or_IndPtr[i],
                                 bufs[i]);
                break;
              default:
                printf("\nERROR: Unknown type code ");
                printf("%d for OUTPUT paramenter %d. Rolling back ...\n",
                       ParameterType[i], i);
                MAIN_PANIC;
            } /* switch */
            break;
          } /* default */
        } /* switch */
      } /* if */
    } /* for */
    printf("\n\n");
  } /* if */

  /*************************************************************/
  /* print the stored procedure's result sets if any           */
  /*************************************************************/

  do
  {
    rc = StmtResultPrint(hstmt1, hdbc);
  }
  /* determine if there are more result sets */
  while (SQLMoreResults(hstmt1) == SQL_SUCCESS);

  /*************************************************************/
  /* terminate the application                                 */
  /*************************************************************/

  /* commit the transaction */
  sqlrc = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
  DBC_HANDLE_CHECK(hdbc, sqlrc);

  /* finished calling the stored procedure, so free the handle */
  sqlrc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt1);
  STMT_HANDLE_CHECK(hstmt1, hdbc, sqlrc);

  /* disconnect from the database */
  sqlrc = SQLDisconnect(hdbc);
  DBC_HANDLE_CHECK(hdbc, sqlrc);

  /* free connection handle */
  sqlrc = SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
  DBC_HANDLE_CHECK(hdbc, sqlrc);

  /* free environment handle */
  sqlrc = SQLFreeHandle(SQL_HANDLE_ENV, henv);
  ENV_HANDLE_CHECK(henv, sqlrc);

  return 0;
} /* main */

