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
-- SOURCE FILE NAME: xmlupdel.db2
--
-- SAMPLE: This sample shows how to update and delete XML documents from
--         the table.
--
-- SQL STATEMENTS USED:
--           SELECT
--	     INSERT 
--	     UPDATE 
--	     DELETE
--
-- XML FUNTIONS USED:
--              XMLPARSE
--              XMLSERIALIZE
--              XMLVALIDATE
--              XMLCAST
--              XMLELEMENT
--              XMLATTRIBUTES
--
-- OUTPUT FILE: xmlupdel.out (available in the online documentation)
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

-- connect to sample
CONNECT TO sample;

-- create table 'oldcustomer' having XML column
CREATE TABLE oldcustomer(ocid integer, 
                         firstname varchar(15), 
                         lastname varchar(15), 
                         addr varchar(300), 
                         information XML);

-- insert rows into the table 'oldcustomer'.

INSERT INTO oldcustomer 
    VALUES(1009, 'Rahul','kumar', '<customerinfo Cid = "1009"><name>Rahul</name><addr country 
    = "Canada"><street>25</street><city>Markham</city><prov-state>
    Ontario</prov-state><pcode-zip>N9C-3T6</pcode-zip></addr><phone
    type = "work">905-555-7258</phone></customerinfo>', XMLPARSE
    (document '<oldcustomerinfo ocid = "1009"><address country = 
    "Canada"><street>25 Westend</street><city>Markham</city><state>
    Ontario</state></address></oldcustomerinfo>'preserve whitespace));

-- insert a row into  table 'customer'
INSERT INTO customer(cid, info)
    VALUES(1008, XMLPARSE(document '<customerinfo Cid = "1008"><name>
            divya</name></customerinfo>' preserve whitespace));

---------------------------------------------------------------------------
-- a simple update using 'constant string(varchar)'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer
    WHERE cid = 1008;

UPDATE customer
    SET info = XMLPARSE(document'<newcustomerinfo><name>rohit<street>
    park street</street><city>delhi</city></name>  	
    </newcustomerinfo>'preserve whitespace)
    WHERE cid = 1008;

-- display the contents of the 'customer' table (after updation)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1008;

---------------------------------------------------------------------------

-- update where source is from 'another XML column'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer
    WHERE cid = 1008;

-- display the contents of the 'oldcustomer' table
SELECT ocid, XMLSERIALIZE(information as varchar(600))
    FROM oldcustomer 
    WHERE ocid = 1009;

UPDATE customer
  SET info = (SELECT information
                  FROM oldcustomer p
                  WHERE p.ocid = 1009)
                  WHERE cid=1008;

-- display the contents of the 'customer' table (after updation)
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer
    WHERE cid = 1008;

--------------------------------------------------------------------------
-- update where source is from 'another string column'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer 
    WHERE cid = 1008;

-- display the contents of the 'oldcustomer' table
SELECT addr
    FROM oldcustomer 
    WHERE ocid = 1009;

UPDATE customer
  SET info = (SELECT XMLPARSE(document addr preserve whitespace)
                    FROM oldcustomer p
                    WHERE p.ocid = 1009)
                    WHERE cid = 1008;

-- display the contents of the 'customer' table (after updation)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1008;

--------------------------------------------------------------------------
-- update with validation where source is 'typed of varchar'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer 
    WHERE cid = 1008;

-- display the contents of the 'oldcustomer' table
SELECT addr
    FROM oldcustomer
    WHERE ocid = 1009;

UPDATE customer
  SET info = (SELECT XMLVALIDATE(XMLPARSE(document addr preserve whitespace)
             according to XMLSCHEMA ID customer)
  		  FROM oldcustomer p 
 		  WHERE p.ocid = 1009)
                  WHERE cid = 1008;

-- display the contents of the 'customer' table (after updation)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1008;

---------------------------------------------------------------------------
-- delete row containing 'XML data'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1008;

DELETE FROM customer
   WHERE cid = 1008;

-- display the contents of the 'customer' table (after deletion)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer
    WHERE cid = 1008;

-- cleanup
DROP TABLE oldcustomer;
