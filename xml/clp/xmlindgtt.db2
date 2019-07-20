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
-- SOURCE FILE NAME: xmlindgtt.db2
--
-- SAMPLE: 
--      The sample demonstrates the support for XML in Declare global 
--      temporary table (DGTT).    
--
-- PREREQUISITE:
--       1)Sample database is setup on the machine.
--
-- Note: Use following command to execute the sample:
--         db2 -td@ -vf xmlindgtt.db2
--
-- USAGE SCENARIO:
--         The Scenario is for a Book Store that has two types of customers; 
--      retail customers and corporate customers. These customers can either 
--      purchase the books online or from the book store.
-- 
--         When an online transaction is made by the customers, the store 
--      tracks all the orders placed by the customer in a transaction such as 
--      adding a book to the cart, deleting a book from the cart or updating 
--      the details about the items in the cart. The order details of each book 
--      including 'name', 'quantity', and 'price' is stored as an XML document. 
--         To store these intermediate transaction details, the store uses a 
--      temporary table (DGTT).
--
--         At the end of the transaction, the orders for different books placed by 
--      the customer in a transaction are collected from the temporary table and 
--      stored in a static table 'purchase_orders' as a single entity, an XML 
--      document.
--
--         At the end of the day, the store will access the records in the 
--      'purchase_orders' table and deliver those products whose status is 
--      'Unshipped'.
--
-- SQL STATEMENTS USED:
--       1) DECLARE GLOBAL TEMPORARY TABLE <TempTable(Column XML)>
--       2) INSERT INTO TempTable VALUES ('<XML>')
--       3) CREATE INDEX
--       4) UPDATE TempTable SET XMLColumn = ...
--       5) DELETE FROM TempTable WHERE XMLEXIST ...
--       6) DROP 
--
-------------------------------------------------------------------------------

-- Connect to sample database

CONNECT TO sample@


-- The book store decides to create a table which is partitioned for every 
-- quarter to store the orders placed by the customer. Each partition will 
-- be placed in a separate table space. Four table spaces ('Tbspace1', 
-- 'Tbspace2', 'Tbspace3' and 'Tbspace4') are created to contain relational 
-- data from the new 'purchase_orders' table. Four table spaces ('Ltbspace1', 
-- 'Ltbspace2', 'Ltbspace3' and 'Ltbspace4') are created to contain long 
-- data from the new 'purchase_orders' table.

CREATE BUFFERPOOL common_Buffer IMMEDIATE SIZE 1000 AUTOMATIC PAGESIZE 4K@

CREATE TABLESPACE Tbspace1 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont1' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Tbspace2 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont2' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Tbspace3 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont3' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Tbspace4 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'cont4' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@


-- The purchase order information is an XML document. To store XML data, a 
-- large tablespace will be used. Hence, four large table spaces are created 
-- to store XML data for these partitions.

CREATE TABLESPACE Ltbspace1 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont1' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Ltbspace2 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont2' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Ltbspace3 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont3' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@
CREATE TABLESPACE Ltbspace4 PAGESIZE 4K MANAGED BY DATABASE 
   USING (FILE 'Lcont4' 2000)
   PREFETCHSIZE 4K BUFFERPOOL common_Buffer@


-- When an online transaction is made, all the orders placed by the customer 
-- in the transaction are placed in a temporary table. A user temporary table 
-- space is created to contain this temporary table. 

CREATE USER TEMPORARY TABLESPACE temp_tbsp@


-- Create 'purchase_orders' table partitioned by 'orderDate' for every quarter. 
-- Data for this table will be stored in tablespaces created  above ('Tbspace1'
-- ,'Tbspace2','Tbspace3','Tbspace4'). Long data will be stored in large 
-- tablespaces created above ('Ltbspace1', 'Ltbspace2', 'Ltbspace3', 'Ltbspace4'). 

CREATE TABLE purchase_orders ( id               INT NOT NULL, 
                               status           VARCHAR(10), 
                               orderDate        DATE, 
                               customerID       INT, 
                               pOrder           XML)
   PARTITION BY RANGE (orderDate)
   (STARTING FROM '2009-01-01' ENDING '2009-03-31' IN Tbspace1 LONG IN Ltbspace1,
                               ENDING '2009-06-30' IN Tbspace2 LONG IN Ltbspace2, 
                               ENDING '2009-09-30' IN Tbspace3 LONG IN Ltbspace3, 
 	                       ENDING '2009-12-31' IN Tbspace4 LONG IN Ltbspace4)@


-- Create a temporary table (DGTT) to store the intermediate information about 
-- the orders placed by the customer in a transaction.

DECLARE GLOBAL TEMPORARY TABLE pOrderInter(id           INT,
                                           orderDate    DATE,
                                           customerID   INT,
                                           prodID       INT,
                                           partPOrder   XML) 
   ON COMMIT DELETE ROWS IN temp_tbsp@


-- Create an index on the items purchased by the customer. This will help 
-- retrieve details about the purchase order faster.

CREATE INDEX SESSION.nIndex ON SESSION.pOrderInter(partPOrder)
   GENERATE KEY USING XMLPATTERN '/Book/name' AS SQL VARCHAR(60)@


-- A customer makes an online transaction, were he places order for three 
-- books, by adding the three books to the cart. The details about these 
-- books added to the cart are inserted into the temporary table 
-- 'pOrderInter'. Customer updates the quantity of the magazine 'The week' 
-- which he had already added to the cart and decides to remove a book 
-- 'Crisis' from the cart. The update and delete from the cart by the 
-- customer is reflected in the DGTT. 
-- These CRUD operations are placed in a ATOMIC block. ATOMIC block ensures 
-- that, if an error occurs in the compound statement, all SQL statements 
-- in the compound statement will be rolled back, and any SQL statements 
-- in the compound statement are not processed.

UPDATE COMMAND OPTIONS USING c OFF@

BEGIN ATOMIC 

   INSERT INTO SESSION.pOrderInter VALUES (3000,'2009-01-10',1900,100,
      '<Book>
          <partid>100</partid>
          <name>DB2 understanding security</name>
          <quantity>1</quantity>
          <price>49.99</price>
       </Book>');

   INSERT INTO SESSION.pOrderInter VALUES (3000,'2009-01-10',1900,2002,
       '<Book>
          <partid>2002</partid>
          <name>Crisis</name>
          <quantity>1</quantity>
          <price>9.99</price>
       </Book>');

   INSERT INTO SESSION.pOrderInter VALUES (3000,'2009-01-10',1900,1001,
       '<Book>
          <partid>1001</partid>
          <name>The week</name>
          <quantity>3</quantity>
          <price>2.99</price>
       </Book>');

   UPDATE SESSION.pOrderInter SET partPOrder = 
	xmlquery('transform 
		  copy $po := $order 
		  modify do replace value of $po/Book/quantity with "4"
                  return $po' 
       PASSING partPOrder AS "order") WHERE 
	XMLEXISTS ('$p/Book[partid=100]' PASSING partPOrder AS "p");

   DELETE FROM SESSION.pOrderInter 
      WHERE XMLEXISTS ('$p/Book[partid=2002]' PASSING partPOrder AS "p");

END@


-- Once the transaction is complete, the products added to the cart by the 
-- customer as in the temporary table 'pOrderInter' are collected and single 
-- XML document is inserted into 'purchase_orders' for the transaction.

SELECT * FROM SESSION.pOrderInter ORDER BY prodID@

INSERT INTO purchase_orders 
  (SELECT p.id, 'Unshipped', p.orderDate, p.customerID,
          XMLDOCUMENT( XMLElement(NAME "PurchaseOrder", 
            XMLAgg( XMLElement(NAME "Books",p.partPOrder OPTION NULL ON NULL) ORDER BY p.prodID) 
          OPTION NULL ON NULL)) 
     FROM SESSION.pOrderInter AS p  
   GROUP BY p.id, p.customerID, p.orderDate)@

COMMIT@

UPDATE COMMAND OPTIONS USING c ON@


-- At the end of the day, the store delivers the purchase orders whose 
-- status='Unshipped' from the 'purchase_orders' table. 
-- Once the store delivers these purchase orders, the status is set 
-- to 'Shipped'

SELECT * FROM purchase_orders 
  WHERE status = 'Unshipped'@

UPDATE purchase_orders SET status = 'Shipped' 
  WHERE status = 'Unshipped'@


-- Clean-Up Script
DROP TABLE purchase_orders@

-- DROP TABLESPACE command fails since 'SESSION.pOrderInter@' still exists.
DROP TABLESPACE temp_tbsp@

DROP TABLESPACE Tbspace1@
DROP TABLESPACE Tbspace2@
DROP TABLESPACE Tbspace3@
DROP TABLESPACE Tbspace4@
DROP TABLESPACE Ltbspace1@
DROP TABLESPACE Ltbspace2@
DROP TABLESPACE Ltbspace3@
DROP TABLESPACE Ltbspace4@

DROP BUFFERPOOL common_Buffer@

-- Close connection to the sample database
CONNECT RESET@

-- Connect to sample database
CONNECT TO sample@

-- SELECT command fails since closing the connection drops all 
-- temporary database objects.
SELECT * FROM SESSION.pOrderInter@

-- DROP TABLESPACE command succeeds since closing the connection drops all 
-- temporary database objects.
DROP TABLESPACE temp_tbsp@

-- Close connection to the sample database
CONNECT RESET@






