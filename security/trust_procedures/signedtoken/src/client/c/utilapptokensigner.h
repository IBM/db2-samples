/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/******************************************************************************
** Source File Name: utilapptokensigner.h
**
** Description     : Public interface for the shared apptoken signing utility.
**
**                   Include this header in demolibapptokengen.c and
**                   demoembeddedconnect.c.
*******************************************************************************/

#ifndef UTILAPPTOKENSIGNER_H
#define UTILAPPTOKENSIGNER_H

#include "db2ApiDf.h"
#include "sqlcli.h"
#include <stdarg.h>

/*
 * utilapptokensigner_logfn_t — optional logging callback.
 * Implementations may pass NULL to suppress logging.
 */
typedef void (*utilapptokensigner_logfn_t)(const char *fmt, ...);

/*
 * utilapptokensigner_build — build and sign an apptoken from the given nonce.
 *
 * Parameters:
 *   pNonce      — raw nonce bytes received from the server (input)
 *   nonceLen    — byte count of pNonce
 *   pOutput     — caller-supplied buffer to receive the assembled token (output)
 *   pOutputLen  — in: byte capacity of pOutput; out: bytes written on success
 *   logfn       — optional log callback; pass NULL to suppress all logging
 *
 * Returns SQL_SUCCESS (0) on success, SQL_ERROR (-1) on failure.
 */
int utilapptokensigner_build(
    const unsigned char         *pNonce,
    sqluint32                    nonceLen,
    unsigned char               *pOutput,
    sqluint32                   *pOutputLen,
    utilapptokensigner_logfn_t   logfn);

#endif /* UTILAPPTOKENSIGNER_H */
