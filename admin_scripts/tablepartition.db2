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
-- SOURCE FILE NAME: tablepartition.db2
--
-- SAMPLE: How to create a partitioned table. 
--
--         This sample demonstrates:
--
--         - Various ways of creating a partitioned table using CREATE TABLE 
--           statement.
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         CREATE TABLESPACE
--         DROP TABLE
--         TERMINATE
--
-- OUTPUT FILE: tablepartition.out (available in the online documentation)
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

-- Connect to database.
CONNECT TO sample;

-- Create DMS tablespaces.
CREATE TABLESPACE tbsp1 MANAGED BY DATABASE USING (FILE 'conta' 1000);
CREATE TABLESPACE tbsp2 MANAGED BY DATABASE USING (FILE 'contb' 1000);
CREATE TABLESPACE tbsp3 MANAGED BY DATABASE USING (FILE 'contc' 1000);
CREATE TABLESPACE tbsp4 MANAGED BY DATABASE USING (FILE 'contd' 1000);

-- Creating a partitioned table on a list of tablespaces. A table 'emp_table'
-- with four partitions will be created. i.e part0 is placed in tbsp1, 
-- part1 will be placed in tbsp2, part2 will be placed in tbsp3 and 
-- part3 will be placed in tbsp4.
CREATE TABLE emp_table(emp_no INT) IN tbsp1, tbsp2, tbsp3, tbsp4
  PARTITION BY RANGE(emp_no)
    (STARTING 0 ENDING 9,
    STARTING 10 ENDING 19,
    STARTING 20 ENDING 29,
    STARTING 30 ENDING 39);

-- Drop the table.
DROP TABLE emp_table;

-- Creating a partitioned table by specifying tablespace for an individual  
-- data partition. A table 'emp_table' with four partitions will be created.
-- i.e part0 is placed in tbsp1,  part1 will be placed in tbsp2,
-- part2 will be placed in tbsp3 and part3 will be placed in tbsp4.
CREATE TABLE emp_table(emp_no INT)
  PARTITION BY RANGE(emp_no)
    (STARTING 0 ENDING 9 IN tbsp1,
    STARTING 10 ENDING 19 IN tbsp2,
    STARTING 20 ENDING 29 IN tbsp3,
    STARTING 30 ENDING 39 IN tbsp4);

-- Drop the table.
DROP TABLE emp_table;

-- Creating a partitioned table by placing data in a Round Robin
-- fashion among the tablespaces.
-- A table 'emp_table' will be created with data placed in a Round Robin 
-- fashion among tbsp1, tbsp2, tbps3 tablespaces.
CREATE TABLE emp_table(emp_no INT) IN tbsp1, tbsp2, tbsp3
  PARTITION BY RANGE(emp_no)
    (STARTING 2 ENDING 9 EVERY 2);

-- Drop the table.
DROP TABLE emp_table;

-- Creating a partitioned table by combining both the short and the long  
-- forms of the syntax.
CREATE TABLE emp_table(emp_no INT) IN tbsp1, tbsp2
  PARTITION BY RANGE(emp_no)
    (STARTING 10 ENDING 19 EVERY 2,
    STARTING 0   ENDING 9,
    STARTING 20  ENDING 29);

-- Drop the table.
DROP TABLE emp_table;

-- Creating a partitioned table 'document' by using LONG IN clause to place 
-- the LOB data in a specified tablespace.
CREATE TABLE document(sno INT, empid INT)LONG IN tbsp3, tbsp4
  PARTITION BY RANGE(empid) (STARTING 1 ENDING 1000 EVERY 100);

-- Drop the table.
DROP TABLE document;

-- Creatng a partitioned table 'persons' using MINVALUE and MAXVALUE.
CREATE TABLE persons (last  character(15) not null,
       	              first character(15),
	              middle  character(15))
  PARTITION BY RANGE(last, first, middle  ) 
    (part 0 starting from (MINVALUE, MINVALUE, MINVALUE),
    part 1 starting from ('COX',     'ELIZABETH', 'ELLEN'  ) exclusive,
    part 2 starting from ('HARDING', 'TONYA',      MINVALUE),
    part 3 starting from ('MACCA',    MINVALUE,    MINVALUE),
    part 4 starting from ('SMITH',    MAXVALUE,    MAXVALUE),
    part 5 starting from ('ZYZYCK',  'MARK',       MAXVALUE) 
             ending (MAXVALUE, MAXVALUE, MAXVALUE));
	    
-- Drop the table.
DROP TABLE persons;

-- Creating a partitioned table. This shows how a partitioned table can be
-- multi-dimensionally clustered to allow finer granularity of data partition
-- and block elimination using ORGANIZE BY clause.
CREATE TABLE orders (YearAndMonth  INT, Province CHAR(2), Country CHAR(3)) 
  IN tbsp1, tbsp2
    PARTITION BY RANGE (YearAndMonth)
      (STARTING 9901 ENDING 9904 EVERY 2)
         ORGANIZE BY (Province);

-- Drop the table.
DROP TABLE orders;

-- The following creates a partitioned table.
-- This shows how to spread the data across different database partitions  
-- using DISTRIBUTE BY clause. All rows with the same value of column  
-- 'Country' will be in the same database partition. All rows with the same  
-- value of column 'YearAndMonth' will be in the same tablespace.
-- For a given value of 'Country' and 'YearAndMonth', all rows with the same 
-- value 'Province' will be clustered together on disk.

CREATE TABLE orders (YearAndMonth  INT, Province CHAR(2), Country CHAR(3))
  IN tbsp1, tbsp2
    DISTRIBUTE BY HASH(Country)
      PARTITION BY RANGE(YearAndMonth) (STARTING 9901 ENDING 9904 EVERY 2)
	ORGANIZE BY DIMENSIONS(Province);

-- Drop the table.
DROP TABLE orders;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;
DROP TABLESPACE tbsp4;

-- Disconnect from database.
CONNECT RESET;

TERMINATE;

