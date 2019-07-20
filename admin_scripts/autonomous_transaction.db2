--/****************************************************************************
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
-- ******************************************************************************
--
-- SAMPLE FILE NAME: autonomous_transaction.db2
--
-- PURPOSE         : The purpose of this sample is to demonstrate the use of 
--                   the AUTONOMOUS keyword in the CREATE PROCEDURE statement.
--
-- USAGE SCENARIO  : In an enterprise, each employee has some privileges on 
--                   certain tables and procedures. The employees use stored 
--                   procedures to perform operations on the table. The employees 
--                   cannot access those tables on which they do not have access 
--                   privileges. If any employee tries to access any restricted 
--                   data, an autonomous procedure will log the complete event and 
--                   store the details in a log table. At the end of day, the 
--                   administrator can check all the events.
--
-- PREREQUISITE    : The following users should exist in the operating system.
--
--                   john with password "john12345" in SYSADM group
--                   bob  with password "bob12345"
--                   pat  with password "pat12345"
--	
-- EXECUTION       : db2 -td@ -vf autonomous_transaction.db2
--                   
-- INPUTS          : NONE
--
-- OUTPUT          : Successful execution of autonomous procedure.
--
-- OUTPUT FILE     : autonomous_transaction.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                CREATE TABLE
--                CREATE PROCEDURE
--                DROP TABLE
--                DROP PROCEDURE
--                INSERT 
--                SELECT
--                UPDATE TABLE
--
-- *************************************************************************
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
-- *************************************************************************
--
--  SAMPLE DESCRIPTION
--  
-- 1. The data is stored in the following tables:

-- a) TEMP_EMPLOYEE   : Contains employee details.
-- b) TEMP_PAYROLL    : Contains the employees' salary details.
-- c) EVENT_LOG       : Contains the details of all the events performed
--                      by the user.

-- 2. The application is processed using the following procedures:
--
-- a) UPDATE_SALARY   : Procedure to update the salary. The user passes the 
--                      employee's experience, work department, and new salary 
--                      as the parameters.
--
-- b) REPORT_GENERATE : Procedure to generate the employee's salary report.
--
-- c) EVENT_LOG       : An autonomous procedure to store the events performed 
--                      by the user.
--
--  SAMPLE DETAILS
--
--  (1) The user JOHN is the administrator with SYSADM authority. JOHN 
--      creates two stored procedures; UPDATE_SALARY, REPORT_GENERATE, 
--      and an autonomous procedure EVENT_LOG. A table EVENT_LOG is 
--      also created by JOHN to store all the events.
--
--  (2) BOB and PAT are non-administrator users. BOB is from the Payroll 
--      department and has access to the TEMP_PAYROLL table and TEMP_EMPLOYEE table. 
--      BOB can also update the employees' salary with the help of a stored 
--      procedure UPDATE_SALARY.
--
--  (3) The user PAT is also from the Payroll department and his job is to generate the 
--      reports. This is done with the help of a stored procedure REPORT_GENERATE.
--
--  (4) BOB invokes the procedure UPDATE_SALARY to update the salary and PAT 
--      invokes the procedure REPORT_GENERATE to generate the report.
--
--  (5) When PAT tries to invoke the procedure UPDATE_SALARY to access the 
--      TEMP_PAYROLL and TEMP_EMPLOYEE tables, an autonomous procedure EVENT_LOG is 
--      automatically invoked as PAT does not have sufficient privileges to 
--      perform this operation. Hence, the transaction is rolled back and the event 
--      is logged in the EVENT_TABLE.
--
--  (6) Later, the administrator (JOHN) will invoke the table EVENT_LOG to track 
--      all the events in the EVENT_LOG table.
-- 
-- *************************************************************************

-- *************************************************************************/
-- SET UP                                                                  */
-- *************************************************************************/

--  /******************************************************/
--  /* User JOHN creates the tables                       */
--  /******************************************************/

-- Connect to sample database
CONNECT TO sample USER john USING john12345@

echo@
echo **************************@
echo CREATE TABLES             @
echo **************************@
echo@

-- Create table temp_employee under 'JOHN' schema

CREATE TABLE temp_employee(
empno CHAR(6), 
empname VARCHAR(10), 
lastname VARCHAR(10), 
workdept CHAR(3), 
bonus DECIMAL(9,2), 
hiredate DATE)@

-- Create table temp_payroll under 'JOHN' schema

CREATE TABLE temp_payroll(
empno CHAR(6), 
salary DECIMAL(9,2))@

-- Create table event_log under 'JOHN' schema.
-- The event_log table stores the session user, the event performed by the user, 
-- the event time, and the event date.

CREATE TABLE event_log(
user_name VARCHAR(10), 
event VARCHAR(65), 
event_time TIME, 
event_date DATE)@


echo@
echo **************************@
echo INSERT DATA INTO TABLES   @
echo **************************@
echo@

-- Insert data into temp_employee table from employee table
INSERT INTO temp_employee VALUES
('000010', 'CHRISTINE', 'HAAS', 'A00', 1000.00, '01/01/1995')@
INSERT INTO temp_employee VALUES
('000020', 'MICHAEL', 'THOMPSON', 'B01', 800.00, '10/10/2003')@
INSERT INTO temp_employee VALUES
('000030', 'SALLY', 'KWAN', 'C01', 800.00, '04/05/2005')@
INSERT INTO temp_employee VALUES
('000050', 'JACK', 'GEYER', 'E01', 800.00, '08/17/1979')@
INSERT INTO temp_employee VALUES
('000060', 'IRVING', 'STERN', 'D11', 500.00, '09/14/2003')@
INSERT INTO temp_employee VALUES
('000070', 'EVA', 'PULASKI', 'D21', 700.00, '09/30/2005')@
INSERT INTO temp_employee VALUES
('000090', 'EILEEN', 'HENDERSON', 'E11', 600.00, '08/15/2000')@
INSERT INTO temp_employee VALUES
('000100', 'THEODORE', 'SPENSER', 'E21', 500.00, '06/19/2000')@
INSERT INTO temp_employee VALUES
('000110', 'VINCENZO', 'LUCCHESSI', 'A00', 900.00, '05/16/1988')@


-- Insert data into temp_payroll table
INSERT INTO temp_payroll VALUES
('000010', 10000.500)@
INSERT INTO temp_payroll VALUES
('000020', 12000.430)@
INSERT INTO temp_payroll VALUES
('000030', 11600.600)@
INSERT INTO temp_payroll VALUES
('000050', 10560.450)@
INSERT INTO temp_payroll VALUES
('000060', 13000.500)@
INSERT INTO temp_payroll VALUES
('000070', 11640.600)@
INSERT INTO temp_payroll VALUES
('000090', 12560.450)@
INSERT INTO temp_payroll VALUES
('000100', 13894.556)@


echo@
echo **************************@
echo FETCH DATA FROM TABLES    @
echo **************************@
echo@

-- Fetch data from temp_employee
SELECT * FROM temp_employee@

-- Fetch data from temp_payroll
SELECT * FROM temp_payroll@


echo@
echo@
echo **************************@
echo CREATE PROCEDURE event_log@
echo **************************@
echo@
echo@

-- Create autonomous procedure "event_log" to log the event. Each procedure 
-- will call this procedure before any operation. While calling 
-- event_log procedure, each procedure will pass the event name as an argument.
-- "event_log" procedure inserts the event in "event_log" table.

CREATE PROCEDURE event_log(IN event CHAR(1))
   AUTONOMOUS
   LANGUAGE SQL
   BEGIN
     CASE event
       WHEN 'U'
       THEN INSERT INTO event_log 
           VALUES(SESSION_USER, 
           'CALLING salary_update PROCEDURE TO UPDATE THE SALARY', 
           CURRENT TIME, 
           CURRENT DATE);

       WHEN 'S'
       THEN INSERT INTO event_log
           VALUES(SESSION_USER, 
           'CALLING report_generate PROCEDURE TO VIEW EMPLOYEES SALARY',
           CURRENT TIME, 
           CURRENT DATE);

     END CASE;
   END@


echo@
echo@
echo *******************************@
echo CREATE PROCEDURE update_salary @
echo *******************************@
echo@
echo@

-- Create procedure "update_salary" to perform the salary update.
-- Caller user passes the employees' total experience, 
-- work department, and new salary as arguments. The "update_salary"         
-- procedure will update the salary of employees' whose work department 
-- and total experience is equal to the passed arguments. Only the user 
-- BOB can update the salary.

CREATE PROCEDURE update_salary
 (IN exp INTEGER,
  IN workdpt CHAR(3), 
  IN new_salary INTEGER)
   LANGUAGE SQL
   BEGIN
    CALL event_log('U');
     UPDATE temp_payroll 
     SET salary = salary + new_salary 
     WHERE empno = 
     (SELECT empno FROM temp_employee WHERE workdept = workdpt 
      AND (CURRENT DATE - hiredate) > exp);
  
        IF (USER <> 'BOB')
          THEN
          ROLLBACK;
        END IF;
   END@


echo@
echo@
echo *********************************@
echo CREATE PROCEDURE report_generate @
echo *********************************@
echo@
echo@

-- Create procedure "report_generate". This procedure
-- will generate the report of employee salary details. Only the user 
-- PAT can generate the report.

CREATE PROCEDURE report_generate()
   LANGUAGE SQL
   BEGIN
     DECLARE v_empfn CHAR(10);
     DECLARE v_empln CHAR(10);
     DECLARE v_empsal DECIMAL(9,2);
     DECLARE c_report_gen CURSOR;
     SET c_report_gen= CURSOR FOR SELECT empname, lastname, salary 
     FROM temp_employee t1, temp_payroll t2 
     WHERE t1.empno = t2.empno;
      CALL event_log('S');
       IF (USER <> 'PAT')
        THEN
        ROLLBACK;
       ELSE
        OPEN c_report_gen;
        
        CALL DBMS_OUTPUT.NEW_LINE;
        CALL DBMS_OUTPUT.PUT_LINE('---------------');
        CALL DBMS_OUTPUT.PUT_LINE('EMPLOYEE REPORT');
        CALL DBMS_OUTPUT.PUT_LINE('---------------');
        CALL DBMS_OUTPUT.NEW_LINE;
        CALL DBMS_OUTPUT.PUT_LINE('');
        CALL DBMS_OUTPUT.PUT
          ('EMP NAME  '||'   '||'LASTNAME '||'    '||'SALARY');
        CALL DBMS_OUTPUT.NEW_LINE;
        CALL DBMS_OUTPUT.PUT
          ('-----------'||'  '||'-----------'||'  '||'-----------');
        CALL DBMS_OUTPUT.NEW_LINE;

       fetch_loop:
       LOOP
         FETCH FROM c_report_gen INTO v_empfn, v_empln, v_empsal;

          IF c_report_gen IS NOT FOUND
            THEN LEAVE fetch_loop;
          END IF;

        CALL DBMS_OUTPUT.PUT(v_empfn);
        CALL DBMS_OUTPUT.PUT('   ');
        CALL DBMS_OUTPUT.PUT(v_empln);
        CALL DBMS_OUTPUT.PUT('   ');
        CALL DBMS_OUTPUT.PUT(v_empsal);
        CALL DBMS_OUTPUT.NEW_LINE;
       
       END LOOP fetch_loop;
       CLOSE c_report_gen;      
       END IF;
   END@


-- /***************************************************
-- /* GRANT EXECUTE privileges to users
-- /***************************************************

echo@
echo@
echo ************************************************@
echo GRANT EXECUTE PRIVILEGES ON PROCEDURES TO USERS @
echo ************************************************@
echo@
echo@

-- Grant execute privilege to user BOB on procedure update_salary
GRANT EXECUTE ON PROCEDURE update_salary TO USER bob@

-- Grant execute privilege to user BOB on procedure report_generate
GRANT EXECUTE ON PROCEDURE report_generate TO USER bob@

-- Grant execute privilege to user PAT on procedure report_generate
GRANT EXECUTE ON PROCEDURE report_generate TO USER pat@

-- Grant execute privilege to user PAT on procedure update_salary
GRANT EXECUTE ON PROCEDURE update_salary TO USER pat@

-- RESET CONNECTION
CONNECT RESET@

-- CALL PROCEDURES TO PERFORM DIFFERENT OPERATIONS@

echo@
echo@
echo ***************************************@
echo FETCH SALARY OF EMPLOYEES BEFORE       @
echo CALLING update_salary STORED PROECDURE @
echo ***************************************@
echo@
echo@


-- Fetch salary of employees before calling update_salary procedure 
-- by user BOB.

-- Connect to database
CONNECT TO sample USER john USING john12345@
 
SELECT salary FROM temp_payroll 
 WHERE empno = (SELECT empno FROM temp_employee 
   WHERE workdept = 'D11' 
    AND (CURRENT DATE - hiredate) > 5)@


-- CALL Procedure update_salary to update the salary

echo@
echo User BOB calls procedure update_salary @
echo TO UPDATE THE SALARY@ 
echo@

-- RESET CONNECTION
CONNECT RESET@

-- Connect to database
CONNECT TO sample user bob using bob12345@

CALL JOHN.update_salary(5, 'D11', 2000)@


echo@
echo@
echo ***************************************@
echo FETCH SALARY OF EMPLOYEES AFTER        @
echo CALLING update_salary STORED PROECDURE @
echo ***************************************@
echo@
echo@

-- Fetch salary of employees after calling update_salary procedure 
-- by user BOB.

-- RESET CONNECTION
CONNECT RESET@

-- Connect to database
CONNECT TO sample user john using john12345@

SELECT salary FROM temp_payroll 
 WHERE empno = (SELECT empno FROM temp_employee 
   WHERE workdept = 'D11' 
    AND (CURRENT DATE - hiredate) > 5)@


echo@
echo@
echo ****************************************@
echo USER PAT CALLS PROCEDURE report_generate@
echo TO GENERATE THE REPORTS                 @
echo ****************************************@
echo@
echo@


-- RESET CONNECTION
CONNECT RESET@

-- Connect to sample database
CONNECT TO sample user pat using pat12345@

-- CALL procedure to generate the report
SET SERVEROUTPUT ON@ 
CALL JOHN.report_generate()@


-- The only user who has the appropriate privilege to execute the procedure 
-- "update_salary" is BOB. So when the user PAT invokes the procedure 
-- "update_salary", the procedure will check if the user is BOB. If the user 
-- is not BOB, all the transactions will be rolled back but the event will be 
-- logged as the event is passed as argument to the autonomous procedure.

echo@
echo@
echo **************************************@
echo FETCH SALARY OF EMPLOYEES BEFORE      @
echo CALLING update_salary STORED PROECDURE@
echo **************************************@
echo@
echo@

-- RESET CONNECTION
CONNECT RESET@

-- Select salary of employees before calling update_salary procedure 
-- by user PAT.

-- Connect to database
CONNECT TO sample user john using john12345@

SELECT salary FROM temp_payroll 
 WHERE empno = (SELECT empno FROM temp_employee 
   WHERE workdept = 'D11' 
    AND (CURRENT DATE - hiredate) > 5)@


echo@
echo@
echo ***************************************@
echo USER PAT CALLS PROCEDURE update_salary @ 
echo TO UPDATE THE SALARY                   @
echo ***************************************@
echo@
echo@

-- RESET CONNECTION
CONNECT RESET@

-- Connect to database
CONNECT TO sample user pat using pat12345@

CALL JOHN.update_salary(5, 'D11', 2000)@

echo@
echo@
echo ***************************************@
echo FETCH SALARY OF EMPLOYEES AFTER        @
echo CALLING update_salary STORED PROECDURE @
echo ***************************************@
echo@
echo@

-- Select salary of employees after calling update_salary procedure 
-- by user PAT.

-- RESET CONNECTION
CONNECT RESET@

-- Connect to database
CONNECT TO sample user john using john12345@

SELECT salary FROM temp_payroll 
 WHERE empno = (SELECT empno FROM temp_employee 
   WHERE workdept = 'D11' 
    AND (CURRENT DATE - hiredate) > 5)@

echo@
echo The above output is expected as the session user is not BOB.@
echo So all the transactions will be rolled back and salary will @
echo remain same but the event will be logged in event_log table.@
echo@


-- RESET CONNECTION
CONNECT RESET@

-- Connect to database
CONNECT TO sample user bob using bob12345@

echo@
echo@
echo ****************************************@
echo USER bob CALLS PROCEDURE report_generate@ 
echo TO GENERATE THE REPORT                  @
echo ****************************************@
echo@
echo@

CALL JOHN.report_generate()@
SET SERVEROUTPUT ON@

echo@
echo The above output is expected as session user is not PAT.   @
echo So report will not generate but the event will be logged in@
echo event_log table.                                           @
echo@

-- RESET CONNECTION
CONNECT RESET@

-- Track all the events.
CONNECT TO sample USER john USING john12345@

echo@
echo@
echo ********************************@
echo FETCH DATA FROM event_log TABLE @
echo ********************************@
echo@
echo@

SELECT * FROM event_log@


-- Disconnect from sample database
CONNECT RESET@


-- *************************************************
-- CLEAN UP
-- *************************************************

echo@
echo@
echo *******************************@
echo DROP ALL TABLES AND PROCEDURES @
echo *******************************@
echo@
echo@

-- Drop tables and procedures
CONNECT TO sample USER john USING john12345@

-- Drop table temp_employee
DROP TABLE temp_employee@

-- Drop table temp_payroll
DROP TABLE temp_payroll@

-- Drop table event_log
DROP TABLE event_log@

-- Drop procedure update_salary
DROP PROCEDURE update_salary@

-- Drop procedure report_generate
DROP PROCEDURE report_generate@

-- Drop procedure event_log
DROP PROCEDURE event_log@

-- Connect reset
CONNECT RESET@


