/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/******************************************************************************
** Source File Name: demolibapptokengen.c
**
** Description     : Client-side shared library for generating application tokens
**                   (apptoken) during Db2 authentication negotiation.
**
**                   Db2 loads this library automatically from:
**                     $INSTHOME/sqllib/security64/apptoken/apptokengen.so
**                   (or $INSTHOME/security64/apptoken/apptokengen.so)
**                   when APPTOKENGEN=ON is configured in db2dsdriver.cfg or db2cli.ini.
**
**                   The library exports:
**                     - apptokengen_callback (called by Db2 client runtime)
**                     - db2GetAppToken       (standard API alias)
**
**                   Signing logic is in utilapptokensigner.c / utilapptokensigner.h;
**                   this file contains only the Db2 API entry points.
**
**                   Token format (all fields concatenated, no padding):
**                     PREFIX   : "TRUSTCALLBACK"  — 13 ASCII bytes
**                     NONCE    : raw nonce bytes   — nonceLen bytes
**                     EXPIRY   : Unix epoch (now + 60 s), big-endian int64 — 8 bytes
**                     SIGLEN   : byte count of SIG, big-endian uint16    — 2 bytes
**                     SIG      : RSA-2048/SHA-256 signature over
**                                (PREFIX || NONCE || EXPIRY)             — SIGLEN bytes
**
**                   Private key location: $HOME/trustproc_keys/private.pem
**
** Build (from signedtoken/):
**   make apptoken_lib
*******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>
#include "db2ApiDf.h"
#include "sqlcli.h"
#include "utilapptokensigner.h"

#define APPTOKEN_MAX_LEN    32672
#define APPTOKEN_LOG_FILE   "/tmp/demolibapptokengen.log"

static void apptoken_log(const char *fmt, ...)
{
    FILE *f = fopen(APPTOKEN_LOG_FILE, "a");
    if (!f) return;

    time_t now = time(NULL);
    struct tm tm_buf;
    localtime_r(&now, &tm_buf);
    char time_str[32];
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", &tm_buf);

    fprintf(f, "[%s] [demolibapptokengen] ", time_str);
    va_list args;
    va_start(args, fmt);
    vfprintf(f, fmt, args);
    va_end(args);
    fprintf(f, "\n");
    fclose(f);
}

/******************************************************************************
** Function : apptokengen_callback
**
** Purpose  : Sole entry point loaded dynamically by Db2 client runtime via
**            dlsym("apptokengen_callback") in secLoadClientApptokengenPlugin.
*******************************************************************************/
SQL_API_RC SQL_API_FN apptokengen_callback(
    sqluint32                 versionNumber,
    void                     *pApptokenUserData,
    ApptokengenParamStruct   *pParmStruct,
    unsigned char            *pApptokenOutput,
    sqluint32                *pApptokenOutputLen)
{
    (void)pApptokenUserData;
    apptoken_log("apptokengen_callback invoked: version=%u", (unsigned int)versionNumber);

    if (pParmStruct == NULL)
    {
        apptoken_log("ERROR: pParmStruct is NULL");
        return SQL_ERROR;
    }

    if (pParmStruct->pNonce == NULL || pParmStruct->nonceLen == 0)
    {
        apptoken_log("ERROR: pNonce is NULL or nonceLen == 0");
        return SQL_ERROR;
    }

    if (pApptokenOutput == NULL || pApptokenOutputLen == NULL)
    {
        apptoken_log("ERROR: pApptokenOutput or pApptokenOutputLen is NULL");
        return SQL_ERROR;
    }

    *pApptokenOutputLen = APPTOKEN_MAX_LEN;
    if (utilapptokensigner_build(pParmStruct->pNonce, pParmStruct->nonceLen,
                                 pApptokenOutput, pApptokenOutputLen,
                                 apptoken_log) != SQL_SUCCESS)
        return SQL_ERROR;

    return SQL_SUCCESS;
}
