/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2004
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*****************************************************************************
**
** SOURCE FILE NAME: combined.c
**
** SAMPLE: Combined userid/password authentication and group lookup sample
**
** This single source files implements both the client and server pieces
** of a simple, file-based userid/password authentication scheme as well
** as file-based group management.
**
** When built, a single loadable object is created (see the makefile).
** However, because DB2 treats server-side authentication, client-side
** authentication and group management as separate plugins, the single
** loadable object must be copied into three different directories
** and the three related database manager configuration parameters
** updated accordingly.  For example, on 32-bit UNIX platforms the
** loadable object should be copied into the following directories:
**   .../sqllib/security32/plugin/server
**   .../sqllib/security32/plugin/client
**   .../sqllib/security32/plugin/group
**
** To enable the plugin the following DBM Configuration parameters must
** also be updated to the name of the loadable object, minus any extension
** (ie, to "combined"):
**   SRVCON_PW_PLUGIN, CLNT_PW_PLUGIN, and GROUP_PLUGIN
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>

#include "sqlenv.h"
#include "db2secPlugin.h"

#if defined DB2_PLAT_UNIX
#include <unistd.h>
#include <sys/types.h>
#if defined USE_CRYPT
#include <crypt.h>
#endif
#include <pwd.h>
#define USE_UNIX_UID_LOOKUP
#else
#define strcasecmp(a,b) stricmp(a,b)
#define snprintf _snprintf
#endif

#if defined db2Is64bit || defined DB2_FORCE_INT32_TYPES_TO_INT
   #define FMT_S32 "%d"
#else
   #define FMT_S32 "%ld"
#endif

db2secLogMessage *logFunc = NULL;
const char * getUserFileName() ;

/* THE USER DEFINITION FILE
 * Userid, password and group information is located in a single
 * file defined by "USER_FILENAME".
 *
 * This file consists of one line per user with the following
 * whitespace separated fields on each line:
 *
 *   username  password  [ group1  [group2 ... ] ]
 *
 * The username and password are mandatory.  Groups are optional.
 * Lines that begin with "#" are comments.  Blank lines are ignored.
 * Note that usernames, passwords, and group names may not
 * contain whitespace (this limitation is specific to this particular
 * plugin implementation, not to DB2 in general).
 *
 * The passwords in this file are in clear text.  For demonstration
 * purposes, conditional code (USE_CRYPT) is available for non-cleartext
 * authentication.  Note that this does not imply that this authentication
 * code is secure.  For instance if the file is globally readable, this
 * authentication mechanism will suffer from succeptability to
 * password cracking and dictionary lookup methods.
 *
 * If USE_CRYPT is enabled, then the password is a standard unix crypt (3)
 * based password.  One can generate this for example with something like
 * the following perl code:
 *
 * my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64] ;
 * my $cryptedText = crypt($clearText, $salt) ;
 *
 * The maximum line length for this file is 1024 characters; lines longer than
 * this value will result in undefined behavior.  User and group
 * names are limited to SQL_AUTH_IDENT bytes, passwords are limited
 * to DB2SEC_MAX_PASSWORD_LENGTH bytes.  Lines containing longer
 * fields will result in an error.
 */
#if 0
/*
 * Examples of the sorts of paths that could be used.  These would
 * normally be defined in the makefile instead of hardcoded.
 */
#if !defined WIN32
#define USER_FILENAME   "/home/db2inst1/sqllib/SamplePluginUsers"
#else
#define USER_FILENAME   "D:\\sqllib\\DB2\\SamplePluginUsers"
#endif
#endif

#if defined USER_FILENAME
const char * getUserFileName()
{
   return USER_FILENAME ;
}
#endif

/* The internal max line length includes room for a line
 * separator (CR/LF on Windows, LF on UNIX) and a NULL byte.
 */
#define MAX_LINE_LENGTH     1027

#define SQL_AUTH_IDENT      128


/*-------------------------------------------------------
 * Functions to read & parse the user definition file
 *-------------------------------------------------------*/

/*
 * NextField()
 * Return a pointer to the next whitespace separated token in the input
 * string.  Skips over any leading whitespace.  A NULL byte is written
 * to the string after the token.
 *
 * The "nextString" output parameter can be used on the next call to
 * this function to retrieve the next token, if any.
 *
 * Returns NULL if no more tokens exist in the input string.
 * The orginal input string must be NULL terminated.
 */
char *NextField(char *inputString, char **nextString)
{
    char *returnString = NULL;
    char *cptr;

    if (nextString != NULL)
    {
        *nextString = NULL;
    }

    cptr = inputString;

    /* If the input string is NULL or zero length, return NULL. */
    if (cptr == NULL || *cptr == '\0')
    {
        goto exit;
    }

    /* Skip any leading whitespace */
    while (*cptr == ' ' || *cptr == '\t')
    {
        cptr++;
    }

    /* If we reach the end of the string return NULL. */
    if (*cptr == '\0')
    {
        goto exit;
    }

    /* Found a non-whitespace, non-NULL character.  This is the
     * start of the string that we'll return.
     */
    returnString = cptr;


    /* Now we need to NULL terminate this token and set up nextString */
    cptr++;
    while (*cptr != '\0')
    {
        if (*cptr == ' ' || *cptr == '\t')
        {
            /* Whitespace */
            *cptr = '\0';           /* NULL terminate */

            if (nextString != NULL)
            {
                /* nextString starts with the character following
                 * the NULL byte we just inserted.
                 */
                *nextString = cptr + 1;
            }
            goto exit;      /* We're done */
        }
        cptr++;
    }

    /* If we get here we've reached the end of the inputString. */
    if (nextString != NULL)
    {
        *nextString = NULL;
    }

exit:
    return(returnString);
} /* NextField */


/* GetNextLine()
 * Returns a pointer to a string containing the next non-blank,
 * non-comment line from the input file.  A comment line is one
 * where "#" is the first non-whitespace character.  Leading
 * whitespace is stripped from the returned string, as are trailing
 * "\n" or "\r\n" sequences.
 *
 * "buf" and "bufLength" refer to a caller-supplied buffer used
 * to hold the information read from the file.
 *
 * NULL is returned on EOF or error; the caller should use
 * feof() and/or ferror() to determine which has occured.
 *
 * (char*)-1 is returned if an input line is encounted that doesn't
 * fit into the supplied buffer.
 */
char *GetNextLine(FILE *fp, char *buf, int bufLength)
{
    char *returnPtr = NULL;
    char *cptr;
    int length;

    /* Loop until we find a valid line */
    while (returnPtr == NULL) {

        cptr = fgets(buf, bufLength - 1, fp);
        if (cptr == NULL)
        {
            /* EOF or error, return NULL */
            goto exit;
        }

        /* Strip trailing CR/NL bytes */
        length = strlen(cptr) - 1;
        while (cptr[length] == '\n' || cptr[length] == '\r')
        {
            cptr[length] = '\0';
            length--;
        }

        /* Skip over any leading whitespace */
        while (*cptr != '\0' && (*cptr == ' ' || *cptr == '\t'))
        {
            cptr++;
        }

        /* If we didn't reach the end of the string and the first
         * character is not '#', then return the line. Otherwise
         * read the next line from the file.
         */
        if (*cptr != '\0' && *cptr != '#')
        {
            returnPtr = cptr;
        }
    }

exit:
    return(returnPtr);
}


/* FindUser()
 * Open the indicated file and find the first line where the first
 * field matches the provided username.  Optionally return the
 * second field (password) and/or parse the remaining fields
 * (groups) into a non-NULL terminated, length-prefixed sequence
 * of strings (see below).
 *
 * The caller must supply a read buffer for use when processing
 * the file.
 *
 * Leading and trailing whitesapce is stripped from the password
 * and all group names.
 *
 * Returns:  0 for success,
 *          -1 if the user was not found
 *          -2 on error, *errorMessage will be set to a static C
 *             string describing the error.
 *
 * If groups are requested, the supplied group buffer must be at
 * least as large as the supplied read buffer.  The groups are
 * written into that buffer in the following format:
 *   <one byte length><group string><one byte length><group string>...
 * and *numGroups is set to indicate how many groups were written
 * to the group buffer.  Note that the group name strings are not
 * NULL terminated.
 */
int FindUser(const char *fileName,  /* File to read                */
             const char *userName,  /* Who we're looking for       */
             char *readBuffer,      /* Caller-supplied read buffer */
             int readBufferLength,
             char **passwordPtr,    /* Output: password            */
             char *groupBuffer,     /* Output: group list          */
             int *numGroups,        /* Output: number of groups    */
             char **errorMessage)   /* Static C string for errors  */
{
    int rc = -1;
    int foundUser = 0;              /* Found the user yet?          */

    int groupCount = 0;
    int length;
    char *linePtr;
    char *field;
    char *nextPtr;
    char *cptr;
    char *errMsg = NULL;            /* Temp local error message */
    FILE *fp = NULL;

    if (userName == NULL)
    {
        errMsg = "NULL user name supplied";
        rc = -2;
        goto exit;
    }

    if (readBuffer == NULL)
    {
        errMsg = "NULL read buffer supplied";
        rc = -2;
        goto exit;
    }

    if (passwordPtr != NULL)
    {
        *passwordPtr = NULL;
    }

    if (numGroups != NULL)
    {
        *numGroups = 0;
    }


    fp = fopen(fileName,"r");
    if (fp == NULL) {
        errMsg = "Cannot open specified file\n";
        rc = -2;
        goto exit;
    }


    while (foundUser == 0)
    {
        linePtr = GetNextLine(fp, readBuffer, readBufferLength);
        if (linePtr == (char*)-1)
        {
            /* Line length error */
            errMsg = "Encountered an invalid input line in file";
            rc = -2;
            goto exit;
        }
        if (linePtr == NULL)
        {
            /* We've probably reached the end of file, but make sure. */
            if (feof(fp))
            {
                /* End of file: User not found. */
                rc = -1;
            }
            else
            {
                /* Not end of file, must have encountered an error. */
                rc = -2;
                errMsg = "Unknown file error encountered";
            }
            goto exit;
        }

        field = NextField(linePtr, &nextPtr);
        if (field != NULL && strcasecmp(field, userName) == 0)
        {
            /* Found the correct user name.  Parse the line. */
            foundUser = 1;

            /* Second field is the password */
            field = NextField(nextPtr, &nextPtr);

            /* A blank password field is an error. */
            if (field == NULL)
            {
                errMsg = "No password for user";
                rc = -2;
                goto exit;
            }
            if (passwordPtr != NULL)
            {
                *passwordPtr = field;
            }

            /* If we were requested to return group information,
             * parse the rest of the line.
             */
            if (groupBuffer != NULL)
            {
                cptr = groupBuffer;

                field = NextField(nextPtr, &nextPtr);
                while (field != NULL)
                {
                    length = strlen(field);

                    if (length > 255)
                    {
                        /* Since the group list is formatted using
                         * one byte lengths, a length of more than 255
                         * bytes is an error.
                         */
                        errMsg = "group name too long";
                        rc = -2;
                        goto exit;
                    }

                    *((unsigned char*)cptr) = (unsigned char)length;
                    cptr++;

                    memcpy(cptr, field, length);
                    cptr += length;

                    groupCount++;

                    field = NextField(nextPtr, &nextPtr);
                }

                /* Write a NULL byte after the last group; a
                 * "zero length group" indicates the end of the
                 * group list in case the caller did not supply
                 * "numGroups".
                 */
                *cptr = '\0';

                if (numGroups != NULL)
                {
                    *numGroups = groupCount;
                }
            }

            rc = 0;     /* Found the user */
        }
    }

exit:
    if (fp != NULL)
    {
        fclose(fp);
    }

    if (errMsg != NULL)
    {
        char msg[256];
        snprintf(msg, 256,
                 "security plugin 'combined' encountered an error\n"
                 "User: %s\nFile: %s\nError: %s\n",
                 userName, fileName, errMsg);
        msg[255]='\0';            /* ensure NULL terminated */
        logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

        if (errorMessage != NULL)
        {
            *errorMessage = errMsg;
        }
    }

    return(rc);
}


/*-------------------------------------------------------
 * Plugin functions
 *-------------------------------------------------------*/

/* CheckPassword()
 * Look up a user, check their password.
 *
 * If a domain name ("namespace") is specified it is appended to
 * the userid with an "@" separator (userid@domain) and that string
 * is then used for the file lookup.
 *
 * The maximum length for the userid (or userid@domain) is
 * SQL_AUTH_IDENT, since it will be returned as the DB2 Authorization
 * ID later.
 */
SQL_API_RC SQL_API_FN CheckPassword(const char *userid,
                         db2int32 useridLength,
                         const char *domain,
                         db2int32 domainLength,
                         db2int32 domainType,           /* ignored */
                         const char *password,
                         db2int32 passwordLength,
                         const char *newPassword,
                         db2int32 newPasswordLength,
                         const char *databaseName,      /* not used */
                         db2int32 databaseNameLength,   /* not used */
                         db2Uint32 connection_details,
                         void **token,                  /* not used */
                         char **errorMessage,
                         db2int32 *errorMessageLength)
{
    int rc = DB2SEC_PLUGIN_OK;
    int length;

    char user[SQL_AUTH_IDENT + 1];       /* User name (possibly with @domain) */
    char lineBuf[MAX_LINE_LENGTH];      /* For reading from the U/P file.    */
    char *passwordStringFromFile = NULL;

    char *cptr;

    *errorMessage = NULL;
    *errorMessageLength = 0;

    memset(user, '\0', SQL_AUTH_IDENT + 1);

    /* Check for a domain name, and make sure the userid length is ok. */
    if (domain != NULL && domainLength > 0)
    {
        if ( (useridLength + 1 + domainLength) > SQL_AUTH_IDENT )
        {
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
        }
        strncpy(user, userid, useridLength);
        strcat(user, "@");
        strncat(user, domain, domainLength);
    }
    else
    {
        if ( useridLength > SQL_AUTH_IDENT )
        {
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
        }
        strncpy(user, userid, useridLength);
    }

    /* Was a new password supplied? */
    if (newPassword != NULL && newPasswordLength > 0)
    {
        rc = DB2SEC_PLUGIN_CHANGEPASSWORD_NOTSUPPORTED;
        goto exit;
    }


    rc = FindUser(getUserFileName(),
                  user,             /* User we're looking for */
                  lineBuf,
                  sizeof(lineBuf),
                  &passwordStringFromFile,
                  NULL,             /* Don't want group info */
                  NULL,
                  errorMessage);
    if (rc == -2)
    {
        /* Unexpected error. */
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
    }
    else if (rc == -1)
    {
        /* User not found */
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
    }


    /* Check the password, if supplied. */
    if (password != NULL && passwordLength > 0)
    {
#if defined USE_CRYPT
        if (strlen(password) > 8)
        {
            /* Bad password. */
            rc = DB2SEC_PLUGIN_BADPWD;
        }
        else if (strlen(passwordStringFromFile) != 13)
        {
            /* Unexpected length for encrypted password in path specified by getUserFileName() (perhaps not encrypted). */
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        }
        else
        {
            char * recrypted = crypt(password, passwordStringFromFile);

            if (0 != strcmp(recrypted, passwordStringFromFile))
            {
                rc = DB2SEC_PLUGIN_BADPWD;
            }
        }
#else
        if ((strlen(passwordStringFromFile) != passwordLength) ||
            (strncmp(passwordStringFromFile, password, passwordLength) != 0))
        {
            /* Bad password. */
            rc = DB2SEC_PLUGIN_BADPWD;
        }
#endif
    }
    else
    {
        /* No password was supplied.  This is okay as long
         * as the following conditions are true:
         *
         *  - The username came from WhoAmI(), and
         *  - If we're on the server side, the connection must
         *    be "local" (originating from the same machine)
         *
         * Note that "DB2SEC_USERID_FROM_OS" means that the userid
         * was obtained from the plugin by calling the function
         * supplied for "db2secGetDefaultLoginContext".
         */
        if (!(connection_details & DB2SEC_USERID_FROM_OS) ||
            ((connection_details & DB2SEC_VALIDATING_ON_SERVER_SIDE) &&
             !(connection_details & DB2SEC_CONNECTION_ISLOCAL)))
        {
            /* Of of the conditions was not met, fail. */
            rc = DB2SEC_PLUGIN_BADPWD;
        }
    }

exit:
    if (*errorMessage != NULL)
    {
        *errorMessageLength = strlen(*errorMessage);
    }

    return(rc);
}


/* GetAuthIDs()
 * Return the username (possibly with the domain name appended) to
 * DB2 as both the System Authentication ID and the Initial Session
 * Authorization ID.
 */
SQL_API_RC SQL_API_FN GetAuthIDs(const char *userid,
                      db2int32 useridLength,
                      const char *domain,
                      db2int32 domainLength,
                      db2int32 domainType,              /* not used */
                      const char *databaseName,         /* not used */
                      db2int32 databaseNameLength,      /* not used */
                      void **token,                     /* not used */
                      char systemAuthID[],
                      db2int32 *systemAuthIDLength,
                      char sessionAuthID[],
                      db2int32 *sessionAuthIDLength,
                      char username[],
                      db2int32 *usernameLength,
                      db2int32 *sessionType,
                      char **errorMessage,
                      db2int32 *errorMessageLength)
{
    int rc = DB2SEC_PLUGIN_OK;
    int length;
    char user[SQL_AUTH_IDENT + 1];       /* User name (possibly with @domain) */

    *errorMessage = NULL;
    *errorMessageLength = 0;

    memset(user, '\0', sizeof(user));

    /* Check for a domain name, and make sure the userid length is ok. */
    if (domain != NULL && domainLength > 0)
    {
        if ( (useridLength + 1 + domainLength) > SQL_AUTH_IDENT )
        {
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
        }
        strncpy(user, userid, useridLength);
        strcat(user, "@");
        strncat(user, domain, domainLength);
    }
    else
    {
        if ( useridLength > SQL_AUTH_IDENT )
        {
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
        }
        strncpy(user, userid, useridLength);
    }

    length = strlen(user);

    memcpy(systemAuthID, user, length);
    *systemAuthIDLength = length;
    memcpy(sessionAuthID, user, length);
    *sessionAuthIDLength = length;
    *sessionType = 0;               /* TBD ?! */
    memcpy(username, user, length);
    *usernameLength = length;

exit:
    return(rc);
}


/* DoesAuthIDExist()
 * Determine if the supplied DB2 Authorization ID is associated with
 * a valid user.
 *
 * Since this plugin derives the authorization ID directly from the
 * username (possibly with the domain name appended), this function
 * simply needs to determine if the given Auth ID exists in the User
 * definition file.
 */
SQL_API_RC SQL_API_FN DoesAuthIDExist(const char *authID,
                           db2int32 authIDLength,
                           char **errorMessage,
                           db2int32 *errorMessageLength)
{
    int rc;
    char lineBuf[MAX_LINE_LENGTH];
    char localAuthID[SQL_AUTH_IDENT + 1];

    *errorMessage = NULL;
    *errorMessageLength = 0;

    /* NULL terminate the authID */
    if (authIDLength > SQL_AUTH_IDENT)
    {
        char msg[512];
        memcpy(localAuthID, authID, SQL_AUTH_IDENT);
        localAuthID[SQL_AUTH_IDENT] = '\0';
        snprintf(msg, 512,
             "DoesAuthIDExist: authID too long ("FMT_S32" bytes): %s... (truncated)",
             authIDLength, localAuthID);

        msg[511]='\0';            /* ensure NULL terminated */
        logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

        *errorMessage = "DoesAuthIDExist: authID too long";
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
    }

    memcpy(localAuthID, authID, authIDLength);
    localAuthID[authIDLength] = '\0';


    rc = FindUser(getUserFileName(),
                  localAuthID,      /* User we're looking for */
                  lineBuf,
                  sizeof(lineBuf),
                  NULL,             /* Don't want the password */
                  NULL,             /* Don't want group info   */
                  NULL,
                  errorMessage);
    if (rc == -2)
    {
        /* Unexpected error. */
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
    }
    else if (rc == -1)
    {
        /* User not found */
        rc = DB2SEC_PLUGIN_INVALIDUSERORGROUP;
        goto exit;
    }
    else
    {
        /* Found the user */
        rc = DB2SEC_PLUGIN_OK;
    }

exit:
    if (*errorMessage != NULL)
    {
        *errorMessageLength = strlen(*errorMessage);
    }
    return(rc);
}

#if defined USE_UNIX_UID_LOOKUP
static SQL_API_RC getUsername(
                  const uid_t uid,
                  char * const userName,
                  db2int32 * const userNameLength,
                  char ** errorMessage)
{
   int err ;
   SQL_API_RC rc = 0 ;
   struct passwd * pResult ;
   struct passwd   passwordData = { 0 } ;
   size_t bufSize = sysconf(_SC_GETPW_R_SIZE_MAX) ;
   char * buf = malloc(bufSize) ;
#if 0
   FILE * o = fopen("/tmp/auth", "a") ;
#endif

   if (!buf)
   {
      goto MALLOC_FAILED ;
   }

   err = getpwuid_r( uid,
                     &passwordData,
                     buf,
                     bufSize,
                     &pResult ) ;
   if (err)
   {
      goto GETPWUID_FAILED ;
   }

   *userNameLength = strlen(pResult->pw_name) ;

   if (*userNameLength > SQL_AUTH_IDENT)
   {
      goto NAME_TOO_LONG ;
   }

   strcpy(userName, pResult->pw_name) ;
   free(buf) ;

FINAL_EXIT:

#if 0
   if (o)
   {
      fprintf(o, "uid: %d ; n: %s\n", uid, userName) ;
      fclose(o) ;
   }
#endif

   return 0 ;

ERROR_EXIT:

   if (buf)
   {
      free(buf) ;
   }

   rc = DB2SEC_PLUGIN_BADUSER ;

   goto FINAL_EXIT ;

GETPWUID_FAILED:
   *errorMessage = "getpwuid_r failed" ;
   goto ERROR_EXIT ;

NAME_TOO_LONG:
   *errorMessage = "User name too long";
   goto ERROR_EXIT ;

MALLOC_FAILED:
   *errorMessage = "malloc failed" ;
   goto ERROR_EXIT ;
}
#endif

/* WhoAmI()
 * Determine the default user identity associated with the current
 * process context.
 *
 * For simplicity this plugin returns the string found in the
 * DB2DEFAULTUSER environment variable, or an error if that variable
 * is undefined.
 */
SQL_API_RC SQL_API_FN WhoAmI(char authID[],
                  db2int32 *authIDLength,
                  char userid[],
                  db2int32 *useridLength,
                  db2int32 useridType,              /* ignored */
                  char domain[],
                  db2int32 *domainLength,
                  db2int32 *domainType,
                  const char *databaseName,         /* not used */
                  db2int32 databaseNameLength,      /* not used */
                  void **token,                     /* not used */
                  char **errorMessage,
                  db2int32 *errorMessageLength)
{
    int rc = DB2SEC_PLUGIN_OK;

    *errorMessage = NULL;
    *errorMessageLength = 0;

    authID[0] = '\0';
    *authIDLength = 0;
    userid[0] = '\0';
    *useridLength = 0;
    domain[0] = '\0';
    *domainLength = 0;
    *domainType = DB2SEC_USER_NAMESPACE_UNDEFINED;

#if defined USE_UNIX_UID_LOOKUP
     if (DB2SEC_PLUGIN_REAL_USER_NAME == useridType)
     {
       rc = getUsername(getuid(), userid, useridLength, errorMessage);
       if ( rc )
       {
         goto exit;
       }
     }
     else
     {
       rc = getUsername(geteuid(), userid, useridLength, errorMessage);
       if ( rc )
       {
         goto exit;
       }
     }

     strcpy(authID, userid);
     *authIDLength = *useridLength;
#else
    {
        int length;
        char *user;

        user = getenv("DB2DEFAULTUSER");

        /* Check the length */
        if (user != NULL)
        {
            length = strlen(user);
            if (length > SQL_AUTH_IDENT)
            {
                *errorMessage = "Default user name (from DB2DEFAULTUSER) too long";
                rc = DB2SEC_PLUGIN_BADUSER;
                goto exit;
            }

            strcpy(authID, user);
            *authIDLength = length;
            strcpy(userid, user);
            *useridLength = length;
        }
        else
        {
            *errorMessage = "DB2DEFAULTUSER not defined";
            rc = DB2SEC_PLUGIN_BADUSER;
            goto exit;
        }
    }
#endif

exit:
    if (*errorMessage != NULL)
    {
        *errorMessageLength = strlen(*errorMessage);
    }

    return(rc);
}


/* LookupGroups()
 * Return the list of groups to which a user belongs.
 *
 * For this plugin this involves finding the provided authorization
 * ID in the User definition file and returning all fields after
 * the second.
 */
SQL_API_RC SQL_API_FN LookupGroups(const char *authID,
                        db2int32 authIDLength,
                        const char *userid,             /* ignored */
                        db2int32 useridLength,          /* ignored */
                        const char *domain,             /* ignored */
                        db2int32 domainLength,          /* ignored */
                        db2int32 domainType,            /* ignored */
                        const char *databaseName,       /* ignored */
                        db2int32 databaseNameLength,    /* ignored */
                        void *token,                    /* ignored */
                        db2int32 tokenType,             /* ignored */
                        db2int32 location,              /* ignored */
                        const char *authPluginName,     /* ignored */
                        db2int32 authPluginNameLength,  /* ignored */
                        void **groupList,
                        db2int32 *groupCount,
                        char **errorMessage,
                        db2int32 *errorMessageLength)
{
    int rc = DB2SEC_PLUGIN_OK;
    int length;
    int ngroups;

    char localAuthID[SQL_AUTH_IDENT + 1];
    char readBuffer[MAX_LINE_LENGTH];
    char *cptr;

    *errorMessage = NULL;
    *errorMessageLength = 0;


    /* NULL terminate the authID */
    if (authIDLength > SQL_AUTH_IDENT)
    {
        char msg[512];
        memcpy(localAuthID, authID, SQL_AUTH_IDENT);
        localAuthID[SQL_AUTH_IDENT] = '\0';
        snprintf(msg, 512,
             "LookupGroups: authID too long ("FMT_S32" bytes): %s... (truncated)",
             authIDLength, localAuthID);

        msg[511]='\0';            /* ensure NULL terminated */
        logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

        *errorMessage = "LookupGroups: authID too long";
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
    }

    memcpy(localAuthID, authID, authIDLength);
    localAuthID[authIDLength] = '\0';


    /* The maximum amount of group information that we could
     * return is less than MAX_LINE_LENGTH bytes.
     */
    *groupList = malloc(MAX_LINE_LENGTH);
    if (*groupList == NULL)
    {
        *errorMessage = "malloc failed for group memory";
        rc = DB2SEC_PLUGIN_NOMEM;
        goto exit;
    }

    rc = FindUser(getUserFileName(),
                  localAuthID,      /* User we're looking for */
                  readBuffer,
                  sizeof(readBuffer),
                  NULL,             /* Don't care about password */
                  *groupList,
                  &ngroups,
                  errorMessage);
    if (rc == -2)
    {
        /* Unexpected error. */
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
    }
    else if (rc == -1)
    {
        /* User not found */
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
    }

    *groupCount = ngroups;

exit:
    if (*errorMessage != NULL)
    {
        *errorMessageLength = strlen(*errorMessage);
    }

    return(rc);
}


/* FreeGroupList()
 * Free a group list allocated in LookupGroups().
 */
SQL_API_RC SQL_API_FN FreeGroupList(void *ptr,
                         char **errorMessage,
                         db2int32 *errorMessageLength)
{
    if (ptr != NULL)
    {
        free(ptr);
    }

    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}


/* DoesGroupExist
 * Searches the user definition file for the named group.  If
 * any user is a member of the group, DB2SEC_PLUGIN_OK is
 * returned, otherwise DB2SEC_PLUGIN_INVALIDUSERORGROUP is
 * returned.
 */
SQL_API_RC SQL_API_FN DoesGroupExist(const char *groupName,
                          db2int32 groupNameLength,
                          char **errorMessage,
                          db2int32 *errorMessageLength)
{
    int rc = DB2SEC_PLUGIN_OK;

    char localGroupName[DB2SEC_MAX_AUTHID_LENGTH + 1];
    char readBuffer[MAX_LINE_LENGTH];

    int foundGroup = 0;

    char *linePtr;
    char *field;
    char *nextPtr;
    FILE *fp = NULL;

    *errorMessage = NULL;
    *errorMessageLength = 0;

    if (groupName == NULL)
    {
        *errorMessage = "NULL group name supplied";
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
    }

    /* NULL terminate the group name */
    if (groupNameLength > DB2SEC_MAX_AUTHID_LENGTH)
    {
        char msg[512];
        memcpy(localGroupName, groupName, DB2SEC_MAX_AUTHID_LENGTH);
        localGroupName[DB2SEC_MAX_AUTHID_LENGTH] = '\0';
        snprintf(msg, 512,
             "DoesGroupExist: group name too long ("FMT_S32" bytes): %s... (truncated)",
             groupNameLength, localGroupName);

        msg[511]='\0';            /* ensure NULL terminated */
        logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

        *errorMessage = "DoesGroupExist: group name too long";
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
    }

    memcpy(localGroupName, groupName, groupNameLength);
    localGroupName[groupNameLength] = '\0';


    fp = fopen(getUserFileName(),"r");
    if (fp == NULL) {
        char msg[256];
        snprintf(msg, 256,
                  "DoesGroupExist: can't open file: %s",
                  getUserFileName());

        msg[255]='\0';            /* ensure NULL terminated */
        logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

        *errorMessage = "Cannot open specified file\n";
        rc = DB2SEC_PLUGIN_UNKNOWNERROR;
        goto exit;
    }

    while (foundGroup == 0)
    {
        /* Read the next line from the user definition file */
        linePtr = GetNextLine(fp, readBuffer, sizeof(readBuffer));

        if (linePtr == (char*)-1)
        {
            /* Line length error */
            *errorMessage = "Encountered an invalid input line in file";
            rc = DB2SEC_PLUGIN_UNKNOWNERROR;
            goto exit;
        }

        if (linePtr == NULL)
        {
            /* We've probably reached the end of file, but make sure. */
            if (feof(fp))
            {
                /* End of file: Group not found. */
                rc = DB2SEC_PLUGIN_INVALIDUSERORGROUP;
            }
            else
            {
                /* Not end of file, must have encountered an error. */
                rc = DB2SEC_PLUGIN_UNKNOWNERROR;
                *errorMessage = "Unknown file error encountered";
            }
            goto exit;
        }


        field = NextField(linePtr, &nextPtr);   /* Skip user name */
        field = NextField(nextPtr, &nextPtr);   /* and password   */

        /* Examine all of the remaining fields */
        field = NextField(nextPtr, &nextPtr);
        while (field != NULL)
        {
            if (strcasecmp(field, localGroupName) == 0)
            {
                /* Found it! */
                foundGroup = 1;
                break;
            }

            field = NextField(nextPtr, &nextPtr);
        }
    }

    if (foundGroup == 1)
    {
        rc = DB2SEC_PLUGIN_OK;
    }

exit:
    if (fp != NULL)
    {
        fclose(fp);
    }

    if (*errorMessage != NULL)
    {
        *errorMessageLength = strlen(*errorMessage);
    }

    return(rc);
}

/* FreeToken()
 * This plugin does not make use of the "token" parameter,
 * so this function is a no-op.
 */
SQL_API_RC SQL_API_FN FreeToken(void *token,
                     char **errorMessage,
                     db2int32 *errorMessageLength)
{
    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}


/* FreeErrorMessage()
 * All of the error messages returned by this plugin are
 * literal C strings, so this function is a no-op.
 */
SQL_API_RC SQL_API_FN FreeErrorMessage(char *msg)
{
    return(DB2SEC_PLUGIN_OK);
}

/* PluginTerminate()
 * There is no cleanup required when this plugin is unloaded.
 */
SQL_API_RC SQL_API_FN PluginTerminate(char **errorMessage,
                           db2int32 *errorMessageLength)
{
    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}


/*
 * PLUGIN INITIALIZATION FUNCTIONS
 *
 * Unlike previous functions in this file, the names of these
 * functions must match those defined in db2secPlugin.h.
 */

/* Server-side userid/password authentication plugin initialization */
SQL_API_RC SQL_API_FN db2secServerAuthPluginInit(
                    db2int32 version,
                    void *server_fns,
                    db2secGetConDetails *getConDetails_fn,
                    db2secLogMessage *msgFunc,
                    char **errorMessage,
                    db2int32 *errorMessageLength)
{
    db2secUseridPasswordServerAuthFunctions_1 *p;

    p = (db2secUseridPasswordServerAuthFunctions_1 *)server_fns;

    p->version = 1;         /* We're a version 1 plugin */
    p->plugintype = DB2SEC_PLUGIN_TYPE_USERID_PASSWORD;
    p->db2secValidatePassword = CheckPassword;
    p->db2secGetAuthIDs = GetAuthIDs;
    p->db2secDoesAuthIDExist = DoesAuthIDExist;
    p->db2secFreeToken = FreeToken;
    p->db2secFreeErrormsg = FreeErrorMessage;
    p->db2secServerAuthPluginTerm = PluginTerminate;

    logFunc = msgFunc;

    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}

SQL_API_RC SQL_API_FN db2secClientAuthPluginInit (db2int32 version,
                                       void *client_fns,
                                       db2secLogMessage *msgFunc,
                                       char **errorMessage,
                                       db2int32 *errorMessageLength)
{
    db2secUseridPasswordClientAuthFunctions_1 *p;

    p = (db2secUseridPasswordClientAuthFunctions_1 *)client_fns;

    p->version = 1;         /* We're a version 1 plugin */
    p->plugintype = DB2SEC_PLUGIN_TYPE_USERID_PASSWORD;
    p->db2secRemapUserid = NULL;    /* optional */
    p->db2secGetDefaultLoginContext = &WhoAmI;
    p->db2secValidatePassword = &CheckPassword;
    p->db2secFreeToken = &FreeToken;
    p->db2secFreeErrormsg = &FreeErrorMessage;
    p->db2secClientAuthPluginTerm = &PluginTerminate;

    logFunc = msgFunc;

    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}

SQL_API_RC SQL_API_FN db2secGroupPluginInit(db2int32 version,
                                 void *group_fns,
                                 db2secLogMessage *msgFunc,
                                 char **errorMessage,
                                 db2int32 *errorMessageLength)
{
    db2secGroupFunction_1  *p;

    p = (db2secGroupFunction_1 *)group_fns;

    p->version = 1;         /* We're a version 1 plugin */
    p->plugintype = DB2SEC_PLUGIN_TYPE_GROUP;
    p->db2secGetGroupsForUser = &LookupGroups;
    p->db2secDoesGroupExist = &DoesGroupExist;
    p->db2secFreeGroupListMemory = &FreeGroupList;
    p->db2secFreeErrormsg = &FreeErrorMessage;
    p->db2secPluginTerm = &PluginTerminate;

    logFunc = msgFunc;

    *errorMessage = NULL;
    *errorMessageLength = 0;
    return(DB2SEC_PLUGIN_OK);
}
