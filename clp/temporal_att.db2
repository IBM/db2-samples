-- /***************************************************************************
-- (c) Copyright IBM Corp. 2011 All rights reserved.
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
-- ****************************************************************************
--
-- SOURCE FILE NAME     : temporal_att.db2
--
-- PURPOSE              : This sample demonstrates:
--                          1. Creation of an Application-Period Temporal Table
--                             (ATT)
--                          2. Query an ATT
--                          3. Update records in an ATT
--                          4. Delete records in an ATT
--                          5. Insert records into an ATT
--                          6. Create views over an ATT
--                          7. Usage of the Current Temporal Business_Time 
--                             special register
--
-- EXECUTION            : db2 -tvf temporal_att.db2
--
-- SQL STATEMENTS USED  :
--                CREATE TABLE
--                CREATE VIEW
--                SELECT
--                UPDATE
--                DELETE
--                INSERT
--                DROP VIEW
--                DROP TABLE
--
-- ****************************************************************************
--
-- USAGE SCENARIO  : 
--     The usage scenario pertains to a banking organization. The 
--     database of the bank contains a table called 'loan_accounts' that stores 
--     details of different loan accounts of its customers like type of loan, 
--     rate of interest, balance, etc. The accounts information keeps changing  
--     due to variations in the rate of interest and balance columns causing  
--     the corresponding business validity periods associated with each loan 
--     account to change as well. It is important to manage these time 
--     sensitive changes accurately.
--
-- ****************************************************************************
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
-- ***************************************************************************/


-- Connect to 'sample' database
CONNECT TO sample ;

echo ************************************************************************* ;
echo  CREATE APPLICATION-PERIOD TEMPORAL TABLE (ATT)                           ;
echo                                                                           ;
echo    A application-period temporal table allows you to store time           ;
echo    sensitive application data.                                            ;
echo ************************************************************************* ;
echo                                                                           ;

-- /***************************************************************************
-- Create an application-period temporal table by associating a 'business_time'
-- period specification in the table definition. This value is user-specified 
-- and stores the validity period of each row.
-- ***************************************************************************/

DROP TABLE loan_accounts ;

-- Create APPLICATION-PERIOD TEMPORAL TABLE 'loan_accounts' that contains 
-- details of loan accounts held by customers in the bank.

CREATE TABLE loan_accounts (
  account_number     INTEGER NOT NULL,
  loan_type          VARCHAR(10),
  rate_of_interest   DECIMAL(5,2) NOT NULL,
  balance            DECIMAL (10,2),
  bus_begin          DATE NOT NULL,
  bus_end            DATE NOT NULL,
    PERIOD BUSINESS_TIME(bus_begin, bus_end)
) ;


-- Create an index to check insertion of overlapping business times into the
-- table

CREATE UNIQUE INDEX index_loan 
  ON loan_accounts (account_number, BUSINESS_TIME WITHOUT OVERLAPS) ;

  
-- Insert data into the table

INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, 
                           balance, bus_begin, bus_end)
  VALUES (2111, 'A21', 9.5, 559500, '2009-11-01', '2013-11-01'), 
         (2112, 'A10', 12, 450320, '2010-01-02', '2013-02-02'),  
         (2113, 'A21', 9, 100000, '2010-02-06', '2010-12-30'),
         (2114, 'A15', 10, 200000, '2010-02-07', '2011-08-31') ; 

 
 
echo ************************************************************************ ;
echo  QUERY THE APPLICATION-PERIOD TEMPORAL TABLE                             ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The bank admin needs to query the application-period temporal table to  
--  retrieve details of loan accounts for different periods of time.
--
--  DB2 provides SQL extensions to the SELECT statement to issue queries based 
--  on time.
-- ***************************************************************************/  
  
-- Regular query against the application-period temporal table.

SELECT account_number, loan_type, rate_of_interest, balance, bus_begin, bus_end
  FROM loan_accounts ;

-- Query the outstanding loans as of 1st December, 2011.

-- To query a record for a certain point in time, use the 
-- 'FOR BUSINESS_TIME AS OF' clause in the SELECT statement

SELECT account_number, bus_begin, bus_end
  FROM loan_accounts
  FOR BUSINESS_TIME AS OF '2011-12-01' ;
  
  
-- Query all loan accounts opened from 1st June, 2009 to 2nd January, 2010.

-- To query a record for a certain period of time, use the 
-- 'FOR BUSINESS_TIME FROM...TO' clause in the SELECT statement to retrieve 
-- records exclusive of the end date specified.

SELECT account_number, bus_begin, bus_end
  FROM loan_accounts
  FOR BUSINESS_TIME FROM '2009-06-01' TO '2010-01-02' ;

  
-- Query all loan accounts opened between 1st June, 2009 and 2nd January, 2010.

-- To query a record for a certain period of time, use the 
-- 'FOR BUSINESS_TIME BETWEEN...TO' clause in the SELECT statement to retrieve 
-- records inclusive of the end date specified.

SELECT account_number, bus_begin, bus_end
  FROM loan_accounts
  FOR BUSINESS_TIME BETWEEN '2009-06-01' AND '2010-01-02' ;


-- Compare the difference between the BETWEEN..AND and FROM..TO results above.

SELECT account_number, bus_begin, bus_end
  FROM loan_accounts
  FOR BUSINESS_TIME BETWEEN '2009-06-01' AND '2010-01-02' 
  
EXCEPT 

SELECT account_number, bus_begin, bus_end
  FROM loan_accounts
  FOR BUSINESS_TIME FROM '2009-06-01' TO '2010-01-02' ;
  

echo ************************************************************************ ;
echo  UPDATE A RECORD IN THE APPLICATION-PERIOD TEMPORAL TABLE                ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The rate of interest keeps changing due to varying market conditions. The
--  bank admin needs to update the changing rate of interest for customer with 
--  account no. '2111'. This causes the associated business validity period to 
--  change accordingly.
-- 
--  The ATT makes time management easy by providing SQL extensions that can be
--  used with the UPDATE statement to update a record for a specific period of 
--  time.
--  The ATT also makes change management easy by performing 'row splitting'
--  that automatically adjusts the business validity periods when an update is 
--  performed on any column of a row in the table.
-- ***************************************************************************/

-- Check pre-existing records for account number '2111'.

SELECT account_number, rate_of_interest, bus_begin, bus_end  
  FROM loan_accounts 
  WHERE account_number = 2111
  ORDER BY account_number, bus_begin ;

  
-- Update the rate of interest for account number '2111'.
-- Note the usage of the 'FOR PORTION OF BUSINESS_TIME FROM...TO' clause to 
-- update the rate of interest for a specific period of time.

UPDATE loan_accounts 
  FOR PORTION OF BUSINESS_TIME FROM '2010-03-01' TO '2010-09-01'
  SET rate_of_interest = 10
  WHERE account_number = 2111 ;

  
-- Query the 'loan_accounts' table to view the automatic row splitting (two 
-- inserts and one update) owing to the above updation. 
-- Compare the result with the state of the table before the update (query 
-- on pre-existing records obtained above)
  
SELECT account_number, rate_of_interest, bus_begin, bus_end  
  FROM loan_accounts 
  WHERE account_number = 2111
  ORDER BY account_number, bus_begin ;


echo ************************************************************************ ;
echo  DELETE A RECORD IN THE APPLICATION-PERIOD TEMPORAL TABLE                ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The customer with account number '2111' decides to pre-close his loan 
--  before the loan period by making part payments. The 'loan_accounts' table 
--  needs to reflect the change in the business time in this case.
--
--  The ATT makes time management easy by providing SQL extensions that can be
--  used with the DELETE statement to delete a record for a specific period of 
--  time.
--  The ATT also makes change management easy by performing 'row splitting'
--  that automatically adjusts the business validity periods when a delete is 
--  performed on a part of a row corresponding to the specific period of time.
-- ***************************************************************************/  

-- Check pre-existing records for account number '2111'.

SELECT account_number, rate_of_interest, bus_begin, bus_end 
  FROM loan_accounts 
  WHERE account_number = 2111
  ORDER BY account_number, bus_begin ;

  
-- Delete records from the 'loan_accounts' table for a specific business 
-- period using the 'FOR PORTION OF BUSINESS_TIME FROM...TO' clause in the 
-- DELETE statement.

DELETE FROM loan_accounts
  FOR PORTION OF BUSINESS_TIME FROM '2012-08-01' TO '2013-11-01'
  WHERE account_number = 2111 ;
  
  
-- Query the 'loan_accounts' table to view the automatic row adjustment (one 
-- delete and one insert) owing to the above deletion. 

SELECT account_number, rate_of_interest, bus_begin, bus_end 
  FROM loan_accounts 
  WHERE account_number = 2111
  ORDER BY account_number, bus_begin ;

  
echo ************************************************************************ ;
echo  INSERT DATA INTO THE APPLICATION-PERIOD TEMPORAL TABLE - ERROR CASE     ;
echo ************************************************************************ ;
echo                                                                          ;

-- Check pre-existing records for account number '2111'.

SELECT account_number, loan_type, rate_of_interest, balance, bus_begin, bus_end 
  FROM loan_accounts 
  WHERE account_number = 2111
  ORDER BY account_number, bus_begin ;
  
-- Insert with overlapping business period.
-- EXPECTED ERROR !!

echo ------------------------- ;
echo EXPECTED ERROR !!         ;
echo ------------------------- ;
echo                           ;

INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, 
                           balance, bus_begin, bus_end)
  VALUES (2111, 'A21', 9.75, 301050, '2010-01-01', '2010-06-30') ; 
  
  
echo ************************************************************************ ;
echo  CREATE VIEWS OVER THE APPLICATION-PERIOD TEMPORAL TABLE                 ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The rate of interest keeps varying due to market conditions. The loan 
--  balance varies owing to monthly loan installment payments made by customers. 
--  Customers frequently request for the loan account information for a specific 
--  period of time. The bank admin also needs to query for active accounts 
--  periodically.
--
--  The bank admin creates two views over the ATT to retrive frequently queried 
--  information faster. With the ATT, you can create views over a specific 
--  period of time as well using the SQL extensions provided. 
-- ***************************************************************************/ 
  
DROP VIEW view_accounts_info ;
DROP VIEW view_active_accounts ;

-- Create a view that records loan account information for a particular 
-- account number '2111'

CREATE VIEW view_accounts_info
  AS SELECT account_number, loan_type, rate_of_interest, balance, 
            bus_begin, bus_end 
  FROM loan_accounts 
  WHERE account_number = 2111;
 
-- Query the view to display the rate of interest variations for 
-- account number '2111' for a specific time, say in the year 2010

SELECT account_number, rate_of_interest, bus_begin, bus_end
  FROM view_accounts_info
  FOR BUSINESS_TIME FROM '2010-01-01' TO '2011-01-01' ;
  

-- Create a view that records information of loan accounts that are 
-- active in the year 2011.

CREATE VIEW view_active_accounts
  AS SELECT account_number, loan_type, balance, rate_of_interest, 
            bus_begin, bus_end 
  FROM loan_accounts
  FOR BUSINESS_TIME FROM '2011-01-01' TO '2012-01-01' ;

-- Update the rate of interest for the account number '2111' for the year 2011

UPDATE view_active_accounts
  SET rate_of_interest = 11
  WHERE account_number = 2111 ;
  
-- Query the view to display details of account number 2111 after the 
-- above update.

SELECT account_number, loan_type, balance, rate_of_interest, bus_begin, bus_end 
  FROM view_active_accounts
  WHERE account_number = 2111 ;
  

echo ************************************************************************ ;
echo  CURRENT TEMPORAL BUSINESS_TIME SPECIAL REGISTER                         ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The 'current temporal business_time' special register is used to 'set the 
--  clock back' to a specific time for a given session. This helps promote code
--  reuse.
--
--  The bank admin needs to query as well as update loan account details 
--  frequently. Instead of modifying the query/update statement each time, the 
--  'current temporal business_time' special register can be set to the 
--  requested time. Any operations performed against the ATT after this affects 
--  values for the set time.
-- ***************************************************************************/ 

-- Set the CURRENT TEMPORAL BUSINESS_TIME to midnight of 1st March, 2012
 
SET CURRENT TEMPORAL BUSINESS_TIME = '2012-03-01' ;


-- Query details of account number '2111' as of midnight of 1st March, 2012
-- Check the tab 'Result 2 of 5' to view the result set.

SELECT account_number, loan_type, balance, rate_of_interest, bus_begin, bus_end 
  FROM loan_accounts 
  WHERE account_number = 2111 ;

-- Update the rate of interest, as special register is set to midnight of 1st March, 2012
-- hence update affects all rows whose BUSINESS_TIME period 
-- contains the point-in-time set by the CTBT special register.

UPDATE view_accounts_info
  SET rate_of_interest = 12 ;
	
-- Query the view after the above update. Results as of 1st March, 2012 
-- are displayed. Check the tab 'Result 4 of 5' to view the result set.

SELECT account_number, loan_type, balance, rate_of_interest, bus_begin, bus_end 
  FROM view_accounts_info ;

 
SET CURRENT TEMPORAL BUSINESS_TIME = NULL ; 


echo ************************************************************************ ;
echo  DROP ALL OBJECTS CREATED                                                ;
echo ************************************************************************ ;
echo                                                                          ;  

DROP VIEW view_accounts_info ;
DROP VIEW view_active_accounts ;
DROP TABLE loan_accounts ;
