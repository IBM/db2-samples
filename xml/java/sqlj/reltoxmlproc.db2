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
-- SOURCE FILE NAME: reltoxmlproc.db2
--
-- SAMPLE:  This stored procedure uses the constructor functions to create an XML 
--          document with all the purchase order details. The input to the constructor 
--          function will be the relational data stored in the tables. The final 
--          output of the constructor functions will be a well formed XML document having 
--          all the purchase orders. The stored procedure will return the purchase order 
--          XML document back to the application.
--          
--          This stored procedure will be called by samples 
--		a)reltoxmldoc.db2
--       	b)reltoxmldoc.sqc
--	        c)RelToXmlDoc.java
-- 		d)RelToXmlDoc.sqlj
--
-- SQL STATEMENTS USED:
--	   CONNECT
--         CREATE PROCEDURE
--         OPEN
--
-- OUTPUT FILE:  NA
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

CONNECT TO SAMPLE@
CREATE PROCEDURE reltoxmlproc()
RESULT SETS 1
LANGUAGE SQL
BEGIN
DECLARE C1 CURSOR WITH RETURN FOR
SELECT po.PoNum, po.CustID, po.OrderDate, XMLCONCAT( XMLPI(NAME "pi", 'MESSAGE("valid, well-formed document")'),
XMLELEMENT (NAME "PurchaseOrder", XMLNAMESPACES( 'http://www.example.org' AS "e"),
XMLATTRIBUTES (po.CustID as "CustID", po.PoNum as "PoNum", po.OrderDate as "OrderDate", po.Status as "Status" ),
  XMLELEMENT (NAME "CustomerAddress", XMLCONCAT(
  XMLELEMENT (NAME "e.Name", c.Name ),
  XMLELEMENT (NAME "e.Street", c.Street ),
  XMLELEMENT (NAME "e.City", c.City ),
  XMLELEMENT (NAME "e.Province", c.Province ),
  XMLELEMENT (NAME "e.PostalCode", c.PostalCode ) ) ),
  XMLELEMENT (NAME "ItemList" ,
XMLELEMENT (NAME "Item",
XMLELEMENT (NAME "PartId", l.ProdID ),
XMLELEMENT (NAME "Description", p.Description ),
XMLELEMENT (NAME "Quantity", l.Quantity ),
XMLELEMENT (NAME "Price", p.Price ) ,
XMLCOMMENT(po.comment) ) ) ) )
FROM PurchaseOrder_Relational as Po, CustomerInfo_Relational AS c, Lineitem_Relational AS l, Products_Relational AS p
WHERE po.CustID = c.CustID and po.PoNum = l.PoNum and l.ProdID = p.ProdID
ORDER BY po.PoNum;
OPEN C1;
END@

