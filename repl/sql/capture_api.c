/*********************************************************************/
/*  IBM DataPropagator Relational Capture API for Unix/Windows NT    */
/*                                                                   */ 
/*    Sample CAPTURE API program                                     */ 
/*                                                                   */
/*     Licensed Materials - Property of IBM                          */
/*                                                                   */
/*     (C) Copyright IBM Corp. 2002 All Rights Reserved              */
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
/* This program is an example of invoking the Capture API from within*/
/* your application.All the options available on the command line    */
/* to invoke asncap are available through this API too. You must     */
/* specify the AUTOSTOP option for the Capture program because only  */
/* synchronous execution is supported with this API.                 */
/*                                                                   */
/* Minimum or Mandatory Input to the Capture API is:                 */
/*    Capture Server, Start Type and AUTOSTOP option                 */
/*                                                                   */
/*            Other input options could be added as desired.         */
/*                                                                   */
/* Output: 0  -- indicates Capture program ran successfully;         */
/*                                                                   */
/*         other values -- indicates Capture program did not run     */
/*                         sucessfully.                              */
/*                                                                   */ 
/* You will need to copy this program and modify the Capture Server  */
/* name to reflect your own. You need to specify start type too. This*/
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
/*     Modifying the capture_api.c sample program                    */
/*     ------------------------------------------                    */
/*     - make your updates to the sample program (capture_api.c)     */
/*                                                                   */
/*     - compile and link the sample program after the desired       */
/*       changes are made by using the sample makefile that is       */
/*       provided for either NT or UNIX. Update the makefile to      */
/*       reflect your sqllib dir or path.                            */
/*                UNIX: capture_api_unix.mak                         */
/*                NT  : capture_api_nt.mak                           */ 
/*                                                                   */
/*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asn.h"                       /* replication API parameters */

/*********************************************************************/
/* This is a helper function to print out parameter contents as      */
/* invoked by user.                                                  */ 
/*********************************************************************/
int printParms(const struct asnParms parms)
{
  int count = 0;
  printf("Start Capture from API: asncap ");
  if ( parms.parmCount > 0 )
   {
      for( count = 0; count < parms.parmCount; count++ )
	{
	  printf("%s ", parms.parms[count]->val);
	}
        printf("\n\n");
        return (0);
   }
  else
  {
    printf("No parameter specified!\n\n");
    return(-1);
  }
}

/*********************************************************************/
/* This main routine sets the parameters required by Capture and     */
/* invokes asnCapture. The variable rc indicates if Capture ran      */
/* successfully or not.                                              */
/*********************************************************************/
int main(int argc, char** argv)
{
  struct asnParms captureParms;
  struct asnParm *currParm;
  int rc = 0;
  int count = 0;
   
  /******************************************************/
  /* This example has 4 parameters passed to Capture    */
  /* Note: If you desire to eliminate some of the       */
  /* parameters, make sure you change the parmCount and */
  /* captureParms.parms array appropriately.             */
  /******************************************************/
  captureParms.parmCount = 4;             /* number of parameters */
  
  captureParms.parms = (struct asnParm **)malloc (captureParms.parmCount *
	                                              sizeof(struct asnParm*));

  /******************************************************/
  /* modify the string "CAPSRV" to reflect your own     */
  /* Capture Server.                                    */
  /******************************************************/  
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"CAPTURE_SERVER=CAPSRV");
  currParm->byteCount = strlen(currParm->val);
  captureParms.parms[0]=currParm;         /* first Capture parameter */

  /******************************************************/
  /* modify the string "WARMSI" to reflect your start   */
  /* mode for capture.                                  */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"STARTMODE=WARMSI");
  currParm->byteCount = strlen(currParm->val);
  captureParms.parms[1]=currParm;         /* second Capture parameter */

  /******************************************************/
  /* add this parameter to send all messages to both the*/
  /* standard output and the log file                   */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"LOGSTDOUT");      
  currParm->byteCount = strlen(currParm->val);
  captureParms.parms[2]=currParm;         /* third Capture parameter */
  
  /******************************************************/
  /* required: AUTOSTOP                                 */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"AUTOSTOP");
  currParm->byteCount = strlen(currParm->val);
  captureParms.parms[3]=currParm;         /* fourth Capture parameter */
    
  /******************************************************/
  /* other parameters you can add:                      */
  /* (Please refer to the Replication Guide and         */
  /*  Reference for parameter details)                  */
  /*----------------------------------------------------*/
  /*  CAPTURE_SCHEMA=schema                             */
  /*  CAPTURE_PATH=path                                 */
  /*  AUTOPRUNE                                         */
  /*  COMMIT_INTERVAL                                   */
  /*  LAG_LIMIT                                         */
  /*  LOGREUSE                                          */
  /*  MEMORY_LIMIT=n                                    */
  /*  MONITOR_INTERVAL=n                                */
  /*  MONITOR_LIMIT=n                                   */
  /*  PRUNE_INTERVAL=n                                  */
  /*  RETENTION_LIMIT=n                                 */
  /*  SLEEP_INTERVAL=n                                  */
  /*  TERM                                              */
  /*  TRACE_LIMIT=n                                     */
  /******************************************************/ 
  
  rc = printParms(captureParms);          /* print parameters out to verify */
  if ( rc == -1 )                         /* no parameters specified */
    return(rc);
  
  rc = asnCapture(&captureParms);         /* invoke Capture API */ 
  
  if ( rc == 0 )                          /* check rc from Capture */
     printf("Capture completed sucessfully.\n");
  else
     printf("Capture failed with rc = %d\n",rc);
  
  for(count=0; count < captureParms.parmCount; count++)
    free(captureParms.parms[count]);
  free(captureParms.parms);              /* free parameter list */

  return(rc);
}
