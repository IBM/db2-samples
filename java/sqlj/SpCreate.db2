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
-- SOURCE FILE NAME: SpCreate.db2
--    
-- SAMPLE: How to catalog the stored procedures contained in SpServer.sqlj 
--
-- To run this script from the CLP issue the below command:
--            "db2 -td@ -vf <script-name>"
--    where <script-name> represents the name of this script
----------------------------------------------------------------------------

connect to sample@

CREATE PROCEDURE OUT_LANGUAGE (OUT LANGUAGE CHAR(8))
SPECIFIC SQLJ_OUT_LANGUAGE
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE JAVA
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.outLanguage'@

CREATE PROCEDURE OUT_PARAM (OUT medianSalary DOUBLE)
SPECIFIC SQLJ_OUT_PARAM
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE JAVA
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.outParameter'@

CREATE PROCEDURE IN_PARAMS (
  IN lowsal DOUBLE,
  IN medsal DOUBLE, 
  IN highsal DOUBLE, 
  IN department CHAR(3))
SPECIFIC SQLJ_IN_PARAMS
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE JAVA 
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
MODIFIES SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.inParams'@

CREATE PROCEDURE INOUT_PARAM (INOUT medianSalary DOUBLE)
SPECIFIC SQLJ_INOUT_PARAM
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE JAVA 
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
MODIFIES SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.inoutParam'@

CREATE PROCEDURE CLOB_EXTRACT (
  IN number CHAR(6), 
  OUT buffer VARCHAR(1000))
SPECIFIC SQLJ_CLOB_EXTRACT
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE JAVA
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.clobExtract'@

CREATE PROCEDURE DECIMAL_TYPE (INOUT decimalIn DECIMAL(10,2))
SPECIFIC SQLJ_DEC_TYPE
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE JAVA 
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.decimalType'@

CREATE PROCEDURE ALL_DATA_TYPES (
  INOUT small SMALLINT, 
  INOUT intIn INTEGER,
  INOUT bigIn BIGINT,
  INOUT realIn REAL, 
  INOUT doubleIn DOUBLE,
  OUT charOut CHAR(1),
  OUT charsOut CHAR(15),
  OUT varcharOut VARCHAR(12),
  OUT dateOut DATE,
  OUT timeOut TIME)
SPECIFIC SQLJ_ALL_DAT_TYPES
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE JAVA 
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.allDataTypes'@

CREATE PROCEDURE ONE_RESULT_SET (IN salValue DOUBLE)
SPECIFIC SQLJ_ONE_RES_SET
DYNAMIC RESULT SETS 1
NOT DETERMINISTIC
LANGUAGE JAVA 
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.resultSetToClient'@

CREATE PROCEDURE TWO_RESULT_SETS (IN salary DOUBLE)
SPECIFIC SQLJ_TWO_RES_SETS
DYNAMIC RESULT SETS 2
NOT DETERMINISTIC
LANGUAGE JAVA 
PARAMETER STYLE JAVA
NO DBINFO
FENCED
THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'SpServer.twoResultSets'@

connect reset@
