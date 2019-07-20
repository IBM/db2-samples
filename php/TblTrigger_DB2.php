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
 * SOURCE FILE NAME: TblTrigger_DB2.php
 *
 * SAMPLE: How to use triggers
 *
 * SQL Statements USED:
 *         CREATE TABLE
 *         CREATE TRIGGER
 *         DROP TABLE
 *         DROP TRIGGER
 *         SELECT
 *         INSERT
 *         UPDATE
 *         DELETE
 *         COMMIT
 *         ROLLBACK
 *
 ****************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 ***************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_DB2.php";
require_once "UtilTableSetup_Staff.php";

class Trigger extends DB2_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO USE TRIGGERS.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }

  // helping function
  public function staff_Tb_Content_Display()
  {
      $toPrintToScreen = "
The Printing the data in the tables: company_a, company_b and salary_change
------------------------------------------------------------------------------
";
      $this->format_Output($toPrintToScreen);

      $query = "
  SELECT ID, NAME, DEPT, JOB, YEARS, SALARY, COMM FROM {$this->schema}staff WHERE id <= 50
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $DataFromTableCompanyA = db2_exec($this->dbconn, $query);

      if($DataFromTableCompanyA)
      {
        $toPrintToScreen = "
| ID   | NAME       | DEPT | JOB        | YEARS | SALARY     | COMM
|------|------------|------|------------|-------|------------|-----------------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($Employee = db2_fetch_assoc($DataFromTableCompanyA))
        {
           $this->format_Output(sprintf("| %4s | %10s | %4s | %10s | %5s | %10s | %s\n",
                                            $Employee['ID'],
                                            $Employee['NAME'],
                                            $Employee['DEPT'],
                                            $Employee['JOB'],
                                            $Employee['YEARS'],
                                            $Employee['SALARY'],
                                            $Employee['COMM']
                                        )
                                );

        }
        db2_free_result($DataFromTableCompanyA);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // staff_Tb_Content_Display

  // helping function
  public function staff_Stats_Tb_Create()
  {
  	     $toPrintToScreen = "
Creating the Table staff_stats:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  CREATE TABLE {$this->schema}staff_stats(nbemp SMALLINT)
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
Insert the total number of staff:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  INSERT INTO {$this->schema}staff_stats VALUES(SELECT COUNT(*) FROM {$this->schema}staff)
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
  } // staff_Stats_Tb_Create

  // helping function
  public function StaffStatsTbContentDisplay()
  {
      $query = "
  SELECT NBEMP FROM {$this->schema}staff_stats
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $DataFromTableCompanyA = db2_exec($this->dbconn, $query);

      if($DataFromTableCompanyA)
      {
        $toPrintToScreen = "
| NBEMP
|---------------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($Employee = db2_fetch_assoc($DataFromTableCompanyA))
        {
           $this->format_Output(sprintf("| %s\n", $Employee['NBEMP']));
        }
        db2_free_result($DataFromTableCompanyA);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // StaffStatsTbContentDisplay

  // helping function
  public function staff_Stats_Tb_Drop()
  {
         $toPrintToScreen = "
Dropping the Table {$this->schema}staff_stats:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TABLE {$this->schema}staff_stats
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
  } // staff_Stats_Tb_Drop

  // helping function
  public function salary_Status_Tb_Create()
  {
         $toPrintToScreen = "
Creating the Table salary_status:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  CREATE TABLE {$this->schema}salary_status(
                                EMP_NAME VARCHAR(9),
                                SALARY DECIMAL(7, 2),
                                STATUS CHAR(15))
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
Insert the name and salary of all staff who's ID <= 50

";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}salary_status
  SELECT NAME, SALARY, 'Not Defined'
    FROM {$this->schema}staff
    WHERE id <= 50

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

  } // salary_Status_Tb_Create

  // helping function
  public function salary_Status_Tb_Content_Display()
  {
      $query = "
  SELECT EMP_NAME, SALARY, STATUS FROM {$this->schema}salary_status
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $DataFromTableCompanyA = db2_exec($this->dbconn, $query);

      if($DataFromTableCompanyA)
      {
        $toPrintToScreen = "
| EMP_NAME   | SALARY     |  STATUS
|------------|------------|--------------------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($Employee = db2_fetch_assoc($DataFromTableCompanyA))
        {
           $this->format_Output(sprintf("| %10s | %10s | %s\n",
                                             $Employee['EMP_NAME'],
                                             $Employee['SALARY'],
                                             $Employee['STATUS']
                                             ));
        }
        db2_free_result($DataFromTableCompanyA);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // salary_Status_Tb_Content_Display

  // helping function
  public function salary_Status_Tb_Drop()
  {
         $toPrintToScreen = "
Dropping the Table salary_status:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TABLE {$this->schema}salary_status
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
  } // salary_Status_Tb_Drop

  // helping function
  public function salary_History_Tb_Create()
  {

         $toPrintToScreen = "
Creating the Table salary_history:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  CREATE TABLE {$this->schema}salary_history(
                                     employee_name VARCHAR(9),
                                     salary_record DECIMAL(7, 2),
                                     change_date DATE)
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
  } // salary_History_Tb_Create

  // helping function
  public function salary_History_Tb_Content_Display()
  {

      $query = "
  SELECT EMPLOYEE_NAME, SALARY_RECORD, CHANGE_DATE FROM {$this->schema}salary_history
";

      $this->format_Output($query);
      //Removing Excess white space.
      $query = preg_replace('/\s+/', " ", $query);

      // Execute the query
      $DataFromTableCompanyA = db2_exec($this->dbconn, $query);

      if($DataFromTableCompanyA)
      {
        $toPrintToScreen = "
| EMPLOYEE_NAME | SALARY_RECORD |  CHANGE_DATE
|---------------|---------------|--------------------
";
        $this->format_Output($toPrintToScreen);
        // retrieve and display the result from the xquery
        while($Employee = db2_fetch_assoc($DataFromTableCompanyA))
        {
           $this->format_Output(sprintf("| %13s | %13s | %s\n",
                                             $Employee['EMPLOYEE_NAME'],
                                             $Employee['SALARY_RECORD'],
                                             $Employee['CHANGE_DATE']
                                             ));
        }
        db2_free_result($DataFromTableCompanyA);
      }
      else
      {
        $this->format_Output(db2_stmt_errormsg());
      }
  } // salary_History_Tb_Content_Display

  // helping function
  public function salary_History_Tb_Drop()
  {
         $toPrintToScreen = "
Dropping the Table salary_history:

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TABLE {$this->schema}salary_history
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
  } // salary_History_Tb_Drop


  public function before_Insert_Trigger_Use()
  {

         $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TRIGGER
  COMMIT
  INSERT
  DROP TRIGGER
TO SHOW A 'BEFORE INSERT' TRIGGER.

";
    $this->format_Output($toPrintToScreen);


    // display the initial content of the 'staff' table
    $this->staff_Tb_Content_Display();
         $toPrintToScreen = "
Create a 'BEFORE INSERT' trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TRIGGER {$this->schema}min_salary
  NO CASCADE BEFORE INSERT
  ON {$this->schema}staff
  REFERENCING NEW AS newstaff
  FOR EACH ROW
  BEGIN ATOMIC
    SET newstaff.salary =
    CASE
      WHEN newstaff.job = 'Mgr'      AND
           newstaff.salary < 17000.00
      THEN 17000.00
      WHEN newstaff.job = 'Sales'    AND
           newstaff.salary < 14000.00
      THEN 14000.00
      WHEN newstaff.job = 'Clerk'    AND
           newstaff.salary < 10000.00
      THEN 10000.00
      ELSE newstaff.salary
    END;
  END
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

         $toPrintToScreen = "
Insert table data using values

";
    $this->format_Output($toPrintToScreen);

    $query = "
INSERT INTO {$this->schema}staff(id, name, dept, job, salary)
  VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),
        (35, 'Hachey', 38, 'Mgr', 21270.00),
        (45, 'Wagland', 38, 'Sales', 11575.00)
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


    // display the final content of the 'staff' table
    $this->staff_Tb_Content_Display();

    $this->commit();


         $toPrintToScreen = "
Drop the trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TRIGGER {$this->schema}min_salary
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
  } // before_Insert_Trigger_Use

  public function after_Insert_Trigger_Use()
  {
         $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TRIGGER
  COMMIT
  INSERT
  DROP TRIGGER
TO SHOW AN 'AFTER INSERT' TRIGGER.

";
    $this->format_Output($toPrintToScreen);


    // create a table called 'staff_stats'
    $this->staff_Stats_Tb_Create();

    // display the content of the 'staff_stats' table
    $this->StaffStatsTbContentDisplay();

         $toPrintToScreen = "
Create an 'AFTER INSERT' trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TRIGGER {$this->schema}new_hire
  AFTER INSERT
  ON {$this->schema}staff
  FOR EACH ROW
  BEGIN ATOMIC
    UPDATE {$this->schema}staff_stats
    SET nbemp = nbemp + 1;
  END
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

         $toPrintToScreen = "
Insert table data using values
  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    INSERT INTO {$this->schema}staff(id, name, dept, job, salary)
      VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),
            (35, 'Hachey', 38, 'Mgr', 21270.00),
            (45, 'Wagland', 38, 'Sales', 11575.00)
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

      // display the content of the 'staff_stats' table
      $this->StaffStatsTbContentDisplay();

    $this->commit();


         $toPrintToScreen = "
Drop the trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TRIGGER {$this->schema}new_hire
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

    // drop the 'staff_stats' table
    $this->staff_Stats_Tb_Drop();

  } // after_Insert_Trigger_Use

  public function before_Delete_Trigger_Use()
  {
          $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TRIGGER
  COMMIT
  DELETE
  DROP TRIGGER
TO SHOW A 'BEFORE DELETE' TRIGGER.

";
    $this->format_Output($toPrintToScreen);

    // display the initial content of the 'staff' table
    $this->staff_Tb_Content_Display();

         $toPrintToScreen = "
Create a 'BEFORE DELETE' trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TRIGGER {$this->schema}do_not_del_sales
  NO CASCADE BEFORE DELETE
  ON {$this->schema}staff
  REFERENCING OLD AS oldstaff
  FOR EACH ROW
  WHEN (oldstaff.job = 'Sales')
  BEGIN ATOMIC
    SIGNAL SQLSTATE '75000'
    ('Sales can not be deleted now.');
  END
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

         $toPrintToScreen = "
Delete data from the 'staff' table
  Invoke the statement:
(This statement is expected to fail because of the trigger above)
";
    $this->format_Output($toPrintToScreen);

    $query = "
    DELETE FROM {$this->schema}staff WHERE id <= 50
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

    // display the final content of the 'staff' table
    $this->staff_Tb_Content_Display();

    $this->commit();


         $toPrintToScreen = "
Drop the trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TRIGGER {$this->schema}do_not_del_sales
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
  } // before_Delete_Trigger_Use

  public function before_Update_Trigger_Use()
  {
          $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TRIGGER
  COMMIT
  DELETE
  DROP TRIGGER
TO SHOW A 'BEFORE UPDATE' TRIGGER.

";
    $this->format_Output($toPrintToScreen);

    // create a table called salary_status
    $this->salary_Status_Tb_Create();

    // display the content of the 'salary_status' table
    $this->salary_Status_Tb_Content_Display();

         $toPrintToScreen = "
Create a 'BEFORE UPDATE' trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TRIGGER {$this->schema}sal_status
  NO CASCADE BEFORE UPDATE OF SALARY
  ON {$this->schema}salary_status
  REFERENCING NEW AS new OLD AS old
  FOR EACH ROW
  BEGIN ATOMIC
    SET new.status =
    CASE
      WHEN new.SALARY < old.SALARY
      THEN 'Decreasing'
      WHEN new.SALARY > old.SALARY
      THEN 'Increasing'
    END;
  END
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

         $toPrintToScreen = "
Update data in table 'salary_status'
  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    UPDATE {$this->schema}salary_status SET SALARY = 18000.00
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

    // display the content of the 'salary_status' table
    $this->salary_Status_Tb_Content_Display();

    $this->commit();


         $toPrintToScreen = "
Drop the trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TRIGGER {$this->schema}sal_status
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

    // drop salary_status table
    $this->salary_Status_Tb_Drop();

  } // before_Update_Trigger_Use

  public function after_Update_Trigger_Use()
  {
          $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TRIGGER
  COMMIT
  UPDATE
  DROP TRIGGER
TO SHOW AN 'AFTER UPDATE' TRIGGER.

";
    $this->format_Output($toPrintToScreen);

    // create a table called 'salary_history'
    $this->salary_History_Tb_Create();

    // display the content of the 'salary_history' table
    $this->salary_History_Tb_Content_Display();

         $toPrintToScreen = "
Create a 'AFTER UPDATE' trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TRIGGER {$this->schema}sal_history
  AFTER UPDATE OF salary
  ON {$this->schema}staff
  REFERENCING NEW AS newstaff
  FOR EACH ROW
  BEGIN ATOMIC
    INSERT INTO {$this->schema}salary_history
      VALUES(newstaff.name,
             newstaff.salary,
             CURRENT DATE);
  END
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

         $toPrintToScreen = "
Update table data
  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    UPDATE {$this->schema}staff SET salary = 20000.00 WHERE name = 'Sanders'
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

  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    UPDATE {$this->schema}staff SET salary = 21000.00 WHERE name = 'Sanders'
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

  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    UPDATE {$this->schema}staff SET salary = 23000.00 WHERE name = 'Sanders'
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

  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    UPDATE {$this->schema}staff SET salary = 20000.00 WHERE name = 'Hanes'
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

  Invoke the statement:

";
    $this->format_Output($toPrintToScreen);

    $query = "
    UPDATE {$this->schema}staff SET salary = 21000.00 WHERE name = 'Hanes'
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

    // display the content of the 'salary_history' table
    $this->salary_History_Tb_Content_Display();

    $this->commit();

         $toPrintToScreen = "
Drop the trigger

";
    $this->format_Output($toPrintToScreen);

    $query = "
  DROP TRIGGER {$this->schema}sal_history
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
    $this->commit();;

    // drop the 'salary_history' table
    $this->salary_History_Tb_Drop();

  } // after_Update_Trigger_Use
} // TbTrig

$Run_Sample = new Trigger();

TABLE_SETUP_General_Staff::CREATE($Run_Sample);

$Run_Sample->before_Insert_Trigger_Use();
$Run_Sample->after_Insert_Trigger_Use();
$Run_Sample->before_Delete_Trigger_Use();
$Run_Sample->before_Update_Trigger_Use();
$Run_Sample->after_Update_Trigger_Use();


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

TABLE_SETUP_General_Staff::DROP($Run_Sample);

// Close the database connection
$Run_Sample->close_Connection();

?>
