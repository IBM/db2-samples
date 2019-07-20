/**********************************************************************
*
*  Source File Name = sample_fenced_user.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: sample fenced user class
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_FENCED_USER_H__
#define __SAMPLE_FENCED_USER_H__

#include "sqlqg_fenced_generic_user.h"

class FencedSample_User : public Fenced_Generic_User
{
public:

  // Constructor.
  FencedSample_User(sqluint8* local_user_name, FencedServer* user_server,
                  sqlint32 *rc);
  
  // Destructor.
  virtual ~FencedSample_User(); 
};


#endif // __SAMPLE_FENCED_USER_H__
