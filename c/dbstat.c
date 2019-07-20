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
** SOURCE FILE NAME: dbstat.c 
**
** SAMPLE: Provide database statistics about DB2 performance 
**          
**         This sample monitors the database activity through performance 
**         related parameters. For information on using the parameters,
**         enter: "dbstat -h". If you execute the program without any
**         parameters, it will monitor the sample database with 10 intervals 
**         of 20 seconds for a total of 200 seconds, then display the
**         output and complete, returning to the command prompt.
**
**         The first interval is always taken at the end of the specified 
**         length. For example, if the interval is 30 seconds long (specified 
**         with the -l option), the first set of results will appear at the 
**         end of the 30th second. The sample is meant to monitor an active 
**         database, so you must connect to the database to receive any
**         information. For meaningful data, you can run the sample during
**         low, moderate or heavy database usage.
**
**         To run the sample using the parameter defaults, enter these
**         commands:
**             db2start
**             db2 connect to sample
**             dbstat
**
** DB2 APIs USED:
**         INSTANCE ATTACH               sqleatin()
**         ENABLE/DISABLE MONITORS       sqlmon()
**         RESET MONITORS                sqlmrst()
**         ESTIMATE SNAP BUFF SIZE       sqlmonsz()
**         TAKE MONITOR DATA             sqlmonss()
**
*****************************************************************************
*
* For information on developing C applications, see the Application
* Development Guide.
*
* For more information on DB2 APIs, see the Administrative API Reference.
*
* For the latest information on programming, compiling, and running DB2 
* applications, visit the DB2 application development website: 
*     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/

#if defined (WIN32) /* sleep call is in windows.h for intel and unistd.h for unix */
  #include <windows.h>
#else
  #include <unistd.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlsystm.h>
#include "sqlca.h"
#include "sqlutil.h"
#include "sqlmon.h"
#include "utilapi.h"


#define TRUE 1
#define FALSE 0
#define NUM_MON_DATA 18
#define DEFAULT (float)0

#define conn 0
#define trans 1
#define rselects 2
#define rupdates 3
#define rdels 4
#define rins 5
#define select 6 /*select statements*/
#define uid 7 /* update insert delete */
#define logpgwrt 8
#define ddlck 9
#define sortoflw 10
#define sorts 11
#define buffDL 12 /* data logical */
#define buffDP 13 /* data physical */
#define buffIL 14 /* index logical */
#define buffIP 15 /* index physical */
#define buffDPW 16
#define buffIPW 17

#define LOG_PAGE_SIZE 4 /*define log page size as 4k*/

struct node
{
  int count;
  sqluint32 data[NUM_MON_DATA] ;
  struct node *next;
};


int First(struct node *cur);

int Last(struct node *cur);

int Past(struct node *cur);

int New_n(struct node *l_n);

void Process_n(struct node *f_n,  int duration);

void PrintData(sqluint32 *,int interval,int secs);

void PrintHeader();

int Enable(int on);

int Reset(char *db);

int Collect(char *dbnm);


struct node *f_ptr;
struct node *cur_ptr;
int	duration = 20; 
FILE *outstream;
int	EXTENDED = FALSE;
   
int main (int argc, char* argv[])
{
  struct sqlca sqlca;
  char userid[9];
  char passwd[19];
  char nodename[9];
  int interval = 10;
  char dbname[9]= "sample";    /* database to be monitored */
  int	OUTF = FALSE;
  int DB = FALSE;
  int	ATTACH = FALSE;
  int	i = 0; 
  int rc = 0;
  static char  *usage = \
		"USAGE:\n\tdb2stat  [-i numInts] [-l intLenght] [-d dbname] \
[-e] [-f fileName] [-a -n nodename -u userid -p passwd] where \n \
   		\t -i numInts  : number of intervals \n \
   		\t -l intLenght: interval lenght in sec \n \
   		\t -d dbname   : database to be monitored \n \
   		\t -e          : optional extended info on pool r/w \n \
   		\t -a          : attach to a node \n\
   		\t -u userid   : user name needed if -a specified \n\
   		\t -p passwd   : password for user if -a specified \n\
   		\t -n nodename : node name if -a specified \n\
   		\t -f fileName : save the stats to fileName \n"; 
   		 
  outstream = stdout;

  if (argc > 18) 
  {
    printf(usage, argv[0]);   
    rc = 1;                
    return rc;
  }

  for (i = 1; rc == 0 && i < argc; i++) 
  {
    if (strcmp(argv[i], "-i") == 0) 
    {
    	i++;
    	interval = atoi(argv[i]);
    	continue;
    }    
    if (strcmp(argv[i], "-l") == 0) 
    {
    	i++;
    	duration = atoi(argv[i]) ;
    	continue;
    }    
    if (strcmp(argv[i], "-d") == 0) 
    {
    	i++;
    	DB = TRUE;
    	strcpy(dbname,argv[i]);
    	continue;
    }    
    if (strcmp(argv[i], "-e") == 0) 
    {
    	EXTENDED = TRUE;
    	continue;
    }    
    if (strcmp(argv[i], "-f") == 0) 
    {
    	i++;
    	outstream = fopen(argv[i],"a");
    	if(outstream == NULL)
	{
     	  printf("Could not open file %s\n",argv[i]);
     	  printf("Defaulting to screen output \n");
     	  outstream = stdout;
	}
    	OUTF = TRUE;			
    	continue;
    } 
    if (strcmp(argv[i], "-a") == 0) 
    {
    	ATTACH = TRUE;
    	continue;
    }
    if (strcmp(argv[i], "-u") == 0) 
    {
    	i++;			
    	strcpy(userid,argv[i]);
    	continue;
    } 
    if (strcmp(argv[i], "-p") == 0) 
    {
    	i++;			
    	strcpy(passwd,argv[i]);
    	continue;
    } 
    if (strcmp(argv[i], "-n") == 0) 
    {
    	i++;			
    	strcpy(nodename,argv[i]);
    	continue;
    } 
    printf(usage, argv[0]);
    rc = 1;
    return rc;
  }
  /* Check to see if a database is specified */  
  if(!DB)
  {
    printf("Using default database: %s\n",dbname);
  }
  
  if(ATTACH)
  {
    sqleatin (nodename, userid, passwd, &sqlca);
    DB2_API_CHECK("ATTACHING TO NODE");
    if(rc != 0)
      return rc;
  }
		
  f_ptr = (struct node*)malloc(sizeof(struct node));
  f_ptr->count = 1;
  f_ptr->next = NULL;
  
  cur_ptr = f_ptr;
  PrintHeader();
  rc = Enable(TRUE);
  if(rc != 0)
    return rc;
  for (i=0;i < interval;i++)
  {
    rc = Reset(dbname); 
    if(rc != 0)
    return rc;
    #if defined (_WIN32)
      Sleep(duration*1000);
    #else
      sleep(duration);
    #endif
    rc = Collect(dbname);
    if(rc != 0)
      return rc;
  }

  fprintf(outstream,"\nCombined Statistics: \n");  
  PrintHeader();   
  Process_n(f_ptr,duration);
  rc = Enable(FALSE);
  if(OUTF)
  {
    rc=fclose(outstream);
    if (rc != 0)
    	fprintf(outstream,"Error closing output file at the end, rc %d",rc);
  }
  	
  return rc;
} /* main */ 

int Enable(int on)
{
  struct sqlca sqlca;
  int rc = 0;
  int i = 0;
  struct sqlm_recording_group states[SQLM_NUM_GROUPS];
  for(i = 0;i < SQLM_NUM_GROUPS;i++)
    states[i].input_state = SQLM_HOLD;
  rc = sqlmon(SQLM_DBMON_VERSION5_2,NULL,states,&sqlca);
  DB2_API_CHECK("Inspecting monitors failed");
  if (rc != 0)
    return rc;
  if(on)
  {
    if(states[3].output_state != SQLM_ON)
    	states[3].input_state = SQLM_ON;
    if(states[5].output_state != SQLM_ON)
    	states[5].input_state = SQLM_ON;
  }
  else
  {
    states[3].input_state = SQLM_OFF;
    states[5].input_state = SQLM_OFF;
  }
  
  rc = sqlmon(SQLM_DBMON_VERSION5_2,NULL,states,&sqlca);
  DB2_API_CHECK("Enabling/Disabling monitors failed");
  if (rc != 0)
    return rc;
  	
  return rc;
} /* Enable */

int Reset(char* db)
{
  struct sqlca sqlca;
  int rc = 0;
  rc=sqlmrset(SQLM_DBMON_VERSION5_2,NULL,SQLM_OFF,db,&sqlca);
  /*check sqlca*/
  if(rc != 0)
    DB2_API_CHECK("Reset monitors failed"); 
  return rc;
} /* Reset */
		
int Collect(char *dbnm)
{
  char *buffer_ptr;         /* buffer for the SNAPSHOT */
  sqlm_collected collected;     /* info. structure for DB SYS. MON. APIs */
  int rc;
  struct sqlca sqlca;
  sqluint32 buffer_sz;
  int i = 0;
  struct sqlm_db2 *db2ptr;
  struct sqlm_dbase *dbase_ptr;
  
  struct sqlma* sqlma = (struct sqlma *) malloc(SQLMASIZE(1));
  /* Request SQLMA_DBASE in sqlma */
  
  sqlma->obj_num = 1;
  strcpy(sqlma->obj_var[0].object, dbnm);
  sqlma->obj_var[0].obj_type = SQLMA_DBASE;
  sqlma->obj_var[0].agent_id = 0L;
    
  rc=sqlmonsz(SQLM_DBMON_VERSION2, NULL, sqlma, &buffer_sz, &sqlca);
  if(rc != 0)
  {
    DB2_API_CHECK("COLLECTING DATA");
    return rc;
  }

  /* Take the Snapshot*/
  buffer_ptr = (char *) malloc(buffer_sz);     /* Allocate the buffer */
  
  rc = sqlmonss(SQLM_DBMON_VERSION2, NULL, sqlma, buffer_sz, buffer_ptr,
                &collected, &sqlca);
  if(rc != 0)
  {
    DB2_API_CHECK("Error calling monitor snapshot");
    return rc;
  }
  
  /* Process snapshot output in buffer_ptr*/
  if (((unsigned )*(buffer_ptr+4)) == SQLM_DBASE_SS)
  {
    dbase_ptr = (struct sqlm_dbase *)(buffer_ptr);
    rc = New_n(cur_ptr);
    if(rc > 0)
    {
      cur_ptr = cur_ptr->next;
      cur_ptr->data[conn] = dbase_ptr->connections_top;
      cur_ptr->data[trans] = dbase_ptr->commit_sql_stmts+
                           dbase_ptr->rollback_sql_stmts;
      cur_ptr->data[rselects] = dbase_ptr->rows_selected;
      cur_ptr->data[rupdates] = dbase_ptr->rows_updated;
      cur_ptr->data[rdels] = dbase_ptr->rows_deleted;
      cur_ptr->data[rins] = dbase_ptr->rows_inserted;
      cur_ptr->data[select] = dbase_ptr->select_sql_stmts;
      cur_ptr->data[uid] = dbase_ptr->uid_sql_stmts;
      cur_ptr->data[logpgwrt] = dbase_ptr->log_writes;
      cur_ptr->data[ddlck] = dbase_ptr->deadlocks;
      cur_ptr->data[sortoflw] = dbase_ptr->sort_overflows;
      cur_ptr->data[sorts] = dbase_ptr->total_sorts;
      cur_ptr->data[buffDL] = dbase_ptr->pool_data_l_reads; /* data log */
      cur_ptr->data[buffDP] = dbase_ptr->pool_data_p_reads; /* data phys */
      cur_ptr->data[buffIL] = dbase_ptr->pool_index_l_reads; /* idx log */
      cur_ptr->data[buffIP] = dbase_ptr->pool_index_p_reads; /* idx phys */
      cur_ptr->data[buffDPW] = dbase_ptr->pool_data_writes;
      cur_ptr->data[buffIPW] = dbase_ptr->pool_index_writes;
      PrintData(cur_ptr->data,1,duration);
    }
    else
      return rc;
  }

  /* Free the buffer */
  free(buffer_ptr);
  free(sqlma);
  return 0;
} /* Collect */


/*******************************************************************************
** Start of data linked list functions
** PURPOSE : Linked list used by the db2stat in order to save the monitoring 
**		data 
** 
*******************************************************************************/

int First(struct node *cur)
{
  if (cur->count == 1)
    return TRUE;
  else
  return FALSE;
} /* First */

int Last(struct node *cur)
{
  if (cur->next == NULL)
    return TRUE;
  else
    return FALSE;
} /* Last */
	
int Past(struct node *cur)
{
  if (cur == NULL)
    return TRUE;
  else
    return FALSE;
} /* Past */

int New_n(struct node *l_n)
{
  struct node *new_node;
  int rc=0;
  if (!Last (l_n))
    return -1;
  l_n->next = (struct node*)malloc(sizeof(struct node));
  if (l_n->next != NULL)
  {
    new_node = l_n->next;
    memset(new_node,'\0',sizeof(struct node));
    new_node->count = l_n->count+1;
    new_node->next = NULL;
    rc = 1;
  }
  else
    rc = -1;
  return rc;
} /* New_n */


void Process_n(struct node *f_n, int duration)
{
  sqluint32 combined[NUM_MON_DATA]; 	
  struct node *trav = f_n;
  int i = 0;
  int totalIntervals = 0;
  for (i=0;i < NUM_MON_DATA;i++)
  	combined[i] = 0;
  do
  {
    if (!First(trav))
    {
      totalIntervals++;
      for (i=0;i < NUM_MON_DATA;i++)
      {
     	  combined[i] += trav->data[i];
      }
    }
    if (Last(trav))
      break;
    else
      trav = trav->next;
  }while(TRUE);
  if(totalIntervals == 0)
    totalIntervals=1;
  PrintData(combined, totalIntervals, (totalIntervals*duration));	
} /* Process_n */

void PrintHeader()
{	
  fprintf(outstream,"  conn     tps    slps   uidps dlc ");
  fprintf(outstream,"   spt   sopt  dphr   iphr  lg_kbs");
  if(EXTENDED)
    fprintf(outstream,"     ppr     lpr     ppw"); 
  fprintf(outstream,"\n");		
} /* PrintHeader */
		
void PrintData(sqluint32* data,int interval,int secs)
{
  float temp = 0.0;
  fprintf(outstream,"%6.0f",(float)data[conn]/interval);
  temp = (float)data[trans]/secs;
  fprintf(outstream,"%8.1f",temp);
  temp = (float)data[select]/secs;
  fprintf(outstream,"%8.1f",temp);
  temp = (float)data[uid]/secs;
  fprintf(outstream,"%8.1f",temp);
  fprintf(outstream,"%4lu",data[ddlck]);
  if(data[sorts] !=0 && data[trans] !=0)
  {	
    temp = ((float)data[sorts]/data[trans]);
    fprintf(outstream," %6.2f",temp);
  }
  else
    fprintf(outstream," %6.2f",DEFAULT);
  
  if(data[sortoflw] !=0 && data[trans] !=0)   
  {
    temp = ((float)data[sortoflw]/data[trans]);
    fprintf(outstream," %6.2f",temp);
  }
  else
    fprintf(outstream," %6.2f",DEFAULT);
  
  if(data[buffDL] != 0)
  {
    temp = (1-((float)data[buffDP]/data[buffDL]))*100;
    fprintf(outstream," %5.1f%%",temp);
  }
  else
    fprintf(outstream," %5.1f%%",DEFAULT);
  
  if(data[buffIL] != 0) 
  {
    temp = (1-((float)data[buffIP]/data[buffIL]))*100;
    fprintf(outstream," %5.1f%%",temp);
  }
  else
    fprintf(outstream," %5.1f%%",DEFAULT);
  
  temp = ((float)data[logpgwrt]*LOG_PAGE_SIZE)/secs;
  fprintf(outstream,"%7.0f",temp);
  
  if(EXTENDED)
  {
    fprintf(outstream," %7lu",data[buffDP]+data[buffIP]);
    fprintf(outstream," %7lu",data[buffDL]+data[buffIL]);
    fprintf(outstream," %7lu",data[buffDPW]+data[buffIPW]);
  }
  fprintf(outstream,"\n");
} /* PrintData */
