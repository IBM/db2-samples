/**********************************************************************
*
*  Source File Name = sample_fenced_server.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: sample fenced server class
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_FENCED_SERVER_H__
#define __SAMPLE_FENCED_SERVER_H__

#include "sample_typedefs.h"
#include "sqlqg_catalog.h"
#include "sqlqg_fenced_generic_server.h"

class FencedSample_Server : public Fenced_Generic_Server {
public:
  
  // Constructors
  FencedSample_Server(sqluint8* server_name, FencedWrapper* server_wrapper,
                  sqlint32* rc);

  virtual ~FencedSample_Server();

  // Create instance of FencedSample_Nickname subclass.
  virtual Nickname* create_nickname(sqluint8 *schema_name, sqluint8 *name, 
                                     sqlint32 *rc); 
  
protected:
   
  // Create instance of Sample_Connection subclass.
  sqlint32 create_remote_connection(FencedRemote_User* user, 
                                    Remote_Connection** connection); 
};

#endif // __SAMPLE_FENCED_SERVER_H__
