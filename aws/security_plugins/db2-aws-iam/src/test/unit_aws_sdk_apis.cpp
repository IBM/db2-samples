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
*  Source File Name = src/test/unit_aws_sdk_apis.cpp          (%W%)
*
*  Descriptive Name = Unit test to verify AWS API calls
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***********************************************************************/

#include "catch.hpp"
#include "utils.h"
#include "AWSUserPoolInfo.h"
#include "AWSUserGroupInfo.h"
#include <cstdio>
#include <assert.h>

TEST_CASE("AWS Group Fetch API", "[User Groups]") {
	AWS_USER_GROUPS_T* awsusergroups = NULL;
	size_t rc = FetchAWSUserGroups(getenv("USERNAME_GENERATED"), getenv("USERPOOLID"), &awsusergroups);
	REQUIRE(rc == 0);
	REQUIRE(awsusergroups->groupCount == 2 );
}

TEST_CASE("AWS Group Check API", "[Group Check]") {
	const char* userPoolID = read_userpool_from_cfg();
	int rc = DoesAWSGroupExist("BLUUSERS", userPoolID);
	REQUIRE(rc == 0);
}

TEST_CASE("AWS ListClients API", "[List Clients]") {
	const char* userPoolID = read_userpool_from_cfg();
	OM_uint32 ret = 0;
	size_t count = 0;
	char** clients = ListClientsForUserPool(userPoolID, &ret, &count, NULL );
	assert(ret == 0);
}

TEST_CASE("AWS User Check API", "[User Check]") {
	const char* userPoolID = read_userpool_from_cfg();
	int rc = DoesAWSUserExist(getenv("USERNAME_GENERATED"), userPoolID);
	REQUIRE(rc == 0);

}

