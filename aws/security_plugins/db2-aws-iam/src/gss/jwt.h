/**************************************************************************
*
*  IBM CONFIDENTIAL
*  OCO SOURCE MATERIALS
*
*  COPYRIGHT:  P#2 P#1
*              (C) COPYRIGHT IBM CORPORATION 2023, 2024
*
*  The source code for this program is not published or otherwise divested of
*  its trade secrets, irrespective of what has been deposited with the U.S.
*  Copyright Office.
*
*  Source File Name = src/gss/jwt.h           (%W%)
*
*  Descriptive Name = Header file for JSON Web Token operation code (jwt.c)
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***************************************************************************/

#ifndef _JWT_H_
#define _JWT_H_

#include <openssl/bn.h>
#include <db2secPlugin.h>

#ifdef  __cplusplus
extern "C" {
#endif


int verify_signature(const char *jwt, size_t jwt_len, BIGNUM *mod, BIGNUM *exp, db2secLogMessage *logFunc);
OM_uint32 verify_jwt_header(const char *jwt, size_t jwt_len, char* iss, db2secLogMessage *logFunc);

OM_uint32 get_json_object_from_jwt(const char *jwt, size_t jwt_len, json_object** jwt_obj, db2secLogMessage *logFunc);
size_t get_string_element_from_jwt(const json_object* jwt_obj, const char * const element_name, char **res, size_t resMaxLen);
db2Uint64 get_int64_element_from_jwt(const json_object* jwt_obj, const char * const element_name);
char** jwt_get_payload_array_element(const json_object* jwt_obj, const char * const element_name, size_t* resLen);

#ifdef  __cplusplus
}
#endif

#endif
