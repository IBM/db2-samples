/**********************************************************************
*
*  Source File Name = sample_fenced_nickname.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for fenced sample nickname class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_fenced_nickname.h"
#include "sample_fenced_server.h"
#include "sample_error_reporting.h"
#include "sample_utilities.h"
#include "sqlqg_utils.h"
#include "sqlcodes.h"
#include <string.h>

/**************************************************************************
*
*  Function Name  = FencedSample_Nickname::FencedSample_Nickname
*
*  Function: FencedSample_Nickname class constructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  sqluint8* schema_name: Scehma name
*          sqluint8* nickname_name: Nickname name
*          FencedServer* nickname_server: server associated with nickname
*
*  Output: (required) sqlint32 *rc - return code
*
*  Normal Return = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
FencedSample_Nickname::FencedSample_Nickname(sqluint8 * schema, 
                     sqluint8* nickname_name, FencedServer* nickname_server, 
                     sqlint32 *rc)
    :Fenced_Generic_Nickname(schema, nickname_name, nickname_server, rc)
{
   Wrapper_Utilities::fnc_entry(80,"FencedSample_Nickname::FencedSample_Nickname");
   Wrapper_Utilities::fnc_exit(80,"FencedSample_Nickname::FencedSample_Nickname", *rc);
}

/**************************************************************************
*
*  Function Name  = FencedSample_Nickname::~FencedSample_Nickname
*
*  Function: FencedSample_Nickname class destructor
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
FencedSample_Nickname::~FencedSample_Nickname()
{
   Wrapper_Utilities::fnc_entry(81,"FencedSample_Nickname::~FencedSample_Nickname");
   Wrapper_Utilities::fnc_exit(81,"FencedSample_Nickname::~FencedSample_Nickname", 0);
}

/**************************************************************************
*
*  Function Name  = FencedSample_Nickname::verify_my_register_nickname_info
*
*  Function: Checks nickname information on a CREATE NICKNAME DDL statement.
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
sqlint32 
FencedSample_Nickname::verify_my_register_nickname_info( Nickname_Info* nickname_info,
                                                         Nickname_Info** delta_info)
{
    sqlint32       rc = 0;
    Catalog_Option *catalog_option = NULL;
    myboolean      option_found = NO;
    sqluint8       *nickname_name = NULL;
    
    Wrapper_Utilities::fnc_entry(82,"FencedSample_Nickname::verify_my_register_nickname_info");
    FencedSample_Server *srv = (FencedSample_Server *)get_server();
    sqluint8            *serverName = srv->get_name();

    rc = Sample_Utilities::verify_column_type_and_options(this, nickname_info, serverName);
    if (rc) 
    {
      Wrapper_Utilities::trace_error(82,"FencedSample_Nickname::verify_my_register_nickname_info", 
                           10, sizeof(rc), &rc);
      goto exit;
    }
       

    //----------------------------------------------------------------------
    //
    // This nickname must be registered with the FILE_PATH option. 
    // 
    // ----------------------------------------------------------------------

    // Walk through the list of options supplied in the DDL. If an option is found that 
    // and it is not known to this wrapper or to DB2, report an error.   

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
           option_found = YES;
        }
        // The option found in the catalog (specified in ddl)might be DB2 (reserved) option
        // if not, complain
        else
        if (!is_reserved_nickname_option((sqluint8 *)catalog_option_name))
        {
            // This option is not valid - report an error
            
            // Get the nickname name
            nickname_info->get_nickname(&nickname_name);
            
            rc = Wrapper_Utilities::report_error("FSN_VMR", SQL_RC_E1881, 3, 
                                    strlen(catalog_option_name), catalog_option_name, 
                                    strlen("Nickname"), "Nickname", 
                                    strlen((const char *) nickname_name), nickname_name);

            Wrapper_Utilities::fnc_data2(82,"FencedSample_Nickname::verify_my_register_nickname_info", 20, 
                                        strlen((char *)catalog_option_name), (char *)catalog_option_name, 
                                        strlen((const char *)nickname_name), (const char *)nickname_name);

            Wrapper_Utilities::trace_error(82,"FencedSample_Nickname::verify_my_register_nickname_info", 
                                  20, sizeof(rc), &rc);
            goto exit;
        }
        
        catalog_option = nickname_info->get_next_option(catalog_option);   
    }
     
    // If we the FILE_PATH_OPTION is not found, go complaing.
      
    if (option_found == NO )
    {
      
      nickname_info->get_nickname(&nickname_name);
       rc = Wrapper_Utilities::report_error("FSN_VMR", SQL_RC_E1883, 3,
                                strlen(FILE_PATH_OPTION), FILE_PATH_OPTION, 
                                strlen("Nickname"), "Nickname", 
                                strlen((const char*) nickname_name), (const char*) nickname_name);

       Wrapper_Utilities::fnc_data2(82,"FencedSample_Nickname::verify_my_register_nickname_info", 30, 
                                   strlen(FILE_PATH_OPTION), FILE_PATH_OPTION, 
                                   strlen((const char *)nickname_name), (const char *)nickname_name);

       Wrapper_Utilities::trace_error(82,"FencedSample_Nickname::verify_my_register_nickname_info", 
                             30, sizeof(rc), &rc);
       goto exit;
    }
    
   // For the time being, all generic nicknames are marked as read_only..
   if (*delta_info == NULL)
   {
      *delta_info = new (&rc) Nickname_Info;
      if(rc!=0)
      {
        rc = sample_report_error_1822(rc, "Memory allocation error.",
                             40, "SW_CS");
        Wrapper_Utilities::trace_error(82,"FencedSample_Nickname::verify_my_register_nickname_info", 
                             40, sizeof(rc), &rc);
        goto exit;
      }
   }
   rc = (*delta_info)->add_option ((sqluint8*)"READ_ONLY",
                                   strlen("READ_ONLY"),
                                   (sqluint8*)"Y", 1);
   
exit:
    
    Wrapper_Utilities::fnc_exit(82,"FencedSample_Nickname::verify_my_register_nickname_info", rc);
    return rc;
}

