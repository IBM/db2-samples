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
-- SOURCE FILE NAME: xquery_xmlproc.db2
--
-- SAMPLE: An application sample developed using SQL stored procedure with
--         XML type parameters and complex XQueries.
-- 
-- SCENARIO:
--         Some of the suppliers have extended the promotional price date for
--         their products. Getting all the customer's Information who purchased
--         these products in the extended period will help the financial department
--         to return the excess amount paid by those customers. The supplier
--         information along with extended date's for the products is provided
--         in an XML document and the client wants to have the information
--         of all the customers who has paid the excess amount by purchasing these
--         products in the extended period.
--
--         This procedure will return an XML document containing customer 
--         information along with the the excess amount paid by them.
--
-- SQL STATEMENTS USED:
--         CREATE PROCEDURE
--         DROP PROCEDURE
--         PREPARE
--         OPEN
--         FETCH
--         INSERT
--         SELECT
--
-- To run this script from the CLP, issue the command 
--                                           "db2 -td@ -vf xquery_xmlproc.db2"
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
CONNECT TO sample@

-- drop the procedure if exists
DROP PROCEDURE Supp_XmlProc@

-- procedure definition
CREATE PROCEDURE Supp_XmlProc(IN inXML XML ,OUT Customers XML)
LANGUAGE SQL
BEGIN

DECLARE SQLCODE INTEGER;
DECLARE data XML;
DECLARE prodid VARCHAR (12);
DECLARE partid VARCHAR (12);
DECLARE oldPromoDate DATE;
DECLARE newPromoDate DATE;
DECLARE originalPrice DECIMAL(30,2);
DECLARE promoPrice DECIMAL(30,2);
DECLARE custid INTEGER;
DECLARE quantity INTEGER;
DECLARE excessamount DECIMAL(30,2);
DECLARE orders XML;
DECLARE stmt_xq1 VARCHAR (1024);
DECLARE stmt_xq2 VARCHAR (1024);
DECLARE stmt_xq3 VARCHAR (1024);
DECLARE stmt_xq4 VARCHAR (1024);
DECLARE stmt1 STATEMENT;
DECLARE stmt2 STATEMENT;
DECLARE stmt3 STATEMENT;
DECLARE stmt4 STATEMENT;
DECLARE cur_xq1 CURSOR FOR stmt1;
DECLARE cur_xq2 CURSOR FOR stmt2;
DECLARE cur_xq3 CURSOR FOR stmt3;
DECLARE cur_xq4 CURSOR FOR stmt4;

-- set the input XML document to an application variable
SET data = inXML;

-- an XQUERY statement to restructure all the PurchaseOrders 
-- into the following form
-- <items>
--    <item OrderDate="YYYY-MM-DD">
--      <custid>XXXX</custid>
--      <partid>XXX-XXX-XX</partid>
--      <quantity>XX</quantity>
--    </item>................<item>...............</item>
--    <item>.................</itemm
-- </items>
-- store the above XML document in an application varible "orders"

SET stmt_xq1= 'XQUERY let $po:=db2-fn:sqlquery("SELECT XMLELEMENT( NAME ""porders"",
               ( XMLCONCAT( XMLELEMENT(NAME ""custid"", p.custid), p.porder) )) 
               FROM PURCHASEORDER as p") return <items> {for $i in $po, $j in 
               $po[custid=$i/custid]/PurchaseOrder[@PoNum=$i/PurchaseOrder/@PoNum]/item 
               return <item>{$i/PurchaseOrder/@OrderDate}{$i/custid}{$j/partid}
               {$j/quantity}</item>}</items>';
PREPARE stmt1 FROM stmt_xq1;
OPEN cur_xq1;
FETCH FROM cur_xq1 INTO orders;
CLOSE cur_xq1;

-- select the oldpromodate, newpromodate, price and promoprice 
-- for the products for which the promodate is extended
-- using input XML document

SET stmt_xq2 = 'SELECT Pid,PromoEnd,Price,PromoPrice,
                       XMLCAST(XMLQUERY(''$info/Suppliers/Supplier/Products/
                       Product[@id=$pid]/ExtendedDate'' passing cast(? as XML) as "info",  
                       pid as "pid") as DATE) FROM product WHERE XMLEXISTS(''for $prod in 
                       $info//Product[@id=$pid] return $prod'' passing by ref cast(? as XML)
                       as "info", pid as "pid")';
PREPARE stmt2 FROM stmt_xq2;
OPEN cur_xq2 USING data,data;
FETCH FROM cur_xq2 INTO prodid,oldPromoDate,originalPrice,promoPrice,newPromoDate;

-- create two temporary tables
CREATE TABLE temp_table1(custid INT,partid VARCHAR(12),excessamount DECIMAL(30,2));
CREATE TABLE temp_table2(cid INT,total DECIMAL(30,2));

-- repeat the above for all products
WHILE (SQLCODE = 0) Do

   -- finding out the toatal quantity of the product purchased by a customer
   -- if that order is made in between oldpromodate and extended promodate.
   -- this query will return the custid, product id and total quantity of
   -- that product purchased in all his orders.

   SET stmt_xq3 = 'WITH temp1 AS (SELECT cid,partid,quantity,orderdate 
                     FROM XMLTABLE(''$od/item'' passing cast(? as XML) as "od" 
                     COLUMNS cid BIGINT path ''./custid'', partid VARCHAR(20) path 
                     ''./partid'', orderdate DATE path ''./@OrderDate'', 
                     quantity BIGINT path ''./quantity'') as temp2 ) SELECT  temp1.cid, 
                     temp1.partid, sum(temp1.quantity) as quantity FROM temp1 WHERE partid=? 
                     and orderdate>? and orderdate<? group by temp1.cid,temp1.partid';
   PREPARE stmt3 FROM stmt_xq3;
   OPEN cur_xq3 USING orders,prodid,oldPromoDate,newPromoDate;
   FETCH FROM cur_xq3 INTO custid,partid,quantity;

   -- repeat the above  to findout all the customers 
   WHILE(SQLCODE = 0) Do

       -- excess amount to be paid to customer for that product
       SET excessamount = (originalPrice - promoPrice)*quantity;

       -- store these results in a temporary table 
       INSERT INTO temp_table1 values(custid,partid,excessamount);

       -- fetching the next result from cursor
       FETCH FROM cur_xq3 INTO custid,partid,quantity;
   END WHILE;

   -- close the cursor cur_xq3
   CLOSE cur_xq3;

   -- fetching the next result from cursor
   FETCH FROM cur_xq2 INTO prodid,oldPromoDate,originalPrice,promoPrice;
END WHILE;

-- close the cursor cur_xq2
CLOSE cur_xq2;

-- findout total excess amount to be paid to a customer for all the products
-- store those results in another temporary table
INSERT INTO temp_table2( SELECT custid, sum(excessamount) FROM temp_table1 GROUP BY custid);

-- format the results into an XML document of the following form
-- <Customers>
--   <Customer>
--      <Custid>XXXX</Custid>
--      <Total>XXXX.XXXX</Total>
--      <customerinfo Cid="xxxx">
--              <name>xxxx xxx</name>
--              <addr country="xxx>........
--              </addr> 
--              <phone type="xxxx">.........
--              </phone>
--      </customerinfo>
--   </Customer>............
-- </Customers>  

SET stmt_xq4='XQUERY let $res:=db2-fn:sqlquery("SELECT XMLELEMENT( NAME ""Customer"",( XMLCONCAT(XMLELEMENT(NAME ""Custid"", t.cid),XMLELEMENT(NAME ""Total"", t.total),c.info))) FROM temp_table2 AS t,customer AS c WHERE t.cid = c.cid") return <Customers>{$res}</Customers>';

PREPARE stmt4 FROM stmt_xq4;
OPEN cur_xq4;
FETCH FROM cur_xq4 INTO Customers;

-- close the cursor cur_xq4
CLOSE cur_xq4;

-- drop the temporary tables created
DROP TABLE temp_table1;
DROP TABLE temp_table2;

-- end of the procedure
END@

-- calling the procedure with necessary options
CALL Supp_XmlProc(xmlparse(document '
<Suppliers>
    <Supplier id="100">
        <Products>
           <Product id="100-100-01">
             <ExtendedDate>2007-01-02</ExtendedDate>
           </Product>
           <Product id="100-101-01">
             <ExtendedDate>2007-05-02</ExtendedDate>
           </Product>
         </Products>
    </Supplier>
    <Supplier id="101">
        <Products>
           <Product id="100-103-01">
             <ExtendedDate>2007-08-22</ExtendedDate>
           </Product>
        </Products>
    </Supplier>
</Suppliers>
'),?)@

-- rollback the work to keep database consistent
ROLLBACK@

CONNECT RESET@

