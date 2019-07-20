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
-- SOURCE FILE NAME: stock.db2
--    
-- SAMPLE: How to use triggers
--
-- SQL STATEMENTS USED:
--         DROP TABLE
--         CREATE TABLE
--         INSERT
--         CREATE TRIGGER
--         SELECT
--         UPDATE
--         DROP TRIGGER
--
-- OUTPUT FILE: stock.out (available in the online documentation)
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

create table currentquote (symbol char(3) not null,
                           quote  decimal(6,2),
                           status varchar(8));

create table quotehistory (symbol char(3) not null,
                           quote  decimal(6,2),  timestamp timestamp);

insert into currentquote values ('IBM',68.5,null);

CREATE TRIGGER STOCK_STATUS                                    
       NO CASCADE BEFORE UPDATE OF QUOTE ON CURRENTQUOTE       
       REFERENCING NEW AS NEWQUOTE OLD AS OLDQUOTE             
       FOR EACH ROW MODE DB2SQL                                
          SET NEWQUOTE.STATUS =                                
             CASE                                              
                WHEN NEWQUOTE.QUOTE >=                         
                      (SELECT MAX(QUOTE) FROM QUOTEHISTORY     
                       WHERE SYMBOL = NEWQUOTE.SYMBOL              
                       AND YEAR(TIMESTAMP) = YEAR(CURRENT DATE) )  
                   THEN 'High'                                    
                WHEN NEWQUOTE.QUOTE <=                            
                      (SELECT MIN(QUOTE) FROM QUOTEHISTORY        
                       WHERE SYMBOL = NEWQUOTE.SYMBOL             
                       AND YEAR(TIMESTAMP) = YEAR(CURRENT DATE) ) 
                   THEN 'Low'                                     
                WHEN NEWQUOTE.QUOTE > OLDQUOTE.QUOTE              
                   THEN 'Rising'                                  
                WHEN NEWQUOTE.QUOTE < OLDQUOTE.QUOTE              
                   THEN 'Dropping'                                
                WHEN NEWQUOTE.QUOTE = OLDQUOTE.QUOTE              
                   THEN 'Steady'                                  
             END;                                                 
      

CREATE TRIGGER RECORD_HISTORY                            
       AFTER UPDATE OF QUOTE ON CURRENTQUOTE             
       REFERENCING NEW AS NEWQUOTE                       
       FOR EACH ROW MODE DB2SQL                          
          INSERT INTO QUOTEHISTORY                                  
          VALUES (NEWQUOTE.SYMBOL,NEWQUOTE.QUOTE,CURRENT TIMESTAMP);

update currentquote set quote =68.25 where symbol='IBM';

select * from currentquote;

update currentquote set quote =68.75 where symbol='IBM';

select * from currentquote;

update currentquote set quote =68.5 where symbol='IBM';

select * from currentquote;

update currentquote set quote =68.5 where symbol='IBM';

select * from currentquote;

update currentquote set quote =68.62 where symbol='IBM';

select * from currentquote;

update currentquote set quote =68 where symbol='IBM';

select * from currentquote;

select * from quotehistory;

drop trigger record_history;

drop trigger stock_status;

drop table currentquote;

drop table quotehistory;

