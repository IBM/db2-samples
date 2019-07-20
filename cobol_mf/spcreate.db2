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
-- SOURCE FILE NAME: spcreate.db2
--    
-- SAMPLE: How to catalog COBOL stored procedures
--
-- To run this script from the CLP, perform the following steps:
-- 1. connect to the database
-- 2. issue the command "db2 -td@ -vf spcreate.db2"
-----------------------------------------------------------------------------
--
-- For more information on the sample programs, see the README file.
--
-- For information on developing COBOL applications, see the Application
-- Development Guide.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2 
-- applications, visit the DB2 application development website: 
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

CREATE PROCEDURE INPSRV ( IN DEPTNUM SMALLINT,
                          IN DEPTNAME CHAR(14),
                          IN LOCATION CHAR(13),
                          OUT SQLCODE INT)
--- Embedded SQL in COBOL currently does not support result sets.
--- However, if you intend to call this COBOL stored procedure from
--- a client application that can handle result sets, set the DYNAMIC
--- RESULT SETS clause to 1, and follow the instructions in the code
--- comments in inpsrv.sqb.
  DYNAMIC RESULT SETS 0
  LANGUAGE COBOL 
  PARAMETER STYLE GENERAL
  NO DBINFO
  FENCED
  NOT THREADSAFE
  MODIFIES SQL DATA
  PROGRAM TYPE SUB
  EXTERNAL NAME 'inpsrv!inpsrv'@
