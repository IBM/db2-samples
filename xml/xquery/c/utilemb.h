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
** SOURCE FILE NAME: utilemb.h
**
** SAMPLE: Error-checking utility header file for utilemb.sqc 
**
**         This is the header file for the utilemb.sqc error-checking utility
**         file. The utilemb.sqc file is compiled and linked in as an object 
**         module with embedded SQL sample programs by the supplied makefile
**         and build files.
**
** Macro defined:
**         EMB_SQL_CHECK(MSG_STR)
**
** Functions declared:
**         TransRollback - rolls back the transaction
**         DbConn - connects to the database
**         DbDisconn - disconnects from the database
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
**
** For information on using SQL statements, see the SQL Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#ifndef UTILEMB_H
#define UTILEMB_H

#include "utilapi.h"

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_UID_LENGTH 18
#define MAX_PWD_LENGTH 30

#ifndef max
#define max(A, B) ((A) > (B) ? (A) : (B))
#endif
#ifndef min
#define min(A, B) ((A) > (B) ? (B) : (A))
#endif

#define LOBLENGTH 29

/* macro for embedded SQL checking */
#define EMB_SQL_CHECK(MSG_STR)                     \
SqlInfoPrint(MSG_STR, &sqlca, __LINE__, __FILE__); \
if (sqlca.sqlcode < 0)                             \
{                                                  \
  TransRollback();                                 \
  return 1;                                        \
}

/* function used in EMB_SQL_CHECK macro */
void TransRollback(void);

/* other useful functions with self-explanatory names */
int DbConn(char * , char *, char *);
int DbDisconn(char *);

#ifdef __cplusplus
}
#endif

#endif /* UTILEMB_H */

