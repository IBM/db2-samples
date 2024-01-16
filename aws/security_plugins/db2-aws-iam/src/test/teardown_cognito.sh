#!/bin/bash
set -e
source ./env.sh 
if [[ $USERPOOLID != "" ]]; then
    aws cognito-idp delete-user-pool --user-pool-id "$USERPOOLID"
fi
if [[ -f $AWS_USERPOOL_CFG_ENV ]]; then
    rm -f $AWS_USERPOOL_CFG_ENV
fi
if [[ -f ./env.sh ]]; then
    rm -f ./env.sh
fi

echo "Tearing Down Cognito user pool"
