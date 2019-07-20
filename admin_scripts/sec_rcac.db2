-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2011 All rights reserved.
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
-- SOURCE FILE NAME: rcac.db2
--
-- SAMPLE: How to take advantage of DB2 RCAC (Row and Column Access Control) 
--         feature 
-- 
--	Scenario: A healthcare organization which has patient healthcare information
--  and different users with different roles. Few users maintain the database and 
--  others access the organizations applications according to theie roles. To comply 
--  with HIPPA(Health Insurance portability and accountability act.) the users should 
--  have access to those data that they are authorised to view. The following sample 
--  demonstrates the how the security policy is implemented using DB2 RCAC.

-- PREREQUISITES FOR RUNNING THE SAMPLE:
--   The sample assumes the existance of the following users along with 
--   the specified passwords
--        alex      with password "test1234" SECADM role 
--        peter     with password "test1234" DBADM role
--        paul      with password "test1234" DEVELOPER role
--        lee       with password "test1234" PHYSICIAN role
--        bob       with password "test1234" PATIENT role   
--        tom   	with password "test1234" MEMBERSHIP role
--        john      with password "test1234" ACCOUNTATNT role
--        jane      with password "test1234" DRUG RESEARCHER role
--
-- DB Admins
--        alex      SECADM who can create RCAC objects.
--        peter     DBADM who can create database objects.
--        paul      Developer who develops is database application logic.
--		
-- DB Users
--        lee       Physician who should view only his patients information.
--        bob       Patient can view only his medical information   
--        tom   	Enrols all patients to the hospital, can view 
--                  all patient information.
--        john      Accountant who should view all patients information 
--                  and their account details.
--        jane      Drug Researcher who should view only medical information
--					of those patients who have opted to give for reasearch.
--
--  Make sure that the above users are created in windows machine.
-- 
-- SQL STATEMENTS USED:
--         CONNECT
--         CREATE TABLE
--         CREATE ROLE
--         CREATE ROW PERMISSION
--         CREATE MASK
--		   CREATE VIEW
--		   CREATE FUNCTION
--		   ALTER
--         GRANT
--		   GRANT CREATE_SECURE_OBJECT 
--		   REVOKE
--         INSERT
--         UPDATE 
--         SELECT 
--
-- OUTPUT FILE: rcac.out (available in the online documentation)
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

-- Disconnect from any existing database connection.;

CONNECT RESET@

-- turn off echo Current Command option to suppress printing of echo command;

UPDATE COMMAND OPTIONS USING v OFF@
!echo ---------------------------------------------------------------------@
!echo --Connect as System administrator and make peter the SECADM and DBADM--@
!echo ---------------------------------------------------------------------@
UPDATE COMMAND OPTIONS USING v ON@

CONNECT TO sample@


---------------------------------------------------------------------;
-- peter initially is the DBADM and SECADM and creates the tables--;
-- and GRANTS roles.--;
---------------------------------------------------------------------;


GRANT SECADM,DBADM ON DATABASE TO USER peter@


---------------------------------------------------------------------;
-- connect to sample as peter the SECADM and DBADM ---;
---------------------------------------------------------------------;


CONNECT TO sample USER peter USING test1234@


-- Patient table stores information regarding patients-- ;


CREATE  TABLE ADMINISTRATOR.PATIENT (
	SSN CHAR(11),
	USERID VARCHAR(18),
	NAME VARCHAR(128),
	ADDRESS VARCHAR(128),
	PHARMACY VARCHAR(5000),
	ACCT_BALANCE DECIMAL(12,2) WITH DEFAULT,
	PCP_ID VARCHAR(18)
	)@


---------------------------------------------------------------------;
-- Patientchoice table which stores what patient opts ;
-- to expose regarding his health information.;
-- 'opt-in' a patient willing to expose his medical information;
-- 'opt-out' a patient not willing to expose his medical information;
---------------------------------------------------------------------;


CREATE  TABLE ADMINISTRATOR.PATIENTCHOICE (
	SSN CHAR(11),
	CHOICE VARCHAR(128),
	VALUE VARCHAR(128)

)@


-- History table to track account balance before and after update to ;
-- patient table.;


CREATE TABLE ADMINISTRATOR.ACCT_HISTORY(
	SSN 		CHAR(11),
	BEFORE_BALANCE	DECIMAL(12,2),
	AFTER_BALANCE	DECIMAL(12,2),
	WHEN 	DATE,
	BY_WHO	VARCHAR(20)
)@


-- Inserting sample patient data.;


INSERT INTO ADMINISTRATOR.PATIENT VALUES('123-55-1234', 'MAX', 'Max', 'First Strt', 'hypertension', 89.70,'LEE')@
INSERT INTO ADMINISTRATOR.PATIENTCHOICE VALUES('123-55-1234', 'drug-research', 'opt-out')@


INSERT INTO ADMINISTRATOR.PATIENT VALUES('123-58-9812', 'MIKE', 'Mike', 'Long Strt', 'diabetics', 8.30,'james')@
INSERT INTO ADMINISTRATOR.PATIENTCHOICE VALUES('123-58-9812', 'drug-research', 'opt-out')@


INSERT INTO ADMINISTRATOR.PATIENT VALUES('123-11-9856', 'SAM', 'Sam', 'Big Strt', 'High blood pressure', 0.00,'LEE')@
INSERT INTO ADMINISTRATOR.PATIENTCHOICE VALUES('123-11-9856', 'drug-research', 'opt-in')@

INSERT INTO ADMINISTRATOR.PATIENT VALUES('123-19-1454', 'DUG', 'Dug', 'Good Strt', 'Influenza', 0.00,'james')@
INSERT INTO ADMINISTRATOR.PATIENTCHOICE VALUES('123-19-1454', 'drug-research', 'opt-in')@


-- Creating roles and granting authority;



CREATE ROLE PCP@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO ROLE PCP@
GRANT UPDATE ON ADMINISTRATOR.PATIENT TO ROLE PCP@


CREATE ROLE DRUG_RESEARCH@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO ROLE DRUG_RESEARCH@


CREATE ROLE ACCOUNTING@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO ROLE ACCOUNTING@
GRANT UPDATE ON ADMINISTRATOR.PATIENT TO ROLE ACCOUNTING@
GRANT SELECT ON ADMINISTRATOR.ACCT_HISTORY TO ROLE ACCOUNTING@

 
CREATE ROLE MEMBERSHIP@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO ROLE MEMBERSHIP@
GRANT INSERT ON ADMINISTRATOR.PATIENT TO ROLE MEMBERSHIP@
GRANT INSERT ON ADMINISTRATOR.PATIENTCHOICE TO ROLE MEMBERSHIP@
GRANT UPDATE ON ADMINISTRATOR.PATIENT TO ROLE MEMBERSHIP@


CREATE ROLE PATIENT@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO ROLE PATIENT@


-- Grant roles and privileges to Users;


GRANT SELECT ON ADMINISTRATOR.PATIENT TO USER alex@
GRANT ALTER  ON ADMINISTRATOR.PATIENT TO USER alex@
GRANT ALTER  ON ADMINISTRATOR.PATIENT TO USER paul@
GRANT INSERT ON ADMINISTRATOR.ACCT_HISTORY TO USER paul@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO USER paul@

GRANT INSERT ON ADMINISTRATOR.ACCT_HISTORY TO USER paul@
GRANT SELECT ON ADMINISTRATOR.PATIENT TO USER paul@


GRANT ROLE PCP TO USER lee@
GRANT ROLE DRUG_RESEARCH TO USER jane@
GRANT ROLE ACCOUNTING  TO USER john@
GRANT ROLE MEMBERSHIP TO USER tom@
GRANT ROLE PATIENT TO USER bob@

GRANT SECADM ON DATABASE TO USER alex@


-- Connect as alex;


CONNECT TO sample USER alex USING test1234@


-- Removing SECADM authority of peter hence;
-- alex is the only SECADM in the database;


REVOKE SECADM ON DATABASE FROM USER peter@


-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF@
!echo -----------------------------------------------------------------------------------------@
!echo -- Creating row permission based on user role and the rows which they should have access.@
!echo ------------------------------------------------------------------------------------------@
UPDATE COMMAND OPTIONS USING v ON@

-- Accounting information;
-- ROLE PATIENT is allowed to access his or her own row;
-- ROLE PCP is allowed to access his or her patients rows;
-- ROLE MEMBERSHIP, ACCOUNTING, and DRUG_RESEARCH are;
-- allowed to access all rows.;


CREATE PERMISSION ADMINISTRATOR.ROW_ACCESS ON ADMINISTRATOR.PATIENT
FOR ROWS WHERE (VERIFY_ROLE_FOR_USER(SESSION_USER,'PATIENT') = 1
AND
ADMINISTRATOR.PATIENT.USERID = SESSION_USER) OR
(VERIFY_ROLE_FOR_USER(SESSION_USER,'PCP') = 1
AND
ADMINISTRATOR.PATIENT.PCP_ID = SESSION_USER) OR
	(VERIFY_ROLE_FOR_USER(SESSION_USER,'MEMBERSHIP') = 1 OR
	VERIFY_ROLE_FOR_USER(SESSION_USER,'ACCOUNTING') = 1 OR
	VERIFY_ROLE_FOR_USER(SESSION_USER, 'DRUG_RESEARCH') = 1)
ENFORCED FOR ALL ACCESS
ENABLE@


--Altering the table to activate the row access control feature.;


ALTER TABLE ADMINISTRATOR.PATIENT ACTIVATE ROW ACCESS CONTROL@


-- Connect as tom the membership officer;


CONNECT TO sample USER tom USING test1234@


-- Inserting patient Bobs information; 


INSERT INTO ADMINISTRATOR.PATIENT VALUES('123-45-6789', 'BOB', 'Bob', '123 Some St.', 'hypertension', 9.00,'LEE')@
INSERT INTO ADMINISTRATOR.PATIENTCHOICE VALUES('123-45-6789', 'drug-research', 'opt-in')@


-- Querying all the patient information;


SELECT SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID  
FROM ADMINISTRATOR.PATIENT @


-- Connect as lee;


CONNECT TO sample USER lee USING test1234@


-- Dr.Lee updating patient Sam information (updates as Sam is Dr. Lee patient);


UPDATE ADMINISTRATOR.PATIENT SET PHARMACY = 'codeine' WHERE NAME = 'Bob'@


-- Dr.Lee updating patient Dug information (will not get updated as Dug is not Dr.Lee patient);
-- Throws a warning saying as no record found for update.;


UPDATE ADMINISTRATOR.PATIENT SET PHARMACY = 'codeine' WHERE NAME = 'Dug'@


-- Query the patient table as Dr.Lee;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@


-- Connect as Bob;


CONNECT TO sample USER bob USING test1234@


-- Query the patient table as patient bob;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@



-- Connect as Alex

CONNECT TO sample USER alex USING test1234@

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF@
!echo -----------------------------------------------------------------------------------------@
!echo -- Creating column mask based on user role and the columns which they have access@
!echo ------------------------------------------------------------------------------------------@
UPDATE COMMAND OPTIONS USING v ON@

-----------------------------------------------------------------;
-- Creating a Column MASK ON ACCT_BALANCE column on PATIENT TABLE;
-- Accounting information:;
-- Role ACCOUNTING is allowed to access the full information;
-- on column ACCT_BALANCE.;
-- Other roles accessing this column  will strictly view a;
-- zero value.;
-----------------------------------------------------------------;


CREATE MASK ADMINISTRATOR.ACCT_BALANCE_MASK ON ADMINISTRATOR.PATIENT FOR
COLUMN  ACCT_BALANCE RETURN
	CASE WHEN VERIFY_ROLE_FOR_USER(SESSION_USER,'ACCOUNTING') = 1
			THEN ACCT_BALANCE
		ELSE 0.00
	END
ENABLE@


-----------------------------------------------------------------;
-- Mask on Column SSN. ;
-- Roles PATIENT, PCP, MEMBERSHIP, and ACCOUNTING are allowed;
-- to access the full information on columns SSN, USERID, NAME,;
-- and ADDRESS. Other roles accessing these columns will;
-- strictly view a masked value.;
-----------------------------------------------------------------;


CREATE MASK ADMINISTRATOR.SSN_MASK ON ADMINISTRATOR.PATIENT FOR
COLUMN SSN RETURN
	CASE WHEN 
		VERIFY_ROLE_FOR_USER(SESSION_USER,'PATIENT') = 1 OR
		VERIFY_ROLE_FOR_USER(SESSION_USER,'PCP') = 1 OR
		VERIFY_ROLE_FOR_USER(SESSION_USER,'MEMBERSHIP') = 1 OR
		VERIFY_ROLE_FOR_USER(SESSION_USER,'ACCOUNTING') = 1
	THEN SSN
		ELSE CHAR('XXX-XX-' || SUBSTR(SSN,8,4))
	END
ENABLE@


-----------------------------------------------------------------;
-- Mask on Column Pharmacy. ;
-- Role PCP is allowed to access the full information on;
-- column PHARMACY.;
-- For the purposes of drug research, Role DRUG_RESEARCH can;
-- conditionally see a patients medical information;
-- provided that the patient has opted-in.;
-- In all other cases, 'XXXXXXXXXXX' values are rendered as column;
-- values.;
-----------------------------------------------------------------;


CREATE MASK ADMINISTRATOR.PHARMACY_MASK ON ADMINISTRATOR.PATIENT FOR
COLUMN PHARMACY RETURN
		CASE WHEN 
		VERIFY_ROLE_FOR_USER(SESSION_USER,'PCP') = 1 OR
		(VERIFY_ROLE_FOR_USER(SESSION_USER,'DRUG_RESEARCH')=1
		AND
			SSN IN (SELECT C.SSN FROM ADMINISTRATOR.PATIENTCHOICE C
		WHERE SSN = C.SSN AND C.CHOICE = 'drug-research' AND C.VALUE = 'opt-in'))
		THEN PHARMACY
		ELSE 'XXXXXXXXXXX'
END
ENABLE@


-- Enabling column access control to implement column masking;


ALTER TABLE ADMINISTRATOR.PATIENT ACTIVATE COLUMN ACCESS CONTROL@


-- Connect as Dr.Lee;


CONNECT TO sample USER lee USING test1234@


-- Query the patient table ;
-- Dr.Lee can view his patients with account balnce as zero;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@


-- Connect as Jane the DRUG RESEARCHER


CONNECT TO sample USER jane USING test1234@


-- Query the patient table ;
-- All patients information with pharmacy information of;
-- those patients who have opted-in are not masked.;
-- The SSN and account balance are also masked;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@


-- Connect as John the accountant


CONNECT TO sample USER john USING test1234@


-- Query the patient table ;
-- All patient information are retived with account balance ans SSN but with;
-- masked pharmacy information.;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@


-- Connect as Bob;


CONNECT TO sample USER bob USING test1234@


-- Query the patient table ;
-- Bob is a patient and can view his information;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@


-- Connect as Alex;


CONNECT TO sample USER alex USING test1234@


-- Query the patient table ;
-- Alex even with highest authority;
-- cannot view patient data. No data is retireved;


SELECT
SESSION_USER AS "LOGGED_USER",SSN, USERID, NAME, ADDRESS, PHARMACY, ACCT_BALANCE, PCP_ID 
FROM ADMINISTRATOR.PATIENT@


-- Connect as peter;


CONNECT TO sample USER peter USING test1234@

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF@
!echo -----------------------------------------------------------------------------------------@
!echo -- Creating view on RCAC protected table.@
!echo ------------------------------------------------------------------------------------------@
UPDATE COMMAND OPTIONS USING v ON@

-- Creating view on RCAC protected table;
-- The view retrieves those patient who have opted to give their medical information for;
-- drug research.;


CREATE VIEW ADMINISTRATOR.PATIENT_INFO_VIEW AS
SELECT P.SSN, P.NAME,C.CHOICE FROM ADMINISTRATOR.PATIENT P, ADMINISTRATOR.PATIENTCHOICE C
WHERE P.SSN = C.SSN AND
	  C.CHOICE = 'drug-research' AND
	  C.VALUE = 'opt-in'@
	  
	  

-- Grant permission to use the view for these users;


GRANT SELECT ON  ADMINISTRATOR.PATIENT_INFO_VIEW TO USER alex@
GRANT SELECT ON  ADMINISTRATOR.PATIENT_INFO_VIEW TO USER lee@
GRANT SELECT ON  ADMINISTRATOR.PATIENT_INFO_VIEW TO USER bob@
GRANT SELECT ON  ADMINISTRATOR.PATIENT_INFO_VIEW TO USER jane@


-- Connect as Dr.Lee;


CONNECT TO sample USER lee USING test1234@

	  
-- Dr.Lee's patients with the view filter condition are retrived.;
-- View works with RCAC as the tables in which RCAC rules are enforced;


SELECT SSN, NAME,CHOICE FROM ADMINISTRATOR.PATIENT_INFO_VIEW@


-- Connect as patient Bob;


CONNECT TO sample USER bob USING test1234@

	  
-- Views Bob's information only;


SELECT SSN, NAME,CHOICE FROM ADMINISTRATOR.PATIENT_INFO_VIEW@


-- Creating SECURE database objects to access RCAC protected;
-- data.;

-- Connect as alex;


CONNECT TO sample USER alex USING test1234@


-- connect as SECADM Alex;
-- Grant the user paul to create secure object.;


GRANT CREATE_SECURE_OBJECT ON DATABASE TO USER paul@


-- connect as paul and run the below script.;


CONNECT TO sample USER paul USING test1234@


-- Functions for ExampleHMO Accounting department;

-- turn off echo Current Command option to suppress printing of echo command
UPDATE COMMAND OPTIONS USING v OFF@
!echo -----------------------------------------------------------------------------------------@
!echo -- Creating secure objects to access RCAC protected data.@
!echo -----------------------------------------------------------------------------------------@
UPDATE COMMAND OPTIONS USING v ON@

CREATE FUNCTION ADMINISTRATOR.EXPHMOACCOUNTINGUDF(X DECIMAL(12,2))
     RETURNS DECIMAL(12,2)
     LANGUAGE SQL
     CONTAINS SQL
     DETERMINISTIC
     NO EXTERNAL ACTION
     RETURN X*(1.0 + RAND(X))@


-- Paul alters the function to be secured ;
-- Hence the function can be used inside a RCAC object;


ALTER FUNCTION ADMINISTRATOR.EXPHMOACCOUNTINGUDF SECURED@


-- Connect as alex;


CONNECT TO sample USER alex USING test1234@


-- Dropping the mask to recreate it with secure function;


DROP MASK ADMINISTRATOR.ACCT_BALANCE_MASK@


-- Recreate the mask which was dropped.;
-- Role ACCOUNTING is allowed to invoke the secured UDF;
-- EXPHMOACCOUNTINGUDF passing column ACCT_BALANCE as;
-- the input argument;

-- Any un secured function cannot be used inside a RCAC object,;
-- thus preventing data leak and perfromance issue.;


CREATE MASK ADMINISTRATOR.ACCT_BALANCE_MASK ON ADMINISTRATOR.PATIENT FOR
COLUMN ACCT_BALANCE RETURN
CASE WHEN VERIFY_ROLE_FOR_USER(SESSION_USER,'ACCOUNTING') = 1
THEN ACCT_BALANCE
ELSE ADMINISTRATOR.EXPHMOACCOUNTINGUDF(ACCT_BALANCE)
END
ENABLE@


-- Connect as paul;


CONNECT TO sample USER paul USING test1234@


-- Functions for NetHMO Pharmacy department,;
-- to be used inside a query.;


CREATE FUNCTION ADMINISTRATOR.DRUGUDF(NAME VARCHAR(128))
      RETURNS VARCHAR(5000)
      NO EXTERNAL ACTION
      BEGIN ATOMIC
	      IF NAME IS NULL THEN
		        RETURN NULL;
		      ELSE
		        RETURN 'Normal';
		      END IF;
      END@

	  
-- Securing the UDF;


ALTER FUNCTION ADMINISTRATOR.DRUGUDF SECURED@ 


-- Granting execute permissions to Dr.Lee;


GRANT EXECUTE ON FUNCTION ADMINISTRATOR.DRUGUDF TO USER lee@


-- Connect as lee;


CONNECT TO sample USER lee USING test1234@


-- Dr.Lee querying after the function is secured;


SELECT PHARMACY FROM ADMINISTRATOR.PATIENT
WHERE ADMINISTRATOR.DRUGUDF(NAME) = 'Normal' AND
SSN = '123-45-6789'@



CONNECT TO sample USER paul USING test1234@


-- Connect as Paul.;
-- Trigger to maintain the account balance history;
-- of patient which fires when ever a update  ;
-- is done on a patient table.;
-- The trigger is made secured by using the SECURED keyword;
-- during creation.;


CREATE TRIGGER ADMINISTRATOR.EXPHMO_ACCT_BALANCE_TRIGGER
	AFTER UPDATE OF ACCT_BALANCE ON ADMINISTRATOR.PATIENT 
	REFERENCING OLD AS O NEW AS N
	FOR EACH ROW MODE DB2SQL SECURED
	BEGIN ATOMIC
	INSERT INTO ADMINISTRATOR.ACCT_HISTORY
	(SSN, BEFORE_BALANCE, AFTER_BALANCE, WHEN, BY_WHO)
	VALUES (O.SSN, O.ACCT_BALANCE, N.ACCT_BALANCE,
	CURRENT TIMESTAMP, SESSION_USER);
END@


-- Connect as john the accountant;


CONNECT TO sample USER john USING test1234@


-- The account balance of the patients is updated in patient table;
-- and the trigger fires updating the ACCT_HISTORY table;
--  with acct_balance before and after update;

-- Before updation;


SELECT ACCT_BALANCE FROM ADMINISTRATOR.PATIENT WHERE SSN = '123-45-6789'@
SELECT SSN,BEFORE_BALANCE,AFTER_BALANCE,BY_WHO	FROM ADMINISTRATOR.ACCT_HISTORY WHERE SSN = '123-45-6789'@


-- John updates the table patient (Trigger fires);


UPDATE ADMINISTRATOR.PATIENT SET ACCT_BALANCE = ACCT_BALANCE * 0.9
WHERE SSN = '123-45-6789'@


-- After updation;


SELECT ACCT_BALANCE FROM ADMINISTRATOR.PATIENT WHERE SSN = '123-45-6789'@ 
SELECT SSN,BEFORE_BALANCE,AFTER_BALANCE,BY_WHO	FROM ADMINISTRATOR.ACCT_HISTORY WHERE SSN = '123-45-6789'@


-- Connect as Alex and revoke Pauls privilege to create;
-- secure object.;


CONNECT TO sample USER alex USING test1234@

REVOKE CREATE_SECURE_OBJECT ON DATABASE FROM USER paul@

--Sample complete

--Dropping all objects
DROP MASK ADMINISTRATOR.ACCT_BALANCE_MASK@
DROP MASK ADMINISTRATOR.SSN_MASK@
DROP MASK ADMINISTRATOR.PHARMACY_MASK@
DROP PERMISSION ADMINISTRATOR.ROW_ACCESS@


CONNECT RESET@

CONNECT TO sample@

DROP VIEW ADMINISTRATOR.PATIENT_INFO_VIEW@
DROP FUNCTION ADMINISTRATOR.EXPHMOACCOUNTINGUDF@
DROP FUNCTION ADMINISTRATOR.DRUGUDF@
DROP TRIGGER ADMINISTRATOR.EXPHMO_ACCT_BALANCE_TRIGGER@

DROP TABLE ADMINISTRATOR.PATIENT@
DROP TABLE ADMINISTRATOR.PATIENTCHOICE@
DROP TABLE ADMINISTRATOR.ACCT_HISTORY@

DROP ROLE PCP@
DROP ROLE DRUG_RESEARCH@
DROP ROLE ACCOUNTING@
DROP ROLE MEMBERSHIP@
DROP ROLE PATIENT@

CONNECT RESET@
