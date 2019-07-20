-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2008 All rights reserved.
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
-- SAMPLE FILE NAME: xmlmdc.db2
--
-- PURPOSE: This sample demonstrates the following features
--     1. XML data type column in MDC tables.
--     2. Faster insert and faster delete options support in MDC tables
--        having XML columns.
--         
-- USAGE SCENARIO: The scenario is for a Book Store that has two types 
--      of customers, retail customers and corporate customers. 
--      Corporate customers do bulk purchases of books for their company
--      libraries. The store's DBA maintains the database, 
--      the store manager runs queries on different tables to view 
--      the book sales. 
--
--      The store expands and opens four more branches
--      in the city, all the books are spread across different branches. 
--      The store manager complains to the DBA that queries to get details
--      like availability of a particular book by a particular author
--      in a particular branch are very slow. 
-- 
--      The DBA decides to improve the query performance by converting a 
--      non-MDC table, for books available in different branches of the
--      store, into an MDC table. To further improve the query performace,
--      the DBA decides to create partition on the MDC table based on 
--      the published date of the book. By creating an MDC table, the query 
--      performance increases and the sales clerk can do faster inserts into 
--      this table when he receives books from different suppliers. He can 
--      also do faster deletes when he wants to delete a particular type of
--      book due to low sales in a particular branch for that category of 
--      book in that location.
--
-- PREREQUISITE: The SAMPLE database should exist before running this script.
--
-- EXECUTION: db2 -tvf xmlmdc.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: Successful execution of all the queries.
--
-- OUTPUT FILE: xmlmdc.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TABLE
--           INSERT
--           DROP
-- SQL/XML FUNCTIONS USED:
-- 		XMLEXISTS
--
-----------------------------------------------------------------------------
--
--  SAMPLE DESCRIPTION
--
-----------------------------------------------------------------------------
-- This sample demonstrates :
-- 1. Moving data from a non-MDC table to an MDC table.
-- 2. MDC table with partition.
-- 3. Faster inserts into MDC table containing an XML column.
-- 4. Faster delete on MDC table containing an XML column.
-- 5. Exploiting block indexes and XML indexes in a query.
-----------------------------------------------------------------------------
--
--   SETUP
--
-----------------------------------------------------------------------------

-- Connect to sample
CONNECT TO SAMPLE;

-----------------------------------------------------------------------------
-- 1. Moving data from a non-MDC table to an MDC table
-----------------------------------------------------------------------------

-- Create schema testschema
CREATE SCHEMA testschema;

-----------------------------------------------------------------------------
-- Setting up tables for the sample
-----------------------------------------------------------------------------

-- Create non-MDC table 'books'
CREATE TABLE testschema.books(book_id VARCHAR(10), publish_date DATE, 
           category VARCHAR(20), location VARCHAR(20), status VARCHAR(15));

-- Insert values into table 'books'
INSERT INTO testschema.books 
  VALUES ('BK101', '10-01-2008', 'Management', 'Tasman', 'available');

INSERT INTO testschema.books 
  VALUES ('BK102', '01-01-2008', 'Fantasy', 'Cupertino', 'available');

INSERT INTO testschema.books 
  VALUES('BK103', '10-10-2007', 'Fantasy', 'Cupertino', 'ordered');

INSERT INTO testschema.books 
  VALUES ('BK104', '05-02-2007', 'Spiritual', 'Tasman', 'available');

-- Create 'books_mdc' table partitioned by 'publish date' and organized
-- by multiple dimensions - category, location and status.
CREATE TABLE testschema.books_mdc(book_id VARCHAR(20), publish_date DATE, category 
		VARCHAR(20), location VARCHAR(20), status VARCHAR(15), 
		book_details XML) 
DISTRIBUTE BY HASH(book_id)
PARTITION BY RANGE(publish_date)
	(STARTING FROM ('01-01-2007')
	ENDING ('12-12-2008') EVERY 3 MONTHS)
ORGANIZE BY DIMENSIONS (category, location, status);

-- Move the book details data from 'books' table and insert 
-- them into 'books_mdc' table
INSERT INTO testschema.books_mdc(book_id, publish_date, category, location, status)
	SELECT book_id, publish_date, category, location, status FROM testschema.books;

-- Update the 'books_mdc' table with 'book_details' XML data
UPDATE testschema.books_mdc SET book_details = '<book_details id="BK101">
					<name>Communication skills</name>
					<author>Peter Sharon</author>
					<price>120</price>
					<publications>Wroxa</publications>
				</book_details>'
WHERE book_id='BK101';

UPDATE testschema.books_mdc SET book_details = '<book_details id="BK102">
					<name>Blue moon</name>
					<author>Paul Smith</author>
					<price>100</price>
					<publications>Orellier</publications>
				</book_details>'
WHERE book_id='BK102';


UPDATE testschema.books_mdc SET book_details = '<book_details id="BK103">
					<name>Paint your house</name>
					<author>Roger Martin</author>
					<price>120</price>
					<publications>BPBH</publications>
				</book_details>'
WHERE book_id='BK103';

UPDATE testschema.books_mdc SET book_details = '<book_details id="BK104">
					<name>Ramayan</name>
					<author>Eric Mathews</author>
					<price>90</price>
					<publications>Tata Ho</publications>
				</book_details>'
WHERE book_id = 'BK104';

-- Display the contents of 'books_mdc' table
SELECT book_id, publish_date, category, location, status 
  FROM testschema.books_mdc;

--------------------------------------------------------------------------
-- 2. MDC table with partition
--------------------------------------------------------------------------
-- When a customer comes to the store 'Tasman' branch and asks for a management 
-- book by a particular author 'Peter Sharon', published on 1st October 2008, 
-- the following query issued by the sales clerk directly goes to the table 
-- partition (October to December) and gets the book details.

-- This query gets the details of list of 'Management' books 
-- available in 'Tasman' branch whose published date is 10-01-2008 
SELECT book_id, publish_date, category, location, status 
FROM testschema.books_mdc
WHERE  location='Tasman' 
   and category='Management' 
   and publish_date='10-01-2008' 
   and XMLEXISTS ('$b/book_details[author="Peter Sharon"]' 
                   PASSING book_details as "b");


----------------------------------------------------------------------------
-- 3. Faster inserts into MDC table containing an XML column.
----------------------------------------------------------------------------
-- The store receives in bulk management books from different 
-- suppliers, These books are entered into database by the sales clerk.
-- As all the books to be inserted belong to same dimension
-- (category, location and status), the sales clerk while inserting the 
-- book details into the books_mdc table enables the LOCKSIZE BLOCKINSERT
-- option for faster insert on MDC table. He does the following operations.

-- Enable the LOCKSIZE BLOCKINSERT option for faster insert on MDC table
ALTER TABLE testschema.books_mdc LOCKSIZE BLOCKINSERT;
UPDATE command options using c off;

-- Insert values into 'books_mdc' table
-- Insert data into block '0'
INSERT INTO testschema.books_mdc 
  VALUES('BK105', '12-10-2007', 'Management', 'Schaumberg',
            'available','<book_details id="BK105">
					<name>How to Sell or Market</name>
					<author>Rusty Harold</author>
					<price>450</price>
					<publications>Orellier</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK106', '03-12-2007', 'Management', 'Schaumberg',
            'available','<book_details id="BK106">
					<name>How to become CEO</name>
					<author>Booster Hoa</author>
					<price>150</price>
					<publications>wroxa</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK107', '06-25-2008', 'Management', 'Schaumberg',
            'available','<book_details id="BK107">
					<name>Effective Email communication</name>
					<author>Sajer Menon</author>
					<price>100</price>
					<publications>PHPB</publications>
				</book_details>');
COMMIT;

-- Insert data into block '1'
INSERT INTO testschema.books_mdc 
  VALUES('BK108', '04-23-2008', 'Management', 'Cupertino',
        'Not available','<book_details id="BK108">
					<name>Presentation skills</name>
					<author>Martin Lither</author>
					<price>125</price>
					<publications>PHPB</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK109', '09-25-2007', 'Management', 'Cupertino',
       'Not available','<book_details id="BK109">
					<name>Assertive Skills</name>
					<author>Robert Steve</author>
					<price>250</price>
					<publications>wroxa</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK110', '05-29-2007', 'Management', 'Cupertino',
        'Not available','<book_details id="BK110">
					<name>Relationship building</name>
					<author>Bunting Mexa</author>
					<price>190</price>
					<publications>Tata Ho</publications>
				</book_details>');
COMMIT;

-- Insert data into block '2'
INSERT INTO testschema.books_mdc 
  VALUES('BK111', '08-14-2008', 'Management', 'Tasman',
           'available','<book_details id="BK111">
					<name>Manage your Time</name>
					<author>Pankaj Singh</author>
					<price>125</price>
					<publications>Orellier</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK112', '07-25-2008', 'Management', 'Tasman',
           'available','<book_details id="BK112">
					<name>Be in the Present</name>
					<author>Hellen Sinki</author>
					<price>200</price>
					<publications>Orellier</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK113', '06-23-2008', 'Management', 'Tasman',
           'available',	'<book_details id="BK112">
					<name>How to become Rich</name>
					<author>Booster Hoa</author>
					<price>200</price>
					<publications>wroxa</publications>
				</book_details>');
COMMIT;

-- Insert data into block '3'
INSERT INTO testschema.books_mdc 
  VALUES('BK114', '08-08-2008', 'Fantasy', 'Schaumberg',
           'available','<book_details id="BK113">
					<name>Dream home</name>
					<author>Hellen Sinki</author>
					<price>250</price>
					<publications>wroxa</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK115', '05-12-2008', 'Fantasy', 'Schaumberg',
           'available',	'<book_details id="BK115">
					<name>Dream world</name>
					<author>Hellen Sinki</author>
					<price>100</price>
					<publications>wroxa</publications>
				</book_details>');
COMMIT;

-- Insert data into block '4'
INSERT INTO testschema.books_mdc 
  VALUES('BK116', '09-10-2007', 'Fantasy', 'Cupertino',
       'Not available','<book_details id="BK116">
					<name>Mothers Island</name>
					<author>Booster Hoa</author>
					<price>250</price>
					<publications>wroxa</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK117', '03-11-2007', 'Fantasy', 'Cupertino',
       'Not available','<book_details id="BK117">
					<name>The destiny </name>
					<author>Marran</author>
					<price>250</price>
					<publications>Orellier</publications>
				</book_details>');
COMMIT;

-- Insert data into block '5'
INSERT INTO testschema.books_mdc 
  VALUES('BK118', '03-12-2007', 'Spiritual', 'Tasman',
           'available','<book_details id="BK118">
					<name>Mahabharat</name>
					<author>Narayana Murthy</author>
					<price>250</price>
					<publications>PHPB</publications>
				</book_details>');

INSERT INTO testschema.books_mdc 
  VALUES('BK119', '09-09-2008', 'Spiritual', 'Tasman',
           'available','<book_details id="BK119">
					<name>Bhagavat Gita</name>
					<author>Narayana Murthy</author>
					<price>250</price>
					<publications>PHPB</publications>
				</book_details>');
COMMIT;

-- Run Runstats command on MDC table to update statistics in the catalog
-- tables.
RUNSTATS ON TABLE testschema.books_mdc WITH DISTRIBUTION and 
DETAILED INDEXES ALL;

-- Change the locksize to default
ALTER TABLE testschema.books_mdc LOCKSIZE ROW;

------------------------------------------------------------------------
-- 4. Faster delete on MDC table containing an XML column.
------------------------------------------------------------------------
-- During monthly analysis the store manager finds out that the 
-- 'Fantasy' category books at 'Cupertino' branch don't have many sales. 
-- So he asks the DBA to delete these books from 'Cupertino' branch. 
-- As all deletes belong to one particular category, the DBA decides 
-- to set the following option to make the delete operation faster.

-- Set MDC ROLLOUT option to make the delete operation faster.
SET CURRENT MDC ROLLOUT MODE IMMEDIATE;

-- Delete all 'Fantasy' category books from 'books_mdc' table
DELETE FROM testschema.books_mdc 
  WHERE category='Fantasy' AND location='Cupertino';

-- Note that the data is saved before it is rolled out.

--------------------------------------------------------------------------
-- 5. Exploiting block indexes and XML indexes in a query
--------------------------------------------------------------------------
-- For faster retrieval of data the DBA creates an XML index on the author 
-- element of book_details XML document.
CREATE INDEX auth_ind ON testschema.books_mdc(book_details)
  GENERATE KEY USING XMLPATTERN '/book_details/author' 
  AS SQL VARCHAR(20); 

-- Query the table to get all 'Management' books available in the store
-- by author 'Booster Ho'. This query exploits both block index 
-- and XML index.
SELECT book_id, publish_date, category, location, status 
FROM testschema.books_mdc 
WHERE category='Management' 
  AND status='available' 
  AND XMLEXISTS('$b/book_details[author="Booster Hoa"]' 
         PASSING book_details as "b");

--------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------
DROP INDEX auth_ind;
DROP TABLE testschema.books;
DROP TABLE testschema.books_mdc;
DROP SCHEMA testschema RESTRICT;
		
