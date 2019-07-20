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
 * SOURCE FILE NAME: DtInfo_PDO.php
 *
 * SAMPLE: How to get information about data types
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_PDO.php";

class INFO extends PDO_Connection
{


  public $SAMPLE_HEADER =
"
echo \"
THIS SAMPLE SHOWS HOW TO GET INFO ABOUT DATA TYPES.
\";
";

  function __construct($initialize = true)
  {
    parent::__construct($initialize);
    $this->make_Connection();
  }


  public function info_Get()
  {
     $toPrintToScreen = "
---------------------------------------------------------------------
USE SYSIBM Tables to retrieve colum information

Use SQL SELECT statment
TO GET INFO ABOUT DATA TYPES AND
TO RETRIEVE THE AVAILABLE INFO IN THE RESULT SET.
";
    $this->format_Output($toPrintToScreen);

    // Retrieve and display the column's name along with its type
    // and precision in the ResultSet

    $query = "
SELECT * FROM SYSIBM.SQLTYPEINFO
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);
    // Execute the query
    try
    {
      $DataFromTableSYSIBMSQLTYPEINFO = $this->PDOconn->query($query);

      if($DataFromTableSYSIBMSQLTYPEINFO)
      {
        $toPrintToScreen = "
  A LIST OF ALL COLUMNS IN THE RESULT SET:
| Column Name          | Column Type
---------------------------------------------
";

        $this->format_Output($toPrintToScreen);
        $NumOfColumns = $DataFromTableSYSIBMSQLTYPEINFO->columnCount();
        for($i = 0; $i < $NumOfColumns; $i++)
        {
          $ColumnMetaData = $DataFromTableSYSIBMSQLTYPEINFO->getColumnMeta($i);
          $this->format_Output(sprintf("| %20s | %s \n",
                                            $ColumnMetaData['name'],
                                            $ColumnMetaData['native_type']
                                        )
                                );

        }

        $toPrintToScreen = "
HERE ARE SOME OF THE COLUMNS' INFO IN THE TABLE ABOVE:

 | TYPE_NAME                     | DATA_ | COLUMN          | NULL- |CASE_
 |                               | TYPE  | SIZE            | ABLE  | SENSITIVE
 |                               | (int) |                 |       |
 |-------------------------------|-------|-----------------|-------|----------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($TableInfo = $DataFromTableSYSIBMSQLTYPEINFO->fetch(PDO::FETCH_ASSOC))
        {
           $this->format_Output(sprintf(" | %29s | %5s | %15s | %5s | %s\n",
                                            $TableInfo['TYPE_NAME'],
                                            $TableInfo['DATA_TYPE'],
                                            $TableInfo['COLUMN_SIZE'],

                                            $TableInfo['NULLABLE'] == true ? "YES" : "NO",

                                            $TableInfo['CASE_SENSITIVE'] == true ? "YES" : "NO"

                                        )
                                );

        }
      }
      else
      {
        $stmtError = $DataFromTableSYSIBMSQLTYPEINFO->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage());
    }
  }
} // DtInfo

// Initialize the class, create the database connection
// process any user input
$Run_Sample = new INFO();
// Get information about the Data type
$Run_Sample->info_Get();

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
