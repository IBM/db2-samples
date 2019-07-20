/**********************************************************************
*
*  Source File Name = sample_nickname.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for unfenced sample nickname class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_nickname.h"
#include "sample_server.h"
#include "sample_utilities.h"
#include "sqlcli.h"
#include "sqlqg_catalog.h"
#include "sqlqg_utils.h"
#include "sqlcodes.h"

/**************************************************************************
*
*  Function Name  = Sample_Nickname::Sample_Nickname
*
*  Function: Sample_Nickname base class constructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  sqluint8* schema_name: Scehma name
*          sqluint8* nickname_name: Nickname name
*          UnfencedServer* nickname_server: server associated with nickname
*
*  Output: (required) sqlint32 *rc - return code
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
Sample_Nickname::Sample_Nickname(sqluint8 *schema_name, sqluint8 *nickname_name,
                             UnfencedServer* nickname_server, sqlint32 *rc)
  :Unfenced_Generic_Nickname(schema_name, nickname_name,
                            (Unfenced_Generic_Server*)nickname_server, rc),
  mFilePath(NULL), mNickname_Info (NULL)
{
   Wrapper_Utilities::fnc_entry(30,"Sample_Nickname::Sample_Nickname");
   Wrapper_Utilities::fnc_exit(30,"Sample_Nickname::Sample_Nickname", *rc);
}

/**************************************************************************
*
*  Function Name  = Sample_Nickname::~Sample_Nickname
*
*  Function: Sample_Nickname base class destructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  none
*
*  Output: none
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
Sample_Nickname::~Sample_Nickname()
{
    Wrapper_Utilities::fnc_entry(31,"Sample_Nickname::~Sample_Nickname");
    if (mFilePath != NULL)
    {
      Wrapper_Utilities::deallocate(mFilePath);
      mFilePath = NULL;
    }
    
    delete mNickname_Info;
    mNickname_Info = NULL;
    Wrapper_Utilities::fnc_exit(31,"Sample_Nickname::~Sample_Nickname", 0);
}

/**************************************************************************
*
*  Function Name  = Sample_Nickname::initialize_my_nickame()
*
*  Function: This method performs nickname specific initialization.
*
*  Restrictions:
*
*  Input:  Nickname_Info *nickname_info: catalog information about nickname.
*
*  Output: none.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Nickname::initialize_my_nickname(Nickname_Info* nickname_info)
{
    sqlint32 rc=0;
    
    Wrapper_Utilities::fnc_entry(32,"Sample_Nickname::initialize_my_nickname");

    rc = Sample_Utilities::save_option_value(nickname_info, FILE_PATH_OPTION, &mFilePath);
    if (rc) 
    {
      Wrapper_Utilities::trace_error(32,"Sample_Nickname::initialize_my_nickname", 
                           10, sizeof(rc), &rc);
      goto exit;
    }
    
    if (mNickname_Info == NULL)
    {
        rc = nickname_info->copy(&mNickname_Info);
        if (rc) 
        {
          Wrapper_Utilities::trace_error(32,"Sample_Nickname::initialize_my_nickname", 
                              20, sizeof(rc), &rc);
          goto exit;
        }
    }
    
exit:
    Wrapper_Utilities::fnc_exit(32,"Sample_Nickname::initialize_my_nickname", rc);
    return rc;
}

/**************************************************************************
*
*  Function Name  = Sample_Nickname::verify_my_register_nickname_info
*
*  Function: NONE, this is done on the fenced side
*
*  Restrictions:
*
*  Input:  Nickname_Info *nickname_info: catalog information about nickname.
*
*  Output: Nickname_Info **delta_info: any additional information about nickname
*          added as a result of the registration process.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Nickname::verify_my_register_nickname_info(Nickname_Info* nickname_info,
                                                           Nickname_Info** delta_info)
{
  sqlint32 rc=0;
  
  Wrapper_Utilities::fnc_entry(33,"Sample_Nickname::verify_my_register_nickname_info");

  // We want an implementation that does *nothing*, because everything
  // should have been checked on the fenced side.  We don't want the
  // default implementation of this method, because it will will get
  // upset about any options appearing.

  Wrapper_Utilities::fnc_exit(33,"Sample_Nickname::verify_my_register_nickname_info", rc);
  return rc;
}

/**************************************************************************
*
*  Function Name  = Sample_Nickname::verify_my_alter_nickname_info
*
*  Function: Checks nickname information on ALTER DDL statement for validity.
*
*  Restrictions:
*
*  Input:  Nickname_Info *nickname_info: catalog information about nickname.
*
*  Output: Nickname_Info **nickname_info: any additional information about nickname
*          added as a result of the registration process.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Nickname::verify_my_alter_nickname_info(Nickname_Info* nickname_info,
                                                   Nickname_Info** delta_info)
{
    sqlint32       rc = 0;
    Column_Info    *columnInfo = NULL;
    Catalog_Option *catalog_option = NULL;
    sqluint8       *nickname_name = NULL;
    Sample_Server  *srv = NULL;
    sqluint8       *serverName = NULL;
    
    Wrapper_Utilities::fnc_entry(34,"Sample_Nickname::verify_my_alter_nickname_info");
    
    columnInfo = nickname_info->get_first_column();
    
    if (columnInfo != NULL)  
    {
       // Some columns are being altered.. Check for unsupported data types.
       
       srv = (Sample_Server *) get_server();
       serverName = srv->get_name();
       rc = Sample_Utilities::verify_column_type_and_options(this, nickname_info, serverName);
       if (rc)
       {
          Wrapper_Utilities::trace_error(34,"Sample_Nickname::verify_my_alter_nickname_info", 
                              30, sizeof(rc), &rc);
          goto exit;
       }
    }
    
    //----------------------------------------------------------------------
    //
    // This nickname must be registered with the FILE_PATH option.
    //
    // ----------------------------------------------------------------------
    
    
    // Walk through the list of options supplied in the DDL to :
    // 1. Check to see if the user is not trying to drop the FILE_PATH option
    // 2. Check to see if the user is not trying to alter an unknown option
    
    if (nickname_info != NULL)
    {
        catalog_option = nickname_info->get_first_option();   
    }
    
    while (catalog_option != NULL)
    {
       const char *catalog_option_name = (const char*) catalog_option->get_name();
        
       // Compare the user supplied option (in DDL) to our options
       
       if (strcmp(FILE_PATH_OPTION, catalog_option_name) == 0)
       {
          // Get the action on this option to make sure that the
          // user is not trying to drop this required option
          
          Catalog_Option::Action action = catalog_option->get_action();
          if (action == Catalog_Option::sqlqg_Drop)
          {
             // A required option cannot be dropped
             
             nickname_name = this->get_local_name();
             rc = Wrapper_Utilities::report_error("SN_VMA", SQL_RC_E1883, 3,
                                     strlen(catalog_option_name),  catalog_option_name, 
                                     strlen("Nickname"), "Nickname", 
                                     strlen((const char*) nickname_name), (const char*) nickname_name);

             Wrapper_Utilities::fnc_data2(34,"Sample_Nickname::verify_my_alter_nickname_info", 40, 
                                         strlen((char *)catalog_option_name), (char *)catalog_option_name, 
                                         strlen((const char *)nickname_name), (const char *)nickname_name);

             Wrapper_Utilities::trace_error(34,"Sample_Nickname::verify_my_alter_nickname_info", 
                                         40, sizeof(rc), &rc);
             goto exit; 
          }

        }

        // The option found in the catalog (specified in ddl) might be DB2 (reserved) option
        // if not, complain
        
        else
        if (!is_reserved_nickname_option((sqluint8 *)catalog_option_name))
        {
            // This option is not valid - report an error
            
            nickname_name = this->get_local_name();
            rc = Wrapper_Utilities::report_error("SN_VMA", SQL_RC_E1881, 3, 
                                    strlen(catalog_option_name), catalog_option_name, 
                                    strlen("Nickname"), "Nickname", 
                                    strlen((const char *) nickname_name), nickname_name);

            Wrapper_Utilities::fnc_data2(34,"Sample_Nickname::verify_my_alter_nickname_info", 50, 
                                        strlen((char *)catalog_option_name), (char *)catalog_option_name, 
                                        strlen((const char *)nickname_name), (const char *)nickname_name);

            Wrapper_Utilities::trace_error(34,"Sample_Nickname::verify_my_alter_nickname_info", 
                                         50, sizeof(rc), &rc);
            goto exit;
        }
        
        catalog_option = nickname_info->get_next_option(catalog_option);   
    }
    
exit:
    
    Wrapper_Utilities::fnc_exit(34,"Sample_Nickname::verify_my_alter_nickname_info", rc);
    return rc;
}

/**************************************************************************
*
*  Function Name  = Sample_Nickname::get_file_path()
*
*  Function: Return the full path to the file.
*
*  Input:
*
*  Output: file_path - pointer to the full path of the file.
*
*  Normal Return = 0
*
*  Error Return = !0
*
**************************************************************************/
sqlint32 Sample_Nickname::get_file_path(sqluint8 **file_path) const
{
    sqlint32 rc = 0;

    *file_path = mFilePath;

    return rc;
}


/**************************************************************************
*
*  Function Name  = Sample_Nickname::get_nickname_info()
*
*  Function: Returns a copy of the Nickname_Info object
*
*  Input:
*
*  Output: nickname_info - pointer to a Nickname_Info object copy
*
*  Normal Return = 0
*
*  Error Return = !0
*
**************************************************************************/
sqlint32 Sample_Nickname::get_nickname_info(Nickname_Info **nickname_info) const
{
    sqlint32 rc = 0;
  
    *nickname_info = mNickname_Info;

    return rc;
}
