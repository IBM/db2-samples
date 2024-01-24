/*******************************************************************************
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
*  Source File Name = src/gss/AWSIAMauthserver.c
*
*  Descriptive Name = Server side plugin that validates the AWS cognito user with accesstoken
*
*  Function: Implements functions required by Db2 server plugin architeture
*            This plugin is meant to be used with AWS IAM security plugin.
*
*            With AWS IAM security plugin in place, when the AWS user uses an access token
*            retrieved from AWS cognito for Db2 authentication, this plugin will validate all the 
*            parameters from the provided JWT token and allows user to connect to Db2 only if the token
*            passes all the validity checks. 
*
*
*  Dependencies: User should be part of the Cognito userpool which is configured in a config file named 
*                ~/sqllib/security64/plugin/cfg/cognito_userpools.json. This is the default file location.
*                One can override this location with the means of environment variable AWS_USERPOOL_CFG_ENV.
*
*  Restrictions: The config file mentioned above supports only one userpool, which means user authenticating 
*                to Db2 can be part of only configured userpool. 
*
*
*******************************************************************************/

#include <assert.h>
#include <json-c/json.h>
#include <stdbool.h>
#include <time.h>
#include <openssl/sha.h>
#include <stdlib.h>

#include "AWSIAMauth.h"
#include <db2secPlugin.h>
#include "../common/base64.h"
#include "iam.h"
#include "jwt.h"
#include "AWSIAMauthfile.h"
#include "../common/AWSIAMtrace.h"
#include "AWSUserPoolInfo.h"
#include "utils.h"
 CRED_T serverCred = {0, sizeof(PRINCIPAL_NAME)-1, PRINCIPAL_NAME, 0, ""};

 
static db2secGetConDetails *getConDetails;

OM_uint32 getClientIPAddress(char szIPAddress[], int maxLength)
{
  struct db2sec_con_details_3 conDetails;
  SQL_API_RC ret = DB2SEC_PLUGIN_OK;
  unsigned char * pIpAddress = NULL;
  int length = 0;
  IAM_TRACE_ENTRY("getClientIPAddress");

  
  // Obtain details about the client that is trying to attempt to have a database connection
  ret = (getConDetails)(DB2SEC_CON_DETAILS_VERSION_3, &conDetails);
  if ( ret != 0 )
  {
    db2Log( DB2SEC_LOG_ERROR, "The database connection does not exist and needs to be started, ret = %d", ret );
    ret = GSS_S_UNAVAILABLE;
    goto finish;
  }

  // To fetch the client IP address which is in decimal format and convert it to a string
  pIpAddress = (unsigned char *) &conDetails.clientIPAddress;

  // To print the IP address and store it in a variable
  length = snprintf( szIPAddress, maxLength, "%u.%u.%u.%u", pIpAddress[0], pIpAddress[1], pIpAddress[2], pIpAddress[3] );
  if( length <= 0 || length >= maxLength )
  {
    db2Log( DB2SEC_LOG_ERROR, "The client IP address (length = %d) is too long", length );
    ret = GSS_S_UNAVAILABLE;
    goto finish;
  }

finish:

  IAM_TRACE_EXIT("getClientIPAddress",ret);

  return ret;
}

/*--------------------------------------------------
 * SERVER SIDE FUNCTIONS
 *--------------------------------------------------*/
 CONTEXT_T *create_server_context(const gss_buffer_t input_token,
    CRED_T *pServerCred)
{
  AUTHINFO_T *pInToken = (AUTHINFO_T *)(input_token->value);
  int useridLen = ByteReverse(pInToken->useridLen);
  int authtokenLen = ByteReverse(pInToken->authTokenLen);
  char *userid = &pInToken->data[authtokenLen];
  CONTEXT_T *pCtx = NULL;
  IAM_TRACE_ENTRY("create_server_context");
  pCtx = (CONTEXT_T *)calloc(1, sizeof(CONTEXT_T));
  if (pCtx == NULL) return NULL;

  pCtx->targetLen = useridLen;
  pCtx->target = (char *)malloc(pCtx->targetLen);
  if (pCtx->target == NULL) goto malloc_fail;
  memcpy(pCtx->target, userid, pCtx->targetLen);

  pCtx->sourceLen = pServerCred->useridLen;
  pCtx->source = (char *)malloc(pCtx->sourceLen);
  if (pCtx->source == NULL) goto malloc_fail;
  memcpy(pCtx->source, pServerCred->userid, pCtx->sourceLen);
  IAM_TRACE_EXIT("create_server_context", 0);
  return pCtx;
malloc_fail:
  if (pCtx->target) free(pCtx->target);
  if (pCtx->source) free(pCtx->source);
  if (pCtx) free(pCtx);
  IAM_TRACE_EXIT("create_server_context", -1);
  return NULL;
}

int reset_userid(CONTEXT_T *pCtx, char *userid, int useridLen)
{
  int rc=0;

  char *newTarget = NULL;
  IAM_TRACE_ENTRY("reset_userid");

  // reset userid in context
  newTarget = (char *)malloc(useridLen*sizeof(char));
  if (!newTarget)
  {
    rc = -1;
    goto exit;
  }

  memcpy(newTarget, userid, useridLen);
  // hopefully we can assume no one else has access to pCtx but this thread
  // free old target if set
  if (pCtx->target)
  {
    free(pCtx->target);
  }
  pCtx->target = newTarget;
  pCtx->targetLen = useridLen;

exit:
  IAM_TRACE_EXIT("reset_userid",rc);
  return rc;
}

  
OM_uint32 validate_auth_info(CONTEXT_T *pCtx, const gss_buffer_t input_token,
    gss_buffer_t output_token, gss_name_t *src_name, OM_uint32 *minor_status)
{

  OM_uint32 rc = GSS_S_COMPLETE;
  int ret = 0;
  AUTHINFO_T *pInToken = (AUTHINFO_T *)(input_token->value);
  AUTHINFO_T *pOutToken = NULL;

  int authmode = DB2SEC_AUTH_MODE_IAM; 
  int authtype = ByteReverse(pInToken->authType);
  char *authtoken = &pInToken->data[0];
  int authtokenLen = ByteReverse(pInToken->authTokenLen);

  char* userInToken = NULL;
  db2int32 authidLen = 0;
  char useridtocheck[DB2SEC_MAX_USERID_LENGTH+1]="";
  db2int32 useridtocheckLen =0 ;

  unsigned char szIPAddress[IP_BUFFER_SIZE]="";  
  IAM_TRACE_ENTRY("validate_auth_info");

  ret = getClientIPAddress(szIPAddress, IP_BUFFER_SIZE);

  if(ret != 0)
  {
    db2Log( DB2SEC_LOG_ERROR, "Fail to retrieve the client IP address, ret = %d", ret );
    *minor_status = RETCODE_BADCONNECTION;
    rc = GSS_S_UNAVAILABLE;
    goto finish;
  }

  db2Log( DB2SEC_LOG_INFO, "validate_auth_info: %s", authTypeToString[authtype]);
  // Perform authentication
  if (authtype == DB2SEC_AUTH_ACCESS_TOKEN)
  {
    // Check to see if the username is passed in with the token and if it is remove it from the token to validate it and
    // use the userid for the lookup later.  The userid will be specified in the form userid:apikey or userid:accesstoken
    char * id_delim = NULL;
    id_delim = (char*)memchr ((char*)authtoken,  ':', authtokenLen); 
    
    if (id_delim != NULL) 
    {
       useridtocheckLen = id_delim - authtoken;
       if( useridtocheckLen > DB2SEC_MAX_USERID_LENGTH )
       {
          db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Userid from %s is longer than %d", szIPAddress, DB2SEC_MAX_USERID_LENGTH );
          *minor_status = RETCODE_BADTOKEN;
          rc = GSS_S_DEFECTIVE_CREDENTIAL;
          goto finish;
       }

       // this is the userid to validate against
       memcpy(useridtocheck, authtoken, useridtocheckLen);

       useridtocheck[useridtocheckLen] = '\0';
       stringToLower(useridtocheck);
       
       authtoken = id_delim+1; 
       
       // subtract useridlen and the ":" from the length of the remaining token       
       authtokenLen = authtokenLen - (useridtocheckLen +1);
    }
    
    ret = verify_access_token(authtoken, authtokenLen, &userInToken, &authidLen, authtype, szIPAddress, minor_status, logFunc);
    if( authidLen == 0 )
    {
      db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Fail to get the username from access token from %s", szIPAddress );
      rc = ret;
      goto finish;
    }
    db2Log( DB2SEC_LOG_INFO, "Username %s is found in Token", userInToken);
  }
  else
  {
    db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Invalid auth type (%d) from %s", authtype, szIPAddress );
    *minor_status = RETCODE_BADPASS;
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish;
  }

  if( rc == RETCODE_OK ) {
    goto success;
  } 
  else if ( rc != RETCODE_OK ) 
  {
    db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Fail to authorize user from %s with auth type (%s)", szIPAddress, authTypeToString[authtype] );
    goto finish;
  }

success:
  db2Log( DB2SEC_LOG_INFO, "validate_auth_info: Successfully authenticated and authorized userid (%.*s) from %s with auth type (%s)", authidLen, userInToken, szIPAddress, authTypeToString[authtype] );
  
  ret = reset_userid(pCtx, userInToken, authidLen);
  if (ret != 0)
  {
    db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Fail to reset userid, ret = %d", ret );
    *minor_status = RETCODE_MALLOC;
    rc = GSS_S_FAILURE;
    goto finish;
  }
  /* Generate service token
   * This is sent back to the client for mutual authentication.
   * We send the hardcoded principle name and a zero length
   * password.  This sample plugin ignores this information on
   * the client side.
   */

populatetoken:
  if (output_token->value == NULL) {
      pOutToken = (AUTHINFO_T *)calloc(1, sizeof(AUTHINFO_T));
      if (pOutToken == NULL)
      {
        db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Fail to allocate memory" );
        *minor_status = RETCODE_MALLOC;
        rc = GSS_S_FAILURE;
        goto finish;
      }

      output_token->value = (void *)pOutToken;
      output_token->length = sizeof(AUTHINFO_T);
  }

finish: 
  IAM_TRACE_EXIT("validate_auth_info",rc);
  if( userInToken != NULL ) free( userInToken );
  return rc;
}

/* GetAuthIDs
 * Return the DB2 Authorization IDs associated with the supplied
 * context.
 *
 * At this point, the GSS-API context is assumed to have been
 * established and the context handle is passed in as the token.
 */
SQL_API_RC SQL_API_FN GetAuthIDs(const char *userid,
               db2int32 useridlen,
               const char *usernamespace,		/* ignored */
               db2int32 usernamespacelen,		/* ignored */
               db2int32 usernamespacetype,	/* ignored */
               const char *dbname,					/* ignored */
               db2int32 dbnamelen,					/* ignored */
               void **token,
               char SystemAuthID[],
               db2int32 *SystemAuthIDlen,
               char InitialSessionAuthID[],
               db2int32 *InitialSessionAuthIDlen,
               char username[],
               db2int32 *usernamelen,
               db2int32  *initsessionidtype,
               char **errormsg,
               db2int32 *errormsglen)
{
  int rc = DB2SEC_PLUGIN_OK;
  CONTEXT_T *pCtx = NULL;
  IAM_TRACE_ENTRY("GetAuthIDs");

  *errormsg = NULL;
  *errormsglen = 0;

  pCtx = (CONTEXT_T *) (*token);
  if( pCtx == NULL )
  {
     IAM_TRACE_DATA( "GETAuthIDs","TRUSTED CONTEXT");
     if(useridlen < 1)
     {
         char dumpMsg[256] ="GetAuthIDs: userid and CTX is empty";
         rc = DB2SEC_PLUGIN_NO_CRED;
         *errormsg = strdup(dumpMsg);
         *errormsglen = strlen(dumpMsg);
         goto exit;
     }

     *usernamelen = useridlen;
     memcpy(username, userid, *usernamelen);     
  }
  else
  {
     *usernamelen = pCtx->targetLen;
     memcpy(username, pCtx->target, *usernamelen);     
  }

  memcpy(SystemAuthID, username, *usernamelen);
  *SystemAuthIDlen = *usernamelen;
  memcpy(InitialSessionAuthID, username, *usernamelen);
  *InitialSessionAuthIDlen = *usernamelen;
  *initsessionidtype = 0;

exit:
  IAM_TRACE_EXIT("GetAuthIDs", rc);

  return(rc);
}

/* DoesAuthIDExist()
 * Does the supplied DB2 Authorization ID refer to a valid user?
 */
SQL_API_RC SQL_API_FN db2secDoesAuthIDExist(const char *authid,
						  db2int32 authidLen,
                          char **errorMsg,
						  db2int32 *errorMsgLen)

{
  int rc = DB2SEC_PLUGIN_OK;

  IAM_TRACE_ENTRY("DoesAuthIDExist");

  const char* userPoolID = read_userpool_from_cfg();
  rc = DoesAWSUserExist(authid, userPoolID);
  if(rc != 0)
  {
    *errorMsg = "No user found in the given user pool";
    *errorMsgLen = strlen(*errorMsg);  
    goto exit;
  }
  else
  {
    *errorMsg = NULL;
    *errorMsgLen = 0;
  }
exit:

  IAM_TRACE_EXIT("DoesAuthIDExist",rc);

  return(rc);
}


/* gss_accept_sec_context()
 * Process a token received from the client, including
 * validating the encapsulated userid/password.
 */
OM_uint32 SQL_API_FN gss_accept_sec_context(
    OM_uint32 *minor_status,
    gss_ctx_id_t *context_handle,
    const gss_cred_id_t acceptor_cred_handle,
    const gss_buffer_t input_token,
    const gss_channel_bindings_t input_chan_bindings,
    gss_name_t *src_name,
    gss_OID *mech_type,
    gss_buffer_t output_token,
    OM_uint32 *ret_flags,
    OM_uint32 *time_rec,
    gss_cred_id_t *delegated_cred_handle)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  CRED_T *pServerCred = NULL;
  CONTEXT_T *pCtx = NULL;
  int rc2;
  int i;

  IAM_TRACE_ENTRY("gss_accept_sec_context");

  db2Log( DB2SEC_LOG_INFO, "gss_accept_sec_context: Security plugin has been loaded" );
  /* Check for non-supported options and sanity checks */
  if (input_chan_bindings != GSS_C_NO_CHANNEL_BINDINGS)
  {
    rc = GSS_S_BAD_BINDINGS;
    goto exit;
  }
  if (mech_type != NULL)
  {
    rc = GSS_S_BAD_MECH;
    goto exit;
  }
  if (acceptor_cred_handle == GSS_C_NO_CREDENTIAL)
  {
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto exit;
  }
  if (input_token == GSS_C_NO_BUFFER)
  {
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto exit;
  }
  if (context_handle == GSS_C_NO_CONTEXT)
  {
    rc = GSS_S_NO_CONTEXT;
    goto exit;
  }

  /* remaining time is not required */
  if (time_rec != NULL)
  {
    *time_rec = 0;
  }

  /*
   * The acceptor_cred_handle should be our server credential.
   */
  pServerCred = (CRED_T *)acceptor_cred_handle;

  /* On first call to init_sec_context, the context handle should
   * be set to GSS_C_NO_CONTEXT; set up the context structure
   */
  if (*context_handle != GSS_C_NO_CONTEXT)
  {
    pCtx = (CONTEXT_T *) *context_handle;
  }
  else
  {
    pCtx = create_server_context(input_token, pServerCred);
    if (!pCtx) {
      rc = GSS_S_NO_CONTEXT;
      goto exit;
    }
    *(CONTEXT_T **)context_handle = pCtx;
  }

  db2Log(DB2SEC_LOG_INFO, "validate_auth_info to be invoked");
  /* First invocation */
  if (pCtx->ctxCount == 0)
  {
    rc = validate_auth_info(pCtx, input_token, output_token, src_name, minor_status);
    if (rc == GSS_S_FAILURE) {
      delete_context(pCtx);
      pCtx = NULL;
      goto exit;
    }
    /* We're done.  No more flows.  Make the context count negative
     * so that the next invocation will result in an error.
     */
    pCtx->ctxCount = -2;
  }
  else
  {
    /* Function shouldn't have been called again for context establishment */
    rc = GSS_S_FAILURE;
    *minor_status = 4;
  }


exit:

  if (pCtx)
     (pCtx->ctxCount)++;
  
  IAM_TRACE_EXIT("gss_accept_sec_context", rc);

  return(rc);
}

/******************************************************************************
*
*  Function Name     =  gss_display_name
*
*  Descriptive Name  =
*
*  Function          =
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             =
*
*  Output            =
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      =
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_display_name(OM_uint32 * minor_status,
                           const gss_name_t input_name,
                           gss_buffer_t output_name_buffer,
                           gss_OID * output_name_type)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  NAME_T *pName;

  IAM_TRACE_ENTRY("gss_display_name");

  /* No name types supported */
  if (output_name_type != NULL)
  {
    rc = GSS_S_BAD_NAMETYPE;
    goto exit;
  }

  if (output_name_buffer)
  {
    pName = (NAME_T *) input_name;
    output_name_buffer->length = pName->useridLen;
    output_name_buffer->value = (void *) malloc(output_name_buffer->length);
    strncpy((char *)(output_name_buffer->value),
			 pName->userid,
             output_name_buffer->length);
    db2Log( DB2SEC_LOG_INFO, "gss_display_name: %s", (char *)output_name_buffer->value);
  }
  else
  {
    rc = GSS_S_BAD_NAME;
    goto exit;
  }

exit:
  IAM_TRACE_EXIT("gss_display_name", rc);

  return(rc);
}


/* db2secServerAuthPluginInit()
 * Set up plugin function pointers and perform other initialization.
 * This function is called by name when the plugin is loaded.
 */
SQL_API_RC SQL_API_FN db2secServerAuthPluginInit(db2int32 version,
                               void *functions,
                               db2secGetConDetails *getConDetails_fn,
                               db2secLogMessage *msgFunc,
                               char **errormsg,
                               db2int32 *errormsglen)
{
  int rc = DB2SEC_PLUGIN_OK;
  db2secGssapiServerAuthFunctions_1 *pFPs;
  char *principalName;
  int length;

  IAM_TRACE_ENTRY("db2secServerAuthPluginInit");
  /* No error message */
  *errormsg = NULL;
  *errormsglen = 0;

  if (version < DB2SEC_API_VERSION)
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    goto exit;
  }

  pFPs = (db2secGssapiServerAuthFunctions_1 *)functions;

  pFPs->plugintype = DB2SEC_PLUGIN_TYPE_GSSAPI;
  pFPs->version = DB2SEC_API_VERSION;

  /* Populate the server name */
  pFPs->serverPrincipalName.value = PRINCIPAL_NAME;
  pFPs->serverPrincipalName.length = strlen(PRINCIPAL_NAME);

  /* Fill in the server's cred handle */
  pFPs->serverCredHandle = (gss_cred_id_t)&serverCred;

  /* Set up function pointers */
  pFPs->db2secGetAuthIDs = GetAuthIDs;
  pFPs->db2secDoesAuthIDExist = db2secDoesAuthIDExist;
  pFPs->gss_accept_sec_context = gss_accept_sec_context;
  pFPs->gss_display_name = gss_display_name;
  /* gssapi_common */
  pFPs->db2secFreeErrormsg = FreeErrorMessage;
  pFPs->gss_delete_sec_context = gss_delete_sec_context;
  pFPs->gss_display_status = gss_display_status;
  pFPs->gss_release_buffer = gss_release_buffer;
  pFPs->gss_release_cred = gss_release_cred;
  pFPs->gss_release_name = gss_release_name;
  pFPs->db2secServerAuthPluginTerm = PluginTerminate;

  logFunc = msgFunc;
  getConDetails = getConDetails_fn;
  if (initIAM(logFunc ) != OK)
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    goto exit;
  }

  db2Log( DB2SEC_LOG_INFO, "db2secServerAuthPluginInit AWS IAM: Security plugin has been loaded" );

exit:
  IAM_TRACE_EXIT("PRINCIPAL_NAME", rc);

  return rc;
}
