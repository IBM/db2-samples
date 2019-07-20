<?PHP
/****************************************************************************
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
 * SOURCE FILE NAME: UtilConnection_DB2.php
 *
 * Description:
 * This class extends IO_Helper.
 *
 * It is meant to perform the generic work of connecting and disconnecting from
 * a database as well as to commit and rollback transactions.
 *
 * $HTML_GENERAL_HELP and $CLI_GENERAL_HELP have been defined to include any
 * necessary information needed for the IBM_DB2 diver to function properly.
 *
 * Public Variables
 * $dbconn - This represents the last database connection that was requested to
 *            be formed
 * $schema - This represents the current schema that the sample is working in.
 *
 * Function List:
 *
 * __construct($initialize = true)
 *   The   Constructor
 *      Initialize IO_Helper and passes it the value of $initialize
 *
 * make_Connection($persistentConnection = false)
 *    Attempts to form a database connection the connection will be
 *      persistent if $persistentConnection is set to true. For the
 *      purposes that this class is going to be used if the
 *      connection  fails an error message is outputted and the program exits.
 *
 * rollback($dbconn = null)
 *    Performs a transaction rollback on the connection $dbconn. If $dbconn
 *      is  set to null the $this->dbconn is used.
 *
 * commit($dbconn = null)
 *    Performs a transaction commit on the connection $dbconn. If $dbconn is
 *      set  to null the $this->dbconn is used.
 *
 * close_Connection($dbconn = null)
 *    Tries to closes the connection dbconn. If $dbconn is set to null the
 *      $this- >dbconn is used.
 *
 *
 **************************************************************************/

class DB2_Connection extends IO_Helper
{
  public $dbconn = null;
  public $HTML_GENERAL_HELP =
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
  public $CLI_GENERAL_HELP =
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
    parent::__construct($initialize);
  }

  public function make_Connection($persistentConnection = false)
  {
    echo "\nTrying to Open a connection to the database...\n\n";

    /* Attempts to connect to the database */
    if($persistentConnection)
    {
      // Persistent
      $this->dbconn = db2_pconnect($this->connectionString, $this->userName, $this->userPassword);
    }
    else
    {
      // Not persistent
      $this->dbconn = db2_connect($this->connectionString, $this->userName, $this->userPassword);
    }

    /* Checks to see if a database connection was successfully established */
    if($this->dbconn == null)
    {
      /* If a connection was not established the returned error message is outputted and then the program is terminated. */
      echo "\n" . db2_conn_errormsg() . "\n";
      exit;
    }
    else
    {
      /* If the connection was established we say so */
      echo "\nConnection Open\n";

      /***
       * Verify that auto commit is turned off or we try to turn it off
       * If we can not turn off auto commit we close the connection and exit.
       ***/
      if(db2_autocommit($this->dbconn) == 0)
      {
         $this->format_Output("-- AUTOCOMMIT is off.\n");
      }
      else
      {
        if(db2_autocommit($this->dbconn, DB2_AUTOCOMMIT_OFF))
        {
           $this->format_Output("-- AUTOCOMMIT is off.\n");
         }
         else
         {
           $this->format_Output("-- AUTOCOMMIT is on.\n");
           $this->format_Output("Connection Failed\n");
           close_Connection();
           exit;
         }
      }
      echo "\n";
    }
    return $this->dbconn;
  }

  public function rollback($dbconn = null)
  {
  	// if $dbconn is null use the local connection
    if($dbconn === null) $dbconn = $this->dbconn;

    // if $dbconn is still null say so and exit the function
    if($dbconn === null)
    {
      $this->format_Output("\nThere is not connection to perform a rollback on!\n");
      return false;
    };
    $this->format_Output("\nRolling back the transaction...");

    if(db2_rollback($dbconn))
    {
      $this->format_Output("\nThe transaction was rolled back.\n");
      return true;
    }
    else
    {
      $this->format_Output("\nError in rolling back transaction\n");
      return false;
    }
  }

  public function commit($dbconn = null)
  {
    // if $dbconn is null use the local connection
    if($dbconn === null) $dbconn = $this->dbconn;

    // if $dbconn is still null say so and exit the function
    if($dbconn === null)
    {
      $this->format_Output("\nThere is not connection to perform a commit on!\n");
      return false;
    };

    $this->format_Output("\nCommitting the transaction...");

    if(db2_commit($dbconn))
    {
      $this->format_Output("\nThe transaction was committed.\n");
      return true;
    }
    else
    {
      $this->format_Output("\nError in Committing the transaction\n");
      return false;
    }
  }

  public function close_Connection($dbconn = null)
  {
    // if $dbconn is null use the local connection
    if($dbconn === null) $dbconn = $this->dbconn;

    // if $dbconn is still null say so and exit the function
    if($dbconn === null)
    {
      $this->format_Output("\nThere is not connection to close!\n");
      return false;
    };

    $this->format_Output("\n\nTrying to close a connection to the database...");

    if(db2_close($dbconn)==1)
    {
      $this->format_Output("\nConnection Closed.\n");
      return true;
    }
    else
    {
      $this->format_Output("\nError Closing Connection .");
    }
    return false;
  }

  public function exec($query)
  {
    if(db2_exec($this->dbconn, $query) === false)
    {
      return false;
    }
    return true;
  }

  public function get_Error()
  {
  	return db2_stmt_errormsg() . "\n";
  }
}
?>
