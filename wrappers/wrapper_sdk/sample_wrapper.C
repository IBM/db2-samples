/**********************************************************************
*
*  Source File Name = sample_wrapper.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for unfenced sample wrapper class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_wrapper.h"
#include "sample_typedefs.h"
#include "sample_error_reporting.h"

#include "sqlqg_catalog.h"
#include "sqlqg_utils.h"
#include "sqlcodes.h"
#include <stdio.h>

///////////////////////////////////////////////////////////////////////////////
// Sample wrapper class
//////////////////////////////////////////////////////////////////////////////

/**************************************************************************
*
*  Function Name  = Sample_Wrapper::Sample_Wrapper()
*
*  Function: Constructor for Sample_Wrapper class
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
Sample_Wrapper::Sample_Wrapper(sqlint32* rc) 
     : Unfenced_Generic_Wrapper(rc, SAMPLE_WRAPPER_VERSION)
{  
   Wrapper_Utilities::fnc_entry(1,"Sample_Wrapper::Sample_Wrapper");
   Wrapper_Utilities::fnc_exit(1,"Sample_Wrapper::Sample_Wrapper", *rc);
}

/**************************************************************************
*
*  Function Name  = Sample_Wrapper::~Sample_Wrapper()
*
*  Function: Destructor for Sample_Wrapper class
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
Sample_Wrapper::~Sample_Wrapper()
{
   Wrapper_Utilities::fnc_entry(2,"Sample_Wrapper::~Sample_Wrapper");
   Wrapper_Utilities::fnc_exit(2,"Sample_Wrapper::~Sample_Wrapper", 0);
}


/**************************************************************************
*
*  Function Name  = Sample_Wrapper::create_server()
*
*  Function: routine to create a new instance of Sample_Server
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  (required) sqluint8* server_name: name of server for which instance
*                     should be instantiated.
*
*  Output: (optional) Server* server: newly instantiated Sample_Server instance.
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
Server* Sample_Wrapper::create_server(sqluint8* server_name, sqlint32* rc)
{
    Sample_Server *server=NULL;
    Wrapper_Utilities::fnc_entry(3,"Sample_Wrapper::create_server");

    Wrapper_Utilities::fnc_data(3,"Sample_Wrapper::create_server", 
                                 10, strlen((char *)server_name), (char*)server_name);
    server = new(rc) Sample_Server(server_name, this, rc);
    if(*rc!=0)
    {
      *rc = sample_report_error_1822(*rc, "Memory allocation error.",
                           20, "SW_CS");
      Wrapper_Utilities::trace_error(3,"Sample_Wrapper::create_server", 
                           20, sizeof(*rc), rc);
    }
    
    Wrapper_Utilities::fnc_exit(3,"Sample_Wrapper::create_server", *rc);
    return server;
}

/**************************************************************************
*
*  Function Name  = UnfencedWrapper_Hook()
*
*  Function: Hook function to get a handle on Sample_Wrapper instance.
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  none
*
*  Output: N/A
*
*  Normal Return = UnfencedWrapper*: a pointer to instantiated Wrapper instance
*
*  Error Return = rc != 0
*
**************************************************************************/
extern "C" UnfencedWrapper* UnfencedWrapper_Hook()
{

    UnfencedWrapper* wrapper=NULL;
    sqlint32 rc=0;
    Wrapper_Utilities::fnc_entry(4,"UnfencedWrapper_Hook");

    wrapper = new(&rc) Sample_Wrapper(&rc);

    if( (rc) || (wrapper == NULL) )
    {
      rc = Wrapper_Utilities::report_error("UW_Hook",
               SQL_RC_E1822, 3, strlen("-1"), "-1",
               strlen(SQLQG_WRAPPER_OPTION), SQLQG_WRAPPER_OPTION,
               strlen(NULL_WRAPPER), NULL_WRAPPER);

      Wrapper_Utilities::trace_error(4,"UnfencedWrapper_Hook", 
                           30, sizeof(rc), &rc);
            
      if (wrapper != NULL )
      {
          delete wrapper;
          wrapper = NULL;
      }

    }

    Wrapper_Utilities::fnc_exit(4,"UnfencedWrapper_Hook", rc);
    return wrapper;
}
