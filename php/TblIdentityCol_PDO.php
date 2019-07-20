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
 * SOURCE FILE NAME: TblIdentityCol_PDO.php
 *
 * SAMPLE: How to use Identity Columns
 *
 * SQL Statements USED:
 *         CREATE TABLE
 *         INSERT
 *         SELECT
 *         DROP
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_PDO.php";

class IdentityColumns extends PDO_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO USE IDENTITY COLUMNS
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }


  public function generate_Always()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENT:
  CREATE TABLE
  INSERT
TO CREATE AN IDENTITY COLUMN WITH VALUE 'GENERATED ALWAYS'
AND TO INSERT DATA IN THE TABLE
";
    $this->format_Output($toPrintToScreen);


    $query = "
CREATE TABLE {$this->schema}building(bldnum INT GENERATED ALWAYS
  AS IDENTITY(START WITH 1, INCREMENT BY 1),
                       addr VARCHAR(20),
                       city VARCHAR(10),
                       floors SMALLINT,
                       employees SMALLINT)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $this->PDOconn->exec($query);
    if(strcmp($this->PDOconn->errorCode(), "00000"))
    {
      $stmtError = $InsertNewEmployee_stmt->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }


    $toPrintToScreen = "
Insert data into the table 'building'
";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}building(bldnum, addr, city, floors, employees)
         VALUES(DEFAULT, '110 Woodpart St', 'Smithville',  3, 10),
               (DEFAULT, '123 Sesame Ave' , 'Jonestown' , 16, 13),
               (DEFAULT, '738 Eglinton Rd', 'Whosburg'  ,  2, 10),
               (DEFAULT, '832 Lesley Blvd', 'Centertown',  2, 18)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $this->PDOconn->exec($query);
    if(strcmp($this->PDOconn->errorCode(), "00000"))
    {
      $stmtError = $InsertNewEmployee_stmt->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }


    $query = "
  SELECT BLDNUM, ADDR, CITY, FLOORS, EMPLOYEES FROM {$this->schema}building
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    // Execute the query
    $DataFromTabledept = $this->PDOconn->query($query);
    $toPrintToScreen = "
| ID   | ADDRESS              | CITY       | FLOORS |EMP
|------|----------------------|------------|--------|---------------
";
    $this->format_Output($toPrintToScreen);
    if($DataFromTabledept)
    {
      // retrieve and display the result from the xquery
      while($Dept = $DataFromTabledept->fetch(PDO::FETCH_ASSOC))
      {
         $this->format_Output(sprintf("| %4s | %20s | %10s | %6s | %s \n",
                                          $Dept['BLDNUM'],
                                          $Dept['ADDR'],
                                          $Dept['CITY'],
                                          $Dept['FLOORS'],
                                          $Dept['EMPLOYEES']
                                      )
                              );

      }

    }
    else
    {
      $stmtError = $DataFromTableCompanyA->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }

    $toPrintToScreen = "
Dropping the table 'building
";
    $this->format_Output($toPrintToScreen);

    $query = "
 DROP TABLE {$this->schema}building
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $this->PDOconn->exec($query);
    if(strcmp($this->PDOconn->errorCode(), "00000"))
    {
      $stmtError = $InsertNewEmployee_stmt->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }


    $this->commit();
  }  // generatedAlways

  public function generate_By_Default()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENT:
  CREATE TABLE
  INSERT
TO CREATE AN IDENTITY COLUMN WITH VALUE 'GENERATED BY DEFAULT'
 AND TO INSERT DATA IN THE TABLE
";
    $this->format_Output($toPrintToScreen);


    $query = "
CREATE TABLE {$this->schema}warehouse(whnum INT GENERATED BY DEFAULT
  AS IDENTITY(START WITH 1, INCREMENT BY 1),
                        addr VARCHAR(20),
                        city VARCHAR(10),
                        capacity SMALLINT,
                        employees SMALLINT)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $this->PDOconn->exec($query);
    if(strcmp($this->PDOconn->errorCode(), "00000"))
    {
      $stmtError = $InsertNewEmployee_stmt->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }


    $toPrintToScreen = "
Insert data into the table 'warehouse'
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}warehouse(whnum, addr, city, capacity, employees)
               VALUES(DEFAULT, '92 Bothfield Dr' , 'Yorkvile'  ,  23, 100),
                     (DEFAULT, '33 Giant Road'   , 'Centertown', 100,  22),
                     (      3, '8200 Warden Blvd', 'Smithville', 254,  10),
                     (DEFAULT, '53 4th Ave'      , 'Whosburg'  ,  97,  28)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $this->PDOconn->exec($query);
    if(strcmp($this->PDOconn->errorCode(), "00000"))
    {
      $stmtError = $InsertNewEmployee_stmt->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }


    $query = "
  SELECT WHNUM, ADDR, CITY, CAPACITY, EMPLOYEES FROM {$this->schema}warehouse
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    // Execute the query
    $DataFromTabledept = $this->PDOconn->query($query);
    $toPrintToScreen = "
| ID   | ADDRESS              | CITY       | CAPACITY |EMP
|------|----------------------|------------|----------|---------------
";
    $this->format_Output($toPrintToScreen);
    if($DataFromTabledept)
    {
      // retrieve and display the result from the xquery
      while($Dept = $DataFromTabledept->fetch(PDO::FETCH_ASSOC))
      {
         $this->format_Output(sprintf("| %4s | %20s | %10s | %8s | %s \n",
                                          $Dept['WHNUM'],
                                          $Dept['ADDR'],
                                          $Dept['CITY'],
                                          $Dept['CAPACITY'],
                                          $Dept['EMPLOYEES']
                                      )
                              );

      }
      $toPrintToScreen = "
NOTE:
  Defining an Identity on a Column dose not imply a unique value
  for each row! To ensure a unique value for each row,
  define an unique index or primary key on the Column
";
      $this->format_Output($toPrintToScreen);

    }
    else
    {
      $stmtError = $DataFromTableCompanyA->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }



    $toPrintToScreen = "
  Dropping the table 'warehouse'
";
    $this->format_Output($toPrintToScreen);

    $query = "
    DROP TABLE warehouse
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    $this->PDOconn->exec($query);
    if(strcmp($this->PDOconn->errorCode(), "00000"))
    {
      $stmtError = $InsertNewEmployee_stmt->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }
    else
    {
      $this->format_Output("Succeeded \n");
    }


    $this->commit();
  }  //generatedByDefault
}


$Run_Sample = new IdentityColumns();
$Run_Sample->generate_Always();
$Run_Sample->generate_By_Default();


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
