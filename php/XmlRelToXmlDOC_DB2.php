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
 * SOURCE FILE NAME: XmlRelToXmlDoc_DB2.php
 *
 * SAMPLE USER SCENARIO : Purchase order database uses relational tables to store the
 *         orders of different customers. This data can be returned as an XML object
 *         to the application. The XML object can be created using the XML constructor
 *         functions on the server side.
 *         To achieve this, the user can
 *           1. Create a stored procedure to implement the logic to create the XML
 *              object using XML constructor functions.
 *           2. Register the above stored procedure to the database.
 *           3. Call the procedure whenever all the PO data is needed as XML
 *              instead of using complex joins.
 *
 * SAMPLE : This sample basically demostrates two things
 *           1. Using joins on relational data
 *           2. Using constructor function to get purchaseorder data as an XML object
 *
 *
 * SQL Statements USED:
 *         SELECT
 *
 * SQL/XML Functions Used :
 *         XMLELEMENT
 *     XMLATTRIBUTES
 *         XMLCONCAT
 *         XMLNAMESPACES
 *         XMLCOMMENT
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";
require_once "UtilTableSetup_Xml.php";

class RelToXmlDoc extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo \"
THIS SAMPLE SHOWS HOW TO CONVERT DATA RELATIONAL TABLES
INTO A XML DOCUMENT USING THE XML CONSTRUCTOR FUNCTIONS
\";
";

  function __construct($initialize = true)
  {
    parent::__construct($initialize);
    $this->make_Connection();
  }

  public function exec_Query()
  {
     $toPrintToScreen = "
----------------------------------------------------------
TO EXECUTE THE QUERY WITH XML CONSTRUCTORS.
";
    $this->format_Output($toPrintToScreen);


    $query = "
SELECT
    po.CustID as CUSTID,
    po.PoNum as PONUM,
    po.OrderDate as ORDERDATE,
    po.Status as STATUS,
    count(l.ProdID) as ITEMS,
    sum(p.Price) as TOTAL,
    po.Comment as COMMENT,
    c.Name as NAME,
    c.Street as STREET,
    c.City as CITY,
    c.Province as PROVINCE,
    c.PostalCode as POSTALCODE
 FROM
    {$this->schema}PurchaseOrder_relational as po,
    {$this->schema}CustomerInfo_relational as c,
    {$this->schema}Lineitem_relational as l,
    {$this->schema}Products_relational as p
 WHERE
    po.CustID = c.CustID
      and
    po.PoNum = l.PoNum
      and
    l.ProdID = p.ProdID
 GROUP BY
    po.PoNum,
    po.CustID,
    po.OrderDate,
    po.Status,
    c.Name,
    c.Street,
    c.City,
    c.Province,
    c.PostalCode,
    po.Comment
 ORDER BY
    po.CustID,
    po.OrderDate
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
    $DataFromTableSYSIBMSQLTYPEINFO = db2_exec($this->dbconn, $query);

    if($DataFromTableSYSIBMSQLTYPEINFO)
    {
      $toPrintToScreen = "
  Results:
 |____________________________________________________________________________|
 | CustId          | PoNum       | OrderDate   | Status                       |
 || Items          | Total Price | Comment                                    |
 || Name           | Street      | City        | Province       | PostalCode  |
 |----------------------------------------------------------------------------|
";
      $this->format_Output($toPrintToScreen);
      // retrieve and display the result from the xquery
      while($Employee = db2_fetch_assoc($DataFromTableSYSIBMSQLTYPEINFO))
      {
         $this->format_Output(
         sprintf(" |____________________________________________________________________________|
 | %16s | %11s | %11s | %27s |
 || %15s | %11s | %41s |
 || %15s | %11s | %11s | %14s | %10s |
 |----------------------------------------------------------------------------|
",
                                          $Employee['CUSTID'],
                                          $Employee['PONUM'],
                                          $Employee['ORDERDATE'],
                                          $Employee['STATUS'],
                                          $Employee['ITEMS'],
                                          $Employee['TOTAL'],
                                          $Employee['COMMENT'],
                                          $Employee['NAME'],
                                          $Employee['STREET'],
                                          $Employee['CITY'],
                                          $Employee['PROVINCE'],
                                          $Employee['POSTALCODE']
                                      )
                              );

      }
      db2_free_result($DataFromTableSYSIBMSQLTYPEINFO);
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg());
    }

  } //exec_Query

  public function call_Rel_To_Xml_Proc()
  {
    // call the stored procedure
    $toPrintToScreen = "
Call stored procedure named {$this->schema}Related_to_XML_Proc
";
    $this->format_Output($toPrintToScreen);

    // prepare the CALL statement for ONE_RESULT_SET
    $query = "
CALL {$this->schema}Related_to_XML_Proc()
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $Results = db2_exec($this->dbconn, $query);
    if($Results === false)
    {
      $toPrintToScreen = "
{$this->schema}Related_to_XML_Proc completed FAILD
";
      $this->format_Output($toPrintToScreen);
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
      $toPrintToScreen = "
{$this->schema}Related_to_XML_Proc completed successfully

=============================================================
";
      $this->format_Output($toPrintToScreen);
      while($A_Results = db2_fetch_array($Results))
      {
        $this->format_Output(sprintf("
|---------------------------|
| PO Number   | %11s |
| Customer ID | %11s |
| Order Date  | %11s |
|-Purchase Order----------- |--------------------------------------------------
%s
--END--------------------------------------------------------------------------",
                                 $A_Results[0],
                                 $A_Results[1],
                                 $A_Results[2],
                                 $this->display_Xml_Parsed_Struct($A_Results[3])
                                  )
                             );
      }
      db2_free_stmt($Results);
    }
  } // call_Rel_To_Xml_Proc

  public function create_SP_Related_to_XML_Proc()
  {
     $toPrintToScreen = "
Attempting to create the stored procedure {$this->schema}Related_to_XML_Proc()

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE PROCEDURE {$this->schema}Related_to_XML_Proc()
RESULT SETS 1
LANGUAGE SQL
BEGIN
  DECLARE C1 CURSOR WITH return for
  SELECT
     po.PoNum,
     po.CustID,
     po.OrderDate,
     XMLCONCAT(
                XMLPI(
                      NAME \"pi\",
                      'MESSAGE(\"valid, well-formed document\")'
                      ),
                XMLELEMENT(
                           NAME \"PurchaseOrder\",
                           XMLNAMESPACES(
                                         'http://www.example.org' AS \"e\"
                                         ),
                           XMLATTRIBUTES(
                                         po.CustID as \"CustID\",
                                         po.PoNum as \"PoNum\",
                                         po.OrderDate as \"OrderDate\",
                                         po.Status as \"Status\"
                                         ),
                           XMLELEMENT(
                                      NAME \"CustomerAddress\",
                                      XMLCONCAT(
                                                XMLELEMENT(
                                                           NAME \"e.Name\",
                                                           c.Name
                                                           ),
                                                XMLELEMENT(
                                                           NAME \"e.Street\",
                                                           c.Street
                                                           ),
                                                XMLELEMENT(
                                                           NAME \"e.City\",
                                                           c.City
                                                           ),
                                                XMLELEMENT(
                                                           NAME \"e.Province\",
                                                           c.Province
                                                           ),
                                                XMLELEMENT(
                                                           NAME \"e.PostalCode\",
                                                           c.PostalCode
                                                           )
                                                )
                                       ),
                           XMLELEMENT(
                                      NAME \"ItemList\" ,
                                      XMLELEMENT(
                                                 NAME \"Item\",
                                                 XMLELEMENT(
                                                            NAME \"PartId\",
                                                            l.ProdID
                                                            ),
                                                 XMLELEMENT(
                                                            NAME \"Description\",
                                                            p.Description
                                                            ),
                                                 XMLELEMENT(
                                                            NAME \"Quantity\",
                                                            l.Quantity
                                                            ),
                                                 XMLELEMENT(
                                                            NAME \"Price\",
                                                            p.Price
                                                            ),
                                                 XMLCOMMENT(
                                                            po.comment
                                                            )
                                                 )
                                     )
                          )
              )
  FROM
     {$this->schema}PurchaseOrder_Relational as Po,
     {$this->schema}CustomerInfo_Relational AS c,
     {$this->schema}Lineitem_Relational AS l,
     {$this->schema}Products_Relational AS p
  WHERE
     po.CustID = c.CustID
         and
     po.PoNum = l.PoNum
         and
     l.ProdID = p.ProdID
  ORDER BY
     po.PoNum;
  OPEN C1;
END
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
  }

  public function drop_SP_Related_to_XML_Proc()
  {
     $toPrintToScreen = "

Attempting to drop the stored procedure Related_to_XML_Proc()
";
    $this->format_Output($toPrintToScreen);

    $query = "
DROP PROCEDURE {$this->schema}Related_to_XML_Proc()
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
  }

} // RelToXmlDoc


$RunSample = new RelToXmlDoc();

TABLE_SETUP_XML::CREATE($RunSample);

$RunSample->create_SP_Related_to_XML_Proc();

// select the purchaseorder data using joins
$RunSample->exec_Query();

// function to call  the stored procedure which will
// select purchaseorder data using XMLconstructors
$RunSample->call_Rel_To_Xml_Proc();

$RunSample->drop_SP_Related_to_XML_Proc();

TABLE_SETUP_XML::DROP($RunSample);


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
$RunSample->rollback();


// Close the database connection
$RunSample->close_Connection();


?>
