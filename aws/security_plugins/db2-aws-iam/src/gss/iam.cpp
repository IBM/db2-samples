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
*  Source File Name = src/gss/iam.cpp           (%W%)
*
*  Descriptive Name = Server side GSS based authentication plugin code
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***********************************************************************/
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <curl/curl.h>

#include <dirent.h>

#include "AWSIAMauth.h"
#include "AWSIAMauthfile.h"
#include "iam.h"
#include "jwt.h"
#include "curl_response.h"
#include "../common/AWSIAMtrace.h"
#include "AWSUserPoolInfo.h"
#include "iam.h"
#include "utils.h"
#define MAX_STR_LEN 8192

#define MAX_STASH_FILE_PATH_LEN 255
#define MAX_AUTH_INFO_TYPE 6

int authType;



/*******************************************************************
*
*  Function Name     = initIAM
*
*  Descriptive Name  = Initialize IAM environment
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = None
*
*  Normal Return     = OK
*
*  Error Return      = INIT_FAIL
*
******************************************************************/
int initIAM(db2secLogMessage *logFunc)
{
  IAM_TRACE_ENTRY("initIAM");
  IAM_TRACE_EXIT("initIAM", 0);
  return 0;
}

/*******************************************************************
*
*  Function Name     = verify_access_token
*
*  Descriptive Name  = Validates various parameters of JWT token
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = authtoken, authtokenLen - IAM access token
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = authid, authIDLen - username and its length from JWT token
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = GSS_S_DEFECTIVE_TOKEN
*
******************************************************************/
OM_uint32 verify_access_token(const char *authtoken, size_t authtokenLen, char** authID, db2int32* authIDLen,
                              int authType, char* szIPAddress, OM_uint32 *minorStatus, db2secLogMessage *logFunc)
{
  OM_uint32 ret = GSS_S_COMPLETE;

  char* userPoolIDOfUser = NULL;
  char* iss = NULL;
  char* tokenInUse = NULL;
  char* exp = NULL;
  json_object* jwt_obj = NULL;
  
  size_t issLen = 0;
  size_t tokenInUseLen = 0;

  char* clientFieldInJWT = NULL;
  char* usernameFieldInJWT = NULL;

  ret = get_json_object_from_jwt(authtoken, authtokenLen, &jwt_obj, logFunc);

  if(ret != GSS_S_COMPLETE || jwt_obj == NULL)
  {
    *minorStatus = RETCODE_BADTOKEN;
    goto finish;
  }
  db2Log(DB2SEC_LOG_INFO, "Got json object from JWT ");

  tokenInUseLen = get_string_element_from_jwt(jwt_obj, "token_use", &tokenInUse, 32); // TODO: Remove hard-coding
  db2Log(DB2SEC_LOG_INFO, "Got token type as %s ", tokenInUse);
  if(tokenInUseLen == 0)
  {
    db2Log( DB2SEC_LOG_WARNING, "verify_access_token: Fail to get token_use parameter from %s with auth type (%s)", szIPAddress, authTypeToString[authType] );
    *minorStatus = RETCODE_BADTOKEN;
    IAM_TRACE_DATA("verify_access_token", "BAD_TOKEN");
    ret = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish;
  }
  if(strcmp(tokenInUse, "id") == 0){
    clientFieldInJWT = (char*) malloc(sizeof(char) * 4 );
    strcpy(clientFieldInJWT, "aud");
    clientFieldInJWT[3] = '\0';
    
    usernameFieldInJWT = (char*) malloc(sizeof(char) * 18 );
    strcpy(usernameFieldInJWT, "cognito:username");
    usernameFieldInJWT[17] = '\0';
  }
  else if (strcmp(tokenInUse, "access") == 0)
  {
    clientFieldInJWT = (char*) malloc(sizeof(char) * 11 );
    strcpy(clientFieldInJWT, "client_id");
    clientFieldInJWT[10] = '\0';
    
    usernameFieldInJWT = (char*) malloc(sizeof(char) * 10 );
    strcpy(usernameFieldInJWT, "username");
    usernameFieldInJWT[9] = '\0';
  }
  
  issLen = get_string_element_from_jwt(jwt_obj, "iss", &iss, DB2SEC_MAX_USERID_LENGTH);
  if(issLen == 0)
  {
    db2Log( DB2SEC_LOG_ERROR, "verify_access_token: Fail to get Issuer in access token from %s with auth type (%s)", szIPAddress, authTypeToString[authType] );
    *minorStatus = RETCODE_BADTOKEN;
    IAM_TRACE_DATA("verify_access_token", "BAD_TOKEN");
    ret = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish;
  }
  db2Log(DB2SEC_LOG_INFO, "Got issuer from JWT ");
  ret = validate_user_poolID(iss, &userPoolIDOfUser);
  if(ret != GSS_S_COMPLETE)
  {
    db2Log( DB2SEC_LOG_ERROR, "verify_access_token: Found invalid user pool ID of access token from %s with auth type (%s)", szIPAddress, authTypeToString[authType] );
    *minorStatus = RETCODE_BADTOKEN;
    IAM_TRACE_DATA("verify_access_token", "BAD_TOKEN");
    ret = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish; 
  }
  db2Log( DB2SEC_LOG_INFO, "Got userpoolID is verified");
  ret = verify_jwt_header(authtoken, authtokenLen, iss, logFunc);
  if(ret != GSS_S_COMPLETE)
  {
    db2Log( DB2SEC_LOG_ERROR, "verify_access_token: Invalid header signature of access token from %s with auth type (%s)", szIPAddress, authTypeToString[authType] );
    *minorStatus = RETCODE_BADTOKEN;
    IAM_TRACE_DATA("verify_access_token", "BAD_TOKEN");
    ret = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish; 
  }
  db2Log( DB2SEC_LOG_INFO, "Signature of JWT is verified");
  ret = validate_access_token_expiry(jwt_obj, minorStatus, logFunc);
  if( ret != GSS_S_COMPLETE )
  {
    IAM_TRACE_DATA("verify_access_token", "EXPIRED_TOKEN");
    *minorStatus = GSS_S_CREDENTIALS_EXPIRED;
    db2Log( DB2SEC_LOG_ERROR, "verify_access_token: Fail to authenticate an expired access token from %s with auth type (%s), ret = %d", szIPAddress, authTypeToString[authType], ret );
    // No need to set minorStatus and rc as validate_access_token_expiry takes care of them
    goto finish;
  }
  db2Log( DB2SEC_LOG_INFO, "Expiry time of JWT is verified");

  ret = validate_access_token_clientID(jwt_obj, clientFieldInJWT, userPoolIDOfUser, minorStatus, logFunc);
  if( ret != GSS_S_COMPLETE )
  {
    IAM_TRACE_DATA("verify_access_token", "INVALID_AUD or INVALID_CLIENTID");
    db2Log( DB2SEC_LOG_ERROR, "verify_access_token: Found invalid audience or client ID from access token from %s", szIPAddress );
    *minorStatus = RETCODE_BADTOKEN;
    ret = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish;
  }
  db2Log(DB2SEC_LOG_INFO, "ClientID is verified");
  
  *authIDLen = get_string_element_from_jwt(jwt_obj, usernameFieldInJWT, authID, DB2SEC_MAX_USERID_LENGTH);
  db2Log(DB2SEC_LOG_INFO, "AUTHID len is as %d ", *authIDLen);
  if( authIDLen == 0 )
  {
    IAM_TRACE_DATA("verify_access_token", "INVALID_AUD or INVALID_CLIENTID");
    db2Log( DB2SEC_LOG_ERROR, "verify_access_token: No username is found from access token from %s", szIPAddress );
    *minorStatus = RETCODE_BADTOKEN;
    ret = GSS_S_DEFECTIVE_CREDENTIAL;
  }
  db2Log(DB2SEC_LOG_INFO, "Got username as %s ", *authID);
  ret = GSS_S_COMPLETE;
  goto finish;
  
finish:
  if ( jwt_obj )
  {
    json_object_put(jwt_obj);
  }
  return ret;
}


/*******************************************************************
*
*  Function Name     = validate_access_token_expiry
*
*  Descriptive Name  = Extract access token expiry from given access token
*                      and compare with current system time
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = apikey/apikeyLen - IAM access token
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = minorStatus - minor status code
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = GSS_S_DEFECTIVE_TOKEN
*
******************************************************************/
OM_uint32 validate_access_token_expiry(const json_object* jwt_obj,
                                       OM_uint32 *minorStatus,
                                       db2secLogMessage *logFunc)
{
  db2Uint64 expiry = 0;
  time_t currentTime;
  char keyName[4] = "exp";
  OM_uint32 rc = GSS_S_COMPLETE;
  IAM_TRACE_ENTRY("validate_access_token_expiry");

  *minorStatus = RETCODE_OK;
  
  // Get access token expiry
  expiry = get_int64_element_from_jwt(jwt_obj, keyName);
  if (expiry == 0)
  {
    db2Log(DB2SEC_LOG_ERROR, "validate_access_token_expiry: Fail to get the token expiry");
    *minorStatus = RETCODE_BADTOKEN;
    rc = GSS_S_DEFECTIVE_TOKEN;
    return rc;
  }

  // Get current system time in seconds
  currentTime = time(NULL);

  // Compare access token expiry and current time
  if (currentTime >= expiry)
  {
    db2Log(DB2SEC_LOG_ERROR, "validate_access_token_expiry: access token has expired");
    *minorStatus = RETCODE_BADTOKEN;  // TODO: Check seg fault here due to db2Log
    rc = GSS_S_CREDENTIALS_EXPIRED;
  }

  return rc;
}

/*******************************************************************
*
*  Function Name     = validate_access_token_clientID
*
*  Descriptive Name  = Extract aud field from given access token
*                      and compare it with expected client IDs
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = authToken - IAM access token
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = minorStatus - minor status code
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = GSS_S_DEFECTIVE_TOKEN
*
******************************************************************/
OM_uint32 validate_access_token_clientID(const json_object* jwt_obj, const char* clientFieldInJWT,
                                    char* userPoolID,
                                    OM_uint32 *minor_status,
                                    db2secLogMessage *logFunc)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  char* audClientID = NULL;
  int audInTokenLen = 0;
  bool matched = false;
  char** clientIDs = NULL;
  size_t countOfClientIDs = 0;
  IAM_TRACE_ENTRY("validate_access_token_clientID");
  *minor_status = 0;

  audInTokenLen = get_string_element_from_jwt(jwt_obj, clientFieldInJWT, &audClientID, DB2SEC_MAX_USERID_LENGTH);

  if (audInTokenLen == 0)
  {
    db2Log(DB2SEC_LOG_ERROR, "validate_access_token_clientID: Fail to get the audience from access token\n");
    *minor_status = RETCODE_BADTOKEN;
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    IAM_TRACE_DATA("validate_access_token_clientID", "NO_SUB_IN_TOKEN");
    goto exit;
  }

  clientIDs = ListClientsForUserPool(userPoolID, &rc, &countOfClientIDs, logFunc);

  if (rc != GSS_S_COMPLETE)
  {
    db2Log(DB2SEC_LOG_ERROR, "validate_access_token_clientID: Failed to get ClientIDs from AWS\n");
    *minor_status = RETCODE_AWS_NO_USER_ATTRI;
    rc = GSS_S_FAILURE;
    IAM_TRACE_DATA("validate_access_token_clientID", "Failed to get ClientIDs from AWS");
    goto exit;
  }

  for ( size_t i = 0; i < countOfClientIDs; ++i )
  {
    if (clientIDs[i] && strncmp(clientIDs[i], audClientID, MAX_STR_LEN) == 0) 
    {
      rc = RETCODE_OK;
      matched = true;
      IAM_TRACE_DATA("validate_access_token_clientID: Matched ClientID with aud",  clientIDs[i]);
      break;
    }
  }
  if (! matched )
  {
    rc = GSS_S_DEFECTIVE_TOKEN;
    db2Log(DB2SEC_LOG_ERROR, "validate_access_token_clientID: Fail to get matching audience from access token\n");
    *minor_status = RETCODE_BADTOKEN;
  }

  goto exit;

exit: 
  IAM_TRACE_EXIT("validate_access_token_clientID",rc);
  if (clientIDs != NULL)
  {
     for(size_t j = 0; j < countOfClientIDs; ++j)
    {
        free(clientIDs[j]);
    }
  } 
  free(clientIDs);
  return rc;
}

size_t validate_user_poolID(const char* iss, char** poolID)
{
  size_t rc = RETCODE_OK;
  char* lastSlash = strrchr(const_cast<char*>(iss), '/');
  size_t NBytes = 0;
  
  bool matched = false;
  if(lastSlash == NULL)
  {
    rc = RETCODE_BADTOKEN;
    return rc;
  }

  NBytes = (iss + strlen(iss) - lastSlash + 1)/sizeof(char);
  *poolID = (char*)malloc(NBytes);

  //UserpoolID starts from last slash in the issuer's URL
  memcpy(*poolID, (lastSlash + (sizeof(char)*1)), NBytes);

  const char* configuredPoolID = read_userpool_from_cfg();

  if (configuredPoolID && strncmp(configuredPoolID, *poolID, MAX_STR_LEN) == 0) 
  {
    rc = RETCODE_OK;
    IAM_TRACE_DATA("read_userpool_from_cfg: Matched userpool ID",  *poolID);
  }
  else
  {
    rc = RETCODE_BADTOKEN;
  }
  return rc;
}
