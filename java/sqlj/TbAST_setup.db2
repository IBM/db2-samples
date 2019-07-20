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
-- SOURCE FILE NAME: TbAst_setup.db2
--
-- SAMPLE: This sample serves as the setup script for the sample
--         TbAst.sqlj 
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--
-- To run this script from the CLP issue the below command:
--            "db2 -tvf TbAst_setup.db2"
--
----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad

----------------------------------------------------------------------------

connect to sample;

-- create base table, summary table, staging table

-- create base table

CREATE TABLE t
              (c1 SMALLINT NOT NULL,
               c2 SMALLINT NOT NULL,
               c3 SMALLINT,
               c4 SMALLINT);

-- create summary table

CREATE SUMMARY TABLE d_ast AS
              (SELECT c1, c2, COUNT(*) AS count
                FROM t
                GROUP BY c1, c2)
              DATA INITIALLY DEFERRED
              REFRESH DEFERRED;

-- create staging table

CREATE TABLE g FOR d_ast PROPAGATE IMMEDIATE;

connect reset;
