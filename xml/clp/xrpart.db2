-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
--
-- SOURCE FILE NAME: xrpart.db2
--
-- SAMPLE:
--       This sample showcases the support for XML in partitioned tables.
--
-- PREREQUISITE:
--         1)Sample database is setup on the machine.
--
-- Usage Scenario:
--
--      The sample refers to a retail store which uses seven tables to store
-- data for the store operations. These tables are Product, PurchaseOrder,
-- Customer, Suppliers and four different tables to store purchase order data
-- for every year.
-- The PurchaseOrder table, which stores data for year 2007, contains an
-- XML column 'pOrder' which contains details about the purchase orders. The
-- purchase orders are large XML documents. To get better performance the DBA
-- decides to partition the PurchaseOrder table into four partitions based on
-- the order date.
--
--      The retail store would like to maintain data for five years in one table.
-- The store takes advantage of the table partitioning feature and ATTACHes the
-- purchase order tables for year 2003, 2004, 2005 and 2006 as four separate
-- partitions to the purchaseOrder table. As the year progresses a partition is
-- ADDed to the PurchaseOrder table for every quarter to store the huge volume
-- of data. The retail store also DETACHes partitions containing old data
-- (data older by five years) that is rarely or never accessed.
-- The store can Backup or Archive the stand-alone table which is a direct result
-- of DETACHing a partition from the PurchaseOrder table.
--
--    During winters the retail store sells many new products, such as 'snow
-- shovel'. These products are very popular and are purchased by many customers,
-- resulting in most of the purchase orders containing them. The store's supply
-- department needs to frequently query the 'purchaseOrder' table to decide, what
-- products and quantity the store should restock. The retail store DBA decides
-- to create an index on the pOrder columns containing the purchase order XML
-- documents for faster data retrieval.
--
--      An employee from the stores department is given only a VIEW containing
-- columns from the PurchaseOrder and the Product table to restrict access to
-- other data, such as customer or transaction information. To improve query
-- performance, the developer also creates multiple INDEXes on the PurchaseOrder
-- table, with a particular XML pattern or value, for products which are in
-- great demand and frequently queried.
--
-- SQL STATEMENTS USED:
--            CREATE
--            SELECT
--            INSERT
--            UPDATE
--            ALTER
--            SET INTEGRITY
--
-----------------------------------------------------------------------------

-- /***************************************************************************/
-- /* SAMPLE DESCRIPTION                                                      */
-- /***************************************************************************/
-- /* 1.Create a partitioned TABLE (with a column of type XML)                */
-- /* 2.INSERT data into the table                                            */
-- /* 3.ATTACH a partition to the table                                       */
-- /* 4.ADD partitions to the table                                           */
-- /* 5.DETACH a partition from the table                                     */
-- /* 6.Create an XML Value Index on the XML column                           */
-- /* 7.Create a VIEW over the partitioned table                              */
-- /***************************************************************************/

-- /***************************************************************************/
-- /* The Retail Store has created tables 'StoreProducts',                    */
-- /* 'StoreSuppliers' and 'PurchaseOrder' to store                           */
-- /* details about their day-to-day transactions.                            */
-- /* These table are created in two tablespaces: 'Rcommon_Tbspace' and       */
-- /* 'Rcommon_Ltbspace'.                                                     */
-- /***************************************************************************/

-- Connect to the sample database

CONNECT TO sample;

-- Create two table spaces 'Rcommon_Tbspace', 'Rcommon_Ltbspace'.
-- The regular data from all the tables will be placed in 'Rcommon_Tbspace'
-- table space. Any long data will be placed in 'Rcommon_Ltbspace' table space.

SET SCHEMA = store;
CREATE BUFFERPOOL Rcommon_Buffer IMMEDIATE SIZE 1000 AUTOMATIC PAGESIZE 4K;
CREATE TABLESPACE Rcommon_Tbspace PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'rcont_com1' 10000, FILE 'rcont_com2' 10000, FILE 'rcont_com3' 10000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE Rcommon_Ltbspace PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'rcont_comL' 20000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;

-- Create 'StoreProducts' table to contain details about the products
-- available in the store.


CREATE TABLE StoreProducts (id          BIGINT NOT NULL PRIMARY KEY,
                            name        VARCHAR(50),
                            quantity    INT,
                            price       DECFLOAT,
                            description VARCHAR(100)) IN Rcommon_Tbspace;

-- Insert details about the Products in the store

INSERT INTO StoreProducts VALUES
   (100,'Snow Shovel, Deluxe 24 inch',50, 19.99,
    'Shovel made of wool, keep you warm in winter');

INSERT INTO StoreProducts VALUES
   (102,'Snow Shovel, Super Deluxe 26 inch',50, 49.99,
    'Shovel made of wool, keep you warm in winter');

INSERT INTO StoreProducts VALUES
   (103,'Snow Shovel, Basic 22 inch',50, 49.99,
    'Shovel made of wool, keep you warm in winter');

INSERT INTO StoreProducts VALUES
   (104,'Ice Scraper, Windshield 4 inch',50, 3.99,'');

INSERT INTO StoreProducts VALUES
   (105,'Hand Gloves',50, 19.99,'');

-- Create 'StoreSuppliers' table to contain details about the Suppliers
-- for the store.

CREATE TABLE StoreSuppliers (id               BIGINT,
                             name             VARCHAR(20),
                             pid              BIGINT,
                             quantityPresent  INT,
                             unitprice        DECFLOAT,
                             description      VARCHAR(100)) IN Rcommon_Tbspace;

-- Insert details about the Suppliers of the store

INSERT INTO StoreSuppliers values (1,'Al',101,300,15.99,'');
INSERT INTO StoreSuppliers values (1,'Al',102,250,44.99,'');
INSERT INTO StoreSuppliers values (1,'Al',103,350,43.99,'');
INSERT INTO StoreSuppliers values (2,'Jamel',104,150,3.00,'');
INSERT INTO StoreSuppliers values (3,'James',105,200,17.99,'');

-- Create four purchase order tables to contain data for all the
-- purchase orders placed by customer, including
-- table 'purchaseOrder2003' for the year 2003, 'purchaseOrder2004' for the
-- year 2004, 'purchaseOrder2005' for the year 2005, 'purchaseOrder2006' for
-- the year 2006. Initially, the store had a purchase order table with columns
-- to have only details about the purchase order placed by the customer;
-- later, they decided to have a XML column to save the feedback given by the
-- customer.

CREATE TABLE purchaseOrder2003 ( id            INT NOT NULL,
                                 status        VARCHAR(10),
                                 orderDate     DATE,
                                 customerID    INT,
                                 pOrder        XML)
   PARTITION BY RANGE (orderDate)
   (STARTING FROM '2003-01-01' ENDING '2003-12-31')
IN Rcommon_Tbspace LONG IN Rcommon_Ltbspace;

CREATE TABLE purchaseOrder2004 ( id               INT NOT NULL,
                                 status           VARCHAR(10),
                                 orderDate        DATE,
                                 customerID       INT,
                                 pOrder           XML)
   PARTITION BY RANGE (orderDate)
   (STARTING FROM '2004-01-01' ENDING '2004-12-31')
IN Rcommon_Tbspace LONG IN Rcommon_Ltbspace;


CREATE TABLE purchaseOrder2005 ( id               INT NOT NULL,
                                 status           VARCHAR(10),
                                 orderDate        DATE,
                                 customerID       INT,
                                 pOrder           XML)
   PARTITION BY RANGE (orderDate)
   (STARTING FROM '2005-01-01' ENDING '2005-12-31')
IN Rcommon_Tbspace LONG IN Rcommon_Ltbspace;

CREATE TABLE purchaseOrder2006 ( id               INT NOT NULL,
                                 status           VARCHAR(10),
                                 orderDate        DATE,
                                 customerID       INT,
                                 pOrder           XML)
   PARTITION BY RANGE (orderDate)
   (STARTING FROM '2006-01-01' ENDING '2006-12-31')
IN Rcommon_Tbspace LONG IN Rcommon_Ltbspace;

-- For the year 2007, the retail store decides to create a table which is
-- partitioned for every quarter to store the orders placed by the customer.
-- Each partition will be placed in a separate table space.
-- Four table spaces ('RTbspace1', 'RTbspace2', 'RTbspace3' and 'RTbspace4') are
-- created to contain relational data from the new 'purchaseOrder_Details' table.
-- Four table spaces ('RLtbspace1', 'RLtbspace2', 'RLtbspace3' and 'RLtbspace4') are
-- created to contain long data from the new 'purchaseOrder_Details' table.

CREATE TABLESPACE RTbspace1 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'rcont1' 10000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE RTbspace2 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'rcont2' 10000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE RTbspace3 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'rcont3' 10000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE RTbspace4 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'rcont4' 10000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;

-- The purchase order information is an XML document. To store XML
-- data, a large tablespace will be used.
-- Therefore four, large table spaces are created to store XML data for these
-- partition.

CREATE TABLESPACE RLtbspace1 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'Lrcont1' 20000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE RLtbspace2 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'Lrcont2' 20000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE RLtbspace3 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'Lrcont3' 20000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;
CREATE TABLESPACE RLtbspace4 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'Lrcont4' 20000)
   PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;

-- Create two tablespaces 'RInd_Tbspace' and 'RGlobal_IndTbspace' to store all
-- the index data. Create 4 tablespaces 'Ind_Tbspace1', 'Ind_Tbspace2', 'Ind_Tbspace3',
-- 'Ind_Tbspace4' to store all index data for four data ranges.

CREATE TABLESPACE RInd_Tbspace MANAGED BY DATABASE
   USING (FILE 'rcont_index' 10000);
CREATE TABLESPACE RGlobal_IndTbspace MANAGED BY DATABASE
   USING (FILE 'rcont_globalInd' 10000);

CREATE TABLESPACE Ind_Tbspace1 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'cont_index1' 10000)
PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;

CREATE TABLESPACE Ind_Tbspace2 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'cont_index2' 10000)
PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;

CREATE TABLESPACE Ind_Tbspace3 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'cont_index3' 10000)
PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;

CREATE TABLESPACE Ind_Tbspace4 PAGESIZE 4K MANAGED BY DATABASE
   USING (FILE 'cont_index4' 10000)
PREFETCHSIZE 4K BUFFERPOOL Rcommon_Buffer;



-- Create 'purchaseOrder_Details' table partitioned by 'orderDate' for every
-- quarter. Data for this table will be stored in tablespaces created above
-- ('RTbspace1','RTbspace2','RTbspace3','RTbspace4'). Long data will be stored in
-- large tablespaces created above ('RLtbspace1','RLtbspace2','RLtbspace3',
-- 'RLtbspace4'). Index created will be stored in a tablespace created for
-- storing indexes ('RInd_Tbspace').

CREATE TABLE purchaseOrder_Details ( id               INT NOT NULL,
                                     status           VARCHAR(10),
                                     orderDate        DATE,
                                     customerID       INT,
                                     pOrder           XML)
   INDEX IN RInd_Tbspace PARTITION BY RANGE (orderDate)
 (PART part1 STARTING FROM '2007-01-01' ENDING '2007-03-31' IN RTbspace1 INDEX IN Ind_Tbspace1 LONG IN RLtbspace1,
  PART part2 STARTING FROM '2007-04-01' ENDING '2007-06-30' IN RTbspace2 INDEX IN Ind_Tbspace2 LONG IN RLtbspace2,
  PART part3 STARTING FROM '2007-07-01' ENDING '2007-09-30' IN RTbspace3 INDEX IN Ind_Tbspace3 LONG IN RLtbspace3,
  PART part4 STARTING FROM '2007-10-01' ENDING '2007-12-31' IN RTbspace4 INDEX IN Ind_Tbspace4 LONG IN RLtbspace4);

-- Insert data into the 'purchaseOrder_Details' table


INSERT INTO purchaseOrder_Details(id,status,orderDate,customerID,pOrder) VALUES
   (1001,'Unshipped','2007-04-20',101,
      '<PurchaseOrder PoNum="1001" OrderDate="2007-04-20" status="Unshipped">
          <item>
                <partid>101</partid>
                <name>Snow Shovel, Deluxe 24 inch</name>
                <quantity>1</quantity>
                <price>19.99</price>
          </item>
          <item>
                <partid>102</partid>
                <name>Snow Shovel, Super Deluxe 26 inch</name>
                <quantity>9</quantity>
                <price>49.99</price>
          </item>
          <item>
                <partid>104</partid>
                <name>Ice Scraper, Windshield 4 inch</name>
                <quantity>1</quantity>
                <price>3.99</price>
          </item>
       </PurchaseOrder>' );



INSERT INTO purchaseOrder_Details(id, status, orderDate, customerID, pOrder) VALUES
   (1000,'Unshipped','2007-02-20',100,
        '<PurchaseOrder PoNum="1000" OrderDate="2007-02-20" Status="Unshipped">
                <item>
                <partid>103</partid>
                        <name>Snow Shovel, Basic 22 inch</name>
                <quantity>5</quantity>
                <price>49.99</price>
                </item>
                <item>
                        <partid>102</partid>
                        <name>Snow Shovel, Super Deluxe 26 inch</name>
                        <quantity>13</quantity>
                        <price>49.99</price>
                </item>
         </PurchaseOrder>' );

INSERT INTO purchaseOrder_Details(id, status, orderDate, customerID, pOrder) VALUES
   (1002,'Unshipped','2007-06-24',100,
        '<PurchaseOrder PoNum="1002" OrderDate="2007-06-24" Status="Unshipped">
            <item>
                <partid>104</partid>
                        <name>Ice Scraper, Windshield 4 inch</name>
                <quantity>10</quantity>
                <price>3.99</price>
            </item>
            <item>
                  <partid>102</partid>
                  <name>Snow Shovel, Super Deluxe 26 inch</name>
                  <quantity>8</quantity>
                  <price>49.99</price>
            </item>
         </PurchaseOrder>' );

INSERT INTO purchaseOrder_Details(id, status, orderDate, customerID, pOrder) VALUES
   (1003,'Unshipped','2007-06-24',103,
        '<PurchaseOrder PoNum="1003" OrderDate="2007-04-21" Status="Unshipped">
            <item>
                  <partid>105</partid>
                  <name>Hand Gloves</name>
                  <quantity>3</quantity>
                  <price>19.99</price>
            </item>
            <item>
                  <partid>102</partid>
                  <name>Snow Shovel, Super Deluxe 26 inch</name>
                  <quantity>15</quantity>
                  <price>49.99</price>
            </item>
         </PurchaseOrder>' );

-- Create an index on the items purchased by the customer.
-- This will help retrieve details about the purchase order faster.
-- The IN clause specifies the tablespace where the INDEX created will be placed.
-- This clause overrides the any INDEX IN clause, specified during the creation of the
-- table.

CREATE INDEX pIndex ON purchaseOrder_Details(pOrder)
   GENERATE KEY USING XMLPATTERN '/PurchaseOrder/item/name' AS SQL VARCHAR(60) NOT PARTITIONED
   IN RGlobal_IndTbspace;

-- Create an index on the items and date of purchase for the purchase made by the customer


CREATE INDEX DateIndex ON store.purchaseOrder_Details(pOrder)
   GENERATE KEY USING XMLPATTERN '/PurchaseOrder/@OrderDate' AS SQL VARCHAR(60) PARTITIONED;

CREATE INDEX NameIndex ON store.purchaseOrder_Details(pOrder)
   GENERATE KEY USING XMLPATTERN '/PurchaseOrder/item/name' AS SQL VARCHAR(60) PARTITIONED;

-- Statistics is collected on the table 'purchaseOrder_Details' by
-- executing RUNSTATS on it. With the new statistics obtained, DB2 uses
-- the index pIndex on the table for processing any further queries on
-- the table 'purchaseOrder_Details' which uses the predicate 'name' of
-- the XML document.

RUNSTATS ON TABLE store.purchaseOrder_Details FOR INDEXES ALL;

-- The retail store can checks for any orders that are not delivered.

SELECT id FROM purchaseOrder_Details WHERE status = 'Unshipped' ORDER BY id;

-- Once the item is shipped, 'purchaseOrder_Details' table is updated
-- to reflect the status of the product delivered. (Status is changed from
-- Unshipped to Shipped).
-- The 'purchaseOrder_Details' table is also updated to contain any feedback from
-- the customer.

UPDATE purchaseorder_Details
SET porder =
   xmlquery('transform
             copy $po := $order
             modify do replace value of $po/PurchaseOrder/@Status with "Shipped"
             return $po'
             passing pOrder as "order"), status = 'Shipped' WHERE id=1000;


-- /***************************************************************************/
-- /* The retail store decides to keep all the purchase order information     */
-- /* from the last five years in 'PurchaseOrder_Details' table.              */
-- /* To do that, the store ATTACHes the four purchaseOrder tables created    */
-- /* earlier, 'purchaseOrder2003', 'purchaseOrder2004', 'purchaseOrder2005'  */
-- /* and 'purchaseOrder2006' to the main table, which is                     */
-- /* 'purchaseOrder_Details'.                                                */
-- /* For the year 2008, the store ADDs new partition to the                  */
-- /* 'purchaseOrder_Details' table for every quarter.                        */
-- /***************************************************************************/

-- ALTER the purchaseOrder_Details table to ATTACH partitions 'part2003',
-- 'part2004', 'part2005' and 'part2006' from tables 'purchaseOrder2003',
-- 'purchaseOrder2004', 'purchaseOrder2005', 'purchaseOrder2006'.

ALTER TABLE purchaseOrder_Details ATTACH PARTITION part2003
   STARTING FROM '2003-01-01' ENDING '2003-12-31' INCLUSIVE FROM purchaseOrder2003;
ALTER TABLE purchaseOrder_Details ATTACH PARTITION part2004
   STARTING FROM '2004-01-01' ENDING '2004-12-31' INCLUSIVE FROM purchaseOrder2004;
ALTER TABLE purchaseOrder_Details ATTACH PARTITION part2005
   STARTING FROM '2005-01-01' ENDING '2005-12-31' INCLUSIVE FROM purchaseOrder2005;
ALTER TABLE purchaseOrder_Details ATTACH PARTITION part2006
   STARTING FROM '2006-01-01' ENDING '2006-12-31' INCLUSIVE FROM purchaseOrder2006;

-- The 'purchaseOrder_Details' table goes into Set Integrity Pending State after the
-- partitions are attached.
-- The table has to be brought out of Set Integrity Pending State before performing
-- any operation on it.

SET INTEGRITY FOR purchaseOrder_Details IMMEDIATE CHECKED;

-- As per the retail store policy only, five years data is maintained
-- in the table. The retail store DETACHes a partition from the table
-- 'purchaseOrder_Details' when they ADD a partition for 2008.
-- ALTER the 'purchaseOrder_Details' table to contain a new column
-- 'customerFeedback'. Populate this column with some feedback for order id 1000.
-- The DETACHed  partition contains data from the year 2003 and is available as a
-- stand-alone table after the DETACH.

ALTER TABLE purchaseOrder_Details ADD PARTITION part2008a
   STARTING FROM '2008-01-01' ENDING '2008-03-31' INCLUSIVE IN RTbspace1 LONG IN RLtbspace1;

ALTER TABLE purchaseOrder_Details ADD COLUMN customerFeedback XML;

-- Reorganize the table and all indexes defined on a table by rebuilding the index data into 
-- unfragmented, physically contiguous pages. This improves the performance of query.
-- NOTE :: REORG is also possible at partition level.

REORG TABLE purchaseorder_Details;
REORG INDEX pIndex FOR TABLE purchaseorder_Details ALLOW READ ACCESS CLEANUP ONLY;
REORG INDEXES ALL FOR TABLE purchaseorder_Details ON DATA PARTITION part2;

ALTER TABLE purchaseOrder_Details DETACH PARTITION part2003 INTO TABLE purchaseOrder2003;


-- Table purchaseOrder_Details is updated to contain the feedback from a customer

UPDATE purchaseOrder_Details
SET customerFeedback = '<Feedback>
                           <item>
                                 <name>Snow Shovel, Basic 22 inch</name>
                           </item>
                           <item>
                                 <name>Snow Shovel, Super Delux 26 inch</name>
                                 <comment>Snow Shovel is very Good, But
                                          a little bit expensive</comment>
                           </item>
                        </Feedback>' where id = 1000;




-- Store manager selects from purchaseOrder_Details, purchase order and customerFeedback for
-- 1000th purchase order.
Select pOrder, customerFeedback FROM purchaseOrder_Details WHERE id = 1000;                                                                                                  
-- A view is created which comprise of data from table 'product' and
-- 'purchaseOrder_Details' table, so that the employee of the store can
-- manipulate over the view and decide over the products in demand and
-- replenish the stocks in the store.

CREATE VIEW PurchaseOrderView (ID,NAME,QUANTITY,QuantityAvail,orderDate)
        AS
   SELECT p.id, v.name, v.quantity, p.Quantity, v.orderDate
      FROM StoreProducts AS p, XMLTABLE('db2-fn:xmlcolumn("PURCHASEORDER_DETAILS.PORDER")/PurchaseOrder/item'
                          COLUMNS partid INTEGER path 'partid',
                          name varchar(60) path 'name',
                          quantity INTEGER path 'quantity',
                          orderdate varchar(50) path 'xs:string(../@OrderDate)') AS v
   WHERE p.id = v.partid;

-- Employee select from the view 'PurchaseOrderView' created to check
-- for the total sales of the product 'Snow Shovel, Deluxe 26 inch'
-- for last 10 days, as this product is in great demand.

SELECT ID,NAME,sum(QUANTITY) as Quantity_Sold,QUANTITYAVAIL
    FROM PurchaseOrderView
    WHERE name = 'Snow Shovel, Super Deluxe 26 inch' AND
             orderDate BETWEEN '2007-06-20' AND '2007-06-30'
GROUP BY id,name,QUANTITYAVAIL;

-- Employee decides to replenish the stock for the product 'Snow Shovel, Deluxe 26 inch'
-- and places a order for 25 'Snow Shovel, Deluxe 26 inch' to the supplier of store
-- as the amount of Snow Shovels sold for last 10 days is more than the stock present
-- in the store.

SELECT * FROM StoreSuppliers
    WHERE pid = (SELECT DISTINCT id FROM PurchaseOrderView
                   WHERE name = 'Snow Shovel, Super Deluxe 26 inch');

UPDATE StoreProducts SET quantity = quantity + 30
    WHERE name = 'Snow Shovel, Super Deluxe 26 inch';

-- /***************************************************************************/
-- /*                             Cleanup Section                             */
-- /***************************************************************************/
-- Drop Indexes
DROP INDEX pIndex;
DROP INDEX DateIndex;
DROP INDEX NameIndex;

-- Drop tables
DROP TABLE purchaseOrder2003;
DROP TABLE purchaseOrder_Details;
DROP TABLE StoreProducts;
DROP TABLE StoreSuppliers;

-- Drop view
DROP VIEW PurchaseOrderView;

-- Drop tablespaces
DROP TABLESPACE Rcommon_Tbspace;
DROP TABLESPACE Rcommon_Ltbspace;
DROP TABLESPACE RTbspace1;
DROP TABLESPACE RTbspace2;
DROP TABLESPACE RTbspace3;
DROP TABLESPACE RTbspace4;
DROP TABLESPACE RLtbspace1;
DROP TABLESPACE RLtbspace2;
DROP TABLESPACE RLtbspace3;
DROP TABLESPACE RLtbspace4;
DROP TABLESPACE Ind_Tbspace1;
DROP TABLESPACE Ind_Tbspace2;
DROP TABLESPACE Ind_Tbspace3;
DROP TABLESPACE Ind_Tbspace4;
DROP TABLESPACE RInd_Tbspace;
DROP TABLESPACE RGlobal_IndTbspace;
DROP BUFFERPOOL Rcommon_Buffer;

-- Reset schema
SET SCHEMA = USER;
-- Close connection to the sample database
CONNECT RESET;

