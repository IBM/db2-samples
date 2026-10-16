/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/******************************************************************************
** Source File Name: utilapptokensigner.c
**
** Description     : Shared signing utility for the Db2 Trust Procedure demo.
**
**                   Contains the token-building and key-loading logic used
**                   by both C-based demo approaches:
**                     - demolibapptokengen.c  (injected .so — no application source changes)
**                     - demoembeddedconnect.c (inline CLI callback — application sets
**                                              callback directly via
**                                              SQL_ATTR_APP_TOKEN_GEN_FUNC)
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
**   make apptoken_lib            — builds demolibapptokengen (injected .so)
**   make demoembeddedconnect     — builds demoembeddedconnect (inline callback app)
*******************************************************************************/

#include "utilapptokensigner.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>
#include <stdint.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include "db2ApiDf.h"

#define APPTOKEN_PREFIX     "TRUSTCALLBACK"
#define APPTOKEN_PREFIX_LEN 13
#define APPTOKEN_EXPIRY_LEN 8   /* 8-byte big-endian int64 */
#define APPTOKEN_SIGLEN_LEN 2   /* 2-byte big-endian uint16 */
#define PRIVATE_KEY_PATH_SUFFIX "/trustproc_keys/private.pem"

/*
 * write_be64 — write a 64-bit value in big-endian byte order.
 */
static void write_be64(unsigned char *dst, uint64_t v)
{
    dst[0] = (unsigned char)((v >> 56) & 0xFF);
    dst[1] = (unsigned char)((v >> 48) & 0xFF);
    dst[2] = (unsigned char)((v >> 40) & 0xFF);
    dst[3] = (unsigned char)((v >> 32) & 0xFF);
    dst[4] = (unsigned char)((v >> 24) & 0xFF);
    dst[5] = (unsigned char)((v >> 16) & 0xFF);
    dst[6] = (unsigned char)((v >>  8) & 0xFF);
    dst[7] = (unsigned char)( v        & 0xFF);
}

/*
 * write_be16 — write a 16-bit value in big-endian byte order.
 */
static void write_be16(unsigned char *dst, uint16_t v)
{
    dst[0] = (unsigned char)((v >> 8) & 0xFF);
    dst[1] = (unsigned char)( v       & 0xFF);
}

/*
 * build_private_key_path — construct $HOME/trustproc_keys/private.pem.
 * Returns 1 on success, 0 on failure (HOME not set or path too long).
 * Logs errors to the caller-supplied log function.
 */
static int build_private_key_path(char *buf, size_t bufsz,
                                   utilapptokensigner_logfn_t logfn)
{
    const char *home = getenv("HOME");
    if (!home || home[0] == '\0')
    {
        if (logfn) logfn("ERROR: HOME environment variable is not set");
        return 0;
    }
    if (strlen(home) + strlen(PRIVATE_KEY_PATH_SUFFIX) + 1 > bufsz)
    {
        if (logfn) logfn("ERROR: private key path too long");
        return 0;
    }
    snprintf(buf, bufsz, "%s%s", home, PRIVATE_KEY_PATH_SUFFIX);
    return 1;
}

/******************************************************************************
** Function : utilapptokensigner_build
**
** Purpose  : Build a signed apptoken from the given nonce.
**
** Parameters:
**   pNonce           — raw nonce bytes from the server
**   nonceLen         — byte count of pNonce
**   pOutput          — caller-supplied buffer to receive the token
**   pOutputLen       — in: buffer capacity; out: bytes written
**   logfn            — optional log callback (may be NULL)
**
** Returns  : SQL_SUCCESS on success, SQL_ERROR on failure.
*******************************************************************************/
int utilapptokensigner_build(
    const unsigned char         *pNonce,
    sqluint32                    nonceLen,
    unsigned char               *pOutput,
    sqluint32                   *pOutputLen,
    utilapptokensigner_logfn_t   logfn)
{
    /* Guard against a nonce so large that the length arithmetic wraps.
     * Db2 nonces are small (typically 16 bytes); 32 KB is a generous ceiling. */
    if (nonceLen == 0 || nonceLen > 32768)
    {
        if (logfn) logfn("ERROR: nonceLen=%u out of valid range (1..32768)", (unsigned int)nonceLen);
        return SQL_ERROR;
    }

    char keypath[512];
    if (!build_private_key_path(keypath, sizeof(keypath), logfn))
        return SQL_ERROR;

    FILE *kf = fopen(keypath, "r");
    if (!kf)
    {
        if (logfn) logfn("ERROR: Cannot open private key: %s", keypath);
        return SQL_ERROR;
    }
    EVP_PKEY *pkey = PEM_read_PrivateKey(kf, NULL, NULL, NULL);
    fclose(kf);
    if (!pkey)
    {
        if (logfn) logfn("ERROR: Failed to parse private key: %s", keypath);
        return SQL_ERROR;
    }
    if (logfn) logfn("Loaded private key from: %s", keypath);

    /* Build data-to-sign: PREFIX || NONCE || EXPIRY */
    time_t now      = time(NULL);
    uint64_t expiry = (uint64_t)(now + 60);

    unsigned char expiry_bytes[APPTOKEN_EXPIRY_LEN];
    write_be64(expiry_bytes, expiry);

    size_t dts_len = APPTOKEN_PREFIX_LEN + nonceLen + APPTOKEN_EXPIRY_LEN;
    unsigned char *dts = (unsigned char *)malloc(dts_len);
    if (!dts)
    {
        if (logfn) logfn("ERROR: Out of memory for sign buffer");
        EVP_PKEY_free(pkey);
        return SQL_ERROR;
    }
    memcpy(dts,                                APPTOKEN_PREFIX,    APPTOKEN_PREFIX_LEN);
    memcpy(dts + APPTOKEN_PREFIX_LEN,          pNonce,             nonceLen);
    memcpy(dts + APPTOKEN_PREFIX_LEN + nonceLen, expiry_bytes,     APPTOKEN_EXPIRY_LEN);

    /* Sign with RSA-2048 / SHA-256 */
    EVP_MD_CTX *mdctx = EVP_MD_CTX_new();
    size_t siglen = 0;
    int rc = SQL_ERROR;

    if (!mdctx ||
        EVP_DigestSignInit(mdctx, NULL, EVP_sha256(), NULL, pkey) != 1 ||
        EVP_DigestSignUpdate(mdctx, dts, dts_len) != 1 ||
        EVP_DigestSignFinal(mdctx, NULL, &siglen) != 1)
    {
        if (logfn) logfn("ERROR: EVP signing initialisation failed");
        goto cleanup;
    }

    {
        sqluint32 totalLen = (sqluint32)(APPTOKEN_PREFIX_LEN + nonceLen
                                        + APPTOKEN_EXPIRY_LEN
                                        + APPTOKEN_SIGLEN_LEN + siglen);
        if (logfn) logfn("Nonce len=%u  expiry=%llu  siglen=%zu  totalLen=%u",
                         (unsigned int)nonceLen, (unsigned long long)expiry,
                         siglen, (unsigned int)totalLen);

        if (totalLen > *pOutputLen)
        {
            if (logfn) logfn("ERROR: Token length %u exceeds buffer %u",
                             (unsigned int)totalLen, (unsigned int)*pOutputLen);
            goto cleanup;
        }

        unsigned char *sig = (unsigned char *)malloc(siglen);
        if (!sig)
        {
            if (logfn) logfn("ERROR: Out of memory for signature buffer");
            goto cleanup;
        }

        if (EVP_DigestSignFinal(mdctx, sig, &siglen) != 1)
        {
            if (logfn) logfn("ERROR: EVP_DigestSignFinal failed");
            free(sig);
            goto cleanup;
        }

        unsigned char *out = pOutput;
        memcpy(out, APPTOKEN_PREFIX, APPTOKEN_PREFIX_LEN);  out += APPTOKEN_PREFIX_LEN;
        memcpy(out, pNonce, nonceLen);                       out += nonceLen;
        memcpy(out, expiry_bytes, APPTOKEN_EXPIRY_LEN);      out += APPTOKEN_EXPIRY_LEN;
        write_be16(out, (uint16_t)siglen);                   out += APPTOKEN_SIGLEN_LEN;
        memcpy(out, sig, siglen);

        *pOutputLen = totalLen;
        if (logfn) logfn("SUCCESS: Generated signed apptoken of %u bytes "
                         "(prefix=%d, nonce=%u, expiry=8, siglen_field=2, sig=%zu)",
                         (unsigned int)totalLen, APPTOKEN_PREFIX_LEN,
                         (unsigned int)nonceLen, siglen);
        free(sig);
        rc = SQL_SUCCESS;
    }

cleanup:
    if (mdctx) EVP_MD_CTX_free(mdctx);
    free(dts);
    EVP_PKEY_free(pkey);
    return rc;
}
