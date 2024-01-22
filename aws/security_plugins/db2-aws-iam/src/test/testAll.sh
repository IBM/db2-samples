#!/bin/bash

source ./settings.sh

Cleanup()
{
        ./teardown_cognito.sh
}

#===========================================BUILD TESTS =====================================================================================

# Build all tests if they are not built
if [[ ! -f ./unitTests ]]; then
	export INSTALLED_OPENSSL=$(openssl version | awk '{print $2}' | sed -e 's/[a-z]-*.*//' | awk -F. '{ print $1$2$3 }')
	export INSTALLED_JSON_C=$(yum info installed json-c | grep Version | sed -e 's/Version\s*: //g' | awk -F. '{ print $1$2$3 }')
        make all
fi

#===========================================SETUP TESTS =====================================================================================

echo "============================= SETTING UP AWS COGNITO FOR TESTS ========================================================================"
./setup_cognito_for_tests.sh $1
if [[ $? != 0 ]]; then
	Cleanup
        exit 1
fi
source ./env.sh

#===========================================EXECUTE TESTS ===================================================================================
# Uncomment following targets if you want to run single test

#./jwtTests
#./jwkTests
#./awsTests

echo "============================= RUNNING UNIT TESTS ========================================================================"
./unitTests

echo "============================= RUNNING FULLTEST ========================================================================"
./fullTest $TESTTOKEN

#============================================TEAR DOWN TEST SETUP============================================================================

echo "============================= CLEAN UP AWS COGNITO SETUP DONE FOR TESTS ================================================================"
Cleanup
