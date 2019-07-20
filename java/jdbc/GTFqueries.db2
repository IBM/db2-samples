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
-- SOURCE FILE NAME: GTFqueries.db2
--
-- SAMPLE: Query to read the sample.csv file using functions in 
--         UDFcsvReader.java
--
-- To run this script from the CLP, perform the following steps:
-- 1. Change the path of the sample.csv in the query to path it is placed
--    in currently
-- 2. issue the command "db2 -tvf GTFqueries.db2" 
----------------------------------------------------------------------------
CONNECT TO sample;

select * from
table(csvRead('$DB2PATH/samples/java/jdbc/sample.csv')) as
TX(first varchar(23), last varchar(10),
street varchar(50), city varchar(15), state char(2),
zip char(5), age smallint, salary integer, id bigint,
gpa real, rand_double double);
