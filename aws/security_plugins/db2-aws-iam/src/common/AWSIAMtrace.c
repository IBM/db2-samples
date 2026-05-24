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
**  Source File Name = src/AWSIAMtrace.c           (%W%)
**
**  Descriptive Name = trace functionality
**
**  Function: 
**
**  Dependencies:
**
**  Restrictions:
**
*****************************************************************************/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/syscall.h>

#include "AWSIAMtrace.h"



#define DB2OC_TRACE_ON_FILE "/tmp/iam_trace_on.cfg"
#define DB2OC_TRACE_FILE "/tmp/IAM_DEBUG.trc"

void printToDebugFile(TRACE_POINT_TYPE type, const char *pszFile, const char *pszFunc, const char *pszData, int iData)
{  
   FILE *pFile = NULL;
   char szOutput[4024] = "";
   struct stat buffer;
   
   pid_t tid = syscall(SYS_gettid);
   // return immediately if trace is not on.
   if(stat(DB2OC_TRACE_ON_FILE, &buffer) !=0 )
   {
      return;
   }

   // Trace output will always go to 
   pFile=fopen(DB2OC_TRACE_FILE, "a");
   switch(type)
   {
      case Ientry:
         snprintf(szOutput,sizeof(szOutput),"%d:%lu:ENTRY->-%s:%s\n",tid, (unsigned long)time(NULL), pszFile, pszFunc);         break;
      case Iexit:
         snprintf(szOutput,sizeof(szOutput),"%d:%lu:EXIT->-%s:%s (%d)\n",tid, (unsigned long)time(NULL), pszFile, pszFunc,iData);         break;
      case Idata:
         if(pszData == NULL)
         {
            snprintf(szOutput,sizeof(szOutput),"%d:%lu:DATA->-%s:%s (%s)\n",tid, (unsigned long)time(NULL), pszFile, pszFunc,"NULL");
         }
         else
         {
            snprintf(szOutput,sizeof(szOutput),"%d:%lu:DATA->-%s:%s (%s)\n",tid, (unsigned long)time(NULL), pszFile, pszFunc,pszData);
         }
         break;
   }

   fputs(szOutput, pFile);
   fflush(pFile);
   fclose(pFile);
}
