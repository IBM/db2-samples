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
 * SOURCE FILE NAME: XmlRead_DB2.php
 *
 * SAMPLE: How to read table data
 *
 * SQL Statements USED:
 *         SELECT
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlRead extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO READ TABLE DATA.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }



  public function basic_Select_Of_XML()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
Perform a Basic select of an XML column casting it as a VARCHAR
Using a basic to execute the query


 Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    cid as CID,
    XMLSERIALIZE(info as varchar(600)) AS INFO
  FROM
    {$this->schema}customer
  WHERE
    cid < 1005
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Execute the query
    $stmt = db2_exec($this->dbconn, $query);

    if($stmt === false)
    {
        $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->PrintResult($stmt);
    }

  }

  public function basic_Select_Of_XML_Column()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
Perform a Basic select of an XML column without casting it
Using a basic to execute the query

 Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    cid as CID,
    info AS INFO
  FROM
    {$this->schema}customer
  WHERE
    cid < 1005
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Execute the query
    $stmt = db2_exec($this->dbconn, $query);

    if($stmt === false)
    {
        $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->PrintResult($stmt);
    }

  }

  public function basic_Prepared_Select_Of_XML()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
Perform a Basic select of an XML column casting it as a VARCHAR
Using a prepared statement to execute the query

  Prepare Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    cid as CID,
    XMLSERIALIZE(info as varchar(600)) AS INFO
  FROM
    {$this->schema}customer
  WHERE
    cid < 1005
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    $stmt = db2_prepare($this->dbconn, $query);

    $toPrintToScreen = "

  Execute prepared statement

";
    $this->format_Output($toPrintToScreen);

    if(db2_execute($stmt))
    {
        $this->PrintResult($stmt);
    }
    else
    {
        $this->format_Output(db2_stmt_errormsg($stmt) . "\n");
    }

  } //execPreparedQuery

  public function basic_Prepared_Select_Of_XML_With_Parameters()
  {

    $CID = 1005;

    $toPrintToScreen = "
------------------------------------------------------------------------------
Perform a Basic select of an XML column casting it as a VARCHAR
Using a prepared statement with a parameter to execute the query
Prepare Statement:
";
    $this->format_Output($toPrintToScreen);


    $query = "
SELECT
    cid AS CID,
    XMLSERIALIZE(info as varchar(600)) AS INFO
  FROM
    {$this->schema}customer
  WHERE
    cid < ?
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    $stmt = db2_prepare($this->dbconn, $query);

    $toPrintToScreen = "

  Set parameter value: parameter 1 = $CID

";
    $this->format_Output($toPrintToScreen);

    db2_bind_param($stmt, 1, "CID", DB2_PARAM_IN);

    $toPrintToScreen = "

  Execute prepared statement

";
    $this->format_Output($toPrintToScreen);

    if(db2_execute($stmt))
    {
        $this->PrintResult($stmt);
    }
    else
    {
        $this->format_Output(db2_stmt_errormsg($stmt) . "\n");
    }


  } //execPreparedQueryWithParam

  public function basic_Select_Of_XML_Cast_As_CLOB()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
Perform a Basic select of an XML column casting it as a CLOB
Using a basic to execute the query
  Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    cid AS CID,
    XMLSERIALIZE(info as Clob) AS INFO
  FROM
    {$this->schema}customer
  WHERE
    cid < 1005
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Execute the query
    $stmt = db2_exec($this->dbconn, $query);

    if($stmt === false)
    {
        $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->PrintResult($stmt);
    }
  } //ReadClobData

  public function basic_Select_Of_XML_Cast_As_BLOB()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
Perform a Basic select of an XML column casting it as a BLOB
Using a basic to execute the query
  Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    cid AS CID,
    XMLSERIALIZE(info as blob) as INFO
  FROM
    {$this->schema}customer
  WHERE
    cid < 1005
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Execute the query
    $stmt = db2_exec($this->dbconn, $query);

    if($stmt === false)
    {
        $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $toPrintToScreen = "
| CUSTOMERID
|--------------------------
|| CUSTOMERINFO
___________________________
-----------------------------------------------------------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($aResult = db2_fetch_assoc($stmt))
        {
           $this->format_Output(sprintf("

| %s
|--------------------------
%s
___________________________",
                                            utf8_decode($aResult['CID']),
                                            $this->display_Xml_Parsed_Struct(utf8_decode($aResult['INFO']), "||")
                                        )
                                );

        }
    db2_free_stmt($stmt);
    }
  } //ReadBlobData

  // With the IBM_DB2 driver we are able to use a common print statement
  // for XML, CLOB because they are all returned essentially as strings.
  public function PrintResult($stmt)
  {
        $toPrintToScreen = "
| CUSTOMERID
|--------------------------
|| CUSTOMERINFO
___________________________
-----------------------------------------------------------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($aResult = db2_fetch_assoc($stmt))
        {
           $this->format_Output(sprintf("

| %s
|--------------------------
%s
___________________________",
                                            $aResult['CID'],
                                            $this->display_Xml_Parsed_Struct($aResult['INFO'], "||")
                                        )
                                );

        }
    db2_free_stmt($stmt);
  }
}

$RunSample = new XMLRead();
$RunSample->basic_Select_Of_XML();
$RunSample->basic_Select_Of_XML_Column();
$RunSample->basic_Prepared_Select_Of_XML();
$RunSample->basic_Prepared_Select_Of_XML_With_Parameters();
$RunSample->basic_Select_Of_XML_Cast_As_CLOB();
$RunSample->basic_Select_Of_XML_Cast_As_BLOB();

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
