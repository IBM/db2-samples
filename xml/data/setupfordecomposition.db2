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
-- FILE NAME: setupfordecomposition.db2
--
-- PURPOSE: This is the set up script for the sample xmldecompostion.db2,
--          xmldecomposition.sqc, xmldecomposition.java.
--          The tables are created that are needed for the decomposition 
--          of the XML document bookdetail.xml.
--
-- SQL STATEMENTS USED:
--          CREATE
--
-- *************************************************************************
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-- *************************************************************************

--CONNET TO DATABASE
CONNECT TO sample;

CREATE TABLE admin.book_author (
   			         authid INTEGER NOT NULL ,
                                 authname VARCHAR(50),
 		                 isbn VARCHAR(13) NOT NULL,
        		         book_title VARCHAR(50),
                                 PRIMARY KEY (isbn));

CREATE TABLE xdb.book_contents (
                                isbn VARCHAR(13) REFERENCES admin.book_author(isbn),
                                chptnum INTEGER,
                                chpttitle VARCHAR(50),
                                chptcontent VARCHAR(1000));


CREATE TABLE xdb.books_avail ( 
                                isbn VARCHAR(13) REFERENCES admin.book_author(isbn),
                                book_title VARCHAR(50),
                                authname VARCHAR(50), 
                                authid  INTEGER,
                                price DECFLOAT,
                                no_of_copies INTEGER DEFAULT 0);
								
CREATE TABLE xdb.book_avail ( 
                                isbn VARCHAR(13) REFERENCES admin.book_author(isbn),
                                book_title VARCHAR(50),
                                authname VARCHAR(50), 
                                authid  INTEGER,
                                price DECFLOAT,
                                no_of_copies INTEGER DEFAULT 0);


-- table to store the information about books returned by customers 
CREATE TABLE xdb.books_returned (customerID VARCHAR(10), booksreturned XML);

-- CREATE books_recevied to store book details of books received from different suppliers 
CREATE TABLE xdb.books_received_BLOB( supplierID VARCHAR(15),  booksinfo BLOB(10K));


CREATE TABLE xdb.books_received( supplierID VARCHAR(15),  booksinfo XML);


-- Insert data into the required tables
INSERT INTO admin.book_author VALUES(234,'Carl','111111-20','DB2 Architecture');
INSERT INTO admin.book_author VALUES(234,'Carl','111112-12','Explore XML');
INSERT INTO admin.book_author VALUES(78,'Peter','111112-29','Learn DB2');
INSERT INTO admin.book_author VALUES(234,'Carl','111112-34','XML Decomposition');
INSERT INTO admin.book_author VALUES(2,'Prashanth','1-11-111112-2','Learn DB2 Architecture ');
INSERT INTO admin.book_author VALUES(32,'Kevin','111111-100','DB2 DBA');
INSERT INTO admin.book_author VALUES(234,'Carl','211111-20','DB2 fundamentals');
INSERT INTO admin.book_author VALUES(234,'Carl','111111-12','XML and DB2 fundamentals');
INSERT INTO admin.book_author VALUES(32,'Kevin','111112-120','DB2 DBA2');

-- import the XML data to books_returned table
IMPORT FROM booksreturned.del OF DEL 
            INSERT INTO xdb.books_returned;


-- INSERT books information into books_received table
INSERT INTO xdb.books_received_BLOB VALUES ('1011', CAST('
                            <books>
                                <book isbn="211111-20">
                                     <book_title>DB2 fundamentals</book_title>
                                     <author>Carl</author>
                                     <authid>234</authid>
                                     <price>80</price>
                                     <no_of_copies>10</no_of_copies>
                                </book>
                                <book isbn="111111-100">
                                     <book_title>DB2 DBA</book_title>
                                     <author>Kevin</author>
                                     <authid>32</authid>
                                     <price>180</price>
                                     <no_of_copies>20</no_of_copies>
                                </book>
                            </books>' AS BLOB));

-- INSERT books information into books_received table
INSERT INTO xdb.books_received_BLOB VALUES ('1012', CAST('
                           <books>
                               <book isbn="111111-12">
                                    <book_title>XML and DB2 fundamentals</book_title>
                                    <author>Carl</author>
                                    <authid>234</authid>
                                    <price>802</price>
                                    <no_of_copies>12</no_of_copies>
                               </book>
                               <book isbn="111112-120">
                                    <book_title>DB2 DBA2</book_title>
                                    <author>Kevin</author>
                                    <authid>32</authid>
                                    <price>182</price>
                                    <no_of_copies>22</no_of_copies>
                               </book>
                          </books>' AS BLOB));

-- insert the data from xdb.books_received_BLOB  table
INSERT INTO xdb.books_received(SELECT supplierID, booksinfo FROM xdb.books_received_BLOB);


-- COMMIT
COMMIT;

-- RESET CONNECTION
CONNECT RESET;
