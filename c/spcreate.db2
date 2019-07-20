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
-- SAMPLE: How to catalog the stored procedures contained in spserver.sqc 
--
-- To run this script from the CLP, perform the following steps:
-- 1. connect to the database
-- 2. issue the command "db2 -td@ -vf <script-name>"
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

CREATE PROCEDURE OUT_LANGUAGE (OUT language CHAR(8))
SPECIFIC C_OUT_LANGUAGE
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!OutLanguage'@

CREATE PROCEDURE OUT_PARAM (OUT medianSalary DOUBLE)
SPECIFIC C_OUT_PARAM
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!OutParam'@

CREATE PROCEDURE IN_PARAMS (
  IN lowsal DOUBLE,
  IN medsal DOUBLE,
  IN highsal DOUBLE,
  IN department CHAR(3))
SPECIFIC C_IN_PARAMS
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
MODIFIES SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!InParams'@

CREATE PROCEDURE INOUT_PARAM (INOUT medianSalary DOUBLE)
SPECIFIC C_INOUT_PARAM
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!InOutParam'@

CREATE PROCEDURE CLOB_EXTRACT (
  IN number CHAR(6),
  OUT buffer VARCHAR(1000))
SPECIFIC C_CLOB_EXTRACT
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!ExtractFromClob'@

CREATE PROCEDURE DBINFO_EXAMPLE (
  IN job CHAR(8),
  OUT salary DOUBLE,
  OUT dbname CHAR(128),
  OUT dbversion CHAR(8))
SPECIFIC C_DBINFO_EXAMPLE
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!DbinfoExample'@

CREATE PROCEDURE MAIN_EXAMPLE (
  IN job CHAR(8),
  OUT salary DOUBLE)
SPECIFIC C_MAIN_EXAMPLE
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE MAIN
EXTERNAL NAME 'spserver!MainExample'@

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
SPECIFIC C_ALL_DAT_TYPES
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!AllDataTypes'@

CREATE PROCEDURE ONE_RESULT_SET (IN salValue DOUBLE)
SPECIFIC C_ONE_RES_SET
DYNAMIC RESULT SETS 1
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!OneResultSetToClient'@

CREATE PROCEDURE TWO_RESULT_SETS (IN salary DOUBLE)
SPECIFIC C_TWO_RES_SETS
DYNAMIC RESULT SETS 2
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE SQL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!TwoResultSets'@

CREATE PROCEDURE GENERAL_EXAMPLE (
  IN edLevel INTEGER,
  OUT errCode INTEGER,
  OUT errMsg CHAR(32))
SPECIFIC C_GEN_EXAMPLE
DYNAMIC RESULT SETS 1
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE GENERAL
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!GeneralExample'@

CREATE PROCEDURE GENERAL_WITH_NULLS_EXAMPLE (
  IN quarter INTEGER,
  OUT errCode INTEGER,
  OUT errMsg CHAR(32))
SPECIFIC C_GEN_NULLS
DYNAMIC RESULT SETS 1
NOT DETERMINISTIC
LANGUAGE C
PARAMETER STYLE GENERAL WITH NULLS
NO DBINFO
FENCED NOT THREADSAFE
READS SQL DATA
PROGRAM TYPE SUB
EXTERNAL NAME 'spserver!GeneralWithNullsExample'@
