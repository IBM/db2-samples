/******************************************************************************
 ** 
 ** Source File Name: asnload.h
 ** 
 ** (C) COPYRIGHT International Business Machines Corp. 2002
 ** All Rights Reserved
 ** Licensed Materials - Property of IBM
 ** 
 ** US Government Users Restricted Rights - Use, duplication or
 ** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 ** 
 ** Function = Include File defining:
 **              System Constants
 **              Variables commonly used in ASNLOAD
 **              Functions commonly used in ASNLOAD
 ** 
 ** Operating System:  Common Code for UNIX, LINUX, WINDOWS
 **
 ******************************************************************************
 *     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                         *
 *     PLEASE READ THE FOLLOWING BEFORE PROCEEDING...                         *
 *     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                         *
 ******************************************************************************
 **                                                                   
 **     This file belongs to the ASNLOAD package for DB2 DataPropagator.          
 **                                                                  
 ** IMPORTANT!! -> this part as is is not ready for compilaton        
 **             -> Please read the explanations of the ASNLOAD.SMP    
 **                for details of the whole ASNLOAD package and how   
 **                to use and modify it                               
 **                                                                   
 ******************************************************************************
 **                                                                   
 **           NOTICE TO USERS OF THE SOURCE CODE EXAMPLE              
 **                                                                   
 ** INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE   
 ** CODE EXAMPLE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         
 ** EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO THE IMPLIED   
 ** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR        
 ** PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE 
 ** SOURCE CODE EXAMPLE IS WITH YOU. SHOULD ANY PART OF THE SOURCE    
 ** CODE EXAMPLE PROVES DEFECTIVE, YOU (AND NOT IBM) ASSUME THE       
 ** ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.    
 **                                                                   
*******************************************************************************/
#ifndef _asnload_
  #define _asnload_

#include <sqlutil.h> //contains #defines like SQLU_MEDIA_LOCATION_LEN

#define onNT  0
#define onUNIX 1

//when using bldapp on aix the data type bool does not exist and
//so define it with int
//if you get an error like bool has already been defined just disable
//the following clause
#ifdef onUNIX
 #define bool int
#endif

#define SHOW_PWD 0

/*************** Return Codes (Passed back to APPLY)**************************/
#define ASNLOAD_PWDPARMPASSED_PWDFILE_NOT_FOUND                     99
#define ASNLOAD_CONNFAILED_PWDENTRYFOUND_wUSINGPHRASE               100
#define ASNLOAD_CONNFAILED_NOPWDPARMPASSED_NOPWDFILE_woUSINGPHRASE  101
#define ASNLOAD_CONNFAILED_PWDFILEFOUND_NOPWDENRTY_woUSINGPHRASE    102
#define ASNLOAD_CONNFAILED_ASNLOADINI_PWDENTRYFOUND_wUSINGPHRASE    103
#define ASNLOAD_CONNFAILED_NOASNLOADINI_woUSINGPHRASE               104
#define ASNLOAD_CONNFAILED_ASNLOADINI__woUSINGPHRASE                105
#define ASNLOAD_LOADXTYPE_2_NOUSERCODE_PROVIDED                     106
#define ASNLOAD_IMPORT_FAILED                                       107
#define ASNLOAD_EXPORT_FAILED                                       108
#define ASNLOAD_LOAD_FAILED                                         109
#define ASNLOAD_XLOAD_FAILED                                        110
#define ASNLOAD_INVALID_LOADXTYPE                                   111
#define ASNLOAD_LOADXTYPE_REQUIRES_NICKNAME                         112
#define ASNLOAD_TARGETTAB_INCOMPATIBLE_LOADXTYPE_4                  113
#define ASNLOAD_TARGETTAB_INCOMPATIBLE_LOADXTYPE_5                  114
#define ASNLOAD_ASNLOADLCOPY_FAILED                                 115
#define ASNLOAD_ERROR                                               98
#define ASNLOAD_ALTERNATE_FULL_REFRESH                              1

/****************************** general clauses *******************************/
#define yes                     1
#define no                      0
#define INSTALLPATH_LENGTH      1000
#define BUF_SIZE                1024
#define FILETYP1                "IXF"
#define LISTNUMBER              2
#define COPY_NOT_SPECIFIED      0
#define COPY_OFF                1
#define COPY_ON                 2
#define MAX_LENGTH_DBALIAS      8
#define TABLE_NAME_LENGTH       128
#define SCHEMA_LENGTH           128
#define APPQUAL_LENGTH          18
#define SETNAME_LENGTH          18
#define ASN_SQL_STMNT_LENGTH    32767
#define ASN_REPL_STMNT_LENGHT   9000
#define TIMESTRING_LENGTH       20

/*********************** defines for the applycheck routines ******************/
#define ASN_SRC_SRVR            1
#define ASN_TRGT_SRVR           2
#define ASN_CTRL_SRVR           3
#define NICKS_ARE_SET           4
#define NICKS_NOT_SET           5
#define NICKS_INCOMPLETED_SET   6
#define OLD_ARCHLVL             7
#define NICKS_NOTFOUND_NOTABLE  8

/*********************** defines for the alterstatement routines **************/
#define CHUNK_SIZE   30 //used for memory allocation algorithm
#define RC_NOTFOUND   1 //internal return code
#define RC_TOKREC   101 //internal return code

/************ defines for routine trace and printasnloadmsg********************/
#define MAXLINE                81
#define LINELENGTH             130
#define TRC_MSG_LENGTH         65534

/************ define clauses for getpwd from the encrypted pwd file*************/
#define DEFAULT_PWD_NAME       "asnpwd.aut" //default name passed by apply
#define MAX_LENGTH_USERID      128
#define MAX_LENGTH_PWD         128

/************ Datalink specific - adopted from the old routine*****************/
#define MAXBUFSIZE     8192
#define MAXDLSIZE      SQL_DATALINK_LENGTH

/************ define clauses for ini-file parsing used in parse_inifile() ******/
#define INIFILE_LINEBUFFER_LENGTH       1000
#define COPYTO_LENGTH                   1000
#define SECTION_LENGTH                  300
#define MEMORY_ALLOCATION_SIZE          50
#define DEFAULT_MAXLOBS                 200000
#define COMMAND_LIST "[statistics][lobpath][lobfile][maxlobs][copy]\
                      [copyto][data_buffer_size][cpu_parallelism]\
                      [disk_parallelism]"

#define INI_FILE_NAME                  "asnload.ini"

/*****************************************************************************/

/******************************************************************************/
// on UNIX stricmp is called strcasecmp, so define this as follows
#if onUNIX
  #define stricmp strcasecmp
  #define strnicmp strncasecmp //@TWA alterstatement
#endif

/************ defines and inlines, used for tracing and messaging *************/

//converts a bool value into "TRUE" or "FALSE" strings
#define BOOL2STRINGALPHA(cond) ((cond)? "TRUE":"FALSE")

//converts a bool value into "ON" or "OFF"
#define BOOL2STRINGBETA(cond)  ((cond)? "ON":"OFF")

//converts a numeric value into strings
inline const char *asnConst2String(short server)
{
  const char *result;
  
  switch(server)
  {
    case ASN_SRC_SRVR:
      result = "Sourceserver";
      break;
    case ASN_TRGT_SRVR:
      result = "Targetserver";
      break;
    default:
      result = "No mapping!";
  }

  return(result);
}

/***************** Typedefinitions for the inifile values *********************/

typedef struct inifile_value
{
  struct inifile_value *ilink;
  char  section[SECTION_LENGTH+1];
  bool  statistics;
  char uid[MAX_LENGTH_USERID+1];
  char pwd[MAX_LENGTH_PWD+1];
  int number_lobpaths;
  sqlu_media_entry* pLobpathListMediaEntries;
  int number_lobfiles;
  sqlu_location_entry* pLobfileListLocEntries;
  int   maxlobs;
  short  copy;
  char  copyto[COPYTO_LENGTH+1];
  int data_buffer_size;
  int cpu_parallelism;
  int disk_parallelism;
} ini_file_values;


/*****************************************************************************/

/******************************************************************************/
/* declare common variables used in all functions of the ASNLOAD package      */
/******************************************************************************/
extern SQL_API_RC  rc;
extern short trc;
extern char  loadx_type[7];
extern char* apply_path;
extern short strlen_applypath;

extern ini_file_values *ifv; //stores the values
extern ini_file_values *point_to_common; //points to default or common values
extern bool            fnd_ini_file;

/******************************************************************************/
/* declare common functions                                                   */
/******************************************************************************/

void trace(char *format, ...);
void printasnloadmsg(char *format, ... );

// starting point for the inifileparsing and invoked in the main function of asnload
extern int parse_inifile(char* dbAliasSrc,
                         char* dbAliasCntl,
                         char* dbAliasTrgt);


#endif
