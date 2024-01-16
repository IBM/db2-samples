/*****************************************************************************
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
*  Source File Name = src/gss/jwt.c           (%W%)
*
*  Descriptive Name = JSON Web Token operation code
*
*  Function: Retrieve JSON Web Token element by specifying the element name
*
*  Dependencies:
*
*  Restrictions:
*
*****************************************************************************/


#include <openssl/bio.h>
#include <openssl/evp.h>
#include <openssl/buffer.h>
#include <openssl/bn.h>
#include <openssl/rsa.h>

#include <string.h>
#include <assert.h>

#include <json-c/json.h>
#include "AWSIAMauthfile.h"
#include "../common/base64.h"
#include "jwk.h"
#include "jwt.h"
#include "AWSIAMauth.h"
#include "../common/AWSIAMtrace.h"

#define MAX_STR_LEN 8192

/****************************************************************************
*
*  Function Name     = get_json_object_from_jwt
*
*  Descriptive Name  = Parse and tokenize JWT to return json_object from it
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt/jwt_len - JSON Web Token
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = json_object from given JWT - jwt_obj 
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWT_ERR, JWT_RSA_ERR, JWT_RSA_KEY_ERR, etc.
*
*****************************************************************************/
OM_uint32 get_json_object_from_jwt(const char *jwt, size_t jwt_len, json_object** jwt_obj, db2secLogMessage *logFunc)
{
  char *start = NULL, *end = NULL;
  assert(jwt);
  char* json_body = NULL;
  size_t json_len = 0;
  json_tokener* tok = NULL;
  int ret = JWK_OK;

  /* decode body */
  start = memchr(jwt, '.', jwt_len);
  if( !start )
  {
    ret = JWT_ERR;
    goto exit;
  }
  ++start;

  end = memchr(start, '.', jwt_len - (start - jwt));
  if( !end )
  {
    ret = JWT_ERR;
    goto exit;
  }

  json_len = base64_decode(start, end - start, (unsigned char **)&json_body);
  if( !json_body )
  {
    ret = JWT_ERR;
    goto exit;
  }

  tok = json_tokener_new();
  if( !tok )
  {
    ret = JWT_ERR;
    goto exit;
  }

  *jwt_obj = json_tokener_parse_ex(tok, json_body, json_len);
  if (*jwt_obj == NULL)
  {
    ret = JWK_JSONTOKEN_ERR;
    goto exit;
  }

  return ret;

exit:
  if(json_body)  free(json_body);
  if(tok)  json_tokener_free(tok);
  return ret;
}
/****************************************************************************
*
*  Function Name     = verify_signature
*
*  Descriptive Name  = Validate JWT to have all the parameters in 
*                      proper conditions
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt/jwt_len - JSON Web Token
*                      BIGNUM mod/exp - A BIGNUM pointer to hold 
*                                       exponential and modulus of RSA key
*                                       THESE WILL BE DELETED
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = integer - Return code
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWT_ERR, JWT_RSA_ERR, JWT_RSA_KEY_ERR, etc.
*
*****************************************************************************/
int verify_signature(const char *jwt, size_t jwt_len, BIGNUM *mod, BIGNUM *exp, db2secLogMessage *logFunc)
{
  char *message = NULL;
  char *signature_encoded = NULL;
  size_t signature_len = 0;
  unsigned char *signature = NULL;
  int rc = JWK_OK;
  RSA *rsa = NULL;
  EVP_PKEY *key = NULL;
  EVP_MD_CTX *ctx = NULL;

  if ( jwt )
  { 
    message = strndup(jwt, jwt_len);
  }

  if ( !message ) 
  {
    rc = JWT_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR in jwt string\n");
    goto exit;
  }

  signature_encoded = strchr(message, '.');
  if ( !signature_encoded ) 
  {
    rc = JWT_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR in jwt string format\n");
    goto exit;
  }
  signature_encoded = strchr(signature_encoded + 1, '.');
  if ( !signature_encoded ) 
  {
    rc = JWT_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR in jwt string format\n");
    goto exit;
  }
  *signature_encoded++ = 0;

  signature_len = base64_decode(signature_encoded, 
      strnlen(signature_encoded, MAX_STR_LEN), 
      &signature);
  if ( signature_len == 0 || !(signature) ) 
  {
    rc = JWT_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR decoding jwt signature\n");
    goto exit;
  }
#ifdef DBG
  FILE *fp = fopen("/tmp/signature", "wb");
  fwrite(signature, signature_len, 1, fp);
  fclose(fp);
  fp = fopen("/tmp/message", "wb");
  fwrite(message, strlen(message), 1, fp);
  fclose(fp);
#endif

  rsa = RSA_new();
  if ( !rsa )
  {
    rc = JWT_RSA_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR creating RSA Object\n");    
    goto exit;
  }

#if defined(OPENSSL_1_1_0)
  if (RSA_set0_key(rsa, mod, exp, NULL) != 1) 
  {
    rc = JWT_RSA_KEY_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR setting RSA key components\n");
    goto exit;
  }
#else
  rsa->n = mod;
  rsa->e = exp;
#endif

  // Set these pointers to NULL as they are handled via RSA_free instead
  // after this point
  mod = NULL;
  exp = NULL;

  key = EVP_PKEY_new();
  if ( !key || EVP_PKEY_set1_RSA(key, rsa) != 1 ) 
  {
    rc = JWT_RSA_PRV_KEY_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR setting RSA Private key\n");
    goto exit;
  }

  ctx = EVP_MD_CTX_create();
  if ( !ctx ) 
  {
    rc = JWT_PRV_KEY_CTX_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR creating RSA Private key digest context(ctx) \n");
    goto exit;
  }

  if ( EVP_DigestVerifyInit(ctx, NULL, EVP_sha256(), NULL, key) != 1 )
  {
    rc = JWT_PRV_KEY_CTX_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR setting up RSA Private key digest context(ctx) \n");
    goto exit;
  }
  if ( EVP_DigestVerifyUpdate(ctx, message, strnlen(message,
          MAX_STR_LEN)) != 1 )
  {
    rc = JWT_PRV_KEY_CTX_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR hashing data with RSA Private key digest context(ctx) \n");
    goto exit;
  }
  if ( EVP_DigestVerifyFinal(ctx, signature, signature_len) != 1 ) 
  {
    rc = JWT_PRV_KEY_CTX_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_signature: ERROR failure to verify data in RSA Private key digest context(ctx) against the signature\n");
    goto exit;
  } 

exit:
  if ( signature ) 
  {
    free(signature);
  }
  if ( ctx ) 
  {
    EVP_MD_CTX_destroy(ctx);
  }
  if ( key ) 
  {
    EVP_PKEY_free(key);
  }
  if ( rsa ) 
  {
     RSA_free(rsa);
  }

  // This function has the responsibility to delete mod and exp
  if(NULL != mod)
  {
    BN_free(mod);
  }
  if(NULL != exp)
  {
    BN_free(exp);
  }

  if ( message )
  {
    free(message);
  }
  return rc;
}

/******************************************************************************
*
*  Function Name     = verify_jwt_header
*
*  Descriptive Name  = Validate JWT header format and its signature
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt/jwt_len - JSON Web Token
*                      logFunc - A pointer to the db2secLogMessage API
*                                for saving debugging messages in db2diag.log
*
*  Output            = Return code of type OM_uint32
*
*  Normal Return     = JWK_OK
*
*  Error Return      = JWK_EXP_ERR, JWK_MOD_ERR, JWT_BIGNUM_ERR, etc.
*
******************************************************************************/
OM_uint32 verify_jwt_header(const char *jwt, size_t jwt_len, char* iss, db2secLogMessage *logFunc)
{
  unsigned char *mod_bytes = NULL, *exp_bytes = NULL;
  size_t mod_len = 0, exp_len = 0;
  BIGNUM *mod_bn=NULL, *exp_bn=NULL;
  json_bool keyExists = FALSE;
  json_object *exp_obj = NULL;
  json_object *mod_obj = NULL;
  int rc = JWK_OK;

  json_object *jwk = NULL;
  mod_bn = BN_new();
  if(mod_bn == NULL)
  {
    rc = JWT_NO_BN_NEW_FAILED;
    goto exit; 
  }

  exp_bn = BN_new();
  if(exp_bn == NULL)
  {
    rc = JWT_NO_BN_NEW_FAILED;
    goto exit;
  }

  rc = get_jwk(jwt, jwt_len, iss, &jwk, logFunc);
  if ( rc != 0 )
  {
    goto exit;
  }

  keyExists = json_object_object_get_ex(jwk, "e", &exp_obj);
  if( !keyExists )
  {
    rc = JWK_EXP_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: encryption exponent e not found in jwk");
    goto exit;
  }

  keyExists = json_object_object_get_ex(jwk, "n", &mod_obj);
  if( !keyExists )
  {
    rc = JWK_MOD_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: modulus component n not found in jwk");
    goto exit;
  }

  mod_len = base64_decode(json_object_get_string(mod_obj),
      json_object_get_string_len(mod_obj),
      &mod_bytes);
  if (mod_len == 0)
  {
    rc = JWK_MOD_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: Error in modulus component of jwk, mod_len is 0");
    goto exit;
  }
  exp_len = base64_decode(json_object_get_string(exp_obj),
      json_object_get_string_len(exp_obj),
      &exp_bytes);
  if (exp_len == 0)
  {
    rc = JWK_EXP_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: Error in encryption exponent of jwk, exp_len is 0");
    goto exit;
  }

  if ( !BN_bin2bn(mod_bytes, mod_len, mod_bn) ) 
  {
    rc = JWT_BIGNUM_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: BIGNUM conversion failed for mod_len");
    goto exit;
  }

  if ( !BN_bin2bn(exp_bytes, exp_len, exp_bn) ) 
  {
    rc = JWT_BIGNUM_ERR;
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: BIGNUM conversion failed for exp_len");
    goto exit;  
  }

  rc = verify_signature(jwt, jwt_len, mod_bn, exp_bn, logFunc);

  // mod_bn and exp_bn are BN_free'd when RSA_free is called in verify_signature
  // See crypto/rsa/rsa_lib.c#L128
  // Set these to NULL so we don't double free
  mod_bn = NULL;
  exp_bn = NULL;

exit:
  if(NULL != mod_bn)
  {
     BN_free(mod_bn);
  }

  if(NULL != exp_bn)
  {
    BN_free(exp_bn);
  }

  if ( jwk )
  {
    json_object_put(jwk);
  }

  if( rc != 0 )
  {
    db2Log( DB2SEC_LOG_ERROR, "verify_jwt_header: Fail to get public key, rc = %d\n", rc );
  }
  return rc;
}

/******************************************************************************
*
*  Function Name     = get_string_element_from_jwt
*
*  Descriptive Name  = Get Value for given element_name from JWT object 
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt_obj - json_object*
*                      element_name - Name of the key element of the JWT object
*                      resMaxLen - the maximum length of element content.
*
*  Output            = res - element content
*
*  Normal Return     = element length which is greater than 0
*
*  Error Return      = 0
*
*******************************************************************************/
size_t get_string_element_from_jwt(const json_object* jwt_obj, const char * const element_name, char **res, size_t resMaxLen)
{
  json_bool keyExists = FALSE;
  json_object *element_obj = NULL;
  size_t resLen = 0;
  
  const char* element = NULL;
  int elementLen = 0;

  assert(element_name);
  assert(jwt_obj);
  
  keyExists = json_object_object_get_ex(jwt_obj, element_name, &element_obj);

  if( !keyExists || !json_object_is_type(element_obj, json_type_string) )
  { 
    printf("\n %s key of type string is not found \n", element_name);
    return 0;
  }

  // Get the element content
  element = json_object_get_string(element_obj);
  elementLen = json_object_get_string_len(element_obj);

  if( elementLen > 0 && elementLen <= resMaxLen )
  {
    *res = (char*)malloc( (elementLen+1) * sizeof(char));
    strcpy(*res, element);
    (*res)[elementLen] = '\0';
    resLen = elementLen;
  } 

  return resLen;
}

/******************************************************************************
*
*  Function Name     = get_int64_element_from_jwt
*
*  Descriptive Name  = Get integer value of given element_name from JWT
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt_obj - json_object*
*                      element_name - Name of the key element of the JWT object
*
*  Output            = element value of type db2Uint64
*
*  Normal Return     = element value
*
*  Error Return      = 0 if no conversion exists
*
*******************************************************************************/
db2Uint64 get_int64_element_from_jwt(const json_object* jwt_obj, const char * const element_name )
{
  json_bool keyExists = FALSE;
  json_object *element_obj;

  db2Uint64 element = 0;

  assert(jwt_obj);
  assert(element_name);

  keyExists = json_object_object_get_ex(jwt_obj, element_name, &element_obj);
  if( keyExists && json_object_is_type(element_obj, json_type_int) )
  {
    element = json_object_get_int64(element_obj);
  }
}

/******************************************************************************
*
*  Function Name     = jwt_get_payload_array_element
*
*  Descriptive Name  = Get JSON object from JWT associated with key element 
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = jwt_obj - json_object*
*                      element_name - Name of the key element of the JWT object
*
*  Output            = res - element content
*
*  Normal Return     = element length which is greater than 0
*
*  Error Return      = 0
*
*******************************************************************************/
char** jwt_get_payload_array_element(const json_object* jwt_obj, const char * const element_name, size_t* resLen)
{
  json_bool keyExists = FALSE;
  json_object *element_arr = NULL ;
 
  char** res = NULL;
  assert(jwt_obj);
  assert(element_name);
 
  keyExists = json_object_object_get_ex(jwt_obj, element_name, &element_arr);
  if( !keyExists || !json_object_is_type(element_arr, json_type_array) )
  {
    db2Log( DB2SEC_LOG_ERROR, "jwt_get_payload_array_element: Failed to retrieve array object for %s \n", element_name ); 
    goto finish;
  }
  
  *resLen = json_object_array_length(element_arr);

  res = (char **)malloc(*resLen * sizeof(char *)); 
  // Loop through array of keys and get the required values.
  for (size_t i = 0; i < *resLen; ++i) 
  {
    json_object *element = json_object_array_get_idx(element_arr, i);
    if ( !element ) 
    {
      continue;
    }
    const char* group = json_object_get_string(element);
    res[i] = (char *)malloc((strlen(group)+1) * sizeof(char)); 
    memset(res[i], '\0', strlen(group)+1);
    memcpy(res[i], group, strlen(group));
  }
  return res;

finish:
  return NULL;
}
