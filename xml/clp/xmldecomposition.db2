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
-- SAMPLE FILE NAME: xmldecomposition.db2                                          
--
-- PURPOSE: To demonstrate annotated XML schema decomposition  
--
-- USER SCENARIO:
--	       A bookstore has books for sale and the descriptive information about
--         each book is stored as an XML document. The store owner needs to store 
--         these details in different relational tables with referential 
--         constraints for easy retreival of data.
--         The Bookstore that has two types of customers, retail customers and
--         corporate customers. Corporate customers do bulk purchases of books
--         for their company libraries. The store has a DBA for maintaining 
--         the database, the store manager runs queries on different tables 
--         to view the book sales. The information about books returned by 
--         customers due to damage or due to exchange with some other book
--         is stored as xml document in books_returned table. At the end of 
--         the day a batch process decomposes these XML documents to update 
--         the books available status with the latest information. The batch 
--         process uses the DECOMPOSE XML DOCUMENTS command to decompose 
--         binary or XML column data into relational tables. 
--
-- SOLUTION:
--         The store manager must have an annotated schema based on which the XML data 
--         can be decomposed. Once a valid annotated schema for the instance document  
--         is ready, it needs to be registered with the XML schema repository with 
--         the decomposition option enabled. Also, the tables in which the data will be 
--         decomposed must exist before the schema is registered. The user can 
--         decompose the instance documents and store the data in the relational 
--         tables using annotated XML Decomposition.
--
--    
--  PREREQUISITE:
--        The instance documents and the annotated schema must exist in the same 
--        directory as the sample.
--        Copy bookdetails.xsd, booksreturned.xsd, bookdetails.xml,
--        booksreturned.del, booksreturned1.xml, booksreturned2.xml, booksreturned3.xml,
--        setupfordecomposition.db2 and cleanupfordecomposition.db2 from directory 
--        <install_path>/sqllib/samples/xml/data in UNIX and
--        <install_path>\sqllib\samples\xml\data in Windows to the working directory. 
--                                                                          
--  EXECUTION:    i)   db2 -tvf setupfordecomposition.db2 (setup script 
--                     to create the required tables and populate them)
--                ii)  db2 -tvf xmldecomposition.db2 (execute the sample)
--                iii) db2 -tvf cleanupfordecomposition.db2 (clean up 
--                     script to drop all the objects created)
--                                                                          
--  INPUTS:       NONE
--                                                                          
--  OUTPUTS:      Decomposition of XML documents according to the dependencies 
--                specified in the annotated XML schema.
--                                                                          
--  OUTPUT FILE:  xmldecomposition.out (available in the online documentation)      
--                                     
--  SQL STATEMENTS USED:                                                    
--        REGISTER XMLSCHEMA                                                  
--        COMPLETE XMLSCHEMA      
--        DECOMPOSE XML DOCUMENT
--        DECOMPOSE XML DOCUMENTS IN                                        
--        CREATE   
--        SELECT 
--        DROP                                          
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
-- 1. Register the annotated XML schemas.
-- 2. Decompose a single XML document using the registered XML schema.
-- 3. Decompose XML documents using the registered XML schema from
--    3.1. An XML column.
--    3.2. A BLOB column. 
-- 4. Decompose XML documents from an XML column resulted by
--    4.1. Join operation 
--    4.2. Union operation
-- *************************************************************************/

-- /*************************************************************************
--    SETUP -- execute setupfordecomposition.db2       
-- **************************************************************************/

-- setupfordecomposition.db2 will create required tables and populate them.

-- Connect to the SAMPLE database 
CONNECT TO sample;

-- /*************************************************************************
-- 1. Register the annotated XML schemas.
-- *************************************************************************/

-- Register the XML schemas containing annotations  
REGISTER XMLSCHEMA 'http://book.com/bookdetails.xsd' 
                   FROM 'bookdetails.xsd' AS xdb.bookdetails;
REGISTER XMLSCHEMA 'http://book.com/booksreturned.xsd' 
                   FROM 'booksreturned.xsd' AS xdb.booksreturned;

-- Complete XML schema registration
COMPLETE XMLSCHEMA xdb.bookdetails ENABLE DECOMPOSITION;
COMPLETE XMLSCHEMA xdb.booksreturned ENABLE DECOMPOSITION;

-- Check catalog tables for information regarding the newly registered schemas.
SELECT status, decomposition, decomposition_version 
                       FROM SYSIBM.SYSXSROBJECTS 
                       where XSROBJECTNAME IN ('BOOKDETAILS', 'BOOKSRETURNED');

-- /*************************************************************************
-- 2. Decompose a single XML document using the registered XML schema.
-- *************************************************************************/

-- Decompose a single XML document
DECOMPOSE XML DOCUMENT bookdetails.xml
              XMLSCHEMA xdb.bookdetails
	      VALIDATE;	

-- check the results of the decomposition
SELECT * FROM admin.book_author WHERE authid=532;
SELECT * FROM xdb.books_avail;
SELECT isbn,chptnum,SUBSTR(chpttitle,1,15),SUBSTR(chptcontent,1,25) FROM xdb.book_contents;

-- cleanup the data from relational tables to see
-- decomposed data.
DELETE FROM xdb.books_avail;

-- /*************************************************************************
-- 3.1. Decompose XML documents from an XML column. 
-- *************************************************************************/

-- Decompose XML documents 
DECOMPOSE XML DOCUMENTS IN 
          SELECT  customerID, booksreturned FROM xdb.books_returned
          XMLSCHEMA xdb.booksreturned VALIDATE
          MESSAGES errorreport.xml;

-- check the results of the decomposition
SELECT * FROM xdb.books_avail;

-- cleanup the data from relational tables to see
-- decomposed data.
DELETE FROM xdb.books_avail;

-- /*************************************************************************
-- 3.2. Decompose XML documents from a BLOB column. 
-- *************************************************************************/

-- Decompose XML documents
DECOMPOSE XML DOCUMENTS IN 
          SELECT supplierID, booksinfo from xdb.books_received_BLOB
          XMLSCHEMA xdb.booksreturned VALIDATE
          MESSAGES errorreport.xml;

-- check the results of the decomposition
SELECT * FROM xdb.books_avail;

-- cleanup the data from relational tables to see
-- decomposed data.
DELETE FROM xdb.books_avail;

-- /*************************************************************************
-- 4.1. Decompose XML documents from an XML column resulted by Join operation.
-- *************************************************************************/

DECOMPOSE XML DOCUMENTS IN 
          SELECT id, data FROM(
          SELECT br.customerID as id, br.booksreturned AS info 
          FROM xdb.books_returned as br,xdb.books_received as bc 
          WHERE XMLEXISTS('$bi/books/book[@isbn] = $bid/books/book[@isbn]' 
          PASSING br.booksreturned as "bi", 
          bc.booksinfo as "bid")) AS temp(id,data)
          XMLSCHEMA xdb.booksreturned VALIDATE 
          CONTINUE_ON_ERROR 
          MESSAGES errorreport.xml;

-- check the results of the decomposition
SELECT * FROM xdb.books_avail;

-- cleanup the data from relational tables to see
-- decomposed data.
DELETE FROM xdb.books_avail;

-- /*************************************************************************
-- 4.2. Decompose XML documents from an XML column resulted by Union operation.
-- *************************************************************************/

DECOMPOSE XML DOCUMENTS IN
          SELECT id, data FROM(
          SELECT customerID as cid, booksreturned AS info 
          FROM xdb.books_returned 
          WHERE XMLEXISTS('$bk/books/book[author="Carl"]' 
          PASSING booksreturned AS "bk")
          UNION ALL
          SELECT supplierID as sid, booksinfo AS books 
          FROM xdb.books_received
          WHERE XMLEXISTS('$br/books/book[author="Carl"]' 
          PASSING booksinfo AS "br")) AS temp(id,data)
          XMLSCHEMA xdb.booksreturned VALIDATE
          CONTINUE_ON_ERROR 
          MESSAGES errorreport.xml;

-- check the results of the decomposition
SELECT * FROM xdb.books_avail;

-- cleanup the data from relational tables to see
-- decomposed data.
DELETE FROM xdb.books_avail;

-- /*************************************************************************
--    CLEANUP -- execute cleanupfordecomposition.db2
-- **************************************************************************/

-- Commit the work and reset the connection
COMMIT;
CONNECT RESET;

