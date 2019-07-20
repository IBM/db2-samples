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
--  SAMPLE FILE NAME: xmlload.db2                                          
--                                                                          
--  PURPOSE:  To demonstrate how to load XML content into a table using 
--            different options of LOAD command.
--                                                                          
--  USAGE SCENARIO: A store manager wants to load bulk of purchase order
--                  documents into an XML column of a table.
--                                                                          
--  PREREQUISITES: 
--        The data files and XML documents must exist in the same 
--        directory as the sample. Copy loaddata1.del and loaddata2.del from 
--        directory <install_path>/sqllib/samples/xml/data in UNIX and
--        <install_path>\sqllib\samples\xml\data in Windows to the working directory. 
--        Create a new directory "xmldatadir" in the working directory and copy 
--        loadfile1.xml and loadfile2.xml from directory
--        <install_path>/sqllib/samples/xml/data in UNIX and
--        <install_path>\sqllib\samples\xml\data in Windows to the newly created
--        xmldatadir directory and to the current working directory.                     
--                                                                          
--  EXECUTION:    db2 -tvf xmlload.db2   
--                                                                          
--  INPUTS:       NONE
--                                                                          
--  OUTPUTS:      Successful loading of XML purchase orders.     
--                                                                          
--  OUTPUT FILE:  xmlload.out (available in the online documentation)      
--                                     
--  SQL STATEMENTS USED:                                                    
--        LOAD                                               
--        INSERT
--        CREATE   
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
--  1. LOAD data into the table without any validation clause.
--  2. LOAD data into the table using XMLVALIDATE USING XDS clause.
--  3. LOAD data into the table using XMLVALIDATE USING SCHEMA clause. 
--  4. LOAD data into the table from cursor.
-- *************************************************************************/

-- /*************************************************************************
--    SETUP                                                                 
-- **************************************************************************/

-- Connect to the sample database
CONNECT TO sample;

-- Create a table POtable with an XML column "porder" to load XML data
CREATE TABLE POtable(POid INT NOT NULL PRIMARY KEY,porder XML);

-- *************************************************************************
--  1. LOAD data into the table without any validation clause
-- *************************************************************************

-- Define loaddata1.del without any schema specifications
-- Load the data from loaddata1.del without validating clause
LOAD FROM loaddata1.del of del MESSAGES loadmsg.txt INSERT into POtable;

-- select the data from the table to show that data is inserted successfully
SELECT count(*) FROM potable;

-- *************************************************************************
--  2. LOAD data into the table using XMLVALIDATE USING XDS clause
-- *************************************************************************

-- Define loaddata2.del with schema attributes
-- Load the data to the table using XMLVALIDATE USING XDS clause
LOAD FROM loaddata2.del OF DEL XML FROM xmldatadir
  MODIFIED BY XMLCHAR
  XMLVALIDATE USING XDS
  DEFAULT porder
  IGNORE (customer, supplier)
  MAP ( (product,porder)) 
  MESSAGES loadmsg.txt 
  INSERT INTO POtable;

-- select the data from the table to show that data is inserted successfully
SELECT count(*) FROM  POtable;

-- delete the inserted data from POtable
DELETE FROM POtable;

-- *************************************************************************
--  3. LOAD data into the table using XMLVALIDATE USING SCHEMA clause.
-- *************************************************************************

-- LOAD the data to the table using XMLVALIDATE USING SCHEMA clause
 LOAD FROM loaddata2.del OF DEL XML FROM xmldatadir
 MODIFIED BY XMLCHAR
 XMLVALIDATE using SCHEMA porder
 MESSAGES loadmsg.txt
 INSERT INTO POtable;

-- Select the data from the table to show that data is inserted successfully
SELECT count(*) FROM POtable;

-- delete the inserted data from POtable
DELETE FROM POtable;

-- *************************************************************************
--  4. LOAD data into the table from cursor.
-- *************************************************************************

-- Load the data from cursor
DECLARE C1 CURSOR FOR SELECT count(*)porder FROM PurchaseOrder;
LOAD FROM C1 of CURSOR MESSAGES loadmsg.txt INSERT INTO POtable;

-- Select the data from the table to show that data is inserted successfully
SELECT count(*) FROM POtable;

-- /*************************************************************************
--    CLEANUP                                                                 
-- **************************************************************************/

-- delete the inserted data from POtable
DELETE FROM POtable;

-- drop the table POtable
DROP TABLE POtable;

CONNECT RESET;
TERMINATE;
