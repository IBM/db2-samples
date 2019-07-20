-------------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2008 All rights reserved.
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
-------------------------------------------------------------------------------
--
-- SOURCE FILE NAME: DropCGTT.db2
--
-- SAMPLE: 
--       i) This script cleans-up all the database objects created by executing  
--       the script file CreateCGTT.db2. 
--
-- Note: Use following command to execute the sample:
--         db2 -td@ -vf DropCGTT.db2
--
-- SQL STATEMENTS USED:
--       1) TRUNCATE TABLE
--       2) DROP 
-------------------------------------------------------------------------------

-- Remove contents from the created temporary table.
TRUNCATE TABLE cgtt.tax_cal IMMEDIATE@

-- DROP the trigger, procedure, and function created by the sample. .
DROP TRIGGER cgtt.tax_update@
DROP FUNCTION cgtt.tax_compute@
DROP SPECIFIC PROCEDURE cgtt.updater@
DROP SPECIFIC PROCEDURE cgtt.initialTax@
DROP SPECIFIC PROCEDURE cgtt.finalTax@
DROP FUNCTION cgtt.printITSheet@

-- DROP all the tables, indexes, and views created by the sample.
DROP INDEX cgtt.IndexOnId@
DROP TABLE cgtt.tax_cal@
DROP TABLE cgtt.payroll@
DROP VIEW cgtt.ViewOnCgtt@

-- DROP tablespaces created by the sample
DROP TABLESPACE TbspaceCgtt@
DROP TABLESPACE TbspacePayroll@
DROP BUFFERPOOL BufForSample@
--------------------------------------------------------------------------------
