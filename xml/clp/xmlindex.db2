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
-- SOURCE FILE NAME: xmlindex.db2
--
-- SAMPLE: How to create an index on XML columns in different ways 
--
-- SQL STATEMENTS USED:
--         CREATE INDEX
--         DROP INDEX
--         TERMINATE
--
-- OUTPUT FILE: xmlindex.out (available in the online documentation)
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

-- create TABLE called company
CREATE TABLE company(ID int, docname VARCHAR(20), doc XML); 

-- insert row1 into TABLE
INSERT INTO company values(1, 'doc1', xmlparse 
    (document '<company name="Company1"><emp id="31201" 
      salary="60000" gender="Female" DOB="10-10-80"> 
    <name><first>Laura</first><last>Brown</last></name> 
    <dept id="M25">Finance</dept><!-- good --></emp> 
    </company>'));

-- insert row2 into TABLE
INSERT INTO company values(2, 'doc2',  xmlparse
       (document '<company name="Company2"><emp id="31664"
       salary="60000" gender="Male" DOB="09-12-75"><name>
       <first>Chris</first><last>Murphy</last></name>
       <dept id="M55">Marketing</dept> </emp> <emp id="42366"
       salary="50000" gender="Female" DOB="08-21-70"><name>
       <first>Nicole</first><last>Murphy</last></name> 
       <dept id="K55">Sales</dept></emp></company>'));


-- create index on an attribute
CREATE INDEX empindex1 on company(doc) GENERATE KEY USING
  XMLPATTERN '/company/emp/@*' AS SQL VARCHAR(15) ;

-- example query using above index
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/emp
   [@id='42366'] return $i/name;

-- create index with self or descendent forward axis
CREATE INDEX empindex2 on company(doc)  GENERATE KEY USING
                 XMLPATTERN '//@salary' AS SQL DOUBLE;

-- example query using above index
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/emp
    [@salary > 35000] return <salary> {$i/@salary} </salary>;

-- create index on a text node
CREATE INDEX empindex3 on company(doc) GENERATE KEY USING
          XMLPATTERN '/company/emp/dept/text()' AS SQL VARCHAR(30);
-- example query using above index
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/
    emp[dept/text()='Finance' or dept/text()='Marketing'] return $i/name;


-- create index when 2 paths are qualified by an xml pattern
CREATE INDEX empindex4 on company(doc) GENERATE KEY USING
                  XMLPATTERN '//@id' AS SQL VARCHAR(25);
-- example query using above index
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/
   emp[@id='31201']  return $i/name;
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/emp/
   dept[@id='K55']  return $i/name;

-- create index with namespace
CREATE index empindex5 on company(doc) GENERATE KEY USING
             XMLPATTERN 'declare default element namespace 
             "http://www.mycompany.com/";declare namespace
              m="http://www.mycompanyname.com/";/company/emp/@m:id'
             AS SQL VARCHAR(30);

-- create indexes with same XMLPATTERN but with different data types
CREATE INDEX empindex6 on company(doc)  GENERATE KEY USING
             XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(10);
CREATE INDEX empindex7 on company(doc)  GENERATE KEY USING
             XMLPATTERN '/company/emp/@id' AS SQL DOUBLE;


-- create index to use in joins (Anding) 
CREATE INDEX empindex8 on company(doc) GENERATE KEY USING
          XMLPATTERN '/company/emp/name/last' AS SQL VARCHAR(100);
CREATE INDEX deptindex on company(doc) GENERATE KEY USING
          XMLPATTERN '/company/emp/dept/text()' AS SQL VARCHAR(30);

-- example query using above index
XQuery for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company
   /emp[name/last='Murphy' and dept/text()='Sales']return $i/name/last;

-- create indexes to use in joins ( Anding or Oring )
CREATE INDEX empindex9 on company(doc) GENERATE KEY USING
            XMLPATTERN '/company/emp/@salary' AS SQL DOUBLE;
CREATE INDEX empindex10 on company(doc) GENERATE KEY USING
          XMLPATTERN '/company/emp/dept' AS SQL VARCHAR(25);
CREATE INDEX empindex11 on company(doc) GENERATE KEY USING
         XMLPATTERN '/company/emp/name/last' AS SQL VARCHAR(25);
-- example query which will use all the above 3 index (Anding and Oring)
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/emp[xs:integer(@salary) > 50000 and dept="Finance"]/name[last="Brown"] 
       return $i/last;

-- create index with Date Data type
CREATE INDEX empindex12 on company(doc) GENERATE KEY USING
        XMLPATTERN '/company/emp/@DOB' as SQL DATE;

-- example query which uses above index
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/emp
      [@DOB < '11-11-78'] return $i/name;

-- create index on comment node
CREATE INDEX empindex13 on company(doc) GENERATE KEY USING
               XMLPATTERN '/company//comment()' AS SQL VARCHAR HASHED;
-- example query which uses above query
XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')/company/emp[comment()
        =' good ']return $i/name;

-- drop indexes
DROP index "EMPINDEX1";
DROP index "EMPINDEX2";
DROP index "EMPINDEX3";
DROP index "EMPINDEX4";
DROP index "EMPINDEX5";
DROP index "EMPINDEX6";
DROP index "EMPINDEX7";
DROP index "EMPINDEX8";
DROP index "DEPTINDEX";
drop index "EMPINDEX9";
drop index "EMPINDEX10";
drop index "EMPINDEX11";
DROP index "EMPINDEX12";
DROP index "EMPINDEX13";

-- drop the TABLE
DROP TABLE "COMPANY";


