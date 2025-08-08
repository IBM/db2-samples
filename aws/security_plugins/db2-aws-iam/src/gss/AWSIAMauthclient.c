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
*****************************************************************************
**
**  Source File Name = src/gss/AWSIAMauthclient.c
**
**  Descriptive Name = Client-side AWS IAM authentication plugin
**
**  Function: Implements client-side functions required by Db2 security
**            plugin architecture
**
**
*******************************************************************************/

#include "AWSIAMauth.h"
#include "../common/AWSIAMtrace.h"
#include "pwd.h"


/******************************************************************************
*
*  Function Name     = FreeToken
*
*  Descriptive Name  = Free Memory used for the token
*
*  Function          = We don't need to free anything as no token is used
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = None
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN FreeToken
(
  void *token,
	char **errorMsg,
	db2int32 *errorMsgLen
)
{
  IAM_TRACE_ENTRY("FreeToken");

  *errorMsg = NULL;
  *errorMsgLen = 0;
  IAM_TRACE_EXIT("FreeToken",0);

  return DB2SEC_PLUGIN_OK;
}



static SQL_API_RC getUsername(
                  const uid_t uid,
                  char * const userName,
                  db2int32 * const userNameLength,
                  char ** errorMessage)
{
   int err ;
   SQL_API_RC rc = 0 ;
   struct passwd * pResult ;
   struct passwd   passwordData = { 0 } ;
   size_t bufSize = sysconf(_SC_GETPW_R_SIZE_MAX) ;
   char * buf = malloc(bufSize) ;
   IAM_TRACE_ENTRY("getUsername");

   if (!buf)
   {
        char dumpMsg[256] ="";
        snprintf(dumpMsg, sizeof(dumpMsg), "getUsername: Unable to allocate memory");
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
        goto exit;
   }

   err = getpwuid_r( uid,
                     &passwordData,
                     buf,
                     bufSize,
                     &pResult ) ;
   if (err)
   {
        char dumpMsg[256] ="";
        snprintf(dumpMsg, sizeof(dumpMsg), "getUsername: Unable to find userid %d", uid);
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
   }

   *userNameLength = strlen(pResult->pw_name) ;

   if (*userNameLength > SQL_AUTH_IDENT)
   {
        char dumpMsg[256] ="";
        snprintf(dumpMsg, sizeof(dumpMsg), "getUsername: Username is too long %s", pResult->pw_name);
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
   }

   strcpy(userName, pResult->pw_name) ;

exit:
   if(buf)
   {
       free(buf) ;
   }

   IAM_TRACE_EXIT("getUsername",rc);

   return rc;
}

/******************************************************************************
*
*  Function Name     = GetDefaultLoginContext
*
*  Descriptive Name  = Determine the default user identity associated with
*                      the current process context.
*
*  Function          = If this function is called by Db2 client,
*                      no credentials have been provided, so always
*                      fail the connect.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = None
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_BADUSER
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN GetDefaultLoginContext
(
  char authID[],
  db2int32 *authIDLength,
  char userid[],
  db2int32 *useridLength,
  db2int32 useridType,
  char domain[],
  db2int32 *domainLength,
  db2int32 *domainType,
  const char *databaseName,
  db2int32 databaseNameLength,
  void **token,
  char **errorMessage,
  db2int32 *errorMessageLength
)
{
    int rc = DB2SEC_PLUGIN_OK;
	  int length;
	  char *user;
    uid_t uid=-1;
    struct passwd *pw = NULL;

    IAM_TRACE_ENTRY("GetDefaultLoginContext");

    authID[0] = '\0';
    *authIDLength = 0;
    userid[0] = '\0';
    *useridLength = 0;
    domain[0] = '\0';
    *domainLength = 0;
    *domainType = DB2SEC_USER_NAMESPACE_UNDEFINED;

    *errorMessage = NULL;
    *errorMessageLength = 0;

    if(DB2SEC_PLUGIN_REAL_USER_NAME == useridType)
    {
        // Get the real username from the OS
        uid = getuid ();
    }
    else if(DB2SEC_PLUGIN_EFFECTIVE_USER_NAME == useridType)
    {
        // Get the effective userid from the OS
        uid = geteuid ();
    }
    else
    {
        char dumpMsg[256] ="";
        snprintf(dumpMsg, sizeof(dumpMsg), "GetDefaultLoginContext: Invalid user type: %d", useridType);
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
        goto exit;
    }
  
    rc = getUsername(uid, userid, useridLength,  errorMessage);
    
    if (DB2SEC_PLUGIN_OK == rc)
    {
        strcpy(authID, userid);
        *authIDLength = *useridLength;        
    }
    else
    {
        char dumpMsg[256] ="";
        snprintf(dumpMsg, sizeof(dumpMsg), "GetDefaultLoginContext: Userid does not exist or is bad: %d", uid);
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_BADUSER;
    }

exit:

    if (*errorMessage != NULL)
    {
        *errorMessageLength = strlen(*errorMessage);
    }
    else
    {
        *errorMessageLength = 0;
    }

    IAM_TRACE_EXIT("GetDefaultLoginContext",rc);

	  return(rc);
}

/******************************************************************************
*
*  Function Name     = GenerateInitialCredUserPassword
*
*  Descriptive Name  = Generate the intial credentials based on the provided
*                      username/password pair and return the GSS-API
*                      credentials handle.
*
*  Function          =
*
*  Dependencies      = None
*
*  Restrictions      = - A forwardable TGT will always be requested
*                      - No change password functionality provided
*                      - If a REALM is specified with the username, then it will
*                        be included in the userid buffer and not parsed into
*                        the userNamespace field
*                      - Certain krb5 objects must be created and exist for the
*                        GSS-API cred handle to be valid.  To make sure that
*                        these krb5 objects are cleaned up properly, their
*                        handles will be stored in a structure pointed to by
*                        pInitInfo so that they may be freed during
*                        db2secFreeInitInfo().
*
*  Input             = userid - User name
*                      useridLen - Length of User name
*                      userNamespace - (not used)
*                      userNamespaceLen - (not used)
*                      userNamespaceType - (not used)
*                      password - User's password
*                      passwordLen - Password string length
*                      newPassword - (not used)
*                      newPasswordLen - (not used)
*                      dbName - (not used)
*                      dbnameLen - (not used)
*
*  Output            = pGSSCredHandle - Pointer to the GSS-API cred handle
*                      ppInitInfo - Pointer to a buffer allocated by the
*                                   function to keep track of krb5 objects
*                                   allocated to create the GSS-API cred handle
*                      ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_CHANGEPASSWORD_NOTSUPPORTED
*                      DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS
*                      DB2SEC_PLUGIN_UNKNOWNERROR
*                      DB2SEC_PLUGIN_BADPWD
*                      DB2SEC_PLUGIN_BADUSER
*                      DB2SEC_PLUGIN_PWD_EXPIRED
*                      DB2SEC_PLUGIN_UID_EXPIRED
*
*******************************************************************************/
SQL_API_RC SQL_API_FN GenerateInitialCredUserPassword
(
  const char *userid,
  db2int32 useridLen,
  const char *usernamespace,
  db2int32 usernamespacelen,
  db2int32 usernamespacetype,
  const char *password,
  db2int32 passwordLen,
  const char *newpassword,
  db2int32 newpasswordLen,
  const char *dbname,
  db2int32 dbnameLen,
  gss_cred_id_t *pGSSCredHandle,
  void **ppInitInfo,
  char **errorMsg,
  db2int32 *errorMsgLen
)
{
  int rc = DB2SEC_PLUGIN_OK;
  CRED_T *pCred = NULL;
  char *localErrorMsg = NULL;
  char oneNullByte[] = {'\0'};

  IAM_TRACE_ENTRY("GenerateInitialCredUserPassword");

  if (newpasswordLen > 0)
  {
    rc = DB2SEC_PLUGIN_CHANGEPASSWORD_NOTSUPPORTED;
    goto exit;
  }

  if (pGSSCredHandle == NULL)
  {
	  localErrorMsg = "GenerateInitialCredential: pGSSCredHandle == NULL";
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    goto exit;
  }

  /* Check lengths */
  if (useridLen > TOKEN_MAX_STRLEN)
  {
	  localErrorMsg = "GenerateInitialCredential: userid too long";
	  rc = DB2SEC_PLUGIN_BADUSER;
  	goto exit;
  }
  if (passwordLen > TOKEN_MAX_STRLEN)
  {
	  localErrorMsg = "GenerateInitialCredential: password too long";
	  rc = DB2SEC_PLUGIN_BADPWD;
	  goto exit;
  }

  pCred = (CRED_T *)malloc(sizeof(CRED_T));
  if (pCred == NULL)
  {
    goto malloc_fail;
  }
  memset(pCred, '\0', sizeof(CRED_T));

  /* Deal with NULL userids and passwords by using a one-byte
   * string containing only a NULL.  We flow this to the server
   * and let it decide.
   */
  if (useridLen == 0 || userid == NULL)
  {
  	userid = oneNullByte;
  	useridLen = 1;
  }
  if (passwordLen == 0 || password == NULL)
  {
  	password = oneNullByte;
  	passwordLen = 1;
  }

  pCred->authtype = DB2SEC_AUTH_PASSWORD;

  pCred->useridLen = useridLen;
  pCred->userid = (char *)malloc(useridLen);
  if (pCred->userid == NULL)
  {
    goto malloc_fail;
  }
  memcpy(pCred->userid, userid, useridLen);

  pCred->authtokenLen = passwordLen;
  pCred->authtoken = (char *)malloc(passwordLen);
  if (pCred->authtoken == NULL)
  {
    goto malloc_fail;
  }
  memcpy(pCred->authtoken, password, passwordLen);

  *pGSSCredHandle = (gss_cred_id_t)pCred;

exit:

  /* No init info */
  if (ppInitInfo != NULL)
  {
    *ppInitInfo = NULL;
  }

  if (localErrorMsg != NULL)
  {
    *errorMsg = localErrorMsg;
    *errorMsgLen = strlen(localErrorMsg);
  }
  else
  {
    *errorMsg = NULL;
    *errorMsgLen = 0;
  }
  IAM_TRACE_EXIT("GenerateInitialCredUserPassword", rc);

  return(rc);

malloc_fail:
  if (pCred != NULL)
  {
    if (pCred->authtoken != NULL) free(pCred->authtoken);
    if (pCred->userid != NULL) free(pCred->userid);
    free(pCred);
  }

  localErrorMsg = "GenerateInitialCredential: malloc failed";
  rc = DB2SEC_PLUGIN_NOMEM;

  goto exit;
}

/*
 * GenerateInitialCredAccessToken
 */
SQL_API_RC SQL_API_FN GenerateInitialCredAccessToken
(
  const char *accesstoken,
  db2int32 accesstokenLen,
  const char *accesstokenspace,
  db2int32 accesstokenspaceLen,
  db2int32 accesstokenspaceType,
  const char *dbname,
  db2int32 dbnameLen,
  gss_cred_id_t *pGSSCredHandle,
  void **ppInitInfo,
  char **errorMsg,
  db2int32 *errorMsgLen
)
{
  int rc = DB2SEC_PLUGIN_OK;
  CRED_T *pCred;
  char *localErrorMsg = NULL;
  char oneNullByte[] = {'\0'};
  const char *userid;
  db2int32 useridLen;

  IAM_TRACE_ENTRY("GenerateInitialCredAccessToken");

  if (pGSSCredHandle == NULL)
  {
    IAM_TRACE_DATA("GenerateInitialCredAccessToken","10");

  	localErrorMsg = "GenerateInitialCredAccessToken: pGSSCredHandle == NULL";
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    goto exit;
  }

  /* Check lengths */
  if (accesstokenLen > TOKEN_MAX_AUTH_TOKEN_LEN)
  {
    IAM_TRACE_DATA("GenerateInitialCredAccessToken", "20");
    rc = DB2SEC_PLUGIN_BADPWD;
    localErrorMsg = "GenerateInitialCredAccessToken: access token too long";
    goto exit;
  }

  pCred = (CRED_T *)malloc(sizeof(CRED_T));
  if (pCred == NULL)
  {
    IAM_TRACE_DATA( "GenerateInitialCredAccessToken", "30");
    goto malloc_fail;
  }
  memset(pCred, '\0', sizeof(CRED_T));

  /* Deal with NULL userids and passwords by using a one-byte
   * string containing only a NULL.  We flow this to the server
   * and let it decide.
   */

  pCred->authtype = DB2SEC_AUTH_ACCESS_TOKEN;

  //pCred->useridLen = 0;
  //pCred->userid = NULL;
  userid = oneNullByte;
  useridLen = 1;
  pCred->useridLen = useridLen;
  pCred->userid = (char *)malloc(useridLen);
  if (pCred->userid == NULL)
  {
    IAM_TRACE_DATA( "GenerateInitialCredAccessToken","40");
    goto malloc_fail;
  }
  memcpy(pCred->userid, userid, useridLen);

  pCred->authtokenLen = accesstokenLen;
  pCred->authtoken = (char *)malloc(accesstokenLen);
  if (pCred->authtoken == NULL)
  {
    IAM_TRACE_DATA("GenerateInitialCredAccessToken", "50");
    goto malloc_fail;
  }
  memcpy(pCred->authtoken, accesstoken, accesstokenLen);

  *pGSSCredHandle = (gss_cred_id_t)pCred;

exit:

  /* No init info */
  if (ppInitInfo != NULL)
  {
    *ppInitInfo = NULL;
  }

  if (localErrorMsg != NULL)
  {
    *errorMsg = localErrorMsg;
    *errorMsgLen = strlen(localErrorMsg);
  }
  else
  {
    *errorMsg = NULL;
    *errorMsgLen = 0;
  }
  IAM_TRACE_EXIT("GenerateInitialCredAccessToken",rc);

  return(rc);

malloc_fail:
  if (pCred != NULL)
  {
    if (pCred->authtoken != NULL) free(pCred->authtoken);
    if (pCred->userid != NULL) free(pCred->userid);
    free(pCred);
  }

  localErrorMsg = "GenerateInitialCredAccessToken: malloc failed";
  rc = DB2SEC_PLUGIN_NOMEM;

  goto exit;
}


/******************************************************************************
*
*  Function Name     = ProcessServerPrincipalName
*
*  Function          = Process the principle name string returned from the
*                      server plugin and package it into a gss_name_t.
*
*  Restrictions      = None
*
*  Input             = name - Principal Name
*                      nameLen - Length of the Principal Name
*
*  Output            = gssName - Packaged Principal Name
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME
*
*******************************************************************************/
SQL_API_RC SQL_API_FN ProcessServerPrincipalName
(
  const char *name,
  db2int32 nameLen,
  gss_name_t *gssName,
  char **errorMsg,
  db2int32 *errorMsgLen
)
{
  int rc = DB2SEC_PLUGIN_OK;
  NAME_T *pName;
  IAM_TRACE_ENTRY("ProcessServerPrincipalName");
  
  /* No error messages */
  *errorMsg = NULL;
  *errorMsgLen = 0;

  if (name != NULL && nameLen > 0)
  {
    pName = (NAME_T *) malloc(sizeof(NAME_T));
	  if (pName == NULL)
    {
      IAM_TRACE_DATA("ProcessServerPrincipalName","10");
      goto malloc_fail;
    }
	  memset(pName, '\0', sizeof(NAME_T));

    pName->useridLen = nameLen;
    pName->userid = (char *) malloc(nameLen);
	  if (pName->userid == NULL)
    {
      IAM_TRACE_DATA("ProcessServerPrincipalName","20");
      goto malloc_fail;
    }
    memcpy(pName->userid, name, nameLen);

    *gssName = (gss_name_t)pName;
  }
  else
  {
    IAM_TRACE_DATA( "ProcessServerPrincipalName","30");
    rc = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME;
    goto exit;
  }

exit:
  IAM_TRACE_EXIT("ProcessServerPrincipalName",rc);

  return(rc);

malloc_fail:
  if (pName != NULL)
  {
	  if (pName->userid)
    {
      free(pName->userid);
    }
  	free(pName);
  }
  *errorMsg = "ProcessServerPrincipalName: malloc failed";
  *errorMsgLen = strlen(*errorMsg);
  goto exit;
}

/* FreeInitInfo()
 * A no-op, since we don't set up any init info.
 */
/******************************************************************************
*
*  Function Name     = FreeInitInfo
*
*  Descriptive Name  = Free Memory used for the init info
*
*  Function          = We don't return an allocated init info, so nothing to
*                      free
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = None
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN FreeInitInfo
(
  void *initInfo,
	char **errorMsg,
	db2int32 *errorMsgLen
)
{
  int rc = DB2SEC_PLUGIN_OK;

  IAM_TRACE_ENTRY("FreeInitInfo");

  *errorMsg = NULL;
  *errorMsgLen = 0;

  if( initInfo != NULL )
  {
    // We don't expect this to be allocated
    rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
    *errorMsg = "FreeInitInfo: initInfo != NULL";
    *errorMsgLen = strlen(*errorMsg);
    goto exit;
  }

exit:
  IAM_TRACE_EXIT("FreeInitInfo",rc);

  return(rc);
}

/******************************************************************************
*
*  Function Name     = gss_init_sec_context
*
*  Function          = Builds a context based on the input credentials
*                      Db2 client sends a payload to Db2 server based on this
*                      context.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = cred_handle - input credentials that we will massage
*                                    into the format understood by the
*                                    server-side security plugin
*                      target_name - name of the server-side security plugin
*                      input_token - not used
*                      mech_type - not used
*                      req_flags - not used
*                      time_req - not used
*
*  Output            = context_handle - the security context that is being
*                                       constructed
*                      output_token - the constructed data block with
*                                     credentials in a format understood
*                                     by the server
*                      minor_status - error message code from this plugin
*                      action_mech_type - not used
*                      ret_flags - not used
*                      time_rec - not used
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_INCOMPATIBLE_VER
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_init_sec_context
(
  OM_uint32 * minor_status,
  const gss_cred_id_t cred_handle,
  gss_ctx_id_t * context_handle,
  const gss_name_t target_name,
  const gss_OID mech_type,
  OM_uint32 req_flags,
  OM_uint32 time_req,
  const gss_channel_bindings_t input_chan_bindings,
  const gss_buffer_t input_token,
  gss_OID * actual_mech_type,
  gss_buffer_t output_token,
  OM_uint32 * ret_flags,
  OM_uint32 * time_rec
)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  NAME_T *pTarget = NULL;
  NAME_T localTarget;
  CONTEXT_T *pCtx = NULL;
  CRED_T *pCred = NULL;
  CRED_T defaultCred;
  AUTHINFO_T *pOutToken = NULL;
  char *localuser = NULL;
  char *localpswd = NULL;
  char *cptr = NULL;
  char *errMsg = NULL;
  int length;
  IAM_TRACE_ENTRY("gss_init_sec_context");
  
  /* Check for unsupported options */
  if (context_handle == NULL)
  {
    IAM_TRACE_DATA("gss_init_sec_context","10");

    errMsg = "gss_init_sec_context: context_handle == NULL";
    rc = GSS_S_NO_CONTEXT;
    goto exit;
  }

  /* Check the target name to be the plugin name */
  pTarget = (NAME_T *)target_name;
  if (pTarget == GSS_C_NO_NAME)
  {
    localTarget.userid = PRINCIPAL_NAME;
    localTarget.useridLen = strlen(PRINCIPAL_NAME);
    pTarget = &localTarget;
  }
  else if(strncmp(pTarget->userid, PRINCIPAL_NAME, pTarget->useridLen) != 0)
  {
    IAM_TRACE_DATA("gss_init_sec_context","20");
    errMsg = "gss_init_sec_context: Principle name mismatch";
    rc = GSS_S_BAD_NAME;
    goto exit;
  }

  /* Check the input credentials */
  if (cred_handle == GSS_C_NO_CREDENTIAL)
  {
    IAM_TRACE_DATA("gss_init_sec_context","30");
    errMsg = "gss_init_sec_context: No credentials";
    rc = GSS_S_BAD_NAME;
    goto exit;
  }
  else
  {
    pCred = (CRED_T *)cred_handle;
  }

  /* On first call to init_sec_context, the context handle should be set to */
  /* GSS_C_NO_CONTEXT; set up the context structure */
  if (*context_handle == GSS_C_NO_CONTEXT)
  {
    pCtx = (CONTEXT_T *)malloc(sizeof(CONTEXT_T));
    if (pCtx == NULL)
    {
      IAM_TRACE_DATA("gss_init_sec_context","40");
      goto malloc_fail;
    }
    memset(pCtx, '\0', sizeof(CONTEXT_T));

    pCtx->targetLen = pTarget->useridLen;
    pCtx->target = (char *)malloc(pCtx->targetLen);
    if (pCtx->target == NULL)
    {
      IAM_TRACE_DATA("gss_init_sec_context","50");
      goto malloc_fail;
    }
    memcpy(pCtx->target, pTarget->userid, pCtx->targetLen);

    // No source is needed
    pCtx->sourceLen = 0;
    pCtx->source = NULL;

    pCtx->ctxCount = 0;
    *context_handle = pCtx;
  }
  else
  {
    pCtx = (CONTEXT_T *)*context_handle;
    if (pCtx->ctxCount == 0)
    {
      IAM_TRACE_DATA( "gss_init_sec_context","60");
      errMsg = "gss_init_sec_context: Invalid context handle";
      rc = GSS_S_NO_CONTEXT;
      goto exit;
    }
  }

  // First invocation
  // Create the data block (output token) that contains the credentials
  // for the server-side plugin to process
  if (pCtx->ctxCount == 0)
  {
    /* There should be no input token */
    if (input_token != GSS_C_NO_BUFFER)
    {
      IAM_TRACE_DATA("gss_init_sec_context","70");
      errMsg = "gss_init_sec_context: bad input_token";
      rc = GSS_S_FAILURE;
      *minor_status = RETCODE_BADTOKEN;
      goto exit;
    }

    int tokenLen = sizeof(AUTHINFO_T)
                   - sizeof( char[1] )   // char      data[1]
                   + pCred->authtokenLen
                   + pCred->useridLen;

    pOutToken = (AUTHINFO_T *)malloc( tokenLen );
    if (pOutToken == NULL)
    {
      IAM_TRACE_DATA("gss_init_sec_context","80");
      goto malloc_fail;
    }

    memset(pOutToken, '\0', tokenLen);

    pOutToken->version = (OM_uint32) ByteReverse(AUTHINFO_VERSION_1);
    pOutToken->authType = (OM_uint32) ByteReverse(pCred->authtype);
    pOutToken->authTokenLen = (OM_uint32) ByteReverse(pCred->authtokenLen);
    pOutToken->useridLen = (OM_uint32) ByteReverse(pCred->useridLen);

    if( pCred->authtokenLen > 0 )
    {
      memcpy(&pOutToken->data[0], pCred->authtoken, pCred->authtokenLen);
    }

    if( pCred->useridLen > 0 )
    {
      memcpy(&pOutToken->data[pCred->authtokenLen], pCred->userid, pCred->useridLen);
    }

    output_token->value = (void *)pOutToken;
    output_token->length = tokenLen;

    if (req_flags & GSS_C_MUTUAL_FLAG)
    {
      IAM_TRACE_DATA("gss_init_sec_context","90");

      /* Mutual authentication requested */
      rc = GSS_S_CONTINUE_NEEDED;
    }
    else
    {
      /* Make the context count negative so that the next invocation will */
      /* result in an error */
      pCtx->ctxCount = -2;
    }
  }
  else if (pCtx->ctxCount == 1)
  {
    /* Set the context count to negative so that the next invocation will */
    /* result in an error */
    pCtx->ctxCount = -2;
  }
  else
  {
    /* Function shouldn't have been called again for context establishment */
    IAM_TRACE_DATA("gss_init_sec_context", "100");
    errMsg = "context count too high!";
    rc = GSS_S_FAILURE;
    *minor_status = RETCODE_PROGERR;
    goto exit;
  }

  // Fill in secondary information
  if(actual_mech_type != NULL)
  {
    *actual_mech_type = mech_type;
  }
  if(ret_flags != NULL)
  {
    *ret_flags = req_flags;
  }
  if(time_rec != NULL)
  {
    *time_rec = time_req;
  }

exit:
  if (errMsg != NULL)
  {
    char msg[512];
    sprintf(msg,"AWSIAMauth::gss_init_sec_context error: %s", errMsg);
    logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));
  }
  if(pCtx != NULL)
     (pCtx->ctxCount)++;

  IAM_TRACE_EXIT("gss_init_sec_context",rc);

  return(rc);

malloc_fail:
  if (localuser != NULL)
  {
    free(localuser);
  }
  if (localpswd != NULL)
  {
    free(localpswd);
  }
  if (pCtx != NULL)
  {
    if (pCtx->target != NULL)
    {
      free(pCtx->target);
    }
    if (pCtx->source != NULL)
    {
      free(pCtx->source);
    }
    free(pCtx);
  }
  if (pOutToken != NULL)
  {
    free(pOutToken);
  }

  rc = GSS_S_FAILURE;
  *minor_status = RETCODE_MALLOC;

  logFunc(DB2SEC_LOG_ERROR,
      "AWSIAMauth::gss_init_sec_context: malloc failure", 50);

  IAM_TRACE_EXIT("gss_init_sec_context",rc);
  return(rc);
}

/******************************************************************************
*
*  Function Name     = db2secClientAuthPluginInit
*
*  Function          = Set up plugin function pointers and
*                      perform other initialization.
*                      This function is called by name when the plugin is
*                      loaded so this function name is the same for all
*                      security plugins.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = version - Version of the plugin that Db2 can handle
*                      msgFunc - function pointer for writing messages back to
*                                Db2
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_INCOMPATIBLE_VER
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secClientAuthPluginInit
(
  db2int32 version,
  void *fns,
  db2secLogMessage *msgFunc,
  char **errormsg,
  db2int32 *errormsglen
)
{
  int rc = DB2SEC_PLUGIN_OK;
  db2secGssapiClientAuthFunctions_2 *pFPs;
  IAM_TRACE_ENTRY("db2secClientAuthPluginInit");

  /* No error message */
  *errormsg = NULL;
  *errormsglen = 0;

  /* Written to version 2 of the API */
  if (version < DB2SEC_GSSAPI_CLIENT_AUTH_FUNCTIONS_VERSION_2)
  {
    rc = DB2SEC_PLUGIN_INCOMPATIBLE_VER;
    goto exit;
  }

  pFPs = (db2secGssapiClientAuthFunctions_2 *) fns;

  pFPs->plugintype = DB2SEC_PLUGIN_TYPE_GSSAPI;
  pFPs->version = DB2SEC_GSSAPI_CLIENT_AUTH_FUNCTIONS_VERSION_2;

  /* Set up function pointers */
  pFPs->db2secGetDefaultLoginContext = GetDefaultLoginContext;
  pFPs->db2secGenerateInitialCred = GenerateInitialCredUserPassword;
  pFPs->db2secGenerateInitialCredAccessToken = GenerateInitialCredAccessToken;
  pFPs->db2secProcessServerPrincipalName = ProcessServerPrincipalName;
  pFPs->db2secFreeToken = FreeToken;
  pFPs->db2secFreeInitInfo = FreeInitInfo;
  pFPs->gss_init_sec_context = gss_init_sec_context;

  /* From AWSIAMauthcommon.c */
  pFPs->gss_delete_sec_context = gss_delete_sec_context;
  pFPs->db2secClientAuthPluginTerm = PluginTerminate;
  pFPs->db2secFreeErrormsg = FreeErrorMessage;
  pFPs->gss_display_status = gss_display_status;
  pFPs->gss_release_buffer = gss_release_buffer;
  pFPs->gss_release_cred = gss_release_cred;
  pFPs->gss_release_name = gss_release_name;

  logFunc = msgFunc;

exit:

  IAM_TRACE_EXIT("db2secClientAuthPluginInit",rc);

  return(rc);
}
