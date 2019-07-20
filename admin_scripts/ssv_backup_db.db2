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
-- /* PURPOSE         : This sample demonstrates performing a database backup */
-- /*                   in a massively parallel processing (MPP) environment. */
-- /*                                                                         */
-- /* USAGE SCENARIO  : This sample demonstrates different options of         */
-- /*                   performing database BACKUP in an MPP environment.     */
-- /*                   In an MPP environment, you can back up a database on  */
-- /*                   a single database partition, on several database      */
-- /*                   partitions at once, or on all database partitions at  */
-- /*                   once. This command can be run from any database       */
-- /*                   partition (catalog or non-catalog). It will backup    */
-- /*                   the database partition that is mentioned in the       */
-- /*                   DBPARTITIONNUM clause.                                */
-- /*                                                                         */
-- /* PREREQUISITE    : MPP setup with 3 database partitions:                 */
-- /*                     NODE 0: Catalog Node                                */
-- /*                     NODE 1: Non-catalog node                            */
-- /*                     NODE 2: Non-catalog node                            */
-- /*                                                                         */
-- /* EXECUTION       : db2 -tvf ssv_backup_db.db2                            */
-- /*                                                                         */
-- /* INPUTS          : NONE                                                  */
-- /*                                                                         */
-- /* OUTPUT          : Successful backups of database on different database  */
-- /*                   partitions.                                           */
-- /*                                                                         */
-- /* OUTPUT FILE     : ssv_backup_db.out                                     */
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
-- /* 1. Back up the database on current database partition (DB2NODE).        */
-- /* 2. Back up the database on any specified database partition.            */
-- /* 3. Back up the database on a range of database partitions.              */
-- /* 4. Back up the database on all database partitions except any one       */
-- /*    database partition.                                                  */
-- /* 5. Back up the database on all database partitions.                     */
-- /***************************************************************************/

-- /***************************************************************************/
-- /*   SETUP                                                                 */
-- /***************************************************************************/

-- Create directories that will be used for storing backup images.
! mkdir $HOME/0;
! mkdir $HOME/1;
! mkdir $HOME/2;

-- /***************************************************************************/
-- /*1. Back up the database on current database partition (DB2NODE).         */
-- /***************************************************************************/

-- This is the default behavior of BACKUP command if the command is specified 
-- without any options (DBPARTITIONNUM). This will back up the database on 
-- current database partition.
BACKUP DB SAMPLE;

-- /***************************************************************************/
-- /* 2. Back up the database on a specified database partition.              */
-- /***************************************************************************/

-- Backup can be performed on any particular database partition using 
-- DBPARTITIONNUM clause.
-- Following command will back up the database on database partition 1.
BACKUP DB SAMPLE ON DBPARTITIONNUM (1);

-- /***************************************************************************/
-- /* 3. Back up the database on a range of database partitions.              */
-- /***************************************************************************/

-- Backup can be performed on any range of database partitions.
-- Following command will back up the database from database partition 1 to 
-- database partition 2.
BACKUP DB SAMPLE ON DBPARTITIONNUM (1 TO 2);

-- /***************************************************************************/
-- /* 4. Back up the database on all database partitions except any one       */
-- /*    database partition.                                                  */
-- /***************************************************************************/

-- Backup can be performed on any range of database partitions with some 
-- exceptions.
-- Following command will back up the database on all database partitions 
-- except database partition 1.
BACKUP DB SAMPLE ON ALL DBPARTITIONNUMS EXCEPT DBPARTITIONNUM (1);

-- /***************************************************************************/
-- /* 5. Back up the database on all database partitions.                     */
-- /***************************************************************************/

-- Backup can be performed on all database partitions. If path expressions 
-- are used, then the backup image for each database partition can be stored
-- into seperate storage space.
-- Note: The target directory must exist before the command is run.
! db2 "BACKUP DB SAMPLE ON ALL DBPARTITIONNUMS TO "$HOME/ $N"";

-- /***************************************************************************/
-- /* CLEAN UP                                                                */
-- /***************************************************************************/

-- Remove temporary directories
! rm -rf $HOME/0;
! rm -rf $HOME/1;
! rm -rf $HOME/2;

TERMINATE;