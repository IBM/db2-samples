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
-- SOURCE FILE NAME: xmlconst.db2
--
-- SAMPLE: How to create UNIQUE index on XML columns 
--
-- SQL STATEMENTS USED:
--         CREATE INDEX
--         DROP INDEX
--         TERMINATE
--
-- OUTPUT FILE: xmlconst.out (available in the online documentation)
-- 
-- NOTE: Primary key, unique constraint, or unique index are not supported 
--       for XML column in the Database Partitioning Feature available with 
--       DB2 Enterprise Server Edition for Linux, UNIX, and Windows.
--
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

-- connect to the SAMPLE database
CONNECT TO sample;

-- create table "company"
CREATE TABLE COMPANY(ID int, DOCNAME VARCHAR(20), DOC XML);

-- create index with unique constraint
CREATE UNIQUE INDEX empindex on company(doc)  GENERATE KEY
                USING XMLPATTERN '/company/emp/@id' AS SQL  DOUBLE;

-- insert row1 into table
INSERT INTO company values (1, 'doc1', xmlparse
       (document '<company name="Company1">
       <emp id="31201" salary="60000" gender="Female">
       <name><first>Laura </first><last>Brown</last></name>
       <dept id="M25">Finance</dept></emp></company>'));

-- insert row2 into table.This insert fails as UNIQUE voilation of id=31201
INSERT INTO company values (1, 'doc1', xmlparse 
        (document '<company name="Company1"> 
        <emp id="31201" salary="60000" gender="Female">
        <name><first>Laura </first><last>Brown</last></name>
        <dept id="M25">Finance</dept></emp></company>'));
-- drop index
DROP INDEX "EMPINDEX";

-- drop table 
DROP TABLE "COMPANY";

-- create table
CREATE TABLE COMPANY(ID int, DOCNAME VARCHAR(20), DOC XML);

-- create index using UNIQUE constraint
CREATE UNIQUE INDEX empindex on company(doc) GENERATE
         KEY USING XMLPATTERN '/company/emp/@id' AS SQL  DOUBLE;

-- insert row into table. No index entry is inserted because "ABCDE" cannot 
-- cast to double data type.
INSERT INTO company values (1, 'doc1', xmlparse
          (document '<company name="Company1">
          <emp id="ABCDE" salary="60000" gender="Female">
          <name><first>Laura </first><last>Brown</last></name>  
          <dept id="M25">Finance</dept></emp></company>'));

-- insert row2 into table.This insert succeeds because no index entry is 
-- inserted since "ABCDE" cannot be cast to DOUBLE datat type.
INSERT INTO company values (1, 'doc1', xmlparse
         (document '<company name="Company1">
         <emp id="ABCDE"
         salary="60000" gender="Female"><name><first>Laura
         </first><last>Brown</last></name><dept id="M25">
         Finance</dept></emp> </company>'));

-- drop index 
DROP INDEX "EMPINDEX";

-- drop table
DROP table "COMPANY";

-- create table
CREATE TABLE COMPANY(ID int, DOCNAME VARCHAR(20), DOC XML);

-- create index with Varchar constraint
CREATE UNIQUE INDEX empindex1 on company(doc)
     GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(4);

-- insert row into table.Insert statement succeeds because length if "312" < 4
INSERT INTO company values (1, 'doc1', xmlparse
        (document '<company name="Company1"><emp id="312"
        salary="60000" gender="Female"><name><first>Laura
        </first><last>Brown</last></name><dept id="M25">
        Finance</dept></emp></company>'));     

-- insert row2 into table.Insert statement fails because the length of 
-- "31202" > 4 
INSERT INTO company values (1, 'doc1', xmlparse
       (document '<company name="Company1"><emp id="31202"
       salary="60000" gender="Female"><name><first>Laura
       </first><last>Brown</last></name><dept id="M25">
       Finance</dept></emp></company>')); 

-- drop index
DROP INDEX "EMPINDEX1";

-- drop table
 DROP TABLE "COMPANY";

-- create table company
CREATE TABLE COMPANY(ID int, DOCNAME VARCHAR(20), DOC XML);

-- insert row into table
INSERT INTO company values (1, 'doc1', xmlparse
      (document '<company name="Company1"><emp id="312"
      salary="60000" gender="Female"><name><first>Laura
      </first><last>Brown</last></name><dept id="M25">
      Finance</dept></emp></company>'));        

-- insert row2 into table
INSERT INTO company values (1, 'doc1', xmlparse
      (document '<company name="Company1"><emp id="31202"
      salary="60000" gender="Female"><name><first>Laura
      </first><last>Brown</last></name><dept id="M25">
      Finance</dept></emp></company>')); 

-- create index with Varchar constraint fails because the 
-- length of "31202" > 4 
CREATE UNIQUE INDEX empindex1 on company(doc)
      GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(4);

-- drop index
DROP index "EMPINDEX1";

--drop table 
DROP table "COMPANY";
