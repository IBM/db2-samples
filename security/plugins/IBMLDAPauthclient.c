/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2006
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*****************************************************************************
**
** SOURCE FILE NAME: IBMLDAPauthclient.c
**
** SAMPLE: client side LDAP based userID/password authentication
**
** This source file implements a client side DB2 securty plugin that
** interacts with an LDAP user registry.
**
** When built, a single loadable object is created that should be copied
** into the appropriate directory under the DB2 instance.  Then the
** CLNT_PW_PLUGIN database manager configuration parameter must be
** updated to the name of the loadable object (minus the library suffix).
**
** For example, on 64-bit UNIX platforms the loadable object should be
** copied to the .../sqllib/security64/plugin/client directory and the
** CLNT_PW_PLUGIN parameter updated to "IBMLDAPauthclient".
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>

#include <ctype.h>
#include <ldap.h>
#include <ldapssl.h>
#include <ldif.h>

#include <errno.h>

#ifdef WIN
#include <winbase.h> // for window platform sdk GetUsername()
// Need Link to Advapi32.lib
#endif
#ifdef SQLUNIX
#include <pwd.h>
#endif

#include <sqlenv.h>
#include "db2secPlugin.h"

#include "IBMLDAPutils.h"


DB2LDAP_EXT_C
db2secLogMessage *db2LogFunc = NULL;

static pluginConfig_t ConfigData;

/* db2ldapGetConfigDataPtr
 * Return a pointer to the config data for this plugin.
 * All plugins (client, server, group) use the same structure, but it is
 * important that the helper functions in other files use the right one!
 */
DB2LDAP_EXT_C
pluginConfig_t *db2ldapGetConfigDataPtr(void)
{
   return(&ConfigData);
}


#define INFO_BUFFER_SIZE 257

/* WhoAmI
 * Figure out what userid we're running as, look them up in LDAP,
 * and return the userid and AuthID.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN WhoAmI(char         authID[],
                             db2int32    *authIDLength,
                             char         userID[],
                             db2int32    *userIDLength,
                             db2int32     userIDType,
                             char         domain[],            /* not used */
                             db2int32    *domainLength,        /* not used */
                             db2int32    *domainType,          /* not used */
                             const char  *databaseName,        /* not used */
                             db2int32     databaseNameLength,  /* not used */
                             void       **token,               /* not used */
                             char       **errorMessage,
                             db2int32    *errorMessageLength)
{
   int   rc = DB2SEC_PLUGIN_OK;
   char  user[INFO_BUFFER_SIZE];
   char  szLog[MAX_ERROR_MSG_SIZE];
   int   loglen = 0;
   char  buffer[MAX_ERROR_MSG_SIZE];
   int   status = 0;
   char *srch_authid = NULL;
   int   authidLen;

   LDAP *ld = NULL;
    
#if defined(SQLWINT)
   DWORD   userLen;
   DWORD   en;
#elif defined(SQLUNIX)
   int     userLen;
   int     en;
   struct  passwd pwd, *pw = NULL;
   uid_t   current_uid = 0;
#else
#error Must define platform
#endif

   *errorMessage = NULL;
   *errorMessageLength = 0;
        
   authID[0] = '\0';
   *authIDLength = 0;
   userID[0] = '\0';
   *userIDLength = 0;
   domain[0] = '\0';
   *domainLength = 0;
   *domainType = DB2SEC_USER_NAMESPACE_UNDEFINED;


   /* Determine what userid we're running under (platform specific). */
    
#ifdef SQLWINT
   /* Windows */
   userLen = INFO_BUFFER_SIZE;
   if (!GetUserNameA( user, &userLen ))
   {
      en = GetLastError();
      snprintf(buffer, sizeof(buffer),
               "LDAP WhoAmI: failed to get current user info, error=%d", en);
      *errorMessage = strdup(buffer);
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      goto exit;
   }
#else
   /* UNIX / Linux */
   if (DB2SEC_PLUGIN_REAL_USER_NAME == userIDType)
   {
      current_uid = getuid();
   }
   else
   {
      current_uid = geteuid();
   }

   status = getpwuid_r(current_uid, &pwd, buffer, sizeof(buffer), &pw);

   en = errno;   /* Error handling is below */

   if (status == 0)
   {
      userLen = strlen(pw->pw_name);
      strcpy(user, pw->pw_name);
   }
   else
   {
      snprintf(buffer, sizeof(buffer), "LDAP WhoAmI: "
               "failed to find user info for uid %u, error=%d",
               current_uid, en);
      *errorMessage = strdup(buffer);
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      goto exit;
   }
#endif

    
   /* Check the length */
   if (userLen > DB2SEC_MAX_USERID_LENGTH)
   {
      snprintf(buffer, sizeof(buffer),
               "LDAP WhoAmI: default user name too long (%d bytes): %s",
               userLen, user);
      *errorMessage = strdup(buffer);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }

   strcpy(userID, user);
   *userIDLength = userLen;


   /* Now connect to LDAP and search for the associated AuthID. */
   rc = initLDAP(&ld, TRUE, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;
    
   rc = db2ldapFindAttrib(ld,
                          ConfigData.userBase,
                          ConfigData.userObjClass,
                          ConfigData.useridAttr,
                          userID,
                          ConfigData.authidAttr,
                          &srch_authid,
                          FALSE,
                          NULL);

   if (rc != GET_ATTRIB_OK)
   {
      const char *msg;
      switch (rc)
      {
         case GET_ATTRIB_NO_OBJECT:
            msg = "user not found in LDAP.";
            rc = DB2SEC_PLUGIN_NO_CRED;
            break;
         case GET_ATTRIB_NOTFOUND:
            msg = "no AuthID found for user.";
            rc = DB2SEC_PLUGIN_BADUSER;
            break;
         case GET_ATTRIB_TOOMANY:
            msg = "more than one AuthID found for user.";
            rc = DB2SEC_PLUGIN_BADUSER;
            break;
         case GET_ATTRIB_LDAPERR:
            msg = "LDAP error while searching for AuthID.";
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            break;
         case GET_ATTRIB_NOMEM:
            msg = "out of memory while retreiving AuthID.";
            rc = DB2SEC_PLUGIN_NOMEM;
            break;
         case GET_ATTRIB_BADINPUT:
         default:
            msg = "internal error while searching for AuthID.";
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            break;
      }
      snprintf(buffer, sizeof(buffer), "LDAP WhoAmI: "
               "can't determine LDAP user associated with\nOS user '%s': "
               "%s\nUserid attribute='%s'  AuthID attribute='%s'\n"
               "user objectClass='%s'  user base DN='%s'",
               userID, msg, ConfigData.useridAttr, ConfigData.authidAttr,
               ConfigData.userObjClass, ConfigData.userBase);
      *errorMessage = strdup(buffer);
      goto exit;
   }

   authidLen = strlen(srch_authid);

   if (authidLen <= 0)
   {
      snprintf(buffer, sizeof(buffer),
               "LDAP WhoAmI: bad AuthID length (%d) for user %s",
               authidLen, userID);
      *errorMessage = strdup(buffer);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }          

   if (authidLen > DB2SEC_MAX_AUTHID_LENGTH)
   {
      snprintf(buffer, sizeof(buffer),
               "LDAP WhoAmI: AuthID too long for user %s: (%d bytes): %s",
               userID, authidLen, srch_authid);
      *errorMessage = strdup(buffer);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }          

   *authIDLength = authidLen;
   strcpy(authID, srch_authid);

exit:
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);
      db2LogFunc(DB2SEC_LOG_ERROR, *errorMessage, *errorMessageLength);
   }

   if (srch_authid != NULL) free(srch_authid);
   if (ld != NULL) ldap_unbind_s(ld);
   return(rc);
}




/* FreeToken
 * The "token" parameter is malloc'd when required.  Free it here.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN FreeToken(void      *token,
                                char     **errorMessage,
                                db2int32  *errorMessageLength)
{
   *errorMessage = NULL;
   *errorMessageLength = 0;

   if (token != NULL) free(token);
   return(DB2SEC_PLUGIN_OK);
}




/* FreeErrorMessage
 * All messages returned from this plugin are strdup'd.  Free them here.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN FreeErrorMessage(char *msg)
{
   if (msg != NULL) free(msg);
   return(DB2SEC_PLUGIN_OK);
}



/* PluginTerminate
 * Terminate & clean up.  Nothing to do for this plugin.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN PluginTerminate(char **errorMessage,
                                      db2int32 *errorMessageLength)
{
   *errorMessage = NULL;
   *errorMessageLength = 0;
   return(DB2SEC_PLUGIN_OK);
}



/* db2secClientAuthPluginInit
 * Plugin initialization.  Parse the config file and set up function
 * pointers.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN
db2secClientAuthPluginInit (db2int32           version,
                            void              *client_fns,
                            db2secLogMessage  *msgFunc,
                            char             **errorMessage,
                            db2int32          *errorMessageLength)
{
   int rc = DB2SEC_PLUGIN_OK;
   db2secUseridPasswordClientAuthFunctions_1 *p;

   *errorMessage = NULL;
   *errorMessageLength = 0;

   p = (db2secUseridPasswordClientAuthFunctions_1 *)client_fns; 

   p->version                      = DB2SEC_USERID_PASSWORD_CLIENT_AUTH_FUNCTIONS_VERSION_1;
   p->plugintype                   = DB2SEC_PLUGIN_TYPE_USERID_PASSWORD;
   p->db2secRemapUserid            = NULL;    /* optional */
   p->db2secGetDefaultLoginContext = &WhoAmI;
   p->db2secValidatePassword       = &CheckPassword;
   p->db2secFreeToken              = &FreeToken;
   p->db2secFreeErrormsg           = &FreeErrorMessage;
   p->db2secClientAuthPluginTerm   = &PluginTerminate;

   db2LogFunc = msgFunc;
    
   rc = db2ldapReadConfig(&ConfigData, CFG_USERAUTH, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;

   /* If an SSL connection has been configured, initialize SSL support
    * here.  This must be done once in every plugin library; if we
    * don't do this here we run into problems passing the LDAP handle
    * between different libraries.
    */
   if (ConfigData.isSSL)
   {
      rc = db2ldapSetGSKitVar(errorMessage);
      if (rc != DB2SEC_PLUGIN_OK) goto exit;

      rc = db2ldapInitSSL(&ConfigData, errorMessage);
      if (rc != DB2SEC_PLUGIN_OK) goto exit;
   }

exit:
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);
      db2LogFunc(DB2SEC_LOG_ERROR, *errorMessage, *errorMessageLength);
   }
   return(rc);
}
