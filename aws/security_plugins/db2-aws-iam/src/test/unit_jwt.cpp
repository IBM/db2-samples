/********************************************************************************************
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
**********************************************************************************************
**
**  Source File Name = src/test/unit_jwt.cpp          (%W%)
**
**  Descriptive Name = Unit test to verify JWT validation
**
**  Function: This file contains unit tests that verifies the JWT token - its signature, header
**           and all the claims.
**
**  Dependencies:
**
**  Restrictions: Should be run on a system which has either AWS developer credentials configured or 
**                a role with proper permissions attached to it. Refer the README.md at path
**                "db2-samples/aws/security_plugins/db2-aws-iam"
**
*********************************************************************************************/

#include <cstring>
#include <assert.h>
#include <iostream>
#include "catch.hpp"
extern "C" {
#include "iam.h"
#include "jwt.h"
#include "base64.h"
}

#define AWS_COGNITO_ISSUER "https://cognito-idp.%s.amazonaws.com/%s"
#define MAX_STR_LEN 8192

TEST_CASE("JWT is verified", "[jwt]") {
	char* userPoolIDOfUser = NULL;
	char* iss = NULL;
	char* tokenInUse = NULL;
	char* exp = NULL;
	json_object* jwt_obj = NULL;

	char* jwt = getenv("TESTTOKEN");
	SECTION("case 1: JSON_obj") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		REQUIRE(ret == 0);
		REQUIRE(jwt_obj != NULL);
	}

	SECTION("case 2: TokenType") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		size_t tokenInUseLen = get_string_element_from_jwt(jwt_obj, "token_use", &tokenInUse, 32);
		REQUIRE(tokenInUse != NULL);
		REQUIRE(strcmp(tokenInUse, "id") == 0);
	}

	SECTION("case 3: Issuer") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		size_t issLen = get_string_element_from_jwt(jwt_obj, "iss", &iss, DB2SEC_MAX_USERID_LENGTH);
		REQUIRE(issLen != 0);
		REQUIRE(iss != NULL);
		char expectedISS[200];
		assert(getenv("USERPOOLID") != NULL);
		sprintf( expectedISS, AWS_COGNITO_ISSUER, getenv("REGION"), getenv("USERPOOLID"));
		REQUIRE(strcmp(iss, expectedISS) == 0);
	}

	SECTION("case 4: UserPoolID") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		size_t issLen = get_string_element_from_jwt(jwt_obj, "iss", &iss, DB2SEC_MAX_USERID_LENGTH);
		REQUIRE(issLen != 0);
		REQUIRE(iss != NULL);
		size_t rc = validate_user_poolID(iss, &userPoolIDOfUser);
		REQUIRE(rc == 0);
		REQUIRE(strcmp(getenv("USERPOOLID"), userPoolIDOfUser) == 0);
	}

	SECTION("case 5: Signature") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		size_t issLen = get_string_element_from_jwt(jwt_obj, "iss", &iss, DB2SEC_MAX_USERID_LENGTH);
		REQUIRE(issLen != 0);
		REQUIRE(iss != NULL);
		ret = verify_jwt_header_and_signature(jwt, strlen(jwt), iss, NULL);
		REQUIRE(ret == 0);
	}

	SECTION("case 6: Expiry") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		REQUIRE(ret == 0);
		OM_uint32 minorStatus = 0;
		ret = validate_access_token_expiry(jwt_obj, &minorStatus, NULL);
		REQUIRE(ret == 0);
	}

	SECTION("case 7: ClientID") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		REQUIRE(ret == 0);
		size_t issLen = get_string_element_from_jwt(jwt_obj, "iss", &iss, DB2SEC_MAX_USERID_LENGTH);
		REQUIRE(issLen != 0);
		OM_uint32 minorStatus = 0;
		size_t rc = validate_user_poolID(iss, &userPoolIDOfUser);
		REQUIRE(rc == 0);
		ret = validate_access_token_clientID(jwt_obj, "aud", userPoolIDOfUser, &minorStatus, NULL);
		REQUIRE(ret == 0);
	}

	SECTION("case 8: Username") {
		OM_uint32 ret = get_json_object_from_jwt(jwt, strlen(jwt), &jwt_obj, NULL);
		REQUIRE(ret == 0);
		char* authID = NULL;
		db2int32 authIDLen = 0;
		authIDLen = get_string_element_from_jwt(jwt_obj, "cognito:username", &authID, DB2SEC_MAX_USERID_LENGTH);
		REQUIRE(strcmp(authID, getenv("USERNAME_GENERATED")) == 0);
	}

	if (jwt_obj != NULL)
	{
		json_object_put(jwt_obj);
	}
}
