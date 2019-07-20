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
--  SAMPLE FILE NAME: xsupdate.db2                                          
--                                                                          
--  PURPOSE:  To demonstrate how to update an existing XML schema with
--            a new schema that is compatible with the original schema
--                                                                          
--  USAGE SCENARIO: A store manager maintains product details in an XML     
--                  document that conforms to an XML schema. The product     
--                  details are: Name, SKU and Price. The store manager      
--                  wants to add a product description for each of the         
--                  products, along with the existing product details.                     
--                                                                          
--  PREREQUISITE: The original schema and the new schema should be     
--                present in the same directory as the sample.             
--                Copy prod.xsd, newprod.xsd from directory 
--                <install_path>/xml/data to the working directory.                           
--                                                                          
--  EXECUTION:    db2 -tvf xsupdate.db2   
--                                                                          
--  INPUTS:       NONE
--                                                                          
--  OUTPUTS:      Updated schema and successful insertion of XML documents 
--                with the new product descriptions.                                              
--                                                                          
--  OUTPUT FILE:  xsupdate.out (available in the online documentation)      
--                                     
--  SQL STATEMENTS USED:                                                    
--        REGISTER XMLSCHEMA                                                  
--        COMPLETE XMLSCHEMA                                                
--        INSERT
--        CREATE   
--        DROP                                          
--                                                                          
--  SQL PROCEDURES USED:                                                    
--        XSR_UPDATE                                                        
--                                                                          
--  SQL/XML FUNCTIONS USED:                                                  
--        XMLVALIDATE                                                       
--        XMLPARSE 
--  
-- *************************************************************************
-- For more information about the command line processor (CLP) scripts,     
-- see the README file.                                                     
-- For information on using SQL statements, see the SQL Reference.          
--                                                                          
-- For the latest information on programming, building, and running DB2     
-- applications, visit the DB2 application development website:             
-- http://www.software.ibm.com/data/db2/udb/ad                              
-- *************************************************************************
--
--  SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
--  1. Register the original schema with product details:Name, SKU and Price.
--  2. Register the new schema containing the product description element 
--     along with the existing product details.
--  3. Call the XSR_UPDATE stored procedure to update the original schema.                                                                 
--  4. Insert an XML document containing the product description elements.
-- *************************************************************************/

-- /*************************************************************************
--    SETUP                                                                 
-- **************************************************************************/

-- connect to the database
CONNECT TO sample;

-- create a relational schema 
CREATE SCHEMA store;
                     
-- /*************************************************************************
-- 1. Register the original schema with product details: Name, SKU and Price.
-- *************************************************************************/

-- register the original XML schema from prod.xsd
REGISTER XMLSCHEMA http://product FROM prod.xsd AS store.prod;
COMPLETE XMLSCHEMA store.prod;

-- table for storing products in XML document
-- created with check constraint so that the XML data is validated 
-- against the STORE.PROD schema
CREATE TABLE store.products(id INT GENERATED ALWAYS AS IDENTITY,plist XML CONSTRAINT ck 
               CHECK(plist IS VALIDATED ACCORDING TO XMLSCHEMA ID store.prod));

-- insert product details into table validating according to the schema store.prod
INSERT INTO store.products(plist) VALUES(XMLVALIDATE( XMLPARSE(
                             DOCUMENT '<products>
                                          <product color="green" weight="20">
                                               <name>Ice Scraper, Windshield 4 inch</name>
                                               <sku>stores</sku>
                                               <price>999</price>
                                          </product>
                                          <product color="blue" weight="40">
                                               <name>Ice Scraper, Windshield 8 inch</name>
                                               <sku>stores</sku>
                                               <price>1999</price>
                                          </product>
                                          <product color="green" weight="26">
                                               <name>Ice Scraper, Windshield 5 inch</name>
                                               <sku>stores</sku>
                                               <price>1299</price>
                                          </product>
                                      </products>')
                              ACCORDING TO XMLSCHEMA ID store.prod));

-- check the inserted data
SELECT * FROM store.products;

-- /**************************************************************************
--  2. Register the new schema containing the product description element 
--     along with the existing product details.                                            
-- **************************************************************************/

-- register the new schema with the product description element
REGISTER XMLSCHEMA http://newproduct FROM newprod.xsd AS store.newprod;
COMPLETE XMLSCHEMA store.newprod;

-- /*************************************************************************
--  3. Call the XSR_UPDATE stored procedure to update the original schema.
-- **************************************************************************/

-- update the original schema to reflect the changes in the new schema.
-- this stored procedure will update the original schema with the new schema
-- if the new schema is compatible with the original one.
-- the last parameter is set to a non zero value to drop the schema used to 
-- update the original schema, if it is set to zero then the new schema will
-- continue to reside in XSR. 
CALL  SYSPROC.XSR_UPDATE('STORE','PROD','STORE','NEWPROD', 1);

-- /*************************************************************************
--  4. Insert an XML document containing the product description elements.
-- **************************************************************************/

-- insert the product details along with their descriptions into the table, 
-- validating against the updated schema STORE.PROD
INSERT INTO store.products(plist) VALUES(XMLVALIDATE( XMLPARSE(
                             DOCUMENT '<products>
                                          <product color="green" weight="20">
                                               <name>Ice Scraper, Windshield 4 inch</name>
                                               <sku>stores</sku>
                                               <price>999</price>
                                               <description>A new prod</description>
                                          </product>
                                          <product color="blue" weight="40">
                                               <name>Ice Scraper, Windshield 8 inch</name>
                                               <sku>stores</sku>
                                               <price>1999</price>
                                               <description>A new prod</description>
                                          </product>
                                          <product color="green" weight="26">
                                               <name>Ice Scraper, Windshield 5 inch</name>
                                               <sku>stores</sku>
                                               <price>1299</price>
                                          </product>
                                      </products>')
                              ACCORDING TO XMLSCHEMA ID store.prod));

-- check the inserted data
SELECT * FROM store.products ORDER BY id;

-- /*************************************************************************
--  CLEANUP                                                                 
-- *************************************************************************/

-- delete the objects created
DROP XSROBJECT store.prod;
DROP TABLE store.products;
DROP SCHEMA store RESTRICT;

CONNECT RESET;
