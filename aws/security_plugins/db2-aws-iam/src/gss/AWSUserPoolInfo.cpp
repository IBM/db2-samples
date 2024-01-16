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
*  Source File Name = src/gss/AWSUserPoolInfo.cpp          (%W%)
*
*  Descriptive Name = GSS based authentication plugin code that queries AWS for fetching userpool
*                     and clients information
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
#include <aws/cognito-idp/model/ListUserPoolClientsRequest.h>
#include <aws/cognito-idp/model/AdminGetUserRequest.h>
#include <iostream>
#include "AWSUserPoolInfo.h"
#include "AWSIAMauth.h"
#include "../common/AWSIAMtrace.h"
#include "AWSSDKRAII.h"

char** ListClientsForUserPool(const char *userpool, OM_uint32* ret, size_t* count, db2secLogMessage *logFunc)
{
    char** outClientIDs = NULL;
    // Initialize the AWS SDK
    const Initialize init;
    {
        // Configure the Cognito Identity Provider client
        Aws::Client::ClientConfiguration clientConfig;
        Aws::CognitoIdentityProvider::CognitoIdentityProviderClient cognitoClient(clientConfig);

        Aws::CognitoIdentityProvider::Model::ListUserPoolClientsRequest request;
        request.SetUserPoolId(userpool);
        Aws::CognitoIdentityProvider::Model::ListUserPoolClientsOutcome outcome = cognitoClient.ListUserPoolClients(request);
        db2Log(DB2SEC_LOG_INFO, "Client IDs requested from AWS from UserPool: %s ", userpool);

        if (outcome.IsSuccess()) {
            
            const auto& clientsDes = outcome.GetResult().GetUserPoolClients();
            *count = clientsDes.size();
            *ret = GSS_S_COMPLETE;
            outClientIDs = (char **)malloc(*count * sizeof(char *));
            size_t i = 0; 
            for (const auto& client : clientsDes) {
                const char* clientID = client.GetClientId().c_str();
                size_t len = strlen(clientID);
                outClientIDs[i] = (char *)malloc((len + 1 ) * sizeof(char)); 
                if(outClientIDs[i] != NULL)
                {
                    memset(outClientIDs[i], '\0', len+1);
                    memcpy(outClientIDs[i], clientID, len);
                    ++i;
                }
            }
        }
        else 
        {   
            *ret = RETCODE_AWS_NO_USER_ATTRI;
            db2Log(DB2SEC_LOG_ERROR, "Error retrieving user attributes: %s ", outcome.GetError().GetMessage());
        }
    }

    return outClientIDs;
}

OM_uint32 DoesAWSUserExist(const char *username, const char* userpoolID)
{
    IAM_TRACE_ENTRY("DoesUserExist");
    OM_uint32 ret = RETCODE_OK;
    if(username == NULL || userpoolID == NULL)
    {
        return RETCODE_BADCFG;
    }
    db2Log(DB2SEC_LOG_INFO, "User existence checked for username %s and poolID %s ", username, userpoolID);
    // Initialize the AWS SDK
    const Initialize init;
    {
        // Configure the Cognito Identity Provider client
        Aws::Client::ClientConfiguration clientConfig;
        Aws::CognitoIdentityProvider::CognitoIdentityProviderClient cognitoClient(clientConfig);

        Aws::CognitoIdentityProvider::Model::AdminGetUserRequest request;
        request.SetUsername(username);
        request.SetUserPoolId(userpoolID);

        Aws::CognitoIdentityProvider::Model::AdminGetUserOutcome outcome =
                cognitoClient.AdminGetUser(request);
      
        if (!outcome.IsSuccess())
        {
            db2Log(DB2SEC_LOG_ERROR, "No such user in the user pool: %s");
            ret = RETCODE_AWS_NO_USER_ATTRI;
        }
    }

    return ret;
}
