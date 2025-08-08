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
**  Source File Name = src/gss/jwk.c           (%W%)
**
**  Descriptive Name = JSON Web Key operation code
**
**  Function: Queries JSON Web Key Set and retrieves JSON Web key
**
**
*****************************************************************************/

#define _GNU_SOURCE
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/stat.h>
#include <curl/curl.h>
#include <json-c/json.h>
#include "AWSIAMauth.h"
#include "AWSIAMauthfile.h"
#include "../common/base64.h"
#include "curl_response.h"
#include "jwk.h"

#define MAX_STR_LEN 8192

/**************************************************************************************
*
*  Function Name     = jwt_kid
*
*  Descriptive Name  = Retrieve Key ID(kid) string from JWT
*
*  Dependencies      = 
*
*  Restrictions      =
*
*  Input             = jwt/jwt_len - JSON Web Token
*                      kid - Key ID, returned string needs to be freed for this variable
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            =
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWK_BADHEADER, JWK_JSONTOKEN_ERR, JWK_OBJ_ERR, etc.
*
****************************************************************************************/
static int jwt_kid(const char *jwt, size_t jwt_len, char** kid, db2secLogMessage *logFunc)
{
  char *end;
  char *json_header = NULL;
  size_t json_len = 0;
  json_tokener *tok = NULL;
  json_object *jwt_obj = NULL;
  json_object *kid_obj = NULL;
  int rc = JWK_OK;
  json_bool found = FALSE;
  const char *kid_str = NULL;
  assert(jwt);

  // Decode header 
  end = memchr(jwt, '.', jwt_len);
  if ( !end )
  {
    db2Log( DB2SEC_LOG_ERROR, "jwt_kid: error in jwk header format\n" );
    rc = JWK_BADHEADER;
    goto exit;
  }

  json_len = base64_decode(jwt, end - jwt, (unsigned char **)&json_header);
  if ( !json_header )
  {
    db2Log( DB2SEC_LOG_ERROR, "jwt_kid: error in jwk header format\n" );
    rc = JWK_BADHEADER;
    goto exit;
  }

  tok = json_tokener_new();
  if ( !tok )
  {
    free(json_header);
    db2Log( DB2SEC_LOG_ERROR, "jwt_kid: failed to create JSON token\n" );
    rc = JWK_JSONTOKEN_ERR;
    goto exit;
  }

  jwt_obj = json_tokener_parse_ex(tok, json_header, json_len);
  free(json_header);

  if ( !jwt_obj )
  {
    json_tokener_free(tok);
    db2Log( DB2SEC_LOG_ERROR, "jwt_kid: failed to parse JSON token\n" );
    rc = JWK_JSONTOKEN_ERR;
    goto exit;
  }
  // Retrieve the key id from the jwt object.
  found = json_object_object_get_ex(jwt_obj, "kid", &kid_obj);
  json_tokener_free(tok);
  if ( !found )
  {
    db2Log( DB2SEC_LOG_ERROR, "jwt_kid: failed to retrieve kid object from jwt\n" );
    rc = JWK_OBJ_ERR;
    goto exit;
  }
  // Extract the key string.
  kid_str = json_object_get_string(kid_obj);
  if( kid_str )
  {
    *kid = strndup(kid_str, MAX_STR_LEN);
  }

exit:
  if ( rc != JWK_OK )
  {
    *kid = NULL;
  }
  if ( jwt_obj )
  {
    json_object_put(jwt_obj);
  }
  return rc;
}

/*****************************************************************************
*
*  Function Name     = query_jwks
*
*  Descriptive Name  = Retrieve JSON Web Key Set
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwk_url - JWKS(JSON Web Key Set)  location
*                      jwks_ptr - pointer to jwks (this variable must be 
*                                 freed by a caller)
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            =
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWK_CURLE_FAIL, JWK_CURLE_RES_FAIL, etc.
*
******************************************************************************/
int query_jwks(const char *jwk_url, char** jwks_json_ptr, db2secLogMessage *logFunc)
{
  int rc = JWK_OK;
  struct write_buf response_body = { 0 };
  CURL *curl = curl_easy_init();
  long http_code = 0;
  CURLcode res = CURLE_OK;

  response_body.ptr = NULL;
  if ( !curl ) 
  {
    db2Log( DB2SEC_LOG_ERROR, "query_jwks: Failed to initialize CURLE\n" ); 
    rc = JWK_CURLE_INIT_ERR;
    goto exit;  
  }
  // Perform CURL operation to get JSON Web Keys.
  curl_easy_setopt(curl, CURLOPT_VERBOSE, 0L);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  //curl_easy_setopt(curl, CURLOPT_CAPATH, "/etc/ssl/certs/");
  curl_easy_setopt(curl, CURLOPT_URL, jwk_url);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&response_body);
  curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);

  res = curl_easy_perform(curl);
  if (res != CURLE_OK)
  {
    rc = JWK_CURLE_FAIL;
    db2Log( DB2SEC_LOG_ERROR, "query_jwks: Failed to perform CURLE operation\n" );
    goto exit;
  }

  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
  if (http_code != 200 || !response_body.ptr) 
  {
    db2Log( DB2SEC_LOG_ERROR, "query_jwks: Failed to receive CURLE operation response\n" ); 
    rc = JWK_CURLE_RES_FAIL;
    goto exit;
  }
  *jwks_json_ptr = response_body.ptr;
exit:
  if ( rc != 0 )
  {
    if (response_body.ptr) 
     {
       free(response_body.ptr);
     }
    *jwks_json_ptr = NULL;
  }
  curl_easy_cleanup(curl);
  return rc;
}

/*****************************************************************************
*
*  Function Name     = find_jwk_by_kid
*
*  Descriptive Name  = Retrieve JWK from JWKS using kid(Key ID)
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwks_json - JSON Web Key Set 
*                      kid - kid (Key ID) string
                       jwk_ptr - pointer to JWK Object
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            =
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWK_JSONTOKEN_ERR, JWK_OBJ_ERR, etc.
*
******************************************************************************/
static int find_jwk_by_kid(const char *jwks_json, const char *kid, json_object** jwk_ptr, db2secLogMessage *logFunc)
{
  int rc = JWK_OK;
  json_object *keys_arr = NULL;
  json_object *jwks_obj = NULL;
  json_bool found  = FALSE;
  int i = 0;
  int keys_nr = 0;
  assert(jwks_json);
  assert(kid);

  jwks_obj = json_tokener_parse(jwks_json);
  if ( !jwks_obj ) 
  {
    rc = JWK_JSONTOKEN_ERR;
    db2Log( DB2SEC_LOG_ERROR, "find_jwk_by_kid: Failed to parse jwks JSON token\n" );
    goto exit;
  }

  found = json_object_object_get_ex(jwks_obj, "keys", &keys_arr);
  if ( !found )
  {
    rc = JWK_OBJ_ERR;
    db2Log( DB2SEC_LOG_ERROR, "find_jwk_by_kid: Failed to retrieve keys array object\n" );
    goto exit;
  }

  keys_nr = json_object_array_length(keys_arr);
  // Loop through array of keys and get the required key corresponding to the kid.
  for (i = 0; i < keys_nr; ++i) 
  {
    json_object *kid_obj = NULL;
     const char *kid_str = NULL;
    json_object *key_obj = json_object_array_get_idx(keys_arr, i);
    if ( !key_obj ) 
    {
      continue;
    }
    found = json_object_object_get_ex(key_obj, "kid", &kid_obj);
    if ( !found )
    {
      continue;
    }
    kid_str = json_object_get_string(kid_obj);
    if (kid_str && strncmp(kid_str, kid, MAX_STR_LEN) == 0) 
    {
      json_object_get(key_obj);
      *jwk_ptr = key_obj;
      break;
    }
  }
  // Check for key being not found in jwks.
  if ( i == keys_nr )
  {
    rc = JWK_NOT_FND;
    db2Log( DB2SEC_LOG_ERROR, "find_jwk_by_kid: Kid %s not found.\n", kid );
  }  

exit:
  if ( rc != 0 )
  {
    *jwk_ptr = NULL;
  }
  if ( jwks_obj )
  { 
    json_object_put(jwks_obj);
  }
  return rc;
}

/****************************************************************************
*
*  Function Name     = get_jwk
*
*  Descriptive Name  = Retrieve JWK from JWT
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt/jwt_len - JSON Web Token
*                      jwk_ptr - A pointer to JWK object
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            =
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWK_BADHEADER, JWK_JSONTOKEN_ERR, JWK_OBJ_ERR, etc.
*
*****************************************************************************/
int get_jwk(const char *jwt, size_t jwt_len, const char* iss, json_object** jwk_ptr, db2secLogMessage *logFunc)
{
  int rc = JWK_OK;
  char *kid = NULL;
  static char *jwks_json = NULL;
  json_object *jwk = NULL;
  char *db2_home = getenv( "DB2_HOME" ); 

  assert(jwt);
  // Get the key id (kid) string for the corresponding jwk.
  rc = jwt_kid(jwt, jwt_len, &kid, logFunc);
  if ( rc != 0 )
  {
    goto cleanup;
  }
  if(jwks_json == NULL)
  { 
    // Get the jwks.
    if( db2_home != NULL && iss != NULL )
    {      
      char keysURL[256];
      sprintf( keysURL, "%s/.well-known/jwks.json", iss);
      rc = query_jwks(keysURL, &jwks_json, logFunc);
      if ( rc != 0 )
      {
         if(jwks_json != NULL)
         {
            free(jwks_json);
            jwks_json = NULL;
         }
         goto cleanup;
      }
    }
  }  
  // Find the required jwk from jwks using the key id string.
  rc = find_jwk_by_kid(jwks_json, kid, jwk_ptr, logFunc);
  if ( rc != 0 )
  {
    free(jwks_json);
    jwks_json = NULL;

    goto cleanup;
  }

cleanup:
  if (kid)
  {
     free(kid);
  }

  if ( rc != 0 )
  {
    jwk = NULL;
    db2Log( DB2SEC_LOG_ERROR, "get_jwk: get_jwk failed with error code %d\n", rc );
  }
  return rc;
}
