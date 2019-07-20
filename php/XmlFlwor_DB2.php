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
 ****************************************************************************
 *
 * SOURCE FILE NAME: XmlFlwor_DB2.php
 *
 * SAMPLE: How to use XQuery FLWOR expressions
 *
 * SQL Statements USED:
 *         SELECT
 *
 * SQL/XML FUNCTIONS USED:
 *                xmlcolumn
 *                xmlquery
 *
 * XQuery function used:
 *                data
 *                string
 *
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class Flwor extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo \"
This sample will demonstrate how to use XQuery FLWOR expressions

\";
";

  function __construct($initialize = true)
  {
    parent::__construct($initialize);
    $this->make_Connection();
  }

  // The order_Cust_Details method returns customer information in alphabetical order by customer name
  public function order_Cust_Details()
  {
     $toPrintToScreen = "
----------------------------------------------------------------
Return customer information in alphabetical order by customer name .....
";
    $this->format_Output($toPrintToScreen);
      $query = "
XQUERY
  for
    \$custinfo
      in
      db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
        /customerinfo[addr/@country=\"Canada\"]
  order by
    \$custinfo/name
  return
    \$custinfo
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
  } // order_Cust_Details

  // The conditional_Cust_Details_1 returns information for customers whose customer ID is greater than
  // the cid value passed as an argument
  public function conditional_Cust_Details_1($cid)
  {
     $toPrintToScreen = "
----------------------------------------------------------------
Return information for customers whose customer ID is greater than $cid.....
";
    $this->format_Output($toPrintToScreen);
      $query = "
SELECT
  XMLQUERY('
        for
          \$customer
            in
            \$cust/customerinfo
        where
          (\$customer/@Cid > \$id)
        return
          <customer id=\"{\$customer/@Cid}\">
            {\$customer/name}
            {\$customer/addr}
          </customer>
      ' passing by ref
          {$this->schema}CUSTOMER.INFO AS \"cust\",
          cast( ? as integer) AS \"id\"
    )
  FROM
    {$this->schema}CUSTOMER
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the value for the parameter marker
      $this->format_Output("\nSet the paramter value: $cid");

      db2_bind_param($stmt, 1, "cid", DB2_PARAM_IN);

      if(db2_execute($stmt))
      {
          // retrieve and display the result from the XQUERY statement
          while($a_result = db2_fetch_array($stmt))
          {
            // Prints a formatted version of the xml tree that is returned
            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }

          db2_free_stmt($stmt);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // conditional_Cust_Details_1

  // The conditional_Cust_Details_2 method returns information for customers whose customer ID is greater than
  //  the cid value passed to the function and who dont live in the country
  public function conditional_Cust_Details_2($cid, $country)
  {
     $toPrintToScreen = "
----------------------------------------------------------------
Return information for customers whose customer ID is greater than $cid and
who do not live in country $country .....
";
    $this->format_Output($toPrintToScreen);
      $query = "
SELECT
  XMLQUERY(
      '
        for
          \$customer
            in
            db2-fn:xmlcolumn(\"{$this->schema}CUSTOMER.INFO\")
              /customerinfo
        where
          (xs:integer(\$customer/@Cid) gt \$id)
            and
          (\$customer/addr/@country !=\$c)
        return
          <customer id=\"{fn:string(\$customer/@Cid)}\">
            {\$customer/name}
            <address>
              {\$customer/addr/street}
              {\$customer/addr/city}
            </address>
          </customer>
      ' passing by ref
          cast( ? AS integer) as \"id\",
          cast( ? AS varchar(10)) as \"c\"
    )
  FROM
    SYSIBM.SYSDUMMY1
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the first parameter marker
      $this->format_Output("\nSet the first parameter value : $cid \n");
      db2_bind_param($stmt, 1, "cid");

      // Set the second parameter marker
      $this->format_Output("\nSet the second parameter value: $country \n");
      db2_bind_param($stmt, 2, "country");

      if(db2_execute($stmt))
      {
          // retrieve and display the result from the query
          while($a_result = db2_fetch_array($stmt))
          {
            // Prints a formatted version of the xml tree that is returned
            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }

          db2_free_stmt($stmt);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }

  } // conditional_Cust_Details_2

  // The max_Price_Product function returns the product details with maximun price
  public function max_Price_Product()
  {
     $toPrintToScreen = "
----------------------------------------------------------------
Select the product with maximun price......
";
    $this->format_Output($toPrintToScreen);
      $query = "
XQUERY
  let
    \$prod := for \$product
                in
                db2-fn:xmlcolumn('{$this->schema}PRODUCT.DESCRIPTION')
                  /product/description
  order by
    \$product/price
  return
    \$product
  return
    <product>
      {\$prod[1]/name}
    </product>
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
  } // max_Price_Product

  // The basic_Product function returns the product with basic attribute value true
  // if the price is less then price parameter otherwiese false
  public function basic_Product($price)
  {
     $toPrintToScreen = "
----------------------------------------------------------------
Select the product with basic price $price ........
";
    $this->format_Output($toPrintToScreen);
      $query = "
SELECT
  XMLQUERY(
      '
        for
          \$prod
            in
            db2-fn:xmlcolumn(\"{$this->schema}PRODUCT.DESCRIPTION\")
              /product/description
        return (
            if (\$prod/price < \$price) then
              <product basic = \"true\">
                {fn:data(\$prod/name)}
              </product>
            else
              <product basic = \"false\">
                {fn:data(\$prod/name)}
              </product>)
      ' passing by ref
          cast( ? as float) as \"price\"
    )
  FROM
    SYSIBM.SYSDUMMY1
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the parameter value
      $this->format_Output("\nSet the parameter value: $price \n");
      db2_bind_param($stmt, 1, "price");

      // Execute the query
      if(db2_execute($stmt))
      {
          $this->format_Output("\n");
          // retrieve and display the result from the xquery
          while($a_result = db2_fetch_array($stmt))
          {
            // Prints a formatted version of the xml tree that is returned
            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }
          db2_free_stmt($stmt);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // basic_Product

} // Flwor

$cid = 1002;
$country = "US";
$price = 10.00;

$Run_Sample = new Flwor();

$Run_Sample->order_Cust_Details();

$Run_Sample->conditional_Cust_Details_1($cid);

$cid=1000;
$Run_Sample->conditional_Cust_Details_2($cid, $country);

$Run_Sample->max_Price_Product();

$Run_Sample->basic_Product($price);


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
