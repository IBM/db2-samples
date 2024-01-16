#!/bin/bash

source ./settings.sh

Cleanup()
{
        ./teardown_cognito.sh
}

#===========================================BUILD TESTS =====================================================================================

# Build all tests if they are not built
if [[ ! -f ./unitTests ]]; then
        make all
fi

#===========================================SETUP TESTS =====================================================================================
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

./unitTests

./fullTest $TESTTOKEN
#============================================TEAR DOWN TEST SETUP============================================================================
Cleanup
