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
-- Source File Name: saBankDemoViewDDL.db2
--
-- Version:          11.5.6+    
--
-- Description: 
--
--
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

--==========================================================================   
--  Show all customers of Branch 1 - Meridian
--==========================================================================   

CREATE VIEW sa_demo.meridian_customers (name, phone, location, branch_name) AS
 SELECT c.name, c.phone, c.location, b.name
 FROM   (sa_demo.customers AS c
		JOIN sa_demo.accounts AS a
                	ON (a.customer_id = c.customer_id))
		JOIN sa_demo.branches AS b
                	ON (b.branch_id = a.branch_id)
 WHERE  b.name='Meridian';

--==========================================================================   
--  Show all customers of Branch 2 - San Carlos
--==========================================================================   

CREATE VIEW sa_demo.sancarlos_customers (name, phone, location, branch_name) AS 
 SELECT c.name, c.phone, c.location, b.name
 FROM   (sa_demo.customers AS c
		JOIN sa_demo.accounts AS a
			ON (a.customer_id = c.customer_id))
		JOIN sa_demo.branches AS b
			ON (b.branch_id = a.branch_id)
 WHERE  b.name='San Carlos';

--==========================================================================   
--  Show the nearest branch of each customer
--==========================================================================   

CREATE VIEW sa_demo.closest_branch AS 
 WITH distance_to_customers(c_id, b_id, distance) AS 
      (SELECT c.customer_id, b.branch_id, ST_Distance(c.location, b.location)
       FROM   sa_demo.customers c, sa_demo.branches b
       WHERE  c.customer_id > 0) 
 SELECT c.name, c.location, c.phone, d_c.b_id, d_c.distance
 FROM   distance_to_customers d_c, sa_demo.customers c 
 WHERE  d_c.c_id=c.customer_id AND  
        d_c.distance <= ALL(SELECT distance
                            FROM   distance_to_customers d_c2
                            WHERE  d_c2.c_id=d_c.c_id);

--==========================================================================   
--  Show all savings balance
--==========================================================================   

CREATE VIEW sa_demo.customers_savings AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   sa_demo.accounts a, sa_demo.customers c 
 WHERE  a.type = 'Saving' AND 
        a.customer_id = c.customer_id;

--==========================================================================   
--  Show all checking accounts balance
--==========================================================================   

CREATE VIEW sa_demo.customers_checkings AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   sa_demo.accounts a, sa_demo.customers c 
 WHERE  a.type = 'Checking' AND
        a.customer_id = c.customer_id;

--==========================================================================   
--  Show checking+saving accounts balance
--==========================================================================   

CREATE VIEW sa_demo.customers_totals AS 
 WITH account_sum (customer_id, sum_balance) AS
  (SELECT   act.customer_id, SUM(act.balance)
   FROM     sa_demo.accounts act
   GROUP BY act.customer_id
   )
 SELECT c.customer_id, c.name, c.phone, c.location, account_sum.sum_balance
 FROM sa_demo.customers c, account_sum
 WHERE account_sum.customer_id = c.customer_id;


--==========================================================================   
--  Show the savings balance of all customers 0.05 degrees (about 3.5 miles) 
--  from my branches
--==========================================================================   

CREATE VIEW sa_demo.closest_savings AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   sa_demo.accounts a, sa_demo.branches b, sa_demo.customers c 
 WHERE  st_distance(b.location, c.location) > .05 AND 
        a.type = 'Saving' AND
        a.customer_id = c.customer_id AND 
        a.balance > 45000;

--==========================================================================   
--  Show the checking balance of all customers 3.5 miles (about 0.05 degrees)
--  from my branches
--==========================================================================   

CREATE VIEW sa_demo.closest_checking AS 
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   sa_demo.accounts a, sa_demo.branches b, sa_demo.customers c 
 WHERE  st_distance(b.location, c.location, 'MILE') > 3.5 AND 
        a.TYPE = 'Checking' AND
        a.customer_id = c.customer_id AND 
        a.balance > 2000;

--==========================================================================   
--  Branch Zone Overlap Query
--  All the customer with more than 50000 in their saving accounts in overlapping zones
--==========================================================================   

CREATE VIEW sa_demo.overlap_zone AS
 SELECT c.customer_id, c.name, c.phone, c.location, a.balance
 FROM   sa_demo.customers c, sa_demo.branches b1, sa_demo.branches b2, 
        sa_demo.accounts a
 WHERE  ST_Within(c.location,
          ST_Intersection(
		    ST_Buffer(b1.location ,0.04),
            ST_Buffer(b2.location ,0.04) 
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

CREATE TABLE sa_demo.branch_buffers(
       sa_row_id            INTEGER,
       geometry   ST_Polygon ) organize by row;

INSERT INTO sa_demo.branch_buffers(sa_row_id, geometry)
  (SELECT sa_row_id, ST_Buffer(location, 0.04) AS ST_Polygon 
   FROM   sa_demo.branches);

--==========================================================================   
--  Create aggregate view of Savings balance per census block
--==========================================================================   

CREATE VIEW sa_demo.avg_savings_block AS
  SELECT cb.geometry, cb.sa_row_id, avg_blocks.avg_balance
  FROM   sa_demo.sj_census_blocks AS cb,
         (SELECT blocks.sa_row_id, avg(customer_savings.balance) AS avg_balance
          FROM   sa_demo.sj_census_blocks AS blocks,
                (SELECT c.location, a.balance
                 FROM   sa_demo.customers AS c, sa_demo.accounts AS a
                 WHERE (a.type='Saving') AND
                       (a.customer_id=c.customer_id) 
                ) as customer_savings
          WHERE  (ST_Within(customer_savings.location, blocks.geometry)=1 )
          GROUP BY blocks.sa_row_id
          ) as avg_blocks
  WHERE cb.sa_row_id=avg_blocks.sa_row_id;

--==========================================================================   
--  Show the areas of Census blocks(SELBLOCKS) that have average
--  income greater than 80% of my maximum savings balance
--==========================================================================   
-- all_customer = all customers with a savings account

CREATE VIEW sa_demo.prospects AS
  WITH max_blocks(amount) AS
    (SELECT MAX(group_blocks.average) 
     FROM
       (SELECT blocks.sa_row_id, AVG(all_customers.balance) AS average
        FROM   sa_demo.sj_census_blocks blocks,
               (SELECT c.location, a.balance
                FROM   sa_demo.customers AS c, sa_demo.accounts AS a
                WHERE  (a.type='Saving') AND
                       (a.customer_id=c.customer_id) 
               ) AS all_customers
        WHERE  (ST_Within(all_customers.location, blocks.geometry)=1)
        GROUP BY blocks.sa_row_id
        ) AS group_blocks
     )
  SELECT blocks.geometry, blocks.sa_row_id, average__1
  FROM   sa_demo.sj_census_blocks AS blocks, max_blocks AS mx
  WHERE  average__1 > (0.8 * mx.amount);  
