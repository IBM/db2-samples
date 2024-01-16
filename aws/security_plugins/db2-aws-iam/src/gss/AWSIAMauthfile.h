/*******************************************************************************
*
*  IBM CONFIDENTIAL
*  OCO SOURCE MATERIALS
*
*  COPYRIGHT:  P#2 P#1
*              (C) COPYRIGHT IBM CORPORATION 2023, 2024
*
*  The source code for this program is not published or otherwise divested of
*  its trade secrets, irrespective of what has been deposited with the U.S.
*  Copyright Office.
*
*  Source File Name = src/gss/AWSIAMauthfile.h
*
*  Descriptive Name = FILE utility functions header file
*
*  Function: Functions for communicating with file
*
*  Dependencies: None
*
*  Restrictions: None
*
*
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
