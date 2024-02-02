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
**  Source File Name = src/gss/jwt.h           (%W%)
**
**  Descriptive Name = JSON Web Token operation code
**
**  Function: This code contains functions that retrieves various types of data from given json object.
              It also has functions that validates header and signature of the JWT.
**
**
*****************************************************************************/

#ifndef _JWT_H_
#define _JWT_H_

#include <openssl/bn.h>
#include <db2secPlugin.h>

#ifdef  __cplusplus
extern "C" {
#endif


int verify_signature(const char *jwt, size_t jwt_len, BIGNUM *mod, BIGNUM *exp, db2secLogMessage *logFunc);
OM_uint32 verify_jwt_header_and_signature(const char *jwt, size_t jwt_len, char* iss, db2secLogMessage *logFunc);

OM_uint32 get_json_object_from_jwt(const char *jwt, size_t jwt_len, json_object** jwt_obj, db2secLogMessage *logFunc);
size_t get_string_element_from_jwt(const json_object* jwt_obj, const char * const element_name, char **res, size_t resMaxLen);
db2Uint64 get_int64_element_from_jwt(const json_object* jwt_obj, const char * const element_name);
char** jwt_get_payload_array_element(const json_object* jwt_obj, const char * const element_name, size_t* resLen);

#ifdef  __cplusplus
}
#endif

#endif
