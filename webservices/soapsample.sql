----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 1995, 2002        
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: soapsample.sql
--    
-- SAMPLE: How to define and invoke DB2 Web Service functions.
--
-- SQL STATEMENTS USED:
--         CREATE FUNCTION
--         VALUES
--         SELECT
--
-- For more information about the command line processor (CLP) scripts, 
-- see the README file.
--
-- For more information about SQL, see the "SQL Reference".
--
-- For the latest information on programming, compiling, and running DB2 
-- applications, refer to the DB2 application development website at 
--     http://www.software.ibm.com/data/db2/udb/ad
--
-- List of Examples (for DB2 Version UDB Version 8)
-- * getQuote        - retrieve 20 minute delayed stock quote
-- * getRate         - returns the exchange rate between any two currencies 
--
-- Due to the nature of these web services being changed, we cannot guarantee 
-- them working all the time. 

----------------------------------------------------------------------------

-- ***************************************************************************
--
-- getQuote: for company name retrieve stock quote.
--
-- ***************************************************************************

-- for DB2 UDB Version 8.2 using SQL/XML: 

VALUES substr(DB2XML.SOAPHTTPV ('http://64.124.140.30:9090/soap', '',
   XML2CLOB(
      XMLELEMENT(NAME "nrs:getQuote", 
         XMLNAMESPACES('urn:xmethods-delayed-quotes' as "nrs", 
                       'http://schemas.xmlsoap.org/soap/encoding/' AS "SOAP-ENV_encodingStyle"),
			XMLELEMENT(NAME "symbol", 'IBM')))), 1, 200);


-- Create a SOAP UDF

DROP FUNCTION getQuote;

CREATE FUNCTION GetQuote (symbol VARCHAR(5))
    RETURNS VARCHAR(40)
  LANGUAGE SQL CONTAINS SQL
  EXTERNAL ACTION NOT DETERMINISTIC
  RETURN
    WITH 

--1. Perform type conversions and prepare SQL input parameters for SOAP envelope

         soap_input (in)
              AS 
           (VALUES VARCHAR(XML2CLOB(
             XMLELEMENT(NAME "ns:getQuote", 
                 XMLNAMESPACES('urn:xmethods-delayed-quotes' as "ns"),
		 XMLELEMENT(NAME "symbol", symbol))))),

--2. Submit SOAP request with input parameter and receive SOAP response

         soap_output (out) 
              AS
            (VALUES DB2XML.SOAPHTTPV ('http://64.124.140.30:9090/soap','',
                             (SELECT in FROM soap_input)))

--3. Shred SOAP response and perform type conversions to get SQL output parameters

         SELECT SUBSTR (out,
                        POSSTR(out,'float">')+7,
                        POSSTR(out,'</') - posstr(out,'float">') -7)
         FROM soap_output;

DROP TABLE COMPANY;
CREATE TABLE COMPANY(name VARCHAR(40), stock_symbol VARCHAR(5));
INSERT INTO COMPANY 
    VALUES ('International Business Machines', 'IBM'), 
           ('MOTOROLA', 'MOT'),
           ('ORACLE', 'ORCL'), 
           ('YAHOO INC', 'YHOO');


SELECT name, stock_symbol,GetQuote(stock_symbol) AS stock_quote
FROM COMPANY where stock_symbol='IBM';


-- ***************************************************************************
--
-- getRate        - returns the exchange rate between any two currencies 
-- 
-- ***************************************************************************


VALUES substr(DB2XML.SOAPHTTPV ('http://services.xmethods.net:80/soap', '', 
    XML2CLOB( XMLELEMENT(NAME "ns:getRate", 
                  XMLNAMESPACES('urn:xmethods-CurrencyExchange' as "ns"), 
                XMLELEMENT(NAME "country1", 'united states'), 
                XMLELEMENT(NAME "country2", 'korea')))), 1, 160); 

-- Create SOAP UDF

DROP FUNCTION getrate;

CREATE FUNCTION GetRate (from VARCHAR(32), to VARCHAR(32))
  RETURNS VARCHAR(40)
  LANGUAGE SQL READS SQL DATA
  EXTERNAL ACTION NOT DETERMINISTIC
  RETURN
    WITH 

--1. Perform type conversions and prepare SQL input parameters for SOAP envelope
      soap_input (in)
           AS 
         (VALUES VARCHAR(XML2CLOB(
	    XMLELEMENT(NAME "ns:getRate", XMLNAMESPACES('urn:xmethods-CurrencyExchange' as "ns"),
		XMLELEMENT(NAME "country1", from),
		XMLELEMENT(NAME "country2", to))))),

--2. Submit SOAP request with input parameter and receive SOAP response

      soap_output (out) 
              AS
     (VALUES DB2XML.SOAPHTTPV('http://services.xmethods.net:80/soap','',
                (SELECT in FROM soap_input)))


--3. Shred SOAP response and perform type conversions to get SQL output parameters

    SELECT SUBSTR (out,
			POSSTR(out,'float">')+7,
			POSSTR(out,'</') - posstr(out,'float">') -7)
    FROM soap_output;


VALUES GetRate('united states', 'korea');


