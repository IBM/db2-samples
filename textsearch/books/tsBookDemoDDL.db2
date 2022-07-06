----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2022
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Product Name:     Db2 Text Search
--
-- Source File Name: tsDemoDDL.db2
--
-- Version:          Any
--
-- Description: Create text search tables in the sample database.
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--
--
----------------------------------------------------------------------------

CREATE TABLE TS_DEMO.BOOKS
( PK integer not null primary key,
  ISBN VARCHAR(18),
  TITLE VARCHAR(100),
  AUTHORS VARCHAR(200),
  PUBLISHERS VARCHAR(200),
  YEAR INTEGER,
  ABSTRACT CLOB(1M),
  PDF BLOB(2G),
  BOOK XML
) DATA CAPTURE NONE ORGANIZE BY ROW;
