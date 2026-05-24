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
**  Source File Name = src/gss/utils.h          (%W%)
**
**  Descriptive Name = Header file for a few utility functions 
**
**
**
***********************************************************************/

#ifndef _UTILS_H_
#define _UTILS_H_

#include <stddef.h>


#define AWS_USERPOOL_CFG_ENV              
#define AWS_USERPOOL_DEFAULTCFGFILE              "security64/plugin/cfg/cognito_userpools.json"
#define DB2OC_USER_REGISTRY_FILE "/mnt/blumeta0/db2_config/users.json"
#define DB2OC_USER_REGISTRY_ERROR_FILE "/mnt/blumeta0/db2_config/users.json.debug"

void stringToUpper(char *s);

void stringToLower(char *s);

#ifdef  __cplusplus
extern "C" {
#endif

const char* read_userpool_from_cfg();

#ifdef  __cplusplus
}
#endif

#endif  //_UTILS_H_
