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
*****************************************************************************
**
**  Source File Name = src/gss/AWSIAMauth.h
**
**  Descriptive Name = Base header file for AWS IAM authentication plugin libraries
**
**
**  
**
*******************************************************************************/
#ifndef _AWS_IAM_AUTH_H
#define _AWS_IAM_AUTH_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <syslog.h>

#ifdef SQLUNIX
#include <unistd.h>
#include <sys/types.h>
#else
#define strcasecmp(a,b) stricmp(a,b)
#define snprintf _snprintf
#endif

#include <sqlenv.h>
#include <db2secPlugin.h>

/* Authentication types */
#define DB2SEC_AUTH_PASSWORD          0   // Authenticate using user/password
#define DB2SEC_AUTH_APIKEY            1   // Authenticate using API key
#define DB2SEC_AUTH_ACCESS_TOKEN      2   // Authenticate using access token

static const char *authTypeToString[] =
{
  "DB2SEC_AUTH_PASSWORD",
  "DB2SEC_AUTH_APIKEY",
  "DB2SEC_AUTH_ACCESS_TOKEN"
};

static db2secLogMessage *logFunc;

#define PRINCIPAL_NAME "AWSIAMauth"

/* Minor Status Codes
 * Ordering of messages is important as it corresponds to the
 * appropriate minor status codes
 */
static const char *retcodeMessage[] =
{
  "Operation completed successfully",            /* RETCODE_OK */
  "Credential failed authenticaiton",            /* RETCODE_BADPASS */
  "Unexpected input token provided",             /* RETCODE_BADTOKEN */
  "Mutual authentication failure",               /* RETCODE_MUTFAIL */
  "Illegal call to gss_init/accept_sec_context", /* RETCODE_PROGERR */
  "Memory allocation error",                     /* RETCODE_MALLOC */
  "Error processing user definition file",       /* RETCODE_USERFILE */
  "No credentials provided",                     /* RETCODE_NOCRED */
  "The database connection is not successful",    /* RETCODE_BADCONNECTION */
  "Error description not available"              /* RETCODE_UNKNOWN */
};

#define RETCODE_OK        0
#define RETCODE_BADPASS   1
#define RETCODE_BADTOKEN  2
#define RETCODE_MUTFAIL   3
#define RETCODE_PROGERR   4
#define RETCODE_MALLOC    5
#define RETCODE_USERFILE  6
#define RETCODE_NOCRED    7
#define RETCODE_BADCONNECTION 8
#define RETCODE_UNKNOWN   9
#define RETCODE_AWS_NO_USER_ATTRI   10
#define RETCODE_BADCFG      11
#define RETCODE_MAXCODE		RETCODE_UNKNOWN

#define GSS_S_AZURE_COMPLETE 1

#define MAJOR_CODE_STRING	PRINCIPAL_NAME " plugin encounted an error"

#define SQL_AUTH_IDENT           128

/* Format of the token */
#define TOKEN_MAX_STRLEN	       1096  // AWS JWT token max length
#define TOKEN_MAX_AUTH_TOKEN_LEN 8192  // IAM access can have theoretically
#define IP_BUFFER_SIZE           16    // IP address 

// _authInfo is used to carry the different types of credentials to be flown
// between client and server security plugin
typedef struct _authInfo
{ 
  OM_uint32 version;
  OM_uint32 authType;
  OM_uint32 authTokenLen;
  OM_uint32 useridLen;
  char data[1];
} AUTHINFO_VERSION_1_T ;

#define AUTHINFO_VERSION_1 1
#define AUTHINFO_T AUTHINFO_VERSION_1_T
typedef struct _name
{
  int useridLen;
  char *userid;
} NAME_T;

// Our GSS-API credential
typedef struct _cred
{
  int authtype;
  int useridLen;
  char *userid;
  int authtokenLen;
  char *authtoken;
} CRED_T;

typedef struct _group_name {
    char *group_name;
    size_t len;
} group_name_t;

typedef struct _context
{
  int sourceLen;
  char *source;
  int targetLen;
  char *target;
  int ctxCount;
  int groupCount;
  group_name_t* groups;
} CONTEXT_T;

OM_uint32 getClientIPAddress(char szIPAddress[], int maxLength);
int ByteReverse(int input);
SQL_API_RC SQL_API_FN FreeErrorMessage(char *errormsg);
OM_uint32 SQL_API_FN gss_release_cred(OM_uint32 *minorStatus,
                            gss_cred_id_t *pCredHandle);
OM_uint32 SQL_API_FN gss_release_name(OM_uint32 *minorStatus,
                            gss_name_t *name);
OM_uint32 SQL_API_FN gss_release_buffer(OM_uint32 *minorStatus,
                              gss_buffer_t buffer);

OM_uint32 SQL_API_FN gss_delete_sec_context(OM_uint32 *minorStatus,
                                 gss_ctx_id_t *context_handle,
                                 gss_buffer_t output_token);

OM_uint32 SQL_API_FN gss_display_status(OM_uint32 *minor_status,
                             OM_uint32 status_value,
                             int status_type,
                             const gss_OID mech_type,
                             OM_uint32 *message_context,
                             gss_buffer_t status_string);

SQL_API_RC SQL_API_FN PluginTerminate(char **errorMsg,
						   db2int32 *errorMsgLen);

void delete_context(CONTEXT_T *pCtx);




#define db2Log(logType, fmt, ...) do { \
   char buffer[4096]; \
   db2int32 len = snprintf(buffer, 4096, "AWSIAMauth::" fmt, ##__VA_ARGS__); \
   openlog( PRINCIPAL_NAME, LOG_CONS | LOG_PID | LOG_NDELAY, LOG_AUTHPRIV ); \
   if( logType == DB2SEC_LOG_INFO ) \
   { \
     syslog( LOG_INFO, "INFO    AWSIAMauth::" fmt, ##__VA_ARGS__ ); \
   } \
   else if( logType == DB2SEC_LOG_WARNING ) \
   { \
     syslog( LOG_WARNING, "WARNING AWSIAMauth::" fmt, ##__VA_ARGS__ ); \
   } \
   else \
   { \
     syslog( LOG_ERR, "ERROR   AWSIAMauth::" fmt, ##__VA_ARGS__ ); \
   } \
   closelog(); \
   if(logFunc) \
   { \
     logFunc(logType, buffer, len > 4095 ? 4095 : len ); \
   } \
   else \
   { \
     printf("\nLOG:TYPE = %d, message=%s\n", logType, buffer); \
   } \
} while (0)

#endif  //_AWS_IAM_AUTH_H
