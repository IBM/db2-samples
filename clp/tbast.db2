----------------------------------------------------------------------------
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
-- SOURCE FILE NAME: tbast.db2
--
-- SAMPLE: How to use staging table for updating deferred AST
--
--         This sample:
--         1. Creates a refresh-deferred summary table
--         2. Creates a staging table for this summary table
--         3. Applies contents of staging table to AST
--         4. Restores the data in a summary table
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         DROP
--         INSERT
--         REFRESH
--         SET INTEGRITY
--         TERMINATE
--
-- OUTPUT FILE: tbast.out (available in the online documentation)
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

-- create a base table
CREATE TABLE t (c1 SMALLINT NOT NULL, c2 SMALLINT NOT NULL,
                c3 SMALLINT, c4 SMALLINT);

-- create a summary table
CREATE TABLE d_ast AS (SELECT c1, c2, COUNT(*)
  AS COUNT FROM t GROUP BY c1, c2) DATA INITIALLY DEFERRED REFRESH DEFERRED;

-- create a staging table
CREATE TABLE g FOR d_ast PROPAGATE IMMEDIATE;

-- show the propagation of changes of base table to summary tables through 
-- the staging table

-- bring staging table out of pending state
SET INTEGRITY FOR g IMMEDIATE CHECKED;

-- refresh summary table, get it out of pending state.
REFRESH TABLE d_ast NOT INCREMENTAL;

-- insert data into base table t
INSERT INTO t VALUES(1,1,1,1), (2,2,2,2), (1,1,1,1), (3,3,3,3);

-- display the contents of staging table 'g'.The Staging table contains 
-- incremental changes to base table.
SELECT c1, c2, count FROM g;

-- refresh the summary table
REFRESH TABLE d_ast INCREMENTAL;

-- display the contents of staging table 'g'.NOTE: The staging table is 
-- pruned after AST is refreshed.The contents are propagated to AST from
-- the staging table.
SELECT c1, c2, count FROM g;

-- display the contents of AST.
-- summary table has the changes propagated from staging table.
SELECT c1, c2, count FROM d_ast;

-- show restoring of data in a summary table

-- block all modifications to the summary table by setting the 
-- integrity to off. (g is placed in pending and g.CC=N)
SET INTEGRITY FOR g OFF;

-- export the query definition in summary table and load directly back to
-- the summary table. (d_ast and g both in pending)
SET INTEGRITY FOR d_ast OFF CASCADE IMMEDIATE;

-- prune staging table and place it in normal state (g.CC=F)
SET INTEGRITY FOR g IMMEDIATE CHECKED PRUNE;

-- changing staging table state to U (g.CC to U)
SET INTEGRITY FOR g STAGING IMMEDIATE UNCHECKED;

-- place d_ast in normal and d_ast.CC to U
SET INTEGRITY FOR d_ast MATERIALIZED QUERY IMMEDIATE UNCHECKED;

-- drop the created tables

-- dropping a base table implicitly drops summary table defined on it
-- which in turn cascades to dropping its staging table.
DROP TABLE t;

-- disconnect from the database
CONNECT RESET;

TERMINATE;
