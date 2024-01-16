#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <stdbool.h>

#include "db2secPlugin.h"
#include "base64.h"
#include "hash.h"
#include "AWSIAMtrace.h"
#include "../crypt_blowfish.h"

#define MAX_SALT_SZ 40
#define OK 0
#define ERROR -1

#define SCHEME_BCRYPT "{BCRYPT}"
#define SCHEME_SSHA "{SSHA}"
#define SCHEME_SHA2 "{SHA2}"
#define SCHEME_SSHA256 "{SSHA256}"
#define SCHEME_SHA1 "{SHA}"

#define BCRYPT_DEFAULT_PREFIX		       "$2b"
#define BCRYPT_DEFAULT_WORKFACTOR       5
#define BCRYPT_OUTPUT_SIZE              61

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

/******************************************************************************
*
*  Function Name     = getRandomU
*
*  Descriptive Name  = Gets random unsigned bytes
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR - bad
*
*******************************************************************************/
static int getRandomU( unsigned char *buf, size_t nBytes )
{
   int rc = DB2SEC_PLUGIN_OK, fd, n=0;

    IAM_TRACE_ENTRY("getRandomU");


   if( nBytes == 0 ) 
   {
      IAM_TRACE_DATA("getRandomU", "NO_BYTES_REQUESTED");
      rc = DB2SEC_PLUGIN_OK;
      goto exit;
   }


   fd = open( "/dev/urandom", O_RDONLY );

   if( fd < 0 )
   { 
      IAM_TRACE_DATA("getRandomU", "NO_RANDOM_DEVICE");
      rc = -1;
      goto exit;
   }

   do {
      rc = read( fd, buf, nBytes );
      if( rc <= 0 ) 
         break;

      buf+=rc;
      nBytes-=rc;

      if( ++n >= 4 ) 
         break;
   } while( nBytes > 0 );

   close(fd);
exit:   
   rc = nBytes > 0 ? DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR : DB2SEC_PLUGIN_OK;
   IAM_TRACE_EXIT("getRandomU", rc);

   return rc;
}

/******************************************************************************
*
*  Function Name     = generateSSHA256HashPasswordInternal
*
*  Descriptive Name  = Internal function which allows for creation with truncation
*                      This exists because at some point we shiped SHA256 but
*                      with a short digest (SHA_DIGEST_LENGTH) and called this 
*                      SHA2. This function takes arguments to get the approriate hash
*
*   Step 1: Generate Random salt
*   Step 2: Generate the hash with the salt
*   Step 3: Combine the salt and the digest
*   Step 4: base64 encode it
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = 
*
*******************************************************************************/
static int generateSSHA256HashPasswordInternal(const char * const pszPassword, char * pszHash, size_t hash_sz, size_t truncation_size, const char * const scheme)
{
    unsigned char hash[SHA256_DIGEST_LENGTH] = {0};
    unsigned char salt[20] = {0};
    unsigned char hash_combined[SHA256_DIGEST_LENGTH+MAX_SALT_SZ+1] = {0};
    int rc = DB2SEC_PLUGIN_OK;

    IAM_TRACE_ENTRY("generateSSHA256HashPasswordInternal");


    if(pszHash == NULL || hash_sz < sizeof(hash_combined))
    {
       IAM_TRACE_DATA("generateSSHA256HashPasswordInternal", "FAILED_TO_GET_RANDOM");
       rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
       goto exit;
    }

    // Step 1: Shake the salt
    rc = getRandomU( salt, sizeof(salt) );
    if(rc != DB2SEC_PLUGIN_OK)
    {
       IAM_TRACE_DATA("generateSSHA256HashPasswordInternal", "FAILED_TO_GET_RANDOM");
       goto exit;
    }

    // Step 2: Generate the hash with the password and salt
    strncpy(pszHash,scheme, hash_sz);

    getHashBuild(salt, sizeof(salt), pszPassword, hash, sizeof(hash), T_SHA256);
    
    // Step 3: Suffix the salt onto the hash
    // Due to a past bug, we unfortunately need to reduce the size of the DIGEST from 32 to 20 because
    // this is how it was done it seems in LDAP and 
    memcpy(hash_combined, hash, truncation_size);
    memcpy(&(hash_combined[truncation_size]), salt, sizeof(salt) );

    // Step 4: Encode the hashsalt
    if(-1 == openLDAP_b64_encode(hash_combined, sizeof(salt)+truncation_size, &(pszHash[strlen(pszHash)]), hash_sz - strlen(pszHash)))
    {
       pszHash[0]='\0'; 
       IAM_TRACE_DATA("generateSSHA256HashPasswordInternal", "ENCODE_FAILED");
       rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
       goto exit;
    }

exit:

    if(rc != DB2SEC_PLUGIN_OK && pszHash != NULL)
    {
       pszHash[0]='\0'; 
    }
    
    IAM_TRACE_EXIT("generateSSHA256HashPasswordInternal",rc);
   
    return rc;
}



/******************************************************************************
*
*  Function Name     = generateSHA2HashPasswordTruncate
*
*  Descriptive Name  = Generates a based64 dencoded hash of a password and 
*                      random salt.
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = return from generateSSHA256HashPasswordInternal
*
*******************************************************************************/
int generateSHA2HashPasswordTruncate(const char * const pszPassword, char * pszHash, size_t hash_sz)
{
    int rc = DB2SEC_PLUGIN_OK;
    IAM_TRACE_ENTRY("generateSSHAHashPasswordTruncate");
        
    rc = generateSSHA256HashPasswordInternal(pszPassword,pszHash, hash_sz, SHA_DIGEST_LENGTH, SCHEME_SHA2);    
    IAM_TRACE_EXIT("generateSSHAHashPasswordTruncate",rc);

    return rc;

}

/******************************************************************************
*
*  Function Name     = generateSSHA256HashPassword
*
*  Descriptive Name  = Generates a based64 dencoded hash of a password and 
*                      random salt.
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = return generateSSHA256HashPasswordInternal
*
*******************************************************************************/
int generateSSHA256HashPassword(const char * const pszPassword, char * pszHash, size_t hash_sz)
{
    int rc = DB2SEC_PLUGIN_OK;

    IAM_TRACE_ENTRY("generateSSHA256HashPassword");   
    rc = generateSSHA256HashPasswordInternal(pszPassword,pszHash, hash_sz, SHA256_DIGEST_LENGTH, SCHEME_SSHA256);    
    IAM_TRACE_EXIT("generateSSHA256HashPassword",rc);

    return rc;

}


/******************************************************************************
*
*  Function Name     = generateBCRYPTHashPassword
*
*  Descriptive Name  = Generates a bcrypt hash of a password with salt.
*
*   Step 1: Generate Random set
*   Step 2: Generate salt
*   Step 3: Generate the salted hash
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = Error return code - on error it is also sets return to empty
*                      string
*
*******************************************************************************/
int generateBCRYPTHashPassword(const char * const pszPassword, char * pszHash, size_t hash_sz)
{
    unsigned char hash[BCRYPT_OUTPUT_SIZE] = {0};
    unsigned char salt[20] = {0};
    char settings[BCRYPT_OUTPUT_SIZE] = {0};

    int rc = DB2SEC_PLUGIN_OK;

    IAM_TRACE_ENTRY("generateBCRYPTHashPassword");

    if(pszHash == NULL || hash_sz < (sizeof (hash)+sizeof(SCHEME_BCRYPT)))
    {
       IAM_TRACE_DATA("generateBCRYPTHashPassword", "FAILED_TO_GET_RANDOM");
       rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
       goto exit;
    }


    // Step 1: Grab the salt shaker
    rc = getRandomU( salt, sizeof(salt) );
    if(rc != DB2SEC_PLUGIN_OK)
    {
       IAM_TRACE_DATA("generateBCRYPTHashPassword", "FAILED_TO_GET_RANDOM");
       goto exit;
    }

    // Step 2: Shake the salt
    if (_crypt_gensalt_blowfish_rn(BCRYPT_DEFAULT_PREFIX,
                                   BCRYPT_DEFAULT_WORKFACTOR,
                                   salt,
                                   sizeof(salt),
                                   settings,
                                   sizeof(settings)) == NULL) {
       rc = DB2SEC_PLUGIN_UNEXPECTED_SYSTEM_ERROR;
       IAM_TRACE_DATA("generateBCRYPTHashPassword", "FAILED_TO_GET_BCRYPT_SALT");
       goto exit;
    }


    // Step 3: Get the salted hash
    
    // prefix with hash type
    strncpy(pszHash,SCHEME_BCRYPT,hash_sz);

    getHashBuild(settings, sizeof(settings), pszPassword, hash, sizeof(hash), T_BCRYPT);


    // Step 3: Suffix the hash onto the type
    memcpy(&(pszHash[sizeof(SCHEME_BCRYPT) -1]), hash, sizeof(hash));
    
exit:

    if(rc != DB2SEC_PLUGIN_OK)
    {
       pszHash[0]='\0'; 
    }
    
    IAM_TRACE_EXIT("generateBCRYPTHashPassword",rc);
   
    return rc;
}

/******************************************************************************
*
*  Function Name     = getSaltDigest
*
*  Descriptive Name  = Checks if passwords match
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = TRUE - yes, FALSE - no
*
*******************************************************************************/
static void getSaltDigest(const char * const currentB64hash, unsigned char *salt, size_t *salt_len, unsigned char *digest, size_t digest_len)
{
    int decode_buf_len = 0;
    unsigned char decode_buf[MAX_SALT_SZ+digest_len+1];
    IAM_TRACE_ENTRY("getSaltDigest");
    size_t pos=0;

    //{SSHA} and {SHA2}
    if ((currentB64hash[0] == '{') && (currentB64hash[5] == '}')) 
    { 
       pos= 6;
    }   //{SSHA256}
    else if ((currentB64hash[0] == '{') && (currentB64hash[8] == '}')) 
    {
       pos=9;
    }

    decode_buf_len = openLDAP_b64_decode(
                                       &(currentB64hash[pos]),
                                       decode_buf, 
                                       sizeof(decode_buf));
    
    memcpy(digest, decode_buf, digest_len);
    *salt_len = decode_buf_len - digest_len;
    memcpy(salt, &(decode_buf[digest_len]), *salt_len);
    
    IAM_TRACE_EXIT("getSaltDigest", 0);
} 

/******************************************************************************
*
*  Function Name     = getHashBuild
*
*  Descriptive Name  = 
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = TRUE - yes, FALSE - no
*
*******************************************************************************/
void getHashBuild(const unsigned char * const salt, const size_t salt_length, const char * const password, unsigned char *outputBuffer, const size_t outputBuffer_length, HASHTYPE hashtype)
{
    SHA_CTX sha1;
    SHA256_CTX sha2;
    IAM_TRACE_ENTRY("getHashBuild");

    char passwordn[strlen(password)+1];
    strcpy(passwordn,password);
    
    if (passwordn[strlen(password)] == '\n') {
       passwordn[strcspn(passwordn,"\n")] = '\0';
    } else if (passwordn[strlen(password)] == ';') {
         passwordn[strcspn(passwordn,";")] = '\0';
    }
    if(hashtype==T_SHA256) 
    {
      IAM_TRACE_DATA("getHashBuild","defaultHashBuild");

      SHA256_Init(&sha2);
      SHA256_Update(&sha2, passwordn, strlen(passwordn));
      SHA256_Update(&sha2, salt, salt_length);
      SHA256_Final(outputBuffer, &sha2);
    } 
    else if(hashtype==T_SHA1) 
    {
      IAM_TRACE_DATA("getHashBuild","oldHashBuild");
      SHA1_Init(&sha1);
      SHA1_Update(&sha1, passwordn, strlen(passwordn));
      SHA1_Update(&sha1, salt, salt_length);
      SHA1_Final(outputBuffer, &sha1);
    } 
    else if(hashtype==T_BCRYPT)
    {
      IAM_TRACE_DATA("getHashBuild","bcryptHashBuild");
      if (_crypt_blowfish_rn( passwordn,
                              salt,
                              outputBuffer,
                              outputBuffer_length) == NULL) 
      {
        outputBuffer[0]='\0'; 

        IAM_TRACE_DATA("generateBCRYPTHashPassword", "FAILED_TO_GET_BCRYPT_SALT");
      }
    }

    IAM_TRACE_EXIT("getHashBuild",0);
}

/******************************************************************************
*
*  Function Name     = doesPasswordMatch
*
*  Descriptive Name  = Checks if passwords match
*
*  Normal Return     = DB2SEC_PLUGIN_OK
*
*  Error Return      = TRUE - yes, FALSE - no
*
*******************************************************************************/
bool doesPasswordMatch(unsigned char *currenthash, unsigned char *currentpassword) 
{
   bool bRc = false;
   HASHTYPE hash_type = T_SHA256;

   IAM_TRACE_ENTRY("doesPasswordMatch");
   if(strncmp(currenthash,SCHEME_BCRYPT, sizeof(SCHEME_BCRYPT)-1) == 0)
   {
      static unsigned char bcrypt_hash[BCRYPT_OUTPUT_SIZE] = {0};

      if(strlen(currentpassword) > sizeof(bcrypt_hash))
      {
         IAM_TRACE_DATA("doesPasswordMatch", "PASSWORD_TOO_LONG");
         bRc=false;
      }
      else
      { 
         // Chop of the SCHEME_BCRYPT from the beginning
         unsigned char * pszHash = &currenthash[sizeof(SCHEME_BCRYPT)-1];

         if (_crypt_blowfish_rn( currentpassword,
                                 pszHash,
                                 bcrypt_hash,
                                 sizeof(bcrypt_hash)) != NULL) 
         {
            if (!memcmp(bcrypt_hash, pszHash, sizeof(bcrypt_hash)))
            {
               bRc = true;
            }
            else
            {
               IAM_TRACE_DATA("doesPasswordMatch", "PASSWORD_NOT_MATCH");
               bRc = false;
            }
         }
         else
         {
            IAM_TRACE_DATA("doesPasswordMatch", "HASH_IS_NULL");
            bRc = false;
         }
      }
   } // Salted SHA256 (Old Scheme - truncated) {SHA2}
   else if (strncmp(currenthash,SCHEME_SHA2, sizeof(SCHEME_SHA2)-1) == 0 )
   {
      static unsigned char salt[MAX_SALT_SZ]=""; 
      static unsigned char digest[SHA_DIGEST_LENGTH]="";
      static unsigned char build_hash[SHA_DIGEST_LENGTH]="";
      size_t salt_len = 0;

      getSaltDigest(currenthash, salt, &salt_len, digest,SHA_DIGEST_LENGTH);

      getHashBuild(salt, salt_len, currentpassword, build_hash, sizeof(build_hash), T_SHA256);

      // SSH_DIGEST_LENGTH is the right number of challenge bytes for what is used by LDAP
      // instead of SHA256_DIGEST_LENGTH
      if (!memcmp(build_hash, digest, SHA_DIGEST_LENGTH))
      {
         bRc = true;
      }
   } // Salted SHA1 {SSHA}
   else if (strncmp(currenthash,SCHEME_SSHA, sizeof(SCHEME_SSHA)-1) == 0)
   {
      static unsigned char salt[MAX_SALT_SZ]=""; 
      static unsigned char digest[SHA_DIGEST_LENGTH]="";
      static unsigned char build_hash[SHA_DIGEST_LENGTH]="";
      size_t salt_len = 0;

      getSaltDigest(currenthash, salt, &salt_len, digest,SHA_DIGEST_LENGTH);

      //check the beginning of the hash for SHA2 if not use the old hash algo
      getHashBuild(salt, salt_len, currentpassword, build_hash, sizeof(build_hash), T_SHA1);

      if (!memcmp(build_hash, digest, SHA_DIGEST_LENGTH))
      {
         bRc = true;
      }
   } //SHA1 - NOT SALTED
   else if (strncmp(currenthash,SCHEME_SHA1, sizeof(SCHEME_SHA1)-1) == 0)
   {
      static unsigned char salt[MAX_SALT_SZ]=""; 
      static unsigned char digest[SHA_DIGEST_LENGTH]="";
      static unsigned char build_hash[SHA_DIGEST_LENGTH]="";
      size_t salt_len = 0;

      //check the beginning of the hash for SHA2 if not use the old hash algo
      getHashBuild(salt, salt_len, currentpassword, build_hash, sizeof(build_hash), T_SHA1);

      if (!memcmp(build_hash, digest, SHA_DIGEST_LENGTH))
      {
         bRc = true;
      }
   } // Salted SHA256
   else if (strncmp(currenthash,SCHEME_SSHA256, sizeof(SCHEME_SSHA256)-1) == 0)
   {
      static unsigned char salt[MAX_SALT_SZ]=""; 
      static unsigned char digest[SHA256_DIGEST_LENGTH]="";
      static unsigned char build_hash[SHA256_DIGEST_LENGTH]="";
      size_t salt_len = 0;

      getSaltDigest(currenthash, salt, &salt_len, digest, SHA256_DIGEST_LENGTH);
      getHashBuild(salt, salt_len, currentpassword, build_hash, sizeof(build_hash), T_SHA256);

      if (!memcmp(build_hash, digest, SHA256_DIGEST_LENGTH))
      {
         bRc = true;
      }
   }
   else
   {
      IAM_TRACE_DATA("doesPasswordMatch", "NO_ALGORITHM_DETECTED");
   }

exit:

   IAM_TRACE_EXIT("doesPasswordMatch",bRc);
   return bRc; 

}
