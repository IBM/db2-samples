-- /***************************************************************************/
-- /*  (c) Copyright IBM Corp. 2007 All rights reserved.
-- /*  
-- /*  The following sample of source code ("Sample") is owned by International 
-- /*  Business Machines Corporation or one of its subsidiaries ("IBM") and is 
-- /*  copyrighted and licensed, not sold. You may use, copy, modify, and 
-- /*  distribute the Sample in any form without payment to IBM, for the purpose of 
-- /*  assisting you in the development of your applications.
-- /*  
-- /*  The Sample code is provided to you on an "AS IS" basis, without warranty of 
-- /*  any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
-- /*  IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- /*  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
-- /*  not allow for the exclusion or limitation of implied warranties, so the above 
-- /*  limitations or exclusions may not apply to you. IBM shall not be liable for 
-- /*  any damages you suffer as a result of using, copying, modifying or 
-- /*  distributing the Sample, even if IBM has been advised of the possibility of 
-- /*  such damages.
-- /***************************************************************************/
-- /*                                                                         */
-- /* SAMPLE FILE NAME: ssv_db_cfg.db2                                        */
-- /*                                                                         */
-- /* PURPOSE         : This sample demonstrates updating database            */
-- /*                   configuration parameters in a massively parallel      */
-- /*                   processing (MPP) environment.                         */
-- /*                                                                         */
-- /* USAGE SCENARIO  : This sample demonstrates different options of         */
-- /*                   updating database configuration parameters in an MPP  */
-- /*                   environment. In an MPP environment, database          */
-- /*                   configuration parameters can either be updated on a   */
-- /*                   single database partition or on all database          */
-- /*                   partitions at once. The UPDATE command can be run     */
-- /*                   from any database partition (catalog or non-catalog). */
-- /*                   It will update the database configuration parameter   */
-- /*                   on the database partition that is mentioned in the    */
-- /*                   DBPARTITIONNUM clause. The sample will use the DB CFG */
-- /*                   parameter 'MAXAPPLS', to demonstrate different UPDATE */
-- /*                   & RESET db cfg command options.                       */
-- /*                                                                         */
-- /* PREREQUISITE    : MPP setup with 3 database partitions:                 */
-- /*                     NODE 0: Catalog Node                                */
-- /*                     NODE 1: Non-catalog node                            */
-- /*                     NODE 2: Non-catalog node                            */
-- /*                                                                         */
-- /* EXECUTION       : db2 -tvf ssv_db_cfg.db2                               */
-- /*                                                                         */
-- /* INPUTS          : NONE                                                  */
-- /*                                                                         */
-- /* OUTPUT          : Successful updation of database configuration         */
-- /*                   parameters on different database partitions.          */
-- /*                                                                         */
-- /* OUTPUT FILE     : ssv_db_cfg.out                                        */
-- /*                   (available in the online documentation)               */
-- /***************************************************************************/
-- /*For more information about the command line processor (CLP) scripts,     */
-- /*see the README file.                                                     */
-- /*For information on using SQL statements, see the SQL Reference.          */
-- /*                                                                         */
-- /*For the latest information on programming, building, and running DB2     */
-- /*applications, visit the DB2 application development website:             */
-- /*http://www.software.ibm.com/data/db2/udb/ad                              */
-- /***************************************************************************/

-- /***************************************************************************/
-- /* SAMPLE DESCRIPTION                                                      */
-- /***************************************************************************/
-- /* 1. Update DB CFG parameter on all database partitions(Default behavior) */
-- /* 2. Update DB CFG parameter on one database partition(partition 1)       */
-- /* 3. Reset DB CFG parameter on one database partition(partition 1)        */
-- /* 4. Reset DB CFG parameter on all database partitions(Default behavior)  */
-- /***************************************************************************/

CONNECT TO SAMPLE;

-- Check the current value of DB CFG parameter MAXAPPLS on all database 
-- partitions.
-- The default value for MAXAPPLS is set to "AUTOMATIC'. 

-- Use db2_all utility to run any DB2 command on all database partitions.
-- db2_all utility can also be used to run a command on specific database 
-- partition.
! db2_all "<<+0< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+1< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+2< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

-- /***************************************************************************/
-- /*1. Update DB CFG parameter on all database partitions.(Default behavior) */
-- /***************************************************************************/

-- This is the default behavior of UPDATE DB CFG command, if it is 
-- specified without any DBPARTITIONNUM clause. 
-- The following command will update the db cfg parameter on all database
-- partitions.
UPDATE DB CFG FOR SAMPLE USING MAXAPPLS 50;

-- Verify the value of DB CFG parameter MAXAPPLS on all database partitions.
-- The value will be 50 on all database partitions.

! db2_all "<<+0< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+1< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+2< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";


-- /***************************************************************************/
-- /* 2. Update DB CFG parameter on one database partition (partition 1)      */
-- /***************************************************************************/

-- UPDATE DB CFG command can be executed on any particular database partition
-- using DBPARTITIONNUM clause. 
-- The following command will update the value of MAXAPPLS to 100 on database
-- partition 1.
UPDATE DB CFG FOR SAMPLE DBPARTITIONNUM 1 USING MAXAPPLS 100;

-- Verify the value of DB CFG parameter MAXAPPLS on all database partitions.
-- The value will be 100 on partition 1 and 50 on other partitions.

! db2_all "<<+0< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+1< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+2< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

-- /***************************************************************************/
-- /* 3. Reset DB CFG parameter on one database partition (partition 1)       */
-- /***************************************************************************/

-- RESET CFG command can be executed on any particular database partition using 
-- DBPARTITIONNUM clause. 
-- The following command will reset the value of 'MAXAPPLS' database parameter on 
-- database partition 1.
RESET DB CFG FOR SAMPLE DBPARTITIONNUM 1;

-- Verify the value of DB CFG parameter MAXAPPLS on all database partitions.
-- The value will be AUTOMATIC on partition 1 and 50 on other partitions.

! db2_all "<<+0< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+1< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+2< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

-- /***************************************************************************/
-- /* 4. Reset DB CFG parameter on all database partitions.(Default behavior) */
-- /***************************************************************************/

-- This is the default behavior of RESET DB CFG command, if it is specified 
-- without any DBPARTITIONNUM clause.
-- The following command will reset the db cfg parameter on all database partitions.
RESET DB CFG FOR SAMPLE;

-- Verify the value of DB CFG parameter MAXAPPLS on all database partitions.
-- The value will be AUTOMATIC on all partitions.

! db2_all "<<+0< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+1< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

! db2_all "<<+2< db2 GET DB CFG FOR SAMPLE" | grep "(MAXAPPLS) =";

TERMINATE;
