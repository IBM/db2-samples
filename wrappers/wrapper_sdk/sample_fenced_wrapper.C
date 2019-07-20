/**********************************************************************
*
*  Source File Name = sample_fenced_wrapper.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for fenced sample wrapper class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_fenced_wrapper.h"
#include "sample_fenced_server.h"
#include "sample_error_reporting.h"

#include "sqlqg_utils.h"
#include "sqlcodes.h"
#include <string.h>
#include <stdio.h>

/**************************************************************************
*
*  Function Name  = FencedSample_Wrapper::FencedSample_Wrapper()
*
*  Function: Constructor for FencedSample_Wrapper class
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  (required) sqlint32* rc: return code to indicate errors.
*
*  Output: N/A
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
FencedSample_Wrapper::FencedSample_Wrapper(sqlint32 *rc )
     : Fenced_Generic_Wrapper(rc, SAMPLE_WRAPPER_VERSION)
{  
   Wrapper_Utilities::fnc_entry(50,"FencedSample_Wrapper::FencedSample_Wrapper");
   Wrapper_Utilities::fnc_exit(50,"FencedSample_Wrapper::FencedSample_Wrapper", *rc);
}

/**************************************************************************
*
*  Function Name  = FencedSample_Wrapper::~FencedSample_Wrapper()
*
*  Function: Destructor for FencedSample_Wrapper class
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  none
*
*  Output: N/A
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
FencedSample_Wrapper::~FencedSample_Wrapper()
{
   Wrapper_Utilities::fnc_entry(51,"FencedSample_Wrapper::~FencedSample_Wrapper");
   Wrapper_Utilities::fnc_exit(51,"FencedSample_Wrapper::~FencedSample_Wrapper", 0);
}

/**************************************************************************
*
*  Function Name  = FencedSample_Wrapper::create_server()
*
*  Function: routine to create a new instance of FencedSample_Server in the fenced side
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  (required) sqluint8* server_name: name of server for which instance
*                     should be instantiated.
*
*  Output: (optional) FencedServer* server: newly instantiated FencedSample_Server instance.
*
*  Normal Return = 0
*
*  Error Return = != 0
*
**************************************************************************/

Server* FencedSample_Wrapper::create_server(sqluint8* server_name,  sqlint32 *rc)
{
    FencedSample_Server *server=NULL;
    
    Wrapper_Utilities::fnc_entry(52,"FencedSample_Wrapper::create_server");
    server = new(rc) FencedSample_Server(server_name, this, rc);
    if(*rc!=0)
    {
      *rc = sample_report_error_1822(*rc, "Memory allocation error.",
                           10, "SF_CS");
      Wrapper_Utilities::trace_error(52,"FencedSample_Wrapper::create_server", 
                           10, sizeof(*rc), rc);
    }
    
    Wrapper_Utilities::fnc_exit(52,"FencedSample_Wrapper::create_server", *rc);
    return server;
}

/**************************************************************************
*
*  Function Name  = FencedWrapper_Hook()
*
*  Function: Hook function to get a handle on FencedSample_Wrapper instance.
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  none
*
*  Output: N/A
*
*  Normal Return = FencdedWrapper*: a pointer to instantiated Wrapper instance
*
*  Error Return = rc != 0
*
**************************************************************************/
extern "C" FencedWrapper* FencedWrapper_Hook()
{
    FencedWrapper* wrapper=NULL;
    sqlint32 rc=0;

    Wrapper_Utilities::fnc_entry(53,"FencedWrapper_Hook");
    wrapper = new(&rc) FencedSample_Wrapper(&rc);

    if(rc || wrapper == NULL)
    {
      rc = Wrapper_Utilities::report_error("FW_Hook",
               SQL_RC_E1822, 3, strlen("-1"), "-1",
               strlen(SQLQG_WRAPPER_OPTION), SQLQG_WRAPPER_OPTION,
               strlen(NULL_WRAPPER), NULL_WRAPPER);

      Wrapper_Utilities::trace_error(53,"FencedWrapper_Hook", 
                           20, sizeof(rc), &rc);
      
      if (wrapper)
      {
        delete wrapper;
        wrapper = NULL;
      }
    }
    
    Wrapper_Utilities::fnc_exit(53,"FencedWrapper_Hook", rc);
    return wrapper;
}
