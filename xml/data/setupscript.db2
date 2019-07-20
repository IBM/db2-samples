-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2007 All rights reserved.
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
-----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: setupscript.db2
--
-- SAMPLE: This file serves as the setupscript for the sample 
--         reltoxmltype.clp, .java and .sqc.
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         INSERT
--
-- OUTPUT FILE: setupscript.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------


CONNECT TO  SAMPLE;

CREATE TABLE Products_Relational
  (
    ProdID     varchar(20) not null primary key,
    Price       decimal(10,2),
    Description varchar (50),
    Info        varchar( 2000 )
  );

CREATE TABLE CustomerInfo_Relational
   (
     CustID integer not null primary key,
     Name        varchar(28),
     Street      varchar(28),
     City        varchar(28),
     Province    varchar(28),
     PostalCode  varchar(7)
   );
CREATE TABLE PurchaseOrder_Relational
   (
     PoNum       integer not null primary key,
     OrderDate   date,
     CustID      integer,
     Status      varchar(20),
     Comment     varchar(1024),
     FOREIGN KEY (CustID) references CustomerInfo_Relational
   );
 
CREATE TABLE LineItem_Relational
   (
     PoNum       integer,
     ProdID      varchar(20),
     Quantity    integer,
     FOREIGN KEY (PoNum) references PurchaseOrder_Relational,
     FOREIGN KEY (ProdID) references Products_Relational
   );

-- Create table CustomerInfo and PurchaseOrder.
CREATE TABLE CustomerInfo_New
  (
     CustID integer not null primary key,
     Address XML
  );

CREATE TABLE PurchaseOrder_new
  (
     PoNum integer not null primary key,
     OrderDate date,
     CustID integer,
     Status varchar(20),
     Price decimal(10,2),
     LineItems XML,
     Comment varchar(1024),
     FOREIGN KEY (CustID) references CustomerInfo_new
  );

INSERT INTO products_relational values 
 ('A-101', 20.80, 'Steel Spoon', 'Dozen spoons with length as 12 cm and  weight as 75 gm and steel color'), 
 ('A-102', 4.56, 'Plastic Spoon', 'Dozen spoons with length as 8.5 cm and weight as 15 gm and  white color'), 
 ('B-101', 30.23, 'Steel glass', '6 in numer and capacity of 300ml');

INSERT INTO CustomerInfo_Relational values
 ( 10082, 'Mark', 'Leslie', 'Toronto', 'Ontario', '3422212'),
 ( 10342, 'Gupta', 'Domlur', 'Bangalore', 'Karnataka', '569923'),
 ( 12033, 'Shaun', 'Markham', 'Toronto', 'Ontario', '2332333');

INSERT INTO PurchaseOrder_Relational values
 ( 8647, '2005-12-11', 10082, 'Delivered', 'Payment Received'),
 ( 1233, '2005-11-17', 10342, 'Payment Pending', 'To be sent once Payment is received');

INSERT INTO LineItem_Relational values
 ( 8647, 'A-101', 12),
 ( 1233, 'B-101', 06);


CONNECT RESET;
