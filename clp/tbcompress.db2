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
-- SOURCE FILE NAME: tbcompress.db2
--
-- SAMPLE: How to create tables with null and default value compression
--         option.
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         DROP TABLE
--         TERMINATE
--
-- OUTPUT FILE: tbcompress.out (available in the online documentation)
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

-- create a table 'comp_tab'
CREATE TABLE comp_tab(col1 INT NOT NULL WITH DEFAULT,
                      col2 CHAR(7),
                      col3 VARCHAR(7) NOT NULL,
                      col4 DOUBLE);

-- activate VALUE COMPRESSION at table level and COMPRESS SYSTEM DEFAULT at
-- column level

-- rows will be formatted using the new row format on subsequent insert,load
-- and update operation, and NULL values will not be taking up space,
-- if applicable.

-- if the table 'comp_tab' does not have many NULL values, enabling 
-- compression will result in using more disk space than using the 
-- old row format

ALTER TABLE comp_tab ACTIVATE VALUE COMPRESSION;

-- use 'COMPRESS SYSTEM DEFAULT' to save more disk space on system default
-- value for column 'col1'.
-- on subsequent insert, load, and update operations, numerical '0' value 
-- (occupying 4 bytes of storage) for column col1 will not be saved on disk.

ALTER TABLE comp_tab ALTER col1 COMPRESS SYSTEM DEFAULT;

-- switch the table to use the old format.
-- rows inserted, loaded or updated after the ALTER statement will have old 
-- row format.

ALTER TABLE comp_tab DEACTIVATE VALUE COMPRESSION;

-- drop the table
DROP TABLE comp_tab;

-- disconnect from the database
CONNECT RESET;

TERMINATE;
