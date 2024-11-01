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
** SOURCE FILE NAME: IBMLDAPconfig.c
**
** SAMPLE: Functions related to finding and parsing the configuration
**         file for the DB2 LDAP security plugin.
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
#include <stdio.h>

#if defined(SQLUNIX)
#include <pwd.h>
#include <errno.h>
#endif

#include "IBMLDAPutils.h"

static int db2ldapGetDefaultConfigPath(char *, int, char **);
static int db2ldapGetConfigLine(FILE *, int *, char *, int);
static int db2ldapParseCfgLine(char *, char **, char **);

#define CFGLINE_OKAY           0
#define CFGLINE_FGETS_FAILED   1
#define CFGLINE_TOO_LONG       2



#define ProcessKeyVal(CURVAL, MAXSZ) \
{  if (CURVAL[0] != '\0')  \
   {  \
      snprintf(dumpMsg, sizeof(dumpMsg), \
          "db2ldapReadConfig: duplicate key value for %s on line %d of %s", \
          key, linenum, cfgfn);  \
      *errorMessage = strdup(dumpMsg);  \
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;  \
      goto exit;  \
   }  \
   if (strlen(value) > MAXSZ)  \
   {  \
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: " \
          "line %d of %s\nvalue for key '%s' is too long (%d bytes, max %d)\n" \
          "value='%s'", \
          linenum, cfgfn, key, (int)strlen(value), MAXSZ, value); \
      *errorMessage = strdup(dumpMsg);  \
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;  \
      goto exit;  \
   }  \
   strcpy(CURVAL,value);  \
}

#define ProcessKeyBool(CURVAL) \
{  if (CURVAL != -1) \
   { \
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: " \
               "duplicate key value for %s on line %d of %s", \
               key, linenum, cfgfn); \
      *errorMessage = strdup(dumpMsg); \
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS; \
      goto exit; \
   } \
   if (strcasecmp(value, "true") == 0) \
      CURVAL = TRUE; \
   else if (strcasecmp(value, "false") == 0) \
      CURVAL = FALSE; \
   else \
   { \
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: " \
               "bad value '%s' for key '%s' on line %d of %s", \
               value, key, linenum, cfgfn); \
      *errorMessage = strdup(dumpMsg); \
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS; \
      goto exit; \
   } \
}

#define VerifyCfg(VAL, KEY) \
{  if (VAL[0] == '\0') \
   { \
      snprintf(dumpMsg, sizeof(dumpMsg), \
               "db2ldapReadConfig: no value for key '%s' found in %s", \
               KEY, cfgfn);  \
      *errorMessage = strdup(dumpMsg);  \
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;  \
      goto exit;  \
   } \
}


/* db2ldapReadConfig
 *
 * Find and parse the LDAP plugin configuration file.  Store the
 * configuration data in the structure pointed to by "cfg".
 *
 * Returns
 *   DB2SEC_PLUGIN_OK
 *   DB2SEC_PLUGIN_FILENOTFOUND          -- Can't locate config file
 *   DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS  -- Syntax error parsing config
 */
int db2ldapReadConfig(pluginConfig_t *cfg,
                      int             types,            /* Bitmask */
                      char          **errorMessage)
{
   int rc = DB2SEC_PLUGIN_OK;
   FILE *fp = NULL;
   int  linenum;
   char fnbuf[CFG_MAX_FILENAME];
   char *cp = NULL;
   char buf[CFG_MAX_LINE_LEN];
   char *key = NULL;
   char *value = NULL;
   char dumpMsg[MAX_ERROR_MSG_SIZE];
   char *cfgfn = NULL;

   /* Find the config file */
#ifdef SQLUNIX
   /* UNIX / Linux */
   cfgfn = getenv(DB2LDAP_ENV_CFGFILE);
#else
   /* Windows */
   DWORD fnlen;
   fnlen = GetEnvironmentVariable(DB2LDAP_ENV_CFGFILE, fnbuf, sizeof(fnbuf));
   if (fnlen == 0)
   {
      cfgfn = NULL;  /* fall through to the code below */
   }
   else if (fnlen > sizeof(fnbuf))
   {
      /* Found the variable, but it's too large. */
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
               "value for environment variable %s is too long",
               DB2LDAP_ENV_CFGFILE);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }
   else
   {
      cfgfn = fnbuf;
   }
#endif

   if (cfgfn == NULL)
   {
      rc = db2ldapGetDefaultConfigPath(fnbuf, sizeof(fnbuf), errorMessage);
      if (rc != DB2SEC_PLUGIN_OK) goto exit;
      cfgfn = fnbuf;
   }

   fp = fopen(cfgfn, "r");
   if (fp == NULL)
   {
      snprintf(dumpMsg, sizeof(dumpMsg),
               "db2ldapReadConfig: can't open config file '%s'", cfgfn);
      *errorMessage = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_FILENOTFOUND;
      goto exit;
   }


   memset(cfg, 0, sizeof(*cfg));
   cfg->groupLookupMethod = -1; /* So we can detect duplicte lines */
   cfg->nestedGroups    = -1;
   cfg->isSSL           = -1;
   cfg->debug           = -1;
   cfg->fipsMode        = -1;
   cfg->followReferrals = -1;
   cfg->securityProtocol = -1;
   cfg->isSaslBindOn    = -1;

   linenum = 0;
   while (1)
   {
      rc = db2ldapGetConfigLine(fp, &linenum, buf, sizeof(buf));
      if (rc == CFGLINE_TOO_LONG)
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig:\n"
                  "line %d is too long (max %d including trailing NULL and "
                  "CR/LF)\nconfig file: %s",
                  linenum, CFG_MAX_LINE_LEN, cfgfn);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
         goto exit;
      }
      else if (rc != CFGLINE_OKAY)
      {
         if (feof(fp))
         {
            rc = DB2SEC_PLUGIN_OK;
            break;
         }
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                  "error reading line %d of config file %s",
                  linenum, cfgfn);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
         goto exit;
      }

      rc = db2ldapParseCfgLine(buf, &key, &value);
      if (rc != 0)
      {
         snprintf(dumpMsg, sizeof(dumpMsg),
                  "db2ldapReadConfig: error parsing line %d of config file %s",
                  linenum, cfgfn);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
         goto exit;
      }


      /* Compare the key against the expected values */
      if (strcasecmp(key, CFGKEY_HOST) == 0)
      {
         ProcessKeyVal(cfg->ldapHost, CFG_MAX_HOST_SIZE);
      }
      else if (strcasecmp(key, CFGKEY_ENABLE_SSL) == 0)
      {
         ProcessKeyBool(cfg->isSSL);
      }
      else if (strcasecmp(key, CFGKEY_SSL_KEYFILE) == 0)
      {
         ProcessKeyVal(cfg->sslKeyfile, CFG_MAX_FILENAME);
      }
      else if (strcasecmp(key, CFGKEY_SSL_PW) == 0)
      {
         ProcessKeyVal(cfg->sslPwd, CFG_MAX_PSWD);
      }
      else if (strcasecmp(key, CFGKEY_SEARCH_DN) == 0)
      {
         ProcessKeyVal(cfg->searchDN, CFG_MAX_DN);
      }
      else if (strcasecmp(key, CFGKEY_SEARCH_PW) == 0)
      {
         ProcessKeyVal(cfg->searchPWD, CFG_MAX_PSWD);
      }
      else if (strcasecmp(key, CFGKEY_USER_BASEDN) == 0)
      {
         ProcessKeyVal(cfg->userBase, CFG_MAX_DN);
      }
      else if (strcasecmp(key, CFGKEY_USERID_ATTRIBUTE) == 0)
      {
         ProcessKeyVal(cfg->useridAttr, CFG_MAX_ATTR);
      }
      else if (strcasecmp(key, CFGKEY_AUTHID_ATTRIBUTE) == 0)
      {
         ProcessKeyVal(cfg->authidAttr, CFG_MAX_ATTR);
      }
      else if (strcasecmp(key, CFGKEY_USER_OBJECTCLASS) == 0)
      {
         ProcessKeyVal(cfg->userObjClass, CFG_MAX_ATTR);
      }
      else if (strcasecmp(key, CFGKEY_GROUP_BASEDN) == 0)
      {
         ProcessKeyVal(cfg->groupBase, CFG_MAX_DN);
      }
      else if (strcasecmp(key, CFGKEY_GROUP_OBJECTCLASS) == 0)
      {
         ProcessKeyVal(cfg->groupObjClass, CFG_MAX_ATTR);
      }
      else if (strcasecmp(key, CFGKEY_GROUP_LOOKUP_ATTRIBUTE) == 0)
      {
         ProcessKeyVal(cfg->groupLookupAttr, CFG_MAX_ATTR);
      }
      else if (strcasecmp(key, CFGKEY_GROUPNAME_ATTRIBUTE) == 0)
      {
         ProcessKeyVal(cfg->groupNameAttr, CFG_MAX_ATTR);
      }
      else if (strcasecmp(key, CFGKEY_NESTED_GROUPS) == 0)
      {
         ProcessKeyBool(cfg->nestedGroups);
      }
      else if (strcasecmp(key, CFGKEY_GROUP_LOOKUP_METHOD) == 0)
      {
         if (cfg->groupLookupMethod != -1)
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                     "duplicate key value for %s on line %d of %s",
                     key, linenum, cfgfn);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
            goto exit;
         }

         if (strcasecmp(value, GROUP_METHOD_STR_USER_ATTR) == 0)
         {
            cfg->groupLookupMethod = GROUP_METHOD_USER_ATTR;
         }
         else if (strcasecmp(value, GROUP_METHOD_STR_SEARCH_BY_DN) == 0)
         {
            cfg->groupLookupMethod = GROUP_METHOD_SEARCH_BY_DN;
         }
         else
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                     "bad value '%s' for key '%s' on line %d of %s",
                     value, key, linenum, cfgfn);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
            goto exit;
         }
      }
      else if (strcasecmp(key, CFGKEY_FOLLOW_REFERRALS) == 0)
      {
         ProcessKeyBool(cfg->followReferrals);
      }
      else if (strcasecmp(key, CFGKEY_DEBUG) == 0)
      {
         ProcessKeyBool(cfg->debug);
      }
      else if (strcasecmp(key, CFGKEY_FIPS_MODE) == 0)
      {
         if (cfg->fipsMode != -1)
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                     "duplicate key value for %s on line %d of %s",
                     key, linenum, cfgfn);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
            goto exit;
         }

         if (strcasecmp(value, FIPS_MODE_STR_ON) == 0)
         {
            cfg->fipsMode = FIPS_MODE_ON;
         }
         else if (strcasecmp(value, FIPS_MODE_STR_OFF) == 0)
         {
            cfg->fipsMode = FIPS_MODE_OFF;
         }
         else if (strcasecmp(value, FIPS_MODE_STR_STRICT) == 0)
         {
            cfg->fipsMode = FIPS_MODE_STRICT;
         }
         else
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                     "bad value '%s' for key '%s' on line %d of %s",
                     value, key, linenum, cfgfn);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
            goto exit;
         }
      }
      else if (strcasecmp(key, CFGKEY_SECURITY_PROTOCOL) == 0)
      {
         if (cfg->securityProtocol != -1)
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                     "duplicate key value for %s on line %d of %s",
                     key, linenum, cfgfn);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
            goto exit;
         }

         if (strcasecmp(value, SECURITY_PROTOCOL_STR_ALL) == 0)
         {
            cfg->securityProtocol = SECURITY_PROTOCOL_ALL;
         }
         else if (strcasecmp(value, SECURITY_PROTOCOL_STR_TLS12) == 0)
         {
            cfg->securityProtocol = SECURITY_PROTOCOL_TLS12;
         }
         else
         {
            snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                     "bad value '%s' for key '%s' on line %d of %s",
                     value, key, linenum, cfgfn);
            *errorMessage = strdup(dumpMsg);
            rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
            goto exit;
         }
      }
      else if (strcasecmp(key, CFGKEY_SSL_EXTN_SIGALG) == 0)
      {
         ProcessKeyVal(cfg->sslExtnSigAlg, CFG_MAX_EXTN_SIGALG);
      }
      else if (strcasecmp(key, CFGKEY_SASL_BIND) == 0)
      {
         ProcessKeyBool(cfg->isSaslBindOn);
      }
      else
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                  "unknown key value '%s' on line %d of %s",
                  key, linenum, cfgfn);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
         goto exit;
      }

   } /* end config read loop */


   /* Check that we have all mandatory values */
   VerifyCfg(cfg->ldapHost, CFGKEY_HOST);
   VerifyCfg(cfg->userObjClass, CFGKEY_USER_OBJECTCLASS);
   VerifyCfg(cfg->authidAttr, CFGKEY_AUTHID_ATTRIBUTE);

   if (types & CFG_USERAUTH)
   {
      VerifyCfg(cfg->useridAttr, CFGKEY_USERID_ATTRIBUTE);
   }

   if (types & CFG_GROUPLOOKUP)
   {
      VerifyCfg(cfg->groupObjClass, CFGKEY_GROUP_OBJECTCLASS);
      VerifyCfg(cfg->groupLookupAttr, CFGKEY_GROUP_LOOKUP_ATTRIBUTE);
      VerifyCfg(cfg->groupNameAttr, CFGKEY_GROUPNAME_ATTRIBUTE);

      if (cfg->groupLookupMethod == -1)
      {
         snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapReadConfig: "
                  "a value must be specified for %s in %s",
                  CFGKEY_GROUP_LOOKUP_METHOD, cfgfn);
         *errorMessage = strdup(dumpMsg);
         rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
         goto exit;
      }
   }


   /* Do we have a searchDN?
    * Note that we don't check for a password... it might be valid
    * not to specify one, and we don't want to try to be too clever.
    */
   if (cfg->searchDN[0] != '\0')
   {
     cfg->haveSearchDN = TRUE;
   }

   /* Optional boolean defaults. */
   if (-1 == cfg->nestedGroups   ) cfg->nestedGroups    = FALSE;
   if (-1 == cfg->isSSL          ) cfg->isSSL           = FALSE;
   if (-1 == cfg->debug          ) cfg->debug           = FALSE;
   if (-1 == cfg->fipsMode       ) cfg->fipsMode        = FIPS_MODE_ON;
   if (-1 == cfg->followReferrals) cfg->followReferrals = TRUE;
   if (-1 == cfg->isSaslBindOn   ) cfg->isSaslBindOn    = FALSE;

exit:
   if (fp != NULL) fclose(fp);

   return(rc);
}


/* db2ldapGetDefaultConfigPath
 *
 * Figure out where the instance "cfg" directory is located.
 *
 * It would be nice if this was available from the ConDetails :-/
 */
static int db2ldapGetDefaultConfigPath(char  *buf,
                                       int    bufsz,
                                       char **errorMsg)
{
   int rc = DB2SEC_PLUGIN_OK;
   char dumpMsg[MAX_ERROR_MSG_SIZE];

#if defined(SQLWINT)
   DWORD len;
   char instpath[MAX_ERROR_MSG_SIZE];
#elif defined(SQLUNIX)
   char *cp = NULL;
   char pwnam_buf[256];
   struct passwd pwd, *pwp = NULL;
   int en;
#endif

#if defined(SQLWINT)
   /* On Windows the path to the DB2 instance files is in DB2PATH */
   len = GetEnvironmentVariableA("DB2PATH", instpath, sizeof(instpath));
   if (len == 0)
   {
      *errorMsg = strdup("db2ldapGetDefaultConfigPath: DB2PATH not set");
      rc = DB2SEC_PLUGIN_FILENOTFOUND;
      goto exit;
   }
   else if (len > sizeof(instpath))
   {
      /* Found the variable, but it's too large. */
      *errorMsg =
           strdup("db2ldapGetDefaultConfigPath: value for DB2PATH is too long");
      rc = DB2SEC_PLUGIN_BAD_INPUT_PARAMETERS;
      goto exit;
   }

   snprintf(buf, bufsz, "%s%s", instpath, DB2LDAP_CFGDFLT_WIN);

#elif defined(SQLUNIX)
   /* On UNIX, we need to get the home directory for the */
   /* username in the DB2INSTANCE environment variable.  */
   cp = getenv("DB2INSTANCE");
   if (cp == NULL || *cp == '\0')
   {
      *errorMsg = strdup("db2ldapGetDefaultConfigPath: DB2INSTANCE not set");
      rc = DB2SEC_PLUGIN_FILENOTFOUND;
      goto exit;
   }

   rc = getpwnam_r(cp, &pwd, pwnam_buf, sizeof(pwnam_buf), &pwp);

   en = errno;

   if (rc != 0)
   {
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetDefaultConfigPath: "
               "getpwnam_r failed for user %s, errno=%d", cp, en);
      *errorMsg = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_FILENOTFOUND;
      goto exit;
   }

   if (pwp->pw_dir == NULL || pwp->pw_dir[0] == '\0')
   {
      snprintf(dumpMsg, sizeof(dumpMsg), "db2ldapGetDefaultConfigPath: "
               "no home directory for user %s from getpwnam_r", cp);
      *errorMsg = strdup(dumpMsg);
      rc = DB2SEC_PLUGIN_FILENOTFOUND;
      goto exit;
   }

   snprintf(buf, bufsz, "%s%s", pwp->pw_dir, DB2LDAP_CFGDFLT_UNIX);

#else
#error Must define platform
#endif

exit:
   return(rc);
}


static void strip(char *buf)
{
   char *cp = buf;
   int len;

   /* Strip leading whitespace */
   while (*cp == ' ' || *cp == '\t') cp++;
   if (cp != buf)
   {
     memmove(buf, cp, strlen(cp) + 1);
   }

   /* Strip trailing whitespace */
   len = strlen(buf) - 1;
   while ((len >= 0) &&
         (buf[len] == ' '  || buf[len] == '\t' ||
          buf[len] == '\r' || buf[len] == '\n'))
   {
     buf[len--] = '\0';
   }
}


/* db2ldapGetConfigLine
 *
 * Read a single line.  Strip leading/trailing whitespace.
 */
static int db2ldapGetConfigLine(FILE *fp,
                                int  *linenum,
                                char *buf,
                                int   bufsz)
{
   int rc = CFGLINE_OKAY;
   int len;
   char *cp;

   do {
      cp = fgets(buf, bufsz, fp);
      if (cp == NULL)
      {
         rc = CFGLINE_FGETS_FAILED;
         goto exit;
      }

      (*linenum)++;

      /* If the line filled the buffer, the last character must
       * be '\n' (possibly '\r') or the line was too long.
       */
      len = strlen(buf);
      if ((len + 1) == bufsz)
      {
         len--;
         if (buf[len] != '\n' && buf[len] != '\r')
         {
            rc = CFGLINE_TOO_LONG;
            goto exit;
         }
      }

      /* Truncate the line at the first ";", if any. */
      cp = strchr(buf, ';');
      if (cp != NULL)
         *cp = '\0';


      /* Strip whitespace */
      strip(buf);
      
   } while(buf[0] == '\0');

exit:
   return(rc);
}


/* db2ldapParseCfgLine
 *
 * Parse the input config line, which should look like "key = value".
 * Leading and trailing space are striped from both the key and the
 * value.
 *
 * Returns 0 (success) or -1 (failure).
 */
static int db2ldapParseCfgLine(char  *input,
                               char **key,
                               char **value)
{
   int rc = 0;
   char *cp;

   /* All valid config lines have at least one "=".  Find it. */
   cp = strchr(input, '=');
   if (cp == NULL) 
   {
      rc = -1;
      goto exit;
   }

   *cp = '\0';
   *key = input;
   *value = cp + 1;

   strip(*key);
   strip(*value);

exit:
   return(rc);
}
