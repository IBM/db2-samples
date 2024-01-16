/**********************************************************************
*
*  IBM CONFIDENTIAL
*  OCO SOURCE MATERIALS
*
*  COPYRIGHT:  P#2 P#1
*              (C) COPYRIGHT IBM CORPORATION 2023
*
*  The source code for this program is not published or otherwise divested of
*  its trade secrets, irrespective of what has been deposited with the U.S.
*  Copyright Office.
*
*  Source File Name = src/test/unit_jwk.cpp          (%W%)
*
*  Descriptive Name = Unit test to verify JWK retrieval and validation
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***********************************************************************/



//#define CATCH_CONFIG_MAIN
#include "catch.hpp"
extern "C" {
#include "jwk.h"
}
#include <cstdio>
#include <cstring>
#include <cassert>
#include <iostream>
#define AWS_COGNITO_ISSUER "https://cognito-idp.%s.amazonaws.com/%s"
#define MAX_STR_LEN 8192

TEST_CASE("Connected to IAM server", "[curl_iam]") {
	char *jwks_json = NULL;
	char keysURL[256];
	char iss[128];
	assert(getenv("USERPOOLID") != NULL);
	sprintf( iss, AWS_COGNITO_ISSUER, getenv("REGION"), getenv("USERPOOLID"));
	sprintf( keysURL, "%s/.well-known/jwks.json", iss);
	int ret = query_jwks(keysURL, &jwks_json, NULL);
	REQUIRE(ret == 0);
	REQUIRE(jwks_json != NULL);
	free(jwks_json);
}

TEST_CASE("JWK retrieved", "[jwk]") {
	char* jwt = getenv("TESTTOKEN");
	assert(jwt != NULL);

	char iss[200];
	assert(getenv("USERPOOLID") != NULL);
	sprintf( iss, AWS_COGNITO_ISSUER, getenv("REGION"), getenv("USERPOOLID"));
	json_object *jwk = NULL;
	get_jwk(jwt, strnlen(jwt, MAX_STR_LEN), iss, &jwk, NULL); 

	REQUIRE(jwk != NULL);

	json_object *exp = NULL;
	json_object *mod = NULL;

	json_bool keyExists = json_object_object_get_ex(jwk, "e", &exp);
	REQUIRE(keyExists == TRUE );

	keyExists = json_object_object_get_ex(jwk, "n", &mod);
	REQUIRE(keyExists == TRUE );

	REQUIRE(exp != NULL);
	REQUIRE(mod != NULL);

	json_object_put(jwk); 
}
