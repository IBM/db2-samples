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
-- SOURCE FILE NAME: tablestatesize.db2
--    
-- SAMPLE: How to use SYSPROC.ADMIN_GET_TAB_INFO and SYSIBMADM.ADMINTABINFO
--         views to obtain the size and status information for a table. 
--
-- SQL STATEMENTS USED:
--         CONNECT
--         CREATE TABLE
--         CREATE TABLESPACE
--         CREATE INDEX
--         DROP INDEX
--         DROP TABLE
--         DROP TABLESPACE
--         INSERT
--         SELECT
--         TERMINATE
-- 
-- OUTPUT FILE: tablestatesize.out (available in the online documentation)
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
-- Connect to 'sample' database.
CONNECT TO SAMPLE;

-- Create 4 regular tablespaces.
CREATE REGULAR TABLESPACE tbsp1;
CREATE REGULAR TABLESPACE tbsp2;
CREATE REGULAR TABLESPACE tbsp3;
CREATE REGULAR TABLESPACE tbsp4;

-- Create a large tablespace.
CREATE LARGE TABLESPACE ltbsp1; 

-- Create a partitioned table.  
CREATE TABLE employee_details (emp_id INT NOT NULL,
                               dept_name VARCHAR(50),
                               date_of_joining DATE,
                               remarks CLOB(1M))
  IN tbsp1, tbsp2, tbsp3, tbsp4
  LONG IN ltbsp1
  PARTITION BY RANGE(EMP_ID) 
    (STARTING FROM (10000) ENDING AT (90000) EVERY (10000));

-- Create Index on a column.
CREATE UNIQUE INDEX uniq_emp_id ON employee_details (emp_id);

-- Insert some valid rows into the table
INSERT INTO employee_details VALUES
  (10923, 'ADMIN_SECTION-1',
    '12-12-2003', 'GRADUATION CERIFICATE COPY NOT YET SUBMITTED'),
  (29833, 'DEVELOPMENT_DB2', '06-03-2001',
    'EXPERIENCE CERTIFICATE TO BE SUBMITTED');

-- Check the physical space occupied by the table EMPLOYEE_DETAILS
-- per datapartition. For partitioned tables, the index size reported by
-- the ADMIN_GET_TAB_INFO UDF is always 0. 
-- This size does not include the size of any index that exist on the table.
SELECT data_partition_id ,(data_object_p_size +
                           index_object_p_size +
                           long_object_p_size +
                           lob_object_p_size + xml_object_p_size)
  AS total_p_size
  FROM TABLE( SYSPROC.ADMIN_GET_TAB_INFO( CURRENT_SCHEMA, 'EMPLOYEE_DETAILS' )) AS T
  ORDER BY data_partition_id ;

-- Check the logical space occupied by the table EMPLOYEE_DETAILS
-- per datapartition. For partitioned tables, the index size reported by
-- the ADMIN_GET_TAB_INFO UDF is always 0. 
-- This size does not include the size of any index that exist on the table.
SELECT data_partition_id , (data_object_l_size +
                            index_object_l_size +
                            long_object_l_size +
                            lob_object_l_size +
                            xml_object_l_size)
  AS total_l_size
  FROM TABLE( SYSPROC.ADMIN_GET_TAB_INFO( CURRENT_SCHEMA, 'EMPLOYEE_DETAILS' )) AS T
  ORDER by data_partition_id;

-- Check the size occupied by different data types in the table
-- EMPLOYEE_DETAILS at data partition level.
SELECT sum(data_object_L_size), sum(index_object_L_size),
       sum(long_object_L_size), sum(lob_object_L_size),
       sum(data_object_P_size), sum(index_object_P_size),
       sum(long_object_P_size), sum(lob_object_P_size),
       data_partition_id
  FROM TABLE( sysproc.admin_get_tab_info(CURRENT_SCHEMA, 'EMPLOYEE_DETAILS') ) AS T
  GROUP BY data_partition_id;

-- Use ADMINTABINFO view to retrieve the results.
SELECT sum(data_object_L_size), sum(index_object_L_size),
       sum(long_object_L_size), sum(lob_object_L_size),
       sum(xml_object_L_size), sum(data_object_P_size),
       sum(index_object_P_size), sum(long_object_P_size),
       sum(lob_object_P_size), sum(xml_object_p_size),
       data_partition_id
  FROM SYSIBMADM.ADMINTABINFO where TABNAME = 'EMPLOYEE_DETAILS'
  GROUP BY data_partition_id;

-- Result obtained in the previous case is at data partition level.
-- Result at the database partition level can also be obtained.
SELECT  sum(data_object_L_size), sum(index_object_L_size),
        sum(long_object_L_size), sum(lob_object_L_size),
        sum(xml_object_L_size), sum(data_object_P_size),
        sum(index_object_P_size), sum(long_object_P_size),
        sum(lob_object_P_size), sum(xml_object_P_size),
        dbpartitionnum
  FROM TABLE( sysproc.admin_get_tab_info(CURRENT_SCHEMA, 'EMPLOYEE_DETAILS') ) AS T
  GROUP BY dbpartitionnum;

-- Check the size occupied by different data types in a table,
SELECT tabschema, tabname,  sum(data_object_L_size),
       sum(index_object_L_size), sum(long_object_L_size),
       sum(lob_object_L_size), sum(data_object_P_size),
       sum(index_object_P_size), sum(long_object_P_size),
       sum(lob_object_P_size)
  FROM TABLE (sysproc.admin_get_tab_info(CURRENT_SCHEMA, 'EMPLOYEE_DETAILS')) AS T
  GROUP BY tabschema, tabname;

-- Identify tables that are using LARGE ROW ID's or LARGE SLOTS.
-- Use ADMINTABINFO view to retrieve the results.
SELECT tabschema, tabname
  FROM SYSIBMADM.ADMINTABINFO
  WHERE LARGE_RIDS = 'Y' OR LARGE_SLOTS = 'Y'
 GROUP BY tabschema, tabname;

-- Identify tables that are in REORG PENDING state.
-- Use ADMINTABINFO to retrieve the results.
SELECT tabschema, tabname
  FROM SYSIBMADM.ADMINTABINFO
  WHERE REORG_PENDING = 'Y'
  GROUP BY tabschema, tabname;

-- List tables that have only READ ACESS.
-- Use ADMINTABINFO view to retrieve the results.
SELECT tabschema, tabname
  FROM SYSIBMADM.ADMINTABINFO
  WHERE READ_ACCESS_ONLY = 'Y'
  GROUP BY tabschema, tabname;

-- Use the UDF with SYSCAT.TABLES to get a detailed status like lock size,
-- drop rule etc.
SELECT SYSCAT.TABLES.tabschema, SYSCAT.TABLES.tabname, status,
       droprule, locksize, compression,
       log_attribute, READ_ACCESS_ONLY, AVAILABLE
  FROM TABLE (sysproc.admin_get_tab_info(CURRENT_SCHEMA, 'EMPLOYEE_DETAILS')) AS T,
             SYSCAT.TABLES where SYSCAT.TABLES.tabname = 'EMPLOYEE_DETAILS';
 
-- Drop the index uniq_emp_id.
DROP INDEX uniq_emp_id;

-- Drop the table employee_details.
DROP TABLE employee_details;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;
DROP TABLESPACE tbsp4;
DROP TABLESPACE ltbsp1;

-- Disconnect from 'sample' database.
CONNECT RESET;

TERMINATE;
