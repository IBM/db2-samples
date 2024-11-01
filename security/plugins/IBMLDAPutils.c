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
** SOURCE FILE NAME: IBMLDAPutils.c 
**
** SAMPLE: Utility functions used in the DB2 LDAP security plugin
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

#include "IBMLDAPutils.h"
#include "ossfeat.h"

/* rebindGetCreds
 *
 * A callback that allows the LDAP client code to obtain bind
 * credentials when following referrals.
 */
DB2LDAP_EXT_C static
int rebindGetCreds(LDAP  *ld,
                   char **dn,
                   char **pw,
                   int   *method,
                   int    dofree)
{
   if ( !dofree )
   {
      pluginConfig_t  *pCfg = db2ldapGetConfigDataPtr();

      *method = LDAP_AUTH_SIMPLE;
      if (pCfg->haveSearchDN)
      {
         *dn = pCfg->searchDN;
         *pw = pCfg->searchPWD;
      }
      else
      {
         *dn = NULL;
         *pw = NULL;
      }
   }
   return(LDAP_SUCCESS);
}


/* initLDAP
 *
 * Initialize an LDAP handle, and optionally bind if a searchDN and
 * password are defined.
 */
DB2LDAP_EXT_C
int initLDAP(LDAP  **ld,
             int     doBind,
             char  **errorMsg)
{
   int        rc = DB2SEC_PLUGIN_OK;
   char       *errStr = NULL;
   char       dumpMsg[MAX_ERROR_MSG_SIZE];
   size_t     msgLength = 0 ;

   pluginConfig_t  *pCfg = db2ldapGetConfigDataPtr();

   if (pCfg->isSSL)
   {
      rc = db2ldapInitSSL(pCfg, errorMsg);
      if (rc != DB2SEC_PLUGIN_OK) goto exit;

      *ld = ldap_ssl_init(pCfg->ldapHost, LDAPS_PORT, NULL);
      if (*ld == NULL)
      {
         rc = ldap_get_errno(*ld);
         snprintf(dumpMsg, MAX_ERROR_MSG_SIZE ,
                  "ldap_ssl_init failed,  rc=%d (%s)\nhost list: %s",
                  rc, ldap_err2string(rc), pCfg->ldapHost);
         *errorMsg = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_NETWORKERROR;
         goto exit;
      }

      if (pCfg->securityProtocol != -1)
      {
         rc = ldap_set_option(*ld, LDAP_OPT_SSL_SECURITY_PROTOCOL,
                              pCfg->securityProtocol == SECURITY_PROTOCOL_ALL?
                                   LDAP_SECURITY_PROTOCOL_OLD_ALL : LDAP_SECURITY_PROTOCOL_TLSV12);
         if (rc != LDAP_SUCCESS)
         {
            snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
                     "InitLDAP: failed setting security_protocol opt to %s\nrc=%d (%s)",
                     pCfg->securityProtocol == SECURITY_PROTOCOL_ALL? 
                           LDAP_SECURITY_PROTOCOL_ALL : LDAP_SECURITY_PROTOCOL_TLSV12,
                     rc, ldap_err2string(rc));
            *errorMsg = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            goto exit;
         }

      }
      else
      {
         rc = ldap_set_option(*ld, LDAP_OPT_SSL_SECURITY_PROTOCOL, LDAP_SECURITY_PROTOCOL_DB2_DEFAULT); 

         if (rc != LDAP_SUCCESS)
         {
            snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
                     "InitLDAP: failed setting security_protocol opt to %s\nrc=%d (%s)",
                     LDAP_SECURITY_PROTOCOL_DB2_DEFAULT,
                     rc, ldap_err2string(rc));
            *errorMsg = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            goto exit;
         }
      }

      // If STRICT fips mode has been configured, turn off TLS_RSA_* ciphers
      // to prevent compatibility issues with LDAP servers that do not
      // have RSA restrictions. In addition, turn off TLS 1.1 and 1.0
      // since the only supported ciphers are TLS_RSA_*
      if (FIPS_MODE_STRICT == pCfg->fipsMode)
      {
         rc = ldap_set_option(*ld, LDAP_OPT_SSL_SECURITY_PROTOCOL,
                              TLS_DEFAULT_STRICT_FIPS_VERSION_STRING);
         if (rc != LDAP_SUCCESS)
         {
            snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
                     "InitLDAP: failed setting LDAP_OPT_SSL_SECURITY_PROTOCOL in strict FIPS mode\nrc=%d (%s)",
                     rc, ldap_err2string(rc));
            *errorMsg = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            goto exit;
         }

         rc = ldap_set_option(*ld, LDAP_OPT_SSL_CIPHER_EX,
                              TLS_DEFAULT_STRICT_FIPS_CIPHERS_STRING);
         if (rc != LDAP_SUCCESS)
         {
            snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
                     "InitLDAP: failed setting LDAP_OPT_SSL_CIPHER_EX in strict FIPS mode\nrc=%d (%s)",
                     rc, ldap_err2string(rc));
            *errorMsg = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            goto exit;
         }
      }
   }
   else
   {
      *ld = ldap_init(pCfg->ldapHost, LDAP_PORT);
      if ((*ld) == NULL)
      {
         rc = ldap_get_errno(*ld);
         snprintf(dumpMsg, MAX_ERROR_MSG_SIZE ,
                  "ldap_init failed,  rc=%d (%s)\nhost list: %s",
                  rc, ldap_err2string(rc), pCfg->ldapHost);
         *errorMsg = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_NETWORKERROR;
         goto exit;
      }
   }

   rc = ldap_set_option(*ld, LDAP_OPT_REFERRALS,
                (void *)(pCfg->followReferrals ? LDAP_OPT_ON: LDAP_OPT_OFF));
   if (rc != LDAP_SUCCESS)
   {
      snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
               "InitLDAP: failed setting referral opt to %d\nrc=%d (%s)",
               pCfg->followReferrals, rc, ldap_err2string(rc));
      *errorMsg = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      goto exit;
   }

   // Bind to the LDAP server if we can find a bind DN & password.
   // If they were not passed in as arguments, check the server data
   // to see if they have been configured.
   if (doBind && pCfg->haveSearchDN)
   {
      rc = ldap_simple_bind_s((*ld), pCfg->searchDN, pCfg->searchPWD);
      if (rc != LDAP_SUCCESS)
      {
         snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
                  "InitLDAP: bind failed rc=%d (%s)\nSearchDN='%s'",
                  rc, ldap_err2string(rc), pCfg->searchDN);
         *errorMsg = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_NETWORKERROR;
         goto exit;
      }

      // Set up a callback so the LDAP client code can obtain
      // credentials when it follows referrals
      ldap_set_rebind_proc( *ld, (LDAPRebindProc)rebindGetCreds );

   }

   rc = DB2SEC_PLUGIN_OK;

exit:
   return rc;
}

/* db2ldapSetGSKitVar
 *
 * Set GSKIT_LOCAL_INSTALL_MODE and/or GSKIT_CLIENT_VERSION
 */
DB2LDAP_EXT_C
int db2ldapSetGSKitVar(char **errorMessage)
{
   int    rc = DB2SEC_PLUGIN_OK;
   char   dumpMsg[MAX_ERROR_MSG_SIZE];

   // set the GSKIT_LOCAL_INSTALL_MODE environment variable if it not set.
   // this variable tells ldap to use the version of GSKit which
   // DB2 packages.
   // Note that these calls are not thread safe on Linux,Windows.
   // This is ok because the plugins are only loaded once
   // and they are not loaded concurently.
   // DB2 on Windows uses global GSKit so not set GSKIT_LOCAL_INSTALL_MODE
#if defined SQLUNIX
   if (getenv("GSKIT_LOCAL_INSTALL_MODE") == NULL)
   {
     rc = setenv( "GSKIT_LOCAL_INSTALL_MODE","1",1) ;
     if (rc != 0)
     {
        snprintf(dumpMsg, MAX_ERROR_MSG_SIZE, "db2ldapSetGSKitVar: "
                "setenv failed, rc= %d",rc);
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
     }
   }
#endif

   // Set the GSKIT_CLIENT_VERSION environment variable if it not set.
   // As of DB2 V9.7 GA, DB2 packages GSKit 8, and the LDAP client that 
   // DB2 LDAP Plugins use is TSA LDAP Client 6.2. Without setting this
   // variable, the LDAP client will try to load GSKit 7 packages by
   // default. Setting it outside the plugins would not work because 
   // this varialbe may not always available inside the plugins.
   if (getenv("GSKIT_CLIENT_VERSION") == NULL)
   {
#if defined SQLUNIX
     rc = setenv( "GSKIT_CLIENT_VERSION","8",1 ) ;
#elif defined SQLWINT
     rc = _putenv( "GSKIT_CLIENT_VERSION=8" ) ;
#endif
     if (rc != 0)
     {
#if defined SQLUNIX
        snprintf(dumpMsg, MAX_ERROR_MSG_SIZE, "db2ldapSetGSKitVar: "
                "setenv failed, rc= %d",rc);
#elif defined SQLWINT
        snprintf(dumpMsg, MAX_ERROR_MSG_SIZE, "db2ldapSetGSKitVar: "
                "_putenv failed, rc= %d",rc);
#endif
        *errorMessage = strdup(dumpMsg);
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
     }
   }
   
exit:
   return(rc);
}

/* db2ldapInitSSL
 *
 * Initialize the LDAP client SSL support with the configured
 * key file and passphrase.
 */
DB2LDAP_EXT_C
int db2ldapInitSSL(pluginConfig_t *cfg, char **errorMessage)
{
   int    rc = DB2SEC_PLUGIN_OK;
   int    sslrc = 0;
   char  *keyfile=NULL, *sslpass=NULL;
   char   dumpMsg[MAX_ERROR_MSG_SIZE];

#if defined( HPUX )
   int    MAX_KEYFILE_SIZE = 396;
#elif defined( SQLSUN )
   int    MAX_KEYFILE_SIZE = 1024; 
#endif

   if (cfg->isSSL)
   {
      if (cfg->sslKeyfile[0] != '\0') keyfile = cfg->sslKeyfile;
      if (cfg->sslPwd[0]     != '\0') sslpass = cfg->sslPwd;

#if defined( HPUX ) || defined( SQLSUN )
     /* wsdbu01304366  ldapsecp bucket testcase ldap022sb.pl failed on Sun64
        Temporary fix for GSKit V8.0.50.47 problem on Sun64 Ticket no: b7967
        GSKit traps when SSL_KEYFILE has filename size of 1024. 
        In normal execution, GSKit should return error 102 when SSL_KEYFILE
        filename size is 1024 but this does not happened in V8.0.50.47 on 
        Sun64. The following path is added to workaround the problem while 
        waiting for the fix from GSKit.
      */
      if ( keyfile != NULL && strlen(keyfile) >= MAX_KEYFILE_SIZE )
      {
         snprintf(dumpMsg, MAX_ERROR_MSG_SIZE, "db2ldapInitSSL: "
                  "Keyfile name exceeds maximum allowable length");
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }
#endif

      if( cfg->sslExtnSigAlg[0] != '\0' )
      {
         rc = ldap_ssl_set_extn_sigalg( cfg->sslExtnSigAlg );

         if (rc != LDAP_SUCCESS)
         {
            snprintf(dumpMsg, MAX_ERROR_MSG_SIZE,
                     "ldap_ssl_set_extn_sigalg: failed setting to [%s]\nrc=%d (%s)",
                     cfg->sslExtnSigAlg,
                     rc, ldap_err2string(rc));
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            goto exit;
         }
      }

      /* Set FIPS mode */
#if defined OSS_HAVE_FIPS
      rc = ldap_ssl_set_fips_mode_np(cfg->fipsMode);
#else
      rc = ldap_ssl_set_fips_mode_np(FIPS_MODE_OFF);
#endif

      if ( rc != LDAP_SUCCESS )
      {
         snprintf(dumpMsg, MAX_ERROR_MSG_SIZE, "db2ldapInitSSL: "
                  "ldap_ssl_set_fips_mode_np failed, rc=%d (%s)",
                  rc, ldap_err2string(rc));
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }

      rc = ldap_ssl_client_init(keyfile,
                                sslpass,
                                0,
                                &sslrc);
      if ( rc != LDAP_SUCCESS && rc != LDAP_SSL_ALREADY_INITIALIZED )
      {
         snprintf(dumpMsg, MAX_ERROR_MSG_SIZE, "db2ldapInitSSL: "
                  "ldap_ssl_client_init failed, rc=%d (%s), sslrc=%d",
                  rc, ldap_err2string(rc), sslrc);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }

      rc = DB2SEC_PLUGIN_OK;
   }

exit:
   return(rc);
}


/* db2ldapFindAttrib
 *
 * Returns the string value found using the ldap base, object class,
 * search attribute name & value, and result attribute provided as input.
 * Returns zero if exactly one matching value is found.
 *
 * Returns:
 *  GET_ATTRIB_OK        - Success
 *  GET_ATTRIB_NO_OBJECT - Search did not find the requested object
 *  GET_ATTRIB_NOTFOUND  - Search did not return the requested attribute
 *  GET_ATTRIB_TOOMANY   - More than one value returned for attribute
 *  GET_ATTRIB_LDAPERR   - An LDAP error occured
 *  GET_ATTRIB_BADINPUT  - Input parameters inccorect
 *  GET_ATTRIB_NOMEM     - strdup failed
 *
 * If at least one match is found, the first value is returned in
 * *resultString.  This string  must later be freed by the caller
 * using "free".  ResultString can be passed as NULL if
 * the value is not required by the caller.
 *
 * If objectOnly is TRUE, the search will be limited to the base
 * object itself (LDAP_SCOPE_BASE).  Otherwise a subtree search is
 * performed.  If objectOnly is TRUE, searchAttr and/or searchAttrValue
 * may be NULL, in which case they are not used to form the filter.
 *
 * If objectDN is not NULL, the DN of the first object in the
 * search results is returned.  String must be free'd by the caller.
 */
int db2ldapFindAttrib(LDAP *ld,
                      const char  *ldapbase,
                      const char  *objectClass,     // Used in filter
                      const char  *searchAttr,      // Used in filter
                      const char  *searchAttrValue, // Used in filter
                      const char  *resultAttr,      // Attribute to return
                      char       **resultString,    // Output, can be NULL
                      int          objectOnly,      // Search object or subtree?
                      char       **objectDN)        // Output, can be NULL
{
   int     rc = DB2SEC_PLUGIN_OK;
   char   *attrs[2];
   char   *cp = NULL;
   char  **values = NULL;
   char    filter[MAX_FILTER_LENGTH];
   size_t  filterLength = 0;
   char    dumpMsg[MAX_ERROR_MSG_SIZE];
   int     entryNum = 0;
   int     msgLength;
   int     scope;

   LDAPMessage *searchResult = NULL;
   LDAPMessage *ldapEntry = NULL;

   pluginConfig_t  *pCfg = db2ldapGetConfigDataPtr();

   if (objectClass == NULL || resultAttr == NULL ||
       (!objectOnly && (searchAttr == NULL || searchAttrValue == NULL)))
   {
      rc = GET_ATTRIB_BADINPUT;
      goto exit;
   }

   scope = (objectOnly) ? LDAP_SCOPE_BASE : LDAP_SCOPE_SUBTREE ;

   if (searchAttr == NULL || searchAttrValue == NULL)
   {
      filterLength = snprintf(filter, sizeof(filter),
                              "(objectClass=%s)",
                              objectClass);
   }
   else
   {
      filterLength = snprintf(filter, sizeof(filter),
                              "(&(objectClass=%s)(%s=%s))",
                              objectClass, searchAttr, searchAttrValue);
   }

   if (filterLength >= sizeof(filter))
   {
      filter[sizeof(filter)-1] = '\0';
      msgLength = snprintf(dumpMsg, sizeof(dumpMsg),
                           "db2ldapFindAttrib: filter too long:%s",
                           filter);
      db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, msgLength);
      rc = GET_ATTRIB_BADINPUT;
      goto exit;
   }
   attrs[0] = (char *)resultAttr;
   attrs[1] = NULL;

   rc = ldap_search_s(ld, ldapbase, scope, filter, attrs, FALSE, &searchResult);
   if (rc == LDAP_NO_SUCH_OBJECT)   
   {
      rc = GET_ATTRIB_NO_OBJECT;
      goto exit;
   }
   else if ( rc == LDAP_REFERRAL )  // We have chased a referral.
   {
      msgLength = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapFindAttrib:\n"
                           "ldap_search_s chased referral rc=%d (%s)\nfilter=%s",
                           rc, ldap_err2string(rc), filter);
      db2LogFunc(DB2SEC_LOG_INFO, dumpMsg, msgLength);
      rc = LDAP_SUCCESS;
   }
   else if ( rc != LDAP_SUCCESS )
   {
      msgLength = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapFindAttrib:\n"
                           "ldap_search_s failed rc=%d (%s)\nfilter=%s",
                           rc, ldap_err2string(rc), filter);
      db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, msgLength);
      rc = GET_ATTRIB_LDAPERR;
      goto exit;
   }

   entryNum = ldap_count_entries(ld, searchResult);

   if (entryNum < 1)
   {
      rc = GET_ATTRIB_NO_OBJECT;
      goto exit;
   }
   else if (entryNum > 1)
   {
      /* Not a fatal error... continue. */
      rc = GET_ATTRIB_TOOMANY;
      if (pCfg->debug)
      {
         msgLength = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapFindAttrib: "
                              "found %d results (scope=%d)\nfilter=%s",
                              entryNum, scope, filter);
         db2LogFunc(DB2SEC_LOG_WARNING, dumpMsg, msgLength);
      }
   }

   ldapEntry = ldap_first_entry(ld, searchResult);
   if (ldapEntry == NULL)
   {
      rc = GET_ATTRIB_NOTFOUND;
      goto exit;
   }

   values = ldap_get_values(ld, ldapEntry, attrs[0]);
   if (values == NULL || values[0] == NULL)
   {
      rc = GET_ATTRIB_NOTFOUND;
      goto exit;
   }
   if (values[1] != NULL)
   {
      rc = GET_ATTRIB_TOOMANY;
      if (pCfg->debug)
      {
         int num=2;
         while (values[num] != NULL) num++;
         msgLength = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapFindAttrib: "
                              "found %d values for attribyte '%s'\nfilter=%s",
                              num, attrs[0], filter);
         db2LogFunc(DB2SEC_LOG_WARNING, dumpMsg, msgLength);
      }
      /* Not a fatal error... continue. */
   }

   if (resultString != NULL)
   {
      *resultString = strdup(values[0]);
      if (*resultString == NULL)
      {
         rc = GET_ATTRIB_NOMEM;
         goto exit;
      }
   }

   /* Return the objectDN if requested. */
   if (objectDN != NULL)
   {
      cp = ldap_get_dn(ld, ldapEntry);
      if (cp == NULL)
      {
         rc = GET_ATTRIB_LDAPERR;
         goto exit;
      }

      *objectDN = strdup(cp);
      ldap_memfree(cp);

      if (*objectDN == NULL)
      {
         rc = GET_ATTRIB_NOMEM;
         goto exit;
      }
   }

exit:
   if (rc == GET_ATTRIB_LDAPERR)
   {
      int ldaprc = ldap_get_errno(ld);
      int len;
      len = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapFindAttrib: "
                     "unexpected LDAP rc=%d (%s)",
                     ldaprc, ldap_err2string(ldaprc));
      db2LogFunc(DB2SEC_LOG_ERROR, dumpMsg, len);
   }

   if (values != NULL) ldap_value_free(values);
   if (searchResult != NULL) ldap_msgfree(searchResult);

   return rc;
}



/* db2ldapGetUserDN
 *
 * Take a user-supplied "userid" and search for the associated user
 * DN on the LDAP server.
 *
 * Three different userid formats are understood:
 * user        (no "=" in userid)
 *   - Search for "cfg->useridAttr = user" with a base of "cfg->userBase"
 *
 * attr=abc    (at least one "=")
 *   - Use the userid string as-is for search, with base of "cfg->userBase"
 *
 * attr1=a,attr2=b,... (more than one "=" and at least one ",")
 *   - Use the userid string as the base, search for "(objectClass=*)"
 *     (to succeed, the userid string must generally be a complete DN)
 *
 * Note: userid must be NULL terminated.
 *
 * The user DN is returned in "userDN", which must be a pointer to a
 * buffer of at least DB2LDAP_MAX_DN_SIZE + 1 bytes.
 *
 * If authID is not NULL, it should be a pointer to a buffer of at least
 * DB2SEC_MAX_AUTHID_LENGTH + 1 bytes, in which the value of the authid
 * attribute will be returned.  If no authid attribute is found, or if
 * more than one value is returned for the user, the authID will be 
 * the empty string and an error will be returned.
 */
DB2LDAP_EXT_C
int db2ldapGetUserDN(LDAP        *ld,
                     const char  *userid,
                     char        *userDN,
                     char        *authID,        /* May be NULL */
                     char       **errorMessage)
{
   int    rc = DB2SEC_PLUGIN_OK;
   int    numEqual = 0;
   int    gotComma = FALSE;
   char  *firstEqual = NULL;
   int    len;
   int    cnt = 0;
   int    scope;
   int    ldaprc, first_ldaprc;
   int    retried = FALSE;
   char  *cp = NULL;
   char  *attrs[2];
   char   filter[MAX_FILTER_LENGTH];
   char   dumpMsg[MAX_ERROR_MSG_SIZE];
   char **values = NULL;
   const char *ldapbase = NULL;

   LDAPMessage *ldapRes   = NULL;
   LDAPMessage *ldapEntry = NULL;

   pluginConfig_t  *pCfg = db2ldapGetConfigDataPtr();


   /* Walk through the provided userid, counting "=" and ",".
    * Keep track of the first "=" we find (useful below).
    */
   cp = (char*)userid;
   while (*cp != '\0' && (numEqual < 2 || !gotComma))
   {
      if (*cp == ',') gotComma = TRUE;
      if (*cp == '=')
      {
         numEqual++;
         if (firstEqual == NULL) firstEqual = cp;
      }
      cp++;
   }

   if (numEqual > 1 && gotComma)
   {
      /* userid appears to be a full DN */
      snprintf(filter, sizeof(filter),
               "(objectClass=%s)", pCfg->userObjClass);
      ldapbase = userid;
      scope = LDAP_SCOPE_BASE;
   }
   else if (numEqual > 0)
   {
      /* userid is "attr=value" */
      snprintf(filter, sizeof(filter),
               "(&(objectClass=%s)(%s))",
               pCfg->userObjClass, userid);
      ldapbase = pCfg->userBase;
      scope = LDAP_SCOPE_SUBTREE;
   }
   else
   {
      /* just plain "userid" */
      snprintf(filter, sizeof(filter),
               "(&(objectClass=%s)(%s=%s))",
               pCfg->userObjClass, pCfg->useridAttr, userid);
      ldapbase = pCfg->userBase;
      scope = LDAP_SCOPE_SUBTREE;
   }


retry_search:
   if (pCfg->debug)
   {
      len = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN: "
                     "searching (retried=%d scope=%d) with\nbase=%s\nfilter=%s",
                     retried, scope, ldapbase, filter);
      db2LogFunc(DB2SEC_LOG_WARNING, dumpMsg, len);
   }

   /* Grab the authid while we're at it. */
   attrs[0] = pCfg->authidAttr;
   attrs[1] = NULL;

   ldaprc = ldap_search_s(ld, ldapbase, scope,
                          filter, attrs, 0, &ldapRes);
   if (ldaprc != LDAP_SUCCESS && ldaprc != LDAP_REFERRAL)
   {
      /* If we didn't find the user fall through, to the retry logic below */
      cnt = 0;
   }
   else
   {
      ldaprc = LDAP_SUCCESS;
      cnt = ldap_count_entries(ld, ldapRes);
   }

   if (cnt == 0)
   {
      if (!retried)
      {
         /* It's possible that we parsed the userid incorrectly.
          * If the userid is "a=bcd", we did a search for attribute
          * "a" with value "bcd".  Try again, treating the supplied
          * userid as plain userid, qualified by the configured userid
          * attribute.
          */

         first_ldaprc = ldaprc;

         /* We only retry if the userid contains at least one "=". */
         if (strchr(userid, '=') != NULL)
         {
            /* Free a bunch of stuff before we overwrite the pointers. */
            if (ldapRes != NULL) ldap_msgfree(ldapRes);
            ldapRes = NULL;

            snprintf(filter, sizeof(filter), "(&(objectClass=%s)(%s=%s))",
                     pCfg->userObjClass, pCfg->useridAttr, userid);
            ldapbase = pCfg->userBase;
            scope    = LDAP_SCOPE_SUBTREE;

            retried = TRUE;
            goto retry_search;
         }
      }

      /* To reach this point we've either already retried or decided
       * not to (because the userid didn't contain a "=").
       */
      if (first_ldaprc == LDAP_SUCCESS)
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN:\n"
                  "LDAP search for user '%s' returned no results", userid);
      }
      else
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN:\n"
                  "LDAP search failed with ldap rc=%d (%s)\nuser='%s'",
                  first_ldaprc, ldap_err2string(first_ldaprc), userid);
      }
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }


   if (cnt > 1)
   {
      len = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN:\n"
                     "search for user '%s' returned multiple (%d) entries",
                     userid, cnt);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }

   ldapEntry = ldap_first_entry(ld, ldapRes);
   if (ldapEntry == NULL)
   {
      /* No user found that matches the search criteria. */
      len = snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN:\n"
                     "ldap_first_entry returned NULL with %d results\n"
                     "user '%s'", cnt, userid);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }

   cp = ldap_get_dn(ld, ldapEntry);
   if (cp == NULL)
   {
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN:\n"
               "ldap_get_dn failed for user '%s'", userid);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      goto exit;
   }

   len = strlen(cp);
   if (len > DB2LDAP_MAX_DN_SIZE)
   {
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN:\n"
               "DN for user '%s' is too long (%d bytes):\n%s",
               userid, len, cp);
      *errorMessage = strdup(dumpMsg);
      ldap_memfree(cp);
      rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      goto exit;
   }

   strcpy(userDN, cp);
   ldap_memfree(cp);

   if (authID != NULL)
   {
      /* Grab the AuthID from the entry */
      values = ldap_get_values(ld, ldapEntry, pCfg->authidAttr);

      authID[0] = '\0';

      /* If we find exactly only value, store it away. */
      if (values != NULL && values[0] != NULL)
      {
         if (values[1] != NULL)
         {
            /* Too many results for this attribute */
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN: "
                     "too many AuthID values found for user '%s'",
                     userid);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
         }

         len = strlen(values[0]);
         if (len > DB2SEC_MAX_AUTHID_LENGTH)
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN: "
                     "authID too long (%d bytes)\nuser='%s'\nauthID='%s'",
                     len, userid, values[0]);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
         }
         strcpy(authID, values[0]);
      }
      else
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetUserDN: "
                  "no AuthID values found for user '%s'",
                  userid);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BADUSER;
         goto exit;
      }
   }

exit:
   if (values  != NULL) ldap_value_free(values);
   if (ldapRes != NULL) ldap_msgfree(ldapRes);
   return(rc);
}


/* CheckPassword
 *
 * Parse the input userid, search for it in LDAP, then bind to
 * the LDAP server using the supplied password.
 */
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
                                    void **token,
                                    char **errorMessage,
                                    db2int32 *errorMessageLength)
{
   int      rc = DB2SEC_PLUGIN_OK;
   LDAP     *ld = NULL;
   LDAP     *ld_auth = NULL;
   token_t  *pluginToken = NULL;
   char     *authIDptr = NULL;
   char      user[DB2SEC_MAX_USERID_LENGTH + 1];
   char      userDN[DB2LDAP_MAX_DN_SIZE + 1] = { '\0' };
   char      authID[DB2SEC_MAX_AUTHID_LENGTH + 1] = { '\0' };
   char      local_passwd[DB2SEC_MAX_PASSWORD_LENGTH + 1];
   char      dumpMsg[MAX_ERROR_MSG_SIZE];

   struct berval ** serverCreds = NULL;
   LDAPControl ** bindControls = NULL;
   LDAPControl ** returnedControls = NULL;
   int controlres = 0;
   int controlerr = 0;
   int controlwarn = 0;

   pluginConfig_t  *pCfg = db2ldapGetConfigDataPtr();

   *errorMessage = NULL;
   *errorMessageLength = 0;

   if (newPassword != NULL && newPasswordLength > 0)
   {
      *errorMessage = strdup("Change password not supported");
      rc = DB2SEC_PLUGIN_CHANGEPASSWORD_NOTSUPPORTED;
      goto exit;
   }

   if (userID == NULL || userIDLength <= 0)
   {
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit ;
   }

   /* Check userID length */
   if ( userIDLength > DB2SEC_MAX_USERID_LENGTH )
   {
      strncpy(user, userID, sizeof(user)-1);
      user[sizeof(user)-1] = '\0';
      snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
               "userid too long: %d bytes\n[truncated]:%s\n",
               (int)userIDLength, user);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BADUSER;
      goto exit;
   }
   memcpy(user, userID, userIDLength);
   user[userIDLength] = '\0';

   
   if (passwordLength > DB2SEC_MAX_PASSWORD_LENGTH || passwordLength < 0)
   {
      snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
               "bad password length (%d) for user '%s'", (int)passwordLength, user);
      rc = DB2SEC_PLUGIN_BADPWD;
      goto exit;
   }

   if (passwordLength <= 0 || password == NULL)
   {
      passwordLength = 0;
   }
   else
   {
      memcpy(local_passwd, password, passwordLength);
      local_passwd[passwordLength] = '\0';
   }

   /* Only bother looking up the AuthID if we're on the server. */
   if (connection_details & DB2SEC_VALIDATING_ON_SERVER_SIDE)
   {
      authIDptr = authID;
   }


   /* Initialize the LDAP handle we'll use for all searches. */
   rc = initLDAP(&ld, TRUE, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;


   rc = db2ldapGetUserDN(ld, user, userDN, authIDptr, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;


   /* It is acceptable not to supply a password only in the
    * following scenario:
    *  - The username was not supplied by the user, and
    *  - If we're on the server side, the connection must
    *    be "local" (originating from the same machine)
    *
    * APAR JR32272, JR32273 and JR32268.  Do extra strlen()
    * check on the password as a password with all binary
    * zeros could turn the bind into an anonymous bind.
    * If an anonymous bind is allowed by the LDAP server
    * then this would allow a user with an invalid 
    * password to pass authentication.
    */
   if (passwordLength == 0 || strlen(local_passwd) == 0)
   {
      if ((connection_details & DB2SEC_USERID_FROM_OS) &&
          ((connection_details & DB2SEC_CONNECTION_ISLOCAL) ||
           !(connection_details & DB2SEC_VALIDATING_ON_SERVER_SIDE)))
      {
         goto skip_bind;
      }
      rc = DB2SEC_PLUGIN_BADPWD;
      goto exit;
   }


   /* Use a seperate LDAP handle for "bind" authentication. */
   rc = initLDAP(&ld_auth, FALSE, errorMessage);
   if (rc != DB2SEC_PLUGIN_OK) goto exit;

   if(pCfg->isSaslBindOn)
   {
      struct berval saslPasswd = {'\0'};

      // password passed in to ldap_sasl_bind
      saslPasswd.bv_len = strlen(local_passwd);
      saslPasswd.bv_val = local_passwd;

      // password policy
      rc = ldap_add_control(LDAP_PWDPOLICY_CONTROL_OID, 0 , NULL, LDAP_OPT_OFF, &bindControls);

      if( rc != LDAP_SUCCESS )
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
                  "unexpected LDAP error adding password policy control \nldaprc=%d (%s)",
                  rc, ldap_err2string(rc));
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }

      rc = ldap_sasl_bind_s(ld_auth, userDN, LDAP_SASL_SIMPLE, &saslPasswd, bindControls, NULL, serverCreds);
   }
   else
   {
      rc = ldap_simple_bind_s(ld_auth, userDN, local_passwd);
   }
#ifdef DB2LDAP_DEBUG
   snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
            "bind rc=%d with '%s' / '%s'", rc, userDN, local_passwd);
   db2LogFunc(DB2SEC_LOG_WARNING, dumpMsg, strlen(dumpMsg));
#endif
   if (rc != LDAP_SUCCESS)
   {
      if (rc == LDAP_INVALID_DN_SYNTAX)
      {
         rc = DB2SEC_PLUGIN_BADUSER;
      }
      else if (rc == LDAP_INVALID_CREDENTIALS)
      {
         rc = DB2SEC_PLUGIN_BADPWD;
      }
      else
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
                  "unexpected LDAP error binding DN '%s'\nldaprc=%d (%s)",
                  userDN, rc, ldap_err2string(rc));
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
      }
      goto exit;
   }

   if(pCfg->isSaslBindOn)
   {
      // Bind was successful, and we are in SASL bind mode.
      // Get the returned controls so we can check if the password was expired 
      rc = ldap_get_bind_controls( ld_auth, &returnedControls );

      if( rc != LDAP_SUCCESS )
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
                  "unexpected error retrieving LDAP controls \nldaprc=%d (%s)",
                  rc, ldap_err2string(rc));
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_UNKNOWNERROR;
         goto exit;
      }

      // If controls were returned, attempt to parse them for the password policy
      if( returnedControls != NULL )
      {
         ldap_parse_pwdpolicy_response(returnedControls, &controlerr, &controlwarn, &controlres);

         if( controlerr != LDAP_SUCCESS )
         {
            switch( controlerr )
            {
               case LDAP_CHANGE_AFTER_RESET:
               case LDAP_PASSWORD_EXPIRED:
                  rc = DB2SEC_PLUGIN_PWD_EXPIRED;
                  break;
               case LDAP_ACCOUNT_LOCKED:
                  rc = DB2SEC_PLUGIN_USER_SUSPENDED;
                  break;
               default:
                  snprintf(dumpMsg, sizeof(dumpMsg), "LDAP CheckPassword:\n"
                           "unexpected password policy response for user '%s'\ncontrolerr=%d (%s)",
                           userDN, controlerr, ldap_pwdpolicy_err2string(controlerr));
                  *errorMessage = strdup(dumpMsg);
                  rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            }
            goto exit;
         }
      }
   }

   /* Unbind the LDAP handle used for authentication. */
   ldap_unbind_s(ld_auth);
   ld_auth = NULL;


skip_bind:

   /* If we're on the server, set up the plugin token so
    * we can pass information into subsequent calls.
    * This reduces the number of LDAP queries.
    */
   if (token != NULL && connection_details & DB2SEC_VALIDATING_ON_SERVER_SIDE)
   {
      pluginToken = (token_t *)malloc(sizeof(token_t));

      /* If the malloc fails we proceed without a token */
      if (pluginToken != NULL)
      {
         memset(pluginToken,0,sizeof(token_t));
         strcpy(pluginToken->eyeCatcher, DB2LDAP_TOKEN_EYECATCHER);

         /* Copy the user DN into the token. */
         strcpy(pluginToken->userDN, userDN);

         /* Copy the authID as well, if we have it. */
         if (authID[0] != '\0')
         {
            strcpy(pluginToken->authid, authID);
            pluginToken->authidLen = strlen(authID);
         }

         /* Store the LDAP handle in the token and prevent it from
          * being freed below.  We'll reuse this to get the AuthID
          * and retreive the groups.  It will eventually be cleaned
          * up in FreeToken.
          */
         pluginToken->ld = ld;
         ld = NULL;

         *token = pluginToken;
      }
   }

   rc = DB2SEC_PLUGIN_OK;

exit:
   if (*errorMessage != NULL)
   {
      *errorMessageLength = (db2int32)strlen(*errorMessage);
      if (pCfg->debug)
         db2LogFunc(DB2SEC_LOG_WARNING, *errorMessage, *errorMessageLength);
   }

   if (ld      != NULL)  ldap_unbind_s(ld);
   if (ld_auth != NULL)  ldap_unbind_s(ld_auth);
   if (returnedControls != NULL) ldap_controls_free(returnedControls);
   if (bindControls != NULL) ldap_controls_free(bindControls);
   if (serverCreds != NULL) ber_bvfree(*serverCreds);

   return(rc);
}

