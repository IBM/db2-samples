-----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- 
-- Governed under the terms of the International
-- License Agreement for Non-Warranted Sample Code.
--
-- (C) COPYRIGHT International Business Machines Corp. 1995 - 2002        
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
-----------------------------------------------------------------------------
--
-- Installs sampleSP.jar to the database and creates 
-- the java stored procedure for the SampleWrapper nickname discovery.
--
-- PLEASE CHANGE ALL OCCURENCES OF SCHEMA to the intended user name
-- PLEASE CHANGE THE JARPATH to the location of the jar file
-- example: on Windows, it might be c:\sqllib\tools\
-- so the CALL sqlj.install_jar command like:
--    CALL sqlj.install_jar('file:///c:\Sqllib\tools\sampleSP.jar', 'sampleSP')
-- on AIX, it might be /home/userid/sqllib/tools/
--    CALL sqlj.install_jar('file:/home/userid/sqllib/tools/sampleSP.jar', 'sampleSP')
--
-- To run this file enter in command line: db2 -tvf sample.db2
--

CALL sqlj.remove_jar('sampleSP');

DROP PROCEDURE SCHEMA.SAMPLE(VARCHAR(4000), VARCHAR(4000), VARCHAR(10), VARCHAR(1));

CALL sqlj.install_jar('file:JARPATH\sampleSP.jar', 'sampleSP');

CREATE PROCEDURE SCHEMA.SAMPLE 	(IN WrapperName VARCHAR(4000),IN directory VARCHAR(4000),IN extension VARCHAR(10),IN subfolder VARCHAR(1) ) SPECIFIC SAMPLE	DYNAMIC RESULT SETS 1 NOT DETERMINISTIC LANGUAGE Java EXTERNAL NAME 'sample!get_Nicknames' FENCED NOT THREADSAFE	PARAMETER STYLE JAVA;