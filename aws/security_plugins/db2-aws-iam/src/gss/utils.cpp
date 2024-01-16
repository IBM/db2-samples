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
*  Source File Name = src/gss/utils.cpp           (%W%)
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
#include <cstring>
#include <stdio.h>
#include "db2secPlugin.h"
#include <json-c/json.h>
#include "../common/AWSIAMtrace.h"
#include "utils.h"
#include "AWSIAMauth.h"


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
