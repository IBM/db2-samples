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
-- SOURCE FILE NAME: xquery_xmlproc_create.db2
--
-- SAMPLE: How to catalog the DB2 CLI stored procedure contained in
--         xquery_xmlproc.c
--
-- To run this script from the CLP, issue the command 
--                     db2 -td@ -vf xquery_xmlproc_create.db2
----------------------------------------------------------------------------
-- For more information on the sample programs, see the README file.
--
-- For information on developing CLI applications, see the CLI Guide
-- and Reference.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- connect to the SAMPLE database
CONNECT TO sample@

-- creating procedure
CREATE PROCEDURE Supp_XML_Proc_CLI( IN  inXML XML as CLOB(5000),
                                    OUT outXML XML as CLOB(5000))
LANGUAGE C
PARAMETER STYLE SQL
FENCED
PARAMETER CCSID UNICODE
EXTERNAL NAME 'xquery_xmlproc!xquery_proc'@

CONNECT RESET@


