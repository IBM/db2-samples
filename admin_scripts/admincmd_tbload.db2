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
-- SOURCE FILE NAME: admincmd_tbload.db2
--
-- SAMPLE: How to load data in to table using ADMIN_CMD routine.
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         DROP TABLE
--         CALL  
--         TERMINATE
--
-- OUTPUT FILE: admincmd_tbload.out (available in the online documentation)
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

-- connect to 'sample' database
CONNECT TO SAMPLE;

-- create a table to prepare LOAD data
CREATE TABLE temp (c1 INT, c2 VARCHAR(20));

-- insert the data into the table 'temp'
INSERT INTO temp VALUES (1, 'A'), (2, 'B'), (3, 'C');

-- export the table data to file 'load_file1.ixf'.
! db2 CONNECT TO SAMPLE;
! db2 "EXPORT TO $HOME/load_file1.ixf OF IXF SELECT * FROM temp";

-- delete the data from the table 'temp'
DELETE FROM temp;

-- insert the data into the table 'temp'.
-- (This data will be used for LOAD with REPLACE)
INSERT INTO temp VALUES (11, 'AA'), (12, 'BB'), (13, 'CC');

-- export the table data to file 'load_file2.ixf'.
! db2 "EXPORT TO $HOME/load_file2.ixf OF IXF SELECT * FROM temp";

-- creating table to be laoded with data
CREATE TABLE temp_load LIKE temp;

-- loading data from data file inserting data into the table temp_load.
! db2 "CALL ADMIN_CMD('LOAD FROM $HOME/load_file1.ixf of IXF INSERT INTO temp_load')";

-- display the contents of the table 'temp_load'
SELECT * FROM temp_load;

-- loading data from data file replacing data loaded by the previous load.
! db2 "CALL ADMIN_CMD('LOAD FROM $HOME/load_file2.ixf of IXF REPLACE INTO temp_load')";

-- display the contents of the table 'temp_load'
SELECT * FROM temp_load;

-- dropping the table
DROP TABLE temp_load;

-- Drop the table 'temp'
DROP TABLE temp;

-- disconnect from the database
CONNECT RESET;

TERMINATE;


