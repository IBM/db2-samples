-----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2000 - 2010
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
-----------------------------------------------------------------------------
--
-- Product Name:    DB2 Spatial Extender v9.7
--
-- Source File Name: seBankDemoConversion.db2
--
-- Version:         9.7.3
--
-- Description:     Create temporary table space and bufferpool for Grid 
--					Index Advisor (gseidx).
--
-- SQL STATEMENTS USED:
--         CREATE BUFFERPOOL
--         CREATE TEMPORARY TABLESPACE
--
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
-----------------------------------------------------------------------------

CONNECT RESET
CONNECT TO se_bank
CREATE BUFFERPOOL se_bank_32k_bp SIZE 1024 PAGESIZE 32 K
CREATE BUFFERPOOL se_bank_8k_bp SIZE 1024 PAGESIZE 8 K
CREATE TEMPORARY TABLESPACE se_bank_temp_ts PAGESIZE 32 K MANAGED BY SYSTEM  USING ('se_bank_container_32k_tt') EXTENTSIZE 64 PREFETCHSIZE 32 BUFFERPOOL se_bank_32k_bp
CREATE USER TEMPORARY TABLESPACE se_bank_u_temp_ts PAGESIZE 32 K MANAGED BY SYSTEM  USING ('se_bank_container_32k_utt') EXTENTSIZE 64 PREFETCHSIZE 32 BUFFERPOOL se_bank_32k_bp
CREATE TABLESPACE se_bank_8k_ts PAGESIZE 8 K MANAGED BY SYSTEM USING ('se_bank_container_8k') EXTENTSIZE 16 PREFETCHSIZE 8 BUFFERPOOL se_bank_8k_bp
GRANT USE OF TABLESPACE se_bank_u_temp_ts TO PUBLIC
GRANT USE OF TABLESPACE se_bank_8k_ts TO PUBLIC
CONNECT RESET

