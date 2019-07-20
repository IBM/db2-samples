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
 * SOURCE FILE NAME: XmlSchema_DB2.php
 *
 * SAMPLE: How to registere XML Schema
 * SAMPLE: How to register an XML Schema
 * SAMPLE USAGE SCENARIO: Consider a user who needs to insert an XML type value
 * into the table. The user would like to ensure that the XML value conforms to a
 * deterministic XML schema.
 *
 * PROBLEM: User has schema's for all the XML values and like to validate the values
 * as per schema while inserting it to the tables.
 *
 * SOLUTION:
 * To achieve the goal, the sample will follow the following steps:
 * a) Register the primary XML schema
 * b) Add the XML schema documents to the primary XML schema to ensure that the
 *    schema is deterministic
 * c) Insert an XML value into an existing XML column and perform validation
 *
 * SQL Statements USED:
 *         INSERT
 *
 * Stored Procedure USED
 *         SYSPROC.XSR_REGISTER
 *         SYSPROC.XSR_ADDSCHEMADOC
 *         SYSPROC.XSR_COMPLETE
 *
 * SQL/XML Function USED
 *         XMLVALIDATE
 *         XMLPARSE
 *
 * PREREQUISITE: copy product.xsd, order.xsd,
 *               customer.xsd, header.xsd Schema files, order.xml XML
 *               document from xml/data directory to working
 *               directory.
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/
require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlSchema extends DB2_Connection
{

  public $relSchema       = "POSAMPLE";
  public $schemaName      = "order";
  public $schemaLocation  = "http://www.test.com/order";
  public $primaryDocument = "order.xsd";
  public $multipleSchema1 = "header.xsd";
  public $multipleSchema2 = "customer.xsd";
  public $multipleSchema3 = "product.xsd";
  public $xmlDoc          = "order.xml";
  public $shred           =  0;
  public $poid            = 10;
  public $status          = "shipped";
  public $SAMPLE_HEADER   = "
echo '
THIS SAMPLE SHOWS UPDATE THE TABLE STATISTICS OF THE \"CUSTOMER\" TABLE.

SCHEMA FIELD IS REQUIERED IN THIS SAMPLE
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();

      // Adds the Document root to the file names
      $this->primaryDocument = $this->documentRoot . "order.xsd";
      $this->multipleSchema1 = $this->documentRoot . "header.xsd";
      $this->multipleSchema2 = $this->documentRoot . "customer.xsd";
      $this->multipleSchema3 = $this->documentRoot . "product.xsd";
      $this->xmlDoc          = $this->documentRoot . "order.xml";
  }


  // This function will register the Primary XML Schema
  public function register_Xml_Schema()
  {

    // register primary XML Schema
    $toPrintToScreen = "
Registering main schema {$this->primaryDocument}...
";
    $this->format_Output($toPrintToScreen);

      $query = "
CALL SYSPROC.XSR_REGISTER(?,?,?,?,NULL)
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $XSRRegstmt = db2_prepare($this->dbconn, $query);

      $primaryDocument = $this->primaryDocument;
      $relSchema       = $this->relSchema;
      $schemaName      = $this->schemaName;
      $schemaLocation  = $this->schemaLocation;

      db2_bind_param($XSRRegstmt, 1, "relSchema", DB2_PARAM_IN);
      db2_bind_param($XSRRegstmt, 2, "schemaName", DB2_PARAM_IN);
      db2_bind_param($XSRRegstmt, 3, "schemaLocation", DB2_PARAM_IN);
      db2_bind_param($XSRRegstmt, 4, "primaryDocument", DB2_PARAM_FILE);


      if(db2_execute($XSRRegstmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg());
      }
      db2_free_stmt($XSRRegstmt);

      // add XML Schema document to the primary schema
      $this->format_Output("  Adding XML Schema document {$this->multipleSchema1}...\n");
      $this->addXmlSchemaDoc($this->multipleSchema1);
      $this->format_Output("  Adding XML Schema document {$this->multipleSchema2}...\n");
      $this->addXmlSchemaDoc($this->multipleSchema2);
      $this->format_Output("  Adding XML Schema document {$this->multipleSchema3}...\n");
      $this->addXmlSchemaDoc($this->multipleSchema3);

     // complete the registeration
    $toPrintToScreen = "
  Completing XML Schema registeration
";
    $this->format_Output($toPrintToScreen);

    $query = "
CALL SYSPROC.XSR_COMPLETE(?,?,NULL,?)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    // Prepare the statement
    $XSRCompstmt = db2_prepare($this->dbconn, $query);

    $relSchema = $this->relSchema;
    $schemaName = $this->schemaName;
    $shred = $this->shred;

    db2_bind_param($XSRCompstmt, 1, "relSchema", DB2_PARAM_IN);
    db2_bind_param($XSRCompstmt, 2, "schemaName", DB2_PARAM_IN);
    db2_bind_param($XSRCompstmt, 3, "shred", DB2_PARAM_IN);

    if(db2_execute($XSRCompstmt))
    {
      $this->format_Output("\nSchema registered successfully\n");
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg($XSRCompstmt));
    }
    db2_free_stmt($XSRCompstmt);
  }// register_Xml_Schema

  // This function will ADD the Schema document to already registered schema.
  // The Schema documents referred in the primary XML schema (using Import or include)
  // should be added to the registered schema before completing the registeration.
  public function addXmlSchemaDoc($schemaDocName)
  {
      $query = "
CALL SYSPROC.XSR_ADDSCHEMADOC(?,?,?,?,NULL)
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $XSRADDstmt = db2_prepare($this->dbconn, $query);

      $relSchema = $this->relSchema;
      $schemaName = $this->schemaName;
      $schemaLocation =$this->schemaLocation;

      db2_bind_param($XSRADDstmt, 1, "relSchema", DB2_PARAM_IN);
      db2_bind_param($XSRADDstmt, 2, "schemaName", DB2_PARAM_IN);
      db2_bind_param($XSRADDstmt, 3, "schemaLocation", DB2_PARAM_IN);
      db2_bind_param($XSRADDstmt, 4, "schemaDocName", DB2_PARAM_FILE);

      if(db2_execute($XSRADDstmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg());
      }
      db2_free_stmt($XSRADDstmt);
  }// addXmlSchemaDoc

  // this function will insert the XML value in the table validating it according
  // to the registered schema
  public function insert_Validate_Xml()
  {

    $query = "
INSERT INTO {$this->schema}PURCHASEORDER(
      poid,
      status,
      porder
    )
  VALUES(
      ?,
      ?,
      xmlvalidate(cast(? as XML) ACCORDING TO XMLSCHEMA ID posample.order)
    )
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $stmt = db2_prepare($this->dbconn, $query);

      $poid = $this->poid;
      $status = $this->status;
      $xmlDoc = $this->xmlDoc;

      db2_bind_param($stmt, 1, "poid", DB2_PARAM_IN);
      db2_bind_param($stmt, 2, "status", DB2_PARAM_IN);
      db2_bind_param($stmt, 3, "xmlDoc", DB2_PARAM_FILE);

      if(db2_execute($stmt) === false)
      {
        $this->format_Output(db2_stmt_errormsg());
      }
      db2_free_stmt($stmt);
  }// insert_Validate_Xml

  // This function will select the information about the registered schema
  public function select_Info()
  {
      $query = "
SELECT
    OBJECTSCHEMA,
    OBJECTNAME
  FROM
    syscat.xsrobjects
  WHERE
    OBJECTNAME = '" . strtoupper($this->schemaName) . "'
";
      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Prepare the statement
      $stmt = db2_prepare($this->dbconn, $query);

    $toPrintToScreen = "
RELATIONAL SCHEMA      XML SCHEMA ID
";
    $this->format_Output($toPrintToScreen);

      if(db2_execute($stmt))
      {
        // retrieve and display the result from the XQUERY statement
        while($a_result = db2_fetch_assoc($stmt))
        {
          // Prints a formatted version of the xml tree that is returned
          $this->format_Output("\n" . $a_result['OBJECTSCHEMA'] . "          " . $a_result['OBJECTNAME']);
        }
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
      db2_free_stmt($stmt);
  } // select_Info

  // This function will drop the registered schema and delete the inserted row
  public function clean_Up()
  {
    $query = "
DROP XSROBJECT posample.{$this->schemaName}
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
DELETE FROM {$this->schema}purchaseorder WHERE poid={$this->poid}
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
} // XmlSchema


$RunSample = new XmlSchema();

// register the XML Schema
$RunSample->register_Xml_Schema();

// Select the information about the registered schema from catalog table
$RunSample->select_Info();

// insert the XML value validating according to the registered schema
$RunSample->insert_Validate_Xml();

// drop the registered the schema
$RunSample->clean_Up();


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
