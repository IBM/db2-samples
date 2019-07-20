/**********************************************************************
*
*  Source File Name = sample_fenced_server.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for fenced sample server class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_fenced_server.h"
#include "sample_fenced_nickname.h"
#include "sample_connection.h"
#include "sample_error_reporting.h"
#include "sqlqg_utils.h"
#include "sqlcodes.h"


/**************************************************************************
*
*  Function Name  = FencedSample_Server::FencedSample_Server
*
*  Function: Sample Server Constructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  sqluint8       *server_name
*          FencedWrapper        *server_wrapper
*
*  Output: sqlint32        *rc
*
*  Normal Return = rc = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
FencedSample_Server::FencedSample_Server(sqluint8* server_name, 
                  FencedWrapper* server_wrapper, sqlint32* rc)
      : Fenced_Generic_Server(server_name, server_wrapper, rc)
{
   Wrapper_Utilities::fnc_entry(60,"FencedSample_Server::FencedSample_Server");
   Wrapper_Utilities::fnc_exit(60,"FencedSample_Server::FencedSample_Server", *rc);
}

/**************************************************************************
*
*  Function Name  = FencedSample_Server::~FencedSample_Server
*
*  Function: FencedSample_Server Destructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  N/A
*
*  Output: N/A
*
*  Normal Return = N/A
*
*  Error Return =  N/A
*
**************************************************************************/
FencedSample_Server::~FencedSample_Server()
{
   Wrapper_Utilities::fnc_entry(61,"FencedSample_Server::~FencedSample_Server");
   Wrapper_Utilities::fnc_exit(61,"FencedSample_Server::~FencedSample_Server", 0);
}

/**************************************************************************
*
*  Function Name  = FencedSample_Server::create_nickname()
* 
*  Function: Method to construct new nickname for a server.
*
*  Input: sqluint8* name: name of nickname
*         Server* server: server with which nickame is associated.
*
*  Output: FencedNickname** nickname: newly created fenced nickname
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
Nickname*
FencedSample_Server::create_nickname(sqluint8 *schema_name,
				   sqluint8 * nickname_name,
				   sqlint32 *rc)
{
  FencedSample_Nickname *nickname=NULL;
  Wrapper_Utilities::fnc_entry(62,"FencedSample_Server::create_nickname");
    
  // Create an instance of the FencedSample_Nickname subclass
  nickname  =  new (rc) FencedSample_Nickname(schema_name, nickname_name, this,
                                               rc);
  if(*rc!=0)
  {
    *rc = sample_report_error_1822(*rc, "Memory allocation error.",
                         10, "FS_CN");
    Wrapper_Utilities::trace_error(62,"FencedSample_Server::create_nickname", 
                         10, sizeof(*rc), rc);
  }
  Wrapper_Utilities::fnc_exit(62,"FencedSample_Server::create_nickname", *rc);
  return(nickname);
}


/**************************************************************************
*
*  Function Name  = Sample_Server::create_remote_connection()
* 
*  Function: Method to construct new connection for a server.
*
*  Input: FencedRemote_User* user: user name accessing remote source
*
*  Output: Remote_Connection** connection: newly created connection
*
*  Normal Return = 0
*
*  Error Return =!0
*
**************************************************************************/
sqlint32 FencedSample_Server::create_remote_connection(FencedRemote_User* user,
                                           Remote_Connection** connection)
{
    sqlint32 rc=0;
    
    Wrapper_Utilities::fnc_entry(63,"FencedSample_Server::create_remote_connection");
    // Create an instance of the Sample Remote_Connection subclass
    *connection = new (&rc) Sample_Connection(this, user, &rc);
    if(rc!=0)
    {
      rc = sample_report_error_1822(rc, "Memory allocation error.",
                           20, "FS_CRX");
      Wrapper_Utilities::trace_error(63,"FencedSample_Server::create_remote_connection", 
                           20, sizeof(rc), &rc);
    }
    
    Wrapper_Utilities::fnc_exit(63,"FencedSample_Server::create_remote_connection", rc);
    return rc;
}

