--/****************************************************************************
-- (c) Copyright IBM Corp. 2009 All rights reserved.
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
-- SAMPLE FILE NAME: datecompat.db2
--
-- PURPOSE: To demonstrate date compatibility features such as:
--
--             1. The DATE type is interpreted as the TIMESTAMP(0) type.
--             2. Date formats DD-MON-RR & DD-MON-YYYY are supported.
--             3. DATE addition and subtraction produce a different result type.
--             4. Show examples of using the DATE type with the following scalar
--                functions.  Note that some results are not exclusive to date
--                compatibility mode.
--                    a.   NEXT_DAY
--                    b.   LAST_DAY
--                    c.   ADD_MONTHS
--                    d.   EXTRACT
--                    e.   MONTHS_BETWEEN
--
--
-- PREREQUISITE: Create the database in DB2 DATE compatibility mode.
--                To do this, follow these steps.
--
--                1. Set the compatibility registry variable to 50.
--                    db2set DB2_COMPATIBILITY_VECTOR=50;
--
--                2. Restart the database manager
--                    db2stop;
--                    db2start;
--
--                3. Create the database by this sample.
--                    db2 "CREATE DB testdb";
--
--                 The number 50 represents the following compatibility
--                 features (10 + 40):
--                 10 - Enables number compatibility mode.  The subset
--                      of number compat mode used in this sample is
--                      for expressions such as 1/24 and 1/24/60/60 to
--                      be calculated using DECFLOAT division instead
--                      of INTEGER division. Using INTEGER division,
--                      both expressions would result in 0.
--                 40 - Enables date compatibility mode.  This sample
--                      illustrates some of differences introduced by
--                      this mode.  For example, the DATE data type is
--                      interpreted as the TIMESTAMP(0) data type in
--                      this mode.
--
-- EXECUTION       : db2 -tvf datecompat.db2
--
-- INPUTS          : NONE
--
-- OUTPUT          : Result of all the functionalities.
--
-- OUTPUT FILE     : datecompat.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                DESCRIBE
--                VALUES
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
-- SAMPLE DESCRIPTION
--
-- *************************************************************************
--
--  1. The DATE type is interpreted as the TIMESTAMP(0) type.
--  2. Date formats DD-MON-RR & DD-MON-YYYY are supported.
--  3. DATE addition and subtraction produce a different result type.
--  4. Show examples of using the DATE type with some scalar functions.
--
-- *************************************************************************/


--  /*****************************************************************/
--  /* Setup                                                         */
--  /*****************************************************************/

-- follow the steps in PREREQUISITES section to create the database

-- connect to database
CONNECT TO testdb;

--  /*****************************************************************/
--  /* DATE as TIMESTAMP(0) type in date compatibility mode          */
--  /*****************************************************************/

-- The following will return the same result type, TIMESTAMP, with
-- length 19.
DESCRIBE VALUES (CURRENT DATE, SYSDATE, CURRENT TIMESTAMP(0));

-- The following three values will return the same result since they are
-- equivalent.  CURRENT DATE returns CURRENT_TIMESTAMP(0) in date
-- compatibility mode.  SYSDATE is a synonym for CURRENT TIMESTAMP(0),
-- with or without date compatibility.
VALUES (CURRENT DATE, SYSDATE, CURRENT TIMESTAMP(0));

-- The DATE function returns a TIMESTAMP(0) result in date compatibility
-- mode.
VALUES DATE('11/14/2008');
VALUES (CURRENT TIMESTAMP, DATE(CURRENT TIMESTAMP));

--  /*****************************************************************/
--  /*  Support for new DD-MON-RR & DD-MON-YYYY date formats         */
--  /*****************************************************************/

-- Date format DD-MON-RR is supported in date compatibility mode.
VALUES DATE('12-JAN-09');
VALUES DATE('12-jan-09');

-- Date format DD-MON-YYYY is supported in date compatibility mode.
VALUES DATE('28-feb-2014');
VALUES DATE('28-Feb-2014');

--  /*****************************************************************/
--  /*  DATE Addition                                                */
--  /*****************************************************************/

-- Add INTEGER, DECIMAL, and DECFLOAT values to DATE.

-- In date compatibility mode, a number added to a DATE is implicitly
-- interpreted as adding a number of days.  Therefore, CURRENT_DATE + 2 DAYS
-- and CURRENT_DATE + 2 will both add 2 days to CURRENT DATE.
VALUES (CURRENT_DATE, CURRENT_DATE + 2 DAYS, CURRENT_DATE + 2);

-- Fractional days can be added to a DATE in date compatibility mode.
-- Adding 2.3 days results in adding 2 days, 7 hours, and 12 minutes
-- to current date.
VALUES(SYSDATE, SYSDATE + 2.3);

-- Add an hour to current date.  The database must be in number compatibility
-- mode in order for 1/24 to be a non-zero result (DECFLOAT vs INTEGER
-- division).
VALUES(SYSDATE, SYSDATE + 1/24);

-- Add a second to current date.
VALUES(SYSDATE, SYSDATE + 1/24/60/60);

-- Add a second to a TIMESTAMP using the DECFLOAT representation of
-- a second, 1/24/60/60.
VALUES (TIMESTAMP('2008-08-08-10.11.12',12),
        1/24/60/60,
        TIMESTAMP('2008-08-08-10.11.12',12) + DECFLOAT(0.000011574074074074074074074074));

--  /*****************************************************************/
--  /*  DATE Subtraction                                             */
--  /*****************************************************************/

-- Subtract INTEGER, DECIMAL, DATE and DECFLOAT values from DATE.

-- Subtract 2 days from CURRENT DATE.
VALUES (CURRENT_DATE, CURRENT_DATE - 2);

-- Subtract 2.3 days from curretn date.  This results in subtracting 2 days, 7 hours,
-- and 12 minutes from current date.
VALUES (SYSDATE, SYSDATE - 2.3);

-- Subtract an hour from current date.  The database must be in number
-- compatibility mode in order for 1/24 to be a non-zero result (DECFLOAT vs
-- INTEGER division).
VALUES (SYSDATE, SYSDATE - 1/24);

-- Subtract a second from current date.
VALUES (SYSDATE, SYSDATE - 1/24/60/60);

-- The result of DATE subtraction is a DECFLOAT which can be added back to
-- the second date in order to obtain the first date.  This DECFLOAT result
-- represents 1 day, 5 hours, 1 minute, and 11 seconds.
VALUES (DATE('2009-08-08-10.11.12') - DATE('2009-08-07-05.10.01'),
        DATE('2009-08-07-05.10.01') + DECFLOAT(1.209155092592592592592592592592));

-- Subtract a second from a TIMESTAMP using the DECFLOAT representation of
-- a second, 1/24/60/60.
VALUES (TIMESTAMP('2008-08-08-10.11.12',12),
        1/24/60/60,
        TIMESTAMP('2008-08-08-10.11.12',12) - DECFLOAT(0.000011574074074074074074074074));

-- The following will result in zero since the two values are equivalent.
VALUES DATE('08-AUG-2008') - TIMESTAMP('2008-08-08-00.00.00');

--  /*****************************************************************/
--  /*  NEXT_DAY                                                     */
--  /*****************************************************************/

-- NEXT_DAY advances the input date to the next day specified by the
-- second argument.
VALUES NEXT_DAY(DATE '2008-04-24', 'TUESDAY');
VALUES NEXT_DAY('2008-02-29', 'fri');
VALUES(SYSDATE, NEXT_DAY(SYSDATE, 'TUE'));

--  /*****************************************************************/
--  /*  LAST_DAY                                                     */
--  /*****************************************************************/

-- LAST_DAY returns the last day of the month indicated by the input date.
VALUES (SYSDATE, LAST_DAY(SYSDATE));
VALUES LAST_DAY('2008-02-28');

--  /*****************************************************************/
--  /*  ADD_MONTHS                                                   */
--  /*****************************************************************/

-- ADD_MONTHS adds the specified number of months to the input date.
VALUES (SYSDATE, ADD_MONTHS(LAST_DAY(SYSDATE), 1));
VALUES ADD_MONTHS('2008-02-29', 4);

--  /*****************************************************************/
--  /*  EXTRACT                                                      */
--  /*****************************************************************/

-- EXTRACT returns a portion of the input datetime value based on its
-- arguments.  EXTRACT is an alternative syntax for the YEAR, MONTH, DAY,
-- HOUR, MINUTE, and SECOND functions.
VALUES (SYSDATE, EXTRACT(YEAR FROM SYSDATE),   YEAR(SYSDATE));
VALUES (SYSDATE, EXTRACT(MONTH FROM SYSDATE),  MONTH(SYSDATE));
VALUES (SYSDATE, EXTRACT(DAY FROM SYSDATE),    DAY(SYSDATE));
VALUES (SYSDATE, EXTRACT(HOUR FROM SYSDATE),   HOUR(SYSDATE));
VALUES (SYSDATE, EXTRACT(MINUTE FROM SYSDATE), MINUTE(SYSDATE));
VALUES (SYSDATE, EXTRACT(SECOND FROM SYSDATE), SECOND(SYSDATE));

--  /*****************************************************************/
--  /*  MONTHS_BETWEEN                                               */
--  /*****************************************************************/

-- MONTHS_BETWEEN returns an estimate of the number of months between
-- two datetime arguments.

-- The assumption of 31 days per month is used in this example.
VALUES (MONTHS_BETWEEN('2005-02-02', '2005-01-01'), 32/31);

-- The result is 0 since the dates are the same.
VALUES MONTHS_BETWEEN('2008-03-29', '2008-03-29');

-- The result is a whole number since both days are the last day of their
-- respective month.
VALUES MONTHS_BETWEEN('2008-03-31', '2008-02-29');

-- Two days difference.
VALUES (MONTHS_BETWEEN('2008-03-31', '2008-03-29'), 2/31);

-- The difference in the time components is reflected in the result.
VALUES MONTHS_BETWEEN('2007-11-01-09.00.00.00000', '2007-12-07-14.30.12.12345');

-- The time portions are ignored since the day of the month is the same.
VALUES MONTHS_BETWEEN('2007-12-13-09.40.30.00000', '2007-11-13-08.40.30.00000');

-- The difference is 12 hours which is half a day = 0.5/31 months.
VALUES (MONTHS_BETWEEN('2008-02-29', '2008-02-28-12.00.00'), 12/24/31);

-- Disconnect from the database.
CONNECT RESET;

