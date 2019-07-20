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
-- FILE NAME: cleanupfordecomposition.db2
--
-- PURPOSE: This is the clean up script for the sample xmldecompostion.db2,
--          xmldecomposition.sqc, xmldecomposition.java.
--          The tables are dropped that were created by the setup script.
--
-- SQL STATEMENTS USED:
--          DROP
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
-- *************************************************************************/

CONNECT TO sample;

-- drop the schemas and tables created
DROP XSROBJECT XDB.BOOKDETAILS;
DROP XSROBJECT XDB.BOOKSRETURNED;
DROP TABLE XDB.BOOK_CONTENTS; 
DROP TABLE ADMIN.BOOK_AUTHOR;
DROP TABLE XDB.BOOKS_AVAIL;
DROP TABLE XDB.BOOK_AVAIL;
DROP TABLE XDB.BOOKS_RETURNED;
DROP TABLE XDB.BOOKS_RECEIVED;
DROP TABLE XDB.BOOKS_RECEIVED_BLOB;

-- RESET CONNECTION
CONNECT RESET;
