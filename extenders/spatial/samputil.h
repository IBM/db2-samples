/*******************************************************
**
** Licensed Materials - Property of IBM
**
** (C) COPYRIGHT International Business Machines Corp. 1995
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
** file = samputil.h
**  Utility functions used in CLI examples
********************************************************/

SQLRETURN
DBconnect(SQLHENV henv,
        SQLHDBC * hdbc);

SQLRETURN
terminate(SQLHENV henv,
          SQLRETURN rc);

SQLRETURN
print_connect_info(SQLHDBC hdbc);

SQLRETURN
print_error(SQLHENV henv,
            SQLHDBC hdbc,
            SQLHSTMT hstmt,
            SQLRETURN frc,
            int line,
            char *  file);

SQLRETURN
check_error(SQLHENV henv,
            SQLHDBC hdbc,
            SQLHSTMT hstmt,
            SQLRETURN frc,
            int line,
            char *  file);

/* Above line was SQLCHAR * file);, changed to just a CHAR */

#define MAX_UID_LENGTH  18
#define MAX_PWD_LENGTH  30


/**
    Macros for common Error Checking using check_error from samputil.c
**/
#define CHECK_ENV( henv, RC)  if (RC != SQL_SUCCESS) \
   {check_error(henv, SQL_NULL_HDBC, SQL_NULL_HSTMT, RC, __LINE__, __FILE__);}
#define CHECK_DBC( hdbc, RC)  if (RC != SQL_SUCCESS) \
   {check_error(SQL_NULL_HENV, hdbc, SQL_NULL_HSTMT, RC, __LINE__, __FILE__);}
#define CHECK_STMT( hstmt, RC)  if (RC != SQL_SUCCESS) \
   {check_error(SQL_NULL_HENV, SQL_NULL_HDBC, hstmt, RC, __LINE__, __FILE__);}

#define INIT_UID_PWD if (argc == 4)  \
     { strncpy((char *)dbase, (const char *)argv[1], SQL_MAX_DSN_LENGTH ); \
       strncpy((char *)uid,  (const char *)argv[2], MAX_UID_LENGTH); \
       strncpy((char *)pwd, (const char *)argv[3], MAX_PWD_LENGTH); } \
     else { \
         printf(">Enter Database Name:\n"); gets((char *) dbase); \
         printf(">Enter User Name:\n"); gets((char *) uid); \
         printf(">Enter Password:\n"); gets((char *) pwd); }


