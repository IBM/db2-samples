----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2000 - 2021
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Component Name:   Db2 Spatial Analytics v11.5
--
-- Source File Name: saBankDemoRefresh.db2
--
-- Version:          11.5.6+
--
-- Description: Drops all the tables and views, and spatially disables the
--              current database.
--
-- SQL STATEMENTS USED:
--         DROP TABLE
--         DROP VIEW
--
-- For more information about the Db2 Spatial Analytics Bank Demo scripts,
-- see the saBankDemoREADME.txt file.
--
-- For more information about Db2 Spatial Analytics component, refer to the 
-- documentation at
-- https://www.ibm.com/docs/en/db2/11.5?topic=data-db2-spatial-analytics.
--
-- For the latest information on Db2 refer to the Db2 website at
-- https://www.ibm.com/analytics/db2.
----------------------------------------------------------------------------

DROP VIEW sa_demo.meridian_customers ;
DROP VIEW sa_demo.sancarlos_customers;
DROP VIEW sa_demo.closest_branch;
DROP VIEW sa_demo.customers_savings ;
DROP VIEW sa_demo.customers_checkings ;
DROP VIEW sa_demo.customers_totals ;
DROP VIEW sa_demo.closest_savings ;
DROP VIEW sa_demo.closest_checking;
DROP VIEW sa_demo.overlap_zone;
DROP VIEW sa_demo.avg_savings_block;
DROP VIEW sa_demo.prospects;
DROP TABLE sa_demo.branch_buffers ;

DROP TABLE sa_demo.customers ;
DROP TABLE sa_demo.branches ;
DROP TABLE sa_demo.accounts ;
DROP TABLE sa_demo.transactions ;
DROP TABLE sa_demo.city_limits;
DROP TABLE sa_demo.sales_regions;
DROP TABLE sa_demo.sj_census_blocks;
DROP TABLE sa_demo.sj_zipcodes;
DROP TABLE sa_demo.sj_main_streets;
