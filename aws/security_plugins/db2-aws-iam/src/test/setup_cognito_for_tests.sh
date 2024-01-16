#!/bin/bash

set -e

#Script to create Cognito User pool, add groups in the user pool, create users and make them part of the groups.
source ./settings.sh

USERPOOLID=""
CLIENTID=""

Delete_Pool()
{
	if [[ ! -z $USERPOOLID ]]; then
		echo "Deleting User Pool"
		aws cognito-idp delete-user-pool --user-pool-id "$USERPOOLID"
	fi
}

Run_Command()
{
	command=$1
	case $command in
		CREATE_USERPOOL)
			command_to_execute="aws cognito-idp create-user-pool --pool-name "UnitTestPool1" --username-attributes="email""
			;;
		CREATE_CLIENT)
			command_to_execute="aws cognito-idp create-user-pool-client --user-pool-id "$USERPOOLID" --client-name "UnitTestClient" --explicit-auth-flows "ALLOW_ADMIN_USER_PASSWORD_AUTH" "ALLOW_REFRESH_TOKEN_AUTH" "ALLOW_USER_PASSWORD_AUTH" "ALLOW_USER_SRP_AUTH" --callback-urls "https://google.com" --supported-identity-providers "COGNITO" --allowed-o-auth-flows "implicit" --allowed-o-auth-scopes "openid" "email" "phone" --logout-urls "https://google.com""
			;;
		CREATE_USER)
			command_to_execute="aws cognito-idp admin-create-user --user-pool-id $USERPOOLID --username $USERNAME"
			;;
		SET_USERPASSWORD)
			command_to_execute="aws cognito-idp admin-set-user-password   --user-pool-id "$USERPOOLID" --username $USERNAME   --password "$PASSWD"   --permanent"
			;;
		CREATE_GROUPS)
			cmd1="aws cognito-idp create-group --group-name $GROUP1 --user-pool-id $USERPOOLID"
			cmd2="aws cognito-idp create-group --group-name $GROUP2 --user-pool-id $USERPOOLID"
			command_to_execute="eval $cmd1 && $cmd2"
			;;
		ADDUSER_TO_GROUPS)
			cmd1="aws cognito-idp admin-add-user-to-group --group-name "$GROUP1" --user-pool-id "$USERPOOLID" --username $USERNAME"
			cmd2="aws cognito-idp admin-add-user-to-group --group-name "$GROUP2" --user-pool-id "$USERPOOLID" --username $USERNAME"
			command_to_execute="eval $cmd1 && $cmd2"
			;;
		*)
			echo "Unknown command"
			exit 1
		esac

	command_output=$($command_to_execute 2>&1)
	command_exit_code=$?
	if  [[ "$command_exit_code" -ne 0 ]]; then
		echo "Error executing command, terminating setup"
	        Delete_Pool
	        exit 1
	else
		echo "$command_output"
	fi
}


Setup_Cognito()
{
	PASSWD=$1

	RESULT=$(Run_Command "CREATE_USERPOOL")
	USERPOOLID=$(echo "$RESULT" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["UserPool"]["Id"])')
	echo "Created User pool"

	RESULT=$(Run_Command "CREATE_CLIENT")
	CLIENTID=$(echo "$RESULT" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["UserPoolClient"]["ClientId"])')
	echo "Created client"

	RESULT=$(Run_Command "CREATE_USER")
	USERNAME_GENERATED=$(echo "$RESULT" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["User"]["Username"])')
	echo "Created user"

	RESULT=$(Run_Command "SET_USERPASSWORD")
	echo "Set Password for user"

	RESULT=$(Run_Command "CREATE_GROUPS")
	echo "Created Groups"

	RESULT=$(Run_Command "ADDUSER_TO_GROUPS")

	echo "export USERPOOLID=\"$USERPOOLID\"" > env.sh
	echo "export CLIENTID=\"$CLIENTID\"" >> env.sh
	echo "export USERNAME_GENERATED=\"$USERNAME_GENERATED\"" >> env.sh

	touch $AWS_USERPOOL_CFG_ENV
	json_data="{ \"UserPools\" : { \"ID\" : \"$USERPOOLID\", \"Name\": \"UnitTestPool1\" } }"
	echo $json_data > $AWS_USERPOOL_CFG_ENV


	#Now generate the token for the user
	./retrieve_token.sh $1
	if [[ $? -eq 0 ]]; then
		echo "Retrieved the token for the user"
	else
			echo "Error while retrieving the token for the user, terminating setup"
			Delete_Pool
			exit 1
	fi
}

USERPASSWD=$1
Setup_Cognito $1

