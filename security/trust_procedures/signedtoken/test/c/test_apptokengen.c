/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/*
 * test_apptokengen.c — unit tests for the signed apptoken generation logic
 * in utilapptokensigner.c, exercised via demolibapptokengen.c.
 *
 * Compiles both source files directly (not as a shared library) so the
 * internal logic can be exercised without loading a .so.  No database
 * connection is required; the tests only need
 * $HOME/trustproc_keys/{private,public}.pem.
 *
 * Token format under test:
 *   PREFIX   : "TRUSTCALLBACK"                 13 bytes
 *   NONCE    : raw nonce bytes                  nonceLen bytes
 *   EXPIRY   : big-endian int64 (now + 60 s)    8 bytes
 *   SIGLEN   : big-endian uint16                2 bytes
 *   SIG      : RSA-2048/SHA-256 signature       256 bytes
 *
 * Build and run (from signedtoken/):
 *   make c_unit_test
 *
 * Exit code: 0 if all tests pass, 1 if any test fails.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <openssl/evp.h>
#include <openssl/pem.h>

#include "demolibapptokengen.c"

/* -------------------------------------------------------------------------
 * Token layout constants (must match utilapptokensigner.c)
 * ------------------------------------------------------------------------- */
#define TC_PREFIX_LEN   13
#define TC_EXPIRY_LEN    8
#define TC_SIGLEN_LEN    2
#define TC_SIG_LEN     256   /* RSA-2048 always produces 256 bytes */

/* Minimum total length for a valid token with a 1-byte nonce */
#define TC_MIN_LEN (TC_PREFIX_LEN + 1 + TC_EXPIRY_LEN + TC_SIGLEN_LEN + TC_SIG_LEN)

/* -------------------------------------------------------------------------
 * Minimal test harness
 * ------------------------------------------------------------------------- */

static int g_passed = 0;
static int g_failed = 0;

static void check(const char *name, int condition)
{
    if (condition) {
        printf("  PASS: %s\n", name);
        g_passed++;
    } else {
        printf("  FAIL: %s\n", name);
        g_failed++;
    }
}

/* -------------------------------------------------------------------------
 * Helper: read a big-endian uint64 from buf[0..7]
 * ------------------------------------------------------------------------- */
static uint64_t read_be64(const unsigned char *buf)
{
    return ((uint64_t)buf[0] << 56) | ((uint64_t)buf[1] << 48) |
           ((uint64_t)buf[2] << 40) | ((uint64_t)buf[3] << 32) |
           ((uint64_t)buf[4] << 24) | ((uint64_t)buf[5] << 16) |
           ((uint64_t)buf[6] <<  8) |  (uint64_t)buf[7];
}

/* -------------------------------------------------------------------------
 * Helper: read a big-endian uint16 from buf[0..1]
 * ------------------------------------------------------------------------- */
static uint16_t read_be16(const unsigned char *buf)
{
    return (uint16_t)(((uint16_t)buf[0] << 8) | (uint16_t)buf[1]);
}

/* -------------------------------------------------------------------------
 * Helper: verify the RS256 signature in a token using the public key.
 *
 * Parses the token assuming nonce is exactly 'nonce_len' bytes, then
 * verifies the signature over (PREFIX || NONCE || EXPIRY) with public.pem.
 * Returns 1 on verified, 0 on failure.
 * ------------------------------------------------------------------------- */
static int verify_token_sig(const unsigned char *tok, unsigned int total,
                             unsigned int nonce_len)
{
    if (total != (unsigned int)(TC_PREFIX_LEN + nonce_len + TC_EXPIRY_LEN
                                + TC_SIGLEN_LEN + TC_SIG_LEN))
        return 0;

    const unsigned char *sig_ptr      = tok + total - TC_SIG_LEN;
    const unsigned char *siglen_ptr   = sig_ptr - TC_SIGLEN_LEN;
    const unsigned char *expiry_ptr   = siglen_ptr - TC_EXPIRY_LEN;

    uint16_t siglen = read_be16(siglen_ptr);
    if (siglen != TC_SIG_LEN)
        return 0;

    /* Load public key */
    char home_buf[512];
    const char *home = getenv("HOME");
    if (!home) return 0;
    snprintf(home_buf, sizeof(home_buf), "%s/trustproc_keys/public.pem", home);

    FILE *kf = fopen(home_buf, "r");
    if (!kf) return 0;
    EVP_PKEY *pkey = PEM_read_PUBKEY(kf, NULL, NULL, NULL);
    fclose(kf);
    if (!pkey) return 0;

    /* Build data-to-verify: PREFIX || NONCE || EXPIRY */
    unsigned int dts_len = TC_PREFIX_LEN + nonce_len + TC_EXPIRY_LEN;
    unsigned char *dts = malloc(dts_len);
    if (!dts) { EVP_PKEY_free(pkey); return 0; }
    memcpy(dts,                              tok,        TC_PREFIX_LEN);
    memcpy(dts + TC_PREFIX_LEN,              tok + TC_PREFIX_LEN, nonce_len);
    memcpy(dts + TC_PREFIX_LEN + nonce_len,  expiry_ptr, TC_EXPIRY_LEN);

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    int ok = 0;
    if (ctx &&
        EVP_DigestVerifyInit(ctx, NULL, EVP_sha256(), NULL, pkey) == 1 &&
        EVP_DigestVerifyUpdate(ctx, dts, dts_len) == 1 &&
        EVP_DigestVerifyFinal(ctx, sig_ptr, (size_t)siglen) == 1)
        ok = 1;

    if (ctx) EVP_MD_CTX_free(ctx);
    free(dts);
    EVP_PKEY_free(pkey);
    return ok;
}

/* -------------------------------------------------------------------------
 * TC1: Normal case — 16-byte nonce (typical Db2 nonce length).
 * ------------------------------------------------------------------------- */
static void tc1_normal_nonce(void)
{
    unsigned char nonce[16] = {
        0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,
        0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10
    };
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = sizeof(nonce);

    printf("\n[ TC1: normal 16-byte nonce ]\n");

    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    check("apptokengen_callback return code = SQL_SUCCESS", rc == SQL_SUCCESS);

    unsigned int expected_len = TC_PREFIX_LEN + 16 + TC_EXPIRY_LEN
                                + TC_SIGLEN_LEN + TC_SIG_LEN;
    check("output length = prefix+nonce+expiry+siglen+sig",
          outputLen == expected_len);
    check("output starts with TRUSTCALLBACK",
          memcmp(output, "TRUSTCALLBACK", TC_PREFIX_LEN) == 0);
    check("nonce bytes at offset 13 are verbatim",
          memcmp(output + TC_PREFIX_LEN, nonce, 16) == 0);
    check("SIGLEN field == 256",
          read_be16(output + TC_PREFIX_LEN + 16 + TC_EXPIRY_LEN) == TC_SIG_LEN);
    check("signature verifies with public key",
          verify_token_sig(output, outputLen, 16));
}

/* -------------------------------------------------------------------------
 * TC2: Single-byte nonce — boundary case for minimum valid nonce.
 * ------------------------------------------------------------------------- */
static void tc2_single_byte_nonce(void)
{
    unsigned char nonce[1] = { 0xAB };
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = 1;

    printf("\n[ TC2: single-byte nonce ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    check("return code = SQL_SUCCESS", rc == SQL_SUCCESS);

    unsigned int expected_len = TC_PREFIX_LEN + 1 + TC_EXPIRY_LEN
                                + TC_SIGLEN_LEN + TC_SIG_LEN;
    check("output length = prefix+1+expiry+siglen+sig",
          outputLen == expected_len);
    check("nonce byte at offset 13 = 0xAB",
          output[TC_PREFIX_LEN] == 0xAB);
    check("signature verifies",
          verify_token_sig(output, outputLen, 1));
}

/* -------------------------------------------------------------------------
 * TC3: All-zero nonce bytes — must not be treated as empty.
 * ------------------------------------------------------------------------- */
static void tc3_zero_nonce_bytes(void)
{
    unsigned char nonce[16];
    memset(nonce, 0x00, sizeof(nonce));
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = sizeof(nonce);

    printf("\n[ TC3: nonce bytes are all zero ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    check("return code = SQL_SUCCESS", rc == SQL_SUCCESS);

    unsigned int expected_len = TC_PREFIX_LEN + 16 + TC_EXPIRY_LEN
                                + TC_SIGLEN_LEN + TC_SIG_LEN;
    check("output length correct",  outputLen == expected_len);
    check("prefix correct",         memcmp(output, "TRUSTCALLBACK", TC_PREFIX_LEN) == 0);
    check("nonce is 16 zero bytes", memcmp(output + TC_PREFIX_LEN, nonce, 16) == 0);
    check("signature verifies",     verify_token_sig(output, outputLen, 16));
}

/* -------------------------------------------------------------------------
 * TC4: High (>0x7F) nonce bytes — confirms no encoding transformation.
 * ------------------------------------------------------------------------- */
static void tc4_high_byte_nonce(void)
{
    unsigned char nonce[4] = { 0x80, 0xFF, 0xC0, 0xDE };
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = sizeof(nonce);

    printf("\n[ TC4: nonce contains high (>0x7F) bytes ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    check("return code = SQL_SUCCESS",    rc == SQL_SUCCESS);
    check("nonce bytes verbatim",    memcmp(output + TC_PREFIX_LEN, nonce, 4) == 0);
    check("signature verifies",      verify_token_sig(output, outputLen, 4));
}

/* -------------------------------------------------------------------------
 * TC5: Expiry field is in the future (within [1 s, 61 s] from now).
 * ------------------------------------------------------------------------- */
static void tc5_expiry_in_future(void)
{
    unsigned char nonce[8] = {0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88};
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = sizeof(nonce);

    printf("\n[ TC5: expiry is in the future ]\n");
    time_t before = time(NULL);
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    time_t after  = time(NULL);
    check("return code = SQL_SUCCESS", rc == SQL_SUCCESS);

    /* Locate the EXPIRY field: bytes [13+8 .. 13+8+8-1] */
    const unsigned char *expiry_ptr = output + TC_PREFIX_LEN + 8 /* nonceLen */;
    uint64_t expiry = read_be64(expiry_ptr);
    check("expiry > current time",  (uint64_t)after  < expiry);
    check("expiry <= now + 61 s",   expiry <= (uint64_t)before + 61);
}

/* -------------------------------------------------------------------------
 * TC6: NULL pParmStruct — must return SQL_ERROR, not crash.
 * ------------------------------------------------------------------------- */
static void tc6_null_parm_struct(void)
{
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    printf("\n[ TC6: NULL pParmStruct ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, NULL, output, &outputLen);
    check("return code = SQL_ERROR", rc == SQL_ERROR);
}

/* -------------------------------------------------------------------------
 * TC7: NULL pNonce inside the param struct — must return SQL_ERROR.
 * ------------------------------------------------------------------------- */
static void tc7_null_nonce_pointer(void)
{
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = NULL;
    parm.nonceLen = 16;

    printf("\n[ TC7: NULL pNonce pointer ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    check("return code = SQL_ERROR", rc == SQL_ERROR);
}

/* -------------------------------------------------------------------------
 * TC8: Zero nonceLen — must return SQL_ERROR.
 * ------------------------------------------------------------------------- */
static void tc8_zero_nonce_len(void)
{
    unsigned char nonce[16] = {0};
    unsigned char output[32672];
    sqluint32     outputLen = sizeof(output);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = 0;

    printf("\n[ TC8: zero nonceLen ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, output, &outputLen);
    check("return code = SQL_ERROR", rc == SQL_ERROR);
}

/* -------------------------------------------------------------------------
 * TC9: NULL output buffer — must return SQL_ERROR.
 * ------------------------------------------------------------------------- */
static void tc9_null_output_buffer(void)
{
    unsigned char nonce[16] = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,
                               0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10};
    sqluint32 outputLen = 32672;

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = sizeof(nonce);

    printf("\n[ TC9: NULL output buffer ]\n");
    SQL_API_RC rc = apptokengen_callback(0, NULL, &parm, NULL, &outputLen);
    check("return code = SQL_ERROR", rc == SQL_ERROR);
}

/* -------------------------------------------------------------------------
 * TC10: Two tokens from the same nonce — both signatures must be valid.
 * ------------------------------------------------------------------------- */
static void tc10_two_tokens_both_valid(void)
{
    unsigned char nonce[16] = {0xDE,0xAD,0xBE,0xEF,0xCA,0xFE,0xBA,0xBE,
                               0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08};
    unsigned char out1[32672], out2[32672];
    sqluint32     len1 = sizeof(out1), len2 = sizeof(out2);

    ApptokengenParamStruct parm;
    memset(&parm, 0, sizeof(parm));
    parm.pNonce   = nonce;
    parm.nonceLen = sizeof(nonce);

    printf("\n[ TC10: two consecutive tokens are both valid ]\n");
    SQL_API_RC rc1 = apptokengen_callback(0, NULL, &parm, out1, &len1);
    SQL_API_RC rc2 = apptokengen_callback(0, NULL, &parm, out2, &len2);

    check("first token rc = SQL_SUCCESS",  rc1 == SQL_SUCCESS);
    check("second token rc = SQL_SUCCESS", rc2 == SQL_SUCCESS);
    check("first token sig valid",         verify_token_sig(out1, len1, 16));
    check("second token sig valid",        verify_token_sig(out2, len2, 16));
}

/* -------------------------------------------------------------------------
 * Entry point
 * ------------------------------------------------------------------------- */

int main(void)
{
    printf("=== test_apptokengen ===\n");

    tc1_normal_nonce();
    tc2_single_byte_nonce();
    tc3_zero_nonce_bytes();
    tc4_high_byte_nonce();
    tc5_expiry_in_future();
    tc6_null_parm_struct();
    tc7_null_nonce_pointer();
    tc8_zero_nonce_len();
    tc9_null_output_buffer();
    tc10_two_tokens_both_valid();

    printf("\n---\n");
    printf("Results: %d passed, %d failed\n", g_passed, g_failed);
    return g_failed > 0 ? 1 : 0;
}
