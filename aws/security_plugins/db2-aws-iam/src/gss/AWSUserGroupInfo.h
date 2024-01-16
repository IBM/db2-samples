/**********************************************************************
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
*  Source File Name = src/gss/AWSUserGroupInfo.h   (%W%)
*
*  Descriptive Name = GSS based authentication plugin code that queries AWS for fetching user groups
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
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
