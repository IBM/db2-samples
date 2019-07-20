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
** SOURCE FILE NAME: utilapi.h
**
** SAMPLE: Checks for and prints to the screen SQL warnings and errors
**
**         This is the header file for the utilapi.c error-checking utility 
**         file. The utilapi.c file is compiled and linked in as an object 
**         module with non-embedded SQL sample programs by the supplied 
**         makefile and build files.
**
** Macros defined:
**         DB2_API_CHECK(MSG_STR)
**         EXPECTED_ERR_CHECK(MSG_STR)
**         EXPECTED_WARN_CHECK(MSG_STR) 
**
** Functions declared:
**         SqlInfoPrint - prints to the screen SQL warnings and errors
**         CmdLineArgsCheck1 - checks the command line arguments, version 1
**         CmdLineArgsCheck2 - checks the command line arguments, version 2
**         CmdLineArgsCheck3 - checks the command line arguments, version 3
**         CmdLineArgsCheck4 - checks the command line arguments, version 4
**         InstanceAttach - attach to instance
**         InstanceDetach - detach from instance
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on creating SQL procedures and developing C applications,
** see the Application Development Guide.
**
** For more information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#ifndef UTILAPI_H
#define UTILAPI_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef max
#define max(A, B) ((A) > (B) ? (A) : (B))
#endif
#ifndef min
#define min(A, B) ((A) > (B) ? (B) : (A))
#endif

#define USERID_SZ 128
#define PSWD_SZ 14

#if (defined(DB2NT))
#define PATH_SEP "\\"
#else /* UNIX */
#define PATH_SEP "/"
#endif

/* macro for DB2_API checking */
#define DB2_API_CHECK(MSG_STR)                     \
SqlInfoPrint(MSG_STR, &sqlca, __LINE__, __FILE__); \
if (sqlca.sqlcode < 0)                             \
{                                                  \
  return 1;                                        \
}

/* macro for expected error checking and message */
#define EXPECTED_ERR_CHECK(MSG_STR)                         \
printf("\n-- The following error report is expected! --"); \
SqlInfoPrint(MSG_STR, &sqlca, __LINE__, __FILE__);          \

/* macro for expected warning */
#define EXPECTED_WARN_CHECK(MSG_STR)                         \
printf("\n-- The following warning report is expected! --"); \
SqlInfoPrint(MSG_STR, &sqlca, __LINE__, __FILE__);          \

/* functions used in ..._CHECK macros */
void SqlInfoPrint(char *, struct sqlca *, int, char *);

/* other functions */
int CmdLineArgsCheck1(int, char * argv[], char *, char *, char *);
int CmdLineArgsCheck2(int, char * argv[], char *, char *, char *);
int CmdLineArgsCheck3(int, char * argv[], char *, char *, char *, char *);
int CmdLineArgsCheck4(int, char * argv[], char *, char *,
                      char *, char *, char *, char *);
int InstanceAttach(char * , char *, char *);
int InstanceDetach(char *);

#ifdef __cplusplus
}
#endif

#endif /* UTILAPI_H */

