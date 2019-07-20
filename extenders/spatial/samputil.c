/*******************************************************************************
**
** Source File Name = samputil.c  %I%
**
** Licensed Materials - Property of IBM
**
** (C) COPYRIGHT International Business Machines Corp. 1995
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
**
**    PURPOSE :
**    - contains various sample functions, used by most other samples:
**       - connect
**       - print_connect_info
**       - terminate
**       - check_error
**       - print_error
**       - print_results
**
**    FUNCTIONS USED :
**        SQLAllocConnect
**        SQLBindCol
**        SQLColAttributes
**        SQLConnect
**        SQLDescribeCol
**        SQLDisconnect
**        SQLError
**        SQLFetch
**        SQLFreeConnect
**        SQLFreeEnv
**        SQLGetInfo
**        SQLNumResultCols
**        SQLSetConnectOption
**
**
*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sqlcli1.h"
#include "samputil.h"

#define MAXCOLS        255

#ifndef max
#define  max(a,b) (a > b ? a : b)
#endif

/*--> SQLL1X12.SCRIPT */
/* Global Variables for user id and password, defined in main module.
   To keep samples simple, not a recommended practice.
   The INIT_UID_PWD macro is used to initialize these variables.
*/
extern    SQLCHAR   dbase[SQL_MAX_DSN_LENGTH + 1];
extern    SQLCHAR   uid[MAX_UID_LENGTH + 1];
extern    SQLCHAR   pwd[MAX_PWD_LENGTH + 1];
/********************************************************************/
SQLRETURN
DBconnect(SQLHENV henv,
          SQLHDBC * hdbc)
{
    SQLRETURN       rc;
    SQLSMALLINT     outlen;

    /* allocate a connection handle     */
    if (SQLAllocConnect(henv, hdbc) != SQL_SUCCESS) {
        printf(">---ERROR while allocating a connection handle-----\n");
        return (SQL_ERROR);
    }
    /* Set AUTOCOMMIT OFF */
    rc = SQLSetConnectOption(*hdbc, SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF);
    if (rc != SQL_SUCCESS) {
        printf(">---ERROR while setting AUTOCOMMIT OFF ------------\n");
        return (SQL_ERROR);
    }
    rc = SQLConnect(*hdbc, dbase, SQL_NTS, uid, SQL_NTS, pwd, SQL_NTS);
    if (rc != SQL_SUCCESS) {
        printf(">--- Error while connecting to database: %s -------\n", dbase);
        SQLDisconnect(*hdbc);
        SQLFreeConnect(*hdbc);
        return (SQL_ERROR);
    } else {                    /* Print Connection Information */
        printf(">Connected to %s\n", dbase);
    }
    return (SQL_SUCCESS);
}

/********************************************************************/
/* DBconnect2 - Connect with conect type and syncpoint type         */
/* Valid connect types SQL_CONCURRENT_TRANS, SQL_COORDINATED_TRANS  */
/* Valid syncpoint types, SQL_1_PHASE, SQL_2_PHASE        */
/********************************************************************/
SQLRETURN
DBconnect2(SQLHENV henv,
           SQLHDBC * hdbc, SQLINTEGER contype, SQLINTEGER conphase)
{
    SQLRETURN       rc;
    SQLSMALLINT     outlen;

    /* allocate a connection handle     */
    if (SQLAllocConnect(henv, hdbc) != SQL_SUCCESS) {
        printf(">---ERROR while allocating a connection handle-----\n");
        return (SQL_ERROR);
    }
    /* Set AUTOCOMMIT OFF */
    rc = SQLSetConnectOption(*hdbc, SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF);
    if (rc != SQL_SUCCESS) {
        printf(">---ERROR while setting AUTOCOMMIT OFF ------------\n");
        return (SQL_ERROR);
    }
    rc = SQLSetConnectOption(hdbc[0], SQL_CONNECTTYPE, contype);
    if (rc != SQL_SUCCESS) {
        printf(">---ERROR while setting Connect Type -------------\n");
        return (SQL_ERROR);
    }
    if (contype == SQL_COORDINATED_TRANS ) {
        rc = SQLSetConnectOption(hdbc[0], SQL_SYNC_POINT, conphase);
        if (rc != SQL_SUCCESS) {
            printf(">---ERROR while setting Syncpoint Phase --------\n");
            return (SQL_ERROR);
        }
    }
    rc = SQLConnect(*hdbc, dbase, SQL_NTS, uid, SQL_NTS, pwd, SQL_NTS);
    if (rc != SQL_SUCCESS) {
        printf(">--- Error while connecting to database: %s -------\n", dbase);
        SQLDisconnect(*hdbc);
        SQLFreeConnect(*hdbc);
        return (SQL_ERROR);
    } else {                    /* Print Connection Information */
        printf(">Connected to %s\n", dbase);
    }
    return (SQL_SUCCESS);

}
/*<-- */

/********************************************************************
**   Prompted_Connect - Prompt for connect options and connect       **
********************************************************************/

int
Prompted_Connect(SQLHENV henv,
          SQLHDBC * hdbc)
{
    SQLRETURN       rc;
    SQLCHAR         buffer[255];
    SQLSMALLINT     outlen;

   /* Set AUTOCOMMIT OFF */
    rc = SQLSetConnectOption(*hdbc, SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF);
    if (rc != SQL_SUCCESS) {
        printf(">---ERROR while setting AUTOCOMMIT OFF ------------\n");
        return (SQL_ERROR);
    }

    printf(">Enter Server Name:\n");
    fgets((char *) dbase, sizeof(dbase), stdin);
    printf(">Enter User Name:\n");
    fgets((char *) uid, sizeof(uid), stdin);
    printf(">Enter Password:\n");
    fgets((char *) pwd, sizeof(pwd), stdin);

    rc = SQLConnect(*hdbc, dbase, SQL_NTS, uid, SQL_NTS, pwd, SQL_NTS);
    if (rc != SQL_SUCCESS) {
        printf(">--- ERROR while connecting to %s -------------\n", dbase);
        return (SQL_ERROR);
    } else {
        printf("Successful Connect to %s\n", dbase);
        return (SQL_SUCCESS);
    }
} /* end Prompted_Connect */

/********************************************************************/
SQLRETURN
terminate(SQLHENV henv,
          SQLRETURN rc)
{
    SQLCHAR         buffer[255];
    SQLSMALLINT     outlen;

    printf(">Terminating ....\n");
    print_error(henv, SQL_NULL_HDBC, SQL_NULL_HENV, rc, __LINE__, __FILE__);

    /* Free environment handle */
    if (SQLFreeEnv(henv) != SQL_SUCCESS)
        print_error(henv, SQL_NULL_HDBC, SQL_NULL_HENV, rc, __LINE__, __FILE__);

    return (rc);
}

/********************************************************************/
/* Print Connection Information */
SQLRETURN
print_connect_info(SQLHDBC hdbc)
{
    SQLCHAR         buffer[255];
    SQLSMALLINT     outlen;
    SQLRETURN       rc;

    printf("-------------------------------------------\n");
    rc = SQLGetInfo(hdbc, SQL_DATA_SOURCE_NAME, buffer, 255, &outlen);
    CHECK_DBC(hdbc, rc);

    printf("Connected to Server: %s\n", buffer);
    rc = SQLGetInfo(hdbc, SQL_DATABASE_NAME, buffer, 255, &outlen);
    CHECK_DBC(hdbc, rc);

    printf(" Database Name: %s\n", buffer);
    rc = SQLGetInfo(hdbc, SQL_SERVER_NAME, buffer, 255, &outlen);
    CHECK_DBC(hdbc, rc);

    printf(" Instance Name: %s\n", buffer);
    rc = SQLGetInfo(hdbc, SQL_DBMS_NAME, buffer, 255, &outlen);
    CHECK_DBC(hdbc, rc);

    printf("     DBMS Name: %s\n", buffer);
    rc = SQLGetInfo(hdbc, SQL_DBMS_VER, buffer, 255, &outlen);
    CHECK_DBC(hdbc, rc);

    printf("  DBMS Version: %s\n", buffer);
    printf("-------------------------------------------\n");

    return (rc);

}

/*--> SQLL1X32.SCRIPT */
/*******************************************************************
**  - print_error   - call SQLError(), display SQLSTATE and message
**                  - called by check_error, see below
*******************************************************************/

SQLRETURN
print_error(SQLHENV henv,
            SQLHDBC hdbc,
            SQLHSTMT hstmt,
            SQLRETURN frc,   /* Return code to be included with error msg  */
            int line,        /* Used for output message, indcate where     */
            char * file)  /* the error was reported from  */
{
    SQLCHAR         buffer[SQL_MAX_MESSAGE_LENGTH + 1];
    SQLCHAR         sqlstate[SQL_SQLSTATE_SIZE + 1];
    SQLINTEGER      sqlcode;
    SQLSMALLINT     length;


    printf(">--- ERROR -- RC= %d Reported from %s, line %d ------------\n",
           frc, file, line);
    while (SQLError(henv, hdbc, hstmt, sqlstate, &sqlcode, buffer,
                    SQL_MAX_MESSAGE_LENGTH + 1, &length) == SQL_SUCCESS) {
        printf("         SQLSTATE: %s\n", sqlstate);
        printf("Native Error Code: %d\n", sqlcode);
        printf("%s \n", buffer);
    };
    printf(">--------------------------------------------------\n");
    return (SQL_ERROR);

}
/*********************************************************************
* The following macros (defined in samputil.h) use check_error
*
* #define CHECK_ENV( henv, RC)  if (RC != SQL_SUCCESS) \
*   {check_error(henv, SQL_NULL_HDBC, SQL_NULL_HSTMT, RC, __LINE__, __FILE__);}
*
* #define CHECK_DBC( hdbc, RC)  if (RC != SQL_SUCCESS) \
*  {check_error(SQL_NULL_HENV, hdbc, SQL_NULL_HSTMT, RC, __LINE__, __FILE__);}
*
* #define CHECK_STMT( hstmt, RC)  if (RC != SQL_SUCCESS) \
*  {check_error(SQL_NULL_HENV, SQL_NULL_HDBC, hstmt, RC, __LINE__, __FILE__);}
*
***********************************************************************/

/*******************************************************************
**  - check_error   - call print_error(), checks severity of return code
*******************************************************************/
SQLRETURN
check_error(SQLHENV henv,
            SQLHDBC hdbc,
            SQLHSTMT hstmt,
            SQLRETURN frc,
            int line,
            char * file)
{
    SQLRETURN       rc;

    switch (frc) {
    case SQL_INVALID_HANDLE:
        printf("\n>------ ERROR Invalid Handle --------------------------\n");
        print_error(henv, hdbc, hstmt, frc, line, file);
        return (SQL_ERROR);
        break;
    case SQL_ERROR:
        printf("\n>--- FATAL ERROR, Attempting to rollback transaction --\n");
        print_error(henv, hdbc, hstmt, frc, line, file);
        return (SQL_ERROR);
        break;
    default:
        break;
    }
    return (SQL_SUCCESS);

}                               /* end check_error */
/*<-- */

SQLRETURN
print_results(SQLHSTMT hstmt)
{
    SQLCHAR         colname[32];
    SQLSMALLINT     coltype;
    SQLSMALLINT     colnamelen;
    SQLSMALLINT     nullable;
    SQLUINTEGER     collen[MAXCOLS];
    SQLSMALLINT     scale;
    SQLINTEGER      outlen[MAXCOLS];
    SQLCHAR        *data[MAXCOLS];
    SQLCHAR         errmsg[256];
    SQLRETURN       rc;
    SQLSMALLINT     nresultcols;
    int             i;
    SQLINTEGER      displaysize;

    rc = SQLNumResultCols(hstmt, &nresultcols);
    CHECK_STMT(hstmt, rc);

    for (i = 0; i < nresultcols; i++) {
        SQLDescribeCol(hstmt, (SQLUSMALLINT)(i + 1), colname, sizeof(colname),
                       &colnamelen, &coltype, &collen[i], &scale, NULL);

        /* get display length for column */
        SQLColAttributes(hstmt, (SQLUSMALLINT)(i + 1), SQL_COLUMN_DISPLAY_SIZE, 
		       NULL, 0, NULL, &displaysize);

        /*
         * set column length to max of display length, and column name
         * length.  Plus one byte for null terminator
         */
        collen[i] = max(displaysize, strlen((char *) colname)) + 1;

        printf("%-*.*s", (int)collen[i], (int)collen[i], colname);

        /* allocate memory to bind column                             */
        data[i] = (SQLCHAR *) malloc((int)collen[i]);

        /* bind columns to program vars, converting all types to CHAR */
        rc = SQLBindCol(hstmt, (SQLUSMALLINT)(i + 1), SQL_C_CHAR, data[i], 
		collen[i], &outlen[i]);
    }
    printf("\n");
    /* display result rows                                            */
    while ((rc = SQLFetch(hstmt)) != SQL_NO_DATA_FOUND) {
        errmsg[0] = '\0';
        for (i = 0; i < nresultcols; i++) {
            /* Check for NULL data */
            if (outlen[i] == SQL_NULL_DATA)
                printf("%-*.*s", (int)collen[i], (int)collen[i], "NULL");
            else
            {   /* Build a truncation message for any columns truncated */
                if (outlen[i] >= collen[i]) {
                    sprintf((char *) errmsg + strlen((char *) errmsg),
                            "%d chars truncated, col %d\n",
                            (int)outlen[i] - collen[i] + 1, i + 1);
                }
                /* Print column */
                printf("%-*.*s", (int)collen[i], (int)collen[i], data[i]);
             }
        }                       /* for all columns in this row  */

        printf("\n%s", errmsg); /* print any truncation messages    */
    }                           /* while rows to fetch */

    /* free data buffers                                              */
    for (i = 0; i < nresultcols; i++) {
        free(data[i]);
    }

    return(SQL_SUCCESS);

}                               /* end print_results */
