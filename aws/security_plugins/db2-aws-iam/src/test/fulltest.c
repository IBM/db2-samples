#include <stdio.h>
#include "../common/base64.h"
#include "iam.h"
#include "jwt.h"
#include "AWSIAMauthfile.h"
#include "AWSIAMauth.h"
#include "AWSIAMtrace.h"
#include "../common/hash.h"
#include "../common/AWSIAMtrace.h"

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

int main(int argc, char* argv[])
{
  OM_uint32 rc = GSS_S_COMPLETE;
  int ret = 0;
  OM_uint32 minor_status = 0;
  int authmode = DB2SEC_AUTH_MODE_IAM; 
  int authtype = DB2SEC_AUTH_ACCESS_TOKEN;
  char *authtoken = argv[1];
  int authtokenLen = strlen(authtoken);

  char* userInToken = NULL;
  db2int32 authidLen = 0;
  char useridtocheck[DB2SEC_MAX_USERID_LENGTH+1]="";
  db2int32 useridtocheckLen =0 ;

  char szIPAddress[IP_BUFFER_SIZE]="127.0.0.1";  
  IAM_TRACE_ENTRY("validate_auth_info");
  db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: %s", authTypeToString[authtype]);
  // Perform authentication
  if (authtype == DB2SEC_AUTH_ACCESS_TOKEN)
  {
    // Check to see if the username is passed in with the token and if it is remove it from the token to validate it and
    // use the userid for the lookup later.  The userid will be specified in the form userid:apikey or userid:accesstoken
    char * id_delim = NULL;
    id_delim = (char*)memchr ((char*)authtoken,  ':', authtokenLen); 
    
    if (id_delim != NULL) 
    {
       useridtocheckLen = id_delim - authtoken;
       if( useridtocheckLen > DB2SEC_MAX_USERID_LENGTH )
       {
          db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Userid from %s is longer than %d", szIPAddress, DB2SEC_MAX_USERID_LENGTH );
          minor_status = RETCODE_BADTOKEN;
          rc = GSS_S_DEFECTIVE_CREDENTIAL;
          goto finish;
       }

       // this is the userid to validate against
       memcpy(useridtocheck, authtoken, useridtocheckLen);

       useridtocheck[useridtocheckLen] = '\0';
       stringToLower(useridtocheck);
       
       authtoken = id_delim+1; 
       
       // subtract useridlen and the ":" from the length of the remaining token       
       authtokenLen = authtokenLen - (useridtocheckLen +1);
    }
    ret = verify_access_token(authtoken, authtokenLen, &userInToken, &authidLen, authtype, szIPAddress, &minor_status, logFunc);
    if( authidLen == 0 )
    {
      db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Fail to get the username from access token from %s", szIPAddress );
      rc = ret;
      goto finish;
    }
    db2Log( DB2SEC_LOG_INFO, "Username %s is found in Token", userInToken);
  }
  else
  {
    db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Invalid auth type (%d) from %s", authtype, szIPAddress );
    minor_status = RETCODE_BADPASS;
    rc = GSS_S_DEFECTIVE_CREDENTIAL;
    goto finish;
  }

  if( rc == RETCODE_OK ) {
    goto success;
  } 
  else if ( rc != RETCODE_OK ) 
  {
    db2Log( DB2SEC_LOG_ERROR, "validate_auth_info: Fail to authorize user from %s with auth type (%s)", szIPAddress, authTypeToString[authtype] );
    goto finish;
  }

success:
  db2Log( DB2SEC_LOG_INFO, "validate_auth_info: Successfully authenticated and authorized userid (%.*s) from %s with auth type (%s)", authidLen, userInToken, szIPAddress, authTypeToString[authtype] );
  
finish: 
  IAM_TRACE_EXIT("validate_auth_info",rc);
  if( userInToken != NULL ) free( userInToken );
}
