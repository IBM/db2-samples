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
 * SOURCE FILE NAME: XmlUpAndDel.php
 *
 * SAMPLE: How to update and delete XML data from table
 *
 * SQL Statements USED:
 *         SELECT
 *
 * PREREQUISITE : copy the files cust1021.xml, cust1022.xml and cust1023.xml
 *                to the working directory before running the sample. These
 *                files can be found in the xml/data directory.                
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlUpDel extends DB2_Connection
{
  public $customerid  = 1008;
  public $customerCid = 1009;

  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO UPDATE AND DELETE XML TABLE DATA.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }


  public function most_Simple_Update_with_Constant_String()
  {

     $toPrintToScreen = "
----------------------------------------------

USE THE SQL STATEMENT:
  UPDATE
TO PERFORM A SIMPLE UPDATE.
";
    $this->format_Output($toPrintToScreen);

      // display the content of the 'customer' table
      $this->customer_Tb_Content_Display($this->customerid);

     $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);


    $query = "
UPDATE
    {$this->schema}customer
  SET
    info = XMLPARSE(document
              '
                <newcustomerinfo>
                  <name>
                    rohit
                    <street>
                      park street
                    </street>
                    <city>
                      delhi
                    </city>
                  </name>
                 </newcustomerinfo>
              ' preserve whitespace
            )
  WHERE
    cid = {$this->customerid}

";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }



    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } // most_Simple_Update_with_Constant_String

  public function update_where_Source_is_Another_Xml_Column()
  {

      //   System.out.println();
     $toPrintToScreen = "
----------------------------------------------------

USE THE SQL STATEMENT:\
  UPDATE\n
 TO PERFORM AN UPDATE WHERE SOURCE IS FROM ANOTHER XML COLUMN.
";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    info = (
              SELECT
                  information
                FROM
                  {$this->schema}oldcustomer1 p
                WHERE
                  p.ocid = {$this->customerCid}
            )
  WHERE
    cid={$this->customerid}
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } // update_where_Source_is_Another_Xml_Column

  public function update_where_Source_is_Another_String_Column()
  {
    $toPrintToScreen = "
-----------------------------------------------------

USE THE SQL STATEMENT:
  UPDATE
TO PERFORM AN UPDATE WHERE SOURCE IS FROM ANOTHER STRING COLUMN.
";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    info = (
              SELECT
                XMLPARSE(document addr preserve whitespace)
              FROM
                {$this->schema}oldcustomer1 p
              WHERE
                p.ocid={$this->customerCid}
           )
  WHERE
    cid={$this->customerid}
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } // update_where_Source_is_Another_String_Column

  public function update_Another_String_Column_With_Implicit_Parsing()
  {

     $toPrintToScreen = "
--------------------------------------------

 USE THE SQL STATEMENT:
  UPDATE
 TO PERFORM AN UPDATE WHERE SOURCE IS FROM ANOTHER STRING COLUMN
WITH IMPLICIT PARSING.

";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    info = (
              SELECT
                  addr
                FROM
                  {$this->schema}oldcustomer1 p
                WHERE
                  p.ocid={$this->customerCid}
           )
  WHERE
    cid = {$this->customerid}
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } //update_Another_String_Column_With_Implicit_Parsing

  public function update_Using_Varchar_With_Implicit_Parsing()
  {

     $toPrintToScreen = "
----------------------------------------------------------

USE THE SQL STATEMENT:
  UPDATE
TO PERFORM A UPDATE USING VARCHAR WITH IMPLICIT PARSING.
";
    $this->format_Output($toPrintToScreen);

      // display the content of the 'customer' table
      // customer_Tb_Content_Display(1008);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);


    $query = "
UPDATE
    {$this->schema}customer
  SET info ='
              <newcustomerinfo>
                <name>
                  rohit
                  <street>
                    park street
                  </street>
                  <city>
                    delhi
                  </city>
                </name>
              </newcustomerinfo>
            '
  WHERE
    cid = {$this->customerid}
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } //update_Using_Varchar_With_Implicit_Parsing

  public function update_where_Source_is_Blob_With_Implicit_Parsing()
  {

      $xsdData = $this->return_File_Values("cust1021.xml");


     $toPrintToScreen = "
-------------------------------------------------

USE THE SQL STATEMENT:
  UPDATE\n
TO PERFORM AN  UPDATE WHERE SOURCE IS A BLOB VARIABLE
 WITH IMPLICIT PARSING
";
    $this->format_Output($toPrintToScreen);

      // display the content of the 'customer' table
      //customer_Tb_Content_Display(1008);

     $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    INFO = cast(? as Blob)
  WHERE
    cid = {$this->customerid}
";
    $stmt = db2_prepare($this->dbconn, $query);

    if(db2_execute($stmt, array('1'=>$xsdData)))
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    db2_free_stmt($stmt);
    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } //update_where_Source_is_Blob_With_Implicit_Parsing

  public function UpdatewithValidation()
  {


     $toPrintToScreen = "
-----------------------------------------------
 USE THE SQL STATEMENT:
 UPDATE
 TO PERFORM AN UPDATE WITH VALIDATION WHERE
 SOURCE IS TYPED OF VARCHAR.
";
    $this->format_Output($toPrintToScreen);

      //  display the content of the 'customer' table
      $this->customer_Tb_Content_Display($this->customerid);

     $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    info = (
              SELECT
                  XMLVALIDATE(
                      XMLPARSE(document addr preserve whitespace)
                      according to XMLSCHEMA ID customer
                    )
                FROM
                  {$this->schema}oldcustomer1 p
                WHERE
                  p.ocid={$this->customerCid}
           )
  WHERE
    cid = {$this->customerid}
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

      // display the content of the 'customer' table
      $this->customer_Tb_Content_Display($this->customerid);

  } // UpdatewithValidation

  public function update_where_Source_is_Blob()
  {
      $xsdData = $this->return_File_Values("cust1022.xml");

     $toPrintToScreen = "
------------------------------------------------

USE THE SQL STATEMENT:
  UPDATE
TO PERFORM AN  UPDATE WHERE SOURCE IS A BLOB VARIABLE.
";
    $this->format_Output($toPrintToScreen);

      // display the content of the 'customer' table
      $this->customer_Tb_Content_Display($this->customerid);

     $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    INFO = XMLPARSE(document cast(? as Blob) strip whitespace)
  WHERE
    cid=$this->customerid

";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $stmt = db2_prepare($this->dbconn, $query);

    if(db2_execute($stmt, array('1'=>$xsdData)))
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    db2_free_stmt($stmt);

      // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } // update_where_Source_is_Blob

  public function update_where_Source_is_Clob()
  {

    $xsdData = $this->return_File_Values("cust1023.xml");


    $toPrintToScreen = "
------------------------------------------------

USE THE SQL STATEMENT:
  UPDATE
TO PERFORM AN  UPDATE WHERE SOURCE IS A CLOB VARIABLE.
";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE
    {$this->schema}customer
  SET
    INFO=XMLPARSE(document cast(? as Clob) strip whitespace)
  WHERE
    cid = {$this->customerid}
";

     $toPrintToScreen = "
  Set parameter value: parameter 1 = clobData
";
    $this->format_Output($toPrintToScreen);

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $stmt = db2_prepare($this->dbconn, $query);

    if(db2_execute($stmt, array('1'=>$xsdData)))
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    db2_free_stmt($stmt);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } // update_where_Source_is_Clob

  // helping function
  public function pre_Requisites()
  {

    // create table 'oldcustomer1'
    $query = "
CREATE TABLE {$this->schema}oldcustomer1(
                          ocid        integer,
                          firstname   varchar(15),
                          lastname    varchar(15),
                          addr        varchar(300),
                          information XML
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
    // populate table oldcustomer1 with data
    $query = "
INSERT INTO {$this->schema}oldcustomer1
             VALUES({$this->customerCid},
                    'Rahul',
                    'kumar',
                    '<customerinfo Cid=\"{$this->customerCid}\">
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
                     </customerinfo>',
                    XMLPARSE(document '<oldcustomer1info ocid=\"{$this->customerCid}\">
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
                                       </oldcustomer1info>'
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
      $this->rollback();
      return false;
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }

    // populate table customer with data
    $query = "
INSERT INTO {$this->schema}customer(cid,info)
     VALUES( {$this->customerid},
             XMLPARSE(document
                  '
                    <customerinfo Cid=\"{$this->customerid}\">
                      <name>
                        divya
                      </name>
                    </customerinfo>
                  ' preserve whitespace
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
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    // Commit
    $this->commit();

  } // PreRequisites

  // helping function
  public function customer_Tb_Content_Display($Cid)
  {
      // prepare the query
     $toPrintToScreen = "
  Prepare Statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    CID,
    XMLSERIALIZE(info as varchar(600))
  FROM
    {$this->schema}customer
  WHERE
    cid = ?
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $toPrintToScreen = "

  Set parameter value: parameter 1 = $Cid

";
    $this->format_Output($toPrintToScreen);
    // Execute the query
    $DataFromTable = db2_prepare($this->dbconn, $query);

    if(db2_execute($DataFromTable, array('1'=>$Cid)))
    {
        // retrieve and display the result from the xquery
        while($Employee = db2_fetch_array($DataFromTable))
        {
           $this->format_Output(sprintf("CUSTOMERID: %15s \nCUSTOMERINFO\n %s \n",
                                            $Employee[0],
                                            $this->display_Xml_Parsed_Struct($Employee[1])
                                        )
                                );

        }
        db2_free_result($DataFromTable);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // CustomerTableContentDisplay


  // this function will Read a file in a buffer and
  // return the String value to cal
  public function return_File_Values($fileName)
  {
    $FileContence  = file_get_contents($fileName, "r");
    if($FileContence === false)
    {
      $toPrintToScreen = "
    FILE OPEN FAILD!
";
      $this->format_Output($toPrintToScreen);
      return null;
    }
    return $FileContence;
  }// return_File_Values

  public function delete_of_Row_with_Xml_Data()
  {
     $toPrintToScreen = "
-------------------------------------------------

USE THE SQL STATEMENT:
  DELETE
TO PERFORM A DELETION OF ROWS WITH XML DATA.
";
    $this->format_Output($toPrintToScreen);

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

    $toPrintToScreen = "
  Perform:
";
    $this->format_Output($toPrintToScreen);

    $query = "
DELETE
  FROM
    {$this->schema}customer
  WHERE
    cid = {$this->customerid}

";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

    // display the content of the 'customer' table
    $this->customer_Tb_Content_Display($this->customerid);

  } // delete_of_Row_with_Xml_Data

  public function cleanup_Pre_Requisites()
  {
    $query = "
DROP
  TABLE
    {$this->schema}oldcustomer1
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
      $this->rollback();
      return false;
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }

      // Commit
    $this->commit();
  } // rollbackChanges
}


$Run_Sample = new XmlUpDel();

$Run_Sample->pre_Requisites();

$Run_Sample->most_Simple_Update_with_Constant_String();
$Run_Sample->update_where_Source_is_Another_Xml_Column();
$Run_Sample->update_where_Source_is_Another_String_Column();
$Run_Sample->update_Another_String_Column_With_Implicit_Parsing();
$Run_Sample->update_Using_Varchar_With_Implicit_Parsing();
$Run_Sample->update_where_Source_is_Blob_With_Implicit_Parsing();
$Run_Sample->update_where_Source_is_Blob();
$Run_Sample->update_where_Source_is_Clob();
$Run_Sample->delete_of_Row_with_Xml_Data();

$Run_Sample->cleanup_Pre_Requisites();


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
