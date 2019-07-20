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
 * SOURCE FILE NAME: UtilTableSetup_Staff.php
 *
 **************************************************************************/

class TABLE_SETUP_General_Staff
{
  public static function CREATE($SampleClass)
  {
    $query = "
CREATE TABLE {$SampleClass->schema}STAFF  (
      ID SMALLINT NOT NULL ,
      NAME VARCHAR(9) ,
      DEPT SMALLINT ,
      JOB CHAR(5) ,
      YEARS SMALLINT ,
      SALARY DECIMAL(7,2) ,
      COMM DECIMAL(7,2)
)
";
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    if($SampleClass->exec($query) === false)
    {
      $SampleClass->format_Output($SampleClass->get_Error());
    }
    else
    {
      $query = "
Insert INTO {$SampleClass->schema}STAFF
      ( ID,        NAME, DEPT,     JOB, YEARS,   SALARY, COMM)
    values
      ( 10, 'Sanders'  ,   20, 'Mgr  ',     7, 18357.50,     null),
      ( 20, 'Pernal'   ,   20, 'Sales',     8, 18171.25,   612.45),
      ( 30, 'Marenghi' ,   38, 'Mgr  ',     5, 17506.75,     null),
      ( 40, 'O`Brien',   38, 'Sales',     6, 18006.00,   846.55),
      ( 50, 'Hanes'    ,   15, 'Mgr  ',    10, 20659.80,     null),
      ( 60, 'Quigley'  ,   38, 'Sales',  null, 16808.30,   650.25),
      ( 70, 'Rothman'  ,   15, 'Sales',     7, 16502.83,  1152.00),
      ( 80, 'James'    ,   20, 'Clerk',  null, 13504.60,   128.20),
      ( 90, 'Koonitz'  ,   42, 'Sales',     6, 18001.75,  1386.70),
      (100, 'Plotz'    ,   42, 'Mgr  ',     7, 18352.80,     null),
      (110, 'Ngan'     ,   15, 'Clerk',     5, 12508.20,   206.60),
      (120, 'Naughton' ,   38, 'Clerk',  null,  2954.75,    80.00),
      (130, 'Yamaguchi',   42, 'Clerk',     6, 10505.90,    75.60),
      (140, 'Fraye'    ,   51, 'Mgr  ',     6, 21150.00,     null),
      (150, 'Williams' ,   51, 'Sales',     6, 19456.50,   637.65),
      (160, 'Molinare' ,   10, 'Mgr  ',     7, 22959.20,     null),
      (170, 'Kermisch' ,   15, 'Clerk',     4, 12258.50,   110.10),
      (180, 'Abrahams' ,   38, 'Clerk',     3, 12009.75,   236.50),
      (190, 'Sneider'  ,   20, 'Clerk',     8, 14252.75,   126.50),
      (200, 'Scoutten' ,   42, 'Clerk',  null, 11508.60,    84.20),
      (210, 'Lu'       ,   10, 'Mgr  ',    10, 20010.00,     null),
      (220, 'Smith'    ,   51, 'Sales',     7, 17654.50,   992.80),
      (230, 'Lundquist',   51, 'Clerk',     3, 13369.80,   189.65),
      (240, 'Daniels'  ,   10, 'Mgr  ',     5, 19260.25,     null),
      (250, 'Wheeler'  ,   51, 'Clerk',     6, 14460.00,   513.30),
      (260, 'Jones'    ,   10, 'Mgr  ',    12, 21234.00,     null),
      (270, 'Lea'      ,   66, 'Mgr  ',     9, 18555.50,     null),
      (280, 'Wilson'   ,   66, 'Sales',     9, 18674.50,   811.50),
      (290, 'Quill'    ,   84, 'Mgr  ',    10, 19818.00,     null),
      (300, 'Davis'    ,   84, 'Sales',     5, 15454.50,   806.10),
      (310, 'Graham'   ,   66, 'Sales',    13, 21000.00,   200.30),
      (320, 'Gonzales' ,   66, 'Sales',     4, 16858.20,   844.00),
      (330, 'Burke'    ,   66, 'Clerk',     1, 10988.00,    55.50),
      (340, 'Edwards'  ,   84, 'Sales',     7, 17844.00,  1285.00),
      (350, 'Gafney'   ,   84, 'Clerk',     5, 13030.50,   188.00)
";
    //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

       // Execute the query
      if($SampleClass->exec($query) === false)
      {
        $SampleClass->format_Output($SampleClass->get_Error());
      }
    }
    $SampleClass->commit();
}

  public static function DROP($SampleClass)
  {

    $query = "
DROP TABLE {$SampleClass->schema}STAFF
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
