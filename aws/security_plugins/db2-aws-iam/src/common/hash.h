#ifndef _HASH_H_
#define _HASH_H_
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <stdbool.h>
#include "../crypt_blowfish.h"

typedef enum {
  T_SHA1,
  T_SHA256,
  T_BCRYPT
} HASHTYPE;

#define DB2OC_USER_REGISTRY_FILE "/mnt/blumeta0/db2_config/users.json"
#define DB2OC_USER_REGISTRY_ERROR_FILE "/mnt/blumeta0/db2_config/users.json.debug"

void stringToUpper(char *s);

void stringToLower(char *s);

static int getRandomU( unsigned char *buf, size_t nBytes );

// Used for test executable
int generateSHA2HashPasswordTruncate(const char * const pszPassword, char * pszHash, size_t hash_sz);
int generateSSHA256HashPassword(const char * const pszPassword, char * pszHash, size_t hash_sz);
int generateBCRYPTHashPassword(const char * const pszPassword, char * pszHash, size_t hash_sz);


static void getSaltDigest(const char * const currentB64hash, unsigned char *salt, size_t *salt_len, unsigned char *digest, size_t digest_len);

void getHashBuild(const unsigned char * const salt, const size_t salt_length, const char * const password, unsigned char *outputBuffer, const size_t outputBuffer_length, HASHTYPE hashtype);
// static void getHashBuildOld(const unsigned char * const salt, const size_t salt_length, const char * const password, unsigned char *outputBuffer, bool default_hash);

// int generateHashPassword(const char * const pszPassword, char * pszHash, size_t hash_sz);

bool doesPasswordMatch(unsigned char *currenthash, unsigned char *currentpassword);
#endif