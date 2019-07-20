-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2008 All rights reserved.
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
-- SAMPLE FILE NAME: xmlolic.db2
--
-- PURPOSE: This sample demonstrates 
--     1. How to run REORG INDEX with ALLOW WRITE ACCESS on regular   
--        tables with index created on XML column.
-- 
--     2. How to run REORG INDEX with ALLOW WRITE ACCESS on a  
--        non-partitioned index created on an XML column in a 
--        partitioned table.
--         
-- USAGE SCENARIO: The scenario is for a Book Store that has two types 
--    of customers, retail customers and corporate customers. Corporate 
--    customers do bulk purchases of books for their company libraries. 
--    The store has a DBA for maintaining the database, the store
--    manager runs queries on different tables to view the book sales.
--    The store manager complains to the DBA that query performance is  
--    very slow while accessing the data from books_available and 
--    books_supplied tables. 
-- 
--    The DBA decides to improve query performance for the table 
--    "books_available" by creating an index on the XML column 
--    book_details. After many insert, update, and delete operations,  
--    the query performance starts to degrade and the DBA sees that the 
--    index has become fragmented and needs to be reorged. With support of the 
--    ALLOW WRITE ACCESS clause on the REORG INDEX command and REORG INDEXES 
--    command, the DBA reorgs the index online and does not have to worry about 
--    blocking other transactions that need to insert, update or delete from 
--    the table.
--
-- PREREQUISITE: The SAMPLE database should exist before running this script.
--
-- EXECUTION: db2 -tvf xmlolic.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: Successful execution of all the queries
--
-- OUTPUT FILE: xmlolic.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TABLE
--           INSERT INTO
--           UPDATE
--           CREATE INDEX
--           REORG INDEX
--           DROP TABLE
--
-- SQL/XML FUNCTIONS USED:
--           XMLQuery
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-----------------------------------------------------------------------------
--
--  SAMPLE DESCRIPTION
--
-----------------------------------------------------------------------------
-- This sample will demonstrate
-- 1. How to run REORG INDEXES with ALLOW WRITE ACCESS on a regular table 
--    with index created on XML column.
--
-- 2. How to run REORG INDEX with ALLOW WRITE ACCESS on a non-partitioned index
--    created on an XML column in a partitioned table.
-----------------------------------------------------------------------------
--
--   SETUP
--
-----------------------------------------------------------------------------

-- Connect to sample
CONNECT TO SAMPLE;

-----------------------------------------------------------------------------
-- 1. How to run REORG INDEXES with ALLOW WRITE ACCESS on a regular table 
--    with index created on XML column.
-----------------------------------------------------------------------------

-- Create table 'books_available'
CREATE TABLE books_available (docID INTEGER, book_details XML);

-- Insert values into 'books_available' table
INSERT INTO books_available 
  VALUES (10, XMLPARSE(document '<book name="DB2 fundamentals">
                           <author1>
                              <fname>Cool </fname>
                              <lname>Laura</lname>
                           </author1>
                           <price>100</price> 
                           <copies_available>10</copies_available>
                         </book>'  preserve whitespace));


INSERT INTO books_available 
  VALUES(20, XMLPARSE(document '<book name="DB2 DBA">
                           <author1>
                             <fname>Cool</fname>
                             <lname>Chris </lname>
                           </author1>
                           <price>200</price>
                           <copies_available>20</copies_available>
                         </book>'  preserve whitespace));

-- To improve the query performance on the books_available table,
-- the DBA plans to create an XML index. He creates an index on 
-- 'author1' element of 'book_details' XML document.
CREATE INDEX nameix ON books_available(book_details)
          GENERATE KEY USING XMLPATTERN '/book/author1' as SQL VARCHAR(50);

-- Create an index on docID column.
CREATE INDEX docIDix ON books_available(docID);

-- Add a new element 'author2' to 'book_details' document
UPDATE books_available SET book_details = XMLQuery ('copy $bk := $BOOK_DETAILS
                      modify do 
                      insert document {<author2>
                                         <fname>Chris</fname>
                                         <lname>Martin</lname>
                                        </author2>
                                      }                             
                       as last into $bk/book return $bk' ) 
WHERE docID = 20;

-- Replace the value of price element in 'book_details' document 
-- with the reduced price
UPDATE books_available SET book_details = XMLQuery('transform 
                 copy $bk := $BOOK_DETAILS
                 modify 
                 for $pr in $bk/book/price
                 return do replace value of $pr with $pr * 0.8 
                 return $bk') 
WHERE docID = 10;

-- Add a new element 'publisher' to 'book_details' document
UPDATE books_available SET book_details = XMLQuery('copy $bk := $BOOK_DETAILS 
                 modify do 
                 insert <publisher>MDM publishers</publisher>  
                 as last into $bk/book return $bk')
WHERE docID = 10;

-- Replace the value of the 'name' element in the 'book_details' document with 
-- the new name "DB2 9 DBA for LUW"
UPDATE books_available SET book_details = XMLQuery('copy $bk := $BOOK_DETAILS
                 modify 
                 for $name in $bk/book/@name 
                 return do replace value of $name with "DB2 9 DBA for LUW" 
                 return $bk')
WHERE docID = 20;
                 
-- After performing the above insert and update operations the query 
-- performance starts to degrade and the DBA sees that the index has
-- become fragmented and needs to be reorged. The DBA decides to 
-- reorganize the index pages of the table 'books_available' by 
-- running the REORG indexes command.
REORG INDEXES ALL FOR TABLE books_available ALLOW WRITE ACCESS;

----------------------------------------------------------------------
 -- 2. How to run REORG INDEX with ALLOW WRITE ACCESS on a non-partitioned 
 --    index created on an XML column in a partitioned table.
----------------------------------------------------------------------
-- The DBA wants to organize the data pertaining to the book orders in 
-- different partitions of the table based on the supplied date. He creates
-- a partitioned table with supplied_date as the partition key.  
CREATE TABLE supplied_books (docID int, supplied_date date, book_details xml)
 PARTITION BY (supplied_date) 
 (STARTING '01/01/2008' 
 ENDING  '12/31/2009' 
 EVERY 3 MONTHS );

-- To improve the application performance, DBA creates a 
-- non-partitioned index on 'name' attribute of book_details document
CREATE INDEX bname ON supplied_books(book_details)
   GENERATE KEY USING XMLPATTERN '/book/@name' as SQL VARCHAR(50) 
   NOT PARTITIONED;

-- Insert values into "supplied_books" table
INSERT INTO supplied_books VALUES
( 1, '10/01/2008', XMLPARSE(document '<book name="Advanced unix">
                                        <author1>
                                          <fname>Nimar</fname>
                                          <lname>Shindey</lname>
                                        </author1>
                                        <price>90</price>
                                        <copies_available>10</copies_available>
                                      </book>' preserve whitespace));

INSERT INTO supplied_books VALUES
( 2, '12/04/2008', XMLPARSE(document '<book name="Networking">
                                         <author1>
                                            <fname> Cool </fname>
                                            <lname>Chris</lname>
                                         </author1>
                                         <price>100</price>
                                         <copies_available>12</copies_available>
                                      </book>' preserve whitespace));


-- Add a new element 'author2' to 'book_details' document
UPDATE supplied_books SET book_details = XMLQuery ('copy $bk := $BOOK_DETAILS
                      modify do 
                      insert document {<author2>
                                         <fname>Sherry</fname>
                                         <lname>Magor</lname>
                                        </author2>
                                      }                             
                       as last into $bk/book return $bk' ) 
WHERE docID = 1;

-- Replace the value of element 'copies_available' with a new value '25'
UPDATE supplied_books SET book_details = XMLQuery('transform 
                 copy $bk := $BOOK_DETAILS
                 modify 
                 for $cps in $bk/book/copies_available
                 return do replace value of $cps with 25 
                 return $bk') 
WHERE docID = 2;

-- Add a new element 'edition' to 'book_details' document
UPDATE supplied_books SET book_details = XMLQuery('copy $bk := $BOOK_DETAILS 
                 modify do 
                 insert <edition>3rd edition</edition>  
                 as last into $bk/book return $bk')
WHERE docID = 1;

-- Replace the value of 'name' element in 'book_details' document with new 
-- name "Networking on Linux and Windows"
UPDATE supplied_books SET book_details = XMLQuery('copy $bk := $BOOK_DETAILS
                 modify 
                 for $name in $bk/book/@name 
                 return do replace value of $name 
                    with "Networking on Linux and Windows" 
                 return $bk')
WHERE docID = 2;


-- After performing the above insert and update operations the query 
-- performance starts to degrade and the DBA sees that the index has
-- become fragmented and needs to be reorged. The DBA decides to 
-- reorganize the index pages of the table 'supplied_books' by 
-- running the REORG indexes command.
REORG INDEX bname FOR TABLE supplied_books ALLOW WRITE ACCESS;

----------------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------------
DROP INDEX docIDix;
DROP INDEX nameix;
DROP INDEX bname;
DROP TABLE supplied_books;
DROP TABLE books_available;





