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
 * SOURCE FILE NAME: DbAuthority_PDO.php
 *
 * SAMPLE: How to grant, display, revoke authorities at the database level
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_PDO.php";

class DB_Authority_grant_and_revoke extends PDO_Connection
{
  public $SAMPLE_HEADER = "
echo \"

THIS SAMPLE DEMONSTRATES
HOW TO:
    GRANT,
    DISPLAY,
    REVOKE,
AUTHORITIES AT DATABASE LEVEL.
\";
";

    function __construct($initialize = true)
    {
        parent::__construct($initialize);
        $this->make_Connection();
    }

  function authority_Grant()
  {
      $toPrintToScreen = "
-----------------------------------------------------------
USE THE SQL STATEMENTS:
  GRANT (Database Authorities)
  COMMIT
TO GRANT AUTHORITIES AT THE DATABASE LEVEL.
";
      $this->format_Output($toPrintToScreen);

      $query = "
GRANT
    CONNECT,
    CREATETAB,
    BINDADD
  ON
    DATABASE
  TO USER
    user1
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

    /* prepare and execute the SQL statement */
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
      	$errorInfo = $this->PDOconn->errorInfo();
        $this->format_Output("\nGrant statement Failed : "
                                 . $errorInfo[2] . "\n");
      }
      else
      {
        $this->format_Output("Grant statement Succeeded \n");
        $this->commit();
      }

  }

  function authority_For_Any_User_or_Group_Display()
  {
       $toPrintToScreen = "
-----------------------------------------------------------
USE THE SQL STATEMENT:
  SELECT INTO
TO DISPLAY AUTHORITIES FOR ANY USER AT DATABASE LEVEL.
";
      $this->format_Output($toPrintToScreen);

      $query = "
SELECT
    granteetype,
    dbadmauth,
    createtabauth,
    bindaddauth,
    connectauth,
    nofenceauth,
    implschemaauth,
    loadauth
  FROM
    syscat.dbauth
  WHERE
    grantee = 'user1'
  for read only
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

    /* prepare and execute the SQL statement */
      $result = $this->PDOconn->query($query);
      if($result == false)
      {
        $errorInfo = $this->PDOconn->errorInfo();
        $this->format_Output("\nSelect statement Failed :  "
                                . $errorInfo[2] . "\n");
      }
      else
      {

      /* call function from util_funcs.php which fetches
         the rows and put it into an array */
      $aResult = $result->fetch(PDO::FETCH_OBJ);
      if($aResult != null)
      {
          $toPrintToScreen = "
  Grantee Type      = $aResult->GRANTEETYPE
  DBADM auth.       = $aResult->DBADMAUTH
  CREATETAB auth.   = $aResult->CREATETABAUTH
  BINDADD auth.     = $aResult->BINDADDAUTH
  CONNECT auth.     = $aResult->CONNECTAUTH
  NO_FENCE auth.    = $aResult->NOFENCEAUTH
  IMPL_SCHEMA auth. = $aResult->IMPLSCHEMAAUTH
  LOAD auth.        = $aResult->LOADAUTH
";
        $this->format_Output($toPrintToScreen);
      }
      else
      {
        $this->format_Output("\n  NO USER FOUND.\n");
      }
    }
  }

  //Explicit authorities or privileges are granted to the user (GRANTEETYPE
  // of U). Implicit authorities or privileges are granted to a group to
  // which the user belongs (GRANTEETYPE of G).
  function display_Full($alpha)
  {
    if ($alpha == "Y")
    {
      return "Yes";
    }
    return "No";
  }

  function authority_For_Current_User_Display()
  {
    $toPrintToScreen = "
-----------------------------------------------------------
TO DISPLAY CURRENT USER AUTHORITIES AT DATABASE LEVEL
";
    $this->format_Output($toPrintToScreen);

    $query = "
SELECT
    USER as USER
  FROM
    sysibm.sysdummy1
" ;

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

    /* prepare and execute the SQL statement */
    $result = $this->PDOconn->query($query);
    $aResult = $result->fetch(PDO::FETCH_ASSOC);
    $user = $aResult['USER'];

    $toPrintToScreen = "
  THE CURRENT USER IS: $user
";
    $this->format_Output($toPrintToScreen);

    /* current user authorities */
    $query = "
SELECT
    dbadmauth,
    createtabauth,
    bindaddauth,
    connectauth,
    nofenceauth,
    implschemaauth,
    loadauth
  FROM
    syscat.dbauth
  WHERE
    grantee = '$user'
  FOR
    read only
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

    /* prepare and execute the SQL statement */
      $result = $this->PDOconn->query($query);
      if($result == false)
      {
        $errorInfo = $this->PDOconn->errorInfo();
        $this->format_Output("\nSelect statement Failed :  " . $errorInfo[2] . "\n");
      }
      else
      {
      /* call function from util_funcs.php which fetches
         the rows and put it into an array */
      $aResult = $result->fetch(PDO::FETCH_OBJ);
      if($aResult != null)
      {
        $toPrintToScreen = "
  User DBADM authority            : $aResult->DBADMAUTH
  User CREATETAB authority        : $aResult->CREATETABAUTH
  User BINDADD authority          : $aResult->BINDADDAUTH
  User CONNECT authority          : $aResult->CONNECTAUTH
  User CREATE_NOT_FENC authority  : $aResult->NOFENCEAUTH
  User IMPLICIT_SCHEMA authority  : $aResult->IMPLSCHEMAAUTH
  User LOAD authority             : $aResult->LOADAUTH
";
      $this->format_Output($toPrintToScreen);
      }
      else
      {
        $this->format_Output("\n  THE CURRENT USER HAS NO USER AUTHORITIES.\n");
      }
    }

    /* current group authorities */
    $query = "
SELECT
    dbadmauth,
    createtabauth,
    bindaddauth,
    connectauth,
    nofenceauth,
    implschemaauth,
    loadauth
  FROM
    syscat.dbauth
  WHERE
    GRANTEETYPE = 'G'
      AND
    GRANTOR = '$user'
  FOR
    read only
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

    /* prepare and execute the SQL statement */
      $result = $this->PDOconn->query($query);
      if($result == false)
      {
        $errorInfo = $this->PDOconn->errorInfo();
        $this->format_Output("\nSelect statement Failed :  " . $errorInfo[2] . "\n");
      }
      else
      {
      /* call function from util_funcs.php which fetches
         the rows and put it into an array */
      $aResult = $result->fetch(PDO::FETCH_OBJ);
      if($aResult != null)
      {
      $toPrintToScreen = "
  Group DBADM authority           : $aResult->DBADMAUTH
  Group CREATETAB authority       : $aResult->CREATETABAUTH
  Group BINDADD authority         : $aResult->BINDADDAUTH
  Group CONNECT authority         : $aResult->CONNECTAUTH
  Group CREATE_NOT_FENC authority : $aResult->NOFENCEAUTH
  Group IMPLICIT_SCHEMA authority : $aResult->IMPLSCHEMAAUTH
  Group LOAD authority            : $aResult->LOADAUTH
";
        $this->format_Output($toPrintToScreen);
      }
      else
      {
        $this->format_Output("\n\n  THE CURRENT USER HAS NO GROUP AUTHORITIES.\n\n");
      }
    }
  }

  function authority_Revoke()
  {
    $toPrintToScreen = "
-----------------------------------------------------------
USE THE SQL STATEMENTS:
  REVOKE (Database Authorities)
  COMMIT
TO REVOKE AUTHORITIES AT DATABASE LEVEL.

";
    $this->format_Output($toPrintToScreen);

      /* revoke user authorities at database level */
      $query =  "
REVOKE
    CONNECT,
    CREATETAB,
    BINDADD
  ON
    DATABASE
  FROM USER
    user1
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

    /* prepare and execute the SQL statement */
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $errorInfo = $this->PDOconn->errorInfo();
        $this->format_Output("\nRevoke statement Failed  : " . $errorInfo[2] . "\n");
      }
      else
      {
        $this->format_Output("\nRevoke statement Succeeded \n");
        $this->commit();
      }
  }
}

$Run_Sample = new DB_Authority_grant_and_revoke();

/* call the function authority_Grant */
$Run_Sample->authority_Grant();

/* call the function authority_For_Any_User_or_Group_Display */
$Run_Sample->authority_For_Any_User_or_Group_Display();

/* call the function authority_For_Current_User_Display */
$Run_Sample->authority_For_Current_User_Display();

/* call the function authority_Revoke */
$Run_Sample->authority_Revoke();

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
