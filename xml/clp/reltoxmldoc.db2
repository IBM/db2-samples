----------------------------------------------------------------------------
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
-- SOURCE FILE NAME: reltoxmldoc.db2
--
-- SAMPLE: Purchase order database uses relational tables to store the orders of
--         different customers. This data can be returned as an XML object to the
--         application. The XML object can be created using the XML constructor
--         functions on the server side.
--         To achieve this, the user can
--           1. Create a stored procedure to implement the logic to create the XML 
--              object using XML constructor functions.
--           2. Register the above stored procedure to the database.
--           3. Call the procedure whenever all the PO data is needed instead of using complex joins.
--
-- PREREQUISITE:
--         The relational tables that store the purchase order data will have to
--         be created before this sample is executed. For this the file
--         setupscript.db2 will have to be run using the command
--            db2 -tvf setupscript.db2
--         The stored procedure will have to be registered before this sample is executed.
--         The command to register the stored procedure is
--            db2 -td@ -f reltoxmlproc.db2
--
-- SQL STATEMENT USED:
--         SELECT
--         CALL
--         CONNECT RESET
--
-- OUTPUT FILE: reltoxmldoc.out (available in the online documentation)
-----------------------------------------------------------------------------

-- CONNECT TO DATABSE
  CONNECT TO sample;

-- Select purchase order data from the relational tables.
  SELECT po.CustID, po.PoNum, po.OrderDate, po.Status, 
         count(l.ProdID) as Items, sum(p.Price) as total,
         po.Comment, c.Name, c.Street, c.City, c.Province, c.PostalCode
     FROM PurchaseOrder_relational as po, CustomerInfo_relational as c, 
          Lineitem_relational as l, Products_relational as p 
     WHERE po.CustID = c.CustID and po.PoNum = l.PoNum and l.ProdID = p.ProdID
     GROUP BY po.PoNum,po.CustID,po.OrderDate,po.Status,c.Name,c.Street,c.City,c.Province,    
              c.PostalCode,po.Comment
     ORDER BY  po.CustID,po.OrderDate;

-- Call the stored procedure. This stored procedure will convert all the relational 
-- purchase order data into an well formed XML document. Thus all the relational data is 
-- stored in the XML document.
  CALL reltoxmlproc();

-- Reset Database connection
  CONNECT RESET;
