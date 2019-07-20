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
 * **************************************************************************
 *
 * SOURCE FILE NAME: XmlXPath_DB2.php
 *
 * SAMPLE: How to run Queries with a simple path expression
 *
 * EXTERNAL DEPENDECIES: NULL
 *
 * SQL STATEMENTS USED:
 *        SELECT
 *
 * SQL/XML STATEMENTS USED:
 *           xmlcolumn
 *
 * XQuery FUNCTIONS USED:
 *               distinct-values
 *               starts-with
 *               avg
 *               count
 *
 *
 * ************************************************************************/
require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XPath extends DB2_Connection
{
    public $SAMPLE_HEADER =
"
echo \"
This sample will demonstrate how to use simple path expression in XQuery
\";
";

    function __construct($initialize = true)
    {
        parent::__construct($initialize);
        $this->make_Connection();
    }

  //The customer_Details method returns all of the XML data in the INFO column of the CUSTOMER table
  public function customer_Details()
  {
    $toPrintToScreen = "
----------------------------------------------------------------
Select the customer information ........

";
    $this->format_Output($toPrintToScreen);

    try
    {
      $Output = "";

      $query = "
XQUERY db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
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
      }
      else
      {
      	$this->format_Output(db2_stmt_errormsg());
      }

    }
    catch(Exception $e)
    {
      try { rollback(); }
      catch (Exception $e) {}
      die(1);
    }
  } // customer_Details

  //The cities_In_Canada method returns a list of cities that are in Canada
  public function cities_In_Canada()
  {
    $toPrintToScreen = "
------------------------------------------------------------------
Select the customer's cities from Canada .....

";
    $this->format_Output($toPrintToScreen);
    try
    {
      $query = "
XQUERY
  fn:distinct-values(
      db2-fn:xmlcolumn('{$this->schema}CUSTOMER.INFO')
       /customerinfo/addr[@country=\"Canada\"]/city
    )
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      $result = db2_exec($this->dbconn, $query);

      if($result)
      {
      	$this->format_Output("\n\nCustomer's cities from Canada:\n");
        // retrieve and display the result from the query
        while($a_result = db2_fetch_array($result))
        {
          // Striping the xml header and printing out the result value
          $this->format_Output("\n" . preg_replace('/\<\?[^(?>)]*\?\>/', "", $a_result[0]));
        }
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
    }
    catch(SQLException $e)
    {
      try { rollback(); }
      catch (Exception $e) {}
      die(1);
    }
  } // cities_In_Canada

  //The cust_Mobile_Num method returns the names of customers whose mobile number starts with 905
  public function cust_Mobile_Num()
  {
    $toPrintToScreen = "
-------------------------------------------------------------------
Return the name of customers whose mobile number starts with 905.......

";
    $this->format_Output($toPrintToScreen);
    try
    {
      $query = "
XQUERY
  db2-fn:xmlcolumn(\"{$this->schema}CUSTOMER.INFO\")
    /customerinfo[phone[@type=\"cell\" and fn:starts-with(text(),\"905\")]]
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
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
      }
      else
      {
      	$this->format_Output(db2_stmt_errormsg());
      }
    }
    catch(SQLException $e)
    {
      try { rollback(); }
      catch (Exception $e) {}
      die(1);
    }
  } // cust_Mobile_Num

  // The AvgPRice method determines the average prive of the products in the 100 series
  public function avg_Price()
  {
    $toPrintToScreen = "
--------------------------------------------------------------------
Return the average price of all products in the 100 series.....

";
    $this->format_Output($toPrintToScreen);
    try
    {

      $query = "
XQUERY
  let
    \$prod_price := db2-fn:xmlcolumn('{$this->schema}PRODUCT.DESCRIPTION')
      /product[fn:starts-with(@pid,\"100\")]/description/price
  return
    avg(\$prod_price)
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      $result = db2_exec($this->dbconn, $query);

      if($result)
      {
        // retrieve and display the result from the xquery
        while($a_result = db2_fetch_array($result))
        {
          // Striping the xml header and printing out the value
          $this->format_Output("\n\nAverage price of all products in the 100 series: " . preg_replace('/\<\?[^(?>)]*\?\>/', "", $a_result[0]));

        }
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
    }
    catch(SQLException $e)
    {
      try { $this->rollback(); }
      catch (Exception $e) {}
      die(1);
    }
  } // avg_Price

  //The customer_From_Toronto method returns information about customers from Toronto
  public function customer_From_Toronto()
  {
    $toPrintToScreen = "
---------------------------------------------------------------------
Return the customers from Toronto.......

";
    $this->format_Output($toPrintToScreen);
    try
    {
      $query = "
XQUERY
  db2-fn:xmlcolumn (\"{$this->schema}CUSTOMER.INFO\")
    /customerinfo[addr/city=\"Toronto\"]
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
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
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
    }
    catch(SQLException $e)
    {
      try { $this->rollback(); }
      catch (Exception $e) {}
      die(1);
    }
  } // customer_From_Toronto

  // The num_Of_Cust_In_Toronto method returns the number of customer from Toronto city
  public function num_Of_Cust_In_Toronto()
  {
    $toPrintToScreen = "
--------------------------------------------------------------------
Return the number of customers from Toronto.......

";
    $this->format_Output($toPrintToScreen);
    try
    {
      $query = "
XQUERY
  fn:count(
      db2-fn:xmlcolumn(\"{$this->schema}CUSTOMER.INFO\")
        /customerinfo[addr/city=\"Toronto\"]
    )
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      $PrepStmt = db2_prepare($this->dbconn, $query);

      if(db2_execute($PrepStmt))
      {
        // retrieve and display the result from the xquery
        while($a_result = db2_fetch_array($PrepStmt))
        {
          // Striping the xml header and printing out the value
          $this->format_Output("\n\nNumber of customers from Toronto: " . preg_replace('/\<\?[^(?>)]*\?\>/', "", $a_result[0]));
        }
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
    }
    catch(SQLException $e)
    {
      try { $this->rollback(); }
      catch (Exception $e) {}
      die(1);
    }
  } // num_Of_Cust_In_Toronto

} //XPath


$Run_Sample = new XPath();

$Run_Sample->customer_Details();

$Run_Sample->cities_In_Canada();

$Run_Sample->cust_Mobile_Num();

$Run_Sample->avg_Price();

$Run_Sample->customer_From_Toronto();

$Run_Sample->num_Of_Cust_In_Toronto();


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
