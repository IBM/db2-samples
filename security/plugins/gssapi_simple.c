/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2004
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*****************************************************************************
**
** SOURCE FILE NAME: gssapi_simple.c
**
** SAMPLE: Basic GSS-API authentication plugin sample (both client & server)
**
** This single source files implements both the client and server pieces
** of a simple GSS-API authentication mechanism.
**
** When built, a single loadable object is created (see the makefile).
** However, because DB2 treats server-side authentication and client-side
** authentication as separate plugins, the single loadable object must
** be copied into two different directories.  For example, on 32-bit
** UNIX platforms the loadable object should be copied into:
**   .../sqllib/security32/plugin/server
**   .../sqllib/security32/plugin/client
**
** To enable the plugin the SRVCON_GSSPLUGIN_LIST database manager
** configuration parameter must be updated (on the server only) to
** include the plugin name, and the AUTHENTICATION parameter (or
** SRVCON_AUTH parameter) must be one of GSSPLUGIN or GSS_SERVER_ENCRYPT.
**
*****************************************************************************
**
** For more information on developing DB2 security plugins, see the
** "Developing Security Plug-ins" section of the Application Development
** Guide.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef DB2_PLAT_UNIX
#include <unistd.h>
#include <sys/types.h>
#else
#define strcasecmp(a,b) stricmp(a,b)
#define snprintf _snprintf
#endif

#include "sqlenv.h"
#include "db2secPlugin.h"

db2secLogMessage *logFunc = NULL;

/* THE USER DEFINITION FILE
 * Userid and password information is located in a
 * file defined by "USER_FILENAME".
 *
 * This file consists of one line per user with two
 * whitespace separated fields on each line:
 *
 *   username  password
 *
 * Both the username and password are mandatory.  Additional
 * fields after the second are ignored.
 *
 * Lines that begin with "#" are comments.  Blank lines are
 * ignored.  Note that usernames and passwords may not
 * contain whitespace.
 *
 * The maximum line length is 1024 characters; lines longer than
 * this value will result in undefined behavior.  User names are
 * limited to SQL_AUTH_IDENT bytes, passwords are limited to
 * DB2SEC_MAX_PASSWORD_LENGTH bytes.  Lines containing longer
 * fields are silently ignored.
 */
#ifndef USER_FILENAME				/* Normally defined in the makefile */
#ifndef WIN32
#define USER_FILENAME	"/home/db2inst1/sqllib/SamplePluginUsers"
#else
#define USER_FILENAME	"D:\\sqllib\\DB2\\SamplePluginUsers"
#endif
#endif

/* Maximum line length for the user definition file
 * The internal max line length includes room for a line
 * separator (CR/LF on Windows, LF on UNIX) and a NULL byte.
 */
#define MAX_LINE_LENGTH		1027

#define SQL_AUTH_IDENT      128

/* Minor Status Codes
 * Ordering of messages is important as it corresponds to the
 * appropriate minor status codes
 */
static const char *retcodeMessage[] =
{
  "Operation completed successfully", 			/* RETCODE_OK */
  "Credential failed authenticaiton", 			/* RECODE_BADPASS */
  "Unexpected input token provided",   			/* RETCODE_BADTOKEN */
  "Mutual authentication failure",    			/* RETCODE_MUTFAIL */
  "Illegal call to gss_init/accept_sec_context",/* RETCODE_PROGERR */
  "Memory allocation error",                    /* RETCODE_MALLOC */
  "Error processing user definition file",		/* RETCODE_USERFILE */
  "Error description not available"	    		/* RETCODE_UNKNOWN */
};

#define RETCODE_OK			0
#define RETCODE_BADPASS		1
#define RETCODE_BADTOKEN	2
#define RETCODE_MUTFAIL		3
#define RETCODE_PROGERR		4
#define RETCODE_MALLOC      5
#define RETCODE_USERFILE    6
#define RETCODE_UNKNOWN		7

#define RETCODE_MAXCODE		RETCODE_UNKNOWN

#define MAJOR_CODE_STRING	"gssapi_simple plugin encounted an error"


/* Format of the token */
#define TOKEN_MAX_STRLEN	64
typedef struct _token{
  int useridLen;
  char userid[TOKEN_MAX_STRLEN];
  int pwdLen;
  char pwd[TOKEN_MAX_STRLEN];
  int targetLen;
  char target[TOKEN_MAX_STRLEN];
  OM_uint32 retFlags;
} TOKEN_T;

typedef struct _name{
  int useridLen;
  char *userid;
} NAME_T;

/* Our GSS-APU Context */
typedef struct _context{
  int sourceLen;
  char *source;
  int targetLen;
  char *target;
  int ctxCount;
} CONTEXT_T;

/* Our GSS-API credential */
typedef struct _cred{
  int useridLen;
  char *userid;
  int pwdLen;
  char *pwd;
} CRED_T;

/* We use a hardcoded principle name that happens to be the name of
 * the plugin.  In a more complex environment, this would be the
 * security mechanism identity associated with the server instance.
 */
#define PRINCIPLE_NAME "GSSAPI_SIMPLE"

/* Hardcoded "server credentials".  This is returned to the
 * client for mutual authentication.  For this example, we
 * use the principle name as the userid and a blank password.
 */
CRED_T serverCred = {sizeof(PRINCIPLE_NAME)-1, PRINCIPLE_NAME, 0, ""};




/*--------------------------------------------------
 * COMMON FUNCTIONS - both client and server side
 *--------------------------------------------------*/

/* ByteReverse()
 * This plugin sends a TOKEN_T (defined above) between client
 * and server system, which may be of different endianess.
 * The length fields in the token are sent in Network Byte Order
 * (big endian), and this function is used to convert them when
 * required.
 *
 * Rather than depend on a static #define to determine behavior
 * we determine the endianess of the current system on the fly.
 */
int ByteReverse(int input)
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

/* NextField()
 * Return a pointer to the next whitespace separated token in the input
 * string.  Skips over any leading whitespace.  A NULL byte is written
 * to the string after the token.
 *
 * The "nextString" output parameter can be used on the next call to
 * this function to retrieve the next token, if any.
 *
 * Returns NULL if no more tokens exist in the input string.
 * The orginal input string must be NULL terminated.
 */
char *NextField(char *inputString, char **nextString)
{
	char *returnString = NULL;
	char *cptr;

	if (nextString != NULL)
	{
		*nextString = NULL;
	}

	cptr = inputString;

	/* If the input string is NULL or zero length, return NULL. */
	if (cptr == NULL || *cptr == '\0')
	{
		goto exit;
	}

	/* Skip any leading whitespace */
	while (*cptr == ' ' || *cptr == '\t')
	{
		cptr++;
	}

	/* If we reach the end of the string return NULL. */
	if (*cptr == '\0')
	{
		goto exit;
	}

	/* Found a non-whitespace, non-NULL character.  This is the
	 * start of the string that we'll return.
	 */
	returnString = cptr;


	/* Now we need to NULL terminate this token and set up nextString */
	cptr++;
	while (*cptr != '\0')
	{
		if (*cptr == ' ' || *cptr == '\t')
		{
			/* Whitespace */
			*cptr = '\0';			/* NULL terminate */

			if (nextString != NULL)
			{
				/* nextString starts with the character following
				 * the NULL byte we just inserted.
				 */
				*nextString = cptr + 1;
			}
			goto exit;		/* We're done */
		}
		cptr++;
	}

	/* If we get here we've reached the end of the inputString. */
	if (nextString != NULL)
	{
		*nextString = NULL;
	}

exit:
	return(returnString);
} /* NextField */


/* GetNextLine()
 * Returns a pointer to a string containing the next non-blank,
 * non-comment line from the input file.  A comment line is one
 * where "#" is the first non-whitespace character.  Leading
 * whitespace is stripped from the returned string, as are trailing
 * "\n" or "\r\n" sequences.
 *
 * "buf" and "bufLength" refer to a caller-supplied buffer used
 * to hold the information read from the file.
 *
 * NULL is returned on EOF or error; the caller should use
 * feof() and/or ferror() to determine which has occured.
 *
 * (char*)-1 is returned if an input line is encounted that doesn't
 * fit into the supplied buffer.
 */
char *GetNextLine(FILE *fp, char *buf, int bufLength)
{
	char *returnPtr = NULL;
	char *cptr;
	int length;

	/* Loop until we find a valid line */
	while (returnPtr == NULL) {

		cptr = fgets(buf, bufLength - 1, fp);
		if (cptr == NULL)
		{
			/* EOF or error, return NULL */
			goto exit;
		}

		/* Strip trailing CR/NL bytes */
        length = strlen(cptr) - 1;
		while (cptr[length] == '\n' || cptr[length] == '\r')
		{
        	cptr[length] = '\0';
			length--;
		}

		/* Skip over any leading whitespace */
		while (*cptr != '\0' && (*cptr == ' ' || *cptr == '\t'))
		{
			cptr++;
		}

		/* If we didn't reach the end of the string and the first
		 * character is not '#', then return the line. Otherwise
		 * read the next line from the file.
		 */
		if (*cptr != '\0' && *cptr != '#')
		{
			returnPtr = cptr;
		}

	}

exit:
	return(returnPtr);
}


/* FindUser()
 * Open the indicated file and find the first line where the first
 * field matches the provided username.  Optionally return the
 * second field (password) and/or parse the remaining fields
 * (groups) into a non-NULL terminated, length-prefixed sequence
 * of strings (see below).
 *
 * The caller must supply a read buffer for use when processing
 * the file.
 *
 * Leading and trailing whitesapce is stripped from the password
 * and all group names.
 *
 * Returns:  0 for success,
 *          -1 if the user was not found
 *          -2 on error, *errorMessage will be set to a static C
 *             string describing the error.
 *
 * If groups are requested, the supplied group buffer must be at
 * least as large as the supplied read buffer.  The groups are
 * written into that buffer in the following format:
 *   <one byte length><group string><one byte length><group string>...
 * and *numGroups is set to indicate how many groups were written
 * to the group buffer.  Note that the group name strings are not
 * NULL terminated.
 */
int FindUser(const char *fileName,	/* File to read                */
             const char *userName,	/* Who we're looking for       */
			 char *readBuffer,		/* Caller-supplied read buffer */
			 int readBufferLength,
			 char **passwordPtr,	/* Output: password            */
			 char **errorMessage)	/* Static C string for errors  */
{
	int rc = -1;
	int foundUser = 0;				/* Found the user yet?			*/

	int length;
	char *linePtr;
	char *field;
	char *nextPtr;
	char *cptr;
	char *errMsg = NULL;			/* Temp local error message */
	FILE *fp = NULL;

	if (userName == NULL)
	{
		errMsg = "NULL user name supplied";
		rc = -2;
		goto exit;
	}

	if (readBuffer == NULL)
	{
		errMsg = "NULL read buffer supplied";
		rc = -2;
		goto exit;
	}

	if (passwordPtr != NULL)
	{
		*passwordPtr = NULL;
	}


	fp = fopen(fileName,"r");
	if (fp == NULL) {
		errMsg = "Cannot open specified file\n";
		rc = -2;
		goto exit;
	}

	
	while (foundUser == 0)
	{
		linePtr = GetNextLine(fp, readBuffer, readBufferLength);
		if (linePtr == (char*)-1)
		{
			/* Line length error */
			errMsg = "Encountered an invalid input line in file";
			rc = -2;
			goto exit;
		}
		if (linePtr == NULL)
		{
			/* We've probably reached the end of file, but make sure. */
			if (feof(fp))
			{
				/* End of file: User not found. */
				rc = -1;
			}
			else
			{
				/* Not end of file, must have encountered an error. */
				rc = -2;
				errMsg = "Unknown file error encountered";
			}
			goto exit;
		}

		field = NextField(linePtr, &nextPtr);
		if (field != NULL && strcasecmp(field, userName) == 0)
		{
			/* Found the correct user name.  Parse the line. */
			foundUser = 1;

			/* Second field is the password */
			field = NextField(nextPtr, &nextPtr);

			/* A blank password field is an error. */
			if (field == NULL)
			{
				errMsg = "No password for user";
				rc = -2;
				goto exit;
			}
			if (passwordPtr != NULL)
			{
				*passwordPtr = field;
			}

			rc = 0;		/* Found the user */
		}
	}
	
exit:
	if (fp != NULL)
	{
		fclose(fp);
	}

	if (errMsg != NULL)
	{
		char msg[256];
		snprintf(msg, 256,
				 "security plugin 'gssapi_simple' encountered an error\n"
				 "User: %s\nFile: %s\nError: %s\n",
				 userName, fileName, errMsg);
		msg[255]='\0';			/* ensure NULL terminated */
		logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

    	if (errorMessage != NULL)
    	{
        	*errorMessage = errMsg;
    	}
	}

	return(rc);
}


/* FreeErrorMessage()
 * This is no-op.  All error messaged returned by this plugin
 * are static C strings.
 */
SQL_API_RC SQL_API_FN FreeErrorMessage(char *errormsg)
{
  return(DB2SEC_PLUGIN_OK);
}

/* gss_release_cred()
 * Release the specified credential and free associated memory.
 */
OM_uint32 SQL_API_FN gss_release_cred(OM_uint32 *minorStatus,
                            gss_cred_id_t *pCredHandle)
{
  OM_uint32 rc=GSS_S_COMPLETE;
  CRED_T *pCred;

  /* This condition also accounts for pCredHandle == GSS_C_NO_CREDENTIAL */
  if (pCredHandle != NULL)
  {
    if (*pCredHandle != GSS_C_NO_CREDENTIAL)
    {
      pCred = (CRED_T *) *pCredHandle;
      free(pCred->userid);
      free(pCred->pwd);
      free(pCred);
      *pCredHandle = GSS_C_NO_CREDENTIAL;
    }
  }
  else
  {
    rc = GSS_S_NO_CRED;
    goto exit;
  }

exit:
  return(rc);
}

/* gss_release_name()
 * Free memory associated with the specified name.
 */
OM_uint32 SQL_API_FN gss_release_name(OM_uint32 *minorStatus,
                            gss_name_t *name)
{
  OM_uint32 rc=GSS_S_COMPLETE;
  NAME_T *pName;

  if (name != NULL && *name != NULL)
  {
    pName = (NAME_T *) *name;
    free(pName->userid);
    free(pName);
    *name = GSS_C_NO_NAME;
  }

  return(rc);
}

/* gss_release_buffer()
 * Free the specified buffer.
 */
OM_uint32 SQL_API_FN gss_release_buffer(OM_uint32 *minorStatus,
                              gss_buffer_t buffer)
{
  OM_uint32 rc=GSS_S_COMPLETE;
  NAME_T *pName;

  if ((buffer != NULL) &&
	  (buffer->length > 0) && (buffer->value != NULL))
  {
    free(buffer->value);
    buffer->value = NULL;
    buffer->length = 0;
  }

  return(rc);
}

/* gss_delete_sec_context()
 * Free the specified context.
 */
OM_uint32 SQL_API_FN gss_delete_sec_context(OM_uint32 *minorStatus,
                                 gss_ctx_id_t *context_handle,
                                 gss_buffer_t output_token)
{
  OM_uint32 rc=GSS_S_COMPLETE;
  CONTEXT_T *pCtx;

  if (context_handle != NULL && *context_handle != NULL)
  {
    pCtx = (CONTEXT_T *)*context_handle;
    free(pCtx->source);
    free(pCtx->target);
    free(pCtx);
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

  return(rc);
}

/* gss_display_status()
 * Return the text message assocaited with the given status type
 * and status value.
 */
OM_uint32 SQL_API_FN gss_display_status(OM_uint32 *minor_status,
                             OM_uint32 status_value,
                             int status_type,
                             const gss_OID mech_type,
                             OM_uint32 *message_context,
                             gss_buffer_t status_string)
{
  OM_uint32 rc=GSS_S_COMPLETE;

  /* No mech types supported */
  if (mech_type != NULL)
  {
    rc = GSS_S_BAD_MECH;
    goto exit;
  }

  /* Regardless of the type of status code, a 0 means success */
  if (status_value == GSS_S_COMPLETE)
  {
    status_string->length = strlen(retcodeMessage[RETCODE_OK]);
    status_string->value = (void *) malloc(status_string->length);
	if (status_string->value == NULL) goto malloc_fail;
    strcpy((char *)(status_string->value), retcodeMessage[RETCODE_OK]);
    goto exit;
  }

  if (status_type == GSS_C_GSS_CODE)
  {
    /* Major status code -- we only have 1 for the moment */
    status_string->length = strlen(MAJOR_CODE_STRING);
    status_string->value = (void *)malloc(status_string->length);
	if (status_string->value == NULL) goto malloc_fail;
    strcpy((char *)(status_string->value), MAJOR_CODE_STRING);
  }
  else if (status_type == GSS_C_MECH_CODE)
  {
    /* Minor status code */
    /* Make sure we don't index too high */
    if (status_value > RETCODE_MAXCODE)
    {
      rc = GSS_S_BAD_STATUS;
	  *minor_status = RETCODE_UNKNOWN;
      goto exit;
    }
    status_string->length = strlen(retcodeMessage[status_value]);
    status_string->value = (void *)malloc(status_string->length);
	if (status_string->value == NULL) goto malloc_fail;
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

  return(rc);

malloc_fail:
  status_string->length = 0;
  rc = GSS_S_FAILURE;
  *minor_status = RETCODE_MALLOC;
  goto exit;
}

/* FreeToken()
 * A no-op, since we don't use a token in this plugin.
 */
SQL_API_RC SQL_API_FN FreeToken(void *token,
					 char **errorMsg,
					 db2int32 *errorMsgLen)
{
  *errorMsg = NULL;
  *errorMsgLen = 0;
  return(DB2SEC_PLUGIN_OK);
}

/* PluginTerminate
 * Clean up anything allocated during plugin initialization.
 */
SQL_API_RC SQL_API_FN PluginTerminate(char **errorMsg,
						   db2int32 *errorMsgLen)
{
  /* Nothing to do */

  *errorMsg = NULL;
  *errorMsgLen = 0;

  return(DB2SEC_PLUGIN_OK);
}


/*--------------------------------------------------
 * CLIENT SIDE FUNCTIONS
 *--------------------------------------------------*/

/* GetDefaultLoginContext()
 * Determine the default user identity associated with the current
 * process context.
 *
 * For simplicity this plugin returns the string found in the
 * DB2DEFAULTUSER environment variable, or an error if that variable
 * is undefined.
 */
SQL_API_RC SQL_API_FN GetDefaultLoginContext(
		   char authID[],
		   db2int32 *authIDLength,
		   char userid[],
		   db2int32 *useridLength,
		   db2int32 useridType,						/* ignored */
		   char domain[],
		   db2int32 *domainLength,
		   db2int32 *domainType,
		   const char *databaseName,					/* not used */
		   db2int32 databaseNameLength,				/* not used */
		   void **token,						/* not used */
		   char **errorMessage,
		   db2int32 *errorMessageLength)
{
	int rc = DB2SEC_PLUGIN_OK;
	int length;
	char *user;

	*errorMessage = NULL;
	*errorMessageLength = 0;

	authID[0] = '\0';
	*authIDLength = 0;
	userid[0] = '\0';
	*useridLength = 0;
	domain[0] = '\0';
	*domainLength = 0;
	*domainType = DB2SEC_USER_NAMESPACE_UNDEFINED;

	user = getenv("DB2DEFAULTUSER");

	/* Check the length */
	if (user != NULL)
	{
		length = strlen(user);
		if (length > SQL_AUTH_IDENT)
		{
			*errorMessage = "Default user name (from DB2DEFAULTUSER) too long";
			rc = DB2SEC_PLUGIN_BADUSER;
			goto exit;
		}

		strcpy(authID, user);
		*authIDLength = length;
		strcpy(userid, user);
		*useridLength = length;
	}
	else
	{
		*errorMessage = "DB2DEFAULTUSER not defined";
		rc = DB2SEC_PLUGIN_BADUSER;
		goto exit;
	}

exit:
	if (*errorMessage != NULL)
	{
		*errorMessageLength = strlen(*errorMessage);
	}

	return(rc);
}


/* GenerateInitialCredential
 */
SQL_API_RC SQL_API_FN GenerateInitialCredential(const char *userid,
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
                              db2int32 *errorMsgLen)
{
  int rc = DB2SEC_PLUGIN_OK;
  CRED_T *pCred;
  char *localErrorMsg = NULL;
  char oneNullByte[] = {'\0'};


  if (newpasswordLen > 0)
  {
    rc = DB2SEC_PLUGIN_CHANGEPASSWORD_NOTSUPPORTED;
    goto exit;
  }

  if (!pGSSCredHandle)
  {
	localErrorMsg = "GenerateInitialCredential: pGSSCredHandle == NULL";
    rc = DB2SEC_PLUGIN_UNKNOWNERROR;
    goto exit;
  }

  /* Check lengths */
  if (useridLen > TOKEN_MAX_STRLEN)
  {
	rc = DB2SEC_PLUGIN_BADUSER;
	localErrorMsg = "GenerateInitialCredential: userid too long";
	goto exit;
  }
  if (passwordLen > TOKEN_MAX_STRLEN)
  {
	rc = DB2SEC_PLUGIN_BADPWD;
	localErrorMsg = "GenerateInitialCredential: password too long";
	goto exit;
  }

  pCred = (CRED_T *)malloc(sizeof(CRED_T));
  if (pCred == NULL) goto malloc_fail;
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

  pCred->useridLen = useridLen;
  pCred->userid = (char *)malloc(useridLen);
  if (pCred->userid == NULL) goto malloc_fail;
  memcpy(pCred->userid, userid, useridLen);

  pCred->pwdLen = passwordLen;
  pCred->pwd = (char *)malloc(passwordLen);
  if (pCred->pwd == NULL) goto malloc_fail;
  memcpy(pCred->pwd, password, passwordLen);

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

  return(rc);

malloc_fail:
  if (pCred != NULL) {
	if (pCred->pwd != NULL) free(pCred->pwd);
	if (pCred->userid != NULL) free(pCred->userid);
	free(pCred);
  }

  localErrorMsg = "GenerateInitialCredential: malloc failed";
  rc = DB2SEC_PLUGIN_NOMEM;

  goto exit;
}

/* ProcessServerPrincipalName
 * Process the principle name string returned from the server
 * and package it into a gss_name_t.
 */
SQL_API_RC SQL_API_FN ProcessServerPrincipalName(const char *name,
                               db2int32 nameLen,
                               gss_name_t *gssName,
                               char **errorMsg,
                               db2int32 *errorMsgLen)
{
  int rc = DB2SEC_PLUGIN_OK;
  NAME_T *pName;

  /* No error messages */
  *errorMsg = NULL;
  *errorMsgLen = 0;

  if (name != NULL && nameLen > 0)
  {
    pName = (NAME_T *) malloc(sizeof(NAME_T));
	if (pName == NULL) goto malloc_fail;
	memset(pName, '\0', sizeof(NAME_T));

    pName->useridLen = nameLen;
    pName->userid = (char *) malloc(nameLen);
	if (pName->userid == NULL) goto malloc_fail;
    memcpy(pName->userid, name, nameLen);

    *gssName = (gss_name_t)pName;
  }
  else
  {
    rc = DB2SEC_PLUGIN_BAD_PRINCIPAL_NAME;
    goto exit;
  }

exit:
  return(rc);

malloc_fail:
  if (pName != NULL)
  {
	if (pName->userid) free(pName->userid);
	free(pName);
  }
  *errorMsg = "ProcessServerPrincipalName: malloc failed";
  *errorMsgLen = strlen(*errorMsg);
  goto exit;
}

/* FreeInitInfo()
 * A no-op, since we don't set up any init info.
 */
SQL_API_RC SQL_API_FN FreeInitInfo(void *initInfo,
						char **errorMsg,
						db2int32 *errorMsgLen)
{
  *errorMsg = NULL;
  *errorMsgLen = 0;
  return(DB2SEC_PLUGIN_OK);
}


/* gss_init_sec_context()
 * Initialize a context based on input data.
 *
 * For the case where no credentials are passed in, the default
 * credentials are built from the userid and password in the
 * "DB2DEFAULTUSER" and "DB2DEFAULTPSWD" environment variables,
 * respectively.  NULL values are used if those variables do not
 * exist.
 */
OM_uint32 SQL_API_FN gss_init_sec_context(
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
                               OM_uint32 * time_rec)
{
  OM_uint32 rc = GSS_S_COMPLETE;
  NAME_T *pTarget = NULL;
  NAME_T localTarget;
  CONTEXT_T *pCtx = NULL;
  CRED_T *pCred = NULL;
  CRED_T defaultCred;
  TOKEN_T *pInToken = NULL;
  TOKEN_T *pOutToken = NULL;
  char *localuser = NULL;
  char *localpswd = NULL;
  char *cptr = NULL;
  char *errMsg = NULL;
  int length;

   /* Check for unsupported options */
  if (input_chan_bindings != GSS_C_NO_CHANNEL_BINDINGS)
  {
	errMsg = "input_chan_bindings != GSS_C_NO_CHANNEL_BINDINGS";
    rc = GSS_S_BAD_BINDINGS;
    goto exit;
  }
  if (mech_type != GSS_C_NO_OID)
  {
	errMsg = "mech_type != GSS_C_NO_OID";
    rc = GSS_S_BAD_MECH;
    goto exit;
  }
  if (context_handle == NULL)
  {
	errMsg = "context_handle == NULL";
    rc = GSS_S_NO_CONTEXT;
    goto exit;
  }

  /* Check the target name; only the hardcoded value is acceptable. */
  pTarget = (NAME_T *)target_name;
  if (pTarget == GSS_C_NO_NAME)
  {
     localTarget.userid = PRINCIPLE_NAME;
     localTarget.useridLen = strlen(PRINCIPLE_NAME);
	 pTarget = &localTarget;
  }
  else if(strncmp(pTarget->userid, PRINCIPLE_NAME, pTarget->useridLen) != 0)
  {
	errMsg = "principle mismatch";
    rc = GSS_S_BAD_NAME;
    goto exit;
  }

  /* Check the input credentials */
  if (cred_handle == GSS_C_NO_CREDENTIAL)
  {
    /* Get default userid/password from the environment,
	 * and truncate them if required.
	 */
	cptr = getenv("DB2DEFAULTUSER");
	if (cptr == NULL)
	{
	  /* Use a one byte NULL for the userid */
      length = 1;
	  cptr = "";
	}
	else
	{
	  length = strlen(cptr);
	  if (length > TOKEN_MAX_STRLEN)
	  {
		length = TOKEN_MAX_STRLEN;
	  }
	}

    localuser = (char *)malloc(length);
	if (localuser == NULL) goto malloc_fail;
	memcpy(localuser, cptr, length);
    defaultCred.userid = localuser;
    defaultCred.useridLen = length;

	cptr = getenv("DB2DEFAULTPSWD");
	if (cptr == NULL)
	{
	  /* Use a one byte NULL for the password */
      length = 1;
	  cptr = "";
	}
	else
	{
	  length = strlen(cptr);
	  if (length > TOKEN_MAX_STRLEN)
	  {
		length = TOKEN_MAX_STRLEN;
	  }
	}

	localpswd = (char*)malloc(length);
	if (localpswd == NULL) goto malloc_fail;
	memcpy(localpswd, cptr, length);
    defaultCred.pwd = localpswd;
    defaultCred.pwdLen = length;

    pCred = &defaultCred;
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
	if (pCtx == NULL) goto malloc_fail;
	memset(pCtx, '\0', sizeof(CONTEXT_T));

    pCtx->targetLen = pTarget->useridLen;
    pCtx->target = (char *)malloc(pCtx->targetLen);
	if (pCtx->target == NULL) goto malloc_fail;
    memcpy(pCtx->target, pTarget->userid, pCtx->targetLen);

    pCtx->sourceLen = pCred->useridLen;
    pCtx->source = (char *)malloc(pCtx->sourceLen);
	if (pCtx->source == NULL) goto malloc_fail;
    memcpy(pCtx->source, pCred->userid, pCtx->sourceLen);

    pCtx->ctxCount = 0;
    *context_handle = pCtx;
  }
  else
  {
    pCtx = (CONTEXT_T *)*context_handle;
    if (pCtx->ctxCount == 0)
    {
	  errMsg = "pCtx->ctxCount == 0";
      rc = GSS_S_NO_CONTEXT;
      goto exit;
    }
  }


  /* Process input token and generate output token */

  /* First invocation */
  if (pCtx->ctxCount == 0)
  {
    /* There should be no input token */
    if (input_token != GSS_C_NO_BUFFER)
    {
	  errMsg = "bad input_token";
      rc = GSS_S_FAILURE;
      *minor_status = 2;
      goto exit;
    }

    /* Generate service token */
    pOutToken = (TOKEN_T *)malloc(sizeof(TOKEN_T));
	if (pOutToken == NULL) goto malloc_fail;
	memset(pOutToken, '\0', sizeof(TOKEN_T));

    pOutToken->useridLen = ByteReverse(pCred->useridLen);
    pOutToken->pwdLen = ByteReverse(pCred->pwdLen);
    pOutToken->targetLen = ByteReverse(pTarget->useridLen);
    memcpy(pOutToken->userid, pCred->userid, pCred->useridLen);
    memcpy(pOutToken->pwd, pCred->pwd, pCred->pwdLen);
    memcpy(pOutToken->target, pTarget->userid, pTarget->useridLen);
    pOutToken->retFlags = req_flags;

    output_token->value = (void *)pOutToken;
    output_token->length = sizeof(TOKEN_T);

    if (req_flags & GSS_C_MUTUAL_FLAG)
    {
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
    /* Second invocation -- mutual authentication if necessary */
    /* Sanity check */
    if (input_token->length != sizeof(TOKEN_T))
    {
	  errMsg = "bad input_token";
      rc = GSS_S_DEFECTIVE_TOKEN;
      goto exit;
    }

    /* Normally we would want to check the information returned
	 * from the server to verify we're talking to who we think
	 * we are.  However, for this example we'll just accept
	 * whatever the server sent us.
	 */
	if (0)
    {
      /* Mutual authentication failed */
      rc = GSS_S_FAILURE;
      *minor_status = RETCODE_MUTFAIL;
      goto exit;
    }

    /* Set the context count to negative so that the next invocation will */
    /* result in an error */
    pCtx->ctxCount = -2;
  }
  else
  {
    /* Function shouldn't have been called again for context establishment */
	errMsg = "context count too high!";
    rc = GSS_S_FAILURE;
    *minor_status = RETCODE_PROGERR;
    goto exit;
  }

  /* Fill in secondary information */
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
	sprintf(msg,"gssapi_simple/gss_init_sec_context error: %s", errMsg);
	logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));
  }

  (pCtx->ctxCount)++;

  return(rc);

malloc_fail:
  if (localuser != NULL) free(localuser);
  if (localpswd != NULL) free(localpswd);
  if (pCtx != NULL)
  {
	if (pCtx->target != NULL) free(pCtx->target);
	if (pCtx->source != NULL) free(pCtx->source);
	free(pCtx);
  }
  if (pOutToken != NULL) free(pOutToken);

  rc = GSS_S_FAILURE;
  *minor_status = RETCODE_MALLOC;

  logFunc(DB2SEC_LOG_ERROR,
		  "gssapi_simple/gss_init_sec_context: malloc failure", 50);

  return(rc);
}


/* db2secClientAuthPluginInit()
 * Set up plugin function pointers and perform other initialization.
 * This function is called by name when the plugin is loaded.
 */
SQL_API_RC SQL_API_FN db2secClientAuthPluginInit(db2int32 version,
                               void *fns,
							   db2secLogMessage *msgFunc,
                               char **errormsg,
                               db2int32 *errormsglen)
{
  int rc = DB2SEC_PLUGIN_OK;
  db2secGssapiClientAuthFunctions_1 *pFPs;

  /* No error message */
  *errormsg = NULL;
  *errormsglen = 0;

  /* Written to version 1 of the API */
  if (version < DB2SEC_API_VERSION)
  {
    rc = DB2SEC_PLUGIN_INCOMPATIBLE_VER;
    goto exit;
  }

  pFPs = (db2secGssapiClientAuthFunctions_1 *) fns;

  pFPs->plugintype = DB2SEC_PLUGIN_TYPE_GSSAPI;
  pFPs->version = 1;

  /* Set up function pointers */
  pFPs->db2secGetDefaultLoginContext = GetDefaultLoginContext;
  pFPs->db2secGenerateInitialCred = GenerateInitialCredential;
  pFPs->db2secProcessServerPrincipalName = ProcessServerPrincipalName;
  pFPs->db2secFreeToken = FreeToken;
  pFPs->db2secFreeErrormsg = FreeErrorMessage;
  pFPs->db2secFreeInitInfo = FreeInitInfo;
  pFPs->db2secClientAuthPluginTerm = PluginTerminate;
  pFPs->gss_init_sec_context = gss_init_sec_context;
  pFPs->gss_delete_sec_context = gss_delete_sec_context;
  pFPs->gss_display_status = gss_display_status;
  pFPs->gss_release_buffer = gss_release_buffer;
  pFPs->gss_release_cred = gss_release_cred;
  pFPs->gss_release_name = gss_release_name;

  logFunc = msgFunc;

exit:

  return(rc);
}


/*--------------------------------------------------
 * SERVER SIDE FUNCTIONS
 *--------------------------------------------------*/

/* GetAuthIDs
 * Return the DB2 Authorization IDs associated with the supplied
 * context.
 *
 * At this point, the GSS-API context is assumed to have been
 * established and the context handle is passed in as the token.
 */
SQL_API_RC SQL_API_FN GetAuthIDs(const char *userid,					/* ignored */
               db2int32 useridlen,					/* ignored */
               const char *usernamespace,				/* ignored */
               db2int32 usernamespacelen,			/* ignored */
               db2int32 usernamespacetype,			/* ignored */
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
  int length;
  CONTEXT_T *pCtx;

  *errormsg = NULL;
  *errormsglen = 0;

  pCtx = (CONTEXT_T *) (*token);
  if (pCtx == NULL)
  {
	rc = DB2SEC_PLUGIN_NO_CRED;
	*errormsg = "GetAuthIDs: pCtx is NULL";
	*errormsglen = strlen(*errormsg);
  }

  length = pCtx->targetLen;

  /* The DB2 Authid is the userid received from the client,
   * currently stored in pCtx->target.  Check the length first!
   */
  if (length > SQL_AUTH_IDENT)
  {
	rc = DB2SEC_PLUGIN_BADUSER;
	*errormsg = "GetAuthIDs: userid too long";
	*errormsglen = strlen(*errormsg);
	goto exit;
  }

  memcpy(username, pCtx->target, length);
  *usernamelen = length;
  memcpy(SystemAuthID, username, length);
  *SystemAuthIDlen = length;
  memcpy(InitialSessionAuthID, username, length);
  *InitialSessionAuthIDlen = length;

  *initsessionidtype = 0;	/* TBD ?! --sil */

exit:
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
  int rc;
  char lineBuf[MAX_LINE_LENGTH];
  char localAuthID[SQL_AUTH_IDENT + 1];

  *errorMsg = NULL;
  *errorMsgLen = 0;

  /* NULL terminate the authID */
  if (authidLen > SQL_AUTH_IDENT)
  {
	char msg[512];
   	memcpy(localAuthID, authid, SQL_AUTH_IDENT);
   	localAuthID[SQL_AUTH_IDENT] = '\0';
	snprintf(msg, 512,
		 "DoesAuthIDExist: authID too long (%d bytes): %s... (truncated)",
		 authidLen, localAuthID);

	msg[511]='\0';			/* ensure NULL terminated */
	logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

  	*errorMsg = "DoesAuthIDExist: authID too long";
  	rc = DB2SEC_PLUGIN_BADUSER;
  	goto exit;
  }

  memcpy(localAuthID, authid, authidLen);
  localAuthID[authidLen] = '\0';

  rc = FindUser(USER_FILENAME,
  			    localAuthID,		/* User we're looking for */
  			    lineBuf,
  			    sizeof(lineBuf),
  			    NULL,				/* Don't want the password */
  			    errorMsg);
  if (rc == -2)
  {
  	/* Unexpected error. */
  	rc = DB2SEC_PLUGIN_UNKNOWNERROR;
  	goto exit;
  }
  else if (rc == -1)
  {
  	/* User not found */
  	rc = DB2SEC_PLUGIN_BADUSER;
  	goto exit;
  }
  else
  {
  	/* Found the user */
  	rc = DB2SEC_PLUGIN_OK;
  }

exit:
  *errorMsgLen = strlen(*errorMsg);
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
  TOKEN_T *pInToken = NULL;
  TOKEN_T *pOutToken = NULL;
  NAME_T *pName = NULL;
  CONTEXT_T *pCtx = NULL;
  char localUserid[SQL_AUTH_IDENT + 1];  /* Null terminated userid */
  char lineBuf[MAX_LINE_LENGTH];
  char *actualPassword = NULL;
  char *errMsg = NULL;
  int rc2;
  int length;
  int i;

  /* Check for non-supported options and sanity checks */
  if (input_chan_bindings != GSS_C_NO_CHANNEL_BINDINGS)
  {
	errMsg = "input_chan_bindings != GSS_C_NO_CHANNEL_BINDINGS";
    rc = GSS_S_BAD_BINDINGS;
    goto exit;
  }
  if (mech_type != NULL)
  {
	errMsg = "mech_type != NULL";
    rc = GSS_S_BAD_MECH;
    goto exit;
  }
  if (acceptor_cred_handle == GSS_C_NO_CREDENTIAL)
  {
	errMsg = "acceptor_cred_handle == GSS_C_NO_CREDENTIAL";
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto exit;
  }
  if (input_token == GSS_C_NO_BUFFER)
  {
	errMsg = "input_token == GSS_C_NO_BUFFER";
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto exit;
  }
  if (context_handle == GSS_C_NO_CONTEXT)
  {
	errMsg = "context_handle == GSS_C_NO_CONTEXT";
    rc = GSS_S_NO_CONTEXT;
    goto exit;
  }
  /* Ignore delegated_cred_handle since we don't use it. */


  /* The Input Token contains the encapsulated userid/password
   * received from the client.
   */
  if (input_token->length != sizeof(TOKEN_T))
  {
	errMsg = "input_token->length != sizeof(TOKEN_T)";
	rc = GSS_S_DEFECTIVE_CREDENTIAL;
	goto exit;
  }
  pInToken = (TOKEN_T *)(input_token->value);

  /*
   * The acceptor_cred_handle should be our server credential.
   */
  pServerCred = (CRED_T *)acceptor_cred_handle;


  /* First check to see if the we have the correct target.
   * The target refers to the server identity, and in this
   * example is the hardcoded principle name.
   */
  length = ByteReverse(pInToken->targetLen);
  if ((length != pServerCred->useridLen) ||
      (strncmp(pInToken->target, pServerCred->userid, length) != 0))
  {
	errMsg = "problem with target server identity";
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto exit;
  }

  /* On first call to init_sec_context, the context handle should
   * be set to GSS_C_NO_CONTEXT; set up the context structure
   */
  if (*context_handle == GSS_C_NO_CONTEXT)
  {
    pCtx = (CONTEXT_T *)malloc(sizeof(CONTEXT_T));
	if (pCtx == NULL) goto malloc_fail;

    pCtx->targetLen = ByteReverse(pInToken->useridLen);
    pCtx->target = (char *)malloc(pCtx->targetLen);
	if (pCtx->target == NULL) goto malloc_fail;
    memcpy(pCtx->target, pInToken->userid, pCtx->targetLen);

    pCtx->sourceLen = pServerCred->useridLen;
    pCtx->source = (char *)malloc(pCtx->sourceLen);
	if (pCtx->source == NULL) goto malloc_fail;
    memcpy(pCtx->source, pServerCred->userid, pCtx->sourceLen);

    pCtx->ctxCount = 0;
    *context_handle = pCtx;
  }
  else
  {
    pCtx = (CONTEXT_T *) *context_handle;
    if (pCtx->ctxCount == 0)
    {
	  errMsg = "pCtx->ctxCount == 0";
      rc = GSS_S_NO_CONTEXT;
      goto exit;
    }
  }

  /* First invocation */
  if (pCtx->ctxCount == 0)
  {
    /* Perform authentication */

	/* Copy & null terminate the userid */
	length = ByteReverse(pInToken->useridLen);

        if (length >= sizeof(localUserid))
        {
           /* Bad userid. */
           rc = GSS_S_DEFECTIVE_CREDENTIAL;
           *minor_status = RETCODE_BADPASS;
        }
        else
        {
	   memcpy(localUserid, pInToken->userid, length);
	   localUserid[length] = '\0';

           rc2 =  FindUser(USER_FILENAME,
	                   localUserid,		/* User we're looking for */
		           lineBuf,
			   sizeof(lineBuf),
			   &actualPassword,
			   NULL);
           if (rc2 == -2)
	   {
	      /* Unexpected error. */
	      rc = GSS_S_FAILURE;
	      *minor_status = RETCODE_USERFILE;
	   }
	   else if (rc2 == -1)
	   {
	      /* User not found */
	      rc = GSS_S_DEFECTIVE_CREDENTIAL;
	      *minor_status = RETCODE_BADPASS;
	   }
	   else
	   {
	     length = ByteReverse(pInToken->pwdLen);
             if ((strlen(actualPassword) != length) ||
	  	  (strncmp(actualPassword, pInToken->pwd, length) != 0))
	     {
	        /* Bad password. */
	        rc = GSS_S_DEFECTIVE_CREDENTIAL;
	        *minor_status = RETCODE_BADPASS;
             }
           }
        }


    /* Generate service token
	 * This is sent back to the client for mutual authentication.
	 * We send the hardcoded principle name and a zero length
	 * password.  This sample plugin ignores this information on
	 * the client side.
	 */
    pOutToken = (TOKEN_T *)malloc(sizeof(TOKEN_T));
	if (pOutToken == NULL) goto malloc_fail;
	memset(pOutToken, '\0', sizeof(TOKEN_T));

	/* Server "userid" (principle name) */
	length = pServerCred->useridLen;
    pOutToken->useridLen = ByteReverse(length);
    memcpy(pOutToken->userid, pServerCred->userid, length);

	/* Server "password" (zero length in this sample) */
    pOutToken->pwdLen = 0;

    /* Target is the userid provided by the client */
	length = ByteReverse(pInToken->useridLen);
    pOutToken->targetLen = pInToken->useridLen;
    memcpy(pOutToken->target, pInToken->userid, length);

    pOutToken->retFlags = pInToken->retFlags;

    output_token->value = (void *) pOutToken;
    output_token->length = sizeof(TOKEN_T);

    /* We're done.  No more flows.  Make the context count negative
	 * so that the  next invocation will result in an error.
	 */
    pCtx->ctxCount = -2;
  }
  else
  {
    /* Function shouldn't have been called again for context establishment */
	errMsg = "context count too large!";
    rc = GSS_S_FAILURE;
    *minor_status = 4;
    goto exit;
  }

  /* Fill in the secondary information */
  if (src_name != NULL)
  {
    pName = (NAME_T *)malloc(sizeof(NAME_T));
	if (pName == NULL) goto malloc_fail;

	length = ByteReverse(pInToken->useridLen);
    pName->userid = (char *)malloc(length);
	if (pName->userid == NULL) goto malloc_fail;

    pName->useridLen = length;
    memcpy(pName->userid, pInToken->userid, length);
    *src_name = (gss_name_t)pName;
  }

  if (ret_flags != NULL)
  {
    *ret_flags = pInToken->retFlags;
  }

  if (time_rec != NULL)
  {
    *time_rec = 0;
  }

exit:
  if (errMsg != NULL)
  {
	char msg[512];
	sprintf(msg,"gssapi_simple/gss_accept_sec_context error: %s", errMsg);
	logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));
  }

  (pCtx->ctxCount)++;
  return(rc);

malloc_fail:
  if (pCtx != NULL)
  {
	if (pCtx->target != NULL) free(pCtx->target);
	if (pCtx->source != NULL) free(pCtx->source);
	free(pCtx);
  }
  if (pOutToken != NULL) free(pOutToken);
  if (pName != NULL)
  {
	if (pName->userid != NULL) free(pName->userid);
	free(pName);
  }

  rc = GSS_S_FAILURE;
  *minor_status = RETCODE_MALLOC;

  logFunc(DB2SEC_LOG_ERROR,
		  "gssapi_simple/gss_accept_sec_context: malloc failure", 52);

  return(rc);
}

/******************************************************************************
*
*  Function Name     =
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
  }
  else
  {
    rc = GSS_S_BAD_NAME;
    goto exit;
  }

exit:

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
  pFPs->serverPrincipalName.value = PRINCIPLE_NAME;
  pFPs->serverPrincipalName.length = strlen(PRINCIPLE_NAME);;

  /* Fill in the server's cred handle */
  pFPs->serverCredHandle = (gss_cred_id_t)&serverCred;

  /* Set up function pointers */
  pFPs->db2secGetAuthIDs = GetAuthIDs;
  pFPs->db2secDoesAuthIDExist = db2secDoesAuthIDExist;
  pFPs->db2secFreeErrormsg = FreeErrorMessage;
  pFPs->db2secServerAuthPluginTerm = PluginTerminate;
  pFPs->gss_accept_sec_context = gss_accept_sec_context;
  pFPs->gss_display_name = gss_display_name;
  pFPs->gss_delete_sec_context = gss_delete_sec_context;
  pFPs->gss_display_status = gss_display_status;
  pFPs->gss_release_buffer = gss_release_buffer;
  pFPs->gss_release_cred = gss_release_cred;
  pFPs->gss_release_name = gss_release_name;

  logFunc = msgFunc;

exit:
  return(rc);
}
