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
** SOURCE FILE NAME: inattach.C
**
** SAMPLE: Attach to and detach from an instance
**
** DB2 APIs USED:
**         sqleatcp -- ATTACH AND CHANGE PASSWORD
**         sqleatin -- ATTACH TO INSTANCE
**         sqledtin -- DETACH FROM INSTANCE
** 
** STRUCTURES USED:
**         sqlca 
**         
** OUTPUT FILE: inattach.out (available in the online documentation)
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

#include <string.h>
#include <sqlutil.h>
#include <sqlenv.h>
#include "utilapi.h"
#if ((__cplusplus >= 199711L) && !defined DB2HP && !defined DB2AIX) || \
    (DB2LINUX && (__LP64__ || (__GNUC__ >= 3)) )
   #include <iostream>
   using namespace std; 
#else
   #include <iostream.h>
#endif

class InAttach:public Instance
{
  public:
    int InstAttach();
    int InstPasswordChange();
    int InstDetach();
};

int InAttach::InstAttach()
{
  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  sqleatin -- ATTACH TO INSTANCE" << endl;
  cout << "TO ATTACH TO AN INSTANCE:" << endl;

  cout << "    instance alias or name: " << nodeName << endl;
  cout << "      - name is specified for current local instance" << endl;
  cout << "    user ID               : " << user << endl;
  cout << "    password              : " << pswd << endl;

  // attach to an instance
  sqleatin(nodeName, user, pswd, &sqlca);
  DB2_API_CHECK("Instance -- Attach");

  return 0;
} //InAttach::InstAttach

int InAttach::InstPasswordChange()
{
  char *newPassword = NULL;

  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  sqleatcp -- ATTACH AND CHANGE PASSWORD" << endl;
  cout << "TO CHANGE THE PASSWORD USED TO ATTACH TO AN INSTANCE:" << endl;

  // change password to attach to the instance
  cout << "\n  Change the password and attach to the instance." << endl;
  cout << "    instance alias or name: " << nodeName << endl;
  cout << "      - name is specified for current local instance" << endl;
  cout << "    user ID               : " << user << endl;
  cout << "    password              : " << pswd << endl;
  cout << "    new password          : keep the same password" << endl;

  // change password and attach to the instance
  sqleatcp(nodeName, user, pswd, newPassword, &sqlca);
  DB2_API_CHECK("Instance Password -- Change");

  return 0;
} //InAttach::InstPasswordChange

int InAttach::InstDetach()
{
  cout << "\n-----------------------------------------------------------";
  cout << "\nUSE THE DB2 API:" << endl;
  cout << "  sqledtin -- DETACH FROM INSTANCE" << endl;
  cout << "TO DETACH FROM AN INSTANCE:" << endl;

  cout << "\n  Detach from the instance." << endl;
  cout << "    instance alias or name: " << nodeName << endl;
  cout << "      - name is specified for the current local instance" << endl;

  // detach from an instance
  sqledtin(&sqlca);
  DB2_API_CHECK("Instance -- Detach");

  return 0;
} //InAttach::InstDetach

int main(int argc, char *argv[])
{
  int rc = 0;
  InAttach inst;

  // check the command line arguments
  if (argc != 4)
  {
    cout << "\nUSAGE: " << argv[0]
         << " nodeName (or currentLocalInstanceName) user password" << endl;
    return 1;
  }
  inst.setInstance(argv[1], argv[2], argv[3]);

  cout << "\nTHIS SAMPLE SHOWS HOW TO ATTACH TO/DETACH FROM AN INSTANCE."
       << endl;

  rc = inst.InstAttach();
  rc = inst.InstPasswordChange();
  rc = inst.InstDetach();

  return 0;
} //main

