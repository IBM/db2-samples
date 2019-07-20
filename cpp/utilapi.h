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
** SAMPLE: Error-checking utility header file for utilapi.C 
**
**         This is the header file for the utilapi.C error-checking utility 
**         file. The utilapi.C file is compiled and linked in as an object 
**         module with non-embedded SQL sample programs by the supplied 
**         makefile and build files.
**
** Macros defined:
**         DB2_API_CHECK(MSG_STR)
**         EXPECTED_ERR_CHECK(MSG_STR)
**
** Classes declared:
**         Db
**         Instance
**         SqlInfo
**         CmdLineArgs
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C++ applications, see the Application
** Development Guide.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, compiling, and running DB2
** applications, visit the DB2 application development website at
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
#else //UNIX
#define PATH_SEP "/"
#endif

// macro for error checking
#define DB2_API_CHECK(MSG_STR)                              \
SqlInfo::SqlInfoPrint(MSG_STR, &sqlca, __LINE__, __FILE__); \
if (sqlca.sqlcode < 0)                                      \
{                                                           \
  return 1;                                                 \
}

// macro for expected error checking
#define EXPECTED_ERR_CHECK(MSG_STR)                          \
cout << "\n**********************************************\n" \
     << "*    AN EXPECTED ERROR                       *\n"   \
     << "**********************************************";    \
SqlInfo::SqlInfoPrint(MSG_STR, &sqlca, __LINE__, __FILE__);

// classes and methods
class Db
{
  public:
    void setDb(char *, char *, char *);
    char *getAlias();
    char *getUser();
    char *getPswd();
  protected:
    char alias[SQL_ALIAS_SZ + 1];
    char user[USERID_SZ + 1];
    char pswd[PSWD_SZ + 1];
};

class Instance
{
  public:
    void setInstance(char *, char *, char *);
    char *getNode();
    char *getUser();
    char *getPswd();
    int Attach();
    int Detach();
  protected:
    char nodeName[SQL_INSTNAME_SZ + 1];
    char user[USERID_SZ + 1];
    char pswd[PSWD_SZ + 1];
    struct sqlca sqlca;
};

class SqlInfo
{
  public:
    static void SqlInfoPrint(char *, struct sqlca *, int, char *);
};

class CmdLineArgs
{
  public:
    static int CmdLineArgsCheck1(int, char *argv[], Db &);
    static int CmdLineArgsCheck2(int, char *argv[], Instance &);
    static int CmdLineArgsCheck3(int, char *argv[], Db &, Instance &);
    static int CmdLineArgsCheck4(int, char *argv[], Db &, Db &);
};

#ifdef __cplusplus
}
#endif

#endif // UTILAPI_H

