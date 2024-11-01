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
** SOURCE FILE NAME: IBMLDAPgroups.c
**
** SAMPLE: DB2 security plugin for LDAP based group lookup
**
** When built, a single loadable object is created.  This object
** should be copied into the group plugin directory.  Then the
** GROUP_PLUGIN database manager configuration parameter should be
** updated to the name of the plugin object file, minus any extensions.
**
** For example, on 64-bit UNIX platforms the loadable object should be
** copied to the .../sqllib/security64/plugin/group directory and the
** GROUP_PLUGIN parameter updated to "IBMLDAPgroups".
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


/* Types used to manage the linked list of groups that
 * is build during the group lookup process.
 */
typedef struct groupElem_s {
   struct groupElem_s *next;
   char name[1];               /* variable size */
} groupElem;

typedef struct {
   groupElem *first;
   groupElem *last;
} groupListHead;



/* addGroupToList
 *
 * Add "name" to the list anchored by "head".
 *
 * Returns: 0 (success) or DB2SEC_PLUGIN_NOMEM.
 */
static int addGroupToList(groupListHead  *head,
                          const char     *name)
{
   int rc = DB2SEC_PLUGIN_OK;
   groupElem *newgrp;

   newgrp = (groupElem*)malloc(sizeof(groupElem) + strlen(name));
   if (newgrp != NULL)
   {
      strcpy(newgrp->name, name);
      newgrp->next = NULL;

      if (head->last == NULL)
      {
         head->first = newgrp;
         head->last = newgrp;
      }
      else
      {
         head->last->next = newgrp;
         head->last = newgrp;
      }
   }
   else 
   {
      rc = DB2SEC_PLUGIN_NOMEM;
   }
   return(rc);
}

/* isGrpDNinList
 *
 * Returns TRUE if "name" is found in the group list, otherwise FALSE.
 */
static int isGrpDNinList(groupListHead  *head,
                         const char     *name)
{
   int rc = FALSE;

   if (head != NULL)
   {
      groupElem *cur = head->first;
      while (rc == FALSE && cur != NULL)
      {
         if (strcmp(name, cur->name) == 0) rc = TRUE;
         cur = cur->next;
      }
   }
   return(rc);
}

/* freeList
 *
 * Free the memory associated with the list anchored by "head".
 */
static void freeList(groupListHead  *head)
{
   groupElem *cur, *next;

   if (head != NULL)
   {
      cur = head->first;
      while (cur != NULL)
      {
         next = cur->next;
         free(cur);
         cur = next;
      }

      head->first = NULL;
   }
   return;
}

/* getGroupNameByDN
 *
 * Look up the groupNameAttr value associated with the input group DN.
 * Caller must free the string returned in *res_str.
 */
static int getGroupNameByDN(LDAP        *ld,
                            const char  *groupDN,
                            char       **res_str,
                            char       **errorMessage)
{
   int rc = DB2SEC_PLUGIN_OK;
   const char *msg = NULL;
   int loglevel, len;
   char dumpMsg[MAX_ERROR_MSG_SIZE];

   if (res_str == NULL)   /* should never happen */
   {
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      goto exit;
   }

   *res_str = NULL;

   rc = db2ldapFindAttrib(ld,
                          groupDN,
                          ConfigData.groupObjClass,
                          NULL, NULL,
                          ConfigData.groupNameAttr,
                          res_str,
                          TRUE,
                          NULL);

   if (rc != DB2SEC_PLUGIN_OK)
   {
      loglevel = DB2SEC_LOG_ERROR;
      switch (rc)
      {
         case GET_ATTRIB_NO_OBJECT:
         case GET_ATTRIB_NOTFOUND:
            /* No "group name" attribute found for this group,
             * or we couldn't find the group DN in LDAP.
             * This is not a fatal error: we log a warning and
             * continue without processing this group.
             */
            msg = "no group name found.";
            loglevel = DB2SEC_LOG_WARNING;
            rc = DB2SEC_PLUGIN_OK;
            break;

         case GET_ATTRIB_TOOMANY:
            /* More than one "group name" attribute found for
             * this group.  This is not a fatal error: we log
             * an informational message and process the first
             * name only.
             */
            msg = "more than one group name found.";
            loglevel = DB2SEC_LOG_INFO;
            rc = DB2SEC_PLUGIN_OK;
            break;

         case GET_ATTRIB_LDAPERR:
            msg = "LDAP error while searching for group name.";
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            break;

         case GET_ATTRIB_NOMEM:
            msg = "out of memory while searching for group name.";
            rc = DB2SEC_PLUGIN_NOMEM;
            break;

         case GET_ATTRIB_BADINPUT:
         default:
            msg = "internal error while searching for group name.";
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            break;
      }

      len = snprintf(dumpMsg, sizeof(dumpMsg),
                     "LDAP getGroupNameByDN: %s\ngroup DN='%s'",
                     msg, groupDN);
      if (rc == DB2SEC_PLUGIN_OK)
      {
         db2LogFunc(loglevel, dumpMsg, len);
      }
      else
      {
         *errorMessage = strdup(dumpMsg);
         goto exit;
      }
   }

exit:
   return(rc);
}

/* EscapeDnAsSearchFilter
 *
 * Takes a DN and converts it so that it can be used as a search filter.
 * A DN can contain escape characters like '\,' but when we use it in 
 * a search filter we have to convert it to '\2C' where 2C is the hex
 * representation of the comma.
 *
 * The caller provides the dn and a buffer dnAsFilter and the length
 * of dnAsFilter (less null-terminator).  The output buffer
 * will be returned in outDnAsFilter.  If there is not enough
 * space in dnAsFilter this function will malloc a bigger buffer
 * and the caller will have to free the buffer.
 * So, if the buffer is big enough then *outDnAsFilter = dnAsFilter
 * otherwise *outDnAsFilter = malloc(strlen(dn)*2).
 */

static int EscapeDnAsSearchFilter( const char*  dn, 
                                   char*  dnAsFilter, 
                                   int    sizeOfFilter,
                                   char** outDnAsFilter )
{
   int rc = DB2SEC_PLUGIN_OK;
   int dnPos = 0;
   int filterPos = 0;
   int len;
   char dumpMsg[MAX_ERROR_MSG_SIZE];

   const int dnLen = strlen(dn);

   len = snprintf(dumpMsg, sizeof(dumpMsg),
                  "LDAP EscapeDnAsSearchFilter:\n"
                  "input dn='%s'",
                  dn );
   db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);

   *outDnAsFilter = NULL;

   // sizeOfFilter does not include null-terminator.
   for( dnPos = 0, filterPos = 0; 
        dnPos < dnLen && filterPos < sizeOfFilter; 
        dnPos++, filterPos++ )
   {
      dnAsFilter[ filterPos ] = dn[ dnPos ];

      if( dn[ dnPos ] == DB2LDAP_ESCAPE_CHAR )
      {
         // Advance to the character that is being escaped.
         // If the escape character is the last character then we end now.
         dnPos++;
         if( dnPos < dnLen )
         {
            // We will convert the escaped-character to hex.  
            // We need to make sure the filter has the space to hold the two 
            // characters.
            if( (filterPos+2) < sizeOfFilter )
            {
               filterPos++;  // Advance to next empty space
               snprintf( dnAsFilter+filterPos, 
                         sizeOfFilter-filterPos, 
                         "%2.2X", 
                         dn[ dnPos ] );
               filterPos++;  // Advance once more because we used up two spaces.
            }
            else
            {
               len = snprintf(dumpMsg, sizeof(dumpMsg), 
                              "LDAP EscapeDnAsSearchFilter: out of space in "
                              "dnAsFilter parameter.\n" );
               db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
               rc = DB2SEC_PLUGIN_NOMEM;
               break;
            }
         }
      }
   }

   if( rc == DB2SEC_PLUGIN_OK )
   {
      // sizeOfFilter is the size of the buffer that can hold the filter without
      // the null terminator.  We are therefore garantee to have enough space for the
      // null terminator.
      dnAsFilter[ filterPos ] = '\0';

      *outDnAsFilter = dnAsFilter;
      len = snprintf(dumpMsg, sizeof(dumpMsg), 
                     "LDAP EscapeDnAsSearchFilter:\n"
                     "dnAsFilter='%s'",
                     dnAsFilter );
      db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
   }
   else if( rc == DB2SEC_PLUGIN_NOMEM )
   {
      const int newLen = strlen(dn) * 2;
      char* newDnAsFilter = NULL;

      // The following check is to prevent a coding error that would
      // have caused an infinite loop. If the dn is nothing but escape 
      // sequences then the maximum expansion is 3/2. Therefore, 
      // doubling the output buffer should be sufficient.  If there 
      // was a bug we would come in again and the sizeOfFilter would
      // be exactly twice of strlen(dn).  If that is the case then we 
      // will not continue.
      if( newLen > sizeOfFilter )
      {
         newDnAsFilter = malloc( newLen );
         if( newDnAsFilter != NULL )
         {
            // It is impossible for the call to EscapeDnAsSearchFilter
            // to allocate another buffer and thus we are not going to
            // check and free newDnAsFilter.
            rc = EscapeDnAsSearchFilter( dn, 
                                         newDnAsFilter, 
                                         newLen-1, 
                                         outDnAsFilter );
         }
         else
         {
            rc = DB2SEC_PLUGIN_NOMEM;
         }
      }
   }

   return rc;
}


/* findGroupsByDnAttr
 *
 * Looks up group membership information for a DN by retreiving an
 * attribute of that DN.  The input DN may be either a user or a
 * group, as determined by the dnIsGroup flag.
 *
 * Groups are appended to the linked list passed as "head".
 *
 * Returns: 0 for success, or a DB2 plugin error code.
 */
DB2LDAP_EXT_C
static int findGroupsByDnAttr(LDAP          *ld,
                              const char    *DN,
                              int            dnIsGroup,
                              groupListHead *head)
{
   int rc = DB2SEC_PLUGIN_OK;
   int  len, i;
   char *objClass = NULL;
   char *attrs[2];
   char filter[MAX_FILTER_LENGTH];
   char dnAsFilterBuffer[MAX_FILTER_LENGTH];
   char *dnAsFilter = NULL;
   char dumpMsg[MAX_ERROR_MSG_SIZE];
   char **values = NULL;

   LDAPMessage *ldapRes = NULL;
   LDAPMessage *ldapEntry = NULL;

   // Convert the DN to a format that can be used
   // as a search filter.
   rc = EscapeDnAsSearchFilter( DN, 
                                dnAsFilterBuffer, 
                                sizeof(dnAsFilterBuffer)-1, 
                                &dnAsFilter );

   if( rc != DB2SEC_PLUGIN_OK )
   {
      goto exit;
   }

   if (dnIsGroup)
   {
      objClass  = ConfigData.groupObjClass;
   }
   else
   {
      objClass  = ConfigData.userObjClass;
   }

   snprintf(filter, sizeof(filter), "(objectClass=%s)", objClass);

   // Dump the filter.  We can see the filter if diaglevel is 4.
   len = snprintf(dumpMsg, sizeof(dumpMsg), 
                  "LDAP findGroupsByDnAttr:\n"
                  "dn='%s'\n"
                  "filter='%s'",
                  DN, filter);
   db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);

   attrs[0] = ConfigData.groupLookupAttr;
   attrs[1] = NULL;

   rc = ldap_search_s(ld, dnAsFilter, LDAP_SCOPE_BASE,
                      filter, attrs, FALSE, &ldapRes);

   if (rc != LDAP_SUCCESS )
   {
      if (rc == LDAP_NO_SUCH_ATTRIBUTE) 
      {
         /* No groups associated with this DN. */
         rc = DB2SEC_PLUGIN_OK;
         goto exit;
      }
      else if (rc == LDAP_NO_SUCH_OBJECT) 
      {
         goto error_DN_not_found;
      }
      else if( rc == LDAP_REFERRAL )
      {
         rc = LDAP_SUCCESS;
      }
      else
      {
         len = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP findGroupsByDnAttr: "
                        "group search failed with ldap rc=%d (%s)\n"
                        "dn='%s'\n"
                        "dnAsFilter='%s'\n"
                        "filter='%s'",
                        rc, ldap_err2string(rc), DN, dnAsFilter, filter);
         db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, len);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }
   }
   
   ldapEntry = ldap_first_entry(ld, ldapRes);
   if (ldapEntry == NULL) goto error_DN_not_found;

   /* values might be NULL here if this DN does not belong to any groups. */
   values = ldap_get_values(ld, ldapEntry, attrs[0]);
   if (values != NULL)
   {
      i = 0;
      while(values[i] != NULL)
      {
         /* If this group DN is already in the list then skip it. */
         if (!isGrpDNinList(head, values[i]))
         {
            rc = addGroupToList(head, values[i]);
            if (rc != DB2SEC_PLUGIN_OK)
            {
               len = snprintf(dumpMsg, sizeof(dumpMsg),
                              "LDAP findGroupsByDnAttr: addGroupToList "
                              "rc=%d for group DN '%s'\n", rc, values[i]);
               db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, len);
               goto exit;
            }
         }

         i++;
      }

      ldap_value_free(values);
   }

exit:
   if (ldapRes != NULL) ldap_msgfree(ldapRes);
   if (dnAsFilter != dnAsFilterBuffer ) free( dnAsFilter );

   return(rc);

error_DN_not_found:
   len = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP findGroupsByDnAttr: "
                  "DN not found in LDAP (isGroup=%d)\n"
                  "DN='%s'\n"
                  "dnAsFilter='%s'\n"
                  "filter='%s'",
                  dnIsGroup, DN, dnAsFilter, filter );
   db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
   /* This is not a severe error: may be a config problem or there
    * may be no LDAP object of the correct object class.
    */
   rc = DB2SEC_PLUGIN_OK;
   goto exit;
}



/* findGroupsByMember
 *
 * Searches for LDAP group entries that list the input DN as a
 * member (via the group lookup attribute).
 *
 * Groups are appended to the linked list passed as "head".
 *
 * Returns: 0 for success, or a DB2 plugin error code.
 */
DB2LDAP_EXT_C
static int findGroupsByMember(LDAP          *ld,
                              const char    *DN,
                              int            dnIsGroup,   /* not used */
                              groupListHead *head)
{
   int rc = DB2SEC_PLUGIN_OK; 
   int  len;
   char *objClass = NULL;
   char *grpDN = NULL;
   char filter[MAX_FILTER_LENGTH];
   char dnAsFilterBuffer[MAX_FILTER_LENGTH];
   char *dnAsFilter = NULL;
   char dumpMsg[MAX_ERROR_MSG_SIZE];
   const char *msg = NULL;

   LDAPMessage *ldapRes = NULL;
   LDAPMessage *ldapEntry = NULL;

   // Convert the DN to a format that can be used
   // as a search filter.
   rc = EscapeDnAsSearchFilter( DN, 
                                dnAsFilterBuffer, 
                                sizeof(dnAsFilterBuffer)-1, 
                                &dnAsFilter );

   if( rc != DB2SEC_PLUGIN_OK )
   {
      goto exit;
   }

   snprintf(filter, sizeof(filter),
            "(&(objectClass=%s)(%s=%s))",
            ConfigData.groupObjClass, ConfigData.groupLookupAttr, dnAsFilter);

   // Dump the filter. We can see the filter if diaglevel is 4.
   len = snprintf(dumpMsg, sizeof(dumpMsg), 
                  "LDAP findGroupsByMember:\n"
                  "dn='%s'\n"
                  "filter='%s'",
                  DN, filter);
   db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);

   rc = ldap_search_s(ld, ConfigData.groupBase, LDAP_SCOPE_SUBTREE,
                      filter, NULL, TRUE, &ldapRes);

   if (rc != LDAP_SUCCESS )
   {
      if( rc == LDAP_REFERRAL )
      {
         rc = LDAP_SUCCESS;
      }
      else if ((rc == LDAP_NO_SUCH_OBJECT) || (LDAP_INVALID_DN_SYNTAX == rc)) /// the return error code from Lotus LDAP Server is LDAP_INVALID_DN_SYNTAX
      {
         /* No groups found that list this DN as a member. */
         rc = DB2SEC_PLUGIN_OK;
         goto exit;
      }
      else
      {
         len = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP findGroupsByMember: "
                        "group search failed with ldap rc=%d (%s)\n"
                        "dn='%s'\n"
                        "filter='%s'",
                        rc, ldap_err2string(rc), DN, filter);
         db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, len);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }
   }

   ldapEntry = ldap_first_entry(ld, ldapRes);
   while (ldapEntry != NULL)
   {
      grpDN = ldap_get_dn(ld, ldapEntry);

      if (grpDN == NULL)
      {
         rc = ldap_get_errno(ld);
         len = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP findGroupsByMember:\n"
                        "ldap rc=%d (%s) trying to get DN for search result\n"
                        "search DN='%s'\n"
                        "filter='%s'",
                        rc, ldap_err2string(rc), DN, filter);
         db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, len);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }

      /* If this group DN is already in the list then skip it. */
      if (!isGrpDNinList(head, grpDN))
      {
         rc = addGroupToList(head, grpDN);
         if (rc != DB2SEC_PLUGIN_OK)
         {
            len = snprintf(dumpMsg, sizeof(dumpMsg),
                           "LDAP findGroupsByMember: addGroupToList "
                           "rc=%d for group DN '%s'\n", rc, grpDN);
            db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, len);
            ldap_memfree(grpDN);
            goto exit;
         }

      }

      ldap_memfree(grpDN);
      grpDN = NULL;

      ldapEntry = ldap_next_entry(ld, ldapEntry);
   }

exit:
   if (grpDN   != NULL) ldap_memfree(grpDN);
   if (ldapRes != NULL) ldap_msgfree(ldapRes);
   if (dnAsFilter != dnAsFilterBuffer ) free( dnAsFilter );

   return(rc);
}



/* FindGroups
 *
 * Find the groups memberships associated with the input AuthID.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN FindGroups(const char *authID,
                                 db2int32 authIDLength,
                                 const char *userID,             /* ignored */
                                 db2int32 userIDLength,          /* ignored */
                                 const char *domain,             /* ignored */
                                 db2int32 domainLength,          /* ignored */
                                 db2int32 domainType,            /* ignored */
                                 const char *databaseName,       /* ignored */
                                 db2int32 databaseNameLength,    /* ignored */
                                 void *token,
                                 db2int32 tokenType,
                                 db2int32 location,
                                 const char *authPluginName,     /* ignored */
                                 db2int32 authPluginNameLength,  /* ignored */
                                 void **groupList,
                                 db2int32 *groupCount,
                                 char **errorMessage,
                                 db2int32 *errorMessageLength)
{
   int      rc = DB2SEC_PLUGIN_OK;
   LDAP    *ld = NULL;
   int      freeLDAP = FALSE;
   int      totalLen, len, num;
   char     local_authid[DB2SEC_MAX_AUTHID_LENGTH + 1];
   char     dumpMsg[MAX_ERROR_MSG_SIZE];
   token_t *pToken = NULL;
   char    *userDN = NULL;
   int      freeUserDN = FALSE;
   char    *gname = NULL;

   groupElem *cur = NULL;
   groupListHead grpList, grpList2;
   unsigned char *ucp = NULL;

   LDAPMessage *ldapRes = NULL;
   LDAPMessage *ldapEntry = NULL;

   int (*lookupFnc)(LDAP *, const char *, int, groupListHead *);

   *errorMessage = NULL;
   *errorMessageLength = 0;

   memset(&grpList,  0, sizeof(grpList));
   memset(&grpList2, 0, sizeof(grpList2));

   if (authID == NULL || groupList == NULL || groupCount == NULL)
   {
      *errorMessage = strdup("LDAP FindGroups: invalid arguments");
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }

   if (authIDLength > DB2SEC_MAX_AUTHID_LENGTH)
   {
      strncpy(local_authid, authID, DB2SEC_MAX_AUTHID_LENGTH);
      local_authid[DB2SEC_MAX_AUTHID_LENGTH] = '\0';
      snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups: "
               "AuthID too long (%d bytes)\n[Truncated]:%s",
               (int)authIDLength, local_authid);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }

   memcpy(local_authid, authID, authIDLength);
   local_authid[authIDLength] = '\0';

   if ((location == DB2SEC_SERVER_SIDE) &&
       (tokenType == DB2SEC_GENERIC) &&
       (token != NULL))
   {
      pToken = (token_t *)token;

      if (memcmp(pToken->eyeCatcher,
                 DB2LDAP_TOKEN_EYECATCHER,
                 sizeof(DB2LDAP_TOKEN_EYECATCHER)) == 0)
      {
         if (pToken->ld != NULL)
         {
            ld = pToken->ld;
            freeLDAP = FALSE;
         }

         /* If the authid matches the one stored in the token
          * (which it should if we a token at all), we may be
          * able to grab the user DN from the token as well.
          */
         if ((pToken->userDN[0] != '\0') &&
             (pToken->authidLen == authIDLength) &&
             (strcasecmp(pToken->authid, local_authid) == 0))
         {
            userDN = pToken->userDN;
         }
      }
   }   

   if (ld == NULL)
   {
      rc = initLDAP(&ld, TRUE, errorMessage);
      if (rc != LDAP_SUCCESS) goto exit;
      freeLDAP = TRUE;
   }

   /* Get the user DN if we don't have it yet. */
   if (userDN == NULL)
   {
      char filter[MAX_FILTER_LENGTH];

      snprintf(filter, sizeof(filter),
               "(&(objectClass=%s)(%s=%s))",
               ConfigData.userObjClass, ConfigData.authidAttr, local_authid);
      
      rc = ldap_search_s(ld, ConfigData.userBase, LDAP_SCOPE_SUBTREE,
                         filter, NULL, TRUE, &ldapRes);
      if ( rc != LDAP_SUCCESS )
      {
         if ( rc == LDAP_REFERRAL )  // We have chased a referral.
         {
            size_t msgLength = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups:\n"
                                        "ldap_search_s chased referral rc=%d (%s)\nfilter=%s",
                                        rc, ldap_err2string(rc), filter);
            db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, msgLength);
            rc = LDAP_SUCCESS;
         }
         else
         {
            if (rc == LDAP_NO_SUCH_OBJECT)
            {
               snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups:\n"
                        "can't find user with authid '%s'\nrc=%d (%s)\nfilter=%s",
                        local_authid, rc, ldap_err2string(rc), filter);
               rc = DB2SEC_PLUGIN_BADUSER;
            }
            else
            {
               snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups:\n"
                        "unexpected LDAP error searching for authid '%s'\n"
                        "rc=%d (%s)\nfilter=%s",
                        local_authid, rc, ldap_err2string(rc), filter);
               rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            }
            *errorMessage = strdup(dumpMsg);
            goto exit;
         }
      }

      num = ldap_count_entries(ld, ldapRes);
      if (num == 0)
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups:\n"
                  "can't find user with authid '%s'\nfilter=%s",
                  local_authid, filter);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BADUSER;
         goto exit;
      }

      if (num > 1)
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups:\n"
                  "too many users (%d) found searching for authid '%s'",
                  num, local_authid);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BADUSER;
         goto exit;
      }

      ldapEntry = ldap_first_entry(ld, ldapRes);
      if (ldapEntry != NULL)
      {
         userDN = ldap_get_dn(ld, ldapEntry);
         freeUserDN = TRUE;
      }
      if (userDN == NULL)
      {
         rc = ldap_get_errno(ld);
         snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups:\n"
                  "error retreiving user DN after successful authid search\n"
                  "ldap rc=%d (%s)\nauthid='%s'",
                  rc, ldap_err2string(rc), local_authid);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BADUSER;
         goto exit;
      }
   }


   /* Determine which group lookup function to call. */
   if (ConfigData.groupLookupMethod == GROUP_METHOD_USER_ATTR)
   {
      lookupFnc = findGroupsByDnAttr;
   }
   else
   {
      lookupFnc = findGroupsByMember;
   }

   rc = lookupFnc(ld, userDN, FALSE, &grpList);
   if (rc != DB2SEC_PLUGIN_OK)
   {
      snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups: "
               "rc=%d retrieving groups for authid '%s'\nuserDN='%s'",
               rc, local_authid, userDN);
      *errorMessage = strdup(dumpMsg);
      goto exit;
   }

   /* If we found no groups for the user, return now. */
   if (grpList.first == NULL)
   {
      if (ConfigData.debug)
      {
         int len;
         len = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups: "
                        "found no groups for authid '%s'\nuserDN='%s'",
                        local_authid, userDN);
         db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
      }
      *groupList = NULL;
      *groupCount = 0;

      rc = DB2SEC_PLUGIN_OK;
      goto exit;
   }

   /* If we want nested group information, walk the linked list of
    * groups found above and get the group information for each
    * one in turn.  The list can grow whlie we're processing it.
    */
   if (ConfigData.nestedGroups == TRUE)
   {
      cur = grpList.first;
      while (cur != NULL)
      {
         rc = lookupFnc(ld, cur->name, TRUE, &grpList);
         if (rc != DB2SEC_PLUGIN_OK)
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups: "
                     "rc=%d retrieving nested groups\ngroupDN='%s'",
                     rc, cur->name);
            *errorMessage = strdup(dumpMsg);
            goto exit;
         }

         cur = cur->next;
      }
   }

   /* Now we have all the group DNs in a linked list.
    * Walk through the list, retreive the group name for each
    * group DN and store it in a new list.  Keep track of the
    * total length we'll need to return the group information.
    */
   totalLen = 0;
   cur = grpList.first;
   while(cur != NULL)
   {
      gname = NULL;
      rc = getGroupNameByDN(ld, cur->name, &gname, errorMessage);
      if (rc != DB2SEC_PLUGIN_OK) goto exit;

      if (gname != NULL)
      {
         /* Ignore group names that are too long */
         len = strlen(gname);
         if (len <= DB2SEC_MAX_AUTHID_LENGTH)
         {
            rc = addGroupToList(&grpList2, gname);
            if (rc != DB2SEC_PLUGIN_OK)
            {
               snprintf(dumpMsg, sizeof(dumpMsg),
                        "LDAP FindGroups: addGroupToList "
                        "rc=%d for group DN '%s'\n", rc, cur->name);
               *errorMessage = strdup(dumpMsg);
               goto exit;
            }

            totalLen += len + 2;  /* length byte + NULL byte */
         }

         free(gname);
         gname = NULL;
      }

      cur = cur->next;
   }


   /* It's possible that we have no group information here,
    * if we couldn't find names for any of the group DNs.
    */
   if (totalLen <= 0)
   {
      if (ConfigData.debug)
      {
         int len;
         len = snprintf(dumpMsg, sizeof(dumpMsg), "LDAP FindGroups: "
                        "zero length group info\nauthid='%s'\nuserDN='%s'",
                        local_authid, userDN);
         db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
      }
      *groupList = NULL;
      *groupCount = 0;

      rc = DB2SEC_PLUGIN_OK;
      goto exit;
   }


   /* Now malloc & populate the group list that will be returned to DB2. */
   *groupList = malloc(totalLen);
   if (*groupList == NULL)
   {
      *errorMessage = strdup("LDAP FindGroups: malloc failure");
      rc = DB2SEC_PLUGIN_NOMEM;
      goto exit;
   }

   *groupCount = 0;
   ucp = (unsigned char*)(*groupList);
   cur = grpList2.first;
   while (cur != 0)
   {
      len = strlen(cur->name);
      *ucp = (unsigned char)len;
      ucp++;

      memcpy(ucp, cur->name, len);
      ucp += len;

      (*groupCount)++;

      cur = cur->next;
   }


exit:
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);

      /* If DB2 receives a BADUSER returncode from this function it
       * assumes the group lookup and authentication plugins are not
       * compatible (which could very well be the case).
       *
       * Since this can be difficult to debug, we want to explicitly
       * log the error here, but at INFO level rather than ERROR.
       */
      if (rc == DB2SEC_PLUGIN_BADUSER && !ConfigData.debug)
      {
         db2LogFunc(DB2SEC_LOG_INFO, *errorMessage, *errorMessageLength);
      }
      else
      {
         db2LogFunc(DB2SEC_LOG_ERROR, *errorMessage, *errorMessageLength);
      }
   }

   if (freeUserDN && userDN != NULL) ldap_memfree(userDN);

   if (ldapRes != NULL) ldap_msgfree(ldapRes);

   if (freeLDAP && ld != NULL) ldap_unbind_s(ld);

   if (gname != NULL) free(gname);

   if (grpList.first  != NULL) freeList(&grpList);
   if (grpList2.first != NULL) freeList(&grpList2);

   return(rc);
}




/* FreeGroupList
 *
 * Free the group list information returned from FindGroups.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN FreeGroupList(void *ptr,
                                    char **errorMessage,
                                    db2int32 *errorMessageLength)
{
    if (ptr != NULL) free(ptr);

    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}



/* DoesGroupExist
 * Search for a user object where the AuthID attribute matches the
 * value provided.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN DoesGroupExist(const char  *groupID,
                                     db2int32     groupIDlength,
                                     char       **errorMessage,
                                     db2int32    *errorMessageLength)
{
   int     rc = DB2SEC_PLUGIN_OK;
   int     filterLength = 0;
   LDAP   *ld = NULL;
   const char *errmsg = NULL;
   char    local_group[DB2SEC_MAX_AUTHID_LENGTH + 1];
   char    dumpMsg[MAX_ERROR_MSG_SIZE];

   *errorMessage = NULL;
   *errorMessageLength = 0;

   if (groupID == NULL || groupIDlength <= 0)
   {
      snprintf(dumpMsg, sizeof(dumpMsg),
               "LDAP DoesGroupExist: AUTHID is NULL or bad length (%d)",
               (int)groupIDlength);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }

   /* NULL terminate the groupID */
   if (groupIDlength > DB2SEC_MAX_AUTHID_LENGTH)
   {
      /* Make a NULL terminated version of known max size */
      strncpy(local_group, groupID, DB2SEC_MAX_AUTHID_LENGTH);
      local_group[DB2SEC_MAX_AUTHID_LENGTH] = '\0';

      snprintf(dumpMsg, sizeof(dumpMsg), "LDAP DoesGroupExist: "
               "groupID too long (%d bytes)\n[truncated]:%s",
               (int)groupIDlength, local_group);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }

   memcpy(local_group, groupID, groupIDlength);
   local_group[groupIDlength] = '\0';

   rc = initLDAP(&ld, TRUE, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;
    
   rc = db2ldapFindAttrib(ld,
                          ConfigData.groupBase,
                          ConfigData.groupObjClass,
                          ConfigData.groupNameAttr,
                          local_group,
                          ConfigData.groupNameAttr,
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
               "LDAP DoesGroupExist: GroupID=%s\n%s",
               local_group, errmsg);
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



/* db2secGroupPluginInit
 * Plugin initialization.  Parse the config file and set up function
 * pointers.
 */
DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN db2secGroupPluginInit(db2int32 version,
                                            void *group_fns,
                                            db2secLogMessage *msgFunc,
                                            char **errorMessage,
                                            db2int32 *errorMessageLength)
{
   int rc = DB2SEC_PLUGIN_OK;
   db2secGroupFunction_1  *p;

   *errorMessage = NULL;
   *errorMessageLength = 0;

   p = (db2secGroupFunction_1*)group_fns;

   p->version                   = DB2SEC_GROUP_FUNCTIONS_VERSION_1;
   p->plugintype                = DB2SEC_PLUGIN_TYPE_GROUP;
   p->db2secGetGroupsForUser    = FindGroups;
   p->db2secDoesGroupExist      = DoesGroupExist;
   p->db2secFreeGroupListMemory = FreeGroupList;
   p->db2secFreeErrormsg        = FreeErrorMessage;
   p->db2secPluginTerm          = PluginTerminate;

   db2LogFunc = msgFunc;

   memset(&ConfigData, 0, sizeof(ConfigData));

   rc = db2ldapReadConfig(&ConfigData, CFG_GROUPLOOKUP, errorMessage);
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
