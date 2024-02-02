/**************************************************************************************************
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
*****************************************************************************************************
**
**  Source File Name = src/test/unit_jwk.cpp          (%W%)
**
**  Descriptive Name = Unit test to verify JWK retrieval and validation
**
**  Function: This file contains unit tests that verfies JWK retrieval and its validation.
**
**  Dependencies:
**
**  Restrictions: Should be run on a system which has either AWS developer credentials configured or 
**                a role with proper permissions attached to it. Refer the README.md at path
**                "db2-samples/aws/security_plugins/db2-aws-iam"
*
******************************************************************************************************/



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
