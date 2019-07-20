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
 * SOURCE FILE NAME: XmlIndex_DB2.php
 *
 * SAMPLE: How to create an index on an XML column in different ways
 *
 * SQL Statements USED:
 *         SELECT
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class XmlIndex extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO CREATE INDEX ON XML COLUMNS IN DIFFERENT WAYS
';
";

  // When ever we go to create an index we are going to add it to this
  // variable so that later we know what Indexes need to be removed.
  public $IndexNumber = 0;
  public $IndexesToBeRemoved;

  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }

  // This function creates a table and inserts rows having
  // XML data
  public function createandInsertIntoTable()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Creating a Table for this sample and populating it with some data.
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TABLE company(id INT, docname VARCHAR(20), doc XML)
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
Insert row 1 into table
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO company
  VALUES(
      1,
      'doc1',
      xmlparse(document
          '
            <company name = \"Company1\">
              <emp
                id = \"31201\"
                salary = \"60000\"
                gender = \"Female\"
                DOB = \"10-10-80\"
              >
                  <name>
                    <first>
                      Laura
                    </first>
                    <last>
                      Brown
                    </last>
                  </name>
                  <dept id = \"M25\">
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
Insert row 2 into table
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO company
  VALUES(
      2,
      'doc2',
      xmlparse(document
          '
            <company name = \"Company2\">
              <emp
                id = \"31664\"
                salary = \"60000\"
                gender = \"Male\"
                DOB = \"09-12-75\"
              >
                <name>
                  <first>
                    Chris
                  </first>
                  <last>
                    Murphy
                  </last>
                </name>
                <dept id = \"M55\">
                  Marketing
                </dept>
              </emp>
              <emp
                id = \"42366\"
                salary = \"50000\"
                gender = \"Female\"
                DOB = \"08-21-70\"
              >
                <name>
                  <first>
                    Nicole
                  </first>
                  <last>
                    Murphy
                  </last>
                </name>
                <dept id = \"K55\">
                  Sales
                </dept>
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
  } // createandInsertIntoTable

  // This function creates an index and shows how we can use XQUERY on
  // the index created
  public function createIndex()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index on attribute
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName
ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/@*'
AS SQL VARCHAR(25)
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


    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/ emp[@id = '42366']
return \$i/name
");
    $this->commit();
  } // createIndex

  // This function creates an index with self or descendent forward
  // axis and shows how we can use XQUERY on the index
  public function createIndexwithSelf()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index with self or descendent forward axis
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '//@salary'
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp[@salary > 35000]
return <salary>{\$i/@salary}</salary>
");

    $this->commit();
  } // createIndexwithSelf

  // This function creates an index on a text mode and shows how to use
  // XQUERY on the index
  public function  createIndexonTextnode()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index on a text mode
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc) GENERATE KEY USING
XMLPATTERN '/company/emp/dept/text()' AS SQL VARCHAR(30)
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp[dept/text() = 'Finance' or dept/text() = 'Marketing']
return \$i/name
");

    $this->commit();
  } //createIndexonTextnode

  // This function creates an index when 2 paths are qualified by
  // an XML and also shows how to use XQUERY on the index
  public function createIndexwith2Paths()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index when 2 paths are qualified by an XML
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc) GENERATE KEY USING
 XMLPATTERN '//@id' AS SQL VARCHAR(25)
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp[@id = '31201']
return \$i/name
");

    $this->PrintWithThisQuery("
XQUERY for \$j in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp[dept/@id = 'K55']
return \$j/name
");

    $this->commit();
  } // createIndexwith2Paths

  // This function creates an index with namespace
  public function createIndexwithNamespace()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index with namespace
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc) GENERATE KEY USING
XMLPATTERN 'declare default element namespace
\"http://www.mycompany.com/\";declare namespace
m = \"http://www.mycompanyname.com/\";/company/emp/
@m:id' AS SQL VARCHAR(30)
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
  } // createIndexwithNamespace

  // This function creates an index with two different data types
  public function createIndexwith2Datatypes()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create indexes with same XMLPATTERN but with different data types
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/@id'
AS SQL VARCHAR(10)
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

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY  USING XMLPATTERN '/company/emp/@id'
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
  } // createIndexwith2Datatypes

  // This function creates an index using joins and shows how
  // to use XQUERY on the index created
  public function createIndexuseAnding()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index using joins (Anding)
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/name/last'
AS SQL VARCHAR(100)
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

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'DEPTINDEX';
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName on {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/dept/text()'
AS SQL VARCHAR(30)
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/ emp[name/last = 'Murphy' and dept/text() = 'Sales']
return \$i/name/last
");
    $this->commit();
  } // createIndexuseAnding

  // This function creates an index using joins (ANDing or ORing)
  // and shows how to use XQUERY on the index created
  public function createIndexuseAndingOrOring()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index using joins (Anding or Oring )
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/@salary'
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

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/dept'
AS SQL VARCHAR(25)
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

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/name/last'
AS SQL VARCHAR(25)
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp [@salary > 50000 and dept = 'Finance']
/name[last = 'Brown']
return \$i/last"
);

    $this->commit();
  } // createIndexuseAndingOrOring

  // This function creates an index with Date Data type and shows how
  // how to use an XQUERY on the index created
  public function createIndexwithDateDatatype()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index with Date Data type
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company/emp/@DOB'
as SQL DATE
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp[@DOB < '11-11-78']
return \$i/name
");

    $this->commit();
  } // createIndexwithDateDatatype

  // This function creates an index on the comment node and shows
  // how to use XQUERY on the index created
  public function createIndexOnCommentNode()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Create index on comment node
Execute Statement:
";
    $this->format_Output($toPrintToScreen);

    $this->IndexNumber++;
    $newIndexName = $this->schema . 'EMPINDEX' . $this->IndexNumber;
    $this->IndexesToBeRemoved[$this->IndexNumber] = $newIndexName;

    $query = "
CREATE INDEX $newIndexName ON {$this->schema}company(doc)
GENERATE KEY USING XMLPATTERN '/company//comment()'
AS SQL VARCHAR HASHED
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

    $this->PrintWithThisQuery("
XQUERY for \$i in db2-fn:xmlcolumn('{$this->schema}COMPANY.DOC')
/company/emp[comment() = ' good ']
return \$i/name
");

    $this->commit();
  } // createIndexOnCommentNode

  public function PrintWithThisQuery($query)
  {
     $toPrintToScreen = "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
Execute Query Statement:
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
      $this->format_Output("\n------------------RESULTS---------------------\n");
      while($AResult = db2_fetch_array($stmt))
      {
        $this->format_Output($this->display_Xml_Parsed_Struct($AResult[0]));
      }
      $this->format_Output("\n----------------RESULTS END-------------------\n");
      db2_free_stmt($stmt);
    }


  }

  // This function does all clean up work. It drops all the indexes
  // created and drops the table created
  public function dropall()
  {
     $toPrintToScreen = "
------------------------------------------------------------------------------
Drop all indexes
Statement:
DROP INDEX {Index Name}
";
    $this->format_Output($toPrintToScreen);

    foreach($this->IndexesToBeRemoved as $AnIndex)
    {
       if(db2_exec($this->dbconn, "DROP INDEX $AnIndex") !== false)
       {
         $this->format_Output("Index: $AnIndex has been dropped\n");
       }
       else
       {
         $this->format_Output("Index: $AnIndex WAS NOT dropped\n");
       }
    }


     $toPrintToScreen = "
------------------------------------------------------------------------------
Drop table
Prepare Statement:
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
  } // dropall
}


$RunSample = new XmlIndex();
//Different ways to create an index on XML columns
$RunSample->createandInsertIntoTable();
$RunSample->createIndex();
$RunSample->createIndexwithSelf();
$RunSample->createIndexonTextnode();
$RunSample->createIndexwith2Paths();
$RunSample->createIndexwithNamespace();
$RunSample->createIndexwith2Datatypes();
$RunSample->createIndexuseAnding();
$RunSample->createIndexuseAndingOrOring();
$RunSample->createIndexwithDateDatatype();
$RunSample->createIndexOnCommentNode();
$RunSample->dropall();


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
