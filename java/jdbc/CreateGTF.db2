-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2010 All rights reserved.
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
-- SOURCE FILE NAME: CreateGTF.db2
--
-- SAMPLE: How to catalog the UDFs contained in UDFcsvReader.java
--
-- To run this script from the CLP, perform the following steps:
-- 1. issue the command "db2 -tvf CreateGTF.db2"
----------------------------------------------------------------------------
CONNECT TO sample;

CREATE FUNCTION CSVREAD(VARCHAR(255))
RETURNS GENERIC TABLE
EXTERNAL NAME 'UDFcsvReader!csvReadString'
LANGUAGE JAVA
SPECIFIC csvReadString
PARAMETER STYLE DB2GENERAL
VARIANT
FENCED THREADSAFE
NOT NULL CALL
NO SQL
NO EXTERNAL ACTION
NO SCRATCHPAD
NO FINAL CALL
DISALLOW PARALLEL
NO DBINFO;

CREATE FUNCTION CSVREAD(VARCHAR(255), VARCHAR(255))
RETURNS GENERIC TABLE
EXTERNAL NAME 'UDFcsvReader!csvRead'
LANGUAGE JAVA
SPECIFIC csvRead
PARAMETER STYLE DB2GENERAL
VARIANT
FENCED THREADSAFE
NOT NULL CALL
NO SQL
NO EXTERNAL ACTION
NO SCRATCHPAD
NO FINAL CALL
DISALLOW PARALLEL
NO DBINFO;

CREATE FUNCTION HTTPCSVREAD(VARCHAR(255), INTEGER, VARCHAR(255))
RETURNS GENERIC TABLE
EXTERNAL NAME 'UDFcsvReader!httpCsvReadString'
LANGUAGE JAVA
SPECIFIC httpCsvReadString
PARAMETER STYLE DB2GENERAL
VARIANT
FENCED THREADSAFE
NOT NULL CALL
NO SQL
NO EXTERNAL ACTION
NO SCRATCHPAD
NO FINAL CALL
DISALLOW PARALLEL
NO DBINFO;

CREATE FUNCTION HADOOPCSVREAD(VARCHAR(255), INTEGER, VARCHAR(255))
RETURNS GENERIC TABLE
EXTERNAL NAME 'UDFcsvReader!hadoopCsvReadString'
LANGUAGE JAVA
SPECIFIC hadoopCsvReadString
PARAMETER STYLE DB2GENERAL
VARIANT
FENCED THREADSAFE
NOT NULL CALL
NO SQL
NO EXTERNAL ACTION
NO SCRATCHPAD
NO FINAL CALL
DISALLOW PARALLEL
NO DBINFO;
