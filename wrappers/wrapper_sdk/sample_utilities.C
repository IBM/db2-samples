/**********************************************************************
*
*  Source File Name = sample_utilities.C
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Function definitions for sample utilities class
*
*  Operating System = All
*
***********************************************************************/
#include "sample_typedefs.h"
#include "sample_utilities.h"
#include "sample_error_reporting.h"
#include "sqlqg_utils.h"
#include "sqlcodes.h"

/**************************************************************************
*
*  Function Name  = Sample_Utilities::verify_column_type_and_options()
*
*  Function: This method will verify that the column data type and the column 
*             options are supported by this wrapper.
*            
*            
*  Input:   nickname_info
*          
*  Output: 
*
*  Normal Return = 0
*
*  Error Return = !0
*
**************************************************************************/
sqlint32 
Sample_Utilities::verify_column_type_and_options(Nickname* a_nickname , 
                              Nickname_Info *nickname_info, sqluint8* serverName)
{
    Column_Info     *columnInfo = NULL;
    Catalog_Option  *catalog_option = NULL;
    sqluint8        *dataType = NULL;
    sqlint32        rc = 0;
    sqlint32        trace_error = 0;
    sqluint8       *column_name = NULL;

    Wrapper_Utilities::fnc_entry(90,"Sample_Utilities::verify_column_type_and_options");
    
    Wrapper_Utilities::fnc_data(90,"Sample_Utilities::verify_column_type_and_options", 
                                 5, strlen((char *)serverName), (char*)serverName);
    columnInfo     = nickname_info->get_first_column();
    
    // sanity check..
    if (columnInfo == NULL)
    {
        rc = Wrapper_Utilities::report_error("SU_FCT",
              SQL_RC_E901, 1, strlen(COLUMN_ERROR), COLUMN_ERROR);
        trace_error = 10;
        goto error;
    }
    

    while (columnInfo != NULL)
    {
        rc = columnInfo->get_type_name(&dataType);
        
        if ((rc) && (rc != SQLQG_NOVALUE))
        {
            trace_error = 20;
            goto error;
        }
        
        Wrapper_Utilities::fnc_data(90,"Sample_Utilities::verify_column_type_and_options", 
                                 25, strlen((char *)dataType), (char*)dataType);
        if (rc != SQLQG_NOVALUE)
        {
            if ((strcmp((const char *)dataType,"CHARACTER") != 0)  &&
                (strcmp((const char *)dataType,"VARCHAR")   != 0)  && 
                (strcmp((const char *)dataType,"INTEGER")   != 0)  &&
                (strcmp((const char *)dataType,"DECIMAL")   != 0)  &&
                (strcmp((const char *)dataType,"DOUBLE")    != 0))
            {
                rc = Wrapper_Utilities::report_error("SU_FCT",
                     SQL_RC_E1823, 2,
                     strlen((const char *)dataType), (const char *)dataType,
                     strlen((const char *)serverName), (const char *)serverName);
                trace_error = 30;
                goto error;
            }
        }
        // check for unknown column options. 
        // This wrapper doesn't have any column options of its own
        
        catalog_option = columnInfo->get_first_option();   
        
        while (catalog_option != NULL)
        {
           sqluint8 *column_option_name =  catalog_option->get_name();
           if (!a_nickname->is_reserved_column_option(column_option_name))
           {
              // This is an unknown option. Complain..
              
              // Get the column name
              columnInfo->get_column_name(&column_name);
              
              rc = Wrapper_Utilities::report_error("SU_FCT", SQL_RC_E1881, 3, 
                                    strlen((const char *) column_option_name), 
                                    (const char *) column_option_name, 
                                    strlen("Column"), "Column", 
                                    strlen((const char *) column_name), 
                                    (const char *)column_name);

              Wrapper_Utilities::fnc_data2(90,"Sample_Utilities::verify_column_type_and_options", 40, 
                                      strlen((char *)column_option_name), (char *)column_option_name, 
                                      strlen((const char *)column_name), (const char *)column_name);
              trace_error = 40;
              goto error;
            
           }
           
           catalog_option = nickname_info->get_next_option(catalog_option);   
        }
        
        rc = 0;
        columnInfo = nickname_info->get_next_column(columnInfo);
    }
    
exit:
    Wrapper_Utilities::fnc_exit(90,"Sample_Utilities::verify_column_type_and_options", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(90,"Sample_Utilities::verify_column_type_and_options", 
                         trace_error, sizeof(rc), &rc);
    goto exit;
}

/**************************************************************************
*
*  Function Name  = Sample_Utilities::save_option_value()
*
*  Function: This method searches the list of catalog options and looks for
*            option_name. If found, it allocats memory for it in
*            option_save_location and copies the option value.
*
*  Dependencies:
*
*  Restrictions:
*
*  Input:  Catalog_Info *catalog_info - Catalog info for options
*          char *option_name - name of the option to get the value for
*
*  Output: char **option_save_location - pointer where memory will be
*              allocated and the option value copied (if found)
*
*
*  Normal Return = 0
*
*  Error Return = !0
*
**************************************************************************/
sqlint32 Sample_Utilities::save_option_value(Catalog_Info *catalog_info, 
                                 const char *option_name, 
                                 sqluint8 **option_save_location)
{
    sqlint32       rc = 0;
    Catalog_Option *option = NULL;
    Wrapper_Utilities::fnc_entry(91,"Sample_Utilities::save_option_value");

    Wrapper_Utilities::fnc_data(91,"Sample_Utilities::save_option_value", 
                                 45, strlen((char *)option_name), (char*)option_name);
        
    // Go through the list of options and look for the specified option. If
    // found, save the value in option_save_buffer
    option = catalog_info->get_first_option();
    while (option != NULL)
    {
        sqluint8 *catalog_option_name = option->get_name();
        if (strcmp((const char *) catalog_option_name, option_name) == 0) 
        {
            if (*option_save_location != NULL)
            {
                Wrapper_Utilities::deallocate(*option_save_location);
            }
                
            rc = Wrapper_Utilities::allocate(strlen((char *)option->get_value()) + 1,
                                             (void **) option_save_location);
            if (rc)
            {
              rc = sample_report_error_1822(rc, "Memory allocation error.", 
                                            50, "SU_SOV");
              Wrapper_Utilities::trace_error(91,"Sample_Utilities::save_option_value", 
                                             50, sizeof(rc), &rc);
              goto exit;
            }
            
            strcpy((char *) *option_save_location, (char *) option->get_value());
            break;
       }

        option = catalog_info->get_next_option(option);
    }
    
exit:    
    Wrapper_Utilities::fnc_exit(91,"Sample_Utilities::save_option_value", rc);
    return rc;
}

/**************************************************************************
*
*  Function Name  = File_Utilities::unpack()
* 
*  Function: Unpacks a DB2 packed decimal into a string. The string representation
*            will be allocated by this function. The caller should free the string
*            when done.
*
*  Input:        
*
*  Output: A string representation of the decimal number of size (precision + 3)
*
*  Normal Return = 0
*
*  Error Return = !0
*
**************************************************************************/
sqlint32 Sample_Utilities::unpack(int scale, int precision, unsigned char *decData, 
                                char **constant)
{
    sqlint32    rc = 0;
    int suppressLeadingZero = 1;
    int decimalPoint = 0;
    int tmp = 0;
    char zero = '0';
    char digit = 0x00;
    
    int i = 0;
    char *bufPtr = NULL;   // Point to the first byte of packed data
    char *ptr = NULL;      // Create a pointer to the start of the unpacked data
    char *sign = NULL;     // Save the location for the sign.
    
    sqlint32        trace_error = 0;
    
    Wrapper_Utilities::fnc_entry(92,"Sample_Utilities::unpack");
  
    // If there's no data to unpack then signal an error.
    if (decData == NULL)
    {
        rc = Wrapper_Utilities::report_error("SUunpack", 
             SQL_RC_E901, 1,
             sizeof("Can't convert decimal"), "Can't convert decimal");
        trace_error = 10;
        goto error;
    }

    // Allocate an area to return the unpacked value.  Make it 3 bytes larger than
    // the precision to hold a decimal point, a sign, and a null terminator. 
    rc = Wrapper_Utilities::allocate((precision + 3), (void **)constant);
    if (rc)
    {
      trace_error = 20;
      goto error;
    }
    
    decimalPoint = precision - scale;   // Calculate the offset to the decimal point
    
    bufPtr = (char *)decData;     // Point to the first byte of packed data
    
    ptr = *constant;      // Create a pointer to the start of the unpacked data
    sign = *constant;     // Save the location for the sign.
    
    ptr++;   // Increment past the sign location
    
    // If the precision is evenly divisable by 2 then that means that there is a
    // leading zero so increment the iterator by 1 to account for the leading zero
    if ((precision % 2) == 0)
    {
        tmp = precision + 1;
    }
    else
    {
      suppressLeadingZero = 0;
      tmp = precision;
    }	
    
    for (i = 1; i <= tmp; i++)
    {        
        digit = *bufPtr;    // move the current byte to the digit byte.
        
        // If the iterator is not divisable by 2 that means we need to unpack the
        // high order 4 bits.  So, shift the high order 4 bits to the right 4 bits.
        // Otherwise we are dealing with the low order 4 bits.  So shift them to the
        // left to clear the high order bits then back to the right.  Increment the 
        // pointer  to the next packed digit. 
        if (i % 2 == 1)
        {
            digit >>= 4;
            digit = digit & 0x0f;
        }
        else
        {
            digit = digit & 0x0f;
            bufPtr++;
        }
        
        // Or the digit with an ascii zero to create the unpacked digit.
        *ptr = zero | digit;
        
        ptr++;  // Move to the next position of the unpacked number.
        
        // If this is the first iteration and the first digit is zero then reset the 
        // next unpacked position pointer and increment the decimal point locator.
        if (suppressLeadingZero && *(ptr - 1) == '0')
        {
            ptr--;
            decimalPoint++;
        }
        
        // Reset the leading zero indicator    
        suppressLeadingZero = 0;
        
        // If the iterator is pointing to the decimal point offset then insert
        // the decimal point into the unpacked string
        if (i == decimalPoint)
        {
            *ptr = '.';
            ptr++;
        }
    }
    
    // Get the sign indicator
    digit = *bufPtr;
    digit = digit & 0x0f;
    
    // If the sign is positive (an F, A, C, or E) insert a "+" sign, otherwise insert
    // a "-" sign.
    if ((digit == 0x0f) ||
        (digit == 0x0a) ||
        (digit == 0x0c) ||
        (digit == 0x0e))
    {
        *sign = '+';
    }
    else
    {
        *sign = '-';
    }
    
exit:
    Wrapper_Utilities::fnc_exit(92,"File_Utilities::unpack", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(92,"File_Utilities::unpack", 
                         trace_error, sizeof(rc), &rc);
    goto exit;
}


/**************************************************************************
*
*  Function Name  = Sample_Utilities::convert_data()
*
*
*  Function: This method converts a local data value into a format suitable
*            for a remote server.
*
*            The caller will pass in a buffer (converted_value) into which
*            the converted value should be placed.  The length of this buffer
*            is given by the argument max_converted_value_length.  If the buffer
*            is not large enough, the return code should be set to 1, and
*            the argument actual_converted_value_length should be set the
*            size of the buffer that is required.
*
*  Dependencies:
*
*  Restrictions:
*
*  Input: sqlint16 sqltype: Data type of input
*         sqluint8* inputData: Pointer to input data
*         sqlint32  inputLenght: Length of input data
*         sqlint32  precision:  Used with decimal datatype
*         sqlint32  scale:   Used with decimal datatype
*         sqluint8 *converted_value: a buffer into which the converted
*                value should be placed.
*
*
*  Output: 
*      sqlint32 converted_value_length: if converted_value_length
*      isn't long enough, should contain the length that the buffer should be.
*
*
*  Normal Return = 0
*
*  Error Return = 1, if converted_value is not large enough to contain value
*               != 0, error condition.
*
**************************************************************************/
//@bd265406vcr
//@bd220117kal
sqlint32 Sample_Utilities::convert_data(
                                   sqlint16 sqltype,
                                   sqluint8* inputData,
                                   sqlint32  inputLength,
                                   sqlint32  precision,
                                   sqlint32  scale,
                                   char *converted_value,
                                   sqlint32 *converted_value_length
                                  )        
{
  sqlint32   rc = 0;
  int searchTermInt = 0;
  short searchTermShort = 0;
  double searchTermFl = 0.0;
  sqlint32        trace_error = 0;
  
  Wrapper_Utilities::fnc_entry(93,"Sample_Utilities::convert_data");

  switch (sqltype)
  {
    case SQL_TYP_INTEGER:
      {
        searchTermInt = *(int *)inputData;
        *converted_value_length = sprintf(converted_value, "%d", searchTermInt);
        break;
      }
    case SQL_TYP_SMALL:
      {
        searchTermShort = *(short *)inputData;
        *converted_value_length = sprintf(converted_value, "%d", searchTermShort);
        break;
      }

    case SQL_TYP_FLOAT:
      {
        searchTermFl = *(double *)inputData;
        *converted_value_length = sprintf(converted_value, "%1f", searchTermFl);
        break;
      }
    case SQL_TYP_CHAR:
    case SQL_TYP_VARCHAR:
      {
        *converted_value_length = inputLength;
        strncpy(converted_value, (char *)inputData, inputLength);
        break;
      }
    case SQL_TYP_DECIMAL:
      {
        char     *decString = NULL;

        // unpack the db2 packed decimal into a string..
        rc = Sample_Utilities::unpack( scale, precision, 
            (unsigned char *)inputData, &decString);
        if (rc)
        {
          if (decString != NULL )
          { 
            Wrapper_Utilities::deallocate(decString);
          }
          trace_error = 10;
          goto error;
        }

        *converted_value_length = strlen(decString);
        strncpy(converted_value, decString,*converted_value_length);
        Wrapper_Utilities::deallocate(decString);
        break;
      }
    default:
      {
        break;
      }
  }   
  
  
exit:
    Wrapper_Utilities::fnc_exit(93,"Sample_Utilities::convert_data", rc);
    return rc;

error:
    Wrapper_Utilities::trace_error(93,"Sample_Utilities::convert_data", 
                         trace_error, sizeof(rc), &rc);
    goto exit;
}
