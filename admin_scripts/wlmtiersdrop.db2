----------------------------------------------------------------------------
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
-----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: wlmtiersdrop.db2
--
-- SAMPLE: This script drops all DB2 Workload Manager (WLM) service classes,
--         thresholds, workloads, work class sets and work action sets that are
--         created by wlmtiersdefault.db2 or wlmtierstimerons.db2.
--
--     Actions performed by this script:
--
--     1.  Alter workload SYSDEFAULTUSERWORKLOAD to map to service
--         class SYSDEFAULTUSERCLASS.
--
--     2.  Disable service classes WLM_SHORT, WLM_MEDIUM, WLM_LONG and 
--         WLM_TIERS.
--
--     3.  Alter service class properties of SYSDEFAULTSYSTEMCLASS,
--         SYSDEFAULTMAINTENANCECLASS and SYSDEFAULTUSERCLASS back to default.
--
--     4.  Drop work action set WLM_TIERS_WAS.
--
--     5.  Drop work class set WLM_TIERS_WCS.
--
--     6.  Drop all CPUTIMEINSC thresholds.
--
--     7.  Drop service classes WLM_SHORT, WLM_MEDIUM, WLM_LONG and
--         WLM_TIERS.
--
-----------------------------------------------------------------------------
--
-- USAGE
--
--    1. Connect to your database. You must have DBADM or WLMADM authority.
--
--    2. Use the following command to execute this script. This sample uses
--       @ as the delimiting character.
--
--          db2 -td@ -vf wlmtiersdrop.db2
--
--    3. Reset the connection.
--
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on the SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Map workload SYSDEFAULTUSERWORKLOAD back to service class
-- SYSDEFAULTUSERCLASS
ALTER WORKLOAD SYSDEFAULTUSERWORKLOAD SERVICE CLASS SYSDEFAULTUSERCLASS@


-- Disable service classes WLM_SHORT, WLM_MEDIUM, WLM_LONG and WLM_TIERS
ALTER SERVICE CLASS WLM_SHORT UNDER WLM_TIERS DISABLE@

ALTER SERVICE CLASS WLM_MEDIUM UNDER WLM_TIERS DISABLE@

ALTER SERVICE CLASS WLM_LONG UNDER WLM_TIERS DISABLE@

ALTER SERVICE CLASS WLM_TIERS DISABLE@


-- Drop work action set WLM_TIERS_WAS
DROP WORK ACTION SET WLM_TIERS_WAS@


-- Drop work class set WLM_TIERS_WCS
DROP WORK CLASS SET WLM_TIERS_WCS@


-- Drop remapping thresholds WLM_TIERS_REMAP_SHORT_TO_MEDIUM and
-- WLM_TIERS_REMAP_MEDIUM_TO_LONG. 
DROP THRESHOLD WLM_TIERS_REMAP_SHORT_TO_MEDIUM@

DROP THRESHOLD WLM_TIERS_REMAP_MEDIUM_TO_LONG@


-- Drop service classes WLM_SHORT, WLM_MEDIUM, WLM_LONG and
-- WLM_TIERS.
DROP SERVICE CLASS WLM_SHORT UNDER WLM_TIERS@

DROP SERVICE CLASS WLM_MEDIUM UNDER WLM_TIERS@

DROP SERVICE CLASS WLM_LONG UNDER WLM_TIERS@

DROP SERVICE CLASS WLM_TIERS@


-- Reset prefetch priority for default service superclasses.

ALTER SERVICE CLASS SYSDEFAULTSYSTEMCLASS  
  PREFETCH PRIORITY DEFAULT@

ALTER SERVICE CLASS SYSDEFAULTMAINTENANCECLASS  
  PREFETCH PRIORITY DEFAULT@
