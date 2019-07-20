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
-- SAMPLE FILE NAME: recxmldecomp.db2                                          
--
-- PURPOSE: How to register a recursive XML schema to the XSR and
--          enable the same for decomposition.
--
-- USER SCENARIO: The existing PurchaseOrder schema in the Sample database is 
--   enhanced to have new Employee tables to process the purchase orders. 
--   We have Recursive Schema for Employee data management, an employee
--   can be a manager and himself reporting to another employee. The XML document 
--   contains the employee information along with department details which needs
--   to be stored in relational tables for easy retrieval of data.  
--
--
--  PREREQUISITE:
--        The instance document and the annotated schema should exist in the same 
--        directory as the sample. Copy recemp.xml, recemp.xsd from directory 
--        <install_path>/sqllib/samples/xml/data in UNIX and
--        <install_path>\sqllib\samples\xml\data in Windows to the working directory.
--                                                                          
--  EXECUTION:    db2 -tvf recxmldecomp.db2 
--                                                                          
--  INPUTS:       NONE
--                                                                          
--  OUTPUTS:      Decomposition of XML document according to the annotations 
--                in recursive schema. 
--                                                                          
--  OUTPUT FILE:  recxmldecomp.out (available in the online documentation)      
--                                     
--  SQL STATEMENTS USED:                                                    
--        REGISTER XMLSCHEMA                                                  
--        COMPLETE XMLSCHEMA      
--        DECOMPOSE XML DOCUMENT                                          
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
-- 1. Register the annotated XML schema.
-- 2. Decompose the XML document using the registered XML schema.
-- 3. Select data from the relational tables to see decomposed data.
-- *************************************************************************/

-- /*************************************************************************
--    SETUP 
-- **************************************************************************/

-- connect to the database sample
CONNECT TO SAMPLE;

-- create the table to store the decomposed data
CREATE TABLE xdb.poemployee (empid VARCHAR(20), deptid VARCHAR(20), members XML);

-- /*************************************************************************
-- 1. Register the annotated XML schema.
-- *************************************************************************/

-- register the schema document
REGISTER XMLSCHEMA 'http://porder.com/employee.xsd' FROM 'recemp.xsd' AS xdb.employee;

-- complete schema registration
COMPLETE XMLSCHEMA xdb.employee ENABLE DECOMPOSITION;

-- check catalog tables for information regarding registered schema.
SELECT status, decomposition, decomposition_version 
                       FROM SYSIBM.SYSXSROBJECTS 
                       where XSROBJECTNAME = 'EMPLOYEE';

-- /*************************************************************************
-- 2. Decompose the XML document using the registered XML schema.
-- *************************************************************************/

-- decompose the XML document
DECOMPOSE XML DOCUMENT recemp.xml XMLSCHEMA xdb.employee VALIDATE;

-- /*************************************************************************
-- 3. Select data from the relational tables to see decomposed data.
-- *************************************************************************/

-- check Decomposition result
SELECT * FROM xdb.poemployee ORDER BY empid;

-- /*************************************************************************
--    CLEANUP 
-- **************************************************************************/

-- drop the created objects
DROP XSROBJECT xdb.employee;
DROP TABLE xdb.poemployee ;

-- Reset connection
CONNECT RESET;
