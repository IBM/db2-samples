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
-- SOURCE FILE NAME: spdrop.db2
--    
-- SAMPLE: How to uncatalog the stored procedures contained in spserver.sqc 
--
-- To run this script from the CLP issue the below command:
--            "db2 -td@ -vf <script-name>"
--    where <script-name> represents the name of this script
-----------------------------------------------------------------------------
-- For more information on the sample programs, see the README file.
--
-- For information on developing C applications, see the Application
-- Development Guide.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2 
-- applications, visit the DB2 application development website: 
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

connect to sample@

DROP PROCEDURE OUT_LANGUAGE (CHAR(8))@

DROP PROCEDURE OUT_PARAM (DOUBLE)@

DROP PROCEDURE IN_PARAMS (DOUBLE, DOUBLE, DOUBLE, CHAR(3))@

DROP PROCEDURE INOUT_PARAM (DOUBLE)@

DROP PROCEDURE CLOB_EXTRACT (CHAR(6), VARCHAR(1000))@

DROP PROCEDURE DBINFO_EXAMPLE (CHAR(8), DOUBLE, CHAR(128), CHAR(8))@

DROP PROCEDURE MAIN_EXAMPLE (CHAR(8), DOUBLE)@

DROP PROCEDURE ALL_DATA_TYPES (SMALLINT, INTEGER, BIGINT, REAL, DOUBLE,
     CHAR(1), CHAR(15), VARCHAR(12), DATE, TIME)@

DROP PROCEDURE ONE_RESULT_SET (DOUBLE)@

DROP PROCEDURE TWO_RESULT_SETS (DOUBLE)@

DROP PROCEDURE GENERAL_EXAMPLE (INTEGER, INTEGER, CHAR(32))@

DROP PROCEDURE GENERAL_WITH_NULLS_EXAMPLE (INTEGER, INTEGER, CHAR(32))@
 
connect reset@    
