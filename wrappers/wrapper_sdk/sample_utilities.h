/**********************************************************************
*
*  Source File Name = sample_utilities.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: Class used to define utilities.
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_UTILITIES_H__
#define __SAMPLE_UTILITIES_H__

#include "sample_nickname.h"
#include "sqlqg_misc.h"
#include "sqlqg_catalog.h"

class Sample_Utilities {
public:
    
    // Verifies that the columns data types and options supplied in the CREATE/ALTER 
    // NICKNAME ddl are supported by this wrapper.
    static sqlint32 verify_column_type_and_options(Nickname* a_nickname, Nickname_Info *nickname_info, 
                                                 sqluint8* serverName);
    
    // Searches for an option_name and saves (allocate and copy) the value as a string
    static sqlint32 save_option_value(Catalog_Info *catalog_info, const char *option_name, 
                                      sqluint8 **option_save_location);
    
    static sqlint32 unpack(int scale, int precision, unsigned char *decData, char **constant);
     
    static sqlint32 convert_data(
                            sqlint16 sqltype,
                            sqluint8* inputData,
                            sqlint32  inputLength,
                            sqlint32  precision,
                            sqlint32  scale,
                            char *converted_value,
                            sqlint32 *converted_value_length
    );

private:

    // Constructor.
    // Made private to prevent others from instantiating this class 
    
    Sample_Utilities();  
    
};


#endif
