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
-- SOURCE FILE NAME: xpath.db2
--
-- SAMPLE: Simple XPath Queries 
--
-- SQL/XML FUNCTIONS USED
--          xmlcolumn
--          sqlquery
-- NOTE : Both the above functions are case sensitive.
--
-- XQUERY FUNCTIONS USED
--          count
--          avg
--          start-with
--          distinct-values
-- NOTE : All the xquery functions are case  sensitive

-- SAMPLE EXECUTION:
-- Run the samples with following command
--    db2 -td@ -vf xpath.db2
--
-- OUTPUT FILE: xpath.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using XQUERY statements, see the XQUERY Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Connect to sample database
CONNECT TO SAMPLE@

-- Find out the information of all the customer
-- Both the queries below will give the same result
XQUERY for $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo
       order by xs:double($cust/@Cid)
       return $cust@

XQUERY db2-fn:sqlquery("select info from customer order by cid")@ 

-- Find out the customers information from Toronto city
-- Both the queries below will give the same result 

XQUERY for $nme in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[addr/city="Toronto"]/name
       order by $nme
       return $nme@

XQUERY for $nme in db2-fn:xmlcolumn('CUSTOMER.INFO')//city[text()="Toronto"]/../../name
       order by $nme
       return $nme@

-- Find out all the customer cities from country Canada

XQUERY for $cty in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo/addr[@country="Canada"]/city)
       order by $cty
       return $cty@

-- Find out number of customer in Toronto city
XQUERY fn:count(db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[addr/city="Toronto"])@

-- Find out all the customer names whose mobile number starts with 905
XQUERY db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[phone[@type="cell" and fn:starts-with(text(),"905")]]@

-- Find out the average price for all the products in 100 series
XQUERY let $prod_price := db2-fn:xmlcolumn('PRODUCT.DESCRIPTION')/product[fn:starts-with(@pid,"100")]/description/price
       return avg($prod_price)@
 
-- Reset the connection
CONNECT RESET@
