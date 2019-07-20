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
-- SAMPLE FILE NAME: xmlxslt.db2
--
-- PURPOSE: The purpose of this sample is to show:
--     1. Using the XSLTRANSFORM function to convert one XML document to 
--        another using an XSLT stylesheet.
--     2. Passing an XSL parameter document to the XSLTRANSFORM function  
--        at runtime.
--         
-- USAGE SCENARIO: A supermarket manager maintains a webpage to show 
--                 the details of the products available in his shop. 
--                 He maintains two tables, namely "product_details" 
--                 and "display_productdetails". 
--                 The "product_details" table contains information about 
--                 all of the products available in his shop, where the 
--                 details for each product are in an XML document format. 
--                 The "display_productdetails" table contains the XSLT 
--                 stylesheet, which specifies how to display the product 
--                 details on the webpage.
--                
-- PREREQUISITE: The SAMPLE database should exist before running this sample.
--
-- EXECUTION: db2 -tvf xmlxslt.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: Displays new XML documents that result from XSLT conversion.
--
-- OUTPUT FILE: xmlxslt.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TABLE
--           INSERT
--           DROP
--
-- SQL/XML FUNCTIONS USED:
--          XSLTRANSFORM
--
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
--
--  SAMPLE DESCRIPTION
--
-----------------------------------------------------------------------------
-- 1. Using the XSLTRANSFORM function to convert one XML document to another
--    using an XSLT stylesheet.
--      1.1 Insert an XML document into the "product_details" table.
--      1.2 Insert an XSL stylesheet into the "display_productdetails" table.
--      1.3 Display the new XML document after transforming the XML document 
--          in the "product_details" table using the XSL stylesheet.
--
-- 2. Passing an XSL parameter document to the XSLTRANSFORM function  
--    at runtime.
--     2.1 Insert a parameter document into the "param_tab" table.
--     2.2 Display the new XML document after transforming the XML document 
--         in the "product_details" table using the XSL stylesheet with  
--         the parameter document.
--
-----------------------------------------------------------------------------
--
--   SETUP
--
-----------------------------------------------------------------------------

-- Connect to the sample database
CONNECT TO SAMPLE;
 
-----------------------------------------------------------------------------
-- 1. Using the XSLTRANSFORM function to convert one XML document to another
--    using an XSLT stylesheet.
-----------------------------------------------------------------------------
-- Create the table "product_details"
CREATE TABLE product_details (productid INTEGER, description XML);

-- Create table "display_productdetails"
CREATE TABLE display_productdetails (productid INTEGER, stylesheet CLOB (10M));

------------------------------------------------------------------------------
--      1.1 Insert an XML document into the "product_details" table.
------------------------------------------------------------------------------

-- Insert an XML document into the "product_details" table
INSERT INTO product_details 
VALUES (1, '<?xml version="1.0"?>
       <products xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <product pid="100-201-01">
           <description>
             <name>Ice Scraper, Windshield 4 inch</name>
             <details>Basic Ice Scraper 4 inches wide, foam handle</details>
             <price>3.99</price>
           </description>
           <supermarketname> BIG BAZAR </supermarketname>
         </product>
       </products>');

------------------------------------------------------------------------------
--      1.2 Insert an XSL stylesheet into the "display_productdetails" table.
------------------------------------------------------------------------------

-- Insert values into the "display_productdetails" table
INSERT INTO display_productdetails 
VALUES(1,'<?xml version="1.0" encoding="UTF-8"?><xsl:stylesheet version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:param name="headline"/>
   <xsl:param name="supermarketname"/>
   <xsl:template match="products">
   <html>
   <head/>
     <body>
        <h1><xsl:value-of select="$headline"/></h1>
        <table border="1">
     <th>
       	<tr>
            <td width="80">product ID</td>
            <td width="200">product name</td>
            <td width="200">price</td>
            <td width="50">details</td>
            <xsl:choose>
               <xsl:when test="$supermarketname =''true'' ">
                                 <td width="200">supermarket name</td>
               </xsl:when>
            </xsl:choose>
         </tr>
      </th>
      <xsl:apply-templates/>
      </table>
     </body>
    </html>
    </xsl:template>
    <xsl:template match="product">
    <tr>
       <td><xsl:value-of select="@pid"/></td>
       <td><xsl:value-of select="/products/product/description/name"/></td>
       <td><xsl:value-of select="/products/product/description/price"/></td>
       <td><xsl:value-of select="/products/product/description/details"/></td>
       <xsl:choose>	 
         <xsl:when test="$supermarketname = ''true'' ">
           <td><xsl:value-of select="/products/product/supermarketname"/></td>
	 </xsl:when>
       </xsl:choose>	
     </tr>
     </xsl:template>
  </xsl:stylesheet>'
);

----------------------------------------------------------------------------
--      1.3 Display the new XML document after transforming the XML document
--          in the "product_details" table using the XSL stylesheet.
----------------------------------------------------------------------------

-- Display the final document
SELECT XSLTRANSFORM (description USING stylesheet AS CLOB (10M)) 
FROM product_details X, display_productdetails D 
WHERE X.productid = D.productid;

----------------------------------------------------------------------------
-- 2. Passing an XSL parameter document to the XSLTRANSFORM function
--    at runtime.
--     
-----------------------------------------------------------------------------

-- Create the table "param_tab"
CREATE TABLE param_tab (productid INTEGER, param VARCHAR (1000));


-----------------------------------------------------------------------------
--     2.1 Insert parameter document into the table "param_tab".
-----------------------------------------------------------------------------

-- Insert parameter values into the "param_tab" table
INSERT INTO param_tab 
VALUES (1, '<?xml version="1.0"?>
   <params xmlns="http://www.ibm.com/XSLTransformParameters">
     <param name="supermarketname" value="true"/>
     <param name="headline">BIG BAZAR super market</param>
   </params>');

-----------------------------------------------------------------------------
--     2.2 Display the new XML document after transforming the XML document
--         in the "product_details" table using the XSL stylesheet with
--         the parameter document.
-----------------------------------------------------------------------------

-- Display the final document
SELECT XSLTRANSFORM (description USING stylesheet WITH param AS CLOB (1M)) 
FROM product_details X, param_tab P, display_productdetails D 
WHERE X.productid=P.productid AND X.productid = D.productid;

----------------------------------------------------------------------------
--
--               CLEANUP
--
----------------------------------------------------------------------------
-- Drop all of the tables
DROP TABLE param_tab;
DROP TABLE product_details;
DROP TABLE display_productdetails;
