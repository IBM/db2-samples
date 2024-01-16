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
*  Source File Name = src/gss/AWSUserGroupInfo.cpp          (%W%)
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

#include <aws/core/VersionConfig.h>
#include <aws/core/Aws.h>
#include <aws/cognito-idp/CognitoIdentityProviderClient.h>
#include <aws/cognito-idp/model/AdminListGroupsForUserRequest.h>

#include <aws/cognito-idp/model/GetGroupRequest.h>
#include <iostream>
#include "AWSUserGroupInfo.h"
#include "../common/AWSIAMtrace.h"
#include "AWSSDKRAII.h"

#include "AWSIAMauth.h"

OM_uint32 FetchAWSUserGroups(const char *username, const char* userpoolID, AWS_USER_GROUPS_T** awsusergroups)
{
    IAM_TRACE_ENTRY("FetchAWSUserGroups");
    OM_uint32 ret = RETCODE_OK;
    if(username == NULL || userpoolID == NULL)
    {
        return RETCODE_BADCFG;
    }
    db2Log( DB2SEC_LOG_INFO, "User groups to be fetched for username %s and poolID is %s", username, userpoolID);
    // Initialize the AWS SDK
    const Initialize init;
    {
        // Configure the Cognito Identity Provider client
        Aws::Client::ClientConfiguration clientConfig;
        Aws::CognitoIdentityProvider::CognitoIdentityProviderClient cognitoClient(clientConfig);
  
        // Specify the user pool ID and username
        Aws::CognitoIdentityProvider::Model::AdminListGroupsForUserRequest  request;
        request.SetUsername(username);
        request.SetUserPoolId(userpoolID);

        // Retrieve the user attributes
        Aws::CognitoIdentityProvider::Model::AdminListGroupsForUserOutcome  outcome = cognitoClient.AdminListGroupsForUser(request);
    
        if (outcome.IsSuccess())
        {
            const auto& userGroups = outcome.GetResult().GetGroups();
            *awsusergroups = (AWS_USER_GROUPS_T*) malloc(sizeof(AWS_USER_GROUPS_T));
            (*awsusergroups)->groups = (groupInfo_t*) malloc(sizeof(groupInfo_t)* userGroups.size());
            (*awsusergroups)->groupCount = userGroups.size();

            size_t i = 0;
            for (const auto& group : userGroups)
            {
                (*awsusergroups)->groups[i].group_name = group.GetGroupName().c_str();
                (*awsusergroups)->groups[i].groupNameLen = group.GetGroupName().size();
                ++i;
            }
        } 
        else
        {
            db2Log( DB2SEC_LOG_ERROR, "Error retrieving user attributes: %s", outcome.GetError().GetMessage().c_str() );
            ret = RETCODE_AWS_NO_USER_ATTRI;
        }
    }
    
    return ret;
}


OM_uint32 DoesAWSGroupExist(const char* groupName, const char* userpoolID)
{
    IAM_TRACE_ENTRY("DoesGroupExist");
    OM_uint32 ret = RETCODE_OK;
    if(groupName == NULL || userpoolID == NULL)
    {
        return RETCODE_BADCFG;
    }

    db2Log( DB2SEC_LOG_INFO, "Group existence to be checked for group: %s", groupName);
    // Initialize the AWS SDK
    const Initialize init;
    {
        // Configure the Cognito Identity Provider client
        Aws::Client::ClientConfiguration clientConfig;
        Aws::CognitoIdentityProvider::CognitoIdentityProviderClient cognitoClient(clientConfig);

        // Specify the user pool ID and username
        Aws::CognitoIdentityProvider::Model::GetGroupRequest request;
        request.SetGroupName(groupName);
        request.SetUserPoolId(userpoolID);

        // Retrieve the user attributes
        Aws::CognitoIdentityProvider::Model::GetGroupOutcome outcome = cognitoClient.GetGroup(request);
            
        if (!outcome.IsSuccess())
        {
            db2Log( DB2SEC_LOG_ERROR, "No such group in the user pool: %s ");
            ret = RETCODE_AWS_NO_USER_ATTRI;
        }
    }

    return ret;
}
