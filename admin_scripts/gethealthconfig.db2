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
-- SOURCE FILE NAME: gethealthconfig.db2
--
-- SAMPLE: How to get definition, alert configuration and default alert 
--         configurations 
--
-- SQL STATEMENTS USED:
--         SELECT
--         TERMINATE
--
-- OUTPUT FILE: gethealthconfig.out (available in the online documentation)
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

-- connect to sample database
CONNECT TO SAMPLE;

-- Get the definition for health indicator db2.mon_heap_util
SELECT D.ID, 
       SUBSTR(D.SHORT_DESCRIPTION, 1, 25) AS SHORT_DESCRIPTION, 
       SUBSTR(D.FORMULA, 1, 55) AS FORMULA
  FROM TABLE(SYSPROC.HEALTH_GET_IND_DEFINITION('')) AS D
  WHERE NAME = 'db2.mon_heap_util';

-- Get alert configuration for health indicator db.log_util on database SAMPLE
SELECT SUBSTR(D.NAME, 1, 15) AS NAME,
       C.EVALUATE,
       C.ACTION_ENABLED,
       C.WARNING_THRESHOLD,
       C.ALARM_THRESHOLD
  FROM TABLE(SYSPROC.HEALTH_GET_IND_DEFINITION('')) AS D, 
       TABLE(SYSPROC.HEALTH_GET_ALERT_CFG('DB', 'O', 'SAMPLE', '')) AS C 
  WHERE D.ID = C.ID AND D.NAME = 'db.log_util';

-- Get Global default alert configuration settings for tablespaces on health indicator ts.ts_util 
SELECT SUBSTR(D.NAME, 1, 15) AS NAME,
       C.EVALUATE,
       C.ACTION_ENABLED,
       C.WARNING_THRESHOLD,
       C.ALARM_THRESHOLD
  FROM TABLE(SYSPROC.HEALTH_GET_IND_DEFINITION('')) AS D, 
       TABLE(SYSPROC.HEALTH_GET_ALERT_CFG('TS', 'G', '', '')) AS C 
  WHERE D.ID = C.ID AND D.NAME = 'ts.ts_util';

-- disconnect from the database
CONNECT RESET;

TERMINATE;