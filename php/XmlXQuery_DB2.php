<?php
/***************************************************************************
 * (c) Copyright IBM Corp. 2007 All rights reserved.
 *
 * The following sample of source code ("Sample") is owned by International
 * Business Machines Corporation or one of its subsidiaries ("IBM") and is
 * copyrighted and licensed, not sold. You may use, copy, modify, and
 * distribute the Sample in any form without payment to IBM, for the purpose
 * of assisting you in the development of your applications.
 *
 * The Sample code is provided to you on an "AS IS" basis, without warranty
 * of any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS
 * OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions
 * do not allow for the exclusion or limitation of implied warranties, so the
 * above limitations or exclusions may not apply to you. IBM shall not be
 * liable for any damages you suffer as a result of using, copying, modifying
 * or distributing the Sample, even if IBM has been advised of the
 * possibility of such damages.
 *
 *****************************************************************************
 *
 * SOURCE FILE NAME: XmlXQuery_DB2.php
 *
 * SAMPLE:
 * How to run an nested XQuery XQUERY EXPRESSION USED FLWOR Expression
 *
 * Required Database driver: ibm_db2
 *
 * Special run instructions: NONE
 *
 * Other Notes: NONE
 *
 ***************************************************************************/
require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XQuery extends DB2_Connection
{
    public $SAMPLE_HEADER =
"
echo \"
This sample will demonstrate how to run an nested XQuery XQUERY EXPRESSION USED FLWOR Expression
\";
";

    function __construct($initialize = true)
    {
        parent::__construct($initialize);
        $this->make_Connection();
    }

  // The PO_Order_By_City method returns the purchaseorder city wise
  public function PO_Order_By_City()
  {
     $toPrintToScreen = "
-------------------------------------------------------------
RESTRUCTURE THE PURCHASEORDERS ACCORDING TO THE CITY....
";
    $this->format_Output($toPrintToScreen);
      $query="
XQUERY
  for
    \$city in fn:distinct-values(
                  db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
                    /customerinfo/addr/city
                )
  return
    <city name='{\$city}'>{
        for
          \$cust in db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
            /customerinfo[addr/city=\$city]
        let
          \$po := db2-fn:sqlquery(
                      \"
                        SELECT
                            XMLELEMENT(
                                NAME \"\"pos\"\",
                                (
                                  XMLCONCAT(
                                      XMLELEMENT(
                                          NAME \"\"custid\"\",
                                          c.custid
                                        ),
                                      XMLELEMENT(
                                          NAME \"\"order\"\",
                                          c.porder
                                        )
                                    )
                                )
                              )
                          FROM
                            {$this->schema}PURCHASEORDER AS c
                        \"
                      )
        let
          \$id := \$cust/@Cid,
          \$order :=\$po [custid=\$id]/order
        return
          <customer id='{\$id}'>
            {\$cust/name}
            {\$cust/Addr}
            {\$order}
          </customer>
      }
    </city>
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $result = db2_exec($this->dbconn, $query);

      if($result)
      {
        $this->format_Output("\n");

        // retrieve and display the result from the xquery
        while($a_result = db2_fetch_both($result))
        {
          // Prints a formatted version of the xml tree that is returned
          $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
        }
        db2_free_result($result);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // PO_Order_By_City

  // This customer_Order_By_Product function returns the  purchaseorders product wise
  public function customer_Order_By_Product()
  {
    $toPrintToScreen = "
-------------------------------------------------------------
RESTRUCTURE THE PURCHASEORDER ACCORDING TO THE PRODUCT.....
";
    $this->format_Output($toPrintToScreen);
      $query="
XQUERY
  for
    \$city in fn:distinct-values(
                  db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
                    /customerinfo/addr/city
                )
  return
    <city name='{\$city}'>{
        for
          \$cust in db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
            /customerinfo[addr/city=\$city]
        let
          \$po := db2-fn:sqlquery(
                      \"
                        SELECT
                            XMLELEMENT(
                                NAME \"\"pos\"\",
                                (
                                  XMLCONCAT(
                                      XMLELEMENT(
                                          NAME \"\"custid\"\",
                                          c.custid
                                      ),
                                      XMLELEMENT(
                                          NAME \"\"order\"\",
                                          c.porder
                                        )
                                    )
                                )
                              )
                          FROM
                            {$this->schema}PURCHASEORDER AS c
                      \"
                    )
        let
          \$id := \$cust/@Cid,
          \$order := \$po[custid=\$id]/order
        return
          <customer id='{\$id}'>
            {\$cust/name}
            {\$cust/Addr}
            {\$order}
          </customer>
      }
    </city>
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $result = db2_exec($this->dbconn, $query);

      $this->format_Output("\n");
      if($result)
      {
          // retrieve and display the result from the xquery
          while($a_result = db2_fetch_array($result))
          {
            // Prints a formatted version of the xml tree that is returned
            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }
          db2_free_result($result);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }

  } // customer_Order_By_Product


  // This PO_Order_By_Prov_City_Street function returns the purchaseorder province, city and stree wise
  public function PO_Order_By_Prov_City_Street()
  {
    $toPrintToScreen = "
-------------------------------------------------------------
RESTRUCTURE THE PURCHASEORDER DATA ACCORDING TO PROVIENCE, CITY AND STREET..
";
    $this->format_Output($toPrintToScreen);
      $query="
XQUERY
  let
    \$po := db2-fn:sqlquery(
                \"
                  SELECT
                      XMLELEMENT(
                          NAME \"\"pos\"\",
                          (
                            XMLCONCAT(
                                XMLELEMENT(
                                    NAME \"\"custid\"\",
                                    c.custid
                                ),
                                XMLELEMENT(
                                    NAME \"\"order\"\",
                                    c.porder
                                  )
                              )
                          )
                        )
                    FROM
                      {$this->schema}PURCHASEORDER as c
                \"
              ),
    \$addr:=db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
      /customerinfo/addr
  for
    \$prov in distinct-values(\$addr/prov-state)
  return
    <province name='{\$prov}'>{
        for
          \$city in fn:distinct-values(\$addr[prov-state=\$prov]/city)
        return
          <city name='{\$city}'>{
              for
                \$s in fn:distinct-values(\$addr/street)
              where
                \$addr/city=\$city
              return
                <street name='{\$s}'>{
                    for
                      \$info
                        in
                        \$addr[prov-state=\$prov
                          and
                        city=\$city
                          and
                        street=\$s]/..
                    return
                      <customer id='{\$info/@Cid}'>{
                          \$info/name
                        }
                        {
                          let
                            \$id := \$info/@Cid,
                            \$order := \$po[custid=\$id]/order
                          return \$order
                        }
                      </customer>
                  }
                </street>
            }
          </city>
      }
    </province>
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);


      // Execute the query
      $result = db2_exec($this->dbconn, $query);

      $this->format_Output("\n");
      if($result !== false)
      {
          // retrieve and display the result from the xquery
          while($a_result = db2_fetch_array($result))
          {
            // Prints a formatted version of the xml tree that is returned
            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }
          db2_free_result($result);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  }

  // The customer_PO function creates the purchaseorder XML document
  public function customer_PO()
  {
    $toPrintToScreen = "
-------------------------------------------------------------
COMBINE THE DATA FROM PRODUCT AND CUSTOMER TABLE TO CREATE A PURCHASEORDER..
";
    $this->format_Output($toPrintToScreen);
      $query="
XQUERY
  <PurchaseOrder>{
      for
        \$ns1_customerinfo0
          in
          db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
            /customerinfo
      where
        (\$ns1_customerinfo0/@Cid=1001)
      return
        <customer customerid='{ fn:string( \$ns1_customerinfo0/@Cid)}'>{
            \$ns1_customerinfo0/name
          }
          <address>{
          	  \$ns1_customerinfo0/addr/street
            }
            {
            	 \$ns1_customerinfo0/addr/city
            }
            {
              if(\$ns1_customerinfo0/addr/@country=\"US\") then
                \$ns1_customerinfo0/addr/prov-state
              else(
                )
            }
            {
              fn:concat(
                  \$ns1_customerinfo0/addr/pcode-zip/text(),
                  \",\",
                  fn:upper-case(\$ns1_customerinfo0/addr/@country)
                )
            }
          </address>
        </customer>
    }
    {
      for
        \$ns2_product0 in db2-fn:xmlcolumn(
                              '
                                {$this->schema}PRODUCT.DESCRIPTION
                              '
                            )/product
      where
        (\$ns2_product0/@pid=\"100-100-01\")
      return
        \$ns2_product0
    }
  </PurchaseOrder>
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);


      // Execute the query
      $result = db2_exec($this->dbconn, $query);

      $this->format_Output("\n");
      if($result !== false)
      {
          // retrieve and display the result from the xquery
          while($a_result = db2_fetch_array($result))
          {
            // Prints a formatted version of the xml tree that is returned
            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }
          db2_free_result($result);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  }
} // XQuery

$Run_Sample = new XQuery();

$Run_Sample->PO_Order_By_City();

$Run_Sample->customer_Order_By_Product();

$Run_Sample-> PO_Order_By_Prov_City_Street();

$Run_Sample->customer_PO();

 /*******************************************************
  * We rollback at the end of all samples to ensure that
  * there are not locks on any tables. The sample as is
  * delivered does not need this. The author of these
  * samples expects that you the read of this comment
  * will play and learn from them and the reader may
  * forget commit or rollback their action as the
  * author has in the past.
  * As such this is here:
  ******************************************************/
$Run_Sample->rollback();

// Close the database connection
$Run_Sample->close_Connection();

?>
