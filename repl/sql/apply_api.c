/*********************************************************************/
/*  IBM DataPropagator Relational Apply API for Unix/Windows NT      */
/*                                                                   */ 
/*    Sample APPLY API program                                       */
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
/* This program is an example of invoking the Apply API from within  */
/* your application.All the options available on the command line    */
/* to invoke asnapply are available through this API too. You must   */
/* specify the COPYONCE option for the Apply program because only    */
/* synchronous execution is supported with this API.                 */
/*                                                                   */
/* Minimum or Mandatory Input to the Apply API is:                   */
/*    Apply Qualifier, Control Server and COPYONCE option            */
/*                                                                   */
/*            Other input options could be added as desired.         */
/*                                                                   */
/* Output: 0  -- indicates Apply program ran successfully;           */
/*                                                                   */
/*         other values -- indicates Apply program did not run       */
/*                         sucessfully.                              */
/*                                                                   */ 
/* You will need to copy this program and modify the Apply Qualifier */
/* and Control Server to reflect your own. This is just a sample     */
/* application. A makefile is provided for the different platforms   */
/* to compile and link the application. This API needs an include    */
/* file called "asn.h" that contains the definitions and function    */
/* prototypes. This is available in the sqllib/include directory for */
/* all platforms.                                                    */
/* The API is included in a shared library called db2repl.dll on     */
/* Windows in sqllib/bin and libdb2repl.a or libdb2repl.so on UNIX   */
/* in sqllib/lib directory. You will also need to link with          */
/* on Windows.                                                       */
/*                                                                   */
/*********************************************************************/ 
/*********************************************************************/
/*                                                                   */
/*     Modifying the apply_api.c sample program                      */
/*     ----------------------------------------                      */
/*     - make your updates to the sample program (apply_api.c)       */
/*                                                                   */
/*     - compile and link the sample program after the desired       */
/*       changes are made by using the sample makefile that is       */
/*       provided for either NT or UNIX. Update the makefile to      */
/*       reflect your sqllib dir or path.                            */
/*                UNIX: apply_api_unix.mak                           */
/*                NT  : apply_api_nt.mak                             */ 
/*                                                                   */
/*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asn.h"                      /* replication API parameters */


/*********************************************************************/
/* This is a helper function to print out parameter contents as      */
/* invoked by user.                                                  */ 
/*********************************************************************/
int printParms(const struct asnParms parms)
{
  int count = 0;
  printf("Start Apply from API: asnapply ");
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
/* This main routine sets the parameters required by Apply and       */
/* invokes asnApply. The variable rc indicates if Apply ran          */
/* successfully or not.                                              */
/*********************************************************************/
int main(int argc, char** argv)
{
  
  struct asnParms applyParms;
  struct asnParm *currParm;
  int rc = 0;
  int count = 0;

  /******************************************************/
  /* This example has 4 parameters passed to Apply      */
  /* Note: If you desire to eliminate some of the       */
  /* parameters, make sure you change the parmCount and */
  /* applyParms.parms array appropriately.              */
  /******************************************************/
  applyParms.parmCount = 4;             /* number of parameters */

  applyParms.parms = (struct asnParm **)malloc (applyParms.parmCount * 
	                                            sizeof(struct asnParm*));

  /******************************************************/
  /* modify the string "APPQUAL" to reflect your own    */
  /* Apply Qualifier.                                   */
  /******************************************************/  
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"APPLY_QUAL=APPQUAL");      
  currParm->byteCount = strlen(currParm->val);
  applyParms.parms[0]=currParm;           /* first Apply parameter */

  /******************************************************/
  /* modify the string "CNTLSRV" to reflect your Control*/
  /* Server.                                            */
  /******************************************************/   
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"CONTROL_SERVER=CNTLSRV");
  currParm->byteCount = strlen(currParm->val);
  applyParms.parms[1]=currParm;           /* second Apply parameter */

  /******************************************************/
  /* add this parameter to send all messages to both the*/
  /* standard output and the log file                   */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"LOGSTDOUT");
  currParm->byteCount = strlen(currParm->val);
  applyParms.parms[2]=currParm;           /* third Apply parameter */

  /******************************************************/
  /* Required: COPYONCE                                 */
  /******************************************************/ 
  currParm = (struct asnParm *)malloc(sizeof(struct asnParm));
  strcpy(currParm->val,"COPYONCE");
  currParm->byteCount = strlen(currParm->val);
  applyParms.parms[3]=currParm;           /* fourth Apply parameter */ 
  
  /******************************************************/
  /* other parameters you can add:                      */
  /* (Please refer to the Replication Guide and         */
  /*  Reference for parameter details)                  */
  /*----------------------------------------------------*/
  /*  APPLY_PATH=path                                   */
  /*  PWDFILE=filename                                  */
  /*  LOGREUSE                                          */
  /*  LOADXIT                                           */
  /*  INAMSG                                            */
  /*  NOTIFY                                            */
  /*  SLEEP                                             */
  /*  TRLREUSE                                          */
  /*  OPT4ONE                                           */
  /*  DELAY                                             */
  /*  ERRWAIT                                           */
  /*  SQLERRORCONTINUE                                  */
  /*  SPILLFILE=disk                                    */
  /*  TERM                                              */
  /******************************************************/ 
  
  rc = printParms(applyParms);            /* print parameters to verify */
  if ( rc == -1 )                         /* no parameters specified */
    return(rc);

  rc = asnApply(&applyParms);             /* invoke Apply API */ 
  
  if ( rc == 0 )                          /* check return code */
     printf("Apply completed sucessfully.\n");
  else
     printf("Apply failed with rc = %d\n",rc);
    
  for(count=0; count < applyParms.parmCount; count++)
    free(applyParms.parms[count]);               
  free( applyParms.parms);                 /* free parameter list */
 
  return(rc);
}

