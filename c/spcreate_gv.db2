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
-- SOURCE FILE NAME: spcreate_gv.db2
--
-- SAMPLE     : How to catalog the stored procedures. This stored procedure 
--              will be called from the source sample globvarsupport.sqc. 
--
-- EXECUTION  : db2 -vtf spcreate_gv.db2
-----------------------------------------------------------------------------
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
-- http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Connect to sample database.
CONNECT TO sample;

-- Create the table 'security.users'.
CREATE TABLE security.users (userid varchar (10) NOT NULL PRIMARY KEY,
                             firstname varchar(10), lastname varchar(10),
                             authlevel int);

-- Populate table with the following data.
INSERT INTO security.users VALUES ('praveen', 'sanjay', 'mohan', 1);
INSERT INTO security.users VALUES ('PRAVEEN', 'SANJAY', 'MOHAN', 1);
INSERT INTO security.users VALUES ('padma', 'gaurav', 'PADMA', 3);

-- Create a global variable.
CREATE VARIABLE security.gv_user VARCHAR (10) DEFAULT (SESSION_USER);

-- Create procedure 'get_authorization' that is dependent on the
-- global variable 'security.gv_user'.
CREATE PROCEDURE get_authorization (OUT authorization INT)
RESULT SETS 1
LANGUAGE SQL
  SELECT authlevel INTO authorization
    FROM security.users
    WHERE userid = security.gv_user;

-- Disconnect from the database.
CONNECT RESET;
TERMINATE;
