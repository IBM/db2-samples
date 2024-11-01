/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2006
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*****************************************************************************
**
** SOURCE FILE NAME: IBMLDAPutils.h
**
** SAMPLE : LDAP security plugin header file.
**
*****************************************************************************
**
** For more information on developing DB2 security plugins, see the
** "Developing Security Plug-ins" section of the Application Development
** Guide.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#ifndef _H_DB2_IBMLDAPUTILS
#define _H_DB2_IBMLDAPUTILS

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>

#include <ctype.h>
#include <ldap.h>
#include <ldapssl.h>
#include <ldif.h>
#include <time.h>


#include <sqlenv.h>
#include <db2secPlugin.h>

#ifdef SQLUNIX
    #include <unistd.h>
    #include <sys/types.h>
#else
    #define strcasecmp(a,b) stricmp(a,b)
    #define snprintf _snprintf
    #define vsnprintf _vsnprintf
#endif

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#ifdef __cplusplus
#define DB2LDAP_EXT_C extern "C"
#else
#define DB2LDAP_EXT_C
#endif

#define DB2LDAP_ESCAPE_CHAR     '\\'

#define MAX_ERROR_MSG_SIZE      3048
#define MAX_FILTER_LENGTH       2048

#define DB2LDAP_MAX_DN_SIZE     1024

/* LDAP Plugin Config File
 *
 * File syntax:
 *  - Lines have the format "key = value"
 *  - Leading and trailing whitespace is stripped from both "key" and "value"
 *  - "key" may not contain whitespace (other than leading/trailing
 *  - "value" may contain whitepace
 *  - ";" begins a comment anywhere on a line
 *  - blank lines are allowed
 *
 * File location:
 *  - May be configured in the DB2LDAP_ENV_CFGFILE environment variable
 *  - Default values below (under instance home on UNIX, $DB2PATH on Windows)
 */

#define DB2LDAP_ENV_CFGFILE     "DB2LDAPSecurityConfig"

#define DB2LDAP_CFGDFLT_WIN     "\\cfg\\IBMLDAPSecurity.ini"
#define DB2LDAP_CFGDFLT_UNIX    "/sqllib/cfg/IBMLDAPSecurity.ini"

#define CFG_MAX_PARMNAME_LEN    64
#define CFG_MAX_FILENAME      1024
#define CFG_MAX_HOST_SIZE      500
#define CFG_MAX_ATTR           128
#define CFG_MAX_PSWD           256
#define CFG_MAX_DN            DB2LDAP_MAX_DN_SIZE
#define CFG_MAX_EXTN_SIGALG    512

/* Max line length is exactly 1092 visible bytes */
#ifdef SQLWINT
/* Account for extra "CR" line terminator on Windows */
#define CFG_MAX_LINE_LEN  (CFG_MAX_PARMNAME_LEN + CFG_MAX_FILENAME + 7)
#else
#define CFG_MAX_LINE_LEN  (CFG_MAX_PARMNAME_LEN + CFG_MAX_FILENAME + 6)
#endif

#define CFGKEY_HOST                     "LDAP_HOST"
#define CFGKEY_ENABLE_SSL               "ENABLE_SSL"
#define CFGKEY_SSL_KEYFILE              "SSL_KEYFILE"
#define CFGKEY_SSL_PW                   "SSL_PW"
#define CFGKEY_SEARCH_DN                "SEARCH_DN"
#define CFGKEY_SEARCH_PW                "SEARCH_PW"
#define CFGKEY_USER_BASEDN              "USER_BASEDN"
#define CFGKEY_USERID_ATTRIBUTE         "USERID_ATTRIBUTE"
#define CFGKEY_AUTHID_ATTRIBUTE         "AUTHID_ATTRIBUTE"
#define CFGKEY_USER_OBJECTCLASS         "USER_OBJECTCLASS"
#define CFGKEY_GROUP_BASEDN             "GROUP_BASEDN"
#define CFGKEY_GROUP_OBJECTCLASS        "GROUP_OBJECTCLASS"
#define CFGKEY_GROUPNAME_ATTRIBUTE      "GROUPNAME_ATTRIBUTE"
#define CFGKEY_GROUP_LOOKUP_ATTRIBUTE   "GROUP_LOOKUP_ATTRIBUTE"
#define CFGKEY_GROUP_LOOKUP_METHOD      "GROUP_LOOKUP_METHOD"
#define CFGKEY_NESTED_GROUPS            "NESTED_GROUPS"
#define CFGKEY_FOLLOW_REFERRALS         "FOLLOW_REFERRALS"
#define CFGKEY_DEBUG                    "DEBUG"
#define CFGKEY_FIPS_MODE                "FIPS_MODE"
#define CFGKEY_SECURITY_PROTOCOL        "SECURITY_PROTOCOL"
#define CFGKEY_SSL_EXTN_SIGALG          "SSL_EXTN_SIGALG"
#define CFGKEY_SASL_BIND                "SASL_BIND"

#define GROUP_METHOD_STR_USER_ATTR      "USER_ATTRIBUTE"
#define GROUP_METHOD_STR_SEARCH_BY_DN   "SEARCH_BY_DN"
#define GROUP_METHOD_USER_ATTR      1
#define GROUP_METHOD_SEARCH_BY_DN   2

#define SECURITY_PROTOCOL_STR_ALL       "ALL"
#define SECURITY_PROTOCOL_STR_TLS12     "TLSV12"
#define SECURITY_PROTOCOL_ALL       1
#define SECURITY_PROTOCOL_TLS12     2

#define FIPS_MODE_STR_OFF    "FALSE"
#define FIPS_MODE_STR_STRICT "STRICT"
#define FIPS_MODE_STR_ON     "TRUE"

#define FIPS_MODE_OFF 0
#define FIPS_MODE_STRICT 1
#define FIPS_MODE_ON 2

// ISVD 10.0.1 changed the default set of TLS versions,
// and added support for TLS 1.3. To provide equivalent
// behaviour to ISDS 6.4 and to prevent issues when
// customers apply fixpacks, we will use the old values
// for the LDAP_SECURITY_PROTOCOL constants
#define LDAP_SECURITY_PROTOCOL_OLD_ALL "SSLV3,TLS10,TLS11,TLS12"

// TLS 1.1 and lower are insecure, so Db2 will enable only
// TLS 1.2 by default unless explicitly configured by the customer
#define LDAP_SECURITY_PROTOCOL_DB2_DEFAULT "TLS12"

// Defaults when "strict FIPS" mode is enabled
#define TLS_DEFAULT_STRICT_FIPS_VERSION_STRING LDAP_SECURITY_PROTOCOL_TLSV12
#define TLS_DEFAULT_STRICT_FIPS_CIPHERS_STRING "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,"\
                                               "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,"\
                                               "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,"\
                                               "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,"\
                                               "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,"\
                                               "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,"\
                                               "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,"\
                                               "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,"\
                                               "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,"\
                                               "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,"\
                                               "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,"\
                                               "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA"

//  The Supported signature hash extensions are:
//    GSK_TLS_SIGALG_RSA_WITH_SHA224
//    GSK_TLS_SIGALG_RSA_WITH_SHA256
//    GSK_TLS_SIGALG_RSA_WITH_SHA384
//    GSK_TLS_SIGALG_RSA_WITH_SHA512
//    GSK_TLS_SIGALG_ECDSA_WITH_SHA224
//    GSK_TLS_SIGALG_ECDSA_WITH_SHA256
//    GSK_TLS_SIGALG_ECDSA_WITH_SHA384
//    GSK_TLS_SIGALG_ECDSA_WITH_SHA512


/* The "types" parameter to db2ldapReadConfig is a bitmask that
 * determines which keys are mandatory.
 */
#define CFG_USERAUTH    0x01
#define CFG_GROUPLOOKUP 0x02

typedef struct
{
    /* LDAP Server Config */
    int  haveSearchDN;
    int  groupLookupMethod;
    int  nestedGroups;
    int  isSSL;
    int  followReferrals;
    int  debug;
    int  fipsMode;
    int  securityProtocol;
    int  isSaslBindOn;

    char ldapHost[CFG_MAX_HOST_SIZE+1];

    char searchDN[CFG_MAX_DN+1];
    char searchPWD[CFG_MAX_PSWD+1];

    char sslKeyfile[CFG_MAX_FILENAME+1];  /* SSL keyfile             */
    char sslPwd[CFG_MAX_PSWD+1];          /* Passphrase for keyfile  */
    char sslExtnSigAlg[CFG_MAX_EXTN_SIGALG+1]; /* TLS signature algorithms extension. */

    char userBase[CFG_MAX_DN+1];          /* Base for user searches  */
    char userObjClass[CFG_MAX_ATTR+1];    /* ObjClass for users      */
    char useridAttr[CFG_MAX_ATTR+1];      /* UserID Attribute        */
    char authidAttr[CFG_MAX_ATTR+1];      /* AuthID Attribute        */

    char groupBase[CFG_MAX_DN+1];         /* Base for group searches */
    char groupObjClass[CFG_MAX_ATTR+1];   /* ObjClass for groups     */
    char groupLookupAttr[CFG_MAX_ATTR+1]; /* Attr used to find group */
    char groupNameAttr[CFG_MAX_ATTR+1];   /* Group name attribute    */
} pluginConfig_t;

DB2LDAP_EXT_C
int db2ldapReadConfig(pluginConfig_t *cfg,
                      int types,            /* Bitmask (see below) */
                      char **errorMessage);

DB2LDAP_EXT_C
pluginConfig_t *db2ldapGetConfigDataPtr(void);



#define DB2LDAP_TOKEN_EYECATCHER    "DB2-LDAP-PLUGIN"

typedef struct {
    char eyeCatcher[sizeof(DB2LDAP_TOKEN_EYECATCHER)];
    LDAP *ld;
    char userDN[DB2LDAP_MAX_DN_SIZE+1];
    int  authidLen;
    char authid[DB2SEC_MAX_AUTHID_LENGTH+1];
} token_t;


DB2LDAP_EXT_C
db2secLogMessage *db2LogFunc;

DB2LDAP_EXT_C
SQL_API_RC SQL_API_FN CheckPassword(const char *userID,
                                    db2int32 userIDLength,
                                    const char *domain,            /* ignored */
                                    db2int32 domainLength,         /* ignored */
                                    db2int32 domainType,           /* ignored */
                                    const char *password,
                                    db2int32 passwordLength,
                                    const char *newPassword,
                                    db2int32 newPasswordLength,
                                    const char *databaseName,     /* not used */
                                    db2int32 databaseNameLength,  /* not used */
                                    db2Uint32 connection_details,
                                    void **token,                 /* not used */
                                    char **errorMessage,
                                    db2int32 *errorMessageLength);


DB2LDAP_EXT_C
int initLDAP(LDAP **ld, int doBind, char **errorMessage);

DB2LDAP_EXT_C
int db2ldapSetGSKitVar(char **errorMessage);

DB2LDAP_EXT_C
int db2ldapInitSSL(pluginConfig_t *cfg, char **errorMessage);

DB2LDAP_EXT_C
int db2ldapFindAttrib(LDAP *ld,
                      const char  *ldapbase,
                      const char  *objectClass,
                      const char  *searchAttr,
                      const char  *searchAttrValue,
                      const char  *resultAttr,
                      char       **resultString,
                      int          objectOnly,
                      char       **objectDN);

/* Return codes for db2ldapFindAttrib */
#define GET_ATTRIB_OK         0x0000
#define GET_ATTRIB_NO_OBJECT  0x1001
#define GET_ATTRIB_NOTFOUND   0x1002
#define GET_ATTRIB_TOOMANY    0x1003
#define GET_ATTRIB_LDAPERR    0x1004
#define GET_ATTRIB_BADINPUT   0x1005
#define GET_ATTRIB_NOMEM      0x1006

DB2LDAP_EXT_C
int db2ldapGetUserDN(LDAP        *ld,
                     const char  *userid,
                     char        *userDN,
                     char        *authID,
                     char       **errorMessage);

DB2LDAP_EXT_C
int getDNByFilter
        (LDAP *ld,
        const char* ldapbase,
        char* filter,
        char* retDN);

DB2LDAP_EXT_C
int DoesEntryExistByFilter
        (LDAP *ld,
        const char* ldapbase,
        const char* filter,
        int* rc);

#endif // _H_DB2_IBMLDAPUTILS
