set -e

source ./settings.sh
source ./env.sh
PASSWD=$1
if [[ $# != 1 ]]; then
     echo "Please run the script with required arguments"
     echo "retrieve_token.sh <password>"
     exit 1
fi

TESTTOKEN=$(aws cognito-idp admin-initiate-auth --user-pool-id $USERPOOLID --client-id $CLIENTID --auth-flow ADMIN_NO_SRP_AUTH --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWD | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["AuthenticationResult"]["IdToken"])')

echo "export TESTTOKEN=\"$TESTTOKEN\"" >> env.sh

