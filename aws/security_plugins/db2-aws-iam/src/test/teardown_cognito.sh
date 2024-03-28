#!/bin/bash
set -e

if [[ -f ./env.sh ]]; then
	source ./env.sh 
	if [[ $USERPOOLID != "" ]]; then
    		aws cognito-idp delete-user-pool --user-pool-id "$USERPOOLID"
	fi
	if [[ -f $AWS_USERPOOL_CFG_ENV ]]; then
    		rm -f $DB2_HOME$AWS_USERPOOL_CFG_ENV
	fi
    	rm -f ./env.sh
fi

echo "Tearing Down Cognito user pool"
