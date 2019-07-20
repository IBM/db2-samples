-- This file contains a set of SQL statements which operate on 
-- the Customer information which is of XML data type.

-- Pure SQL query that lists the information about Customers whose ids are in 1000,1002 and 2000
SELECT Info FROM Customer WHERE Cid IN(1000,1002,2000);

-- SQL Query with XPath that lists the information about a customer whose id is 1000
SELECT Info FROM Customer WHERE XMLEXISTS('$info/*:customerinfo[@Cid = 1000]' PASSING BY REF Customer.Info AS "info");

-- XQUERY statement that lists the cities of the customers from Info column
XQUERY for $col in db2-fn:xmlcolumn("CUSTOMER.INFO") return $col//*:city;

-- Pure SQL mixed with XQUERY statement that lists work phone number of customers from Info column
SELECT XMLSERIALIZE( content xmlquery('declare namespace po = "http://podemo.org"; for $i in $info/*:customerinfo for $p in $i/*:phone where $p/@type = "work" return <contact>{$i/*:name}{$p}</contact>'PASSING BY REF Info AS "info" RETURNING SEQUENCE) AS varchar(1000)) FROM Customer;


