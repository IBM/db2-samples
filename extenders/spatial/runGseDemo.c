/*****************************************************************************
**
** Source File Name = runGseDemo.c
**
** Licensed Materials - Property of IBM
**
** (C) COPYRIGHT International Business Machines Corp. 2000, 2014
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
**
**P   PURPOSE :
**      Demonstrates the major GIS concepts and services supported by DB2
**      Spatial Extender
**E
*****************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include "sql.h"
#include "sqlcli.h"
#include "sqlcli1.h"
#include "sqlca.h"
#include "sqlutil.h"
#include "samputil.h"
#include "db2gse.h"
#include "sqlenv.h"
#include "db2ApiDf.h"

#define MAX_COLUMNS    255

#define MIN_APPLHEAPSZ     2048
#define MIN_LOGPRIMARY       10
#define MIN_LOGFILSIZ      1000

#define LAT_LONG 54031
#define KENT5 26980
#define NORTH_AMERICAN 4269
#define POINT_TYPE "ST_Point"
#define POLYGON_TYPE "ST_Polygon"

#define MAX_STMT_LEN 255
#define MAX_SP_PARAMS 22

#ifndef max
#define  max(a,b) (a > b ? a : b)
#endif


/* Macro for Statement Handle Checking */
#define STMT_HANDLE_CHECK( hstmt, SQLRC )                               \
    if ( SQLRC != SQL_SUCCESS )                                         \
    {                                                                   \
      rc = HandleInfoPrint( SQL_HANDLE_STMT, hstmt,                     \
                            SQLRC, __LINE__, __FILE__ ) ;               \
      if ( rc == 2 )  StmtResourcesFree( hstmt );                       \
      if ( rc != 0 )  return rc;                                        \
    }

/* Macro for Connection Handle Checking */
#define DBC_HANDLE_CHECK( hdbc, SQLRC )                                 \
    if ( SQLRC != SQL_SUCCESS )                                         \
    {                                                                   \
      rc = HandleInfoPrint( SQL_HANDLE_DBC, hdbc,                       \
                            SQLRC, __LINE__, __FILE__ ) ;               \
      if ( rc != 0 )  return rc;                                        \
    }


#undef _NOW32OS
#undef _W32OS

#if (   defined(DB2AIX) || defined(DB2SUN) ||        \
        defined(DB2HP) || \
        defined(DB2LINUX))
#define _NOW32OS
#else
#define _W32OS
#endif

SQLHANDLE henv;
SQLHANDLE hdbc;
SQLHANDLE hstmt;

SQLCHAR dbase[SQL_MAX_DSN_LENGTH + 1] = "sample";
SQLCHAR uid[MAX_UID_LENGTH + 1];
SQLCHAR pwd[MAX_PWD_LENGTH + 1];
SQLCHAR AbChoice[4]="Y";

char  path[255];
char  exceptionpath[255];
char  msgpath[255];

SQLINTEGER ind[MAX_SP_PARAMS];

/* Return code for all the services */
SQLINTEGER retCode = 0;
SQLINTEGER NbCall = 0;
SQLINTEGER NbError = 0;
SQLINTEGER CheckRC = 0;
SQLINTEGER domenu = 0;
SQLRETURN rc;

char       reserved[SQL_MAX_MESSAGE_LENGTH+1] = "";
char       locatorFile[257];
char       parvalues[1000];
char       buffer[80];

struct sqlca    sqlca;

/* local functions for util.c */
void HandleLocationPrint( SQLRETURN, int, char * );
void HandleDiagnosticsPrint( SQLSMALLINT, SQLHANDLE );

/******************************************************************************
**        1.1 - HandleInfoPrint - prints on the screen everything that
**                                goes unexpected with a SQL... function.
******************************************************************************/
int HandleInfoPrint( SQLSMALLINT htype,  /* handle type identifier */
                     SQLHANDLE   hndl,   /* handle used by the SQL...func. */
                     SQLRETURN   sqlrc,  /* ret. code of the SQL... func. */
                     int         line,
                     char *      file )
{
  int rc = 0;

  switch ( sqlrc )
  {
    case SQL_SUCCESS:
      rc = 0;
      break ;
    case SQL_INVALID_HANDLE:
      printf( "\n-SQL INVALID HANDLE-----\n");
      HandleLocationPrint( sqlrc, line, file);
      rc = 1;
      break ;
    case SQL_ERROR:
      printf( "\n--SQL ERROR--------------\n");
      HandleLocationPrint( sqlrc, line, file);
      HandleDiagnosticsPrint( htype, hndl);
      rc = 2;
      break ;
    case SQL_SUCCESS_WITH_INFO:
      rc = 0;
      break ;
    case SQL_STILL_EXECUTING :
      rc = 0;
      break ;
    case SQL_NEED_DATA :
      rc = 0;
      break ;
    case SQL_NO_DATA_FOUND:
      rc = 0;
      break ;
    default:
      printf( "\n--default----------------\n");
      HandleLocationPrint( sqlrc, line, file);
      rc = 3;
      break ;
  }

  return ( rc ) ;
}


/******************************************************************************
**                1.1.1 - HandleLocationPrint    - used by HandleInfoPrint
******************************************************************************/
void HandleLocationPrint( SQLRETURN   sqlrc,
                          int         line,
                          char *      file)
{
  printf( "  sqlrc             = %d\n", sqlrc);
  printf( "  line              = %d\n", line);
  printf( "  file              = %s\n", file);
}

/******************************************************************************
**                1.1.2 - HandleDiagnosticsPrint - used by HandleInfoPrint
******************************************************************************/
void HandleDiagnosticsPrint( SQLSMALLINT htype, /* handle type identifier */
                             SQLHANDLE   hndl  /* handle */)
{
  SQLCHAR     message[SQL_MAX_MESSAGE_LENGTH + 1] ;
  SQLCHAR     sqlstate[SQL_SQLSTATE_SIZE + 1] ;
  SQLINTEGER  sqlcode ;
  SQLSMALLINT length, i ;

  i = 1 ;

  while ( SQLGetDiagRec( htype, hndl, i, sqlstate, &sqlcode,
                         message, SQL_MAX_MESSAGE_LENGTH + 1,
                         &length ) == SQL_SUCCESS )
  {
    printf( "\n  SQLSTATE          = %s\n", sqlstate ) ;
    printf( "  Native Error Code = %d\n", sqlcode ) ;
    printf( "%s\n", message ) ;
    i++ ;
  }

  printf( "-------------------------\n" ) ;
}
/*<-- */


/******************************************************************************
**        1.3 - StmtResourcesFree - no more comments
******************************************************************************/
/* this function is used in STMT_HANDLE_CHECK, */
/* it can not contain STMT_HANDLE_CHECK        */
int  StmtResourcesFree( SQLHANDLE hstmt )
{
  SQLRETURN   sqlrc = SQL_SUCCESS;
  int         rc = 0;

  sqlrc = SQLFreeStmt( hstmt, SQL_UNBIND ) ;
  rc = HandleInfoPrint( SQL_HANDLE_STMT, hstmt,
                        sqlrc, __LINE__, __FILE__);
  if( rc != 0) return(1) ;

  sqlrc = SQLFreeStmt( hstmt, SQL_RESET_PARAMS ) ;
  rc = HandleInfoPrint( SQL_HANDLE_STMT, hstmt,
                        sqlrc, __LINE__, __FILE__);
  if( rc != 0) return(1) ;

  sqlrc = SQLFreeStmt( hstmt, SQL_CLOSE ) ;
  rc = HandleInfoPrint( SQL_HANDLE_STMT, hstmt,
                        sqlrc, __LINE__, __FILE__);
  if( rc != 0) return(1) ;

  return( 0 );
}

/*======================================================================*/
/*                                                                      */
/*        createDb - create a database in the local db directory        */
/*                                                                      */
/*======================================================================*/
int createDb(char* dbase)
{
  struct sqledbdesc db_desc;
  struct sqledbcountryinfo dbCountry;
  struct sqledbdescext db_desc_ext;


  printf("---------------> Creating the database '%s'  ...\n", dbase);

  memset(&db_desc, 0, sizeof db_desc);
  strcpy(db_desc.sqldbdid, SQLE_DBDESC_2);
  db_desc.sqldbccp = 0;
  db_desc.sqldbcss = 0;
  db_desc.sqldbsgp = 0;
  db_desc.sqldbnsg = 10;
  db_desc.sqltsext = -1;
  db_desc.sqlusrts = NULL;
  db_desc.sqltmpts = NULL;
  db_desc.sqlcatts = NULL;
  strcpy(db_desc.sqldbcmt, "spatial extender test database");
  strcpy(dbCountry.sqldbcodeset, "IBM-850");
  strcpy(dbCountry.sqldblocale, "En_US");
  
  memset(&db_desc_ext, 0, sizeof db_desc_ext);
  db_desc_ext.sqlPageSize = SQL_PAGESIZE_8K;  

  sqlecrea(dbase, dbase, "", &db_desc, &dbCountry, '\0', &db_desc_ext, &sqlca);

  if (sqlca.sqlcode != 0)
  {
    printf("<--------------- Failed to create local database '%s' with return \
code %d.\n", dbase, sqlca.sqlcode);
    return sqlca.sqlcode;
  }
  else
    printf("<--------------- Database '%s' was successfully created.\n",
           dbase);

  return sqlca.sqlcode;
}

/*======================================================================*/
/*                                                                      */
/*    getNumPartitions - Get the number of entries from db2nodes.cfg    */
/*                                                                      */
/*    returns: numPartitions                                            */
/*       - if numPartitions = 1 we run in a single partition env        */
/*       - if numPartitions > 1 we run in a multiple partition env      */
/*                                                                      */
/*    Note: no longer used as of 04/09/07                               */
/*                                                                      */
/*======================================================================*/
int getNumPartitions()
{
  FILE  *db2nodes_fp;              /* db2nodes.cfg file pointer     */
  char  cfg[256];                  /* input configuration file name */
  char  sqllibdir[255];            /* the concrete sqllib path      */

  int max_node_number, node_number = 0;

  strcpy(sqllibdir,getenv("DB2PATH"));
#ifdef _NOW32OS
  sprintf(cfg,"%s/%s",sqllibdir,"db2nodes.cfg");
#else
  sprintf(cfg,"%s\\db2\\%s",sqllibdir,"db2nodes.cfg");
#endif

  db2nodes_fp = fopen (cfg,"r");

  if ( db2nodes_fp != NULL )
  {
    /*================================================================*/
    /* Read the input cfg file for node num and keep the maximum      */
    /*================================================================*/
    while(!feof(db2nodes_fp))
    {
      fscanf(db2nodes_fp,"%d", &node_number);
      fscanf(db2nodes_fp,"%*[^\n]");   /* Skip to the End of the Line */
      fscanf(db2nodes_fp,"%*1[\n]");   /* Skip One Newline */

      max_node_number = node_number + 1; /* the first number is 0 */
    }

    fclose (db2nodes_fp);
  }
  else
  {
    /*===============================================================*/
    /* If we can not read the file because it does not exist, we can */
    /* asume that we have single node environment only.              */
    /*===============================================================*/

    max_node_number = 1;
  }

  return max_node_number;
}

/*======================================================================*/
/*                                                                      */
/*                        Wrap up the Demo session                      */
/*                                                                      */
/*======================================================================*/
int WrapUpDemo()
{
  SQLRETURN rc;
  printf("==========> Wrapping up the DB2GSE demo program ...\n");
  rc = SQLTransact(henv, hdbc, SQL_COMMIT);
  CHECK_DBC(hdbc, rc);

  if (rc != SQL_SUCCESS)
  {
    terminate(henv, rc);
    exit(0);
  }

  printf("Total errors: %i\n",NbError);
  printf("<========== The DB2GSE demo program is wrapped up \
successfully.\n\n");
  printf("Disconnecting .....\n");

  rc = SQLDisconnect(hdbc);
  CHECK_DBC(hdbc, rc);
  if (rc != SQL_SUCCESS)
  {
    terminate(henv, rc);
    exit(0);
  }

  rc = SQLFreeHandle(SQL_HANDLE_DBC,hdbc);
  CHECK_DBC(hdbc, rc);
  if (rc != SQL_SUCCESS)
  {
    terminate(henv, rc);
    exit(0);
  }
  rc = SQLFreeHandle(SQL_HANDLE_ENV,henv);
  if (rc != SQL_SUCCESS)
    terminate(henv, rc);
  exit(0);
}


/*======================================================================*/
/*                                                                      */
/*                              GseCheck()                              */
/*   - Just check SQLRETURN values and closes program in error case     */
/*   - The CheckRC=1 variable may be used to avoid abborting in the     */
/*     error situation for debugging pourposes                          */
/*                                                                      */
/*======================================================================*/
void GseCheck(SQLRETURN rc)
{
  NbCall++;
  if (rc != 0)
  {
    NbError++;
    if(CheckRC) /*  CheckRC=1 - Abort on any error */
      WrapUpDemo();
    else /*  CheckRC=0 - go on */
    {
      printf("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
      printf("==========> An error has occurred in the function call number \
%00i\n",NbCall);
      printf("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\
\n\n");

    }
  }
  else
  {
    printf("===========================================================\n");
    printf("==========> Successfully called function number %00i\n",NbCall);
    printf("===========================================================\n\n\
\n");
  }
  fflush(stdout);
}


/*======================================================================*/
/*                                                                      */
/*                           gseBuildSampleFolder()                     */
/*                                                                      */
/*  - build a full pathname for filename placing it in the demo         */
/*    directory                                                         */
/*                                                                      */
/*======================================================================*/
void gseBuildSampleFolder(char *fullpath,char *filename)
{
  char homedir[255];

  strcpy(homedir,getenv("DB2PATH"));
#ifdef _NOW32OS
  sprintf(fullpath,"%s/samples/extenders/spatial/data/%s",homedir,filename);
#else
  sprintf(fullpath,"%s\\samples\\extenders\\spatial\\data\\%s",homedir,filename);
#endif
}


/*======================================================================*/
/*                                                                      */
/*                           gseBuildTempFolder()                       */
/*                                                                      */
/*  - build a full pathname for filename placing it in the demo temp    */
/*    directory                                                         */
/*                                                                      */
/*======================================================================*/
void gseBuildTempFolder(char *fullpath,char *filename)
{
  char homedir[255];
  char *tempdir;

#ifdef _NOW32OS
  tempdir = (char *)getenv("DEMO_TMPDIR");
  if (tempdir == NULL)
     tempdir = "/tmp";
  sprintf(fullpath,"%s/%s",tempdir, filename);
#else
  strcpy(homedir,getenv("DB2PATH"));
  sprintf(fullpath,"%s\\samples\\extenders\\spatial\\%s",homedir,filename);
#endif
}



/*======================================================================*/
/*                                                                      */
/*                           stEnableDB()                               */
/*                                                                      */
/* - enable the database with an ST_enable_db stored procedure call     */
/*                                                                      */
/*======================================================================*/
int stEnableDB()
{
  SQLRETURN rc;
  SQLCHAR   createEnableProc[] =
  "CREATE PROCEDURE db2gse.my_enable_db ( "                \
       "IN   tableCreationParameters VARCHAR(32672 OCTETS), "     \
       "OUT  msgCode                 INTEGER, "            \
       "OUT  msgText                 VARCHAR(1024 OCTETS)) "     \
     "SPECIFIC db2gse.my_EnableDB "                        \
     "MODIFIES SQL DATA "                                  \
     "NOT DETERMINISTIC "                                  \
     "CALLED ON NULL INPUT "                               \
     "LANGUAGE C "                                         \
     "EXTERNAL NAME 'db2gsead!ST_enable_db_ext' "          \
     "NOT FENCED "                                         \
     "THREADSAFE "                                         \
     "INHERIT SPECIAL REGISTERS "                          \
     "PARAMETER STYLE GENERAL WITH NULLS "                 \
     "PROGRAM TYPE SUB "                                   \
     "NO DBINFO ";
  SQLCHAR   callEnableDB[]   = "CALL db2gse.my_enable_db(?,?,?)";
  SQLCHAR   dropEnableProc[] = "DROP SPECIFIC PROCEDURE db2gse.my_EnableDB";

  char *tableCreateParameters = NULL;

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. drop the stored procedure - it should not exist
  rc = SQLExecDirect(hstmt, dropEnableProc, SQL_NTS);

  // 3. create the stored procedure
  rc = SQLExecDirect(hstmt, createEnableProc, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 4. prepare the call statement
  rc = SQLPrepare(hstmt, callEnableDB, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 5. bind the following 3 parameters to ST_enable_db:
  //    - table parameters (e.g. tablespace)
  //    - return code
  //    - reserved parameter (not used)
  ind[0] = (tableCreateParameters == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR,255, 0,tableCreateParameters,
                        256, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = 0;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = 0;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[2]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Enabling the database '%s' with spatial capability ...\
\n", dbase);
  fflush(stdout);

  // 6. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to enable the database '%s' with return \
code=%d text=%s\n\n", dbase, retCode, reserved);
  else
    printf("<========== Database '%s' is successfully enabled.\n\n", dbase);

  fflush(stdout);

  // 7. drop the stored procedure
  rc = SQLExecDirect(hstmt, dropEnableProc, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 8. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}


/*======================================================================*/
/*                                                                      */
/*                            stDisableDB()                             */
/*                                                                      */
/* - disable the database with an ST_disable_db stored procedure call   */
/*                                                                      */
/*======================================================================*/
int stDisableDB(short force)
{
  SQLRETURN       rc;
  SQLCHAR   callDisableDB[] = "call db2gse.ST_disable_db (?,?,?)";

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. prepare the statement
  rc = SQLPrepare(hstmt, callDisableDB, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 3. bind the following 3 parameters to ST_disable_db:
  //    - force switch
  //    - return code
  //    - reserved parameter (not used)
  ind[0] = (force == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_SHORT,
                        SQL_SMALLINT, 0, 0, &force, 2, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = 0;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = 0;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[2]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Disabling the spatial capability for database \
'%s' ...\n", dbase);
  fflush(stdout);

  // 4. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to disable the database '%s' with return \
code=%d text=%s\n\n", dbase, retCode, reserved);
  else
    printf("<========== Database '%s' is successfully disabled.\n\n",
           dbase);

  // 5. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                            stCreateCS()                             */
/*                                                                      */
/*   - Creates a new Coordinate System                                  */
/*                                                                      */
/*======================================================================*/
int stCreateCS (char *csName,char *definition,char *organization,int csID,
                char *description)
{
  SQLRETURN       rc;

  SQLCHAR   callCreateCS[]
    = "call db2gse.ST_create_coordsys (?,?,?,?,?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);
  rc = SQLPrepare(hstmt, callCreateCS, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, csName, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 2047, 0, definition, 2048, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = (organization == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, organization, 128, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = (csID == (int)NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &csID, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = (description == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 253, 0, description, 254, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = 0;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = 0;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[6]);
  CHECK_STMT(hstmt, rc);


  printf("==========> Creating a new coordinate system %s with id=%d ...\n",
         csName,csID);
  fflush(stdout);
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to create the coordinate system %s - id=%d \
with return code=%d text=%s\n\n",csName,csID, retCode, reserved);
  else
    printf("<========== The coordinate system %s - id=%d was created \
successfully.\n\n", csName,csID);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}


/*======================================================================*/
/*                                                                      */
/*                            stAlterCS()                               */
/*                                                                      */
/*   - Alters a  Coordinate System                                      */
/*                                                                      */
/*======================================================================*/
int stAlterCS (char *csName,char *definition,char *organization,int csID,
               char *description)
{
  SQLRETURN       rc;

  SQLCHAR   callAlterCS[]
    = "call db2gse.ST_alter_coordsys  (?,?,?,?,?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callAlterCS, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, csName, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = (definition == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 2047, 0, definition, 2048, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = (organization == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, organization, 128, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = (csID == (int)NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &csID, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = (description == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 253, 0, description, 254, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = 0;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = 0;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[6]);
  CHECK_STMT(hstmt, rc);


  printf("==========> Altering a coordinate system %s with id=%d ...\n",
         csName,csID);
  fflush(stdout);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to alter the coordinate system %s - id=%d \
with return code=%d text=%s\n\n",csName,csID, retCode, reserved);
  else
    printf("<========== The coordinate system %s - id=%d was successfully \
altered.\n\n", csName,csID);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}



/*======================================================================*/
/*                                                                      */
/*                            stDropCS()                               */
/*                                                                      */
/*   - Deletes a Coordinate System                                      */
/*                                                                      */
/*======================================================================*/
int stDropCS (char *csName)
{
  SQLRETURN       rc;

  SQLCHAR   callDropCS[]
    = "call db2gse.ST_drop_coordsys (?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callDropCS, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, csName, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = 0;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = 0;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[2]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Dropping coordinate system %s ...\n",csName);
  fflush(stdout);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to drop the coordinate system %s with return \
code=%d text=%s\n\n",csName, retCode, reserved);
  else
    printf("<========== The coordinate system %s was successfully dropped. \
\n\n", csName);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}



/*======================================================================*/
/*                                                                      */
/*                            stCreateSRS()                             */
/*                                                                      */
/*   - Creates a new Spatial Reference System                           */
/*                                                                      */
/*======================================================================*/
int stCreateSRS (char *srsName,int srsID,
                 double xOffset, double xScale, double yOffset, double yScale,
                 double zOffset, double zScale,
                 double mOffset, double mScale,
                 char *coordsysName,char *description)
{
  SQLRETURN       rc;

  SQLCHAR   callEnableSref[]
    = "call db2gse.ST_create_srs (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callEnableSref, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, srsName, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = 0;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &srsID, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;  // xOffset
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &xOffset, 4, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = 0;//xScale
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &xScale, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = SQL_NTS; //yOffset
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &yOffset, 4, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = SQL_NTS; //yScale
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &yScale, 4, &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = SQL_NTS; //zOffset
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &zOffset, 4, &ind[6]);
  CHECK_STMT(hstmt, rc);

  ind[7] =  SQL_NTS; //zScale
  rc = SQLBindParameter(hstmt, 8, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &zScale, 4, &ind[7]);
  CHECK_STMT(hstmt, rc);

  ind[8] = SQL_NTS; //mOffset
  rc = SQLBindParameter(hstmt, 9, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &mOffset, 4, &ind[8]);
  CHECK_STMT(hstmt, rc);

  ind[9] = SQL_NTS;//mScale
  rc = SQLBindParameter(hstmt, 10, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &mScale, 4, &ind[9]);
  CHECK_STMT(hstmt, rc);

  ind[10] = SQL_NTS; //coordsysName
  rc = SQLBindParameter(hstmt, 11, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, coordsysName, 128, &ind[10]);
  CHECK_STMT(hstmt, rc);

  ind[11] = (description == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 12, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 253, 0, description, 254, &ind[11]);
  CHECK_STMT(hstmt, rc);

  ind[12] = 0;
  rc = SQLBindParameter(hstmt, 13, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[12]);
  CHECK_STMT(hstmt, rc);

  ind[13] = 0;
  rc = SQLBindParameter(hstmt, 14, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[13]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Creating a new spatial reference system with id=%d ...\
\n",srsID);
  fflush(stdout);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to create the spatial reference system id=%d \
with return code=%d text=%s\n\n", srsID, retCode, reserved);
  else
    printf("<========== The spatial reference system id=%d was successfully \
created.\n\n", srsID);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}
/*======================================================================*/
/*                                                                      */
/*                            stAlterSRS()                             */
/*                                                                      */
/*   - Alters an existing Spatial Reference System                       */
/*                                                                      */
/*======================================================================*/
int stAlterSRS (char *srsName,int srsID,
                double xOffset, double xScale, double yOffset, double yScale,
                double zOffset, double zScale,
                double mOffset, double mScale,
                char *coordsysName,char *description)
{
  SQLRETURN       rc;

  SQLCHAR   callAlterSref[]
    = "call db2gse.ST_alter_srs (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callAlterSref, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, srsName, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = (srsID == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &srsID, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;  // xOffset
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &xOffset, 4, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = 0;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &xScale, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &yOffset, 4, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = SQL_NTS; //yScale
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &yScale, 4, &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = SQL_NTS; //zOffset
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &zOffset, 4, &ind[6]);
  CHECK_STMT(hstmt, rc);

  ind[7] = SQL_NTS; //zScale
  rc = SQLBindParameter(hstmt, 8, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &zScale, 4, &ind[7]);
  CHECK_STMT(hstmt, rc);

  ind[8] = SQL_NTS; //mOffset
  rc = SQLBindParameter(hstmt, 9, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &mOffset, 4, &ind[8]);
  CHECK_STMT(hstmt, rc);

  ind[9] = SQL_NTS;//mScale
  rc = SQLBindParameter(hstmt, 10, SQL_PARAM_INPUT, SQL_C_DOUBLE,
                        SQL_DOUBLE, 0, 0, &mScale, 4, &ind[9]);
  CHECK_STMT(hstmt, rc);

  ind[10] = (coordsysName == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 11, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, coordsysName, 128, &ind[10]);
  CHECK_STMT(hstmt, rc);

  ind[11] = (description == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 12, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 253, 0, description, 254, &ind[11]);
  CHECK_STMT(hstmt, rc);

  ind[12] = 0;
  rc = SQLBindParameter(hstmt, 13, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[12]);
  CHECK_STMT(hstmt, rc);

  ind[13] = 0;
  rc = SQLBindParameter(hstmt, 14, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[13]);
  CHECK_STMT(hstmt, rc);


  printf("==========> Creating a new spatial reference system with id=%d ...\
\n",srsID);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to create the spatial reference system id=%d \
with return code=%d text=%s\n\n", srsID, retCode, reserved);
  else
    printf("<========== The spatial reference system id=%d was successfully \
created.\n\n", srsID);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}



/*======================================================================*/
/*                                                                      */
/*                            stDropSRS()                              */
/*   - Deletes an existing Spatial Reference System                     */
/*                                                                      */
/*======================================================================*/
int stDropSRS(char *srsName)
{
  SQLRETURN       rc;

  SQLCHAR   callDisableSref[]
    = "call db2gse.ST_drop_srs (?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callDisableSref, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, srsName, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = 0;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = 0;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[2]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Dropping a spatial reference system with name %s ...\
\n",srsName);
  fflush(stdout);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to drop the spatial reference system %s with \
return code=%d test=%s\n\n", srsName, retCode, reserved);
  else
    printf("<========== The spatial reference system %s was successfully \
dropped.\n\n", srsName);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                            gseCreateLatLongGeocoder()                          */
/*                                                                      */
/*  (1) Create the UDF LatLongGeocoder.                                   */
/*                                                                      */
/*======================================================================*/
int gseCreateLatLongGeocoder()
{
  SQLRETURN       rc;

SQLCHAR   createGCUDF[]
  = "CREATE OR REPLACE FUNCTION db2se.LatLongGC(latitude double, longitude double, srs_id int) \
     RETURNS db2gse.ST_Point \
     SPECIFIC db2se.LatLongGC \
     LANGUAGE SQL \
     DETERMINISTIC \
     EXTERNAL ACTION \
     READS SQL DATA \
     RETURN TREAT(db2gse.ST_Point(longitude, latitude, 1)..st_transform(srs_id) AS db2gse.ST_Point)";
     
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  printf("---------------> Creating the geocoder UDF...\n");
  fflush(stdout);

  rc = SQLExecDirect(hstmt, createGCUDF, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to create the geocoder UDF.\n");
  } else {
    printf("<--------------- The geocoder UDF was successfully created.\n");
  };	 

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;	 
}
	
/*======================================================================*/
/*                                                                      */
/*                            gseSetupTables()                          */
/*                                                                      */
/*  (1) Create the "customers" table.                                   */
/*  (2) Populate the "customers" table.                                 */
/*  (3) Alter the "customers" table by adding the "location" column.    */
/*  (4) Create the "offices" table                                      */
/*                                                                      */
/*======================================================================*/
int gseSetupTables()
{
  SQLRETURN       rc;
  char datafile[256];
  char msgfile[256];
  char tmpbuf[100];
  time_t xtime;
  struct sqldcol dataDescriptor;  
  struct sqllob *pColumnString;
  char impStatement[] = "INSERT INTO CUSTOMERS";
  char fileType[] = SQL_DEL;
  db2ImportStruct importStruct;
  db2ImportIn importInput;
  db2ImportOut importOutput;


  SQLCHAR   createOffices[]
    = "CREATE TABLE OFFICES ( \
        NAME CHAR(16) , \
        EMPLOYEES BIGINT , \
        ID BIGINT , \
        LOCATION  DB2GSE.ST_POINT ) organize by row";

  SQLCHAR   createCustomers[]
    = "CREATE TABLE CUSTOMERS \
        (ID INTEGER, \
        NAME VARCHAR(30), \
        ADDRESS VARCHAR(30), \
        CITY    VARCHAR(28), \
        STATE VARCHAR(2), \
        ZIP VARCHAR(5), \
        INCOME FLOAT, \
        PREMIUM FLOAT, \
        CATEGORY SMALLINT, \
        LATITUDE DOUBLE, \
        LONGITUDE DOUBLE \
        ) organize by row";


  SQLCHAR   alterCustomers[]
    = "ALTER TABLE CUSTOMERS ADD COLUMN LOCATION DB2GSE.ST_POINT";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  printf("==========> Setting up tables ...\n");

  printf("---------------> Creating the 'customers' table ...\n");
  fflush(stdout);

  rc = SQLExecDirect(hstmt, createCustomers, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to create the 'customers' table.\n");
    goto exit;
  }

  printf("<--------------- The 'customers' table was successfully created.\
         \n");

  printf("---------------> Populating the 'customers' table ...\n");

  /* setup the load-file information ('customers.data') */
  strcpy(datafile,getenv("DB2PATH"));
#ifdef _NOW32OS
  strcat(datafile,"/samples/extenders/spatial/customers.data");
#else
  strcat(datafile,"\\samples\\extenders\\spatial\\customers.data");
#endif

  time(&xtime);
  /*---------------------------------------------------------------*/
  sprintf(tmpbuf,"loadCust.log_%i",xtime);
  gseBuildTempFolder(msgfile,tmpbuf);

  printf("  Load from: %s\n", datafile);
  printf("  Logfile: %s\n", msgfile);

  /* setup data descriptor */
  /* Map columns in load-file 1:1 to columns in table */
  dataDescriptor.dcolmeth = SQL_METH_D;

  /* need to allocate the proper amount of space for the impStatement */
  pColumnString = (struct sqllob *)malloc(MAX_STMT_LEN
                                           + sizeof(struct sqllob));

  pColumnString->length = strlen(impStatement);
  strncpy (pColumnString->data, impStatement, strlen(impStatement));
  
  memset(&importStruct,0,sizeof(importStruct));
  memset(&importInput,0,sizeof(importInput));
  memset(&importOutput,0,sizeof(importOutput));
  
  importStruct.piDataFileName = datafile;
  importStruct.piDataDescriptor = &dataDescriptor;
  importStruct.piFileType = fileType;
  importStruct.piMsgFileName = msgfile;
  importStruct.iCallerAction = SQLU_INITIAL;
  importStruct.piImportInfoIn = &importInput;
  importStruct.poImportInfoOut = &importOutput;
  importStruct.piLongActionString= pColumnString;

  /* / do the IMPORT */
  rc = db2Import(SQL_REL9702,
                 &importStruct,
		 &sqlca);


  if (rc != SQL_ERROR && rc != SQL_INVALID_HANDLE)
  {
    printf("          %d rows read, %d rows committed.\n",
                 importOutput.oRowsRead, importOutput.oRowsCommitted);
    if(importOutput.oRowsCommitted > 0 &&
               importOutput.oRowsCommitted == importOutput.oRowsRead)
       printf("<--------------- The 'customers' table was successfully \
populated.\n");
    else
    {
       printf("     **Check that the logfile directory exists and has write permissions.\n");
       rc = SQL_ERROR;
    }
  }

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to populate the 'customers' table.\n");
    goto exit;
  }


  printf("---------------> Adding the 'location' column to the 'customers' \
table ...\n");

  rc = SQLExecDirect(hstmt, alterCustomers, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to add the 'location' column to the \
'customers' table.\n");
    goto exit;
  }
  printf("<--------------- The 'location' column of the 'customers' table \
was successfully added.\n");

  printf("---------------> Creating the 'offices' table ...\n");

  rc = SQLExecDirect(hstmt, createOffices, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to create the 'offices' table.\n");
    goto exit;
  }
  printf("<--------------- The 'offices' table was successfully created.\n");

 exit:
  retCode = rc;

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
    printf("<========== Failed to set up tables with return code=%d.\n\n",
           rc);
  else
    printf("<========== Tables were successfully set up.\n\n");

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}


/*======================================================================*/
/*                                                                      */
/*                            stRegisterGc()                            */
/*                                                                      */
/* - register the geocoder with an ST_register_geocoder stored          */
/*   procedure call                                                     */
/*                                                                      */
/*                                                                      */
/*======================================================================*/
int stRegisterGc   (char *gcName,char *functionSchema,char *functionName,
                    char *specificName,char *ParValues,
                    char *ParDescription, char *vendor, char *description)
{
  SQLRETURN       rc;
  char parameterValues[1000];
  char parameterDescription[1000];

  SQLCHAR   callRegisterGc[]
    = "call db2gse.ST_register_geocoder (?,?,?,?,?,?,?,?,?,?)";

  if(ParValues)
    strcpy(parameterValues,ParValues);

  if(ParDescription)
    strcpy(parameterDescription,ParDescription);

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. prepare the statement
  rc = SQLPrepare(hstmt, callRegisterGc, SQL_NTS);
  CHECK_STMT(hstmt, rc);


  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 129, 0, gcName, 130, &ind[0]);
  CHECK_STMT(hstmt, rc);

  // 3. bind the following 10 parameters to ST_register_geocoder:
  //    - @param  geocoder name
  //    - @param  function schema
  //    - @param  function name
  //    - @param  specific name
  //    - @param  default parameter values
  //    - @param  parameter descriptions
  //    - @param  vendor
  //    - @param  description
  //    - @return message code
  //    - @return message text
  ind[1] = (functionSchema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 129, 0, functionSchema, 130, &ind[1]);
  CHECK_STMT(hstmt, rc);


  ind[2] = (functionName == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 129, 0, functionName, 130, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = (specificName == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 129, 0, specificName, 130, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = (ParValues == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(parameterValues)-1), 0,
                        parameterValues, sizeof(parameterValues), &ind[4]);

  ind[5] = (ParDescription == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(parameterDescription)-1), 0,
                        parameterValues, sizeof(parameterValues), &ind[5]);

  ind[6] = (vendor == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 253, 0, vendor, 254, &ind[6]);
  CHECK_STMT(hstmt, rc);

  ind[7] = (description == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 8, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 256, 0, description, 256, &ind[7]);
  CHECK_STMT(hstmt, rc);

  ind[8] = 0;
  rc = SQLBindParameter(hstmt, 9, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[8]);
  CHECK_STMT(hstmt, rc);

  ind[9] = 0;
  rc = SQLBindParameter(hstmt, 10, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[9]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Registering a new geocoder %s ...\n", gcName);
  fflush(stdout);

  // 4. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to register the geocoder %s with return \
code=%d text=%s\n\n", gcName, retCode, reserved);
  else
    printf("<========== The geocoder %s was successfully registered.\n\n",
           gcName);

  // 5. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                            stUnregisterGc()                         */
/*                                                                      */
/*======================================================================*/
int stUnregisterGc(char *gcName)
{
  SQLRETURN       rc;

  SQLCHAR   callUnregisterGc[]
    = "call db2gse.ST_unregister_geocoder (?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callUnregisterGc, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 129, 0, gcName, 130, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = 0;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = 0;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[9]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Unregistering a geocoder %s ...\n", gcName);
  fflush(stdout);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to unregister the geocoder %s with return \
code=%d text=%s\n\n", gcName, retCode, reserved);
  else
    printf("<========== The geocoder %s was successfully unregistered\n\n",
           gcName);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                       stRegisterSpatialColumn()                      */
/*                                                                      */
/* - register a spatial column with an ST_register_spatial_column       */
/*   stored procedure call                                              */
/*                                                                      */
/*======================================================================*/
int stRegisterSpatialColumn(char *sourceschema, char *sourcetable,
                            char *sourcecolumn,     char *srsName)
{
  SQLRETURN       rc;
  SQLCHAR   callRegisterSpatialColumn[]
    = "call db2gse.ST_register_spatial_column(?,?,?,?,?,?)";

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. prepare the statement
  rc = SQLPrepare(hstmt, callRegisterSpatialColumn, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 3. bind the following 6 parameters to ST_resgister_spatial_column:
  //    - schema name
  //    - table name
  //    - column name
  //    - spatial reference system name
  //    - return code
  //    - reserved parameter (not used)
  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourceschema, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcetable, 128, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcecolumn, 128, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT,  SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, srsName, 128, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = 0;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = 0;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[5]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Registering a new spatial column for \
'%s.%s' ...\n", sourcetable, sourcecolumn);
  fflush(stdout);

  // 4. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to register the spatial column with return \
code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== The spatial column for table.column '%s.%s' was \
successfully registered.\n\n", sourcetable, sourcecolumn);

  // 5. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}


/*======================================================================*/
/*                                                                      */
/*                            stSetupGeocoding()                        */
/*                                                                      */
/*   - Setup the geocoder for a column/table with an ST_setup_geocoding */
/*      stored procedure call                                           */
/*                                                                      */
/*======================================================================*/
int stSetupGeocoding(char *sourceschema,
                     char *sourcetable,
                     char *sourcecolumn,
                     char *geocoderName,
                     char *ParValues,
                     char *AutoGCValue,
                     char *WhereClause,
                     int   commitscope)
{
  SQLRETURN       rc;

  SQLCHAR   callSetupGeocoding[]
    = "call db2gse.ST_setup_geocoding(?,?,?,?,?,?,?,?,?,?)";

  char parameterValues[1000]={'\0'};
  char autoGCValue[1000]={'\0'};

  if(ParValues)
    strcpy(parameterValues,ParValues);

  if(AutoGCValue)
    strcpy(autoGCValue,AutoGCValue);

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. prepare the statement
  rc = SQLPrepare(hstmt, callSetupGeocoding, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 3. bind the following 10 parameters to ST_setup_geocoding:
  //    - schema name
  //    - table name
  //    - column name
  //    - geocoder name
  //    - geocoder parameters
  //    - autogeocoding switch
  //    - where clause
  //    - commit scope
  //    - return code
  //    - reserved parameter (not used)
  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourceschema, 129, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcetable, 129, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcecolumn, 129, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, geocoderName, 129, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = (ParValues == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(parameterValues)-1), 0,
                        parameterValues, sizeof(parameterValues), &ind[4]);

  ind[5] = (AutoGCValue == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(autoGCValue)-1), 0, autoGCValue,
                        sizeof(autoGCValue), &ind[5]);

  ind[6] = (WhereClause == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 255, 0, WhereClause, 256, &ind[6]);

  ind[7] = (commitscope == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 8, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &commitscope, 4, &ind[7]);
  CHECK_STMT(hstmt, rc);

  ind[8] = 0;
  rc = SQLBindParameter(hstmt, 9, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[8]);
  CHECK_STMT(hstmt, rc);

  ind[9] = 0;
  rc = SQLBindParameter(hstmt, 10, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[9]);
  CHECK_STMT(hstmt, rc);


  printf("==========> Associating geocoder with spatial column \
table.column '%s.%s' ...\n", sourcetable, sourcecolumn);
  fflush(stdout);

  // 4. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to Setup Geocoder for spatial column \
with return code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== Geocoder is sucessfully setup for spatial column \
table.column '%s.%s'.\n\n", sourcetable, sourcecolumn);

  // 5. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                            stRemoveGeocodingSetup                    */
/*                                                                      */
/* - remove the geocoding setup with an ST_remove_geocoding_setup       */
/*   stored procedure call                                              */
/*                                                                      */
/*                                                                      */
/*======================================================================*/
int stRemoveGeocodingSetup(char *sourceschema, char *sourcetable,
                           char *sourcecolumn)
{
  SQLRETURN       rc;

  SQLCHAR   callRemoveGeocodingSetup[]
    = "call db2gse.ST_remove_geocoding_setup(?,?,?,?,?)";

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. prepare the statement
  rc = SQLPrepare(hstmt, callRemoveGeocodingSetup, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 3. bind the following 5 parameters to ST_remove_geocoding_setup:
  //    - @param table schema
  //    - @param table name
  //    - @param column name
  //    - @return message code
  //    - @return message text
  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourceschema, 129, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcetable, 129, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcecolumn, 129, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = 0;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[8]);
  CHECK_STMT(hstmt, rc);

  ind[4] = 0;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[9]);
  CHECK_STMT(hstmt, rc);


  printf("==========> Removing Geocoding Setup from table.column '%s.%s' \
...\n", sourcetable, sourcecolumn);
  fflush(stdout);

  // 4. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to remove Geocoder setup in the spatial \
column with return code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== Geocoder setup was sucessfully removed from \
column and table.column '%s.%s'.\n\n", sourcetable, sourcecolumn);

  // 5. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                            stUnregisterSpatialColumn()               */
/*                                                                      */
/* - unregister a spatial column with an ST_unregister_spatial_column   */
/*   stored procedure call                                              */
/*                                                                      */
/*======================================================================*/
int stUnregisterSpatialColumn(char *sourceschema, char *sourcetable,
                              char *sourcecolumn)
{
  SQLRETURN       rc;
  SQLCHAR   callUnregistSpatialColumn[]
    = "call db2gse.ST_unregister_spatial_column (?,?,?,?,?)";

  // 1. allocate the statement handle
  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  // 2. prepare the statement
  rc = SQLPrepare(hstmt, callUnregistSpatialColumn, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  // 3. bind the following 5 parameters to ST_unregister_spatial_column:
  //    - schema name
  //    - table name
  //    - column name
  //    - return code
  //    - reserved parameter (not used)
  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 30, 0, sourceschema, 31, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcetable, 129, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcecolumn, 129, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = 0;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = 0;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[4]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Unregistering a spatial column for table.column '%s.%s'\
...\n", sourcetable, sourcecolumn);
  fflush(stdout);

  // 4. execute the statement
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to unregister the spatial column with return \
code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== The spatial column for table.column '%s.%s' was \
successfully unregistered.\n\n", sourcetable, sourcecolumn);

  // 5. free the statement handle
  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                               stRunGC()                             */
/*                                                                      */
/*======================================================================*/
int stRunGC(char *sourceschema, char *sourcetable, char *sourcecolumn,
            char *geocoderName,
            char *ParValues,
            char *whereclause,
            int   commitscope)
{
  SQLRETURN       rc;

  SQLCHAR   callRunGC[]
    = "call db2gse.ST_run_geocoding (?,?,?,?,?,?,?,?,?)";

  char parameterValues[1000];

  if(ParValues)
    strcpy(parameterValues,ParValues);

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callRunGC, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 30, 0, sourceschema, 31, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcetable, 129, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, sourcecolumn, 129, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, geocoderName, 129, &ind[3]);
  CHECK_STMT(hstmt, rc);


  ind[4] = (ParValues == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(parameterValues)-1), 0,
                        parameterValues, sizeof(parameterValues), &ind[4]);

  ind[5] = (whereclause == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 256, 0, whereclause, 256, &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = (commitscope == (int)NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &commitscope, 4, &ind[6]);
  CHECK_STMT(hstmt, rc);

  ind[7] = 0;
  rc = SQLBindParameter(hstmt, 8, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[7]);
  CHECK_STMT(hstmt, rc);

  ind[8] = 0;
  rc = SQLBindParameter(hstmt, 9, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[8]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Running the geocoder %s for spatial column: \
'%s.%s' ...\n",geocoderName, sourcetable, sourcecolumn);
  fflush(stdout);

  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to geocode the spatial column with return \
code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== The spatial column '%s.%s' is successfully geocoded.\
\n\n", sourcetable, sourcecolumn);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}
/*======================================================================*/
/*                                                                      */
/*                            stImportShape()                          */
/*                                                                      */
/*======================================================================*/
int stImportShape(char *path,char *InputAttColumns,char *srsName,
                  char *sourceschema,char *sourcetable,
                  char *TableAttColumns, int createTableFlag,
                  char *TableCreationParameters,char *sourcecolumn,
                  char *typeSchema,char *typeName,int inlineLength,
                  char *identityColumn,int idColumnIsIdentity,
                  int restartCount, int commitscope,
                  char *exceptionFile,char *messageFile)
{
  SQLRETURN       rc;
  char inputAttColumns[1000];
  char tableAttColumns[1000];
  char tableCreationParameters[1000];

  SQLCHAR   callImportShape[]
    = "call db2gse.ST_import_shape(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

  if(InputAttColumns)
    strcpy(inputAttColumns,InputAttColumns);

  if(TableAttColumns)
    strcpy(tableAttColumns,TableAttColumns);

  if(TableCreationParameters)
    strcpy(tableCreationParameters,TableCreationParameters);

  printf("  Logfile: %s\n", messageFile);

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callImportShape, SQL_NTS);
  CHECK_STMT(hstmt, rc);


  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 128, 0, path, 129, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = (InputAttColumns == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, sizeof(inputAttColumns)-1, 0,
                        inputAttColumns, sizeof(inputAttColumns), &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, srsName, 128, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourceschema, 128, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcetable, 128, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = (TableAttColumns == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, sizeof(tableAttColumns)-1, 0,
                        tableAttColumns, sizeof(tableAttColumns), &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = (createTableFlag == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &createTableFlag, 4, &ind[6]);
  CHECK_STMT(hstmt, rc);

  ind[7] = (TableCreationParameters == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 8, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, sizeof(tableCreationParameters)-1, 0,
                        tableCreationParameters,
                        sizeof(tableCreationParameters), &ind[7]);
  CHECK_STMT(hstmt, rc);

  ind[8] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 9, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcecolumn, 128, &ind[8]);
  CHECK_STMT(hstmt, rc);

  ind[9] = (typeSchema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 10, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, typeSchema, 128, &ind[9]);
  CHECK_STMT(hstmt, rc);

  ind[10] = (typeName == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 11, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, typeName, 128, &ind[10]);
  CHECK_STMT(hstmt, rc);

  ind[11] = (inlineLength == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 12, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &inlineLength, 4, &ind[11]);
  CHECK_STMT(hstmt, rc);

  ind[12] = (identityColumn == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 13, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, identityColumn, 128, &ind[12]);
  CHECK_STMT(hstmt, rc);

  ind[13] = (idColumnIsIdentity == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 14, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &idColumnIsIdentity, 4, &ind[13]);
  CHECK_STMT(hstmt, rc);

  ind[14] = (restartCount == -1) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 15, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &restartCount, 4, &ind[14]);
  CHECK_STMT(hstmt, rc);

  ind[15] = (commitscope == -1) ? SQL_NULL_DATA : SQL_NTS;;
  rc = SQLBindParameter(hstmt, 16, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &commitscope, 4, &ind[15]);
  CHECK_STMT(hstmt, rc);

  ind[16] = (exceptionFile == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 17, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 255, 0, exceptionFile, 256, &ind[16]);
  CHECK_STMT(hstmt, rc);

  ind[17] = (messageFile == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 18, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 255, 0, messageFile, 256, &ind[17]);
  CHECK_STMT(hstmt, rc);

  ind[18] = 0;
  rc = SQLBindParameter(hstmt, 19, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[18]);
  CHECK_STMT(hstmt, rc);

  ind[19] = 0;
  rc = SQLBindParameter(hstmt, 20, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[19]);
  CHECK_STMT(hstmt, rc);

  printf("\n==========> Importing the shape file '%s' ...\n", path);
  fflush(stdout);
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to import the shape file '%s' with return \
code=%d text=%s\n\n", path, retCode, reserved);
  else
    printf("<========== The shape file '%s' was successfully imported\n\n",
           path);

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;

}


/*======================================================================*/
/*                                                                      */
/*                            gseCLICreateIndex()                       */
/*                                                                      */
/*  - Create INDEX on sourcetable.sourcecolumn                          */
/*                                                                      */
/*======================================================================*/
int gseCLICreateIndex(char *sourcetable, char *sourcecolumn,
                      char *indexname,
                      char *gridSizes)
{
  SQLRETURN       rc=0;
  char EnableIDXBuffer[255];


  SQLCHAR   CreateIndex[]
    = "CREATE INDEX ? ON ?(?) EXTEND USING DB2GSE.SPATIAL_INDEX (?,?,?)";

  sprintf(EnableIDXBuffer,"CREATE INDEX %s ON %s(%s) EXTEND USING \
db2gse.spatial_index(%s)",
          indexname,sourcetable,sourcecolumn,gridSizes);

  printf("%s\n\n",EnableIDXBuffer);

  /* allocate a statement handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt) ;
  DBC_HANDLE_CHECK(hdbc, rc);

  rc = SQLExecDirect( hstmt, (SQLCHAR *) EnableIDXBuffer, SQL_NTS ) ;
  STMT_HANDLE_CHECK( hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
    printf("<========== Failed to create spatial index \n");
  else
    printf("<========== The spatial index was successfully created\n\n");

  /* free the statement handle */
  rc = SQLFreeHandle( SQL_HANDLE_STMT, hstmt ) ;
  STMT_HANDLE_CHECK( hstmt, rc);

  return rc;
}

/*======================================================================*/
/*                                                                      */
/*                            gseCLIDropIndex()                         */
/*                                                                      */
/*  - Drop INDEX indexname                                              */
/*                                                                      */
/*======================================================================*/
int gseCLIDropIndex(char *indexname)
{
  SQLRETURN       rc=0;
  char DropIDXBuffer[255];

  sprintf(DropIDXBuffer,"DROP INDEX %s",indexname);
  printf("%s\n\n",DropIDXBuffer);

  /* allocate a statement handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt) ;
  DBC_HANDLE_CHECK(hdbc, rc);


  rc = SQLExecDirect( hstmt, (SQLCHAR *) DropIDXBuffer, SQL_NTS ) ;
  STMT_HANDLE_CHECK( hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
    printf("<========== Failed to drop spatial index \n");
  else
    printf("<========== The spatial index was successfully removed\n\n");

  /* free the statement handle */
  rc = SQLFreeHandle( SQL_HANDLE_STMT, hstmt ) ;
  STMT_HANDLE_CHECK( hstmt, rc);

  return rc;
}

/*======================================================================*/
/*                                                                      */
/*                         stEnableAutoGC()                             */
/*                                                                      */
/*                                                                      */
/*======================================================================*/
int stEnableAutoGC(char *sourceschema, char *sourcetable, char *sourcecolumn)
{
  SQLRETURN       rc;

  SQLCHAR   callEnableAutoGc[]
    = "call db2gse.ST_enable_autogeocoding (?,?,?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callEnableAutoGc, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourceschema, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcetable, 128, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcecolumn, 128, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = 0;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = 0;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[4]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Enabling automatic geocoder ...\n");
  fflush(stdout);
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to enable automatic geocoder with return \
code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== The automatic geocoder is successfully enabled\n\n");

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}


/*======================================================================*/
/*                                                                      */
/*                            gseInsDelUpd()                            */
/*                                                                      */
/*======================================================================*/
int gseInsDelUpd()
{
  SQLRETURN       rc;

  SQLCHAR   insertCustomers[]
    = "INSERT INTO CUSTOMERS(ID, NAME, ADDRESS, CITY, STATE, ZIP, INCOME, PREMIUM, CATEGORY, LATITUDE, LONGITUDE) \
        VALUES(999999, 'NEW CUSTOMER', \
        '2000 AVON CIRCLE', \
        'RADCLIFF', 'KY', '40160', \
	72000, 1300, 6, \
        37.82, -85.96)";

  SQLCHAR   deleteCustomers[]
    = "DELETE FROM CUSTOMERS WHERE ID >=  81000 AND ID <= 140000";

  SQLCHAR   updateCustomers[]
    = "UPDATE CUSTOMERS SET (LATITUDE, LONGITUDE) = (37.82, -85.96)  WHERE ID >= 140000";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  printf("==========> Inserts, updates, and deletes on the 'customers' \
table ...\n");
  fflush(stdout);

  printf("---------------> Inserting tuples into the 'customers' table ...\
\n");

  rc = SQLExecDirect(hstmt, insertCustomers, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to insert into the 'customers' table.\n");
    goto exit;
  }

  printf("<--------------- Inserts to 'customers' table successful.\n");

  rc = SQLTransact(henv, hdbc, SQL_COMMIT);

  printf("---------------> Updating the 'customers' table ...\n");

  rc = SQLExecDirect(hstmt, updateCustomers, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to update the 'customers' table.\n");
    goto exit;
  }

  printf("<--------------- Updates to 'customers' table successful.\n");

  rc = SQLTransact(henv, hdbc, SQL_COMMIT);

  printf("---------------> Deleting from the 'customers' table ...\n");

  rc = SQLExecDirect(hstmt, deleteCustomers, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
  {
    printf("<--------------- Failed to delete from the 'customers' table.\n");
    goto exit;
  }

  printf("<--------------- Deletes from 'customers' table successful.\
\n");

  rc = SQLTransact(henv, hdbc, SQL_COMMIT);

 exit:

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
    printf("\n<========== Insert, update, or delete failed \
with return code %d.\n\n", rc);
  else
    printf("<========== Inserts, updates and deletes on the 'customers' table \
were successful.\n\n");

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return rc;
}
/*======================================================================*/
/*                                                                      */
/*                         stDisableAutoGc()                           */
/*                                                                      */
/*======================================================================*/
int stDisableAutoGc(char *sourceschema, char *sourcetable,
                    char *sourcecolumn)
{
  SQLRETURN       rc;

  SQLCHAR   callDisableAutoGc[]
    = "call db2gse.ST_disable_autogeocoding (?,?,?,?,?)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callDisableAutoGc, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = (sourceschema == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourceschema, 128, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcetable, 128, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 127, 0, sourcecolumn, 128, &ind[2]);
  CHECK_STMT(hstmt, rc);

  ind[3] = 0;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = 0;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[4]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Disabling automatic geocoder ...\n");
  fflush(stdout);
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to disable automatic geocoder with return \
code=%d text=%s\n\n", retCode,reserved);
  else
    printf("<========== The automatic geocoder was successfully disabled \
\n\n");

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}

/*======================================================================*/
/*                                                                      */
/*                            gseCreateView()                           */
/*                                                                      */
/*   Create a view HIGHRISKCUSTOMERS representing a spatial join with   */
/*   a join predicate ST_WITHIN(GEOM1, GEOM2).                          */
/*                                                                      */
/*======================================================================*/
int gseCreateView()
{
  SQLRETURN       rc;

  SQLCHAR   createView[]
    = "CREATE VIEW HIGHRISKCUSTOMERS (ID, NAME, ADDRESS, CITY, STATE, ZIP, \
        INCOME, PREMIUM, CATEGORY, LOCATION) \
        AS (SELECT C.ID, C.NAME, C.ADDRESS, C.CITY, C.STATE, C.ZIP, \
        C.INCOME, C.PREMIUM, C.CATEGORY, C.LOCATION \
        FROM CUSTOMERS C, FLOODZONES F \
        WHERE DB2GSE.ST_WITHIN(C.LOCATION, F.LOCATION) = 1)";

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  printf("==========> Creating the 'highRiskCustomers' view ...\n");
  fflush(stdout);

  rc = SQLExecDirect(hstmt, createView, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  if (rc == SQL_ERROR || rc == SQL_INVALID_HANDLE)
    printf("<========== Failed to create the 'highRiskCustomers' view with \
return code %d.\n\n", rc);
  else
    printf("<========== The 'highRiskCustomers' view was successfully \
created.\n\n");

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return rc;
}


/*======================================================================*/
/*                                                                      */
/*                            stExportShape()                           */
/*                                                                      */
/*======================================================================*/
int stExportShape(char *fileName,int appendFlag,char *OutputColumnNames,
                  char *SelectStatement,char *messagesFile)
{
  SQLRETURN       rc;
  char outputColumnNames[1000];
  char selectStatement[1000];

  SQLCHAR   callExportShape[]
    = "call db2gse.ST_export_shape (?,?,?,?,?,?,?)";

  if(OutputColumnNames)
    strcpy(outputColumnNames,OutputColumnNames);

  if(SelectStatement)
    strcpy(selectStatement,SelectStatement);

  rc = SQLAllocHandle(SQL_HANDLE_STMT,hdbc, &hstmt);
  CHECK_DBC(hdbc, rc);

  rc = SQLPrepare(hstmt, callExportShape, SQL_NTS);
  CHECK_STMT(hstmt, rc);

  ind[0] = SQL_NTS;
  rc = SQLBindParameter(hstmt, 1, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 255, 0, fileName, 256, &ind[0]);
  CHECK_STMT(hstmt, rc);

  ind[1] = (appendFlag == -1) ? SQL_NULL_DATA : SQL_NTS;;
  rc = SQLBindParameter(hstmt, 2, SQL_PARAM_INPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &appendFlag, 4, &ind[1]);
  CHECK_STMT(hstmt, rc);

  ind[2] = (OutputColumnNames == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 3, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, sizeof(outputColumnNames)-1, 0,
                        outputColumnNames, sizeof(outputColumnNames),
                        &ind[2]);
  CHECK_STMT(hstmt, rc);


  ind[3] = (SelectStatement == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 4, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, sizeof(selectStatement)-1, 0,
                        selectStatement, sizeof(selectStatement), &ind[3]);
  CHECK_STMT(hstmt, rc);

  ind[4] = (messagesFile == NULL) ? SQL_NULL_DATA : SQL_NTS;
  rc = SQLBindParameter(hstmt, 5, SQL_PARAM_INPUT, SQL_C_CHAR,
                        SQL_VARCHAR, 255, 0, messagesFile, 256, &ind[4]);
  CHECK_STMT(hstmt, rc);

  ind[5] = 0;
  rc = SQLBindParameter(hstmt, 6, SQL_PARAM_OUTPUT, SQL_C_LONG,
                        SQL_INTEGER, 0, 0, &retCode, 4, &ind[5]);
  CHECK_STMT(hstmt, rc);

  ind[6] = 0;
  rc = SQLBindParameter(hstmt, 7, SQL_PARAM_OUTPUT, SQL_C_CHAR,
                        SQL_VARCHAR, (sizeof(reserved)-1), 0, reserved,
                        sizeof(reserved), &ind[6]);
  CHECK_STMT(hstmt, rc);

  printf("==========> Exporting spatial column and data ...\n");
  fflush(stdout);
  rc = SQLExecute(hstmt);
  CHECK_STMT(hstmt, rc);

  if (retCode != 0)
    printf("<========== Failed to export spatial column with return \
code=%d test=%s\n\n", retCode,reserved);
  else
    printf("<========== The spatial column was successfully exported\n\n");

  rc = SQLFreeHandle(SQL_HANDLE_STMT,hstmt);
  CHECK_STMT(hstmt, rc);

  return retCode;
}
/*======================================================================*/
/*                                                                      */
/*                     gseRunSpatialQueries()                           */
/*                                                                      */
/*======================================================================*/
int gseRunSpatialQueries(SQLHANDLE hdbc, char *queryStmt, char * queryTxt)
{
  SQLRETURN   sqlrc = SQL_SUCCESS;
  SQLINTEGER  rc = 0;
  SQLHANDLE   hstmt ;

  SQLSMALLINT i;
  SQLSMALLINT nResultCols;

  SQLCHAR     colName[32];
  SQLSMALLINT colNameLen;
  SQLSMALLINT colType;
  SQLUINTEGER colSize;
  SQLSMALLINT colScale;

  SQLINTEGER colDataDisplaySize;
  SQLINTEGER colDisplaySize[MAX_COLUMNS];

  struct
  {
    SQLCHAR    *buff;
    SQLINTEGER  len;
    SQLINTEGER  buffLen;
  } outData[MAX_COLUMNS]; /* var. to read the results */

  int rows_found = 0;

  /* allocate a statement handle */
  sqlrc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt) ;
  DBC_HANDLE_CHECK(hdbc, sqlrc);

  printf("=============== RUNNING SPATIAL QUERY ================\n");
  /* execute directly the statement */
  printf("%s.\n", queryStmt);
  printf("\n%s\n", queryTxt);
  sqlrc = SQLExecDirect( hstmt, (SQLCHAR *) queryStmt, SQL_NTS ) ;
  STMT_HANDLE_CHECK( hstmt, sqlrc);


  /*"    Identify the output columns, then \n"*/
  /*"    fetch each row and display.\n"*/
  sqlrc = SQLNumResultCols( hstmt, &nResultCols ) ;
  STMT_HANDLE_CHECK( hstmt, sqlrc);

  printf("\n ");

  for ( i = 0; i < nResultCols; i++ )
  {
    sqlrc = SQLDescribeCol( hstmt,
                            ( SQLSMALLINT ) ( i + 1 ),
                            colName,
                            sizeof(colName),
                            &colNameLen,
                            &colType,
                            &colSize,
                            &colScale,
                            NULL ) ;
    STMT_HANDLE_CHECK( hstmt, sqlrc);

    /* get display size for column */
    sqlrc = SQLColAttribute( hstmt,
                             ( SQLSMALLINT ) ( i + 1 ),
                             SQL_DESC_DISPLAY_SIZE,
                             NULL,
                             0,
                             NULL,
                             &colDataDisplaySize ) ;
    STMT_HANDLE_CHECK( hstmt, sqlrc);

    /* set "column display size" to max of "column data display size",
       and "column name length". Plus at least one space between
       columns.
    */
    colDisplaySize[i] = max(colDataDisplaySize, colNameLen) + 1 ;

    /* print the column name */
    printf( "%-*.*s",
            (int) colDisplaySize[i],
            (int) colDisplaySize[i],
            colName ) ;

    /* set "output data buffer length" to "column data display size".
       Plus one byte for null terminator.
    */
    outData[i].buffLen = colDataDisplaySize + 1;

    /* allocate memory to bind column */
    outData[i].buff = ( SQLCHAR * ) malloc( (int) outData[i].buffLen ) ;

    /* bind columns to program vars, converting all types to CHAR */
    sqlrc = SQLBindCol( hstmt,
                        ( SQLSMALLINT ) ( i + 1 ),
                        SQL_C_CHAR,
                        outData[i].buff,
                        outData[i].buffLen,
                        &outData[i].len ) ;
    STMT_HANDLE_CHECK( hstmt, sqlrc);
  }

  printf( "\n" ) ;
  rows_found = 0;

  /* fetch each row and display */
  sqlrc = SQLFetch( hstmt ) ;
  STMT_HANDLE_CHECK( hstmt, sqlrc);

  if (sqlrc == SQL_NO_DATA_FOUND)
    printf("\n  No rows found.\n");

  while ( sqlrc != SQL_NO_DATA_FOUND )
  {
    rows_found++;
    printf(" ");
    for ( i = 0; i < nResultCols; i++ )
    {
      /* check for NULL data */
      if ( outData[i].len == SQL_NULL_DATA )
        printf( "%-*.*s", (int) colDisplaySize[i], (int) colDisplaySize[i],
                "NULL" ) ;
      else /* print outData for this column */
        printf("%-*.*s", (int) colDisplaySize[i], (int) colDisplaySize[i],
               outData[i].buff);
    } /* for all columns in this row  */

    printf("\n");
    sqlrc = SQLFetch( hstmt ) ;
    STMT_HANDLE_CHECK( hstmt, sqlrc);
  }                              /* while rows to fetch */
  printf("\n");
  /* free data buffers */
  for (i = 0; i < nResultCols; i++)
    free( outData[i].buff );

  /* free the statement handle */
  sqlrc = SQLFreeHandle( SQL_HANDLE_STMT, hstmt ) ;
  STMT_HANDLE_CHECK( hstmt, sqlrc);

  if (rows_found > 0)
     printf("<========== The spatial query was executed successfully\n");
  else
  {
     printf("<========== Spatial query failed to return any data\n");
     rc = SQL_ERROR;
  }

  return(rc);
}


/*=================================================================*/
/*                       Enable Spatial Database                   */
/*=================================================================*/
int EnableDB()
{
  rc = stEnableDB();
  GseCheck(rc);
  return(rc);
}

/*=================================================================*/
/*                      Disable Spatial Database                   */
/*=================================================================*/
int DisableDB(void)
{
  rc = stDisableDB(-1);
  GseCheck(rc);
  return(rc);
}


/*=================================================================*/
/*             TEST OF Enable/disable Spatial Database             */
/*=================================================================*/
/*                                                                 */
/*  (1) Enable the spatial database                                */
/*  (2) Disable the spatial database                               */
/*  (3) Enable the spatial database again                          */
/*                                                                 */
/*=================================================================*/
int TestEnableDisable()
{
  printf("START: TestEnableDisable()\n");
  rc = stEnableDB();
  GseCheck(rc);

  rc = stDisableDB(-1);
  GseCheck(rc);

  rc = stEnableDB();
  GseCheck(rc);

  return(rc);
}

/*=================================================================*/
/*         Test of Creating/Dropping Coordinate systems            */
/*=================================================================*/
/*                                                                 */
/*  (1) Create Coordinate System "NORTH_AMERICAN"                  */
/*  (2) Drop Coordinate System "NORTH_AMERICAN"                    */
/*  (3) Create Coordinate System "KY_STATE_PLANE"                  */
/*                                                                 */
/*=================================================================*/
int TestCoordinateSystem(void)
{
  printf("START: TestCoordinateSystem()\n");
  /*====================Created and dropped ======================*/
  rc = stCreateCS ("NORTH_AMERICAN",
                   "GEOGCS[\"GCS_North_American_1983\",\
DATUM[\"D_North_American_1983\",\
SPHEROID[\"GRS_1980\",6378137,298.257222101]],\
PRIMEM[\"Greenwich\",0],\
UNIT[\"Degree\",0.0174532925199432955]]",
                   "EPSG",
                   1001,
                   "Test Coordinate Systems");
  GseCheck(rc);

  rc = stDropCS ("NORTH_AMERICAN");
  GseCheck(rc);

  /*=====================Created and used ========================*/
  rc = stCreateCS ("KY_STATE_PLANE",
                   "\
PROJCS[\"NAD_1983_StatePlane_Kentucky_South_FIPS_1602_Feet\",\
GEOGCS[\"GCS_North_American_1983\",\
DATUM[\"D_North_American_1983\",\
SPHEROID[\"GRS_1980\",6378137.0,298.257222101]],\
PRIMEM[\"Greenwich\",0.0],\
UNIT[\"Degree\",0.0174532925199433]],\
PROJECTION[\"Lambert_Conformal_Conic\"],\
PARAMETER[\"False_Easting\",1640416.666666667],\
PARAMETER[\"False_Northing\",1640416.666666667],\
PARAMETER[\"Central_Meridian\",-85.75],\
PARAMETER[\"Standard_Parallel_1\",36.73333333333333],\
PARAMETER[\"Standard_Parallel_2\",37.93333333333333],\
PARAMETER[\"Latitude_Of_Origin\",36.33333333333334],\
UNIT[\"Foot_US\",0.3048006096012192]]",
                   "ESRI",
                   1002,
                   "Coordinate System used for Customers Table");

  GseCheck(rc);

  return(rc);
}

/*=================================================================*/
/*      Test the Creation/Drop of spatial reference systems        */
/*=================================================================*/
/*                                                                 */
/*  (1) Create the spatial reference system SRSDEMO1               */
/*  (2) Drop the spatial reference system SRSDEMO1                 */
/*  (3) Create and use the spatial reference system KY_PROJ_SRS    */
/*                                                                 */
/*  Note:                                                          */
/*     SRSDEMO1 is based on a geographic coordinate system whereas */
/*     KY_STATE_SRS uses a state plane system for Kentucky State.  */
/*                                                                 */
/*     SRSDEMO1 has                                                */
/*            cs: NORTH_AMERICAN                                   */
/*            srsId  : 100001   srsName: SRSDEMO1                  */
/*            xOffset: -180     xScale : 5965232                   */
/*            yOffset: -90      yScale : 5965232                   */
/*            zOffset: 0        zScale : 1                         */
/*            mOffset: 0        mScale : 1                         */
/*                                                                 */
/*     KY_STATE_SRS has                                            */
/*            cs: KY_PROJ_CS                                       */
/*            srsId  : 100002   srsName: KY_PROJ_SRS               */
/*            xOffset: 0        xScale : 10                        */
/*            yOffset: 0        yScale : 10                        */
/*            zOffset: 0        zScale : 1                         */
/*            mOffset: 0        mScale : 1                         */
/*                                                                 */
/*=================================================================*/
int TestSRS(void)
{
  printf("START: TestSRS() for Spatial Reference System SRSDEMO1\n");
  /*====================Created and dropped ======================*/
  rc = stCreateSRS("SRSDEMO1",100001,-180,5965232,-90,5965232,0,1,0,1,
                   "GCS_NORTH_AMERICAN_1983",
                   "GSE Demo Program: test SRS");
  GseCheck(rc);

  rc = stDropSRS("SRSDEMO1");
  GseCheck(rc);

  /*======================Create KY_PROJ_SRS=======================*/
  /* The Spatial References System is based on a coordinate system */
  /* and defines additional offset values and scale factors to be  */
  /* used by spatial extender routines to convert floating point   */
  /* external representation to the internal integer representation*/
  /*                                                               */
  /* The x and y coordinate values in the Kentucky coordinate      */
  /* will always be 0 so we just use x and y offsets of 0.         */
  /*                                                               */
  /* The scale factor is set to 10 which will preserve precision   */
  /* to at least a foot.                                           */
  /*===============================================================*/

  rc = stCreateSRS("KY_PROJ_SRS",100002,0,10,0,10,0,1,0,1,
                   "KY_STATE_PLANE",
                   "GSE Demo Program: customers table");
  GseCheck(rc);

  return(rc);

}

/*=================================================================*/
/*                   Test creation of spatial tables               */
/*=================================================================*/
int CreateSpatialTables(void)
{
  printf("START: CreateSpatialTables()\n");
  rc = gseSetupTables();
  GseCheck(rc);

  return(rc);
}

/*=================================================================*/
/*                   Test creation of geocoder               */
/*=================================================================*/
int TestCreateLatLongGeocoder(void)
{
  printf("START: CreateLatLongGeocoder()\n");
  rc = gseCreateLatLongGeocoder();
  GseCheck(rc);

  return(rc);
}
/*=================================================================*/
/*                Test registration of spatial columns             */
/*=================================================================*/
/*                                                                 */
/*  (1) Register the customers/location column                     */
/*  (2) Unregister the customers/location column from step (1)     */
/*  (3) Reregister the customers/location column from step (1)     */
/*  (4) Register the offices/location column                       */
/*                                                                 */
/*=================================================================*/
int TestRegisterSpatialColumn(void)
{
  printf("START: TestRegisterSpatialColumn()\n");
  /*==============Register and unregister test ===================*/
  /* ---- Checking to see if the SRSDEMO1 was created indeed ---- */
  rc = stRegisterSpatialColumn(NULL,"CUSTOMERS", "LOCATION","NAD83_SRS_1");
  GseCheck(rc);

  rc = stUnregisterSpatialColumn(NULL, "CUSTOMERS", "LOCATION");
  GseCheck(rc);


  /*======================Registered and used =======================*/
  rc = stRegisterSpatialColumn(NULL,"CUSTOMERS", "LOCATION","KY_PROJ_SRS");
  GseCheck(rc);

  rc = stRegisterSpatialColumn(NULL, "OFFICES", "LOCATION","KY_PROJ_SRS");
  GseCheck(rc);
  /*=================================================================*/

  return(rc);
}

/*====================================================================*/
/*                Test registration of the geocoder                   */
/*====================================================================*/
/*                                                                    */
/*  (1) Register a geocoder using DEFAULT geocoder UDF                */
/*  (2) Unregister the geocoder registered in step (1)                */
/*  (3) Register a geocoder using the projected coordinate system     */
/*      for Kentucky data                                             */
/*                                                                    */
/*====================================================================*/
int TestRegisterGeocoder(void)
{
  printf("START: TestRegisterGeocoder()\n");
  /*==============Register and unregister test =====================*/

  /* In a first test we are going to register a geocoder SAMPLEGC   */
  /* that uses a simple geocoder to convert latitude and            */
  /* longitude into a spatial point value.                          */
  /* A set of parameters is used to adjust the geocoding function.  */
  /* - column names that match LATITUDE and LONGITUDE               */
  /* - the spatial reference system used for the result coordinates */
  /*   is identified by the SRSID 1                                 */
  /*                                                                */
  /* The parameter description is left NULL and the vendor name is  */
  /* DEFAULT. With the description 'Latitude & Longitude geocoder'  */
  /* we have an additional field to distinguish between multiple    */
  /* geocoder.                                                      */
  /*                                                                */
  /*================================================================*/

  rc = stRegisterGc("SAMPLEGC","db2se","LATLONGGC","LATLONGGC",
                    "LATITUDE,LONGITUDE,1",
                    NULL,"DEFAULT","Latitude & Longitude geocoder");
  GseCheck(rc);

  rc = stUnregisterGc("SAMPLEGC");
  GseCheck(rc);

  /*=====================Registered and used ======================*/
  /* For the next geocoder setup we use the same values as above.  */
  /* Only the SRSID 100002 points to a the KY_PROJ_SRS spatial     */
  /* reference system created in TestSRS(). The KY_PROJ_SRS is     */
  /* based on a projected coordinate system rather than a          */
  /* geographic coordinate system. For some spatial analysis below */
  /* we need the customer data in a projected coordinate system    */
  /* and avoid a transformation if we have the geocoder to produce */
  /* the required projection already.                              */
  /*===============================================================*/

  rc = stRegisterGc("KY_STATE_GC","db2se","LATLONGGC","LATLONGGC",
                    "LATITUDE,LONGITUDE,1000002",
                    NULL,"DEFAULT","Geocoder for Kentucky State Coordinates");		
  GseCheck(rc);
  /*=================================================================*/

  return(rc);
}

/*=================================================================*/
/*                                                                 */
/*     Test setup of Geocoders for the spatial columns             */
/*                                                                 */
/*=================================================================*/
int TestSetupGeocoder(void)
{
  printf("START: TestSetupGeocoder()\n");
  /** Checking to see if the geocoder(KY_STATE_GC) was registered correctly **/

  rc = stSetupGeocoding(NULL, "CUSTOMERS", "LOCATION","KY_STATE_GC",
                        "LATITUDE,LONGITUDE,100002",NULL,NULL,-1);
  GseCheck(rc);

  rc = stRemoveGeocodingSetup(NULL, "CUSTOMERS", "LOCATION");
  GseCheck(rc);

  /****************** Checking just the setup geocoding ********************/
  rc = stSetupGeocoding(NULL, "CUSTOMERS", "LOCATION","KY_STATE_GC",
                        "LATITUDE,LONGITUDE,100002",NULL,NULL,-1);
  GseCheck(rc);

  /*-----------------------------------------------------------------------*/

  return(rc);
}


/*=================================================================*/
/*             Test the geocoding of the spatial columns           */
/*=================================================================*/
/*                                                                 */
/*    Geocode the customers/location column using the KY_STATE_GC  */
/*    geocoder from above.                                         */
/*                                                                 */
/*=================================================================*/
int TestGeocoder(void)
{
  printf("START: TestGeocoder()\n");
/*========== Testing Geocoding with registered Geocoder ===========*/
  rc = stRunGC(NULL, "CUSTOMERS", "LOCATION","KY_STATE_GC",
               "LATITUDE,LONGITUDE,100002",NULL,0);
  GseCheck(rc);

  return(rc);
}

/*=================================================================*/
/*                                                                 */
/*                 Test of InportShape procedure                   */
/*                 Populating the spatial column...                */
/*                                                                 */
/*=================================================================*/
int TestImportShape(void)
{
  char tmpbuf[100];
  char tmpbuf2[100];
  time_t xtime;

  printf("START: TestImportShape()\n");
  time(&xtime);
  /*---------------------------------------------------------------*/
  gseBuildSampleFolder(path,"offices");
  sprintf(tmpbuf,"importOffices.log_%i",xtime);
  sprintf(tmpbuf2,"importOffices.err_%i",xtime);
  gseBuildTempFolder(msgpath,tmpbuf);
  gseBuildTempFolder(exceptionpath,tmpbuf2);
  rc=stImportShape(path,NULL,"KY_PROJ_SRS",NULL,"OFFICES",NULL,
                   0,NULL,"LOCATION",NULL,NULL,-1,
                   NULL,-1,-1,-1,exceptionpath,msgpath);
  GseCheck(rc);
  /*---------------------------------------------------------------*/
  gseBuildSampleFolder(path,"floodzones");
  sprintf(tmpbuf,"importFloodzones.log_%i",xtime);
  sprintf(tmpbuf2,"importFloodzones.err_%i",xtime);
  gseBuildTempFolder(msgpath,tmpbuf);
  gseBuildTempFolder(exceptionpath,tmpbuf2);
  rc =stImportShape(path,NULL,"KY_PROJ_SRS",NULL,"FLOODZONES",NULL,
                    1,NULL,"LOCATION",NULL,NULL,-1,
                    NULL,-1,-1,-1,exceptionpath,msgpath);
  GseCheck(rc);
  /*------------------------------------------------------------------*/
  gseBuildSampleFolder(path,"regions");
  sprintf(tmpbuf,"importRegions.log_%i",xtime);
  sprintf(tmpbuf2,"importRegions.err_%i",xtime);
  gseBuildTempFolder(msgpath,tmpbuf);
  gseBuildTempFolder(exceptionpath,tmpbuf2);
  rc =stImportShape(path,NULL,"KY_PROJ_SRS",NULL,"REGIONS",NULL,
                    1,NULL,"LOCATION",NULL,NULL,-1,
                    NULL,-1,-1,-1,exceptionpath,msgpath);
  GseCheck(rc);
  /*------------------------------------------------------------------*/

  return(rc);
}

/*====================================================================*/
/*                Test Enable/Drop spatial indexes                    */
/*====================================================================*/
/*                                                                    */
/*  (1) Create/Drop spatial index for the customers/location column   */
/*  (2) Enable spatial index for all spatial tables                   */
/*                                                                    */
/*====================================================================*/
int TestIndexes(void)
{
  printf("START: TestIndexes()\n");

  /* The following data have been generated in a test run on
     CUSTOMERS.LOCATION:

Number of Rows: 338
Number of non-empty Geometries: 333
Number of empty Geometries: 5
Number of null values: 0


Extent covered by data:
    Minimum X: 1114636.300000
    Maximum X: 2435792.500000
    Minimum Y: 1762676.500000
    Maximum Y: 2651005.100000

     Suggested Grid Sizes:
     ---------------------
     Size 0: 5000
     Size 1: 0
     Size 2: 0 */

  rc = gseCLICreateIndex("CUSTOMERS","LOCATION","CUSTOMERSLOC", "5000.0, 0.0, 0.0");
  GseCheck(rc);

  rc = gseCLIDropIndex("CUSTOMERSLOC");
  GseCheck(rc);

  rc = gseCLICreateIndex("CUSTOMERS","LOCATION","CUSTOMERSLOC", "5000.0, 0.0, 0.0");
  GseCheck(rc);

  /* The following data have been generated in a test run on
     OFFICES.LOCATION:

Number of Rows: 31
Number of non-empty Geometries: 31
Number of empty Geometries: 0
Number of null values: 0


Extent covered by data:
    Minimum X: 1260842.000000
    Maximum X: 2312300.500000
    Minimum Y: 1861630.200000
    Maximum Y: 2619517.400000

     Suggested Grid Sizes:
     ---------------------
     Size 0: 5000
     Size 1: 0
     Size 2: 0 */

  rc = gseCLICreateIndex("OFFICES", "LOCATION","OFFICESLOC", "5000.0, 0.0, 0.0");
  GseCheck(rc);

  /* The following data have been generated in a test run on
     FLOODZONES.LOCATION:

Number of Rows: 38
Number of non-empty Geometries: 38
Number of empty Geometries: 0
Number of null values: 0


Extent covered by data:
    Minimum X: 1267927.700000
    Maximum X: 2443079.200000
    Minimum Y: 2014026.400000
    Maximum Y: 2644878.300000

     Suggested Grid Sizes:
     ---------------------
     Size 0: 3900
     Size 1: 23000
     Size 2: 46000 */

  rc = gseCLICreateIndex("FLOODZONES", "LOCATION","BOUNDARYLOC", "3900.0, 23000.0, 46000.0");
  GseCheck(rc);

  /* The following data have been generated in a test run on
     REGIONS.LOCATION:

Number of Rows: 3
Number of non-empty Geometries: 3
Number of empty Geometries: 0
Number of null values: 0


Extent covered by data:
    Minimum X: 562573.500000
    Maximum X: 2739247.900000
    Minimum Y: 1708027.300000
    Maximum Y: 2664796.800000

     Suggested Grid Sizes:
     ---------------------
     Size 0: 95000
     Size 1: 450000
     Size 2: 0 */

  rc = gseCLICreateIndex("REGIONS", "LOCATION","REGIONLOC", "95000.0, 450000.0, 0.0");
  GseCheck(rc);

  return(rc);
}

/*=================================================================*/
/*                                                                 */
/*             Automatic geocoder and indexes test                 */
/*                                                                 */
/*=================================================================*/
int TestAutoGC(void)
{
  printf("START: TestAutoGC() Automatic geocoder and indexes test\n");
  rc = stRemoveGeocodingSetup(NULL, "CUSTOMERS", "LOCATION");
  GseCheck(rc);

  /*====================================================================*/
  /*  (1) Register the automatic geocoder for the customers/location    */
  /*      column                                                        */
  /*====================================================================*/
  rc = stSetupGeocoding(NULL, "CUSTOMERS", "LOCATION","KY_STATE_GC",
                        "LATITUDE,LONGITUDE,100002","LATITUDE, LONGITUDE",NULL,-1);
  GseCheck(rc);

  rc = stEnableAutoGC(NULL, "CUSTOMERS", "LOCATION");
  GseCheck(rc);
  /*=================================================================*/
  /*  (1) Insert some tuples with different street number            */
  /*  (2) Update some tuples with new address                        */
  /*  (3) Delete some tuples from the table                          */
  /*=================================================================*/
  rc = gseInsDelUpd();
  GseCheck(rc);

  return(rc);
}

/*=================================================================*/
/*                                                                 */
/*          Create a view and register it as a spatial column      */
/*                   Perform spatial analysis                      */
/*                                                                 */
/*=================================================================*/
int TestViewsAndQueries(void)
{

/****************************************************************************/
  SQLCHAR query1txt[] = "Number of customers served by each region:";

  SQLCHAR query1[]
    = "SELECT R.NAME, COUNT(C.NAME) AS CUSTOMERS \n \
        FROM CUSTOMERS C, REGIONS R \n \
        WHERE DB2GSE.ST_WITHIN(C.LOCATION, R.LOCATION) = 1 \n \
        GROUP BY R.NAME ORDER BY R.NAME";

/****************************************************************************/
  SQLCHAR query2txt[] = "For offices and customers within each region, \
the number of \n customers that are within 10 miles of each office:";

  SQLCHAR query2[] =
    "SELECT R.NAME AS REGION_NAME, O.NAME AS OFFICE_NAME, \n \
        COUNT(C.NAME) AS CUSTOMERS  \n \
        FROM CUSTOMERS C, REGIONS R, OFFICES O \n \
        WHERE DB2GSE.ST_DISTANCE(C.LOCATION, O.LOCATION, 'STATUTE MILE') < 10.0 AND  \n \
        DB2GSE.ST_WITHIN(O.LOCATION, R.LOCATION) = 1 \n \
        GROUP BY R.NAME, O.NAME ORDER BY R.NAME,O.NAME";

/****************************************************************************/
  SQLCHAR query3txt[] = "For each region the average income and premium of \
its customers:";

  SQLCHAR query3[] =
    "SELECT R.NAME, DECIMAL(AVG(C.INCOME),8,2) AS INCOME, \n \
        DECIMAL(AVG(C.PREMIUM),8,2) AS PREMIUM \n \
        FROM CUSTOMERS C, REGIONS R \n \
        WHERE DB2GSE.ST_WITHIN(C.LOCATION, R.LOCATION) = 1 \n \
        GROUP BY R.NAME ORDER BY R.NAME";

/****************************************************************************/
  SQLCHAR query4txt[] = "List of flood zones that cross specific region \
boundaries:";

  SQLCHAR query4[] =
    "SELECT FZ.NAME FROM FLOODZONES FZ, REGIONS R1, REGIONS R2 \n \
        WHERE (RTRIM(R1.NAME) = 'Kentucky Central' AND \n \
        DB2GSE.ST_OVERLAPS(FZ.LOCATION, R1.LOCATION) = 1) \n \
        AND \n \
        (RTRIM(R2.NAME) = 'Kentucky West' AND \n \
        DB2GSE.ST_OVERLAPS(FZ.LOCATION, R2.LOCATION) = 1) ORDER BY FZ.NAME";

/****************************************************************************/
  SQLCHAR query5txt[] = "Minimum distance from a specific customer to the \
nearest office:";

  SQLCHAR query5[] =
    "WITH TEMP(CUSTOMER,ID,OFFICE, DISTANCE) AS \n \
        (SELECT C.NAME,C.ID,O.NAME,\n \
        DB2GSE.ST_DISTANCE(C.LOCATION, O.LOCATION, 'STATUTE MILE')\n \
        FROM CUSTOMERS C, OFFICES O \n \
        WHERE C.ID = 80708 ) \n \
        SELECT DISTINCT ID,CUSTOMER, OFFICE, \n \
        DECIMAL(DISTANCE,6,2) AS DISTANCE \n \
        FROM TEMP  \n \
        WHERE DISTANCE = \n \
        (SELECT MIN(DISTANCE) \n \
        FROM TEMP)";

/****************************************************************************/
  SQLCHAR query6txt[] = "Customers located within half a mile of flood zone 'Boone':";

  SQLCHAR query6[] =
    "SELECT C.NAME FROM CUSTOMERS C, FLOODZONES FZ \n \
        WHERE RTRIM(FZ.NAME) = 'Boone'  AND   \n \
          DB2GSE.ST_DISTANCE(FZ.LOCATION, C.LOCATION, 'STATUTE MILE') < 0.5 \n \
	  ORDER BY C.NAME";

/****************************************************************************/
  SQLCHAR query7txt[] = "High risk customers located within 2 miles of the \
offices:";

  SQLCHAR query7[] =
    "SELECT HR.NAME FROM HIGHRISKCUSTOMERS HR, OFFICES O \n \
        WHERE  DB2GSE.ST_WITHIN(HR.LOCATION, \n \
        DB2GSE.ST_BUFFER(O.LOCATION, 2, 'STATUTE MILE'))=1 ORDER BY HR.NAME";

/****************************************************************************/

  printf("START: TestViewsAndQueries()\n");
  /*=================================================================*/
  /*  (1) Create a view, highRiskCustomers, based on the spatial     */
  /*      join of the customers locations and the the hazardZones    */
  /*      using the spatial function ST_WITHIN as join predicate.    */
  /*  (2) Register this view as a spatial column                     */
  /*=================================================================*/
  rc = gseCreateView();
  GseCheck(rc);

  rc = stRegisterSpatialColumn(NULL, "HIGHRISKCUSTOMERS", "LOCATION",
                               "KY_PROJ_SRS");
  GseCheck(rc);

  /*=================================================================*/
  /*  (1) Find the average customer distance from each office        */
  /*      (within, distance)                                         */
  /*  (2) Find the average customer income and premium for each      */
  /*      office (within)                                            */
  /*  (3) Find customers who is not covered by any existing office   */
  /*      (within)                                                   */
  /*  (4) Find the number of hazard zones each office zone overlaps  */
  /*      with (overlap)                                             */
  /*  (5) Find the minimum distance from a particular customer       */
  /*      location to the surrounding offices.                       */
  /*  (6) Find the customers whose location is close to the boundary */
  /*      of a particular hazard zone (buffer, overlap)              */
  /*  (7) Find those high risk customers who is covered by a         */
  /*      particular office                                          */
  /*=================================================================*/

  /* Remove non-spatial query about Gene
  rc = gseRunSpatialQueries(hdbc, "SELECT id, name \nFROM customers \n\
WHERE name like 'Gene%' ORDER BY id", "Get all the customers with name GENE");
  GseCheck(rc);
  */

  rc = gseRunSpatialQueries(hdbc, (char *) query1, (char *) query1txt);
  GseCheck(rc);

  rc = gseRunSpatialQueries(hdbc, (char *) query2, (char *) query2txt);
  GseCheck(rc);

  rc = gseRunSpatialQueries(hdbc, (char *) query3, (char *) query3txt);
  GseCheck(rc);

  rc = gseRunSpatialQueries(hdbc, (char *) query4, (char *) query4txt);
  GseCheck(rc);

  rc = gseRunSpatialQueries(hdbc, (char *) query5, (char *) query5txt);
  GseCheck(rc);

  rc = gseRunSpatialQueries(hdbc, (char *) query6, (char *) query6txt);
  GseCheck(rc);

  rc = gseRunSpatialQueries(hdbc, (char *) query7, (char *) query7txt);
  GseCheck(rc);

  return(rc);

}

/*=================================================================*/
/*                 Test the ExportShape procedure                  */
/*=================================================================*/
/*                                                                 */
/*  (1) Export the 'highRiskCustomers' view                        */
/*                                                                 */
/*=================================================================*/
int TestExportShape(void)
{
  char tbuffer[100];
  char tbuffer2[100];
  time_t xtime;

  printf("START: TestExportShape()\n");
  time(&xtime);
  sprintf(tbuffer,"hiRiskCustShape_%i",xtime);
  sprintf(tbuffer2,"hiRiskCustMsg_%i",xtime);
  gseBuildTempFolder(path,tbuffer);
  gseBuildTempFolder(msgpath,tbuffer2);
  printf("==========> Export from HighRiskCustomers view to Shapefile...\n");
  printf("     Path: %s\n", path);
  printf("  Logfile: %s\n", msgpath);
  fflush(stdout);
  rc = stExportShape(path,-1,NULL,"SELECT * FROM HIGHRISKCUSTOMERS",
       msgpath);
  GseCheck(rc);

  return(rc);

}

/*=================================================================*/
/*         An interactive system for maintenance purposes          */
/*=================================================================*/
int menu()
{

  int choice = -1;

  while(choice!=99)
  {
    printf(" CHOOSE FROM ONE OF THE OPTIONS AND 99 TO EXIT\n");
    printf(" 1  - TestEnableDisable();\n");
    printf(" 2  - TestCoordinateSystem();\n");
    printf(" 3  - TestSRS();\n");
    printf(" 4  - CreateSpatialTables();\n");
    printf(" 5  - TestRegisterSpatialColumn();\n");
    printf(" 6  - TestRegisterGeocoder();\n");
    printf(" 7  - TestSetupGeocoder();\n");
    printf(" 8  - TestGeocoder();\n");
    printf(" 9  - TestImportShape();\n");
    printf(" 10 - TestIndexes();\n");
    printf(" 11 - TestAutoGC();\n");
    printf(" 12 - TestViewsAndQueries();\n");
    printf(" 13 - TestExportShape();\n");
    printf(" 14 - TestCreateLatLongGeocoder();\n");   
    printf(" 15 - EnableDB();\n");
    printf(" 16 - DisableDB();\n");
    printf(" 99 - WrapUpDemo() - EXIT;\n");

    scanf("%i",&choice);
    switch(choice)
    {
      case 1: TestEnableDisable();                    break;
      case 2: TestCoordinateSystem();                 break;
      case 3: TestSRS();                              break;
      case 4: CreateSpatialTables();                  break;
      case 5: TestRegisterSpatialColumn();            break;
      case 6: TestRegisterGeocoder();                 break;
      case 7: TestSetupGeocoder();                    break;
      case 8: TestGeocoder();                         break;
      case 9: TestImportShape();                      break;
      case 10:TestIndexes();                          break;
      case 11:TestAutoGC();                           break;
      case 12:TestViewsAndQueries();                  break;
      case 13:TestExportShape();                      break;
      case 14:TestCreateLatLongGeocoder();            break;      
      case 15:EnableDB();                             break;
      case 16:DisableDB();                            break;
      case 99:WrapUpDemo();                           break;
    }
  }
  return(0);
}

/*======================================================================*/
/*                                                                      */
/* The following scenario is used in this sample program to demonstrate */
/* the typical usage of DB2 Spatial Extender:                           */
/*                                                                      */
/* (1) Story:                                                           */
/*     (a) An insurance company having online "customers" data and      */
/*         "offices" data for its daily operations would like to adopt  */
/*         the spatial technology for enhancing the business.           */
/*     (b) More precisely, they would like to use the spatial attribute */
/*         of the existing data to perform various kinds of spatial     */
/*         analysis such as finding the average premium of customers in */
/*         a certain area, looking for those customers who need to be   */
/*         evacuated if certain area gets flooded, etc.                 */
/* (2) Data:                                                            */
/*     (a) Customers table consists of 1000 records.                    */
/*     (b) Offices table consists of 120 records.                       */
/*     (c) HazardZones table consists of 3551 records.                  */
/* (3) Major steps:                                                     */
/*     (a) Enable the database with spatial capability.                 */
/*     (b) Register spatial reference systems for the spatial data:     */
/*         * The "location" column of the "customers" table.            */
/*         * The "location" column of the "offices" table.              */
/*         * The "zone" column of the "offices" table.                  */
/*         * The "boundary" column of the "hazardZones" table.          */
/*     (c) Register the spatial columns                                 */
/*         * The "location" column of the "customers" table.            */
/*         * The "location" column of the "offices" table.              */
/*         * The "zone" column of the "offices" table.                  */
/*         * The "boundary" column of the "hazardZones" table will be   */
/*           registered by the shape file loader.                       */
/*     (c) Populate the spatial data:                                   */
/*         * Geocoding the customers.location column based on the       */
/*           address columns of the same table.                         */
/*                                                                      */
/*======================================================================*/

/*======================================================================*/
/*                                                                      */
/*                          main(argc, argv)                            */
/*                                                                      */
/*======================================================================*/
int main(int argc, char * argv[])
{
  SQLRETURN rc;

  struct sqlfupd  l_sqlfupd;
  short  applheapsz = 0;
  short  logprimary = 0;
  short    logfilsz = 0;
  char   yn_reply[4];

  int dbExists = 0;

  if (argc > 5 || (argc >=2 &&
              ((strncmp(argv[1],"-h",2)==0)||(strncmp(argv[1],"-?",2)==0))))
  {
    printf(
     "Syntax for runGseDemo - Spatial Extender demo program: \n"
     "   runGseDemo db_name [userid password [AbortOnError(y/n)?] ]\n");
    printf("\nFor interactive input, type runGseDemo with no arguments. \n");

#ifdef _NOW32OS
    printf(
     "\n==>To save the GSE Demo output, the tee program can be helpful.\n");
    printf(
     "Examples: \n");
    printf(
     " runGseDemo <db_name> | tee <outfile>    OR \n");
    printf(
     " runGseDemo <db_name> <userid> <passwd> | tee <outfile>\n");
    printf(
     "Be sure <outfile> is in a directory where you have write permissions.\n");
    printf(
     "\n==> It is recommended to create a directory for temp files that are\n");
    printf(
     "generated when runGseDemo executes.  Set the environment variable \n");
    printf(
     "DEMO_TMPDIR to the full path to that directory.\n");
#endif
    return(0);
  }

  if (argc == 5)
  {
    strcpy((char *)dbase,   argv[1]);
    strcpy((char *)uid,      argv[2]);
    strcpy((char *)pwd,      argv[3]);
    strcpy((char *)AbChoice, argv[4]);
  }
  else
    if (argc == 4)
    {
      strcpy((char *)dbase, argv[1]);
      strcpy((char *)uid   , argv[2]);
      strcpy((char *)pwd   , argv[3]);
    }
    else
      if (argc == 2)
        strcpy((char *)dbase  , argv[1]);
      else
      {
        printf("Interactive Mode.  [For more info, use -? or -h] \n");
        printf("Do you wish to continue in Interactive Mode? (y/n) \n");
        fgets(yn_reply, sizeof(yn_reply), stdin);
        if ((yn_reply[0]!='y') && (yn_reply[0]!='Y'))
        {
          printf("Exiting runGseDemo program at user request. \n");
          exit(0);
        }
        printf("Enter database name:\n");
        fgets((char *) dbase, sizeof(dbase), stdin);

        /* discard the newline character in the dbase name */
        if (dbase[strlen((char *) dbase) - 1] == '\n')
          dbase[strlen((char *) dbase) - 1] = 0;

        printf("Enter userid or hit ENTER to use your userid:\n");
        fgets((char *) uid, sizeof(uid), stdin);

        /* discard the newline character in the user id */
        if (uid[strlen((char *) uid) - 1] == '\n')
          uid[strlen((char *) uid) - 1] = 0;

        printf("Enter password or hit ENTER to use your password:\n");
        fgets((char *) pwd, sizeof(pwd), stdin);

        /* discard the newline character in the password */
        if (pwd[strlen((char *) pwd) - 1] == '\n')
          pwd[strlen((char *) pwd) - 1] = 0;

        printf("Want to abort if any error occurs?(y/n) DEFAULT = y: ");
        fgets((char *) AbChoice, 4, stdin);

        /* discard the newline character for the y/n answer */
        if (AbChoice[strlen((char *) AbChoice) - 1] == '\n')
          AbChoice[strlen((char *) AbChoice) - 1] = 0;
      }

  // in case we have a valid y\n answer we are going to proceed
  // if we got a @ we will show a debug menu for maintenance purposes
  if((AbChoice[0]=='y')||(AbChoice[0]=='Y')||
     (strcmp((char *)AbChoice,"")==0))
    CheckRC=1;
  else
  {
    CheckRC=0;
    if(AbChoice[0]=='@')
      domenu=1;
  }

  /*=================================================================*/
  /*       Initialize the Spatial Extender runGseDemo program        */
  /*=================================================================*/
  /*                                                                 */
  /*  (1) Initialize the CLI environment (ENV and DB)                */
  /*  (2) Check if the database exists                               */
  /*  (3) Update some database configuration parameters              */
  /*  (4) Connect to the database                                    */
  /*=================================================================*/

  printf("==========> Initializing the Spatial Extender runGseDemo program \
...\n");
  fflush(stdout);
  if (getenv("DB2PATH") == NULL)
  {
    printf(
     "<========== Failed to find the DB2PATH environment variable. \n");
    printf(
     "    Please set DB2PATH to the full path to sqllib for this instance.\n");
    printf("\n runGseDemo exiting. \n");
    exit(0);
  }

  /*====================================================================*/
  /* (1) We allocate the environment handle and a database handle. The  */
  /* database does not necessarily have to exist in order to allocate a */
  /* database handle. But we can not connect to the database without an */
  /* handle.                                                            */
  /*====================================================================*/
  rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  if (rc != SQL_SUCCESS)
  {
    printf("<========== Fail to allocate (henv) environment handle\
=============>.\n\n");

    terminate(henv, rc);
    return (1);
  }

  rc = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
  if (rc != SQL_SUCCESS)
  {
    printf("<========== Fail to allocate hdbc(database) handle\
=============>.\n\n");

    terminate(henv, rc);
    return (1);
  }

  /*====================================================================*/
  /* (2) We try to retrieve some database configuration parameter. If   */
  /* this is not successful and returns a SQL1013 the database does not */
  /* exist. We will then ask the user if we should create the database. */
  /*====================================================================*/

  l_sqlfupd.token = SQLF_DBTN_APPLHEAPSZ;
  l_sqlfupd.ptrvalue = (char*)&applheapsz;

  rc = sqlfxdb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

  /*====================================================================*/
  /* Check the return code to see if we were successful.                */
  /*     YES: => set dbExists =1                                        */
  /*     SQL1013: database does not exist => set dbExists = 0           */
  /*     SQL1032: instance is not started => return with error          */
  /*     DEFAULT: => return with error                                  */
  /*====================================================================*/

  switch ( sqlca.sqlcode )
  {
    case SQL_RC_OK:
      dbExists = 1;
      break;

    case SQLE_RC_NODB: /* SQL1013 */
      dbExists = 0;
      /* For UNIX, we require the database to already exist. */
#ifdef _NOW32OS
      printf("<========== Database [%s] does not exist.\n", dbase);
      printf("     The database must be created before running the sample\n");
      return(1);
#endif
      break;

    case SQLE_RC_NOSTARTG: /* SQL1032 */
      printf("<========== The database instance is not started.\
 Please execute the `db2start` command before you proceed.\n");
      return(1);
      break;

    default:
      printf("<========== Failed to retrieve db cfg with return \
code %d.\n", sqlca.sqlcode);
      return(1);
  }

  // If the database does not exist we ask the user for permission to create.
  if (dbExists == 0)
  {
    printf("The database does not seem to exist. Do you want the demo \
program to create a database '%s' in your local database directory? \
(y/n) DEFAULT = y: ", &dbase);

    fgets((char *) AbChoice, 4, stdin);

    /* discard the newline character for the y/n answer */
    if (AbChoice[strlen((char *) AbChoice) - 1] == '\n')
      AbChoice[strlen((char *) AbChoice) - 1] = 0;

    // If the  answer is yes we create the database now
    if((AbChoice[0]=='y') || (AbChoice[0]=='Y') ||
       (strcmp((char *)AbChoice,"")==0))
    {
      rc = createDb((char*) dbase);

      // If even the create database statement failed, we have to
      // return with error
      if (rc != 0) return(1);
    }
  }

  /*==================================================================*/
    /* (3) We now try to udpate the following database parameters:      */
    /* - APPLHEAPSZ                                                     */
    /* - LOGPRIMARY                                                     */
    /* - LOGFILSIZ                                                      */
    /* as recommended in the users guide.                               */
    /*==================================================================*/

    /*==================================================================*/
    /*                        APPLHEAPSZ                                */
    /*==================================================================*/

    l_sqlfupd.token = SQLF_DBTN_APPLHEAPSZ;
    l_sqlfupd.ptrvalue = (char*)&applheapsz;

    rc = sqlfxdb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

    if (sqlca.sqlcode != 0)
    {

      printf("<========== Failed to retrieve db cfg APPLHEAPSZ with return \
code %d.\n", sqlca.sqlcode);
      return(1);
    }

    if (applheapsz < MIN_APPLHEAPSZ)
    {
      applheapsz = MIN_APPLHEAPSZ;

      rc = sqlfudb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

      if (sqlca.sqlcode != 0)
      {
        printf("<========== Failed to update db cfg APPLHEAPSZ with return \
code %d.\n", sqlca.sqlcode);
        return(1);
      }
    }

    /*==================================================================*/
    /*                        LOGPRIMARY                                */
    /*==================================================================*/
    l_sqlfupd.token = SQLF_DBTN_LOGPRIMARY;
    l_sqlfupd.ptrvalue = (char*)&logprimary;

    rc = sqlfxdb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

    if (sqlca.sqlcode != 0)
    {
      printf("<========== Failed to retrieve db cfg LOGPRIMARY with return \
code %d.\n", sqlca.sqlcode);
      return(1);
    }

    if (logprimary < MIN_LOGPRIMARY)
    {
      logprimary = MIN_LOGPRIMARY;

      rc = sqlfudb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

      if (sqlca.sqlcode != 0)
      {
        printf("<========== Failed to update db cfg LOGPRIMARY with return \
code %d.\n", sqlca.sqlcode);
        return(1);
      }
    }

    /*==================================================================*/
    /*                        LOGFILSZ                                  */
    /*==================================================================*/
    l_sqlfupd.token = SQLF_DBTN_LOGFILSIZ;
    l_sqlfupd.ptrvalue = (char*)&logfilsz;

    rc = sqlfxdb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

    if (sqlca.sqlcode != 0)
    {
      printf("<========== Failed to retrieve db cfg LOGFILSZ with return \
code %d.\n", sqlca.sqlcode);
      return(1);
    }

    if (logfilsz < MIN_LOGFILSIZ)
    {
      logfilsz = MIN_LOGFILSIZ;

      rc = sqlfudb((_SQLOLDCHAR *)dbase, 1, &l_sqlfupd, &sqlca);

      if (sqlca.sqlcode != 0)
      {
        printf("<========== Failed to update db cfg LOGFILSZ with return \
code %d.\n", sqlca.sqlcode);
        return(1);
      }
    }

    /*==================================================================*/
    /* (4) Finally we connect to the database and can start with the    */
    /* spatial sample routines and functions.                           */
    /*==================================================================*/

    rc = SQLConnect(hdbc, (SQLCHAR *)dbase, SQL_NTS, (SQLCHAR *)uid, SQL_NTS,
                    (SQLCHAR *)pwd, SQL_NTS);
    CHECK_DBC(hdbc, rc);
    if (rc != SQL_SUCCESS)
    {
      printf("<========== Fail to connect to the database =============>.\
\n\n");
      terminate(henv, rc);
      exit(0);
    }

    printf("<========== The runGseDemo program was initialized successfully.\
\n\n");

    /*=================================================================*/
    /*                                                                 */
    /*      The following steps will run all the tests in the demo     */
    /*                                                                 */
    /*=================================================================*/
    if(domenu)
      return(menu());
    else
    {
      TestEnableDisable();
      TestCoordinateSystem();
      TestSRS();
      CreateSpatialTables();
      TestRegisterSpatialColumn();
      TestCreateLatLongGeocoder();
      TestRegisterGeocoder();
      TestSetupGeocoder();
      TestGeocoder();
      TestImportShape();
      TestIndexes();
      TestAutoGC();
      TestViewsAndQueries();
      TestExportShape();
      WrapUpDemo();
      return(0);
    }
} /* end main */
