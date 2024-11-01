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
** SOURCE FILE NAME: IBMLDAPauthserver.C
**
** SAMPLE: server side LDAP based userID/password authentication
**
** This source file implements a server side DB2 securty plugin that
** interacts with an LDAP user registry.
**
** When built, a single loadable object is created that should be copied
** into the appropriate directory under the DB2 instance.  Then the
** SRVCON_PW_PLUGIN database manager configuration parameter must be
** updated to the name of the loadable object (minus the library suffix).
**
** For example, on 64-bit UNIX platforms the loadable object should be
** copied to the .../sqllib/security64/plugin/server directory and the
** CLNT_PW_PLUGIN parameter updated to "IBMLDAPauthserver".
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

#include "sqlenv.h"
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



/* GetAuthIDs
 * Search LDAP for the user that matches the given "userID" and return
 * the value of the AuthID attribute associated with the user object.
 *
 * Note that the AuthID may have been picked up earlier (in CheckPassword)
 * and stored in the "token" parameter.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN GetAuthIDs(const char *userID,
                                 db2int32 userIDLength,
                                 const char *domain,              /* not used */
                                 db2int32 domainLength,           /* not used */
                                 db2int32 domainType,             /* not used */
                                 const char *databaseName,        /* not used */
                                 db2int32 databaseNameLength,     /* not used */
                                 void **token,
                                 char systemAuthID[],
                                 db2int32 *systemAuthIDLength,
                                 char sessionAuthID[],
                                 db2int32 *sessionAuthIDLength,
                                 char username[],
                                 db2int32 *usernameLength,
                                 db2int32 *sessionType,
                                 char **errorMessage,
                                 db2int32 *errorMessageLength)
{
   int       rc = DB2SEC_PLUGIN_OK;
   LDAP     *ld = NULL;
   int       freeLDAP = FALSE;
   char     *authid = NULL;
   int       authidLen;
   int       haveTokenWantAuthID = FALSE;
   token_t  *pluginToken = NULL;
   char      dumpMsg[MAX_ERROR_MSG_SIZE];
   char      userDN[DB2LDAP_MAX_DN_SIZE + 1];
   char      local_userid[DB2SEC_MAX_USERID_LENGTH + 1];
   char      local_authid[DB2SEC_MAX_AUTHID_LENGTH + 1];

   *errorMessage = NULL;
   *errorMessageLength = 0;

   if (userID == NULL)
   {
      *errorMessage = strdup("LDAP GetAuthIDs: userid is NULL");
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }

   if ( userIDLength > DB2SEC_MAX_USERID_LENGTH )
   {
      /* Make a NULL terminated version of known max size */
      strncpy(local_userid, userID, DB2SEC_MAX_USERID_LENGTH);
      local_userid[DB2SEC_MAX_USERID_LENGTH] = '\0';

      snprintf(dumpMsg, sizeof(dumpMsg),
               "LDAP GetAuthIDs: userid too long: %d bytes\n[truncated:]%s",
               (int)userIDLength, local_userid);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }

   /* For this plugin the "username" is the same as the */
   /* "userID" supplied by the cient.                   */
   memcpy(username, userID, userIDLength);
   *usernameLength = userIDLength;

   /* Create a local NULL-terminated version of the userid */
   memcpy(local_userid, userID, userIDLength);
   local_userid[userIDLength] = '\0';

   /* The AuthID might already be in the token */
   if (token != NULL && *token != NULL)
   {
      pluginToken = (token_t *)(*token);
      if (memcmp(pluginToken->eyeCatcher,
                 DB2LDAP_TOKEN_EYECATCHER,
                 sizeof(DB2LDAP_TOKEN_EYECATCHER)) == 0)
      {
         authidLen = pluginToken->authidLen;
         if (authidLen > 0)
         {
            authid = pluginToken->authid;
            goto check_authid;
         }
         haveTokenWantAuthID = TRUE;

         /* Even if the AuthID wasn't there, we might have an LDAP
          * handle we can use.
          */
         if (pluginToken->ld != NULL)
         {
            ld = pluginToken->ld;
            freeLDAP = FALSE;
         }
      }
   }


   if (ld == NULL)
   {
      rc = initLDAP(&ld, TRUE, errorMessage);
      if (rc != DB2SEC_PLUGIN_OK) goto exit;
      freeLDAP = TRUE;
   }

   rc = db2ldapGetUserDN(ld, local_userid, userDN, local_authid, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;

   authid    = local_authid;
   authidLen = strlen(authid);


check_authid:
   if (authidLen <= 0)
   {
      snprintf(dumpMsg, sizeof(dumpMsg),
               "LDAP GetAUTHIDs: bad AuthID length (%d)\nuser='%s'",
               authidLen, local_userid);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }          

   /* The max authid length is checked in db2ldapGetUserDN */

   memcpy(systemAuthID, authid, authidLen);
   *systemAuthIDLength = authidLen;
   memcpy(sessionAuthID, authid, authidLen);
   *sessionAuthIDLength = authidLen;
   *sessionType = DB2SEC_ID_TYPE_AUTHID;

   /* If we had a token without an AuthID in it, store the one
    * we found there now so it's available for FindGroups.
    */
   if (haveTokenWantAuthID)
   {
     strcpy(pluginToken->authid, authid);
     pluginToken->authidLen = authidLen;

     if (userDN[0] != '\0' && strlen(userDN) <= DB2LDAP_MAX_DN_SIZE)
     {
        strcpy(pluginToken->userDN, userDN);
     }
   }

exit:
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);
   }

   if (freeLDAP && ld != NULL) ldap_unbind_s(ld);

   return(rc);
}



/* DoesAuthIDExist
 * Search for a user object where the AuthID attribute matches the
 * value provided.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN DoesAuthIDExist(const char  *authID,
                                      db2int32     authIDLength,
                                      char       **errorMessage,
                                      db2int32    *errorMessageLength)
{
   int     rc = DB2SEC_PLUGIN_OK;
   int     filterLength = 0;
   LDAP   *ld = NULL;
   const char *errmsg = NULL;
   char    localAuthID[DB2SEC_MAX_AUTHID_LENGTH + 1];
   char    dumpMsg[MAX_ERROR_MSG_SIZE];

   *errorMessage = NULL;
   *errorMessageLength = 0;

   if (authID == NULL || authIDLength <= 0)
   {
      snprintf(dumpMsg, sizeof(dumpMsg),
               "LDAP DoesAuthIDExist: AUTHID is NULL or bad length (%d)",
               (int)authIDLength);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }

   /* NULL terminate the authID */
   if (authIDLength > DB2SEC_MAX_AUTHID_LENGTH)
   {
      /* Make a NULL terminated version of known max size */
      strncpy(localAuthID, authID, DB2SEC_MAX_AUTHID_LENGTH);
      localAuthID[DB2SEC_MAX_AUTHID_LENGTH] = '\0';

      snprintf(dumpMsg, sizeof(dumpMsg), "LDAP DoesAuthIDExist: "
               "AuthID too long: %d bytes\n[truncated:]%s",
               (int)authIDLength, localAuthID);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }

   memcpy(localAuthID, authID, authIDLength);
   localAuthID[authIDLength] = '\0';

   rc = initLDAP(&ld, TRUE, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;
    
   rc = db2ldapFindAttrib(ld,
                          ConfigData.userBase,
                          ConfigData.userObjClass,
                          ConfigData.authidAttr,
                          localAuthID,
                          ConfigData.authidAttr,
                          NULL,
                          FALSE,
                          NULL);

   switch (rc)
   {
      case GET_ATTRIB_OK:
      case GET_ATTRIB_TOOMANY:  /* finding more than one is okay here */
         rc = DB2SEC_PLUGIN_OK;
         break;
      case GET_ATTRIB_NO_OBJECT: /* search worked, but didn't find a match */
      case GET_ATTRIB_NOTFOUND:
         rc = DB2SEC_PLUGIN_INVALIDUSERORGROUP;
         break;
      case GET_ATTRIB_LDAPERR:
         errmsg = "LDAP error searching for AUTHID";
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         break;
      case GET_ATTRIB_NOMEM:
         errmsg = "out of memory while searching for AUTHID";
         rc = DB2SEC_PLUGIN_NOMEM;
         break;
      case GET_ATTRIB_BADINPUT:
      default:
         errmsg = "Internal error while searching for AUTHID";
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         break;
   }

   if (errmsg != NULL)
   {
      snprintf(dumpMsg, sizeof(dumpMsg),
               "LDAP DoesAuthIDExist:\n%s\nAuthID='%s'",
               errmsg, localAuthID);
      *errorMessage = strdup(dumpMsg);
   }

exit:
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);
   }
    
   if (ld != NULL) ldap_unbind_s(ld);

   return (rc);
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

   if (token != NULL)
   {
      if (((token_t*)token)->ld != NULL)
         ldap_unbind_s(((token_t*)token)->ld);
      free(token);
   }
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




/* db2secServerAuthPluginInit
 * Plugin initialization.  Parse the config file and set up function
 * pointers.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN
db2secServerAuthPluginInit(db2int32              version,
                           void                 *server_fns,
                           db2secGetConDetails  *getConDetails_fn,
                           db2secLogMessage     *msgFunc,
                           char                **errorMessage,
                           db2int32             *errorMessageLength)
{
   int rc = DB2SEC_PLUGIN_OK;
   db2secUseridPasswordServerAuthFunctions_1 *p;

   *errorMessage = NULL;
   *errorMessageLength = 0;

   p = (db2secUseridPasswordServerAuthFunctions_1*)server_fns;

   p->version                    = DB2SEC_USERID_PASSWORD_SERVER_AUTH_FUNCTIONS_VERSION_1;
   p->plugintype                 = DB2SEC_PLUGIN_TYPE_USERID_PASSWORD;
   p->db2secValidatePassword     = &CheckPassword;
   p->db2secGetAuthIDs           = &GetAuthIDs;
   p->db2secDoesAuthIDExist      = &DoesAuthIDExist;
   p->db2secFreeToken            = &FreeToken;
   p->db2secFreeErrormsg         = &FreeErrorMessage;
   p->db2secServerAuthPluginTerm = &PluginTerminate;

   db2LogFunc = msgFunc;

   memset(&ConfigData, 0, sizeof(ConfigData));

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

