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
-- SAMPLE FILE NAME: xmlcheckconstraint.db2
--
-- PURPOSE: The purpose of this sample is to show how to use check constraints
--          on XML column.
--
-- USAGE SCENARIO: Super market maintains different stores for different
--     products like music players, boots, headphones. Each store sells one
--     type of product, as they would want to have separate accounting or
--     billing for their products. Super market application maintains a
--     separate table data for each product to make his work easy.Whenever
--     a customer purchases some product an entry is made in the corresponding
--     table restricting the table to a particular product entry.
--     Because there are multiple tables and if the manager wants to frequently
--     view data from multiple tables, he creates a view on top of these product
--     tables with required columns. Also, when a customer purchases 2 or
--     more products, inserting data from view has made his job easy.
--     Some times when he wants to get the customer address details, he uses
--     "customer" table from sample database to get only valid data using
--     IS VALIDATED predicate. In XML case, users can insert data into tables
--     through views. But if the user wants to select data, as indexes are
--     created on XML documents on base tables and not on views, it would be
--     best to make use of indexes on base tables rather than using
--     select on views.
--
-- PREREQUISITE: SAMPLE database should exist before running this sample.
--
--    On Unix:    copy boots.xsd file from <install_path>/sqllib
--                /samples/xml/data directory to current directory.
--                copy musicplayer.xsd file from <install_path>/sqllib
--                /samples/xml/data directory to current directory.
--    On Windows: copy boots.xsd file from <install_path>\sqllib\samples\
--                xml\data directory to current directory
--                copy musicplayer.xsd file from <install_path>\sqllib\
--                samples\xml\data directory to current directory
--
-- EXECUTION: db2 -tvf xmlcheckconstraint.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: Displays tables with inserted documents. 
--          One of the insert statements will fail when check constraint
--          is violated.
--
-- OUTPUT FILE: xmlcheckconstraint.out (available in online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TABLE
--           CREATE VIEW
--           REGISTER XMLSCHEMA
--           COMPLETE XMLSCHEMA
--           INSERT
--           SELECT 
--           DROP
--
-- SQL/XML FUNCTIONS USED:
--           XMLVALIDATE
--           XMLPARSE 
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
--
--  SAMPLE DESCRIPTION
--
-----------------------------------------------------------------------------
-- 1. Register XML schemas 
--
-- 2. Create tables with check constraint on XML column and insert data into
--    tables.
--
-- 3. Show partitioning of tables by schema.
--
-- 4. Show usage of IS VALIDATED and IS NOT VALIDATED predicates.
--
-- 5. Shows insert statement failure when check constraint is violated.
--
-- 6. Show check constraint and view dependency on schema.
--
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
--
--   SETUP
--
-----------------------------------------------------------------------------

-- Connect to SAMPLE database
CONNECT TO SAMPLE;

-----------------------------------------------------------------------------
-- 1. Register XML schemas
-----------------------------------------------------------------------------

-- Register XML schema "musicplayer"
REGISTER XMLSCHEMA http://posample1.org FROM musicplayer.xsd as musicplayer;
COMPLETE XMLSCHEMA musicplayer;

-- Register XML schema "boots"
REGISTER XMLSCHEMA http://posample1.org FROM boots.xsd as boots;
COMPLETE XMLSCHEMA boots;

-----------------------------------------------------------------------------
-- 2. Create tables with check constraint on XML column and insert data into
--    tables.
-----------------------------------------------------------------------------

-- Create table "item"
CREATE TABLE item(custid int, xmldoc XML constraint valid_check
  CHECK(xmldoc IS VALIDATED ACCORDING TO XMLSCHEMA IN (ID musicplayer, 
  ID boots)));

-- Insert into table "item"
INSERT INTO item 
VALUES(100, xmlvalidate(xmlparse(document
    '<Product xmlns="http://posample1.org"  PoNum="5001"
       PurchaseDate= "2006-03-01">
         <musicplayer>
           <name>samsung</name>
           <power> 200 watts</power>
           <NoOfSpeakers>5</NoOfSpeakers>
           <NoiseRatio>3</NoiseRatio>
           <NoOfDiskChangers>2</NoOfDiskChangers>
           <price>400.00</price>
         </musicplayer>
    </Product>') ACCORDING TO XMLSCHEMA ID musicplayer));

INSERT INTO item
VALUES (100, XMLVALIDATE(XMLPARSE(document
       '<Product xmlns="http://posample1.org" PoNum="5002"
         PurchaseDate= "2006-04-02">
           <boots>
              <name>adidas</name>
              <size>7</size>
              <quantity>10</quantity>
              <price>299.9</price>
           </boots>
        </Product>') ACCORDING TO XMLSCHEMA ID boots));

-- Create table "musicplayer"
CREATE TABLE musicplayer (custid int, 
         xmldoc XML constraint valid_check1 
           CHECK(xmldoc IS VALIDATED ACCORDING TO XMLSCHEMA ID musicplayer));

-- Insert values into "musicplayer" table.
INSERT INTO musicplayer 
VALUES(100, xmlvalidate(xmlparse(document 
    '<Product xmlns="http://posample1.org"  PoNum="1001" 
       PurchaseDate= "2006-03-01">
         <musicplayer>
           <name>sony</name>
           <power> 100 watts</power>
           <NoOfSpeakers>5</NoOfSpeakers>
           <NoiseRatio>3</NoiseRatio>
           <NoOfDiskChangers>4</NoOfDiskChangers>
           <price>200.00</price>
         </musicplayer>
    </Product>') ACCORDING TO XMLSCHEMA ID musicplayer)); 

-- Create table "boots"
CREATE TABLE boots (custid int, 
    xmldoc XML constraint valid_check2 
        CHECK(xmldoc IS VALIDATED ACCORDING TO XMLSCHEMA ID boots));

-- Insert values into "boots" table
INSERT INTO boots 
VALUES (100, XMLVALIDATE(XMLPARSE(document 
       '<Product xmlns="http://posample1.org" PoNum="1002" 
         PurchaseDate= "2006-04-02">
           <boots>
              <name>nike</name>
              <size>7</size>
              <quantity>10</quantity>
              <price>99.9</price>
           </boots>
        </Product>') ACCORDING TO XMLSCHEMA ID boots));

----------------------------------------------------------------------------
-- 3. Show partitioning of tables by schema
----------------------------------------------------------------------------

-- Create view "view_purchases"
CREATE VIEW view_purchases(custid, xmldoc) AS 
(SELECT  * FROM musicplayer UNION ALL SELECT * FROM boots);

-- Insert values into view "view_purchases"
INSERT INTO view_purchases 
VALUES (1001,xmlvalidate(xmlparse(document 
    '<Product xmlns="http://posample1.org"  PoNum="1007" 
       PurchaseDate="2006-03-10">
          <musicplayer>
            <name>philips</name>
            <power> 1000 watts</power>
            <NoOfSpeakers>2</NoOfSpeakers>
            <NoiseRatio>5</NoiseRatio>
            <NoOfDiskChangers>4</NoOfDiskChangers>
            <price>1200.00</price>
          </musicplayer></Product>') ACCORDING TO XMLSCHEMA ID musicplayer));

-- Insert one more row in view "view_purchases"
INSERT INTO view_purchases 
VALUES (1002, XMLVALIDATE(XMLPARSE(document 
    '<Product xmlns="http://posample1.org" PoNum="1008" 
       PurchaseDate="2006-04-12">
         <boots>
           <name>adidas</name>
           <size>10</size>
           <quantity>2</quantity>
           <price>199.9</price>
         </boots>
     </Product>') ACCORDING TO XMLSCHEMA ID boots));

-- Display contents of "musicplayer" table
SELECT * FROM musicplayer ORDER BY custid;

-- Display contents of "boots" table
SELECT * FROM boots ORDER BY custid;

---------------------------------------------------------------------------
-- 4. Show usage of IS VALIDATED and IS NOT VALIDATED predicates
---------------------------------------------------------------------------

-- Get customer addresses from "customer" table for the customers who
-- purchased boots or musicplayers
SELECT custid, info 
FROM customer C, view_purchases V
WHERE V.custid = C.Cid AND info IS VALIDATED ORDER BY custid;

-- Create table "temp_table"
CREATE TABLE temp_table (custid int, xmldoc XML);

-- Insert values into "temp_table"
INSERT INTO temp_table 
VALUES(1003, 
    '<Product xmlns="http://posample1.org" PoNum="1009" 
       PurchaseDate="2006-04-17">
         <boots>
            <name>Red Tape</name>
            <size>6</size>
            <quantity>2</quantity>
            <price>1199.9</price>
         </boots>
    </Product>');

-- Insert values into "temp_table"
INSERT INTO temp_table 
VALUES(1004, XMLVALIDATE(XMLPARSE(document 
    '<Product xmlns="http://posample1.org" PoNum="1010" 
      PurchaseDate="2006-04-19">
        <boots>
           <name>Liberty</name>
           <size>6</size>
           <quantity>2</quantity>
           <price>900.90</price>
        </boots>
    </Product>') ACCORDING TO XMLSCHEMA ID boots));

-- Create view "temp_table_details"
CREATE VIEW temp_table_details AS 
(SELECT * FROM temp_table WHERE xmldoc IS NOT VALIDATED);

-- Display contents of "temp_table_details" view
SELECT * FROM temp_table_details;

------------------------------------------------------------------------
-- 5. Shows insert statement failure when check constraint is violated
------------------------------------------------------------------------

-- Insert values into "musicplayer" table will fail as the XML document
-- is being validated against wrong schema.
INSERT INTO musicplayer 
VALUES (1005, XMLVALIDATE(XMLPARSE(document 
    '<Product xmlns="http://posample1.org" PoNum="1011" 
       PurchaseDate="2006-04-17">
         <boots>
           <name>Red Tape</name>
           <size>6</size>
           <quantity>2</quantity>
           <price>1199.9</price>
         </boots>
    </Product>') ACCORDING TO XMLSCHEMA ID boots));

-------------------------------------------------------------------------
-- 6. Show check constraint and view dependency on schema
-------------------------------------------------------------------------

-- Drop "boots" schema
DROP XSROBJECT boots;

-- Insert into "boots" table will succeed even without any validation
INSERT INTO boots 
VALUES (1006, 
    '<Product xmlns="http://posample1.org" PoNum="1011" 
       PurchaseDate="2006-04-17">
         <boots>
            <name>Red Tape</name>
            <size>6</size>
            <quantity>2</quantity>
            <price>1199.9</price>
         </boots>
    </Product>');

-- Insert into view "view_purchases" will succeed without any validation
INSERT INTO view_purchases 
VALUES (1007, 
    '<musicplayer xmlns="http://posample1.org"  PoNum="1006"
       PurchaseDate="2006-03-10">
         <name>philips</name>
         <power> 1000 watts </power>
         <NoOfSpeakers>2</NoOfSpeakers>
         <NoiseRatio>5</NoiseRatio>
         <NoOfDiskChangers>4</NoOfDiskChangers>
         <price>1200.00</price>
    </musicplayer>');

----------------------------------------------------------------------------
--  
--    CLEANUP
--
----------------------------------------------------------------------------
DROP VIEW view_purchases;
DROP VIEW temp_table_details;
DROP TABLE musicplayer;
DROP TABLE boots;
DROP TABLE temp_table;
DROP XSROBJECT musicplayer;
DROP TABLE item;
