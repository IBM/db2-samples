/****************************************************************************
** (c) Copyright IBM Corp. 2009 All rights reserved.
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
** SOURCE FILE NAME: utilci.h
**
** SAMPLE: Declaration of utility functions used by DB2 CI samples
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on using SQL statements, see the SQL Reference.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#ifndef UTILCI_H
#define UTILCI_H

#ifndef SQL_MAX_DSN_LENGTH
#define SQL_MAX_DSN_LENGTH 128
#endif
#define MAX_UID_LENGTH 18
#define MAX_PWD_LENGTH 30
#define MAX_STMT_LEN 255
#define MAX_COLUMNS 255
#ifdef DB2WIN
#define MAX_TABLES 50
#else
#define MAX_TABLES 255
#endif

#ifndef max
#define max(a,b) (a > b ? a : b)
#endif

/* macro for error handle checking */
#define ERR_HANDLE_CHECK(errhp, ciRC)              \
if (ciRC != OCI_SUCCESS)                          \
{                                                  \
  rc = HandleInfoPrint(OCI_HTYPE_ERROR, errhp,       \
                       ciRC, __LINE__, __FILE__); \
  if (rc != 0) return rc;                          \
}
#define ENV_HANDLE_CHECK(envhp, ciRC)              \
if (ciRC != OCI_SUCCESS)                          \
{                                                  \
  rc = HandleInfoPrint(OCI_HTYPE_ENV, envhp,       \
                       ciRC, __LINE__, __FILE__); \
  if (rc != 0) return rc;                          \
}
/* functions used in ...CHECK_HANDLE macros */
int HandleInfoPrint(ub4, dvoid *, sb4, int, char *);
void TransRollback( OCISvcCtx * svch, OCIError * errhp );

/* functions to check the number of command line arguments */
int CmdLineArgsCheck1(int, char *argv[], char *, char *, char *);
int CmdLineArgsCheck2(int, char *argv[], char *, char *, char *, char *);
int CmdLineArgsCheck3(int, char *argv[], char *, char *,
                      char *, char *, char *, char *);

/* other utility functions */
int CIAppInit(char dbAlias[], char user[], char pswd[], OCIEnv ** pHenv, OCISvcCtx ** pHdbc, OCIError ** errhp );
int CIAppTerm(OCIEnv ** pHenv, OCISvcCtx ** pHdbc, OCIError * errhp, char * dbAlias );
int StmtResultPrint(OCIStmt * hstmt, OCISvcCtx * hdbc, OCIError * errhp );

#endif

