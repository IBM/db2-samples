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
-- SOURCE FILE NAME: xmlinsert.db2
--
-- SAMPLE: This sample shows how to insert XML documents into a column of 
--         XML datatype of a table
--
-- SQL STATEMENTS USED:
--           SELECT
--	     INSERT 
--           DELETE
--	     DROP
--
--              XMLPARSE
--              XMLSERIALIZE
--              XMLVALIDATE
--              XMLCAST
--              XMLELEMENT
--              XMLATTRIBUTES
--
-- OUTPUT FILE: xmlinsert.out (available in the online documentation)
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

-- create table 'oldcustomer' having an XML column
CREATE TABLE oldcustomer(ocid integer, firstname varchar(15), lastname
    varchar(15), addr varchar(300), information XML);

-- insert XML values into the table 'oldcustomer' table.

-- insert a row into table
INSERT INTO oldcustomer 
  VALUES(1007, 'Raghu', 'nandan', '<addr country="india"><state>
  karnataka<district>bangalore</district></state></addr>',
  XMLPARSE(document'<oldcustomerinfo ocid = "1007"><address 
  country = "india"><street>24 gulmarg</street><city>bangalore
  </city><state>karnataka</state></address></oldcustomerinfo>'
  preserve whitespace));

-- insert a row into table
INSERT INTO oldcustomer
  VALUES(1008, 'Rama', 'murthy', '<addr country = "india"><state>
  karnataka<district>belgaum</district></state></addr>',
  XMLPARSE(document'<oldcustomerinfo ocid = "1008"><address 
  country = "india"><street>12 gandhimarg</street><city>
  belgaum</city><state>karnataka</state> </address>
  </oldcustomerinfo>'preserve whitespace));

-- insert a row into table
INSERT INTO oldcustomer 
  VALUES(1009, 'Rahul', 'kumar', '<customerinfo Cid = "1009"><name>Rahul</name><addr
  country = "Canada"><street>25</street><city>Markham</city>
  <prov-state>Ontario</prov-state><pcode-zip>N9C-3T6	
  </pcode-zip></addr><phone type="work">905-555-7258
  </phone></customerinfo>',XMLPARSE(document '<oldcustomerinfo 
  ocid = "1009"><address country = "Canada"><street>25 Westend
  </street><city>Markham</city><state>Ontario</state> 
  </address></oldcustomerinfo>'preserve whitespace));

-- insert a row into table
INSERT INTO oldcustomer
  VALUES(1010, 'Sweta', 'Priya', '<addr country = "india">
  <state>karnataka<district>kolar</district></state></addr>',
  XMLPARSE(document'<oldcustomerinfo ocid = "1010"><address 
  country = "india"><street>56 hillview</street>
  <city>kolar</city><state>karnataka</state> </address>
  </oldcustomerinfo>'preserve whitespace));

---------------------------------------------------------------------------
-- a simple INSERT

-- display the current contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer 
    WHERE cid = 1006;

INSERT INTO customer(cid, info)
    VALUES(1006, XMLPARSE(document '<customerinfo Cid = "1006"><name>
            divya</name></customerinfo>' preserve whitespace));

-- display the results after inserting a row 
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1006;

----------------------------------------------------------------------------
-- insert where the source is 'from another XML column'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer
    WHERE cid = 1007;

-- display the contents of the 'oldcustomer' table
SELECT ocid, XMLSERIALIZE(information as varchar(600))
     FROM oldcustomer 
     WHERE ocid = 1007;

INSERT INTO customer(cid, info)
    SELECT ocid, information
       FROM oldcustomer p
       WHERE p.ocid = 1007;

-- display the contents after insertion
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer
    WHERE cid = 1007;

---------------------------------------------------------------------------
-- insert where the source is 'from another string column'

-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer 
    WHERE cid = 1008;

-- display the contents of the 'oldcustomer' table
SELECT ocid, XMLSERIALIZE(information as varchar(600))
    FROM oldcustomer
    WHERE ocid = 1008;

INSERT INTO customer(cid, info)
     SELECT ocid, XMLPARSE(document addr preserve whitespace)
         FROM oldcustomer p
         WHERE p.ocid = 1008;

-- display the contents of the 'customer' table (after insertion)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer
    WHERE cid = 1008;

----------------------------------------------------------------------------
-- insert with validation where source is of type varchar


-- display the contents of the 'customer' table
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer 
    WHERE cid = 1009;

-- display the contents of the 'oldcustomer' table
SELECT ocid, XMLSERIALIZE(information as varchar(600))
    FROM oldcustomer
    WHERE ocid = 1009;

INSERT INTO customer(cid, info)
    SELECT ocid, XMLVALIDATE(XMLPARSE(document addr preserve whitespace)
    according to XMLSCHEMA id customer)
        FROM oldcustomer p 
        WHERE p.ocid = 1009;

-- display the contents of the 'customer' table (after insertion)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1009;

---------------------------------------------------------------------------
-- insert where source is 'a XML funtion'

-- display the contents of the 'customer' table
SELECT cid,XMLSERIALIZE(info as varchar(600))
    FROM customer 
    WHERE cid = 1010;

-- display the contents of the 'oldcustomer' table
SELECT ocid,XMLSERIALIZE(information as varchar(600))
    FROM oldcustomer 
    WHERE ocid = 1010;

INSERT INTO customer(cid, info)
    SELECT ocid, XMLPARSE(document XMLSERIALIZE(content
    XMLELEMENT(NAME"oldCustomer", XMLATTRIBUTES(s.ocid,
    s.firstname||' '||s.lastname AS "name"))
    as varchar(200))  strip whitespace)
    FROM oldcustomer s WHERE s.ocid = 1010 ;

-- display the contents of the 'customer' table (after insertion)
SELECT cid, XMLSERIALIZE(info as varchar(600)) 
    FROM customer 
    WHERE cid = 1010;

----------------------------------------------------------------------------

-- insert where the source is not as per schema
INSERT INTO customer(cid, info)
    VALUES(1011, '<name>arjun<name>');

-- insertion will fail in this case

---------------------------------------------------------------------------

-- insert where source is typecast to XML
INSERT INTO customer(cid, info) VALUES(1031, XMLCAST(XMLPARSE(document
    '<oldcustomerinfo ocid = "1031"><address country = "india">
    <street>56 hillview</street><city>kolar</city><state>karnataka
    </state> </address></oldcustomerinfo>' preserve whitespace)  as XML));

-- display the contents of the 'customer' table (after insertion)
SELECT cid, XMLSERIALIZE(info as varchar(600))
    FROM customer
    WHERE cid = 1031;

---------------------------------------------------------------------------

-- cleanup
DROP TABLE oldcustomer;

DELETE FROM customer WHERE cid >= 1006;
