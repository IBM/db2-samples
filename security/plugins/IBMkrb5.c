/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2012
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*****************************************************************************
**
** SOURCE FILE NAME: IBMkrb5.c
**
** SAMPLE: Kerberos 5 authentication security plugin
**
** GSS-APIs USED:
**         gss_accept_sec_context - accept the security context
**         gss_acquire_cred - acquire credentials handle
**         gss_delete_sec_context - delete security context
**         gss_display_name - display test representation of internal name
**         gss_display_status - display text message for status code
**         gss_import_name - convert text name into internal format
**         gss_init_sec_context - initialize the security context
**         gss_inquire_context - obtain info about current context
**         gss_inquire_cred - obtain info about default credential
**         gss_krb5_acquire_cred_ccache - obtain GSS-API cred handle from
**                                        krb5 cred cache
**         gss_release_buffer - release storage associated with internal buffer
**         gss_release_cred - release storage associated with credential handle
**         gss_release_name - releases storage associated with internal name
**
** KRB5 APIs USED:
**         krb5_build_principal_ext - build principal from component strings
**         krb5_cc_destroy - destroy credentials cache
**         krb5_cc_intialize - intialize credentials cache
**         krb5_cc_resolve - resolve credentials cache
*          krb5_free_context - free storage associated with krb5 context
**         krb5_free_principal - free storage assciated with principal
**         krb5_free_string - free text string
**         krb5_get_in_tkt_with_password - obtain tgt using userid/password
**         krb5_init_context - create a new krb5 context
**         krb5_parse_name - create a krb5 internal name from a text name
**         krb5_sname_to_principal - generate principal name from service name
**         krb5_svc_get_msg - get text message from krb5 error code
**         krb5_unparse_name - convert principal to text string
**         krb5_us_timeofday - returns time in seconds & microseconds
**
** STRUCTURES USED:
**         gss_buffer_desc
**         gss_cred_id_t
**         gss_ctx_id_t
**         gss_name_t
**         krb5_data
**         krb5_context
**         krb5_principal
**         krb5_creds
**         krb5_ccache
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
**
** For information on using SQL statements, see the SQL Reference.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************
**
** This file is setup to depend on one of three Kerberos implementations
** 1) NAS - Network Authentication Service, AIX only
** 2) Solaris Kerberos - Implementation of Kerberos on Solaris
** 3) MIT source - platforms that direclty match the MIT source implementation
**
** In order for this file to compile, one of the following must be defined
** by the caller.
** NAS_SUPPORT
** SOLARIS_KERBEROS_SUPPORT
** MIT_KERBEROS_SUPPORT
**
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


#if defined SOLARIS_KERBEROS_SUPPORT

#include <gssapi/gssapi.h>
#include <gssapi/gssapi_ext.h>

/* krb5.h is broken in Solaris.  It does not properly define 'extern "C"' at the
   beginning of the file, so we need to do it ourself.  This is on 5.10 */
#if defined(__cplusplus)
#define KRB5INT_BEGIN_DECLS     extern "C" {
#define KRB5INT_END_DECLS       }
#endif
#include <kerberosv5/krb5.h>
#include <kerberosv5/com_err.h>

#elif defined MIT_KERBEROS_SUPPORT

#include <gssapi.h>
#include <gssapi/gssapi_krb5.h>
#include <krb5.h>

/* MIT KRB5 1.5 has a new error handling message
   Mininum supported version of Linux for DB2 is still at 1.4 */
#if !defined(__linux)
#define MIT_KERBEROS_HAS_GET_ERROR_MSG
#endif
#elif defined NAS_SUPPORT

#include <gssapi/gssapi_krb5.h>
#include <ibm_svc/krb5_svc.h>

#else
#error undefined Kerberos implementation
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Since we have included the platform specific GSSAPI header files
   we will get colisions if we include gssapiDB2.h.  So make sure that
   it is not included via db2secPlugin.h */
#define _GSSAPIDB2_H
#include "db2secPlugin.h"

static const char getenvError[] = "getenv( DB2INSTANCE ) = NULL";

/* Global var to keep track of memory allocated during server init */
static char *pluginServerPrincipalName = NULL;
static gss_name_t pluginServerName = GSS_C_NO_NAME;
static gss_cred_id_t pluginServerCredHandle = GSS_C_NO_CREDENTIAL;

/* Client and server message logging functions */
db2secLogMessage *pServerLogMessage;
db2secLogMessage *pClientLogMessage;


/******************************************************************************
*
*  Function Name     = plugin_gss_display_status
*
*  Descriptive Name  = Plugin Wrapper to gss_display_status
*
*  Function          = This wrapper function needs to exist since the NAS
*                      libraries implemented this function with a slightly
*                      different prototype than outlined in IETF RFC2744
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             =
*
*  Output            =
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = GSS-API status codes returned by gss_display_status
*
*******************************************************************************/
OM_uint32 SQL_API_FN plugin_gss_display_status(  OM_uint32 *minor_status,
                                                 OM_uint32 status_value,
                                                 int status_type,
                                                 const gss_OID mech_type,
                                                 OM_uint32 * message_context,
                                                 gss_buffer_t status_string )
{
  OM_uint32 majorStatus;

  majorStatus = gss_display_status( minor_status,
                                    status_value,
                                    status_type,
                                    (gss_OID) mech_type,
                                    message_context,
                                    status_string );

  return( majorStatus );
}

/******************************************************************************
*
*  Function Name     = getGSSErrorMsg
*
*  Descriptive Name  = Get the text GSS-API text error message based on the
*                      major and minor status codes
*
*  Function          =
*
*  Dependencies      = Memory to hold error messages are alloacted and
*                      db2secFreeErrormsg() is assumed to be called to free
*                      buffer once it is no longer neede
*
*  Restrictions      = Only the first message for the major and minor status
*                      codes are obtained.  The messages are then
*                      concatenating into the ErrorMsg.
*                      No checks are performed to ascertain if buffer already
*                      allocated.
*
*  Input             =
*
*  Output            =
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None. No error message will be returned in case of error
*
*******************************************************************************/
void getGSSErrorMsg( OM_uint32 majorStatus,
                     OM_uint32 minorStatus,
                     char **ppErrorMsg,
                     db2int32 *pErrorMsgLen,
                     const char *funcName )
{
  OM_uint32 major = GSS_S_COMPLETE;
  OM_uint32 minor = GSS_S_COMPLETE;
  OM_uint32 msgContext = 0;
  gss_buffer_desc majorBuff = GSS_C_EMPTY_BUFFER;
  gss_buffer_desc minorBuff = GSS_C_EMPTY_BUFFER;
  size_t length = 0;


  /*
   * Get the first major status message
   */
  if( majorStatus != GSS_S_COMPLETE )
  {
    major = gss_display_status( &minor,
                                majorStatus,
                                GSS_C_GSS_CODE,
                                GSS_C_NULL_OID,
                                &msgContext,
                                &majorBuff );
    if( major != GSS_S_COMPLETE )
    {
      /* Nothing to really do here since we're already in an error condition */
      goto exit;
    }
  }

  /*
   * Get the first minor status message
   */
  if( minorStatus != GSS_S_COMPLETE )
  {
    major = gss_display_status( &minor,
                                minorStatus,
                                GSS_C_MECH_CODE,
                                GSS_C_NULL_OID,
                                &msgContext,
                                &minorBuff );
    if( major != GSS_S_COMPLETE )
    {
      /* Nothing to really do here since we're already in an error condition */
      goto exit;
    }
  }

  /* Allocate memory for error msg and copy
   *
   * Note: the +6 to the length is to account for the punctuation and spacing
   *       used in concatentating the error messages
   *       the +30 is to account for the two integers that are printed.
   */
  length = majorBuff.length + minorBuff.length + strlen(funcName) + 36;

  *ppErrorMsg = (char *) malloc( length );
  if( *ppErrorMsg == NULL )
  {
    goto exit;
  }
  *pErrorMsgLen = length;

  if( majorBuff.length > 0 )
  {
    if( minorBuff.length > 0 )
    {
      snprintf( *ppErrorMsg, length, "%s: (%u,%i) %.*s.  %.*s",
                   funcName, majorStatus, (krb5_error_code)minorStatus,
                   (int)majorBuff.length, (char *)majorBuff.value,
                   (int)minorBuff.length, (char *)minorBuff.value );
    }
    else
    {
      snprintf( *ppErrorMsg, length, "%s: (%u,%i)%.*s",
                   funcName, majorStatus, (krb5_error_code)minorStatus,
                   (int)majorBuff.length, (char *)majorBuff.value );
    }
  }
  else
  {
    if( minorBuff.length > 0 )
    {
      snprintf( *ppErrorMsg, length, "%s: (%u,%i) %.*s",
                   funcName, majorStatus, (krb5_error_code)minorStatus,
                   (int)minorBuff.length, (char *)minorBuff.value );
    }
    else
    {
      snprintf( *ppErrorMsg, length, "%s: (%u,%i)", funcName,
                    majorStatus, (krb5_error_code)minorStatus );
    }
  }

 exit:
  /* Free GSS-API allocated memory */
  if( majorBuff.length != 0 )
  {
    gss_release_buffer( &minor, &majorBuff );
  }
  if( minorBuff.length != 0 )
  {
    gss_release_buffer( &minor, &minorBuff );
  }

  return;
}

/******************************************************************************
*
*  Function Name     = mapPrincToAuthid
*
*  Descriptive Name  = Maps the Kerberos Principal into a DB2 AUTHID
*
*  Function          =
*
*  Dependencies      = None
*
*  Restrictions      = Assumes that the principal name is in the format
*                      name/instance@REALM
*
*  Input             = pName - Buffer containing the principal name
*
*  Output            = authid - preallocated buffer (of size
*                               DB2SEC_MAX_AUTHID_LENGTH) containing the AUTHID
*                      authidLen - length of the AUTHID string
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_BADUSER
*
*******************************************************************************/
SQL_API_RC mapPrincToAuthid( gss_buffer_t pName,
                             char *authid,
                             db2int32 *authidLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  int count;
  char *pTextName;

  /*  The authid will simply be derived from the first part of the fully
   *  qualified principal name.
   *      e.g., The authid from 'name/instance@REALM' will be 'name'
   *  DB2 will uppercase the authids and verify adherance to the naming rules
   *  so no need to do it here
   */

  pTextName = (char *) (pName->value);
  for( count=0; count < pName->length; count++ )
  {
    if( (pTextName[count] == '@') || (pTextName[count] == '/') )
    {
      break;
    }
  }

  /*
   * ALTERNATE MAPPINGS SUGGESTIONS:
   *    1 - Return full principal name
   *    2 - Read maping from a file
   */

  if( count > DB2SEC_MAX_AUTHID_LENGTH )
  {
    rc = DB2SEC_PLUGIN_BADUSER;
    goto error;
  }

  memcpy( authid, pName->value, count );
  *authidLen = count;

 exit:

  return( rc );

 error:

  goto exit;

}


/******************************************************************************
*
*  Function Name     = mapGSSAPItoDB2SECerror
*
*  Descriptive Name  = Map a GSS-API major/minor code into DB2SEC error code
*
*  Function          =
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = major - Major status code
*                      minor - Minor status code
*
*  Output            = None
*
*  Normal Return     = Various DB2SEC error code
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC mapGSSAPItoDB2SECerror( OM_uint32 major, OM_uint32 minor )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;

  krb5_error_code kMinorStatus = (krb5_error_code) minor;

  switch( major )
  {
    case GSS_S_COMPLETE:
      rc = DB2SEC_PLUGIN_OK;
      break;
    case GSS_S_BAD_NAME:
      rc = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME;
      break;
    case GSS_S_NO_CRED:
      rc = DB2SEC_PLUGIN_NO_CRED;
      break;
    case GSS_S_CREDENTIALS_EXPIRED:
      rc = DB2SEC_PLUGIN_CRED_EXPIRED;
      break;
    case GSS_S_FAILURE:
      switch( kMinorStatus )
      {
        case KRB5_FCC_NOFILE:
          rc = DB2SEC_PLUGIN_NO_CRED;
          break;
        case KRB5KRB_AP_ERR_BAD_INTEGRITY:
          rc = DB2SEC_PLUGIN_BADPWD;
          break;
        case KRB5KDC_ERR_C_PRINCIPAL_UNKNOWN:
          rc = DB2SEC_PLUGIN_BADUSER;
          break;
        case KRB5KDC_ERR_NAME_EXP:
          rc = DB2SEC_PLUGIN_UID_EXPIRED;
          break;
        case KRB5KDC_ERR_KEY_EXP:
          rc = DB2SEC_PLUGIN_PWD_EXPIRED;
          break;
        case KRB5_CC_NOTFOUND:
          rc = DB2SEC_PLUGIN_NO_CRED;
          break;
        default:
          rc = DB2SEC_PLUGIN_UNKNOWNERROR;
          break;
      }
      break;
    default:
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      break;
  }

  return( rc );
}

/******************************************************************************
*
*  Function Name     = db2secFreeErrormsg
*
*  Descriptive Name  = Free error message buffer
*
*  Function          =
*
*  Dependencies      = Memory to hold error messages are alloacted and
*                      db2secFreeErrormsg() is assumed to be called to free
*                      buffer once it is no longer neede
*
*  Restrictions      =
*
*  Input             = ppErrorMsg - Pointer to string holding the error message
*                                 that was previously allocated by one of the
*                                 db2sec* plugin functions
*
*  Output            = None
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secFreeErrormsg( char *ppErrorMsg )
{
  free( ppErrorMsg );
  return( DB2SEC_PLUGIN_OK );
}


/******************************************************************************
*
*  Function Name     = getKrb5ErrorMsg
*
*  Descriptive Name  = Get the text GSS-API text error message based on the
*                      major and minor status codes
*
*  Function          =
*
*  Dependencies      =
*
*  Restrictions      = Only the first message for the major and minor status
*                      codes are obtained.  The messages are then
*                      concatenating into the ErrorMsg.
*                      No checks are performed to ascertain if buffer already
*                      allocated.
*
*  Input             =
*
*  Output            =
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None. No error message will be returned in case of error
*
*******************************************************************************/
void getKrb5ErrorMsg( krb5_error_code kStatus,
                      char **ppErrorMsg,
                      db2int32 *pErrorMsgLen,
                      const char *funcName )
{
  char *message = NULL;
  int length = 0;

#if defined MIT_KERBEROS_SUPPORT && defined MIT_KERBEROS_HAS_GET_ERROR_MSG


  /* krb5_get_error_message is new to the MIT source in 1.5 */
  krb5_context kContext = NULL;
  krb5_error_code kstatus;
  static char szErrContext[] = "Failed to create krb5 context";

  /* Create a new krb5 context */
  kstatus = krb5_init_context( &kContext );

  if( kstatus )
  {
    message = szErrContext;
  }
  else
  {
    message = (char *) krb5_get_error_message(kContext, kStatus);
  }

#elif defined MIT_KERBEROS_SUPPORT || defined SOLARIS_KERBEROS_SUPPORT

  message = (char *) error_message(kStatus);

#elif defined NAS_SUPPORT

  krb5_svc_get_msg( (const krb5_ui_4) kStatus, &message );

#endif

  if( message )
  {
    /* +16 to account for the punctuation in the string and (0x%x) */
    length = strlen(funcName) + sizeof(kStatus) + strlen(message) + 16;

    *ppErrorMsg = (char *) malloc( length );
    if( *ppErrorMsg == NULL )
    {
      goto exit;
    }

    snprintf( *ppErrorMsg, length, "%s: (0x%x) %s", funcName, kStatus,message );
    *pErrorMsgLen = length;
  }

 exit:

#if defined MIT_KERBEROS_SUPPORT && defined MIT_KERBEROS_HAS_GET_ERROR_MSG
    if(kContext != NULL)
    {
        krb5_free_error_message(kContext, message);   /* This function can be used starting  krb5 1.5  */
        krb5_free_context( kContext );      /* destroy context */
    }
#elif defined NAS_SUPPORT

    if(message != NULL)
    {
        krb5_free_string( NULL, message );
    }

#endif

  return;
}


/**
 ** CLIENT FUNCTIONS
 **/

/******************************************************************************
*
*  Function Name     = db2secFreeToken
*
*  Descriptive Name  = Free token allocated by plug-in
*
*  Function          = Since no token is allocated by this plug-in, this
*                      function is a no-op.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = token - Pointer to plug-in allocated token
*
*  Output            = ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secFreeToken( void *token,
                                       char **ppErrorMsg,
                                       db2int32 *errorMsgLen )
{
  /* This is a no-op since we don't use the plugin token */
  return( DB2SEC_PLUGIN_OK );
}

/******************************************************************************
*
*  Function Name     = db2secGetDefaultLoginContext
*
*  Descriptive Name  =
*
*  Function          = This function will return the userid (principal name)
*                      and authid from the default login context.
*
*  Dependencies      = None.  This function will clean up all allocated
*                      resources before returing to the caller
*
*  Restrictions      =
*
*  Input             = useridtype (not used)
*                      dbname (not used)
*
*  Output            = authid
*                      userid
*                      token (not used)
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_NOTLOGGEDIN
*                      DB2SEC_PLUGIN_CRED_EXPIRED
*                      DB2SEC_PLUGIN_UNSPECIFIEDERROR
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secGetDefaultLoginContext (
                            char authid[DB2SEC_MAX_AUTHID_LENGTH],
                            db2int32 *pAuthIdLen,
                            char userid[DB2SEC_MAX_USERID_LENGTH],
                            db2int32 *useridLen,
                            db2int32 useridType,
                            char userNamespace[DB2SEC_MAX_USERNAMESPACE_LENGTH],
                            db2int32 *userNamespaceLen,
                            db2int32 *userNamespaceType,
                            const char *dbName,
                            db2int32 dbNameLen,
                            void **ppToken,
                            char **ppErrorMsg,
                            db2int32 *pErrorMsgLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  OM_uint32 majorStatus = GSS_S_COMPLETE;
  OM_uint32 minorStatus;
  gss_name_t gssName = GSS_C_NO_NAME;
  gss_buffer_desc name = GSS_C_EMPTY_BUFFER;
  gss_cred_id_t credHandle = GSS_C_NO_CREDENTIAL;
  db2int32 x = 0;

  *ppErrorMsg = NULL;
  *pErrorMsgLen = 0;

  /* Token is not allocated by this plugin */
  if( ppToken )
  {
    *ppToken = NULL;
  }

  /* Namespace is not used */
  *userNamespaceLen = 0;
  *userNamespaceType = DB2SEC_USER_NAMESPACE_UNDEFINED;

#if defined NAS_SUPPORT
  /* There is a bug in the NAS code where if the cred_handle is set to
   * GSS_C_NO_CREDENTIAL, NAS has a difficult time retreiving the correct
   * credential handle if the application has kinit, kdestroy, and then kinit
   * as another principal while the application is still up.  The workaround is
   * to explicitly grab the credential handle for the default login context and
   * pass it in to the problematic function
   */
  majorStatus = gss_acquire_cred( &minorStatus,
                                  GSS_C_NO_NAME,
                                  0,
                                  GSS_C_NO_OID_SET,
                                  GSS_C_INITIATE,
                                  &credHandle,
                                  NULL,
                                  NULL );
  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_acquire_cred" );
    goto error;
  }
#endif

  /* Obtain the name associated with the default credential */
  majorStatus = gss_inquire_cred( &minorStatus,
                                  credHandle,
                                  &gssName,
                                  NULL,   /* lifetime */
                                  NULL,   /* cred usage */
                                  NULL ); /* mechanism */
  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_inquire_cred" );
    goto error;
  }

  /* Convert internal name into text format */
  majorStatus = gss_display_name( &minorStatus, gssName, &name, NULL );
  if( majorStatus != GSS_S_COMPLETE )
  {
    if( majorStatus == GSS_S_BAD_NAME )
    {
      rc = DB2SEC_PLUGIN_BADUSER;
    }
    else
    {
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    }
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_display_name");
    goto error;
  }

  /* Don't use  complete principal name as the user name.
   *
   * */
  *useridLen = (name.length < DB2SEC_MAX_USERID_LENGTH) ?
                name.length : DB2SEC_MAX_USERID_LENGTH;
  memcpy( userid, name.value, *useridLen );

  for ( x = 0; x < *useridLen; x++ )
  {
    if ( userid[x] == '/' || userid[x] == '@'  )
    {
      userid[x] = '\0';
          *useridLen = x ;
          break;
    }
  }

  /* If the logged on userid contains any uppercase characters,
     then the userid is automatically considered bad.  This is because
     all userids on UNIX/Linux are assumed to be completely in lowercase
     or else it is impossible to uniquely map an AUTHID back to a userid
     as is required for group lookups.
  */
  for( x = 0; x < *useridLen; x++ )
  {
    if( userid[x] >= 'A' && userid[x] <= 'Z' )
    {
      rc = DB2SEC_PLUGIN_BADUSER;
      goto error;
    }
  }

  rc = mapPrincToAuthid( &name, authid, pAuthIdLen );
  if( rc != DB2SEC_PLUGIN_OK )
  {
    goto error;
  }

 exit:
  if( gssName != GSS_C_NO_NAME )
  {
    majorStatus = gss_release_name( &minorStatus, &gssName );
    if( majorStatus != GSS_S_COMPLETE )
    {
      if( *pErrorMsgLen == 0 )
      {
        getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                        "gss_release_name");
      }
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    }
  }

  if( name.length > 0 )
  {
    majorStatus = gss_release_buffer( &minorStatus, &name );
    if( majorStatus != GSS_S_COMPLETE )
    {
      if( *pErrorMsgLen == 0  && rc == DB2SEC_PLUGIN_OK )
      {
        getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                        "gss_release_buffer");
        rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      }
    }
  }

  if( credHandle != GSS_C_NO_CREDENTIAL )
  {
    majorStatus = gss_release_cred( &minorStatus, &credHandle );
    if( majorStatus != GSS_S_COMPLETE )
    {
      if( *pErrorMsgLen == 0  && rc == DB2SEC_PLUGIN_OK )
      {
        getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                        "gss_release_cred");
        rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      }
    }
  }
  return( rc );

 error:

  goto exit;
}


/******************************************************************************
*
*  Function Name     = db2secGenerateInitialCred
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
*                      userNamespace - (unused)
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
SQL_API_RC SQL_API_FN db2secGenerateInitialCred( const char *userid,
                                                 db2int32 useridLen,
                                                 const char *userNamespace,
                                                 db2int32 userNamespaceLen,
                                                 db2int32 userNamespaceType,
                                                 const char *password,
                                                 db2int32 passwordLen,
                                                 const char *newPassword,
                                                 db2int32 newPasswordLen,
                                                 const char *dbName,
                                                 db2int32 dbNameLen,
                                                 gss_cred_id_t *pGSSCredHandle,
                                                 void **ppInitInfo,
                                                 char **ppErrorMsg,
                                                 db2int32 *pErrorMsgLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  OM_uint32 majorStatus=GSS_S_COMPLETE;
  OM_uint32 minorStatus;

  int x = 0;

#if defined NAS_SUPPORT || defined MIT_KERBEROS_SUPPORT

  krb5_data tgtname={ 0, KRB5_TGS_NAME_SIZE, KRB5_TGS_NAME };
  krb5_context kContext=NULL;
  krb5_error_code kStatus=0;
  krb5_principal userPrinc=NULL;
  krb5_principal server=NULL;
  krb5_creds kCreds;
  krb5_ccache cCache=NULL;
  char cacheName[80];
  char nameSeed[40]; // 10 (seconds) + 7 (useconds) + 19 (address)
  krb5_int32 seconds;
  krb5_int32 useconds;
  int retryGrabTGT = 0;
  krb5_get_init_creds_opt  options;
  const char* cache_old_name = NULL;

#elif defined SOLARIS_KERBEROS_SUPPORT

  gss_name_t userGSSName;
  gss_buffer_desc usernameBufferDesc = {0};
  gss_buffer_desc passwordBufferDesc = {0};

#endif

  *ppErrorMsg = NULL;
  *pErrorMsgLen = 0;

  if( newPasswordLen > 0 )
  {
    rc = DB2SEC_PLUGIN_CHANGEPASSWORD_NOTSUPPORTED;
    goto exit;
  }

  if( !pGSSCredHandle )
  {
    rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
    goto exit;
  }

  /* If the logged on userid contains any uppercase characters,
     then the userid is automatically considered bad.  This is because
     all userids on UNIX/Linux are assumed to be completely in lowercase
     or else it is impossible to uniquely map an AUTHID back to a userid
     as is required for group lookups.
  */
  for( x = 0; x < useridLen; x++ )
  {
    if ( userid[x] == '/' || userid[x] == '@'  )
    {
      break;
    }

    if( userid[x] >= 'A' && userid[x] <= 'Z' )
    {
      rc = DB2SEC_PLUGIN_BADUSER;
          goto error;
    }
  }

#if defined SOLARIS_KERBEROS_SUPPORT
  passwordBufferDesc.value  = (void *)password;
  passwordBufferDesc.length = (size_t)passwordLen;

  usernameBufferDesc.value  = (void*)userid;
  usernameBufferDesc.length = (size_t)useridLen;


  majorStatus = gss_import_name( &minorStatus,
                                 &usernameBufferDesc,
                                 GSS_C_NT_USER_NAME,
                                 &userGSSName );

  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_import_name");
    goto error;
  }

  majorStatus = gss_acquire_cred_with_password( &minorStatus,
                                                userGSSName,
                                                &passwordBufferDesc,
                                                0,
                                                GSS_C_NO_OID_SET,
                                                GSS_C_INITIATE,
                                                pGSSCredHandle,
                                                NULL,   // actual_mechs
                                                NULL ); // time_rec


  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_acquire_cred_with_password");
    goto error;
  }

#elif defined NAS_SUPPORT || defined MIT_KERBEROS_SUPPORT

  /* Create a new krb5 context */
  kStatus = krb5_init_context( &kContext );
  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_init_context" );
    goto error;
  }

  /* Create principal name
   *
   * Note: userid must be in name@REALM format; if no realm is specified, the
   *       krb5_parse_name API will assume the default realm.
   */
  kStatus = krb5_parse_name( kContext, userid, &userPrinc );
  if( kStatus)
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_parse_name" );
    goto error;
  }

  /* Initialise krb5 cred structure */
  memset( (char *)&kCreds, 0, sizeof(kCreds) );

  kCreds.client = userPrinc;

  /* Build the actual krb5 principal */
  kStatus = krb5_build_principal_ext(
                                kContext,
                                &server,
                                krb5_princ_realm( kContext, userPrinc )->length,
                                krb5_princ_realm( kContext, userPrinc )->data,
                                tgtname.length,
                                tgtname.data,
                                krb5_princ_realm( kContext, userPrinc )->length,
                                krb5_princ_realm( kContext, userPrinc )->data,
                                0 );
  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen,
                     "krb5_build_principal_ext" );
    goto error;
  }

  /* Create a new credential cache in memory.  The cache name must be distinct
   * from any other that exist.  The composition of the cache name will be:
   *  CLIENT PRINCIPAL NAME + TIMESTAMP + ADDRESS OF GSS CRED HANDLE
   */
  kStatus = krb5_us_timeofday( kContext, &seconds, &useconds );
  if( kStatus)
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_us_timeofday" );
    goto error;
  }
  snprintf( nameSeed, sizeof(nameSeed), "%d%d%p",
            seconds, useconds, (void *)pGSSCredHandle  );
  snprintf( cacheName, sizeof(cacheName), "MEMORY:%s%s", userid, nameSeed );

  kStatus = krb5_cc_resolve( kContext, cacheName, &cCache );
  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_cc_resolve" );
    goto error;
  }

  /* Initalise the new cred cache */
  kStatus = krb5_cc_initialize( kContext, cCache, kCreds.client );
  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_cc_initialize" );
    goto error;
  }

  kCreds.server = server;
  /* Use default lifetime */
  kCreds.times.starttime = 0;
  kCreds.times.endtime = 0;

 grabTGT:


   krb5_get_init_creds_opt_init(&options);
   krb5_get_init_creds_opt_set_forwardable (&options, 1);

   /* Use the password to grab a forwardable TGT  */

   kStatus = krb5_get_init_creds_password( kContext, &kCreds, kCreds.client, (char*)password,
                                                     NULL ,
                                                     NULL ,
                                                     0 ,
                                                     0 ,
                                                     &options  );


  if( kStatus )
  {

    /* Complete krb5 error listing in krb5krb.h */
    switch( kStatus )
    {
      case KRB5KDC_ERR_PREAUTH_FAILED:
      case KRB5KRB_AP_ERR_BAD_INTEGRITY:
        rc = DB2SEC_PLUGIN_BADPWD;
        break;
      case KRB5KDC_ERR_C_PRINCIPAL_UNKNOWN:
        /* In addition to a bad user, this error occurs if the user exists but
         * the KRB5_DISALLOW_ALL_TIX flag is set for the principal */
        rc = DB2SEC_PLUGIN_BADUSER;
        break;
      case KRB5KDC_ERR_KEY_EXP:
        /* Both normal password expiry and admin forced expiry */
        rc = DB2SEC_PLUGIN_PWD_EXPIRED;
        break;
      case KRB5KDC_ERR_NAME_EXP:
        rc = DB2SEC_PLUGIN_UID_EXPIRED;
        break;
      case KRB5KDC_ERR_POLICY:
        /* Likely, local policies prohibit this user from requesting forwardable
         * tickets.  In this case try grabbing the ticket one more time without
         * the forwardable flag
         */
        if( !retryGrabTGT )
        {
          retryGrabTGT = 1;
          goto grabTGT;
        }
        /* else fall into default: case */
      default:
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        break;
    }
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen,
                     "krb5_get_init_creds_password" );
    goto error;
  }


#ifdef MIT_KERBEROS_SUPPORT

  /* set the new credentials cache name */

  kStatus = gss_krb5_ccache_name(&minorStatus, cacheName, &cache_old_name);  // The data allocated for cache_old_name is free upon next call to gss_krb5_ccache_name().

  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getGSSErrorMsg( kStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_krb5_ccache_name");
    goto error;
 }

  /* place in the new cred cache */

  kStatus = krb5_cc_store_cred(kContext, cCache, &kCreds);

  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_cc_store_cred" );
    goto error;
  }

  kStatus = gss_acquire_cred( &minorStatus,
                                    GSS_C_NO_NAME,
                                    0,
                                    GSS_C_NO_OID_SET,
                                    GSS_C_INITIATE,
                                    pGSSCredHandle,
                                    NULL,
                                    NULL );
  if( kStatus != GSS_S_COMPLETE )
  {
    rc = DB2SEC_PLUGIN_NO_CRED;
    getGSSErrorMsg( kStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_acquire_cred");
    goto error;
  }

   /* set the original credentials cache name back */

  kStatus = gss_krb5_ccache_name(&minorStatus, cache_old_name, NULL);

  if( kStatus != GSS_S_COMPLETE )
  {
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      getGSSErrorMsg( kStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_krb5_ccache_name");
      goto error;
  }

#else

  /* place in the new cred cache */

  kStatus = krb5_cc_store_cred(kContext, cCache, &kCreds);

  if( kStatus )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_cc_store_cred" );
    goto error;
  }

  /*
   * Acquire a GSS-API credential handle
   *
   * The following API is only available with IBM NAS. It is able convert a krb5
   * cred cache handle into a GSS-API cred handle very nicely.  Notice that
   * there is no need to resort to placing the credentials in the default
   * cred cache.
   */

  majorStatus = gss_krb5_acquire_cred_ccache( &minorStatus,
                                              cCache,
                                              0,    /* use default lifetime */
                                              GSS_C_INITIATE,
                                              pGSSCredHandle,
                                              NULL); /* Cred time returned */
  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_krb5_acquire_cred_ccache");
    goto error;
  }
#endif

  /* Save the krb5 context so that they can be cleaned up properly after
   * authentication is complete.  Note, the krb5 cred cache does not need to
   * be stored and freed later.  This is because it is a memory cache and
   * the call to gss_release_cred() will implicitly free it.
   */
  *ppInitInfo = (void *) kContext;

  /* no longer need principal objects */
  if ( userPrinc )
  {
    krb5_free_principal(kContext, userPrinc);
  }
  if ( server )
  {
    krb5_free_principal(kContext, server);
  }

#endif              // defined NAS_SUPORT || defined MIT_KERBEROS_SUPPORT

#if defined SOLARIS_KERBEROS_SUPPORT
  if( userGSSName != GSS_C_NO_NAME )
  {
    majorStatus = gss_release_name( &minorStatus, &userGSSName );
    if( majorStatus != GSS_S_COMPLETE )
    {
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                      "gss_release_name");
      goto error;
    }
  }
#endif


exit:

  return( rc );

error:

#if defined NAS_SUPPORT || defined MIT_KERBEROS_SUPPORT
  if( kContext )
  {
      if (cCache)
      {
          krb5_cc_destroy(kContext, cCache); /* destroy cred cache */
      }
      if ( userPrinc )
      {
          krb5_free_principal(kContext, userPrinc );
      }
      if ( server )
      {
          krb5_free_principal(kContext, server);
      }
      krb5_free_context( kContext );      /* destroy context */
  }
#endif

#if defined SOLARIS_KERBEROS_SUPPORT
  if( userGSSName != GSS_C_NO_NAME )
  {
    gss_release_name( &minorStatus, &userGSSName );
  }
#endif

  if( pGSSCredHandle )
  {
     gss_release_cred( &minorStatus, pGSSCredHandle );
  }

  goto exit;

}

/******************************************************************************
*
*  Function Name     = db2secProcessServerPrincipalName
*
*  Descriptive Name  =
*
*  Function          = Convert text service principal name into the GSS-API
*                      internal format for use with the other APIs
*
*  Dependencies      = Client-side routine only.
*                      DB2 will call gss_release_name at the appropriate time
*                      to clean up the gss_name_t structure
*
*  Restrictions      =
*
*  Input             = name - Text service principal name string pointer
*                      nameLen - Text string length
*
*  Output            = gssName - Internal GSS-API name structure
*                      ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME
*                      DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secProcessServerPrincipalName( const char *name,
                                                        db2int32 nameLen,
                                                        gss_name_t *gssName,
                                                        char **ppErrorMsg,
                                                        db2int32 *pErrorMsgLen )
{
  gss_buffer_desc nameBuff;
  OM_uint32 majorStatus=GSS_S_COMPLETE;
  OM_uint32 minorStatus;
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;

  *ppErrorMsg = NULL;
  *pErrorMsgLen = 0;

  if( gssName == NULL )
  {
    rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
    goto error;
  }

  if( nameLen > 0 )
  {
    /*
     * DRDA stipulates that the Kerberos principal name be sent in the
     * GSS_C_NT_USER_NAME format, e.g., name/host@REALM
     */
    nameBuff.value = (void *) name;
    nameBuff.length = (OM_uint32 ) nameLen;

    majorStatus = gss_import_name( &minorStatus,
                                   &nameBuff,
                                   GSS_C_NT_USER_NAME,
                                   gssName );
    if( majorStatus != GSS_S_COMPLETE )
    {
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                      "gss_import_name");
      goto error;
    }
  }

 exit:

  return( rc );

 error:

  goto exit;

}

/******************************************************************************
*
*  Function Name     = db2secFreeInitInfo
*
*  Descriptive Name  = Free krb5 objects allocated in db2secGenerateInitialCred
*
*  Function          = Free the krb5 context created in
*                      db2secGenerateInitialCred.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = initInfo - Pointer to any krb5 objects allocated by
*                                 db2secGenerateInitialCred
*
*  Output            = ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secFreeInitInfo( void *initInfo,
                                          char **ppErrorMsg,
                                          db2int32 *pErrorMsgLen )
{
  if( initInfo )
  {
    krb5_free_context( (krb5_context) initInfo );
  }

  return( DB2SEC_PLUGIN_OK );
}


/******************************************************************************
*
*  Function Name     = plugin_gss_init_sec_context
*
*  Descriptive Name  =
*
*  Function          = This wrapper function needs to exist since the NAS
*                      libraries implemented this function with a slightly
*                      different prototype than outlined in IETF RFC2744
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             =
*
*  Output            =
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = Various GSS-API errors returned by gss_init_sec_context
*
*******************************************************************************/
OM_uint32 SQL_API_FN plugin_gss_init_sec_context(
                               OM_uint32 *minor_status,
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
                               OM_uint32 * time_rec )
{
  OM_uint32 majorStatus = GSS_S_COMPLETE;
  OM_uint32 major = GSS_S_COMPLETE;
  OM_uint32 minor = GSS_S_COMPLETE;

  gss_cred_id_t credHandle = GSS_C_NO_CREDENTIAL;

  /* There is a bug in the NAS code where if the cred_handle is set to
   * GSS_C_NO_CREDENTIAL, NAS has a difficult time retreiving the correct
   * credential handle if the application has kinit, kdestroy, and then kinit
   * as another principal while the application is still up.  The workaround is
   * to explicitly grab the credential handle for the default login context and
   * pass it in to the problematic function
   */

  if( cred_handle == GSS_C_NO_CREDENTIAL )
  {
    majorStatus = gss_acquire_cred( minor_status,
                                    GSS_C_NO_NAME,
                                    0,
                                    GSS_C_NO_OID_SET,
                                    GSS_C_INITIATE,
                                    &credHandle,
                                    NULL,
                                    NULL );
    if( majorStatus != GSS_S_COMPLETE )
    {
      goto error;
    }
  }
  else
  {
    credHandle = cred_handle;
  }

  majorStatus = gss_init_sec_context(
                                   minor_status,
                                   (gss_cred_id_t) credHandle,
                                   context_handle,
                                   (gss_name_t) target_name,
                                   (gss_OID) mech_type,
                                   req_flags,
                                   time_req,
                                   (gss_channel_bindings_t) input_chan_bindings,
                                   (gss_buffer_t) input_token,
                                   actual_mech_type,
                                   output_token,
                                   ret_flags,
                                   time_rec );

 exit:

  if( cred_handle == GSS_C_NO_CREDENTIAL )
  {
    major = gss_release_cred( &minor, &credHandle );
    if( major != GSS_S_COMPLETE && majorStatus == GSS_S_COMPLETE)
    {
      majorStatus = major;
      *minor_status = minor;
    }
  }

  return( majorStatus );

 error:

  goto exit;
}

/******************************************************************************
*
*  Function Name     = db2secClientAuthPluginTerm
*
*  Descriptive Name  =
*
*  Function          = Client plugin clean-up code called during termination
*                      of the client-side plugin.  Since nothing is required
*                      to be cleaned up on the client side, this funciton is
*                      a no-op.
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = None
*
*  Output            = ppErrorMsg - (not used)
*                      pErrorMsgLen - (not used)
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secClientAuthPluginTerm( char **ppErrorMsg,
                                                  db2int32 *pErrorMsgLen )
{
  /* Nothing to do */
  return( DB2SEC_PLUGIN_OK );
}

/******************************************************************************
*
*  Function Name     = db2secClientAuthPluginInit
*
*  Descriptive Name  = Initialization routine for client plugin startup
*
*  Function          =
*
*  Dependencies      =
*
*  Restrictions      = This function must use C-linkage
*
*  Input             = version - The plug-in API version supported by DB2
*                      logMessage_fn - Function pointer to allow plugin to
*                                      log a message into the db2diag.log
*
*  Output            = pFunctions - Function pointer structure populated with
*                                   client-side functions
*                      ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_INCOMPATIBLE_VER
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secClientAuthPluginInit(
                                                db2int32 version,
                                                void *pFunctions,
                                                db2secLogMessage *logMessage_fn,
                                                char **ppErrorMsg,
                                                db2int32 *pErrorMsgLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  db2secGssapiClientAuthFunctions_1 *pFPs;

  *ppErrorMsg = NULL;
  *pErrorMsgLen = 0;

  if( version < DB2SEC_GSSAPI_CLIENT_AUTH_FUNCTIONS_VERSION_1 )
  {
    rc = DB2SEC_PLUGIN_INCOMPATIBLE_VER;
    goto exit;
  }

  pClientLogMessage = logMessage_fn;

  pFPs = (db2secGssapiClientAuthFunctions_1 *) pFunctions;
  pFPs->plugintype = DB2SEC_PLUGIN_TYPE_KERBEROS;
  pFPs->version = DB2SEC_GSSAPI_CLIENT_AUTH_FUNCTIONS_VERSION_1;

  /* Set up function pointers */
  pFPs->db2secGetDefaultLoginContext = db2secGetDefaultLoginContext;
  pFPs->db2secGenerateInitialCred = db2secGenerateInitialCred;
  pFPs->db2secProcessServerPrincipalName = db2secProcessServerPrincipalName;
  pFPs->db2secFreeToken = db2secFreeToken;
  pFPs->db2secFreeErrormsg = db2secFreeErrormsg;
  pFPs->db2secFreeInitInfo = db2secFreeInitInfo;
  pFPs->db2secClientAuthPluginTerm = db2secClientAuthPluginTerm;
  pFPs->gss_init_sec_context = plugin_gss_init_sec_context;
  pFPs->gss_delete_sec_context = gss_delete_sec_context;
  pFPs->gss_display_status = plugin_gss_display_status;
  pFPs->gss_release_buffer = gss_release_buffer;
  pFPs->gss_release_cred = gss_release_cred;
  pFPs->gss_release_name = gss_release_name;

 exit:

  return( rc );
}


/*
 * SERVER FUNCTIONS
 */

/******************************************************************************
*
*  Function Name     = db2secGetAuthIDs
*
*  Descriptive Name  =
*
*  Function          =
*
*  Dependencies      = At this point, the GSS-API context is assumed to have
*                      been established and the context handle is passed in
*                      as the token
*
*  Restrictions      = Server-side routine only
*                      The token is assumed to be the GSS-API context handle
*
*  Input             = userid (not used)
*                      userNameSpace (not used)
*                      dbName (not used)
*                      token - GSS-API context handle
*
*  Output            = systemAuthID / systemAuthIDLen,
*                      initialSessionAuthID / initialSessionAuthIDLen,
*                      userName / userNameLen
*                      initSessionIDType (not used)
*                      ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      =
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secGetAuthIDs(
                            const char *userid,
                            db2int32 useridLen,
                            const char *userNameSpace,
                            db2int32 userNameSpaceLen,
                            db2int32 userNameSpaceType,
                            const char *dbName,
                            db2int32 dbNameLen,
                            void **ppToken,
                            char systemAuthID[DB2SEC_MAX_AUTHID_LENGTH],
                            db2int32 *systemAuthIDLen,
                            char initialSessionAuthID[DB2SEC_MAX_AUTHID_LENGTH],
                            db2int32 *initialSessionAuthIDLen,
                            char userName[DB2SEC_MAX_USERID_LENGTH],
                            db2int32 *userNameLen,
                            db2int32  *initSessionIDType,
                            char **ppErrorMsg,
                            db2int32 *pErrorMsgLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  OM_uint32 majorStatus = GSS_S_COMPLETE;
  OM_uint32 minorStatus;
  gss_ctx_id_t ctxHandle;
  gss_name_t srcName = GSS_C_NO_NAME;
  gss_buffer_desc textName = GSS_C_EMPTY_BUFFER;

  *ppErrorMsg = NULL;
  *pErrorMsgLen = 0;

  // If a userid was provided, we've been asked to do userid only
  int useridOnlyValidation = (useridLen > 0);

  if (useridOnlyValidation)
  {
     textName.length = useridLen;
     textName.value = (void * )userid;
  }
  else
  {
     ctxHandle = (gss_ctx_id_t) (*ppToken);

     majorStatus = gss_inquire_context( &minorStatus,
                                        ctxHandle,
                                        &srcName,
                                        NULL,    /* target name */
                                        NULL,    /* cred lifetime */
                                        NULL,    /* mech type */
                                        NULL,    /* flags */
                                        NULL,    /* local context */
                                        NULL ); /* ctx establishment complete */
     if( majorStatus != GSS_S_COMPLETE )
     {
       rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
       getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                       "gss_inquire_context" );
       goto error;
     }

     /* Obtain textual representation of the internal name */
     majorStatus = gss_display_name( &minorStatus,
                                     srcName,
                                     &textName,
                                     NULL );       /* name type */
     if( majorStatus != GSS_S_COMPLETE )
     {
       if( majorStatus == GSS_S_BAD_NAME )
       {
         rc = DB2SEC_PLUGIN_BADUSER;
       }
       else
       {
         rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
       }
       /* Obtain descriptive text message */
       getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                       "gss_display_name" );
       goto error;
     }
  }

  /* Use the complete principal name as the user name.
   *
   * Truncation is okay since the reported username is only informational */
  *userNameLen = (textName.length < DB2SEC_MAX_USERID_LENGTH) ?
                  textName.length : DB2SEC_MAX_USERID_LENGTH;
  memcpy( userName, textName.value, *userNameLen );

  rc = mapPrincToAuthid( &textName, systemAuthID, systemAuthIDLen );
  if( rc != DB2SEC_PLUGIN_OK )
  {
    goto error;
  }

  /* Set the initial session authid to be the same as the system authid */
  memcpy( initialSessionAuthID, systemAuthID, *systemAuthIDLen );
  *initialSessionAuthIDLen = *systemAuthIDLen;

 exit:

  if( srcName != GSS_C_NO_NAME )
  {
    majorStatus = gss_release_name( &minorStatus, &srcName );
    if( majorStatus != GSS_S_COMPLETE )
    {
      if( rc == DB2SEC_PLUGIN_OK && *pErrorMsgLen == 0 )
      {
        getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                        "gss_release_name" );
        rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      }
    }
  }

  if ( ( textName.length > 0 ) && (!useridOnlyValidation) )
  {
    majorStatus = gss_release_buffer( &minorStatus, &textName );
    if( majorStatus != GSS_S_COMPLETE )
    {
      if( rc == DB2SEC_PLUGIN_OK && *pErrorMsgLen == 0 )
      {
        getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                        "gss_release_buffer" );
        rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      }
    }
  }

  return( rc );

 error:

  goto exit;
}

/******************************************************************************
*
*  Function Name     = db2secDoesAuthIDExist
*
*  Descriptive Name  = Informs DB2 whether the provided AUTHID corresponds to
*                      an existing Kerberos principal
*
*  Function          = There is no way to determine if a particular principal
*                      exists using GSS-API so this function will always
*                      return DB2SEC_PLUGIN_USERSTATUSNOTKNOWN
*
*  Dependencies      = None
*
*  Restrictions      =
*
*  Input             = authid - DB2 AUTHID
*                      authidLen - Length of AUTHID string
*
*  Output            = ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_USERSTATUSNOTKNOWN
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secDoesAuthIDExist( const char *authid,
                                             db2int32 authidLen,
                                             char **ppErrorMsg,
                                             db2int32 *pErrorMsgLen )
{
  /* This is not possible through GSS-API so for now always return
   * DB2SEC_PLUGIN_USERSTATUSNOTKNOWN.
   */

  return( DB2SEC_PLUGIN_USERSTATUSNOTKNOWN );
}

/******************************************************************************
*
*  Function Name     = plugin_gss_accept_sec_context
*
*  Descriptive Name  =
*
*  Function          = This wrapper function needs to exist since the NAS
*                      libraries implemented this function with a slightly
*                      different prototype than outlined in IETF RFC2744
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             =
*
*  Output            =
*
*  Normal Return     = GSS_S_COMPLETE
*
*  Error Return      = Various GSS-API status codes from gss_accept_sec_context
*
*******************************************************************************/
OM_uint32 SQL_API_FN plugin_gss_accept_sec_context(
                               OM_uint32 *minor_status,
                               gss_ctx_id_t * context_handle,
                               const gss_cred_id_t acceptor_cred_handle,
                               const gss_buffer_t input_token,
                               const gss_channel_bindings_t input_chan_bindings,
                               gss_name_t * src_name,
                               gss_OID * mech_type,
                               gss_buffer_t output_token,
                               OM_uint32 * ret_flags,
                               OM_uint32 * time_rec,
                               gss_cred_id_t * delegated_cred_handle )
{
  OM_uint32 majorStatus;

  majorStatus = gss_accept_sec_context(
                                   minor_status,
                                   context_handle,
                                   (gss_cred_id_t) acceptor_cred_handle,
                                   (gss_buffer_t) input_token,
                                   (gss_channel_bindings_t) input_chan_bindings,
                                   src_name,
                                   mech_type,
                                   output_token,
                                   ret_flags,
                                   time_rec,
                                   delegated_cred_handle );

  return( majorStatus );
}

/******************************************************************************
*
*  Function Name     = db2secServerAuthPluginTerm
*
*  Descriptive Name  = Server plugin termination routine
*
*  Function          = Clean up memory allocated at plugin init time and also
*                      reset all the global variables as DB2 may call the
*                      db2secServerAuthPluginInit function right after this call
*
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = None
*
*  Output            = ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = None
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secServerAuthPluginTerm( char **ppErrorMsg,
                                                  db2int32 *pErrorMsgLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  OM_uint32 majorStatus;
  OM_uint32 minorStatus;

  *ppErrorMsg = NULL;
  *pErrorMsgLen = 0;

  if( pluginServerPrincipalName )
  {
    free( pluginServerPrincipalName );
    pluginServerPrincipalName = NULL;
  }

  if( pluginServerName )
  {
    majorStatus = gss_release_name( &minorStatus, &pluginServerName );
    if( majorStatus!= GSS_S_COMPLETE )
    {
      getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                      "gss_release_name" );
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    }
  }

  if( pluginServerCredHandle )
  {
    majorStatus = gss_release_cred( &minorStatus, &pluginServerCredHandle );
    if( majorStatus != GSS_S_COMPLETE )
    {
      /* Don't want to overwrite previous message if there is one */
      if( rc == DB2SEC_PLUGIN_OK && *pErrorMsgLen == 0 )
      {
        getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                        "gss_release_cred" );
        rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
      }
    }
  }

  return( rc );
}

/******************************************************************************
*
*  Function Name     = db2secServerAuthPluginInit
*
*  Descriptive Name  = Initialize server-side plugin support
*
*  Function          = Obtain all initial information required by the server
*                      plugin and populate the function pointer structure
*
*  Dependencies      = None
*
*  Restrictions      = This function must use C linkage
*
*  Input             = version - The plug-in API version supported by DB2
*                      db2secGetConDetailsFP - Function pointer to a DB2
*                                              function that will return the
*                                              connection details
*                      logMessage_fn - Function pointer to allow plugin to
*                                      log a message into the db2diag.log
*
*  Output            = functions - Function pointer structure populated with
*                                  server-side functions
*                      ppErrorMsg - Pointer to a string that will contain
*                                   an error message
*                      errorMsgLen - Pointer to the length of the error message
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_INCOMPATIBLE_VER
*
*******************************************************************************/
SQL_API_RC SQL_API_FN db2secServerAuthPluginInit(
                                     db2int32 version,
                                     void *functions,
                                     db2secGetConDetails *db2secGetConDetailsFP,
                                     db2secLogMessage *logMessage_fn,
                                     char **ppErrorMsg,
                                     db2int32 *pErrorMsgLen )
{
  SQL_API_RC rc = DB2SEC_PLUGIN_OK;
  db2secGssapiServerAuthFunctions_1 *pFPs;
  char *principalName;
  OM_uint32 majorStatus;
  OM_uint32 minorStatus;
  char *instName = NULL;
  char *envVar = NULL;
  int length = 0;
  krb5_context kContext = NULL;
  krb5_error_code kStatus = 0;
  krb5_principal kServer = NULL;

  if( ppErrorMsg )
  {
    *ppErrorMsg = NULL;
    *pErrorMsgLen = 0;
  }

  if( version < DB2SEC_GSSAPI_SERVER_AUTH_FUNCTIONS_VERSION_1 )
  {
    rc = DB2SEC_PLUGIN_INCOMPATIBLE_VER;
    goto exit;
  }

  pServerLogMessage = logMessage_fn;

  pFPs = (db2secGssapiServerAuthFunctions_1 *) functions;
  pFPs->plugintype = DB2SEC_PLUGIN_TYPE_KERBEROS;
  pFPs->version = DB2SEC_GSSAPI_SERVER_AUTH_FUNCTIONS_VERSION_1;

  /* Check if server plugin is being initialized without have previously been
   * properly terminated.
   *
   * If any of the global server-side variables have been set, then it means
   * that we're initializing the plugin again before terminating it first.
   * DB2 expects the plugin to call the termination routine itself in this case
   */
  if( pluginServerPrincipalName
      || pluginServerName != GSS_C_NO_NAME
      || pluginServerCredHandle != GSS_C_NO_CREDENTIAL )
  {
    rc = db2secServerAuthPluginTerm( ppErrorMsg, pErrorMsgLen );
    if( rc != DB2SEC_PLUGIN_OK )
    {
      goto error;
    }
  }

  /*
   * Populate the server principal name
   *
   * If the environment variable DB2_KRB5_PRINCIPAL is set, then use it as it
   *  should contain the fully qualified service principal name.  Otherwise,
   *  the principal name will be assumed to be
   *  <instance name>/<fully qualified host>@<REALM>
   */

  envVar = getenv( "DB2_KRB5_PRINCIPAL" );
  if( envVar )
  {
    length = strlen( envVar );
    principalName = (char *) malloc( length + 1 );
    if( !principalName )
    {
      rc = DB2SEC_PLUGIN_NOMEM;
      goto error;
    }
    memcpy( principalName, envVar, length + 1 );
  }
  else
  {
    instName = getenv( "DB2INSTANCE" );
    if( !instName )
    {
      *pErrorMsgLen = strlen( getenvError ) + 1;
      *ppErrorMsg = (char *) malloc( *pErrorMsgLen );
      if( ppErrorMsg )
      {
        snprintf( *ppErrorMsg, *pErrorMsgLen, getenvError );
      }
      else  /* At least write an error message into the db2diag.log */
      {
        pServerLogMessage( DB2SEC_LOG_ERROR, (void *)getenvError,
                           *pErrorMsgLen );
      }
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto error;
    }

    /* Create a new krb5 context */
    kStatus = krb5_init_context( &kContext );
    if( kStatus )
    {
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_init_context" );
      goto error;
    }

    kStatus = krb5_sname_to_principal( kContext,
                                       NULL,      /* use local host */
                                       (const char *) instName,
                                       KRB5_NT_SRV_HST,
                                       &kServer );
    if( kStatus )
    {
      rc = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME;
      getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen,
                       "krb5_sname_to_principal" );
      goto error;
    }

    kStatus = krb5_unparse_name( kContext, kServer, &principalName );
    if( kStatus )
    {
      rc = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME;
      getKrb5ErrorMsg( kStatus, ppErrorMsg, pErrorMsgLen, "krb5_unparse_name" );
      goto error;
    }
  }

  pFPs->serverPrincipalName.value = principalName;
  pFPs->serverPrincipalName.length = strlen( principalName );

  /* log the service principal name as informational diagnostics */
  pServerLogMessage( DB2SEC_LOG_INFO,
                     (void *)"Kerberos service principal name:",
                     strlen( "Kerberos service principal name:" ) );
  pServerLogMessage( DB2SEC_LOG_INFO,
                     pFPs->serverPrincipalName.value,
                     pFPs->serverPrincipalName.length );

  /* Copy to global var so that we can deallocate during termination */
  pluginServerPrincipalName = principalName;

  /*
   * Fill in the server's cred handle
   */
  majorStatus = gss_import_name( &minorStatus,
                                 &(pFPs->serverPrincipalName),
                                 GSS_C_NT_USER_NAME,
                                 &pluginServerName );
  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_import_name" );
    goto error;
  }

  /* Note: Picking up environment variables that alter the default keytab
   *       location, e.g., KRB5_KTNAME, may not be possible in the plugin as we
   *       are running within a DB2 agent process
   */
  majorStatus = gss_acquire_cred( &minorStatus,
                                  pluginServerName,
                                  0,      /* request default time */
                                  GSS_C_NO_OID_SET,
                                  GSS_C_ACCEPT,
                                  &(pFPs->serverCredHandle),
                                  NULL,   /* actual mech type */
                                  NULL ); /* actual cred time */
  if( majorStatus != GSS_S_COMPLETE )
  {
    rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                    "gss_acquire_cred" );
    goto error;
  }

  /* Copy to global var so that we can deallocate during termination */
  pluginServerCredHandle = pFPs->serverCredHandle;

  /*
   * Set up function pointers
   */
  pFPs->db2secGetAuthIDs = db2secGetAuthIDs;
  pFPs->db2secDoesAuthIDExist = db2secDoesAuthIDExist;
  pFPs->db2secFreeErrormsg = db2secFreeErrormsg;
  pFPs->db2secServerAuthPluginTerm = db2secServerAuthPluginTerm;
  pFPs->gss_accept_sec_context = plugin_gss_accept_sec_context;
  pFPs->gss_display_name = gss_display_name;
  pFPs->gss_delete_sec_context = gss_delete_sec_context;
  pFPs->gss_display_status = plugin_gss_display_status;
  pFPs->gss_release_buffer = gss_release_buffer;
  pFPs->gss_release_cred = gss_release_cred;
  pFPs->gss_release_name = gss_release_name;

 exit:

  if( kContext )
  {
    if( kServer )
    {
      krb5_free_principal( kContext, kServer );
    }
    krb5_free_context( kContext );
  }

  return( rc );

 error:

  /* Clean up any allocated memory */
  if( pluginServerPrincipalName )
  {
    free( pluginServerPrincipalName );
    pluginServerPrincipalName = NULL;
  }

  if( pluginServerName )
  {
    majorStatus = gss_release_name( &minorStatus, &pluginServerName );
    /* Don't want to overwrite previous message if there is one */
    if( majorStatus != GSS_S_COMPLETE
        && rc == DB2SEC_PLUGIN_OK && *pErrorMsgLen == 0)
    {
      getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                      "gss_release_name" );
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    }
  }

  if( pluginServerCredHandle )
  {
    majorStatus = gss_release_cred( &minorStatus, &pluginServerCredHandle );
    /* Don't want to overwrite previous message if there is one */
    if( majorStatus != GSS_S_COMPLETE
        && rc == DB2SEC_PLUGIN_OK && *pErrorMsgLen == 0)
    {
      getGSSErrorMsg( majorStatus, minorStatus, ppErrorMsg, pErrorMsgLen,
                      "gss_release_cred" );
      rc = mapGSSAPItoDB2SECerror( majorStatus, minorStatus );
    }
  }

  pFPs->serverPrincipalName.value = NULL;
  pFPs->serverPrincipalName.length = 0;
  pFPs->serverCredHandle = GSS_C_NO_CREDENTIAL;

  goto exit;
}

#ifdef __cplusplus
}
#endif
