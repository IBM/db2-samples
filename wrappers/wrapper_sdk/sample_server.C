/**********************************************************************
*
*  Source File Name = sample_server.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for unfenced sample server class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_server.h"
#include "sample_wrapper.h"
#include "sample_utilities.h"
#include "sample_error_reporting.h"

#include "sqlqg_catalog.h"
#include "sqlqg_utils.h"
#include "sqlcodes.h"
#include "sqlqg_request.h"
#include "sqlqg_runtime_data_operation.h"
#include <string.h>
#include <ctype.h>

class Unfenced_Generic_Nickname;

/**************************************************************************
*
*  Function Name  = Sample_Server::Sample_Server
*
*  Function: Sample Server Constructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  sqluint8       *server_name
*          Wrapper        *server_wrapper
*
*  Output: sqlint32        *rc
*
*  Normal Return = rc = 0
*
*  Error Return = rc != 0
*
**************************************************************************/
Sample_Server::Sample_Server(sqluint8* server_name, UnfencedWrapper* server_wrapper,
                                 sqlint32* rc)
  : Unfenced_Generic_Server(server_name, server_wrapper, rc)
{
   Wrapper_Utilities::fnc_entry(10,"Sample_Server::Sample_Server");
   Wrapper_Utilities::fnc_exit(10,"Sample_Server::Sample_Server", *rc);
}

/**************************************************************************
*
*  Function Name  = Sample_Server::~Sample_Server
*
*  Function: Sample Server Destructor
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  N/A
*
*  Output: N/A
*
*  Normal Return = N/A
*
*  Error Return =  N/A
*
**************************************************************************/
Sample_Server::~Sample_Server()
{
   Wrapper_Utilities::fnc_entry(11,"Sample_Server::~Sample_Server");
   Wrapper_Utilities::fnc_exit(11,"Sample_Server::~Sample_Server", 0);
}

/**************************************************************************
*
*  Function Name  = Sample_Server::verify_my_register_server_info()
*
*  Function: Check server info for validity for servers.
*            This function verifies that info specified on a CREATE SERVER
*            DDL statement is correct.
*            This wrapper accepts only the following for of CREATE SERVER:
*            CREATE SERVER <server_name> WRAPPER <wrapper_name>
*            No type and no version are allowed for this wrapper
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  Server_Info *server_info: catalog information about server.
*
*  Output: Server_Info **delta_info: any additional information to be
*                                    stored about the server.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Server::verify_my_register_server_info(Server_Info* server_info,
                                                     Server_Info** delta_info)
{
    sqlint32          rc = 0;
    char              *func_name = "SS_VMR"; // for the error macro
    sqluint8          *server_type = NULL;
    sqluint8          *serverVersion = NULL;
    Catalog_Option    *option = NULL;
    sqluint8          *option_name = NULL;
    sqluint8          *server_name = NULL;

    Wrapper_Utilities::fnc_entry(12,"Sample_Server::verify_my_register_server_info");
    //  The sample wrapper doesn't require any option of its own but might accept an option 
    // if it is known to be a DB2 option.

    // Get the TYPE of server
    rc = server_info->get_server_type(&server_type);
    
    // The sample wrapper doesn't require the server_type when creating the server. 
    // an rc of SQLQG_NOVALUE means that the srever_type wasn't set. 
    
    switch (rc)
    {
       case SQLQG_NOVALUE :
       {  
          rc = 0;
          break;
       }
       default            : 
       {
          Wrapper *wrapper = this->get_wrapper();
          sqluint8 *wrapperName = wrapper->get_name();
          
          rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1816, 3,
                                             strlen((const char *)wrapperName),(const char *)wrapperName, 
                                             strlen("type"),"type", 
                                             strlen((const char *)server_type),(const char *)server_type); 

          Wrapper_Utilities::fnc_data2(12,"Sample_Server::verify_my_register_server_info", 10, 
                                      strlen((char *)wrapperName), (char *)wrapperName, 
                                      strlen((const char *)server_type), (const char *)server_type);

          Wrapper_Utilities::trace_error(12,"Sample_Server::verify_my_register_server_info", 
                                        10, sizeof(rc), &rc);
          goto exit;
       }
    }
    
    // Get the VERSION of server
    rc = server_info->get_server_version(&serverVersion);
    
    // The sample wrapper doesn't require the serverVersion when creating the server. 
    // an rc of SQLQG_NOVALUE means that the sreverVersion wasn't set. 
    
    switch (rc)
    {
       case SQLQG_NOVALUE :
       {  
          rc = 0;
          break;
       }
       default            : 
       {
          Wrapper *wrapper = this->get_wrapper();
          sqluint8 *wrapperName = wrapper->get_name();
          
          rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1816, 3,
                                             strlen((const char *)wrapperName),(const char *)wrapperName, 
                                             strlen("version"),"version", 
                                             strlen((const char *)serverVersion),(const char *)serverVersion); 
          Wrapper_Utilities::fnc_data2(12,"Sample_Server::verify_my_register_server_info", 20, 
                                      strlen((char *)wrapperName), (char *)wrapperName, 
                                      strlen((char *)serverVersion), (char *)serverVersion);

          Wrapper_Utilities::trace_error(12,"Sample_Server::verify_my_register_server_info", 
                                        20, sizeof(rc), &rc);
         
          goto exit;
       }
    }
    
    // verify that the options are known to db2.
    
    option = server_info->get_first_option();
    while (option != NULL) 
    {
      option_name = option->get_name();
      if (!is_reserved_server_option(option_name)) 
      {
         server_info->get_server_name(&server_name);
         rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1881, 3,
                                     strlen((char *)option_name), option_name,
                                     strlen(SQLQG_SERVER_OPTION), SQLQG_SERVER_OPTION,
                                     strlen((char *)server_name), server_name);

         Wrapper_Utilities::fnc_data2(12,"Sample_Server::verify_my_register_server_info", 30, 
                                     strlen((char *)option_name), (char *)option_name, 
                                     strlen((char *)server_name), (char *)server_name);

         Wrapper_Utilities::trace_error(12,"Sample_Server::verify_my_register_server_info", 
                                       30, sizeof(rc), &rc);
       
         goto exit;
      }
       option = server_info->get_next_option(option);
    }

exit:
    Wrapper_Utilities::fnc_exit(12,"Sample_Server::verify_my_register_server_info", rc);
    return rc;

}

/**************************************************************************
*
*  Function Name  = Sample_Server::verify_my_alter_server_info()
*
*  Function: Check server info for validity for server.
*            This function verifies that info specified on a CREATE SERVER
*            DDL statement is correct.
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  Server_Info *server_info: catalog information about server.
*
*  Output: Server_Info **delta_info: any additional information to be
*                                    stored about the server.
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
sqlint32 Sample_Server::verify_my_alter_server_info(Server_Info* server_info,
                                                    Server_Info** delta_info)
{
    sqlint32        rc = 0;
    char            *func_name = "SS_VMA"; // for the error macro
    sqluint8        *server_type = NULL;
    sqluint8        *serverVersion = NULL;
    Catalog_Option  *option = NULL;
    sqluint8        *option_name=NULL;
    sqluint8        *server_name=NULL;
    
    Wrapper_Utilities::fnc_entry(13,"Sample_Server::verify_my_alter_server_info");
    //  The sample wrapper doesn't require any option of its own but might accept an option 
    // if it is known to be a DB2 option.
      
    // Get the TYPE of server
    
    rc = server_info->get_server_type(&server_type);
      
    // The sample wrapper doesn't require the server_type when creating the server. 
    // an rc of SQLQG_NOVALUE means that the srever_type wasn't set. 
      
    switch (rc)
    {
       case SQLQG_NOVALUE :
       {  
          rc = 0;
          break;
       }
       default            : 
       {
          Wrapper *wrapper = this->get_wrapper();
          sqluint8 *wrapperName = wrapper->get_name();
    
          rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1816, 3, 
                               strlen((const char *)wrapperName), (const char *)wrapperName, 
                               strlen("type"),"type", 
                               strlen((const char *)server_type),(const char *)server_type);
    
          Wrapper_Utilities::fnc_data2(13,"Sample_Server::verify_my_alter_server_info", 40, 
                                      strlen((char *)wrapperName), (char *)wrapperName, 
                                      strlen((char *)server_type), (char *)server_type);
    
          Wrapper_Utilities::trace_error(13,"Sample_Server::verify_my_alter_server_info", 
                                        40, sizeof(rc), &rc);
          goto exit;
        }
    }
    
    // Get the VERSION of server
    rc = server_info->get_server_version(&serverVersion);
      
    // The sample wrapper doesn't require the serverVersion when creating the server. 
    // an rc of SQLQG_NOVALUE means that the sreverVersion wasn't set. 
      
    switch (rc)
    {
       case SQLQG_NOVALUE :
       {  
          rc = 0;
          break;
       }
       default            : 
       {
            Wrapper *wrapper = this->get_wrapper();
            sqluint8 *wrapperName = wrapper->get_name();
            
            rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1816, 3,
                                               strlen((const char *)wrapperName),(const char *)wrapperName, 
                                               strlen("version"),"version", 
                                               strlen((const char *)serverVersion),(const char *)serverVersion); 
    
            Wrapper_Utilities::fnc_data2(13,"Sample_Server::verify_my_alter_server_info", 50, 
                                        strlen((char *)wrapperName), (char *)wrapperName, 
                                        strlen((char *)serverVersion), (char *)serverVersion);
    
            Wrapper_Utilities::trace_error(13,"Sample_Server::verify_my_alter_server_info", 
                                          50, sizeof(rc), &rc);
            goto exit;
    
       }
    }
      
    // verify that the options are known to db2.
    
    option = server_info->get_first_option();
    while (option != NULL) 
    {
      option_name = option->get_name();
      if (!is_reserved_server_option(option_name))
      {
        server_info->get_server_name(&server_name);
        rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1881, 3,
                                     strlen((char *)option_name), option_name,
                                     strlen(SQLQG_SERVER_OPTION), SQLQG_SERVER_OPTION,
                                     strlen((char *)server_name), server_name);
    
        Wrapper_Utilities::fnc_data2(13,"Sample_Server::verify_my_alter_server_info", 60, 
                                    strlen((char *)option_name), (char *)option_name, 
                                    strlen((char *)server_name), (char *)server_name);
    
        Wrapper_Utilities::trace_error(13,"Sample_Server::verify_my_alter_server_info", 
                                      60, sizeof(rc), &rc);
        goto exit;
      }
      option = server_info->get_next_option(option);
    }

exit: 
    Wrapper_Utilities::fnc_exit(13,"Sample_Server::verify_my_alter_server_info", rc);
    return rc;

}


/**************************************************************************
*
*  Function Name  = Sample_Server::create_nickname()
* 
*  Function: Method to construct new nickname for a server.
*
*  Input: sqluint8* name: name of nickname
*         Server* server: server with which nickame is associated.
*
*  Output: Remote_Nickname** nickname: newly created nickname
*
*  Normal Return = 0
*
*  Error Return =
*
**************************************************************************/
Nickname* Sample_Server::create_nickname(sqluint8 *schema_name,
				       sqluint8 *nickname_name,
				       sqlint32 *xrc)
{
    sqlint32 rc=0;
    Sample_Nickname *n = NULL;
    Wrapper_Utilities::fnc_entry(14,"Sample_Server::create_nickname");
    
    // Create an instance of the Sample Nickname subclass
    n  =  new (&rc) Sample_Nickname(schema_name, nickname_name, this, &rc);
    if(rc!=0)
    {
        rc = sample_report_error_1822(rc, "Memory allocation error.",
                           70, "SS_CN");
        Wrapper_Utilities::trace_error(14,"Sample_Server::create_nickname", 
                           70, sizeof(rc), &rc);
    }
    
    *xrc = rc;
    Wrapper_Utilities::fnc_exit(14,"Sample_Server::create_nickname", rc);
    return(n);
}


/**************************************************************************
*
*  Function Name  = Sample_Server::plan_request()
* 
*  Function: Generates a reply and execution description
*
*  Input: Request
*
*  Output: Reply
*
*  Normal Return = 0
*
*  Error Return = non 0
*
**************************************************************************/
sqlint32 Sample_Server::plan_request(Request *rq, Reply **rep)
{
   sqlint32               rc = 0;
   sqlint32               trace_error = 0;
   char                   *column_name = NULL; 
   char                   *exec_desc = NULL; 
   char                   *curr_ptr = NULL; // these cannot be void - need pointer arithmetics
   char                   *filePath = NULL;
   char                   *token = NULL;
   char                   *SearchTerm = NULL;
   char                   seatch_term_const[MAX_VARCHAR_LENGTH];
   int                    i = 0; 
   int                    l = 0; 
   int                    len = 0;
   int                    KeyVector = 0;
   char                   *KeyColumn = NULL;
   int                    KeyColumlen = 0;
   int                    ColumnVectorSize = 0; 
   int                    handle = 0;
   int                    index = 0;
   int                    NumColumns = 0;
   int                    NumPredicts = 0;
   int                    *ColumnVector = NULL;
   sqlint32               SearchTermLen = 0;
   int                    BindIndex = -1;
   int                    UnboundIndex = 0;
   Sample_Nickname        *nickname = NULL;
   Nickname_Info          *nickname_info = NULL;
   relOperator            PredOperator = ALL_ROWS;
   Request_Exp            *rExp = NULL; 
   Request_Exp::kind      c1k, c2k, arg_kind, rExp_kind;
   Request_Exp            *c1p = NULL, *c2p = NULL, *argP = NULL, *columnP = NULL;
   Sample_Exec_Descriptor *fedsP = NULL;
   Request_Constant       *value = NULL;
   columnData             *Data = NULL;
   Unfenced_Generic_Nickname *gu_nickname = NULL;
   char                   *func_name = "SS_PR"; // for the error macro

  
   Wrapper_Utilities::fnc_entry(15,"Sample_Server::plan_request");
   *rep = NULL; //No plan done yet
   
   if (rq == NULL)  //sanity check
   {
       rc = sample_report_error_1822(rc, "Internal error: Request not recieved.", 100, func_name);
       trace_error = 100;  
       goto exit;
   
   }
 
   // No parameters and joins! Only 1 nickname at a time
   if( rq->get_number_of_quantifiers() > 1)
   {
       goto exit; //Success - it is not an error when the wrapper returns no plan.
   }
     
   rc = create_reply(rq, rep); //Create new reply
   if (rc) 
   {
       trace_error = 110;  
       goto error;
   }
 
   if (rep == NULL)  //sanity check
   {
       rc = sample_report_error_1822(rc, "Internal error: Create reply failed.", 120, func_name);
       trace_error = 120;  
       goto error;
   }

////////////////////////////////////////////////////////////////////////////////
// NICKNAMES in the FROM clause, and misc preparations
////////////////////////////////////////////////////////////////////////////////

// Take care only of the first quantifier, ignore the rest
   rc = rq->get_quantifier_handle(1, &handle);
   if (rc) 
   {
      trace_error = 130;  
      goto error;
   }
   
   rc = rq->get_nickname(handle, &gu_nickname);
   if (rc) 
   {
      trace_error = 140;  
      goto error;
   }
   
   nickname = (Sample_Nickname*) gu_nickname;
   if (nickname == NULL) //Table function
   {
      goto exit; //Cannot handle table functions..
   }
   
   rc = (*rep)->add_quantifier(handle);
   if (rc) 
   {
      trace_error = 150;  
      goto error;
   }
   
   // Get the path to the data file, if null return an error to DB2
   rc = nickname->get_file_path((sqluint8 **)&filePath);
   if (rc) 
   {
      trace_error = 160;  
      goto error;
   }
   
   if (filePath == NULL)  // sanity check
   {
       rc = Wrapper_Utilities::report_error(func_name,
               SQL_RC_E901, 1,strlen(NULL_PATH), NULL_PATH);
       trace_error = 170;  
       goto error;
   }
   
   Wrapper_Utilities::fnc_data(15,"Sample_Server::plan_request", 175, 
                                 strlen(filePath), filePath);
   // Get a reference for the nickname_info object.  This is used to find out 
   // information about data source.
   rc = nickname->get_nickname_info(&nickname_info);
   
   if ((rc != 0) || (nickname_info == NULL))  //sanity check
   {
      rc = sample_report_error_1822(rc, "Internal error: Failed in getting nickname info.", 
                                    180, func_name);
      trace_error = 180;  
      goto exit;
   }
   
   // Save the number of columns in this data source.  This is used to determine the
   // size of the token and columnData arrays.  It will also be used to calculate the
   // minimum row size which will be used by various searching functions.
   NumColumns = nickname_info->get_number_columns();
   
   //Prepare the return buffers info - no alloc here, that is done during 'open'
   rc = prepare_data_area(nickname_info, Data, NumColumns);
   if (rc) 
   {
      trace_error = 190;  
      goto error;
   }


////////////////////////////////////////////////////////////////////////////////
// PREDICATES
////////////////////////////////////////////////////////////////////////////////
    // This wrapper only handle predicates like column='cst' or 'cst'=column
    // or column = unbound or unbound = column
    // and only support one predicate
    NumPredicts=rq->get_number_of_predicates();
    
    //We only support one predicate, choose one that is valid for our conditions from all predicates
    for( i=1; i <= NumPredicts; i++)
    {
      //get the predicate    
       rc = rq->get_predicate_handle(i, &handle);
       if (rc)
       {
          trace_error = 210;
          goto error;
       }
       
       rc = rq->get_predicate(handle, &rExp);
       if (rc)
       {
          trace_error = 220;  
          goto error;
       }
      
       rc = rExp->get_kind(rq, &rExp_kind);
       if (rc)
       {
          trace_error = 230;  
          goto error;
       }
       
       //We like only predicates that have an operator and 2 children
       if (rExp_kind == Request_Exp::oper &&  rExp->get_number_of_children() == 2)
       {
          rExp->get_token(&token, &len);                                                                   
          //can be used only in conjunction with '=' operator                             
          if( len == 1 && token[0] == '=' )                                                                
          {             
             //Get the operands
             c1p = rExp->get_first_child();
             c2p = c1p->get_next_child();
             
             //Get the kinds of the operands
             rc = c1p->get_kind(rq, &c1k);
             if (rc)
             {
                trace_error = 250;  
                goto error;
             }
             rc = c2p->get_kind(rq, &c2k);
             if (rc)
             {
                trace_error = 260;  
                goto error;
             }
             
             // predicates of form column = 'cst' or 'cst' = column or unbound = column
             // or column = unbound only
             if(c1k == Request_Exp::column &&
                 (c2k == Request_Exp::constant || c2k == Request_Exp::unbound))
             {
                columnP = c1p; argP = c2p; arg_kind = c2k;
             }           
             else  if(c2k == Request_Exp::column &&
                 (c1k == Request_Exp::constant || c1k == Request_Exp::unbound))
             {
                columnP = c2p; argP = c1p; arg_kind = c1k;
             }
             else
             {
             	 continue;
             }
             
             KeyVector = -1;
     	     rc = columnP->get_column_name((char **)&KeyColumn,&KeyColumlen);
     	     
     	     if (rc)
     	     {
     	        trace_error = 270;
     	        goto error;
     	     }
     	     
     	     //Get the number of the column
     	     for (i=0; i < NumColumns; i++)
     	     {
     	        if (strncmp(KeyColumn,(const char *)Data[i].name,KeyColumlen) == 0)
     	        {
     	           KeyVector = i;
     	           break;
     	        }
     	     }
     	     
             //Can not find the column name
             if(KeyVector<0)
             {
                rc = Wrapper_Utilities::report_error(func_name,
                           SQL_RC_W206, 1,strlen(BAD_COLUMN), BAD_COLUMN);
                trace_error = 280;
     	        goto error;
             }
             
             //Get the value of the constant
             if(arg_kind == Request_Exp::constant) //form column = 'cst' or 'cst' = column
     	     {
                rc = argP->get_value(&value);
                if (rc)
                {
                   trace_error = 290;
                   goto error;
                }
                
                memset(seatch_term_const,'\0', MAX_VARCHAR_LENGTH);
                SearchTerm = seatch_term_const;
                rc = Sample_Utilities::convert_data(
                              value->get_data_type(),
                              value->get_data(),
                              value->get_actual_length (),
                              value->get_precision (),
                              value->get_scale (),
                              SearchTerm,
                              &SearchTermLen);
                if (rc)
                {
                   trace_error = 300;
                   goto error;
                }
             } 
             else   //form column = unbound or unbound = column
     	     {
     	        BindIndex = UnboundIndex++;
     	     }
             
             
             //Add the predicate to the reply
             rc = (*rep)->add_predicate(handle);
             if (rc)
             {
                trace_error = 320;
                goto error;
             }
             
             PredOperator = SQL_EQ;
             break;
          }
       }
    }
////////////////////////////////////////////////////////////////////////////////
// HEAD EXPRESSIONS
////////////////////////////////////////////////////////////////////////////////

 // Allocate space for the column vector array.  This is an array of integers.
 // Each integer represents the relative position of the column requested by
 // DB2 (relative to zero).  The array is terminated by -1.

   ColumnVectorSize = NumColumns+1;
   
   rc = Wrapper_Utilities::allocate(sizeof(int) * (ColumnVectorSize + 1),
                                    (void **)&ColumnVector); 
   if (rc)
   {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 340, func_name);
       trace_error = 340;  
       goto exit;
   }
      
   // Initialize the column vectors to -1
   for (i = 0; i <= ColumnVectorSize; i++)
   {
       ColumnVector[i] = -1;
   }
   
   
   // Build the column vector array.  Get the name of each column request by the DB2 
   // query.  Loop thru the column data array looking for the matching column name.
   // When found store in the column vector the relative position of the requested
   // column in the column data array. 
   
   for(i=1; i <= rq->get_number_of_head_exp(); i++)
   {
      rc = rq->get_head_exp_handle(i, &handle);
      if (rc) 
      {
         trace_error = 350;  
         goto error;
      }
      rc = rq->get_head_exp(handle, &rExp);
      if (rc) 
      {
         trace_error = 360;  
         goto error;
      }
      //Take care only of the columns
      if(rExp != NULL)
      {
         rc = rExp->get_kind(rq, &rExp_kind);
         if (rc) 
         {
            trace_error = 370;  
            goto error;
         }
      }
      
      if(rExp != NULL &&  rExp_kind == Request_Exp::column)
      {     
         // add this column to the reply
         rc = rq->get_head_exp_handle(i, &handle);
         if (rc) 
         {
            trace_error = 380;  
            goto error;
         }
         rc = (*rep)->add_head_exp(handle);
         if (rc) 
         {
            trace_error = 390;  
            goto error;
         }
         
         //get the name of the column and its length 
         rExp->get_column_name(&column_name, &len);
         
         Wrapper_Utilities::fnc_data2(15,"Sample_Server::plan_request", 400, 
                                    strlen(column_name), column_name,
                                    sizeof(len), &len);
         
         for (l = 0;  l < NumColumns; l++)
         {
            if ( (strncmp(column_name,(char *)Data[l].name, len) == 0) &&
                 (len == (int) strlen((char *)Data[l].name)) )
            {
               ColumnVector[i-1] = l;
               break;
            }
         }
         if (ColumnVector[i-1]  == -1)
         {
            rc = sample_report_error_1822(rc, BAD_COLUMN, 410, func_name);
            trace_error = 410;  
            goto exit;
         }
      }
   }
 
////////////////////////////////////////////////////////////////////////////////
// PACKING 
////////////////////////////////////////////////////////////////////////////////
 
  //Packing of the execution descriptor in a continuous memory block
  //The fixed length pieces are stored as parts of a structure of
  //type Sample_Exec_Descriptor. The variable size pieces are stored after this struct
  
  
  //Determine the total length
  len = sizeof(Sample_Exec_Descriptor) +            //The Sample_Exec_Descriptor instance
          sizeof(int) * (NumColumns + 1)  +         //The size of mColumnVector
          sizeof(columnData) * NumColumns +         //Size of the columnData vector
          strlen(filePath) + 1 +                    //The file path string
          SearchTermLen + 1;                        //SearchTermLen string
  
  //allocate the memory
  rc = Wrapper_Utilities::allocate(len, (void**) &exec_desc);
  if (rc)
  {
      rc = sample_report_error_1822(rc, "Memory allocation error.", 420, func_name);
      trace_error = 420;  
      goto exit;
  }
   
  (*rep)->set_exec_desc(exec_desc, len);
  
  //set the fixed length pieces of the execution descriptor
  fedsP = (Sample_Exec_Descriptor*) exec_desc;
  fedsP->mNumColumns =  NumColumns;
  fedsP->mPredOperator =  PredOperator;
  fedsP->mKeyVector = KeyVector;
  fedsP->mBindIndex = BindIndex;
  
  
  //store the variable length pieces
  curr_ptr = exec_desc + sizeof(Sample_Exec_Descriptor);
  store_and_advance(curr_ptr, ColumnVector, sizeof(int) * (NumColumns + 1));
  store_and_advance(curr_ptr, Data,              sizeof(columnData) * NumColumns);
  store_and_advance(curr_ptr, filePath,          strlen(filePath)+1);
  
  if(SearchTerm)
  {
     store_and_advance(curr_ptr, SearchTerm,   SearchTermLen);
     *((char *)curr_ptr) = '\0'; //null terminate SearchTerm
  }
  
  //delete the allocated storage
  Wrapper_Utilities::deallocate(ColumnVector);           
  Wrapper_Utilities::deallocate(Data);                  

exit:
   //exit 
   Wrapper_Utilities::fnc_exit(15,"Sample_Server::plan_request", rc);
   return rc;


error:
   //report error and goto exit
   Wrapper_Utilities::trace_error(15,"Sample_Server::plan_request", 
                                 trace_error, sizeof(rc), &rc);
   goto exit;

}    


/****************************************************************************
*  Function Name =  Sample_Server::store_and_advance()
* 
*  Function: Stores a memory block into the execution handle descriptor 
*            
* 
*
*  Input: source pointer, target pointer and length
*                                                                      
*  Output: the targed pointer advanced for the length
*****************************************************************************/
inline void
Sample_Server::store_and_advance(char* &curr_ptr, void *source_ptr,int  len)
{ 
    memcpy(curr_ptr, source_ptr, len);
    curr_ptr+=len;
}

/****************************************************************************
*  Function Name =  Sample_Server::prepare_data_area()
* 
*  Function: This function will prepare the column data array based on information
*            found in the nickname_info object. At this point no buffers allocated
* 
*
*  Input: (nickname* , required) 
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Server::prepare_data_area(Nickname_Info *nickname_info, columnData* &Data,
			             int mNumColumns)
{
    Column_Info   *columnInfo = NULL;
    sqlint32      rc = 0;
    sqlint32      trace_error = 0;
    sqlint32      i = 0;
    sqluint8      *sqlType = NULL;
    
    Wrapper_Utilities::fnc_entry(16,"Sample_Server::prepare_data_area");
    // Allocate space for an array of columnData items
    // (1 for each column in the pseudo-table)
    rc = Wrapper_Utilities::allocate((sizeof(columnData) * mNumColumns),
                                     (void **)&Data);
    if (rc)
    {
        rc = sample_report_error_1822(rc, "Memory allocation error.", 300, "SS_PDA");
        trace_error = 300;  
        goto error;
    }
    
    // Get the columnInfo for the first column.  Save the column attributes (name,
    // length, and sql type in the column data array. Repeat this
    // process for each column in the pseudo-table.
    columnInfo = nickname_info->get_first_column();
    
    if (columnInfo == NULL)
    {
        rc = Wrapper_Utilities::report_error("SS_PDA",
              SQL_RC_E901, 1, strlen(COLUMN_ERROR), COLUMN_ERROR);
        trace_error = 310;  
        goto error;
    }
      
    while (columnInfo != NULL)
    {
      // Save the column name
      rc = columnInfo->get_column_name(&Data[i].name);
      if (rc) 
      {
        trace_error = 320;  
        goto error;
      }
      // Save the column length
      rc = columnInfo->get_org_length(&Data[i].len);
      if (rc) 
      {
        trace_error = 330;  
        goto error;
      }
      // Get the sql data type name
      rc = columnInfo->get_type_name(&sqlType);  
      if (rc) 
      {
        trace_error = 340;  
        goto error;
      }
      Wrapper_Utilities::fnc_data3(16,"Sample_Server::prepare_data_area", 345, 
                                  strlen((const char*)Data[i].name), (const char *)Data[i].name,
                                  sizeof(Data[i].len), &Data[i].len, 
                                  strlen((const char *)sqlType), (const char *)sqlType);

      // If the data type is INTEGER
      if (strcmp((char *)sqlType,"INTEGER") == 0)
      {
          Data[i].type = SQL_INTEGER;
      }
      else
      // If the data type is DOUBLE
      if (strcmp((char *)sqlType,"DOUBLE") == 0)
      {
         Data[i].type = SQL_DOUBLE;
      }
      else
      // If the data type is DECIMAL
      if (strcmp((char *)sqlType,"DECIMAL") == 0)
      {
         Data[i].type = SQL_DECIMAL;
         sqlint16    scale = 0;
         rc = columnInfo->get_org_scale(&scale);
         if (rc) 
         {
           trace_error = 350;  
           goto error;
         }
         Data[i].scale = scale;
         rc = columnInfo->get_org_length((sqlint32 *)&Data[i].precision);
         if (rc) 
         {
           trace_error = 360;  
           goto error;
         }
      }
      else    
      // If the data type is CHAR 
      if (strcmp((char *)sqlType,"CHARACTER") == 0)
      {
         Data[i].type = SQL_CHAR; 
      }
      else
      if (strcmp((char *)sqlType,"VARCHAR") == 0)
      {
         Data[i].type = SQL_VARCHAR;
      }       
      else
      {
         // sanity check
         rc = sample_report_error_1822(rc, "Wrong column data type", 370, "SS_PDA"); 
         Wrapper_Utilities::trace_error(16,"Sample_Server::prepare_data_area", 
                                       370, sizeof(rc), &rc);
         goto error;
       }

      // Get the next column  
      columnInfo = nickname_info->get_next_column(columnInfo);
      i++;
    }                      

exit:
    Wrapper_Utilities::fnc_exit(16,"Sample_Server::prepare_data_area", rc);
    return rc;

error:
  Wrapper_Utilities::trace_error(16,"Sample_Server::prepare_data_area", 
                                trace_error, sizeof(rc), &rc);
  goto exit;
}

sqlint32 Sample_Server::null_terminate(char *instring, int len, char** outstring)
{
  sqlint32 rc = 0;
  
  char *null_term_buff = NULL;
  Wrapper_Utilities::fnc_entry(17,"Sample_Server::null_terminate");
  
  rc = Wrapper_Utilities::allocate(len+1, (void **) &null_term_buff);
  if (rc)
  {
      rc = sample_report_error_1822(rc, "Memory allocation error.", 400, "SS_NT");
      Wrapper_Utilities::trace_error(17,"Sample_Server::null_terminate", 
                                    400, sizeof(rc), &rc);
      goto exit;
  }
  
  strncpy(null_term_buff, instring, len);
  null_term_buff[len] = '\0';
  *outstring = null_term_buff;

exit:
  Wrapper_Utilities::fnc_exit(17,"Sample_Server::null_terminate", rc);
  return(rc);
  
}
