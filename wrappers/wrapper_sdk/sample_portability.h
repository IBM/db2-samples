/**********************************************************************
*
*  Source File Name = sample_portability.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining:  Macros used  for portability
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_PORTABILITY_H__
#define __SAMPLE_PORTABILITY_H__

#include <errno.h>
#define MAX_LINE_SIZE   32768

#ifdef SQLUNIX

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#define NOT_READABLE_FILE(PATH)         (access(PATH,R_OK) != 0)
#define CHECK_FILE_TYPE(PATH)           (stat(PATH,&statBuffer))
#define NON_STANDARD_FILE               (S_ISDIR(statBuffer.st_mode) ||\
                                         S_ISFIFO(statBuffer.st_mode) ||\
                                         S_ISSOCK(statBuffer.st_mode))
#define OPEN_FILE(PATH,FILE_PTR)        (FILE_PTR = fopen(PATH,"r"))
#define OPEN_FAILED(FILE_PTR)           (FILE_PTR == NULL ? 1 : 0)
#define FILE_SIZE                       (statBuffer.st_size);
#define END_OF_FILE(FILE_PTR)           (feof(FILE_PTR))
#define GET_A_RECORD(BUFFER, FILE_PTR)  (fgets(BUFFER, MAX_LINE_SIZE, FILE_PTR))
#define BUILD_ERROR_MESSAGE(MSG)        (sprintf(MSG,"ERRNO = %d\0",errno))
#define CLOSE_FILE(FILE_PTR)            (fclose(FILE_PTR))


#elif WIN32

#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>
#include <errno.h>

#define R_OK	4

#define NOT_READABLE_FILE(PATH)        (access(PATH,R_OK) != 0)
#define CHECK_FILE_TYPE(PATH)          (stat(PATH,&statBuffer))
#define NON_STANDARD_FILE              (((_S_IFDIR)&(statBuffer.st_mode)) ||\
                                        ((_S_IFIFO)&(statBuffer.st_mode)) ||\
                                        ((_S_IFCHR)&(statBuffer.st_mode)))
#define OPEN_FILE(PATH, FILE_PTR)      (FILE_PTR = fopen(PATH,"r"))
#define OPEN_FAILED(FILE_PTR)          (FILE_PTR == NULL ? 1 : 0)
#define FILE_SIZE                      (statBuffer.st_size);
#define END_OF_FILE(FILE_PTR)          (feof(FILE_PTR))
#define GET_A_RECORD(BUFFER,FILE_PTR)  (fgets(BUFFER, MAX_LINE_SIZE, FILE_PTR))
#define BUILD_ERROR_MESSAGE(MSG)       (sprintf(MSG,"ERRNO = %d\0",errno))
#define CLOSE_FILE(FILE_PTR)           (fclose(FILE_PTR))

#endif

#if defined (WIN32) || defined (SQLSUN) || defined (SQLLinux) || defined (HPUX)
#include <limits.h>
#endif

#endif
