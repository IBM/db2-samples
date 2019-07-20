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
-- /* SAMPLE FILE NAME: ssv_backup_tbsp.db2                                   */
-- /*                                                                         */
-- /* PURPOSE         : This sample demonstrates performing a tablespace      */
-- /*                   backup in a massively parallel processing (MPP)       */
-- /*                   environment.                                          */
-- /*                                                                         */
-- /* USAGE SCENARIO  : This sample demonstrates different options of         */
-- /*                   performing tablespace BACKUPs in an MPP environment.  */
-- /*                   In an MPP environment, you can back up tablespaces    */
-- /*                   on a single database partition, on several database   */
-- /*                   partitions at once, or on all database partitions at  */
-- /*                   once.                                                 */
-- /*                                                                         */
-- /* PREREQUISITE    : MPP setup with 3 database partitions:                 */
-- /*                     NODE 0: Catalog Node                                */
-- /*                     NODE 1: Non-catalog node                            */
-- /*                     NODE 2: Non-catalog node                            */
-- /*                                                                         */
-- /* EXECUTION       : db2 -tvf ssv_backup_tbsp.db2                          */
-- /*                                                                         */
-- /* INPUTS          : NONE                                                  */
-- /*                                                                         */
-- /* OUTPUT          : Three tablespace backups                              */
-- /*                     - Two successful backups                            */
-- /*                     - One backup with warning                           */
-- /*                                                                         */
-- /* OUTPUT FILE     : ssv_backup_tbsp.out                                   */
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
-- /* 1.  Back up a tablespace on a set of specified database partitions      */
-- /*     (database partition 1 and database partition 2.)                    */
-- /* 2.  Back up a tablespace on all database partitions at once.            */
-- /***************************************************************************/

-- /***************************************************************************/
-- /*   SETUP                                                                 */
-- /***************************************************************************/

-- Create a directory to store database logs.
! mkdir $HOME/archive;

CONNECT TO SAMPLE;

-- Create a database partition group on database partitions 1 and 2.
CREATE DATABASE PARTITION GROUP dbpgroup ON DBPARTITIONNUMS (1, 2);

-- Create a tablespace on the partition group just created, dbpgroup.
CREATE TABLESPACE t1 IN dbpgroup;

-- Before performing a tablespace backup, the database must be made recoverable.
-- This will make the logs available which are necessary to restore/rollforward 
-- the tablespace. Without making the database recoverable, tablespace can not
-- be backed up.
-- To make the database recoverable, set the LOGARCHMETH1 configuration parameter
-- and take a full backup of the database.
! db2 "UPDATE DB CFG FOR SAMPLE USING logarchmeth1 disk:$HOME/archive";

CONNECT RESET;
BACKUP DB sample ON ALL DBPARTITIONNUMS;

-- /***************************************************************************/
-- /* 1. Back up a tablespace on a specified set of database partitions.      */
-- /***************************************************************************/

-- Back up the tablespace t1 on the database partitions 1 and 2.
BACKUP DATABASE SAMPLE ON DBPARTITIONNUM (1, 2) TABLESPACE t1;

-- /***************************************************************************/
-- /* 2. Back up a tablespace on all database partitions at once.             */
-- /***************************************************************************/

-- Back up tablespace t1 on all the database partitions. The DB2 data server
-- will return a warning on database partition 0 when you run the following 
-- command because the tablespace t1 does not exist on database partition 0.  
-- However, this warning does not cause the overall backup to fail.  When you 
-- run this command, the DB2 data server will display the results of the backup,
-- including the individual results for each database partition.
BACKUP DATABASE SAMPLE ON ALL DBPARTITIONNUMS TABLESPACE t1;

-- /***************************************************************************/
-- /* CLEAN UP                                                                */
-- /***************************************************************************/

CONNECT TO SAMPLE;

-- Drop the tablespace
DROP TABLESPACE t1;

-- Drop the database partition group.
DROP DATABASE PARTITION GROUP dbpgroup;

-- Remove the temporary directories
! rm -rf $HOME/archive;

TERMINATE;