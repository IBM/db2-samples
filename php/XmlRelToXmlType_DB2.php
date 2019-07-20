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
 * SOURCE FILE NAME: XmlRelToXmlType_DB2.php
 *
 * SAMPLE : Purchase order database uses relational tables to store the orders of
 *          different customers. This data can be returned as an XML object to the
 *          application. The XML object can be created using the XML constructor
 *          functions on the server side.
 *
 *          To achieve this, the user will
 *              To achieve this, the user will
 *                  1. Create new tables having XML columns.
 *                  2. Change the relational data to XML type
 *                      using constructor functions
 *                  3. Insert the data in new tables.
 *                  4. Use the query to select all PO data.
 *
 * SQL Statements USED:
 *         SELECT
 *         INSERT
 *
 * SQL/XML FUNCTION USED:
 *         XMLDOCUMENT
 *         XMLELEMENT
 *         XMLATTRIBUTES
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";
require_once "UtilTableSetup_Xml.php";

class RelToXmlType extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO CONVERT DATA RELATIONAL TABLES
INTO A XML DOCUMENT USING THE XML CONSTRUCTOR FUNCTIONS
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }

  public function relational_Data_To_XML_Type()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------

EXECUTE THE QUERY WITH XML CONSTRUCTORS.

Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}Customerinfo_New(Custid, Address)
  (
    SELECT Custid,
        XMLDOCUMENT(
            XMLELEMENT(
                NAME \"Address\",
                XMLELEMENT(NAME \"Name\", c.Name),
                XMLELEMENT(NAME \"Street\", c.Street),
                XMLELEMENT(NAME \"City\", c.City),
                XMLELEMENT(NAME \"Province\", c.Province),
                XMLELEMENT(NAME \"PostalCode\", c.PostalCode)
              )
          )
      FROM
        {$this->schema}CustomerInfo_relational AS C
  )
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


     $toPrintToScreen = "

Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}purchaseorder_new(PoNum, OrderDate, CustID, Status, LineItems)
  (
    SELECT
        Po.PoNum,
        OrderDate,
        CustID,
        Status,
        XMLDOCUMENT(
            XMLELEMENT(
                NAME \"itemlist\",
                XMLELEMENT(NAME \"PartID\", l.ProdID),
                XMLELEMENT(NAME \"Description\", p.Description ),
                XMLELEMENT(NAME \"Quantity\", l.Quantity),
                XMLELEMENT(NAME \"Price\", p.Price)
              )
          )
      FROM
        {$this->schema}purchaseorder_relational AS po,
        {$this->schema}lineitem_relational AS l,
        {$this->schema}products_relational AS P
      WHERE
        l.PoNum=po.PoNum
            AND
        l.ProdID=P.ProdID
  )
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
  } //relational_Data_To_XML_Type

  public function select_All_PO_Data()
  {

    $toPrintToScreen =  "
------------------------------------------------------------------------------

Use the query to select all PO data
With the Statement:
";
    $this->format_Output($toPrintToScreen);
    $query = "
SELECT
    po.PoNum AS PONUM,
    po.CustId AS CUSTID,
    po.OrderDate AS ORDERDATE,
    XMLELEMENT(NAME \"PurchaseOrder\",
      XMLATTRIBUTES(
          po.CustID AS \"CustID\",
          po.PoNum AS \"PoNum\",
          po.OrderDate AS \"OrderDate\",
          po.Status AS \"Status\"
        )
      ) AS PORDER,
    XMLELEMENT(NAME \"Address\", c.Address) AS ADDRESS,
    XMLELEMENT(NAME \"lineitems\", po.LineItems) AS LINEITEMS
  FROM
    {$this->schema}PurchaseOrder_new AS po,
    {$this->schema}CustomerInfo_new AS c
  WHERE
    po.custid = c.custid
  ORDER BY
    po.custID
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    // Execute the query
    $DataFromTableCompanyB = db2_exec($this->dbconn, $query);

    if($DataFromTableCompanyB)
    {
      $toPrintToScreen = "
|Customer ID | Purchase Order Number | Purchase Order Date
|~~Address
|Address in XML Format
|~~Line Item
|Line Item in XML Format
||-Purchase Order-----------------
|| Purchase Order Document
______________________________________________________________
-----------------------------------------------------------------------------";
      $this->format_Output($toPrintToScreen);
      // retrieve and display the result from the xquery
      while($Employee = db2_fetch_assoc($DataFromTableCompanyB))
      {
        $this->format_Output(sprintf("

| Customer ID | Purchase Order Number | Purchase Order Date
| %11s | %21s | %19s
|~~Address
%s
|~~Line Item
%s
||-Purchase Order-----------------
%s
______________________________________________________________",
                                            $Employee['PONUM'],
                                            $Employee['CUSTID'],
                                            $Employee['ORDERDATE'],
                                            $this->display_Xml_Parsed_Struct($Employee['LINEITEMS'], '|'),
                                            $this->display_Xml_Parsed_Struct($Employee['PORDER'], '|'),
                                            $this->display_Xml_Parsed_Struct($Employee['ADDRESS'], '||')
                                        )
                                );

      }
      db2_free_result($DataFromTableCompanyB);
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg());
    }
  } //select_All_PO_Data
} // RelToXmlType

$RunSample = new RelToXmlType();
// Create new tables having XML columns.
TABLE_SETUP_XML::CREATE($RunSample);

// Change the relational data to XML type using constructor functions
// Insert the data in new tables.
$RunSample->relational_Data_To_XML_Type();
//Use the query to select all PO data
$RunSample->select_All_PO_Data();

// Drop the tables
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
