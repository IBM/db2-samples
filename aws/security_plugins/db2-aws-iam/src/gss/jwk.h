/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2024
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
**********************************************************************************
**
**  Source File Name = src/gss/jwk.h           (%W%)
**
**  Descriptive Name = Header file for JSON Web Key operation code (jwk.c)
**
**  Function: Queries JSON Web Key Set and retrieves JSON Web key
**
**
***************************************************************************/

#ifndef _JWK_H_
#define _JWK_H_
#include <json-c/json.h>
#include <db2secPlugin.h>

#define JWK_OK                  0   /* Operation completed successfully */
#define JWK_BADHEADER           1   /* JWK has bad header format */
#define JWK_JSONTOKEN_ERR       2   /* ERROR in JSON TOKEN */
#define JWK_CURLE_INIT_ERR      3   /* Failure in Initializing CURL */
#define JWK_CURLE_FAIL          4   /* CURL Operation failure */
#define JWK_CURLE_RES_FAIL      5   /* Failure in reception of CURL operation */
#define JWK_OBJ_ERR             6   /* ERROR in JWK Object */
#define JWK_NOT_FND             7   /* JWK not found in JWKS */
#define JWK_MOD_ERR             8   /* Modulus component not found in jwk */
#define JWK_EXP_ERR             9   /* Encryption component not found in jwk */ 
#define JWT_BIGNUM_ERR         10   /* BIGNUM conversion failure */
#define JWT_ERR                11   /* ERROR in JWT */
#define JWT_RSA_ERR            12   /* RSA Object ERROR */ 
#define JWT_RSA_KEY_ERR        13   /* RSA Key ERROR */
#define JWT_RSA_PRV_KEY_ERR    14   /* RSA private key ERROR */
#define JWT_PRV_KEY_CTX_ERR    15   /* RSA private key digest context ERROR */
#define JWT_NO_BN_NEW_FAILED   16   /* Error getting new BIGNUMBER */
int get_jwk(const char *jwt, size_t jwt_len, const char* iss, json_object** jwk_ptr, db2secLogMessage *logFunc);
int query_jwks(const char *jwk_url, char** jwks_json_ptr, db2secLogMessage *logFunc);
#endif

