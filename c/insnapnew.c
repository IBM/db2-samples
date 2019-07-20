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
** SOURCE FILE NAME: insnapnew.c 
**
** SAMPLE: Capture a snapshot at the instance level
**          
**         This sample creates an instance attachment, enables throttling
**         for utilities and calls functions in utilsnap.c to capture an 
**         instance-level snapshot and print the monitor data.
**
** DB2 APIs USED:
**         db2GetSnapshot -- Get Snapshot
**
** STRUCTURES USED:
**         sqlma
**
** OUTPUT FILE: insnap.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C applications, see the Application
** Development Guide.
**
** For information on DB2 APIs, see the Administrative API Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#include "utilsnap.c"

int GetInstanceSnapshot(void);

int main(int argc, char *argv[])
{
  int rc = 0;
  char nodeName[SQL_INSTNAME_SZ + 1];
  char user[USERID_SZ + 1];
  char pswd[PSWD_SZ + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck2(argc, argv, nodeName, user, pswd);
  if (rc != 0) return rc;

  printf("\nTHIS SAMPLE SHOWS HOW TO GET AN INSTANCE LEVEL SNAPSHOT.\n");

  /* attach to a local or remote instance */
  rc = InstanceAttach(nodeName, user, pswd);
  if (rc != 0) return rc;

  /* turn on all the monitor switches */
  rc = TurnOnAllMonitorSwitches();
  if (rc != 0) return rc;
  
  /* update UTIL_IMPACT_LIM parameter */
  rc = UpdateUtilImpactLim();
  if (rc != 0) return rc;

  /* capture a snapshot at the instance level and print the monitor data */
  rc = GetInstanceSnapshot();

  /* detach from the local or remote instance */
  rc = InstanceDetach(nodeName);

  return rc;
} /* main */

/***************************************************************************/
/* GetInstanceSnapshot                                                     */
/* Construct new request stream with values that tell the db2GetSnapshot   */
/* API capture an instance level snapshot. Then pass the sqlma to the      */
/* GetSnapshot function in utilsnap.c, which captures the snapshot (using  */
/* the db2GetSnapshot API) and prints the monitor data.                    */
/***************************************************************************/
int GetInstanceSnapshot(void)
{
  int rc = 0;                   /* return code */
  db2AddSnapshotRqstData snapReq;
  struct sqlca sqlca;

  memset(&snapReq, 0, sizeof(snapReq));
  memset(&sqlca  , 0, sizeof(sqlca));

  /* noqual 1 */
  snapReq.pioRequestData = NULL;
  snapReq.iRequestType   = SQLMA_DB2;
  rc = db2AddSnapshotRequest(db2Version970, &snapReq, &sqlca);
  sqlmCheckRC(rc);

  rc = GetSnapshotNew(&snapReq);

exit:

  return rc;
} /* GetInstanceSnapshot */
