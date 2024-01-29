.DEFAULT_GOAL := all

PRINCIPAL_NAME := AWSIAMauth
GSSAPI_CLIENT_MODULE := $(PRINCIPAL_NAME)client.so
GSSAPI_SERVER_MODULE := $(PRINCIPAL_NAME)server.so
GROUP_MODULE := $(PRINCIPAL_NAME)group.so

AWS_SDK_LIBS := -L/usr/local/lib64 -laws-cpp-sdk-core -laws-cpp-sdk-cognito-idp -Wl,-rpath,/usr/local/lib64
CPPLIBS := -lstdc++
export INSTALLED_OPENSSL := $(shell openssl version | awk '{print $2}' | sed -e 's/[a-z]-*.*//' | awk -F. '{ print $1$2$3 }')
export INSTALLED_JSON_C := $(shell yum info installed json-c | grep Version | sed -e 's/Version\s*: //g' | awk -F. '{ print $1$2$3 }')

CXXFLAGS := -D_GLIBCXX_USE_CXX11_ABI=0

INCLUDES := -I$(DB2_HOME)/include -I../gss -I../common -I/usr/include
OSSL_LIBS_PATH := -L/usr/lib64

ifeq ($(OPENSSL_VER), 3)
    INCLUDES := -I$(DB2_HOME)/include -I../gss -I../common -I/usr/include -I/usr/include/openssl3
endif

OSSL_MACRO :=
ifeq ($(shell expr $(INSTALLED_OPENSSL) \>= 110), 1)
        OSSL_MACRO := -DOPENSSL_1_1_0
endif

JSON_MACRO :=
ifeq ($(shell expr $(INSTALLED_JSON_C) \>= 0130), 1)
        JSON_MACRO := -DJSON_C_0_13
endif

CFLAGS := $(INCLUDES) -L$(DB2_HOME)/lib -L../obj -g -fpic -fno-strict-aliasing -Werror \
          -DSQLUNIX \
          -D_GLIBCXX_USE_CXX11_ABI=0 \
          -D_REENTRANT \
          $(OSSL_MACRO) \
          $(JSON_MACRO) \
          -DCRYPT_OPENSSL_SUPPORTED

SCFLAGS := -I./$(DB2_HOME)/include -I./../gss -L$(DB2_HOME)/lib -L.. -fpic -fno-strict-aliasing 

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $< -o $@
 

LIBS := -lcrypto -lcurl -ljson-c $(OSSL_LIBS_PATH) 
GROUP_LIBS := -lcrypto -Wl,-z,defs
GROUP_LIBSJ := -ljson-c
SERVERLIBS := -lssl -ldb2


unitTests: unit_jwk.o unit_jwt.o unit_aws_sdk_apis.o unit_main.o
	g++ $(CFLAGS) $(LIBS) $(AWS_SDK_LIBS) -o $@ unit_jwk.o unit_jwt.o unit_aws_sdk_apis.o unit_main.o ../build/security64/plugin/IBM/server/AWSIAMauth.so ../build/security64/plugin/IBM/group/AWSIAMauthgroup.so 

jwtTests: unit_jwt.o unit_main.o
	g++ $(CFLAGS) $(LIBS) -o $@ unit_jwt.o unit_main.o ../build/security64/plugin/IBM/server/AWSIAMauth.so ../build/security64/plugin/IBM/group/AWSIAMauthgroup.so

jwkTests: unit_jwk.o  unit_main.o
	g++ $(CFLAGS) $(LIBS) -o $@ unit_jwk.o unit_main.o ../build/security64/plugin/IBM/server/AWSIAMauth.so ../build/security64/plugin/IBM/group/AWSIAMauthgroup.so

awsTests: unit_aws_sdk_apis.o unit_main.o
	g++ $(CFLAGS) $(CXXFLAGS) $(LIBS) $(AWS_SDK_LIBS) -o $@ unit_aws_sdk_apis.o unit_main.o ../build/security64/plugin/IBM/server/AWSIAMauth.so ../build/security64/plugin/IBM/group/AWSIAMauthgroup.so

fullTest: fulltest.o
	g++ $(CFLAGS) $(CXXFLAGS) $(LIBS) $(AWS_SDK_LIBS) -o $@ fulltest.o ../build/security64/plugin/IBM/server/AWSIAMauth.so ../build/security64/plugin/IBM/group/AWSIAMauthgroup.so

unit_jwt.o: unit_jwt.cpp
	g++ $(CFLAGS) $(LIBS)  -c -o $@ $<

unit_jwk.o: unit_jwk.cpp
	g++ $(CFLAGS) $(LIBS)  -c -o $@ $<

unit_aws_sdk_apis.o: unit_aws_sdk_apis.cpp
	g++ $(CFLAGS) $(CXXFLAGS) -I/usr/local/include $(CPPLIBS) $(AWS_SDK_LIBS) $(LIBS)  -c -o $@ $<

# Command line example
unit_main.o: unit_main.cpp
	g++ $(CFLAGS) $(CXXFLAGS) $(LIBS) -c -o $@ $<

fulltest.o: fulltest.c
	g++ $(CFLAGS) $(LIBS)  -c -o $@ $<

.PHONY: all clean
all: unitTests awsTests jwkTests jwtTests fullTest

clean:
	rm -f *.o $(PROGS) jwtTests jwkTests awsTests unitTests fullTest

cleansetup:
	rm -f env.sh test_cognito_userpools.json
