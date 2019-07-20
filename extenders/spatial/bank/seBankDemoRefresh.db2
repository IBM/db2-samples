----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2000 - 2010
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Product Name:     DB2 Spatial Extender v9.7
--
-- Source File Name: seBankDemoRefresh.db2
--
-- Version:          9.7.3
--
-- Description: Drops all the tables and views, and spatially disables the
--              current database.
--
-- SQL STATEMENTS USED:
--         DROP TABLE
--         DROP VIEW
--         CALL db2gse.ST_disable_db(1,?,?)
--
-- For more information about the DB2 Spatial Extender Bank Demo scripts,
-- see the seBankDemoREADME.txt file.
--
-- For more information about DB2 Spatial Extender, refer to the DB2 Spatial 
-- Extender User's Guide and Reference.
--
-- For the latest information on DB2 Spatial Extender and the Bank Demo
-- refer to the DB2 Spatial Extender website at
-- http://www.software.ibm.com/software/data/spatial/db2spatial
----------------------------------------------------------------------------

DROP VIEW se_demo.meridian_customers ;
DROP VIEW se_demo.sancarlos_customers;
DROP VIEW se_demo.closest_branch;
DROP VIEW se_demo.customers_savings ;
DROP VIEW se_demo.customers_checkings ;
DROP VIEW se_demo.customers_totals ;
DROP VIEW se_demo.closest_savings ;
DROP VIEW se_demo.closest_checking;
DROP VIEW se_demo.overlap_zone;
DROP VIEW se_demo.avg_savings_block;
DROP VIEW se_demo.prospects;
DROP TABLE se_demo.branch_buffers ;

DROP TABLE se_demo.customers ;
DROP TABLE se_demo.branches ;
DROP TABLE se_demo.accounts ;
DROP TABLE se_demo.transactions ;
DROP TABLE se_demo.city_limits;
DROP TABLE se_demo.sales_regions;
DROP TABLE se_demo.sj_census_blocks;
DROP TABLE se_demo.sj_zipcodes;
DROP TABLE se_demo.sj_main_streets;

CALL db2gse.ST_disable_db(1,?,?);
