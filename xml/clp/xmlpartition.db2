-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
--
-- SOURCE FILE NAME: xmlpartition.db2
--
-- SAMPLE: 
--      The sample demonstrates the use of XML in 
--      partitioned database environment, MDC and partitioned tables.
--
-- PREREQUISITE:
--       1)Sample database is setup on the machine.
--
-- Note: Use following command to execute the sample:
--         db2 -td@ -vf xmlpartition.db2
--
--         
-- USAGE SCENARIO:
--       The Scenario is for an Book Store that has two types of customers,  
--       retail customers and corporate customers. Corporate customers do 
--       bulk purchases  of books for their company libraries. The store has  
--       a DBA for maintaining the database; the store manager runs queries  
--       on different tables to view the book sales and to deliver the purchase 
--       orders. 
-- 
--       The store manger, to expand his business, opens more branches in  
--       different countries.
--       The store manager complains to the DBA about the degrading  
--       response time of different queries like: 
--         1) Checks for sales for a particular country every quarter.
--	   2) Checks for sales on different modes of purchase 	
--            (online OR offline).
--         3) Retrieve all purchase orders that are to be delivered to the 
--            customers.
--
--       In order to increase the response time of the queries and speed up  
--       the process, DBA decides to partition the table 'Purchase_Orders'  
--       by 'OrderDate' as range. Because of increasing sales, DBA creates 
--       the tables 'Purchase_Order' and 'Customers' in database partitioned 
--       environment so that data required for delivering a purchase order  
--       like customer and purchase order details from 'Purchase_Orders' and  
--       'Customers' can be fetched quickly. He also organizes the table based  
--       on dimensions, country and modeOfPurchase, so that details about the 
--       sales for a country / mode of purchase can be fetched quickly. 
--       As the year progresses, store DBA ATTACHes a partition the PurchaseOrder 
--       table for every quarter to store the huge volume of data.
--
--
-- SQL STATEMENTS USED:
--       1) CREATE TABLE with DISTRIBUTE BY HASH, PARTITION BY RANGE and		
--          ORGANIZE BY DIMENSIONS clause.
--       2) INSERT 
--       3) SELECT
--       4) ALTER TABLE ... ATTACH
--       5) CREATE INDEX
--
-------------------------------------------------------------------------------

-- Connect to sample database
CONNECT TO sample@


-- For the year 2008, the retail store decides to create a table which is 
-- partitioned for every quarter to store the orders placed by the customer.
-- Each partition will be placed in a separate table space.
-- Four table spaces ('Tbspace1', 'Tbspace2', 'Tbspace3' and 'Tbspace4') are
-- created to contain relational data from the new 'purchaseOrder_Details' table.
-- Four table spaces ('Ltbspace1', 'Ltbspace2', 'Ltbspace3' and 'Ltbspace4') are
-- created to contain long data from the new 'purchaseOrder_Details' table.
SET SCHEMA = store@
CREATE BUFFERPOOL common_Buffer IMMEDIATE SIZE 1000 AUTOMATIC PAGESIZE 4K@

CREATE TABLESPACE Tbspace1 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont1' 10000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Tbspace2 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont2' 10000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Tbspace3 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont3' 10000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Tbspace4 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont4' 10000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@

-- The purchase order information is an XML document. To store XML 
-- data, a large tablespace will be used.
-- Therefore four, large table spaces are created to store XML data for these 
-- partition.
CREATE TABLESPACE Ltbspace1 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont1' 20000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Ltbspace2 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont2' 20000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Ltbspace3 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont3' 20000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Ltbspace4 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont4' 20000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@


-- A tablespace 'Global_IndTbspace' is created to store all 
-- the index data.
CREATE TABLESPACE Global_IndTbspace MANAGED BY DATABASE
   USING (FILE 'cont_globalInd' 10000)@


-- Create tables 'Customers' and 'Purchase_Orders' which stores information
-- about customers and purchase orders placed by them.
CREATE TABLE Customers (id 	        INT NOT NULL PRIMARY KEY,
                        name            VARCHAR(20),
                        country         VARCHAR(20),
                        contactNumber   VARCHAR(15),
                        type            VARCHAR(15),
                        address         XML)
   DISTRIBUTE BY HASH (ID)@


 CREATE TABLE Purchase_Orders 
                     (id 		   INT NOT NULL PRIMARY KEY,
                      status 		   VARCHAR(10),
                      custID 		   INT REFERENCES Customers(id),
                      orderDate 	   DATE,
                      country 	           VARCHAR(20),
                      modeOfPurchase       VARCHAR(10), 
                      pOrder 		   XML,
                      feedback 	           XML)
DISTRIBUTE BY HASH (ID)
   PARTITION BY RANGE (orderDate)
   (PART Q1  STARTING FROM '2008-01-01' ENDING '2008-03-31' IN Tbspace1 LONG IN Ltbspace1,
            PART Q2                   ENDING '2008-06-30' IN Tbspace2 LONG IN Ltbspace2,
            PART Q3                   ENDING '2008-09-30' IN Tbspace3 LONG IN Ltbspace3,
            PART Q4                   ENDING '2008-12-31' IN Tbspace4 LONG IN Ltbspace4 )
   ORGANIZE BY DIMENSIONS (country, modeOfPurchase)@
   

-- Insert data into 'Customers' table
INSERT INTO Customers VALUES (1000,'Joe','Canada','9008788889','Corporate',
                              '<Address>
                                  <Street>1805 Back Street</Street>
                                  <PostalCode>EC3M 4TD</PostalCode>
                                  <City>Toronto</City>
                                  <Country>Canada</Country>
                               </Address>')@
INSERT INTO Customers VALUES (1001,'Smith','US','9876721212','Corporate',
                              '<Address>
                                  <Street>498 White Street</Street>
                                  <City>Los Angeles</City>
                                  <Country>US</Country>
                               </Address>')@
INSERT INTO Customers VALUES (1002,'Bob','US','9876654789','Retail',
                              '<Address>
                                  <Street>98th Main Street</Street>
                                  <PostalCode>100027</PostalCode>
                                  <City>Chicago</City>
                                  <Country>US</Country>
                               </Address>')@
INSERT INTO Customers VALUES (1003,'Patrick','Canada','9000087634','Retail',
                              '<Address>
                                  <Street>Chruch Street</Street>
                                  <City>Charlottetown</City>
                                  <Country>Canada</Country>
                               </Address>')@
INSERT INTO Customers VALUES (1004,'William','Canada','9098765432','Corporate',
                              '<Address>
                                  <Street>City Main</Street>
                                  <City>Yellowknife</City>
                                  <Country>Canada</Country>
                               </Address>')@
INSERT INTO Customers VALUES (1005,'Sue','India','9980808080','Corporate',
                              '<Address>
                                  <POBox>98765</POBox>
                                  <PostalCode>100027</PostalCode>
                                  <City>Bangalore</City>
                                  <Country>India</Country>
                               </Address>')@

-- Insert data into 'Purchase_Orders' table



INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5000,'Shipped',1000,'2008-03-21','Canada','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5000" OrderDate="2008-03-21" Status="shipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 understanding security</name>
		<quantity>3</quantity>
		<price>149.97</price>
	</Book>	
</Books>
<Books Category="Magazines">
	<Book>
		<partid>1000</partid>
		<name>Cars</name>
		<quantity>3</quantity>
		<price>14.97</price>
	</Book>	
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5001,'Shipped',1000,'2008-03-30','Canada','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5001" OrderDate="2008-03-30" Status="shipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 understanding security</name>
		<quantity>3</quantity>
		<price>149.97</price>
	</Book>	
</Books>
<Books Category="Magazines">
	<Book>
		<partid>1001</partid>
		<name>The week</name>
		<quantity>3</quantity>
		<price>8.97</price>
	</Book>	
</Books>
</PurchaseOrder>')@


INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5002,'Shipped',1000,'2008-04-21','Canada','Offline',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5002" OrderDate="2008-04-21" Status="shipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 understanding security</name>
		<quantity>3</quantity>
		<price>149.97</price>
	</Book>	
	<Book>
		<partid>101</partid>
		<name>PHP Power Programming</name>
		<quantity>2</quantity>
		<price>59.98</price>
	</Book>
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5003,'Shipped',1000,'2008-05-21','Canada','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5003" OrderDate="2008-05-21" Status="shipped">
<Books Category="TextBooks">
	<Book>
		<partid>102</partid>
		<name>PHP Pear Programming</name>
		<quantity>1</quantity>
		<price>29.99</price>
	</Book>	
</Books>
<Books Category="Novels">
	<Book>
		<partid>2000</partid>
		<name>7 habbits of success</name>
		<quantity>2</quantity>
		<price>29.98</price>
	</Book>	
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5004,'Shipped',1000,'2008-05-22','Canada','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5004" OrderDate="2008-05-22" Status="shipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 understanding security</name>
		<quantity>1</quantity>
		<price>49.99</price>
	</Book>	
</Books>
<Books Category="Novels">
	<Book>
		<partid>2002</partid>
		<name>Crisis</name>
		<quantity>2</quantity>
		<price>19.98</price>
	</Book>	
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5005,'Shipped',1000,'2008-05-23','Canada','Offline',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5005" OrderDate="2008-05-23" Status="shipped">
<Books Category="Magazines">
	<Book>
		<partid>1004</partid>
		<name>Digit</name>
		<quantity>2</quantity>
		<price>9.98</price>
	</Book>	
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5006,'Shipped',1000,'2008-05-24','Canada','Offline',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5006" OrderDate="2008-05-24" Status="shipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 understanding security</name>
		<quantity>3</quantity>
		<price>149.97</price>
	</Book>	
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5007,'Unshipped',1000,'2008-06-24','Canada','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5007" OrderDate="2008-06-24" Status="Unshipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 understanding security</name>
		<quantity>3</quantity>
		<price>149.97</price>
	</Book>	
</Books>
</PurchaseOrder>')@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder) 
VALUES (5008,'Unshipped',1005,'2008-07-03','India','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5008" OrderDate="2008-07-03" Status="Unshipped">
<Books Category="TextBooks">
	<Book>
		<partid>100</partid>
		<name>DB2 Partitioning techniques</name>
		<quantity>2</quantity>
		<price>59.98</price>
	</Book>	
</Books>
</PurchaseOrder>')@



-- Create an index on the items purchased by the customer.
-- This will help retrieve details about the purchase order faster.
-- The IN clause specifies the tablespace where the INDEX created will be placed.
-- This clause overrides the any INDEX IN clause, specified during the creation of the
-- table.

CREATE INDEX pIndex ON Purchase_Orders(pOrder)
   GENERATE KEY USING XMLPATTERN '/PurchaseOrder/Books/Book/name' AS SQL VARCHAR(60) NOT PARTITIONED
   IN Global_IndTbspace@


-- Statistics is collected on the table 'purchaseOrder_Details' by
-- executing RUNSTATS on it. With the new statistics obtained, DB2 uses
-- the index pIndex on the table for processing any further queries on
-- the table 'purchaseOrder_Details' which uses the predicate 'name' of
-- the XML document.

RUNSTATS ON TABLE store.Purchase_Orders FOR INDEXES ALL@



-- Select customer and purchase order details about the orders that are not shipped
SELECT p.custID, p.id, p.pOrder, c.name, c.contactNumber, c.address
FROM Purchase_Orders as p, Customers as c
WHERE c.id = p.custID and status = 'Unshipped' ORDER BY p.custID@


-- Find total online sales for canada in the second quarter
SELECT sum(X."Price") AS TotalSales
FROM
XMLTABLE ('db2-fn:xmlcolumn("PURCHASE_ORDERS.PORDER")/PurchaseOrder/Books/Book'
COLUMNS
 "PoNum" BIGINT PATH './../../@PoNum',
 "Price" DECFLOAT PATH './price') as X, purchase_orders as p
 WHERE p.id = X."PoNum" and p.orderdate BETWEEN '2008-04-01' AND '2008-06-30' 
   AND country = 'Canada' AND modeOfPurchase = 'Online'@


-- Find total sales that has happened Online and Offline in the second quarter 
WITH temp AS ( SELECT p.modeOfPurchase, p.orderDate, t.price
               FROM Purchase_Orders AS p, XMLTABLE('$po/PurchaseOrder/Books/Book' 
                  passing p.pOrder as "po"
                  COLUMNS price DECFLOAT path './price') AS t)
SELECT temp.modeOfPurchase, sum(temp.price) AS Total FROM temp 
WHERE temp.orderDate BETWEEN '2008-04-01' AND '2008-06-30' 
   GROUP BY temp.modeOfPurchase@


-- As the year progress, store DBA adds new partition for every quarter.
ALTER TABLE Purchase_Orders ADD PARTITION part2009a 
   STARTING FROM '2009-01-01' ENDING '2009-03-31' INCLUSIVE IN Tbspace1 LONG IN Ltbspace1@

INSERT INTO Purchase_Orders(id, status, custID, orderDate, country, modeOfPurchase, pOrder)
VALUES (5009,'Unshipped',1005,'2009-01-03','India','Online',
'<?xml version="1.0" encoding="UTF-8" ?>
<PurchaseOrder PoNum="5009" OrderDate="2009-01-03" Status="Unshipped">
<Books Category="TextBooks">
        <Book>
                <partid>100</partid>
                <name>DB2 Partitioning techniques</name>
                <quantity>2</quantity>
                <price>59.98</price>
        </Book>
</Books>
</PurchaseOrder>')@

-- Select purchase orders that are not shipped for the first quarter of 2009
SELECT * FROM Purchase_Orders 
  where XMLEXISTS('$d/PurchaseOrder/Books/Book[name="DB2 Partitioning techniques"]' passing PORDER as "d") and status = 'Unshipped' and orderDate between '2009-01-01' and '2009-03-31'@


REORG TABLE Purchase_Orders@
REORG INDEX pIndex FOR TABLE Purchase_Orders ALLOW READ ACCESS CLEANUP ONLY@
REORG INDEXES ALL FOR TABLE Purchase_Orders ON DATA PARTITION Q1@
REORG INDEXES ALL FOR TABLE Purchase_Orders ON DATA PARTITION Q2@
REORG INDEXES ALL FOR TABLE Purchase_Orders ON DATA PARTITION Q3@
REORG INDEXES ALL FOR TABLE Purchase_Orders ON DATA PARTITION Q4@
REORG INDEXES ALL FOR TABLE Purchase_Orders ON DATA PARTITION part2009a@

-- Clean-Up Script
DROP INDEX pIndex@
DROP TABLE Purchase_Orders@
DROP TABLE Customers@
DROP TABLESPACE Tbspace1@
DROP TABLESPACE Tbspace2@
DROP TABLESPACE Tbspace3@
DROP TABLESPACE Tbspace4@
DROP TABLESPACE Ltbspace1@
DROP TABLESPACE Ltbspace2@
DROP TABLESPACE Ltbspace3@
DROP TABLESPACE Ltbspace4@
DROP TABLESPACE Global_IndTbspace@
DROP BUFFERPOOL common_Buffer@

-- Close connection to the sample database
CONNECT RESET@

