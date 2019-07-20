/**********************************************************************
*
*  Source File Name = sample_fenced_wrapper.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: sample fenced wrapper class
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_FENCED_WRAPPER_H__
#define __SAMPLE_FENCED_WRAPPER_H__

#include "sample_typedefs.h"
#include "sqlqg_catalog.h"
#include "sqlqg_fenced_generic_wrapper.h"

class Server;

class FencedSample_Wrapper : public Fenced_Generic_Wrapper 
{
public:
  
  // Constructor.
  FencedSample_Wrapper(sqlint32 *rc);
  
  // Destructor.
  virtual ~FencedSample_Wrapper();
  
protected:

  // create_server() allows a wrapper subclass instance to
  // create an instance of its own remote server subclass.  
  
  virtual Server* create_server(sqluint8* server_name, sqlint32 *rc);
};

#endif // __SAMPLE_FENCED_WRAPPER_H__
