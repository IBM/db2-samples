/*********************************************************************/
/*  IBM DataPropagator Relational Monitor API for Unix/Windows NT    */
/*                                                                   */ 
/*    Sample MONITOR API program                                     */ 
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
/* This program is an example of invoking the Monitor API from within*/
/* your application.All the options available on the command line    */
/* to invoke asnmon are available through this API too. You must     */
/* specify the RUNONCE option for the Monitor program because only   */
/* synchronous execution is supported with this API.                 */
/*                                                                   */
/* Minimum or Mandatory Input to the Monitor API is:                 */
/*    Monitor Qualifier, Monitor Server and RUNONCE option           */
/*                                                                   */
/*            Other input options could be added as desired.         */
/*                                                                   */
/* Output: 0  -- indicates Monitor program ran successfully;         */
/*                                                                   */
/*         other values -- indicates Monitor program did not run     */
/*                         sucessfully.                              */
/*                                                                   */ 
/* You will need to copy this program and modify the Monitor         */
/* Qualifier and Monitor Server to reflect your own. This is just a  */
/* sample application. A makefile is provided for the different      */
/* platforms to compile and link the application. This API needs an  */
/* include file called "asn.h" that contains the definitions         */
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
/*     Modifying the monitor_api.c sample program                    */
/*     ------------------------------------------                    */
/*     - make your updates to the sample program (monitor_api.c)     */
/*                                                                   */
/*     - compile and link the sample program after the desired       */
/*       changes are made by using the sample makefile that is       */
/*       provided for either NT or UNIX. Update the makefile to      */
/*       reflect your sqllib dir or path.                            */
/*                UNIX: monitor_api_unix.mak                         */
/*                NT  : monitor_api_nt.mak                           */ 
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
  printf("Start Monitor from API: asnmon ");
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
/* This main routine sets the parameters required by Monitor and     */
/* invokes asnMonitor. The variable rc indicates if Monitor ran      */
/* successfully or not.                                              */
/*********************************************************************/
int main(int argc, char** argv)
{
  struct asnParms monitorParms;
  struct asnParm *currParm;
  int rc = 0;
  int count = 0;
   
  /******************************************************/
  /* This example has 4 parameters passed to Monitor    */
  /* Note: If you desire to eliminate some of the       */
  /* parameters, make sure you change the parmCount and */
  /* monitorParms.parms array appropriately.            */
  /******************************************************/
  monitorParms.parmCount = 4;             /* number of parameters */
  
  monitorParms.parms = (struct asnParm **)malloc (monitorParms.parmCount * 
	                                              sizeof(struct asnParm*));

  /******************************************************/
  /* modify the string "MONSRV" to reflect your own     */
  /* Monitor Server.                                    */
  /******************************************************/  
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"MONITOR_SERVER=MONSRV");       
  currParm->byteCount = strlen(currParm->val);
  monitorParms.parms[0]=currParm;         /* first monitor parameter */

  /******************************************************/
  /* modify the string "MONQUAL" to reflect your own    */
  /* Monitor Qualifier.                                 */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"MONITOR_QUAL=MONQUAL");
  currParm->byteCount = strlen(currParm->val);
  monitorParms.parms[1]=currParm;         /* second monitor parameter */
 
  /******************************************************/
  /* add this parameter to send all messages to both the*/
  /* standard output and the log file                   */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"LOGSTDOUT");
  currParm->byteCount = strlen(currParm->val);
  monitorParms.parms[2]=currParm;         /* third monitor parameter */
    
  /******************************************************/
  /* Required: RUNONCE                                  */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"RUNONCE");
  currParm->byteCount = strlen(currParm->val);
  monitorParms.parms[3]=currParm;         /* fourth monitor parameter */

  /******************************************************/
  /* other parameters you can add:                      */
  /* (Please refer to the Replication Guide and         */
  /*  Reference for parameter details)                  */
  /*----------------------------------------------------*/
  /*  MONITOR_INTERVAL=n                                */
  /*  AUTOPRUNE                                         */
  /*  LOGREUSE                                          */
  /*  ALERT_PRUNE_LIMIT=n                               */
  /*  TRACE_LIMIT=n                                     */
  /*  MAX_NOTIFICATIONS_PER_ALERT=n                     */
  /*  MAX_NOTIFICATIONS_MINUTES=n                       */
  /*  PWDFILE=filepath                                  */
  /*  MONITOR_PATH=path                                 */
  /*  MONITOR_ERRORS=address                            */
  /*  EMAIL_SERVER=servername                           */
  /******************************************************/ 
  
  rc = printParms(monitorParms);          /* print parameters out to verify */
  if ( rc == -1 )                         /* no parameters specified */
    return(rc);
  
  rc = asnMonitor(&monitorParms);         /* invoke Alert Monitor API */ 
  
  if ( rc == 0 )                          /* check rc from Alert Monitor */
     printf("Alert Monitor completed sucessfully.\n");
  else
     printf("Alert Monitor failed with rc = %d\n",rc);
  
  for(count=0; count < monitorParms.parmCount; count++)
    free(monitorParms.parms[count]);
  free(monitorParms.parms);              /* free parameter list */

  return(rc);
}
