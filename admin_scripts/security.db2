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
-- SOURCE FILE NAME: security.db2
--
-- SAMPLE: How users can query details about the groups, authorities,
--         privileges and ownerships by using APIs without querying various
--         catalog tables for this purpose.
--
--         The sample shows how to:
--         1. Retrieve the groups to which the user belongs to using the UDF
--            SYSPROC.AUTH_LIST_GROUPS_FOR_AUTHID
--         2. Retrieve the objects owned by the user by using the view
--            SYSCAT.OBJECTOWNERS
--         3. Retrieve authorities/privileges directly granted to the user
--            by using the view SYSCAT.PRIVILEGES
--         4. Retrieve the authid type of an authid by using the view
--            SYSCAT.AUTHORIZATIONIDS.
--
-- SQL STATEMENTS USED:
--         CONNECT
--         SELECT
--         TERMINATE
--
-- OUTPUT FILE: security.out (available in the online documentation)
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
-- Connect to sample database
CONNECT TO SAMPLE;

-- Retrieve the group to which the user belongs to
SELECT * FROM table (SYSPROC.AUTH_LIST_GROUPS_FOR_AUTHID (CURRENT USER)) AS ST;

-- Retrieve the objects owned by the current user
SELECT * FROM  SYSIBMADM.OBJECTOWNERS WHERE OWNER = CURRENT USER;
    
-- Retrieve authorities/privileges directly granted to the user
SELECT * FROM SYSIBMADM.PRIVILEGES WHERE AUTHID = CURRENT USER;

-- Retrieve the authorization type of the authid
SELECT * FROM SYSIBMADM.AUTHORIZATIONIDS WHERE AUTHID = CURRENT USER;

-- Disconnect from the sample database;
CONNECT RESET;

TERMINATE;
