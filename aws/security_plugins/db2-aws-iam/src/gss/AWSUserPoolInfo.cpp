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
**  Source File Name = src/gss/AWSUserPoolInfo.cpp          (%W%)
**
**  Descriptive Name = GSS based authentication plugin code that queries AWS for fetching userpool
**                     and clients information
**
**  Function: The code in this file has functions that fetches userpool clients in the given userpool
**            from AWS Cognito using AWS CPP SDK APIs
**
**
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
            db2Log(DB2SEC_LOG_ERROR, "No such user in the user pool: %s", userpoolID);
            ret = RETCODE_AWS_NO_USER_ATTRI;
        }
    }

    return ret;
}
