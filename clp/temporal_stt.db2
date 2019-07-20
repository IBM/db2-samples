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
-- SOURCE FILE NAME     : temporal_stt.db2
--
-- PURPOSE              : This sample demonstrates:
--                          1. Creation of System-Period Temporal Table (STT)
--                          2. Migration of a regular table to a STT
--                          3. Insertion of a record into a STT
--                          4. Querying a STT
--                          5. Update records in a STT
--                          6. Delete records in a STT
--                          7. Create views over a STT
--                          8. Usage of the Current Temporal System_Time 
--                             special register
--
-- EXECUTION            : db2 -tvf temporal_stt.db2
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
--     due to variations in the rate of interest and balance columns. It is 
--     critical to maintain historical records of this table for audit and  
--     compliance initiatives. The table is also frequently queried based on 
--     customer requests to retrieve various accounts information.
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
echo  CREATE SYSTEM-PERIOD TEMPORAL TABLE (STT)                                ;
echo                                                                           ;
echo    A system-period temporal table allows you to maintain                  ;
echo    historical versions of the rows in a table.                            ;
echo ************************************************************************* ;
echo                                                                           ;

-- /***************************************************************************
-- Creating a system-period temporal table is a three step process :
-- ****************************************************************************
--   1. Create table 'loan_accounts' with a 'SYSTEM_TIME' period definition.
--      This captures the start, SYSTEM_BEGIN, and end, SYSTEM_END, times of 
--      each row of the table. Values in these columns are automatically set by
--      DB2. The 'trans_start' timestamp is generated in case of transactions 
--      making multiple updates to the same row in order to avoid conflicts 
--      that could lead to transaction aborts.
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

-- Create a SYSTEM-PERIOD TEMPORAL TABLE 'loan_accounts' that contains
-- details of loan accounts held by customers in the bank.

CREATE TABLE loan_accounts (
  account_number     INTEGER NOT NULL,
  loan_type          VARCHAR(10),
  rate_of_interest   DECIMAL(5,2) NOT NULL,
  balance            DECIMAL (10,2),
  system_begin       TIMESTAMP(12) NOT NULL 
                       GENERATED ALWAYS AS ROW BEGIN IMPLICITLY HIDDEN, 
  system_end         TIMESTAMP(12) NOT NULL 
                       GENERATED ALWAYS AS ROW END IMPLICITLY HIDDEN,
  trans_start        TIMESTAMP(12) 
                       GENERATED ALWAYS AS TRANSACTION START ID IMPLICITLY HIDDEN,
    PERIOD SYSTEM_TIME (system_begin, system_end)
) ;

-- Create the 'loan_accounts_history' table that stores historical
-- versions of data in the 'loan_accounts' table.

CREATE TABLE loan_accounts_history 
  LIKE loan_accounts ;

  
-- Enable the 'loan_accounts' table for versioning to use the 
-- 'loan_accounts_history' table.

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
--  An existing table can be migrated to a system-period temporal table.
--
--   The banking organization already has data in pre-existing base and history
--   tables. This needs to be migrated to a system-period temporal table.
-- ***************************************************************************/
  
DROP TABLE loan_accounts ;

-- Create a pre-existing 'loan_accounts' table with two timestamp columns,  
-- namely system_begin and system_end columns.

CREATE TABLE loan_accounts (
  account_number     INTEGER NOT NULL,
  loan_type          VARCHAR(10),
  rate_of_interest   DECIMAL(5,2) NOT NULL,
  balance            DECIMAL (10,2),
  system_begin       TIMESTAMP(12) NOT NULL, 
  system_end         TIMESTAMP(12) NOT NULL 
) ;

-- Create the 'loan_accounts_history' table that stores records of all  
-- historical transactions of the 'loan_accounts' table.

CREATE TABLE loan_accounts_history 
  LIKE loan_accounts ;

  
-- Insert pre-existing data into the 'loan_accounts' table.

INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest,  
                           balance, system_begin, system_end)
  VALUES 
   (2111, 'A21', 9.5, 559500, '2010-02-01-05.45.02', '9999-12-30-00.00.00.000000000000'),
   (2112, 'A10', 12, 450320, '2010-02-02-03.21.18', '9999-12-30-00.00.00.000000000000'),
   (2113, 'A21', 9, 100000, '2010-02-06-13.15.06', '9999-12-30-00.00.00.000000000000'),
   (2114, 'A15', 10, 200000, '2010-02-07-22.20.15', '9999-12-30-00.00.00.000000000000') ; 
		
		
-- Insert pre-existing data into the 'loan_accounts_history' table that reflects 
-- historical records of the 'loan_accounts' table. 

INSERT INTO loan_accounts_history (account_number, loan_type, rate_of_interest, 
                                   balance, system_begin, system_end)
  VALUES 
   (2111, 'A21', 8, 669000, '2009-09-01-23.45.01', '2009-10-01-14.33.08'),
   (2111, 'A21', 8, 648000, '2009-10-01-14.33.08', '2009-11-01-09.56.17'),
   (2111, 'A21', 9.5, 625875, '2009-11-01-09.56.17', '2009-12-01-07.03.18'),
   (2111, 'A21', 9.5, 603750, '2009-12-01-07.03.18', '2010-01-01-00.00.00'),
   (2111, 'A21', 9.5, 581625, '2010-01-01-00.00.00', '2010-02-01-05.45.02'),
   (2112, 'A10', 12, 468000, '2010-01-02-09.04.16', '2010-02-02-03.21.18') ;


echo ************************************************************************ ;
echo  MIGRATE TO SYSTEM-PERIOD TEMPORAL TABLE AND ENABLE VERSIONING           ;
echo ************************************************************************ ;
echo                                                                          ;

-- Migrate the regular 'loan_accounts' table into a SYSTEM-PERIOD TEMPORAL 
-- TABLE by adding the SYSTEM_TIME period definition and enable it for 
-- versioning to use the 'loan_accounts_history' table.

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
echo  INSERT DATA INTO THE SYSTEM-PERIOD TEMPORAL TABLE                       ;
echo ************************************************************************ ;
echo                                                                          ;

-- Insert a new record into the 'loan_accounts' table. 
-- Values for the 'system_begin' and 'system_end' columnns are generated 
-- automatically and need not be specified by the user.

INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, balance)
  VALUES (2115, 'A20', 11, 300000) ;


-- Display the automatically generated 'system_begin' and 'system_end' values 
-- for the newly generated row.
  
SELECT account_number, loan_type, rate_of_interest, 
       balance, system_begin, system_end
  FROM loan_accounts 
  WHERE account_number = 2115 ;

  
echo ************************************************************************ ;
echo  QUERY THE SYSTEM-PERIOD TEMPORAL TABLE                                  ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The bank admin needs to query the system-period temporal table for 
--  historical records during an audit.
--
--  DB2 provides SQL extensions to the SELECT statement to query the STT. Using
--  these SQL extensions signals DB2 to automatically route the query and 
--  retrieve the relevant data from both the base and history tables.
-- ***************************************************************************/  
  
-- Regular query against the system-period temporal table.

SELECT account_number, rate_of_interest, system_begin, system_end
  FROM loan_accounts
  WHERE account_number = 2111 ;

-- Query the rate of interest as of 1st October, 2009 for customer with account
-- number '2111'. 

-- To query a record for a certain point in time, use the 
-- 'FOR SYSTEM_TIME AS OF' clause in the SELECT statement.

SELECT account_number, rate_of_interest, system_begin, system_end
  FROM loan_accounts
  FOR SYSTEM_TIME AS OF '2009-10-01' 
  WHERE account_number = 2111 ;

-- To query a record for a certain period of time, use the 
-- 'FOR SYSTEM_TIME FROM...TO' clause in the SELECT statement to retrieve 
-- records exclusive of the end date specified.
  
-- Query the loan statement from 1st November, 2009 to 1st January, 2010.

SELECT account_number, rate_of_interest, balance, system_begin, system_end
  FROM loan_accounts  
  FOR SYSTEM_TIME FROM '2009-11-01' TO '2010-01-01'
  WHERE account_number = 2111 ;

-- To query a record for a certain period of time, use the 
-- 'FOR SYSTEM_TIME BETWEEN...TO' clause in the SELECT statement to retrieve 
-- records inclusive of the end date specified.
  
-- Query the loan statement between 1st November, 2009 and 1st January, 2010.

SELECT account_number, rate_of_interest, balance, system_begin, system_end
  FROM loan_accounts
  FOR SYSTEM_TIME BETWEEN '2009-11-01' AND '2010-01-01'
  WHERE account_number = 2111 ;
  
  
-- Compare the difference between the BETWEEN..AND and FROM..TO results above.
  
SELECT account_number, rate_of_interest, balance, system_begin, system_end
  FROM loan_accounts
  FOR SYSTEM_TIME BETWEEN '2009-11-01' AND '2010-01-01'
  WHERE account_number = 2111 
  
EXCEPT

SELECT account_number, rate_of_interest, balance, system_begin, system_end
  FROM loan_accounts  
  FOR SYSTEM_TIME FROM '2009-11-01' TO '2010-01-01'
  WHERE account_number = 2111 ;
    

echo ************************************************************************ ;
echo  UPDATE A RECORD IN THE SYSTEM-PERIOD TEMPORAL TABLE                     ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  A customer has made his monthly loan installment payment. The bank admin
--  needs to update this information in the 'loan_accounts' table and also 
--  store the previous value.
-- 
--  The STT makes change management easy by automatically maintaining different
--  versions of data.
-- ***************************************************************************/

-- Update the 'balance' column for the account to reflect the monthly loan
-- installment payment.

UPDATE loan_accounts 
  SET balance = 603750
  WHERE account_number = 2111 ;


-- Verify the update for the account in the 'loan_accounts' table.

SELECT account_number, balance, system_begin, system_end
  FROM loan_accounts
  WHERE account_number = 2111 ;


-- On updation of a record in the system-period temporal table 'loan_accounts', 
-- a copy of the previous record is automatically moved to the associated 
-- history table 'loan_accounts_history' by DB2.

-- Query the history table to verify the above.
  
SELECT account_number, balance, system_begin, system_end
  FROM loan_accounts_history
  WHERE account_number = 2111 ;
  
  
-- Display all records for the particular account i.e both current and 
-- historical records. Use the 'FOR SYSTEM_TIME FROM...TO' clause to query and
-- retrieve data from both the base and history tables.

SELECT account_number, balance, system_begin, system_end
  FROM loan_accounts
  FOR SYSTEM_TIME FROM '0001-01-01' TO '9999-12-31'
  WHERE account_number = 2111 ;


echo ************************************************************************ ;
echo  DELETE A RECORD IN THE SYSTEM-PERIOD TEMPORAL TABLE                     ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The bank admin realises he has performed an incorrect update of the balance
--  for the customer. He needs to revert the base table back to its original 
--  state and correct the error.
-- ***************************************************************************/  

-- Delete the wrongly updated row from the 'loan_accounts' table.

DELETE FROM loan_accounts
  WHERE account_number = 2111 ;

  
-- The deleted record information is automatically moved to the history table.
-- Query the history table to verify this.
  
SELECT account_number, loan_type, rate_of_interest, balance, 
       system_begin, system_end
  FROM loan_accounts_history
  WHERE account_number = 2111 ;

  
-- Recover the previous(wrongly updated) record from the 'loan_accounts_history' 
-- table and insert into the 'loan_accounts' table. 
  
INSERT INTO loan_accounts (account_number, loan_type, rate_of_interest, balance)
  SELECT account_number, loan_type, rate_of_interest, balance
    FROM loan_accounts
    FOR SYSTEM_TIME AS OF '2010-02-02'
    WHERE account_number = 2111 ;

	
-- Update the balance correctly.
	
UPDATE loan_accounts 
  SET balance = 537375
  WHERE account_number = 2111 ;

-- Verify the above update in the 'loan_accounts' table.

SELECT account_number, loan_type, rate_of_interest, balance, system_begin, system_end
  FROM loan_accounts
  WHERE account_number = 2111 ;


echo ************************************************************************ ;
echo  CREATE VIEWS OVER THE SYSTEM-PERIOD TEMPORAL TABLE                      ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The rate of interest keeps varying due to market conditions. The loan 
--  balance varies owing to monthly loan installment payments made by customers. 
--  Customers frequently request for the loan account statement for a specific 
--  period of time or for information on the rate of interest at a certain time 
--  in the past.
--
--  The bank admin creates two views over the STT to retrive frequently queried 
--  information faster. With the STT, you can create views over a specific 
--  period of time as well using the SQL extensions provided. 
-- ***************************************************************************/ 
  
DROP VIEW view_interest ;
DROP VIEW view_statement ;

-- Create a view that stores information on varying interest rates for 
-- different loan accounts.

CREATE VIEW view_interest
  AS SELECT account_number, rate_of_interest, system_begin, system_end
  FROM loan_accounts ;


-- Query the view to find the rate of interest as on 1st October, 2009 for 
-- customer with account number '2111'.   

SELECT account_number, rate_of_interest, system_begin, system_end
  FROM view_interest 
  FOR SYSTEM_TIME AS OF '2009-10-01'
  WHERE account_number = 2111 ;
  
  
-- Update the rate of interest for account '2111' using the view. The update  
-- on the view is automatically reflected in the base table 'loan_accounts'.

UPDATE view_interest
  SET rate_of_interest = 10
  WHERE account_number = 2111 ;

-- Verify the update for the customer in the 'loan_accounts' table.

SELECT account_number, rate_of_interest, system_begin, system_end
  FROM loan_accounts
  WHERE account_number = 2111 ;

-- The previous record is moved to the history table after an update on the 
-- 'loan_accounts' table. Query the history table to verify the same.
  
SELECT account_number, rate_of_interest, system_begin, system_end
  FROM loan_accounts_history
  WHERE account_number = 2111 ;
  

-- Create another view that stores loan accounts statement for the period from 
-- 1st Jan, 2010 to 1st Jan, 2011.
  
CREATE VIEW view_statement
  AS SELECT account_number, loan_type, rate_of_interest, balance, 
            system_begin, system_end
  FROM loan_accounts 
  FOR SYSTEM_TIME FROM '2010-01-01' TO '2011-01-01' ;

-- Query the view to obtain the loan account statement for the above period 
-- for the customer with account number '2111'. 
  
SELECT account_number, rate_of_interest, balance, system_begin, system_end
  FROM view_statement 
  WHERE account_number = 2111 ;
  

echo ************************************************************************ ;
echo  CURRENT TEMPORAL SYSTEM_TIME SPECIAL REGISTER                           ;
echo ************************************************************************ ;
echo                                                                          ;
  
-- /***************************************************************************
--  The 'current temporal system_time' special register is used to 'set the 
--  clock back' to a specific time for a given session. This helps promote code
--  reuse.
--
--  Customers frequently request for their rate of interest information. Instead 
--  of modifying the query every time, the 'current temporal system_time' 
--  special register can be set to the requested time. Any queries issued 
--  against the STT after this retrieves values for the set time.
-- ***************************************************************************/ 

-- Set the CURRENT TEMPORAL SYSTEM_TIME special register to 2nd February, 2010.

SET CURRENT TEMPORAL SYSTEM_TIME = '2010-01-01-00.00.00.000000000000' ;

-- Query the rate of interest for a customer as of 2nd February, 2010.

SELECT account_number, rate_of_interest, system_begin, system_end
  FROM loan_accounts
  WHERE account_number = 2111 ;

-- Query against the view also returns the same result.
  
SELECT account_number, rate_of_interest, system_begin, system_end
  FROM view_interest
  WHERE account_number = 2111 ;

-- The above queries will be implicitly converted to :
-- SELECT account_number, rate_of_interest, system_begin, system_end
-- FROM loan_accounts FOR SYSTEM_TIME AS OF '2010-01-01-00.00.00.000000000000'

SET CURRENT TEMPORAL SYSTEM_TIME = NULL ;


echo ************************************************************************ ;
echo  DROP ALL OBJECTS CREATED                                                ;
echo ************************************************************************ ;
echo                                                                          ;  

DROP VIEW view_interest ;
DROP VIEW view_statement ;
DROP TABLE loan_accounts ;
