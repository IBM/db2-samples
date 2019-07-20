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
-- SOURCE FILE NAME: lbac.db2
--
-- SAMPLE: How to take advantage of DB2 LBAC (Label Based Access Control) 
--         feature 
-- 
-- PREREQUISITES FOR RUNNING THE SAMPLE:
--   The sample assumes the existance of the following users along with 
--   the specified passwords
--        secadm   with password "secadm123"
--        joe      with password "joe123"
--        bob      with password "bob123"
--        pat      with password "pat123"    
-- 
-- SQL STATEMENTS USED:
--         CONNECT
--         CREATE SECURITY LABEL 
--         CREATE SECURITY POLICY 
--         CREATE TABLE 
--         DELETE
--         DROP SECURITY LABEL
--         DROP TABLE 
--         GRANT SECURITY LABEL 
--         GRANT EXEMPTION
--         REVOKE SECURITY LABEL 
--         REVOKE EXEMPTION 
--         INSERT
--         UPDATE 
--         SELECT 
--
-- OUTPUT FILE: lbac.out (available in the online documentation)
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

-- Disconnect from any existing database connection.
CONNECT RESET;

-- This example shows how to take advantage of the DB2 LBAC feature. 
-- It shows LBAC being used in a hypothetical government setting.

-- Grant SECADM authority to a user secadm
-- An user with SYSADM authority can grant SECADM authority to a user

CONNECT TO sample;
GRANT SECADM ON DATABASE TO USER secadm;

-- Connect as the user with SECADM authority 
CONNECT TO sample USER secadm USING secadm123;

-- First, a user with SECADM authority creates the security label components 
-- that will be part of the security policy. This sample uses three security 
-- label components: level, departments, and groups.

--  The level component is of type ARRAY and has these elements:
--  
--      TOP SECRET        (Highest)
--      SECRET
--      CONFIDENTIAL
--      UNCLASSIFIED      (Lowest)
-- 
--  This statement creates the level component:

CREATE SECURITY LABEL COMPONENT level ARRAY ['TOP SECRET', 
                                             'SECRET', 
                                             'CONFIDENTIAL', 
                                             'UNCLASSIFIED'];

--  The departments component is of type SET and has these elements:
--  
--      ALPHA, SIGMA, and DELTA
-- 
--  This statement creates the departments component:

CREATE SECURITY LABEL COMPONENT departments SET {'ALPHA', 'DELTA', 'SIGMA'};

--  The groups component is of type TREE and has these elements:
--  
--          G1  (ROOT)
--       +--+--+
--       |     |
--      G2     G3
--          +--+--+
--          |     |
--         G4     G5
-- 
--  This statement creates the groups component:

CREATE SECURITY LABEL COMPONENT groups
  TREE ('G1' ROOT,
        'G2' UNDER 'G1',
        'G3' UNDER 'G1',
        'G4' UNDER 'G3',
        'G5' UNDER 'G3');

--  Next, a user with SECADM authority executes this statement to 
--  create a security policy named secpolicy that has the three 
--  components previously created and uses the DB2LBACRULES rule set.

CREATE SECURITY POLICY secpolicy
  COMPONENTS level, departments, groups
  WITH DB2LBACRULES;

--  Now the user with SECADM authority can execute the following 
--  statements to create some security labels that are part of the 
--  security policy secpolicy. 

--  For the purposes of this example the security label names end with 
--  a number that indicates the relative "strength" of the label. 
--  In other words seclabel1 is blocked by seclabel2 and seclabel2 is 
--  blocked by seclabel3 but not by seclabel1, etc. This is only to make 
--  the example easier to follow.

CREATE SECURITY LABEL secpolicy.seclabel1
  COMPONENT level 'UNCLASSIFIED',
  COMPONENT departments 'ALPHA', 'DELTA',
  COMPONENT groups 'G4';

CREATE SECURITY LABEL secpolicy.seclabel2
  COMPONENT level 'CONFIDENTIAL',
  COMPONENT departments 'ALPHA', 'DELTA',
  COMPONENT groups 'G4';

CREATE SECURITY LABEL secpolicy.seclabel3 
  COMPONENT level 'SECRET',
  COMPONENT departments 'ALPHA', 'DELTA',
  COMPONENT groups 'G4';

CREATE SECURITY LABEL secpolicy.seclabel4
  COMPONENT level 'TOP SECRET',
  COMPONENT departments 'ALPHA', 'DELTA',
  COMPONENT groups 'G4';

-- Granting seclabel2 to user joe in order to create a column 
-- secured with seclabel2 
GRANT SECURITY LABEL secpolicy.seclabel2 TO USER joe;

CONNECT TO sample USER joe USING joe123; 

--  The user with SECADM authority now creates a protected table 
--  and attaches the security policy to the table. The table includes 
--  a column named rowseclabel that will hold the security labels 
--  protecting the rows. It also has a column named payrank that is 
--  protected by the security label seclabel2. The payrank column has 
--  a default value of 0.

--  This is the statement that creates a protected table:

CREATE TABLE joe.employee_lbac (
  empno     int,
  lastname  char(10),
  deptno    int,
  payrank   int SECURED WITH seclabel2 DEFAULT 0,
  rowseclabel DB2SECURITYLABEL
  )
  SECURITY POLICY secpolicy;

-- The protected table is now ready for use.

-- The user with SECADM authority grants security label seclabel1 to user joe
CONNECT TO sample USER secadm USING secadm123;

REVOKE SECURITY LABEL secpolicy.seclabel2 FROM USER joe;
GRANT SECURITY LABEL secpolicy.seclabel1 TO USER joe;

-- Joe now holds the security label seclabel1 for both read and write access.

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF;

!echo ---------------------------------------------------------------------;
!echo -- INSERTING INTO A PROTECTED TABLE ---;
!echo ---------------------------------------------------------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-- Joe tries to insert a row to the table by specifying a value for every 
-- column except rowseclabel:

CONNECT TO sample USER joe USING joe123;

INSERT INTO joe.employee_lbac (empno, lastname, deptno, payrank) 
  VALUES (1, 'Smith', 11, 3);

-- The insert fails because the column 'payrank' is protected by the 
-- security label seclabel2 and joe holds security label seclabel1. The security 
-- label seclabel1 cannot read from or write to security label seclabel2.

-- Joe removes the column payrank from the INSERT statement. This time the insert 
-- is successful because the column payrank has a default value and therefore it 
-- is not necessary that an explicit value be given for it.

INSERT INTO joe.employee_lbac (empno, lastname, deptno) VALUES (1, 'Smith', 11);

-- Because no value is given for the column rowseclabel, the security label that 
-- the user holds for writing is inserted by default. In the case of user joe 
-- that is seclabel1.

-- The rows in table employee_lbac now look like this:

--    EMPNO   LASTNAME   DEPTNO   PAYRANK  ROWSECLABEL
--     1       Smith      11       0        UNCLASSIFIED:(ALPHA,DELTA):G4

-- Now the user with SECADM authority revokes seclabel1 from joe and grants 
-- him seclabel2 instead, by executing these statements: 
CONNECT TO sample USER secadm USING secadm123;

REVOKE SECURITY LABEL secpolicy.seclabel1 FROM USER joe;
GRANT SECURITY LABEL secpolicy.seclabel2 TO USER joe;

-- Joe now holds the security label seclabel2 for both read and write access. 
-- He no longer holds the security label seclabel1.

-- Joe inserts another row as he did before:
CONNECT TO sample USER joe USING joe123;
INSERT INTO joe.employee_lbac (empno, lastname, deptno) VALUES (2, 'Haas', 11);

-- Select the rows in the table employee_lbac
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(rowseclabel AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- The values in the rowseclabel column are shown in a character representation
-- of the internal format. This is the default. Joe wants to read them in 
-- security label string format so he executes the select again, this time using 
-- the SECLABEL_TO_CHAR built-in function to convert the security labels as below:
-- CAST to VARCHAR(30) is done on rowseclabel column only to make the output fit 
-- the screen and is not otherwise required.

-- Select the rows in the table employee_lbac
SELECT empno, 
       lastname, 
       deptno,   
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30)) 
  AS rowseclabel FROM joe.employee_lbac;

-- Joe wants the next row he writes to be protected by seclabel1 rather than the 
-- security label he currently holds. He uses the SECLABEL_BY_NAME built-in 
-- function to provide seclabel1 for insert.
INSERT INTO joe.employee_lbac (empno, lastname, deptno, rowseclabel) 
  VALUES (3, 'Miller', 11, SECLABEL_BY_NAME('SECPOLICY', 'SECLABEL1'));

-- The statement does not give joe the results he wants. When you provide an 
-- explicit security label to protect a row you must be able to write to data 
-- protected by that security label, otherwise it cannot be used. You cannot 
-- insert a row that you would be unable to write to.
-- The reason that seclabel2 cannot write to seclabel1 is the rule DB2LBACWRITEARRAY. 
-- That rule prevents writing to any security label that has an element for an ARRAY
-- type component that is different than the element for the same component in your 
-- security label. The security label seclabel1 has a value of 'UNCLASSIFIED' for 
-- the level component while seclabel2 has a value of 'CONFIDENTIAL' for that component.

-- What happens when you try to insert a security label that you cannot write to 
-- depends on whether or not the security policy was created with the 
-- RESTRICT NOT AUTHORIZED WRITE SECURITY LABEL option. It the option was used 
-- then the statement fails and an error is returned. If it was not used then no 
-- error is given but the provided security label is ignored and the user's 
-- security label for write access is used instead.
-- The security policy secpolicy was created without
-- the RESTRICT NOT AUTHORIZED WRITE SECURITY LABEL option, so no error is given 
-- and joe's current security label is used instead.

-- Select the rows in the table employee_lbac
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- A user with SECADM authority now grants joe an exemption to the part of 
-- the DB2LBACWRITEARRAY rule that prevents writing to elements that are lower 
-- than yours (the write-down portion):

CONNECT TO sample USER secadm USING secadm123;

GRANT EXEMPTION ON RULE DB2LBACWRITEARRAY WRITEDOWN
  FOR secpolicy
  TO USER joe;

-- Joe again tries to insert a row protected by seclabel1:
CONNECT TO sample USER joe USING joe123;

INSERT INTO joe.employee_lbac (empno, lastname, deptno, rowseclabel) 
   VALUES (4, 'Barberra', 11, SECLABEL_BY_NAME('SECPOLICY', 'SECLABEL1'));

-- This insert does what joe expects because joe can now write to data 
-- protected by seclabel1

-- Select the rows in the table employee_lbac
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- The next row that joe needs to insert must be protected by a security label in 
-- which level = UNCLASSIFIED, departments = ALPHA, and groups = G4. There is no 
-- named security label with those values so joe must use the SECLABEL built-in 
-- function. The SECLABEL function creates a security label based on a list of 
-- element values.

INSERT INTO joe.employee_lbac (empno, lastname, deptno, rowseclabel) 
   VALUES (5, 'Kubrick', 11, SECLABEL('SECPOLICY', 'UNCLASSIFIED:ALPHA:G4'));

-- Joe is able to write to data protected by a security label with the 
-- values 'UNCLASSIFIED:ALPHA:G4' so the insert takes place and the 
-- supplied security label is used.

-- Select the rows in the table employee_lbac
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- Joe must now insert a row that includes a payrank of 2 and is to be protected 
-- by seclabel2. Joe currently holds security label seclabel2 for write access. 
-- This means that he is able to write to the column payrank, which is protected 
-- by seclabel2. It also means that when he does not explicitly provide a security 
-- label for the column rowseclabel, the security label seclabel2 will be used.
-- Joe executes this insert statement, which executes without error:

INSERT INTO joe.employee_lbac (empno, lastname, deptno, payrank)
   VALUES (6, 'Little', 11, 2);

-- Select the rows in the table employee_lbac
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- Joe has one last row to insert. This one must be protected by seclabel4 and 
-- must have a payrank of 5. Security labels seclabel2 and seclabel4 both have 
-- the same values for the departments and groups components. They are only 
-- different in the level component. So, if Joe is granted an exemption to the 
-- rule DB2WRITEARRAY for write-up he will be able to write to data protected 
-- by seclabel4 and will therefore be able to insert seclabel4 into the column.

-- Note: Granting an exemption is a somewhat drastic solution to this problem 
-- and is only being done here for demonstration purposes.

-- A user with SECADM authority grants joe an exemption to the write-up portion 
-- of the DB2WRITEARRAY rule by executing this statement:

CONNECT TO sample USER secadm USING secadm123;

GRANT EXEMPTION ON RULE DB2LBACWRITEARRAY WRITEUP
  FOR secpolicy
  TO USER joe;

-- Joe now does an insert with security label seclabel4
CONNECT TO sample USER joe USING joe123; 

INSERT INTO joe.employee_lbac (empno, lastname, deptno, payrank, rowseclabel) 
   VALUES (7, 'Addams', 22, 5, SECLABEL_BY_NAME('SECPOLICY', 'SECLABEL4'));

-- The rows in table employee_lbac now look like this:

-- EMPNO       LASTNAME   DEPTNO      PAYRANK     ROWSECLABEL
-- ----------- ---------- ----------- ----------- ------------------------------
--           1 Smith               11           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--           2 Haas                11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--           3 Miller              11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--           4 Barberra            11           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--           5 Kubrick             11           0 UNCLASSIFIED:ALPHA:G4
--           6 Little              11           2 CONFIDENTIAL:(ALPHA,DELTA):G4
--           7 Addams              22           5 TOP SECRET:(ALPHA,DELTA):G4

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF;

!echo ---------------------------------------------------------------------;
!echo -- READING FROM A PROTECTED TABLE ---;
!echo ---------------------------------------------------------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-- Just after finishing the previous inserts. Joe wants to make sure that all of 
-- the data is in the table so he executes this SELECT statement to count the rows:

SELECT COUNT(*) AS count FROM joe.employee_lbac;

-- The statement returns a count of 6. There seems to be a row missing. 
-- Joe executes this statement to view the rows:

-- Select the rows in the table employee_lbac
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- The reason is that joe holds only seclabel2 for read access and has been granted 
-- no exemptions to the rules for read access. He cannot read the last row because 
-- his LBAC credentials prevent it.

-- To allow joe to view the entire table, a user with SECADM authority revokes 
-- seclabel2 from joe and grants seclabel4 to him:

CONNECT TO sample USER secadm USING secadm123;

REVOKE SECURITY LABEL secpolicy.seclabel2 FROM USER joe;
GRANT SECURITY LABEL secpolicy.seclabel4 TO USER joe;

-- Select the rows in the table employee_lbac
CONNECT TO sample USER joe USING joe123;

SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- Joe is now done with the inserts so the user with SECADM authority revokes 
-- all of joe's exemptions and sets his security label back to seclabel1 with 
-- these statements:
CONNECT TO sample USER secadm USING secadm123;

REVOKE EXEMPTION ON RULE ALL FOR secpolicy FROM USER joe;
REVOKE SECURITY LABEL secpolicy.seclabel4 FROM USER joe;
GRANT SECURITY LABEL secpolicy.seclabel1 TO USER joe;

-- Joe now tries to count the rows again. This time the count is 3 because with 
-- a security label of seclabel1 he is only able to read 3 of the rows.
CONNECT TO sample USER joe USING joe123;
SELECT COUNT(*) AS count FROM joe.employee_lbac;

-- Joe tries to view the rows with this statement but because the 
-- asterisk (*) includes the column payrank in the select the 
-- statement fails. Joe no longer has read access to the column payrank.

SELECT * FROM joe.employee_lbac;

-- Joe changes the statement to exclude the payrank column and also to convert 
-- the security labels to a security label string format, then executes it:

SELECT empno, 
       lastname, 
       deptno, 
       CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30)) AS rowseclabel
  FROM joe.employee_lbac;

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF;

!echo ---------------------------------------------------------------------;
!echo -- UPDATING A PROTECTED TABLE ---;
!echo ---------------------------------------------------------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-- These rows are in table employee_lbac:

-- EMPNO       LASTNAME   DEPTNO      PAYRANK     ROWSECLABEL
-- ----------- ---------- ----------- ----------- ------------------------------
--           1 Smith               11           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--           2 Haas                11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--           3 Miller              11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--           4 Barberra            11           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--           5 Kubrick             11           0 UNCLASSIFIED:ALPHA:G4
--           6 Little              11           2 CONFIDENTIAL:(ALPHA,DELTA):G4
--           7 Addams              22           5 TOP SECRET:(ALPHA,DELTA):G4

-- User bob needs to make some updates to the employee_lbac table. A user 
-- with SECADM authority grants him security label seclabel1 with this statement:
CONNECT TO sample USER secadm USING secadm123;
GRANT SECURITY LABEL secpolicy.seclabel1 TO USER bob;

-- Grant select, insert, update, delete privileges on employee_lbac 
-- table to bob, pat. This can be done by joe using the below statement
CONNECT TO sample user joe USING joe123;
GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE joe.employee_lbac TO USER bob, pat;

-- Bob issues the following update statement:
CONNECT TO sample USER bob USING bob123;
UPDATE joe.employee_lbac SET deptno = 0;

-- The update executes without error but rows to which bob does not have 
-- read access are not affected. Also, because the update does not explicitly 
-- set the column rowseclabel it is automatically set to the security label 
-- that bob holds for write access (seclabel1).

-- After the statement, the rows in the table look like this:

-- EMPNO       LASTNAME   DEPTNO      PAYRANK     ROWSECLABEL
-- ----------- ---------- ----------- ----------- ------------------------------
--           1 Smith                0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--           2 Haas                11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--           3 Miller              11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--           4 Barberra             0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--           5 Kubrick              0           0 UNCLASSIFIED:ALPHA:G4
--           6 Little              11           2 CONFIDENTIAL:(ALPHA,DELTA):G4
--           7 Addams              22           5 TOP SECRET:(ALPHA,DELTA):G4

-- Now bob tries to change all payranks greater than 0 to 1. He executes this 
-- statement but the statement fails because he does not have write access or 
-- read access to the column payrank:

UPDATE joe.employee_lbac SET payrank = 1 WHERE payrank > 0;

-- A user with SECADM authority changes bob's security label to seclabel3

-- Connect as the SECADM user 
CONNECT TO sample USER secadm USING secadm123;

REVOKE SECURITY LABEL secpolicy.seclabel1 FROM USER bob;
GRANT SECURITY LABEL secpolicy.seclabel3 TO USER bob;

-- Bob tries the update again. This time it fails because seclabel3, which bob 
-- holds for write access, has a value of 'SECRET' for the component level 
-- and the security label protecting the row has a value of 'CONFIDENTIAL' for 
-- that component. Writing to the row would violate the write-down part of the 
-- DB2LBACWRITEARRAY rule. To allow bob to make the update, a user with SECADM 
-- could either grant the security label seclabel2 to him or grant him an exemption 
-- on the write-down portion of the DB2LBACWRITEARRAY rule. Granting a new security 
-- label is by far the safest way to grant access, but for demonstration purposes 
-- assume the user with SECADM authority grants the exemption:

GRANT EXEMPTION ON RULE DB2LBACWRITEARRAY WRITEDOWN
  FOR secpolicy
  TO USER bob;

-- Bob executes the update again. This time it executes with no error because bob has 
-- both read and write access to the column payrank and also to the row. The update 
-- does not affect the row where empno = 7, however because bob is not able to read that 
-- row. Also, the security label protecting the updated row is changed to the security 
-- label that bob holds for write access, namely seclabel3.

CONNECT TO sample USER bob USING bob123;
UPDATE joe.employee_lbac SET payrank = 1 WHERE payrank > 0;

-- After the statement, the rows in the table look like this:
-- EMPNO       LASTNAME   DEPTNO      PAYRANK     ROWSECLABEL
-- ----------- ---------- ----------- ----------- ------------------------------
--          1 Smith                0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--          2 Haas                11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--          3 Miller              11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--          4 Barberra             0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--          5 Kubrick              0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--          6 Little              11           1 SECRET:(ALPHA,DELTA):G4 
--          7 Addams              22           5 TOP SECRET:(ALPHA,DELTA):G4

-- To check his work, bob selects the rows of the table. He uses the SECLABEL_TO_CHAR 
-- built-in function to convert the security labels to a more readable form.

SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- Bob needs to change the row where empno = 6 so that it it protected by seclabel2 
-- instead of seclabel3. Because he already holds an exemption to the write-down portion 
-- of the DB2LBACWRITEARRAY rule he can write to seclabel2 and can therefore explicitly 
-- use it in his update:

UPDATE joe.employee_lbac 
  SET rowseclabel = SECLABEL_BY_NAME('SECPOLICY', 'SECLABEL2')
  WHERE empno = 6;

-- After the statement, the rows in the table look like this:
-- EMPNO       LASTNAME   DEPTNO      PAYRANK     ROWSECLABEL
-- ----------- ---------- ----------- ----------- ------------------------------
--          1 Smith                0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--          2 Haas                11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--          3 Miller              11           0 CONFIDENTIAL:(ALPHA,DELTA):G4
--          4 Barberra             0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--          5 Kubrick              0           0 UNCLASSIFIED:(ALPHA,DELTA):G4
--          6 Little              11           1 CONFIDENTIAL:(ALPHA,DELTA):G4
--          7 Addams              22           5 TOP SECRET:(ALPHA,DELTA):G4

-- Bob is finished with his updates. The user with SECADM authority revokes all 
-- exemptions from him and also changes his security label back to seclabel1

CONNECT TO sample USER secadm USING secadm123;

REVOKE EXEMPTION ON RULE ALL FOR secpolicy FROM USER bob;
REVOKE SECURITY LABEL secpolicy.seclabel3 FROM USER bob;
GRANT SECURITY LABEL secpolicy.seclabel1 TO USER bob;

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF;

!echo ---------------------------------------------------------------------;
!echo -- DELETING FROM A PROTECTED TABLE ---;
!echo ---------------------------------------------------------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-- User pat needs to delete some rows from the table employee_lbac. A user 
-- with SECADM authority grants her security label seclabel1 with this statement:

GRANT SECURITY LABEL secpolicy.seclabel1 TO USER pat;

-- Pat issues the following SQL statement. It fails because she has neither 
-- read access nor write access to the column payrank.

CONNECT TO sample USER pat USING pat123;
DELETE FROM joe.employee_lbac WHERE EMPNO >= 1;

-- A user with SECADM authority grants security label seclabel2 to pat:
CONNECT TO sample USER secadm USING secadm123;
REVOKE SECURITY LABEL secpolicy.seclabel1 FROM USER pat;
GRANT SECURITY LABEL secpolicy.seclabel2 TO USER pat;

-- Pat tries the delete again.
CONNECT TO sample USER pat USING pat123;
DELETE FROM joe.employee_lbac WHERE EMPNO >= 1;

-- This time the delete gives an error because some of the rows selected for deletion 
-- are protected by security labels that pat cannot write to. For example the row in 
-- which empno = 1 is protected by the security label seclabel1. Pat is able to read 
-- that row but is unable to write to it because that would violate the write-down 
-- portion of the DB2LBACWRITEARRAY rule. 
-- No rows are affected by the statement.

-- A user with SECADM authority grants pat an exemption to both the write-up and the 
-- write-down portions of the DB2LBACWRITEARRAY rule:

CONNECT TO sample USER secadm USING secadm123;

GRANT EXEMPTION ON RULE DB2LBACWRITEARRAY WRITEUP 
  FOR secpolicy
  TO USER pat;

GRANT EXEMPTION ON RULE DB2LBACWRITEARRAY WRITEDOWN
  FOR secpolicy
  TO USER pat;

-- Components of type ARRAY will have no effect when pat is writing.

-- Pat tries the delete again. This time it executes without error because pat is able 
-- to write to all of the rows she is able to read. The rows that she is unable to 
-- read, however, are unaffected by the delete:

CONNECT TO sample USER pat USING pat123;
DELETE FROM joe.employee_lbac WHERE EMPNO >= 1;

-- After the statement, there is only one row in the table:
--    EMPNO   LASTNAME   DEPTNO   PAYRANK  ROWSECLABEL
--    7       Addams     22       5        TOP SECRET:(ALPHA,DELTA):G4

-- If pat executes a select on the table, however, she will see no rows because she 
-- is unable to read the row that is there. 
SELECT empno,
       lastname,
       deptno,
       payrank, CAST(SECLABEL_TO_CHAR('SECPOLICY', rowseclabel) AS VARCHAR(30))
  AS rowseclabel FROM joe.employee_lbac;

-- No rows are returned.

-- The user with SECADM authority revokes all exemptions from pat and 
-- grants her security label seclabel1:
CONNECT TO sample USER secadm USING secadm123;

REVOKE EXEMPTION ON RULE ALL FOR secpolicy FROM USER pat;
REVOKE SECURITY LABEL secpolicy.seclabel2 FROM USER pat;
GRANT SECURITY LABEL secpolicy.seclabel1 TO USER pat;

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF;

!echo ---------------------------------------------------------------------;
!echo -- REVOKING SECURITY LABELS FROM USERS.                       ----;
!echo -- DROPPING SECURITY LABELS, SECURITY POLICY, PROTECTED TABLE ----;
!echo -- SECURITY LABEL COMPONENTS.                                 ----;
!echo ---------------------------------------------------------------------;

-- turn on the Echo Current Command option
UPDATE COMMAND OPTIONS USING v ON;

-- Revoke the security labels from joe, bob and pat
REVOKE SECURITY LABEL secpolicy.seclabel1 FROM USER joe;
REVOKE SECURITY LABEL secpolicy.seclabel1 FROM USER bob;
REVOKE SECURITY LABEL secpolicy.seclabel1 FROM USER pat;

-- Drop the protected table 'employee_lbac'

CONNECT TO sample USER joe USING joe123;
DROP TABLE joe.employee_lbac;

-- Drop the security labels created
CONNECT TO sample USER secadm USING secadm123;

DROP SECURITY LABEL secpolicy.seclabel1;
DROP SECURITY LABEL secpolicy.seclabel2;
DROP SECURITY LABEL secpolicy.seclabel3;
DROP SECURITY LABEL secpolicy.seclabel4;

-- Drop the security policy 'secpolicy'
DROP SECURITY POLICY secpolicy;

-- Drop the security label components
DROP SECURITY LABEL COMPONENT level;
DROP SECURITY LABEL COMPONENT departments;
DROP SECURITY LABEL COMPONENT groups;

-- Disconnect from the database
CONNECT RESET;
