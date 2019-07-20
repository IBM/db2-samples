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
** SOURCE FILE NAME: clisnap.C
**
** SAMPLE: Capture a snapshot at the client level
**          
**         This sample creates an instance attachment, and calls functions  
**         in utilsnap.C to capture an application-level snapshot and print
**         the monitor data. Monitor data from the application-level
**         logical data groups is unavailable if no applications are
**         connected to the database being monitored.
**
**         In order to access application-level monitor data, you must
**         connect to the relevant database before you run this sample.
**
** DB2 APIs USED:
**         db2GetSnapshot -- Get Snapshot
**
** STRUCTURES USED:
**         sqlma
**
** OUTPUT FILE: clisnap.out (available in the online documentation)
*****************************************************************************
*
* For information on developing C++ applications, see the Application
* Development Guide.
*
* For more information on DB2 APIs, see the Administrative API Reference.
*
* For the latest information on programming, compiling, and running DB2 
* applications, visit the DB2 application development website: 
*     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include <sqlsystm.h>
#if (defined(DB2NT))
#include "utilsnap.cxx"
#else // UNIX
#include "utilsnap.C"
#endif

class ApplicationSnapshot
{
public:
  int GetApplicationSnapshot();
};

/***************************************************************************/
/* GetApplicationSnapshot                                                  */
/* Initialize the sqlma with values that tell the db2GetSnapshot API to    */
/* capture a client level snapshot. Then pass the sqlma to the             */
/* GetSnapshot function in utilsnap.C, which captures the snapshot (using  */
/* the db2GetSnapshot API) and prints the monitor data.                    */
/***************************************************************************/
int ApplicationSnapshot::GetApplicationSnapshot(void)
{
  int rc = 0;                   // return code
  unsigned int obj_num = 3;     // # of objects to monitor
  struct sqlma *ma_ptr = NULL;  // sqlma structure pointer
  unsigned int ma_sz;           // size of sqlma structure
  Snapshot snapshot;            // Snapshot object

  // determine and allocate the required memory for sqlma structure
  // the memory allocated to ma_ptr is freed in the GetSnapshot function
  ma_sz = SQLMASIZE(obj_num);
  ma_ptr = (struct sqlma *) malloc(ma_sz);
  if ( ma_ptr == NULL)
  {
    cout << "error allocating sqlma. Exiting.\n";
    return(99);
  }

  // initialize sqlma structure -- of significant importance here is the
  // "obj_type" parameter, which indicates the categories of monitor data
  // that will be collected
  memset(ma_ptr, '\0', ma_sz);
  ma_ptr->obj_num = obj_num;
  ma_ptr->obj_var[0].obj_type = SQLMA_APPLINFO_ALL;
  ma_ptr->obj_var[1].obj_type = SQLMA_APPL_ALL;
  ma_ptr->obj_var[2].obj_type = SQLMA_APPL_REMOTE_ALL;

  rc = snapshot.GetSnapshot(ma_ptr);

  return rc;
} // ApplicationSnapshot::GetApplicationSnapshot

int main(int argc, char *argv[])
{
  int rc = 0;
  char nodeName[SQL_INSTNAME_SZ + 1];
  char user[USERID_SZ + 1];
  char pswd[PSWD_SZ + 1];
  CmdLineArgs check;            // command line arguments object
  Instance inst;                // Instance object
  ApplicationSnapshot snapshot; // Snapshot object

  // check the command line arguments
  rc = check.CmdLineArgsCheck2(argc, argv, inst);
  if (rc != 0) return rc;

  cout << "\nTHIS SAMPLE SHOWS HOW TO GET A CLIENT LEVEL SNAPSHOT.\n";

  // attach to a local or remote instance
  rc = inst.Attach();
  if (rc != 0) return rc;

  // turn on all the monitor switches
  rc = Snapshot::TurnOnAllMonitorSwitches();
  if (rc != 0) return rc;

  // capture a snapshot at the client level and print the monitor data
  rc = snapshot.GetApplicationSnapshot();

  // detach from the local or remote instance
  rc = inst.Detach();

  return rc;
} // main
