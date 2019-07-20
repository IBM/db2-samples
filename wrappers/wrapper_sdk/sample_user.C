/**********************************************************************
*
*  Source File Name = sample_user.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for unfenced sample user class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_user.h"
#include "sqlqg_utils.h"

/**************************************************************************
*
*  Function Name  = Sample_User::Sample_User
*
*  Function: Sample_User class constructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  sqluint8* local_user_name: local authid of user.
*          User_Info* user_info: catalog info
*          UnfencedServer* user_server: server associated with user
*
*  Output: (required) sqlint32 *rc - return code
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
Sample_User::Sample_User(sqluint8* local_user_name, UnfencedServer* user_server,
                         sqlint32 *rc)
  :UnfencedRemote_User(local_user_name, user_server, rc)
{
   Wrapper_Utilities::fnc_entry(20,"Sample_User::Sample_User");
   Wrapper_Utilities::fnc_exit(20,"Sample_User::Sample_User", *rc);
}

/**************************************************************************
*
*  Function Name  = Sample_User::~Sample_User
*
*  Function: Sample_User class destructor
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
Sample_User::~Sample_User()
{
   Wrapper_Utilities::fnc_entry(21,"Sample_User::~Sample_User");
   Wrapper_Utilities::fnc_exit(21,"Sample_User::~Sample_User", 0);
}
