/*******************************************************************************
*
*  IBM CONFIDENTIAL
*  OCO SOURCE MATERIALS
*
*  COPYRIGHT:  P#2 P#1
*              (C) COPYRIGHT IBM CORPORATION Y1, Y2
*
*  The source code for this program is not published or otherwise divested of
*  its trade secrets, irrespective of what has been deposited with the U.S.
*  Copyright Office.
*
*  Source File Name = common/sec/IBMIAMauth/db2itrace.h
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
