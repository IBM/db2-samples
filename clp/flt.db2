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
-- SOURCE FILE NAME: flt.db2
--    
-- SAMPLE: How to do a RECURSIVE QUERY 
--
-- SQL STATEMENTS USED:
--         DROP TABLE
--         CREATE TABLE
--         INSERT
--         SELECT
--
-- OUTPUT FILE: flt.out (available in the online documentation)
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

create table flights (source varchar (8), 
                      destination varchar (8),
                      d_time integer, 
                      a_time integer, 
                      cost smallint,
                      airline varchar (8));

INSERT INTO FLIGHTS VALUES ('Paris',   'Detroit',  null,null,700,'KLM'),
                           ('Paris',   'New York', null,null,600,'KLM'),
                           ('Paris',   'Toronto',   null,null,750,'AC'), 
                           ('Detroit', 'San Jose', null,null,400,'AA'),     
                           ('New York','Chicago',  null,null,200,'AA'),     
                           ('Toronto',  'Chicago',  null,null,275,'AC'),      
                           ('Chicago', 'San Jose', null,null,300,'AA');

WITH 
 REACH (SOURCE, DESTINATION, COST, STOPS) AS
   ( SELECT SOURCE, DESTINATION, COST, CAST(0 AS SMALLINT)
      FROM FLIGHTS
       WHERE SOURCE = 'Paris'
    UNION ALL
     SELECT R.SOURCE, F.DESTINATION, CAST(R.COST+F.COST AS SMALLINT), CAST(R.STOPS+1 AS SMALLINT)
     FROM REACH R, FLIGHTS F
      WHERE R.DESTINATION=F.SOURCE
        AND R.STOPS < 5
   )
SELECT DESTINATION, COST, STOPS FROM REACH;

drop table flights;

