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
-- SOURCE FILE NAME: sqlxquery.db2
--
-- SAMPLE: SQL/XML Queries 
--
-- SQL/XML FUNCTIONS USED
--          sqlquery
--          xmlexists
--          xmlquery 
--
-- SQL STATEMETNS USED
--          SELECT 
--
-- SAMPLE EXECUTION:
-- Run the samples with following command
--    db2 -td@ -vf sqlxquery.db2
--
-- OUTPUT FILE: xpath.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using XQUERY statements, see the XQUERY Reference.
--
-- For information on using SQL statements, see the SQL Reference.

-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Connect to sample database
CONNECT TO SAMPLE@

-- Find out first purchaseorders of the customer with name Robert Shoemaker 
SELECT XMLQUERY('$p/PurchaseOrder/item[1]' PASSING p.porder AS "p") 
     FROM purchaseorder AS p, customer AS c
     WHERE XMLEXISTS('$custinfo/customerinfo[name="Robert Shoemaker" and @Cid = $cid]'  
                     PASSING c.info AS "custinfo", p.custid AS "cid")@
 
-- Return the first item in the purchaseorder and the history of all the customer 
-- when the following conditions are met
-- 1. Customer ID in the sequence (1000,1002,1003) or
-- 2. Name is sequece (X,Y,Z)
SELECT XMLQUERY('$p/PurchaseOrder/item[1]' passing p.porder as "p"),XMLQUERY('$x/history' passing c.history as "x") 
       FROM purchaseorder as p,customer as c  
       WHERE XMLEXISTS('$custinfo/customerinfo[name=(X,Y,Z) or @Cid=(1000,1002,1003) and @Cid=$cid ]'
                        PASSING c.info AS "custinfo", p.custid AS "cid")@

-- Find out all the customer names and sort them according to number of orders
WITH count_table AS ( SELECT count(poid) AS c,custid 
                FROM purchaseorder,customer 
                WHERE cid=custid GROUP BY custid ) 
     SELECT c,custid, XMLQUERY('$s/customerinfo[@Cid=$id]/name' 
                                PASSING customer.info AS "s", count_table.custid AS "id") 
     FROM customer,count_table 
     WHERE custid=cid ORDER BY custid@

-- Find out the number of purchaseorder having item with partid 100-101-01 for customer Robert Shoemaker 
WITH cid_table AS (SELECT Cid FROM customer 
                   WHERE XMLEXISTS('$custinfo/customerinfo[name="Robert Shoemaker"]' PASSING customer.info AS "custinfo")) 
     SELECT count(poid) FROM purchaseorder,cid_table 
     WHERE XMLEXISTS('$po/itemlist/item[partid="100-101-01"]' PASSING purchaseorder.porder AS "po") 
                 AND purchaseorder.custid=cid_table.cid@ 

-- Reset the connection
CONNECT RESET@


