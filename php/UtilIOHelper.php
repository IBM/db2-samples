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
 * SOURCE FILE NAME: UtilIOHelper.php
 *
 **************************************************************************/

class IO_Helper
{
  /****************************************************************************
   * The public variables:
   *
   * $SAMPLE_HEADER
   *
   * $CLI_GENERAL_HELP
   * $CLI_SAMPLE_HELP
   *
   * $HTML_GENERAL
   * $HTML_GENERAL_HELP
   * $HTML_SAMPLE_HELP
   *
   *
   * Are used to output help and other general information to the screen. These
   * variables are broken in to the three groups you see above. It should be
   * noted that these variable are evaluated not just echoed to the screen. This
   * is to allow for thing like: When an html forum is submitted and redisplayed
   * on the screen, any field that had information retain such information.
   *
   * $SAMPLE_HEADER is meant to represent information about the sample that
   * should be printed out every time the sample is run. This might include
   * things like a short description, a title and the commands used.
   *
   * $CLI_... are variables used when help is requested to be printed when the
   * sample is run from a command line interface. General Help information is
   * the basic information that is common across all samples such as how to
   * specify what database you want to connect to as well as how to specify a
   * username and password. This should not normally be needed to be overridden.
   * Sample Help is any sample specific information that is needed to be
   * outputted.
   *
   * $HTML_... are variables used when the sample is being run in a web
   * environment. General information set up the forum used to return
   * information to the program html headers and other use full things. This
   * should not need to be overridden. General Help contains forum content that
   * allows for the input of the database name, username and password, and any
   * general run information. This should not normally be needed to be
   * overridden. Sample Help is any sample specific information that is needed
   * to be outputted. It is wrapped with in a forum so it is possible to include
   * forum content and have it returned to the sample.
   *
   ****************************************************************************/
  public $SAMPLE_HEADER = "";

  public $CLI_SAMPLE_HELP =
'
echo \'
    No sample level configurations available
\';
';
  public $CLI_GENERAL_HELP = '';

  public $HTML_SAMPLE_HELP =
'
echo \'
<br/>
    No sample level configurations available
<br/>
\';
';
  public $HTML_GENERAL =
 '
echo \'
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>PHP Sample</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <meta name="copyright" content="(C) Copyright IBM Corporation 2006" />
    <meta name="security" content="public" />
</head>

<body>
<pre>
<div style="border: solid; border-width: thin; border-colour: blue" >
\';
eval($this->SAMPLE_HEADER);
echo \'
Alternate Connection Information:
<div id="ConnectionInformation">
<form name="input" method="post">\';
  eval($this->HTML_GENERAL_HELP);
  echo
\'<input type="checkbox" name="showOptions" value="checked" \';
echo $this->showOptions;
echo \' /> Show sample options.
\';
  if($this->showOptions != "")
  {
    eval($this->HTML_SAMPLE_HELP);
  }
  echo
\'<input type="submit" value="Run & Update Sample">
<form>
</div>
</div>\';
';
  public $HTML_GENERAL_HELP = '';

  public $isWebBased = false;

  public $isRunningOnWindows = false;

  public $documentRoot = "";

  public $connectionString = "SAMPLE";
  public $userName = "";
  public $userPassword = "";

  public $schema = "";

  public $showOptions = "";

  public $passedArgs;

  function __construct($initialize = true)
  {
    if($initialize)
    {
      $this->try_To_Load_Default_Values();
      /* Retrieves run time information */
      $this->check_Parameters();
      if(isset($this->passedArgs["schema"]))
      {
        if($this->passedArgs["schema"] != "")
        {
          $matches = explode(" ", $this->passedArgs["schema"]);
          $this->passedArgs["schema"] = strtoupper($matches[0]);
          $this->schema = $this->passedArgs["schema"] . ".";
        }
        else
          $this->schema = $this->schema;
      }
    }
    //A few checks to try to see if we are running on a Win32 OS
    if(isset($_SERVER['windir']))
      $this->isRunningOnWindows = true;
    if(isset($_SERVER['WINDIR']))
      $this->isRunningOnWindows = true;
    if(isset($_SERVER['OS']))
      if(stristr($_SERVER['OS'], 'win') !== false)
        $this->isRunningOnWindows = true;
    if(isset($_SERVER['SERVER_SOFTWARE']))
      if(stristr($_SERVER['SERVER_SOFTWARE'], 'win') !== false)
        $this->isRunningOnWindows = true;
    if(isset($_SERVER['SCRIPT_FILENAME']))
    {
      $index = strrpos($_SERVER['SCRIPT_FILENAME'], "/");
      if($index === false)
      {
        $index = strrpos($_SERVER['SCRIPT_FILENAME'], "\\");
      }
      if($index === false)
      {
        $this->documentRoot = "";
      }
      else
      {
        $this->documentRoot = substr($_SERVER['SCRIPT_FILENAME'], 0, $index+1);
      }
    }
  }

  private function try_To_Load_Default_Values()
  {
    $filename = "PHPSampleConfig.cfg";
  	if (file_exists($filename))
  	{
      $PHPSampleConfig = file($filename);

      if($PHPSampleConfig !== false)
      {

        foreach($PHPSampleConfig as $Line)
        {
          $matches = "";
          preg_match("/([^=]+)(?:\=\\\"?([^\\\"]*))\\\"??/", $Line, $matches);
          if(isset($matches[1]))
          {
            $val = "";
            $key = strtolower($matches[1]);
            if(isset($matches[2]))
            {
              $val = $matches[2];
            }
            $this->passedArgs[$key] = $val;
          }
        }
        $this->connectionString = $this->isset_Or_Use_Default('db', $this->connectionString);
        $this->userName = $this->isset_Or_Use_Default('u', $this->userName);
        $this->userPassword = $this->isset_Or_Use_Default('p', $this->userName);
      }
    }
  }

  private function check_Parameters()
  {
    if(isset($_SERVER["argc"]))
    {
      $this->isWebBased = false;
      foreach($_SERVER["argv"] as $commandLineArg)
      {
        /*****
         * Performs a Regular expression match on the given argument
         * Arguments are in the forum
         * -<option>=<value>
         * Arguments are then stored in the array which was passed in to the function
         *
         * The keys used to store the <value> portion of the argument are as follows:
         *
         * The first two letters of <option>
         * The first letter of <option> (This will blindly overwrite any other option
         *                               with the same first letter. So carefully name
         *                               your tags or use full option name only)
         *
         * (If an option is inputted as only one character then there will be only one
         * entry in the array, all keys are forced to lowercase)
         *
         * Options with no value portion are still stored. A blank value is assigned.
         *
         * Reserved - anything starting with the following
         * db -- database connection string
         * u -- user name
         * p -- user password
         * h, -h, ?, -? -- Display help
         ****/
        $matches = "";
        preg_match("/^\-([^=]+)(?:\=(.*))?/", $commandLineArg, $matches);
        if(isset($matches[1]))
        {
          $val = "";
          $key = strtolower($matches[1]);
          if(isset($matches[2]))
          {
            $val = $matches[2];
          }
          $this->passedArgs[$key] = $val;
        }
      }

      $this->connectionString = $this->isset_Or_Use_Default('db', $this->connectionString);
      $this->userName = $this->isset_Or_Use_Default('u', $this->userName);
      $this->userPassword = $this->isset_Or_Use_Default('p', $this->userName);
      eval($this->SAMPLE_HEADER);
      if(isset($this->passedArgs['h']) || isset($this->passedArgs['-h']) || isset($this->passedArgs['?']) || isset($this->passedArgs['-?']))
      {
        $this->showOptions = true;

        eval($this->CLI_SAMPLE_HELP);
        eval($this->CLI_GENERAL_HELP);
        die;
      }
    }
    else
    {
      $this->isWebBased = true;

      $this->connectionString = isset($_POST['ConnectionString']) ?
                                  (
                                    strcmp($_POST['ConnectionString'],"") != 0 ?
                                      $_POST['ConnectionString'] :
                                      $this->isset_Or_Use_Default('db', $this->connectionString)
                                  ) :
                                  $this->isset_Or_Use_Default('db', $this->connectionString);


      $this->userName = isset($_POST['UserName']) ?
                          $_POST['UserName'] :
                          $this->isset_Or_Use_Default('u', $this->userName);
      $this->userPassword = isset($_POST['Password']) ?
                              $_POST['Password'] :
                              $this->isset_Or_Use_Default('p', $this->userPassword);
      $this->showOptions = isset($_POST['showOptions']) ? $_POST['showOptions'] : "";

      foreach($_POST as $key => $val)
      {
        $this->passedArgs[$key] = $val;
      }
      foreach($_GET as $key => $val)
      {
        $this->passedArgs[$key] = $val;
      }

      eval($this->HTML_GENERAL);

      $this->showOptions = isset($_POST['showOptions']) ? ($_POST['showOptions'] ? true : false) : false;
    }
  }

  private function isset_Or_Use_Default($KEY, $Default)
  {
    return  isset($this->passedArgs[$KEY]) ?
              (
                strcmp($this->passedArgs[$KEY],"") != 0 ?
                  $this->passedArgs[$KEY] :
                  $Default
              ) :
              $Default;
  }

  /****************************************************************************
   * Simply make sure the output looks the same in a web browser or consoled
   */
  public function format_Output($str)
  {
    /* This statement checks to see if we are outputting to a web browser if we are
     * it properly formatted. */
    /* Replaces Carrots 'Special Characters' as to not affect html code */
    echo $this->isWebBased ? htmlspecialchars($str) : $str;
  }

  public function close_Sample()
  {
  	echo $this->isWebBased ? "</pre></body>" : "";
  }

  public function display_Xml_Parsed_Struct($input, $lineStartChar = "")
  {
  	$xml_parser_results = "";

    try
    {
      $xml_parser = xml_parser_create();

      xml_parse_into_struct($xml_parser, $input, $xml_parser_results);

      xml_parser_free($xml_parser);
    }
    catch(Exception $e)
    {
      return "$lineStartChar\n$lineStartChar\n-- XML parsing error  --\n$lineStartChar\n$lineStartChar";
    }

    $return_string = $lineStartChar;
    foreach($xml_parser_results as $value)
    {
       if(ereg($value['type'], 'close'))
       {
           $return_string .= $this->print_White_Space(($value['level']-1)*4);
           $return_string .= "</" . $value['tag'] . ">\n$lineStartChar";
       }
       else if(!ereg($value['type'], 'cdata'))
       {
            $return_string .= $this->print_White_Space(($value['level']-1)*4);
            $return_string .= "<" . $value['tag'];
            if(isset($value['attributes']))
            {
                $return_string .= $this->print_Attribute($value['attributes']);
            }
            $return_string .= ">\n$lineStartChar";
            if(isset($value['value']))
            {
            	if(!ereg($value['value'], ' '))
                {
                  $return_string .= $this->print_White_Space(($value['level']-1)*4+4);
                  $return_string .= $value['value'] . "\n$lineStartChar";
                }
            }
        }
        if(ereg($value['type'], 'complete'))
        {
            $return_string .= $this->print_White_Space(($value['level']-1)*4);
            $return_string .= "</" . $value['tag'] . ">\n$lineStartChar";
        }
    }
    return $return_string;
  }

  private function print_Attribute($attrib)
  {
      $return_string = "";
      foreach($attrib as $key => $value)
      {
        $return_string .= ' ' . $key . '="' . $value . '"';
      }
      return $return_string;
  }

  private function print_White_Space($number)
  {
      $return_string = "";
      $i = 0;
      for(;$i<$number;$i++)
      {
          $return_string .= " ";
      }
      return $return_string;
  }
}

?>
