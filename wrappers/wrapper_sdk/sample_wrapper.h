/**********************************************************************
*
*  Source File Name = sample_wrapper.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: unfenced wrapper class for sample wrapper
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_WRAPPER_H__
#define __SAMPLE_WRAPPER_H__

#include "sqlqg_unfenced_generic_wrapper.h"
#include "sample_server.h"

//////////////////////////////////////////////////////////////////////////////
// Sample wrapper class
//////////////////////////////////////////////////////////////////////////////

class Sample_Wrapper : public Unfenced_Generic_Wrapper
{
public:

  // Constructor.
  Sample_Wrapper(sqlint32 *rc);

  // Destructor.
  virtual ~Sample_Wrapper();
  
protected:
  
  ////////////////
  // Methods.
  ////////////////

  // create_server() allows a wrapper subclass instance to
  // create an instance of its own remote server subclass.  

  virtual Server* create_server(sqluint8* server_name,
				sqlint32* xrc); 

};

#endif
