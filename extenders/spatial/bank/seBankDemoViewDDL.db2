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
-- Product Name:     DB2 Spatial Extender 
--
-- Source File Name: seBankDemoViewDDL.db2
--
-- Version:          10.5.0      
--
-- Description: 
--
--
--
-- For more information about the DB2 Spatial Extender Bank Demo scripts,
-- see the seBankDemoREADME.txt file.
--
-- For more information about DB2 SE, see the "DB2 Spatial Extender User Guide".
--
-- For the latest information on DB2 Spatial Extender and the Bank Demo
-- refer to the DB2 Spatial Extender website at
--     http://www.software.ibm.com/software/data/spatial/db2spatial
----------------------------------------------------------------------------

--==========================================================================   
--  Show all customers of Branch 1 - Meridian
--==========================================================================   

CREATE VIEW se_demo.meridian_customers (name, phone, location, branch_name) AS
 SELECT c.name, c.phone, c.location, b.name
 FROM   (se_demo.customers AS c
		JOIN se_demo.accounts AS a
                	ON (a.customer_id = c.customer_id))
		JOIN se_demo.branches AS b
                	ON (b.branch_id = a.branch_id)
 WHERE  b.name='Meridian';

--==========================================================================   
--  Show all customers of Branch 2 - San Carlos
--==========================================================================   

CREATE VIEW se_demo.sancarlos_customers (name, phone, location, branch_name) AS 
 SELECT c.name, c.phone, c.location, b.name
 FROM   (se_demo.customers AS c
		JOIN se_demo.accounts AS a
			ON (a.customer_id = c.customer_id))
		JOIN se_demo.branches AS b
			ON (b.branch_id = a.branch_id)
 WHERE  b.name='San Carlos';

--==========================================================================   
--  Show the nearest branch of each customer
--==========================================================================   

CREATE VIEW se_demo.closest_branch AS 
 WITH distance_to_customers(c_id, b_id, distance) AS 
      (SELECT c.customer_id, b.branch_id, db2gse.ST_Distance(c.location, b.location)
       FROM   se_demo.customers c, se_demo.branches b
       WHERE  c.customer_id > 0) 
 SELECT c.name, c.location, c.phone, d_c.b_id, d_c.distance
 FROM   distance_to_customers d_c, se_demo.customers c 
 WHERE  d_c.c_id=c.customer_id AND  
        d_c.distance <= ALL(SELECT distance
                           FROM   distance_to_customers d_c2
                           WHERE  d_c2.c_id=d_c.c_id);

--==========================================================================   
--  Show all savings balance
--==========================================================================   

CREATE VIEW se_demo.customers_savings AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   se_demo.accounts a, se_demo.customers c 
 WHERE  a.type = 'Saving' AND 
        a.customer_id = c.customer_id;

--==========================================================================   
--  Show all checking accounts balance
--==========================================================================   

CREATE VIEW se_demo.customers_checkings AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   se_demo.accounts a, se_demo.customers c 
 WHERE  a.type = 'Checking' AND
        a.customer_id = c.customer_id;

--==========================================================================   
--  Show checking+saving accounts balance
--==========================================================================   

CREATE VIEW se_demo.customers_totals AS 
 WITH account_sum (customer_id, sum_balance) AS
  (SELECT   act.customer_id, SUM(act.balance)
   FROM     se_demo.accounts act
   GROUP BY act.customer_id
   )
 SELECT c.customer_id, c.name, c.phone, c.location, account_sum.sum_balance
 FROM se_demo.customers c, account_sum
 WHERE account_sum.customer_id = c.customer_id;


--==========================================================================   
--  Show the savings balance of all customers 0.05(3.5) miles from my branches
--==========================================================================   

CREATE VIEW se_demo.closest_savings AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   se_demo.accounts a, se_demo.branches b, se_demo.customers c 
 WHERE  db2gse.st_distance(b.location, c.location) > .05 AND 
        a.type = 'Saving' AND
        a.customer_id = c.customer_id AND 
        a.balance > 45000;

--==========================================================================   
--  Show the checking balance of all customers 0.05 miles from my branches
--==========================================================================   

CREATE VIEW se_demo.closest_checking AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   se_demo.accounts a, se_demo.branches b, se_demo.customers c 
 WHERE  db2gse.st_distance(b.location, c.location) > .05 AND 
        a.TYPE = 'Checking' AND
        a.customer_id = c.customer_id AND 
        a.balance > 2000;

--==========================================================================   
--  Branch Zone Overlap Query
--  All the customer with more than 50000 in their saving accounts in overlapping zones
--==========================================================================   

CREATE VIEW se_demo.overlap_zone AS
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   se_demo.customers c, se_demo.branches b1, se_demo.branches b2, 
        se_demo.accounts a
 WHERE  db2gse.ST_Within(c.location,
          db2gse.ST_Intersection(
		    db2gse.ST_Buffer(b1.location ,0.04),
            db2gse.ST_Buffer(b2.location ,0.04) 
          ) 
        )=1    
        AND b1.branch_id <> b2.branch_id 
        AND a.balance > 50000 AND a.type = 'Saving' 
        AND a.customer_id = c.customer_id 
        AND (a.branch_id=b1.branch_id OR a.branch_id=b2.branch_id);

--==========================================================================   
--  Branch Buffers 
--  Show the areas 0.04 miles away from my branches
--==========================================================================   
-- This table is needed because of a limitation in ArcExplorer.
-- ArcExplorer can't visualize views when the geometry changes type.

CREATE TABLE se_demo.branch_buffers(
       se_row_id            INTEGER,
       geometry   db2gse.ST_Polygon ) organize by row;

INSERT INTO se_demo.branch_buffers(se_row_id, geometry)
  (SELECT se_row_id, TREAT(db2gse.ST_Buffer(location, 0.04) AS db2gse.ST_Polygon) 
   FROM   se_demo.branches);

--==========================================================================   
--  Create aggregate view of Savings balance per census block
--==========================================================================   

CREATE VIEW se_demo.avg_savings_block AS
  SELECT cb.geometry, cb.se_row_id, avg_blocks.avg_balance
  FROM   se_demo.sj_census_blocks AS cb,
         (SELECT blocks.se_row_id, avg(customer_savings.balance) AS avg_balance
          FROM   se_demo.sj_census_blocks AS blocks,
                (SELECT c.location, a.balance
                 FROM   se_demo.customers AS c, se_demo.accounts AS a
                 WHERE (a.type='Saving') AND
                       (a.customer_id=c.customer_id) 
                ) as customer_savings
          WHERE  (db2gse.ST_Within(customer_savings.location, blocks.geometry)=1 )
          GROUP BY blocks.se_row_id
          ) as avg_blocks
  WHERE cb.se_row_id=avg_blocks.se_row_id;

--==========================================================================   
--  Show the areas of Census blocks(SELBLOCKS) that have average
--  income greater than 80% of my maximum savings balance
--==========================================================================   
-- all_customer = all customers with a savings account

CREATE VIEW se_demo.prospects AS
  WITH max_blocks(amount) AS
    (SELECT MAX(group_blocks.average) 
     FROM
       (SELECT blocks.se_row_id, AVG(all_customers.balance) AS average
        FROM   se_demo.sj_census_blocks blocks,
               (SELECT c.location, a.balance
                FROM   se_demo.customers AS c, se_demo.accounts AS a
                WHERE  (a.type='Saving') AND
                       (a.customer_id=c.customer_id) 
               ) AS all_customers
        WHERE  (db2gse.ST_Within(all_customers.location, blocks.geometry)=1)
        GROUP BY blocks.se_row_id
        ) AS group_blocks
     )
  SELECT blocks.geometry, blocks.se_row_id, average__1
  FROM   se_demo.sj_census_blocks AS blocks, max_blocks AS mx
  WHERE  average__1 > (0.8 * mx.amount);  
