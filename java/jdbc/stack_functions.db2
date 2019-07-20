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
-- SOURCE FILE NAME: stack_functions.db2 
--
-- DESCRIPTION: This is the set up script for the sample Array_Stack.java
--
-- SQL STATEMENTS USED:
--               SELECT
--               DROP
--               CALL
--               CREATE PROCEDURE
--
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

-- Connect to the database
CONNECT TO sample@

-- Drop the database objects if already exists.
DROP PROCEDURE push @
DROP PROCEDURE top @
DROP PROCEDURE pop @
DROP PROCEDURE stack_2_resultset @
DROP PROCEDURE use_stack @
DROP TYPE int_stack @

----------------------------------------------------------------------------
--
-- 1. Create an ARRAY type to implement a stack. 
--
-----------------------------------------------------------------------------

CREATE TYPE int_stack AS INTEGER ARRAY[] @

----------------------------------------------------------------------------
--
-- 2. Create a procedure to push a value in the stack. 
--
-----------------------------------------------------------------------------

-- Create a stored procedure to insert value in the stack.
CREATE  PROCEDURE push(INOUT s int_stack, IN element INTEGER)
BEGIN
  IF (s is NULL) THEN
    SET s[1] = element;
  ELSE
    SET s[cardinality(s) + 1] = element;
  END IF;
END @

----------------------------------------------------------------------------
--
-- 3. Create a procedure to pop/retrieve value from the stack.
--
-----------------------------------------------------------------------------

-- Create a procedure to pop/retrieve a value from the stack.
CREATE PROCEDURE pop(INOUT s int_stack, OUT element INTEGER)
BEGIN
  IF NOT(s is NULL) AND cardinality(s) > 0 THEN
    SET element = s[cardinality(s)];
    SET s = trim_array(s, 1);
  END IF;
END @

----------------------------------------------------------------------------
--
-- 4. Create a procedure to select the topmost value from the stack. 
--
-----------------------------------------------------------------------------

-- Create a procedure to select the topmost value in the stack.
CREATE PROCEDURE top(IN s int_stack, OUT element INTEGER)
BEGIN
  IF NOT(s is NULL) AND cardinality(s) > 0 THEN
    SET element = s[cardinality(s)];
  END IF;
END @

----------------------------------------------------------------------------
--
-- 5. Create a procedure to return all the stack values as a result set. 
--
-----------------------------------------------------------------------------

-- Create a procedure to return the stack values as a result set
CREATE PROCEDURE stack_2_resultset(IN s int_stack)
BEGIN
  DECLARE cur CURSOR WITH RETURN  TO CLIENT FOR
    SELECT elem, idx FROM unnest(s) WITH ORDINALITY AS t(elem, idx);

  OPEN cur;

END @

----------------------------------------------------------------------------
--
-- 6. Create a procedure to show case the stack functionalities. 
--
-----------------------------------------------------------------------------

-- Create a procedure to show case the stack functionalities.
CREATE PROCEDURE use_stack(INOUT  s int_stack,
                           OUT val1 INTEGER,
                           OUT val2 INTEGER)
BEGIN
  CALL push(s, 100);
  CALL push(s, 200);
  CALL push(s, 300);
  CALL push(s, 400);

  CALL pop(s, val1);
  CALL top(s, val2);

  CALL stack_2_resultset(s);
END @

