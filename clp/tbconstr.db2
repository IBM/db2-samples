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
-- SOURCE FILE NAME: tbconstr.db2
--
-- SAMPLE: How to create, use, and drop constraints
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         DELETE
--         DROP TABLE
--         INSERT
--         SELECT 
--         TERMINATE 
--         UPDATE
--
-- OUTPUT FILE: tbconstr.out (available in the online documentation)
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

-- turn off the Auto-commit option 
UPDATE COMMAND OPTIONS USING c OFF;

-----------------------------------------------------------------------------
-- Illustration of 'NOT NULL' constraint 
-----------------------------------------------------------------------------
-- turn off the Echo Current Command option to suppress the printing of the 
-- echo command
UPDATE COMMAND OPTIONS USING v OFF;

! echo ------------------NOT NULL constraint-----------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-- create a table
CREATE TABLE emp_sal(lastname VARCHAR(10) NOT NULL,
                     firstname VARCHAR(10),
                     salary DECIMAL(7, 2));

COMMIT;

-- insert values into the table that violate the constraint
INSERT INTO emp_sal VALUES(NULL, 'PHILIP', 17000.00);

-- drop the table
DROP TABLE emp_sal;

-- turn off the Echo Current Command option to suppress the printing of the 
-- echo command
UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'UNIQUE' constraint 
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo ------------------UNIQUE constraint-----------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- create a table
CREATE TABLE emp_sal(lastname VARCHAR(10) NOT NULL,
                     firstname VARCHAR(10) NOT NULL,
                     salary DECIMAL(7, 2),
  CONSTRAINT unique_cn UNIQUE(lastname, firstname));

COMMIT;

-- insert values into the table that violate the constraint
INSERT INTO emp_sal VALUES('SMITH', 'PHILIP', 17000.00),
                          ('SMITH', 'PHILIP', 21000.00);

-- drop the constraint 
ALTER TABLE emp_sal DROP CONSTRAINT unique_cn;

-- drop the table
DROP TABLE emp_sal;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'PRIMARY KEY' constraint
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo ---------------PRIMARY KEY constraint----------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- create a table
CREATE TABLE emp_sal(lastname VARCHAR(10) NOT NULL,
                     firstname VARCHAR(10) NOT NULL,
                     salary DECIMAL(7, 2),
  CONSTRAINT pk_cn PRIMARY KEY(lastname, firstname));

COMMIT;

-- insert values into the table that violate the constraint
INSERT INTO emp_sal VALUES('SMITH', 'PHILIP', 17000.00),
                          ('SMITH', 'PHILIP', 21000.00);

-- drop the constraint
ALTER TABLE emp_sal DROP CONSTRAINT pk_cn;

-- drop the table
DROP TABLE emp_sal;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'CHECK' constraint
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -------------------CHECK constraint-----------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- create a table
CREATE TABLE emp_sal(lastname VARCHAR(10),
                     firstname VARCHAR(10),
                     salary DECIMAL(7, 2),
  CONSTRAINT check_cn CHECK(salary < 25000.00));

COMMIT;

-- insert values into the table that violate the constraint
INSERT INTO emp_sal VALUES('SMITH', 'PHILIP', 27000.00);

-- drop the constraint
ALTER TABLE emp_sal DROP CONSTRAINT check_cn;

-- drop the table
DROP TABLE emp_sal;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'INFORMATIONAL' constraint
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo ------------------INFORMATIONAL constraint------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- create a table
CREATE TABLE tab_emp (empno INTEGER NOT NULL PRIMARY KEY,
                 name VARCHAR(10),
                 firstname VARCHAR(20),
                 salary INTEGER CONSTRAINT minsalary
                                  CHECK (salary >= 25000)
                                NOT ENFORCED
                                ENABLE QUERY OPTIMIZATION);

COMMIT;

-- insert data that doesn't satisfy the constraint 'minsalary'.
-- database manager does not enforce the constraint for IUD operations
INSERT INTO tab_emp VALUES(1, 'SMITH', 'PHILIP', 1000);

-- alter the constraint to make it ENFORCED by database manager
ALTER TABLE tab_emp ALTER CHECK minsalary ENFORCED;

-- delete entries from 'tab_emp' Table
DELETE FROM tab_emp;

-- alter the constraint to make it ENFORCED by database manager
ALTER TABLE tab_emp ALTER CHECK minsalary ENFORCED;

-- insert into the table with data not conforming to the constraint 
-- 'minsalary'. Database manager now enforces the constraint for IUD 
-- operations
INSERT INTO tab_emp VALUES(1, 'SMITH', 'PHILIP', 1000);

-- drop the table
DROP TABLE tab_emp;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'WITH DEFAULT' constraint
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo ------------------WITH DEFAULT constraint-------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- create a table
CREATE TABLE emp_sal(lastname VARCHAR(10),
                     firstname VARCHAR(10),
                     salary DECIMAL(7, 2) WITH DEFAULT 17000.00);

COMMIT;

-- insert into the table 
INSERT INTO emp_sal(lastname, firstname)
             VALUES('SMITH' , 'PHILIP'),
                   ('PARKER', 'JOHN'),
                   ('PEREZ' , 'MARIA');

-- display the content of the table
SELECT * FROM emp_sal;

-- drop the table
DROP TABLE emp_sal;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- create two tables 'tab_dept' and 'tab_emp' for illustrating the FOREIGN KEY
-- constraint
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo ------------Create Tables for FOREIGN KEY---------------------;

UPDATE COMMAND OPTIONS USING v ON;

CREATE TABLE tab_dept (deptno CHAR(3) NOT NULL,
                  deptname VARCHAR(20),
                  CONSTRAINT pk_tab_dept PRIMARY KEY(deptno));

-- insert rows into the table
INSERT INTO tab_dept VALUES('A00', 'ADMINISTRATION'),
                       ('B00', 'DEVELOPMENT'), 
                       ('C00', 'SUPPORT');

CREATE TABLE tab_emp (empno CHAR(4),
                 empname VARCHAR(10),
                 dept_no CHAR(3));

-- insert rows into the table
INSERT INTO tab_emp VALUES('0010', 'Smith', 'A00'),
                      ('0020', 'Ngan', 'B00'), 
                      ('0030', 'Lu', 'B00'), 
                      ('0040', 'Wheeler', 'B00'), 
                      ('0050', 'Burke', 'C00'), 
                      ('0060', 'Edwards', 'C00'), 
                      ('0070', 'Lea', 'C00'); 

COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of how FOREIGN key works on INSERT
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo ---------How FOREIGN KEY works on INSERT----------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- display initial content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- create a foreign key
ALTER TABLE tab_emp ADD CONSTRAINT fk_dept 
                    FOREIGN KEY(dept_no)
                    REFERENCES tab_dept(deptno);

COMMIT;

-- insert into the parent table
INSERT INTO tab_dept VALUES('D00', 'SALES');

-- insert into the child table
INSERT INTO tab_emp VALUES('0080', 'Pearce', 'E03');

-- display the final content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- rollback the transaction
ROLLBACK;

-- drop the foreign key
ALTER TABLE tab_emp DROP CONSTRAINT fk_dept;

COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'ON UPDATE NO ACTION' FOREIGN KEY
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -----------ON UPDATE NO ACTION FOREIGN KEY-----------------;

UPDATE COMMAND OPTIONS USING v ON;

-- display initial content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- create a foreign key
ALTER TABLE tab_emp ADD CONSTRAINT fk_dept
                    FOREIGN KEY(dept_no)
                    REFERENCES tab_dept(deptno) ON UPDATE NO ACTION;

COMMIT;

-- update the parent table
UPDATE tab_dept SET deptno = 'E01' WHERE deptno = 'A00';

UPDATE tab_dept SET deptno = 
  CASE 
    WHEN deptno = 'A00' THEN 'B00'
    WHEN deptno = 'B00' THEN 'A00'
  END
  WHERE deptno = 'A00' OR deptno = 'B00';

-- update the child table
UPDATE tab_emp SET dept_no = 'G11' WHERE empname = 'Wheeler';

-- display the final content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- rollback the transaction
ROLLBACK;

-- drop the foreign key
ALTER TABLE tab_emp DROP CONSTRAINT fk_dept;

COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'ON UPDATE RESTRICT' FOREIGN KEY
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -----------ON UPDATE RESTRICT FOREIGN KEY-------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- display initial content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- create a foreign key
ALTER TABLE tab_emp ADD CONSTRAINT fk_dept
                    FOREIGN KEY(dept_no)
                    REFERENCES tab_dept(deptno) ON UPDATE RESTRICT;

COMMIT;

-- update the parent table
UPDATE tab_dept SET deptno = 'E01' WHERE deptno = 'A00';

UPDATE tab_dept SET deptno =
  CASE
    WHEN deptno = 'A00' THEN 'B00'
    WHEN deptno = 'B00' THEN 'A00'
  END
  WHERE deptno = 'A00' OR deptno = 'B00';

-- update the child table
UPDATE tab_emp SET dept_no = 'G11' WHERE empname = 'Wheeler';

-- display the final content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- rollback the transaction
ROLLBACK;

-- drop the foreign key
ALTER TABLE tab_emp DROP CONSTRAINT fk_dept;

COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'ON DELETE CASCADE' FOREIGN KEY
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -----------ON DELETE CASCADE FOREIGN KEY--------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- display initial content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- create a foreign key
ALTER TABLE tab_emp ADD CONSTRAINT fk_dept
                    FOREIGN KEY(dept_no)
                    REFERENCES tab_dept(deptno) ON DELETE CASCADE;

COMMIT;

-- delete from the parent table
DELETE FROM tab_dept WHERE deptno = 'C00';

-- display the content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- delete from the child table
DELETE FROM tab_emp WHERE empname = 'Wheeler';

-- display the final content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- rollback the transaction
ROLLBACK;

-- drop the foreign key
ALTER TABLE tab_emp DROP CONSTRAINT fk_dept;
 
COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'ON DELETE SET NULL' FOREIGN KEY
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -----------ON DELETE SET NULL FOREIGN KEY-------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- display initial content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- create a foreign key
ALTER TABLE tab_emp ADD CONSTRAINT fk_dept
                    FOREIGN KEY(dept_no)
                    REFERENCES tab_dept(deptno) ON DELETE SET NULL;

COMMIT;

-- delete from the parent table
DELETE FROM tab_dept WHERE deptno = 'C00';

-- display the content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- delete from the child table
DELETE FROM tab_emp WHERE empname = 'Wheeler';

-- display the final content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- rollback the transaction
ROLLBACK;

-- drop the foreign key
ALTER TABLE tab_emp DROP CONSTRAINT fk_dept;

COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- Illustration of 'ON DELETE NO ACTION' FOREIGN KEY
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -----------ON DELETE NO ACTION FOREIGN KEY------------------;

UPDATE COMMAND OPTIONS USING v ON;

-- display initial content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- create a foreign key
ALTER TABLE tab_emp ADD CONSTRAINT fk_dept
                    FOREIGN KEY(dept_no)
                    REFERENCES tab_dept(deptno) ON DELETE NO ACTION;

COMMIT;

-- delete from the parent table
DELETE FROM tab_dept WHERE deptno = 'C00';

-- delete from the child table
DELETE FROM tab_emp WHERE empname = 'Wheeler';

-- display the final content of the tables 'tab_dept' and 'tab_emp'

SELECT * FROM tab_dept;

SELECT * FROM tab_emp;

-- rollback the transaction
ROLLBACK;

-- drop the foreign key
ALTER TABLE tab_emp DROP CONSTRAINT fk_dept;

COMMIT;

UPDATE COMMAND OPTIONS USING v OFF;

! echo --------------------------------------------------------------;

UPDATE COMMAND OPTIONS USING v ON;

-----------------------------------------------------------------------------
-- drop the two tables 'tab_dept' and 'tab_emp'
-----------------------------------------------------------------------------
UPDATE COMMAND OPTIONS USING v OFF;

! echo -------------Drop the Tables created for FOREIGN KEY----------;

UPDATE COMMAND OPTIONS USING v ON;

DROP TABLE tab_dept;

DROP TABLE tab_emp;

COMMIT;

-- disconnect from the database
CONNECT RESET;

TERMINATE;
