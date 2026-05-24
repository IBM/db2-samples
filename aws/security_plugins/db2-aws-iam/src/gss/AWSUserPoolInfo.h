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
**  Source File Name = src/gss/AWSUserPoolInfo.h          (%W%)
**
**  Descriptive Name = GSS based authentication plugin code that queries AWS for fetching userpool
**                     and clients information
**
**  Function: The code in this file has functions that fetches userpool clients in the given userpool
**            from AWS Cognito using AWS CPP SDK APIs
**
**
***********************************************************************/

#ifndef _AWS_USERPOOL_INFO_H_
#define _AWS_USERPOOL_INFO_H_

#include <stddef.h>
#include <db2secPlugin.h>

#ifdef  __cplusplus
extern "C" {
#endif

char** ListClientsForUserPool(const char *userpool, OM_uint32* ret, size_t* count, db2secLogMessage *logFunc);
OM_uint32 DoesAWSUserExist(const char *username, const char* userpoolID);

#ifdef  __cplusplus
}
#endif

#endif // _AWS_USERPOOL_INFO_H_
