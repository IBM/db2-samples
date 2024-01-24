
OBJDIR := obj
BUILDDIR := build
OUTPUTDIR := output
PLUGINDIR := $(BUILDDIR)/security64/plugin/IBM
TEST_DIR := test

# need to be built by instance owner
# $DB2_HOME points to expanded ~/sqllib
PRINCIPAL_NAME := AWSIAMauth
GSSAPI_CLIENT_MODULE := $(PLUGINDIR)/client/$(PRINCIPAL_NAME).so
GSSAPI_SERVER_MODULE := $(PLUGINDIR)/server/$(PRINCIPAL_NAME).so
GROUP_MODULE := $(PLUGINDIR)/group/$(PRINCIPAL_NAME)group.so
AWS_SDK_LIBS := -L/usr/local/lib64 -laws-cpp-sdk-core -laws-cpp-sdk-cognito-idp -Wl,-rpath,/opt/ibm/db2/V11.5/lib64
CPPLIBS := -lstdc++

export INSTALLED_OPENSSL := $(shell openssl version | awk '{print $2}' | sed -e 's/[a-z]-*.*//' | awk -F. '{ print $1$2$3 }')
export INSTALLED_JSON_C := $(shell yum info installed json-c | grep Version | sed -e 's/Version\s*: //g' | awk -F. '{ print $1$2$3 }')

_dummy := $(shell mkdir -p $(OBJDIR))
_dummy := $(shell mkdir -p $(OUTPUTDIR))
_dummy := $(shell mkdir -p $(PLUGINDIR)/server)
_dummy := $(shell mkdir -p $(PLUGINDIR)/client)
_dummy := $(shell mkdir -p $(PLUGINDIR)/group)
#_dummy := $(shell chown -R bin:bin $(PLUGINDIR))


.DEFAULT_GOAL := all

CXXFLAGS := -D_GLIBCXX_USE_CXX11_ABI=0

INCLUDES := -I$(DB2_HOME)/include -I.
OSSL_LIBS_PATH := -L/usr/lib64

ifeq ($(OPENSSL_VER), 3)
    INCLUDES := -I$(DB2_HOME)/include -I. -I/usr/include/openssl3
    OSSL_LIBS_PATH := -L/usr/lib64
endif

OSSL_MACRO :=
ifeq ($(shell expr $(INSTALLED_OPENSSL) \>= 110), 1)
    OSSL_MACRO := -DOPENSSL_1_1_0
endif     

JSON_MACRO :=
ifeq ($(shell expr $(INSTALLED_JSON_C) \>= 0130), 1)
    JSON_MACRO := -DJSON_C_0_13
endif

CFLAGS := $(INCLUDES) -g -fpic -fno-strict-aliasing \
          -DSQLUNIX \
          -D_GLIBCXX_USE_CXX11_ABI=0 \
          -D_REENTRANT \
          $(OSSL_MACRO) \
          $(JSON_MACRO) \
          -DCRYPT_OPENSSL_SUPPORTED


GSSAPI_CLIENT_SRC := AWSIAMauthclient.c AWSIAMauthcommon.c AWSIAMtrace.c base64.c
GSSAPI_CLIENT_OBJ := $(addprefix $(OBJDIR)/,$(notdir $(GSSAPI_CLIENT_SRC:.c=.o)))

GSSAPI_SERVER_SRC := AWSIAMauthserver.c AWSIAMauthcommon.c jwt.c jwk.c base64.c AWSIAMtrace.c utils.c
GSSAPI_SERVER_OBJ := $(addprefix $(OBJDIR)/,$(notdir $(GSSAPI_SERVER_SRC:.c=.o)))

GSSAPI_SERVER_SRC2 := AWSUserPoolInfo.cpp iam.cpp AWSSDKRAII.cpp
GSSAPI_SERVER_OBJ2 := $(addprefix $(OBJDIR)/,$(notdir $(GSSAPI_SERVER_SRC2:.cpp=.o)))

GROUP_SRC := AWSIAMauthgroup.c AWSIAMauthcommon.c AWSIAMtrace.c jwt.c jwk.c base64.c usersjson.c utils.c
GROUP_OBJ := $(addprefix $(OBJDIR)/,$(notdir $(GROUP_SRC:.c=.o)))

GROUP_SRC2 := AWSUserGroupInfo.cpp AWSSDKRAII.cpp
GROUP_OBJ2 := $(addprefix $(OBJDIR)/,$(notdir $(GROUP_SRC2:.cpp=.o)))


LIBS := -lcrypto -lcurl -ljson-c -lldap $(OSSL_LIBS_PATH)
GROUP_LIBS := -lcrypto -Wl,-z,defs
GROUP_LIBSJ := -ljson-c

$(GSSAPI_CLIENT_MODULE): $(GSSAPI_CLIENT_OBJ)
	$(CC) $(CFLAGS) $(LIBS) -shared $^ -o $@
	chmod 755 $@

$(GSSAPI_SERVER_MODULE): $(GSSAPI_SERVER_OBJ) $(GSSAPI_SERVER_OBJ2)
	$(CC) $(CFLAGS) $(LIBS) $(CPPLIBS) $(AWS_SDK_LIBS) -shared $^ -o $@
	chmod 755 $@

$(GROUP_MODULE): $(GROUP_OBJ) $(GROUP_OBJ2)
	$(CC) $(CFLAGS) $(LIBS) $(CPPLIBS) $(AWS_SDK_LIBS) -Wl,-z,defs -shared $^ -o $@
	chmod 755 $@


.PHONY: gss
gss: $(OUTPUTDIR)/db2-aws-iam-secplugins.tar.gz

$(OUTPUTDIR)/db2-aws-iam-secplugins.tar.gz: $(GSSAPI_CLIENT_MODULE) $(GSSAPI_SERVER_MODULE) $(GROUP_MODULE) $(BUILDDIR)/configSecPlugin.sh 
	tar -C $(BUILDDIR) --owner=bin --group=bin -cvf $(OUTPUTDIR)/db2-aws-iam-secplugins.tar .
	tar -C $(BUILDDIR) --owner=1500 --group=1500 -rvf $(OUTPUTDIR)/db2-aws-iam-secplugins.tar 
	gzip -f $(OUTPUTDIR)/db2-aws-iam-secplugins.tar

	
$(BUILDDIR)/configSecPlugin.sh: configSecPlugin.sh
	sed 's/__PRINCIPAL_NAME__/$(PRINCIPAL_NAME)/g' configSecPlugin.sh >  $(BUILDDIR)/configSecPlugin.sh
	chmod 755 $@

.PHONY: cleangss
cleangss: 
	$(RM) $(GSSAPI_CLIENT_OBJ) $(GSSAPI_SERVER_OBJ) $(GSSAPI_SERVER_OBJ2) $(GROUP_OBJ) $(GROUP_OBJ2) $(GSSAPI_SERVER_MODULE) $(GSSAPI_CLIENT_MODULE) $(GROUP_MODULE) \
		$(UNIT_OBJ) $(UNIT_TEST) $(OUTPUTDIR)/db2-aws-iam-secplugins.tar.gz $(BUILDDIR)/configSecPlugin.sh

$(OBJDIR)/%.o: gss/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: commmon/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: common/%.c common/%.h
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: gss/%.c gss/%.h
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/iam.o: gss/iam.cpp gss/iam.h
	$(CC) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

$(OBJDIR)/AWSUserGroupInfo.o: gss/AWSUserGroupInfo.cpp gss/AWSUserGroupInfo.h
	$(CXX) $(CFLAGS) $(CXXFLAGS) -I/usr/local/include $(CPPLIBS) $(AWS_SDK_LIBS) -c $< -o $@
 
$(OBJDIR)/AWSUserPoolInfo.o: gss/AWSUserPoolInfo.cpp gss/AWSUserPoolInfo.h
	$(CXX) $(CFLAGS) $(CXXFLAGS) -I/usr/local/include $(CPPLIBS) $(AWS_SDK_LIBS) -c $< -o $@

$(OBJDIR)/AWSSDKRAII.o: gss/AWSSDKRAII.cpp gss/AWSSDKRAII.h
	$(CXX) $(CFLAGS) $(CXXFLAGS) -I/usr/local/include $(CPPLIBS) $(AWS_SDK_LIBS) -c $< -o $@

$(OBJDIR)/AWSIAMauthgroup.o: gss/AWSIAMauthgroup.c
	$(CC) $(CFLAGS) -z defs -c $< -o $@ 

$(OBJDIR)/AWSIAMtrace.o:  common/AWSIAMtrace.c 
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/usersjson.o: common/usersjson.c
	$(CC) $(CFLAGS) -c $< -o $@

-include $(wildcard *.d)

.PHONY: install
install: $(OUTPUTDIR)/db2-aws-iam-secplugins.tar.gz
	sudo tar -C ~/sqllib -xvf $(OUTPUTDIR)/db2-aws-iam-secplugins.tar.gz
	sh ~/sqllib/configSecPlugin.sh
	db2 terminate; db2stop force; db2start; db2 activate db bludb

.PHONY: remove
remove:
	sh ~/sqllib/configSecPlugin.sh -remove
	sudo $(RM) ~/sqllib/security64/plugin/IBM/client/$(notdir ${GSSAPI_CLIENT_MODULE})
	sudo $(RM) ~/sqllib/security64/plugin/IBM/server/$(notdir ${GSSAPI_SERVER_MODULE})
	sudo $(RM) ~/sqllib/security64/plugin/IBM/group/$(notdir ${GROUP_MODULE})
	db2 terminate; db2stop force; db2start; db2 activate db bludb

.PHONY: tail
tail:
	tailf ~/sqllib/db2dump/db2diag.log  | grep AWSIAMauth


$(TEST_DIR)/unit_apikey.o: $(TEST_DIR)/unit_apikey.cpp
	g++ $(CFLAGS)  $(LIBS) -c -o $@ $<


# Command line example
$(TEST_DIR)/unit-main.o: $(TEST_DIR)/unit_main.cpp
	g++ $(CFLAGS)  $(LIBS) -c -o $@ $<


$(TEST_DIR)/unit_test_apikey: $(TEST_DIR)/unit-main.o $(TEST_DIR)/unit_apikey.o
	g++ $(CFLAGS)  $(LIBS) -o $@ $(TEST_DIR)/unit-main.o $(TEST_DIR)/unit_apikey.o  ${GSSAPI_SERVER_MODULE}

unit_test: $(UNIT_TEST)
	./test/$(UNIT_TEST)

$(UNIT_TEST): $(UNIT_OBJ) $(GSSAPI_OBJ)
	$(CXX) -g $(CFLAGS) $^ $(LIBS) -o $@

.PHONY: cleanum
DB2PATH = $(HOME)/sqllib
ERASE = rm -f
cleanum : 
	$(ERASE) obj/*.o
