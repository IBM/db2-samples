/**********************************************************************
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
*  Source File Name = src/gss/iam.h           (%W%)
*
*  Descriptive Name = Header file for the Server side GSS based authentication 
*                     plugin code (iam.cpp)
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***********************************************************************/

#ifndef _IAM_H_
#define _IAM_H_

#include <stddef.h>
#include <db2secPlugin.h>
#include <json-c/json.h>

#define OK                                0
#define INIT_FAIL                         1
#define SET_HEADER_FAIL                   2
#define ENCODE_FAIL                       3
#define CONSTRUCT_BODY_FAIL               4
#define CURL_FAIL                         5
#define VERIFICATION_FAIL                 6
#define GET_PASSWORD_FROM_STASH_FAIL      7
#define DB2_HOME_NOT_DEFINED              8
#define CONSTRUCT_BEARER_FAIL 10
#define DB2SEC_AUTH_MODE_IAM              11   // Authenticate using IAM

#define URL_MAX_LEN                       255
#define REST_API_PORT                     9999

//#define REST_API_NAME                     "ext-auth-rest"
#define REST_API_NAME                     "localhost"


extern int authType;
#ifdef  __cplusplus
extern "C" {
#endif

int initIAM(db2secLogMessage *logFunc);
OM_uint32 verify_access_token(const char *authtoken, size_t authtokenLen, char** authID, db2int32* authIDLen,
                              int authType, char* szIPAddress, OM_uint32 *minorStatus, db2secLogMessage *logFunc);
OM_uint32 validate_access_token_expiry(const json_object *jwt_obj, OM_uint32 *minorStatus, db2secLogMessage *logFunc);
OM_uint32 validate_access_token_clientID(const json_object *jwt_obj, const char* clientFieldInJWT, char* userPoolID, OM_uint32 *minorStatus, db2secLogMessage *logFunc);
size_t validate_user_poolID(const char* iss, char** poolID);

#ifdef  __cplusplus
}
#endif

#define MAX_STASH_BUFFER_LEN 255

#endif