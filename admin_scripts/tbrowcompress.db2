-- /*************************************************************************
--   (c) Copyright IBM Corp. 2007 All rights reserved.
--   
--   The following sample of source code ("Sample") is owned by International 
--   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
--   copyrighted and licensed, not sold. You may use, copy, modify, and 
--   distribute the Sample in any form without payment to IBM, for the purpose of 
--   assisting you in the development of your applications.
--   
--   The Sample code is provided to you on an "AS IS" basis, without warranty of 
--   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
--   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
--   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
--   not allow for the exclusion or limitation of implied warranties, so the above 
--   limitations or exclusions may not apply to you. IBM shall not be liable for 
--   any damages you suffer as a result of using, copying, modifying or 
--   distributing the Sample, even if IBM has been advised of the possibility of 
--   such damages.
-- *************************************************************************
--
-- SAMPLE FILE NAME: tbrowcompress.db2
--
-- PURPOSE : To demonstrate row compression and automatic dictionary creation.
--           
--    Row Compression:
--         1. How to enable the row compression after a table is created.
--         2. How to enable the row compression during table creation.
--         3. Usage of the options to REORG to use the exiting dictionary 
--            or creating a new dictionary.   
--         4. How to estimate the effectiveness of the compression.
--
--    Automatic Dictionary Creation:
--         1. When the compression dictionary will automatically be created.
--         2. Automatic dictionary creation with DML commands like INSERT, IMPORT and LOAD.
--         3. How to determine whether a new dictionary should be built or not. 
--         4. Automatic dictionary creation for a data partitioned table. 
--
--  EXECUTION: db2 -td@ -vf tbrowcompress.db2
--
--  INPUTS:    NONE
--                                                                          
--  OUTPUTS:   successful creation of compression dictionary. 
--
--  OUTPUT FILE: tbrowcompress.out (available in the online documentation)
--
--  SQL STATEMENTS USED:
--         CREATE TABLE ... COMPRESS YES
--         CREATE PROCEDURE
--         CALL
--         ALTER TABLE 
--         DELETE
--         DROP TABLE
--         EXPORT
--         IMPORT
--         INSERT
--         INSPECT
--         LOAD
--         REORG
--         RUNSTATS
--         TERMINATE
--         UPDATE
--
--  SQL ROUTINES USED:  
--         SYSPROC.ADMIN_GET_TAB_COMPRESS_INFO
--
-- *************************************************************************
-- For more information about the command line processor (CLP) scripts,     
-- see the README file.                                                     
-- For information on using SQL statements, see the SQL Reference.          
--                                                                          
-- For the latest information on programming, building, and running DB2     
-- applications, visit the DB2 application development website:             
-- http://www.software.ibm.com/data/db2/udb/ad                              
-- *************************************************************************
--
--  SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
--  1. ROW COMPRESSION 
--  2. AUTOMATIC DICTIONARY CREATION
-- *************************************************************************/


-- *************************************************************************
--  1. ROW COMPRESSION 
-- *************************************************************************/

-- Connect to sample database. 
CONNECT TO sample@

-- Create a schema.
CREATE SCHEMA testschema@

-- Create a scratch table.
CREATE TABLE testschema.temp(empno INT, sal DOUBLE)@

-- Insert data into the table and export the data in order to obtain 
-- dummy.del file in the required format for load. 
-- Create a procedure to insert the sufficient data for ADC.
DROP PROCEDURE insertdata@

CREATE PROCEDURE insertdata(IN size INT)
LANGUAGE SQL
BEGIN
   DECLARE count INTEGER DEFAULT 0;
   while (count < size)
   do
      INSERT INTO testschema.temp VALUES(100, 20000);
      INSERT INTO testschema.temp VALUES(200, 30000);
      INSERT INTO testschema.temp VALUES(200, 30000);
      SET count=count+1;
   end while;
END@

-- Call the procedure to insert data into the table until table size threshold is breached.
CALL insertdata(1000)@
 
EXPORT TO dummy.del OF DEL SELECT * FROM testschema.temp@

-- Drop the table.
DROP TABLE testschema.temp@

-- Create a table without enabling row compression at the time of table creation. 
CREATE TABLE testschema.empl (emp_no INT, salary DOUBLE)@
 
-- Perform a load operation to load three rows of data into empl.
LOAD FROM dummy.del OF DEL INSERT INTO testschema.empl@
 
-- Enable row compression.  
ALTER TABLE testschema.empl COMPRESS YES@

-- Perform non-inplace reorg to compress rows.
REORG TABLE testschema.empl@
 
-- Drop the table.
DROP TABLE testschema.empl@

-- Create a table enabling compression initially.  
CREATE TABLE testschema.empl (emp_no INT, salary DOUBLE) COMPRESS YES@

-- Load data into table.
LOAD FROM dummy.del OF DEL INSERT INTO testschema.empl@

-- Perform reorganization to compress rows.
REORG TABLE testschema.empl@

-- Perform modifications on table.
INSERT INTO testschema.empl VALUES(400, 30000)@
UPDATE testschema.empl SET salary = salary + 1000@
DELETE FROM testschema.empl WHERE emp_no = 200@

-- Disable row compression for the table.
ALTER TABLE testschema.empl COMPRESS NO@

-- Perform reorganization to remove existing dictionary.
-- New dictionary will be created and all the rows processed by the reorg 
-- are decompressed. 
REORG TABLE testschema.empl RESETDICTIONARY@
 
-- Drop the table.
DROP TABLE testschema.empl@ 
 
-- Create a table, load data, perform some modifications on the table.
-- All the rows will be in non-compressed state until reorganization is performed. 
CREATE TABLE testschema.empl (emp_no INT, salary DOUBLE)@

IMPORT FROM dummy.del OF DEL INSERT INTO testschema.empl@

ALTER TABLE testschema.empl COMPRESS YES@

INSERT INTO testschema.empl VALUES(400, 30000)@

-- Perform inspect to estimate the effectiveness of compression.
-- INSPECT command has to be run before the REORG utility. 
-- Inspect allows you to look over table spaces and tables for their
-- architectural integrity.
-- 'result' file contains percentage of bytes saved from compression,
-- Percentage of rows ineligible for compression due to small row size,
-- Compression dictionary size, Expansion dictionary size etc.
-- To view the contents of 'result' file perform
--    db2inspf result result.out@ 
-- This formats the 'result' file to readable form.

INSPECT ROWCOMPESTIMATE TABLE NAME empl SCHEMA testschema RESULTS KEEP result@
 
REORG TABLE testschema.empl@

-- All the rows will be compressed including the one inserted after reorg.
INSERT INTO testschema.empl VALUES(500, 40000)@

-- Disable row compression for the table. 
-- Rows inserted after this will be non-compressed. 
ALTER TABLE testschema.empl COMPRESS NO@
INSERT INTO testschema.empl VALUES(600, 50000)@

-- Enable row compression again to compress the rows inserted later. 
ALTER TABLE testschema.empl COMPRESS YES@
INSERT INTO testschema.empl VALUES(700, 40600)@

-- Perform runstats to measure the effectiveness of compression using 
-- compression related catalog fields. New columns will be updated to 
-- catalog table after runstats is performed on a compressed table.
RUNSTATS ON TABLE testschema.empl@

-- Display the contents of 'empl' table.
SELECT count(*) FROM testschema.empl@

-- Display the contents of 'SYSCAT.TABLES' to measure effectiveness 
-- of compression. 
SELECT avgrowsize, avgcompressedrowsize, pctpagessaved, avgrowcompressionratio, 
  pctrowscompressed from SYSCAT.TABLES WHERE tabname = 'EMPL'@ 

-- Drop the table.
DROP TABLE testschema.empl@

-- Remove temporary file.
-- Delete the 'result1' file created by INSPECT command
! rm dummy.del@
! rm -rf $HOME/sqllib/db2dump/result@


-- *************************************************************************
--  2. AUTOMATIC DICTIONARY CREATION
-- *************************************************************************

-- Automatic Dictionary Creation(ADC) while populating table using INSERT command.

-- Create a table with row compression turned on.
CREATE TABLE testschema.emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES@

-- Create a procedure to insert the sufficient data for ADC.
DROP PROCEDURE insertdata@

CREATE PROCEDURE insertdata(IN size INT)
LANGUAGE SQL
BEGIN
   DECLARE count INTEGER DEFAULT 0;
   while (count < size)
   do
      INSERT INTO testschema.emptable VALUES(10, 'Padma Kota', '2001-12-02');
      INSERT INTO testschema.emptable VALUES(30, 'Doug Foulds', '1898-08-08');
      INSERT INTO testschema.emptable VALUES(50, 'Kathy Smith', '2006-12-02');
      INSERT INTO testschema.emptable VALUES(75, 'Brad Cassels', '1984-04-06');
      INSERT INTO testschema.emptable VALUES(90, 'Kelly Booch', '2003-12-02');
      SET count=count+1;
   end while;
END@

-- Call the procedure to insert data into the table until table size threshold is breached.
CALL insertdata(8000)@

-- When the table size is reaches threshold, the compression dictionary 
-- will be created automatically. Get the dictionary size using.
SELECT dict_builder, dict_build_timestamp, compress_dict_size, expand_dict_size, pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('TESTSCHEMA','EMPTABLE','REPORT')) as temp@

-- Export the data to a temporary file.
EXPORT TO dummy.del OF DEL SELECT * FROM testschema.emptable@

-- Drop the table.
DROP TABLE testschema.emptable@

-- Automatic Dictionary Creation(ADC) while populating table using IMPORT command.

-- Create a table with row compression turned on.
CREATE TABLE testschema.emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES@

-- IMPORT data into an existing table which is currently less in size than     
-- the threshold for ADC. As data is inserted into the table, the threshold is breached and 
-- a dictionary is built, inserted into the table and the remaining data to be loaded is          
-- subject to compression.
IMPORT FROM dummy.del OF DEL INSERT INTO testschema.emptable@

-- When the table size is reaches threshold, the compression dictionary 
-- will be created automatically. Get the dictionary size using.
SELECT dict_builder, dict_build_timestamp, compress_dict_size, expand_dict_size, pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('TESTSCHEMA','EMPTABLE','REPORT')) as temp@

-- Drop the table.
DROP TABLE testschema.emptable@

-- Automatic Dictionary Creation(ADC) while populating table using LOAD command.

-- Create a table with row compression turned on.
CREATE TABLE testschema.emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES@

-- LOAD INSERT into an existing table which is currently less in size than     
-- the threshold for ADC. As data is inserted into the table, the threshold is breached and 
-- a dictionary is built, inserted into the table and the remaining data to be loaded is          
-- subject to compression.
LOAD FROM dummy.del OF DEL INSERT INTO testschema.emptable@

-- When the table size is reaches threshold, the compression dictionary 
-- will be created automatically. Get the dictionary size using
SELECT dict_builder, dict_build_timestamp, compress_dict_size, expand_dict_size, pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('TESTSCHEMA','EMPTABLE','REPORT')) as temp@

-- Drop the table.
DROP TABLE testschema.emptable@

-- To confirm whether a new dictionary should be built in order re-establish 
-- a more acceptable compression ratio for already existing dictionary 
-- which is built using offline REORG.

-- Create a table with compression attribute enabled.
CREATE TABLE testschema.emptable(empid int, dept int, name varchar(50), joindate date) COMPRESS YES@

-- Insert some data into the table. 
INSERT INTO testschema.emptable VALUES(1, 720, 'Smith', '05/12/2006')@
INSERT INTO testschema.emptable VALUES (3, 168, 'Jones', '05/13/2006')@

-- Do a offline REORG on the table.
REORG TABLE employee@

-- Insert some more data into the table.
INSERT INTO testschema.emptable VALUES(5, 720, 'Smith', '05/12/2006')@
INSERT INTO testschema.emptable VALUES (6, 168, 'Jones', '05/13/2006')@

-- Reports compression information as of last generation.
SELECT pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('TESTSCHEMA','EMPTABLE','REPORT')) as temp@

-- Insert some more data into the table. 
INSERT INTO testschema.emptable VALUES(7, 720, 'Smith', '05/12/2006')@
INSERT INTO testschema.emptable VALUES (8, 168, 'Jones', '05/13/2006')@

-- Generates an estimate of new compression information based on current table data.
SELECT pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('TESTSCHEMA','EMPTABLE','ESTIMATE')) as temp@

-- Delete the table employee.
DROP TABLE testschema.emptable@

-- Automatic Dictionary Creation in a partitioned table.

-- Create a data partitioned table, and load with an initial subset of data.
CREATE TABLESPACE tbsp1 MANAGED BY DATABASE USING (FILE 'conta' 1000)@
CREATE TABLESPACE tbsp2 MANAGED BY DATABASE USING (FILE 'contb' 1000)@
CREATE TABLESPACE tbsp3 MANAGED BY DATABASE USING (FILE 'contc' 1000)@
CREATE TABLESPACE tbsp4 MANAGED BY DATABASE USING (FILE 'contd' 1000)@
CREATE TABLESPACE tbsp5 MANAGED BY DATABASE USING (FILE 'conte' 1000)@

-- Create a data partitioned table with a condition and compress attribute set.
CREATE TABLE testschema.emp_dpart (id int, name varchar(120), joindate DATE) IN tbsp1, tbsp2, tbsp3, tbsp4, tbsp5 partition by range(id) (starting from (1) ending (100) every (20)) COMPRESS YES@

-- Load some records of data into table so that the partitions data size reaches
-- ADC threshold.
LOAD FROM dummy.del OF del MESSAGES load_ins.msg INSERT INTO testschema.emp_dpart@

-- Get the dictionary sizes for the partitions.
SELECT dict_builder, compress_dict_size+expand_dict_size, data_partition_id from table(sysproc.admin_get_tab_compress_info('TESTSCHEMA','EMP_DPART','REPORT')) as temp@

-- Get compression statistics via RUNSTATS command.
RUNSTATS ON TABLE testschema.emp_dpart@
SELECT avgcompressedrowsize, pctrowscompressed, pctpagessaved FROM syscat.tables WHERE tabschema='TESTSCHEMA' and tabname='EMP_DPART'@

-- Delete the table. 
DROP TABLE testschema.emp_dpart@

DROP TABLESPACE tbsp1@
DROP TABLESPACE tbsp2@
DROP TABLESPACE tbsp3@
DROP TABLESPACE tbsp4@
DROP TABLESPACE tbsp5@

-- Drop the schema.
DROP SCHEMA testschema RESTRICT@

-- Remove temporary file.
! rm dummy.del@

-- Disconnect from database.
CONNECT RESET@

TERMINATE@
