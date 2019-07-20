-------------------------------------------------------------------------------
--
-- Source File Name: create_function_mappings.ddl
--
-- (C) COPYRIGHT International Business Machines Corp. 2002, 2003
-- All Rights Reserved
-- Licensed Materials - Property of IBM
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
--
-- Function = Data Definition Language file containing
--              Function template declarations for Script wrapper
--              custom functions.
--
-- Operating System: All
--
-------------------------------------------------------------------------------

CREATE FUNCTION lsscript.args (varchar(), varchar()) 
   RETURNS INTEGER AS TEMPLATE 
   DETERMINISTIC NO EXTERNAL ACTION;  

CREATE FUNCTION lsscript.args (CLOB(), CLOB()) 
   RETURNS INTEGER AS TEMPLATE 
   DETERMINISTIC NO EXTERNAL ACTION; 

CREATE FUNCTION lsscript.args (double, double) 
   RETURNS INTEGER AS TEMPLATE 
   DETERMINISTIC NO EXTERNAL ACTION; 

CREATE FUNCTION lsscript.args (date, date) 
   RETURNS INTEGER AS TEMPLATE 
   DETERMINISTIC NO EXTERNAL ACTION;

CREATE FUNCTION lsscript.args (integer, integer) 
   RETURNS INTEGER AS TEMPLATE 
   DETERMINISTIC NO EXTERNAL ACTION;
