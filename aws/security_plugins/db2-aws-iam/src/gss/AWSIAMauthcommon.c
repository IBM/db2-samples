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
*  Source File Name = src/gss/AWSIAMauthcommon.c
*
*  Descriptive Name = Common Code for IAM authentication plugin
*
*  Function: Provide common functions shared between client-side and
*            server-side security plugins
*
*  Dependencies: None
*
*  Restrictions: None
*
*
*******************************************************************************/

#include "AWSIAMauth.h"
#include "../common/AWSIAMtrace.h"

/******************************************************************************
*
*  Function Name     = ByteReverse
*
*  Function          = Reverse the given integer for endianess
*                      This plugin sends a AUTHINFO_T (defined above) between
*                      client and server system, which may be of different
*                      endianess.
*                      The length fields in the AUTHINFO_T are sent in Network
*                      Byte Order (big endian), and this function is used to
*                      convert them when required.
*
*                      Rather than depend on a static #define to determine
*                      behavior we determine the endianess of the current
*                      system on the fly.
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
int ByteReverse( int input )
{
  int output = input;
  union
  {
    short s;
    char c;
  } test;

  test.s = 1;
  if (test.c == (char)1)
  {
    /* This is a little endian platform, byte reverse.
     * We try to make no assumptions about the size of the native
     * type here.  This may not be efficient, but it's portable.
     */
    char *ip = (char*)&input;
    char *op = (char*)&output;
    int size = sizeof(int);
    int i;
    for (i=0; i < size; i++)
    {
      op[i] = ip[size - i - 1];
    }
  }
  return(output);
}

/******************************************************************************
*
*  Function Name     = FreeErrorMessage
*
*  Function          = This is no-op.  All error messaged returned by this
*                      plugin are static C strings.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = errormsg - error message to be freed
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN FreeErrorMessage( char *errormsg )
{
  if (errormsg != NULL) free(errormsg);
  return(DB2SEC_PLUGIN_OK);
}

/******************************************************************************
*
*  Function Name     = gss_release_cred()
*
*  Function          = Free the specified credential and free associated memory
*                      (gss_cred_id_t)
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = pCredHandle - credential handle to be freed
*
*  Output            = None
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = None
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_release_cred
(
  OM_uint32 *minorStatus,
  gss_cred_id_t *pCredHandle
)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  CRED_T *pCred;
  IAM_TRACE_ENTRY("gss_release_cred");

  // This condition also accounts for pCredHandle == GSS_C_NO_CREDENTIAL
  if (pCredHandle != NULL)
  {
    if (*pCredHandle != GSS_C_NO_CREDENTIAL)
    {
      pCred = (CRED_T *) *pCredHandle;
      free( pCred->userid );
      free( pCred->authtoken );
      free( pCred );
      *pCredHandle = GSS_C_NO_CREDENTIAL;
    }
  }
  else
  {
    rc = GSS_S_NO_CRED;
    goto exit;
  }

exit:
  IAM_TRACE_EXIT("gss_release_cred",0);
  return(rc);
}

/******************************************************************************
*
*  Function Name     = gss_release_name()
*
*  Function          = Free the memory used by gss_name_t in this plugin
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = name - name to be freed
*
*  Output            = minorStatus - not used
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = None
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_release_name
(
  OM_uint32 *minorStatus,
  gss_name_t *name
)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  NAME_T *pName;
  IAM_TRACE_ENTRY("gss_release_name");

  if (name != NULL && *name != NULL)
  {
    pName = (NAME_T *) *name;
    free(pName->userid);
    free(pName);
    *name = GSS_C_NO_NAME;
  }
  IAM_TRACE_EXIT("gss_release_name",0);

  return(rc);
}

/* gss_release_buffer()
 * Free the specified buffer.
 */
/******************************************************************************
*
*  Function Name     = gss_release_buffer()
*
*  Function          = Free the buffer (gss_release_t) passed to Db2 before
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = buffer - buffer to be freed
*
*  Output            = minorStatus - not used
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = None
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_release_buffer
(
  OM_uint32 *minorStatus,
  gss_buffer_t buffer
)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  NAME_T *pName;
  IAM_TRACE_ENTRY("gss_release_buffer");

  if( (buffer != NULL) &&
	    (buffer->length > 0) &&
      (buffer->value != NULL) )
  {
    free(buffer->value);
    buffer->value = NULL;
    buffer->length = 0;
  }


  IAM_TRACE_EXIT("gss_release_buffer",rc);

  return(rc);
}

/******************************************************************************
*
*  Function Name     = delete_context
*
*  Function          = Free the memory used by the given context
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = pCtx - context to be freed
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
void delete_context( CONTEXT_T *pCtx )
{

  IAM_TRACE_ENTRY("delete_context");

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
    if( pCtx->groups != NULL )
    {
      int i;
      for( i = 0; i < pCtx->groupCount; ++i )
      {
        if( pCtx->groups[i].group_name ) free( pCtx->groups[i].group_name );
      }
    }
    free(pCtx);
  }
  IAM_TRACE_EXIT("delete_context", 0);

}

/******************************************************************************
*
*  Function Name     = gss_delete_sec_context
*
*  Function          = Free the specified context
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = context_handle - context to be freed
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_delete_sec_context
(
  OM_uint32 *minorStatus,
  gss_ctx_id_t *context_handle,
  gss_buffer_t output_token
)
{
  OM_uint32 rc=GSS_S_COMPLETE;
  CONTEXT_T *pCtx;

  IAM_TRACE_ENTRY("gss_delete_sec_context");

  if (context_handle != NULL && *context_handle != NULL)
  {
    pCtx = (CONTEXT_T *)*context_handle;
    delete_context(pCtx);
    *context_handle = GSS_C_NO_CONTEXT;

    if (output_token != GSS_C_NO_BUFFER)
    {
	    output_token->value = NULL;
      output_token->length = 0;
    }
  }
  else
  {
    rc = GSS_S_NO_CONTEXT;
    goto exit;
  }

exit:
  IAM_TRACE_EXIT("gss_delete_sec_context", rc);

  return(rc);
}

/******************************************************************************
*
*  Function Name     = gss_display_status()
*
*  Function          = Return the text message associated with the given status
*                      type and value
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = status_value - status value
*                      status_type - status type
*                      mech_type - not used
*
*  Output            = None
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = None
*
*******************************************************************************/
OM_uint32 SQL_API_FN gss_display_status
(
  OM_uint32 *minor_status,
  OM_uint32 status_value,
  int status_type,
  const gss_OID mech_type,
  OM_uint32 *message_context,
  gss_buffer_t status_string
)
{
  OM_uint32 rc=GSS_S_COMPLETE;
  IAM_TRACE_ENTRY("gss_display_status");

  /* No mech types supported */
  if (mech_type != NULL)
  {
    rc = GSS_S_BAD_MECH;
    goto exit;
  }

  /* Regardless of the type of status code, a 0 means success */
  if (status_value == GSS_S_COMPLETE)
  {
    status_string->length = strlen(retcodeMessage[RETCODE_OK]) + 1;
    status_string->value = (void *) malloc(status_string->length);
	  if (status_string->value == NULL)
    {
      goto malloc_fail;
    }
    strcpy((char *)(status_string->value), retcodeMessage[RETCODE_OK]);
    goto exit;
  }

  if (status_type == GSS_C_GSS_CODE)
  {
    /* Major status code -- we only have 1 for the moment */
    status_string->length = strlen(MAJOR_CODE_STRING) + 1;
    status_string->value = (void *)malloc(status_string->length);
	  if (status_string->value == NULL)
    {
      goto malloc_fail;
    }
    strcpy((char *)(status_string->value), MAJOR_CODE_STRING);
  }
  else if (status_type == GSS_C_MECH_CODE)
  {
    // Minor status code
    // Make sure that the status value is within range
    if (status_value > RETCODE_MAXCODE)
    {
      rc = GSS_S_BAD_STATUS;
	    *minor_status = RETCODE_UNKNOWN;
      goto exit;
    }
    status_string->length = strlen(retcodeMessage[status_value]) + 1;
    status_string->value = (void *)malloc(status_string->length);
    if (status_string->value == NULL)
    {
      goto malloc_fail;
    }
    strcpy((char *)(status_string->value), retcodeMessage[status_value]);
  }
  else
  {
    rc = GSS_S_BAD_STATUS;
    goto exit;
  }

exit:
  /* No more messages available */
  *message_context = 0;
  IAM_TRACE_EXIT("gss_display_status",rc);

  return(rc);

malloc_fail:
  status_string->length = 0;
  rc = GSS_S_FAILURE;
  *minor_status = RETCODE_MALLOC;
  goto exit;
}

/******************************************************************************
*
*  Function Name     = PluginTerminate()
*
*  Function          = Clean up anything allocated during plugin initialization
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
SQL_API_RC SQL_API_FN PluginTerminate
(
  char     **errorMsg,
	db2int32  *errorMsgLen
)
{
  // Nothing to do
  IAM_TRACE_ENTRY("PluginTerminate");

  *errorMsg = NULL;
  *errorMsgLen = 0;
  IAM_TRACE_EXIT("PluginTerminate", 0);

  return(DB2SEC_PLUGIN_OK);
}
