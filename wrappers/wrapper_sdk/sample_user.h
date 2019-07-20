/**********************************************************************
*
*  Source File Name = sample_user.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: unfenced sample user subclass
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_USER_H__
#define __SAMPLE_USER_H__

#include "sqlqg_unfenced_user.h"

//////////////////////////////////////////////////////////////////////////////
// Sample_User class definition
//////////////////////////////////////////////////////////////////////////////
class Sample_User : public UnfencedRemote_User {
public:
    // Constructor.
    Sample_User(sqluint8* local_user_name, UnfencedServer* user_server, sqlint32 *rc);
    
    // Destructor. 
    virtual ~Sample_User();
    
protected:


};

#endif
