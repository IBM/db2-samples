/**********************************************************************
*
*  Source File Name = sample_error_reporting.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining:General error functions 
*
*  Operating System = All
*
***********************************************************************/
#ifndef _ERROR_REPORTING_
#define _ERROR_REPORTING_

#include "sqlqg_utils.h"
#include "sqlcodes.h"
#include <stdio.h>
#include <string.h>

inline sqlint32 sample_report_error_1822(sqlint32 rc, sqlint8* error_str, 
                                         sqlint32 trace_point, sqlint8* func_name)
{ 
   char trace_point_str[25];
   sprintf(trace_point_str, "%d", trace_point);
   rc = Wrapper_Utilities::report_error((char* ) func_name, SQL_RC_E1822, 3,
                                        strlen(trace_point_str), trace_point_str,
                                        strlen("Sample Wrapper"), "Sample Wrapper",
                                        strlen(error_str), error_str);
   printf("Error in %s: %s, Trace point %d; rc= %d\n",func_name, error_str, trace_point, rc);
   return rc;

}

#endif
