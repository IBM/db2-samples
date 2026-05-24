/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2024
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
******************************************************************************
**
**  Source File Name = src/gss/AWSIAMauthfile.h
**
**  Descriptive Name = FILE utility functions header file
**
**  Function: Functions for communicating with file
**
**
**
*******************************************************************************/

#ifndef _AWS_IAM_AUTHFILE_H
#define _AWS_IAM_AUTHFILE_H

#include <string.h>
#include <stdbool.h>
#include <db2secPlugin.h>
#define URL_BUFFER_SIZE 1024
#define MAX_ERROR_MSG_SIZE      2048

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
#define DB2FILE_EXT_C extern "C"
#else
#define DB2FILE_EXT_C
#endif

#define SALT_SZ 4
#define MAX_SALT_SZ 40
#define MAX_ENCODED_PASSWORD_HASH 256

#ifndef IS_EMPTY
   #define IS_EMPTY(x) (x == NULL || x[0] == '\0')
#endif
#endif // _AWS_IAM_AUTHFILE_H
