/**********************************************************************
*
*  Source File Name = sample_connction.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004 
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: sample_connection subclass
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_CONNECTION_H__
#define __SAMPLE_CONNECTION_H__

#include "sqlxa.h"
#include "sqlqg_connection.h"

//////////////////////////////////////////////////////////////////////////////
// sample_connection subclass
//////////////////////////////////////////////////////////////////////////////

class Sample_Connection : public Remote_Connection {
public:

  // Constructor.
  Sample_Connection(FencedServer* server, FencedRemote_User *user, sqlint32* rc);

  // Destructor.
  virtual ~Sample_Connection();

  // Connect and disconnect.
  sqlint32 connect();
  sqlint32 disconnect();

  // Remote operation suppport routines.  These methods will create
  // the appropriate remote operation subclass objects for use by the
  // UDB runtime to control the execution of a remote operation such as
  // a query or an insert/update/delete operation.
  sqlint32 create_remote_query(Runtime_Operation* runtime_query,
                               Remote_Query** query);
  sqlint32 create_remote_passthru(Runtime_Operation *runtime_passthru,
                                  Remote_Passthru **passthru);
  
protected:

  ////////////////
  // Data.
  ////////////////

  ////////////////
  // Methods.
  ////////////////

  // Transaction support routines. 
  
  sqlint32 commit();
  sqlint32 rollback();

};


#endif
