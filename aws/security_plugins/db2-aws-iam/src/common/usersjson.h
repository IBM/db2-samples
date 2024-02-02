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
**  Source File Name = src/common/usersjson.h           (%W%)
**
**  Descriptive Name = Header file for Code that handles users.json file (usersjson.h)
**
**  Function:
**
**  Dependencies:
**
**  Restrictions:
**
*****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <json-c/json.h>
#include <string.h>
#include "db2secPlugin.h"
#include "../gss/AWSIAMauthfile.h"
#include "AWSIAMtrace.h"

#ifdef __cplusplus
extern "C" {
#endif
void DumpUsersJson(const char* fileDestination, db2secLogMessage* logFunc);
void UsersJsonErrorMsg(const char* fnName, char** errorMessage, db2int32* errorMessageLength, const char* lstError);
#ifdef __cplusplus
}; 
#endif

