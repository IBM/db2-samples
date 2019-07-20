/****************************************************************************
** (c) Copyright IBM Corp. 2007 All rights reserved.
** 
** The following sample of source code ("Sample") is owned by International 
** Business Machines Corporation or one of its subsidiaries ("IBM") and is 
** copyrighted and licensed, not sold. You may use, copy, modify, and 
** distribute the Sample in any form without payment to IBM, for the purpose of 
** assisting you in the development of your applications.
** 
** The Sample code is provided to you on an "AS IS" basis, without warranty of 
** any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
** IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
** not allow for the exclusion or limitation of implied warranties, so the above 
** limitations or exclusions may not apply to you. IBM shall not be liable for 
** any damages you suffer as a result of using, copying, modifying or 
** distributing the Sample, even if IBM has been advised of the possibility of 
** such damages.
*****************************************************************************
**
** SOURCE FILE NAME: dbxamon.c
**
** SAMPLE: Show and roll back indoubt transactions.
**
** USAGE: Following is the usage of dbxamon command.
**
**     1. Command syntax
**
**        dbxamon [-d <database_alias> [-u <userid> -p <password>]
**                |-f <initialize_file> [-c]]
**                [-o <log_file>] [-t <timeout>] [-i <interval>]
**                [-l <trace_level>] [-v] [-[h|?]]
**
**        where : database_alias  = Database alias name
**                userid          = User ID
**                password        = Password
**                initialize_file = Initialization file name
**                log_file        = Log file name
**                timeout         = Timeout value (1 - 32767)
**                interval        = Interval value (1 - 32767)
**                trace_level     = Trace level (1 - 5)
**
**     2. Command parameters
**
**        -h or -?          : Displays the usage information of the command.
**        -d database_alias : Specifies an alias name of the database.
**        -u userid         : User ID used to connect to the database.
**                            If this option is omitted, the current user is
**                            assumed.
**        -p password       : Password for the specified user ID.
**        -f initialize_file : Specifies the name of initialization file.
**                            Some command options can be given from this
**                            initialization file.
**        -c                : If this option is specified, dbxamon command
**                            tries to check the contents of initialization
**                            file once in each monitoring iteration. If the
**                            contents of initialization file have been
**                            changed, dbxamon will get and apply them as
**                            new values. If this option is not set, the
**                            initialization file will be read once at the
**                            timing of program start.
**        -o log_file       : Specifies the name of file used to record the
**                            status, error, and various messages from the
**                            program. The message level to be logged, can be
**                            changed by '-l' option. When no '-o' option is
**                            specified, the default log file named
**                            'database_alias + .log' will be created.
**        -t timeout (seconds) : Specifies timeout value for the transaction.
**                            If the transaction idle time became longer than
**                            this value, dbxamon will rollback the
**                            transaction. The default value is '600'. The
**                            minimum value is 1 and the maximum value is 32767.
**        -i interval (seconds) : Specifies the frequency of transaction
**                            status check. The default value is '900'. The
**                            maximum value is 32767.
**        -l trace_level    : Specifies the level of trace to be recorded
**                            into the log file. Valid values are;
**                              1---System and error messages.
**                              2---System, error and rollback messages.
**                              3---System, error, rollback, and transaction
**                                  information.
**                              4---Records all messages.
**                              5---Records all messages and API return codes
**                                  (for debugging purpose).
**                            The default value is '2'.
**        -v                : Displays the command prompt for the parameter
**                            change or quit.
**
**     3. Initialization file
**
**        Initialization file can include all command options (except '-c',
**        '-f', and '-h|?' options) and their values. When '-f' option is
**        specified, each parameters and values in the specified
**        initialization file will be applied to the dbxamon command.
**        Initialization file is an ASCII file and available parameters are
**        described below.
**
**       3.1 Syntax
**
**           <parameter> = <value>
**
**       3.2 Parameters
**
**           Following is the list of available parameters and equivalent
**           command options.
**
**           +----------+----------+-------------------------------+
**           |Parameter |Equivalent|Description                    |
**           |          |  option  |                               |
**           +----------+----------+-------------------------------+
**           |DBALIAS   |    -d    |  Database alias name.         |
**           |USERID    |    -u    |  User id.                     |
**           |PASSWORD  |    -p    |  Password.                    |
**           |LOGFILE   |    -o    |  Log file name.               |
**           |TIMEOUT   |    -t    |  Timeout value (1 - 32767).   |
**           |INTERVAL  |    -i    |  Interval  (1 - 32767).       |
**           |TRACELVL  |    -l    |  Trace level  (1 - 5).        |
**           |PROMPT    |    -v    |  Display prompt ('YES'or'NO').|
**           |EXIT      |   none   |  Exit program ('YES'or'NO').  |
**           +----------+----------+-------------------------------+
**
**       3.3 Comment
**
**           The string that follows the character '#' is recognized as a
**           comment.
**
**       3.4 Example
**
**           Below is the example of the contents of initialization file.
**
**             DBALIAS = mysampl
**             USERID = db2inst1
**             PASSWORD = db2inst1
**             TIMEOUT = 300
**
**       3.5 'EXIT' parameter
**
**           'EXIT' parameter is unique in the initialization file and there
**            is no corresponding one in the command option. If the value of
**            this parameter is set to 'YES', program will terminate
**            immediately. See the message in the log file to confirm if the
**            termination completed successfully. If the value is not 'YES' or
**            if no 'EXIT' parameter is specified, the termination will not
**            occur. This parameter is useful to terminate the program which
**            is executed without '-v' option.
**
**       3.6 Usage notes
**
**           - When dbxamon is started with '-f' option and without any
**             'DBALIAS' parameter in the initialization file, if '-v' was
**             specified in the command option, the prompt appears and you
**             will be asked to type the database alias name. If '-v' was not
**             specified, the program will terminate with 'no database alias
**             name' error in the log file.
**           - If wrong value is specified in the initialization file, the
**             default value will be applied and the program will continue.
**
**     4. Silent and interactive mode
**
**        - When user did not specify '-v' option, program goes into the
**          infinite loop and no message will be displayed on the console.
**          This mode is called as 'Silent mode'. To quit from the silent
**          mode, enter ctrl-C or kill the program (e.g. issue kill command
**          for UNIX, use 'task manager' for Windows) with SIGINT signal. The
**          other way of the program termination in the silent mode is to start
**          the command with '-f' and '-c' option, and put 'EXIT=YES" statement
**          into the initialization file when you want to stop it. Silent mode
**          is useful to execute dbxamon as a background daemon.
**        - If '-v' is specified, program will display the command prompt
**          (see below) and you can change the parameters any time by typing
**          'c' on the prompt. This mode is called as 'Interactive mode'.
**          To quit, simply type 'q' on the command prompt.
**
**               Do you want to quit or change parameters ? (Quit/Change) :
**
**     5. Version check
**
**        - For the correct timeout detection, dbxamon requires the database
**          of UDB version 8.2 (or higher). If the version of the target
**          database is lower than 8.2, dbxamon will record the error message
**          and terminates immediately.
**
**     6. Usage note
**
**        - If the same option is specified in the command line and
**          initialization file, the value in the initialization file will be
**          applied.
**        - dbxamon continues to write log information into the file
**          specified in the '-o' option without any care of the left of disk
**          space. If you set higher trace level, please confirm if there is
**          enough free disk space on your environment.
**        - In a log file, password characters will be recorded as single
**          asterisk ('*').
**        - If dbxamon failed to open a log file for some reason, the message
**          will be logged into the default system log file named 'dbxamon.log'.
**        - Once the program has been started, user can not change the
**          parameters for 'DB alias name', 'UserID', 'Password', 'Display
**          prompt', and 'Ini file name'. If the dbxamon is started with '-c'
**          option and these parameters have been changed in the initialization
**          file, those changes will be ignored.
**
** DB2 APIs USED:
**         sqlaintp -- Get error message
**         sqllogstt -- Get SQLSTATE message
**
** CLI FUNCTIONS USED:
**
**         SQLAllocHandle -- Allocate Handle
**         SQLConnect -- Connect to a Data Source
**         SQLDisconnect -- Disconnect from a Data Source
**         SQLFreeHandle -- Free Handle Resources
**         SQLGetConnectAttr -- Get Current Attribute Setting
**
** HEURISTIC FUNCTIONS USED:
**
**         db2XaListIndTrans -- List indoubt transactions.
**         sqlxphrl -- Roll back an indoubt transaction.
**         sqlxhfrg -- Forget transaction status.
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference".
**
** For information on using Heuristic APIs, see the Administrative API
** Reference.
**
** For the latest information on programming, compiling, and running DB2
** applications, refer to the DB2 application development website at
**     http://www.software.ibm.com/data/db2/udb/ad
******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <signal.h>
#include <sqlcli.h>
#include <sqlcli1.h>
#include <sqlca.h>
#include <sqlxa.h>
#include <sqlcodes.h>
#include <db2ApiDf.h>
#ifdef DB2NT
#include <conio.h>
#else
#include <termio.h>
#ifdef DB2SUN
#include <stropts.h>
#endif
#endif

/* ----------------------------------------------------------------- */
/* Return codes                                                      */
/* ----------------------------------------------------------------- */
#define RC_OK                 0   /* Ok                              */
#define RC_ERROR             -1   /* General error                   */
#define RC_INI_ERROR          1   /* INI file format error           */
#define RC_NO_DBALIAS         2   /* No database alias specified     */
#define RC_NO_USERID          3   /* No userid specified             */
#define RC_NO_PASSWORD        4   /* No password specified           */
#define RC_NO_LOGFILE         5   /* No log file name specified      */
#define RC_NO_INIFILE         6   /* No ini file name specified      */
#define RC_NO_TIMEOUT         7   /* No timeout value specified      */
#define RC_NO_INTERVAL        8   /* No interval value specified     */
#define RC_NO_TRACELVL        9   /* No tracelevel specified         */
#define RC_LOG_FILE_OPEN_ERR 10   /* Log file open error             */
#define RC_INI_FILE_OPEN_ERR 11   /* Ini file open error             */
#define RC_MAX_VALUE_ERR     12   /* Value exceeded over the max     */
#define RC_WRONG_PARAM       13   /* Wrong option parameter specified*/
#define RC_WRONG_PARAM_VALUE 14   /* Wrong parameter value specified */
#define RC_WRONG_INI_FORMAT  15   /* Wrong INI file format           */
#define RC_CONNECT           16   /* Connect error                   */
#define RC_DISCONNECT        17   /* Disconnect error                */
#define RC_GETCONATTR        18   /* Get connection attribute error  */
#define RC_ALLOC_ENV         19   /* Environment handle allocation error */
#define RC_FREE_ENV          20   /* Environment handle free error   */
#define RC_ALLOC_HANDLE      21   /* Connection handle allocation error */
#define RC_FREE_HANDLE       22   /* Connection handle free error    */
#define RC_XA_ROLLBACK       23   /* XA rollback error               */
#define RC_XA_FORGET         24   /* XA forget status error          */
#define RC_XA_GET_DATA       25   /* XA get indoubt transaction data error */
#define RC_XA_GET_NUMBER     26   /* XA get indoubt transaction num. error */
#define RC_SYNTAX_ERROR      27   /* Command syntax error            */
#define RC_INVALID_VERSION   28   /* Invalid database version        */
#define RC_SHOW_HELP         29   /* Help option is specified        */

/* ------------------------------------------------------------------ */
/* Constants                                                          */
/* ------------------------------------------------------------------ */
#define DEFAULT_TIMEOUT     600   /* default timeout value            */
#define DEFAULT_INTERVAL    900   /* default interval value           */
#define DEFAULT_TRACELEVEL    2   /* default trace level              */
#define DEFAULT_LOGFILE_EXT ".log"/* default log file name ext.       */
#define DEFAULT_SLEEP_TIME  100   /* default sleep time (100ms)       */

#define MAX_LINE_LENGTH     256   /* Max. line length for the fgets   */
#define MAX_MSG_LENGTH     1024   /* Max. message length              */
#define MAX_INT_VALUE     32767   /* Max. integer parameter value     */


#define VALID_VERSION         8   /* Valid version                    */
#define VALID_RELEASE         2   /* Valid release for valid version  */

#define SYSTEM_LOGFILE "dbxamon.log" /* system log file name          */

/* ------------------------------------------------------------------ */
/* Initialization file parameter keyword list                         */
/* ------------------------------------------------------------------ */
#define PARMKEY_DBALIAS     "DBALIAS"  /* database alias parameter    */
#define PARMKEY_USERID      "USERID"   /* user id parameter           */
#define PARMKEY_PASSWORD    "PASSWORD" /* password parameter          */
#define PARMKEY_LOGFILE     "LOGFILE"  /* log file parameter          */
#define PARMKEY_TIMEOUT     "TIMEOUT"  /* timeout parameter           */
#define PARMKEY_INTERVAL    "INTERVAL" /* interval parameter          */
#define PARMKEY_TRACELVL    "TRACELVL" /* trace level parameter       */
#define PARMKEY_PROMPT      "PROMPT"   /* interactive mode parameter  */
#define PARMKEY_EXIT        "EXIT"     /* exit parameter              */

/* ------------------------------------------------------------------ */
/* Messages                                                           */
/* ------------------------------------------------------------------ */
#define MSG_PARM_HEAD  "Current parameters are :\n"
#define MSG_CMD_PROMPT "Do you want to quit or change parameters ? (Quit/Change) : "
#define MSG_END_PROMPT "Are you sure you want to quit the program ? (Yes/No) : "
#define MSG_DBALIAS  "  DB alias name  =  %s" /* database alias       */
#define MSG_USERID   "  User ID        =  %s" /* user id              */
#define MSG_PASSWORD "  Password       =  %s" /* password             */
#define MSG_LOGFILE  "  Log file name  =  %s" /* log file             */
#define MSG_INIFILE  "  Ini file name  =  %s" /* ini file             */
#define MSG_TIMEOUT  "  Timeout        =  %d" /* timeout              */
#define MSG_INTERVAL "  Interval       =  %d" /* interval             */
#define MSG_TRACELVL "  Trace level    =  %d" /* trace level          */
#define MSG_PROMPT   "  Display prompt =  %s" /* interactive mode     */
#define MSG_CHKINI   "  Check ini file =  %s" /* check ini mode       */
#define MSG_DBNAME_INPUT "Enter database alias name :"
#define MSG_PROMPT_DBNAME   "DB alias name"/* DB name prompt     */
#define MSG_PROMPT_USERID   "User id"    /* UserID  prompt            */
#define MSG_PROMPT_PASSWORD "Password"   /* Password prompt           */
#define MSG_PROMPT_TIMEOUT  "Timeout"    /* Timeout prompt            */
#define MSG_PROMPT_INTERVAL "Interval"   /* Interval prompt           */
#define MSG_PROMPT_TRACELVL "Tracelevel" /* Trace level prompt        */
#define MSG_PROMPT_LOGFILE  "Log file name" /* Log file name prompt   */
#define MSG_PARM_INPUT "You can change the timeout/interval/tracelevel parameters.\nEnter new value or just type enter to keep the current value.\n"
#define MSG_TYPE_ERR   "E"             /* Message type (Error)        */
#define MSG_TYPE_WAR   "W"             /* Message type (Warning)      */
#define MSG_TYPE_INF   "I"             /* Message type (Information)  */
#define MSG_TYPE_DEB   "D"             /* Message type (Debug)        */
#define MSG_NONE       "(none)"        /* No value                    */

/* Error messages   */
#define MSG_ERR_UNKNOWN           "Unknown error. Set trace level to 5 and get more information."
#define MSG_ERR_ERROR             "Generic error. Set trace level to 5 and get more information."
#define MSG_ERR_INI_ERROR         "Initialization file format error."
#define MSG_ERR_NO_DBALIAS        "No database alias name is specified."
#define MSG_ERR_NO_USERID         "No user id is specified."
#define MSG_ERR_NO_PASSWORD       "No password is specified."
#define MSG_ERR_NO_LOGFILE        "No log file name is specified."
#define MSG_ERR_NO_INIFILE        "No ini file name is specified."
#define MSG_ERR_NO_TIMEOUT        "No timeout value is specified."
#define MSG_ERR_NO_INTERVAL       "No interval value is specified."
#define MSG_ERR_NO_TRACELVL       "No trace level is specified."
#define MSG_ERR_LOG_FILE_OPEN_ERR "Log file open error."
#define MSG_ERR_INI_FILE_OPEN_ERR "Initialization file open error."
#define MSG_ERR_MAX_VALUE_ERR     "The value exceeded max."
#define MSG_ERR_WRONG_PARAM       "Wrong parameter specified."
#define MSG_ERR_WRONG_PARAM_VALUE "Wrong parameter value specified."
#define MSG_ERR_WRONG_INI_FORMAT  "Wrong initialization file format."
#define MSG_ERR_CONNECT           "Failed to connect to the database."
#define MSG_ERR_DISCONNECT        "Failed to disconnect from the database."
#define MSG_ERR_GETCONATTR        "Failed to get connection attributes."
#define MSG_ERR_ALLOC_ENV         "Failed to allocate environment handle."
#define MSG_ERR_FREE_ENV          "Failed to free environment handle."
#define MSG_ERR_ALLOC_HANDLE      "Failed to allocate connection handle."
#define MSG_ERR_FREE_HANDLE       "Failed to free connection handle."
#define MSG_ERR_XA_ROLLBACK       "Failed to rollback transaction."
#define MSG_ERR_XA_FORGET         "Failed to forget transaction status."
#define MSG_ERR_XA_GET_DATA       "Failed to get indoubt data."
#define MSG_ERR_XA_GET_NUMBER     "Failed to get number of indoubt transaction."
#define MSG_ERR_SYNTAX_ERROR      "Syntax error."
#define MSG_ERR_INVALID_VERSION   "Invalid database version. For the correct execution, database on DB2 version 8.2 or upper is required."
/* Level 1 messages */
#define MSG_INF_STARTED           "%s started successfully."
#define MSG_INF_STOPPED           "%s stopped successfully."
#define MSG_INF_CONNECTED         "Connected to the database [%s] successfully."
#define MSG_INF_DISCONNECTED      "Disconnected from the database [%s] successfully."
#define MSG_INF_INIFILEOPEN       "Initialization file [%s] opened successfully."
#define MSG_INF_LOGFILEOPEN       "Log file [%s] opened successfully."
#define MSG_INF_INI_EXIT          "EXIT is specified in the initialization file."
#define MSG_WAR_INI_CHANGE_DBNAME "The update of database alias name is ignored."
#define MSG_WAR_INI_CHANGE_USERID "The update of user id is ignored."
#define MSG_WAR_INI_CHANGE_PASSWD "The update of password is ignored."
#define MSG_WAR_INI_CHANGE_PROMPT "The update of prompt parameter is ignored."
#define MSG_WAR_ID_AND_PW         "User id and password need to be specified together."
#define MSG_WAR_C_REQ_F           "'-c' option need to be specified with '-f' option."
/* Level 2 messages */
#define MSG_INF_ROLLBACK_OK       "Rollback completed successfully."
#define MSG_INF_ROLLBACK_NG       "Rollback failed."
#define MSG_INF_FORGET_OK         "Forget transaction status completed successfully."
#define MSG_INF_FORGET_NG         "Forget transaction status failed."
#define MSG_INF_TIMEOUT_OCCURRED  "Transaction timeout is detected [%d]s has been passed."
/* Level 3 messages */
#define MSG_INF_INDTOTAL          "Found %d indoubt transaction(s)."
#define MSG_INF_IND_HEADER        "=== Transaction information ==============="
#define MSG_INF_IND_TIME          "  Timestamp            = %d"
#define MSG_INF_IND_DBALIAS       "  Database alias       = %s"
#define MSG_INF_IND_APPLID        "  Application ID       = %s"
#define MSG_INF_IND_SEQNO         "  Sequence number      = %s"
#define MSG_INF_IND_AUTHID        "  Authorization ID     = %s"
#define MSG_INF_IND_LOGFULL       "  Log full             = %s"
#define MSG_INF_IND_STATUS        "  Indoubt status       = %c"
#define MSG_INF_IND_ORIGIN        "  Originator           = %d"
#define MSG_INF_IND_XID_FID       "  XID Format ID        = %d"
#define MSG_INF_IND_XID_GID       "  XID Global thread ID = %s"
#define MSG_INF_IND_SECONDS       "[%d] seconds have been passed from xa_end."
#define MSG_INF_IND_DATA_NG       "Failed to get indoubt data."
#define MSG_INF_IND_NUMBER_NG     "Failed to get a total number of indoubt transaction."
/* Level 4 messages */
#define MSG_INF_ITR_STARTED       "Transaction check iteration started."
#define MSG_INF_INIVALUE          "INI contents. Param [%s], Value [%s]."
#define MSG_WAR_ITR_BREAK         "Iteration break is specified."
#define MSG_INF_INI_CHECK         "Checking initialization file."
#define MSG_INF_COMMAND           "User typed [%c] on the prompt."
#define MSG_INF_WRONG_OPTION      "Wrong option [%s] is specified."
#define MSG_INF_INI_DBCHANGED     "Database parameter have been changed in the INI file."
#define MSG_INF_INI_LOGCHANGED    "Log file name has been changed in the INI file."
#define MSG_INF_INT_DBCHANGED     "Database parameter have been changed on the prompt."
#define MSG_INF_INT_LOGCHANGED    "Log file name has been changed  on the prompt."
#define MSG_INF_CLI_ALLOC_ENV_OK  "Succeeded to allocate CLI environment handle."
#define MSG_INF_CLI_ALLOC_ENV_NG  "Failed to allocate CLI environment handle."
#define MSG_INF_CLI_ALLOC_DBC_OK  "Succeeded to allocate CLI connection handle."
#define MSG_INF_CLI_ALLOC_DBC_NG  "Failed to allocate CLI connection handle."
#define MSG_INF_CLI_FREE_ENV_OK   "Succeeded to free CLI environment handle."
#define MSG_INF_CLI_FREE_ENV_NG   "Failed to free CLI environment handle."
#define MSG_INF_CLI_FREE_DBC_OK   "Succeeded to free CLI connection handle."
#define MSG_INF_CLI_FREE_DBC_NG   "Failed to free CLI connection handle."
/* Level 5 messages */
#define MSG_DEB_FUNC_IN           "Function [%s] Enter."
#define MSG_DEB_FUNC_OUT          "Function [%s] Exit."
#define MSG_DEB_FUNC_OUT_RC       "Function [%s] Exit (rc = %d)."

/* ------------------------------------------------------------------ */
/* Define TRUE and FALSE if required                                  */
/* ------------------------------------------------------------------ */
#ifndef TRUE
#  define  TRUE   1
#endif

#ifndef FALSE
#  define  FALSE  0
#endif

/* ------------------------------------------------------------------ */
/* Define structure for input parameters                              */
/* ------------------------------------------------------------------ */
typedef struct input_parms
{
  char* dbAlias;
  char* userId;
  char* password;
  char* logFile;
  char* iniFile;
  int   timeout;
  int   interval;
  int   traceLevel;
  int	promptModeFlag;
  int   checkIniFlag;
  int   exitFlag;
} INPUT_PARMS;

/* ------------------------------------------------------------------ */
/* Function prototypes                                                */
/* ------------------------------------------------------------------ */
int
  CheckTimeout(int timeout);       /* Timeout value                   */

void
  CheckKeyInput();

int
  ParseArguments(int argNumber,    /* Input parameter count           */
                 char* argValue[]);/* Input parameter list            */

int
  ParseIniFile(int iniFlag);       /* Flag for the initial read       */

void
  InputParams();

void
  LogParams();

void
  DispParams();

int
  ConnectToDB(char* aliasName,     /* Database alias name             */
              char* userid,        /* User ID                         */
              char* password);     /* Password                        */
int
  DisconnectFromDB();

int
  ConnectionChange(char* newAliasName, /* New database alias name     */
                   char* newUserid,    /* New user ID                 */
                   char* newPassword); /* New password                */

int
  OpenLogFile(char* logFileName);  /* Log file name                   */

void
  CloseLogFile();

int
  LogFileChange(char* newLogFile); /* New log file name               */

void
  PrintLog(int level,              /* Message Level                   */
           char* type,             /* Message type                    */
           char* msg,              /* Message string                  */
           ...);                   /* Arguments                       */

void
  LogErrors(int errCode);          /* Error code                      */

char*
  GetErrorMessage(int errCode);    /* Error code                      */

void
  LogSqlcaData(struct sqlca sqlCa);/* SQLCA structure                 */

void
  DisplayHelp(char* cmdName);      /* Command name                    */

void
  GetStringFromPrompt(char* stringBuffer, /* String buffer            */
                      int bufferLen); /* Buffer length                */

void
  BreakFromLoop();

/* ------------------------------------------------------------------ */
/* Definition for platform dependent elements                         */
/* ------------------------------------------------------------------ */
#ifdef DB2NT
/* ------------------------------------------------------------------ */
/* Windows unique                                                     */
/* ------------------------------------------------------------------ */
#define signal(sig,func) signal(sig, (void(__cdecl *)(int))func)
#else
/* ------------------------------------------------------------------ */
/* UNIX common                                                        */
/* ------------------------------------------------------------------ */
#define Sleep(n) usleep(n * 1000)
#ifdef DB2SUN
/* ------------------------------------------------------------------ */
/* Solaris unique                                                     */
/* ------------------------------------------------------------------ */
#define IOCTL_REQ I_NREAD
#else
/* ------------------------------------------------------------------ */
/* Other UNIXes                                                       */
/* ------------------------------------------------------------------ */
#define IOCTL_REQ FIONREAD
#endif
#endif

/* ------------------------------------------------------------------ */
/* Global variables                                                   */
/* ------------------------------------------------------------------ */
FILE*       logFp = NULL;        /* Log file pointer                  */
FILE*       logSysFp = NULL;     /* System Log file pointer           */
int         currentLevel;        /* Current trace level               */
int         monitorFlag = TRUE;  /* Flag for the monitoring loop      */
char        errMsg[MAX_LINE_LENGTH]; /* Error message string buffer   */
SQLHANDLE   hEnv = 0;            /* SQL environment handle            */
SQLHANDLE   hDbc = 0;            /* SQL connection handle             */
INPUT_PARMS params;              /* Parameter structure               */

/**********************************************************************/
/* Main routine                                                       */
/**********************************************************************/
int main(int argc, char* argv[])
{
  int           rc = RC_OK;          /* Return code                   */
  time_t        startTime;           /* Start time for interval check */
#ifndef DB2NT
  struct termio ttyd;                /* Terminal I/O info. structure  */
  struct termio ttyd_old;            /* Terminal I/O info. backup     */
#endif

  /* ---------------------------------------------------------------- */
  /* Parse option parameters and values                               */
  /* ---------------------------------------------------------------- */
  rc = ParseArguments(argc, argv);

  if (rc != RC_OK)
  {
    if ((rc != RC_GETCONATTR) && (rc != RC_INVALID_VERSION))
    {
      /* ------------------------------------------------------------ */
      /* Put error into log file                                      */
      /* ------------------------------------------------------------ */
      if (rc != RC_SHOW_HELP)
      {
        LogErrors(rc);
      }

      /* ------------------------------------------------------------ */
      /* Display command syntax                                       */
      /* ------------------------------------------------------------ */
      DisplayHelp(argv[0]);
    }
  }
  else
  {
#ifndef DB2NT
    setbuf(stdout, NULL);
#endif

    PrintLog(1, MSG_TYPE_INF, MSG_INF_STARTED, argv[0]);

    /* -------------------------------------------------------------- */
    /* Log & display parameters                                       */
    /* -------------------------------------------------------------- */
    DispParams();

    /* -------------------------------------------------------------- */
    /* Connect to the database                                        */
    /* -------------------------------------------------------------- */
    if ((hEnv == 0) && (hDbc == 0))
    {
      rc = ConnectToDB(params.dbAlias, params.userId, params.password);
    }

    if (rc == RC_OK)
    {
      /* ------------------------------------------------------------ */
      /* Hook SIGINT                                                  */
      /* ------------------------------------------------------------ */
      signal(SIGINT, BreakFromLoop);

#ifndef DB2NT
      /* ------------------------------------------------------------ */
      /* Backup & change the terminal information                     */
      /* ------------------------------------------------------------ */
      if (params.promptModeFlag == TRUE)
      {
        ioctl(0,TCGETA,&ttyd);
        memcpy(&ttyd_old,&ttyd,sizeof(ttyd));
        ttyd.c_cc[VMIN]=1;
        ttyd.c_cc[VTIME]=0;
        ttyd.c_lflag &= ~(ICANON | ISIG);
        ioctl(0,TCSETA,&ttyd);
      }
#endif

      /* ------------------------------------------------------------ */
      /* Monitoring iteration (Top)                                   */
      /* ------------------------------------------------------------ */
      while (monitorFlag)
      {
        PrintLog(4, MSG_TYPE_INF, MSG_INF_ITR_STARTED);

        /* ---------------------------------------------------------- */
        /*  Quit command if "EXIT" is specified in the INI file       */
        /* ---------------------------------------------------------- */
        if (params.exitFlag == TRUE)
        {
          monitorFlag = FALSE;
          PrintLog(2, MSG_TYPE_INF, MSG_INF_INI_EXIT);
        }

        /* ---------------------------------------------------------- */
        /* Save the iteration start time                              */
        /* ---------------------------------------------------------- */
        time(&startTime);

        /* ---------------------------------------------------------- */
        /* Check and rollback the timeout transaction                 */
        /* ---------------------------------------------------------- */
        rc = CheckTimeout(params.timeout);

        if ((rc == RC_OK) && (monitorFlag == TRUE))
        {
          /* -------------------------------------------------------- */
          /* Check the interval duration                              */
          /* -------------------------------------------------------- */
          while ((time(NULL) - startTime) < params.interval)
          {
            /* ------------------------------------------------------ */
            /* If interactive mode, accept user input                 */
            /* ------------------------------------------------------ */
            if (params.promptModeFlag == TRUE)
            {
              CheckKeyInput();
            }

            if (monitorFlag == FALSE)
            {
              PrintLog(4, MSG_TYPE_WAR, MSG_WAR_ITR_BREAK);
              break;
            }

            /* ------------------------------------------------------ */
            /* Sleep to eliminate CPU usage                           */
            /* ------------------------------------------------------ */
            Sleep(DEFAULT_SLEEP_TIME);
          }

          /* -------------------------------------------------------- */
          /*  If needed, scan initialization file and change param.   */
          /* -------------------------------------------------------- */
          if (params.checkIniFlag)
          {
            PrintLog(4, MSG_TYPE_INF, MSG_INF_INI_CHECK);
            ParseIniFile(FALSE);
          }
        }
        else
        {
          /* -------------------------------------------------------- */
          /* Check transaction failed                                 */
          /* -------------------------------------------------------- */
          if (rc != RC_OK)
          { 
            monitorFlag = FALSE;
            LogErrors(rc);
          }
        }
      }
      /* ------------------------------------------------------------ */
      /* Monitoring iteration (Bottom)                                */
      /* ------------------------------------------------------------ */

#ifndef DB2NT
      /* ------------------------------------------------------------ */
      /* Restore the terminal information                             */
      /* ------------------------------------------------------------ */
      if (params.promptModeFlag == TRUE)
      {
        ioctl(0,TCSETA,&ttyd_old);
      }
#endif
      /* ------------------------------------------------------------ */
      /* Disconnect from database                                     */
      /* ------------------------------------------------------------ */
      rc = DisconnectFromDB();
    }
	else
	{
      if ((rc == RC_GETCONATTR) || (rc == RC_INVALID_VERSION))
      {
        DisconnectFromDB();
      }
	}
    PrintLog(1, MSG_TYPE_INF, MSG_INF_STOPPED, argv[0]);
  }

  /* ---------------------------------------------------------------- */
  /* Close log file                                                   */
  /* ---------------------------------------------------------------- */
  if (logFp)
  {
    CloseLogFile();
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "main", rc);

  return rc;
} /* main */

/**********************************************************************/
/* CheckTimeout() - Check transaction timeout and rollback it         */
/**********************************************************************/
int
  CheckTimeout(int timeout)
{
  int                     rc = RC_OK; /* Return code                  */
  int                     i;         /* Iteration counter             */
  struct sqlca            sqlca;     /* SQL comm. area structure      */
  db2XaListIndTransStruct iTList;    /* Indoubt transaction list      */
  db2XaRecoverStruct*     piData;    /* Indoubt data                  */
  char*                   sqlReason; /* SQLCA reason code             */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "CheckTimeout");

  /* ---------------------------------------------------------------- */
  /* Get the total number of indoubt transactions                     */
  /* ---------------------------------------------------------------- */
  iTList.piIndoubtData = NULL;
  iTList.iIndoubtDataLen = 0;
  db2XaListIndTrans(db2Version970, &iTList, &sqlca);

  PrintLog(5, MSG_TYPE_DEB, "db2XaListIndTrans(NULL)");
  LogSqlcaData(sqlca);

  if ((sqlca.sqlcode == SQL_RC_OK) || (sqlca.sqlcode == SQL_RC_W1251))
  {
    PrintLog(5, MSG_TYPE_INF, MSG_INF_INDTOTAL, iTList.oNumIndoubtsTotal);

    /* -------------------------------------------------------------- */
    /* Get the detail status of indoubt transactions                  */
    /* -------------------------------------------------------------- */
    if (iTList.oNumIndoubtsTotal)
    {
      PrintLog(3, MSG_TYPE_INF, MSG_INF_INDTOTAL, iTList.oNumIndoubtsTotal);

      /* ------------------------------------------------------------ */
      /* Allocate required space for the data structures              */
      /* ------------------------------------------------------------ */
      if (iTList.oReqBufferLen > (sizeof(db2XaRecoverStruct)
                                 * iTList.oNumIndoubtsTotal))
      {
        piData = (db2XaRecoverStruct*)malloc(iTList.oReqBufferLen);
      }
      else
      {
        piData = (db2XaRecoverStruct*)malloc(sizeof(db2XaRecoverStruct)
                                             * iTList.oNumIndoubtsTotal);
      }

      iTList.piIndoubtData = piData;
      iTList.iIndoubtDataLen = iTList.oReqBufferLen;
      db2XaListIndTrans(db2Version970, &iTList, &sqlca);

      PrintLog(5, MSG_TYPE_DEB, "db2XaListIndTrans");
      LogSqlcaData(sqlca);

      if (sqlca.sqlcode == SQL_RC_OK)
      {
        /* ---------------------------------------------------------- */
        /* Check the status of the indoubt transactions               */
        /* ---------------------------------------------------------- */
        for(i = 0; i < (int)iTList.oNumIndoubtsTotal; ++i)
        {
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_HEADER);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_TIME, piData[i].timestamp);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_DBALIAS, piData[i].dbalias);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_APPLID, piData[i].applid);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_SEQNO, piData[i].sequence_no);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_AUTHID, piData[i].auth_id);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_LOGFULL, piData[i].log_full);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_STATUS, piData[i].indoubt_status);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_ORIGIN, piData[i].originator);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_XID_FID, piData[i].xid.formatID);
          PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_XID_GID, piData[i].xid.data);

          /* -------------------------------------------------------- */
          /* If xa_end is issued (and xa_prepare is not issued) ...   */
          /* -------------------------------------------------------- */
          if (piData[i].indoubt_status == SQLXA_TS_END)
          {
            PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_SECONDS,
                            time(NULL) - (int)piData[i].timestamp);

            /* ------------------------------------------------------ */
            /* Check the timeout                                      */
            /* ------------------------------------------------------ */
            if(time(NULL) - (int)piData[i].timestamp > timeout)
            {
              PrintLog(2, MSG_TYPE_WAR, MSG_INF_TIMEOUT_OCCURRED,
                            time(NULL) - (int)piData[i].timestamp);
              /* ---------------------------------------------------- */
              /* Rollback the transaction                             */
              /* ---------------------------------------------------- */
              rc = sqlxphrl(SQLXA_EXE_THIS_NODE, &(piData[i].xid), &sqlca);

              PrintLog(5, MSG_TYPE_DEB, "sqlxphrl");
              LogSqlcaData(sqlca);

              if ((rc == 0) && (sqlca.sqlcode == 0))
              {
                /* -------------------------------------------------- */
                /* Rollback completed successfully                    */
                /* -------------------------------------------------- */
                PrintLog(2, MSG_TYPE_INF, MSG_INF_ROLLBACK_OK);
              }
              else
              {
                PrintLog(2, MSG_TYPE_INF, MSG_INF_ROLLBACK_NG);
                rc = RC_XA_ROLLBACK;
              }

              /* ---------------------------------------------------- */
              /* Forget transaction status                            */
              /* ---------------------------------------------------- */
              rc = sqlxhfrg(&(piData[i].xid), &sqlca);

              PrintLog(5, MSG_TYPE_DEB, "sqlxhfrg");
              LogSqlcaData(sqlca);

              if ((rc == 0) && (sqlca.sqlcode == 0))
              {
                /* -------------------------------------------------- */
                /* Forget transaction status completed successfully   */
                /* -------------------------------------------------- */
                PrintLog(2, MSG_TYPE_INF, MSG_INF_FORGET_OK);
              }
              else if ((rc == 0) && (sqlca.sqlcode == SQL_RC_E998))
              {
                sqlReason = (char*)malloc(sqlca.sqlerrml + 1);
                *(sqlReason + sqlca.sqlerrml) = 0;
                memcpy(sqlReason, sqlca.sqlerrmc, sqlca.sqlerrml);
                if (strcmp(sqlReason, "36"))
                {
                  rc = RC_XA_FORGET;
                }
                free(sqlReason);
              }
              else
              {
                /* -------------------------------------------------- */
                /* Forget transaction status error                    */
                /* -------------------------------------------------- */
                PrintLog(2, MSG_TYPE_INF, MSG_INF_FORGET_NG);
                rc = RC_XA_FORGET;
              }
            }
          }
        }
      }
      else
      {
        /* ---------------------------------------------------------- */
        /* Failed to get indoubt data                                 */
        /* ---------------------------------------------------------- */
        PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_DATA_NG);
        rc = RC_XA_GET_DATA;
      }
      free(piData);
    }
  }
  else
  {
    /* -------------------------------------------------------------- */
    /* Failed to get a total number of indoubt transaction            */
    /* -------------------------------------------------------------- */
    PrintLog(3, MSG_TYPE_INF, MSG_INF_IND_NUMBER_NG);
    rc = RC_XA_GET_NUMBER;
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "CheckTimeout", rc);

  return rc;
} /* CheckTimeout */

/**********************************************************************/
/* CheckKeyInput() - Key input check for interactive mode             */
/**********************************************************************/
void
  CheckKeyInput()
{
  int           iCommand;            /* Input command character       */
  char          iCommandStr[64];     /* Input command string          */
  int           keyHitFlag;          /* Key hit flag                  */

  /* ---------------------------------------------------------------- */
  /* Check key input                                                  */
  /* ---------------------------------------------------------------- */
#ifdef DB2NT
  keyHitFlag = _kbhit();
#else
  ioctl(0, IOCTL_REQ, &keyHitFlag);
#endif
  if (keyHitFlag)
  {
    /* -------------------------------------------------------------- */
    /* Get command character                                          */
    /* -------------------------------------------------------------- */
#ifdef DB2NT
    iCommand = _getch();
#else
    iCommand = getchar();
#endif

    PrintLog(4, MSG_TYPE_INF, MSG_INF_COMMAND, iCommand);

    /* -------------------------------------------------------------- */
    /* Change parameter                                               */
    /* -------------------------------------------------------------- */
    if ((iCommand == 'C') || (iCommand == 'c'))
    {
#ifdef DB2NT
      printf("%c", iCommand);
#endif
      InputParams();
    }

    /* -------------------------------------------------------------- */
    /* Quit command                                                   */
    /* -------------------------------------------------------------- */
    if ((iCommand == 'Q') || (iCommand == 'q'))
    {
#ifdef DB2NT
      printf("%c", iCommand);
#endif
      /* ------------------------------------------------------------ */
      /* Display quit confirmation message                            */
      /* ------------------------------------------------------------ */
      printf("\n\n");
      printf(MSG_END_PROMPT);

      GetStringFromPrompt(iCommandStr, 64);

      if ((*iCommandStr == 'Y' || *iCommandStr == 'y'))
      {
        /* ---------------------------------------------------------- */
        /* Ignore the interval and quit immediately                   */
        /* ---------------------------------------------------------- */
        monitorFlag = FALSE;
      }
      else
      {
        /* ---------------------------------------------------------- */
        /* Continue the iteration                                     */
        /* ---------------------------------------------------------- */
        DispParams();
      }
    }
  }

  return;
} /* CheckKeyInput */


/**********************************************************************/
/* ParseArguments() - Parse input parameters                          */
/**********************************************************************/
int
  ParseArguments(int argNumber,
                 char* argValue[])
{
  char* value;                       /* Pointer to the argument value */
  char  optionChar;                  /* Option character              */
  int   optionInt;                   /* Option value                  */
  int   count = 1;                   /* Counter                       */
  int   rc = RC_OK;                  /* Return code                   */
  char  inputBuf[64];                /* Buffer for the user input     */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "ParseArguments");

  /* ---------------------------------------------------------------- */
  /* Parameter initialization (Apply default values)                  */
  /* ---------------------------------------------------------------- */
  params.dbAlias = (char*)malloc(1);
  strcpy(params.dbAlias, "");
  params.userId = (char*)malloc(1);
  strcpy(params.userId, "");
  params.password = (char*)malloc(1);
  strcpy(params.password, "");
  params.logFile = (char*)malloc(1);
  strcpy(params.logFile, "");
  params.iniFile = (char*)malloc(1);
  strcpy(params.iniFile, "");
  params.timeout = DEFAULT_TIMEOUT;
  params.interval = DEFAULT_INTERVAL;
  params.traceLevel = DEFAULT_TRACELEVEL;
  params.promptModeFlag = FALSE;
  params.checkIniFlag = FALSE;
  params.exitFlag = FALSE;

  /* ---------------------------------------------------------------- */
  /* Set trace level as global                                        */
  /* ---------------------------------------------------------------- */
  currentLevel = params.traceLevel;

  /* ---------------------------------------------------------------- */
  /* Open system log file                                             */
  /* ---------------------------------------------------------------- */
  logSysFp = fopen(SYSTEM_LOGFILE, "a+");
  setbuf(logSysFp, NULL);

  /* ---------------------------------------------------------------- */
  /* Read entire command arguments                                    */
  /* ---------------------------------------------------------------- */
  while ((count + 1 <= argNumber) && (rc == RC_OK))
  {
    value = argValue[count];
    
    if (((value[0] == '-') || (value[0] == '/')) && (value[2] == 0))
    {
      optionChar = value[1];

      /* ------------------------------------------------------------ */
      /* Command check                                                */
      /* ------------------------------------------------------------ */
      switch (optionChar)
      {
        /* ---------------------------------------------------------- */
        /* Database alias name                                        */
        /* ---------------------------------------------------------- */
        case 'd':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              free(params.dbAlias);
              params.dbAlias = (char*)malloc(strlen(argValue[count + 1]) + 1);
              strcpy(params.dbAlias, argValue[count + 1]);
            }
            else
            {
              rc = RC_NO_DBALIAS;
            }
          }
          else
          {
            rc = RC_NO_DBALIAS;
          }
          break;

        /* ---------------------------------------------------------- */
        /* User ID                                                    */
        /* ---------------------------------------------------------- */
        case 'u':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              free(params.userId);
              params.userId = (char*)malloc(strlen(argValue[count + 1]) + 1);
              strcpy(params.userId, argValue[count + 1]);
            }
            else
            {
              rc = RC_NO_USERID;
            }
          }
          else
          {
            rc = RC_NO_USERID;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Password                                                   */
        /* ---------------------------------------------------------- */
        case 'p':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              free(params.password);
              params.password = (char*)malloc(strlen(argValue[count + 1]) + 1);
              strcpy(params.password, argValue[count + 1]);
            }
            else
            {
              rc = RC_NO_PASSWORD;
            }
          }
          else
          {
            rc = RC_NO_PASSWORD;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Log file name                                              */
        /* ---------------------------------------------------------- */
        case 'o':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              free(params.logFile);
              params.logFile = (char*)malloc(strlen(argValue[count + 1]) + 1);
              strcpy(params.logFile, argValue[count + 1]);

              /* ---------------------------------------------------- */
              /* Open log file                                        */
              /* ---------------------------------------------------- */
              rc = OpenLogFile(params.logFile);
            }
            else
            {
              rc = RC_NO_LOGFILE;
            }
          }
          else
          {
            rc = RC_NO_LOGFILE;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Initialization file name                                   */
        /* ---------------------------------------------------------- */
        case 'f':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              free(params.iniFile);
              params.iniFile = (char*)malloc(strlen(argValue[count + 1]) + 1);
              strcpy(params.iniFile, argValue[count + 1]);
            }
            else
            {
              rc = RC_NO_INIFILE;
            }
          }
          else
          {
            rc = RC_NO_INIFILE;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Timeout                                                    */
        /* ---------------------------------------------------------- */
        case 't':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              optionInt = (int)atol(argValue[count + 1]);
              if (optionInt <= MAX_INT_VALUE)
              {
                if (optionInt > 0)
                {
                  params.timeout = optionInt;
                }
                else
                {
                  rc = RC_WRONG_PARAM_VALUE;
                }
              }
              else
              {
                rc = RC_MAX_VALUE_ERR;
              }
            }
            else
            {
              rc = RC_NO_TIMEOUT;
            }
          }
          else
          {
            rc = RC_NO_TIMEOUT;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Interval                                                   */
        /* ---------------------------------------------------------- */
        case 'i':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              optionInt = (int)atol(argValue[count + 1]);
              if (optionInt <= MAX_INT_VALUE)
              {
                if (optionInt > 0)
                {
                  params.interval = optionInt;
                }
                else
                {
                  rc = RC_WRONG_PARAM_VALUE;
                }
              }
              else
              {
                rc = RC_MAX_VALUE_ERR;
              }
            }
            else
            {
              rc = RC_NO_INTERVAL;
            }
          }
          else
          {
            rc = RC_NO_INTERVAL;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Trace level                                                */
        /* ---------------------------------------------------------- */
        case 'l':
          if (count + 1 < argNumber)
          {
            if (*argValue[count + 1] != '-')
            {
              optionInt = (int)atol(argValue[count + 1]);
              if (optionInt <= 5)
              {
                if (optionInt >= 1)
                {
                  params.traceLevel = (int)atol(argValue[count + 1]);
                  currentLevel = params.traceLevel;
                }
                else
                {
                  rc = RC_WRONG_PARAM_VALUE;
                }
              }
              else
              {
                rc = RC_MAX_VALUE_ERR;
              }
            }
            else
            {
              rc = RC_NO_TRACELVL;
            }
          }
          else
          {
            rc = RC_NO_TRACELVL;
          }
          break;

        /* ---------------------------------------------------------- */
        /* Prompt mode                                                */
        /* ---------------------------------------------------------- */
        case 'v':
          params.promptModeFlag = TRUE;
          count = count - 1;
          break;

        /* ---------------------------------------------------------- */
        /* Check initialization file mode                             */
        /* ---------------------------------------------------------- */
        case 'c':
          params.checkIniFlag = TRUE;
          count = count - 1;
          break;

        /* ---------------------------------------------------------- */
        /* Help option                                                */
        /* ---------------------------------------------------------- */
        case 'h':
        case '?':
          rc = RC_SHOW_HELP;
          count = count - 1;
          break;

        /* ---------------------------------------------------------- */
        /* Unknown option specified                                   */
        /* ---------------------------------------------------------- */
        default :
          rc =  RC_WRONG_PARAM;
          break;
      }

      /* ------------------------------------------------------------ */
      /* Read next option                                             */
      /* ------------------------------------------------------------ */
      count = count + 2;

    } else {
      PrintLog(1, MSG_TYPE_INF, MSG_INF_WRONG_OPTION, value);
      rc = RC_WRONG_PARAM;
    }
  }

  if (argNumber == 1)
  {
    rc = RC_SHOW_HELP;
  }

  if (rc == RC_OK)
  {
    /* -------------------------------------------------------------- */
    /* Get parameters from Initialization file                        */
    /* -------------------------------------------------------------- */
    if (*params.iniFile != 0)
    {
      rc = ParseIniFile(TRUE);
    }

    if (rc == RC_OK)
    {
      /* ------------------------------------------------------------ */
      /* If database name is not specified, prompt user to type it    */
      /* ------------------------------------------------------------ */
      if (*params.dbAlias == 0)
      {
        if (params.promptModeFlag == TRUE)
        {
          printf("\n");
          printf(MSG_DBNAME_INPUT);
          printf("\n");

          /* -------------------------------------------------------- */
          /* Get database name                                        */
          /* -------------------------------------------------------- */
          printf("\t");
          printf(MSG_PROMPT_DBNAME);
          printf(" ==> ");

          GetStringFromPrompt(inputBuf, 64);

          if (*inputBuf)
          {
            free(params.dbAlias);
            params.dbAlias = (char*)malloc(strlen(inputBuf) + 1);
            strcpy(params.dbAlias, inputBuf);
          }

          /* -------------------------------------------------------- */
          /* Get user id                                              */
          /* -------------------------------------------------------- */
          printf("\t");
          printf(MSG_PROMPT_USERID);
          printf(" ==> ");

          GetStringFromPrompt(inputBuf, 64);

          if (*inputBuf)
          {
            free(params.userId);
            params.userId = (char*)malloc(strlen(inputBuf) + 1);
            strcpy(params.userId, inputBuf);
          }

          /* -------------------------------------------------------- */
          /* Get password                                             */
          /* -------------------------------------------------------- */
          printf("\t");
          printf(MSG_PROMPT_PASSWORD);
          printf(" ==> ");

          GetStringFromPrompt(inputBuf, 64);

          if (*inputBuf)
          {
            free(params.password);
            params.password = (char*)malloc(strlen(inputBuf) + 1);
            strcpy(params.password, inputBuf);
          }
        }
        else
        {
          /* -------------------------------------------------------- */
          /* Just return error, if not interactive mode               */
          /* -------------------------------------------------------- */
          rc = RC_NO_DBALIAS;
        }
      }

      /* ------------------------------------------------------------ */
      /* Set default log file name, if not specified                  */
      /* ------------------------------------------------------------ */
      if (*params.logFile == 0)
      {
        if (*params.dbAlias)
        {
          free(params.logFile);
          params.logFile = (char*)malloc(strlen(params.dbAlias)
                                       + strlen(DEFAULT_LOGFILE_EXT) + 1);
          strcpy(params.logFile, params.dbAlias);
          strcat(params.logFile, DEFAULT_LOGFILE_EXT);
          /* -------------------------------------------------------- */
          /* Open log file                                            */
          /* -------------------------------------------------------- */
          rc = OpenLogFile(params.logFile);
        }
        else
        {
          /* -------------------------------------------------------- */
          /* Open default log file                                    */
          /* -------------------------------------------------------- */
          OpenLogFile(params.logFile);
          rc = RC_NO_DBALIAS;
        }
      }

      if (*params.dbAlias)
      {
        if ((!*params.userId && *params.password) ||
             (*params.userId && !*params.password))
        {
          /* -------------------------------------------------------- */
          /* Syntax error (-u and -p need to be specified together)   */
          /* -------------------------------------------------------- */
          rc = RC_SYNTAX_ERROR;
          PrintLog(1, MSG_TYPE_WAR, MSG_WAR_ID_AND_PW);
        }
      }

      /* ------------------------------------------------------------ */
      /* '-c' option need to be used together with '-f' option        */
      /* ------------------------------------------------------------ */
      if ((*params.iniFile == 0) && (params.checkIniFlag == TRUE))
      {
        rc = RC_SYNTAX_ERROR;
        PrintLog(1, MSG_TYPE_WAR, MSG_WAR_C_REQ_F);
      }
    }
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "ParseArguments", rc);

  return rc;
} /* ParseArguments */

/**********************************************************************/
/* ParseIniFile() - Get option parameters from INI file.              */
/**********************************************************************/
int
  ParseIniFile(int iniFlag)
{
  char* keyParam = NULL;             /* Pointer to the key parameter  */
  char* keyValue = NULL;             /* Pointer to the key value      */
  char* bufferPos;                   /* Pointer to the buffer position*/
  FILE  *iniFp = NULL;               /* File pointer                  */
  char  lineBuf[MAX_LINE_LENGTH];    /* Line buffer                   */
  int   findEqualFlag;               /* Flag for the 'equal' read     */
  int   lineLength;                  /* Line length                   */
  int   dbConnectFlag = FALSE;       /* DB re-connection flag         */
  int   logChangeFlag = FALSE;       /* Log file change flag          */
  char* newDbAlias = NULL;           /* New database alias name       */
  char* newUserid = NULL;            /* New userid                    */
  char* newPassword = NULL;          /* New password                  */
  char* newLogFile = NULL;           /* New log file                  */
  int   changeFlag = FALSE;          /* Flag for the parameter change */
  int   rc = RC_OK;                  /* Return code                   */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "ParseIniFile");

  /* ---------------------------------------------------------------- */
  /* Open initialization file as read-only                            */
  /* ---------------------------------------------------------------- */
  iniFp = fopen (params.iniFile, "r");

  if (iniFp)
  {
    if (iniFlag == TRUE)
    {
      PrintLog(1, MSG_TYPE_INF, MSG_INF_INIFILEOPEN, params.iniFile);
    }
    else
    {
      PrintLog(4, MSG_TYPE_INF, MSG_INF_INIFILEOPEN, params.iniFile);
    }
    /* -------------------------------------------------------------- */
    /* Read lines one by one                                          */
    /* -------------------------------------------------------------- */
    while (fgets(lineBuf, MAX_LINE_LENGTH, iniFp))
    {
      bufferPos = lineBuf;
      findEqualFlag = FALSE;
      lineLength = strlen(lineBuf);

      /* ------------------------------------------------------------ */
      /* Retrieve parameter and value                                 */
      /* ------------------------------------------------------------ */
      do
      {
        if ((*bufferPos != ' ') && (*bufferPos != '\n')
         && (*bufferPos != '\r') && (*bufferPos != '\t'))
        {
          if (*bufferPos == '#')
          {
            break;
          }

          if (keyParam)
          {
            if (*bufferPos == '=')
            {
              *bufferPos = 0;
              findEqualFlag = TRUE;
            }
            else
            {
              if (findEqualFlag)
              {
                keyValue = bufferPos;
                findEqualFlag = FALSE;
              }
            }
          }
          else
          {
            keyParam = bufferPos;
          }
        }
        else
        {
          *bufferPos = 0;
        }
      }
      while(bufferPos++ < lineBuf + lineLength);

      /* ------------------------------------------------------------ */
      /* Put values in the parameter structure                        */
      /* ------------------------------------------------------------ */
      if (keyParam && keyValue)
      {
        if ((*keyParam) && (*keyValue))
        {
          PrintLog(4, MSG_TYPE_INF, MSG_INF_INIVALUE, keyParam, keyValue);

          /* -------------------------------------------------------- */
          /* Database alias name                                      */
          /* -------------------------------------------------------- */
          if (!strcmp(keyParam, PARMKEY_DBALIAS))
          {
            if (iniFlag == TRUE)
            {
              newDbAlias = (char*)malloc(strlen(keyValue) + 1);
              strcpy(newDbAlias, keyValue);
              dbConnectFlag = TRUE;
            
              if (strcmp(params.dbAlias, newDbAlias))
              {
                changeFlag = TRUE;
              }
            }
            else
            {
              if (strcmp(params.dbAlias, keyValue))
              {
                PrintLog(1, MSG_TYPE_WAR, MSG_WAR_INI_CHANGE_DBNAME);
              }
            }
          }
          /* -------------------------------------------------------- */
          /* User ID                                                  */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_USERID))
          {
            if (iniFlag == TRUE)
            {
              newUserid = (char*)malloc(strlen(keyValue) + 1);
              strcpy(newUserid, keyValue);
              dbConnectFlag = TRUE;

              if (strcmp(params.userId, newUserid))
              {
                changeFlag = TRUE;
              }
            }
            else
            {
              if (strcmp(params.userId, keyValue))
              {
                PrintLog(1, MSG_TYPE_WAR, MSG_WAR_INI_CHANGE_USERID);
              }
            }
          }
          /* -------------------------------------------------------- */
          /* Password                                                 */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_PASSWORD))
          {
            if (iniFlag == TRUE)
            {
              newPassword = (char*)malloc(strlen(keyValue) + 1);
              strcpy(newPassword, keyValue);
              dbConnectFlag = TRUE;

              if (strcmp(params.password, newPassword))
              {
                changeFlag = TRUE;
              }
            }
            else
            {
              if (strcmp(params.password, keyValue))
              {
                PrintLog(1, MSG_TYPE_WAR, MSG_WAR_INI_CHANGE_PASSWD);
              }
            }
          }
          /* -------------------------------------------------------- */
          /* Log file name                                            */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_LOGFILE))
          {
            newLogFile = (char*)malloc(strlen(keyValue) + 1);
            strcpy(newLogFile, keyValue);

            logChangeFlag = TRUE;

            if (strcmp(params.logFile, newLogFile))
            {
              changeFlag = TRUE;
            }
          }
          /* -------------------------------------------------------- */
          /* Timeout value                                            */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_TIMEOUT))
          {
            if (atoi(keyValue) <= MAX_INT_VALUE)
            {
              if (atoi(keyValue) > 0)
              {
                if (params.timeout != atoi(keyValue))
                {
                  changeFlag = TRUE;
                }
                params.timeout = atoi(keyValue);
              }
              else
              {
                LogErrors(RC_WRONG_PARAM_VALUE);
              }
            }
            else
            {
              LogErrors(RC_MAX_VALUE_ERR);
            }
          }
          /* -------------------------------------------------------- */
          /* Interval value                                           */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_INTERVAL))
          {
            if (atoi(keyValue) <= MAX_INT_VALUE)
            {
              if (atoi(keyValue) > 0)
              {
                if (params.interval != atoi(keyValue))
                {
                  changeFlag = TRUE;
                }
                params.interval = atoi(keyValue);
              }
              else
              {
                LogErrors(RC_WRONG_PARAM_VALUE);
              }
            }
            else
            {
              LogErrors(RC_MAX_VALUE_ERR);
            }
          }
          /* -------------------------------------------------------- */
          /* Trace level                                              */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_TRACELVL))
          {
            if (atoi(keyValue) <= 5)
            {
              if (atoi(keyValue) >= 1)
              {
                if (params.traceLevel != atoi(keyValue))
                {
                  changeFlag = TRUE;
                }
                params.traceLevel = atoi(keyValue);
                currentLevel = params.traceLevel;
              }
              else
              {
                LogErrors(RC_WRONG_PARAM_VALUE);
              }
            }
            else
            {
              LogErrors(RC_MAX_VALUE_ERR);
            }
          }
          /* -------------------------------------------------------- */
          /* Prompt mode flag                                         */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_PROMPT))
          {
            if ((*(keyValue) == 'y') || (*(keyValue) == 'Y'))
            {
              if (params.promptModeFlag == FALSE)
              {
                if (iniFlag == TRUE)
                {
                  changeFlag = TRUE;
                  params.promptModeFlag = TRUE;
                }
                else
                {
                  PrintLog(1, MSG_TYPE_WAR, MSG_WAR_INI_CHANGE_PROMPT);
                }
              }
            }
            else if ((*(keyValue) == 'n') || (*(keyValue) == 'N'))
            {
              if (params.promptModeFlag == TRUE)
              {
                if (iniFlag == TRUE)
                {
                  changeFlag = TRUE;
                  params.promptModeFlag = FALSE;
                }
                else
                {
                  PrintLog(1, MSG_TYPE_WAR, MSG_WAR_INI_CHANGE_PROMPT);
                }
              }
            }
            else
            {
              LogErrors(RC_WRONG_PARAM_VALUE);
            }
          }
          /* -------------------------------------------------------- */
          /* Loop Exit flag                                           */
          /* -------------------------------------------------------- */
          else if (!strcmp(keyParam, PARMKEY_EXIT))
          {
            if ((*(keyValue) == 'y') || (*(keyValue) == 'Y'))
            {
              if (params.exitFlag == FALSE)
              {
                changeFlag = TRUE;
              }
              params.exitFlag = TRUE;
            }
            else if ((*(keyValue) == 'n') || (*(keyValue) == 'N'))
            {
              if (params.exitFlag == TRUE)
              {
                changeFlag = TRUE;
              }
              params.exitFlag = FALSE;
            }
            else
            {
              LogErrors(RC_WRONG_PARAM_VALUE);
            }
          }
          /* -------------------------------------------------------- */
          /* Unknown parameter                                        */
          /* -------------------------------------------------------- */
          else
          {
            LogErrors(RC_WRONG_INI_FORMAT);
          }
        }
        else
        {
          /* -------------------------------------------------------- */
          /* Either parameter or value is blank                       */
          /* -------------------------------------------------------- */
          LogErrors(RC_WRONG_INI_FORMAT);
        }
      }
      /* ------------------------------------------------------------ */
      /* Reset parameter and value pointers                           */
      /* ------------------------------------------------------------ */
      keyParam = NULL;
      keyValue = NULL;
    }
    /* -------------------------------------------------------------- */
    /* Close ini file handle                                          */
    /* -------------------------------------------------------------- */
    fclose(iniFp);
  }
  else
  {
    /* -------------------------------------------------------------- */
    /* Initialization file open error                                 */
    /* -------------------------------------------------------------- */
    LogErrors(RC_INI_FILE_OPEN_ERR);
  }

  /* ---------------------------------------------------------------- */
  /* DB name, userid, or password has been changed                    */
  /* ---------------------------------------------------------------- */
  if (dbConnectFlag == TRUE)
  {
    /* -------------------------------------------------------------- */
    /* Change the database connection                                 */
    /* -------------------------------------------------------------- */
    PrintLog(4, MSG_TYPE_INF, MSG_INF_INI_DBCHANGED);
    rc = ConnectionChange(newDbAlias, newUserid, newPassword);
  }

  /* ---------------------------------------------------------------- */
  /* Log file name has been changed                                   */
  /* ---------------------------------------------------------------- */
  if (logChangeFlag == TRUE)
  {
    /* -------------------------------------------------------------- */
    /* Change log file                                                */
    /* -------------------------------------------------------------- */
    PrintLog(4, MSG_TYPE_INF, MSG_INF_INI_LOGCHANGED);
    LogFileChange(newLogFile);
  }

  /* ---------------------------------------------------------------- */
  /* Parameter has been changed in the iteration.                     */
  /* ---------------------------------------------------------------- */
  if ((changeFlag == TRUE) && (iniFlag == FALSE))
  {
    DispParams();
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "ParseIniFile", rc);

  return rc;
} /* ParseIniFile */

/**********************************************************************/
/* InputParms() - Accept parameter changes                            */
/**********************************************************************/
void
  InputParams()
{
  char  newValueC[64];               /* New value (string)            */
  int   newValueI;                   /* New value (numeric)           */
  char* newLogFile = NULL;           /* New log file                  */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "InputParams");

  /* ---------------------------------------------------------------- */
  /* Display the header message for the parameter input               */
  /* ---------------------------------------------------------------- */
  printf("\n\n");
  printf(MSG_PARM_INPUT);
  printf("\n");

  /* ---------------------------------------------------------------- */
  /* Timeout parameter input                                          */
  /* ---------------------------------------------------------------- */
  printf("\t");
  printf(MSG_PROMPT_TIMEOUT);
  printf("(%d) = ", params.timeout);

  GetStringFromPrompt(newValueC, 64);

  if (*newValueC)
  {
    newValueI = atoi(newValueC);
    if (newValueI <= MAX_INT_VALUE)
    {
      if (newValueI > 0)
      {
        params.timeout = newValueI;
      }
      else
      {
        LogErrors(RC_WRONG_PARAM_VALUE);
      }
    }
    else
    {
      LogErrors(RC_MAX_VALUE_ERR);
    }
  }

  /* ---------------------------------------------------------------- */
  /* Interval parameter input                                         */
  /* ---------------------------------------------------------------- */
  printf("\t");
  printf(MSG_PROMPT_INTERVAL);
  printf("(%d) = ", params.interval);

  GetStringFromPrompt(newValueC, 64);

  if (*newValueC)
  {
    newValueI = atoi(newValueC);
    if (newValueI <= MAX_INT_VALUE)
    {
      if (newValueI > 0)
      {
        params.interval = newValueI;
      }
      else
      {
        LogErrors(RC_WRONG_PARAM_VALUE);
      }
    }
    else
    {
      LogErrors(RC_MAX_VALUE_ERR);
    }
  }

  /* ---------------------------------------------------------------- */
  /* Trace level parameter input                                      */
  /* ---------------------------------------------------------------- */
  printf("\t");
  printf(MSG_PROMPT_TRACELVL);
  printf("(%d) = ", params.traceLevel);

  GetStringFromPrompt(newValueC, 64);

  if (*newValueC)
  {
    newValueI = atoi(newValueC);
    if (newValueI <= 5)
    {
      if (newValueI >= 1)
      {
        params.traceLevel = newValueI;
        currentLevel = params.traceLevel;
      }
      else
      {
        LogErrors(RC_WRONG_PARAM_VALUE);
      }
    }
    else
    {
      LogErrors(RC_MAX_VALUE_ERR);
    }
  }

  /* ---------------------------------------------------------------- */
  /* Log file name parameter input                                    */
  /* ---------------------------------------------------------------- */
  printf("\t");
  printf(MSG_PROMPT_LOGFILE);
  printf("(%s) = ", params.logFile);

  GetStringFromPrompt(newValueC, 64);

  if (*newValueC)
  {
    newLogFile = (char*)malloc(strlen(newValueC) + 1);
    strcpy(newLogFile, newValueC);

    /* -------------------------------------------------------------- */
    /* Change log file                                                */
    /* -------------------------------------------------------------- */
    PrintLog(4, MSG_TYPE_INF, MSG_INF_INT_LOGCHANGED);
    LogFileChange(newLogFile);
  }

  /* ---------------------------------------------------------------- */
  /* Log & display parameters                                         */
  /* ---------------------------------------------------------------- */
  DispParams();

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "InputParams");

  return;
} /* InputParams */

/******************************************************************+***/
/* LogParms() - Log parameters in the file                            */
/**********************************************************************/
void
  LogParams()
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "LogParams");

  /* ---------------------------------------------------------------- */
  /* Record parameter values into the log file                        */
  /* ---------------------------------------------------------------- */
  PrintLog(1, MSG_TYPE_INF, MSG_DBALIAS, params.dbAlias);
  PrintLog(1, MSG_TYPE_INF, MSG_USERID, params.userId);
  PrintLog(1, MSG_TYPE_INF, MSG_PASSWORD, "*");  /* Hide password     */
  PrintLog(1, MSG_TYPE_INF, MSG_LOGFILE, params.logFile);
  PrintLog(1, MSG_TYPE_INF, MSG_INIFILE, params.iniFile);
  PrintLog(1, MSG_TYPE_INF, MSG_TIMEOUT, params.timeout);
  PrintLog(1, MSG_TYPE_INF, MSG_INTERVAL, params.interval);
  PrintLog(1, MSG_TYPE_INF, MSG_TRACELVL, params.traceLevel);
  PrintLog(1, MSG_TYPE_INF, MSG_PROMPT, params.promptModeFlag ? "ON" : "OFF");
  PrintLog(1, MSG_TYPE_INF, MSG_CHKINI, params.checkIniFlag ? "ON" : "OFF");

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "LogParams");

  return;
} /* LogParams */

/**********************************************************************/
/* DispParms() - Log & display parameters                             */
/**********************************************************************/
void
  DispParams()
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "DispParams");

  /* ---------------------------------------------------------------- */
  /* Record parameters into the log file                              */
  /* ---------------------------------------------------------------- */
  LogParams();

  if (params.promptModeFlag == TRUE)
  {
    /* -------------------------------------------------------------- */
    /* Display parameters on the console                              */
    /* -------------------------------------------------------------- */
    printf ("\n");
    printf (MSG_PARM_HEAD);
    printf ("\n");
    printf (MSG_DBALIAS, params.dbAlias);
    printf ("\n");
    printf (MSG_USERID, params.userId);
    printf ("\n");
    printf (MSG_PASSWORD, *(params.userId) ? "*" : "");/* Hide passwd */
    printf ("\n");
    printf (MSG_TIMEOUT, params.timeout);
    printf ("\n");
    printf (MSG_INTERVAL, params.interval);
    printf ("\n");
    printf (MSG_TRACELVL, params.traceLevel);
    printf ("\n");
    printf (MSG_PROMPT, params.promptModeFlag ? "ON" : "OFF");
    printf ("\n");
    printf (MSG_CHKINI, params.checkIniFlag ? "ON" : "OFF");
    printf ("\n");
    printf (MSG_LOGFILE, params.logFile);
    printf ("\n");
    printf (MSG_INIFILE, *params.iniFile ? params.iniFile : "(null)");
    printf ("\n");

    printf(MSG_CMD_PROMPT);
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "DispParams");

  return;
} /* DispParams */

/**********************************************************************/
/* ConnectToDB() - Connect to the database.                           */
/**********************************************************************/
int
  ConnectToDB(char* aliasName,
              char* userid,
              char* password)
{
  int        rc = RC_OK;              /* Return code                  */
  SQLRETURN  sqlRc = SQL_SUCCESS;     /* SQL return code structure    */
  SQLCHAR   *value = 0;               /* Version & rel. information   */
  SQLINTEGER length = 0;              /* Length of version string     */
  int        version;                 /* Version number               */
  int        release;                 /* Release number               */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "ConnectToDB");

  /* ---------------------------------------------------------------- */
  /* Allocate environment handle                                      */
  /* ---------------------------------------------------------------- */
  sqlRc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &hEnv);

  if (sqlRc == SQL_SUCCESS)
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_ALLOC_ENV_OK);
  }
  else
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_ALLOC_ENV_NG);
    rc = RC_ALLOC_ENV;
  }

  /* ---------------------------------------------------------------- */
  /* Allocate connection handle                                       */
  /* ---------------------------------------------------------------- */
  sqlRc = SQLAllocHandle(SQL_HANDLE_DBC, hEnv, &hDbc);

  if (sqlRc == SQL_SUCCESS)
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_ALLOC_DBC_OK);
  }
  else
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_ALLOC_DBC_NG);
    rc = RC_ALLOC_HANDLE;
  }

  /* ---------------------------------------------------------------- */
  /* Connect to the database                                          */
  /* ---------------------------------------------------------------- */
  sqlRc = SQLConnect(hDbc, (SQLCHAR*)aliasName, SQL_NTS,
                           (SQLCHAR*)userid, SQL_NTS,
                           (SQLCHAR*)password, SQL_NTS);

  if (sqlRc == SQL_SUCCESS)
  {
    PrintLog(1, MSG_TYPE_INF, MSG_INF_CONNECTED, aliasName);

    /* -------------------------------------------------------------- */
    /* Get version and release information                            */
    /* -------------------------------------------------------------- */
    value = (SQLCHAR*)malloc(10);

    sqlRc = SQLGetConnectAttr(hDbc, SQL_ATTR_DB2_SQLERRP, value, SQL_IS_POINTER, &length);
    if (sqlRc == SQL_SUCCESS)
    {
      *(value + length - 1) = 0;
      release = atoi((const char*)value + 5);
      *(value + length - 3) = 0;
      version = atoi((const char*)value + 3);

      /* ------------------------------------------------------------ */
      /* V8.2 or higher is required                                   */
      /* ------------------------------------------------------------ */
      if (version < VALID_VERSION)
      {
        rc = RC_INVALID_VERSION;
        LogErrors(rc);
      }
      else
      {
        if ((version == VALID_VERSION) && (release < VALID_RELEASE))
        {
          rc = RC_INVALID_VERSION;
          LogErrors(rc);
        }
      }
    }
    else
    {
      rc = RC_GETCONATTR;
      LogErrors(rc);
    }
    
    free(value);
  }
  else
  {
    rc = RC_CONNECT;
    LogErrors(rc);

    /* -------------------------------------------------------------- */
    /* Syntax error (id and pw need to be specified together)         */
    /* -------------------------------------------------------------- */
    if ((!*userid && *password) || (*userid && !*password))
    {
      rc = RC_SYNTAX_ERROR;
      PrintLog(1, MSG_TYPE_WAR, MSG_WAR_ID_AND_PW);
      LogErrors(rc);
    }

    /* -------------------------------------------------------------- */
    /* Frees connection handle                                        */
    /* -------------------------------------------------------------- */
    sqlRc = SQLFreeHandle(SQL_HANDLE_DBC, hDbc);

    if (sqlRc == SQL_SUCCESS)
    {
      PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_DBC_OK);
      hDbc = 0;
    }
    else
    {
      PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_DBC_NG);
      rc = RC_FREE_HANDLE;
    }

    /* -------------------------------------------------------------- */
    /* Frees environment handle                                       */
    /* -------------------------------------------------------------- */
    sqlRc = SQLFreeHandle(SQL_HANDLE_ENV, hEnv);

    if (sqlRc == SQL_SUCCESS)
    {
      PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_ENV_OK);
      hEnv = 0;
    }
    else
    {
      PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_ENV_NG);
      rc = RC_FREE_ENV;
    }
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "ConnectToDB", rc);

  return rc;
} /* ConnectToDB */

/**********************************************************************/
/* DisconnectFromDB() - Disconnect from the database.                 */
/**********************************************************************/
int
  DisconnectFromDB()
{
  int       rc = RC_OK;              /* Return code                   */
  SQLRETURN sqlRc = SQL_SUCCESS;     /* SQL return code structure     */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "DisconnectFromDB");

  /* ---------------------------------------------------------------- */
  /* Disconnect from database                                         */
  /* ---------------------------------------------------------------- */
  sqlRc = SQLDisconnect(hDbc);

  if (sqlRc == SQL_SUCCESS)
  {
      PrintLog(1, MSG_TYPE_INF, MSG_INF_DISCONNECTED, params.dbAlias);
  }
  else
  {
    rc = RC_DISCONNECT;
    LogErrors(rc);
  }

  /* ---------------------------------------------------------------- */
  /* Frees connection handle                                          */
  /* ---------------------------------------------------------------- */
  sqlRc = SQLFreeHandle(SQL_HANDLE_DBC, hDbc);

  if (sqlRc == SQL_SUCCESS)
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_DBC_OK);
  }
  else
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_DBC_NG);
    rc = RC_FREE_HANDLE;
  }

  /* ---------------------------------------------------------------- */
  /* Frees environment handle                                         */
  /* ---------------------------------------------------------------- */
  sqlRc = SQLFreeHandle(SQL_HANDLE_ENV, hEnv);

  if (sqlRc == SQL_SUCCESS)
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_ENV_OK);
  }
  else
  {
    PrintLog(4, MSG_TYPE_INF, MSG_INF_CLI_FREE_ENV_NG);
    rc = RC_FREE_ENV;
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "DisconnectFromDB", rc);

  return rc;
} /* DisconnectFromDB */

/**********************************************************************/
/* ConnectionChange() - Change the target database                    */
/**********************************************************************/
int
  ConnectionChange(char* newAliasName,
                   char* newUserid,
                   char* newPassword)
{
  int rc = RC_OK;                      /* Return code                 */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "ConnectionChange");

  if (newAliasName == NULL)
  {
    newAliasName = (char*)malloc(1);
    strcpy(newAliasName, "");
  }

  if (newUserid == NULL)
  {
    newUserid = (char*)malloc(1);
    strcpy(newUserid, "");
  }

  if (newPassword == NULL)
  {
    newPassword = (char*)malloc(1);
    strcpy(newPassword, "");
  }

  if (strcmp(newAliasName, params.dbAlias) ||
      strcmp(newUserid, params.userId) ||
      strcmp(newPassword, params.password))
  {
    if (hEnv && hDbc)
    {
      /* -------------------------------------------------------------- */
      /* Disconnect from database                                       */
      /* -------------------------------------------------------------- */
      rc = DisconnectFromDB();
    }

    if (rc == RC_OK)
    {
      /* -------------------------------------------------------------- */
      /* Connect to new database                                        */
      /* -------------------------------------------------------------- */
      rc = ConnectToDB(newAliasName, newUserid, newPassword);

      if ((rc == RC_OK) || (rc == RC_GETCONATTR) || (rc == RC_INVALID_VERSION))
      {
        /* ------------------------------------------------------------ */
        /* Connect succeeded (Put parameters to the structure)          */
        /* ------------------------------------------------------------ */
        if (newAliasName)
        {
          free(params.dbAlias);
          params.dbAlias = (char*)malloc(strlen(newAliasName) + 1);
          strcpy(params.dbAlias, newAliasName);
        }

        if (newUserid)
        {
          free(params.userId);
          params.userId = (char*)malloc(strlen(newUserid) + 1);
          strcpy(params.userId, newUserid);
        }

        if (newPassword)
        {
          free(params.password);
          params.password = (char*)malloc(strlen(newPassword) + 1);
          strcpy(params.password, newPassword);
        }

        if ((rc == RC_GETCONATTR) || (rc == RC_INVALID_VERSION))
        {
          DisconnectFromDB();
        }
      }
      else
      {
        /* ------------------------------------------------------------ */
        /* Connect failed (Connect to the previous database)            */
        /* ------------------------------------------------------------ */
        if (hEnv && hDbc)
        {
          rc = ConnectToDB(params.dbAlias, params.userId, params.password);
        }
      }
    }
  }

  if (newAliasName)
  {
    free(newAliasName);
  }

  if (newUserid)
  {
    free(newUserid);
  }

  if (newPassword)
  {
    free(newPassword);
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "ConnectionChange", rc);

  return rc;
} /* ConnectionChange */

/**********************************************************************/
/* OpenLogFile() - Open log file                                      */
/**********************************************************************/
int
  OpenLogFile(char* logFileName)
{
  int rc = RC_OK;                      /* Return code                 */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "OpenLogFile");

  /* ---------------------------------------------------------------- */
  /* Open log file                                                    */
  /* ---------------------------------------------------------------- */
  logFp = fopen(logFileName, "a+");

  if (logFp)
  {
    setbuf(logFp, NULL);
    PrintLog(1, MSG_TYPE_INF, MSG_INF_LOGFILEOPEN, logFileName);
  }
  else
  {
    rc = RC_LOG_FILE_OPEN_ERR;
    LogErrors(rc);
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "OpenLogFile", rc);

  return rc;
} /* OpenLogFile */

/**********************************************************************/
/* CloseLogFile() - Close log file                                    */
/**********************************************************************/
void
  CloseLogFile()
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "CloseLogFile");

  /* ---------------------------------------------------------------- */
  /* Close log file                                                   */
  /* ---------------------------------------------------------------- */
  fclose(logFp);

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "CloseLogFile");

  return;
} /* CloseLogFile */

/**********************************************************************/
/* LogFileChange() - Change the log file                              */
/**********************************************************************/
int
  LogFileChange(char* newLogFile)
{
  int rc = RC_OK;                      /* Return code                 */

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "LogFileChange");

  if (strcmp(newLogFile, params.logFile))
  {
    if (logFp)
    {
      /* ------------------------------------------------------------ */
      /* Close log file                                               */
      /* ------------------------------------------------------------ */
      CloseLogFile();
    }

    /* -------------------------------------------------------------- */
    /* Open new log file                                              */
    /* -------------------------------------------------------------- */
    rc = OpenLogFile(newLogFile);

    if (rc == RC_OK)
    {
      /* ------------------------------------------------------------ */
      /* File open succeeded (Put file name into structure)           */
      /* ------------------------------------------------------------ */
      free(params.logFile);
      params.logFile = (char*)malloc(strlen(newLogFile) + 1);
      strcpy(params.logFile, newLogFile);
    }
    else
    {
      /* ------------------------------------------------------------ */
      /* File open error (Open previous log file)                     */
      /* ------------------------------------------------------------ */
      rc = OpenLogFile(params.logFile);
    }
  }

  if (newLogFile)
  {
    free(newLogFile);
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT_RC, "LogFileChange", rc);

  return rc;
} /* LogFileChange */

/**********************************************************************/
/* PrintLog() - Print log message                                     */
/**********************************************************************/
void
  PrintLog(int level,
           char* type,
           char* msg,
           ...)
{
  va_list    args;                   /* Argument list                 */
  char*      cValue;                 /* Pointer for the string arg.   */
  int        iValue;                 /* Numeric argument              */
  time_t     tm;                     /* Store the time value          */
  struct tm* lTime;                  /* Structure for the time data   */
  char       stringBuf[MAX_LINE_LENGTH]; /* Message string buffer     */
  char*      bufTop;                 /* Buffer pointer                */
  char*      msgPtr;                 /* Message pointer               */
  FILE*      fp;                     /* File pointer                  */

  /* ---------------------------------------------------------------- */
  /* Check the message level                                          */
  /* ---------------------------------------------------------------- */
  if (level <= currentLevel)
  {
    strcpy(stringBuf, msg);

    bufTop = stringBuf;
    msgPtr = msg;

    va_start(args , msg);

    /* -------------------------------------------------------------- */
    /* If %s or %d is found in the message, get arguments             */
    /* -------------------------------------------------------------- */
    do
    {
      msgPtr = strstr(msgPtr, "%");
      if (msgPtr)
      {
        /* ---------------------------------------------------------- */
        /* If %s is found, retrieve argument as string                */
        /* ---------------------------------------------------------- */
        if (*(msgPtr + 1) == 's')
        {
          cValue = va_arg(args , char*);
        }
        /* ---------------------------------------------------------- */
        /* If %d is found, retrieve argument as integer               */
        /* ---------------------------------------------------------- */
        else if (*(msgPtr + 1) == 'd')
        {
          iValue = va_arg(args , int);
          cValue = (char*)malloc(32);
          sprintf(cValue, "%d", iValue);
        }
        /* ---------------------------------------------------------- */
        /* If %c is found, retrieve argument as character             */
        /* ---------------------------------------------------------- */
        else if (*(msgPtr + 1) == 'c')
        {
          iValue = va_arg(args , int);
          cValue = (char*)malloc(2);
          sprintf(cValue, "%c", iValue);
        }
        else
        {
          /* -------------------------------------------------------- */
          /* No value is retrieved                                    */
          /* -------------------------------------------------------- */
          cValue = NULL;
        }

        /* ---------------------------------------------------------- */
        /* If the string value is "", replace it to "none"            */
        /* ---------------------------------------------------------- */
        if (cValue == NULL)
        {
          cValue = (char*)malloc(strlen(MSG_NONE) + 1);
          strcpy(cValue, MSG_NONE);
        }

        /* ---------------------------------------------------------- */
        /* Replace the value                                          */
        /* ---------------------------------------------------------- */
        bufTop = strstr(bufTop, "%");
        strcpy(bufTop, cValue);
        strcpy(bufTop + strlen(cValue), msgPtr + 2);
        bufTop = bufTop + strlen(cValue);

        if (!strcmp(cValue, MSG_NONE) || 
               (*(msgPtr + 1) == 'd') || (*(msgPtr + 1) == 'c'))
        {
          free(cValue);
        }

        /* ---------------------------------------------------------- */
        /* Increment the pointer to search for the next '%'           */
        /* ---------------------------------------------------------- */
        msgPtr = msgPtr + 2;
      }
    } while (msgPtr);

    va_end(args);

    /* -------------------------------------------------------------- */
    /* Get current time                                               */
    /* -------------------------------------------------------------- */
    time(&tm);
    lTime = localtime(&tm);

    /* -------------------------------------------------------------- */
    /* If log file is not open, write to system log                   */
    /* -------------------------------------------------------------- */
    if (logFp)
    {
      fp = logFp;
    }
    else
    {
      fp = logSysFp;
    }

    /* -------------------------------------------------------------- */
    /* Generate log string and put it to the file                     */
    /* -------------------------------------------------------------- */
    fprintf(fp, "%02d/%02d/%04d %02d:%02d:%02d [%s] %s\n",
            lTime->tm_mon+1, lTime->tm_mday, lTime->tm_year+1900,
            lTime->tm_hour, lTime->tm_min, lTime->tm_sec, type, stringBuf);
  }

  return;
} /* PrintLog */

/**********************************************************************/
/* LogErrors() - Log error message                                    */
/**********************************************************************/
void
  LogErrors(int errCode)
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "LogErrors");

  /* ---------------------------------------------------------------- */
  /* Put error message into log file                                  */
  /* ---------------------------------------------------------------- */
  PrintLog(1, MSG_TYPE_ERR, GetErrorMessage(errCode));

  /* ---------------------------------------------------------------- */
  /* Display error message, if interactive mode                       */
  /* ---------------------------------------------------------------- */
  if (params.promptModeFlag == TRUE)
  {
    printf("\n[ERROR] : ");
    printf(GetErrorMessage(errCode));
    printf("\n");
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "LogErrors");

  return;
} /* LogErrors */

/**********************************************************************/
/* GetErrorMessage() - Get error message string                       */
/**********************************************************************/
char*
  GetErrorMessage(int errCode)
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "GetErrorMessage");

  /* ---------------------------------------------------------------- */
  /* Retrieve error message string from error number                  */
  /* ---------------------------------------------------------------- */
  switch (errCode)
  {
    case RC_ERROR :
      strcpy(errMsg, MSG_ERR_ERROR);
      break;
    case RC_INI_ERROR :
      strcpy(errMsg, MSG_ERR_INI_ERROR);
      break;
    case RC_NO_DBALIAS :
      strcpy(errMsg, MSG_ERR_NO_DBALIAS);
      break;
    case RC_NO_USERID :
      strcpy(errMsg, MSG_ERR_NO_USERID);
      break;
    case RC_NO_PASSWORD :
      strcpy(errMsg, MSG_ERR_NO_PASSWORD);
      break;
    case RC_NO_LOGFILE :
      strcpy(errMsg, MSG_ERR_NO_LOGFILE);
      break;
    case RC_NO_INIFILE :
      strcpy(errMsg, MSG_ERR_NO_INIFILE);
      break;
    case RC_NO_TIMEOUT :
      strcpy(errMsg, MSG_ERR_NO_TIMEOUT);
      break;
    case RC_NO_INTERVAL :
      strcpy(errMsg, MSG_ERR_NO_INTERVAL);
      break;
    case RC_NO_TRACELVL :
      strcpy(errMsg, MSG_ERR_NO_TRACELVL);
      break;
    case RC_LOG_FILE_OPEN_ERR :
      strcpy(errMsg, MSG_ERR_LOG_FILE_OPEN_ERR);
      break;
    case RC_INI_FILE_OPEN_ERR :
      strcpy(errMsg, MSG_ERR_INI_FILE_OPEN_ERR);
      break;
    case RC_MAX_VALUE_ERR :
      strcpy(errMsg, MSG_ERR_MAX_VALUE_ERR);
      break;
    case RC_WRONG_PARAM :
      strcpy(errMsg, MSG_ERR_WRONG_PARAM);
      break;
    case RC_WRONG_PARAM_VALUE :
      strcpy(errMsg, MSG_ERR_WRONG_PARAM_VALUE);
      break;
    case RC_WRONG_INI_FORMAT :
      strcpy(errMsg, MSG_ERR_WRONG_INI_FORMAT);
      break;
    case RC_CONNECT :
      strcpy(errMsg, MSG_ERR_CONNECT);
      break;
    case RC_DISCONNECT :
      strcpy(errMsg, MSG_ERR_DISCONNECT);
      break;
    case RC_ALLOC_ENV :
      strcpy(errMsg, MSG_ERR_ALLOC_ENV);
      break;
    case RC_FREE_ENV :
      strcpy(errMsg, MSG_ERR_FREE_ENV);
      break;
    case RC_ALLOC_HANDLE :
      strcpy(errMsg, MSG_ERR_ALLOC_HANDLE);
      break;
    case RC_FREE_HANDLE :
      strcpy(errMsg, MSG_ERR_FREE_HANDLE);
      break;
    case RC_XA_ROLLBACK :
      strcpy(errMsg, MSG_ERR_XA_ROLLBACK);
      break;
    case RC_XA_FORGET :
      strcpy(errMsg, MSG_ERR_XA_FORGET);
      break;
    case RC_XA_GET_DATA :
      strcpy(errMsg, MSG_ERR_XA_GET_DATA);
      break;
    case RC_XA_GET_NUMBER :
      strcpy(errMsg, MSG_ERR_XA_GET_NUMBER);
      break;
    case RC_SYNTAX_ERROR :
      strcpy(errMsg, MSG_ERR_SYNTAX_ERROR);
      break;
    case RC_GETCONATTR :
      strcpy(errMsg, MSG_ERR_GETCONATTR);
      break;
    case RC_INVALID_VERSION :
      strcpy(errMsg, MSG_ERR_INVALID_VERSION);
      break;
    default :
      strcpy(errMsg, MSG_ERR_UNKNOWN);
      break;
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "GetErrorMessage");

  return errMsg;
} /* GetErrorMessage */

/**********************************************************************/
/* LogSqlcaData() - Log SQLCA data (for debug purpose only)           */
/**********************************************************************/
void LogSqlcaData(struct sqlca sqlCa)
{
  char msgBuf[MAX_MSG_LENGTH + 1];   /* Message buffer                */

  if (currentLevel == 5)
  {
    PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "LogSqlcaData");

    if (sqlCa.sqlcode)
    {
      if (sqlCa.sqlcode < 0)
      {
        /* ---------------------------------------------------------- */
        /* Error                                                      */
        /* ---------------------------------------------------------- */
        PrintLog(5, MSG_TYPE_DEB, "======= ERROR =========");
      }
      else
      {
        /* ---------------------------------------------------------- */
        /* Warning                                                    */
        /* ---------------------------------------------------------- */
        PrintLog(5, MSG_TYPE_DEB, "======= WARNING =======");
      }

      PrintLog(5, MSG_TYPE_DEB, "SQLCODE  = %d", sqlCa.sqlcode);

      /* ------------------------------------------------------------ */
      /* Get message string for the sqlcode                           */
      /* ------------------------------------------------------------ */
      sqlaintp(msgBuf, MAX_MSG_LENGTH, 80, &sqlCa);

      PrintLog(5, MSG_TYPE_DEB, msgBuf);
      PrintLog(5, MSG_TYPE_DEB, "SQLSTATE = %d", sqlCa.sqlstate);

      /* ------------------------------------------------------------ */
      /* Get messages string for the sqlstate                         */
      /* ------------------------------------------------------------ */
      sqlogstt(msgBuf, MAX_MSG_LENGTH, 80, sqlCa.sqlstate);

      PrintLog(5, MSG_TYPE_DEB, msgBuf);
    }
    else
    {
      /* ------------------------------------------------------------ */
      /* No error                                                     */
      /* ------------------------------------------------------------ */
      PrintLog(5, MSG_TYPE_DEB, "======= NO ERROR ======");
      PrintLog(5, MSG_TYPE_DEB, "SQLCODE  = %d", sqlCa.sqlcode);
    }

    PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "LogSqlcaData");
  }

  return;
} /* LogSqlcaData */

/**********************************************************************/
/* DisplayHelp() - Show command syntax                                */
/**********************************************************************/
void DisplayHelp(char* cmdName)
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "DisplayHelp");

  /* ---------------------------------------------------------------- */
  /* Display usage on the console                                     */
  /* ---------------------------------------------------------------- */
  printf ("\n");
  printf("Usage : %s [-d <database_alias> [-u <userid> -p <password>]\n", cmdName);
  printf("                                    | -f <initialize_file> [-c]]\n");
  printf("                 [-o <log_file>] [-t <timeout>] [-i <interval>]\n");
  printf("                 [-l <trace_level>] [-v] [-[h|?]]\n");
  printf ("\n");
  printf ("where : database_alias  = Database alias name.\n");
  printf ("        userid          = User ID.\n");
  printf ("        password        = Password.\n");
  printf ("        initialize_file = Initialization file name.\n");
  printf ("        log_file        = Log file name.\n");
  printf ("        timeout         = Timeout value (1 - 32767).\n");
  printf ("        interval        = Interval value (1 - 32767).\n");
  printf ("        trace_level     = Trace level (1 - 5).\n");

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "DisplayHelp");

  return;
} /* DisplayHelp */

/**********************************************************************/
/* GetStringFromPrompt() - Get the string from the prompt             */
/**********************************************************************/
void
  GetStringFromPrompt(char* stringBuffer, int bufferLen)
{
  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "GetStringFromPrompt");

  fgets(stringBuffer, bufferLen, stdin);

  /* ---------------------------------------------------------------- */
  /* Strip \n                                                         */
  /* ---------------------------------------------------------------- */
  if (*(stringBuffer + strlen(stringBuffer) - 1) == '\n')
  {
    *(stringBuffer + strlen(stringBuffer) - 1) = 0;
  }

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "GetStringFromPrompt");

  return;
} /* GetStringFromPrompt */

/**********************************************************************/
/* BreakFromLoop() - Break from loop (Signal handler for SIGINT)      */
/**********************************************************************/
void BreakFromLoop()
{

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_IN, "BreakFromLoop");

  /* ---------------------------------------------------------------- */
  /* Set monitor flag to exit from the iteration                      */
  /* ---------------------------------------------------------------- */
  monitorFlag = FALSE;

  PrintLog(5, MSG_TYPE_DEB, MSG_DEB_FUNC_OUT, "BreakFromLoop");

  return;
} /* BreakFromLoop */
