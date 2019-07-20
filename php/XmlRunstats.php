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
 * SOURCE FILE NAME: XmlRunstats.php
 *
 * SAMPLE: How to perform RUNSTATS on a table containing XML type columns.
 *
 * SQL STATEMENTS USED:
 *         SELECT
 *         CONNECT
 *         RUNSTATS
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";

class XmlRunstats extends IO_Helper
{

  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS UPDATE THE TABLE STATISTICS OF THE \"CUSTOMER\" TABLE.

      -------- SCHEMA FIELD IS REQUIERED IN THIS SAMPLE --------
';
";

  public $HTML_SAMPLE_HELP =
'
    echo
\'<Table>
  <tr>
    <td>
      Connection String (Default \\\'Sample\\\'):
    </td>
    <td>
      <input type="text" name="ConnectionString" value="\';
echo $this->connectionString;
echo \'" /></td>
  </tr><tr>
    <td>
      User Name (Default blank):
    </td>
    <td>
      <input type="text" name="UserName" value="\';
echo $this->userName;
echo \'"  /></td>
  </tr><tr>
    <td>
      Password (Default blank):
    </td>
    <td>
      <input type="password" name="Password" value="\';
echo $this->userPassword;
echo \'" /></td>
  </tr>
  </tr><tr>
    <td>
    </td>
    <td>
    </td>
  </tr>
  </tr><tr>
    <td>
      Schema (Default logged in user):
    </td>
    <td>
      <input type="text" name="schema" value="\';
echo isset($this->passedArgs["schema"]) ? $this->passedArgs["schema"] : "";
echo \'" /></td>
  </tr>
</Table>\';
';
  public $CLI_SAMPLE_HELP =
'
echo \'
    Connection Options:
      -db -- If present specifies the connection
                string to use default -db="sample"

      -u  -- If present specifies the user name

      -p  -- If present specifies the user password

      -schema
          -- If present will specify what schema the
              sample database is located under.
\';
';


  function __construct($initialize = true)
  {
    $this->showOptions = "checked";
    parent::__construct($initialize);
    if(isset($this->passedArgs["schema"]))
    {
      if($this->passedArgs["schema"] != "")
      {
        $this->schema = strtoupper($this->passedArgs["schema"]) . ".";
      }
      else
        $this->schema = "";
    }
    else
      $this->schema = "";
  }

  // call runstats on 'customer' table to update its statistics
  public function xml_Runstats()
  {
    $descriptorspec = array(
                              0 => array('pipe', 'r'),
                              1 => array('pipe', 'w'),
                              2 => array('pipe', 'r')
                            );
    $ProcStartString = "";
    $ProcEndString = "";
    $endString = "Done
";

    if($this->isRunningOnWindows)
    {
      $ProcStartString = "db2cmd -i";
      $ProcEndString = "exit \n\n";
    }
    $resource = proc_open($ProcStartString, $descriptorspec, $pipes);
    if (is_resource($resource))
    {
      $stdin = $pipes[0];
      $stdout = $pipes[1];
      $stderr = $pipes[2];

      $toPrintToScreen = "
-----------------------------------------------------------
 Form a connection to a database:

";
      $this->format_Output($toPrintToScreen);

      $query = "db2 connect to {$this->connectionString}";
      $query .= $this->userName == "" ? "": " USER " . $this->userName;
      $query .= $this->userPassword == "" ? "": " USING " . $this->userPassword;
      $query .= "
";
      $this->format_Output($query);

      fwrite($stdin, $query);

      $toPrintToScreen = "
-----------------------------------------------------------
 USE THE SQL STATEMENT:
   RUNSTATS
 TO UPDATE TABLE STATISTICS.

";
      $this->format_Output($toPrintToScreen);

      $toPrintToScreen = "

Perform runstats on table customer for all columns including XML columns

";
      $this->format_Output($toPrintToScreen);
      $query = "
RUNSTATS ON TABLE {$this->schema}CUSTOMER
";

      $this->format_Output($query);

      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      fwrite($stdin, "db2 " . escapeshellarg($query) . "\n\n");

      $toPrintToScreen = "

Perform runstats on table customer for XML columns

";
      $this->format_Output($toPrintToScreen);
      $query = "
RUNSTATS ON TABLE {$this->schema}CUSTOMER
  ON COLUMNS (
        Info,
        History
      )
";
      $this->format_Output($query);

      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      fwrite($stdin, "db2 " . escapeshellarg($query) . "\n\n");

      $toPrintToScreen = "

Perform runstats on table customer for XML columns
with the following options:

Distribution statistics for all partitions
Frequent values for table set to 30
Quantiles for table set to -1 (NUM_QUANTILES as in DB Cfg)
Allow others to have read-only while gathering statistics

";
      $this->format_Output($toPrintToScreen);

      $query = "
RUNSTATS ON TABLE {$this->schema}CUSTOMER
  ON COLUMNS (
        Info,
        History LIKE STATISTICS
      )
  WITH
    DISTRIBUTION ON KEY COLUMNS
    DEFAULT NUM_FREQVALUES 30
    NUM_QUANTILES -1
  ALLOW
    READ ACCESS
";
      $this->format_Output($query);

      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      fwrite($stdin, "db2 " . escapeshellarg($query) . "\n\n");

      $toPrintToScreen = "

Perform runstats on table customer
with the following options:

EXCLUDING XML COLUMNS.
This option allows the user to exclude all XML type columns from
statistics collection. Any XML type columns that have been specified
in the cols-list will be ignored and no statistics will be collected
from them. This clause facilitates the collection of statistics
on non XML columns.

";
      $this->format_Output($toPrintToScreen);

      $query = "
RUNSTATS ON TABLE {$this->schema}CUSTOMER
  ON COLUMNS (
        Info,
        History LIKE STATISTICS
      )
  WITH
    DISTRIBUTION ON KEY COLUMNS
    EXCLUDING XML COLUMNS
";
      $this->format_Output($query);

      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);
      fwrite($stdin, "db2 " . escapeshellarg($query) . "\n\n");

      fwrite($stdin, "echo Done\n");

      $toPrintToScreen = "

Result:
-------------------------------------------------------------------------------
";
      $this->format_Output($toPrintToScreen);

      //We need to wait a bit for everything to run
      while(true)
      {
        $input = fgets($stdout, 1024);
        if($input === false)
        {
          echo "Waiting\n";
          sleep(1);
        }
        else
        {
          if(strcmp($input, $endString) != 0)
            {
              echo $input;

            }
            else
            {
              break;
            }
        }
      }

      fclose($stdin);
      fclose($stdout);
      fclose($stderr);
      proc_close($resource);

    }
  } // xml_Runstats

} // XmlRunstats

// call xml_Runstats that updates the statistics of customer table
$Run_Sample = new XmlRunstats();

$Run_Sample->xml_Runstats();


?>
