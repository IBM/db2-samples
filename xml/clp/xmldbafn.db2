--/*************************************************************************
--   (c) Copyright IBM Corp. 2008 All rights reserved.
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
--  SAMPLE FILE NAME: xmldbafn.db2                                          
--                                                                          
--  PURPOSE: To show how to use the following DBA functions to get
--           inline properties of XML documents or LOBs.
--           1.	ADMIN_IS_INLINED: Evaluates whether data (XML, LOB) is 
--                inlined in a row.
--           2.	ADMIN_EST_INLINE_LENGTH: Evaluates the estimated 
--                inline length of a column in order to inline the 
--                data (XML, LOB) in a row.   
--                                                                          
--  USAGE SCENARIO: The scenario is for a Book Store that has two types 
--           of customers, retail customers and corporate customers. 
--           Corporate customers do bulk purchases of books for their 
--           company libraries. The store has a DBA for maintaining 
--           the database, the store’s manager runs queries on different
--           tables to view the book sales. 
--
--           The store manager notifies the DBA that the queries 
--           for the employee and contact details tables are running  
--           very slowly. Because both the employee and contact details 
--           tables were created with the “INLINE” option on XML column   
--           for faster retrieval, the DBA decides to investigate the reason  
--           for the performance issues. The DBA uses the ADMIN_IS_INLINED 
--           function to determine if all the XML documents are 
--           inlined. For the XML documents that are not inlined, the 
--           DBA uses the ADMIN_EST_INLINE_LENGTH function to get the 
--           maximum inline length required for the table. The DBA then 
--           increases the inline length of the XML column to make the 
--           documents inline.     
--
--           This sample creates the employee_inline and contact_details 
--           tables and shows how to use the new DBA functions to get 
--           the inline statistics of XML documents or LOBs. This 
--           sample also shows how to increase query performance by 
--           inlining documents or LOBs that are not already inlined.
                
--                                                                          
--  PREREQUISITE: NONE                           
--                                                                          
--  EXECUTION:    db2 -tvf xmldbafn.db2   
--                                                                          
--  INPUTS:       NONE
--                                                                          
--  OUTPUTS:      Successful usage of XML DBA functions.                                            
--                                                                          
--  OUTPUT FILE:  xmldbafn.out (available in the online documentation)      
--                                     
--  SQL STATEMENTS USED:                                                    
--        CREATE
--        INSERT
--        SELECT
--        ALTER
--        UPDATE
--        DROP                                          
--                                                                                                                                                   
--  XML DBA FUNCTIONS USED:                                                  
--        ADMIN_IS_INLINED
--        ADMIN_EST_INLINE_LENGTH 
--  
-- *************************************************************************
-- For more information about the command line processor (CLP) scripts,     
-- see the README file.                                                     
-- For information on using SQL statements, see the SQL Reference.          
--                                                                          
-- *************************************************************************
--
--  SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
-- This sample will demonstrate the following features
--  1. Inlining XML documents
--  2. Inlining CLOB data
-- *************************************************************************/

-- /*************************************************************************
--    Connection setup
-- **************************************************************************/

-- connect to the database
CONNECT TO sample;


--/************************************************************************
-- Setting up tables for the sample
-- ************************************************************************/

-- Create table 'employee_inline' to contain the employee information. 
-- The XML column in this table is created with inline length 450 based on 
-- initial document's size in the table.
CREATE TABLE employee_inline (emp_ID INT NOT NULL PRIMARY KEY,
                              emp_details XML INLINE LENGTH 450);

-- Insert employee details into employee_inline table
INSERT INTO employee_inline 
  VALUES(101, XMLPARSE(document '<emp_details ID="101">
                                   <name>Sowmya</name>
                                   <type>contractor</type>
                                   <dept>QA</dept>
                                   <designation>software engineer</designation>
                                   <salary>20000</salary>
                                 </emp_details>' preserve whitespace));

INSERT INTO employee_inline 
  VALUES(102, XMLPARSE(document '<emp_details ID="102">
      <name>Rahul</name>
      <type>regular</type>
      <dept>QA</dept>
      <designation>software engineer</designation>
      <salary>50000</salary>
      <date_of_birth>10-10-1934</date_of_birth>
      <gender> female</gender>
      <date_of_joining>10-20-1955</date_of_joining>
      <contact_details>
          <address>
            <street>Nagole</street>
            <city>Chennai</city>
            <state>Tamil Nadu</state>
          </address>
      </contact_details>
 </emp_details>' preserve whitespace));

-- Create 'contact_details' table with INLINE length 120 ON CLOB column
-- based on initial document's size in the table
CREATE TABLE contact_details (emp_ID INT, address CLOB(1K) INLINE LENGTH 120);

-- Insert contact details of employees into contact_details table
INSERT INTO contact_details 
  VALUES (101, 'indra nagar,Hyderabad,AP-500050,040-32432433' );

INSERT INTO contact_details 
   VALUES (102, 'Address: street: Nagole road, 11-1234-201-405, 
                          City:Chennai,T-nagar,4th crossa,17th line,
                          State:Tamil Nadu,India - 400040.
                          Phone:044-7643534, 044-23452345,
                          Mobile: 09999988888');

-- /*************************************************************************
--  1. Inlining XML documents
-- *************************************************************************/

-- DBA checks how many documents are inlined in 
-- employee_inlined table with the following query.
SELECT emp_ID, ADMIN_IS_INLINED(emp_details) as IS_INLINED 
       FROM employee_inline;

-- From the output of the above query, DBA gets to know that all the documents
-- are not inlined. So, the DBA uses the ADMIN_EST_INLINE_LENGTH function to 
-- calculate maximum inline length of XML documents in XML column of
-- employee_inline table 
SELECT MAX(ADMIN_EST_INLINE_LENGTH(emp_details)) AS MAX_INLINE_LENGTH 
  FROM employee_inline;

-- From the output of the above query, the DBA gets to know that maximum 
-- estimated inline length is 780. So he alters the employee_inline table 
-- with this estimated inline length of 780 for emp_details column.
-- NOTE: Once after increasing the inline length, it cannot reduced.
ALTER TABLE employee_inline ALTER COLUMN emp_details 
      SET INLINE LENGTH 780;

-- DBA updates the emp_details column to inline documents with new inline length 
UPDATE employee_inline SET emp_details=emp_details;

-- DBA uses the following query to determine if all the documents are inlined
SELECT emp_ID, ADMIN_IS_INLINED(emp_details) as IS_INLINED 
       FROM employee_inline;

-- /*************************************************************************
--  2. Inlining CLOB data
-- *************************************************************************/
-- The DBA calls the ADMIN_IS_INLINED function to 
-- determine which CLOB data in the contact_details table are inlined.
SELECT emp_ID, ADMIN_IS_INLINED(address) as IS_INLINED 
  FROM contact_details;

-- From the output of the above query, DBA gets to know that all the CLOB 
-- data is not inlined. So, he uses the ADMIN_EST_INLINE_LENGTH function to 
-- calculate maximum estimated inline length for CLOB column
-- NOTE: Once after increasing the inline length, it cannot reduced.
SELECT MAX(ADMIN_EST_INLINE_LENGTH(address)) AS EST_INLINE_LENGTH 
  FROM contact_details;

-- From this output of the above query, the DBA learns that the maximum 
-- estimated inline length required for the address column is 190. 
-- The DBA then alters the contact_details table with this estimated 
-- inline length for the address column.
ALTER TABLE contact_details ALTER address SET INLINE LENGTH 190;

-- Update address value to get the address details inlined 
UPDATE contact_details set address = address;

-- DBA uses the following query to determine if all the 
-- documents are inlined
SELECT emp_ID, ADMIN_IS_INLINED(address) AS IS_INLINED 
  FROM contact_details;

-- Drop the tables
DROP TABLE employee_inline;
DROP TABLE contact_details;

CONNECT RESET;
