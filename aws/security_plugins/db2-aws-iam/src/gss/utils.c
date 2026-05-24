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
**  Source File Name = src/gss/utils.cpp           (%W%)
**
**  Descriptive Name = Implementation of a few utility functions 
**
**
**
***********************************************************************/
#include <stdio.h>
#include <db2secPlugin.h>
#include <json-c/json.h>
#include <stdbool.h>
#include "../common/AWSIAMtrace.h"
#include "utils.h"
#include "AWSIAMauth.h"

void stringToLower(char *s)
{
    int i=0;
    while(s[i]!='\0')
    {
        if(s[i]>='A' && s[i]<='Z'){
            s[i]=s[i]+32;
        }
        ++i;
    }
}

void stringToUpper(char *s)
{
    int i=0;
    while(s[i]!='\0')
    {
        if(s[i]>='a' && s[i]<='z'){
            s[i]=s[i]-32;
        }
        ++i;
    }
}


const char* read_userpool_from_cfg()
{
  char* userpoolCfgFile = NULL;
  struct json_object *parsed_json = NULL, *userpool_json = NULL;
  char* cfgPathEnv = getenv("AWS_USERPOOL_CFG_ENV");
  char *db2_home = getenv( "DB2_HOME" );
  const char* userpoolID = NULL;
  if(cfgPathEnv == NULL)
  {
    cfgPathEnv = AWS_USERPOOL_DEFAULTCFGFILE;
  }
  if(db2_home != NULL)
  {
    userpoolCfgFile = (char*) malloc(sizeof(char) * (strlen(cfgPathEnv) + strlen(db2_home) + 2 ));
    if(userpoolCfgFile != NULL)
    {
      strcpy(userpoolCfgFile, db2_home);
      strcat(userpoolCfgFile, "/");
      strcat(userpoolCfgFile, cfgPathEnv);
      userpoolCfgFile[strlen(userpoolCfgFile)] = '\0';
    }
  }
  if(userpoolCfgFile != NULL)
  {
    parsed_json = json_object_from_file(userpoolCfgFile);
    if (parsed_json == NULL)
    {
      db2Log(DB2SEC_LOG_ERROR, "No userpool configured");
      IAM_TRACE_DATA( "read_userpool_from_cfg", "10");
      goto exit;
    } 

    if(!json_object_object_get_ex(parsed_json, "UserPools", &userpool_json))
    {
      IAM_TRACE_DATA("read_userpool_from_cfg","20");
      goto exit;
    }
    json_object* id = NULL;
    bool found = json_object_object_get_ex(userpool_json, "ID", &id);
    if ( !found )
    {
      goto exit;
    }
    userpoolID = json_object_get_string(id);
    return userpoolID;
  }
  goto exit;

exit:
  if(parsed_json) json_object_put(parsed_json);
  if(userpool_json) json_object_put(userpool_json);
  return userpoolID;
}
