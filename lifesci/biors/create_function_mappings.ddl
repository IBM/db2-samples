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
--              Function template declarations for BioRS wrapper
--              custom functions.
--
-- Operating System: All
--
-------------------------------------------------------------------------------

-- DROP FUNCTION biors.contains (varchar(), varchar()) ;
-- DROP FUNCTION biors.contains (varchar(), char()) ;
-- DROP FUNCTION biors.contains (varchar(), date) ;
-- DROP FUNCTION biors.contains (varchar(), timestamp) ;
-- DROP FUNCTION biors.contains (varchar(), integer) ;
-- DROP FUNCTION biors.contains (varchar(), smallint) ;
-- DROP FUNCTION biors.contains (varchar(), bigint) ;
-- DROP FUNCTION biors.contains (varchar(), decimal) ;
-- DROP FUNCTION biors.contains (varchar(), double) ;
-- DROP FUNCTION biors.contains (varchar(), real) ;
-- DROP FUNCTION biors.contains (char(), varchar()) ;
-- DROP FUNCTION biors.contains (char(), char()) ;
-- DROP FUNCTION biors.contains (char(), date) ;
-- DROP FUNCTION biors.contains (char(), timestamp) ;
-- DROP FUNCTION biors.contains (char(), integer) ;
-- DROP FUNCTION biors.contains (char(), smallint) ;
-- DROP FUNCTION biors.contains (char(), bigint) ;
-- DROP FUNCTION biors.contains (char(), decimal) ;
-- DROP FUNCTION biors.contains (char(), double) ;
-- DROP FUNCTION biors.contains (char(), real) ;
-- DROP FUNCTION biors.contains (clob, varchar()) ;
-- DROP FUNCTION biors.contains (clob, char()) ;
-- DROP FUNCTION biors.contains (clob, date) ;
-- DROP FUNCTION biors.contains (clob, timestamp) ;
-- DROP FUNCTION biors.contains (clob, integer) ;
-- DROP FUNCTION biors.contains (clob, smallint) ;
-- DROP FUNCTION biors.contains (clob, bigint) ;
-- DROP FUNCTION biors.contains (clob, decimal) ;
-- DROP FUNCTION biors.contains (clob, double) ;
-- DROP FUNCTION biors.contains (clob, real) ;

CREATE FUNCTION biors.contains (varchar(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (varchar(), real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (char(), real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains (clob, real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;

-- DROP FUNCTION biors.contains_le (varchar(), varchar()) ;
-- DROP FUNCTION biors.contains_le (varchar(), char()) ;
-- DROP FUNCTION biors.contains_le (varchar(), date) ;
-- DROP FUNCTION biors.contains_le (varchar(), timestamp) ;
-- DROP FUNCTION biors.contains_le (varchar(), integer) ;
-- DROP FUNCTION biors.contains_le (varchar(), smallint) ;
-- DROP FUNCTION biors.contains_le (varchar(), bigint) ;
-- DROP FUNCTION biors.contains_le (varchar(), decimal) ;
-- DROP FUNCTION biors.contains_le (varchar(), double) ;
-- DROP FUNCTION biors.contains_le (varchar(), real) ;
-- DROP FUNCTION biors.contains_le (char(), varchar()) ;
-- DROP FUNCTION biors.contains_le (char(), char()) ;
-- DROP FUNCTION biors.contains_le (char(), date) ;
-- DROP FUNCTION biors.contains_le (char(), timestamp) ;
-- DROP FUNCTION biors.contains_le (char(), integer) ;
-- DROP FUNCTION biors.contains_le (char(), smallint) ;
-- DROP FUNCTION biors.contains_le (char(), bigint) ;
-- DROP FUNCTION biors.contains_le (char(), decimal) ;
-- DROP FUNCTION biors.contains_le (char(), double) ;
-- DROP FUNCTION biors.contains_le (char(), real) ;
-- DROP FUNCTION biors.contains_le (clob, varchar()) ;
-- DROP FUNCTION biors.contains_le (clob, char()) ;
-- DROP FUNCTION biors.contains_le (clob, date) ;
-- DROP FUNCTION biors.contains_le (clob, timestamp) ;
-- DROP FUNCTION biors.contains_le (clob, integer) ;
-- DROP FUNCTION biors.contains_le (clob, smallint) ;
-- DROP FUNCTION biors.contains_le (clob, bigint) ;
-- DROP FUNCTION biors.contains_le (clob, decimal) ;
-- DROP FUNCTION biors.contains_le (clob, double) ;
-- DROP FUNCTION biors.contains_le (clob, real) ;

CREATE FUNCTION biors.contains_le (varchar(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (varchar(), real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (char(), real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_le (clob, real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;

-- DROP FUNCTION biors.contains_ge (varchar(), varchar()) ;
-- DROP FUNCTION biors.contains_ge (varchar(), char()) ;
-- DROP FUNCTION biors.contains_ge (varchar(), date) ;
-- DROP FUNCTION biors.contains_ge (varchar(), timestamp) ;
-- DROP FUNCTION biors.contains_ge (varchar(), integer) ;
-- DROP FUNCTION biors.contains_ge (varchar(), smallint) ;
-- DROP FUNCTION biors.contains_ge (varchar(), bigint) ;
-- DROP FUNCTION biors.contains_ge (varchar(), decimal) ;
-- DROP FUNCTION biors.contains_ge (varchar(), double) ;
-- DROP FUNCTION biors.contains_ge (varchar(), real) ;
-- DROP FUNCTION biors.contains_ge (char(), varchar()) ;
-- DROP FUNCTION biors.contains_ge (char(), char()) ;
-- DROP FUNCTION biors.contains_ge (char(), date) ;
-- DROP FUNCTION biors.contains_ge (char(), timestamp) ;
-- DROP FUNCTION biors.contains_ge (char(), integer) ;
-- DROP FUNCTION biors.contains_ge (char(), smallint) ;
-- DROP FUNCTION biors.contains_ge (char(), bigint) ;
-- DROP FUNCTION biors.contains_ge (char(), decimal) ;
-- DROP FUNCTION biors.contains_ge (char(), double) ;
-- DROP FUNCTION biors.contains_ge (char(), real) ;
-- DROP FUNCTION biors.contains_ge (clob, varchar()) ;
-- DROP FUNCTION biors.contains_ge (clob, char()) ;
-- DROP FUNCTION biors.contains_ge (clob, date) ;
-- DROP FUNCTION biors.contains_ge (clob, timestamp) ;
-- DROP FUNCTION biors.contains_ge (clob, integer) ;
-- DROP FUNCTION biors.contains_ge (clob, smallint) ;
-- DROP FUNCTION biors.contains_ge (clob, bigint) ;
-- DROP FUNCTION biors.contains_ge (clob, decimal) ;
-- DROP FUNCTION biors.contains_ge (clob, double) ;
-- DROP FUNCTION biors.contains_ge (clob, real) ;

CREATE FUNCTION biors.contains_ge (varchar(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (varchar(), real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (char(), real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, date) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, timestamp) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, integer) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, smallint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, bigint) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, decimal) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, double) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.contains_ge (clob, real) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;

-- DROP FUNCTION biors.search_term (varchar(), varchar()) ;
-- DROP FUNCTION biors.search_term (varchar(), char()) ;
-- DROP FUNCTION biors.search_term (char(), varchar ()) ;
-- DROP FUNCTION biors.search_term (char(), char ()) ;

CREATE FUNCTION biors.search_term (varchar(), varchar()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.search_term (varchar(), char()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.search_term (char(), varchar ()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
CREATE FUNCTION biors.search_term (char(), char ()) RETURNS INTEGER AS TEMPLATE DETERMINISTIC NO EXTERNAL ACTION;
