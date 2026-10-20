/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/******************************************************************************
** Source File Name: demoembeddedconnect.c
**
** Description     : C demo application showing inline apptoken callback
**                   registration via the Db2 CLI API.
**
**                   This is the C equivalent of DemoEmbeddedConnect.java: the token
**                   generator is a function inside the application itself,
**                   registered directly with the CLI driver before the
**                   connection is made. No separate shared library or
**                   configuration entry (APPTOKENGEN=ON) is required.
**
**                   The apptoken signing logic is shared with demolibapptokengen.c
**                   via utilapptokensigner.c / utilapptokensigner.h.
**
** Usage:
**     demoembeddedconnect <dsn> <authid> <password>
**
**     <dsn>      — DSN, hostname, or alias as used in SQLConnect / db2cli.ini
**     <authid>   — connecting user name (e.g. BOSS)
**     <password> — password for <authid>
**
** Expected output on a trusted connection:
**     Connecting: <dsn> as <authid>
**     SUCCESS: Trusted connection established under context: DEMO_TRUSTCTX
**
** Build (from signedtoken/):
**     make demoembeddedconnect
**
** Run:
**     ./build/demoembeddedconnect $DSN $AUTHID $PASSWORD
*******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>

/* Db2 headers */
#include "db2ApiDf.h"
#include "sqlcli1.h"
#include <stdint.h>

/* Shared signing utility */
#include "utilapptokensigner.h"

#define APPTOKEN_MAX_LEN 32672
#define DEMOEMBEDDEDCONNECT_LOG_FILE "/tmp/demoembeddedconnect.log"

/* -----------------------------------------------------------------------
 * Logging
 * ----------------------------------------------------------------------- */

static void demo_log(const char *fmt, ...)
{
    FILE *f = fopen(DEMOEMBEDDEDCONNECT_LOG_FILE, "a");
    if (!f) return;

    time_t now = time(NULL);
    struct tm tm_buf;
    localtime_r(&now, &tm_buf);
    char time_str[32];
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", &tm_buf);

    fprintf(f, "[%s] [demoembeddedconnect] ", time_str);
    va_list args;
    va_start(args, fmt);
    vfprintf(f, fmt, args);
    va_end(args);
    fprintf(f, "\n");
    fclose(f);
}

/* -----------------------------------------------------------------------
 * Inline apptoken callback — registered directly by this application.
 *
 * Signature matches db2ApiDf.h db2GetAppToken typedef.
 * Delegates all token construction to utilapptokensigner_build().
 *
 * Return convention: 0 = success, non-zero = failure.
 * The runtime (sqlexGenerateAppToken) only tests zero vs non-zero.
 * DB2SEC_PLUGIN_* codes are for security plugins only — do not use them here.
 * ----------------------------------------------------------------------- */

static SQL_API_RC SQL_API_FN trust_callback(
    sqluint32                versionNumber,
    void                    *pApptokenUserData,
    ApptokengenParamStruct  *pParmStruct,
    unsigned char           *pApptokenOutput,
    sqluint32               *pApptokenOutputLen)
{
    (void)pApptokenUserData;
    demo_log("trust_callback invoked: version=%u", (unsigned int)versionNumber);

    if (pParmStruct == NULL || pParmStruct->pNonce == NULL || pParmStruct->nonceLen == 0)
    {
        demo_log("ERROR: invalid pParmStruct or nonce");
        return SQL_ERROR;
    }
    if (pApptokenOutput == NULL || pApptokenOutputLen == NULL)
    {
        demo_log("ERROR: NULL output pointer");
        return SQL_ERROR;
    }

    *pApptokenOutputLen = APPTOKEN_MAX_LEN;
    if (utilapptokensigner_build(pParmStruct->pNonce, pParmStruct->nonceLen,
                                 pApptokenOutput, pApptokenOutputLen,
                                 demo_log) != SQL_SUCCESS)
        return SQL_ERROR;

    return SQL_SUCCESS;
}

/* -----------------------------------------------------------------------
 * CLI helper: print diagnostic records on error.
 * ----------------------------------------------------------------------- */

static void print_diag(SQLSMALLINT htype, SQLHANDLE handle, const char *label)
{
    SQLCHAR     state[6];
    SQLINTEGER  native;
    SQLCHAR     msg[SQL_MAX_MESSAGE_LENGTH];
    SQLSMALLINT msglen;
    SQLSMALLINT i = 1;

    while (SQLGetDiagRec(htype, handle, i++, state, &native,
                         msg, sizeof(msg), &msglen) == SQL_SUCCESS)
    {
        fprintf(stderr, "[%s] SQLSTATE=%s  native=%d  %s\n",
                label, state, (int)native, msg);
    }
}

/* -----------------------------------------------------------------------
 * main
 * ----------------------------------------------------------------------- */

int main(int argc, char *argv[])
{
    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s <dsn> <authid> <password>\n", argv[0]);
        return 1;
    }

    const char *dsn      = argv[1];
    const char *authid   = argv[2];
    const char *password = argv[3];

    printf("Connecting: %s as %s\n", dsn, authid);
    demo_log("Connecting: dsn=%s authid=%s", dsn, authid);

    /* ----------------------------------------------------------------
     * 1. Allocate CLI environment and connection handles
     * ---------------------------------------------------------------- */
    SQLHENV  henv  = SQL_NULL_HANDLE;
    SQLHDBC  hdbc  = SQL_NULL_HANDLE;
    SQLHSTMT hstmt = SQL_NULL_HANDLE;
    SQLRETURN rc;

    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLAllocHandle(ENV) failed: %d\n", (int)rc);
        return 1;
    }

    rc = SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION,
                       (SQLPOINTER)(intptr_t)SQL_OV_ODBC3, 0);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLSetEnvAttr(ODBC3) failed: %d\n", (int)rc);
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        return 1;
    }

    rc = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLAllocHandle(DBC) failed: %d\n", (int)rc);
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        return 1;
    }

    /* ----------------------------------------------------------------
     * 2. Register the inline callback via SQL_ATTR_APP_TOKEN_GEN_CALLBACK.
     *
     *    This is the direct-callback analogue of:
     *      props.put("appTokenGen", new TrustCallbackImpl())  — Java
     *
     *    The callback function pointer is cast to SQLPOINTER.
     *    No shared library installation or APPTOKENGEN=ON config required.
     * ---------------------------------------------------------------- */
    rc = SQLSetConnectAttr(hdbc,
                           SQL_ATTR_APP_TOKEN_GEN_CALLBACK,
                           (SQLPOINTER)(uintptr_t)trust_callback,
                           SQL_IS_POINTER);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLSetConnectAttr(APP_TOKEN_GEN_CALLBACK) failed: %d\n", (int)rc);
        print_diag(SQL_HANDLE_DBC, hdbc, "SQLSetConnectAttr");
        SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        return 1;
    }
    demo_log("Registered inline apptoken callback via SQL_ATTR_APP_TOKEN_GEN_CALLBACK");

    /* ----------------------------------------------------------------
     * 3. Connect
     * ---------------------------------------------------------------- */
    rc = SQLConnect(hdbc,
                    (SQLCHAR *)dsn,      SQL_NTS,
                    (SQLCHAR *)authid,   SQL_NTS,
                    (SQLCHAR *)password, SQL_NTS);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLConnect failed: %d\n", (int)rc);
        print_diag(SQL_HANDLE_DBC, hdbc, "SQLConnect");
        SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        return 1;
    }
    demo_log("Connected successfully");

    /* ----------------------------------------------------------------
     * 4. Verify the trusted connection
     * ---------------------------------------------------------------- */
    rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLAllocHandle(STMT) failed: %d\n", (int)rc);
        SQLDisconnect(hdbc);
        SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        return 1;
    }

    rc = SQLExecDirect(hstmt, (SQLCHAR *)"VALUES TRUSTED_CONTEXT", SQL_NTS);
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        fprintf(stderr, "SQLExecDirect(VALUES TRUSTED_CONTEXT) failed: %d\n", (int)rc);
        print_diag(SQL_HANDLE_STMT, hstmt, "SQLExecDirect");
        SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
        SQLDisconnect(hdbc);
        SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        return 1;
    }

    /* Fetch one row — TRUSTED_CONTEXT is VARCHAR(128) */
    char ctx[129];
    memset(ctx, 0, sizeof(ctx));
    SQLLEN ind = SQL_NULL_DATA;

    SQLFetch(hstmt);
    SQLGetData(hstmt, 1, SQL_C_CHAR, ctx, sizeof(ctx), &ind);

    if (ind == SQL_NULL_DATA || ctx[0] == '\0')
    {
        printf("NOT TRUSTED: TRUSTED_CONTEXT = NULL\n");
        demo_log("NOT TRUSTED: TRUSTED_CONTEXT = NULL");
    }
    else if (strcmp(ctx, "DEMO_TRUSTCTX") == 0)
    {
        printf("SUCCESS: Trusted connection established under context: %s\n", ctx);
        demo_log("SUCCESS: TRUSTED_CONTEXT = %s", ctx);
    }
    else
    {
        printf("NOT TRUSTED: TRUSTED_CONTEXT = %s\n", ctx);
        demo_log("NOT TRUSTED: TRUSTED_CONTEXT = %s", ctx);
    }

    /* ----------------------------------------------------------------
     * 5. Clean up
     * ---------------------------------------------------------------- */
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
    SQLDisconnect(hdbc);
    SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
    SQLFreeHandle(SQL_HANDLE_ENV, henv);
    return 0;
}
