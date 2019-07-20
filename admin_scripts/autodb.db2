-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2007 All rights reserved.
-- 
-- The following sample of source code ("Sample") is owned by International 
-- Business Machines Corporation or one of its subsidiaries ("IBM") and is 
-- copyrighted and licensed, not sold. You may use, copy, modify, and 
-- distribute the Sample in any form without payment to IBM, for the purpose of 
-- assisting you in the development of your applications.
-- 
-- The Sample code is provided to you on an "AS IS" basis, without warranty of 
-- any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
-- IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
-- not allow for the exclusion or limitation of implied warranties, so the above 
-- limitations or exclusions may not apply to you. IBM shall not be liable for 
-- any damages you suffer as a result of using, copying, modifying or 
-- distributing the Sample, even if IBM has been advised of the possibility of 
-- such damages.
-----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: autodb.db2
--
-- SAMPLE: How to use DB2_ENABLE_AUTOCONFIG_DEFAULT registry variable to
--         enable/disable the Configuration Advisor at database creation.
--
-- SQL STATEMENT USED:
--         AUTOCONFIGURE
--         CREATE DB
--         DROP DB
--         GET DB CFG
--
-- OUTPUT FILE: autodb.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Disconnect from any existing database connection.
CONNECT RESET;

-- The registry variable DB2_ENABLE_AUTOCONFIG_DEFAULT controls the auto
-- enablement of the Configuration Advisor at database creation time.
-- Valid values for this registry variable are:
--     YES    : Enable Configuration Advisor at database creation.
--     <unset>: (default) same as "YES".
--              Enable Configuration Advisor at database creation
--     NO     : Do not run the Configuration Advisor at database creation.

-- DB2_ENABLE_AUTOCONFIG_DEFAULT is a dynamic variable and hence instance
-- restart is not required when it is set.
-- Registry variable can be set using
--       db2set DB2_ENABLE_AUTOCONFIG_DEFAULT=YES

-- If DB2_ENABLE_AUTOCONFIG_DEFAULT is either set to "YES" or <unset>, the
-- Configuration Advisor is enabled at database creation time and the database
-- configuration parameters will be tuned.  

-- If DB2_ENABLE_AUTOCONFIG_DEFAULT is set to "NO", the Configuration
-- Advisor is disabled at database creation time and the database 
-- configuration parameters will not be tuned. However, if AUTOCONFIGURE 
-- or CREATE DB AUTOCONFIGURE commands are executed, then this overrides the
-- DB2_ENABLE_AUTOCONFIG_DEFAULT setting, and the Configuration Advisor will 
-- always be executed against the database since an explicit 
-- statement (AUTOCONFIGURE) has been made. 

-- NOTE: The below example results are applicable to non-DPF systems

-- EXAMPLES:
------------

-- Example 1: Setting DB2_ENABLE_AUTOCONFIG_DEFAULT =<unset>

! db2set DB2_ENABLE_AUTOCONFIG_DEFAULT= ;
CREATE DB test; 

GET DB CFG FOR test;

-- Expected Result: 
-------------------

-- The DB CFG parameters should be tuned by the Configuration Advisor.
-- In addition, the following STMM (Self Tuning Memory Management) 
-- and Auto Runstats parameters should be ON or AUTOMATIC:

-- Sort heap threshold (4KB)                  (SHEAPTHRES) = 0 
-- Self tuning memory                    (SELF_TUNING_MEM) = ON
-- Package cache size (4KB)                   (PCKCACHESZ) = AUTOMATIC
-- Sort list heap (4KB)                         (SORTHEAP) = AUTOMATIC
-- Sort heap thres for shared sorts (4KB) (SHEAPTHRES_SHR) = AUTOMATIC
-- Max storage for lock list (4KB)              (LOCKLIST) = AUTOMATIC
-- Percent. of lock lists per application       (MAXLOCKS) = AUTOMATIC
-- Size of database shared memory (4KB)  (DATABASE_MEMORY) = AUTOMATIC
-- Automatic maintenance                      (AUTO_MAINT) = ON
--   Automatic table maintenance          (AUTO_TBL_MAINT) = ON
--     Automatic runstats                  (AUTO_RUNSTATS) = ON 

-- If you wish to disable STMM or Auto Runstats on the database, this can be 
-- done by updating the SELF_TUNING_MEM or AUTO_RUNSTATS database 
-- configuration parameters, respectively, using the UPDATE DB CFG command.

-- Note: When DB2_ENABLE_AUTOCONFIG_DEFAULT=YES, you should get the same 
-- behaviour as when DB2_ENABLE_AUTOCONFIG_DEFAULT=

DROP DB test;
-----------------------------------------------------------------------------
-- Example 2: Setting DB2_ENABLE_AUTOCONFIG_DEFAULT=NO

! db2set DB2_ENABLE_AUTOCONFIG_DEFAULT=NO ;
CREATE DB test; 

GET DB CFG FOR test;

-- Expected Result: 
----------------
-- The DB CFG parameters should NOT be tuned by the Configuration Advisor
-- In addition, the following STMM and Auto Runstats parameters should be ON
-- or AUTOMATIC:

-- Sort heap threshold (4KB)                  (SHEAPTHRES) = 0 
-- Self tuning memory                    (SELF_TUNING_MEM) = ON
-- Package cache size (4KB)                   (PCKCACHESZ) = AUTOMATIC
-- Sort list heap (4KB)                         (SORTHEAP) = AUTOMATIC
-- Sort heap thres for shared sorts (4KB) (SHEAPTHRES_SHR) = AUTOMATIC
-- Max storage for lock list (4KB)              (LOCKLIST) = AUTOMATIC
-- Percent. of lock lists per application       (MAXLOCKS) = AUTOMATIC
-- Size of database shared memory (4KB)  (DATABASE_MEMORY) = AUTOMATIC
-- Automatic maintenance                      (AUTO_MAINT) = ON
--   Automatic table maintenance          (AUTO_TBL_MAINT) = ON
--     Automatic runstats                  (AUTO_RUNSTATS) = ON 

-- If you wish to disable STMM or Auto Runstats on the database, this can be
-- done by updating the SELF_TUNING_MEM or AUTO_RUNSTATS database
-- configuration parameters, respectively, using the UPDATE DB CFG command.

DROP DB test;
-----------------------------------------------------------------------------

-- Example 3: AUTOCONFIGURE keyword overrides DB2_ENABLE_AUTOCONFIG_DEFAULT 
--            value setting
  
! db2set DB2_ENABLE_AUTOCONFIG_DEFAULT=NO;
CREATE DB test AUTOCONFIGURE APPLY DB ONLY;

GET DB CFG FOR test;

-- Expected Result: 
-------------------
-- The DB CFG parameters should be tuned by the Configuration Advisor
-- In addition, the following STMM and Auto Runstats parameters should 
-- be ON or AUTOMATIC:

-- Sort heap threshold (4KB)                  (SHEAPTHRES) = 0 
-- Self tuning memory                    (SELF_TUNING_MEM) = ON
-- Package cache size (4KB)                   (PCKCACHESZ) = AUTOMATIC
-- Sort list heap (4KB)                         (SORTHEAP) = AUTOMATIC
-- Sort heap thres for shared sorts (4KB) (SHEAPTHRES_SHR) = AUTOMATIC
-- Max storage for lock list (4KB)              (LOCKLIST) = AUTOMATIC
-- Percent. of lock lists per application       (MAXLOCKS) = AUTOMATIC
-- Size of database shared memory (4KB)  (DATABASE_MEMORY) = AUTOMATIC
-- Automatic maintenance                      (AUTO_MAINT) = ON
--   Automatic table maintenance          (AUTO_TBL_MAINT) = ON
--     Automatic runstats                  (AUTO_RUNSTATS) = ON 

-- In this case, the explicit call to AUTOCONFIGURE in the CREATE DB statement 
-- has taken precedence over the DB2_ENABLE_AUTOCONFIG_DEFAULT=NO value, i.e., 
-- the Configuration Advisor has been executed against the database.
-- Using the AUTOCONFIGURE command against an existing database will have the 
-- same effect. 

DROP DB test;
