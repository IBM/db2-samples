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
**  Source File Name = src/test/unit_aws_sdk_apis.cpp          (%W%)
**
**  Descriptive Name = Unit test to verify AWS API calls
**
**  Function: This file contains code that tests the AWS API calls that are made in the plugin code.
**
**  Dependencies:
**
**  Restrictions: Should be run on a system which has either AWS developer credentials configured or 
**                a role with proper permissions attached to it. Refer the README.md at path
**                "db2-samples/aws/security_plugins/db2-aws-iam"
**
*****************************************************************************************************/

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

