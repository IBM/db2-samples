/**********************************************************************
*
*  Source File Name = sample_operation.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for sample operation class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_operation.h"
#include "sample_portability.h"
#include "sample_utilities.h"
#include "sample_error_reporting.h"
#include "sample_fenced_server.h"
#include <string.h>

/****************************************************************************
* Function Name =  Sample_Query::Sample_Query
* 
*  Function: Constructor for new Sample query
* 
*  Input: active_connection: connection to server
*         runtime_query: UDB runtime operator info for query
* 
*  Output: Remote_Query != NULL : Success
*          Remote_Query == NULL : failure
*
*****************************************************************************/
Sample_Query::Sample_Query(Remote_Connection *active_connection,
                       Runtime_Operation *runtime_query, sqlint32 *rc)
  :Remote_Query(active_connection, runtime_query, rc),
  mColumnVector (NULL), mData (NULL), mFile (NULL), mNumColumns (0),
  mExecDesc(NULL), mFinished (NO), mTokens (NULL)
{
    char *func_name = "SQSQC";
    
    Wrapper_Utilities::fnc_entry(100,"Sample_Query::Sample_Query");
    
    mPredOperator = ALL_ROWS;
    mKeyVector=-1;
    mResult = NO_MATCH;
    mSearchTerm = NULL;
    mFilePath = NULL;
    mBindIndex = -1;
    memset(mSearchTermBind, '\0', MAX_VARCHAR_LENGTH);
    
    // Bail out if an error occure in the base class constructor 
    if (*rc) goto exit;
    
    *rc = Wrapper_Utilities::allocate(MAX_LINE_SIZE, (void**) &mBuffer);
    if (*rc)
    {
       *rc = sample_report_error_1822(*rc, "Memory allocation error.", 10, func_name);
       Wrapper_Utilities::trace_error(100,"Sample_Query::Sample_Query", 
                           10, sizeof(*rc), rc);
       goto exit;
    }
    
exit:
    Wrapper_Utilities::fnc_exit(100,"Sample_Query::Sample_Query", *rc);
}

/****************************************************************************
*  Function Name =  Sample_Query::~Sample_Query
* 
*  Function: Destructor for Sample_Query class
* 
*  Input: None
* 
*  Output: None
*****************************************************************************/
Sample_Query::~Sample_Query()
{
    
    sqlint32 i = 0 ;
      
    Wrapper_Utilities::fnc_entry(101,"Sample_Query::~Sample_Query");
    // Close the data file

    if (mFile != NULL)
    {
        CLOSE_FILE(mFile);
        mFile = NULL;
    }

    // Release allocated memory back to the system.
    if (mTokens != NULL)
    {
       // If any tokens exist release the memory back to DB2
       for (i = 0; i < mNumColumns; i++)
       {
         if (mTokens[i] != NULL)
         {
            Wrapper_Utilities::deallocate(mTokens[i]);
            mTokens[i] = NULL;
         }
       }
       Wrapper_Utilities::deallocate(mTokens);
       mTokens = NULL;
    }
    
    if (mBuffer != NULL)
    {
      Wrapper_Utilities::deallocate(mBuffer);
      mBuffer = NULL; 
    }

    for ( i = 0; i < mNumColumns; i++)
    {
        if (mData[i].data != NULL)
        {
            Wrapper_Utilities::deallocate(mData[i].data);
            mData[i].data = NULL;
        }
    }
    
    if (mExecDesc != NULL)                                      
    {
      Wrapper_Utilities::deallocate(mExecDesc); 
      mExecDesc = NULL;                                             
    }      
    
    Wrapper_Utilities::fnc_exit(101,"Sample_Query::~Sample_Query", 0);
}

/****************************************************************************
*  Function Name =  Sample_Query::open()
*                                          
*  Function: Open a query to be executed. 
*                                             
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::open()
{
    Runtime_Data_List       *queryInput = NULL;
    Runtime_Data            *rt_data = NULL;
    sqlint32                rc = 0;
    sqlint32                trace_error = 0;
    struct  stat            statBuffer;
    int                     i = 0;
    char                    *ptr = NULL;
    char                    *exec_desc = NULL;
    Sample_Exec_Descriptor  *fedsP = NULL;
    char                    errorMessage[80];
    char                    errnoBuffer[20];
    FencedSample_Server     *srv = (FencedSample_Server *)get_server();
    sqluint8                *serverName = srv->get_name();

    Wrapper_Utilities::fnc_entry(102,"Sample_Query::open");
    
    memset(errorMessage, '\0', sizeof(errorMessage));
    memset(errnoBuffer,  '\0', sizeof(errnoBuffer));
    
    //unpack from the execution descriptor
    get_exec_desc((void **)&exec_desc, &i);

    //Get a copy of the execution descriptor locally
    rc = Wrapper_Utilities::allocate(i ,(void**)&mExecDesc);
    if (rc)
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 10, "SQOpen");
       trace_error = 10;
       goto error;
    }

    memcpy(mExecDesc, exec_desc, i);
    fedsP = (Sample_Exec_Descriptor *)mExecDesc;
    
    // sanity check! 
    if (fedsP == NULL) 
    {
       sample_report_error_1822(rc,"Internal error: Cannot get the plan.", 20, "SQOpen");
       trace_error = 20;
       goto error;
    }
    
    //fixed size items
    mNumColumns = fedsP->mNumColumns;
    //Can only handle column='cst' or'cst'=column or column = unbound or unbound = column predicates
    mPredOperator = fedsP->mPredOperator;
    mKeyVector = fedsP->mKeyVector;
    
    //variable size items
    mColumnVector = (int *) ((char*)mExecDesc + sizeof(Sample_Exec_Descriptor));
    mData = (columnData *) ((char *)mColumnVector + (sizeof(int) * (mNumColumns +1)));
    mFilePath = (char *)mData + (sizeof(columnData) * mNumColumns);
    mBindIndex = fedsP->mBindIndex;
    
    if (mFilePath == NULL)
    {
        rc = Wrapper_Utilities::report_error("SQOpen",
             SQL_RC_E901, 1,strlen(NULL_PATH), NULL_PATH);
        trace_error = 30;
        goto error;
    }
    
    //get the constant
    if(mPredOperator == SQL_EQ)
    {
       //constant: extract the value from the execution descriptor
       if(mBindIndex == -1)
       {
          mSearchTerm = mFilePath + strlen(mFilePath) +1;
       }
       //parameter (bind var or host var): get the value from the input
       else
       {
       	  queryInput = get_input_data(); 
          rt_data = queryInput->get_ith_value(fedsP->mBindIndex);
          
          if( !rt_data->is_data_null() )
          {
             sqlint32 mSearchTermLength = 0;
             mSearchTerm = mSearchTermBind;
          
             rc = Sample_Utilities::convert_data(           
                            rt_data->get_data_type (),
                            rt_data->get_data (),
                            rt_data->get_actual_length (),
                            rt_data->get_precision (),
                            rt_data->get_scale (),
                            mSearchTerm,
                            &mSearchTermLength);
          }
          if( rc )
          {
             trace_error = 35;
             goto error;
          }
       }
    }
    
    // Check to see if we can read the file, if not return an error to DB2
    
    if  (NOT_READABLE_FILE(mFilePath))
    {
        BUILD_ERROR_MESSAGE(errorMessage);
        rc = Wrapper_Utilities::report_error("SQOpen",
             SQL_RC_E1822, 3, strlen(errorMessage), errorMessage,
             strlen((const char *)serverName), (const char *)serverName, 
             strlen(ACCESS_ERROR),ACCESS_ERROR);

        Wrapper_Utilities::fnc_data(102,"Sample_Query::open", 40, 
                               strlen((const char *)serverName), (const char *)serverName);
        trace_error = 40;
        goto error;
    }     
    
    // lstat the file, check to see if it is a non standard type file
    //(a directory, a pipe/fifo, or a socket), if so return an error to DB2
    if (CHECK_FILE_TYPE(mFilePath) < 0)
    {
        BUILD_ERROR_MESSAGE(errnoBuffer);
        strcpy(errorMessage, LSTAT_ERROR);
        strcat(errorMessage, ".  ");
        strcat(errorMessage,errnoBuffer);
        rc = Wrapper_Utilities:: report_error("SQOpen",
             SQL_RC_E901, 1, strlen(errorMessage), errorMessage);
        trace_error = 50;
        goto error;
    }
    
    if (NON_STANDARD_FILE)
    {
        rc = Wrapper_Utilities::report_error("SQOpen",
             SQL_RC_E1822, 3, strlen(DATA_ERROR), DATA_ERROR,
             strlen((const char *)serverName), (const char *)serverName, 
             strlen(NOT_FILE_ERROR), NOT_FILE_ERROR);

        Wrapper_Utilities::fnc_data(102,"Sample_Query::open", 60, 
                               strlen((const char *)serverName), (const char *)serverName);
        trace_error = 60;
        goto error;
    }

    // Open the data file for reading only.  If we can't open the file return an
    // error to DB2.
    OPEN_FILE(mFilePath,mFile);

    if (OPEN_FAILED(mFile))
    {
        BUILD_ERROR_MESSAGE(errorMessage);
        rc = Wrapper_Utilities::report_error("SQOpen",
             SQL_RC_E1822, 3, strlen(errorMessage), errorMessage,
             strlen((const char *)serverName), (const char *)serverName, 
             strlen(OPEN_ERROR), OPEN_ERROR);

        Wrapper_Utilities::fnc_data(102,"Sample_Query::open", 70, 
                               strlen((const char *)serverName), (const char *)serverName);
        trace_error = 70;
        goto error;
    }  
    
    // Allocate space for the tokens array.  We initially use a temporary pointer
    // for the allocation because passing allocate a pure ** rather than the address
    // of a pointer triggers an abend in the allocate method.
    
    rc = Wrapper_Utilities::allocate((sizeof(char *) * mNumColumns),(void**)&ptr);
    if (rc)
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 80, "SQOpen");
       trace_error = 80;
       goto error;
    }
    
    mTokens = (char **)ptr;

    // Build the columnData array.  This array will hold information describing each
    // column in the data source along with a void pointer to the any fetched data.
    rc = build_data_area(mNumColumns, mData);
    if(rc)
    {
       trace_error = 90;
       goto error;
    }
    
exit:
    Wrapper_Utilities::fnc_exit(102,"Sample_Query::open", rc);
    return rc;
    
error:
    Wrapper_Utilities::trace_error(102,"Sample_Query::open", 
                         trace_error, sizeof(rc), &rc);
    
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::reopen()
*
*  Function: Re-opens a query to be executed again.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*              != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::reopen(sqlint16 action)
{
  // This function is called to re-open a query that was previously executed. It gets called
  // when the query has a bind var (host var) in the query. Every time the bind var changes,
  // this function is called.

   sqlint32           rc = 0;
   Runtime_Data_List  *queryInput = NULL;
   Runtime_Data       *rt_data = NULL;
   mSearchTerm = NULL;
   memset(mSearchTermBind, '\0', MAX_VARCHAR_LENGTH);
   mResult = NO_MATCH;
   mFinished = NO;
   sqlint32 trace_error= 0;
   char     errorMessage[80];    
   memset(errorMessage, '\0', sizeof(errorMessage));
   FencedSample_Server     *srv = (FencedSample_Server *)get_server();
   sqluint8    *serverName = srv->get_name();
     
   Wrapper_Utilities::fnc_entry(103,"Sample_Query::reopen");
   
   
   OPEN_FILE(mFilePath,mFile);
   
   if (OPEN_FAILED(mFile))
   {
       BUILD_ERROR_MESSAGE(errorMessage);
       rc = Wrapper_Utilities::report_error("SQReOpen",
            SQL_RC_E1822, 3, strlen(errorMessage), errorMessage,
            strlen((const char *)serverName), (const char *)serverName, 
            strlen(OPEN_ERROR), OPEN_ERROR);

       Wrapper_Utilities::fnc_data(103,"Sample_Query::reopen", 10, 
                              strlen((const char *)serverName), (const char *)serverName);
       trace_error = 10;
       goto error;
   }
     
   if ( mBindIndex >= 0 )
   {
     queryInput = get_input_data(); 
     rt_data = queryInput->get_ith_value(mBindIndex);

     if( ! rt_data->is_data_null() )
     {
       sqlint32 mSearchTermLength = 0;
       mSearchTerm = mSearchTermBind;
       rc = Sample_Utilities::convert_data(           
                           rt_data->get_data_type (),
                           rt_data->get_data (),
                           rt_data->get_actual_length (),
                           rt_data->get_precision (),
                           rt_data->get_scale (),
                           mSearchTerm,
                           &mSearchTermLength
               );
     }
     if( rc )
     {
       trace_error = 20;
       goto error;
     }
   }

exit:
    Wrapper_Utilities::fnc_exit(103,"Sample_Query::reopen", rc);
    return rc;
    
error:
    Wrapper_Utilities::trace_error(103,"Sample_Query::reopen", 
                         trace_error, sizeof(rc), &rc);
    
    goto exit;
}  

/****************************************************************************
*  Function Name =  Sample_Query::fetch()
* 
*  Function: Retrieves the next row.
*                                                                      
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::fetch()
{
    sqlint32            rc=0;
    sqlint32            trace_error = 0;
    Runtime_Data_List   *queryOutput = NULL;
    Runtime_Data        *rt_data = NULL;
    sqlint32            runTimeDataCount = 0 , i = 0;
    
    Wrapper_Utilities::fnc_entry(104,"Sample_Query::fetch");
    rc = table_scan();
    if (rc) 
    {
        trace_error = 100;
        goto error;
    }
    
    // If a no eof and no error is encountered when reading the data, 
    // then get the runtime data object from runtime data list for each requested column.  
    // Set the runtime data with the data from the selected column array indexed by the 
    // integer stored in the column vector array. 
    // If eof is encounted, call report_eof to signal DB2 that we are done returning data.  
    
    if (mFinished == NO)     
    {
       queryOutput = get_output_data();
       if (!queryOutput)
       {
           rc = sample_report_error_1822(rc, "Internal error: Cannot get output data.", 
                                        110, "SQFetch"); // Sanity check
           trace_error = 110;
           goto error;
       }

        
       i = 0;
       runTimeDataCount = 0;
       
       while(mColumnVector[i] != -1)
       {
          rt_data = queryOutput->get_ith_value(runTimeDataCount);
          if (!rt_data)
          {
              rc = sample_report_error_1822(rc, "Internal error: Cannot get output data.", 
                                            100+i, "SQFetch"); // Sanity check
              trace_error = 120;
              goto error;
          }
          
          if (mData[mColumnVector[i]].data != NULL)
          {  
             if (mData[mColumnVector[i]].type == SQL_VARCHAR)
             {
                rt_data->set_data((unsigned char *)mData[mColumnVector[i]].data, 
                                   strlen((const char *)mData[mColumnVector[i]].data));
             }
             else
             if (mData[mColumnVector[i]].type == SQL_DECIMAL)
             {
                 rc = format_packed_decimal(mColumnVector[i],     
                                            rt_data->get_precision(),
                                            rt_data->get_scale());
                 rt_data->set_data((unsigned char *)mData[mColumnVector[i]].data,
                                   mData[mColumnVector[i]].len);
             }
             else 
             {
                // all other data types
                 rt_data->set_data((unsigned char *)mData[mColumnVector[i]].data, 
                                   mData[mColumnVector[i]].len);
             }
          }
          else
          {
             rt_data->set_data_null();
          }
                 
          i++;
          runTimeDataCount++;
       }
    }
    else
    {
       rc = report_eof();
    }
    
exit:
    Wrapper_Utilities::fnc_exit(104,"Sample_Query::fetch", rc);
    return rc;
    
error:
    Wrapper_Utilities::trace_error(104,"Sample_Query::fetch", 
                         trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::close()
* 
*  Function: closes a query.
*                                                                      
*  Function: 
*                                                                      
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::close(sqlint16 status)
{
  sqlint32 rc=0;
  Wrapper_Utilities::fnc_entry(105,"Sample_Query::close");
 
  Wrapper_Utilities::fnc_exit(105,"Sample_Query::close", rc);
  return rc;
}

/****************************************************************************
* Function Name =  Sample_Passthru::Sample_Passthru
* 
*  Function: Constructor for new passthru
* 
*  Input: active_connection: connection to the remote server
*         runtime_passthru: UDB runtime operator info for passthru
* 
*  Output: Remote_Passthru != NULL : Success
*          Remote_Passthru == NULL : failure
*****************************************************************************/
Sample_Passthru::Sample_Passthru(Remote_Connection *active_connection,
                                 Runtime_Operation *runtime_passthru,
                                 sqlint32 *rc)
  :Remote_Passthru(active_connection, runtime_passthru, rc)
{

    *rc = Wrapper_Utilities::report_error("SP_SPC", SQL_RC_E30090,1,2,"21");

}


/****************************************************************************
*  Function Name =  Sample_Passthru::~Sample_Passthru
* 
*  Function: Destructor for Sample_Passthru class
* 
*  Input: None
* 
*  Output: None
*****************************************************************************/
Sample_Passthru::~Sample_Passthru()
{
}

/****************************************************************************
*  Function Name =  Sample_Passthru::prepare(Runtime_Data_Desc_List*)
* 
*  Function: Prepares a Sample Passthru object.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Passthru::prepare(Runtime_Data_Desc_List*) 
{
  sqlint32 rc=0;

  rc = Wrapper_Utilities::report_error("SPPrep", SQL_RC_E30090,1,2,"21"); 
  return rc;  
}

/****************************************************************************
*  Function Name =  Sample_Passthru::describe()
* 
*  Function: Describes the results of executing a Sample Passthru object.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Passthru::describe(Runtime_Data_Desc_List *data_description_list)
{
  sqlint32 rc=0;

  rc = Wrapper_Utilities::report_error("SPDesc", SQL_RC_E30090,1,2,"21"); 
  return rc;  
}

/****************************************************************************
*  Function Name =  Sample_Passthru::execute()
* 
*  Function: Executes a Sample Passthru object.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Passthru::execute()
{
  sqlint32 rc=0;

  rc = Wrapper_Utilities::report_error("SPExec", SQL_RC_E30090,1,2,"21"); 
  return rc;  
}

/****************************************************************************
*  Function Name =  Sample_Passthru::open()
* 
*  Function: Opens a Sample Passthru object.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Passthru::open()
{
  sqlint32 rc=0;

  rc = Wrapper_Utilities::report_error("SPOpen", SQL_RC_E30090,1,2,"21");
  return rc;  
}

/****************************************************************************
*  Function Name =  Sample_Passthru::fetch()
* 
*  Function: Fetchs a row from a Sample Passthru object.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Passthru::fetch()
{
  sqlint32 rc=0;

  rc = Wrapper_Utilities::report_error("SPFetch", SQL_RC_E30090,1,2,"21"); 
  return rc;  
}  

/****************************************************************************
*  Function Name =  Sample_Passthru::close()
* 
*  Function: Closes a Sample Passthru object.
*
*  Input: (input , required) none
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Passthru::close()
{
  sqlint32 rc=0;

  rc = Wrapper_Utilities::report_error("SPClose", SQL_RC_E30090,1,2,"21"); 
  return rc;  
}   
  
/****************************************************************************
*  Function Name =  Sample_Query::build_data_area()
* 
*  Function: Allocates the buffers for each column
*            
*            
*
*  Input:  
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::build_data_area(int mNumColumns, columnData *mData)
{
    sqlint32            rc = 0;
    sqlint32            i = 0;
    sqlint32            bsize = 0;
    FencedSample_Server *srv = NULL;
    sqluint8            *serverName = NULL;
    
    Wrapper_Utilities::fnc_entry(106,"Sample_Query::build_data_area");
    for(i=0; i < mNumColumns; i++)
    {
        switch(mData[i].type)
        {
          case SQL_INTEGER:
                             bsize = sizeof(int);
                             break;
          case SQL_DOUBLE:
                             bsize = sizeof(double);
                             break;
          case SQL_DECIMAL:
                             bsize = sizeof(MAX_DECIMAL_SIZE);
                             break;
          case SQL_CHAR:
          case SQL_VARCHAR:
                             bsize = mData[i].len + 1;
                             break;
          default:
                             srv = (FencedSample_Server *)get_server();
                             serverName = srv->get_name();
                             rc = Wrapper_Utilities::report_error("SQBda", SQL_RC_E1823, 2,
                                   strlen((const char *)mData[i].name), (const char *)mData[i].name,
                                   strlen((const char *)serverName), (const char *)serverName);

                             Wrapper_Utilities::fnc_data2(106,"Sample_Query::build_data_area", 100, 
                                                  strlen((const char *)mData[i].name), (const char *)mData[i].name,
                                                  strlen((const char *)serverName), (const char *)serverName);

                             Wrapper_Utilities::trace_error(106,"Sample_Query::build_data_area", 
                                                    100, sizeof(rc), &rc);
                             goto exit;
        }
        rc = Wrapper_Utilities::allocate(bsize,(void **)&mData[i].data);
        if (rc)
        {
           rc = sample_report_error_1822(rc, "Memory allocation error.", 110, "SQBda");
           Wrapper_Utilities::trace_error(106,"Sample_Query::build_data_area", 
                                           110, sizeof(rc), &rc);
           goto exit;
        }
    }

exit:
    Wrapper_Utilities::fnc_exit(106,"Sample_Query::build_data_area", rc);
    return rc;
}

/****************************************************************************
*  Function Name =  Sample_Query::table_scan()
* 
*  Function: The table_scan function retrieves one row at a time until the end 
*            of the file is reached. 
*            When a row is read, we save the selected data elements in the
*            column data array and return to the fetch function.  The file
*            pointer is left pointing to the next row so when fetch is called
*            to return the next row the table_scan function will resume 
*            searching for matches where it had left off previously.
*
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::table_scan()
{
    sqlint32    rc = 0;  
    sqlint32    i = 0;
    
    Wrapper_Utilities::fnc_entry(107,"Sample_Query::table_scan");
    // Get and tokenize a row from the data source
    rc = get_data();
    if (rc) 
    {
        Wrapper_Utilities::trace_error(107,"Sample_Query::table_scan", 
                                        100, sizeof(rc), &rc);
        goto exit;
    }

    // If there are no more rows (mFinished set to YES by get_data()) return to fetch.
    if (mFinished == YES) return rc;
	
    mResult = NO_MATCH;
    if (mPredOperator == ALL_ROWS)
    {
        mResult = MATCH;
    }
    else
    {
        // Compare the retrieved row key to the search term
        rc = do_compare();
        if (rc)
        {
          Wrapper_Utilities::trace_error(107,"Sample_Query::table_scan", 
                                        110, sizeof(rc), &rc);
          goto exit;
        }
          
        // If the retrieved row is not a match and there are more rows available
        // then continue retrieving until 1) a match is found, or 2) there are no
        // more rows to search
        while (mResult != MATCH && !mFinished)
        {  
            // Get and tokenize the next row 
            rc = get_data();
            if (rc)
            {
                Wrapper_Utilities::trace_error(107,"Sample_Query::table_scan", 
                                        120, sizeof(rc), &rc);
                goto exit;
            }

            if (mFinished)
	    {
                goto exit;
            }        
            // Compare the retrieved row to the search term
            rc = do_compare();
            if (rc)
            {
                Wrapper_Utilities::trace_error(107,"Sample_Query::table_scan", 
                                        130, sizeof(rc), &rc);
                goto exit;
            }
        }
    }
          
    // If a match was found then save the request columns in the column
    // data array and return to the fetch function.      
    if (mResult == MATCH)
    {
        i = 0;
        while (mColumnVector[i] != -1)
        {
            rc = save(mTokens[mColumnVector[i]],mColumnVector[i]);
            if (rc)
            {
                Wrapper_Utilities::trace_error(107,"Sample_Query::table_scan", 
                                        140, sizeof(rc), &rc);
                goto exit;
            }
            i++;
        }
    }
    
exit:
    Wrapper_Utilities::fnc_exit(107,"Sample_Query::table_scan", rc);
    return rc;
}

/****************************************************************************
*  Function Name =  Sample_Query::save()
* 
*  Function:  The save function takes character representation of the data
*             element to be saved, converts it if needed to the proper data
*             type, and then stores it in the column data array item indexed
*             by the columnVector.
*
*  Input: char *fetchedData  character representation of the data element to
*                            be saved.
*
*         int  columnVector  An index into the column data array pointing to 
*                            the appropriate column to save this data.
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure  
*          Note:  There is no way of knowing if the atoi or atof failed.  If
*                 either fail the return value is undefined, but usually 0.                                           
*****************************************************************************/
sqlint32 Sample_Query::save(char *fetchedData, int columnVector)
{
    char                   *func_name = "SQ_Sv";
    sqlint32               rc = 0;
    sqlint32               trace_error = 0;
    int                    tempInt = 0;
    size_t                 offset = 0;
    double                 tempDouble = 0;
    FencedSample_Server    *srv = NULL; 
    sqluint8               *serverName = NULL;
    
    // If the data type for this column is INTEGER then convert the fetched
    // data to type INT and store it in the previously allocate data area.
    Wrapper_Utilities::fnc_entry(108,"Sample_Query::save");
    
    if (mData[columnVector].type == SQL_INTEGER)
    {
       if (fetchedData == NULL)
       {
           if (mData[columnVector].data != NULL)
           {
               Wrapper_Utilities::deallocate(mData[columnVector].data);
               mData[columnVector].data = NULL;
           }
       }
       else
       {
           offset = strspn(fetchedData,"+-0123456789");              
           if (offset != strlen(fetchedData))
           {
               rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E408,1,
                     strlen((const char *)mData[columnVector].name),
                     (const char *)mData[columnVector].name);

               Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 100, 
                                         strlen((const char *)mData[columnVector].name),
                                         (const char *)mData[columnVector].name); 
               trace_error = 100;
               goto error;
           }              
              double intMax = INT_MAX;
              double intMin = INT_MIN;
              errno = 0;
              double value = atof(fetchedData);
              if ((errno == ERANGE) || (errno == EINVAL)) 
              {
                  rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E405, 1,
                  strlen((const char *)mData[columnVector].name),
                  (const char *)mData[columnVector].name);

                  Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 110, 
                                         strlen((const char *)mData[columnVector].name),
                                         (const char *)mData[columnVector].name); 
                  trace_error = 110;
                  goto error;
              }

              if ((value < intMin) || (value > intMax)) 
              {
                  rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E405, 1,
                       strlen((const char *)mData[columnVector].name),
                       (const char *)mData[columnVector].name);

                  Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 120, 
                                         strlen((const char *)mData[columnVector].name),
                                         (const char *)mData[columnVector].name); 
                  trace_error = 120;
                  goto error; 
              }
              
              if (mData[columnVector].data == NULL)
              {
                  rc = Wrapper_Utilities::allocate(sizeof(int),(void **)&mData[columnVector].data);
                  if (rc) 
                  {
                    rc = sample_report_error_1822(rc, "Memory allocation error.", 130, func_name);
                    trace_error = 130;
                    goto error; 
                  }
              }
              errno = 0;
              tempInt = atoi(fetchedData);
              if ((errno == ERANGE) || (errno == EINVAL)) 
              {
                  rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E405, 1,
                       strlen((const char *)mData[columnVector].name),
                       (const char *)mData[columnVector].name);

                  Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 140, 
                                         strlen((const char *)mData[columnVector].name),
                                         (const char *)mData[columnVector].name); 
                  trace_error = 140;
                  goto error;
              }
              memcpy(mData[columnVector].data, &tempInt, sizeof(int));
       }
    }

    // If the data type is DOUBLE then convert the fetched data to type double and
    // store it in the previously allocated data area. 
    else if
    (mData[columnVector].type == SQL_DOUBLE)
    {
       if (fetchedData == NULL)
       {
          if (mData[columnVector].data != NULL)
          {
                Wrapper_Utilities::deallocate(mData[columnVector].data);
                mData[columnVector].data = NULL;
          }
       }
       else
       {
          offset = strspn(fetchedData,"+-.0123456789eE");
          if (offset != strlen(fetchedData))
          {
              rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E408,1,
                      strlen((const char *)mData[columnVector].name),
                      (const char *)mData[columnVector].name);

              Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 150, 
                                     strlen((const char *)mData[columnVector].name),
                                     (const char *)mData[columnVector].name); 
              trace_error = 150;
              goto error;
          }
          if (mData[columnVector].data == NULL)
          {
              rc = Wrapper_Utilities::allocate(sizeof(double),(void **)&mData[columnVector].data);
              if (rc)
              {
                rc = sample_report_error_1822(rc, "Memory allocation error.", 160, func_name);
                trace_error = 160;
                goto error; 
              }
          }
          errno = 0; 
          tempDouble = atof(fetchedData);
          if ((errno == ERANGE) || (errno == EINVAL))
          {
              rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E405, 1,
                      strlen((const char *)mData[columnVector].name),
                      (const char *)mData[columnVector].name);

              Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 170, 
                                     strlen((const char *)mData[columnVector].name),
                                     (const char *)mData[columnVector].name); 
              trace_error = 170;
              goto error;
          }
             
          memcpy(mData[columnVector].data,&tempDouble, sizeof(double));
       }
    }
    
    // If the data type is DECIMAL then convert the fetched data to type decimal and
    // store it in the previously allocated data area. 
    else if
    (mData[columnVector].type == SQL_DECIMAL)
    {
         if (fetchedData == NULL)
         {
              if (mData[columnVector].data != NULL)
              { 
                  Wrapper_Utilities::deallocate(mData[columnVector].data);
                  mData[columnVector].data = NULL;
              }
         }
         else
         {
             offset = strspn(fetchedData,"+-.0123456789");
             if (offset != strlen(fetchedData))
             {
                 rc = Wrapper_Utilities::report_error("SQSave", SQL_RC_E408,1,
                      strlen((const char *)mData[columnVector].name),
                      (const char *)mData[columnVector].name);

                 Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 180, 
                                        strlen((const char *)mData[columnVector].name),
                                        (const char *)mData[columnVector].name); 
                 trace_error = 180;
                 goto error;
             }
             if (mData[columnVector].data == NULL)
             {
                 rc = Wrapper_Utilities::allocate(MAX_DECIMAL_SIZE,(void **)&mData[columnVector].data);
                 if (rc)
                 {
                   rc = sample_report_error_1822(rc, "Memory allocation error.", 190, func_name);
                   trace_error = 190;
                   goto error; 
                 }
                 mData[columnVector].len = MAX_DECIMAL_SIZE - 1;  // Don't count the null terminator
             }
             if (mData[columnVector].len < MAX_DECIMAL_SIZE)
             {
                 Wrapper_Utilities::deallocate(mData[columnVector].data);
                 rc = Wrapper_Utilities::allocate(MAX_DECIMAL_SIZE,(void **)&mData[columnVector].data);
                 if (rc)
                 {
                   rc = sample_report_error_1822(rc, "Memory allocation error.", 200, func_name);
                   trace_error = 200;
                   goto error; 
                 }
                 mData[columnVector].len = MAX_DECIMAL_SIZE - 1;
             }
             
             strcpy((char *)mData[columnVector].data, fetchedData);
         }
      }   

    // If the data type was CHARACTER or VARCHAR then copy it to the previously
    // allocated data area.  Truncation may occur if the fetched data length is
    // greater than the defined column size.  
    
    else if
    (mData[columnVector].type == SQL_CHAR)
    {
          if (fetchedData == NULL)
          {
              if (mData[columnVector].data != NULL)
              {
                  Wrapper_Utilities::deallocate(mData[columnVector].data);
                  mData[columnVector].data = NULL;
              }
          }
          else
          {
              if (mData[columnVector].data == NULL)
              {
                  rc = Wrapper_Utilities::allocate(mData[columnVector].len + 1,(void **)&mData[columnVector].data);
                  if (rc)
                  {
                     rc = sample_report_error_1822(rc, "Memory allocation error.", 210, func_name);
                     trace_error = 210;
                     goto error; 
                  }
              }
              memset((char *)mData[columnVector].data,' ',mData[columnVector].len);
              if ((sqlint32) strlen(fetchedData) > mData[columnVector].len)
              {
                  strncpy((char *)mData[columnVector].data,fetchedData,mData[columnVector].len);
              }
              else
              {
                  strncpy((char *)mData[columnVector].data,fetchedData,strlen(fetchedData));
              }
          }
    }          
    else if
    (mData[columnVector].type == SQL_VARCHAR)
      {
          if (fetchedData == NULL)
          {
              if (mData[columnVector].data != NULL)
              { 
                  Wrapper_Utilities::deallocate(mData[columnVector].data);
                  mData[columnVector].data = NULL;
              }
          }
          else
          {
              if (mData[columnVector].data == NULL)
              {
                  rc = Wrapper_Utilities::allocate(mData[columnVector].len + 1,(void **)&mData[columnVector].data);
                  if (rc)
                  {
                     rc = sample_report_error_1822(rc, "Memory allocation error.", 220, func_name);
                     trace_error = 220;
                     goto error; 
                  }
              }
             if ( (sqlint32) strlen(fetchedData) > mData[columnVector].len)
              { 
                  memcpy((char *)mData[columnVector].data, fetchedData, mData[columnVector].len);
                  *((char *)mData[columnVector].data + mData[columnVector].len) = '\0';
              }
              else
              {
                  strncpy((char *)mData[columnVector].data,fetchedData,strlen(fetchedData));
                  *((char *)mData[columnVector].data + strlen(fetchedData)) = '\0';
              }
         }     
      }    
    // Report and unsupported data type error to DB2  
    else
    {
          srv = (FencedSample_Server *)get_server();
          serverName = srv->get_name();
          rc = Wrapper_Utilities::report_error("SQDcomp", SQL_RC_E1823,2,
                    strlen((const char *)mData[columnVector].name), (const char *)mData[columnVector].name,
                    strlen((const char *)serverName), (const char *)serverName);

          Wrapper_Utilities::fnc_data(108,"Sample_Query::save", 230, 
                                  strlen((const char *)mData[columnVector].name),
                                  (const char *)mData[columnVector].name); 
          trace_error = 230;
          goto error;
    }  

exit:
    Wrapper_Utilities::fnc_exit(108,"Sample_Query::save", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(108,"Sample_Query::save", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::build_decimal_string()
* 
*  Function:  This function is used to build a stringified version of a 
*             decimal number so that it can be used in a comparison.
*
*  Input: char **result     - location for the stringified decimal number
*         char *input       - variable size character string of decimal number
*         int scale         - scale of the decimal number
*         int precision     - precision of the decimal number
*         int *sign         - location to store the sign of the number 
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*          NOTE:  There is no way to be sure that the atoi function worked
*                 properly.  If the fuction fails the return result is 
*                 undefined, but usually zero.                                                                                      
*****************************************************************************/

sqlint32 Sample_Query::build_decimal_string(char **result,
                                          char *input, 
                                          int scale, 
                                          int precision,
                                          int *sign)
{
    char        decimal[32];    // location to hold the decimal part of the number
    char        mantissa[32];   // location to hold the mantissa
    sqlint32    rc = 0;
    sqlint32    trace_error = 0;
    char        *ptr = NULL;    
    char        *progress = NULL;   // pointer for strtok_r
    char        *tempDec = NULL;    // pointer to the decimal part of the number
    char        *tempMant = NULL;   // pointer to the mantissa
    char        *buffer = NULL;     // workarea to hold a copy of the input
    
    
    Wrapper_Utilities::fnc_entry(109,"Sample_Query::build_decimal_string");
    // allocate work area
    rc = Wrapper_Utilities::allocate(strlen(input) + 1, (void **)&buffer);
    if (rc)
    {
        rc = sample_report_error_1822(rc, "Memory allocation error.", 300, "SQ:BDS");
        trace_error = 300;
        goto error; 
    }
    
    // Copy decimal number to work area
    strcpy(buffer,input);
       
    // Allocate space for the stringified version of the decimal number.
    // Max decimal(31) + max mantissa(31) + sign(1) + radix char(1) + null terminator(1)   
    rc = Wrapper_Utilities::allocate(65,(void **)result);
    if (rc)
    {
        rc = sample_report_error_1822(rc, "Memory allocation error.", 310, "SQ:BDS");
        trace_error = 310;
        goto error; 
    }
    
    // Get a pointer to the result area
    ptr = *result;
    
    memset(decimal,'0',31);     // Set the decimal work area to character zero's
    memset(mantissa,'0',31);    // Set the mantissa work area to character zero's
    decimal[31] = '\0';         // Null terminate the decimal work area
    mantissa[31] = '\0';        // Null terminate the mantissa work area
    
    ptr = buffer;   // Point to the work area version of the decimal number
    
    if (*ptr == '-' || *ptr == '+')  // If a sign in present 
    {
        if (*ptr == '-')
        {
            *sign = -1;  // Set the sign to negative
        }
        else
        {
            *sign = 1;   // set the sign to positive
        }
        ptr++;  // increment past the sign
    }
    else
    {
        *sign = 1;  // If no sign present assume it's positive
    }
    
    // Get the decimal and mantissa portions of the number 
#ifdef SQLUNIX
    tempDec = strtok_r(ptr,".",&progress);
    tempMant = strtok_r(NULL,".",&progress);
#endif

#ifdef WIN32
	tempDec = strtok(ptr,".");
	tempMant = strtok(NULL,".");
#endif
    
    // Copy the decimal portion of the number to the decimal work area
    // Right justifying the number in the work area.
    strcpy((char *)&decimal + (strlen(decimal) - strlen(tempDec)),tempDec);
    
    // Copy the mantissa portion of the number to the mantissa work area
    // left justifying the number and possibly truncating.
    if (scale < (int) strlen(tempMant))
    {
        memcpy((char *)&mantissa,tempMant,scale);
    }
    else
    {
        memcpy((char *)&mantissa,tempMant,strlen(tempMant));
    }
    
    ptr = *result;      // Point to the result area
            
    strcpy(ptr,(char *)&decimal);   // copy the decimal portion of the number to the result
    strcat(ptr,(char *)&mantissa);  // copy the matissa portion of the number to the result
    
    Wrapper_Utilities::deallocate(buffer);  // Free the work area

exit:
    Wrapper_Utilities::fnc_exit(109,"Sample_Query::build_decimal_string", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(109,"Sample_Query::build_decimal_string", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
    
}

/****************************************************************************
*  Function Name =  Sample_Query::get_data()
* 
*  Function:  This function reads a record from the data file and tokenizes
*             the data.
*             
*
*  Input: 
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::get_data()
{
    char                *func_name = "SQdta";
    sqlint32            rc = 0;
    sqlint32            trace_error = 0;
    FencedSample_Server *srv = (FencedSample_Server *)get_server();
    sqluint8            *serverName = srv->get_name(); 

    Wrapper_Utilities::fnc_entry(110,"Sample_Query::get_data");
    
    for (int j = 0; j < mNumColumns; j++)
    {
        if (mTokens[j] != NULL)
        {
            Wrapper_Utilities::deallocate(mTokens[j]);
            mTokens[j] = NULL;
        }
    }   
            
    // Get a record into the input buffer.
    GET_A_RECORD(mBuffer,mFile);
    
    // If we are at eof then set the finished indicator and return
    if (END_OF_FILE(mFile))
    {
        mFinished = YES;
        goto exit;
    } 
    
    // Checking to see if the record we read is longer than the buffer 
    // we allocated (more than MAX_LINE_SIZE)
    if ((*(mBuffer + (strlen(mBuffer) - 1)) != '\n') && (mFinished == NO))
    {
        rc = Wrapper_Utilities::report_error(func_name, SQL_RC_E1822, 3,
             strlen(DATA_ERROR), DATA_ERROR,
             strlen((const char *)serverName), (const char *)serverName, 
             strlen(FILE_SIZE_ERROR), FILE_SIZE_ERROR);
        CLOSE_FILE(mFile);
        trace_error = 100;
        goto error;
    }
    
    // Break the line up into the appropriate columns
    rc = tokenize((sqluint8 *)mBuffer,mNumColumns,(sqluint8 **)mTokens);
    if (rc)
    { 
        CLOSE_FILE(mFile);
        trace_error = 110;
        goto error;
    }
    
exit:
    Wrapper_Utilities::fnc_exit(110,"Sample_Query::get_data", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(110,"Sample_Query::get_data", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}   

/**************************************************************************
*
*  Function Name  = Sample_Query::tokenize(sqluint8 *buffer, 
*                                          int colCount,
*                                          sqluint8 **tokens)
*
*  Function: This routine tokenizes a buffer based on the comma delimiter
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:   sqluint8 *buffer   -  input line to tokenize
*           int      colCount  -  number of columns in pseudo-table
*           sqluint8 **tokens  -  ptrs to the char ptrs that hold the tokens
*
*  Output: sqlint32 rc
*
*  Normal Return = 0
*
*  Error Return = !0
*
**************************************************************************/

sqlint32 Sample_Query::tokenize(sqluint8 *buffer, int colCount,  sqluint8 **tokens)
{
    char      *tokStart = (char *)buffer;
    char      *tokEnd = strchr(tokStart,',');   // *tokEnd = NULL if no ',' found
    int       i = 0;
    int	      columnsFound = 0;
    int       size = tokEnd - tokStart;
    sqlint32  rc = 0;
    sqlint32  trace_error = 0;
    char      *ptr = (char *)buffer + strlen((const char *)buffer) - 1;
    
    Wrapper_Utilities::fnc_entry(111,"Sample_Query::tokenize");

    if ((int) strlen((const char *)buffer) < colCount)
    {
	rc = Wrapper_Utilities::report_error("SQToken", SQL_RC_E1822, 2,
		strlen("Remote Data Error"),"Remote Data Error",
		strlen("Invalid Data File"),"Invalid Data File");
        trace_error = 340;
        goto error;
    }

    // Check for invalid delimter or nicknames with only one column defined
    if (tokEnd == NULL) 
    {
      // Check to make sure that this nickname has more than 1 column defined
      if (colCount != 1)
      {
	// Delimiter (comma) not found in the line we read; hence wrong delimiter!
        
	rc = Wrapper_Utilities::report_error("SQToken", SQL_RC_E1822, 2,
		strlen("Remote Data Error"),"Remote Data Error",
		strlen("Invalid Column Delimiter"),"Invalid Column Delimiter");
        trace_error = 350;
        goto error;
      }
    }
    
    // Replace the newline with a null terminator
    if (*ptr == '\n')
    { 
        *ptr = '\0';
    }
    
    // Release any previously allocated tokens
    for (i = 0; i < colCount; i++)
    {
        if (tokens[i] != NULL)
            Wrapper_Utilities::deallocate(tokens[i]);
        tokens[i] = NULL;
    }
    
    i = 0;
    
    /**************************************************************************/
    /* Tokenize the line.  We had to write our own tokenizer rather than      */
    /* use strtok_r because strtok_r did not handle the NULL column condition */
    /* (where two delimiters where back to back) correctly.                   */  
    /**************************************************************************/

    // We will go inside this loop only if there is more than one column defined
    if (colCount > 1)
    {
      for (;;)
      {
          if (columnsFound == colCount)
          {
	      rc = Wrapper_Utilities::report_error("SQToken", SQL_RC_E1822, 2,
      	               strlen("Remote Data Error"),"Remote Data Error",
                       strlen("Too many columns"), "Too many columns");
              trace_error = 360;
              goto error;
          }
          
          if (size == 0)  // NULL column condition
          {
              tokens[i] = NULL;
          }
          else
          {   // allocate space for the token and copy it there
              rc = Wrapper_Utilities::allocate(size + 1,(void **)&tokens[i]);
              if (rc) 
              {
                  rc = sample_report_error_1822(rc, "Memory allocation error.", 370, "SQ:TOK");
                  trace_error = 370;
                  goto error;
              }
              memcpy(tokens[i],tokStart,size);
          }
	  
	  columnsFound++;
        
          tokStart = tokEnd + 1;  // Find the start of the next token
          tokEnd = strchr(tokStart,',');  // Find the end of the next token
          
          if (tokEnd == NULL) // Is this the last token?
          {
	     // If we found too many tokens signal an error
	     if (columnsFound == colCount)
	     {
		  rc = Wrapper_Utilities::report_error("SQToken",SQL_RC_E1822, 2,
		       strlen("Remote Data Error"),"Remote Data Error",
		       strlen("Too many columns"),"Too many columns");
                  trace_error = 380;
                  goto error;
	      }
              i++;            // Yes increment the counter and break
	      columnsFound++;
              break;
          }
          
          size = tokEnd - tokStart;  // calculate the size of the token
          i++;
      }
    
      // If we didn't find all the columns signal an error
      if (columnsFound != colCount)
      {
	  rc = Wrapper_Utilities::report_error("SQToken", SQL_RC_E1822, 2,
                  strlen("Remote Data Error"),"Remote Data Error",
	          strlen("Data file missing columns"),"Data file missing columns");
          trace_error = 390;
          goto error;
      }
    
    } // end if (colCount !=1)
 
    // Process the last token
    if (strlen(tokStart) > 0)  // Is the token not null?
    {   
        // allocate space for the token and copy it there
        size = strlen(tokStart) + 1;
        rc = Wrapper_Utilities::allocate(size, (void **)&tokens[i]);
        if (rc) 
        {
           rc = sample_report_error_1822(rc, "Memory allocation error.", 400, "SQ:TOK");
           trace_error = 400;
           goto error;
        }
        strcpy((char *)tokens[i],tokStart);
    }
    else    // Last token NULL
    {
        tokens[i] = NULL;
    }
    
exit:
    Wrapper_Utilities::fnc_exit(111,"Sample_Query::tokenize", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(111,"Sample_Query::tokenize", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::pack()
* 
*  Function:  The pack function takes a character string representation of a 
*             number and converts it to packed decimal.
*             
*  Input: number - char* representation of a number.
*         packed - char ** location for packed decimal representation of number
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::pack(char *number, char **packed)
{
    int     negative = NO;      // Negative number indicator
    char    *ptr = number;      // pointer to first character of number
    char    *packedPtr = NULL;  // pointer to the first byte of the packed number
    int     digitCount = 0;     // digit counter
    char    nible = 0x00;       // indicator used to denote which nible is being constructed
    char    digit = 0x00;       // packed digit workarea
    int     rc = 0;             // return code
    
    Wrapper_Utilities::fnc_entry(112,"Sample_Query::pack");
    packedPtr = *packed;        // point to first byte of packed number
    
    digitCount = strlen(number);  // Count the number of characters in the number
                                  // to be converted
    
    if (*number == '-')         // If the number is negative decrement the digit counter
    {                           // set the negative indicator, and move the pointer to the
        digitCount--;           // first digit of the number
        negative = YES;
        ptr++;
    }
    
    if (strstr(number,".") != NULL)     // If there is a decimal point in the number
        digitCount--;                   // decrement the digit count.
    
    if (digitCount % 2 == 0)    // If the number of digits to be packed is even 
        nible ^= 0x01;          // then begin constructing the packed number at the
                                // second nible of the byte.
                                
    while (digitCount != 0)     // while there are digits to pack do...
    {
        digit = *ptr;           // copy the digit into the work area
        
        if (digit == '.')       // if the digit is actually a decimal point
        {                       // go to the next digit and restart the loop
            ptr++;
            continue;
        }
            
        if (nible == 0x01)          //  If we are working with the second nible
        {                           // then clear the first nible.  Next OR the
            digit &= 0x0f;          // second nible to the second nible of the
            *packedPtr |= digit;    // packed number. Move the next packed byte
            packedPtr++;            
        }
        else                                  // If we are working with the first nible of
        {                                     // of the packed number then shift the numeric
            digit <<= 4;                     // bits to the first nible of the workarea and
            *packedPtr = (digit & 0xf0);     // OR them to the first nible of the packed digit
        }
        
        ptr++;          // Move to the next digit to be packed
        
        digitCount--;   // Decrement the digit counter
        
        nible ^= 0x01;  // flip flop the nible indicator
            
    }
    
    if (negative)               // If the number being packed is negative then
        *packedPtr |= 0x0d;     // OR the sign nible negative, otherwise OR the
    else                        // sign nible positive
        *packedPtr |= 0x0c;    
    
    Wrapper_Utilities::fnc_exit(112,"Sample_Query::tokenize", rc);
    return rc;    
    
}

/****************************************************************************
*  Function Name =  Sample_Query::format_packed_decimal()
* 
*  Function:  This function converts a decimal number, temporarily stored as
*             a double, into the proper sized packed decimal number.
*             
*  Input:   int vector   - index to the data structure for the decimal number
*           int precision - the precision of the column
*           int scale    - the scale of the column
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::format_packed_decimal(int vector,int precision,int scale)
{
    sqlint32    rc = 0;                         // Return code
    sqlint32    trace_error = 0;
    char        buffer[100];                    // work area
    char        *pd = NULL;                     // area to hold the packed number
    int         pdSize = (precision / 2) + 1;   // size in bytes of pd number
    char        *ptr = &buffer[0];              // pointer to workarea
    char        *decimal = NULL;                // pointer to decimal part of number
    char        *mantissa = NULL;               // pointer to the mantissa
    int         negative = NO;                  // negative indicator
    char        *progress = NULL;               // place holder for strtok_r
    int         decSize = precision - scale;    // size of decimal portion
    char        *decBuffer = NULL;              // ptr to decimal workarea
    char        *scaleBuffer = NULL;            // ptr to mantissa workarea
    char        *rawNumber = NULL;              // ptr to unpacked reconstructed number
    
    Wrapper_Utilities::fnc_entry(113,"Sample_Query::format_packed_decimal");
    //  Allocate space for the packed decimal number, the decimal, mantissa, and
    //  reconstructed number work areas
    rc = Wrapper_Utilities::allocate(pdSize,(void **)&pd);
    if (rc) 
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 410, "SQ:TOK");
       trace_error = 410;
       goto error;
    }
    
    rc = Wrapper_Utilities::allocate((decSize + 1),(void **)&decBuffer);
    if (rc) 
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 420, "SQ:TOK");
       trace_error = 420;
       goto error;
    }
    
    rc = Wrapper_Utilities::allocate((scale + 1), (void **)&scaleBuffer);
    if (rc) 
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 430, "SQ:TOK");
       trace_error = 430;
       goto error;
    }
    
    rc = Wrapper_Utilities::allocate((precision + 3),(void **)&rawNumber);
    if (rc) 
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 440, "SQ:TOK");
       trace_error = 440;
       goto error;
    }
    
    // Convert the double into the character representation of the number
   
    strcpy(buffer,(const char *)mData[vector].data);
    
    if (*ptr == '-')        // If the number is negative point past the minus sign
    {                       // and set the negative indicator
        negative = YES;
        ptr++;
    }
   
    if (*ptr == '+')	    // If a plus sign is on the number than point past the sign
    {
	ptr++;
    }
 
    // parse the decimal and mantissa portions of the number
    if (buffer[0] == '.')
    {
#ifdef SQLUNIX
        mantissa = strtok_r(ptr,".",(char **)&progress);
#endif
#ifdef WIN32
		mantissa = strtok(ptr,".");
#endif
    }
    else
    {
#ifdef SQLUNIX
        decimal = strtok_r(ptr,".",(char **)&progress);
        mantissa = strtok_r((char *)NULL,".",(char **)&progress);
#endif
#ifdef WIN32
		decimal = strtok(ptr,".");
		mantissa = strtok(NULL,".");
#endif
    }
    
    if (decimal != NULL)
    {
        if (decSize < (int) strlen(decimal))  // If the decimal part of the number is too 
        {                               // large for the column signal an error to DB2
            rc = Wrapper_Utilities::report_error("SQFpd",SQL_RC_E405,1,
                 strlen((const char *)mData[vector].name),
                 (const char *)mData[vector].name);

            Wrapper_Utilities::fnc_data(113,"Sample_Query::format_packed_decimal", 450, 
                                    strlen((const char *)mData[vector].name),
                                    (const char *)mData[vector].name); 
            trace_error =450;
            goto error;
        }
        else                            // If decimal part of number is smaller than max size
        if (decSize > (int) strlen(decimal))  // left fill the decimal buffer with zeros and copy
        {                               // the number into the buffer
            memset(decBuffer,'0',decSize);
            memcpy(decBuffer + (decSize - strlen(decimal)),decimal,strlen(decimal));
        }
        else                            // copy the number into the buffer
        {
            memcpy(decBuffer,decimal,strlen(decimal));
        }
    }
    else
    {
        memset(decBuffer,'0',decSize);
    }
    
    if (scale <= (int) strlen(mantissa))  // If the mantissa is LE the size available then
    {                               // copy the mantissa into the buffer possible truncating data
        memcpy(scaleBuffer,mantissa,scale);
    }
    else                            // Right pad the mantissa buffer and copy the mantissa into
    {                               // the buffer
        memset(scaleBuffer,'0',scale);
        memcpy(scaleBuffer,mantissa,strlen(mantissa));
    } 
    
    ptr = rawNumber;        // point to the unformatted buffer
    
    if (negative)           // If it's a negative number then insert the minus sign
    {
        *ptr = '-';
        ptr++;
    }
    
    strcat(ptr,decBuffer);      // cat the decimal part of the number to the unformatted buffer
    strcat(ptr,".");            // cat the decimal point
    strcat(ptr,scaleBuffer);    // cat the mantissa
    
    rc = pack(rawNumber,&pd);   // pack the number
    if (rc)
    {
        trace_error =460;
        goto error;
    }
    
    Wrapper_Utilities::deallocate(mData[vector].data);  // free the char representation of the data
    
    mData[vector].data = NULL;  // set the data ptr to null
    
    // allocate space for the packed decimal number
    rc = Wrapper_Utilities::allocate(pdSize,&mData[vector].data);
    if (rc) 
    {
       rc = sample_report_error_1822(rc, "Memory allocation error.", 470, "SQ:TOK");
       trace_error = 470;
       goto error;
    }

    
    memcpy(mData[vector].data,pd,pdSize);   // Copy the packed decimal number to the data field
    
    mData[vector].len = pdSize;     // Store the size
    
    Wrapper_Utilities::deallocate(pd);
    Wrapper_Utilities::deallocate(decBuffer);
    Wrapper_Utilities::deallocate(scaleBuffer);
    Wrapper_Utilities::deallocate(rawNumber);
    
exit:
    Wrapper_Utilities::fnc_exit(113,"Sample_Query::format_packed_decimal", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(113,"Sample_Query::format_packed_decimal", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::do_compare()
* 
*  Function:  This function is used to control the comparison of the search term
*             to the key field.  The actual compare function is overloaded
*             and varies by the argument type being used in the compare.
*
*  Input: 
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::do_compare()
{
    sqlint32    rc = 0;
    sqlint32    trace_error = 0;
    int         tmpInt = 0;
    short       tmpShort = 0;
    float       tmpFloat = 0.0;
    double      tmpDouble = 0.0;
    int         scale = 0;
    int         precision = 0;
    double      intMax = INT_MAX;
    double      intMin = INT_MIN;
    double      value = 0;
    FencedSample_Server   *srv = NULL;
    sqluint8            *serverName = NULL;

    
    Wrapper_Utilities::fnc_entry(114,"Sample_Query::do_compare");
  
    // Select which compare to call based upon the sql type of the key field
    switch(mData[mKeyVector].type)
    {
        case SQL_INTEGER:
            // For integer compares, convert the fetched data to an
            // integer and call the compare function.
            errno = 0;
            value = atof(mTokens[mKeyVector]);
            if ((errno == ERANGE) || (errno == EINVAL))
            { 
                rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405, 1,
                strlen((const char *)mData[mKeyVector].name),
                (const char *)mData[mKeyVector].name);
                trace_error = 01;
                goto error;
            }

            if ((value < intMin) || (value > intMax))
            {
                rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405, 1,
                     strlen((const char *)mData[mKeyVector].name),
                     (const char *)mData[mKeyVector].name);
                trace_error = 10;
                goto error;
            }
            
            errno = 0;
            tmpInt = atoi(mTokens[mKeyVector]);
            if ((errno == ERANGE) || (errno == EINVAL))
            {
                rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405, 1,
                     strlen((const char *)mData[mKeyVector].name),
                     (const char *)mData[mKeyVector].name);
                trace_error = 20;
                goto error;
            }
            rc = compare(tmpInt);
            if( rc )
            {
                trace_error = 30;
                goto error;
            }
            break;

          case SQL_SMALLINT:
              // For short compares, convert the fetched data to an
              // integer.  Verify that the data is valid for a short.
              // Assign the data to a short and call the compare function.
              errno = 0;
              tmpInt = atoi(mTokens[mKeyVector]);
              if ((errno == ERANGE) || (errno == EINVAL))
              {
                  rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                       (const char *)mData[mKeyVector].name);
                  trace_error = 40;
                  goto error;
              } 
              if ((tmpInt > SHRT_MAX) || (tmpInt < SHRT_MIN))
              {
                  rc = Wrapper_Utilities::report_error("SQdcomp",SQL_RC_E405,1,
                       strlen((const char *)mData[mKeyVector].name),
                       (const char *)mData[mKeyVector].name);
                  trace_error = 50;
                  goto error;
                }
              tmpShort = (short)tmpInt;  
              rc = compare(tmpShort);
              if( rc )
              {
                trace_error = 60;
                goto error;
              }
              break;

          case SQL_DECIMAL:
             // Decimal range checking will be done in the format_packed_data
             // function that is used to build the decimal comparison terms

             rc = compare(mTokens[mKeyVector],mData[mKeyVector].scale,mData[mKeyVector].precision);
             if( rc )
             {
               trace_error = 70;
               goto error;
             }
             break;

          case SQL_DOUBLE:
              // For double compares, convert the fetched data to a double and
              // call the compare fuction.
              errno = 0;
              tmpDouble = atof(mTokens[mKeyVector]);
              if ((errno == ERANGE) || (errno == EINVAL))
              {
                  rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                       (const char *)mData[mKeyVector].name);
                  trace_error = 80;
                  goto error;
              }

              rc = compare(tmpDouble);
              if( rc )
              {
                trace_error = 90;
                goto error;
              }
              break;

          case SQL_REAL:
              // For real compares, convert the fetched data to a double and
              // verify that the data is a valid single precision number.  Then
              // assign the data to a float and call the compare function.
              errno = 0;
              tmpDouble = atof(mTokens[mKeyVector]);
              if ((errno == ERANGE) || (errno == EINVAL))
              {
                  rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                       (const char *)mData[mKeyVector].name);
                  trace_error = 100;
                  goto error;
              } 

              if ((tmpDouble != 0.0) &&
                  ((fabs(tmpDouble) < FLT_MIN) ||
                   (fabs(tmpDouble) > FLT_MAX)))
              {
                  rc = Wrapper_Utilities::report_error("SQdcomp", SQL_RC_E405,1,
                       strlen((const char *)mData[mKeyVector].name),
                       (const char *)mData[mKeyVector].name);
                  trace_error = 110;
                 goto error;
              }
              
              tmpFloat = (float)tmpDouble;
              rc = compare(tmpFloat);
              
              if( rc )
              {
                trace_error = 120;
                goto error;
              }
              break;

          case SQL_CHAR:
          case SQL_VARCHAR:
              // For Character and VARCHAR compares call the compare function
              rc = compare(mTokens[mKeyVector]);
              if( rc )
              {
                trace_error = 130;
                goto error;
              }

              break;
          default:
              // We don't support other data types to signal an error to DB2
              
              srv = (FencedSample_Server *)get_server();
              serverName = srv->get_name();
              rc = Wrapper_Utilities::report_error("SQdcomp",
                    SQL_RC_E1823,2,strlen((const char *)mData[mKeyVector].name),
                    (const char *)mData[mKeyVector].name,
                    strlen((const char *)serverName), (const char *)serverName);
                    
              trace_error = 140;
              goto error;
      }

exit:
    Wrapper_Utilities::fnc_exit(114,"Sample_Query::do_compare", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(114,"Sample_Query::do_compare", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}



/****************************************************************************
*  Function Name =  Sample_Query::compare()
* 
*  Function:  This function is used to compare the search term to the key 
*             element selected from the current row. This is called when
*             the key is an int.
*
*  Input: int compareTerm   key element from the current row
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure         
*          NOTE:  There is no way to be sure that the atoi function worked
*                 properly.  If the fuction fails the return result is 
*                 undefined, but usually zero.                                              
*****************************************************************************/  
sqlint32 Sample_Query::compare(int compareTerm)
{
    sqlint32 rc = 0;  
    sqlint32    trace_error = 0;  
    int      searchTerm = 0;
    double      intMax = INT_MAX;
    double      intMin = INT_MIN;
    double      value = 0;

    Wrapper_Utilities::fnc_entry(115,"Sample_Query::compare(int)");
  
    // errno is a global var in libc.a
    errno = 0;
    value = atof(mSearchTerm);
    if ((errno == ERANGE) || (errno == EINVAL))
    {
       rc = Wrapper_Utilities::report_error("SQdcompi", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
       trace_error = 10;
       goto error;
    }

    if ((value < intMin) || (value > intMax))
    {
       rc = Wrapper_Utilities::report_error("SQdcompi", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
       trace_error = 20;
       goto error;
    }
    
    // Convert the search term to an integer.
    errno = 0;
    searchTerm = atoi(mSearchTerm);
    if ((errno == ERANGE) || (errno == EINVAL))
    {
        rc = Wrapper_Utilities::report_error("SQdcompi", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
       trace_error = 30;
       goto error;
    }
    
    // Set mResult based upon the predicate operator. 
    switch (mPredOperator)
    {
    	//only support '='
        case SQL_EQ:
                
            if (searchTerm == compareTerm) 
            {
                mResult = MATCH;
            }   
            else
            {
            	mResult = NO_MATCH;
            }
            break;
          
       default:
           { 
               rc = Wrapper_Utilities::report_error("SQdcompi",
                    SQL_RC_E901,1,strlen(BAD_PRED_OP),BAD_PRED_OP);
               trace_error = 40;
               goto error;
           }
    }

exit:
    Wrapper_Utilities::fnc_exit(115,"Sample_Query::compare(int)", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(115,"Sample_Query::compare(int)", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::compare()
* 
*  Function:  This function is used to compare the search term to the key
*             element selected from the current row.  This is called when
*             the key is a short.
*
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure    
*          NOTE:  There is no way to be sure that the atoi function worked
*                 properly.  If the fuction fails the return result is 
*                 undefined, but usually zero.                                                                                      
*****************************************************************************/
sqlint32 Sample_Query::compare(short compareTerm)
{
    sqlint32  rc = 0;
    sqlint32    trace_error = 0;
    int       tmpInt = 0;
    short     searchTerm = 0;
    int       compTerm = 0;
      
    Wrapper_Utilities::fnc_entry(116,"Sample_Query::compare(short)");
  
    // Convert the search term to an integer

    errno = 0;
    tmpInt = atoi(mSearchTerm);

    if ((errno == ERANGE) || (errno == EINVAL))
    {
        rc = Wrapper_Utilities::report_error("SQdcomps", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
        trace_error = 10;
        goto error;
    } 

    // Verify that it is a valid short value
    if ((tmpInt > SHRT_MAX) || (tmpInt < SHRT_MIN))
    {
        rc = Wrapper_Utilities::report_error("SQdcomps", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
        trace_error = 20;
        goto error;
    }
   
    searchTerm = (short)tmpInt;

    // Set the result based upon the predicate operator.
    switch (mPredOperator)
    {
    	//only support '='
        case SQL_EQ:
            if (searchTerm == compareTerm) 
            {
                mResult = MATCH;
            }   
            else
            {
            	mResult = NO_MATCH;
            }
            break;
        default:
            rc = Wrapper_Utilities::report_error("SQdcomps",
                  SQL_RC_E901,1,strlen(BAD_PRED_OP),BAD_PRED_OP);
            trace_error = 30;
            goto error;
    }

exit:
    Wrapper_Utilities::fnc_exit(116,"Sample_Query::compare(short)", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(116,"Sample_Query::compare(short)", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::compare()
* 
*  Function:  This function is used to compare the search term to the key
*             element from the selected row.  This function is called when
*             the key element is a double.
*
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*          NOTE:  There is no way to be sure that the atof function worked
*                 properly.  If the fuction fails the return result is 
*                 undefined, but usually zero.                                                                                      
*****************************************************************************/
sqlint32 Sample_Query::compare(double compareTerm)
{
    sqlint32    rc = 0;
    sqlint32    trace_error = 0;
    double      searchTerm = 0;

    Wrapper_Utilities::fnc_entry(117,"Sample_Query::compare(double)");
    
    // Convert the search term to a double
    errno = 0;
    searchTerm = atof(mSearchTerm);
    if ((errno == ERANGE) || (errno == EINVAL))
    {
       rc = Wrapper_Utilities::report_error("SQdcompd", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
       trace_error = 10;
       goto error;
    }


    // Set the result based upon the predicate operator
    switch (mPredOperator)
    {
    	//only support '='
        case SQL_EQ:
            if (searchTerm == compareTerm) 
            {
                mResult = MATCH;
            }   
            else
            {
                mResult = NO_MATCH;
            }              
            break;
 
        default:
            rc = Wrapper_Utilities::report_error("SQdcompd",
                    SQL_RC_E901, 1, strlen(BAD_PRED_OP),BAD_PRED_OP);
              trace_error = 20;
              goto error;
      }

exit:
    Wrapper_Utilities::fnc_exit(117,"Sample_Query::compare(double)", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(117,"Sample_Query::compare(double)", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query:compare()
* 
*  Function:  This function is used to compare the search term to the key 
*             element from the selected row.  This function is called when
*             the key element is a string.
*
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*****************************************************************************/
sqlint32 Sample_Query::compare(char *compareTerm)
{
    sqlint32    rc = 0;
    sqlint32    trace_error = 0;
    int     result = 0, size = 0;
    char    *searchTerm = NULL;
    char    *currentValue = NULL;
    sqlint32 compare_length = 0;


    Wrapper_Utilities::fnc_entry(118,"Sample_Query::compare(char*)");

    compare_length = strlen(compareTerm);

    if (compare_length > strlen(mSearchTerm))
    {
        size = compare_length + 1;
    }
    else
    {
        size = strlen(mSearchTerm) + 1;
    }
        
    rc = Wrapper_Utilities::allocate(size,(void **)&searchTerm);
    if (rc)
    {
      trace_error = 10;
      goto error;
    }
       
    memset(searchTerm, ' ',(size -1));
    
    memcpy(searchTerm,mSearchTerm,strlen(mSearchTerm));
    
    rc = Wrapper_Utilities::allocate(size,(void **)&currentValue);
    if (rc)
    {
      trace_error = 20;
      goto error;
    }
     
    memset(currentValue, ' ',(size - 1));
    if (compare_length > mData[mKeyVector].len)
    {
        memcpy(currentValue,compareTerm,mData[mKeyVector].len);
    }
    else
    {
        memcpy(currentValue,compareTerm,compare_length);
    }

    // Compare the search term to the compare time
    result = strcoll(searchTerm,currentValue);
    
    Wrapper_Utilities::deallocate(searchTerm);
    Wrapper_Utilities::deallocate(currentValue);
   
    
    // Set the result based upon the predicate operator
    switch (mPredOperator)
    {
    	//only support '='
        case SQL_EQ:
            if (result == 0)
            {
            	mResult = MATCH;
            }
            else
            {
            	mResult = NO_MATCH;
            }
            break;
        default:
            rc = Wrapper_Utilities::report_error("FFQcmpst",
                    SQL_RC_E901, 1,strlen(BAD_PRED_OP),BAD_PRED_OP);
            trace_error = 30;
            goto error;
    }

exit:
    Wrapper_Utilities::fnc_exit(118,"Sample_Query::compare(char*)", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(118,"Sample_Query::compare(char*)", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

/****************************************************************************
*  Function Name =  Sample_Query::compare()
* 
*  Function:  This function is used to compare the search term to the key
*             element from the selected row.  This function is called when
*             the key element is a decimal.
*
*  Input: (nickname* , required) 
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*          NOTE:  
*                                                                                     
*****************************************************************************/

sqlint32 Sample_Query::compare(char *compareTerm,
                             int searchTermScale, 
                             int searchTermPrecision)
{
    sqlint32    rc = 0;
    sqlint32    trace_error = 0;
    int         compareTermScale = mData[mKeyVector].scale;
    int         compareTermPrecision = mData[mKeyVector].precision;
    char        *searchString = NULL;
    char        *compareString = NULL;
    int         searchSign = 0;
    int         compareSign = 0;
    int         result = 0;
    
    Wrapper_Utilities::fnc_entry(119,"Sample_Query::compare(decimal)");
  
    // Build a stringified representation of the decimal number from the query
    rc = Sample_Query::build_decimal_string(&searchString, mSearchTerm, searchTermScale,
                              searchTermPrecision, &searchSign);
    if (rc)
    {
      trace_error = 10;
      goto error;
    }
    
    // Build a stringified representation of the decimal number from the data file
    rc = Sample_Query::build_decimal_string(&compareString, compareTerm, compareTermScale,
                              compareTermPrecision, &compareSign);                      
    if (rc)
    {
      trace_error = 20;
      goto error;
    }
    
    // if the signs of the two terms are not equal...
    if (searchSign != compareSign)
    {
        switch(mPredOperator)
        {
            //only support '='
            case SQL_EQ:
                mResult = NO_MATCH; 
                break;
            default:
                rc = Wrapper_Utilities::report_error("SQdcompde",SQL_RC_E901, 1,
                         strlen(BAD_PRED_OP),BAD_PRED_OP);
                trace_error = 30;
                goto error;
        } 
    }
    else    // Both terms have the same sign
    {       // compare the query term with the data file term
        result = strcoll(searchString,compareString);
        
        if (searchSign > 0)     // If both are positive numbers...
        {
            switch(mPredOperator)
            {
            	//only support '='
                case SQL_EQ:
                    if (result == 0)
                    {    
                        mResult = MATCH;
                    }
                    else
                    {
                        mResult = NO_MATCH; 
                    }
                    break;
                default:
                    rc = Wrapper_Utilities::report_error("SQdcompde",SQL_RC_E901, 1,
                         strlen(BAD_PRED_OP),BAD_PRED_OP);
                    trace_error = 40;
                    goto error;
            }
        } 
        else    // Both terms are negative numbers
        {
            //only supply '='
            switch(mPredOperator)
            {
                case SQL_EQ:
                    if (result == 0)
                    {
                        mResult = MATCH;
                    }
                    else
                    {
                        mResult = NO_MATCH; 
                    }
                break;
            
                default:
                    rc = Wrapper_Utilities::report_error("SQdcompde",SQL_RC_E901,1,
                         strlen(BAD_PRED_OP),BAD_PRED_OP);
                    trace_error = 50;
                    goto error;
            }
        }    
    }
    
    // Release the stringified versions of the numbers back to the system       
    Wrapper_Utilities::deallocate(searchString);
    Wrapper_Utilities::deallocate(compareString);
    
exit:
    Wrapper_Utilities::fnc_exit(119,"Sample_Query::compare(decimal)", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(119,"Sample_Query::compare(decimal)", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}
    
/****************************************************************************
*  Function Name =  Sample_Query::compare()
* 
*  Function:  This function is used to compare the search term to the key
*             element from the selected row.  This function is called when
*             the key element is a float.
*
*  Input: (nickname* , required) 
*                                                                      
*  Output: rc  = 0, success                                            
*             != 0, failure                                            
*          NOTE:  There is no way to be sure that the atof function worked
*                 properly.  If the fuction fails the return result is 
*                 undefined, but usually zero.                                                                                      
*****************************************************************************/
sqlint32 Sample_Query::compare(float compareTerm)
{
    sqlint32    rc = 0;
    sqlint32    trace_error = 0;
    double      tmpSearchTerm = 0.0;
    float       searchTerm = 0.0;
    
    Wrapper_Utilities::fnc_entry(120,"Sample_Query::compare(float)");
    
    // Convert the search term to a double
    errno = 0;
    tmpSearchTerm = atof(mSearchTerm);
    if ((errno == ERANGE) || (errno == EINVAL))
    {
        rc = Wrapper_Utilities::report_error("SQdcompf", SQL_RC_E405, 1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
        trace_error = 10;
        goto error;
    }

    //Verify that the search term is a valid single precision floating point
    // number.
    
    if ((tmpSearchTerm != 0.0) && 
        ((fabs(tmpSearchTerm) < FLT_MIN) || (fabs(tmpSearchTerm) > FLT_MAX)))
    {
        rc = Wrapper_Utilities::report_error("SQdcompf", SQL_RC_E405,1,
                       strlen((const char *)mData[mKeyVector].name),
                              (const char *)mData[mKeyVector].name);
        trace_error = 20;
        goto error;
    }
    
    searchTerm = (float)tmpSearchTerm;

    // Set the result based upon the predicate operator
    switch (mPredOperator)
    {
    	//only support '='
        case SQL_EQ:
            if (searchTerm == compareTerm) 
            {
                mResult = MATCH;
            }   
            else
            {
                mResult = NO_MATCH;
            }              
            break;
        default:
            rc = Wrapper_Utilities::report_error("SQdcompf",
                    SQL_RC_E901, 1,strlen(BAD_PRED_OP),BAD_PRED_OP);
            trace_error = 30;
            goto error;
            break;
      }

exit:
    Wrapper_Utilities::fnc_exit(120,"Sample_Query::compare(float)", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(120,"Sample_Query::compare(float)", 
                                   trace_error, sizeof(rc), &rc);
    goto exit;
}

