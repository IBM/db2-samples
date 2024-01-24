#include <stdio.h>
#include <stdlib.h>
#include "usersjson.h"
#include "../gss/utils.h"

/*******************************************************************************
*
*  Function Name     = DumpUsersJson
*
*  Function          = 
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = fileDestination - path to file
*                      logFunc         - function used for logging errors
*
*  Output            = Writes to a file with the current users.json content
*
*******************************************************************************/
void DumpUsersJson(const char* fileDestination, db2secLogMessage* logFunc)
{
  IAM_TRACE_ENTRY("DumpUsersJson");
  
  char dumpMsg[128] = "";
  int rc = DB2SEC_PLUGIN_OK;
  FILE* f = fopen(fileDestination, "r");
  if(!f) {
    rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
    goto exit;
  }

  fseek(f, 0L, SEEK_END);
  size_t fileSize = ftell(f);
  char* message = (char*) malloc(fileSize + 1);
  rewind(f);

  if(message == NULL) {
    rc = DB2SEC_PLUGIN_NOMEM;
    goto exit;
  }

  if(fread(message, fileSize, 1, f) != 1) {
    rc =  DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
    goto exit;
  }

  FILE* d = fopen(DB2OC_USER_REGISTRY_ERROR_FILE, "w");
  if(!d){
    rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
    goto exit;
  }

  if(fprintf(d, message) < 0){
    rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
    goto exit;
  }

exit:
  if(f){
    fclose(f);
  }

  if(message != NULL){
    free(message);
  }

  if(d){
    fclose(d);
  }

  if(rc != DB2SEC_PLUGIN_OK){
    char dumpMsg[32];
    snprintf(dumpMsg, sizeof(dumpMsg), "Unable to dump users.json!");
    logFunc(DB2SEC_LOG_ERROR, dumpMsg, strlen(dumpMsg));
  }
  IAM_TRACE_EXIT("DumpUsersJson", rc);
}

/*******************************************************************************
*
*  Function Name     = UsersJsonErrorMsg
*
*  Function          = 
*  Dependencies      = None
*
*  Restrictions      = None
*
*  Input             = fnName             - Name of error function
*                      errorMessage       - Message that will be sent to db2diag
*                      errorMessageLength - Length of the error message
*
*  Output            = None
*
*******************************************************************************/
void UsersJsonErrorMsg(const char* fnName, char** errorMessage, db2int32* errorMessageLength, const char* lstError) {
    char dumpMsg[1024] ="";
    snprintf(dumpMsg, sizeof(dumpMsg), "%s - unable to parse registry file %s: %s.", fnName, DB2OC_USER_REGISTRY_FILE, lstError);
    *errorMessage = strdup(dumpMsg);
    *errorMessageLength = strlen(*errorMessage);
}
