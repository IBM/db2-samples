----------------------------------------------------------------------------
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
----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: Simple_XmlProc_Drop.db2
--
-- SAMPLE: How to uncatalog the stored procedure in Simple_XmlProc.java
--
-- To run this script from the CLP, 
--  issue the command "db2 -td@ -vf Simple_XmlProc_Drop.db2"
----------------------------------------------------------------------------

-- connect to the SAMPLE database
CONNECT TO sample@

-- drop the procedure
DROP PROCEDURE Simple_XML_Proc_Java( XML AS CLOB(5000), XML AS CLOB(5000), INTEGER)@

CONNECT RESET@

