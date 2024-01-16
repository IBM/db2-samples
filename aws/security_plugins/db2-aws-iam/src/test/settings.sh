USERNAME="testAWS@test.com"
GROUP1="BLUUSERS"
GROUP2="DB2IADM1"
export DB2_HOME=$(pwd)
export AWS_USERPOOL_CFG_ENV="test_cognito_userpools.json"
export REGION=$(aws configure  get  region)
