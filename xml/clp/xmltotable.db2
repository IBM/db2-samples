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
-- SOURCE FILE NAME:xmltotable.db2
--
-- SAMPLE USAGE SCENARIO:Purchase order XML document contains detailed 	
-- information about all the orders. It will also have the detail of the 
-- customer with each order.  
--
-- PROBLEM: The document has some redundant information as customer info 
-- and product info is repeated in each order for example 
-- Customer info is repeated for each order from same customer. 
-- Product info will be repeated for each order of same product from different customers. 

-- SOLUTION: The sample database has tables with both relational and XML data to remove 
-- this redundant information. These relational tables will be used to store 
-- the customer info and product info in the relational table having XML data 
-- and id value. Purchase order will be stored in another table and it will 
-- reference the customerId and productId to refer the customer and product 
-- info respectively. 

-- To achieve the above goal this sample will shred the data for purchase order XML 
-- document and insert it into the tables. 

-- The sample will follow the following steps 

-- 1. Get the relevant data in XML format from the purchase order XML document (use XMLQuery)
-- 2. Shred the XML doc into the relational table. (Use XMLTable)
-- 3. Select the relevant data from the table and insert into the target relational table. 
 
-- SAMPLE EXECUTION : Run the samples using following command
--                    db2 -td! -vf xmltotable.db2
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         INSERT
--         SELECT
--
-- SQL/XML FUNCTIONS USED:
--         XMLQUERY
--         XMLTABLE

-- OUTPUT FILE: xmltotable.out (available in the online documentation)
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

-- CONNECT TO THE DATABASE
CONNECT TO sample!

-- CREATE A TABLE po
CREATE TABLE po(id INT GENERATED ALWAYS AS IDENTITY,purchaseorder XML)!

-- CREATE THE PROCEDURE
CREATE PROCEDURE PO_shred (IN purchaseorder XML) LANGUAGE SQL
  BEGIN
    DECLARE xmlvar XML;
    DECLARE stmt_text VARCHAR(1024);
    DECLARE at_end SMALLINT DEFAULT 0;
    DECLARE not_found
      CONDITION for SQLSTATE '02000';
    DECLARE stmt STATEMENT;
    DECLARE cur1 CURSOR FOR stmt;
    DECLARE CONTINUE HANDLER for not_found
    SET at_end = 1;

    -- INSERT THE PURCHASEORDER XML DOCUMENT INTO PO TABLE 
    INSERT INTO PO(purchaseorder) VALUES(XMLDOCUMENT(purchaseorder));

    -- SELECT THE PURCHASE ORDERS WITH THE STATUS SHIPPED USING AN XQUERY 
    SET stmt_text= 'XQUERY db2-fn:xmlcolumn("PO.PURCHASEORDER")/PurchaseOrders/PurchaseOrder[@Status="shipped"]';    
    PREPARE stmt FROM stmt_text;
    OPEN cur1;
 
    -- ITERATE THROUGH THE RESULT SET OF THE XQUERY
    fetch_loop:
    LOOP
      FETCH cur1 into xmlvar;
      IF at_end <> 0 THEN LEAVE fetch_loop;
      END IF;
    
      -- XMLTABLE WILL CONVERT THE INDIVIDUAL PURCHASEORDER XML DOCUMENT TO A RELATIONAL TABLE. 
      -- SELECT THE DETAILS FROM THIS TABLE AND INSERT IT INTO CUSTOMER TABLE
      INSERT INTO customer(CID,info,history)
        SELECT T.CustID, XMLDOCUMENT(XMLELEMENT(NAME "customerinfo",XMLATTRIBUTES (T.CustID as "Cid"),
               XMLCONCAT(
                         XMLELEMENT(NAME "name", T.Name ),T.Addr,
                         XMLELEMENT(NAME "phone", XMLATTRIBUTES(T.Type as "type"), T.Phone)
                        ))), xmldocument(T.History) 
        FROM  XMLTABLE( '$d/PurchaseOrder' PASSING XMLDOCUMENT(xmlvar)  AS "d"
                         COLUMNS
                             CustID   BIGINT       PATH '@CustId',
                             Addr     XML          PATH './Address',
                             History  XML          PATH './History',
                             Name     VARCHAR(20)  PATH './name',
                             Country  VARCHAR(20)  PATH './Address/@country',
                             Phone    VARCHAR(20)  PATH './phone',
                             Type     VARCHAR(20)  PATH './phone/@type' 
                       ) as T where T.CustID not in (Select CID from customer);
       INSERT INTO purchaseOrder(poid, orderdate, custid,status, porder, comments)
          SELECT Poid, OrderDate, CustID, Status, xmldocument(XMLELEMENT(NAME "PurchaseOrder", 
                                                  XMLATTRIBUTES(T.Poid as "PoNum", T.OrderDate as "OrderDate",
                                                                T.Status as "Status"), 
                                                  T.itemlist)), Comment 
            FROM XMLTable ('$d/PurchaseOrder' PASSING XMLDOCUMENT(xmlvar)  as "d"
                          COLUMNS
                              Poid      BIGINT      PATH '@PoNum',
                              OrderDate DATE        PATH '@OrderDate',
                              CustID    BIGINT      PATH '@CustId',
                              Status    varchar(10) PATH '@Status',
                              itemlist  XML         PATH './itemlist',
                              Comment varchar(1024) PATH './comments'
                         ) as T;

    END LOOP fetch_loop;
  CLOSE cur1;
END!

-- CALL THE ABOVE STORED PROCEDURE WITH PURCHASEORDER DOCUMENT

CALL PO_shred(XMLPARSE(DOCUMENT('<PurchaseOrders>
                       <PurchaseOrder CustId = "10" PoNum="110" OrderDate="2004-01-29" Status="shipped">
                               <name>Manoj K Sardana</name>
                                 <Address country="India">
                                   <Street>Ring Road</Street>
                                   <city>Bangalore</city>
                                   <province>Karnataka</province>
                                   <postalcode>560071</postalcode>
                                </Address>
                                <phone type="cell">9880471176</phone>
                                 <History></History>
                                <itemlist>
                                        <item>
                                                <partid>100-103-01</partid>
                                                <name>Snow Shovel, Super Deluxe 26"</name>
                                                <quantity>1</quantity>
                                                <price>49.99</price>
                                        </item>
                                </itemlist>
                            <comments></comments>
                           </PurchaseOrder>
                         <PurchaseOrder CustId = "11" PoNum="111" OrderDate="2004-01-29" Status="shipped">
                                <name>Balunaini Prasad</name>
                                   <Address country="India">
                                   <Street>Ring Road</Street>
                                   <city>Bangalore</city>
                                   <province>Karnataka</province>
                                   <postalcode>560071</postalcode>
                                </Address>
                               <phone type="cell">9886362610</phone>
                               <History></History>
                                <itemlist>
                                        <item>
                                                <partid>100-201-01</partid>
                                                <name>Ice Scraper, Windshield 4" Wide</name>
                                                <quantity>1</quantity>
                                                <price>3.99</price>
                                        </item>
                                </itemlist>
                          <comments></comments>
                          </PurchaseOrder>
                  </PurchaseOrders>')))!

-- SELECT FROM THE TABLES TO CHECK THAT DATA IS INSERTED CORRECTLY
SELECT POID, XMLSERIALIZE(porder as VARCHAR(1028))  FROM PURCHASEORDER ORDER BY POID!
SELECT CID, XMLSERIALIZE(info as VARCHAR(1028)) FROM CUSTOMER ORDER BY CID!

-- DELETE THE ROWS FROM PURCHASEORDER
DELETE FROM PURCHASEORDER WHERE POID IN (110,111)!
DELETE FROM CUSTOMER WHERE CID IN (10,11)! 

-- DROP THE TABLE PO
DROP TABLE po!

-- DROP THE PROCEDURE
DROP PROCEDURE PO_shred!

-- RESET THE CONNECTION
CONNECT RESET!
