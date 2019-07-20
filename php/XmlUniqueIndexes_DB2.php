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
 * SOURCE FILE NAME: XmlUniqueIndexs_DB2.php
 *
 * SAMPLE: How to create UNIQUE index on XML columns
 *
 * SQL Statements USED:
 *         SELECT
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlConst extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO CREATE UNIQUE INDEX.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }

  public function create_Index_Constraint_Unique()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Here we will create an unique index on the table {$this->schema}COMPANY
  in the XML document at '/company/emp/@id' and set it as a SQL VARCHAR
  of length 8

When we try to insert the rows you will find that Row 2 will fail because it
  contain values in '/company/emp/@id’ that is identical to Row 1 which has
  already been inserted.

";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE UNIQUE INDEX {$this->schema}empindex on {$this->schema}company(COMP_DOC)
  GENERATE KEY USING XMLPATTERN '/company/emp/@id'
  AS SQL VARCHAR(8)
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
  }

  public function create_Index_Constraint_Double()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Here we will create an index on the table {$this->schema}COMPANY
  in the XML document at '/company/emp/@id' and set it as a SQL DOUBLE

When an index is created within an XML column for the data types DOUBLE, DATE,
  and TIMESTAMP it dose not place a constraint on the rows being inserted.

If the identified value which is to be used in an index in a row
  dose not conform to the expected data type.

The row is inserted into the table and not indexed.

No errors are raised or given.

When we try to insert the rows, Rows 1, 2 and 4 will succeed but will not be
  indexed because they do not contain values in '/company/emp/@id’
  that are numbers.

";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE UNIQUE INDEX {$this->schema}empindex on {$this->schema}company(COMP_DOC)
  GENERATE KEY USING XMLPATTERN '/company/emp/@id'
  AS SQL DOUBLE
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
  }

  public function create_Index_Constraint_Max_Length()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Here we will create an index on the table {$this->schema}COMPANY
  in the XML document at '/company/emp/@id' and set it as a SQL VARCHAR
   with a length of 4

When we try to insert the rows you will find that Rows 1 and 2 will
  fail because they both contain values in '/company/emp/@id’ that have
  a length greater then 4.

";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE UNIQUE INDEX {$this->schema}empindex on {$this->schema}company(COMP_DOC)
  GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(4)
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
  }

  public function create_Index_Constraint_Max_Length_With_Data()
  {

     $toPrintToScreen = "
------------------------------------------------------------------------------
We are going to try to create an index on the table {$this->schema}.COMPANY
  that already has rows present.

When we try to create the index with a varchar constraint it will fail
  because the length of Rows 1 and 2 are greater then the max length
  that we specified of 4

";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE UNIQUE INDEX {$this->schema}empindex on {$this->schema}company(COMP_DOC)
  GENERATE KEY USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(4)
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If we then delete Rows 1 and 2 so that there are no rows
  that conflate with the constraint we are trying to insert,
  it will succeed.

";
    $this->format_Output($toPrintToScreen);

    $this->remove_Row(1);
    $this->remove_Row(2);

     $toPrintToScreen = "

Trying to create the index again:
";
    $this->format_Output($toPrintToScreen);

    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    $this->commit();
  }

  public function try_To_Insert_Rows()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Trying to Insert 4 rows in to the table {$this->schema}COMPANY

";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "
Trying to insert row 1 into the table
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}company
  values( 1,
          'doc1',
          xmlparse(document '
                  <company name=\"Company1\">
                     <emp
                        id=\"3120A\"
                        salary=\"60000\"
                        gender=\"Female\"
                        DOB=\"10-10-80\"
                      >
                         <name>
                           <first>
                              Laura
                           </first>
                           <last>
                              Brown
                           </last>
                         </name>
                         <dept id=\"M25\">
                              Finance
                         </dept>
                         <!-- good -->
                      </emp>
                  </company>
                 '
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

     $toPrintToScreen = "
Trying to insert row 2 into the table
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}company
  values( 2,
          'doc1',
          xmlparse(document '
                  <company name=\"Company1\">
                     <emp
                        id=\"3120A\"
                        salary=\"60000\"
                        gender=\"Female\"
                        DOB=\"10-10-80\"
                      >
                         <name>
                           <first>
                              Laura
                           </first>
                           <last>
                              Brown
                           </last>
                         </name>
                         <dept id=\"M25\">
                              Finance
                         </dept>
                         <!-- good -->
                      </emp>
                  </company>
                 '
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

     $toPrintToScreen = "
Trying to insert row 3 into the table
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}company
  values( 3,
          'doc1',
          xmlparse(document '
                  <company name=\"Company1\">
                     <emp
                        id=\"312\"
                        salary=\"60000\"
                        gender=\"Female\"
                        DOB=\"10-10-80\"
                      >
                         <name>
                           <first>
                              Laura
                           </first>
                           <last>
                              Brown
                           </last>
                         </name>
                         <dept id=\"M25\">
                              Finance
                         </dept>
                         <!-- good -->
                      </emp>
                  </company>
                 '
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

     $toPrintToScreen = "
Trying to insert row 4 into the table
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}company
  values( 4,
          'doc1',
          xmlparse(document '
                  <company name=\"Company1\">
                     <emp
                        id=\"ABC\"
                        salary=\"60000\"
                        gender=\"Female\"
                        DOB=\"10-10-80\"
                      >
                         <name>
                           <first>
                              Laura
                           </first>
                           <last>
                              Brown
                           </last>
                         </name>
                         <dept id=\"M25\">
                              Finance
                         </dept>
                         <!-- good -->
                      </emp>
                  </company>
                 '
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
  }

  public function create_Table()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create a table for this sample to work from
";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}COMPANY(
                    COMP_ID INT,
                    COMP_DOCNAME VARCHAR(20),
                    COMP_DOC XML
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
  }

  public function clean_Table()
  {

     $toPrintToScreen = "
------------------------------------------------------------------------------
Drop index and Deleting all items in the table
";
    $this->format_Output($toPrintToScreen);
    $query = "
DROP INDEX {$this->schema}EMPINDEX
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
DELETE FROM {$this->schema}COMPANY
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
  }

  public function remove_Row($COMP_ID)
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Deleting COMP_ID: $COMP_ID in table {$this->schema}COMPANY
";
     $query = "
DELETE FROM {$this->schema}COMPANY WHERE COMP_ID = $COMP_ID
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
  }

  public function drop_Table()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Droping the Table:
";
    $this->format_Output($toPrintToScreen);
    $query = "
DROP TABLE {$this->schema}COMPANY
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
  }
}

$RunSample = new XmlConst();
$RunSample->create_Table();

$RunSample->create_Index_Constraint_Unique();
$RunSample->try_To_Insert_Rows();
$RunSample->clean_Table();

$RunSample->create_Index_Constraint_Double();
$RunSample->try_To_Insert_Rows();
$RunSample->clean_Table();

$RunSample->create_Index_Constraint_Max_Length();
$RunSample->try_To_Insert_Rows();
$RunSample->clean_Table();

$RunSample->try_To_Insert_Rows();
$RunSample->create_Index_Constraint_Max_Length_With_Data();
$RunSample->clean_Table();

$RunSample->drop_Table();


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
