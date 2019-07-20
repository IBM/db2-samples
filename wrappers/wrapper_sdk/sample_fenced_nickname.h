/**********************************************************************
*
*  Source File Name = sample_fenced_nickname.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: sample fenced nickname class
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_FENCED_NICKNAME_H__
#define __SAMPLE_FENCED_NICKNAME_H__

#include "sqlqg_catalog.h"
#include "sqlqg_fenced_generic_nickname.h"
#include "sample_typedefs.h"

class FencedSample_Nickname : public Fenced_Generic_Nickname
{
public:
  
  // Constructor.
  FencedSample_Nickname(sqluint8 * schema, sqluint8* nickname_name,
                     FencedServer* nickname_server, sqlint32 *rc);
  
  // Destructor.
  virtual ~FencedSample_Nickname();
  
  // Verify options specified on CREATE nickname object.
  virtual sqlint32 verify_my_register_nickname_info(Nickname_Info *nickname_info,
						    Nickname_Info **delta_info);
}; 


#endif // __SAMPLE_FENCED_NICKNAME_H__
