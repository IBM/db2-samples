/*********************************************************************/
/*  IBM Q Replication Q Capture API for Unix/Windows NT              */
/*                                                                   */
/*    Sample Q CAPTURE API program                                   */
/*                                                                   */
/*     Licensed Materials - Property of IBM                          */
/*                                                                   */
/*     (C) Copyright IBM Corp. 2004 All Rights Reserved              */
/*                                                                   */
/*     US Government Users Restricted Rights - Use, duplication      */
/*     or disclosure restricted by GSA ADP Schedule Contract         */
/*     with IBM Corp.                                                */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*                                                                   */
/*           NOTICE TO USERS OF THE SOURCE CODE EXAMPLE              */
/*                                                                   */
/* INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE   */
/* CODE EXAMPLE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         */
/* EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO THE IMPLIED   */
/* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR        */
/* PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE */
/* SOURCE CODE EXAMPLE IS WITH YOU. SHOULD ANY PART OF THE SOURCE    */
/* CODE EXAMPLE PROVES DEFECTIVE, YOU (AND NOT IBM) ASSUME THE       */
/* ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.     */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                */
/*     PLEASE READ THE FOLLOWING BEFORE PROCEEDING...                */
/*     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                */
/*********************************************************************/
/*********************************************************************/
/* This program is an example of invoking the Q Capture API from     */
/* within your application. All the options available on the command */
/* line to invoke asnqcap are available through this API too. You    */
/* must specify the AUTOSTOP option for the Capture program because  */
/* only synchronous execution is supported with this API.            */
/*                                                                   */
/* Minimum or Mandatory Input to the Q Capture API is:               */
/*    Capture Server                                                 */
/*                                                                   */
/*            Other input options could be added as desired.         */
/*                                                                   */
/* Output: 0  -- indicates Q Capture program ran successfully;       */
/*                                                                   */
/*         other values -- indicates Q Capture program did not run   */
/*                         successfully.                             */
/*                                                                   */
/* You will need to copy this program and modify the Capture Server  */
/* name to reflect your own. You need to specify start mode too. This*/
/* is just a sample application. A makefile is provided for the      */
/* different platforms to compile and link the application. This API */
/* needs an include file called "asn.h" that contains the definitions*/
/* and function prototypes. This is available in the sqllib/include  */
/* directory for all platforms.                                      */
/* The API is included in a shared library called db2repl.dll on     */
/* Windows in sqllib/bin and libdb2repl.a or libdb2repl.so on UNIX   */
/* in sqllib/lib directory. You will also need to link with          */
/* db2repl.lib on Windows.                                           */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*     Modifying the qcapture_api.C sample program                   */
/*     -------------------------------------------                   */
/*     - make your updates to the sample program (qcapture_api.C)    */
/*                                                                   */
/*     - compile and link the sample program after the desired       */
/*       changes are made by using the sample makefile that is       */
/*       provided for either NT or UNIX. Update the makefile to      */
/*       reflect your sqllib dir or path.                            */
/*                UNIX: qcapture_api_unix.mak                        */
/*                NT  : qcapture_api_nt.mak                          */
/*                                                                   */
/*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asn.h"                       /* replication API parameters */

/*********************************************************************/
/* This main routine sets the parameters required by Q Capture and   */
/* invokes asnQCapture. The variable rc indicates if Q Capture ran   */
/* successfully or not.                                              */
/*********************************************************************/
int main(int argc, char** argv)
{
  int rc = 0;
  int count = 0;
   
  /******************************************************/
  /*****    Sample invocation of Q Capture API      *****/
  /******************************************************/
  char **qcapArgv;              /* Q Capture parameters */
  int    qcapArgc = 5;          /* Number of parameters */
  
  qcapArgv = (char**) malloc( ( qcapArgc ) * sizeof( char * ) ) ;
   
  /******************************************************/
  /* This example has 4 parameters passed to Q Capture  */
  /* Note: The first parameter is the function name     */
  /******************************************************/
  qcapArgv[0] = strdup("asnQCapture");

  /******************************************************/
  /* modify the string "CAPSRV" to reflect your own     */
  /* Capture Server.                                    */
  /******************************************************/  
  qcapArgv[1] = strdup("CAPTURE_SERVER=CAPSRV");

  /******************************************************/
  /* modify the string "WARMSI" to reflect your start   */
  /* mode for capture.                                  */
  /******************************************************/ 
  qcapArgv[2] = strdup("STARTMODE=WARMSI");

  /******************************************************/
  /* add this parameter to send all messages to both the*/
  /* standard output and the log file                   */
  /******************************************************/ 
  qcapArgv[3] = strdup("LOGSTDOUT");
  
  /******************************************************/
  /* stop Q Capture when hitting the end of the log     */
  /******************************************************/ 
  qcapArgv[4] = strdup("AUTOSTOP");
    
  /******************************************************/
  /* other parameters you can add:                      */
  /* (Please refer to the Replication Guide and         */
  /*  Reference for parameter details)                  */
  /*----------------------------------------------------*/
  /*  ADD_PARTITION                                     */
  /*  CAPTURE_SCHEMA=schema                             */
  /*  CAPTURE_PATH=path                                 */
  /*  COMMIT_INTERVAL                                   */
  /*  LOGREUSE                                          */
  /*  MEMORY_LIMIT=n                                    */
  /*  MONITOR_INTERVAL=n                                */
  /*  MONITOR_LIMIT=n                                   */
  /*  PRUNE_INTERVAL=n                                  */
  /*  SIGNAL_LIMIT=n                                    */
  /*  SLEEP_INTERVAL=n                                  */
  /*  TERM                                              */
  /*  TRACE_LIMIT=n                                     */
  /******************************************************/ 
  
  rc = asnQCapture(qcapArgc, qcapArgv);    /* invoke Q Capture API */ 
  
  if ( rc == 0 )                           /* check rc from Q Capture */
     printf("QCapture completed sucessfully.\n");
  else
     printf("QCapture failed with rc = %d\n",rc);
  
  /******************************************************/
  /* Clean up parameter list                            */
  /******************************************************/
  for(count=0; count < qcapArgc; count++)
  {
    free(qcapArgv[count]);
  }
  free(qcapArgv);

  return(rc);
}
