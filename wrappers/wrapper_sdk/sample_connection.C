/**********************************************************************
*
*  Source File Name = sample_connction.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for sample connection class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_connection.h"
#include "sample_operation.h"
#include "sample_error_reporting.h"

#include "sqlqg_catalog.h"
#include "sqlcodes.h"


//////////////////////////////////////////////////////////////////////////////////
// Sample_Connection class.
//////////////////////////////////////////////////////////////////////////////////

/**************************************************************************
*
*  Function Name  = Sample_Connection::Sample_Connection()
*
*  Function: Constructor for Sample_Connection class
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  FencedServer* server: server to which connection is desired
*          FencedRemote_User* user: user info for connection
*
*  Output: sqlint32 *rc: return code to indicate a problem
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
Sample_Connection::Sample_Connection(FencedServer* server, FencedRemote_User *user,
                                     sqlint32 *rc)
  :Remote_Connection(server, user, one_phase_kind, rc)
{
   Wrapper_Utilities::fnc_entry(40,"Sample_Connection::Sample_Connection");
   Wrapper_Utilities::fnc_exit(40,"Sample_Connection::Sample_Connection", *rc);
}

/**************************************************************************
*
*  Function Name  = Sample_Connection::~Sample_Connection()
*
*  Function: Destructor for Sample_Connection class
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  none.
*
*  Output: none.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
Sample_Connection::~Sample_Connection()
{
     Wrapper_Utilities::fnc_entry(41,"Sample_Connection::~Sample_Connection");
     Wrapper_Utilities::fnc_exit(41,"Sample_Connection::~Sample_Connection", 0);
}

/**************************************************************************
*
* Function name: Sample_Connection::connect()
*
* Function: establish connection to the remote server
*
* Input: none
*
* Output: none
*
**************************************************************************/
sqlint32 Sample_Connection::connect()
{
    sqlint32 rc=0;
    Wrapper_Utilities::fnc_entry(42,"Sample_Connection::connect");
    
    Wrapper_Utilities::fnc_exit(42,"Sample_Connection::connect", rc);
    return rc;  
}

/**************************************************************************
*
* Function name: Sample_Connection::disconnect()
*
* Function: disconnect from the server.
*
* Input: none
*
* Output: none
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Connection::disconnect()
{
    sqlint32 rc=0;
    Wrapper_Utilities::fnc_entry(43,"Sample_Connection::disconnect");
    
    Wrapper_Utilities::fnc_exit(43,"Sample_Connection::disconnect", rc);
    return rc;
}

/**************************************************************************
*
*  Function Name  = Sample_Connection::create_remote_query()
* 
*  Function: create a Remote_Query object with all
*  necessary state information for executing a query.
*
*  Input: remoteQuery* runtime_query: pointer to runtime query operator
*
*  Output:  Remote_Query** query: newly created Remote_Query object
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Connection::create_remote_query(Runtime_Operation* runtime_query,
                                              Remote_Query** query)
{
    sqlint32 rc=0;
    Wrapper_Utilities::fnc_entry(44,"Sample_Connection::create_remote_query");

    *query = new (&rc) Sample_Query(this, runtime_query, &rc);
    if(rc!=0)
    {
      rc = sample_report_error_1822(rc, "Memory allocation error.",
                           10, "SC_CRQ");
      Wrapper_Utilities::trace_error(44,"Sample_Connection::create_remote_query", 
                           10, sizeof(rc), &rc);
    }
    
    Wrapper_Utilities::fnc_exit(44,"Sample_Connection::create_remote_query", rc);
    return rc;
}

/**************************************************************************
*
*  Function Name  = Sample_Connection::create_remote_passthru()
* 
*  Function: create a Remote_Passthru object with all
*  necessary state information for establishing passthru session.
*
*  Input: Runtime_Operation* runtime_passthru: pointer to runtime passthru operator
*
*  Output: Remote_Passthru** passthru: newly created Remote_Passthru object
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Connection::
  create_remote_passthru(Runtime_Operation* runtime_passthru,
                         Remote_Passthru** passthru)
{
    sqlint32 rc=0;
    Wrapper_Utilities::fnc_entry(45,"Sample_Connection::create_remote_passthru");
    
    *passthru = new (&rc) Sample_Passthru(this, runtime_passthru, &rc);
    if(rc!=0)
    {
      rc = sample_report_error_1822(rc, "Memory allocation error.",
                           20, "SC_CRP");
      Wrapper_Utilities::trace_error(45,"Sample_Connection::create_remote_passthru", 
                           20, sizeof(rc), &rc);
    }
    
    Wrapper_Utilities::fnc_exit(45,"Sample_Connection::create_remote_passthru", rc);
    return rc;  
}

/**************************************************************************
*
*  Function Name  = Sample_Connection::commit()
* 
*  Function: commit a transaction.
*
*  Input: 
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Connection::commit()
{
    sqlint32 rc=0;

    Wrapper_Utilities::fnc_entry(46,"Sample_Connection::commit");
    // No transaction supported by this wrapper
    
    Wrapper_Utilities::fnc_exit(46,"Sample_Connection::commit", rc);
    return rc;  
}
  
/**************************************************************************
*
*  Function Name  = Sample_Connection::rollback()
* 
*  Function: rollback a transaction.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Connection::rollback()
{
    sqlint32 rc=0;
    Wrapper_Utilities::fnc_entry(47,"Sample_Connection::rollback");
    
    // No transaction supported by this wrapper
    
    Wrapper_Utilities::fnc_exit(47,"Sample_Connection::rollback", rc);
    return rc; 
}

