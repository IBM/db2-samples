/**********************************************************************
*
*  Source File Name = sample_fenced_user.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for fenced sample user class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_fenced_user.h"
#include "sqlqg_utils.h"

/**************************************************************************
*
*  Function Name  = FencedSample_User::FencedSample_User
*
*  Function: FencedSample_User class constructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  sqluint8* local_user_name: local authid of user.
*          FencedServer* user_server: server associated with user
*
*  Output: (required) sqlint32 *rc - return code
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
FencedSample_User::FencedSample_User(sqluint8* local_user_name, 
                  FencedServer* user_server, sqlint32 *rc)
    : Fenced_Generic_User(local_user_name, user_server, rc)
{
   Wrapper_Utilities::fnc_entry(70,"FencedSample_User::FencedSample_User");
   Wrapper_Utilities::fnc_exit(70,"FencedSample_User::FencedSample_User", *rc);
}

/**************************************************************************
*
*  Function Name  = FencedSample_User::~FencedSample_User
*
*  Function: FencedSample_User class destructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  none
*
*  Output: none
*
**************************************************************************/
FencedSample_User::~FencedSample_User()
{
   Wrapper_Utilities::fnc_entry(71,"FencedSample_User::~FencedSample_User");
   Wrapper_Utilities::fnc_exit(71,"FencedSample_User::~FencedSample_User", 0);
}
