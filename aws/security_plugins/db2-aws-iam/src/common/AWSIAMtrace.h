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
**********************************************************************************
**
**  Source File Name = common/AWSIAMtrace.h
**
**  Descriptive Name = FILE utility functions header file
**
**  Function: Functions for communicating with file
**
**  Dependencies: None
**
**  Restrictions: None
*
*
*******************************************************************************/
#ifndef _H_DB2_AWSIAMTRACE
#define _H_DB2_AWSIAMTRACE


#ifdef __cplusplus
#define DB2FILE_EXT_C extern "C"
#else
#define DB2FILE_EXT_C
#endif

typedef enum TRACE_POINT_TYPE {Ientry, Iexit, Idata} TRACE_POINT_TYPE;

DB2FILE_EXT_C void printToDebugFile(TRACE_POINT_TYPE type, const char *pszFile, const char *pszFunc, const char *pszData, int iData);

#define IAM_TRACE_ENTRY(a) printToDebugFile(Ientry, __FILE__, a, NULL, 0)
#define IAM_TRACE_EXIT(a,b) printToDebugFile(Iexit, __FILE__, a, NULL, b)
#define IAM_TRACE_DATA(a,b) printToDebugFile(Idata, __FILE__, a, b, 0)


#endif  // _H_DB2_AWSIAMTRACE
