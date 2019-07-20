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
-- SOURCE FILE NAME: contacts.db2
--
-- SAMPLE: How to add, update and drop contacts and contactgroups
--
--         This sample shows:
--           1. How to add a contact for a user with e-mail address.
--           2. How to create a contactgroup with contact names.
--           3. How to update the address for the sample user.
--           4. How to update the contactgroup by adding a contact.
--           5. How to read a contact list.
--           6. How to read a contact group list
--           7. How to drop a contact from the list of contacts.
--           8. How to drop a contactgroup from the list of groups
--
-- Note: The Database Administration Server(DAS) should be running.
--
-- SQL STATEMENTS USED:
--           ADD
--           CONNECT
--           DROP
--           GET
--           UPDATE
--           TERMINATE
--
-- OUTPUT FILE: contacts.out (available in the online documentation)
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
CONNECT  TO sample;

-- Add contacts for a user with e-mail address
ADD CONTACT testuser1 TYPE EMAIL ADDRESS testuser1@test.com;

ADD CONTACT testuser2 TYPE EMAIL ADDRESS testuser2@test.com;

-- Create a contactgroup with a contact name
ADD CONTACTGROUP gname1 CONTACT testuser1;

-- Update the address for the user testuser1
UPDATE CONTACT testuser1 USING ADDRESS address@test.com;

-- Update the contactgroup by adding a contact
UPDATE CONTACTGROUP gname1 ADD CONTACT testuser2;

-- Get the list of contactgroups
GET CONTACTGROUPS;

-- Get the list of contacts
GET CONTACTS;

-- Drop a contactgroup from the list of groups
DROP CONTACTGROUP gname1;

-- Drop contacts from the list of contacts
DROP CONTACT testuser1;

DROP CONTACT testuser2;

-- Disconnect from the database
CONNECT RESET;

TERMINATE;
