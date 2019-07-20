----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2000 - 2014
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Product Name:     DB2 Spatial Extender v10.0
--
-- Source File Name: seBankDemoDDL.db2
--
-- Version:          10.5.0
--
-- Description: Load non-spatial data into the sample database.
--
-- SQL STATEMENTS USED:
--         DROP TABLE
--         CREATE TABLE
--
--
-- For more information about the DB2 Spatial Extender Bank Demo scripts,
-- see the seBankDemoREADME.txt file.
--
-- For more information about DB2 Spatial Extender, refer to the DB2 Spatial 
-- Extender User's Guide and Reference.
--
-- For the latest information on DB2 Spatial Extender and the Bank Demo
-- refer to the DB2 Spatial Extender website at
-- http://www.software.ibm.com/software/data/spatial/db2spatial
----------------------------------------------------------------------------
CREATE TABLE se_demo.customers (
       customer_id INTEGER NOT NULL 
          PRIMARY KEY,
       se_row_id INTEGER,
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
      ) DATA CAPTURE NONE ORGANIZE BY ROW ;

CREATE TABLE se_demo.branches (
       branch_id INTEGER  NOT NULL 
          PRIMARY KEY, 
       se_row_id INTEGER,
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
       )  DATA CAPTURE NONE ORGANIZE BY ROW ;

CREATE TABLE se_demo.accounts (
       customer_id INTEGER  NOT NULL,
       branch_id INTEGER  NOT NULL,
       account_id INTEGER  NOT NULL
          PRIMARY KEY,
       type VARCHAR (10)  NOT NULL,
       balance DECIMAL (14, 2)  NOT NULL,
       routing_number integer  NOT NULL,
       CONSTRAINT fk_branches FOREIGN KEY(branch_id) 
          REFERENCES se_demo.branches(branch_id) ON DELETE CASCADE,
       CONSTRAINT fk_customers FOREIGN KEY(customer_id) 
          REFERENCES se_demo.customers(customer_id) ON DELETE CASCADE
      ) ORGANIZE BY ROW;

CREATE TABLE se_demo.transactions (
       transaction_id INTEGER NOT NULL
          PRIMARY KEY,
       transaction_date DATE NOT NULL, 
       description VARCHAR (100),	
       account_id INTEGER NOT NULL , 
       amount DECIMAL (14, 2) NOT NULL, 
       notes VARCHAR (100),  
       classification VARCHAR (30),
       CONSTRAINT fk_accounts FOREIGN KEY(account_id) 
          REFERENCES se_demo.accounts(account_id) ON DELETE CASCADE
      ) ORGANIZE BY ROW;
