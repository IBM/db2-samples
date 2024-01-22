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
*  Source File Name = src/gss/AWSIAMauthgroup.c
*
*  Descriptive Name = Plugin that queries AWS cognito for user groups and users.json for system's users
*
*  Function: Implements functions required by Db2 group plugin architeture
*            This plugin is meant to be used with AWS IAM security plugin.
*
*            With AWS IAM security plugin in place, the authentication will be
*            done against IAM, and not through the OS. Assuming the
*            authentication is successful, the next step is to determine
*            authorization. For AWS IAM user, all the groups must be collected from AWS cognito.
*            The collected group names are aggregated to
*            form the full list. In case of OS based authentication, users.json 
*            will be looked at to get the groups of default system user like db2inst1.
*
*
*  Dependencies: None
*
*  Restrictions: None
*
*
*******************************************************************************/

#include <sqlenv.h>
#include <db2secPlugin.h>
#include "AWSIAMauthfile.h"
#include "../common/usersjson.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <json-c/json.h>
#include <sqlenv.h>
#include <db2secPlugin.h>
#include "AWSIAMauth.h"
#include "AWSIAMauthfile.h"
#include "../common/hash.h"
#include "../common/AWSIAMtrace.h"
#include "iam.h"
#include "AWSUserGroupInfo.h"
#include <time.h>
#include "utils.h"

db2secLogMessage *db2LogFunc = NULL;
#define JSON_READ_ERROR "Error reading json objects from %s"

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

   IAM_TRACE_ENTRY("addGroupToList");
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

exit:
   IAM_TRACE_EXIT("addGroupToList", rc);
   return(rc);
}

/* freeList
 *
 * Free the memory associated with the list anchored by "head".
 */
static void freeList(groupListHead  *head)
{
   groupElem *cur, *next;

   IAM_TRACE_ENTRY("freeList");

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

exit:
   IAM_TRACE_EXIT("freeList", 0);
   return;
}



/* FindGroups
 *
 * Find the groups memberships associated with the input AuthID.
 * 
 * <= authID - this will be the authorization ID and it is always uppercase
 * 
 */
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
   int      totalLen=0, len=0, num=0;
   char     local_authid[DB2SEC_MAX_AUTHID_LENGTH + 1] = "";
   char     dumpMsg[MAX_ERROR_MSG_SIZE] = "";
   bool      inUsersJson = TRUE;
   const char *groupListG = NULL;
   groupElem *cur = NULL;
   groupListHead grpList, grpList2;
   unsigned char *ucp = NULL;
   struct json_object *parsed_json = NULL;
   CONTEXT_T* pCtxt = (CONTEXT_T*)token;
   int i;
   struct json_object *passwordt = NULL, *user_json = NULL, *user = NULL, *group = NULL;
   char     *gname = NULL;
   struct timespec ts;

   *errorMessage = NULL;
   *errorMessageLength = 0;

   IAM_TRACE_ENTRY("FindGroups");

   memset(&grpList,  0, sizeof(grpList));
   memset(&grpList2, 0, sizeof(grpList2));
   if (authIDLength > DB2SEC_MAX_AUTHID_LENGTH)
   {
      char    dumpMsg[256] ="";
      strncpy(local_authid, authID, DB2SEC_MAX_AUTHID_LENGTH);
      local_authid[DB2SEC_MAX_AUTHID_LENGTH] = '\0';
      snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: "
               "AuthID is too long (%d bytes)\n[Truncated]:%s",
               (int)authIDLength, local_authid);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   } 

   memcpy(local_authid, authID, authIDLength);
   local_authid[authIDLength] = '\0'; 

   IAM_TRACE_DATA("FindGroups, local_authid:", local_authid);

   if (authID == NULL || groupList == NULL || groupCount == NULL)
   {
      *errorMessage = strdup("FindGroups: invalid arguments");
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }
   IAM_TRACE_DATA("FindGroups", "Started collecting token groups from context");
   totalLen = 0;

   if (tokenType == DB2SEC_GENERIC)
   {
   // Check for system user
   // open the user registry file
      char json_err[256];
      parsed_json = json_object_from_file(DB2OC_USER_REGISTRY_FILE);

      for(int retries = 0; retries < 5 && parsed_json == NULL; retries++)
      {
#ifdef JSON_C_0_13
         char* json_e = json_util_get_last_err();
         strcpy(json_err, json_e);
#else
         snprintf(json_err, sizeof(json_err), JSON_READ_ERROR , DB2OC_USER_REGISTRY_FILE);
#endif
         UsersJsonErrorMsg("FindGroups", errorMessage, errorMessageLength, json_err);
         db2LogFunc(DB2SEC_LOG_ERROR, *errorMessage, *errorMessageLength);
         free(*errorMessage);
         *errorMessage = NULL;
         ts.tv_sec = 0;
         ts.tv_nsec = 100000000;
         nanosleep(&ts, NULL); // sleep for 100 ms
         parsed_json = json_object_from_file(DB2OC_USER_REGISTRY_FILE);
      } 

      if(parsed_json == NULL)
      {
#ifdef JSON_C_0_13
         char* json_e = json_util_get_last_err();
         strcpy(json_err, json_e);
#else
         snprintf(json_err, sizeof(json_err), JSON_READ_ERROR , DB2OC_USER_REGISTRY_FILE);
#endif
         UsersJsonErrorMsg("FindGroups", errorMessage, errorMessageLength, json_err);
         rc = DB2SEC_PLUGIN_BADUSER;
         DumpUsersJson(DB2OC_USER_REGISTRY_FILE, db2LogFunc);
         goto exit;
      }

      json_object_object_get_ex(parsed_json, "users", &user_json);

      // Authorization IDs are upper case. The user file can be lower case 
      // Convert it to lower if we can't find it the first time.
      if(!json_object_object_get_ex(user_json, local_authid, &user))
      {
         stringToLower(local_authid);
         if(!json_object_object_get_ex(user_json, local_authid, &user)) inUsersJson = FALSE;
      }

      len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: found in users %d ",
                        inUsersJson);
      db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
         
      if(inUsersJson)
      {
         json_object_object_get_ex(user, "group", &group);

         groupListG = json_object_get_string(group);

         if (groupListG == NULL)
         {
            len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: no groups found for users %s ",
                        local_authid);
            db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
            IAM_TRACE_DATA("findGroups", "is NULL");
            gname = NULL;
         } else {
            IAM_TRACE_DATA("findGroups", "is NOT NULL");
            // We have the group list if it exists - parse it and add the groups to the list
            gname = strtok ((char*)groupListG,",");
            len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: groups found for users %s: %s ",
                        local_authid, gname);
            db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
         }
         
         while (gname != NULL) 
         {
            len = strlen(gname);
            if (len <= DB2SEC_MAX_AUTHID_LENGTH)
            {
               rc = addGroupToList(&grpList2, gname); 
               if (rc != DB2SEC_PLUGIN_OK)
               {
                  char    dumpMsg[256] ="";
                  snprintf(dumpMsg, sizeof(dumpMsg),
                           "FindGroups: addGroupToList "
                           "rc=%d for group '%s'\n", rc, gname);
                  *errorMessage = strdup(dumpMsg);
                  goto exit;
               }

               gname = strtok (NULL, ",");
               totalLen += len +2;  /* length of gname + 1 byte + NULL */  
            }
         }

         if(totalLen > 0) 
            goto populate;
         rc = DB2SEC_PLUGIN_USERSTATUSNOTKNOWN;
         goto exit;
      }
      else
      {
         len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: no group found for user %s in users.json",
                        local_authid);
         db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);      
      }
   }

   if (tokenType == DB2SEC_GSSAPI_CTX_HANDLE)
   {
      const char* userPoolID = read_userpool_from_cfg();
      AWS_USER_GROUPS_T* awsusergroups = NULL;
      rc = FetchAWSUserGroups(local_authid, userPoolID, &awsusergroups);
      if( rc == 0 )
      {
         len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: groups found for users from AWS %s: %d ",
                        local_authid, awsusergroups->groupCount);
         db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
         if(awsusergroups->groupCount < 100){
            /* If the group info is recieved from the token, 
            * populate the group list and return the list 
            * directly to DB2.
            */
            for( i = 0; i < awsusergroups->groupCount; ++i )
            { 
               printf("Groups from AWS: %s", awsusergroups->groups[i].group_name);
               rc = addGroupToList(&grpList2, awsusergroups->groups[i].group_name );
               if (rc != DB2SEC_PLUGIN_OK)
               {
                  snprintf(dumpMsg, sizeof(dumpMsg),
                              "FindGroups: addGroupToList "
                              "rc=%d for AWS cognito groups \n", rc);
                  *errorMessage = strdup(dumpMsg);
                  goto exit;
               }
               totalLen += awsusergroups->groups[i].groupNameLen + 2;  /* length byte + NULL byte */
            }
            IAM_TRACE_DATA("FindGroups", "Finished collecting token groups from context");
            goto populate;
         } 
      }
      else
      {
         len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: no group found for user %s either from users.json or from AWS ",
                        local_authid);
         db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);
      }
   }  
   /* If we found no groups for the user, return now. */
   if (grpList.first == NULL)
   {
      *groupList = NULL;
      *groupCount = 0;

      rc = DB2SEC_PLUGIN_OK;
      goto exit;
   }

   /* It's possible that we have no group information here,
    * if we couldn't find names for any of the group DNs.
    */

populate:
  /* It's possible that we have no group information here,
   * if we couldn't find any roles in Azure AD.
   */
   if ( totalLen <= 0 )
   {
      strncpy(local_authid, authID, DB2SEC_MAX_AUTHID_LENGTH);
      local_authid[DB2SEC_MAX_AUTHID_LENGTH] = '\0'; 
      len = snprintf(dumpMsg, sizeof(dumpMsg), "FindGroups: "
                        "No db2 groups for authid='%s' \n",
                        local_authid );
      db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, len);

      *groupList = NULL;
      *groupCount = 0;
      rc = DB2SEC_PLUGIN_OK;
      goto exit;
   }
  
   /* Now malloc & populate the group list that will be returned to DB2. */
   *groupList = malloc(totalLen);
   if (*groupList == NULL)
   {
       *errorMessage = strdup("FindGroups: malloc failure");
       rc = DB2SEC_PLUGIN_NOMEM;
       goto exit;
   }

   *groupCount = 0;

   // Copy the group list to the Memory allocated above (will be freed by Db2)
   ucp = (unsigned char*)(*groupList);

   cur = grpList2.first;

   // Format of the return is <one byte length><group string><one byte length><group string>
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
   IAM_TRACE_EXIT("FindGroups", rc);

   if (grpList.first != NULL) freeList(&grpList);
   if (grpList2.first != NULL) freeList(&grpList2);
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);
      db2LogFunc(DB2SEC_LOG_ERROR, *errorMessage, *errorMessageLength);
   }
   return rc;
}

/* FreeGroupList
 *
 * Free the group list information returned from FindGroups.
 */

SQL_API_RC SQL_API_FN FreeGroupList(void *ptr,
                                    char **errorMessage,
                                    db2int32 *errorMessageLength)
{
   IAM_TRACE_ENTRY("FreeGroupList");
   if (ptr != NULL) free(ptr);

   *errorMessage = NULL;
   *errorMessageLength = 0;
   IAM_TRACE_EXIT("FreeGroupList", DB2SEC_PLUGIN_OK);
   return(DB2SEC_PLUGIN_OK);
}



/* DoesGroupExist
 * Search for a user object where the AuthID attribute matches the
 * value provided.
 */

SQL_API_RC SQL_API_FN DoesGroupExist(const char  *groupID,
                                     db2int32     groupIDlength,
                                     char       **errorMessage,
                                     db2int32    *errorMessageLength)
{
   int     rc = DB2SEC_PLUGIN_OK;
   IAM_TRACE_ENTRY("DoesGroupExist");

   const char* userPoolID = read_userpool_from_cfg();
   rc = DoesAWSGroupExist(groupID, userPoolID);
   if(rc != 0)
   {
     *errorMessage = "No user found in the given user pool";
     *errorMessageLength = strlen(*errorMessage);  
     goto exit;
   }
   else
   {
     *errorMessage = NULL;
     *errorMessageLength = 0;
   }
exit:
   IAM_TRACE_EXIT("DoesGroupExist", rc);
   return (rc);
}


/* db2secGroupPluginInit
 * Plugin initialization.  Parse the config file and set up function
 * pointers.
 */

SQL_API_RC SQL_API_FN db2secGroupPluginInit(db2int32 version,
                                            void *group_fns,
                                            db2secLogMessage *msgFunc,
                                            char **errorMessage,
                                            db2int32 *errorMessageLength)
{
   IAM_TRACE_ENTRY("db2secGroupPluginInit");
   int rc = DB2SEC_PLUGIN_OK;
   db2secGroupFunction_1  *p;
   char message[1025];

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

exit:
   IAM_TRACE_EXIT("db2secGroupPluginInit", rc);
   if (*errorMessage != NULL)
   {
      *errorMessageLength = strlen(*errorMessage);
      db2LogFunc(DB2SEC_LOG_ERROR, *errorMessage, *errorMessageLength);
   }
   return(rc);
}
