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
-- SAMPLE FILE NAME: scalarfunction.db2
--
-- PURPOSE         : To demonstrate how to use the following scalar functions and
--                   the special register. 
--                 1. INITCAP  
--                 2. LPAD
--                 3. RPAD
--                 4. TO_CLOB
--                 5. TO_DATE 
--                 6. TO_CHAR
--                 7. TO_NUMBER
--                 8. DAYNAME
--                 9. MONTHNAME
--                10. INSTR
--                11. TIMESTAMP_FORMAT
--                12. TO_TIMESTAMP
--                13. LOCATE_IN_STRING
--                14. CURRENT LOCALE LC_TIME Register
--                15. TRUNC  
--                16. ROUND
--                17. TRUNC_TIMESTAMP
--                18. ROUND_TIMESTAMP
--                19. VARCHAR_FORMAT
--                20. ADD_MONTHS
--                21. LAST_DAY

--
-- PREREQUISITE    : Sample must be executed using a 1208 code page.
--	
-- EXECUTION       : db2set DB2CODEPAGE=1208 (Set the client code page to 1208)
--                 : db2 terminate
--                 : db2stop
--                 : db2start
--                 : db2 -tvf scalarfunction.db2
--                   
-- INPUTS          : NONE
--
-- OUTPUT          : Successful execution of all scalar functions
--
-- OUTPUT FILE     : scalarfunction.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--			CREATE TABLE          	
--			INSERT
--		 	SELECT
--		 	TRUNCATE TABLE
--			DROP TABLE
--
-- OUTPUT FILE: scalarfunction.out (available in the online documentation)
--
-- *************************************************************************
--
--  SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
--  1. Use of INITCAP Scalar Function. 
--  2. Use of INITCAP Scalar Function with accented characters.
--  3. Use of LPAD Scalar Function.
--  4. Use of RPAD Scalar Function.
--  5. Use of TO_CLOB Scalar Function.
--  6. Use of TRUNC and TRUNCATE Scalar Function with numeric value.
--  7. Use of TRUNC and TRUNCATE Scalar Function with datetime value.
--  8. Use of ROUND Scalar Function with numeric value.
--  9. Use of ROUND Scalar Function with datetime value.
-- 10. Use of TRUNC_TIMESTAMP Scalar Function with datetime value.
-- 11. Use of ROUND_TIMESTAMP Scalar Function with datetime value.
-- 12. Use of TO_DATE Scalar Function.
-- 13. Use of TIMESTAMP_FORMAT Scalar Function.
-- 14. Use of TO_TIMESTAMP Scalar Function.
-- 15. Use of TO_CHAR Scalar Function.
-- 16. Use of DAYNAME Scalar Function.
-- 17. Use of MONTHNAME Scalar Function.
-- 18. Use of INSTR Scalar Function.
-- 19. Use of LOCATE_IN_STRING Scalar Function.
-- 20. Use of CURRENT LOCALE LC_TIME register with TO_CHAR Scalar Function.
-- 21. Use of CURRENT LOCALE LC_TIME register with TO_DATE Scalar Function.
-- 22. Use of LAST_DAY Scalar Function.
-- 23. Use of ADD_MONTHS Scalar Function.
-- 24. Use of TO_NUMBER Scalar Function.
-- *************************************************************************/

-- Connect to sample database
CONNECT TO sample;

-- Create table temp_table
CREATE TABLE temp_table(rowno INTEGER, tempdata VARCHAR(30),
format VARCHAR(15));

-- Create table temp_timestamp
CREATE TABLE temp_timestamp(col TIMESTAMP);

-- Create table stockprice to store decfloat values
create table stockprice (stock_id INTEGER, stock DECFLOAT(16));


--  /*****************************************************************/
--  /* INITCAP                                                       */
--  /*****************************************************************/

-- Convert the first character of each word to uppercase                              
SELECT INITCAP(Firstnme) FROM employee; 
SELECT INITCAP('THEODORE Q SPENSER is manager') FROM sysibm.sysdummy1;

-- INITCAP handles accented characters
SELECT INITCAP('my name is élizãbeth ñatz') FROM sysibm.sysdummy1;

--  /*****************************************************************/
--  /* LPAD                                                          */
--  /*****************************************************************/

-- Make a string of certain length by adding (padding) a specified 
-- character to the left
SELECT LPAD(Lastname, 10,'*') AS LastName FROM employee;

--  /*****************************************************************/
--  /* RPAD                                                          */
--  /*****************************************************************/

-- Make a string of certain length by adding (padding) a specified 
-- character to the right
SELECT RPAD(Firstnme, 20, '.') FROM employee;

--  /*****************************************************************/
--  /* TO_CLOB                                                       */
--  /*****************************************************************/

-- Represent a character string as CLOB type
SELECT TO_CLOB(Job) FROM employee;


--  /*****************************************************************/
--  /* TRUNC and TRUNCATE numeric value                              */
--  /*****************************************************************/

-- Select average salary from the employee table
SELECT AVG(SALARY) FROM employee;

-- Select average salary and truncate 5 places to the right of the
-- decimal point
SELECT TRUNCATE((AVG(SALARY)), 5) FROM employee;

-- Select average salary and truncate 2 places to the left of the
-- decimal point
SELECT TRUNC((AVG(SALARY)), -2) FROM employee;

-- If no argument is passed, the default value 0 is set
SELECT TRUNCATE(AVG(SALARY)) FROM employee;


--  /*****************************************************************/
--  /* TRUNC and TRUNCATE datetime value                             */
--  /*****************************************************************/

-- Select rows from the in_tray table
SELECT received FROM in_tray;

-- Truncate a DATE and a TIME value based on a format element

SELECT TRUNC(DATE(received), 'MONTH') FROM in_tray;
SELECT TRUNCATE(DATE(received), 'DAY') FROM in_tray;
SELECT TRUNCATE(DATE(received), 'YEAR') FROM in_tray;
SELECT TRUNC(DATE(received), 'CC') FROM in_tray;
SELECT TRUNC(DATE(received), 'Q') FROM in_tray;
SELECT TRUNCATE(DATE(received), 'I') FROM in_tray;
SELECT TRUNC(TIME(received), 'HH') FROM in_tray;
SELECT TRUNC(TIME(received), 'MI') FROM in_tray;
SELECT TRUNC(TIME(received), 'SS') FROM in_tray;

-- Truncate a DATE value based on a format element and a locale

SELECT TRUNCATE(DATE(received), 'DAY', 'ja_JP') FROM in_tray;
SELECT TRUNCATE(DATE(received), 'D', 'fr_FR') FROM in_tray;



--  /*****************************************************************/
--  /* ROUND numeric value                                           */
--  /*****************************************************************/

-- Select average salary
SELECT AVG(SALARY) FROM employee;

-- Select average salary and round 5 places to the right of the
-- decimal point
SELECT ROUND((AVG(SALARY)), 5) FROM employee;

-- Select average salary and round 2 places to the right of the
-- decimal point
SELECT ROUND((AVG(SALARY)), -2) FROM employee;

-- if no argument is passed, the default value 0 is set
SELECT ROUND(AVG(SALARY)) FROM employee;


--  /*****************************************************************/
--  /* ROUND datetime value                                          */
--  /*****************************************************************/

-- Round a DATE and a TIME value based on a format element

SELECT DATE(received) FROM in_tray;
SELECT ROUND(DATE(received), 'MON') FROM in_tray;
SELECT ROUND(DATE(received), 'D') FROM in_tray;
SELECT ROUND(DATE(received), 'Y') FROM in_tray;
SELECT ROUND(DATE(received), 'WW') FROM in_tray;

SELECT TIME(received) FROM in_tray;
SELECT ROUND(TIME(received), 'HH') FROM in_tray;
SELECT ROUND(TIME(received), 'MI') FROM in_tray;


-- ROUND a DATE value based on a format element and a locale

SELECT ROUND(DATE(received), 'DAY', 'zh_CN') FROM in_tray;
SELECT ROUND(DATE(received), 'D', 'fr_FR') FROM in_tray;



--  /*****************************************************************/
--  /* TRUNC_TIMESTAMP TIMESTAMP value                               */
--  /*****************************************************************/

-- Truncate TIMESTAMP value based on a format element

SELECT TRUNC_TIMESTAMP(received, 'D') FROM in_tray;
SELECT TRUNC_TIMESTAMP('1988-12-22-14.07.21.136421', 'MONTH') FROM sysibm.sysdummy1;
SELECT TRUNC_TIMESTAMP('1988-12-25-17.12.30.000000', 'YEAR') FROM sysibm.sysdummy1;
SELECT TRUNC_TIMESTAMP('1988-12-25', 'CC') FROM sysibm.sysdummy1;
SELECT TRUNC_TIMESTAMP('1988-12-23', 'Q') FROM sysibm.sysdummy1;
SELECT TRUNC_TIMESTAMP('1988-12-25-17.12.30.000000', 'I') FROM sysibm.sysdummy1;
SELECT TRUNC_TIMESTAMP('1988-12-22-14.07.21.136421', 'DAY', 'es_ES') 
FROM sysibm.sysdummy1;


--  /*****************************************************************/
--  /* ROUND_TIMESTAMP TIMESTAMP value                               */
--  /*****************************************************************/

--  ROUND a TIMESTAMP value based on a format string

SELECT ROUND_TIMESTAMP('1988-12-22-14.07.21.136421', 'HH') FROM sysibm.sysdummy1;
SELECT ROUND_TIMESTAMP('1988-12-22-14.07.21.136421', 'MM') from sysibm.sysdummy1;


--  /*****************************************************************/
--  /* LOCATE_IN_STRING and INSTR                                    */
--  /* Returns the starting position of the first occurrence of      */
--  /* search string within another source string.                   */
--  /*****************************************************************/

-- Locate character "ß" in the given string starting from position 1

SELECT LOCATE_IN_STRING('Jürgen lives on Hegelstraße','ß',1,CODEUNITS32) 
FROM sysibm.sysdummy1;

-- Locate string "position" in the given string.

SELECT LOCATE_IN_STRING('The INSTR function returns the starting
position of the first occurrence of one string within another string',
'position',1, OCTETS) FROM sysibm.sysdummy1;

-- Locate the fourth occurrence of character "f" in the given string

SELECT INSTR('The INSTR function returns the starting position of the
first occurrence of one string within another string', 
'f',1, 4, OCTETS) FROM sysibm.sysdummy1;

-- Locate the second occurrence of "string" by searching from the 
-- end of the given string

SELECT INSTR('The INSTR function returns the starting position of the
first occurrence of one string within another string', 
'string', -1, 2, OCTETS) FROM sysibm.sysdummy1;



--  /*****************************************************************/
--  /* TO_DATE                                                       */
--  /*****************************************************************/

-- Represent character string as a TIMESTAMP 
-- Demonstrate different format elements of TO_DATE function

-- Insert data into temp_table
INSERT INTO temp_table VALUES (1,'1999-12-31.23:59:59', NULL);

SELECT TO_DATE(tempdata, 'YYYY-MM-DD HH24:MI:SS') FROM temp_table;

-- Insert data into temp_table
INSERT INTO temp_table VALUES (2,'1999-12-31', 'YYYY-MM-DD');

SELECT TO_DATE(tempdata, format) FROM temp_table 
WHERE rowno = 2;

-- Insert data into temp_table
INSERT INTO temp_table VALUES (3,'1999-DEC-31', NULL);

SELECT TO_DATE(tempdata, 'YYYY-MON-DD', 'CLDR 1.5:en_US' ) FROM temp_table
WHERE rowno = 3;


--  /*****************************************************************/
--  /* TIMESTAMP_FORMAT and TO_TIMESTAMP                             */
--  /*****************************************************************/

-- Insert TIMESTAMP value in different formats.
INSERT INTO temp_timestamp VALUES (TIMESTAMP_FORMAT
('1999-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO temp_timestamp VALUES (TIMESTAMP_FORMAT
((SELECT tempdata FROM temp_table WHERE rowno = 2), 'YYYY-MM-DD', 9));
INSERT INTO temp_timestamp VALUES (TO_TIMESTAMP
('1999-12-31 23:59:59:796000', 'YYYY-MM-DD HH24:MI:SS:NNNNNN', 'CLDR 1.5:en_US', 10));
INSERT INTO temp_timestamp VALUES (TO_TIMESTAMP
((SELECT tempdata FROM temp_table WHERE rowno = 3), 'YYYY-MON-DD', 
'CLDR 1.5:en_US'));

-- Fetch rows from temp_timestamp table.
SELECT * FROM temp_timestamp;

--  /*****************************************************************/
--  /* TO_CHAR and VARCHAR_FORMAT                                    */
--  /* 1) TIMESTAMP to VARCHAR representation                        */
--  /* 2) DECIMAL floating point to VARCHAR representation           */
--  /*****************************************************************/

-- TIMESTAMP to VARCHAR representation:

-- Show tablename and its creation time as a String where tablename
-- starts with 'empl'

SELECT VARCHAR(TABNAME, 20) AS Table_Name, TO_CHAR(CREATE_TIME, 
'YYYY-MM-DD HH24:MI:SS') AS Creation_Time FROM SYSCAT.TABLES 
WHERE TABNAME LIKE 'EMPL%';

-- Demonstrate different format elements of a DATE and a TIMESTAMP
-- values with TO_CHAR function
SELECT TO_CHAR( received ) FROM in_tray;
SELECT TO_CHAR( received, 'FF9') FROM in_tray;
SELECT TO_CHAR( received, 'FF12') FROM in_tray;
SELECT TO_CHAR( received, 'MON', 'de_DE') FROM in_tray;
SELECT TO_CHAR( received, 'MONTH') from in_tray;
SELECT TO_CHAR( received, 'Dy') FROM in_tray;
SELECT TO_CHAR( received, 'DD-YYYY-Month-Day' ) FROM in_tray;
SELECT TO_CHAR( received, 'DD-YYYY-MONTH-Day' ) FROM in_tray;
SELECT TO_CHAR( received, 'DD-YYYY-MONTH-DAY' ) FROM in_tray;
SELECT TO_CHAR( received, 'YYYY-MONTH-DD' ) FROM in_tray;
SELECT TO_CHAR( received, 'YYYY-Month-DAY-DD') FROM in_tray;
SELECT TO_CHAR( received, 'DD-YYYY-mon-dy HH-MM-SS' ) FROM in_tray;
SELECT TO_CHAR( received, 'Dy-YYYY-MON-DD HH12-MM-SS' ) FROM in_tray;
SELECT TO_CHAR( received, 'D-YYYY-Mon-DAY-DD HH12-MI-SS' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'DAY-YYYY-Month-DD HH12-MM-SS' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'Day-YYYY-Month-DD HH24-MM-SS' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'DAY-YYYY-Month-DD HH12-MM-SS PM' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'DD-YYYY-MONTH-DAY HH24-MM-SS P.M.' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'DAY-YYYY-MONTH-DD HH12-MM-SS AM' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'DD-YYYY-Month-day HH12-MM-SS A.M.' ) FROM in_tray;
SELECT VARCHAR_FORMAT( received, 'DD-YYYY/MON/DAY', 'en_US' ) FROM in_tray;
SELECT VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'MON','de_DE') FROM sysibm.sysdummy1;
SELECT VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'MON','zh_CN') FROM sysibm.sysdummy1;
SELECT VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'DAY','de_DE') FROM sysibm.sysdummy1;


-- DECIMAL floating point to VARCHAR representation:

-- Insert data into stockprice table
INSERT INTO stockprice VALUES (1, 1556.69);
INSERT INTO stockprice VALUES (2, -1556.69);

-- VARCHAR representation of stock column in stockprice table
SELECT VARCHAR_FORMAT(stock, '9999.99') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, '99999.99') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, '00000.00') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, '9999.99MI') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, 'S9999.99') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, '9999.99PR') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, 'S$9,999.99') FROM stockprice WHERE stock_id=1;
SELECT VARCHAR_FORMAT(stock, '9999.99') FROM stockprice WHERE stock_id=2;
SELECT VARCHAR_FORMAT(stock, '99999.99') FROM stockprice WHERE stock_id=2;
SELECT VARCHAR_FORMAT(stock, '00000.00') FROM stockprice WHERE stock_id=2;
SELECT VARCHAR_FORMAT(stock, '9999.99MI') FROM stockprice WHERE stock_id=2;
SELECT VARCHAR_FORMAT(stock, 'S9999.99') FROM stockprice WHERE stock_id=2;
SELECT VARCHAR_FORMAT(stock, '9999.99PR') FROM stockprice WHERE stock_id=2;
SELECT VARCHAR_FORMAT(stock, 'S$9,999.99') FROM stockprice WHERE stock_id=2;



--  /*****************************************************************/
--  /* DAYNAME                                                       */
--  /*****************************************************************/

-- Present dayname in the French locale
SELECT DAYNAME(received, 'CLDR 1.5:fr_FR') FROM in_tray;

-- Present dayname in the Chinese locale
SELECT DAYNAME(received, 'CLDR 1.5:zh_CN') FROM in_tray;

-- Present dayname in the Japanese locale
SELECT DAYNAME(received, 'CLDR 1.5:ja_JP') FROM in_tray;

-- Present dayname in the German locale
SELECT DAYNAME(received, 'CLDR 1.5:de_DE') FROM in_tray;


--  /*****************************************************************/
--  /* MONTHNAME                                                     */
--  /*****************************************************************/

-- Present Monthname in the Spanish locale
SELECT MONTHNAME(received, 'CLDR 1.5:es_ES') FROM in_tray;

-- Present Monthname in the Italian locale
SELECT MONTHNAME(received, 'CLDR 1.5:it_IT') FROM in_tray;

-- Present Monthname in the Japanese locale
SELECT MONTHNAME(received, 'CLDR 1.5:ja_JP') FROM in_tray;

-- Present Monthname in the German locale
SELECT MONTHNAME(received, 'CLDR 1.5:de_DE') FROM in_tray;


--  /*****************************************************************/
--  /* CURRENT LOCALE LC_TIME                                        */
--  /* Use of CURRENT LOCALE LC_TIME with TO_CHAR Scalar Function.   */
--  /*****************************************************************/

-- Use of the special register CURRENT LOCALE LC_TIME 

-- Present a TIMESTAMP value in the French locale

SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR';
SELECT TO_CHAR(received) FROM in_tray;

-- Present a TIMESTAMP value in the Japanese locale

SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:ja_JP';
SELECT TO_CHAR(received) FROM in_tray;

-- Present a TIMESTAMP value in the Chinese locale.

SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:zh_CN';
SELECT TO_CHAR(received) FROM in_tray;


--  /*****************************************************************/
--  /* CURRENT LOCALE LC_TIME                                        */
--  /* Use of CURRENT LOCALE LC_TIME with TO_DATE Scalar Function.   */
--  /*****************************************************************/

-- Present a DATE value in the French locale

-- SET CURRENT LOCALE 
SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR';

-- Insert into temp_table 
INSERT INTO temp_table VALUES (5,'1999-DÉC.-31', 'YYYY-MON-DD');

SELECT TO_DATE(tempdata, format)FROM temp_table WHERE rowno = 5;


-- Present a DATE value in the English locale

-- SET CURRENT LOCALE 
SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:en_US';

-- Insert into temp_table 
INSERT INTO temp_table VALUES (4,'1999-DEC-31', 'YYYY-MON-DD');

SELECT TO_DATE(tempdata, format)FROM temp_table WHERE rowno = 4;


--  /*****************************************************************/
--  /* CURRENT LOCALE LC_TIME                                        */
--  /* Use of CURRENT LOCALE LC_TIME with DAYNAME Scalar Function    */
--  /* MONTHNAME Scalar Function.                                    */
--  /*****************************************************************/

-- Present a Dayname in the French locale

-- SET CURRENT LOCALE 
SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR';
SELECT DAYNAME(received) FROM in_tray;

-- Present Dayname in the Italian locale

-- SET CURRENT LOCALE 
SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:it_IT';
SELECT DAYNAME(received) FROM in_tray;

-- Returns a character string containing the name of the MONTH for the
-- month portion of expression based on the value of LOCALE LC_TIME

-- Present Monthname in the Spanish locale

-- SET CURRENT LOCALE 
SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:es_ES';
SELECT MONTHNAME(received) FROM in_tray;

-- Present Monthname in the German locale

-- SET CURRENT LOCALE 
SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:de_DE';
SELECT MONTHNAME(received) FROM in_tray;


--  /*****************************************************************/
--  /*  LAST_DAY                                                     */
--  /*****************************************************************/

-- Select last day of the month from given argument.

SELECT CURRENT DATE FROM sysibm.sysdummy1;
SELECT LAST_DAY(CURRENT DATE) FROM sysibm.sysdummy1;
SELECT LAST_DAY(DATE(received)) AS lastday FROM in_tray;


--  /*****************************************************************/
--  /*  ADD_MONTHS                                                   */
--  /*****************************************************************/

-- Add number of months in a given argument.

-- Add 6 months in CURRENT DATE
SELECT CURRENT DATE FROM sysibm.sysdummy1;
SELECT ADD_MONTHS(CURRENT DATE, 6) FROM sysibm.sysdummy1;

-- Add 5 months to the received column
SELECT ADD_MONTHS(received, 5) AS new_received FROM in_tray;

-- Subtract 4 months from CURRENT DATE 
SELECT ADD_MONTHS(CURRENT DATE, -4) FROM sysibm.sysdummy1;

-- Subtract 3 months from the received column
SELECT ADD_MONTHS(received, -3) AS new_received FROM in_tray;
  

--  /*****************************************************************/
--  /*  TO_NUMBER                                                    */
--  /*****************************************************************/

-- Show string value in DECFLOAT type format.

-- Each 0 or 9 in the format element represents a digit.
SELECT TO_NUMBER(EmpNo, '999999') AS EmpNo FROM employee;
SELECT TO_NUMBER(EmpNo, '000000') AS EmpNo FROM employee;

-- TRUNCATE all data from table temp_table 

TRUNCATE TABLE temp_table IMMEDIATE;

-- INSERT new data into table temp_table

INSERT INTO temp_table VALUES (1, '123.45', NULL);
INSERT INTO temp_table VALUES (2, '-123456.78', NULL);
INSERT INTO temp_table VALUES (3, '+123456.78', NULL);
INSERT INTO temp_table VALUES (4, '1.23E4', NULL);
INSERT INTO temp_table VALUES (5, '001,234', NULL);
INSERT INTO temp_table VALUES (6, '1234', NULL);
INSERT INTO temp_table VALUES (7, '1234-', NULL);
INSERT INTO temp_table VALUES (8, '+1234', NULL);
INSERT INTO temp_table VALUES (9, '<1234>', NULL);
INSERT INTO temp_table VALUES (10, '123,456.78-', NULL);
INSERT INTO temp_table VALUES (11, '<123,456.78>', NULL);
INSERT INTO temp_table VALUES (12, '$123,456.78', NULL);
INSERT INTO temp_table VALUES (13, '+123,456.78', NULL);

-- List rows from table temp_table
SELECT * FROM temp_table;

-- MI in the format element is to represent the sign of the string
-- If it is a negative number, a trailing minus sign (-) is expected. 
-- If it is a positive number, an optional trailing space is expected.

SELECT TO_NUMBER(tempdata)FROM temp_table WHERE rowno = 1;  
SELECT TO_NUMBER(tempdata)FROM temp_table WHERE rowno = 2;
SELECT TO_NUMBER(tempdata)FROM temp_table WHERE rowno = 3;
SELECT TO_NUMBER(tempdata)FROM temp_table WHERE rowno = 4;
SELECT TO_NUMBER(tempdata,'000,000')FROM temp_table WHERE rowno = 5;
SELECT TO_NUMBER(tempdata,'9999.99')FROM temp_table WHERE rowno = 1;
SELECT TO_NUMBER(tempdata,'9999MI')FROM temp_table WHERE rowno =  6;
SELECT TO_NUMBER(tempdata,'9999MI')FROM temp_table WHERE rowno = 7;
SELECT TO_NUMBER(tempdata,'999999MI')FROM temp_table WHERE rowno = 6; 
SELECT TO_NUMBER(tempdata,'S9999')FROM temp_table WHERE rowno = 8;
SELECT TO_NUMBER(tempdata,'9999PR')FROM temp_table WHERE rowno = 6; 
SELECT TO_NUMBER(tempdata,'9999PR')FROM temp_table WHERE rowno = 9;
SELECT TO_NUMBER(tempdata,'000,000.00MI')FROM temp_table WHERE rowno = 10;
SELECT TO_NUMBER(tempdata,'000,000.00PR')FROM temp_table WHERE rowno = 11;
SELECT TO_NUMBER(tempdata,'$999,999.99')FROM temp_table WHERE rowno = 12;
SELECT TO_NUMBER(tempdata,'$S000,000.00')FROM temp_table WHERE rowno = 12;
SELECT TO_NUMBER(tempdata,'S000,000.00')FROM temp_table WHERE rowno = 13;


-- Drop table temp_table, temp_timestamp, stockprice
DROP TABLE temp_table;
DROP TABLE temp_timestamp;
DROP TABLE stockprice;

-- Disconnect from the database
CONNECT RESET;
