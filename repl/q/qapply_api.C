/*********************************************************************/
/*  IBM Q Replication Q Apply API for Unix/Windows NT                */
/*                                                                   */
/*    Sample Q Apply API program                                     */
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
/* This program is an example of invoking the Q Apply API from       */
/* within your application. All the options available on the command */
/* line to invoke asnqcap are available through this API too. You    */
/* must specify the AUTOSTOP option for the Apply program because    */
/* only synchronous execution is supported with this API.            */
/*                                                                   */
/* Minimum or Mandatory Input to the Q Apply API is:                 */
/*    Apply Server                                                   */
/*                                                                   */
/*            Other input options could be added as desired.         */
/*                                                                   */
/* Output: 0  -- indicates Q Apply program ran successfully;         */
/*                                                                   */
/*         other values -- indicates Q Apply program did not run     */
/*                         successfully.                             */
/*                                                                   */
/* You will need to copy this program and modify the Apply Server    */
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
/*     Modifying the qapply_api.C sample program                     */
/*     -------------------------------------------                   */
/*     - make your updates to the sample program (qapply_api.C)      */
/*                                                                   */
/*     - compile and link the sample program after the desired       */
/*       changes are made by using the sample makefile that is       */
/*       provided for either NT or UNIX. Update the makefile to      */
/*       reflect your sqllib dir or path.                            */
/*                UNIX: qapply_api_unix.mak                          */
/*                NT  : qapply_api_nt.mak                            */
/*                                                                   */
/*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asn.h"                       /* replication API parameters */

/*********************************************************************/
/* This main routine sets the parameters required by Q Apply and     */
/* invokes asnQApply. The variable rc indicates if Q Apply ran       */
/* successfully or not.                                              */
/*********************************************************************/
int main(int argc, char** argv)
{
  int rc = 0;
  int count = 0;
   
  /******************************************************/
  /*****     Sample invocation of Q Apply API       *****/
  /******************************************************/
  char **qappArgv;              /* Q Apply parameters   */
  int    qappArgc = 4;          /* Number of parameters */
  
  qappArgv = (char**) malloc( ( qappArgc ) * sizeof( char * ) ) ;
  
  /******************************************************/
  /* This example has 4 parameters passed to Q Apply   */
  /* Note: The first parameter is the function name     */
  /******************************************************/
  qappArgv[0] = strdup("asnQApply");

  /******************************************************/
  /* modify the string "APPSRV" to reflect your own     */
  /* Apply Server.                                      */
  /******************************************************/  
  qappArgv[1] = strdup("APPLY_SERVER=APPSRV");

  /******************************************************/
  /* add this parameter to send all messages to both the*/
  /* standard output and the log file                   */
  /******************************************************/ 
  qappArgv[2] = strdup("LOGSTDOUT");
  
  /******************************************************/
  /* stop Q Capture when hitting the end of the log     */
  /******************************************************/ 
  qappArgv[3] = strdup("AUTOSTOP");
    
  /******************************************************/
  /* other parameters you can add:                      */
  /* (Please refer to the Replication Guide and         */
  /*  Reference for parameter details)                  */
  /*----------------------------------------------------*/
  /*  APPLY_PATH=path                                   */
  /*  Apply_SCHEMA=schema                               */
  /*  DEADLOCK_RETRIES=n                                */
  /*  LOGREUSE                                          */
  /*  MONITOR_INTERVAL=n                                */
  /*  MONITOR_LIMIT=n                                   */
  /*  PRUNE_INTERVAL=n                                  */
  /*  TERM                                              */
  /*  TRACE_LIMIT=n                                     */
  /******************************************************/ 
  
  rc = asnQApply(qappArgc, qappArgv);            /* invoke Q Apply API */ 
  
  if ( rc == 0 )                           /* check rc from Q Apply */
     printf("QApply completed sucessfully.\n");
  else
     printf("QApply failed with rc = %d\n",rc);
  
  /******************************************************/
  /* Clean up parameter list                            */
  /******************************************************/
  for(count=0; count < qappArgc; count++)
  {
    free(qappArgv[count]);
  }
  free(qappArgv);

  return(rc);
}
