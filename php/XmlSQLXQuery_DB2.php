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
 * SOURCE FILE NAME: XmlSQLXQuery_DB2.php
 *
 * SAMPLE: How to run SQL/XML Queries
 *
 * SQL Statements USED:
 *         SELECT
 *
 *
 * SQL/XML STATEMENTS USED:
 *                XMLQUERY
 *                XMLEXISTS
 *
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class SqlXQuery extends DB2_Connection
{
    public $SAMPLE_HEADER =
"
echo \"
This sample will demonstrate how to run SQL/XML Queries

\";
";

    function __construct($initialize = true)
    {
        parent::__construct($initialize);
        $this->make_Connection();
    }

  // The first_PO1 function returns the first item in the purchase order for customer custName passed as an argument
  public function first_PO1($custName)
  {
      $toPrintToScreen = "
---------------------------------------------------------------------------
RETURN THE FIRST ITEM IN THE PURCHASEORDER FOR THE CUSTOMER $custName......
";
      $this->format_Output($toPrintToScreen);

     $query="
SELECT
    XMLQUERY(
        '
            \$p/PurchaseOrder/item[1]
        '
        passing p.porder AS \"p\"
      )
  FROM
    {$this->schema}PURCHASEORDER AS p,
    {$this->schema}CUSTOMER AS c
  WHERE
    XMLEXISTS(
        '
            \$custinfo/customerinfo[name=\$c and @Cid = \$cid]
        '
        passing c.info AS \"custinfo\",
        p.custid AS \"cid\",
        cast(? as varchar(20)) as \"c\"
      )
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      // Prepare the SQL/XML query
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the value of parameter marker

      $this->format_Output("\nSet the value of the parameter: $custName");
      db2_bind_param($stmt, 1, "custName", DB2_PARAM_IN);

      if(db2_execute($stmt))
      {
          // retrieve and display the result from the SQL/XML statement
          $this->format_Output("\n");
          // retrieve and display the result from the xquery
          while($a_result = db2_fetch_array($stmt))
          {
            // getting the XML value in a string object

            $this->format_Output("\n" . $this->display_Xml_Parsed_Struct($a_result[0]));
          }
          db2_free_stmt($stmt);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // first_PO1

  // The first_PO2 function returns the first item in the purchaseorder when
  //  Name is from the sequence (X,Y,Z)
  // or the customer id is from the sequence (1000,1002,1003)
  public function first_PO2()
  {

      $toPrintToScreen = "
---------------------------------------------------------------------------
RETURN THE FIRST ITEM IN THE PURCHASEORDER WHEN THE CUSTOMER IS IN SEQUENCE
(X,Y,Z) AND CUSTOMER ID IN THE SEQUENCE (1001,1002,1003)   ........
";
      $this->format_Output($toPrintToScreen);

      $query="
SELECT
    CID,
    XMLQUERY(
        '
            \$custinfo/customerinfo/name
        ' passing c.info AS \"custinfo\"
      ) AS NAME,
    XMLQUERY(
        '
            \$p/PurchaseOrder/item[1]
        ' passing p.porder AS \"p\"
      ) as PURCHASEORDER,
    XMLQUERY(
        '
            \$x/history
        ' passing c.history AS \"x\"
      ) AS HISTORY
  FROM
    {$this->schema}PURCHASEORDER AS p,
    {$this->schema}CUSTOMER AS c
  WHERE
    XMLEXISTS(
        '
            \$custinfo/customerinfo[name=(X,Y,Z)
            or @Cid=(1000,1002,1003) and @Cid=\$cid ]
        ' passing c.info AS \"custinfo\", p.custid AS \"cid\"
      )
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      // Execute the query
      $result = db2_exec($this->dbconn, $query);
      if($result)
      {
          // retrieve and display the result from the SQL/XML statement
          while($a_result = db2_fetch_array($result))
          {
            // Print the customer id
            $this->format_Output("\n\nCid: " . $a_result[0]);

            // Print the name as DB2 String
            $this->format_Output("\nName: \n" . $this->display_Xml_Parsed_Struct($a_result[1]));

            // Print the first item in the purchaseorder as DB2 XML String
            $this->format_Output("\nFirst Item in purchaseorder : \n" . $this->display_Xml_Parsed_Struct($a_result[2]));

            // Retrieve the history for the customer

            // Print the history of the customer as DB2 XML String
            $this->format_Output("\nHistory:\n" . $this->display_Xml_Parsed_Struct($a_result[3]));
          }

          // Close the result set and statement object
        db2_free_result($result);
      }
      else
      {
      	$this->format_Output(db2_stmt_errormsg());
      }
  } // first_PO2

  // The sort_Cust_PO function sort the customers according to the number of purchaseorders
  public function sort_Cust_PO()
  {
      $toPrintToScreen = "
--------------------------------------------------------------------------
SORT THE CUSTOMERS ACCORDING TO THE NUMBER OF PURCHASEORDERS...........
";
      $this->format_Output($toPrintToScreen);
      $query="
WITH count_table AS
(
   SELECT
      count(poid) as COUNT_POID,
      custid
    FROM
      {$this->schema}PURCHASEORDER,
      {$this->schema}CUSTOMER
    WHERE
      cid=custid
    GROUP BY
      custid
)
SELECT
    COUNT_POID,
    XMLQUERY(
        '
            \$s/customerinfo[@Cid=\$id]/name
        ' passing
            {$this->schema}CUSTOMER.INFO AS \"s\",
            count_table.custid as \"id\"
      ) AS CUSTOMER
  FROM
    {$this->schema}CUSTOMER,
    count_table
  WHERE
    custid=cid
  ORDER BY
    COUNT_POID
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      // Execute the query
      $result = db2_exec($this->dbconn, $query);

      if($result !== FALSE)
      {
          $this->format_Output("\n");
          // retrieve and display the result from the SQL/XML statement
          while($a_result = db2_fetch_array($result))
          {
            // Print the customer names in order of number of purchase orders
            $this->format_Output("COUNT : " . $a_result[0] . "\n  CUSTOMER : \n" . $this->display_Xml_Parsed_Struct($a_result[1]) . "\n");
          }
          db2_free_result($result);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // sort_Cust_PO

  // The num_PO function returns the number of purchaseorder having specific partid
  // for the specific customer passed as an argument to the function
   public function num_PO($name, $partId)
  {
      $toPrintToScreen = "
---------------------------------------------------------------------------
RETURN THE NUMBER OF PURCHASEORDER FOR THE CUSTOMER $name HAVING THE
 PARTID $partId......
";
      $this->format_Output($toPrintToScreen);

      $query="
WITH cid_table AS
(
  SELECT
      Cid
    FROM
      {$this->schema}CUSTOMER
    WHERE
      XMLEXISTS(
          '
              \$custinfo/customerinfo[name=\$name]
          ' passing
              {$this->schema}CUSTOMER.INFO AS \"custinfo\",
              cast(? as varchar(20)) as \"name\"
        )
)
SELECT
    count(poid) as COUNT_POID
  FROM
    {$this->schema}PURCHASEORDER,
    cid_table
  WHERE
    XMLEXISTS(
        '
            \$po/PurchaseOrder/item[partid=\$id]
        ' passing
            {$this->schema}PURCHASEORDER.PORDER AS \"po\",
            cast(? as varchar(20)) as \"id\"
      )
      AND
    {$this->schema}PURCHASEORDER.CUSTID = cid_table.cid
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      // Prepare the statement
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the first parameter value value
      $this->format_Output("\nset the first parameter value : $name");
      db2_bind_param($stmt, 1, "name", DB2_PARAM_IN);

      // Set the second parameter value
      $this->format_Output("\nset the second paramter value : $partId");
      db2_bind_param($stmt, 2, "partId", DB2_PARAM_IN);
      $this->format_Output("\n\n");
      if(db2_execute($stmt))
      {
          $this->format_Output("\n");
          // retrieve and display the result from the SQL/XML statement
          while($a_result = db2_fetch_array($stmt))
          {
            // Print the number of purchase order
            $this->format_Output("Number of purchase order with partid $partId for customer $name : " . $a_result[0]);
          }
          db2_free_stmt($stmt);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  }     // num_PO

} // SqlXQuery



$custName="Robert Shoemaker";
$partID="100-101-01";

$Run_Sample = new SqlXQuery();

$Run_Sample->first_PO1($custName);

$Run_Sample->first_PO2();

$Run_Sample->sort_Cust_PO();

$Run_Sample->num_PO($custName, $partID);


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
