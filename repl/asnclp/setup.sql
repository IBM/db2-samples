--*******************************************************************--
--  IBM DB2 Q Replication                                            --
--                                                                   --
--     ASNCLP sample files                                           --
--                                                                   --
--     Licensed Materials - Property of IBM                          --
--                                                                   --
--     (C) Copyright IBM Corp. 2004 All Rights Reserved              --
--                                                                   --
--     US Government Users Restricted Rights - Use, duplication      --
--     or disclosure restricted by GSA ADP Schedule Contract         --
--     with IBM Corp.                                                --
--                                                                   --
--*******************************************************************--
--*******************************************************************--
--                                                                   --
--                                                                   --
--           NOTICE TO USERS OF THE SOURCE CODE EXAMPLE              --
--                                                                   --
-- INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE   --
-- CODE EXAMPLE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         --
-- EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO THE IMPLIED   --
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR        --
-- PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE --
-- SOURCE CODE EXAMPLE IS WITH YOU. SHOULD ANY PART OF THE SOURCE    --
-- CODE EXAMPLE PROVES DEFECTIVE, YOU (AND NOT IBM) ASSUME THE       --
-- ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.     --
--                                                                   --
--*******************************************************************--

-- SQL for setting up P2P Database environment for sample scripts.

-- NOTE: It is recommended to run this file before attempting to use the Multidirectional Replication Samples.
-- This script will drop and create the required database and source tables
-- The user must still create the Control Tables
-- For testdb, a pair of Capture and Apply Control tables must created with the schema name BLUE
-- For testdb1, a pair of Capture and Apply Control tables must created with the schema name RED
-- For testdb2, a pair of Capture and Apply Control tables must created with the schema name YELLOW



connect reset;

drop db testdb;
drop db testdb1;
drop db testdb2;

create db testdb;
create db testdb1;
create db testdb2;

connect to testdb;
create table BLUE.AllTypes0(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table BLUE.AllTypes1(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table BLUE.AllTypes2(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table BLUE.AllTypes3(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table BLUE.AllTypes4(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table BLUE.AllTypes5(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
connect reset;

connect to testdb1;
create table RED.AllTypes0(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table RED.AllTypes1(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table RED.AllTypes2(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table RED.AllTypes3(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table RED.AllTypes4(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table RED.AllTypes5(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
connect reset;

connect to testdb2;
create table YELLOW.AllTypes0(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table YELLOW.AllTypes1(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table YELLOW.AllTypes2(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table YELLOW.AllTypes3(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table YELLOW.AllTypes4(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
create table YELLOW.AllTypes5(c1 int, c2 char, c3 bigint not null unique, c4 varchar(1024), c5 DEC(10,10), c6 DATE, c7 TIME, c8 TIMESTAMP, c9 NUM(10,10), c10 NUMERIC(10,10), c11 DEC(10,10));
connect reset;
