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
** SOURCE FILE NAME: group_file.c
**
** SAMPLE: Simple file-based group management plugin
**
** This source file implements a simple, file-based group management
** scheme.
**
** When built, a single loadable object is created (see the makefile),
** which should be copied into the group plugin directory.  Then the
** GROUP_PLUGIN database manager configuration parameter should be
** updated to the name of the plugin object file, minus any extensions.
**
** For example, on 32-bit UNIX platforms the loadable object should be
** copied to the .../sqllib/security32/plugin/group directory and the
** GROUP_PLUGIN parameter updated to "group_file".
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

#ifdef DB2_PLAT_UNIX
#include <unistd.h>
#include <sys/types.h>
#else
#define strcasecmp(a,b) stricmp(a,b)
#define snprintf _snprintf
#endif

db2secLogMessage *logFunc = NULL;

/* THE GROUP DEFINITION FILE
 * Group membership information is managed in a file
 * defined by "GROUP_FILENAME".
 *
 * This file consists of one line per user consisting of the
 * username followed by zero or more groups, separted by whitespace:
 *
 *   username  [ group1  [group2 ... ] ]
 *
 * Lines that begin with "#" are comments.  Blank lines are ignored.
 * Note that user and group names may not contain whitespace (this
 * limitation applies to this plugin implementation, not DB2 in
 * general).
 *
 * The maximum line length is 1024 characters; lines longer than
 * this value will result in undefined behavior.  User and group
 * names are limited to SQL_AUTH_IDENT bytes.  Lines containing
 * longer fields will result in an error.
 */
#ifndef GROUP_FILENAME				/* Normally defined in the makefile */
#ifndef WIN32
#define GROUP_FILENAME	"/home/db2inst1/sqllib/SampleGroupFile"
#else
#define GROUP_FILENAME	"D:\\sqllib\\DB2\\SampleGroupFile"
#endif
#endif

/* The internal max line length includes room for a line
 * separator (CR/LF on Windows, LF on UNIX) and a NULL byte.
 */
#define MAX_LINE_LENGTH		1027

#define SQL_AUTH_IDENT      128


/*-------------------------------------------------------
 * Functions to read & parse the group definition file
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
			*cptr = '\0';			/* NULL terminate */

			if (nextString != NULL)
			{
				/* nextString starts with the character following
				 * the NULL byte we just inserted.
				 */
				*nextString = cptr + 1;
			}
			goto exit;		/* We're done */
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
int FindUser(const char *fileName,	/* File to read                */
             const char *userName,	/* Who we're looking for       */
			 char *readBuffer,		/* Caller-supplied read buffer */
			 int readBufferLength,
			 char *groupBuffer,		/* Output: group list          */
			 int *numGroups,		/* Output: number of groups    */
			 char **errorMessage)	/* Static C string for errors  */
{
	int rc = -1;
	int foundUser = 0;				/* Found the user yet?			*/

	int groupCount = 0;
	int length;
	char *linePtr;
	char *field;
	char *nextPtr;
	char *cptr;
	char *errMsg = NULL;			/* Temp local error message */
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

			/* If a group buffer pointer was supplied,
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

			rc = 0;		/* Found the user */
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
				 "security plugin 'group_file' encountered an error\n"
				 "User: %s\nFile:%s\nError: %s\n",
				 userName, fileName, errMsg);
		msg[255]='\0';			/* ensure NULL terminated */
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

/* LookupGroups()
 * Return the list of groups to which a user belongs.
 *
 * Find the gven Auth ID in the group definition file and
 * return the associated groups.
 */
SQL_API_RC SQL_API_FN LookupGroups(const char *authID,
						db2int32 authIDLength,
						const char *userid,				/* ignored */
						db2int32 useridLength,			/* ignored */
						const char *domain,				/* ignored */
						db2int32 domainLength,			/* ignored */
						db2int32 domainType,			/* ignored */
						const char *databaseName,		/* ignored */
						db2int32 databaseNameLength,	/* ignored */
						void *token,					/* ignored */
						db2int32 tokenType,				/* ignored */
						db2int32 location,				/* ignored */
						const char *authPluginName,		/* ignored */
						db2int32 authPluginNameLength,	/* ignored */
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
			 "LookupGroups: authID too long (%d bytes): %s... (truncated)",
			 authIDLength, localAuthID);

		msg[511]='\0';			/* ensure NULL terminated */
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

	rc = FindUser(GROUP_FILENAME,
				  localAuthID,		/* User we're looking for */
				  readBuffer,
				  sizeof(readBuffer),
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
 * Searches the group definition file for the named group.  If
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

	char localGroupName[DB2SEC_MAX_AUTHID_LENGTH+1];
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
			 "DoesGroupExist: group name too long (%d bytes): %s... (truncated)",
			 groupNameLength, localGroupName);

		msg[511]='\0';			/* ensure NULL terminated */
		logFunc(DB2SEC_LOG_ERROR, msg, strlen(msg));

        *errorMessage = "DoesGroupExist: group name too long";
        rc = DB2SEC_PLUGIN_BADUSER;
        goto exit;
    }

	memcpy(localGroupName, groupName, groupNameLength);
	localGroupName[groupNameLength] = '\0';


	fp = fopen(GROUP_FILENAME,"r");
	if (fp == NULL) {
		char msg[256];
		snprintf(msg, 256,
			 	 "DoesGroupExist: can't open file: %s",
			 	 GROUP_FILENAME);

		msg[255]='\0';			/* ensure NULL terminated */
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


		field = NextField(linePtr, &nextPtr);	/* Skip user name */

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


/* PLUGIN INITIALIZATION FUNCTION
 *
 * This is the only plugin function that is required to have
 * a specific name.
 */
SQL_API_RC SQL_API_FN db2secGroupPluginInit(db2int32 version,
                                 void *group_fns,
								 db2secLogMessage *msgFunc,
                                 char **errorMessage,
                                 db2int32 *errorMessageLength)
{
	db2secGroupFunction_1  *p;

	p = (db2secGroupFunction_1 *)group_fns;

	p->version = 1;			/* We're a version 1 plugin */
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
