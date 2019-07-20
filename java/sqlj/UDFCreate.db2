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
-- SOURCE FILE NAME: UDFCreate.db2
--    
-- SAMPLE: How to catalog the UDFs contained in UDFsrv.java 
--
-- To run this script from the CLP issue the below command:
--            "db2 -td@ -vf <script-name>"
--    where <script-name> represents the name of this script
----------------------------------------------------------------------------

connect to sample@

CREATE FUNCTION scratchpadScUDF( )
RETURNS INTEGER
EXTERNAL NAME 'UDFsrv!scratchpadScUDF'
FENCED
SCRATCHPAD 10
FINAL CALL
VARIANT
NO SQL
PARAMETER STYLE DB2GENERAL
LANGUAGE JAVA
NO EXTERNAL ACTION@

CREATE FUNCTION scUDFReturningErr( DOUBLE, DOUBLE )
RETURNS DOUBLE
EXTERNAL NAME 'UDFsrv!scUDFReturningErr'
FENCED
NOT VARIANT
NO SQL
PARAMETER STYLE DB2GENERAL
LANGUAGE JAVA
NO EXTERNAL ACTION@

CREATE FUNCTION tableUDF ( DOUBLE )
RETURNS TABLE ( name VARCHAR(20), job VARCHAR(20), salary DOUBLE )
EXTERNAL NAME 'UDFsrv!tableUDF'
LANGUAGE JAVA
PARAMETER STYLE DB2GENERAL
NOT DETERMINISTIC
FENCED
NO SQL
NO EXTERNAL ACTION
SCRATCHPAD 10
FINAL CALL
DISALLOW PARALLEL
NO DBINFO@

connect reset@
