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
*  Source File Name = src/gss/utils.h           (%W%)
*
*  Descriptive Name = Header file for the Server side OS-based authentication 
*                     plugin code (iam.cpp)
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***********************************************************************/

#ifndef _UTILS_H_
#define _UTILS_H_

#include <stddef.h>


#define AWS_USERPOOL_CFG_ENV              
#define AWS_USERPOOL_DEFAULTCFGFILE              "security64/plugin/cfg/cognito_userpools.json"

#ifdef  __cplusplus
extern "C" {
#endif

const char* read_userpool_from_cfg();

#ifdef  __cplusplus
}
#endif

#endif  //_UTILS_H_
