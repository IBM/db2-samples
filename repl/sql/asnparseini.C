/*********************************************************************/
/*                                                                   */
/*     IBM DataPropagator Apply for UNIX AND WINDOWS                 */
/*                                                                   */
/*     Sample ASNLOAD program                                        */
/*                                                                   */
/*     Licensed Materials - Property of IBM                          */
/*                                                                   */
/*     (C) Copyright IBM Corp. 1994, 2002 All Rights Reserved        */
/*                                                                   */
/*     US Government Users Restricted Rights - Use, duplication      */
/*     or disclosure restricted by GSA ADP Schedule Contract         */
/*     with IBM Corp.                                                */
/*                                                                   */
/*********************************************************************/
/*     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                */
/*     PLEASE READ THE FOLLOWING BEFORE PROCEEDING...                */
/*     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                */
/*********************************************************************/
/*                                                                   */
/*     This file belongs to the ASNLOAD package for DataPropagator   */
/*     It contains the logic for parsing the inifile asnload.ini     */
/*                                                                   */
/* IMPORTANT!! -> this part as is is not ready for compilaton        */
/*             -> Please read the explanations of the ASNLOAD.SMP    */
/*                for details of the whole ASNLOAD package and how   */
/*                to use and modify it                               */
/*                                                                   */
/*********************************************************************/
/*                                                                   */
/*           NOTICE TO USERS OF THE SOURCE CODE EXAMPLE              */
/*                                                                   */
/* INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE   */
/* CODE EXAMPLE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         */
/* EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO THE IMPLIED   */
/* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR        */
/* PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE */
/* SOURCE CODE EXAMPLE IS WITH YOU. SHOULD ANY PART OF THE SOURCE    */
/* CODE EXAMPLE PROVES DEFECTIVE, YOU (AND NOT IBM) ASSUME THE       */
/* ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.     */
/*                                                                   */
/*********************************************************************/
#include "asnload.h"

#include <ctype.h>
#include <memory.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#if onUNIX
  #include <strings.h>
#endif
#include <stdlib.h>
#include <malloc.h>
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
#include <sqlutil.h>

/* db2 includes: */
#include <sqlcli1.h>

/******************************************************************************/
/****** global typedefs and variables needed for parsing the ini file *********/
/******************************************************************************/
FILE *finifile;
bool fnd_ini_file;
char inifilelinebuffer[INIFILE_LINEBUFFER_LENGTH+1]; // stores 1 line
int len_inifilelinebuffer;
bool check_if_commentline = FALSE;

/* - define a dynamic data structure for ini-filevalues per [database alias]   */
/* - only the 1st element has the values of the [common] section in case that */
/*   this section was found in the ini-file                                   */
/* - if there is no common section specified the 1st element holds the default*/
/*   values                                                                   */
/* ... see asnload.h for declaration of ini_file_values                       */
ini_file_values *ifv = NULL;
// pointer to common values resp. default values
ini_file_values *point_to_common = NULL;

/* holds the information if there is a double specified command in a given section */
struct double_commands
{
  char* section;          
  bool  statistics;
  bool uid;
  bool pwd;
  bool lobpath;
  bool lobfile;
  bool maxlobs;
  bool copy;
  bool copyto;
  bool data_buffer_size;
  bool cpu_parallelism;
  bool disk_parallelism;
};
struct double_commands double_command;

/******************************************************************************/
/* Functions declarations                                                     */
/******************************************************************************/
/* see definitions for parameter explanations and more details                */
/******************************************************************************/

// entry function for the inifileparsing
int parse_inifile(char* dbAliasSrc,
                  char* dbAliasCntl,
                  char* dbAliasTrgt);

// traces out the parsed values in the end
/* ! this function need to be changed if you add a new keyword ! */
void trace_inifilevalues();

/*********** the following  functions handle the inifile commands  ***********/

// extracts a section header and processes it
int handle_section_header(char* dbAliasSrc,
                          char* dbAliasTrgt,
                          char* dbAliasCntl,
                          bool  *piowait_until_next_section,
                          int ind,
                          int cnt);

// extracts a specified keyword of a inifileline
int extract_keyword(char* keywordstring,
                    int *pind);

// checks a specified keyword if it is valid and initiates the reading
// of the value for each keyword with the invokation of respective
// functions
/* ! this function need to be changed if you add a new keyword ! */
int check_keyword (char* tmpstring,
                   char* inifilelinebuffer,
                   struct double_commands *double_command,
                   int ind,
                   int cnt);

/********** the following functions are needed to extract the values **********/

// reads the separated value of type character
int read_character_value(
                         char* pvaluecharacter,
                         char* inifilelinebuffer,
                         int ind,
                         int cnt,
                         int maxstrlen
                         );

// reads the separated value of numeric type
int read_num_value (
                    int* pifvalueinteger,
                    char* inifilelinebuffer,
                    int ind,
                    int cnt
                    );

//reads the separated value of type boolean
int read_bool_value(bool* pifvaluebool,
                    char* inifilelinebuffer,
                    int ind,
                    int cnt);

// character values: needed for lobaths/lobfile values, when values are longer
// than a line and one keyword can have >1 values indicated with a comma
int read_multiple_valuelines (char* inifilelinebuffer,
                              char** piString,
                              int ind, 
                              int cnt,
                              bool values_needed);

// checks an inifile value (single value) for quotes
int check_quotes (char* inifilelinebuffer,
                  int *ind, 
                  int *cnt, 
                  int *number );

// separates the values from the inifileline
int circle_value(char* inputstring, char* keyword, int *pind, int *pcnt,
                 int len_inputstring);

// separates one particular value in a string containing more than one value in
// the case one command is allowed to have multivalues
int circle_value_in_multivaluestring(char* inputstring,
                                     int *ponumcharacters,
                                     int *prun,
                                     int *pleft,
                                     int *pright,
                                     int last);

/*********** additional useful functions for parsing through a string ********/

// determine the position of the first non blank character value
void gofirstcharacter( char* string, int *pind, int length );
// determine the position of the last non blank character value
void golastcharacter( char* string, int *pcnt, int length );
// converts a string into upperstring
void convertToUpper(char* str);

/***************************** other functions *******************************/

//sets the ASNLOAD defaults
/* ! this function might be needs to be changed if you add a new keyword ! */
void set_defaults();

//belongs to handle_section header and allocates new memory for values if a
//new header is found
/* ! this function need to be changed if you add a new keyword ! */
void create_new_section(char* sectionstring);

//needed to manage double commands in a section
/* ! this function need to be changed if you add a new keyword ! */
void reset_double_commands();

/***************  for each keyword there is a specific function: ***************/
int check_statistics_value (char* inifilelinebuffer, 
                            struct double_commands *double_command, 
                            int ind,
                            int cnt);

int check_uid_value(char* inifilelinebuffer,
                    struct double_commands *double_command,
                    int ind,
                    int cnt);

int check_pwd_value(char* inifilelinebuffer,
                    struct double_commands *double_command,
                    int ind,
                    int cnt);

int check_lobpath_value (char* inifilelinebuffer,
                         struct double_commands *double_command,
                         int ind,
                         int cnt);

int check_lobfile_value(char* inifilelinebuffer,
                        struct double_commands *double_command,
                        int ind,
                        int cnt);

int check_maxlobs_value (char* inifilelinebuffer,
                         struct double_commands *double_command,
                         int ind,
                         int cnt);

int check_copy_value (char* inifilelinebuffer,
                      struct double_commands *double_command,
                      int ind,
                      int cnt);

int check_copyto_value (char* inifilelinebuffer,
                        struct double_commands *double_command,
                        int ind,
                        int cnt);

int check_databuffersize_value (char* inifilelinebuffer,
                                struct double_commands *double_command,
                                int ind,
                                int cnt);

int check_cpuparallelism_value (char* inifilelinebuffer,
                                struct double_commands *double_command,
                                int ind,
                                int cnt);

int check_diskparallelism_value (char* inifilelinebuffer,
                                 struct double_commands *double_command,
                                 int ind,
                                 int cnt);

/*******           special functions for certain keywords             ******/
// builds a lobfile list in the global variable Lobfilelist of asnload.sqc
// for the keyword lobfile
int build_lobfile_list (char* tmpstring,
                        int first,
                        int last, 
                        int* number_of_elements, 
                        sqlu_location_entry** pListe);


// builds a lobpath list in the global variable Lobpathlist of asnload.sqc
//for the keyword lobpath
int build_lobpath_list (char* tmpstring,
                        int first,
                        int last, 
                        int* number_of_elements,
                        sqlu_media_entry** pListe);


/*****************************************************************************/
/******                     Begin of Implementation                     ******/
/*****************************************************************************/

/******************************************************************************
 *
 *  Function Name  = convertToUpper
 *
 *  Descriptive Name = convert string to upperstring
 *
 *  Function = converts a string into upperstring
 *
 *  Input params:
 *
 *  Output params:
 *    str: string to be converted
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void convertToUpper(char* str) 
{

  int length,i;
  length = strlen(str);
  for(i=0; i<length; i++)
  {
    *(str+i) = (char)toupper((int)*(str+i));
  }
  
}


/******************************************************************************
 *
 *  Function Name  = check_quotes
 *
 *  Descriptive Name = tests a  string for quotation marks
 *
 *  Function = - circles the value if its surrounded by quotation marks and
 *             - determines the length of the value (without quotes)
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inifilelinebuffer: one line of the inifile
 *
 *  Output params:
 *    ind: pointer to an integer representing the position of the first
 *         character of the value in the sting
 *    cnt: pointer to an integer representing the position of the last
 *         char of the value in the string
 *    number: pointer to an integer representing the length of the value
 *             (without quotation marks)
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int check_quotes (
                  char* inifilelinebuffer,
                  int *ind, 
                  int *cnt, 
                  int *number 
                  )
{
  rc = 0;

  /* check quotes syntax */
  if ( 
      (
        ((inifilelinebuffer[*ind] == '"') && 
         ( inifilelinebuffer[*cnt] == '"')&& 
         (*ind==*cnt))
        ||
        ((inifilelinebuffer[*ind] == '"') && 
         (inifilelinebuffer[*cnt]!='"'))
        ||
        ((inifilelinebuffer[*ind] !='"') && 
         (inifilelinebuffer[*cnt]        =='"'))
       )
    )
  {
    if (trc)
    {
      trace("  ERR: Wrong set quotes in commandline: %s",
            inifilelinebuffer);
    }
    printasnloadmsg("  ERR: Wrong set quotes in commandline: %s",
                    inifilelinebuffer);
    rc = ASNLOAD_ERROR;
    goto exit;
  }
  else if ((inifilelinebuffer[*ind] == '"') &&(inifilelinebuffer[*cnt]== '"'))
  {
    *ind=*ind+1;
    *cnt=*cnt-1;
  }
  
  /* number shows how many not empty characters the value has and how */
  /*many charactars may have to be copied, when using strncpy/strncat */
  *number=*cnt-*ind+1;
  
 exit:
  
  if (rc!=0) 
  { 
    return ASNLOAD_ERROR;
  } else 
  {
    return 0;
  }
  
} /* end of function check_quotes */

/******************************************************************************
 *
 *  Function Name  = circle_value_in_multivaluestring
 *
 *  Descriptive Name = circle one value in string with multiple values
 *
 *  Function = In the case a keyword is allowed to have more than one value
 *             (e.g. path lists) and the values are separated by  commas,
 *             this function sets the positions of one values begin and end
 *             while also checking for quotation marks. 
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inputstring: a string containing all values of the keyword, this
 *                 string has been built before with checking if these values
 *                 were specified in multiple lines of the inifile
 *
 *  Output params:
 *    ponumcharacters: pointer to an integer showing the length of that
 *                     particular value
 *    prun: pointer to an integer representing the position of the comma
 *          -> input comma before value
 *          -> output comma after value
 *    pleft: -> input: pointer to an integer representing the position either
 *              of the first character of the multivalues or the character
 *              after the comma
 *           -> output: pointer to an integer representing the first position
 *              of a particular value (without quotes)
 *    pright: pointer to an integer representing the position of the last
 *            character of a particular value in a multivalue string
 *            (quotes not included)
 *    last: integer representing the position of the last character in
 *          the inputstring
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int circle_value_in_multivaluestring(char* inputstring,
                                     int *ponumcharacters,
                                     int *prun,
                                     int *pleft,
                                     int *pright,
                                     int last)
{
  rc=0;

  int run=*prun;
  int ind=*pleft;
  int cnt=*pright;

  if (inputstring[ind]=='"')
  {
    /*commas are allowed in pathnames so try now only to jump over   */
    /*commas within quotes because quotes indicate special characters*/
    /* such as commas included                                       */
    //goto the next quotesign
    for (
          cnt=ind+1;
          ((cnt<=last)&&(inputstring[cnt]!='"'));
          cnt++
      );
          
    if (cnt>last)
    {
      if (trc)
      {
        trace("  ERR: Wrong set quotes for Lobpath/Lobfile value");
      }
      rc=ASNLOAD_ERROR;
      goto exit;
    }
          
    /* now circle value */
          
    //run to the next comma after the quotes and check if correct
    run=cnt+1;
    if (run<last)
    {
      //only blanks are allowed after the quotes so ignore
      for (run;isspace(inputstring[run]);run++);
      if (inputstring[run]!=',')
      {
        if (trc)
        {
          trace("  ERR: Wrong set Lobpath/Lobfile value");
        }
        rc=ASNLOAD_ERROR;
        goto exit;
      }
    }
          
    ind=ind+1;
    cnt = cnt-1;
    if (ind>cnt)
    {
      if (trc)
      {
        trace("  ERR: Wrong set quotes in for Lobpath/Lobfile value");
      }
      rc=ASNLOAD_ERROR;
      goto exit;
    }
  } else //end of if quotes
  {
    /* run to the (next) comma */
    for (run=ind;((run<=last)&&(inputstring[run]!=','));run++);
          
    /* last value doesn't end with a comma so set cnt to last */
    if (run > last)
    {
      cnt = last;
    } else
    {
      //delete blanks before the comma
      for (
           cnt=run-1; 
           (run>0) && (isspace(inputstring[cnt])); 
           cnt--
          );
      if (cnt<ind)
      {
        if (trc)
        {
          trace("  ERR: Wrong set value - check commas");
        }
        rc=ASNLOAD_ERROR;
        goto exit;
      }
    }

  } //end else
      
  *ponumcharacters=cnt-ind+1;
  *prun=run;
  *pleft=ind;
  *pright=cnt;

 exit:

  return rc;
  
} //end of circle_value_in_multivaluestring

/******************************************************************************
 *
 *  Function Name  = read_multiple_valuelines
 *
 *  Descriptive Name = read multiple value lines
 *
 *  Function = In the case a keyword is allowed to have multiple values
 *             this function reads all these lines of the inifile and
 *             builds one string from those.
 *
 *  Input params:
 *    trc (global): traceindicator
 *    finifile (global): inifilename
 *    inifilelinebuffer: content of the actual line of the infile
 *    len_inifilelinebuffer (global): length of the actual inifilelinebuffer
 *    values_needed: if not needed overjump some parts to save time
 *    ind: position of the first non blank character of inifilelinebuffer
 *    cnt: position of the last non blank character of inifilelinebuffer
 *
 *  Output params:
 *    piString: holds all multiple values
 *    len_inifilelinebuffer: length of inifilelinebuffer, but has no effect
 *                           because after this the normal parsing loop
 *                           continues with receiving a new line and the
 *                           len_inifilelinebuffer will be reset immediately.
 *    
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int read_multiple_valuelines (
                              char* inifilelinebuffer,
                              char** piString,
                              int ind, 
                              int cnt,
                              bool values_needed
                             )
{
  rc=0;
  char* tmpstring=NULL;
  int number = 0;
  bool stopwhile;
  char* check;
  
  stopwhile = FALSE;

  if (values_needed)
  {
    number=cnt-ind+1;
    tmpstring = (char*) malloc( number+1 );
    strncpy(tmpstring,&inifilelinebuffer[ind],number);
    tmpstring[number]='\0';
  }
  
  if ( inifilelinebuffer[cnt] != ',' ) 
  {
    stopwhile=TRUE;
  }
  
  /*In case of loadx_type other than NULL, 2, 4 and 5 or a double command    */
  /*(indicated by values_needed) don't save the values to                    */
  /*improve asnload speed. ...but still check whether                        */
  /*the next line continues with values and in this case that line must be   */
  /*skipped in the further routine:                                          */ 
  /* next commandline continues with values if last char of                  */
  /*inifilelinbuffer == ';'                                                  */
  while (!stopwhile/*inifilelinebuffer[cnt] == ','*/) //cnt indicates last char 
                                                       //of inifilelinebuffer
  {
    if  ( fgets(inifilelinebuffer,INIFILE_LINEBUFFER_LENGTH+1,finifile)!= NULL )
    {
    } else if ( !(feof(finifile)) )
    {
      if (trc) 
      {
        trace ("  ERR: Can not read in the ini file - "
               "file access error");
      }
      rc = ASNLOAD_ERROR;
      goto exit;
    } else
    {
      if (trc) {trace ("  ERR: unexpected end of file");}
      rc = ASNLOAD_ERROR;
      goto exit;
    }

    len_inifilelinebuffer=strlen(inifilelinebuffer);

    //if too long...
    if (!(strstr(inifilelinebuffer, "\n")) && 
        (len_inifilelinebuffer==INIFILE_LINEBUFFER_LENGTH)) 
    {       
      if (trc) 
      {
        trace("  ERR: inifile command line is too long ");
        trace("       allowed are '%d' characters:", INIFILE_LINEBUFFER_LENGTH);
      }
      rc= ASNLOAD_ERROR;
      goto exit;
    }

    //goto the 1st nonblankchar of the linebuffer
    gofirstcharacter(inifilelinebuffer,&ind,INIFILE_LINEBUFFER_LENGTH);

    //goto the last nonblankchar of the linebuffer
    golastcharacter(inifilelinebuffer, &cnt, len_inifilelinebuffer);

    // if commentline -> run a check for the next line
    if ( inifilelinebuffer[ind] == ';' )
    {
      check_if_commentline = TRUE; //chg31
    }
    // if empty line -> run check for the next line
    else if ( inifilelinebuffer[ind]=='\n' || inifilelinebuffer[ind]=='\0')
    {
    }
    //if section header -> error
    else if (inifilelinebuffer[ind] == '[')
    {
      if (trc)
      {
        trace("  ERR: No section header allowed. %s",inifilelinebuffer);
      }
      printasnloadmsg("  ERR: No section header allowed, expecting continuing "
                      "value");
      printasnloadmsg("   --- See commandline: %s",inifilelinebuffer);
      rc=ASNLOAD_ERROR;
      goto exit;
    }
    // else check line for further values
    else
    {
      if ( inifilelinebuffer[cnt] != ',' )
      {
        stopwhile=TRUE;
        check_if_commentline = FALSE;
      }
      
      //If a new command was read because of an incorrect set comma -> Error
      //This is necessary because the new commandline would be used
      //as a path or file value and the utiltiy might not recognize this as
      //an error because the name is valid
      if ( (check=strchr(inifilelinebuffer,'='))!=0)
      {
        int hleft=0;
        int hright=0;
        char helpstring[INIFILE_LINEBUFFER_LENGTH+1];
        strcpy(helpstring,"");

        //circle the fields before the '=' sign
        for (hleft; isspace(inifilelinebuffer[hleft]);hleft++);
        for (hright; &inifilelinebuffer[hright]<check;hright++);
        for (
              hright--;
              isspace(inifilelinebuffer[hright])&&(hright>0);
              hright--
             );
        //if there is a string before the = sign -> check if it is a keyword
        //else add it to the multiple value string
        if ( (inifilelinebuffer[hleft]!='=')&&(hright>0) )
        {
          number=hright-hleft+1;
          strncpy(helpstring,&inifilelinebuffer[hleft],number);
          helpstring[number]='\0';
          if ( strstr(COMMAND_LIST,helpstring)!=0)
          {
            printasnloadmsg("  ERR: Inifileline must be a continuing value, "
                            "because of a comma, set in the previous line...");
            printasnloadmsg("   --- See commandline: %s",inifilelinebuffer);
            rc=ASNLOAD_ERROR;
            goto exit;
          }
        }
      } //end check for a command
      
      if (values_needed)
      {
        // add actual to line to tmpstring
        number=cnt-ind+1;
        if ((tmpstring = 
             (char*) realloc (tmpstring,strlen(tmpstring)+number+1)) == NULL)
        {
          if (trc)
          {
            trace("  ERR: an internal error occured       ");
            trace("       ...memory allocation error for lobpathvalue");
          }
          rc = ASNLOAD_ERROR;
          goto exit;                
        }
        strncat(tmpstring,&inifilelinebuffer[ind],number);
      }
    } //end else
    
  } /* end of while */
  
  *piString=tmpstring;
  
 exit:
  
  return(rc);
}//end of read_multiple_valuelines


/******************************************************************************
 *
 *  Function Name  = build_lobfile_list
 *
 *  Descriptive Name = build lobfile list
 *
 *  Function = Inital point for building a list from a string containing
 *             all lobfile values. This function builds this list of type
 *             sqlu_location_entry and allocates the memory.
 *
 *  Input params:
 *    trc (global): traceindicator
 *    tmpstring: string containing all lobfile values
 *    first: position of the first non blank character in tmpstring
 *    last: position of the last non blank character in tmpstring
 *
 *  Output params:
 *    number_of_elements: pointer to an integer representing the
 *                        number of lobfile values
 *    pListe: pointer to a pointer of type sqlu_location_entry,
 *            memory for that pointer will be allocated here
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int build_lobfile_list (
                        char* tmpstring,
                        int first,
                        int last, 
                        int* number_of_elements, 
                        sqlu_location_entry** pListe
                       )
{
  rc=0;
  
  //for parsing the tempstring
  int number; //number of characters for a particular value
  int run;    //stringposition of  a comma
  int left;
  int right;

  int loop=0; //also indicates number of elements
  sqlu_location_entry* help_pointer=NULL;
    
  help_pointer = (sqlu_location_entry*) 
    malloc(MEMORY_ALLOCATION_SIZE * sizeof(sqlu_location_entry));
  
  run=first;
  left=first;
  
  while (left<=last)
  {
    if ( (((loop) % MEMORY_ALLOCATION_SIZE) == 0) && (loop!=0) )
    {
      if ((help_pointer = (sqlu_location_entry*) 
           realloc (help_pointer ,(((loop)+(MEMORY_ALLOCATION_SIZE))*
                                   (sizeof(sqlu_location_entry))))) == 0)
      {
        if (trc)
        {
          trace("  ERR: an internal error occured");
          trace("  --- ...memory allocation error for Lobpath/Lobfilelist");
        }
        rc = ASNLOAD_ERROR;
        goto exit;
      }
    }

    //now circle one value in the multivalue string
    rc = circle_value_in_multivaluestring(tmpstring,
                                          &number,
                                          &run,
                                          &left,
                                          &right,
                                          last);
    if (rc!=0)
    {
      goto exit;
    }

    //insert value into the list if allowed
    if (number > SQLU_MEDIA_LOCATION_LEN ) //if value is too long
    {
      if (trc)
      {
        //prepare the tmpstring, that (can) contain many values
        //to show the value that is too long and trace it
        strncpy(tmpstring,&tmpstring[left],number);
        tmpstring[number]='\0';
        trace ("  ERR: Lobfile entry is longer than %d "
               "characters",SQLU_MEDIA_LOCATION_LEN);
        trace ("  ---  See entry: %s", tmpstring);
              
      }
      rc=ASNLOAD_ERROR;
      goto exit;
    } else
    {
      strncpy((help_pointer + loop) -> location_entry, 
              &tmpstring[left], 
              number);
      (help_pointer + loop) -> location_entry[number]='\0';
      (help_pointer + loop)-> reserve_len =
        strlen((help_pointer +loop) -> location_entry);
    }
      
    //now set left after the run (comma) sign and delete blanks
    left=run+1;
    if (left<last)
    {
      for(left; isspace(tmpstring[left]); left++ ) ;
    }
      
    loop = loop+1;
          
  } /* end while */
  
  //reallocate memory to the exact amount of lobfile/lobpath values to 
  //avoid complications when passing the list through the movement apis
  if((help_pointer =  (sqlu_location_entry*) 
      realloc ( help_pointer,((loop) *(sizeof(sqlu_location_entry))))) == 0) 
  {
    if (trc)
    {
      trace ("  ERR: an internal error occured ");
      trace ("       ...memory allocation error for "
             "Lobfilelist");
    }
    rc = ASNLOAD_ERROR;
    goto exit;
  }
  
  
  *pListe=help_pointer;
  *number_of_elements=loop;
      
 exit:
  
  return(rc);

} // end of build_lobfile_list


/******************************************************************************
 *
 *  Function Name  = build_lobpath_list
 *
 *  Descriptive Name = build lobpath list
 *
 *  Function = Inital point for building a list from a string containing
 *             all lobpath values. This function builds this list of type
 *             sqlu_media_entry and allocates the memory.
 *
 *  Input params:
 *    trc (global): traceindicator
 *    tmpstring: string containing all lobpath values
 *    first: position of the first non blank character in tmpstring
 *    last: position of the last non blank character in tmpstring
 *
 *  Output params:
 *    number_of_elements: pointer to an integer representing the
 *                        number of lobpath values
 *    pListe: pointer to a pointer of type sqlu_media_entry,
 *            memory for that pointer will be allocated here
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int build_lobpath_list (
                        char* tmpstring,
                        int first,
                        int last, 
                        int* number_of_elements,
                        sqlu_media_entry** pListe
                       )
{
  rc=0;
  
  //for parsing the tempstring
  int number; //number of characters for a particular value
  int run;      //stringposition of  a comma
  int left;
  int right;

  int loop=0; //also indicates number of elements
  sqlu_media_entry* help_pointer=NULL;
  
  help_pointer = (sqlu_media_entry*) 
    malloc(MEMORY_ALLOCATION_SIZE * sizeof(sqlu_media_entry));
  
  run=first;
  left=first;
  
  while (left<=last)
  {
    if ( (((loop) % MEMORY_ALLOCATION_SIZE) == 0) && (loop!=0) )
    {
      if ( (help_pointer = (sqlu_media_entry*) 
            realloc (help_pointer ,
                     (((loop) + (MEMORY_ALLOCATION_SIZE))*
                      (sizeof(sqlu_media_entry))))) == 0 ) 
      {
        if (trc)
        {
          trace("  ERR: an internal error occured       ");
          trace("       ...memory allocation error for Lobpathlist");
        }
        rc = ASNLOAD_ERROR;
        goto exit;
      }
    }

    //now circle one value in the multivalue string
    rc = circle_value_in_multivaluestring(tmpstring,
                                          &number,
                                          &run,
                                          &left,
                                          &right,
                                          last);
    if (rc!=0)
    {
      goto exit;
    }
      
            
    //insert value into the list
    if (number > SQLU_DB_DIR_LEN ) //if value is too long
    {
      if (trc)
      {
        //prepare the tmpstring, that (can) contain many values
        //to show the value that is too long and trace it
        strncpy(tmpstring,&tmpstring[left],number);
        tmpstring[number]='\0';
        trace ("  ERR: Lobpath entry is longer than %d "
               "characters",
               SQLU_DB_DIR_LEN);
        trace ("   --- See entry: %s", tmpstring);
              
      }
      rc=ASNLOAD_ERROR;
      goto exit;
    } else
    {
      strncpy((help_pointer + loop) -> media_entry, &tmpstring[left], number);
      (help_pointer + loop) -> media_entry[number]='\0';
#if onNT
      if ( (help_pointer +loop) -> media_entry[number-1] != '\\')
      {   
        if ( strlen((help_pointer +loop) -> media_entry ) >= SQLU_DB_DIR_LEN )
        {
          rc=ASNLOAD_ERROR;
          goto exit;
        }
        strcat( (help_pointer +loop) -> media_entry, "\\");
      }
#else
      if ( (help_pointer+loop) -> media_entry[number-1] != '/' )
      {
        if ( strlen((help_pointer +loop) -> media_entry ) >= SQLU_DB_DIR_LEN )
        {
          rc=ASNLOAD_ERROR;
          goto exit;
        }
        strcat( (help_pointer +loop) -> media_entry , "/");
      }
#endif
      (help_pointer + loop)-> reserve_len = 
        strlen((help_pointer +loop) -> media_entry);
    }
      
    //now set left after the run (comma) sign and delete blanks
    left=run+1;
    if (left<last)
    {
      for(left; isspace(tmpstring[left]); left++ ) ;
    }
      
    loop = loop+1;
      
  } /* end while */
  
  //reallocate memory to the exact amount of lobfile/lobpath values to avoid
  //complications when passing the list through the movement apis
  if( (help_pointer =  (sqlu_media_entry*) 
       realloc (help_pointer, ((loop)*(sizeof(sqlu_media_entry))))) == 0 ) 
  {
    if (trc)
    {
      trace ("  ERR: An internal error occured");
      trace ("       ...memory allocation error for Lobpathlist");
    }
    rc = ASNLOAD_ERROR;
    goto exit;
  }
  
  
  *pListe=help_pointer;
  *number_of_elements=loop;
  
 exit:

  return(rc);
}//end of build_lobpath_list



/******************************************************************************
 *
 *  Function Name  = read_character_value
 *
 *  Descriptive Name = read character value
 *
 *  Function = reads a character value from the inifilelinebuffer while
 *             checking for errors
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inifilelinebuffer: one line of the inifile
 *    ind: position of the begin of the value in inifilelinebuffer
 *    cnt: position of the end of the value in inifilelinebuffer
 *    maxstrlen: maximum length of the value to be read
 *
 *  Output params:
 *    pvaluecharacter: this string contains the extracted value
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int read_character_value(
                         char* pivaluecharacter,
                         char* inifilelinebuffer,
                         int ind,
                         int cnt,
                         int maxstrlen
                        )
{
  rc=0;
  int number;

  rc = check_quotes (inifilelinebuffer,&ind,&cnt,&number);
  if (rc!=0)
  {
    goto exit;
  }
  
  if ( number > maxstrlen )
  {
    trace("  ERR: The value is longer than the allowed '%d' characters.",
          maxstrlen);
    rc=ASNLOAD_ERROR;
    goto exit;
  }

  strncpy(pivaluecharacter, &inifilelinebuffer[ind], number);
  pivaluecharacter[number] = '\0';

 exit:
  
  return rc;

} // end of read_character_value

/******************************************************************************
 *
 *  Function Name  = read_num_value
 *
 *  Descriptive Name = read numerical value
 *
 *  Function = reads a numerical (integer) value from the inifilelinebuffer
 *             while checking for errors
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inifilelinebuffer: one line of the inifile
 *    ind: position of the begin of the value in inifilelinebuffer
 *    cnt: position of the end of the value in inifilelinebuffer
 *
 *  Output params:
 *    pifvalueinteger: pointer to an integer variable containing the read
 *                     value
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int read_num_value (
                    int* pifvalueinteger,
                    char* inifilelinebuffer,
                    int ind,
                    int cnt
                    )
{
  rc=0;
  
  int number;
  int i;
  int r;
  char helpstring[INIFILE_LINEBUFFER_LENGTH+1];
  
  rc = check_quotes (inifilelinebuffer,&ind,&cnt,&number);
  if (rc!=0)
  {
    goto exit;
  }
    
  /* read the inputstring and convert to integer value */
  for (i=ind,r=0; i<ind+number; i++,r++)
  {
    if ( (inifilelinebuffer[i]>='0') && (inifilelinebuffer[i]<='9') )
    {
      helpstring[r]=inifilelinebuffer[i];
    } else
    {
      if (trc)
      {
        trace("  ERR: The value must be of type integer");
      }
      printasnloadmsg("  ERR: The value must be of type integer. Line: %s",
                      inifilelinebuffer);
      *pifvalueinteger=0;
      rc=ASNLOAD_ERROR;
      goto exit;
    }
  }
  //terminate the helpstring
  helpstring[number]='\0';
  //all characters are numeric -> convert the string
  *pifvalueinteger = atoi(helpstring);

 exit:
  
  return rc;
  
} // end of read_num_value

/******************************************************************************
 *
 *  Function Name  = read_bool_value
 *
 *  Descriptive Name = read bool value
 *
 *  Function = reads a bool  value from the inifilelinebuffer
 *             while checking for errors
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inifilelinebuffer: one line of the inifile
 *    ind: position of the begin of the value in inifilelinebuffer
 *    cnt: position of the end of the value in inifilelinebuffer
 *
 *  Output params:
 *    pifvaluebool: pointer to a bool variable containing the read
 *                  value
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int read_bool_value(bool* pifvaluebool,
                    char* inifilelinebuffer,
                    int ind,
                    int cnt)
{
  rc=0;
  int number;

  rc = check_quotes (inifilelinebuffer,&ind,&cnt,&number);
  if (rc!=0)
  {
    goto exit;
  }

  if (number == 1 )
  {
    if (inifilelinebuffer[ind] == 'y' || inifilelinebuffer[ind] == 'Y' )
    {
      *pifvaluebool = TRUE;
    } else if ( inifilelinebuffer[ind] == 'n' || inifilelinebuffer[ind] =='N' )
    {
      *pifvaluebool = FALSE;
    } else 
    {
      if (trc)
      {
        trace("  ERR: Valid values are only: y,Y,n,N");
      }
      printasnloadmsg("  ERR: Valid values are only: y,Y,n,N. Line: %s",
                      inifilelinebuffer);
      rc=ASNLOAD_ERROR;
      goto exit;
    }
  } else 
  {
    if (trc)
    {
      trace("  ERR: Valid values are only: y,Y,n,N");
    }
    printasnloadmsg("  ERR: Valid values are only: y,Y,n,N. Line: %s",
                    inifilelinebuffer);
    rc = ASNLOAD_ERROR;
    goto exit;
  }

  
 exit:

  return rc;

}// end of read_bool_value


/******************************************************************************/
/******************************************************************************/
/*----------------------------------------------------------------------------*/
/*                                                                            */
/*                   SPECIAL KEYWORD HANDLING FUNCTIONS                       */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/* The following functions process for each command of a section the value    */
/* and check the value for errors                                             */
/* - all are invoked by the function: chech_keyword (...)                     */
/*                                                                            */
/* parameters (only input):                                                   */
/* - inifilelinebuffer : contains one line of the inifile                     */
/* - double_command : indicates that a command of a section has already been  */
/*                    processed and that the processing of this one can be    */
/*                    skipped                                                 */
/* - ind : position of the 1st not empty sign of the valuestring in           */
/*         inifilelinebuffer                                                  */
/* - cnt : position of the last not empty char of the valuestring             */
/*         in inifilelinebuffer                                               */
/******************************************************************************/
/* Normal Returns: 0                                                          */
/*                                                                            */
/* Error Returns: ASNLOAD_ERROR                                               */
/******************************************************************************/
/* !!! If you want to use a new keyword, after you have inserted it in     !!!*/
/* !!! the function check_keyword, add a function for this new keyword     !!!*/
/* !!! following the same template as the other keywords.                  !!!*/
/******************************************************************************/
/******************************************************************************/


/* checks the value of keyword "statistics"                                   */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_statistics_value (
                            char* inifilelinebuffer, 
                            struct double_commands *double_command, 
                            int ind, 
                            int cnt
                           )
{
  rc = 0;
  
  if (double_command ->statistics) 
  {
    return(0);
  }
  
  rc=read_bool_value(
                     &(ifv->statistics),
                     inifilelinebuffer,
                     ind,
                     cnt
                     );

  double_command ->statistics = TRUE;

 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword statistics");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword statistics");
  }

  return (rc);

} /* end of function check_statistics_value */

/* checks the value of keyword "lobpath"                                      */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_lobpath_value (
                         char* inifilelinebuffer,
                         struct double_commands *double_command,
                         int ind,
                         int cnt
                        )
{
  rc=0;
  char* tmpstring=NULL;
  bool  values_needed=FALSE;

  if ( ((loadx_type[0] == 'N' ) || 
        (loadx_type[0] == '2' ) ||
        (loadx_type[0] == '4' ) ||
        (loadx_type[0] == '5' ))
       && 
       !(double_command->lobpath) )
  {
    values_needed=TRUE;
  }
  
  rc=read_multiple_valuelines (
                               inifilelinebuffer,
                               &tmpstring,
                               ind,
                               cnt,
                               values_needed
                               );
  if (rc!=0)
  {
    goto exit;
  }
  
  if (values_needed)
  {
    //reset ind and cnt to first and last char of tmpstring
    ind=0;cnt=strlen(tmpstring)-1;
    //build the Lobpathlist from the tmpstring
    rc=build_lobpath_list(
                          tmpstring,
                          ind,
                          cnt,
                          &(ifv -> number_lobpaths),
                          &(ifv->pLobpathListMediaEntries)
                          );
    if (rc!=0)
    {
      goto exit;
    }
  }
  
  double_command ->lobpath = TRUE;
  
 exit:
  
  if (tmpstring!=NULL)
  {
    free(tmpstring);
    tmpstring=NULL;
  }
  
  return(rc);
  
} /* end of function check_lobpath_value */

/* checks the value of keyword "uid"                                          */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_uid_value(
                    char* inifilelinebuffer,
                    struct double_commands *double_command,
                    int ind,
                    int cnt
                    )
{
  rc=0;

  if (double_command -> uid)
  {
    return (0);
  }

  rc=read_character_value(
                          (ifv ->uid),
                          inifilelinebuffer,
                          ind,
                          cnt,
                          MAX_LENGTH_USERID
                         );

  double_command -> uid = TRUE;

 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword uid");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword uid");
  }
  
  return rc;
  
}

/* checks the value of keyword "pwd"                                          */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_pwd_value(
                    char* inifilelinebuffer,
                    struct double_commands *double_command,
                    int ind,
                    int cnt
                    )
{
  rc=0;
  
  if (double_command -> pwd)
  {
    return (0);
  }
  
  rc=read_character_value(
                          (ifv->pwd),
                          inifilelinebuffer,
                          ind,
                          cnt,
                          MAX_LENGTH_PWD
                          );


  double_command -> pwd = TRUE;

 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword pwd");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword pwd");
  }

  return rc;
}

/* checks the value of keyword "lobfile"                                      */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_lobfile_value(
                        char* inifilelinebuffer,
                        struct double_commands *double_command,
                        int ind,
                        int cnt
                        )
{
  rc=0;
  char* tmpstring=NULL;
  bool  values_needed=FALSE;

  //if apply passed a loadx_type 3 to ASNLOAD don't build the list, because it won't
  //be needed and saves some time
  if ( ((loadx_type[0] == 'N' ) || 
        (loadx_type[0] == '2' ) ||
        (loadx_type[0] == '4' ) ||
        (loadx_type[0] == '5' ))
       &&
       !(double_command->lobfile) )
  {
    values_needed = TRUE;
  }

  rc=read_multiple_valuelines(
                              inifilelinebuffer,
                              &tmpstring,
                              ind,
                              cnt,
                              values_needed
                             );
  if (rc!=0)
  {
    goto exit;
  }

  if (values_needed)
  {
    //reset ind and cnt to first and last char of tmpstring
    ind=0;cnt=strlen(tmpstring)-1;
    //build the Lobpathlist from the tmpstring
    rc=build_lobfile_list(
                          tmpstring,
                          ind,
                          cnt,
                          &(ifv -> number_lobfiles),
                          &(ifv->pLobfileListLocEntries)
                         );
    if (rc!=0)
    {
      goto exit;
    }
  }
  
  double_command ->lobfile = TRUE;
  
 exit:

  if (tmpstring!=NULL)
  {
    free(tmpstring);
    tmpstring=NULL;
  }
  return(rc);
  
} /* end of function check_lobfile_value */

/* checks the value of keyword "maxlobs"                                      */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_maxlobs_value (
                         char* inifilelinebuffer,
                         struct double_commands *double_command,
                         int ind,
                         int cnt
                        )
{
  rc=0;
  
  if (double_command ->maxlobs) 
  {
    return(0);
  }
  
  rc=read_num_value(
                    &(ifv->maxlobs),
                    inifilelinebuffer,
                    ind,
                    cnt
                    );
  
  double_command ->maxlobs = TRUE;
  
 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword maxlobs");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword maxlobs");
  }

  return(rc);

} /* end of function check_maxlobs_value */

/* checks the value of keyword "copy"                                         */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_copy_value (
                      char* inifilelinebuffer,
                      struct double_commands *double_command,
                      int ind,
                      int cnt
                      )
{
  rc=0;
  bool result;

  if (double_command ->copy) 
  {
    return(0);
  }
  
  rc=read_bool_value(
                     &result,
                     inifilelinebuffer,
                     ind,
                     cnt
                     );
  
  if (result==TRUE)
  {
    (ifv->copy)= COPY_ON;
  } else
  {
    (ifv->copy)= COPY_OFF;
  }
    
  double_command ->copy = TRUE;

 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword copy");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword copy");
  }
  
  return (rc);

} /* end of function check_copy_value */

/* checks the value of keyword "copyto"                                       */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_copyto_value (
                        char* inifilelinebuffer,
                        struct double_commands *double_command,
                        int ind,
                        int cnt
                       )
{
  rc = 0;
  int l;
  
  if (double_command ->copyto) 
  {
    return(0);
  }
  
  rc=read_character_value(
                          (ifv -> copyto),
                          inifilelinebuffer,
                          ind,
                          cnt,
                          COPYTO_LENGTH
                          );

  l=strlen(ifv -> copyto);
#if onNT
  if (ifv -> copyto[l-1] != '\\')
  {   
    strcat(ifv -> copyto, "\\");
  }
#else
  if (ifv ->copyto[l-1] != '/')
  {
    strcat(ifv -> copyto, "/");
  }
#endif

  double_command ->copyto = TRUE;
  
 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword copyto");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword copyto");
  }
  
  return(rc);
  
} /* end of function check_copy_to_value */

/* checks the value of keyword "data_buffer_size"                             */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_databuffersize_value (
                                char* inifilelinebuffer,
                                struct double_commands *double_command,
                                int ind,
                                int cnt
                                )
{
  rc =0;

  if (double_command ->data_buffer_size) 
  {
    return(0);
  }
  
  rc=read_num_value(
                    &(ifv -> data_buffer_size),
                    inifilelinebuffer,
                    ind,
                    cnt
                    );
                    
  double_command ->data_buffer_size = TRUE;
  
 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword data_buffer_size");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword data_buffer_size");
  }
  
  return (rc);
  
}/* end of function check_databuffersize_value */

/* checks the value of keyword "cpu_parallelism"                              */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_cpuparallelism_value (
                                char* inifilelinebuffer,
                                struct double_commands *double_command,
                                int ind,
                                int cnt
                               )
{
  rc = 0;

  if (double_command ->cpu_parallelism) 
  {
    return(0);
  }
  
  rc=read_num_value( 
                    &(ifv -> cpu_parallelism),
                    inifilelinebuffer,
                    ind,
                    cnt
                    );
    
  double_command -> cpu_parallelism = TRUE;
  
 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword cpu_parallelism");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword cpu_parallelism");
  }
  
  return (rc);
  
} /* end of function check_cpuparallelism_value */

/* checks the value of keyword "disk_parallelism"                             */
/* see "SPECIAL KEYWORD HANDLING FUNCTIONS" for parameter explanations        */
int check_diskparallelism_value (
                                 char* inifilelinebuffer,
                                 struct double_commands *double_command,
                                 int ind,
                                 int cnt
                                )
{
  rc=0;
  
  if (double_command ->disk_parallelism) 
  {
    return 0;
  }

  rc=read_num_value( 
                    &(ifv -> disk_parallelism),
                    inifilelinebuffer,
                    ind,
                    cnt
                   );
  
  double_command -> disk_parallelism = TRUE;

 exit:

  if (rc!=0)
  {
    if(trc)
    {
      trace("  ERR: Couldn't read value for keyword disk_parallelism");
    }
    printasnloadmsg("  ERR: Couldn't read value for keyword disk_parallelism");
  }
  
  return (rc);

} /* end of function check_diskparallelism_value */

/******************************************************************************/
/******************************************************************************/
/*----------------------------------------------------------------------------*/
/*                                                                            */
/*         ...end of SPECIAL KEYWORD HANDLING FUNCTIONS                       */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/******************************************************************************/
/******************************************************************************/

/******************************************************************************
 *
 *  Function Name  = check_keyword
 *
 *  Descriptive Name = check keyword
 *
 *  Function = For all valid keywords, the corresponding function will be
 *             called through this function. The called functions will
 *             check and extract the values from the inifile and save them
 *             in the structure ini_file_values pointed to by ifv.
 *
 *  Input params:
 *    trc (global): traceindicator
 *    tmpstring: string that holds the extracted keyword
 *    inifilelinebuffer: the actual line of the inifile
 *    double_command: indicator for doubled specified commands
 *    ind: position of the 1st non blank character in the inifilelinebuffer
 *         that should be the begining of the value
 *    cnt: position of the last non blank character in the inifilelinebuffer
 *         that should be the end of the value
 *    ifv -> section (global): the name of the actual section
 *
 *  Output params:
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int check_keyword (
                   char* tmpstring,
                   char* inifilelinebuffer,
                   struct double_commands *double_command,
                   int ind,
                   int cnt
                  ) 
{
  rc =0;
  
  if (trc)
  {
    trace("  Checking the keyword %s (check_keyword)",tmpstring);
  }
  
  /****************************************************************************/
  /* for each keyword the corresponding function call                         */
  /****************************************************************************/
  if ( stricmp(tmpstring,"statistics") == 0 ) 
  {
    rc = check_statistics_value(
                                inifilelinebuffer,
                                double_command,
                                ind,
                                cnt
                                );
    goto exit;
  }
  else if ( stricmp(tmpstring,"uid") == 0)
  {
    rc=check_uid_value(
                       inifilelinebuffer,
                       double_command,
                       ind,
                       cnt
                       );
    goto exit;
  } else if ( stricmp(tmpstring,"pwd")==0 )
  {
    rc=check_pwd_value(
                       inifilelinebuffer,
                       double_command,
                       ind,
                       cnt
                      );
    goto exit;         
  }
  else if ( stricmp(tmpstring, "lobpath") == 0 )    
  {
    rc = check_lobpath_value(
                             inifilelinebuffer,
                             double_command,
                             ind,
                             cnt 
                             );
    goto exit;
  } else if ( stricmp(tmpstring, "lobfile") == 0 )
  {
    rc = check_lobfile_value (
                              inifilelinebuffer,
                              double_command,
                              ind,
                              cnt 
                              );
    goto exit;
  } else if ( stricmp(tmpstring, "maxlobs") == 0 )    
  {
    rc = check_maxlobs_value(
                             inifilelinebuffer,
                             double_command,
                             ind,
                             cnt
                            );
    goto exit;
  } else if ( stricmp(tmpstring, "copy"   ) == 0 )   
  {
    rc = check_copy_value (
                           inifilelinebuffer,
                           double_command,
                           ind,
                           cnt
                           );
    goto exit;
  } else if ( stricmp(tmpstring, "copyto" ) == 0 ) 
  {
    rc = check_copyto_value(
                            inifilelinebuffer,
                            double_command,
                            ind,
                            cnt
                            );
    goto exit;
  } else if ( stricmp(tmpstring, "data_buffer_size") == 0 ) 
  {
    rc = check_databuffersize_value(
                                    inifilelinebuffer,
                                    double_command,
                                    ind,
                                    cnt
                                    );
    goto exit;
  } else if ( stricmp(tmpstring, "cpu_parallelism" ) == 0 ) 
  {
    rc = check_cpuparallelism_value (inifilelinebuffer,
                                     double_command,
                                     ind,
                                     cnt);
    goto exit;
  } else if ( stricmp(tmpstring, "disk_parallelism") == 0 )
  {
    rc = check_diskparallelism_value(
                                     inifilelinebuffer,
                                     double_command,
                                     ind,
                                     cnt
                                     );
    goto exit;
  } else 
  {
    if (trc) 
    {
      trace("  ERR: '%s' of inifilesection '%s' is no valid keyword",
            tmpstring, ifv->section);
    }
    printasnloadmsg("  ERR: '%s' of inifilesection '%s' is no valid keyword",
                    tmpstring, ifv->section);
    rc = ASNLOAD_ERROR;
    goto exit;
  }
  
 exit:

  return (rc);
  
} /* end of function check_keyword */


/******************************************************************************
 *
 *  Function Name  = trace_inifilevalues
 *
 *  Descriptive Name = trace the values of the inifile 
 *
 *  Function = All read values of the relevant section headers will be traced
 *             out.
 *
 *  Input params:
 *    trc (global): traceindicator
 *    ifv (global): pointer to the structure ini_file_values used to build
 *                  a dynamic list to hold the values
 *    point_to_common (global): pointer to the default/common values in
 *                              the dynamic list
 *
 *  Output params:
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void trace_inifilevalues()
{
  int loop;
  ifv = point_to_common;
  
  trace("\n  Inifilevalues/Defaultvalues: ");
  trace("     - If there is no common section specified in the inifile,");
  trace("       the traced common values represent asnload defaults");
  trace("     - Note: Lobfiles and Lobpaths will not be evaluated "
        "if preset loadx_type 3,");
  trace("             because they won't be needed");
  
  for ( ifv = point_to_common;ifv != NULL;ifv = ifv ->ilink)
  {
    trace("\n  Section: [%s]", ifv ->section);
    trace("  Statistics: %s", BOOL2STRINGBETA(ifv ->statistics));

    loop=0;
    while (loop<ifv->number_lobpaths)
    {
      trace("  Lobpath %d: %s",loop,
            (ifv->pLobpathListMediaEntries+loop) ->media_entry );
      loop++;
    }
      
    loop=0;
    while (loop<ifv->number_lobfiles )
    {
      trace("  Lobfile %d: %s",loop,
             (ifv->pLobfileListLocEntries+loop)->location_entry );
      loop++;
    }
      
      
    trace( "  Maxlobs (# of lobfilebasenames): %d", ifv ->maxlobs);
    if ( ifv -> copy == COPY_NOT_SPECIFIED)
    {
      trace("  Copy: Default will be set when calling the load utility");   
    } else if ( ifv -> copy == COPY_OFF)
    {
      trace("  Copy: OFF");
    } else
    {
      trace("  Copy: ON");
    }
    trace( "  Copyto: %s ", ifv ->copyto);
    trace( "  Data_buffer_size: %d", ifv ->data_buffer_size);
    trace( "  Cpu_parallelism: %d ", ifv ->cpu_parallelism);
    trace( "  Disk_parallelism: %d", ifv ->disk_parallelism);
#if SHOW_PWD
    trace( "  Userid: %s", ifv -> uid);
    trace( "  Passwd: %s\n", ifv -> pwd);
#endif
  }//end for
  
  return;
}// end of trace_inifilevalues

/******************************************************************************
 *
 *  Function Name  = set_defaults
 *
 *  Descriptive Name = set default values
 *
 *  Function = The asnload default values will be set when starting the inifile
 *             parsing by filling the first created element of the list with
 *             those values. These values can only be overwritten with a section
 *             specified as 'common' on top of the inifile. So these
 *             'common' values will then represent the defaults for further
 *             sections. 
 *
 *  Input params:
 *
 *  Output params:
 *    ifv (global): pointer to the first element of the dynamic list of
 *                  structures of type ini_file_values
 *    point_to_common (global): pointer to the element of the list of type
 *                              ini_file_values holding the default values,
 *                              in this case the first element and the
 *                              pointers ifv == point_to_common
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void set_defaults()
{
  ini_file_values *newifv = NULL; //pointer for allocating a new listblock

  newifv = (ini_file_values*) malloc(sizeof(ini_file_values)); 
  
/*****************************************************************************/
/*    DEFAULT Values for each keyword will be set here                       */
/*    -- Consider this if you add a keyword                                  */
/*****************************************************************************/
  strcpy( newifv -> section , "COMMON" );
  newifv -> statistics = yes;
  newifv->uid[0]='\0';
  newifv->pwd[0]='\0';
  newifv -> number_lobpaths =0;
  newifv -> pLobpathListMediaEntries = NULL;

  newifv -> number_lobfiles = 0;
  newifv -> pLobfileListLocEntries = NULL;
  
  newifv -> maxlobs = DEFAULT_MAXLOBS;
  newifv -> copy = COPY_NOT_SPECIFIED; //default value - will be proofed, 

  //needed for invoke_load
  if (strlen_applypath > COPYTO_LENGTH)
  {
    if (trc)
    {
      trace("  ERR: Unexpected Error - apply_path is too long for COPYTO");
    }
    rc = ASNLOAD_ERROR;
    goto exit;
  }
  
  strcpy (newifv -> copyto, apply_path);
  newifv -> data_buffer_size = 0; 
  newifv -> cpu_parallelism = 0;
  newifv -> disk_parallelism = 0;
  newifv -> ilink = NULL;

/*****************************************************************************/
/*    DEFAULT Values for each keyword will be set above                      */
/*****************************************************************************/

  ifv = newifv;
  point_to_common = ifv; //set pointer for default or common section values

exit:

  return;

}//end set_defaults

/******************************************************************************
 *
 *  Function Name  = create_new_section
 *
 *  Descriptive Name = create new section
 *
 *  Function = If a new section header was found in the inifile a new element
 *             in the  dynamic list of structures of type ini_file_values will
 *             be created and filled with asndefaults or common values.
 *
 *  Input params: 
 *    sectionstring: string holding the name of the actual section
 *
 *  Output params:
 *    ifv (global): pointer to the new created list element of type
 *                  ini_file_values
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies: called by handle_section_header and depending on the logic
 *                implemented there
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void create_new_section(char* sectionstring)
{
  ini_file_values *newifv = NULL; //pointer for allocating a new listblock
  
/*****************************************************************************/
/*    DEFAULT OR COMMON set Values for each keyword of a new section will be */
/*    set here                                                               */
/*    -- Consider this if you add a keyword                                  */
/*****************************************************************************/
  newifv = (ini_file_values*) malloc(sizeof(ini_file_values));
  strcpy( newifv -> section , sectionstring );
  newifv -> statistics = point_to_common ->statistics;
  strcpy(newifv->uid, point_to_common -> uid);
  strcpy(newifv->pwd, point_to_common -> pwd);
  newifv -> number_lobpaths = point_to_common -> number_lobpaths;
  newifv -> pLobpathListMediaEntries = 
    point_to_common -> pLobpathListMediaEntries;
  newifv -> number_lobfiles = point_to_common -> number_lobfiles;
  newifv -> pLobfileListLocEntries =
    point_to_common -> pLobfileListLocEntries;
  newifv -> maxlobs = point_to_common ->maxlobs;
  newifv -> copy = point_to_common->copy; 
  strcpy (newifv -> copyto, point_to_common->copyto);
  newifv -> data_buffer_size = point_to_common->data_buffer_size;
  newifv -> cpu_parallelism = point_to_common->cpu_parallelism;
  newifv -> disk_parallelism = point_to_common->disk_parallelism;
/*****************************************************************************/
/*    DEFAULT OR COMMON set Values for each keyword of a new section will be */
/*    set above                                                              */
/*****************************************************************************/                            
  newifv -> ilink = NULL;
  ifv -> ilink = newifv;
  ifv=ifv->ilink;

  return;
}//end create_new_section

/******************************************************************************
 *
 *  Function Name  = reset_double_commands
 *
 *  Descriptive Name = reset double commands
 *
 *  Function = For all valid keyword this structure is an indicator for
 *             double specified commands under the actual section header. So
 *             a new section header was found and a new list element has been
 *             created this indicator needs to be reset - done by this
 *             function.
 *
 *  Input params:
 *
 *  Output params:
 *    double_command: structure showing for each keyword if the command was
 *                    already specified
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies: depending of the logic of handle_section_header and is called
 *                by this function  
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void reset_double_commands()
{
/*****************************************************************************/
/*    The counter for double commands will be reset here after a new section */
/*    header was found                                                       */            
/*    -- Consider this if you add a keyword                                  */
/*****************************************************************************/
  double_command.statistics       = FALSE;
  double_command.uid              = FALSE;
  double_command.pwd              = FALSE;
  double_command.lobpath          = FALSE;
  double_command.lobfile          = FALSE;
  double_command.maxlobs          = FALSE;
  double_command.copy             = FALSE;
  double_command.copyto           = FALSE;
  double_command.data_buffer_size = FALSE;
  double_command.cpu_parallelism  = FALSE;
  double_command.disk_parallelism = FALSE;
/*****************************************************************************/
/*    The counter for double commands will be reset above                    */
/*****************************************************************************/
  return;
}//end reset_double_commands

/******************************************************************************
 *
 *  Function Name  = gofirstcharacter
 *
 *  Descriptive Name = set position to the first character
 *
 *  Function = Goes to the first non blank character in the string.
 *
 *  Input params:
 *    string: inputstring
 *
 *  Output params:
 *    pind: pointer to an integer representing the position in string
 *          that is the first non blank character
 *    length: maximum allowed length of 'string' 
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void gofirstcharacter( char* string, int *pind, int length )
{
  for (*pind=0;
       ((isspace(string[*pind]))&&
        (*pind<=length));
       (*pind)++);

  return;
}// end go firstcharacter

/******************************************************************************
 *
 *  Function Name  = golastcharacter
 *
 *  Descriptive Name = go to the last character
 *
 *  Function = goes to the last non blank character in the string and parameter
 *             2 will be set to this position
 *
 *  Input params:
 *    string: inputstring
 *    length: actual length of 'string'
 *
 *  Output params:
 *    pcnt: pointer to an inputstring representing the last non blank character
 *          of 'string' (except the '\n' character!). If line is empty pcnt
 *          points to a negative integer
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = void
 *
 *  Error Return = void
 *
******************************************************************************/
void golastcharacter( char* string, int *pcnt, int length )
{
  for (*pcnt=length-1;
       (*pcnt>=0)&&((isspace(string[*pcnt]))||(string[*pcnt] == '\n'));
       (*pcnt)--);
  
  return;
}

/******************************************************************************
 *
 *  Function Name  = extract_keyword
 *
 *  Descriptive Name = extract the keyword
 *
 *  Function = This function extracts the keyword from the actual inifile
 *             command line.
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inifilelinebuffer (global): actual line of the infile
 *    len_inifilelinebuffer (global): string length of inifilelinebuffer
 *
 *  Output params:
 *    keywordstring: the keyword
 *    pind: -> input a pointer to an integer representing the first non
 *             blank character of inifilelinebuffer
 *          -> output a pointer to an integer representing the first
 *             character after the '=' sign
 *          
 *  Output params for DB2SQL param style:
 *
 *  Dependencies: the position of pind is very important for correct working
 *                of this function
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int extract_keyword( char* keywordstring,
                     int *pind)
{
  rc = 0;

  int ind;
  int cnt;
  int positioneqsign; //position of the '=' sign

  ind=*pind;

  strcpy(keywordstring,"");
  
  //run count until the '=' sign is reached
  for ( cnt=ind;(cnt < len_inifilelinebuffer) &&
          (inifilelinebuffer[cnt]!= '=');cnt++ );
          
  if ( inifilelinebuffer[cnt] != '=' )
  {
    rc=ASNLOAD_ERROR;
    if (trc) 
    {
      trace("  ERR: no valid commandline: %s", inifilelinebuffer);
    }
    printasnloadmsg("  ERR: no valid commandline: %s", inifilelinebuffer);    
    goto exit;
  }
  positioneqsign = cnt;

  // run now to the last non empty character before the '=' sign
  for (cnt=cnt-1;(cnt >= 0) && (isspace(inifilelinebuffer[cnt]));cnt--);
                    
  if ( cnt < 0 )
  {
    rc = ASNLOAD_ERROR;
    if (trc) 
    {
      trace("  ERR: No keyword in line: %s", inifilelinebuffer); //chg31
    }
    goto exit;
  // put the command into keywordstring     
  }else
  {
    for(ind; ind<cnt+1; ind++) 
    {
      strncat(keywordstring,&inifilelinebuffer[ind], 1);
    }
  }

  // set ind for further processing one character after the '=' sign
  ind=positioneqsign+1;

 exit:

  *pind=ind;

  return rc;
  
}//end fct extract_keyword

/******************************************************************************
 *
 *  Function Name  = circle_value
 *
 *  Descriptive Name = circle value 
 *
 *  Function = sets the pointers pind and pcnt to the position of begin and end
 *             of the value, so it deletes blank signs
 *
 *  Input params:
 *    trc (global): traceindicator
 *    inputstring: inifilelinebuffer
 *    keyword: the actual keyword
 *    len_inputstring: string length of the inputstring
 *
 *  Output params:
 *    pind: -> input pointer to an integer representing the position after 
 *             the '='
 *          -> position of the first non blank after the '=' sign
 *    pcnt: pointer to an integer representing the position of the end of
 *          the value
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int circle_value(char* inputstring, char* keyword, int *pind, int *pcnt,
                 int len_inputstring)
{
  rc=0;

  // delete blanks after the '=' sign, where ind actually 
  // points to and set ind to the first character of the 
  // value and delete blanks after the value, set cnt to 
  // last valuecharacter
  for(*pind; isspace(inputstring[*pind]); (*pind)++ );

  for(*pcnt=len_inputstring-1;
      ((isspace(inputstring[*pcnt]))||(inputstring[*pcnt] == '\n'));
      (*pcnt)--);

  // errormssge + trace because no value specified
  if (*pind>*pcnt) 
  {
    if (trc)
    {
      trace("  ERR: Cannot use keyword '%s', because no value specified",
            keyword);
    }
    rc=ASNLOAD_ERROR;
    goto exit;
  }

 exit:

  return rc;
  
}//end fct circle_value

/******************************************************************************
 *
 *  Function Name  = handle_section_header
 *
 *  Descriptive Name = handle section header
 *
 *  Function = If the current line of the inifile is a section header this
 *             function processes the next steps:
 *             - check what kind of section header
 *             - allocate memory for the values of this section if necessary
 *             - setting defaults
 *             - resetting double_command
 *
 *  Input params:
 *    trc (global): traceindicator
 *    double_command: structure that has a string indicating if a section
 *                    header was specified more than once                      
 *    inifilelinebuffer (global): string holds the current line of the inifile
 *    dbAliasSrc: alias name source server
 *    dbAliasTrgt: alias name target server
 *    dbAliasCntl: alias name control server
 *    ind: position of the beginning of section header in inifilelinebuffer
 *    cnt: position of the end of section header in inifilelinebuffer
 *
 *  Output params:
 *    piowait_until_next_section: pointer to a bool value indicating the
 *                                parse_inifile function not to process the
 *                                keywords of the current section
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int handle_section_header(char* dbAliasSrc,
                          char* dbAliasTrgt,
                          char* dbAliasCntl,
                          bool  *piowait_until_next_section,
                          int ind,
                          int cnt)
{
  rc = 0;
  
  //sectionstring will hold the section header e.g. "common"
  char sectionstring[INIFILE_LINEBUFFER_LENGTH+1];
  
  int number; //number of characters to be used for strncpy

  strcpy(sectionstring,"");

  // go to the last non blank char of the inifilelinebuffer
  golastcharacter( inifilelinebuffer, &cnt, len_inifilelinebuffer);

  if ( inifilelinebuffer[cnt] != ']') //error in inifileline
  {
    rc = ASNLOAD_ERROR;
    if (trc) 
    {
      trace("  ERR: Wrong section header: %s", inifilelinebuffer);
    }
    printasnloadmsg("  ERR: Wrong section header: %s", inifilelinebuffer);
    goto exit;
                        
  } else
  {
    //number = section header length without brackets(!)
    number=((cnt-1)-(ind+1)+1);
    if ( number > SECTION_LENGTH )
    {
      trace("  ERR: Section header is too long");
      rc = ASNLOAD_ERROR;
      goto exit;
    } else
    {
      //copy the section header name without brackets into the sectionstring
      strncpy(sectionstring,&inifilelinebuffer[ind+1],number);
      sectionstring[number]='\0';
      convertToUpper(sectionstring);
    }
  }

  /* if the section header has already been specified */
  if ( strstr(double_command.section,sectionstring)!=0 )
  {
    
    if (trc)
    {
      trace("\n  WRN: double section header found: [%s] - the first one was used"
            ,sectionstring);
    }
    *piowait_until_next_section = TRUE;
  /* else if this is not a relevant section header set      */
  /* piowait_until_next_section to true to skip the section */
  } else if ((strcmp(sectionstring,dbAliasSrc)!=0)  && 
             (strcmp(sectionstring,dbAliasTrgt)!=0) &&
             (strcmp(sectionstring,dbAliasCntl)!=0) &&
             (stricmp(sectionstring,"common") !=0))
  {
    *piowait_until_next_section = TRUE;
  /* the section header is needed -> so prepare further processing */
  } else
  {
    /*if the section header is not the common section (so any database alias)*/
    if ( (stricmp(sectionstring,"common")) != 0)
    {
      // allocate for the new section header a memory block into ifv and
      // insert the default or common values of the point_to_common memory
      // block
      create_new_section(sectionstring);
      
    }
    /* else: the section header is the "common" section */
    /*
     * Note: Any user default value specified in "common" will overwrite the
     *        corresponding ASNLOAD default value. Since there was already  a
     *        memory block for the ASNLOAD default values created where
     *        point_to_common points to its not necessary to
     *        invoke create_new_section. Just proof if it was specified on top
     *        of the inifile
     */
    else 
    {
      if (ifv != point_to_common) 
      {
        if (trc)
        {
          trace("  ERR: [COMMON] is only allowed to be the first "
                "section header");
        }
        rc=ASNLOAD_ERROR;
        goto exit;
      }
    }

    //reset the indicator for double commands in the ini file
    reset_double_commands();
    *piowait_until_next_section = FALSE;

    if (trc)
    {
      trace("\n -- Reading values for section [%s] --", sectionstring);
    }
    printasnloadmsg("  INF: Reading values for section [%s]", sectionstring);

    //insert [sectionstring] into double_command .section, to 
    //be sure it is unique
    if (
        (double_command.section = (char*) realloc(double_command.section, 
                           (strlen(double_command.section) +
                            strlen(sectionstring)+3))) == NULL
       )
    {
      if (trc)
      {
        trace("  ERR: an internal error occured ");
        trace("       ...memory allocation error for double_commands");
      }
      rc = ASNLOAD_ERROR;
      goto exit;          
    } else
    {
      strcat(double_command .section,"[");
      strcat(double_command .section,sectionstring);
      strcat(double_command .section,"]");
    }
    
  }// end of the else branch: section header is needed
  
 exit:

  return rc;

}//end fct handle_section_header


/******************************************************************************
 *
 *  Function Name  = parse_inifile
 *
 *  Descriptive Name = parse the inifile
 *
 *  Function = This is the initial point for the inifileparsing and it
 *             will handle most of the work for getting the lines from the
 *             file and prepares the further processing of those lines.
 *
 *  Input params:
 *    dbAliasTrg: database alias name for the target database, because only
 *                these values will be needed from the inifile
 *    dbAliasCntl: database alias name for the control server, because only
 *                 these values will be needed from the inifile
 *    dbAliasSrc: database alias name for the source database, because only
 *                these values will be needed from the inifile
 *    trc (global): traceindicator
 *
 *  Output params:
 *    fnd_ini_file: indicates if the inifile was found
 *
 *  Output params for DB2SQL param style:
 *
 *  Dependencies:
 *
 *  Normal Return = 0
 *
 *  Error Return = ASNLOAD_ERROR
 *
******************************************************************************/
int parse_inifile(
                  char* dbAliasSrc,
                  char* dbAliasCntl,
                  char* dbAliasTrgt
                  )
{
  rc = 0;

  int ind;    //indicates a left position in a string 
  int cnt;    //indicates a right position in a string
  char  tmpstring[INIFILE_LINEBUFFER_LENGTH+1];
  bool wait_until_next_section = FALSE;
  char* inifilename;
  
  printasnloadmsg("\n Parsing the inifile");
  if(trc) 
  { 
    trace(" *** ");
    trace (" Parsing the ini file (parse_inifile)");
  }

  //1st step fill the [common] section in the ifv structure with default values
  set_defaults();

  /* try to open the inifile */
  inifilename = (char*) malloc(strlen_applypath+strlen(INI_FILE_NAME)+1);
  strcpy(inifilename, apply_path);
  strcat(inifilename, INI_FILE_NAME);
  finifile=fopen(inifilename,"rt");

  if ( finifile == NULL)
  {
    if (trc) 
    {
      trace ("  INF: fopen for the inifile failed, using default values." );
      trace ("   --  inifilename: %s",inifilename);
    }
    printasnloadmsg("  INF: No inifile found, using default values");
    fnd_ini_file=FALSE;
    goto exit;
  } else
  {
    fnd_ini_file=TRUE;
  }
  free(inifilename);

  /* init the double_command.section as an empty string */
  double_command.section = (char*) malloc(1);
  double_command.section[0] = '\0';

  /*** parse ini file lines in a while loop ***/
  while ( (fgets(inifilelinebuffer,INIFILE_LINEBUFFER_LENGTH+1,finifile))!= NULL )
  {
    len_inifilelinebuffer = strlen(inifilelinebuffer);
    
    // go to first non blank character in the string 
    gofirstcharacter(inifilelinebuffer, &ind, INIFILE_LINEBUFFER_LENGTH);
    
    // if blank line do nothing
    if ((inifilelinebuffer[ind] != '\0') && (inifilelinebuffer[ind] != '\n'))
    {
      // if one line is too long -> terminate 
      if ( (len_inifilelinebuffer==INIFILE_LINEBUFFER_LENGTH) && 
           !(strstr(inifilelinebuffer, "\n")) ) 
      { 
        if (trc) 
        {
          trace("  ERR: inifile command line is too long "
                "allowed are: %d characters.", INIFILE_LINEBUFFER_LENGTH);
        }
        rc = ASNLOAD_ERROR;
        goto exit;
      }
            
      // if ";" then comment line do nothing but if no comment line ->see below
      if ( (inifilelinebuffer[ind] != ';') && (inifilelinebuffer[ind] != '\n') )
      {

        check_if_commentline=FALSE;

        //initalize cnt variable
        cnt=0;
                
        /* handle section header '[]' */
        if ( inifilelinebuffer[ind] == '['  )
        {
          rc = handle_section_header(dbAliasSrc,
                                     dbAliasTrgt,
                                     dbAliasCntl,
                                     &wait_until_next_section,
                                     ind,
                                     cnt);
          if (rc != 0)
          {
            goto exit;
          }
        } else if ( wait_until_next_section == FALSE )
          /*
           * The line in the buffer should now be a keyword. For this there
           * will be the function check_keyword. If an error occurs
           * asnload will terminate
           */
        {         
          //extract the keyword from the inifilelinebuffer
          rc = extract_keyword(tmpstring,(int*) &ind);
          if (rc!=0)
          {
            goto exit;
          }
          
          //ind and cnt will be set to the positions of the beginning and the end of the value
          rc = circle_value(inifilelinebuffer,tmpstring, (int*) &ind, (int*) &cnt,len_inifilelinebuffer);
          if (rc!=0)
          {
            goto exit;
          }

          //invoke the keyword handling function
          rc = check_keyword(
                             tmpstring,//should hold the keyword
                             inifilelinebuffer,
                             &double_command,
                             ind,
                             cnt 
                            );
          if (rc !=0) 
          {
            goto exit;
          }
        } /* else if ( wait_until...) */
      }else
      {
        check_if_commentline = TRUE;
      } // end if handling commentline
            
    } //end if blank line go to next line
  } //end while (fgets...)
    
    
  if (!feof(finifile))
  {
    if (trc) 
    {
      trace ("  ERR: Cannot read in the ini file; file access error");
    }
    rc = ASNLOAD_ERROR;
    goto exit;
  } else if ( !(check_if_commentline) )
  {
    if (trc) 
    {
      trace ("  ERR: Last line of the ini file is not a commentline ");
    }
    printasnloadmsg("  ERR: Last line of the ini file is not a commentline ");
    rc = ASNLOAD_ERROR;
    goto exit;
  }
 
 exit:

  /* messsaging and tracing */
  if ( (trc) && (rc==0) )
  {
    trace_inifilevalues();
  }
  if (trc)
  {
    trace(" Exiting parse_inifile with return code %d",rc);
    trace(" *** ");
  }
  if (rc!=0)
  {
    printasnloadmsg(" An error occured when parsing the inifile, rc is %d", rc);
  }
  printasnloadmsg(" Exiting Parsing the inifile\n");

  /* close the inifile */
  if (finifile)
  {
    fclose(finifile);
  }
 
  return(rc);
    
}//end of parse_inifile
