--/****************************************************************************
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
-- ******************************************************************************
--
-- SAMPLE FILE NAME: tsinfo.db2
--
-- PURPOSE         : This sample demonstrates how to get tablespace information.
--
-- PREREQUISITE    : SAMPLE database must exist before executing this sample.
--	
-- EXECUTION       : db2 -tvf tsinfo.db2
--                   
-- INPUTS          : NONE
--
-- OUTPUT          : Successful execution of all SELECT statements.
--
-- DEPENDENCIES    : NONE 
--
-- SQL STATEMENTS USED:
--                 SELECT
--
-- *************************************************************************
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--
-- http://www.ibm.com/software/data/db2/ad/ 
--
-- *************************************************************************
--
--  SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
-- This sample demonstrates
--   1. How to get tablespace info for all the tablespaces.
--   2. How to get tablespace info for a particular tablespace.
--   3. How to get info for all containers in all tablespaces.
--   4. How to get container info for a particular tablespace.
-- *************************************************************************/

-- Connect to sample database
CONNECT TO sample;

--  /*****************************************************************/
--  /* 1. How to get tablespace info for all the tablespaces            */
--  /*****************************************************************/

-- Get information for all tablespaces using table function 
-- SYSPROC.MON_GET_TABLESPACE. First parameter ''(empty string) gets 
-- information for all containers in all tablespaces in the database. 

SELECT tbsp_id, tbsp_name, tbsp_type, tbsp_content_type, tbsp_state, 
       tbsp_total_pages, tbsp_usable_pages, tbsp_used_pages, 
       tbsp_free_pages, tbsp_page_top 
  FROM TABLE(SYSPROC.MON_GET_TABLESPACE('', -1));


--  /*****************************************************************/
--  /* 2. How to get tablespace info for a particular tablespace        */
--  /*****************************************************************/

-- Get tablespace information for tablespace 'USERSPACE1' of current database
-- member ('-1' if database is multipartitioned) using table function 
-- SYSPROC.MON_GET_TABLESPACE. 

SELECT tbsp_id, tbsp_name, tbsp_type, tbsp_content_type, tbsp_state, 
       tbsp_total_pages, tbsp_usable_pages, tbsp_used_pages, tbsp_free_pages, 
       tbsp_page_top 
  FROM TABLE(SYSPROC.MON_GET_TABLESPACE('USERSPACE1', -1));


--  /*****************************************************************/
--  /* 3. How to get info for all containers in all tablespaces         */
--  /*****************************************************************/

-- Get information for all containers of all tablespaces of current 
-- database member using table function SYSPROC.MON_GET_CONTAINER. 
-- When NULL value is specified for second parameter, -1 is set 
-- implicitly. 

SELECT tbsp_id, container_id, container_name, container_type 
FROM TABLE(SYSPROC.MON_GET_CONTAINER('', NULL));

--  /*****************************************************************/
--  /* 4. How to get container info for a particular tablespace         */
--  /*****************************************************************/

-- Get information for all containers of tablespace 'USERSPACE1' of ('-1')
-- current database member using table function SYSPROC.MON_GET_CONTAINER. 

SELECT tbsp_id, container_id, container_name, container_type 
  FROM TABLE(SYSPROC.MON_GET_CONTAINER('USERSPACE1', -1));

-- Disconnect from the database
CONNECT RESET;

