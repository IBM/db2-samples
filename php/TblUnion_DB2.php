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
 * SOURCE FILE NAME: TblUnion_DB2.php
 *
 * SAMPLE: How to insert through a UNION ALL view
 *
 * SQL Statements USED:
 *         SELECT
 *         CREATE TABLE
 *         ALTER TABLE
 *         DROP TABLE
 *         CREATE VIEW
 *         DROP VIEW
 *         INSERT
 *         DELETE
 *         UPDATE
 *
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";

class Union extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO INSERT THROUGH A \"UNION ALL\" VIEW.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }


  // This method create tables Q1, Q2, Q3 and Q4 and adds constraints
  // to them. It also creates a view FY which is a view over the full year.
  public function create_Tables_And_View()
  {
    /********************************************************************/
     $toPrintToScreen = "
CREATE TABLES Q1,Q2,Q3 AND Q4 BY INVOKING
  THE STATEMENTS:

";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}Q1(product_no INT, sales INT, date DATE)
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
CREATE TABLE {$this->schema}Q2 LIKE {$this->schema}Q1
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
CREATE TABLE {$this->schema}Q3 LIKE {$this->schema}Q1
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
CREATE TABLE {$this->schema}Q4 LIKE {$this->schema}Q1
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
    /********************************************************************/

    /********************************************************************/
     $toPrintToScreen = "
ADD CONSTRAINTS TO TABLES Q1, Q2, Q3 AND Q4 BY INVOKING
  THE STATEMENTS:

";
    $this->format_Output($toPrintToScreen);
    $query = "
ALTER TABLE {$this->schema}Q1 ADD CONSTRAINT Q1_CHK_DATE
    CHECK (MONTH(date) IN (1, 2, 3))
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
ALTER TABLE {$this->schema}Q2 ADD CONSTRAINT Q2_CHK_DATE
    CHECK (MONTH(date) IN (4, 5, 6))
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
ALTER TABLE {$this->schema}Q3 ADD CONSTRAINT Q3_CHK_DATE
    CHECK (MONTH(date) IN (7, 8, 9))
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
ALTER TABLE {$this->schema}Q4 ADD CONSTRAINT Q4_CHK_DATE
    CHECK (MONTH(date) IN (10, 11, 12))
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
    /********************************************************************/

    /********************************************************************/
     $toPrintToScreen = "
CREATE A VIEW 'FY' BY INVOKING THE STATEMENT:
    CREATE VIEW FY AS

";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE VIEW {$this->schema}FY AS
  SELECT product_no, sales, date FROM {$this->schema}Q1
  UNION ALL
  SELECT product_no, sales, date FROM {$this->schema}Q2
  UNION ALL
  SELECT product_no, sales, date FROM {$this->schema}Q3
  UNION ALL
  SELECT product_no, sales, date FROM {$this->schema}Q4
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
    /********************************************************************/
    $this->commit();
  }

  // This method inserts some values directly into tables Q1, Q2, Q3 and Q4
  public function insert_Initial_Values_In_Tables()
  {
    /********************************************************************/
     $toPrintToScreen = "
INSERT INITIAL VALUES INTO TABLES Q1, Q2, Q3, Q4 BY INVOKING
  THE STATEMENTS:

";
    $this->format_Output($toPrintToScreen);

    // Insert initial values into tables Q1, Q2, Q3 and Q4

    $query = "
INSERT INTO {$this->schema}Q1
               VALUES (5, 6, '2001-01-02'),
                      (8, 100, '2001-02-28')
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
INSERT INTO {$this->schema}Q2
               VALUES (3,  10, '2001-04-11'),
                      (5,  15, '2001-05-19')
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
INSERT INTO {$this->schema}Q3 VALUES (1,  12, '2001-08-27')
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
INSERT INTO {$this->schema}Q4
               VALUES (3,  14, '2001-12-29'),
                      (2,  21, '2001-12-12')
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
    /********************************************************************/
    $this->commit();
  }

  // This method drops tables Q1, Q2, Q3 and Q4 and the view FY
  public function drop_Tables_And_View()
  {
    /********************************************************************/
     $toPrintToScreen = "
DROP TABLES Q1,Q2,Q3,Q4 AND VIEW FY BY INVOKING
  THE STATEMENTS:

";
    $this->format_Output($toPrintToScreen);

    // Insert initial values into tables Q1, Q2, Q3 and Q4

    $query = "
DROP TABLE {$this->schema}Q1
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
DROP TABLE {$this->schema}Q2
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
DROP TABLE {$this->schema}Q3
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
DROP TABLE {$this->schema}Q4
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
    /********************************************************************/
    $this->commit();

  }

  // Helper method: This method displays the results of the query
  // specified by 'querystr'
  public function DisplayData($query)
  {
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
    $DataFromTableCompanyA = db2_exec($this->dbconn, $query);

    if($DataFromTableCompanyA)
    {
      $toPrintToScreen = "
| PRODUCT_NO           | SALES      | DATE                           |
|----------------------|------------|--------------------------------|
";
      $this->format_Output($toPrintToScreen);
      // retrieve and display the result from the xquery
      while($Employee = db2_fetch_assoc($DataFromTableCompanyA))
      {
         $this->format_Output(sprintf("| %20s | %10s | %30s |\n",
                                          $Employee['PRODUCT_NO'],
                                          $Employee['SALES'],
                                          $Employee['DATE']
                                      )
                              );

      }
      db2_free_result($DataFromTableCompanyA);
    }
    else
    {
      $this->format_Output(db2_stmt_errormsg());
    }
  }

  // This method demonstrates how to insert through a UNION ALL view
  public function insert_Using_Union_All()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENT:
    INSERT
TO INSERT DATA THROUGH THE 'UNION ALL' VIEW.

  CONTENTS OF THE VIEW 'FY' BEFORE INSERTING DATA:
";
    $this->format_Output($toPrintToScreen);

    // Display the initial content of the view FY before inserting new
    // rows
    $this->DisplayData("\n SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}FY ORDER BY date, product_no \n");

    // INSERT data into tables Q1, Q2, Q3 and Q4 through the
    // UNION ALL view FY

    $toPrintToScreen = "
INSERT DATA THROUGH THE 'UNION ALL' VIEW
 BY INVOKING THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}FY
              VALUES (1, 20, '2001-06-03'),
                     (2, 30, '2001-03-21'),
                     (2, 25, '2001-08-30')
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

    // Display the final content of all tables
    $toPrintToScreen = "
CONTENTS OF THE TABLES Q1, Q2, Q3, AND Q4 AFTER INSERTING DATA:
";
    $this->format_Output($toPrintToScreen);

    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q1 ORDER BY date, product_no");
    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q2 ORDER BY date, product_no");
    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q3 ORDER BY date, product_no");
    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q4 ORDER BY date, product_no");

    $this->rollback();

  }

  // This method modifies the constraints of table Q1
  public function new_Constraints()
  {
    $toPrintToScreen = "
CHANGE THE CONSTRAINTS OF TABLE 'Q1' BY
 INVOKING THE STATEMENTS:
";
    $this->format_Output($toPrintToScreen);


    // Drop the constraint Q1_CHK_DATE and add a new one
    $query = "
DELETE FROM {$this->schema}FY
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
ALTER TABLE {$this->schema}Q1 DROP CONSTRAINT Q1_CHK_DATE
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
ALTER TABLE {$this->schema}Q1 ADD CONSTRAINT Q1_CHK_DATE
  CHECK (MONTH(date) IN (4, 2, 3))
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

  // This method attempts to insert data through a UNION ALL view where no
  // table accepts the row
  public function insert_When_No_Table_Accepts_It()
  {
   $toPrintToScreen = "
----------------------------------------------------------
  USE THE SQL STATEMENT:
    INSERT

  TO ATTEMPT TO INSERT DATA THROUGH A 'UNION ALL' VIEW WHERE
  NO TABLE ACCEPTS THE ROW

  NO TABLE ACCEPTS A ROW WITH 'MONTH' = 1.
  AN ATTEMPT TO INSERT A ROW WITH
  'MONTH' = 1, WOULD CAUSE A 'NO TARGET' ERROR TO BE RAISED

  ATTEMPT TO INSERT A ROW WITH 'MONTH' = 1
  BY INVOKING THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);


    // Attempt to insert a row with 'MONTH' = 1 which no table will accept
    $query = "
INSERT INTO {$this->schema}FY VALUES (5, 35, '2001-01-14')
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
     // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    $this->rollback();
  }

  // This method attempts to insert data through a UNION ALL view where more
  // than one table accepts the row
  public function insert_When_More_Than_One_Table_Accepts_It()
  {
   $toPrintToScreen = "
----------------------------------------------------------
  USE THE SQL STATEMENT:
    INSERT

  TO ATTEMPT TO INSERT DATA THROUGH A 'UNION ALL' VIEW WHERE
  MORE THAN ONE TABLE ACCEPTS THE ROW

  BOTH TABLES Q1 AND Q2 ACCEPT A ROW WITH 'MONTH' = 4. AN ATTEMPT TO
  INSERT A ROW WITH 'MONTH' = 4, WOULD CAUSE AN 'AMBIGUOUS TARGET' ERROR
  TO BE RAISED

  ATTEMPT TO INSERT A ROW WITH 'MONTH' = 4
  BY INVOKING THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);


    // Attempt to insert a row with 'MONTH' = 1 which no table will accept
    $query = "
INSERT INTO {$this->schema}FY VALUES (3, 30, '2001-04-21')
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
    // Execute the query
    if(db2_exec($this->dbconn, $query) === false)
    {
      $this->format_Output(db2_stmt_errormsg() . "\n");
    }
    else
    {
        $this->format_Output("Succeeded \n");
    }
    $this->rollback();
  }

  // This function creates a new view.  The new view has the WITH ROW
  // MIGRATION clause in it, which enables row migration.  It performs some
  // updates through this view to show how row migration affects the
  // underlying tables.
  public function update_With_Row_Movement()
  {
   $toPrintToScreen = "
CREATE A VIEW 'vfullyear' BY INVOKING THE STATEMENT:
    CREATE VIEW vfullyear AS
";
    $this->format_Output($toPrintToScreen);

    // Create the view vfullyear, this is the same as view FY with the
    // exception that it has the WITH ROW MOVEMENT clause.  This additional
    // clause allows updates through the view to move rows across the underlying
    // tables (row migration) as necessary.
    $query = "
CREATE VIEW {$this->schema}vfullyear AS
  SELECT product_no, sales, date FROM {$this->schema}Q1
  UNION ALL
  SELECT product_no, sales, date FROM {$this->schema}Q2
  UNION ALL
  SELECT product_no, sales, date FROM {$this->schema}Q3
  UNION ALL
  SELECT product_no, sales, date FROM {$this->schema}Q4
  WITH ROW MOVEMENT
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
CONTENTS OF THE TABLES Q1 AND Q2 BEFORE ROW MOVEMENT OCCURS
";
    $this->format_Output($toPrintToScreen);

    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q1");
    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q2");

    $toPrintToScreen = "
UPDATE VALUES IN VIEW vfullyear BY INVOKING
  THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);
      // Demonstrate row movement by executing the following UPDATE statement.
      // This statement causes a row to move from table Q1 to table Q2.
    $query = "
UPDATE {$this->schema}vfullyear SET date = date + 2 MONTHS
                 WHERE date='2001-02-28'
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
CONTENTS OF THE TABLES Q1 AND Q2 AFTER ROW MOVEMENT OCCURS
";
    $this->format_Output($toPrintToScreen);

    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q1");
    $this->DisplayData("SELECT PRODUCT_NO, SALES, DATE FROM {$this->schema}Q2");

    $toPrintToScreen = "
DROP THE VIEW vfullyear BY INVOKING
  THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);

    $query = "
DROP VIEW {$this->schema}vfullyear
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

  } // update_With_Row_Movement

  // This function creates three new tables and one new view.  It performs some
  // updates through the view to show two special cases of row migration.
  public function update_With_Row_Movement_Special_Case()
  {
   $toPrintToScreen = "
CREATE TABLES T1,T2 AND T3 BY INVOKING
  THE STATEMENTS:
";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TABLE {$this->schema}T1(name CHAR, grade INT)
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
CREATE TABLE {$this->schema}T2 LIKE {$this->schema}T1
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
CREATE TABLE {$this->schema}T3 LIKE {$this->schema}T1
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
INSERT INITIAL VALUES INTO TABLES T1, T2, T3 BY INVOKING
  THE STATEMENTS:
";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}T1 VALUES ('a', 40), ('b', 55)
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
INSERT INTO {$this->schema}T2 VALUES ('c', 50), ('d', 75)
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
INSERT INTO {$this->schema}T3 VALUES ('d', 90), ('e', 95)
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
ADD CONSTRAINTS TO TABLES T1, T2 AND T3 BY INVOKING
  THE STATEMENTS:
";
    $this->format_Output($toPrintToScreen);

    $query = "
ALTER TABLE {$this->schema}T1 ADD CONSTRAINT T1_CHK_GRADE
 CHECK (grade >= 0 AND grade <= 55)
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
ALTER TABLE {$this->schema}T2 ADD CONSTRAINT T2_CHK_GRADE
 CHECK (grade >= 50 AND grade <= 100)
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
ALTER TABLE {$this->schema}T3 ADD CONSTRAINT T3_CHK_GRADE
 CHECK (grade >= 90 AND grade <= 100)
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
CREATE A VIEW 'vmarks' BY INVOKING THE STATEMENT:
    CREATE VIEW vmarks AS
";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE VIEW {$this->schema}vmarks AS
  SELECT name, grade FROM {$this->schema}T1
  UNION ALL
  SELECT name, grade FROM {$this->schema}T2
  UNION ALL
  SELECT name, grade FROM {$this->schema}T3
  WITH ROW MOVEMENT
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
Attempt to update the row where grade = 50, which satisfies constraints
for both tables T2 and T3.  In this case no error is raised as row
migration doesn't apply.  The row does not need to be moved because it
satisfies all constraints of the table it is already in.

ATTEMPT TO UPDATE THE ROW WITH grade = 50
 BY INVOKING THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE vmarks SET grade = 60 WHERE grade = 50
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
Attempt to update the row where grade = 90, which satisfies constraints
for both tables T1 and T2.  An error is raised since this update is
ambiguous.  A similar error is raised on an ambiguous insert statement.

ATTEMPT TO UPDATE THE ROW WITH grade = 90
 BY INVOKING THE STATEMENT:
";
    $this->format_Output($toPrintToScreen);

    $query = "
UPDATE vmarks SET grade = 50 WHERE grade = 90
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
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
DROP TABLES T1,T2,T3 AND VIEW vmarks BY INVOKING
  THE STATEMENTS:
";
    $this->format_Output($toPrintToScreen);

    $query = "
DROP TABLE {$this->schema}T1
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
DROP TABLE {$this->schema}T2
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
DROP TABLE {$this->schema}T3
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
  } // update_With_Row_Movement_Special_Case
} // TbUnion


$Run_Sample = new Union();
// Create tables Q1, Q2, Q3 and Q4 and add constraints to them.
// Also create a view FY which is a view over the full year.
$Run_Sample->create_Tables_And_View();

// Insert some values directly into tables Q1, Q2, Q3 and Q4
$Run_Sample->insert_Initial_Values_In_Tables();

// Demonstrate how to insert through a UNION ALL view
$Run_Sample->insert_Using_Union_All();

// Modify the constraints of table Q1
$Run_Sample->new_Constraints();

// Attempt to insert data through a UNION ALL view where no table
// accepts the row
$Run_Sample->insert_When_No_Table_Accepts_It();

// Attempt to insert data through a UNION ALL view where more than
// one table accepts the row
$Run_Sample->insert_When_More_Than_One_Table_Accepts_It();

// Drop, recreate and reinitialize the tables and view
$Run_Sample->drop_Tables_And_View();
$Run_Sample->create_Tables_And_View();
$Run_Sample->insert_Initial_Values_In_Tables();

// Create a new view and perform some updates through it.  This shows how
// updates through a view with row migration affect the underlying
// tables
$Run_Sample->update_With_Row_Movement();

// Show two special cases of row migration involving tables with
// overlapping constraints
$Run_Sample->update_With_Row_Movement_Special_Case();

// Drop tables Q1, Q2, Q3 and Q4 and the view FY
$Run_Sample->drop_Tables_And_View();



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
