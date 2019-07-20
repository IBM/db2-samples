<?php

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
 * SOURCE FILE NAME: UtilTableSetup_LOB.php
 *
 **************************************************************************/

class TABLE_SETUP_General_LOB
{
  public static function CREATE($SampleClass)
  {
    $query = "
CREATE TABLE {$SampleClass->schema}staff_photo  (
      EMPNO CHAR(6) NOT NULL ,
      PHOTO_FORMAT VARCHAR(10) NOT NULL ,
      PICTURE BLOB(102400) LOGGED NOT COMPACT
    )
";
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if($SampleClass->exec($query) === false)
    {
      $SampleClass->format_Output($SampleClass->get_Error());
    }

    $query = "
CREATE TABLE {$SampleClass->schema}staff_resume  (
      EMPNO CHAR(6) NOT NULL ,
      RESUME_FORMAT VARCHAR(10) NOT NULL ,
      RESUME CLOB(5120) LOGGED NOT COMPACT
    )
";
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if($SampleClass->exec($query) === false)
    {
      $SampleClass->format_Output($SampleClass->get_Error());
    }

    $SampleClass->commit();
}

  public static function DROP($SampleClass)
  {

    $query = "
DROP TABLE {$SampleClass->schema}staff_resume
  ";
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if($SampleClass->exec($query) === false)
    {
      $SampleClass->format_Output($SampleClass->get_Error());
    }

    $query = "
DROP TABLE {$SampleClass->schema}staff_photo
  ";
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if($SampleClass->exec($query) === false)
    {
      $SampleClass->format_Output($SampleClass->get_Error());
    }

    $SampleClass->commit();
  }

}
?>
