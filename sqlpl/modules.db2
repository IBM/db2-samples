-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
--
-- SOURCE FILE NAME: modules.db2
--
-- SAMPLE: This sample demonstrates:
--          1. Creation of modules and module objects
--          2. Creation and usage of row data types, boolean data type,
--             associative arrays and array of rows
--          3. Creation and usage of strongly-typed, weakly-typed and 
--             parameterized cursors
--          4. Full SQL PL support for functions, triggers and compiled 
--             compound statements
--          5. Support for INOUT and OUT parameters in compiled UDFs
--          6. Support for compiled UDFs and triggers that contain
--             assignment to global variables
--
-- USAGE SCENARIO: This is a furniture store product purchasing scenario 
-- in which data related to purchase orders, product delivery and inventory
-- is managed. Store customers can place a purchase order for a set of 
-- furniture items and specify delivery requirements. A customer bill is
-- generated that reflects the order placed and the total order cost.
-- Shippping costs are determined and the shipping information is recorded.
-- A check is maintained on the stock of products in the store. Suppliers can 
-- view data regarding supply requirements. A store bill is generated for the 
-- stock replenished.
--
-- SAMPLE DESCRIPTION: The data is stored in tables:
--
-- (1) Product_details       : Contains the details of products available in 
--                             the store.                                
-- (2) Customer_details      : Contains the customer details.            
-- (3) Purchaseorder_master  : Contains details of the customer purchase order.   
--                             This is the master table. 
-- (4) Purchaseorder_details : Contains details of products ordered by the 
--                             customer. This is the child table.
-- (5) Shipping              : Contains details of products shipped to the 
--                             customers.
-- (6) Inventory_details     : Contains details of products available with the 
--                             supplier.
-- (7) Supply_orders         : Contains details of products that need to be
--                             replenished in the store by the supplier.
--      
-- The application processing is performed by the following routines:
-- 
--   (1) Function 'replenish_stock' : Procures details of products that need to 
--                                    be replenished in the store to place an
--                                    order with the supplier.
--   (2) Trigger 'check_stock'      : Checks stock of items remaining in the 
--                                    store and places order with the supplier
--   (3) Module 'store_transactions' : Contains stored procedures, functions,
--                                     user-defined data types and cursors that
--                                     process all customer-store transactions.
--                                     This module is used by the store owner.                                    
--       
--   (a) Function 'compute_bill'    : Computes the total amount payable for the 
--                                    customer order.
--   (b) Procedure 'process_order'  : Processes the customer-store transactions
--                                    and calls the 'compute_bill' function to 
--                                    compute the customer bill.
--   (c) Procedure 'take_order'     : Takes the customer order as input, inserts
--                                    it into the tables and generates the 
--                                    customer bill.
--   (d) Procedure 'shipping'       : Processes the shipping of products to the  
--                                    customer.
--    
-- (4) Module 'supply_stock' : Processes the supplier-store transactions. 
--                             This module is used by the supplier.
--       
--   (a) Function 'compute_bill'   : Computes the amount payable by the store
--                                   owner for each product supplied.
--   (b) Procedure 'process_order' : Processes the supplier-store transactions
--                                   and calls the function 'compute_bill'  
--                                   to compute the store bill.
--
-- (5) Standalone Compiled Compound Statement :
--                      Calls the 'take_order' and 'shipping' procedures of 
--                      the module 'store_transactions' to process the 
--                      customer-store transactions and the 'process_order'
--                      procedure of the module 'supply_stock' to process the
--                      supplier-store transactions.
-------------------------------------------------------------------------------
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         CREATE TYPE
--         CREATE SEQUENCE
--         CREATE TRIGGER
--         CREATE VARIABLE
--         CREATE MODULE
--         ALTER MODULE PUBLISH TYPE
--         ALTER MODULE PUBLISH FUNCTION
--         ALTER MODULE PUBLISH PROCEDURE
--         ALTER MODULE ADD FUNCTION 
--         ALTER MODULE ADD PROCEDURE
--         INSERT
--         SELECT
--         UPDATE
--         DROP MODULE
--         DROP TABLE
--         DROP TYPE
--         DROP SEQUENCE
--         DROP VARIABLE
-------------------------------------------------------------------------------

-- Connect to 'sample' database
CONNECT TO sample@

-----------------------------------------------------------------------------
-- 1. Create and populate the tables 'inventory_details', 'product_details', 
--    'customer_details', 'purchaseorder_master', 'purchaseorder_details', 
--    'shipping' and 'supply_orders'.
-----------------------------------------------------------------------------

-- Create table 'inventory_details' to store details of products available 
-- with the supplier
CREATE TABLE inventory_details(
  product_ID         BIGINT NOT NULL,
  quantity           INTEGER,
  location           VARCHAR(20),
  cost               DECFLOAT,
  PRIMARY KEY (product_ID))@

-- Insert existing values into the 'inventory_details' table
INSERT INTO inventory_details 
  VALUES(11, 50, 'warehouse', 80),
        (12, 40, 'warehouse', 750),
        (13, 35, 'store', 900),
        (14, 25, 'warehouse', 2200),
        (20, 60, 'store', 400),
        (100, 55, 'warehouse', 10000),
        (121, 25, 'warehouse', 8000)@

-- Create table 'product_details' to store details of the products available 
-- in the store
CREATE TABLE product_details(
  product_ID            BIGINT NOT NULL,
  product_name          VARCHAR(10),
  quantity_available    INTEGER,
  selling_price         DECFLOAT,
  PRIMARY KEY (product_ID),
  CONSTRAINT fk_prodid2 FOREIGN KEY (product_ID)
    REFERENCES inventory_details (product_ID) ON DELETE CASCADE)@

-- Insert existing product details into the 'product_details' table
INSERT INTO product_details
  VALUES(11, 'VASE', 10, 100),
        (12, 'CHAIR', 10, 900),
        (13, 'TABLE', 6, 1100),
        (14, 'BED', 4, 2500)@

-- Create table 'customer_details' to store the customer details
CREATE TABLE customer_details(
  customer_ID       BIGINT NOT NULL,                
  customer_name     VARCHAR(15),
  phoneno           BIGINT,
  address           VARCHAR(50),
  purchase_amount   BIGINT,
  PRIMARY KEY (customer_ID))@

-- Insert existing customer details into the 'customer_details' table
INSERT INTO customer_details 
  VALUES(1000, 'Bob', '9845245388', '104,Millers Street,Toronto', 6000), 
        (1001, 'Joe', '9876543012', '112,Fairview Lane,Ontario', 10000), 
        (1002, 'Pat', '9765909016', '15,Singer Street,Langsford', 4800),
        (1003, 'Mat', '9890371322', '214,Hilton Street,Parksville', 5400)@

-- Tables 'purchaseorder_master' and 'purchaseorder_details' store the 
-- customer order details. The master table 'purchaseorder_master' contains
-- details of the order such as the purchaseorder ID, order date, etc. 
-- As a customer order may contain multiple products, a separate child table 
-- 'purchaseorder_details' stores details of the products ordered.

-- Create table 'purchaseorder_master' to store details of the orders 
-- placed by the customers 
CREATE TABLE purchaseorder_master(
  purchaseorder_ID     BIGINT NOT NULL,
  customer_ID          BIGINT NOT NULL,
  order_date           DATE,
  status               VARCHAR(10) NOT NULL WITH DEFAULT 'UNSHIPPED',
  total_amount         DECFLOAT WITH DEFAULT 0,
  PRIMARY KEY (purchaseorder_ID),
  CONSTRAINT fk_custid FOREIGN KEY (customer_ID)
    REFERENCES customer_details (customer_ID) ON DELETE RESTRICT)@  

-- Create table 'purchaseorder_details' to store details of products ordered 
-- by the customers
CREATE TABLE purchaseorder_details(
  purchaseorder_master_ID     BIGINT NOT NULL,
  product_ID                  BIGINT NOT NULL, 
  quantity_ordered            INTEGER,
  CONSTRAINT fk_poid1 FOREIGN KEY (purchaseorder_master_ID) 
    REFERENCES purchaseorder_master (purchaseorder_ID) ON DELETE CASCADE,
  CONSTRAINT fk_prodid3 FOREIGN KEY (product_ID)
    REFERENCES product_details (product_ID) ON DELETE CASCADE)@

-- Insert existing orders into the 'purchaseorder_master' table
INSERT INTO purchaseorder_master 
  VALUES(10497, 1000, '2008-03-11', 'UNSHIPPED', 2500), 
        (10498, 1003, '2008-02-15', 'SHIPPED', 2500),
        (10499, 1001, '2008-03-10', 'UNSHIPPED', 4200)@

-- Insert existing orders into the 'purchaseorder_details' table
INSERT INTO purchaseorder_details 
  VALUES(10497, 12, 2),
        (10498, 14, 1),
        (10499, 11, 4),
        (10499, 12, 1)@

-- Create table 'shipping' to store details of customer orders for shipping
CREATE TABLE shipping(
  purchaseorder_ID       BIGINT NOT NULL,
  customer_ID            BIGINT NOT NULL,
  customer_address       VARCHAR(50),
  order_date             DATE,
  shipping_date          DATE,
  shipping_cost          BIGINT,
  CONSTRAINT fk_poid2 FOREIGN KEY (purchaseorder_ID)
    REFERENCES purchaseorder_master (purchaseorder_ID) ON DELETE CASCADE,
  CONSTRAINT fk_custid2 FOREIGN KEY (customer_ID)
    REFERENCES customer_details (customer_ID) ON DELETE RESTRICT)@

-- Insert existing shipping details into the 'shipping' table
INSERT INTO shipping
  VALUES(10498, 
         1003,
         '214,Hilton Street,Parksville',
         '2008-02-15',
         '2008-02-16',
         50)@

-- Create table 'supply_orders' that stores details of products that 
-- need to be supplied to the store by the supplier
CREATE TABLE supply_orders(
  store_ID             BIGINT NOT NULL,
  product_ID           BIGINT NOT NULL,
  quantity_required    INTEGER,
  status               VARCHAR(30) NOT NULL,
  CONSTRAINT fk_prodid1 FOREIGN KEY (product_ID)
    REFERENCES inventory_details (product_ID) ON DELETE CASCADE)@

-- Insert existing values into the 'supply_orders' table
INSERT INTO supply_orders
  VALUES(1106009, 11, 5, 'STOCK REPLENISHED'),
        (2204510, 14, 20, 'STOCK REPLENISHED'),
        (1106009, 14, 10, 'PENDING')@

-----------------------------------------------------------------------------
-- 2. Create sequence, row data types and global variables 
-----------------------------------------------------------------------------

-- Create a sequence to automatically generate purchase order IDs
CREATE OR REPLACE SEQUENCE purchaseorder_ID START WITH 10500@

-- Create an associative array type to store customer input values
CREATE TYPE assoc_array AS INTEGER ARRAY[INTEGER]@

-- Create row data types having the same fields as the columns in the 
-- respective tables
CREATE TYPE order_stock_t AS ROW ANCHOR ROW OF supply_orders@
CREATE TYPE product_stock_t AS ROW
  (product_ID BIGINT, product_name VARCHAR(10))@

-- Create global boolean and row type variables
CREATE OR REPLACE VARIABLE value_v BOOLEAN@
CREATE OR REPLACE VARIABLE product_stock_v product_stock_t@

-----------------------------------------------------------------------------
--  3. Function 'replenish_stock' showcases :
--          - Row type variable as return type
--          - Usage of row type variable within a function
--          - Global variable support
-----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION replenish_stock() 
RETURNS order_stock_t
LANGUAGE SQL
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------
  
  -- Local variable declaration of row type 'order_stock_t'
  DECLARE order_stock_v order_stock_t;

  ----------------------------
  -- Executable SQL Statements
  ----------------------------

  -- Populate values into the row type variable
  SET order_stock_v.store_ID = 1106009;
  SET order_stock_v.product_ID = product_stock_v.product_ID;
  SET order_stock_v.quantity_required = 10;
  SET order_stock_v.status = 'PENDING';

  -- Print the details of products that need to be replenished
  
  -- Usage of global boolean variable 'value_v'
  IF value_v = TRUE THEN
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
  CALL DBMS_OUTPUT.PUT_LINE('REPLENISH STOCK FOR THE FOLLOWING PRODUCTS :');
  CALL DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('***********************************************');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('PRODUCT ID'||'  '||'PRODUCT NAME'||'  ');
  CALL DBMS_OUTPUT.PUT_LINE('----------'||'  '||'------------'||'  ');
  END IF;

  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT(product_stock_v.product_ID);
  CALL DBMS_OUTPUT.PUT('          ');
  CALL DBMS_OUTPUT.PUT(product_stock_v.product_name);

  IF value_v = FALSE THEN
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('***********************************************');
  CALL DBMS_OUTPUT.NEW_LINE;
  END IF;

  RETURN order_stock_v;
END@

-----------------------------------------------------------------------------
--  4. Trigger 'check_stock' showcases :
--          - Full SQL PL support for Triggers
--          - Exit handler within a trigger
--          - Support for assignment to global variables
-----------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER check_stock
AFTER UPDATE OF quantity_available ON product_details
REFERENCING NEW AS new
FOR EACH ROW 
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------

  -- Local variable declaration of row type 'order_stock_t'
  DECLARE place_order_v order_stock_t;

  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE errorLabel CHAR(50) DEFAULT '';

  -- Error Handler in case of SQL error
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE VALUE sqlstate SET MESSAGE_TEXT = errorLabel;

  ----------------------------
  -- Executable SQL Statements
  ----------------------------

  -- Assignment to global row type variable 'product_stock_v'
  IF new.quantity_available < 5 THEN
    SET product_stock_v.product_ID = new.product_ID;
    SET product_stock_v.product_name = new.product_name;
      
    -- Call the function 'replenish_stock'
    SET place_order_v = replenish_stock();

    SET errorLabel = 'INSERT INTO supply_orders';

    -- Populate the 'supply_orders' table with details of products that need
    -- to be replenished 
    INSERT INTO supply_orders VALUES place_order_v;
    
  END IF;
END@

-----------------------------------------------------------------------------
-- 5. Create module 'store_transactions'. The module showcases encapsulation 
--    via Public and Private object visibility. It also showcases support for
--    procedures, functions, cursor types and row data type creation and 
--    usage within the module
-----------------------------------------------------------------------------

echo --------------------------@
echo Start Module Specification@
echo --------------------------@

CREATE OR REPLACE MODULE store_transactions@

-- The objects specified in the module specification are visible outside the  
-- module as they are defined with the 'PUBLISH' keyword

-- Create row data types having the same fields as the columns in the 
-- respective tables

ALTER MODULE store_transactions PUBLISH TYPE product_t 
  AS ROW(product_ID BIGINT, product_name VARCHAR(10))@

ALTER MODULE store_transactions PUBLISH TYPE purchaseorder_master_t 
  AS ROW(purchaseorder_ID BIGINT,  
         customer_ID BIGINT,
         order_date DATE, 
         status VARCHAR(10),
         total_amount DECFLOAT)@

ALTER MODULE store_transactions PUBLISH TYPE purchaseorder_details_t 
  AS ROW ANCHOR ROW OF purchaseorder_details@

ALTER MODULE store_transactions PUBLISH TYPE customer_t 
  AS ROW ANCHOR ROW OF customer_details@

ALTER MODULE store_transactions PUBLISH TYPE stock_orders_t 
  AS ROW ANCHOR ROW OF supply_orders@

-- Create a type for collection of rows to store an array of row type variables
ALTER MODULE store_transactions PUBLISH TYPE purchaseorder_master_array_t 
  AS purchaseorder_master_t ARRAY[]@

-- Create Strong typed cursors that return a row of the corresponding row type 

ALTER MODULE store_transactions 
  PUBLISH TYPE purchaseorder_master_cursor_t 
  AS purchaseorder_master_t CURSOR@

ALTER MODULE store_transactions 
  PUBLISH TYPE purchaseorder_details_cursor_t
  AS purchaseorder_details_t CURSOR@ 

-- Create procedure prototypes 

ALTER MODULE store_transactions 
  PUBLISH PROCEDURE take_order(customer_ID_p INTEGER,
                               productID_quantity_p assoc_array)@

ALTER MODULE store_transactions PUBLISH PROCEDURE shipping()@

echo ------------------------@
echo End Module Specification@
echo ------------------------@

echo ------------------------@
echo Body of Module@
echo ------------------------@

-----------------------------------------------------------------------------
--  5.(a) Function 'compute_bill' (private module object) showcases :
--             - Full SQL PL support for functions
--             - Support for IN and OUT parameters
--             - Strong typed cursor as input parameter
--             - Cursor predicate 'IS NOT FOUND'
--             - Support for ANCHOR DATA TYPES
--             - Exit handler within a function
--             - Usage of row type variable
----------------------------------------------------------------------------- 

ALTER MODULE store_transactions ADD FUNCTION compute_bill
 (IN products_ordered_p purchaseorder_details_cursor_t, 
  OUT customer_bill_p DECFLOAT)
RETURNS INTEGER 
LANGUAGE SQL
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------

  -- Anchored scalar type in local variable declaration. This anchors the
  -- datatype of the variable to that of the corresponding column in the table
  DECLARE individual_cost_v ANCHOR DATA TYPE TO product_details.selling_price;

  DECLARE purchase_products_v purchaseorder_details_t;

  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE code, SQLCODE INTEGER DEFAULT 0;
  DECLARE errorLabel CHAR(50) DEFAULT '';

  -- Error Handler in case of SQL error
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE VALUE sqlstate SET MESSAGE_TEXT = errorLabel;
 
  ----------------------------
  -- Executable SQL Statements
  ----------------------------

  SET code = SQLCODE;
  SET customer_bill_p = 0;

  -- SQL statements to compute the amount payable for the customer purchase
  -- with a discount of 10% offered if the total cost exceeds 5,000

  fetch_loop:
    LOOP
      -- Fetch input cursor value into row type variable 'purchase_products_v'
      FETCH products_ordered_p INTO purchase_products_v;

      -- The cursor predicate 'IS NOT FOUND' checks whether a row has been 
      -- found for the cursor 'products_ordered_p'
      IF products_ordered_p  IS NOT FOUND
        THEN LEAVE fetch_loop;
      END IF;

      SET errorLabel = 'SELECT selling_price';

      SELECT selling_price 
        INTO individual_cost_v 
        FROM product_details 
        WHERE product_ID = purchase_products_v.product_ID;

      SET customer_bill_p =
        customer_bill_p + (individual_cost_v *  
                          purchase_products_v.quantity_ordered);
        
    END LOOP fetch_loop;

    IF customer_bill_p > 5000
      THEN SET customer_bill_p = 0.90 * customer_bill_p;
    END IF;

  CLOSE products_ordered_p;
  
RETURN code;
END@


-------------------------------------------------------------------------------
--  5.(b) Procedure 'process_order' (private module object) showcases :
--             - Row type variable as an INOUT parameter
--             - Usage of row type variables within the procedure
--             - Strong typed cursor as OUT parameter
--             - Usage of strong and weak typed cursor within the procedure 
--             - Passing of cursors between procedures and functions.
-------------------------------------------------------------------------------

ALTER MODULE store_transactions ADD PROCEDURE process_order
  (INOUT purchaseorder_master_p purchaseorder_master_t, 
   OUT products_ordered purchaseorder_details_cursor_t)
LANGUAGE SQL
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------

  DECLARE return_code_v INTEGER DEFAULT 0;
  DECLARE customer_bill_v DECFLOAT; 
  
  ----------------------------
  -- Executable SQL Statements
  ----------------------------

  -- Fetch details of products ordered using the strong typed cursor 
  -- 'products_ordered'
  SET products_ordered = CURSOR FOR SELECT * FROM purchaseorder_details 
    WHERE purchaseorder_master_ID = purchaseorder_master_p.purchaseorder_ID;

  OPEN products_ordered;
 
  -- Call the function 'compute_bill' with the strong typed cursor 
  -- 'products_ordered' as IN parameter and the variable 
  -- 'customer_bill_v' to store the OUT parameter from the function
  SET return_code_v = compute_bill(products_ordered, customer_bill_v);

  SET purchaseorder_master_p.total_amount = customer_bill_v;

  -- Update the 'purchaseorder_master' table with the total amount for 
  -- the transaction
  UPDATE purchaseorder_master 
    SET total_amount = customer_bill_v 
    WHERE purchaseorder_ID = purchaseorder_master_p.purchaseorder_ID;

  -- Update the 'customer_details' table with the total transaction 
  -- amount till date of each customer
  UPDATE customer_details
    SET purchase_amount = purchase_amount + customer_bill_v
    WHERE customer_ID = purchaseorder_master_p.customer_ID;

  -- Open the cursor again for the OUT parameter of the procedure		
	      
  OPEN products_ordered;
END@

-----------------------------------------------------------------------------
--  5.(c) Procedure 'take_order' (public module object) showcases :
--             - Anchored data type as IN parameter
--             - Usage of row type and boolean variables
--             - Associative array functionality
--             - Print using the DBMS_OUTPUT module routine
-----------------------------------------------------------------------------

ALTER MODULE store_transactions ADD PROCEDURE take_order
  (IN customer_ID_p ANCHOR DATA TYPE TO purchaseorder_master.customer_ID, 
   IN productID_quantity_p assoc_array)
LANGUAGE SQL
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------
  
  -- Local variable declaration of row data types
  DECLARE purchaseorder_master_v  purchaseorder_master_t;
  DECLARE products_v purchaseorder_details_t;
 
  -- Local declaration of strong typed cursor 'purchaseorder_details_cursor_t'   
  DECLARE products_cursor purchaseorder_details_cursor_t;
  
  DECLARE count_v INTEGER DEFAULT 0;
  DECLARE product_name_v VARCHAR(10);
  
  ----------------------------
  -- Executable SQL Statements
  ----------------------------
  
  -- Insert customer input into the 'purchaseorder_master' and 
  -- 'purchaseorder_details' table

  SET purchaseorder_master_v.purchaseorder_ID = NEXT VALUE FOR purchaseorder_ID;
  SET purchaseorder_master_v.customer_ID = customer_ID_p;
  
  INSERT INTO purchaseorder_master 
    VALUES (purchaseorder_master_v.purchaseorder_ID,
            purchaseorder_master_v.customer_ID,
            CURRENT DATE, 
            DEFAULT,
            DEFAULT);

  -- Use the ARRAY_FIRST and ARRAY_NEXT functions to retrieve the first
  -- and next index values respectively in the associative array

  SET count_v = ARRAY_FIRST(productID_quantity_p);

  -- Set a value for the global boolean variable 
  SET value_v = TRUE;
  
  while (count_v IS NOT NULL) do
  
    -- Populate the purchaseorder_ID, product_ID and quantity_ordered columns  
    -- of the 'purchaseorder_details' table and update the 'product_details' 
    -- table to reflect the reduction in stock in the store

    INSERT INTO purchaseorder_details 
      VALUES(purchaseorder_master_v.purchaseorder_ID,
             count_v,
             productID_quantity_p[count_v]);
 
    UPDATE product_details
      SET quantity_available = quantity_available 
        - productID_quantity_p[count_v]
      WHERE product_ID = count_v;

    SET value_v = FALSE;
    SET count_v = ARRAY_NEXT(productID_quantity_p, count_v);
  END while;
  
  -- Call procedure 'process_order' passing a row type variable as an 
  -- input parameter and a cursor variable to fetch the output parameter

  CALL process_order
    (purchaseorder_master_v, products_cursor);

  -- Print the Customer Bill
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('-------------');
  CALL DBMS_OUTPUT.PUT_LINE('CUSTOMER BILL');
  CALL DBMS_OUTPUT.PUT_LINE('-------------');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('******************************************');

  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE
    ('TRANSACTION_ID : ' || purchaseorder_master_v.purchaseorder_ID);
  CALL DBMS_OUTPUT.PUT_LINE('--------------');
  CALL DBMS_OUTPUT.NEW_LINE;

  CALL DBMS_OUTPUT.PUT
    ('PRODUCT ID'||'  '||'PRODUCT NAME'||'  '||'QUANTITY ORDERED');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT
    ('----------'||'  '||'------------'||'  '||'----------------');
  CALL DBMS_OUTPUT.NEW_LINE;

  -- Fetch the output from the 'process_order' procedure using the 
  -- cursor 'products_cursor' into the row type variable 'products_v'

  fetch_loop:
    LOOP
      FETCH products_cursor INTO products_v;

      IF products_cursor IS NOT FOUND 
        THEN LEAVE fetch_loop;
      END IF;

      SELECT product_name 
        INTO product_name_v
        FROM product_details
        WHERE product_ID = products_v.product_ID;

      -- Print the products ordered by the customer 
      CALL DBMS_OUTPUT.PUT(products_v.product_ID);
      CALL DBMS_OUTPUT.PUT('          ');
      CALL DBMS_OUTPUT.PUT(product_name_v);
      CALL DBMS_OUTPUT.PUT('         ');
      CALL DBMS_OUTPUT.PUT(products_v.quantity_ordered);
      CALL DBMS_OUTPUT.NEW_LINE;

    END LOOP fetch_loop;
  CLOSE products_cursor;

  -- Print the total bill payable by the customer 
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('TOTAL : ' || purchaseorder_master_v.total_amount);
  CALL DBMS_OUTPUT.PUT_LINE('-----');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('******************************************');
    
END@

-----------------------------------------------------------------------------
--  5.(d) Procedure 'shipping' (public module object) showcases :
--             - Strong typed cursor functionality
--             - Array of rows (collection of row types) functionality
-----------------------------------------------------------------------------

ALTER MODULE store_transactions ADD PROCEDURE shipping()
LANGUAGE SQL
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------
  DECLARE shipping_cost_v BIGINT DEFAULT 0;
  DECLARE count_v INTEGER;

  -- Local variable declaration of collection of rows type 
  -- 'purchaseorder_master_array_t'
  DECLARE order_v purchaseorder_master_array_t;
 
  -- Local variable declaration of row type 'customer_t'
  DECLARE customer_v customer_t;

  -- Local variable declaration of strong typed cursor 
  -- 'purchaseorder_master_cursor_t'
  DECLARE order_details purchaseorder_master_cursor_t;

  ----------------------------
  -- Executable SQL Statements
  ----------------------------

  SET count_v = 1;

  -- Strong typed cursor 'order_details' fetches details of 'UNSHIPPED' 
  -- transactions from the 'purchaseorder_master' table

  SET order_details = CURSOR FOR SELECT * FROM purchaseorder_master 
    WHERE status = 'UNSHIPPED';

  OPEN order_details;
 
  fetch_loop:
    LOOP
      FETCH order_details INTO order_v[count_v];
      
      IF order_details IS NOT FOUND 
        THEN LEAVE fetch_loop;
      END IF;

      -- The shipping cost is waived off for customers with 
      -- a purchase amount of over 8000

      SELECT * INTO customer_v 
        FROM customer_details 
        WHERE customer_ID = order_v[count_v].customer_ID;

      IF customer_v.purchase_amount > 8000
        THEN SET shipping_cost_v = 0;
        ELSE SET shipping_cost_v = 50;
      END IF;
 
      -- Populate the 'shipping' table with details of products shipped to  
      -- the customer
      INSERT INTO shipping 
        VALUES (order_v[count_v].purchaseorder_ID, 
                customer_v.customer_ID, 
                customer_v.address, 
                order_v[count_v].order_date, 
                CURRENT DATE,
                shipping_cost_v);

      -- Update the order status in the 'purchaseorder_master' table 
      UPDATE purchaseorder_master 
        SET status = 'SHIPPED'
        WHERE purchaseorder_ID = order_v[count_v].purchaseorder_ID; 
      
      SET count_v = count_v + 1;
    
    END LOOP fetch_loop;
  CLOSE order_details;
     
END@

echo ------------------------@
echo End Module Body@
echo ------------------------@

-----------------------------------------------------------------------------
-- 6. Create module 'supply_stock' used by the supplier.
-----------------------------------------------------------------------------

echo --------------------------@
echo Start Module Specification@
echo --------------------------@

CREATE OR REPLACE MODULE supply_stock@

-- Create a prototype of the procedure 'process_order'
ALTER MODULE supply_stock PUBLISH PROCEDURE process_order(store_ID_p BIGINT)@

echo ------------------------@
echo End Module Specification@
echo ------------------------@

echo ------------------------@
echo Body of Module@
echo ------------------------@

-----------------------------------------------------------------------------
--  6.(a) Function 'compute_bill' (private module object) showcases :
--            - Support for IN and INOUT parameters
--            - Anchored data type variable as IN parameter
-----------------------------------------------------------------------------

ALTER MODULE supply_stock ADD FUNCTION compute_bill
  (IN supply_product_p ANCHOR DATA TYPE TO ROW OF supply_orders,
   INOUT store_bill_p DECFLOAT,
   IN bulk_order_p INTEGER)
RETURNS INTEGER 
LANGUAGE SQL
BEGIN 
  ----------------------------
  -- Declaration Section
  ---------------------------- 

  DECLARE bill_v DECFLOAT DEFAULT 0;
  DECLARE cost_price_v DECFLOAT DEFAULT 0;

  DECLARE code INTEGER DEFAULT 0;
  DECLARE SQLCODE INTEGER;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN
    SET code = SQLCODE;
    RETURN code;
  END;
		
  ----------------------------
  -- Executable SQL Statements
  ----------------------------

  -- Procure the cost of each product from the 'inventory_details' table
  SELECT cost 
    INTO cost_price_v 
    FROM inventory_details
    WHERE product_ID = supply_product_p.product_ID;
    
  -- Offer a discount to the store in case of bulk orders and compute the bill 
  IF bulk_order_p > 2
    THEN SET bill_v = 0.80 * (cost_price_v * supply_product_p.quantity_required);
  ELSE
    SET bill_v = cost_price_v * supply_product_p.quantity_required;
  END IF;

  SET store_bill_p = store_bill_p + bill_v;

RETURN code;
END@

-----------------------------------------------------------------------------
--  6.(b) Procedure 'process_order' (public module object) showcases :
--            - Weak typed and parameterized cursor functionality
-----------------------------------------------------------------------------

ALTER MODULE supply_stock ADD PROCEDURE process_order(IN store_ID_p BIGINT)
LANGUAGE SQL
BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------
  -- Local variable declaration of anchored data type
  DECLARE supply_product_v ANCHOR DATA TYPE TO ROW OF supply_orders;

  DECLARE return_code_v INTEGER DEFAULT 0;
  DECLARE bulk_order_v INTEGER DEFAULT 0;
  DECLARE store_bill_v DECFLOAT DEFAULT 0;

  -- Declaration of weak typed cursor 'supply_pending'
  DECLARE supply_pending CURSOR;

  ----------------------------
  -- Executable SQL Statements
  ----------------------------
  -- Print the Store Bill
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('-----------');
  CALL DBMS_OUTPUT.PUT_LINE('STORE BILL');
  CALL DBMS_OUTPUT.PUT_LINE('-----------');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('******************************************');

  CALL DBMS_OUTPUT.PUT('STORE ID'||'  '||'PRODUCT ID'||'  ');
  CALL DBMS_OUTPUT.PUT('QUANTITY SUPPLIED');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT('--------'||'  '||'----------'||'  ');
  CALL DBMS_OUTPUT.PUT('-----------------');
  CALL DBMS_OUTPUT.NEW_LINE;

  -- Fetch the count of total number of orders placed by the store
  SELECT count(*) 
    INTO bulk_order_v
    FROM supply_orders
    WHERE store_ID = store_ID_p;
   
  -- Use 'parameterized cursor' to fetch the details of products that 
  -- need to be supplied to the store
  SET supply_pending = CURSOR(store_ID_v BIGINT) FOR SELECT * FROM supply_orders
    WHERE store_ID = store_ID_v AND status = 'PENDING';

  OPEN supply_pending(store_ID_p);

  fetch_loop:
    LOOP
      FETCH supply_pending INTO supply_product_v;

      IF supply_pending IS NOT FOUND
        THEN LEAVE fetch_loop;
      END IF;

      -- Update the 'inventory_details' table once the products are supplied
      UPDATE inventory_details 
        SET quantity = quantity - (supply_product_v.quantity_required)
        WHERE product_ID = supply_product_v.product_ID;
         
      -- Call the function 'compute_bill' to compute the bill for the store.
      -- 'store_bill_v' is an INOUT parameter to the function
      SET return_code_v = compute_bill(supply_product_v, store_bill_v,
                                       bulk_order_v);

      -- Update the supply status in the 'supply_orders' table
      UPDATE supply_orders
        SET status = 'STOCK REPLENISHED' 
        WHERE store_ID = supply_product_v.store_ID 
         AND product_ID = supply_product_v.product_ID 
         AND status = 'PENDING';

      -- Update the 'product_details' table to reflect the replenished stock
      UPDATE product_details
        SET quantity_available = quantity_available 
                                   + supply_product_v.quantity_required
        WHERE product_ID = supply_product_v.product_ID;

      -- Print details of products supplied
      CALL DBMS_OUTPUT.PUT(supply_product_v.store_ID);
      CALL DBMS_OUTPUT.PUT('   ');
      CALL DBMS_OUTPUT.PUT(supply_product_v.product_ID);
      CALL DBMS_OUTPUT.PUT('          ');
      CALL DBMS_OUTPUT.PUT(supply_product_v.quantity_required);
      CALL DBMS_OUTPUT.NEW_LINE;

    END LOOP fetch_loop;
  CLOSE supply_pending;

  -- Print the total bill payable to the supplier
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('TOTAL : ' || store_bill_v);
  CALL DBMS_OUTPUT.PUT_LINE('-----');
  CALL DBMS_OUTPUT.NEW_LINE;
  CALL DBMS_OUTPUT.PUT_LINE('******************************************');

END@
    
echo ------------------------@ 
echo End Module Body@
echo ------------------------@

-----------------------------------------------------------------------------
-- 7. Standalone compiled compound statement showcases :
--            - Full SQL PL support for such blocks
--            - Associative array functionality
--            - Anchored data type functionality
--            - Exit handler within a compiled compound statement
-----------------------------------------------------------------------------

-- 'SET SERVEROUTPUT ON' to redirect the output to standard output
SET SERVEROUTPUT ON@

BEGIN
  ----------------------------
  -- Declaration Section
  ----------------------------
  -- Local variable declaration of associative array type
  DECLARE productID_quantity_v assoc_array;

  DECLARE customer_ID_v ANCHOR DATA TYPE TO purchaseorder_master.customer_ID;
  DECLARE no_of_purchaseorders_v INTEGER;
  DECLARE store_ID_v BIGINT;
 
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE errorLabel CHAR(50) DEFAULT '';

  -- Error Handler in case of SQL error
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE VALUE sqlstate SET MESSAGE_TEXT = errorLabel;

  ----------------------------
  -- Executable SQL Statements
  ----------------------------
  -- Accept the customer input in an associative array
  SET customer_ID_v = 1002;
  SET productID_quantity_v[12] = 6;
  SET productID_quantity_v[13] = 2;
 
  ---------------------------------------------------------------------------
  -- Call the procedure 'store_transactions.take_order' to start the 
  -- customer-store transaction processing
  --------------------------------------------------------------------------- 
 
  -- Pass the associative array input to the 'take_order' procedure for further 
  -- processing
  CALL store_transactions.take_order
    (customer_ID_v, productID_quantity_v);
  
  ---------------------------------------------------------------------------
  -- Call the 'store_transactions.shipping' procedure for product delivery
  ---------------------------------------------------------------------------
  -- Fetch the count of number of 'UNSHIPPED' orders

  SET errorLabel = 'SELECT COUNT';

  SELECT count(*) 
    INTO no_of_purchaseorders_v 
    FROM purchaseorder_master 
    WHERE status = 'UNSHIPPED';

  -- Call the 'shipping' procedure based on the number of unshipped orders
  IF no_of_purchaseorders_v > 2
     THEN CALL store_transactions.shipping();
  END IF;

  ------------------------------------------------------------------------------
  -- Call the procedure 'supply_stock.process_order' to start the supplier-store
  -- transaction processing
  ------------------------------------------------------------------------------

  SET store_ID_v = 1106009;  

  -- Use 2-part name to call the object 'process_order' common to both the modules 
  CALL supply_stock.process_order(store_ID_v);

END@

SET SERVEROUTPUT OFF@

------------------------------------------------
-- 8. Drop the tables and types created
------------------------------------------------

DROP TABLE purchaseorder_master@
DROP TABLE purchaseorder_details@
DROP TABLE customer_details@
DROP TABLE product_details@
DROP TABLE shipping@
DROP TABLE inventory_details@
DROP TABLE supply_orders@
DROP TYPE order_stock_t@
DROP TYPE product_stock_t@
DROP TYPE assoc_array@
