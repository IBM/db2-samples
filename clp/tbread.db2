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
-- SOURCE FILE NAME: tbread.db2
--
-- SAMPLE: How to read tables
--
-- SQL STATEMENTS USED:
--         SELECT
--         TERMINATE
--
-- OUTPUT FILE: tbread.out (available in the online documentation)
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

-- a simple SUBSELECT

-- display the contents of the 'org' table
SELECT * FROM org;

-- display only two columns from the 'org' table
SELECT deptnumb, deptname FROM org;

-- a basic SUBSELECT

-- display the contents of the 'org' table
SELECT * FROM org;

-- use a WHERE clause to display only a few rows
SELECT deptnumb, deptname FROM org WHERE deptnumb < 30;

-- a 'GROUP BY' SUBSELECT

-- display the contents of the 'org' table
SELECT * FROM org;

-- use a GROUP BY clause 
SELECT division, MAX(deptnumb) AS MAX_deptnumb FROM org GROUP BY division;

-- a SUBSELECT with WHERE and GROUP BY clauses

-- display the contents of the 'org' table
SELECT * FROM org;

SELECT division, MAX(deptnumb) AS MAX_deptnumb 
  FROM org
  WHERE location NOT IN 'New York'
  GROUP BY division HAVING division LIKE '%ern';

-- a 'ROW' SUBSELECT

-- display the contents of the 'org' table
SELECT * FROM org;

SELECT deptnumb, deptname
  FROM org
  WHERE location = 'New York';

-- a FULLSELECT with UNION

-- display the contents of the 'org' table
SELECT * FROM org;

SELECT deptnumb, deptname 
  FROM org
  WHERE deptnumb < 20 UNION VALUES(7, 'New Deptname');

-- a SELECT with 'WITH' clause 

-- display the contents of the 'org' table
SELECT * FROM org;

WITH new_org(new_deptnumb, new_deptname)
  AS(SELECT deptnumb, deptname
       FROM org
       UNION VALUES(7, 'New Dept 1'),
                   (77, 'New Dept 2'),
                   (777, 'New Dept 3'))
  SELECT new_deptnumb, new_deptname
    FROM new_org
    WHERE new_deptnumb > 70
    ORDER BY new_deptname;

-- SUBSELECT from multiple tables

-- display the contents of the 'org' table
SELECT * FROM org;

-- display the contents of the 'department' table
SELECT * FROM department;

SELECT deptnumb, o.deptname, deptno, d.deptname
  FROM org o, department d
  WHERE deptnumb <= 15 AND deptno LIKE '%11';

-- SUBSELECT from a joined table

-- display the contents of the 'org' table

SELECT * FROM org;

-- display the contents of the 'department' table
SELECT * FROM department;

SELECT deptnumb, manager, deptno, mgrno
  FROM org INNER JOIN department
  ON manager = INTEGER(mgrno)
  WHERE deptnumb BETWEEN 20 AND 100;

-- SUBSELECT using a SUBQUERY

-- display the contents of the 'org' table
SELECT * FROM org;

SELECT deptnumb, deptname
  FROM org
  WHERE deptnumb < (SELECT AVG(deptnumb) FROM org);

-- SUBSELECT using a CORRELATED SUBQUERY

-- display the contents of the 'org' table
SELECT * FROM org;

SELECT deptnumb, deptname
  FROM org o1
  WHERE deptnumb > (SELECT AVG(deptnumb)
                      FROM org o2
                      WHERE o2.division = o1.division);

-- SUBSELECT using GROUPING SETS

-- display a partial content of the 'employee' table
SELECT job, edlevel, comm
  FROM employee
  WHERE job IN('DESIGNER', 'FIELDREP');

SELECT job, edlevel, SUM(comm) AS SUM_comm
  FROM employee
  WHERE job IN('DESIGNER', 'FIELDREP')
  GROUP BY GROUPING SETS((job, edlevel), (job));

-- SUBSELECT using ROLLUP

-- display a partial content of the 'employee' table
SELECT job, edlevel, comm
  FROM employee
  WHERE job IN('DESIGNER', 'FIELDREP');

SELECT job, edlevel, SUM(comm) AS SUM_comm
  FROM employee
  WHERE job IN('DESIGNER', 'FIELDREP')
  GROUP BY ROLLUP(job, edlevel);

-- SUBSELECT using CUBE

-- display a partial content of the 'employee' table
SELECT job, edlevel, comm
  FROM employee
  WHERE job IN('DESIGNER', 'FIELDREP');

SELECT job, edlevel, SUM(comm) AS SUM_comm
  FROM employee
  WHERE job IN('DESIGNER', 'FIELDREP')
  GROUP BY CUBE(job, edlevel);

-- SELECT using RECURSIVE COMMON TABLE EXPRESSION

-- display the content of the 'department' table
SELECT * FROM department;

WITH rcte_department(deptno, deptname, admrdept)
  AS(SELECT root.deptno, root.deptname, root.admrdept
       FROM department root
       WHERE root.deptname = 'SUPPORT SERVICES'
       UNION ALL SELECT child.deptno, child.deptname, child.admrdept
                   FROM department child, rcte_department parent
                   WHERE child.admrdept = parent.deptno)
  SELECT * FROM rcte_department;

-- SELECT using QUERY SAMPLING

-- computing AVG(salary) without sampling
SELECT AVG(salary) AS AVG_salary FROM employee;

-- computing AVG(SALARY) with query sampling
--                        - ROW LEVEL SAMPLING   
--                        - BLOCK LEVEL SAMPLING 
-- ROW LEVEL SAMPLING : use the keyword 'BERNOULLI'
-- for a sampling percentage of P, each row of the table is
-- selected for the inclusion in the result with a probability
-- of P/100, independently of the other rows in T

SELECT AVG(salary) AS AVG_salary FROM employee
  TABLESAMPLE BERNOULLI(25) REPEATABLE(5);

-- BLOCK LEVEL SAMPLING : use the keyword 'SYSTEM'
-- for a sampling percentage of P, each row of the table is
-- selected for inclusion in the result with a probability
-- of P/100, not necessarily independently of the other rows
-- in T, based upon an implementation-dependent algorithm

SELECT AVG(salary) AS AVG_salary FROM employee
  TABLESAMPLE SYSTEM(50) REPEATABLE(1234);

-- REPEATABLE clause ensures that repeated executions of that
-- table reference will return identical results for the same
-- value of the repeat argument (in parenthesis)

-- disconnect from the database

CONNECT RESET;

TERMINATE;
