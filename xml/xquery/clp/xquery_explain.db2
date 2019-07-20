
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
-- SOURCE FILE NAME: xquery_explain.db2
--
-- SAMPLE: How to get the explain information of a SQL/XML or XQuery statement 
--
-- SAMPLE EXECUTION:
-- Run the samples with following command
--    db2 -td@ -vf xquery_explain.db2
--
-- PREREQUISITE : Explain tables should be created before running this sample
--                Use the following command to create the Explain Table
--           
--          db2 -tf EXPLAIN.DDL
-- EXPLAIN.DDL file can be found in sqllib/misc directory
--
-- OUTPUT FILE: xquery_explain.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using XQUERY statements, see the XQUERY Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- connect to the database
CONNECT TO SAMPLE@

-- set CURRENT EXPLAIN MODE to EXPLAIN. 
SET CURRENT EXPLAIN MODE = EXPLAIN@

-- run a dynamic statement. as CURRENT EXPLAIN MODE is set to EXPLAIN, 
-- query will not run only the explain information will be captured
XQUERY for $custinfo in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[addr/@country="Canada"]
       order by $custinfo/name
       return $custinfo/name @

-- format the explain tables, explain plan will be found in file explain_result1
!db2exfmt -d sample -e newton -f O -g OTI -n %% -s %% -o explain_result1 -w -1 -# 0@

-- set CURRENT EXPLAIN MODE to YES
SET CURRENT EXPLAIN MODE = YES@

-- run a dynamic statement. as CURRENT EXPLAIN MODE is set to YES,
-- query will be executed and the explain information will be captured
XQUERY let $prod_price := db2-fn:xmlcolumn('PRODUCT.DESCRIPTION') 
       /product[fn:starts-with(@pid,"100")]/description/price
       return avg($prod_price)@

-- format the explain tables, explain plan will be found in file explain_result2
!db2exfmt -d sample -e newton -f O -g OTI -n %% -s %% -o explain_result2 -w -1 -# 0@

-- explain a SQL/XML statement using EXPLAIN PLAN statement
EXPLAIN PLAN SELECTION FOR SELECT XMLQUERY
      ('$p/PurchaseOrder/item[1]' 
       PASSING p.porder AS "p")
      FROM purchaseorder AS p, customer AS c
      WHERE XMLEXISTS('$custinfo/customerinfo[name="Robert Shoemaker" and @Cid = $cid]'
                     PASSING c.info AS "custinfo", p.custid AS "cid")@ 

-- format the explain tables, explain plan will be found in file explain_result3
!db2exfmt -d sample -e newton -f O -g OTI -n %% -s %% -o explain_result3 -w -1 -# 0@

-- explain an SQL/XML statement
EXPLAIN PLAN SELECTION FOR WITH count_table AS ( SELECT count(poid) AS c,custid
                FROM purchaseorder,customer
                WHERE cid=custid GROUP BY custid )
             SELECT c,custid, XMLQUERY('$s/customerinfo[@Cid=$id]/name'
                                PASSING customer.info AS "s", count_table.custid AS "id")
     FROM customer,count_table
     WHERE custid=cid ORDER BY c@

-- format the explain tables, explain plan will be found in file explain_result4
!db2exfmt -d sample -e newton -f O -g OTI -n %% -s %% -o explain_result4 -w -1 -# 0@

-- explain a simple XQuery statement
EXPLAIN PLAN SELECTION FOR XQUERY 'let $prod_price := db2-fn:xmlcolumn("PRODUCT.DESCRIPTION")
                               /product[fn:starts-with(@pid,"100")]/description/price
                                return avg($prod_price)'@

-- format the explain tables, explain plan will be found in file explain_result5
!db2exfmt -d sample -e newton -f O -g OTI -n %% -s %% -o explain_result5 -w -1 -# 0@

-- explain an XQuery statement with FLWOR expression
EXPLAIN PLAN SELECTION FOR XQUERY 'for $customer in db2-fn:xmlcolumn("CUSTOMER.INFO")/customerinfo
       where ($customer/@Cid gt 1002) and ($customer/addr/@country !="US")
       return
      <customer customerid="{fn:string($customer/@Cid)}">
        {$customer/name}
        <address>
          {$customer/addr/street}
          {$customer/addr/city}
        </address>
      </customer>'@

-- format the explain tables, explain plan will be found in file explain_result6
!db2exfmt -d sample -e newton -f O -g OTI -n %% -s %% -o explain_result6 -w -1 -# 0@


CONNECT RESET@
 
