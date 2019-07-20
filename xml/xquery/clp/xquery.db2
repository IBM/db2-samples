---------------------------------------------------------------------------
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
-- SOURCE FILE NAME: xquery.db2
--
-- SAMPLE: How to run a nested XQuery and shows how to pass parameters to
--         sqlquery function. 
--
-- SQL/XML FUNCTIONS USED
--          xmlcolumn
--          sqlquery
--
-- XQUERY FUNCTIONS/EXPRESSIONS USED
--          distinct-values
--          concat
--          upper-case
--          flwor expression
--          conditional expression
--          arithmatic expression
--
-- SAMPLE EXECUTION:
-- Run the samples with following command
--    db2 -td! -vf xquery.db2
--
-- OUTPUT FILE: xquery.out (available in the online documentation)
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

-- Connect to sample database
CONNECT TO SAMPLE!

-- Find out all the purchaseorders city wise
XQUERY for $city in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo/addr/city)
       order by $city
              return
                <city name='{$city}'>
              {
                  for  $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[addr/city=$city]
                  let $po:=db2-fn:sqlquery("SELECT XMLELEMENT( NAME ""pos"",
                                               (XMLCONCAT( XMLELEMENT(NAME ""custid"", c.custid),
                                                           XMLELEMENT(NAME ""order"", c.porder)
                                                         ) ))
                                    FROM purchaseorder AS c")
          let $id:=$cust/@Cid,
              $order:=$po/pos[custid=$id]/order
          order by $cust/@Cid
          return
          <customer id='{$id}'>
           {$cust/name}
           {$cust/addr}
           {$order}
          </customer>}
         </city>!

-- In Viper2 the above query can be written as follows
XQUERY  for $city in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO') /customerinfo/addr/city) 
        order by $city
           return 
             <city name='{$city}'> 
           { 
              for  $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo [addr/city=$city]  
              let $po:=db2-fn:sqlquery("SELECT porder FROM PURCHASEORDER WHERE custid=parameter(1)",$cust/@Cid), 
               $order:=$po/order
              order by $cust/@Cid
              return 
                <customer id = '{$cust/@Cid}'>
                  {$cust/name} 
                  {$cust/Addr} 
                  {$order}
                </customer>}
             </city>!

-- Find out all the customer product wise
XQUERY let $po:=db2-fn:sqlquery("SELECT XMLELEMENT( NAME ""pos"", 
                                                        ( XMLCONCAT( XMLELEMENT(NAME ""custid"", c.custid),
                                                                     XMLELEMENT(NAME ""order"", c.porder)
                                                        ) ))
                                      FROM purchaseorder AS c" )
                   for $partid in fn:distinct-values(db2-fn:xmlcolumn('PURCHASEORDER.PORDER')/PurchaseOrder/item/partid)
                   order by $partid
                     return
                     <Product name='{$partid}'>
                      <Customers>
                        {
                          for  $id in fn:distinct-values($po[order/PurchaseOrder/item/partid=$partid]/custid)
                          let  $order:=<quantity>
                          {fn:sum($po[custid=$id]/order/PurchaseOrder/item[partid=$partid]/quantity)}
                          </quantity>,
                        $cust:=db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[@Cid=$id]
                      order by $id
                      return
                      <customer id='{$id}'>
                        {$order}
                        {$cust}
                      </customer>
                      }
                   </Customers>
                 </Product>!


-- Find out all the purchaseorders province wise, then city wise and then street wise.
XQUERY let $po:=db2-fn:sqlquery("SELECT XMLELEMENT( NAME ""pos"",
                                          ( XMLCONCAT( XMLELEMENT(NAME ""custid"", c.custid),
                                          XMLELEMENT(NAME ""order"", c.porder)
                                                       ) ))
                                            FROM PURCHASEORDER as c ORDER BY poid"),
        $addr:=db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo/addr
        for $prov in distinct-values($addr/prov-state)
        return
        <province name='{$prov}'>
        {
          for $city in fn:distinct-values($addr[prov-state=$prov]/city)
          order by $city
          return
          <city name='{$city}'>
          {
            for $s in fn:distinct-values($addr/street) where $addr/city=$city
            order by $s
            return
            <street name='{$s}'>
            {
              for $info in $addr[prov-state=$prov and city=$city and street=$s]/..
              order by $info/@Cid
              return
              <customer id='{$info/@Cid}'>
              {$info/name}
              {
                let $id:=$info/@Cid, $order:=$po[custid=$id]/order
                return $order
              }
             </customer>
            }
           </street>
          }
           </city>
        }
        </province>!


-- Combine XML data from customer.info and product.description to for the customer id 1000.
XQUERY <PurchaseOrder>
                    {
                         for $ns1_customerinfo0 in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo
                         where ($ns1_customerinfo0/@Cid=1001)
                         return
                         <customer customerid='{ fn:string( $ns1_customerinfo0/@Cid)}'>
                         {$ns1_customerinfo0/name}
                             <address>
                               {$ns1_customerinfo0/addr/street}
                               {$ns1_customerinfo0/addr/city}
                               {
                                  if($ns1_customerinfo0/addr/@country="US")
                                  then
                                  $ns1_customerinfo0/addr/prov-state
                                   else()
                               }
                                {
                    fn:concat ($ns1_customerinfo0/addr/pcode-zip/text(),",",fn:upper-case($ns1_customerinfo0/addr/@country
))}
                            </address>
                           </customer>
                         }
                         {
                          for $ns2_product0 in db2-fn:xmlcolumn('PRODUCT.DESCRIPTION')/product
                          where ($ns2_product0/@pid="100-100-01")
                          return
                          $ns2_product0
                      }
                    </PurchaseOrder>!

-- Reset the connection
CONNECT RESET!

