-- ************************************************************************
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
-- ************************************************************************
--
-- SAMPLE FILE NAME: fasterrollout.db2
--
-- PURPOSE         : To demonstrate how to change the default MDC roll out 
--                   behavior to a deferred index cleanup behavior.
--
-- USAGE SCENARIO  : This sample demonstrates different ways to cleanup 
--                   indexes using DELETE statement.
--
-- PREREQUISITE    : NONE
--
-- EXECUTION       : db2 -tvf fasterrollout.db2
--                                                                          
-- INPUTS          : NONE
--
-- OUTPUTS         : Successful change of MDC roll out behaviour from 
--                   IMMEDIATE index cleanup to DEFERRED index cleanup. 
--
-- OUTPUT FILE     : fasterrollout.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--                                                                          
-- SQL STATEMENTS USED: 
--                   CREATE TABLE
--                   CREATE INDEX
--                   DELETE
--                   DROP TABLE
--                   INSERT
--                   SET CURRENT ROLLOUT MODE 
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
--  SAMPLE DESCRIPTION                                                      
-- *************************************************************************
--  1. How to perform delete that uses IMMEDIATE INDEX CLEANUP roll out type. 
--  2. How to perform delete that uses DEFERRED INDEX CLEANUP roll out type. 
-- *************************************************************************
--
-- *************************************************************************
--    SETUP                                                                 
-- *************************************************************************
-- Connect to the database.
CONNECT TO sample;

-- *************************************************************************
-- Following shows how to perform delete that uses IMMEDIATE INDEX 
-- CLEANUP roll out type.
-- *************************************************************************

-- Create MDC table 'MDC_temp'.

CREATE TABLE MDC_emp (emp_no INT NOT NULL, emp_sal DOUBLE, 
                      emp_location CHAR (25))         
  ORGANIZE BY DIMENSIONS (emp_no, emp_location);

-- Populate table 'MDC_emp' with data.

INSERT INTO MDC_emp values (100, 1.25, 'BANGALORE');
INSERT INTO MDC_emp values (200, 2.00, 'BANGALORE');
INSERT INTO MDC_emp values (300, 2.00, 'CHENNAI');
INSERT INTO MDC_emp values (400, 3.00, 'CHENNAI');
INSERT INTO MDC_emp values (500, 2.00, 'PUNE');
INSERT INTO MDC_emp values (600, 2.00, 'BANGALORE');

-- Create index on columns 'emp_no' and 'emp_location'.

CREATE INDEX indx1 ON MDC_emp (emp_no, emp_location);

-- The below DELETE statement uses 'IMMEDIATE INDEX CLEANUP ROLLOUT' as default. 
-- Indexes are cleaned up at delete time and rolled out blocks will be 
-- available for immediate use.

DELETE FROM MDC_emp WHERE emp_sal = 2.00 AND emp_location = 'BANGALORE';

-- Drop the table.

DROP TABLE MDC_emp;

-- *************************************************************************
-- Following shows how to perform DELETE that uses DEFERRED INDEX CLEANUP 
-- roll out type. This type of index cleanup is very efficient in case of 
-- large tables. This even shows how to change the DEFAULT mode to 
-- DEFERRED mode.
-- *************************************************************************

-- Create MDC table 'MDC_temp'.

CREATE TABLE MDC_emp (emp_no INT NOT NULL, emp_sal DOUBLE, 
                      emp_location CHAR (25))         
  ORGANIZE BY DIMENSIONS (emp_no, emp_location);

-- Populate table 'MDC_emp' with data.

INSERT INTO MDC_emp values (100, 1.25, 'BANGALORE');
INSERT INTO MDC_emp values (200, 2.00, 'BANGALORE');
INSERT INTO MDC_emp values (300, 2.00, 'CHENNAI');
INSERT INTO MDC_emp values (400, 3.00, 'CHENNAI');
INSERT INTO MDC_emp values (500, 2.00, 'PUNE');
INSERT INTO MDC_emp values (600, 2.00, 'BANGALORE');

-- Create index on columns 'emp_no' and 'emp_location'.

CREATE INDEX indx1 ON MDC_emp (emp_no, emp_location);

-- Change the roll out type to 'DEFERRED'.

SET CURRENT MDC ROLLOUT MODE = DEFERRED;

-- The above statement changes the roll out type from 'IMMEDIATE' to 'DEFERRED'.
-- Once the delete statement is committed, DB2 begins to cleanup 
-- RID indexes asynchronously.  Users cannot use the rolled out blocks immediately 
-- after DELETE. These blocks will be available for reuse only after index cleanup 
-- is completed by DB2. 

DELETE FROM MDC_emp WHERE emp_sal = 2.00 OR emp_location = 'BANGALORE';

-- Drop table.

DROP TABLE MDC_emp;

-- Disconnect form database.

CONNECT RESET;

TERMINATE;
 
