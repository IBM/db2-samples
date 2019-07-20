--/*************************************************************************
--   (c) Copyright IBM Corp. 2007 All rights reserved.
--   
--   The following sample of source code ("Sample") is owned by International 
--   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
--   copyrighted and licensed, not sold. You may use, copy, modify, and 
--   distribute the Sample in any form without payment to IBM, for the purpose of 
--   assisting you in the development of your applications.
--   
--   The Sample code is provided to you on an "AS IS" basis, without warranty of 
--   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
--   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
--   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
--   not allow for the exclusion or limitation of implied warranties, so the above 
--   limitations or exclusions may not apply to you. IBM shall not be liable for 
--   any damages you suffer as a result of using, copying, modifying or 
--   distributing the Sample, even if IBM has been advised of the possibility of 
--   such damages.
-- *************************************************************************
--                                                                          
--  SAMPLE FILE NAME: xupdate.db2                                          
--                                                                          
--  PURPOSE:  To demonstrate how to insert, delete, update, replace, and rename 
--            one or more XML documents or document fragments using transform 
--            expressions. 
--                                                                          
--  USAGE SCENARIO: The orders made by customers are stored in the existing 
--                  PurchaseOrder system. A customer has ordered some items initially, 
--                  and now the customer wants to add some more items and remove some 
--                  items from the list. This sample will show how the order is modified 
--                  using the XQuery transform expression and updating expressions.
--                                                                          
--  PREREQUISITE: NONE
--                                                                          
--  EXECUTION:    db2 -tvf xupdate.db2   
--                                                                          
--  INPUTS:       NONE
--                                                                          
--  OUTPUTS:      Successful updation of the purchase orders.
--                                                                          
--  OUTPUT FILE:  xupdate.out (available in the online documentation)      
--                                     
--  SQL STATEMENTS USED: 
--        INSERT
--        UPDATE
--        DROP 
--                                                                          
--  SQL/XML FUNCTIONS USED:                                                  
--        XMLQUERY                                                       
--  
-- *************************************************************************
-- For more information about the command line processor (CLP) scripts,     
-- see the README file.                                                     
-- For information on using SQL statements, see the SQL Reference. 
-- For information about XQuery expressions see the XQuery Reference.       
--                                                                          
-- For the latest information on programming, building, and running DB2     
-- applications, visit the DB2 application development website:             
-- http://www.software.ibm.com/data/db2/udb/ad                              
-- *************************************************************************
--
--  SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
--  1. Insert Expression  -- Insert a new element to the existing XML document/fragment. 
--  2. Delete Expression  -- Delete some elements from the exisitng XML document/fragment.
--  3. Replace value of Expression -- i)  Replace the value of an element 
--                                    ii) Replace the value of attribute
--  4. Replace Expression -- Replace an element and attribute
--  5. Rename Expression  -- i)  Rename an element in the existing XML document/fragment.
--                           ii) Rename an attribute in the existing XML document/fragment.
--  6. Insert and Replace Expressions -- Combination of transform expressions.
-- *************************************************************************/

-- Connect to the database
CONNECT TO sample;

-- Insert an XML document into the purchaseorder table
DELETE FROM purchaseorder WHERE poid=5012;
INSERT INTO PURCHASEORDER(poid, status, porder, orderdate, comments, custid)
         values(5012,'Unshipped',XMLPARSE(DOCUMENT('
                       <PurchaseOrder PoNum="5012" OrderDate="2006-02-18" Status="Unshipped">
                           <item>
                                 <partid>100-100-01</partid>
                                 <name>Snow Shovel, Basic 22 inch</name>
                                 <quantity>3</quantity>
                                 <price>9.99</price>
                           </item>
                          <item>
                                <partid>100-101-01</partid>
                                <name>Snow Shovel, Deluxe 24 inch</name>
                                <quantity>1</quantity>
                                <price>19.99</price>
                          </item>
                          <item>
                                <partid>100-201-01</partid>
                                <name>Ice Scraper, Windshield 4 inch</name>
                                <quantity>5</quantity>
                                <price>3.99</price>
                          </item> </PurchaseOrder> ')), '2006-02-18','THIS IS A NEW PURCHASE ORDER',1002);


                     
-- /*************************************************************************
-- 1. Insert Expression -- Insert a new element to the existing XML document/fragment. 
-- *************************************************************************/

--  add a new item element
SELECT  xmlquery('transform
                   copy $po := $order
                   modify do insert
 document { <item>
     <partid>100-103-01</partid>
     <name>Snow Shovel, Super Deluxe 26 inch</name>
     <quantity>2</quantity>
     <price>49.99</price>
</item>     }
 as last into $po
                      return  $po' passing purchaseorder.porder as "order")
from purchaseorder where poid=5012;


-- Add one item to the XML document and update in the database
UPDATE purchaseorder SET porder =
              xmlquery('transform
                        copy $po := $order
                        modify do insert
 document { <item>
     <partid>100-103-01</partid>
     <name>Snow Shovel, Super Deluxe 26 inch</name>
     <quantity>4</quantity>
     <price>49.99</price>
</item>     }
 into $po/PurchaseOrder return  $po'
      passing purchaseorder.porder as "order") where poid=5012;

-- verify the result
SELECT porder FROM purchaseorder WHERE poid=5012;

-- **************************************************************************
--  2. Delete Expression  -- Delete some items from the exisitng XML document/fragment.
-- **************************************************************************

-- Delete some items basing on a condition
XQUERY transform
       copy $po := db2-fn:sqlquery('select porder from purchaseorder where poid=5012')
       modify do delete $po/PurchaseOrder/item[partid = '100-201-01']
       return  $po;

-- Update the table with deleted items
UPDATE purchaseorder SET porder =
      xmlquery('transform
                copy $po := $order
                modify do delete $po/PurchaseOrder/item[partid = ''100-201-01'']
                return  $po'
                passing porder as "order")
      WHERE poid=5012;

-- Cross verify the result
SELECT porder FROM purchaseorder WHERE poid=5012;

-- **************************************************************************
--  3. Replace value of Expression -- i) Replace the value of an element 
-- **************************************************************************

-- Update element values in an existing document
UPDATE purchaseorder SET porder =
      xmlquery('transform
                copy  $po := $order
                modify
                           for $i in $po/PurchaseOrder/item[1]//price
                           return do replace value of $i  with $i*0.8
                           return  $po'
                passing porder as "order") WHERE poid=5012;

-- Cross verify the result
SELECT porder FROM purchaseorder WHERE poid=5012;

-- **************************************************************************
--  3. Replace value of Expression -- ii) Replace the value of an attribute
-- **************************************************************************

-- Replace the value of an attribute
UPDATE purchaseorder
SET porder =
      xmlquery('transform
                       copy $po := $order
                       modify do replace value of $po/PurchaseOrder/@Status with "Shipped"
                       return $po'
                       passing porder as "order") WHERE poid=5012;

-- Cross verify the result
SELECT porder FROM purchaseorder WHERE poid=5012;

-- **************************************************************************
--  4. Replace Expression -- i) Replace an element and attribute.
-- **************************************************************************

-- Replace an element and attribute
XQUERY for $k in db2-fn:sqlquery("SELECT porder FROM purchaseorder WHERE poid < 5002")
       order by $k//@PoNum
       return transform
              copy $i := $k
              modify (do replace $i//PurchaseOrder/@OrderDate with
                      (
                       attribute BilledDate {"12-12-2007"}
                       ),
                      do replace $i//item[1]/price with $k//item[1]/price
                      )
               return $i//PurchaseOrder;

-- Cross verify the result
SELECT porder FROM purchaseorder WHERE poid < 5002 ORDER BY poid;

-- *************************************************************************
--  5. Rename Expression -- i) Rename an element.
-- *************************************************************************/

-- Rename the elements
UPDATE purchaseorder SET porder =
   xmlquery ('transform
                    copy $po := $order
                    modify
                         for $i in $po//item[quantity > 1]
                       return do rename $i as "items"
                   return  $po' passing porder as "order")
WHERE poid=5012;

-- Cross verify the result
SELECT porder FROM purchaseorder WHERE poid=5012;

-- *************************************************************************
--  5. Rename Expression -- ii) Rename an attribute and element.
-- *************************************************************************/

-- Rename an attribute, Insert a new attribute and rename an element
XQUERY for $k in db2-fn:sqlquery("SELECT porder FROM purchaseorder WHERE poid = 5004")
       return transform
              copy $i := $k
              modify (do rename $i//*:PurchaseOrder/@OrderDate as "BilledDate",
                      do insert attribute Totalcost {"405.99"}
                         into $i//*:PurchaseOrder,
                      do rename $i//*:PurchaseOrder/item[2]/*:partid as "productid"
                      )
               return $i//*:PurchaseOrder;


-- *************************************************************************
--  6. Insert and Replace Expressions -- Combination of updating expressions.
-- *************************************************************************/

-- Insert and Replace Expressions
UPDATE purchaseorder SET porder =
   xmlquery ('transform
                    copy   $po := $order
                   modify
                   ( for $i in $po/PurchaseOrder/item[1]//price
                    return do replace value of $i with $i*0.8,
                    do  insert document {
                                <item>
				     <partid>100-103-01</partid>
				     <name>Snow Shovel, Super Deluxe 26 inch</name>
     				     <quantity>2</quantity>
				     <price>49.99</price>
				</item> }
                        as last into $po/PurchaseOrder
                    )
                  return  $po' passing porder as "order") WHERE poid = 5012;

-- Cross verify the result
SELECT porder FROM purchaseorder WHERE poid=5012;

CONNECT RESET;

TERMINATE;
