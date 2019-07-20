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
 * SOURCE FILE NAME: UtilConnection_PDO.php
 *
 * Description:
 * This class extends IO_Helper.
 * It is meant to perform the generic work of connecting and disconnecting
 * from a database as well as to commit and rollback transactions.
 *
 * $HTML_GENERAL_HELP and $CLI_GENERAL_HELP have been defined to include
 * any necessary information needed for the POD diver to function properly.
 *
 * Public Variables
 * $PDOconn - This represents the last database connection that was
 *             requested to be formed
 * $schema - This represents the current schema that the sample is
 *           working in.
 *
 * Function List:
 *
 * __construct($initialize = true)
 *    The Constructor
 *       Initialize IO_Helper and passes it the value of $initialize
 *
 * make_Connection($persistentConnection = false)
 *     Attempts to form a database connection the connection will be
 *     persistent if $persistentConnection is set to true. For the
 *     purposes that this class is going to be used if the connection
 *     fails an error message is outputted and the program exits.
 *
 * rollback($PDOconn = null)
 *     Performs a transaction rollback on the connection $PDOconn.
 *     If $PDOconn is set to null the $this->PDOconn is used.
 *
 * commit($PDOconn = null)
 *     Performs a transaction commit on the connection $PDOconn.
 *     If $PDOconn is set to null the $this->PDOconn is used.
 *
 * close_Connection()
 *     sets the local instance of $PDOconn to null.
 *     PDO connection are closed when they are not longer referenced
 *
 * get_XML_as_Text($returned_value)
 *     This function looks at the connection and then returns the
 *       given xml data in a string.
 *     One of the difference between the PDO_IBM driver and the
 *       PDO_ODBC DRIVER is the way in which XML data is returned
 *       the PDO_ODBC driver you will get back a string. PDO_IBM
 *       returns a stream from which you can read the XML data. For
 *       our purposes the xml that we are retrieving is small and
 *       we want a string to work with.
 *
 *
 **************************************************************************/


class PDO_Connection extends IO_Helper
{
  public $PDOconn = null;
  public $HTML_GENERAL_HELP =
'
    echo
\'<Table>
  <tr>
    <td>
      <input type="radio" name="dbdriver" value="IBM" \';
if(isset($this->passedArgs["dbdriver"]))
{
    if(strtolower($this->passedArgs["dbdriver"]) == "ibm")
    {
        echo "checked";
    }
}
else
{
    echo "checked";
}
echo \'/>PDO IBM Driver</td>
    </td>\';
//    <td>
//      <input type="radio" name="dbdriver" value="odbc" \';
//if(isset($this->passedArgs["dbdriver"]))
//{
//	if(strtolower($this->passedArgs["dbdriver"]) == "odbc")
//    {
//        echo "checked";
//	}
//}
//
//echo \'/>ODBC PDO Driver</td>
  echo \'</tr>
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

      -dbdriver
          -- If present alows specification of which
             PDO driver to use
             \\\'-dbdriver=IBM\\\' - will use the PDO_IBM
                                     driver
\' . //        \\\'-dbdriver=odbc\\\' - will use the PDO odbc
     //                               driver
\'
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
  	$options = null;
    echo "\nTrying to Open a connection to the database...\n\n";

    if($persistentConnection)$options = array(PDO::ATTR_PERSISTENT => true);

    /* Attempts to connect to the database */
    try
    {
        if(isset($this->passedArgs["dbdriver"]))
        {
            if(strtolower($this->passedArgs["dbdriver"]) == "odbc")
            {
                $this->PDOconn = new PDO("odbc:" . $this->connectionString, $this->userName, $this->userPassword, $options);
            }
            else
            {
            	$this->PDOconn = new PDO("ibm:" . $this->connectionString, $this->userName, $this->userPassword, $options);
            }
        }
        else
        {
            $this->PDOconn = new PDO("ibm:" . $this->connectionString, $this->userName, $this->userPassword);
        }
      $this->PDOconn->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
    }
    catch(PDOException $e)
    {
      /* If a connection was not established the returned error message is outputted and then the program is terminated. */
      $this->format_Output("\nConnection Failed: " . $e->getMessage() . "\n");
      exit;
    }
    $this->begin_Transaction();
    /* If the connection was established we say so */
    $this->format_Output("\nConnection Open\n");

    return $this->PDOconn;
  }

  public function begin_Transaction()
  {
    try
    {
      $this->PDOconn->beginTransaction();
      $this->format_Output("-- Transaction Started\n");
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage());
      $this->format_Output("\n\nTransaction Start FAILD. Exiting now.\n\n");
      exit;
    }
  }

  public function rollback($PDOconn = null)
  {
    // if $dbconn is null use the local connection
    if($PDOconn === null) $PDOconn = $this->PDOconn;

    // if $dbconn is still null say so and exit the function
    if($PDOconn === null)
    {
      $this->format_Output("\nThere is not connection to perform a rollback on!\n");
      return false;
    };

    $this->format_Output("\nRolling back the transaction...");
    try
    {
      if($PDOconn->rollBack())
      {
        $this->format_Output("\nThe transaction was rolled back.\n");
        $this->begin_Transaction();
        return true;
      }
      else
      {
        $this->format_Output("\nError in rolling back transaction\n");
        return false;
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage());
    }
  }

  public function commit($PDOconn = null)
  {
    // if $dbconn is null use the local connection
    if($PDOconn === null) $PDOconn = $this->PDOconn;

    // if $dbconn is still null say so and exit the function
    if($PDOconn === null)
    {
      $this->format_Output("\nThere is not connection to perform a rollback on!\n");
      return false;
    };

    $this->format_Output("\nCommitting the transaction...");
    try
    {
      if($PDOconn->commit())
      {
        $this->format_Output("\nThe transaction was committed.\n");
        $this->begin_Transaction();
        return true;
      }
      else
      {
        $this->format_Output("\nError in Committing the transaction\n");
        return false;
      }
    }
    catch (PDOException $e)
    {
      print $e->getMessage();
    }
  }

  public function close_Connection()
  {
    $this->dbconn = null;
    $this->format_Output("\nConnection Closed.\n");
    return true;

  }
  // The odbc driver does not return a stream with XML data, the contents is read directly.
  // Under windows you must configure the odbc data source CLI Parameter to return xml
  // as a lob or you will get back garbage. See <?obbc_config> for more details.
  public function get_XML_as_Text($returned_value)
  {
  	if($returned_value === null)
  	{
  		$this->format_Output("\n--------------- Null Value Returned! ---------------\n");
  		return "";
  	}
  	else
  	{
	  if(isset($this->passedArgs["dbdriver"]))
	  {
	    if(strtolower($this->passedArgs["dbdriver"]) == "odbc")
	    {
	      return $returned_value;
	    }
	    else
	    {
	      return stream_get_contents($returned_value);
	    }
	  }
	  else
	  {
	  	return stream_get_contents($returned_value);
	  }
	}
  }

  public function get_Data($returned_value)
  {
  	  return $this->get_XML_as_Text($returned_value);
  }

  public function exec($query)
  {
  	try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        return false;
      }
    }
    catch(PDOException $e)
    {
    	return false;
    }
    return true;
  }

  public function get_Error()
  {
    if($this->PDOconn !== null)
    {
      $stmtError = $this->PDOconn->errorInfo();
      return "\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n";
    }
  }
}
?>
