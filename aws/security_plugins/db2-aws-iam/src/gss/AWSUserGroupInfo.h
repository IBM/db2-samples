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
**********************************************************************************
**
**  Source File Name = src/gss/AWSUserGroupInfo.h         (%W%)
**
**  Descriptive Name = GSS based authentication plugin code that queries AWS for fetching user groups
**
**  Function: The code in this file has functions that  fetch group information for a particular user
**            from AWS Cognito using AWS CPP SDK APIs.
**
**
***********************************************************************/

#ifndef _AWS_USER_GROUP_INFO_H_
#define _AWS_USER_GROUP_INFO_H_

#include <stddef.h>
#include <db2secPlugin.h>
#include "iam.h"


#ifdef  __cplusplus
extern "C" {
#endif

typedef struct _groupInfo {
    const char *group_name;
    size_t groupNameLen;
} groupInfo_t;

typedef struct user_groups
{
  groupInfo_t* groups; 
  int groupCount;
} AWS_USER_GROUPS_T;

OM_uint32 FetchAWSUserGroups(const char *username, const char* userpoolID, AWS_USER_GROUPS_T** awsusergroups);

OM_uint32 DoesAWSGroupExist(const char* groupName, const char* userpoolID);

#ifdef  __cplusplus
}
#endif

#define MAX_STASH_BUFFER_LEN 255

#endif //_AWS_USER_GROUP_INFO_H_
