-- /***************************************************************************/
-- /*  (c) Copyright IBM Corp. 2007 All rights reserved.
-- /*  
-- /*  The following sample of source code ("Sample") is owned by International 
-- /*  Business Machines Corporation or one of its subsidiaries ("IBM") and is 
-- /*  copyrighted and licensed, not sold. You may use, copy, modify, and 
-- /*  distribute the Sample in any form without payment to IBM, for the purpose of 
-- /*  assisting you in the development of your applications.
-- /*  
-- /*  The Sample code is provided to you on an "AS IS" basis, without warranty of 
-- /*  any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
-- /*  IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- /*  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
-- /*  not allow for the exclusion or limitation of implied warranties, so the above 
-- /*  limitations or exclusions may not apply to you. IBM shall not be liable for 
-- /*  any damages you suffer as a result of using, copying, modifying or 
-- /*  distributing the Sample, even if IBM has been advised of the possibility of 
-- /*  such damages.
-- /***************************************************************************/
-- /*                                                                         */
-- /* SAMPLE FILE NAME: audit.db2                                             */
-- /*                                                                         */
-- /* PURPOSE         : To demonstrate the new features in db2audit utility.  */
-- /*                                                                         */
-- /* USAGE SCENARIO  : The usage scenario is based on the Online Banking     */ 
-- /*   Transaction Processing (OLTP). In an international bank database,     */
-- /*   tables like TRANSACTION, ACCOUNT, PERSONALINFO contain extremely      */
-- /*   sensitive information. To track access to these tables, bank can      */
-- /*   create many new db2audit policies depending on the roles of people    */
-- /*   who are accessing these tables. In future if bank decides to modify   */
-- /*   these policies, DB2 provides the bank with the ALTER AUDIT POLICY     */
-- /*   command. In a similar way bank can use DROP AUDIT POLICY to drop any  */
-- /*   existing audit policies. DB2 facilitates the bank in taking the backup*/
-- /*   of audit data for future reference using db2audit archive command and */
-- /*   retrieving the data using extract command. DB2 provides one more      */
-- /*   method to archive and extract the audit data using AUDIT_ARCHIVE      */
-- /*   and AUDIT_DELIM_EXTRACT stored procedure respectively.                */
-- /*                                                                         */
-- /* PREREQUISITE    :                                                       */
-- /*                   1. Two userid's present on the machine.               */
-- /*                   2. One user with SYSADM authority.                    */
-- /*                   3. Second user name is joe, password is abcd1234      */
-- /*                                                                         */
-- /* EXECUTION       : db2 -tvf audit.db2                                    */
-- /*                                                                         */
-- /* INPUTS          : NONE                                                  */
-- /*                                                                         */
-- /* OUTPUT          : Audit data in the form of delimited files in side     */
-- /*                   the current working directory                         */ 
-- /*                                                                         */
-- /* OUTPUT FILE     : audit.out                                             */
-- /*                   (available in the online documentation)               */
-- /***************************************************************************/
-- /*For more information about the command line processor (CLP) scripts,     */
-- /*see the README file.                                                     */
-- /*For information on using SQL statements, see the SQL Reference.          */
-- /*                                                                         */
-- /*For the latest information on programming, building, and running DB2     */
-- /*applications, visit the DB2 application development website:             */
-- /*http://www.software.ibm.com/data/db2/udb/ad                              */
-- /***************************************************************************/

-- /***************************************************************************/
-- /* SAMPLE DESCRIPTION                                                      */
-- /***************************************************************************/
-- /* 1. Setup the db2audit environment.                                      */
-- /* 2. Create, alter and drop audit policies.                               */
-- /* 3. Apply AUDIT statement on different objects.                          */
-- /* 4. Run transactions to generate audit data.                             */ 
-- /* 5. Archive the audit data to different location.                        */
-- /* 6. Extract the audit data when required.                                */ 
-- /* 7. Loading the extracted del files to view the audit data.              */     
-- /***************************************************************************/

-- /***************************************************************************/
-- /*                   SETUP THE DB2AUDIT ENVIRONMENT                        */
-- /***************************************************************************/

--
-- Create a database BANKDB and connect to BANKDB.
--
CREATE DATABASE BANKDB;

CONNECT TO BANKDB;

--
-- Create an 8K bufferpool.
--
CREATE BUFFERPOOL bpool8k SIZE 20000 PAGESIZE 8 K;

--
-- Create an 8K tablespace associating the bufferpool bpool8k.  
--
CREATE TABLESPACE tbsp_8k 
  PAGESIZE 8 K 
  BUFFERPOOL bpool8k;

--
-- Grant the SECADM privilege to execute the audit statements.
--
GRANT SECADM ON DATABASE TO USER joe;

--
-- Grant the EXECUTE privilege to execute the audit routines.
--
GRANT EXECUTE ON FUNCTION SYSPROC.AUDIT_ARCHIVE TO USER joe;
GRANT EXECUTE ON PROCEDURE SYSPROC.AUDIT_ARCHIVE TO USER joe;
GRANT EXECUTE ON PROCEDURE SYSPROC.AUDIT_DELIM_EXTRACT TO USER joe;
GRANT EXECUTE ON FUNCTION SYSPROC.AUDIT_LIST_LOGS TO USER joe;

--
-- Connect to BANKDB as SECADM.
--
CONNECT TO BANKDB USER joe USING abcd1234;

--
-- Execute the db2audit DDL to create audit tables.
-- AUDIT CATEGORY
--
CREATE TABLE DB2AUDIT.AUDIT ( TIMESTAMP CHAR(32 OCTETS),
                              CATEGORY CHAR(32 OCTETS),
                              EVENT VARCHAR(32 OCTETS),
                              CORRELATOR INTEGER,
                              STATUS INTEGER,
                              USERID VARCHAR(1024 OCTETS),
                              AUTHID VARCHAR(128 OCTETS),
                              DATABASE CHAR(8 OCTETS),
                              NODENUM SMALLINT,
                              COORDNUM SMALLINT,
                              APPID VARCHAR(255 OCTETS),
                              APPNAME VARCHAR(1024 OCTETS),
                              PKGSCHEMA VARCHAR(128 OCTETS),
                              PKGNAME VARCHAR(128 OCTETS),
                              PKGSECNUM SMALLINT,
                              PKGVER VARCHAR(64 OCTETS),
                              LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                              GLBLTRANSID VARCHAR(32 OCTETS) FOR BIT DATA,
                              CLNTUSERID VARCHAR(255 OCTETS),
                              CLNTWRKSTNAME VARCHAR(255 OCTETS),
                              CLNTAPPNAME VARCHAR(255 OCTETS),
                              CLNTACCSTRING VARCHAR(255 OCTETS),
                              TRSTCTXNAME VARCHAR(255 OCTETS),
                              CONTRSTTYPE CHAR(1 OCTETS),
                              ROLEINHERITED VARCHAR(128 OCTETS),
                              POLNAME VARCHAR(128 OCTETS),
                              POLASSOCOBJTYPE CHAR(10 OCTETS),
                              POLASSOCSUBOBJTYPE CHAR(10 OCTETS),
                              POLASSOCNAME VARCHAR(128 OCTETS),
                              OBJSCHEMA VARCHAR(128 OCTETS),
                              AUDITSTATUS CHAR(1 OCTETS),
                              CHECKINGSTATUS CHAR(1 OCTETS),
                              CONTEXTSTATUS CHAR(1 OCTETS),
                              EXECUTESTATUS CHAR(1 OCTETS),
                              EXECUTEDATA CHAR(1 OCTETS),
                              OBJMAINTSTATUS CHAR(1 OCTETS),
                              SECMAINTSTATUS CHAR(1 OCTETS),
                              SYSADMINSTATUS CHAR(1 OCTETS),
                              VALIDATESTATUS CHAR(1 OCTETS),
                              ERRORTYPE CHAR(8 OCTETS),
                              DATAPATH VARCHAR(1024 OCTETS),
                              ARCHIVEPATH VARCHAR(1024 OCTETS),
                              ORIGUSERID VARCHAR(1024 OCTETS),
                              INSTNAME VARCHAR(128 OCTETS),
                              HOSTNAME VARCHAR(255 OCTETS));

--
-- CHECKING CATEGORY
--

CREATE TABLE DB2AUDIT.CHECKING ( TIMESTAMP CHAR(32 OCTETS),
                                 CATEGORY CHAR(32 OCTETS),
                                 EVENT VARCHAR(32 OCTETS),
                                 CORRELATOR INTEGER,
                                 STATUS INTEGER,
                                 DATABASE CHAR(8 OCTETS),
                                 USERID VARCHAR(1024 OCTETS),
                                 AUTHID VARCHAR(128 OCTETS),
                                 NODENUM SMALLINT,
                                 COORDNUM SMALLINT,
                                 APPID VARCHAR(255 OCTETS),
                                 APPNAME VARCHAR(1024 OCTETS),
                                 PKGSCHEMA VARCHAR(128 OCTETS),
                                 PKGNAME VARCHAR(128 OCTETS),
                                 PKGSECNUM SMALLINT,
                                 OBJSCHEMA VARCHAR(128 OCTETS),
                                 OBJNAME VARCHAR(128 OCTETS),
                                 OBJTYPE VARCHAR(32 OCTETS),
                                 ACCESSAPP CHAR(34 OCTETS),
                                 ACCESSATT CHAR(34 OCTETS),
                                 PKGVER VARCHAR(64 OCTETS),
                                 CHKAUTHID VARCHAR(128 OCTETS),
                                 LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                                 GLBLTRANSID VARCHAR(32 OCTETS) FOR BIT DATA,
                                 CLNTUSERID VARCHAR(255 OCTETS),
                                 CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                 CLNTAPPNAME VARCHAR(255 OCTETS),
                                 CLNTACCSTRING VARCHAR(255 OCTETS),
                                 TRSTCTXNAME VARCHAR(255 OCTETS),
                                 CONTRSTTYPE CHAR(1 OCTETS),
                                 ROLEINHERITED VARCHAR(128 OCTETS),
                                 ORIGUSERID VARCHAR(1024 OCTETS),
                                 INSTNAME VARCHAR(128 OCTETS),
                                 HOSTNAME VARCHAR(255 OCTETS));

--
-- OBJMAINT CATEGORY
--

CREATE TABLE DB2AUDIT.OBJMAINT ( TIMESTAMP CHAR(32 OCTETS),
                                 CATEGORY CHAR(32 OCTETS),
                                 EVENT VARCHAR(32 OCTETS),
                                 CORRELATOR INTEGER,
                                 STATUS INTEGER,
                                 DATABASE CHAR(8 OCTETS),
                                 USERID VARCHAR(1024 OCTETS),
                                 AUTHID VARCHAR(128 OCTETS),
                                 NODENUM SMALLINT,
                                 COORDNUM SMALLINT,
                                 APPID VARCHAR(255 OCTETS),
                                 APPNAME VARCHAR(1024 OCTETS),
                                 PKGSCHEMA VARCHAR(128 OCTETS),
                                 PKGNAME VARCHAR(128 OCTETS),
                                 PKGSECNUM SMALLINT,
                                 OBJSCHEMA VARCHAR(128 OCTETS),
                                 OBJNAME VARCHAR(128 OCTETS),
                                 OBJTYPE VARCHAR(32 OCTETS),
                                 PACKVER VARCHAR(64 OCTETS),
                                 SECPOLNAME VARCHAR(128 OCTETS),
                                 ALTERACTION VARCHAR(32 OCTETS),
                                 PROTCOLNAME VARCHAR(128 OCTETS),
                                 COLSECLABEL VARCHAR(128 OCTETS),
                                 SECCOLNAME VARCHAR(128 OCTETS),
                                 LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                                 GLBLTRANSID VARCHAR(32 OCTETS) FOR BIT DATA,
                                 CLNTUSERID VARCHAR(255 OCTETS),
                                 CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                 CLNTAPPNAME VARCHAR(255 OCTETS),
                                 CLNTACCSTRING VARCHAR(255 OCTETS),
                                 TRSTCTXNAME VARCHAR(255 OCTETS),
                                 CONTRSTTYPE CHAR(1 OCTETS),
                                 ROLEINHERITED VARCHAR(128 OCTETS),
                                 MODULENAME VARCHAR(128 OCTETS),
                                 ASSOCOBJNAME VARCHAR(128 OCTETS),
                                 ASSOCOBJSCHEMA VARCHAR(128 OCTETS),
                                 ASSOCOBJTYPE VARCHAR(32 OCTETS),
                                 ASSOCSUBOBJNAME VARCHAR(128 OCTETS),
                                 ASSOCSUBOBJTYPE VARCHAR(32 OCTETS),
                                 SECURED VARCHAR(32 OCTETS),
                                 STATE VARCHAR(32 OCTETS),
                                 ACCESSCONTROL VARCHAR(32 OCTETS),
                                 ORIGUSERID VARCHAR(1024 OCTETS),
                                 INSTNAME VARCHAR(128 OCTETS),
                                 HOSTNAME VARCHAR(255 OCTETS));


--
-- SECMAINT CATEGORY
--

CREATE TABLE DB2AUDIT.SECMAINT ( TIMESTAMP CHAR(32 OCTETS),
                                 CATEGORY CHAR(32 OCTETS),
                                 EVENT VARCHAR(32 OCTETS),
                                 CORRELATOR INTEGER,
                                 STATUS INTEGER,
                                 DATABASE CHAR(8 OCTETS),
                                 USERID VARCHAR(1024 OCTETS),
                                 AUTHID VARCHAR(128 OCTETS),
                                 NODENUM SMALLINT,
                                 COORDNUM SMALLINT,
                                 APPID VARCHAR(255 OCTETS),
                                 APPNAME VARCHAR(1024 OCTETS),
                                 PKGSCHEMA VARCHAR(128 OCTETS),
                                 PKGNAME VARCHAR(128 OCTETS),
                                 PKGSECNUM SMALLINT,
                                 OBJSCHEMA VARCHAR(128 OCTETS),
                                 OBJNAME VARCHAR(128 OCTETS),
                                 OBJTYPE VARCHAR(32 OCTETS),
                                 GRANTOR VARCHAR(128 OCTETS),
                                 GRANTEE VARCHAR(128 OCTETS),
                                 GRANTEETYPE VARCHAR(32 OCTETS),
                                 PRIVAUTH CHAR(34 OCTETS),
                                 PKGVER VARCHAR(64 OCTETS),
                                 ACCESSTYPE VARCHAR(32 OCTETS),
                                 ASSUMEAUTHID VARCHAR(128 OCTETS),
                                 LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                                 GLBLTRANSID VARCHAR(32 OCTETS) FOR BIT DATA,
                                 GRANTORTYPE VARCHAR(32 OCTETS),
                                 CLNTUSERID VARCHAR(255 OCTETS),
                                 CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                 CLNTAPPNAME VARCHAR(255 OCTETS),
                                 CLNTACCSTRING VARCHAR(255 OCTETS),
                                 TRSTCTXUSER VARCHAR(128 OCTETS),
                                 TRSTCTXUSERAUTH INTEGER,
                                 TRSTCTXNAME VARCHAR(255 OCTETS),
                                 CONTRSTTYPE CHAR(1 OCTETS),
                                 ROLEINHERITED VARCHAR(128 OCTETS),
                                 ALTERACTION VARCHAR(32 OCTETS),
                                 ASSOCOBJNAME VARCHAR(128 OCTETS),
                                 ASSOCOBJSCHEMA VARCHAR(128 OCTETS),
                                 ASSOCOBJTYPE VARCHAR(32 OCTETS),
                                 ASSOCSUBOBJNAME VARCHAR(128 OCTETS),
                                 ASSOCSUBOBJTYPE VARCHAR(32 OCTETS),
                                 SECURED VARCHAR(32 OCTETS),
                                 STATE VARCHAR(32 OCTETS),
                                 ACCESSCONTROL VARCHAR(32 OCTETS),
                                 ORIGUSERID VARCHAR(1024 OCTETS),
                                 INSTNAME VARCHAR(128 OCTETS),
                                 HOSTNAME VARCHAR(255 OCTETS));


--
-- SYSADMIN CATEGORY
--

CREATE TABLE DB2AUDIT.SYSADMIN ( TIMESTAMP CHAR(32 OCTETS),
                                 CATEGORY CHAR(32 OCTETS),
                                 EVENT VARCHAR(32 OCTETS),
                                 CORRELATOR INTEGER,
                                 STATUS INTEGER,
                                 DATABASE CHAR(8 OCTETS),
                                 USERID VARCHAR(1024 OCTETS),
                                 AUTHID VARCHAR(128 OCTETS),
                                 NODENUM SMALLINT,
                                 COORDNUM SMALLINT,
                                 APPID VARCHAR(255 OCTETS),
                                 APPNAME VARCHAR(1024 OCTETS),
                                 PKGSCHEMA VARCHAR(128 OCTETS),
                                 PKGNAME VARCHAR(128 OCTETS),
                                 PKGSECNUM SMALLINT,
                                 PKGVER VARCHAR(64 OCTETS),
                                 LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                                 GLBLTRANSID VARCHAR(32 OCTETS) FOR BIT DATA,
                                 CLNTUSERID VARCHAR(255 OCTETS),
                                 CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                 CLNTAPPNAME VARCHAR(255 OCTETS),
                                 CLNTACCSTRING VARCHAR(255 OCTETS),
                                 TRSTCTXNAME VARCHAR(255 OCTETS),
                                 CONTRSTTYPE CHAR(1 OCTETS),
                                 ROLEINHERITED VARCHAR(128 OCTETS),
                                 ORIGUSERID VARCHAR(1024 OCTETS),
                                 EVENTDETAILS VARCHAR(2048 OCTETS),
                                 INSTNAME VARCHAR(128 OCTETS),
                                 HOSTNAME VARCHAR(255 OCTETS));

--
-- VALIDATE CATEGORY
--

CREATE TABLE DB2AUDIT.VALIDATE ( TIMESTAMP CHAR(32 OCTETS),
                                 CATEGORY CHAR(32 OCTETS),
                                 EVENT VARCHAR(32 OCTETS),
                                 CORRELATOR INTEGER,
                                 STATUS INTEGER,
                                 DATABASE CHAR(8 OCTETS),
                                 USERID VARCHAR(1024 OCTETS),
                                 AUTHID VARCHAR(128 OCTETS),
                                 EXECID VARCHAR(1024 OCTETS),
                                 NODENUM SMALLINT,
                                 COORDNUM SMALLINT,
                                 APPID VARCHAR(255 OCTETS),
                                 APPNAME VARCHAR(1024 OCTETS),
                                 AUTHTYPE VARCHAR(32 OCTETS),
                                 PKGSCHEMA VARCHAR(128 OCTETS),
                                 PKGNAME VARCHAR(128 OCTETS),
                                 PKGSECNUM SMALLINT,
                                 PKGVER VARCHAR(64 OCTETS),
                                 LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                                 GLBLTRANSID VARCHAR(32 OCTETS) FOR BIT DATA,
                                 PLUGINNAME VARCHAR(32 OCTETS),
                                 CLNTUSERID VARCHAR(255 OCTETS),
                                 CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                 CLNTAPPNAME VARCHAR(255 OCTETS),
                                 CLNTACCSTRING VARCHAR(255 OCTETS),
                                 TRSTCTXNAME VARCHAR(255 OCTETS),
                                 CONTRSTTYPE CHAR(1 OCTETS),
                                 ROLEINHERITED VARCHAR(128 OCTETS),
                                 ORIGUSERID VARCHAR(1024 OCTETS),
                                 INSTNAME VARCHAR(128 OCTETS),
                                 HOSTNAME VARCHAR(255 OCTETS));

--
-- CONTEXT CATEGORY
--

CREATE TABLE DB2AUDIT.CONTEXT ( TIMESTAMP CHAR(32 OCTETS),
                                CATEGORY CHAR(32 OCTETS),
                                EVENT VARCHAR(32 OCTETS),
                                CORRELATOR INTEGER,
                                DATABASE CHAR(8 OCTETS),
                                USERID VARCHAR(1024 OCTETS),
                                AUTHID VARCHAR(128 OCTETS),
                                NODENUM SMALLINT,
                                COORDNUM SMALLINT,
                                APPID VARCHAR(255 OCTETS),
                                APPNAME VARCHAR(1024 OCTETS),
                                PKGSCHEMA VARCHAR(128 OCTETS),
                                PKGNAME VARCHAR(128 OCTETS),
                                PKGSECNUM SMALLINT,
                                STMTTEXT CLOB(2M OCTETS),
                                PKGVER VARCHAR(64 OCTETS),
                                LCLTRANSID VARCHAR(16 OCTETS) FOR BIT DATA,
                                GLBLTRANSID VARCHAR(64 OCTETS) FOR BIT DATA,
                                CLNTUSERID VARCHAR(255 OCTETS),
                                CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                CLNTAPPNAME VARCHAR(255 OCTETS),
                                CLNTACCSTRING VARCHAR(255 OCTETS),
                                TRSTCTXNAME VARCHAR(255 OCTETS),
                                CONTRSTTYPE CHAR(1 OCTETS),
                                ROLEINHERITED VARCHAR(255 OCTETS),
                                ORIGUSERID VARCHAR(1024 OCTETS),
                                INSTNAME VARCHAR(128 OCTETS),
                                HOSTNAME VARCHAR(255 OCTETS));

--
-- EXECUTE CATEGORY
--

CREATE TABLE DB2AUDIT.EXECUTE ( TIMESTAMP CHAR(32 OCTETS),
                                CATEGORY CHAR(32 OCTETS),
                                EVENT VARCHAR(32 OCTETS),
                                CORRELATOR INTEGER,
                                STATUS INTEGER,
                                DATABASE CHAR(8 OCTETS),
                                USERID VARCHAR(1024 OCTETS),
                                AUTHID VARCHAR(128 OCTETS),
                                SESSNAUTHID VARCHAR(128 OCTETS),
                                NODENUM SMALLINT,
                                COORDNUM SMALLINT,
                                APPID VARCHAR(255 OCTETS),
                                APPNAME VARCHAR(1024 OCTETS),
                                CLNTUSERID VARCHAR(255 OCTETS),
                                CLNTWRKSTNAME VARCHAR(255 OCTETS),
                                CLNTAPPNAME VARCHAR(255 OCTETS),
                                CLNTACCSTRING VARCHAR(255 OCTETS),
                                TRSTCTXNAME VARCHAR(255 OCTETS),
                                CONTRSTTYPE CHAR(1 OCTETS),
                                ROLEINHERITED VARCHAR(128 OCTETS),
                                PKGSCHEMA VARCHAR(128 OCTETS),
                                PKGNAME VARCHAR(128 OCTETS),
                                PKGSECNUM SMALLINT,
                                PKGVER VARCHAR(64 OCTETS),
                                LCLTRANSID VARCHAR(10 OCTETS) FOR BIT DATA,
                                GLBLTRANSID VARCHAR(30 OCTETS) FOR BIT DATA,
                                UOWID BIGINT,
                                ACTIVITYID BIGINT,
                                STMTINVOCID BIGINT,
                                STMTNESTLVL BIGINT,
                                STMTTYPE VARCHAR(128 OCTETS),
                                STMTISOLATIONLVL CHAR(128 OCTETS),
                                ROWSREAD CHAR(128 OCTETS),
                                ROWSMODIFIED CHAR(32 OCTETS),
                                ROWSRETURNED CHAR(16 OCTETS),
                                STMTTEXT CLOB(2M OCTETS),
                                COMPENVDESC BLOB(8K),
                                STMTVALINDEX INTEGER,
                                STMTVALTYPE CHAR(16 OCTETS),
                                STMTVALDATA CLOB(32K OCTETS),
                                LOCAL_START_TIME CHAR(32 OCTETS),
                                ORIGUSERID VARCHAR(1024 OCTETS),
                                INSTNAME VARCHAR(128 OCTETS),
                                HOSTNAME VARCHAR(255 OCTETS));

--
-- Configure the datapath and archivepath for audit purpose.
--
! db2audit CONFIGURE datapath "$HOME" 
                     archivepath "$HOME";

-- /***************************************************************************/
-- /*                   CREATE THE REQUIRED BANK TABLES                       */
-- /***************************************************************************/

--
-- Create TRANSACTION, ACCOUNT and PERSONALINFO tables.
--
CREATE TABLE TRANSACTION ( AccNo INT  NOT NULL,
                           TrDate DATE,
                           TrType VARCHAR(10),
                           Amount DECIMAL(7,2),
                           Remarks VARCHAR(50) );

CREATE TABLE ACCOUNT ( CName 	VARCHAR(30),
                       AccType VARCHAR(10) NOT NULL,
                       AccNo 	INT NOT NULL PRIMARY KEY,
                       CType 	VARCHAR(10),
                       TrDate	DATE,
                       Balance DECIMAL(9,2),
                       Remarks VARCHAR(50) );

CREATE TABLE PERSONALINFO ( CName	VARCHAR(30),
                            CType	VARCHAR(10),
                            CPhone	VARCHAR(15),
                            CAddress VARCHAR(100),
                            LoanInfo VARCHAR(50),
                            Remarks	VARCHAR(50) );

-- /***************************************************************************/
-- /*                      CREATE AUDIT POLYCIES                              */
-- /***************************************************************************/

--
-- Create TRANSACTIONPOLICY to generate the audit records to show the
-- execution of SQL statements.
--
CREATE AUDIT POLICY TRANSACTIONPOLICY 
  CATEGORIES EXECUTE STATUS BOTH 
  ERROR TYPE AUDIT; 

--
-- Create ACCOUNTPOLICY to generate the audit records for any thing happening 
-- on the table.
--
CREATE AUDIT POLICY ACCOUNTPOLICY
  CATEGORIES ALL STATUS BOTH
  ERROR TYPE AUDIT;

--
-- Create PERSONALADMINPOLICY to generate the audit records when
--                               creating or dropping data objects,
--                               granting or revoking object privileges,
--                               granting or revoking database privileges,
--                               granting or revoking DBADM authority,
--                               authenticating users or retrieving system 
--                               security information related to a user. 
--
CREATE AUDIT POLICY PERSONALADMINPOLICY
  CATEGORIES OBJMAINT STATUS BOTH, 
  SECMAINT STATUS BOTH,
  SYSADMIN STATUS BOTH,
  VALIDATE STATUS FAILURE
  ERROR TYPE AUDIT;

COMMIT;

-- /***************************************************************************/
-- /*                       ALTER AUDIT POLYCY                                */
-- /***************************************************************************/

--
-- Alter the current policy TRANSACTIONPOLICY to audit all the information.        
--
ALTER AUDIT POLICY TRANSACTIONPOLICY 
  CATEGORIES ALL STATUS BOTH 
  ERROR TYPE AUDIT;

COMMIT;

-- /***************************************************************************/
-- /*                       DROP AUDIT POLYCY                                 */
-- /***************************************************************************/

--
-- Drop the the current policy TRANSACTIONPOLICY
--
-- DROP AUDIT POLICY TRANSACTIONPOLICY;
-- COMMIT;

-- /***************************************************************************/
-- /*              APPLY AUDIT STATEMENTS ON DIFFERENT OBJECTS                */
-- /***************************************************************************/

--
-- Audit the database using the TRANSACTIONPOLICY policy.
--
AUDIT DATABASE USING POLICY TRANSACTIONPOLICY;

--
-- Audit the table ACCOUNT using ACCOUNTPOLICY policy.
--
AUDIT TABLE ACCOUNT USING POLICY ACCOUNTPOLICY;

--
-- Audit the SYSADM, SYSMAINT, SECADM, DBADM activities using 
-- PERSONALADMINPOLICY policy.
--
AUDIT SYSADM, SYSMAINT, SECADM, DBADM USING POLICY PERSONALADMINPOLICY;

-- /***************************************************************************/
-- /*                           RUN TRANSACTIONS                              */
-- /***************************************************************************/

--
-- Run transactions on table TRANSACTION
-- Insert records into the table TRANSACTION 
--
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-20', 'CREDIT', 2000.00, '2000$ 
        	                 got credited from AccNo 01232 Citi Bank');
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-20', 'CREDIT', 1050.00, '1050$
                                 got credited from AccNo 98211 AMEX Bank');
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-20', 'DEBIT', 100.00, '100$ got
                                 debited and credited to American Express');
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-21', 'CREDIT', 200.00, '200$
                                 got credited from AccNo 87342 HSBC Bank');
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-23', 'CREDIT', 400.00, '400$
                                 got credited from AccNo 81234 HSBC Bank');
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-26', 'DEBIT', 600.00, '600$
                                 got debited and credited to AMEX Loan');
INSERT INTO TRANSACTION VALUES ( 1000, '2007-01-30', 'CREDIT', 4000.00, '4000$
                                 got credited BI-MONTHLY Salary for JAN 2007');
COMMIT;

--
-- Select the records from TRANSACTION
--
SELECT TrDate, TrType, Amount, Remarks FROM TRANSACTION;

--
-- Run transactions on table ACCOUNT
-- Insert records into the table ACCOUNT
--
INSERT INTO ACCOUNT VALUES ( 'MOHAN SARASWATIPURA', 'SALARY', 1000, 'GOLD', 
                             '2007-01-30', 20000.00, 'Balance amount 
                             is 20000$');
INSERT INTO ACCOUNT VALUES ( 'PRAVEEN SOGALAD', 'SALARY', 1010, 'GOLD',
                             '2007-01-30', 20200.00, 'Balance amount is 20200$');
INSERT INTO ACCOUNT VALUES ( 'SANJAY KUMAR', 'SALARY', 1020, 'GOLD','2007-02-13',
                             30010.00, 'Balance amount is 30010$');
INSERT INTO ACCOUNT VALUES ( 'GAURAV SHUKLA', 'SALARY', 2001, 'GOLD','2007-01-30',
                             15001.00, 'Balance amount is 15001$');
INSERT INTO ACCOUNT VALUES ( 'ITI RAWAT', 'SALARY', 1030, 'GOLD','2007-01-30',
                             30000.00, 'Balance amount is 30000$');
INSERT INTO ACCOUNT VALUES ( 'MARK TAYLOR', 'SAVING', 4030, 'GOLD','2007-01-30',
                             52000.00, 'Balance amount is 52000$');
COMMIT;

--
-- Select the records from ACCOUNT
--
SELECT CName, AccType, AccNo, TrDate, Balance FROM ACCOUNT;

--
-- Run transactions on table PERSONALINFO
-- Insert records into the table PERSONALINFO
--
INSERT INTO PERSONALINFO VALUES ( 'MOHAN SARASWATIPURA', 'GOLD', '9880012396',
                                  'VIJAYNAGAR, BANGALORE', 'PERSONAL LOAN PLoanNo:
                                  1233812', 'GOLD CUSTOMER');
INSERT INTO PERSONALINFO VALUES ( 'PRAVEEN SOGALAD', 'GOLD', '9881212391', 
                                  'VIJAYNAGAR, BANGALORE', 'HOME LOAN HLoanNo: 
                                  0129111', 'GOLD CUSTOMER');
INSERT INTO PERSONALINFO VALUES ( 'SANJAY KUMAR', 'GOLD', '9900012345', 
                                  'INDIRANAGAR, BANGALORE', 'HOME LOAN HLoanNo:
                                  1112911', 'GOLD CUSTOMER');
INSERT INTO PERSONALINFO VALUES ( 'GAURAV SHUKLA', 'GOLD', '9900054321', 
                                  'RAJAJINAGAR, BANGALORE', 'No Information', 
                                  'GOLD CUSTOMER');
INSERT INTO PERSONALINFO VALUES ( 'ITI RAWAT', 'GOLD', '9990012345', 
                                  'INDIRANAGAR, BANGALORE', 'HOME LOAN HLoanNo: 
                                  2112911', 'GOLD CUSTOMER');
INSERT INTO PERSONALINFO VALUES ( 'MARK TAYLOR', 'GOLD', '602-712121',
                                  'ARIZONA, USA', 'No Information', 'GOLD CUSTOMER');

-- /***************************************************************************/
-- /*                      ARCHIVE THE AUDIT LOGS                             */
-- /***************************************************************************/

--
-- Archive the audit data to different location.
-- METHOD: 1
-- Archival using normal db2audit command.
-- 
-- ! db2audit ARCHIVE DATABASE BANKDB TO "$HOME";

-- METHOD: 2
-- Archival can also be enabled using the stored procedure.
-- 
! db2 "CONNECT TO BANKDB USER joe USING abcd1234";
CALL SYSPROC.AUDIT_ARCHIVE(NULL,0);
--
-- Parameter NULL specifies '$HOME' as the default archive location.
-- -2 instead of 0 enables the archive on all the nodes in case of MPP setup.
--

-- /***************************************************************************/
-- /*                      EXTRACT THE AUDIT LOGS                             */
-- /***************************************************************************/

--
-- Extract the audit data from the archive logs to AUDIT directory.
--

! db2 "CONNECT TO BANKDB USER joe USING abcd1234";
CALL SYSPROC.AUDIT_DELIM_EXTRACT (';',NULL,NULL,
       'db2audit.db.BANKDB.log.%.20%',' '); 

--
-- Parameter ';' specifies the delimiter in extracted log files. 
-- Parameter NULL specifies '$HOME' as the default audit logs extract location.
-- Parameter NULL specifies '$HOME' as the archive logs location. 
-- Parameter 'db2audit.db.BANKDB.log.%.20%' specifies the log name.
-- Parameter ' ' directs stored procedure to extract all the activities.
-- One can specify 'execute status failure' to extract only the execute 
-- failures.
--

-- /***************************************************************************/
-- /*               IMPORT DELIMITED FILES TO AUDIT TABLES                    */
-- /***************************************************************************/

-- 
-- Import the extracted del files to audit tables for auditing purpose.
-- Uncomment the comments to load the data into audit tables
--                         			DB2AUDIT.AUDIT
--                        		 	DB2AUDIT.CHECKING
--                         			DB2AUDIT.OBJMAINT
--                         			DB2AUDIT.SECMAINT
--                         			DB2AUDIT.SYSADMIN
--                         			DB2AUDIT.VALIDATE
--                         			DB2AUDIT.CONTEXT
--                         			DB2AUDIT.EXECUTE
-- 

 
! db2stop force;
! db2start;

-- ! db2 "CONNECT TO BANKDB USER joe USING abcd1234";
-- ! db2 "SET SCHEMA DB2AUDIT";
-- ! db2 "IMPORT FROM $HOME/audit.del OF DEL REPLACE INTO AUDIT";
-- ! db2 "IMPORT FROM $HOME/checking.del OF DEL REPLACE INTO CHECKING";
-- ! db2 "IMPORT FROM $HOME/objmaint.del OF DEL REPLACE INTO OBJMAINT";
-- ! db2 "IMPORT FROM $HOME/secmaint.del OF DEL REPLACE INTO SECMAINT";
-- ! db2 "IMPORT FROM $HOME/sysadmin.del OF DEL REPLACE INTO SYSADMIN";
-- ! db2 "IMPORT FROM $HOME/validate.del OF DEL REPLACE INTO VALIDATE";
-- ! db2 "IMPORT FROM $HOME/context.del OF DEL REPLACE INTO CONTEXT";
-- ! db2 "IMPORT FROM $HOME/execute.del OF DEL REPLACE INTO EXECUTE";

-- /***************************************************************************/
-- /*                        VIEW THE AUDIT DATA                              */
-- /***************************************************************************/
-- 
-- Connect to database BANKDB;
-- Execute select statement on the tables 
--                         DB2AUDIT.AUDIT
--                         DB2AUDIT.CHECKING
--                         DB2AUDIT.OBJMAINT
--                         DB2AUDIT.SECMAINT
--                         DB2AUDIT.SYSADMIN
--                         DB2AUDIT.VALIDATE
--                         DB2AUDIT.CONTEXT
--                         DB2AUDIT.EXECUTE
-- Uncomment the comments to view the records

-- ! db2 "CONNECT TO BANKDB USER joe USING abcd1234";
-- ! db2 "SET SCHEMA DB2AUDIT";
-- ! db2 "SELECT * FROM AUDIT";
-- ! db2 "SELECT * FROM CHECKING";
-- ! db2 "SELECT * FROM OBJMAINT";
-- ! db2 "SELECT * FROM SECMAINT";
-- ! db2 "SELECT * FROM SYSADMIN";
-- ! db2 "SELECT * FROM VALIDATE";
-- ! db2 "SELECT * FROM CONTEXT";
-- ! db2 "SELECT * FROM EXECUTE";

-- /***************************************************************************/
-- /*                              CLEAN UP                                   */
-- /***************************************************************************/

! db2stop force;
! db2start;
DROP DB BANKDB;

! rm $HOME/audit.del;
! rm $HOME/checking.del;
! rm $HOME/context.del;
! rm $HOME/execute.del;
! rm $HOME/objmaint.del;
! rm $HOME/secmaint.del;
! rm $HOME/sysadmin.del;
! rm $HOME/validate.del;
! rm -rf  $HOME/db2audit.db.BANKDB.*;
! rm $HOME/auditlobs;

TERMINATE;

-- /***************************************************************************/
-- /*   END OF SAMPLE                                                         */
-- /***************************************************************************/ 
