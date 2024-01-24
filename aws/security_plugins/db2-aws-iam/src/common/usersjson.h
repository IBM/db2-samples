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

