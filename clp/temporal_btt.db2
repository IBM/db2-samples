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
-- SOURCE FILE NAME     : temporal_btt.db2
--
-- PURPOSE              : This sample demonstrates:
--                          1. Creation of Bitemporal Table (BTT)
--                          2. Migration of an Application-Period Temporal Table 
--                             to a BTT
--                          3. Insertion of a record into a BTT
--                          4. Querying a BTT
--                          5. Update records in a BTT
--                          6. Delete records in a BTT
--                          7. Create views over a BTT
--                          8. Usage of the Current Temporal System_Time and 
--                             Current Temporal Business_TIme special registers
--
-- EXECUTION            : db2 -tvf temporal_btt.db2
--
-- SQL STATEMENTS USED  :
--                CREATE TABLE
--                CREATE VIEW
--                ALTER TABLE
--                INSERT
--                SELECT
--                UPDATE
--                DELETE
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
--     sensitive changes accurately. It is also critical to maintain historical 
--     records of this table for audit and compliance initiatives. The table is 
--     also frequently queried based on customer requests to retrieve various 
--     accounts information.
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
echo  CREATE BITEMPORAL TABLE (BTT)                                            ;
echo                                                                           ;
echo    A bitemporal table can be used to keep user based period information   ;
echo    as well as system-based historical information. It is a combination of ;
echo    system-period temporal table and application-period temporal table.    ;
echo ************************************************************************* ;
echo                                                                           ;

-- /***************************************************************************
-- Creating a bitemporal table is a three step process :
-- ****************************************************************************
--   1. Create table 'loan_accounts' with the 'SYSTEM_TIME' and 'BUSINESS_TIME' 
--      periods definition. The SYSTEM_TIME captures the start and end times of 
--      each row and the BUSINESS_TIME the validity period of each row. The
--      'trans_start' timestamp is generated in case of transactions making
--      multiple updates to the same row in order to avoid conflicts that could
--      lead to transaction aborts. Specify the BUSINESS_TIME WITHOUT OVERLAPS 
--      clause on the account number (primary key) to ensure there is no 
--      overlap of business times.
--
--   NOTE: The system time periods are defined as IMPLICITLY HIDDEN. This means 
--   that the column will be unavailable unless it is explicitly referenced in 
--   SELECT or INSERT statements.
--
--  2. Create the history table 'loan_accounts_history' in the same schema 
--     as the 'loan_accounts' table.
--
--  3. Enable versioning for the base table 'loan_accounts' to use the 
--     history table 'loan_accounts_history'.
-- ***************************************************************************/

DROP TABLE loan_accounts ;
DROP TABLE loan_accounts_history ;

-- Create a BITEMPORAL TABLE 'loan_accounts' that contains details of 
-- loan accounts held by customers in the bank

CREATE TABLE loan_accounts (
  account_number     INTEGER NOT NULL,
  loan_type          VARCHAR(10),
  rate_of_interest   DECIMAL(5,2) NOT NULL,
  balance            DECIMAL (10,2),
  bus_begin          DATE NOT NULL,
  bus_end            DATE NOT NULL,
  system_begin       TIMESTAMP(12) NOT NULL 
                       GENERATED ALWAYS AS ROW BEGIN IMPLICITLY HIDDEN,  
  system_end         TIMESTAMP(12) NOT NULL 
                       GENERATED ALWAYS AS ROW END IMPLICITLY HIDDEN,
  trans_start        TIMESTAMP(12) 
                       GENERATED ALWAYS AS TRANSACTION START ID IMPLICITLY HIDDEN,
    PERIOD SYSTEM_TIME (system_begin, system_end),
    PERIOD BUSINESS_TIME (bus_begin, bus_end),
    PRIMARY KEY (account_number, BUSINESS_TIME WITHOUT OVERLAPS)  
) ;


-- Create the 'loan_accounts_history' table that stores historical 
-- versions of data in the 'loan-accounts' table

CREATE TABLE loan_accounts_history 
  LIKE loan_accounts ;

  
-- Enable the 'loan_accounts' table for versioning to use the 
-- 'loan_accounts_history' table

ALTER TABLE loan_accounts
  ADD VERSIONING USE HISTORY TABLE loan_accounts_history ;
  
  
echo ************************************************************************* ;
echo  CREATE PRE-EXISTING BASE AND HISTORY TABLES                              ;
echo ************************************************************************* ;
echo                                                                           ;

-- /***************************************************************************
--  NOTE: For the purpose of demonstration of this feature, it is required to 
--        have pre-existing data in order to be able to query 'historical' data.
--        Hence, the scenario of pre-existing tables and their migration to 
--        temporal tables is shown in this sample.
-- ***************************************************************************/

-- /***************************************************************************
--  An existing table can be migrated to a bitemporal table.
--
--   The banking organization already has data in pre-existing base and history
--   tables. This needs to be migrated to a bitemporal table.
-- ***************************************************************************/
  
DROP TABLE loan_accounts ;
DROP TABLE loan_accounts_history ;

-- Create an APPLICATION-PERIOD TEMPORAL TABLE 'loan_accounts' with 
-- BUSINESS_TIME specification and two timestamp columns, namely system_begin 
-- and system_end columns.

CREATE TABLE loan_accounts (
  account_number     INTEGER NOT NULL,
  loan_type          VARCHAR(10),
  rate_of_interest   DECIMAL(5,2) NOT NULL,
  balance            DECIMAL (10,2),
  bus_begin          DATE NOT NULL,
  bus_end            DATE NOT NULL,
  system_begin       TIMESTAMP(12) NOT NULL,  
  system_end         TIMESTAMP(12) NOT NULL,
    PERIOD BUSINESS_TIME(bus_begin, bus_end)  
) ;


-- Create an index to check insertion of overlapping business times into 
-- the table.

CREATE UNIQUE INDEX ix_loan_accounts 
  ON loan_accounts (account_number, BUSINESS_TIME WITHOUT OVERLAPS) ;

  
-- Create the 'loan_accounts_history' table that stores records of all  
-- historical transactions of the 'loan_accounts' table.

CREATE TABLE loan_accounts_history 
  LIKE loan_accounts ;

  
-- Insert data into the 'loan_accounts' table

INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, balance, 
                           system_begin, system_end, bus_begin, bus_end)
  VALUES 
    (2111, 'A21', 9.5, 559500, '2010-02-01-05.45.02', '9999-12-30-00.00.00.000000000000', '2009-11-01', '2013-11-01'),
    (2112, 'A10', 12, 450320, '2010-02-02-03.21.18', '9999-12-30-00.00.00.000000000000', '2010-01-02', '2013-02-02'),  
    (2113, 'A21', 9, 100000, '2010-02-06-13.15.06', '9999-12-30-00.00.00.000000000000', '2010-02-06', '2010-12-30'),
    (2114, 'A15', 10, 200000, '2010-02-07-22.20.15', '9999-12-30-00.00.00.000000000000', '2010-02-07', '2011-08-31') ; 
		
		
-- Insert pre-existing data into the 'loan_accounts_history' table that  
-- reflects historical records of the 'loan_accounts' table.

INSERT INTO loan_accounts_history (account_number, loan_type, rate_of_interest, balance,   
                                   system_begin, system_end, bus_begin, bus_end)	
  VALUES 
    (2111, 'A21', 8, 669000, '2009-09-01-23.45.01', '2009-10-01-14.33.08', '2009-08-01', '2013-11-01'),
    (2111, 'A21', 8, 648000, '2009-10-01-14.33.08', '2009-11-01-09.56.17', '2009-08-01', '2013-11-01'),
    (2111, 'A21', 9.5, 625875, '2009-11-01-09.56.17', '2009-12-01-07.03.18', '2009-11-01', '2013-11-01'),
    (2111, 'A21', 9.5, 603750, '2009-12-01-07.03.18', '2010-01-01-00.00.00', '2009-11-01', '2013-11-01'),
    (2111, 'A21', 9.5, 581625, '2010-01-01-00.00.00', '2010-02-01-05.45.02', '2009-11-01', '2013-11-01'),
    (2112, 'A10', 12, 468000, '2010-01-02-09.04.16', '2010-02-02-03.21.18', '2010-01-02', '2013-02-02') ;


echo ************************************************************************ ;
echo  MIGRATE TO BITEMPORAL TABLE AND ENABLE VERSIONING                       ;
echo ************************************************************************ ;
echo                                                                          ;

-- Migrate the application-period temporal table 'loan_accounts' into a 
-- BITEMPORAL TABLE by adding the SYSTEM_TIME period definition and enable 
-- it for versioning to use the 'loan_accounts_history' table.

-- The 'loan_accounts' table is now a 'BITEMPORAL TABLE' acting both as a 
-- SYSTEM PERIOD TEMPORAL TABLE and a APPLICATION PERIOD TEMPORAL TABLE


ALTER TABLE loan_accounts ALTER COLUMN system_begin
  SET GENERATED AS ROW BEGIN ;

-- Optional step
ALTER TABLE loan_accounts ALTER COLUMN system_begin 
  SET IMPLICITLY HIDDEN ; 
 
ALTER TABLE loan_accounts ALTER COLUMN system_end
  SET GENERATED AS ROW END ;

-- Optional step
ALTER TABLE loan_accounts ALTER COLUMN system_end  
 SET IMPLICITLY HIDDEN ;
 
ALTER TABLE loan_accounts
  ADD PERIOD SYSTEM_TIME (system_begin, system_end) ;

ALTER TABLE loan_accounts ADD COLUMN trans_start TIMESTAMP(12)
  GENERATED AS TRANSACTION START ID IMPLICITLY HIDDEN ;

ALTER TABLE loan_accounts_history 
  ADD COLUMN trans_start TIMESTAMP(12) IMPLICITLY HIDDEN ;
  
-- If IMPLICITLY HIDDEN is set above, then must set it for history table
ALTER TABLE loan_accounts_history ALTER COLUMN system_begin
  SET IMPLICITLY HIDDEN ;

-- If IMPLICITLY HIDDEN is set above, then must set it for history table
ALTER TABLE loan_accounts_history ALTER COLUMN system_end
  SET IMPLICITLY HIDDEN ;  

ALTER TABLE loan_accounts
  ADD VERSIONING USE HISTORY TABLE loan_accounts_history ;


echo ************************************************************************ ;
echo  INSERT DATA INTO THE BITEMPORAL TABLE                                   ;
echo ************************************************************************ ;
echo                                                                          ;

-- Insert a new record into the 'loan_accounts' table. 
-- Values for the 'system_begin' and 'system_end' columnns are generated 
-- automatically and need not be specified by the user.

INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, balance, 
                           bus_begin, bus_end, system_begin, system_end)
  VALUES 
    (2115, 'A04', 9, 621000, '2010-02-27', '2015-03-27', DEFAULT, DEFAULT) ;
  
-- Display the automatically generated 'system_begin' and 'system_end' values 
-- for the newly generated row.

SELECT account_number, loan_type, rate_of_interest, balance, 
       bus_begin, bus_end, system_begin, system_end
  FROM loan_accounts
  WHERE account_number = 2115 ;

  
echo ************************************************************************ ;
echo  QUERY THE BITEMPORAL TABLE                                              ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The bank admin, based on a customer request, needs to query the bitemporal 
--  table for details of loan accounts for either a certain point in time or a
--  period of time.
--
--  DB2 provides SQL extensions to the SELECT statement to issue time based 
--  queries. Using these SQL extensions signals DB2 to automatically route the 
--  query and retrieve the relevant data from both the base and history tables.
-- ***************************************************************************/  
  
-- Regular query against the bitemporal table.

SELECT account_number, rate_of_interest, bus_begin, bus_end, 
       system_begin, system_end
  FROM loan_accounts ;

-- Query the outstanding loans as of BUSINESS_TIME '2011-12-01'.

-- To query a record for a certain point in time, use the 
-- 'FOR BUSINESS_TIME AS OF' or the 'FOR SYSTEM_TIME AS OF' clause in the 
-- SELECT statement.

SELECT account_number, bus_begin, bus_end, system_begin, system_end
  FROM loan_accounts
  FOR BUSINESS_TIME AS OF '2011-12-01' ;
 
-- Query the rate of interest as of SYSTEM_TIME '2010-01-01'.

SELECT account_number, rate_of_interest, bus_begin, bus_end, 
       system_begin, system_end
  FROM loan_accounts
  FOR SYSTEM_TIME AS OF '2010-01-01' ;
  
-- Query the BITEMPORAL table for both the SYSTEM_TIME as well as the 
-- BUSINESS_TIME to obtain the rate of interest recorded on 1st Oct, 2009 
-- pertaining to business time as of 1st Dec, 2009.

SELECT account_number, rate_of_interest, bus_begin, bus_end, 
       system_begin, system_end
  FROM loan_accounts
  FOR BUSINESS_TIME AS OF '2009-12-01'
  FOR SYSTEM_TIME AS OF '2009-10-01' ;  
    

echo ************************************************************************ ;
echo  UPDATE A RECORD IN THE BITEMPORAL TABLE                                 ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The 'loan_accounts' table needs to be updated frequently to reflect the 
--  change in balance owing to monthly loan installment payments by the 
--  customer as well as changes in rates of interest due to varying market 
--  conditions.
-- 
--  The BTT makes time management easy by providing SQL extensions that can be
--  used with the UPDATE statement to update a record for a specific period of 
--  time. The BTT also makes change management easy by performing 'row splitting'
--  that automatically adjusts the business validity periods when an update is 
--  performed on any column of a row in the table.
--  The BTT automatically maintains historical versions of data as well.
-- ***************************************************************************/

-- Update the rate of interest for account number '2111'. 

UPDATE loan_accounts 
  FOR PORTION OF BUSINESS_TIME FROM '2010-03-01' TO '2010-09-01'
  SET rate_of_interest = 10
  WHERE account_number = 2111 ;


-- Update the balance of a particular customer to reflect monthly installment 
-- payment.

UPDATE loan_accounts 
  SET balance = 603750
  WHERE account_number = 2111 ;


-- The historical records are moved to the history table.
  
SELECT account_number, rate_of_interest, balance, system_begin, system_end, 
       bus_begin, bus_end
  FROM loan_accounts_history
  WHERE account_number = 2111 ;
  
  
-- Query all records for the particular customer from both the current and 
-- history tables. 

SELECT account_number, rate_of_interest, balance, system_begin, system_end, 
       bus_begin, bus_end
  FROM loan_accounts
  FOR SYSTEM_TIME FROM '0001-01-01' TO '9999-12-30-00.00.00.000000000000'
  WHERE account_number = 2111 ;


echo ************************************************************************ ;
echo  DELETE A RECORD IN THE BITEMPORAL TABLE                                 ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The bank admin realises he has performed an incorrect update of the balance
--  for the customer. He needs to revert the base table back to its original 
--  state and correct the error.
--  The customer with account number '2111' decides to pre-close his loan 
--  before the loan period by making part payments. The 'loan_accounts' table 
--  needs to reflect the change in the business time in this case.
--
--  The BTT makes time management easy by providing SQL extensions that can be
--  used with the DELETE statement to delete a record for a specific period of 
--  time.
--  The BTT also makes change management easy by performing 'row splitting'
--  that automatically adjusts the business validity periods when a delete is 
--  performed on a part of a row corresponding to the specific period of time.
-- ***************************************************************************/  

-- Delete the wrongly updated row from the 'loan_accounts' table

DELETE FROM loan_accounts
  WHERE account_number = 2111 ;

-- The deleted record is stored in the history table.
  
SELECT account_number, loan_type, rate_of_interest, balance, bus_begin, bus_end, 
       system_begin, system_end
  FROM loan_accounts_history
  WHERE account_number = 2111 ;

  
-- Recover the previous (wrongly updated) record and insert into the current table.
  
INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, 
                               balance, bus_begin, bus_end)
  SELECT account_number, loan_type, rate_of_interest, balance, bus_begin, bus_end
    FROM loan_accounts
    FOR SYSTEM_TIME AS OF '2010-02-02'
    WHERE account_number = 2111 ;

	
-- Update the balance for correctly.
	
UPDATE loan_accounts 
  SET balance = 537375
  WHERE account_number = 2111 ;
  
-- Update the rate of interest for account number '2111'. 

UPDATE loan_accounts 
  FOR PORTION OF BUSINESS_TIME FROM '2010-03-01' TO '2010-09-01'
    SET rate_of_interest = 10
  WHERE account_number = 2111 ;  
  
-- Delete records from the 'loan_accounts' table for a particular business period.
-- Note the usage of the 'FOR PORTION OF BUSINESS_TIME FROM...TO' clause to 
-- delete the rate of interest for a specific period of time.

DELETE FROM loan_accounts
  FOR PORTION OF BUSINESS_TIME FROM '2012-08-01' TO '2013-11-01'
  WHERE account_number = 2111 ;  

-- Query the 'loan_accounts' table to view the automatic row adjustment
-- owing to the above delete. 

SELECT account_number, rate_of_interest, bus_begin, bus_end, system_begin, system_end 
  FROM loan_accounts 
  WHERE account_number = 2111
  ORDER BY account_number, bus_begin ;
  

echo ************************************************************************ ;
echo  CREATE VIEWS OVER THE BITEMPORAL TABLE                                  ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  Customers frequently request for the loan account statement for a specific 
--  period of time or for information on the rate of interest at a certain time 
--  in the past.
--
--  The bank admin creates two views over the BTT to retrive frequently queried 
--  information faster. With the BTT, you can create views over a specific 
--  period of time as well using the SQL extensions provided. 
-- ***************************************************************************/ 
  
DROP VIEW view_accounts_info ;
DROP VIEW view_statement ;

-- Create a view that records loan account information for a particular 
-- account number say '2111'.

CREATE VIEW view_accounts_info
  AS SELECT account_number, loan_type, rate_of_interest, balance, bus_begin, 
            bus_end, system_begin, system_end
  FROM loan_accounts 
  WHERE account_number = 2111;
  
-- Query the view to display the rate of interest variations for account 
-- number '2111' in the year 2010.

SELECT account_number, rate_of_interest, bus_begin, bus_end, 
       system_begin, system_end
  FROM view_accounts_info
  FOR BUSINESS_TIME FROM '2010-01-01' TO '2011-01-01' ;
  
-- Create a view that stores loan accounts information as of business time 
-- 1st Jan 2011 and for SYSTEM_TIME from 1st Jan, 2010 to 1st Jan, 2011.
  
CREATE VIEW view_statement
  AS SELECT account_number, loan_type, rate_of_interest, balance, bus_begin, 
            bus_end, system_begin, system_end
  FROM loan_accounts 
  FOR BUSINESS_TIME AS OF '2011-01-01'
  FOR SYSTEM_TIME FROM '2010-01-01' TO '2011-01-01' ;  

-- Query the view to obtain records for the specified business and system times.

SELECT  account_number, rate_of_interest, balance, bus_begin, bus_end, system_begin, system_end
  FROM view_statement 
  WHERE account_number = 2111 ;
    

echo ************************************************************************ ;
echo  CURRENT TEMPORAL SYSTEM_TIME AND 
echo  CURRENT TEMPORAL BUSINESS_TIME SPECIAL REGISTERS                        ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The two special registers are used to 'set the clock back' to a specific 
--  time for a given session. This helps promote code reuse.
--
--  The bank admin needs to query as well as update loan account details 
--  frequently. Instead of modifying the query/update statement each time, the 
--  two special register can be set to the requested time. Any operations 
--  performed against the ATT after this affects values for the set time.
-- ***************************************************************************/ 

-- Set the CURRENT TEMPORAL BUSINESS_TIME to 1st January, 2011.
-- Set the CURRENT TEMPORAL SYSTEM_TIME to 1st October 2010.

SET CURRENT TEMPORAL BUSINESS_TIME = '2011-01-01' ;
SET CURRENT TEMPORAL SYSTEM_TIME = '2010-10-01' ;

-- Query the 'loan_accounts' table for loans that are active as of 1st Jan, 2011.

SELECT  account_number, rate_of_interest, balance, bus_begin, bus_end, system_begin, system_end
  FROM loan_accounts ;

-- Query the view to display the rate of interest for account number '2111'
-- as on 1st January, 2011.

SELECT account_number, rate_of_interest, bus_begin, bus_end 
  FROM view_accounts_info ;
  

SET CURRENT TEMPORAL BUSINESS_TIME = NULL ;
SET CURRENT TEMPORAL SYSTEM_TIME = NULL ;


echo ************************************************************************ ;
echo  DROP ALL OBJECTS CREATED                                                ;
echo ************************************************************************ ;
echo                                                                          ;  

DROP VIEW view_accounts_info ;
DROP VIEW view_statement ;
DROP TABLE loan_accounts ;
