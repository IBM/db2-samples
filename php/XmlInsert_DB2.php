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
 * SOURCE FILE NAME: XmlInsert_DB2.php
 *
 * SAMPLE: How to insert rows having XML data into a table.
 *
 *
 * PREREQUISITE : copy the files cust1023.xml to working directory before running 
*                 the sample. This file can be found in xml/data
 *                directory.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlInsert extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO INSERT XML TABLE DATA.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }


  public function most_Simple_Insert()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM A SIMPLE INSERT.

";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1006);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  VALUES(
    1006,
    XMLPARSE(document
        '
          <customerinfo Cid=\"1006\">
            <name>
              divya
            </name>
          </customerinfo>
        '
        preserve whitespace
      )
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

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1006);
    $this->commit();
  } // most_Simple_Insert

  public function insert_From_Another_Xml_Column()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM AN INSERT WHERE SOURCE IS FROM ANOTHER XML COLUMN.

";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1007);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  SELECT
      ocid,
      information
    FROM
      {$this->schema}oldcustomer p
    WHERE
      p.ocid=1007
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

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1007);
    $this->commit();
  } // insert_From_Another_Xml_Column

  public function insert_From_Another_String_Column()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM AN  INSERT WHERE SOURCE IS FROM ANOTHER STRING COLUMN.

";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1008);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  SELECT
      ocid,
      XMLPARSE(document addr preserve whitespace)
    FROM
      {$this->schema}oldcustomer p
    WHERE
      p.ocid=1008
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

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1008);
    $this->commit();
  } // insert_From_Another_String_Column

  public function insert_with_Validation_Sourceis_Varchar()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  {$this->schema}INSERT
TO PERFORM AN  INSERT WITH VALIDATION WHERE SOURCE IS TYPED OF VARCHAR.

";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1009);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  SELECT
      ocid,
      XMLVALIDATE(
        XMLPARSE(document addr preserve whitespace)
        according to XMLSCHEMA ID {$this->schema}CUSTOMER
      )
    FROM
      {$this->schema}oldcustomer p
    WHERE
      p.ocid=1009
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

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1009);
    $this->commit();
  } // insert_with_Validation_Sourceis_Varchar

  public function insert_where_Source_is_Xml_Function()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT\n
TO PERFORM AN INSERT WHERE SOURCE IS A XML FUNCTION.
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  SELECT
      ocid,
      XMLPARSE(
          document XMLSERIALIZE(
            content XMLELEMENT(
              NAME\"oldCustomer\",
              XMLATTRIBUTES(
                s.ocid,
                s.firstname||' '||s.lastname AS \"name\"
                )
              )
              as varchar(200)
            )
          strip whitespace
        )
    FROM
      {$this->schema}oldcustomer s
    WHERE
      s.ocid=1010
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

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1010);
    $this->commit();
  } //  insert_where_Source_is_Xml_Function

  public function insert_where_Source_is_Typecast_To_XML()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM AN  INSERT WHERE SOURCE IS TYPECAST TO XML.
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  VALUES(
          1031,
          XMLCAST(
            XMLPARSE(
              document
                '
                  <oldcustomerinfo ocid = \"1031\">
                    <address country=\"india\">
                      <street>
                        56 hillview
                      </street>
                      <city>
                        kolar
                      </city>
                      <state>
                        karnataka
                      </state>
                    </address>
                  </oldcustomerinfo>
                '
                preserve whitespace
              )
              as XML
            )
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

    //display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1031);
    $this->commit();
  } //insert_where_Source_is_Typecast_To_XML

  public function validate_XML_Document()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM AN  INSERT WITH VALIDATION WHEN  DOCUMENT IS NOT AS PER SCHEMA
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  VALUES(
          1012,
          XMLVALIDATE(XMLPARSE(document
                          '
                            <customerinfo
                                Cid=\"1012\"
                            >
                              <addr country= \"india\">
                                <street>
                                  12 gandhimarg
                                </street>
                                <city>
                                  belgaum
                                </city>
                                <prov-state>
                                  karnataka
                                </prov-state>
                              </addr>
                            </customerinfo>
                          '
                         preserve whitespace
                        )
                        according to XMLSCHEMA ID {$this->schema}CUSTOMER
                      )
        )
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $toPrintToScreen = "
-------- This statement is expected to fail --------
";
    $this->format_Output($toPrintToScreen);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1012);
    $this->commit();
  } //validate_XML_Document

  public function insert_where_Source_is_LOB()
  {

    $XMLDataString = file_get_contents("cust1023.xml");

    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM AN  INSERT WHERE SOURCE IS A CLOB VARIABLE.
";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1022);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  VALUES(
          1023,
          XMLPARSE(document cast(? as Clob) strip whitespace)
        )
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $stmt = db2_prepare($this->dbconn, $query);


    $toPrintToScreen = "
  Set parameter value: parameter 1 = clobData
";
    $this->format_Output($toPrintToScreen);

    db2_bind_param($stmt, 1, 'XMLDataString', DB2_PARAM_IN);

    $toPrintToScreen = "
  Execute prepared statement
";
    $this->format_Output($toPrintToScreen);


     if(db2_execute($stmt))
     {
       $this->format_Output("Succeeded!\n");
     }
     else
     {
        $this->format_Output(db2_stmt_errormsg() . "\n");
     }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1023);
    $this->commit();
  } // InsertwithValidationSourceisClob

  public function insert_From_String_Not_Well_Formed_XML()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  INSERT
TO PERFORM INSERT WITH NOT WELL FORMED XML
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}customer(cid,info)
  VALUES(
          1032,
          '
            <customerinfo Cid=\"1032\">
              <name>
                divya
              </name>
          '
        )
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $toPrintToScreen = "
-------- This statement is expected to fail --------
";
    $this->format_Output($toPrintToScreen);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1032);
    $this->commit();
  } //insert_From_String_Not_Well_Formed_XML

  // helping function
  public function pre_Requisites()
  {
    $toPrintToScreen = "
------------------------------------------------------------------------------
Preparing a table for use with this sample.

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TABLE {$this->schema}oldcustomer(
                ocid integer,
                firstname varchar(15),
                lastname varchar(15),
                addr varchar(300),
                information XML)
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

      // populate table oldcustomer with data
    $query = "
INSERT INTO {$this->schema}oldcustomer
  VALUES(
          1007,
          'Raghu',
          'nandan',
          '
            <addr country=\"india\">
              <state>
                karnataka
                <district>
                  bangalore
                </district>
              </state>
            </addr>
          ',
          XMLPARSE(document '
                              <oldcustomerinfo ocid=\"1007\">
                                <address country=\"india\" >
                                  <street>
                                    24 gulmarg
                                  </street>
                                  <city>
                                    bangalore
                                  </city>
                                  <state>
                                    karnataka
                                  </state>
                                </address>
                              </oldcustomerinfo>
                            '
                    preserve whitespace
                   )
        ),
        (
          1008,
          'Rama',
          'murthy',
          '
            <addr country=\"india\">
              <state>
                karnataka
                <district>
                  belgaum
                </district>
              </state>
            </addr>
          ',
          XMLPARSE(document '
                              <oldcustomerinfo ocid=\"1008\">
                                <address country=\"india\">
                                  <street>
                                    12 gandhimarg
                                  </street>
                                  <city>
                                    belgaum
                                  </city>
                                  <state>
                                    karnataka
                                  </state>
                                </address>
                              </oldcustomerinfo>
                            '
                    preserve whitespace
                  )
        ),
        (
          1009,
          'Rahul',
          'kumar',
          '
            <customerinfo Cid=\"1009\">
              <name>
                Rahul
              </name>
              <addr country=\"Canada\">
                <street>
                  25
                </street>
                <city>
                  Markham
                </city>
                <prov-state>
                  Ontario
                </prov-state>
                <pcode-zip>
                  N9C-3T6
                </pcode-zip>
              </addr>
              <phone type=\"work\">
                905-555-7258
              </phone>
            </customerinfo>
          ',
          XMLPARSE(document
                            '
                              <oldcustomerinfo ocid=\"1009\">
                                <address country=\"Canada\">
                                  <street>
                                    25 Westend
                                  </street>
                                  <city>
                                    Markham
                                  </city>
                                  <state>
                                    Ontario
                                  </state>
                                </address>
                              </oldcustomerinfo>
                            '
                    preserve whitespace
                  )
        ),
        (
          1010,
          'Sweta',
          'Priya',
          '
            <addr country=\"india\">
              <state>
                karnataka
                <district>
                  kolar
                </district>
              </state>
            </addr>
          ',
          XMLPARSE(document
                            '
                              <oldcustomerinfo ocid=\"1010\">
                                <address country=\"india\">
                                  <street>
                                    56 hillview
                                  </street>
                                  <city>
                                    kolar
                                  </city>
                                  <state>
                                    karnataka
                                  </state>
                                </address>
                              </oldcustomerinfo>
                            '
                    preserve whitespace
                  )
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
    $this->commit();
  } // PreRequisites

  // helping function
  public function customer_Tb_Content_Display($Cid)
  {
    $toPrintToScreen = "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Select the contains of CUSTOMER
WHERE
  CID = $Cid
Prepare Statement:
";
    $this->format_Output($toPrintToScreen);

      $query = "
SELECT CID,XMLSERIALIZE(info as varchar(600)) AS CXML
  FROM
    {$this->schema}customer
  WHERE
    cid = $Cid
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $DataFromTable = db2_exec($this->dbconn, $query);

      if($DataFromTable)
      {
        $toPrintToScreen = "
|CUSTOMERID:
|--------CUSTOMERINFO-------------
| XML
|_________________________________
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($CUSTOMER = db2_fetch_assoc($DataFromTable))
        {
           $this->format_Output(sprintf("
|CUSTOMERID: %s
|--------CUSTOMERINFO-------------
%s
|_________________________________",
                                            $CUSTOMER['CID'],
                                            $this->display_Xml_Parsed_Struct($CUSTOMER['CXML'], "|")
                                        )
                                );

        }
        $this->format_Output("\n|___________END___________________\n\n");
        db2_free_result($DataFromTable);
      }
      else
      {
      	$this->format_Output("No Data Returned\n\n");
        $this->format_Output(db2_stmt_errormsg());
      }
  } // CustomerTableContentDisplay


  public function delete_of_Row_with_Xml_Data()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
USE THE SQL STATEMENT:
  DELETE
TO PERFORM A DELETE OF ROW WITH XML DATA.
";
    $this->format_Output($toPrintToScreen);


    $query = "
DELETE FROM {$this->schema}customer
  WHERE cid >= 1006 and cid <= 1032
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
DROP TABLE {$this->schema}oldcustomer
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

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display(1007);
    $this->commit();
  } //delete_of_Row_with_Xml_Data
} //XmlInsert


$RunSample = new XmlInsert();
$RunSample->pre_Requisites();
$RunSample->most_Simple_Insert();
$RunSample->insert_From_Another_Xml_Column();
$RunSample->insert_From_Another_String_Column();
$RunSample->insert_where_Source_is_Xml_Function();
$RunSample->insert_where_Source_is_LOB();
$RunSample->insert_From_String_Not_Well_Formed_XML();
$RunSample->insert_where_Source_is_Typecast_To_XML();
$RunSample->insert_with_Validation_Sourceis_Varchar();
$RunSample->validate_XML_Document();
$RunSample->delete_of_Row_with_Xml_Data();


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
