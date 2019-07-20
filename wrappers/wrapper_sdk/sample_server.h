/**********************************************************************
*
*  Source File Name = sample_server.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: unfenced sample server subclass
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_SERVER_H__
#define __SAMPLE_SERVER_H__

#include "sample_typedefs.h"
#include "sample_nickname.h"
#include "sqlqg_unfenced_generic_server.h"
#include "sqlqg_fenced_user.h"

class Remote_Connection;
class Runtime_Data; 
class Request;
class Reply;
class Request_Exp_Type;
class Request_Exp;
class Request_Constant;

//////////////////////////////////////////////////////////////////////////////
// Sample Server class
/////////////////////////////////////////////////////////////////////////////
class Sample_Server : public Unfenced_Generic_Server 
{
public:

    // Constructor.
    Sample_Server(sqluint8* server_name, UnfencedWrapper* server_wrapper, sqlint32 *rc);
    
    // Destructor.
    virtual ~Sample_Server();
    
    // Verifies options, local type mappings, remote function mappings
    // specified on CREATE SERVER statement.
    virtual sqlint32 verify_my_register_server_info(Server_Info* catalog_info,
                                               Server_Info** delta_info);
    
    // Verifies options, local type mappings, remote function mappings
    // specified on ALTER SERVER statement.
    virtual sqlint32 verify_my_alter_server_info(Server_Info* catalog_info,
                                            Server_Info** delta_info);
    // Plan a request and return a reply
    virtual sqlint32 plan_request(Request *rq, Reply **rep);


protected:
    ////////////////
    // Data.
    ////////////////


    ////////////////
    // Methods.
    ////////////////
    
    // Create instance of Sample_Nickname subclass.
    virtual Nickname* create_nickname(sqluint8 *schema_name,
				      sqluint8 *name,
				      sqlint32 *rc); 
    
    //stores a block of memory into the execution descriptor
    inline void store_and_advance(char*&,void*,int);
    
    //Sets the types and the lengths of the data buffers, but does not allocate anything
    sqlint32 prepare_data_area(Nickname_Info *nickname_info, columnData* &Data, int NumColumns);

    // Allocate, copy and null terminate a string
    sqlint32 null_terminate(char *instr, int len, char** outstring);
};

#endif
