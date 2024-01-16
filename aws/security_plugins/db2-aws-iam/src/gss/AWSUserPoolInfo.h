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
*  Source File Name = src/gss/AWSUserPoolInfo.h   (%W%)
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
