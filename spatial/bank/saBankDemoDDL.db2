----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2000 - 2021
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Component Name:   Db2 Spatial Analytics
--
-- Source File Name: saBankDemoDDL.db2
--
-- Version:          11.5.6+
--
-- Description: Load non-spatial data into the sample database.
--
-- SQL STATEMENTS USED:
--         DROP TABLE
--         CREATE TABLE
--
-- The tables are created using the database default table organization.
-- Note: for column organized tables the primary keys are not enforced
-- by default.
--
-- For more information about the Db2 Spatial Analytics Bank Demo scripts,
-- see the saBankDemoREADME.txt file.
--
-- For more information about Db2 Spatial Analytics component, refer to the 
-- documentation at
-- https://www.ibm.com/docs/en/db2/11.5?topic=data-db2-spatial-analytics.
--
-- For the latest information on Db2 refer to the Db2 website at
-- https://www.ibm.com/analytics/db2.
----------------------------------------------------------------------------
CREATE TABLE sa_demo.customers (
       customer_id INTEGER NOT NULL 
          PRIMARY KEY ENFORCED,
       sa_row_id INTEGER,
       name VARCHAR (20),
       street VARCHAR (25), 
       city VARCHAR (10), 
       state VARCHAR (2), 
       zip VARCHAR (5), 
       phone VARCHAR (20) , 
       email VARCHAR (50) ,		
       customer_type VARCHAR (10) ,		
       date_billed DATE , 
       notes VARCHAR (100),
       date_entered DATE,
       latitude DOUBLE,
       longitude DOUBLE
      ) ;

CREATE TABLE sa_demo.branches (
       branch_id INTEGER  NOT NULL 
          PRIMARY KEY ENFORCED, 
       sa_row_id INTEGER,
       name VARCHAR (12),
       manager VARCHAR (20),
       street VARCHAR (20),
       city VARCHAR (10),
       state VARCHAR (2),
       zip VARCHAR (5),
       phone VARCHAR (30),
       fax VARCHAR (30),
       latitude DOUBLE,
       longitude DOUBLE
       ) ;

CREATE TABLE sa_demo.accounts (
       customer_id INTEGER  NOT NULL,
       branch_id INTEGER  NOT NULL,
       account_id INTEGER  NOT NULL
          PRIMARY KEY ENFORCED,
       type VARCHAR (10)  NOT NULL,
       balance DECIMAL (14, 2)  NOT NULL,
       routing_number integer  NOT NULL,
       CONSTRAINT fk_branches FOREIGN KEY(branch_id) 
          REFERENCES sa_demo.branches(branch_id) ON DELETE CASCADE,
       CONSTRAINT fk_customers FOREIGN KEY(customer_id) 
          REFERENCES sa_demo.customers(customer_id) ON DELETE CASCADE
      ) ;

CREATE TABLE sa_demo.transactions (
       transaction_id INTEGER NOT NULL
          PRIMARY KEY,
       transaction_date DATE NOT NULL, 
       description VARCHAR (100),	
       account_id INTEGER NOT NULL , 
       amount DECIMAL (14, 2) NOT NULL, 
       notes VARCHAR (100),  
       classification VARCHAR (30),
       CONSTRAINT fk_accounts FOREIGN KEY(account_id) 
          REFERENCES sa_demo.accounts(account_id) ON DELETE CASCADE
      )  ;
