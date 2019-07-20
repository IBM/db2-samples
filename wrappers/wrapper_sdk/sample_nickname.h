/**********************************************************************
*
*  Source File Name = sample_nickname.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: unfenced sample nickname subclass
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_NICKNAME_H__
#define __SAMPLE_NICKNAME_H__

#include "sqlqg_unfenced_generic_nickname.h"

//////////////////////////////////////////////////////////////////////////////
// Nickname base class (used to represent remote tables)
//////////////////////////////////////////////////////////////////////////////

////////////////////////////////
// Base class.
////////////////////////////////
class Sample_Nickname : public Unfenced_Generic_Nickname 
{
public:
    // Constructor.
    Sample_Nickname(sqluint8 *schema_name, sqluint8* nickname_name,
                    UnfencedServer* nickname_server, sqlint32 *rc);  
    
    // Destructor.
    virtual ~Sample_Nickname();
    
    // Initialization hook.  Invoked after creating a nickname object
    // to intialize state from catalog information.
    virtual sqlint32 initialize_my_nickname(Nickname_Info* catalog_info);
    
    // Verify options specified on CREATE nickname object.
    virtual sqlint32 verify_my_register_nickname_info(Nickname_Info* nick_info,
						      Nickname_Info** delta_info);
    // Verify options specified on ALTER nickname object.
    virtual sqlint32 verify_my_alter_nickname_info(Nickname_Info *nickname_info,
                                                   Nickname_Info **delta_info);
    
    // Returns a pointer to the file path
    sqlint32 get_file_path(sqluint8 **file_path) const;
    
    // Returns a pointer to the Nickname_Info object
    sqlint32 get_nickname_info(Nickname_Info **nickname_info) const;


protected:

    ////////////////
    // Data.
    ////////////////   
    
    // Full path to the data file
    sqluint8 *mFilePath;

    // Copy of Nickname_Info object
    Nickname_Info   *mNickname_Info;

};
    
#endif
