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
 * SOURCE FILE NAME: XmlToTable_DB2.php
 *
 * SAMPLE USAGE SCENARIO: Purchase order XML document contains detailed
 * information about all the orders. It will also have the detail of the
 * customer with each order.
 *
 * PROBLEM: The document has some redundant information as customer info
 * and product info is repeated in each order for example
 * Customer info is repeated for each order from same customer.
 * Product info will be repeated for each order of same product from different customers.
 *
 * SOLUTION: The sample database has tables with both relational and XML data to remove
 * this redundant information. These relational tables will be used to store
 * the customer info and product info in the relational table having XML data
 * and id value. Purchase order will be stored in another table and it will
 * reference the customerId and productId to refer the customer and product
 * info respectively.
 *
 * To achieve the above goal this sample will shred the data for purchase order XML
 * document and insert it into the tables.
 *
 * The sample will follow the following steps
 *
 * 1. Get the relevant data in XML format from the purchase order XML document (use XMLQuery)
 * 2. Shred the XML doc into the relational table. (Use XMLTable)
 * 3. Select the relevant data from the table and insert into the target relational table.
 *
 * EXTERNAL DEPENDENCIES:
 *     For successful precompilation, the sample database must exist
 *     (see DB2's db2sampl command).
 *     XML Document purchaseorder.xml must exist in the same directory as of this sample
 *
 * SQL Statements USED:
 *         SELECT
 *         INSERT
 *
 * XML Functions USED:
 *         XMLCOLUMN
 *         XMLELEMENT
 *         XMLTABLE
 *         XMLDOCUMENT
 *         XMLATTRIBTES
 *         XMLCONCAT
 *         XQUERY
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlToTable extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
This sample will shred the data for purchase order XML document and insert it into the tables
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }


  public function display_Content()
  {
    $query = "
SELECT CID, INFO FROM {$this->schema}CUSTOMER
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Prepare the SQL/XML query
    $SELECTCustomerstmt = db2_prepare($this->dbconn, $query);

    if(db2_execute($SELECTCustomerstmt))
    {
        // retrieve and display the result from the SQL/XML statement
        $this->format_Output("\n");
        // retrieve and display the result from the xquery
        while($a_result = db2_fetch_assoc($SELECTCustomerstmt))
        {
          $this->format_Output("\nCID : " . $a_result['CID'] . "\nINFO :\n" . $this->display_Xml_Parsed_Struct($a_result['INFO']));
        }
        db2_free_stmt($SELECTCustomerstmt);
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg($SELECTCustomerstmt));
    }

    $query = "

SELECT POID, PORDER FROM {$this->schema}purchaseorder

";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Prepare the SQL/XML query
    $SELECTPurchaseorderstmt = db2_prepare($this->dbconn, $query);

    if(db2_execute($SELECTPurchaseorderstmt))
    {
        // retrieve and display the result from the SQL/XML statement
        $this->format_Output("\n");
        // retrieve and display the result from the xquery
        while($a_result = db2_fetch_assoc($SELECTPurchaseorderstmt))
        {
          $this->format_Output("\nPOID : " . $a_result['POID'] . "PORDER :\n" . $this->display_Xml_Parsed_Struct($a_result['PORDER']));
        }
        db2_free_stmt($SELECTPurchaseorderstmt);
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg($SELECTPurchaseorderstmt));
    }

  } // display_Content

  public function clean_Up()
  {
    $query = "

DELETE FROM {$this->schema}CUSTOMER WHERE CID IN (10,11)

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

    $query = "

DELETE FROM {$this->schema}PURCHASEORDER WHERE POID IN (110,111)

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

    $this->commit();
 } // clean_Up

  //Select the XML data and then pass it back in to the database
  public function PO_shred_Method_1()
  {
    // create PO table
    $query = "
CREATE TABLE {$this->schema}PO (purchaseorder XML)
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
      $this->commit();

      $query="
insert into {$this->schema}PO values(?)
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      // Prepare the SQL/XML query
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the value of parameter marker
      $XMLFileContents = $this->return_File_Values("purchaseorder.xml");

      $this->format_Output("\nSet the value of the parameter to the contents of the file purchaseorder.xml");
      db2_bind_param($stmt, 1, "XMLFileContents", DB2_PARAM_IN);

      if(db2_execute($stmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg($stmt));
      }
      db2_free_stmt($stmt);
      $this->commit();
    }
    $toPrintToScreen = "
INSERT INTO CUSTOMER TABLE USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED
";
    $this->format_Output($toPrintToScreen);

    $custInsert="
INSERT INTO {$this->schema}customer(
                CID,
                info,
                history
              )
  SELECT
    T.CustID,
    xmldocument(
        XMLELEMENT(
            NAME \"customerinfo\",
            XMLATTRIBUTES (T.CustID as \"Cid\"),
            XMLCONCAT(
                XMLELEMENT(NAME \"name\", T.Name ),
                T.Addr,
                XMLELEMENT(
                    NAME \"phone\",
                    XMLATTRIBUTES(T.type as \"type\"),
                    T.Phone
                  )
              )
          )
      ),
    XMLDOCUMENT(T.History)
  FROM
    XMLTABLE(
        '
          \$d/PurchaseOrder
        ' PASSING
            XMLCAST(? as XML)  AS \"d\"
            COLUMNS
              CustID   BIGINT      PATH  '@CustId',
              Addr     XML         PATH './Address',
              Name     VARCHAR(20) PATH './name',
              Country  VARCHAR(20) PATH './Address/@country',
              Phone    VARCHAR(20) PATH './phone',
              Type     VARCHAR(20) PATH './phone/@type',
              History  XML         PATH './History'
      ) as T
  WHERE
    T.CustID NOT IN(
        SELECT CID FROM {$this->schema}customer
      )
";
      $this->format_Output($custInsert);
      //Removing Excess white space.
      $custInsert = preg_replace('/\s+/', " ", $custInsert);
      // Prepare the SQL/XML query
      $custInsertstmt = db2_prepare($this->dbconn, $custInsert);

     $toPrintToScreen = "
INSERT INTO PURCHASE ORDER USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED
";
    $this->format_Output($toPrintToScreen);

      $POInsert = "
INSERT INTO {$this->schema}purchaseOrder(
                                  poid,
                                  orderdate,
                                  custid,
                                  status,
                                  porder,
                                  comments
                                )
  SELECT
      poid,
      orderdate,
      custid,
      status,
      XMLDOCUMENT(
          XMLELEMENT(
              NAME \"PurchaseOrder\",
              XMLATTRIBUTES(
                  T.Poid as \"PoNum\",
                  T.OrderDate as \"OrderDate\",
                  T.Status as \"Status\"
                ),
              T.itemlist
            )
        ),
      comment
  FROM
    XMLTable(
        '
          \$d/PurchaseOrder
        ' PASSING
            XMLCAST(? as XML)  as \"d\"
            COLUMNS
              poid      BIGINT        PATH '@PoNum',
              orderdate DATE          PATH '@OrderDate',
              CustID    BIGINT        PATH '@CustId',
              status    VARCHAR(10)   PATH '@Status',
              itemlist  XML           PATH './itemlist',
              comment   VARCHAR(1024) PATH './comments'
      ) as T
";


      $this->format_Output($POInsert);
      //Removing Excess white space.
      $POInsert = preg_replace('/\s+/', " ", $POInsert);
      // Prepare the SQL/XML query
      $custPOInsert = db2_prepare($this->dbconn, $POInsert);

     $toPrintToScreen = "
Run the XQuery to find out the purchaseorder with status shipped:
";
    $this->format_Output($toPrintToScreen);
    $query = "

XQUERY db2-fn:xmlcolumn('{$this->schema}PO.PURCHASEORDER')/PurchaseOrders/PurchaseOrder[@Status='shipped']

";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Prepare the SQL/XML query
    $XQUERYstmt = db2_prepare($this->dbconn, $query);

    if(db2_execute($XQUERYstmt))
    {
       $num_record_customer = 0;
       $num_record_po = 0;
       // iterate for all the rows, insert the data into the relational table
       while($a_result = db2_fetch_array($XQUERYstmt))
       {
         $XML_Data = $a_result[0];

         // insert into customer table
         $toPrintToScreen = "
Inserting into customer table ....
";
         $this->format_Output($toPrintToScreen);

         // Set the value of parameter marker

         $this->format_Output("\nSet the value of the parameter to the contents of the file purchaseorder.xml\n");

         db2_bind_param($custInsertstmt, 1, "XML_Data", DB2_PARAM_IN);

         if(db2_execute($custInsertstmt) === false)
         {
           $this->format_Output(db2_stmt_errormsg($custInsertstmt));
         }
         $num_record_customer++;

         // insert into purchaseorder table
         $toPrintToScreen = "
Inserting into purchaseorder table .....

";
         $this->format_Output($toPrintToScreen);
         // Set the value of parameter marker
        $this->format_Output("\nSet the value of the parameter to the contents of the file purchaseorder.xml\n");
        db2_bind_param($custPOInsert, 1, "XML_Data", DB2_PARAM_IN);

        if(db2_execute($custPOInsert) === false)
        {
          $this->format_Output(db2_stmt_errormsg($custPOInsert));
        }
        $num_record_po++;

       }// while loop

      $toPrintToScreen = "

Number of record inserted to customer table = $num_record_customer
Number of record inserted to purchaseorder table = $num_record_po

";
      $this->format_Output($toPrintToScreen);
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg($toPrintToScreen));
    }
    db2_free_stmt($custPOInsert);
    db2_free_stmt($custInsertstmt);
    db2_free_stmt($XQUERYstmt);

    $query = "

DROP TABLE {$this->schema}PO

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

    $this->commit();
  }// PO_shred

  //Shread XML already in the database
  public function PO_shred_Method_2()
  {
    // create PO table
    $query = "
CREATE TABLE {$this->schema}PO (purchaseorder XML)
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
      $this->commit();

      $query="
insert into {$this->schema}PO values(?)
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      // Prepare the SQL/XML query
      $stmt = db2_prepare($this->dbconn, $query);

      // Set the value of parameter marker
      $XMLFileContents = $this->return_File_Values("purchaseorder.xml");
      $this->format_Output("\nSet the value of the parameter to the contents of the file purchaseorder.xml");
      db2_bind_param($stmt, 1, "XMLFileContents", DB2_PARAM_IN);

      if(db2_execute($stmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg($stmt));
      }
      db2_free_stmt($stmt);
      $this->commit();
    }
    $toPrintToScreen = "
INSERT INTO CUSTOMER TABLE USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED
";
    $this->format_Output($toPrintToScreen);

    $custInsert="
INSERT INTO {$this->schema}customer(
                      CID,
                      info,
                      history
                    )
  SELECT
    T.CustID,
    XMLDOCUMENT(
        XMLELEMENT(
            NAME \"customerinfo\",
            XMLATTRIBUTES (T.CustID as \"Cid\"),
            XMLCONCAT(
                XMLELEMENT(NAME \"name\", T.Name ),
                T.Addr,
                XMLELEMENT(
                    NAME \"phone\",
                    XMLATTRIBUTES(T.type as \"type\"),
                    T.Phone
                  )
              )
          )
      ),
    XMLDOCUMENT(T.History)
  FROM
    XMLTABLE(
        '
          db2-fn:xmlcolumn(\"{$this->schema}PO.PURCHASEORDER\")
            /PurchaseOrders/PurchaseOrder[@Status=\"shipped\"]
        ' COLUMNS
            CustID   BIGINT      PATH  '@CustId',
            Addr     XML         PATH './Address',
            Name     VARCHAR(20) PATH './name',
            Country  VARCHAR(20) PATH './Address/@country',
            Phone    VARCHAR(20) PATH './phone',
            Type     VARCHAR(20) PATH './phone/@type',
            History  XML         PATH './History'
      ) as T
  WHERE
      T.CustID NOT IN(
          SELECT CID FROM {$this->schema}customer
        )
";
      $this->format_Output($custInsert);
      //Removing Excess white space.
      $custInsert = preg_replace('/\s+/', " ", $custInsert);
      // Prepare and execute the SQL/XML query
    if(db2_exec($this->dbconn, $custInsert) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

     $toPrintToScreen = "
INSERT INTO PURCHASE ORDER USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED
";
    $this->format_Output($toPrintToScreen);

      $POInsert = "
INSERT INTO {$this->schema}purchaseOrder(
                                  poid,
                                  orderdate,
                                  custid,
                                  status,
                                  porder,
                                  comments
                                )
  SELECT
      poid,
      orderdate,
      custid,
      status,
      xmldocument(
          XMLELEMENT(
              name \"PurchaseOrder\",
              XMLATTRIBUTES(
                  T.Poid as \"PoNum\",
                  T.OrderDate as \"OrderDate\",
                  T.Status as \"Status\"
                ),
              T.itemlist
            )
          ),
        comment
  FROM
    XMLTable(
        '
          db2-fn:xmlcolumn(\"{$this->schema}PO.PURCHASEORDER\")
            /PurchaseOrders/PurchaseOrder[@Status=\"shipped\"]
        ' columns
            poid      BIGINT        path '@PoNum',
            orderdate DATE          path '@OrderDate',
            CustID    BIGINT        path '@CustId',
            status    VARCHAR(10)   path '@Status',
            itemlist  XML           path './itemlist',
            comment   VARCHAR(1024) path './comments'
      ) as T
";


      $this->format_Output($POInsert);
      //Removing Excess white space.
      $POInsert = preg_replace('/\s+/', " ", $POInsert);
      // Prepare and execute the SQL/XML query
    if(db2_exec($this->dbconn, $POInsert) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    $query = "

DROP TABLE {$this->schema}PO

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

    $this->commit();

  }// PO_shred

  //Shread XML in to the database right from a file
  public function PO_shred_Method_3()
  {
  	$XMLFileContents = $this->return_File_Values("purchaseorder.xml");
    $toPrintToScreen = "
INSERT INTO CUSTOMER TABLE USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED
";
    $this->format_Output($toPrintToScreen);

    $custInsert="
INSERT INTO {$this->schema}customer(
                      CID,
                      info,
                      history
                    )
  SELECT
    T.CustID,
    XMLDOCUMENT(
        XMLELEMENT(
            NAME \"customerinfo\",
            XMLATTRIBUTES (T.CustID as \"Cid\"),
            XMLCONCAT(
                XMLELEMENT(NAME \"name\", T.Name ),
                T.Addr,
                XMLELEMENT(
                    NAME \"phone\",
                    XMLATTRIBUTES(T.type as \"type\"),
                    T.Phone
                  )
              )
          )
      ),
    xmldocument(T.History)
  FROM
    XMLTABLE(
        '
          \$d/PurchaseOrders/PurchaseOrder
        ' PASSING
            XMLCAST(? as XML)  as \"d\"
            COLUMNS
              CustID   BIGINT      PATH  '@CustId',
              Addr     XML         PATH './Address',
              Name     VARCHAR(20) PATH './name',
              Country  VARCHAR(20) PATH './Address/@country',
              Phone    VARCHAR(20) PATH './phone',
              Type     VARCHAR(20) PATH './phone/@type',
              History  XML         PATH './History'
      ) as T
  WHERE
    T.CustID NOT IN(
        SELECT CID FROM {$this->schema}customer
      )
";
      $this->format_Output($custInsert);
      //Removing Excess white space.
      $custInsert = preg_replace('/\s+/', " ", $custInsert);
      // Prepare and execute the SQL/XML query
      $custInsertstmt = db2_prepare($this->dbconn, $custInsert);
      db2_bind_param($custInsertstmt, 1, "XMLFileContents", DB2_PARAM_IN);

      if(db2_execute($custInsertstmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg($custInsertstmt));
      }
      db2_free_stmt($custInsertstmt);
      $toPrintToScreen = "
INSERT INTO PURCHASE ORDER USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED
";
      $this->format_Output($toPrintToScreen);

      $POInsert = "
INSERT INTO {$this->schema}purchaseOrder(
                                  poid,
                                  orderdate,
                                  custid,
                                  status,
                                  porder,
                                  comments
                                )
  SELECT
    poid,
    orderdate,
    custid,
    status,
    xmldocument(
        XMLELEMENT(
            name \"PurchaseOrder\",
            XMLATTRIBUTES(
                T.Poid as \"PoNum\",
                T.OrderDate as \"OrderDate\",
                T.Status as \"Status\"
              ),
            T.itemlist
          )
      ),
    comment
  FROM
    XMLTable(
        '
          \$d/PurchaseOrders/PurchaseOrder
        ' PASSING
            XMLCAST(? as XML)  as \"d\"
            COLUMNS
              poid      BIGINT        PATH '@PoNum',
              orderdate DATE          PATH '@OrderDate',
              CustID    BIGINT        PATH '@CustId',
              status    VARCHAR(10)   PATH '@Status',
              itemlist  XML           PATH './itemlist',
              comment   VARCHAR(1024) PATH './comments'
      ) as T
";


      $this->format_Output($POInsert);
      //Removing Excess white space.
      $POInsert = preg_replace('/\s+/', " ", $POInsert);
      // Prepare and execute the SQL/XML query
      $POInsertStmt = db2_prepare($this->dbconn, $custInsert);

      db2_bind_param($POInsertStmt, 1, "XMLFileContents", DB2_PARAM_IN);

      if(db2_execute($POInsertStmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg($POInsertStmt));
      }
      db2_free_stmt($POInsertStmt);
      $this->commit();

  }// PO_shred

 public function return_File_Values($fileName)
 {
 	$FileContence  = file_get_contents($fileName, "r");
    if($FileContence === false)
    {
      $toPrintToScreen = "
    FILE OPEN FAILD!
";
      $this->format_Output($toPrintToScreen);
    }
    return $FileContence;
 }// return_File_Values
}// XmlToTable


$Run_Sample = new XmlToTable();
$Run_Sample->PO_shred_Method_1();
$Run_Sample->display_Content();
$Run_Sample->clean_Up();

$Run_Sample->PO_shred_Method_2();
$Run_Sample->display_Content();
$Run_Sample->clean_Up();

$Run_Sample->PO_shred_Method_3();
$Run_Sample->display_Content();
$Run_Sample->clean_Up();


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
