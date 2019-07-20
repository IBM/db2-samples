/***************************************************************************
**  (c) Copyright IBM Corp. 2007 All rights reserved.
**
**  The following sample of source code ("Sample") is owned by International
**  Business Machines Corporation or one of its subsidiaries ("IBM") and is
**  copyrighted and licensed, not sold. You may use, copy, modify, and
**  distribute the Sample in any form without payment to IBM, for the purpose of
**  assisting you in the development of your applications.
**
**  The Sample code is provided to you on an "AS IS" basis, without warranty of
**  any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
**  IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
**  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
**  not allow for the exclusion or limitation of implied warranties, so the above
**  limitations or exclusions may not apply to you. IBM shall not be liable for
**  any damages you suffer as a result of using, copying, modifying or
**  distributing the Sample, even if IBM has been advised of the possibility of
**  such damages.
***************************************************************************
**                                                                         
** SAMPLE FILE NAME: ssv_db_cfg.c                                          
**                                                                         
** PURPOSE         : This sample demonstrates updating & resetting         
**                   database configuration parameters in a Massively      
**                   Parallel Processing (MPP) environment.                
**                                                                         
** USAGE SCENARIO  : This sample demonstrates different options of         
**                   updating & resetting database configuration parameters
**                   in an MPP environment. In an MPP environment, database
**                   configuration parameters can either be updated or     
**                   resetted on a single database partition or on all     
**                   database partitions at once. The sample will use the  
**                   DB CFG parameter 'MAXAPPLS', to demonstrate different 
**                   UPDATE & RESET db cfg command options.                
**                                                                         
** PREREQUISITE    : MPP setup with 3 database partitions:                 
**                     NODE 0: Catalog Node                                
**                     NODE 1: Non-catalog node                            
**                     NODE 2: Non-catalog node                            
**                                                                         
** EXECUTION       : ssv_db_cfg [dbalias [username password]]                                                                **                       
** INPUTS          : NONE                                                  
**                                                                         
** OUTPUT          : Successful update & reset of database configuration   
**                   parameters on different database partitions.          
**                                                                         
** OUTPUT FILE     : ssv_db_cfg.out                                        
**                  (available in the online documentation)                
***************************************************************************
**For more information about the command line processor (CLP) scripts,     
**see the README file.                                                     
**For information on using SQL statements, see the SQL Reference.          
**                                                                         
**For the latest information on programming, building, and running DB2     
**applications, visit the DB2 application development website:             
**http:**www.software.ibm.com*data*db2*udb*ad                              
***************************************************************************

***************************************************************************
** SAMPLE DESCRIPTION                                                      
***************************************************************************
** 1. Update DB CFG parameter on all database partitions at once.          
** 2. Update DB CFG parameter on specified database partition              
** 3. Reset DB CFG parameter on specified database partition               
** 4. Reset DB CFG parameter on all database partitions at once.           
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlenv.h>
#include <sqlutil.h>
#include <db2ApiDf.h>
#include "utilemb.h"

int main(int argc, char *argv[])
{
  int rc = 0;
  struct sqlca sqlca = { 0 };
  char dbAlias[SQL_ALIAS_SZ + 1] = { 0 };
  char user[USERID_SZ + 1] = { 0 };
  char pswd[PSWD_SZ + 1] = { 0 };

/***************************************************************************/
/*   SETUP                                                                 */
/***************************************************************************/
  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\nTHIS SAMPLE SHOWS HOW TO UPDATE DB CFG PARAMETERS IN AN "
         "MPP ENVIRONMENT.\n");

/***************************************************************************/
/* 1. Update DB CFG parameter on all database partitions at once           */
/***************************************************************************/
  rc = updateDbCfgOnAllPartitions(dbAlias);
  if (rc != 0)
  {
    return rc;
  }

/***************************************************************************/
/* 2. Update DB CFG parameter on specified database partition              */
/***************************************************************************/
  rc = updateDbCfgOnOnePartition(dbAlias);
  if (rc != 0)
  {
    return rc;
  }

/***************************************************************************/
/* 3. Reset DB CFG parameter on specified database partition               */
/***************************************************************************/
  rc = resetDbCfgOnOnePartition(dbAlias);
  if (rc != 0)
  {
    return rc;
  }

/***************************************************************************/
/* 4. Reset DB CFG parameter on all database partitions at once            */
/***************************************************************************/
  rc = resetDbCfgOnAllPartitions(dbAlias);
  if (rc != 0)
  {
    return rc;
  }

  return 0;
}

/***************************************************************************/
/* Function: updateDbCfgOnAllPartitions  		                   */
/* Update DB CFG parameter on all database partitions at once              */
/***************************************************************************/
int updateDbCfgOnAllPartitions(char dbAlias[])
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  printf(
    "\n****************************************************************\n");
  printf(
    "** UPDATE DB CFG PARAMETER 'MAXAPPLS' ON ALL DATABASE PARTITIONS **");
  printf(
    "\n****************************************************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- Set DB CFG Parameters\n");
  printf("TO UPDATE DB CFG PARAMETERS.\n");

  /* set the value for db cfg parameter MAXAPPLS to 100*/
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[0].ptrvalue = (char *)malloc(sizeof(sqluint16));
  *(sqluint16 *)(cfgParameters[0].ptrvalue) = 100;

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;

  /* default options will update db cfg parameters on all */
  /* database partitions                                  */
  cfgStruct.flags = db2CfgDatabase;
  cfgStruct.dbname = dbAlias;

  /* set database configuration */
  db2CfgSet( db2Version970,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("Update cfg parameter");

  printf
    ("\nThe DB CFG parameter is updated successfully on all "
     "database partitions.\n");

  return 0;

}

/***************************************************************************/
/* Function: updateDbCfgOnOnePartition                                     */
/* Update DB CFG parameter on specified database partition                 */
/***************************************************************************/
int updateDbCfgOnOnePartition(char dbAlias[])
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  printf(
    "\n****************************************************************\n");
  printf(
    "** UPDATE DB CFG PARAMETER 'MAXAPPLS' ON DATABASE PARTITION 1 **\n");
  printf(
    "******************************************************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- Set DB CFG Parameters\n");
  printf("TO UPDATE DB CFG PARAMETERS.\n");

  /* set the value for db cfg parameter MAXAPPLS to 50*/
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[0].ptrvalue = (char *)malloc(sizeof(sqluint16));
  *(sqluint16 *)(cfgParameters[0].ptrvalue) = 50;

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;

  /* db2CfgSingleDbpartition is used to update db cfg parameters on */
  /* selective database partitions                                  */
  cfgStruct.flags = db2CfgDatabase | db2CfgSingleDbpartition;
  cfgStruct.dbname = dbAlias;

  /* specify the database partition number on which update */
  /* is to be performed                                    */
  cfgStruct.dbpartitionnum = 1;

  /* set database configuration */
  db2CfgSet( db2Version970,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("Update cfg parameter");

  printf("\nThe DB CFG parameter is updated successfully on "
         "database partition 1.\n");

  return 0;
}

/***************************************************************************/
/* Function: resetDbCfgOnOnePartition                                      */
/* Reset DB CFG parameter on specified database partition                  */
/***************************************************************************/
int resetDbCfgOnOnePartition(char dbAlias[])
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  printf(
    "\n*****************************************************************\n");
  printf(
    "** RESET DB CFG PARAMETER 'MAXAPPLS' ON DATABASE PARTITION 1  **\n");
  printf(
    "*******************************************************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- Reet DB CFG Parameters\n");
  printf("TO RESET DB CFG PARAMETERS.\n");

  /* reset db cfg parameter MAXAPPLS */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[0].ptrvalue = (char *)malloc(sizeof(sqluint16));

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;

  /* db2CfgSingleDbpartition is used to reset db cfg parameters on */
  /* selective database partitions                                 */
  cfgStruct.flags = db2CfgDatabase | db2CfgReset | db2CfgSingleDbpartition;
  cfgStruct.dbname = dbAlias;

  /* specify the database partition number on which reset  */
  /* is to be performed                                    */
  cfgStruct.dbpartitionnum = 1;

  /* set database configuration */
  db2CfgSet( db2Version970,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("Reset db cfg parameters");

  printf("\nThe DB CFG parameter is resetted successfully on "
         "database partition 1.\n");

  return 0;

}

/***************************************************************************/
/* Function: resetDbCfgOnAllPartitions                                     */
/* Reset DB CFG parameter on all database partitions at once               */
/***************************************************************************/
int resetDbCfgOnAllPartitions(char dbAlias[])
{
  int          rc = 0;
  struct sqlca sqlca = { 0 };
  db2CfgParam  cfgParameters[1] = { 0 };
  db2Cfg       cfgStruct = { 0 };

  printf(
    "\n*****************************************************************\n");
  printf(
    "** RESET DB CFG PARAMETER 'MAXAPPLS' ON ALL DATABASE PARTITIONS **\n");
  printf(
    "*******************************************************************\n");
  printf("\nUSE THE DB2 APIs:\n");
  printf("  db2CfgSet -- Reet DB CFG Parameters\n");
  printf("TO RESET DB CFG PARAMETERS.\n");

  /* reset db cfg parameter MAXAPPLS */
  cfgParameters[0].flags = 0;
  cfgParameters[0].token = SQLF_DBTN_MAXAPPLS;
  cfgParameters[0].ptrvalue = (char *)malloc(sizeof(sqluint16));

  /* initialize cfgStruct */
  cfgStruct.numItems = 1;
  cfgStruct.paramArray = cfgParameters;

  /* default options will update db cfg parameter on all */
  /* database partitions                                 */
  cfgStruct.flags = db2CfgDatabase | db2CfgReset;
  cfgStruct.dbname = dbAlias;

  /* set database configuration */
  db2CfgSet( db2Version970,
             (void *)&cfgStruct,
             &sqlca );
  DB2_API_CHECK("Reset db cfg parameters");

  printf("\nThe DB CFG parameter is resetted successfully on all " 
         "database partitions.\n");

  return 0;

}
