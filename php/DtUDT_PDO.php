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
 * SOURCE FILE NAME: DtUDT_PDO.php
 *
 * SAMPLE: How to create, use and drop user defined distinct types
 *
 * SQL statements USED:
 *         CREATE DISTINCT TYPE
 *         CREATE TABLE
 *         DROP DISTINCT TYPE
 *         DROP TABLE
 *         INSERT
 *         COMMIT
 *
 ***************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_PDO.php";

class UDT extends PDO_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO CREATE, USE AND DROP USER DEFINED DISTINCT TYPES.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }

  // This function creates a few user defined distinct types
  public function UDT_create()
  {
  	try
    {
      $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE DISTINCT TYPE
  COMMIT\n
TO CREATE UDTs.
";
      $this->format_Output($toPrintToScreen);
      $query = "
CREATE DISTINCT TYPE {$this->schema}udt1
  AS INTEGER
  WITH COMPARISONS
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
      $query = "
CREATE DISTINCT TYPE {$this->schema}udt2
  AS CHAR(2)
  WITH COMPARISONS
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
      $query = "
CREATE DISTINCT TYPE {$this->schema}udt3
  AS DECIMAL(7, 2)
  WITH COMPARISONS
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
      $this->commit();
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage());
      return false;
    }
  } // create

  // This function uses the user defined distinct types that we created
  // at the beginning of this program.
  public function UDT_use()
  {
    try
    {
      $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  EXECUTE IMMEDIATE
  COMMIT\n
TO USE UDTs.

 Create a table that uses the user defined distinct types
";
      $this->format_Output($toPrintToScreen);
      $query = "
CREATE TABLE {$this->schema}udt_table(
        col1 {$this->schema}udt1,
        col2 {$this->schema}udt2,
        col3 {$this->schema}udt3
      )
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
      $this->commit();


       $toPrintToScreen = "
Insert data into the table with the user defined distinct types
";
      $this->format_Output($toPrintToScreen);
      $query = "
INSERT INTO {$this->schema}udt_table
  VALUES(
      CAST(77 AS {$this->schema}udt1),
      CAST('ab' AS {$this->schema}udt2),
      CAST(111.77 AS {$this->schema}udt3)
    )
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
      $this->commit();

     $toPrintToScreen = "
Drop the table with the user defined distinct types
";
      $this->format_Output($toPrintToScreen);
      $query = "
  DROP TABLE {$this->schema}udt_table
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
      $this->commit();
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage());
      return false;
    }
  } // use

  // This function drops all of the user defined distinct types that
  // we created at the beginning of this program
  public function UDT_drop()
  {
    try
    {
      $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  DROP
  COMMIT\n
TO DROP UDTs.

 Create a table that uses the user defined distinct types
";
      $this->format_Output($toPrintToScreen);
      $query = "
  DROP DISTINCT TYPE {$this->schema}udt1
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }

      $query = "
  DROP DISTINCT TYPE {$this->schema}udt2
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }

      $query = "
  DROP DISTINCT TYPE {$this->schema}udt3
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $this->format_Output("Failed \n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }

      $this->commit();
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage());
      return false;
    }
  } // drop
} // DtUdt



$Run_Sample = new UDT();
$Run_Sample->UDT_create();
$Run_Sample->UDT_use();
$Run_Sample->UDT_drop();

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
