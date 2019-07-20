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
 * SOURCE FILE NAME: TblConstraints_PDO.php
 *
 * SAMPLE: How to create, use and drop constraints
 *
 * SQL Statements USED:
 *         CREATE TABLE
 *         DROP TABLE
 *         DELETE
 *         COMMIT
 *         ROLLBACK
 *         INSERT
 *         ALTER
 *
 ***************************************************************************
 *
 * For more information on the sample programs, see the README file.
 *
 **************************************************************************/

require_once "UtilIOHelper.php";
require_once "UtilConnection_PDO.php";

class TableConstraints extends PDO_Connection
{
  public $SAMPLE_HEADER =
"
echo '
THIS SAMPLE SHOWS HOW TO CREATE, USE AND DROP CONSTRAINTS.
';
";
  function __construct($initialize = true)
  {
      parent::__construct($initialize);
      $this->make_Connection();
  }

  // helping function: This function creates two foreign keys
  public function FK_Two_Tables_Create()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
|    Create tables for FOREIGN KEY sample functions
------------------------------------------------------------------------------
";
    $this->format_Output($toPrintToScreen);

    $query = "
CREATE TABLE {$this->schema}emp_dept(deptno CHAR(3) NOT NULL,
                  deptname VARCHAR(20),
                  CONSTRAINT pk_dept
                  PRIMARY KEY(deptno))
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $query = "
INSERT INTO {$this->schema}emp_dept VALUES('A00', 'ADMINISTRATION'),
                       ('B00', 'DEVELOPMENT'),
                       ('C00', 'SUPPORT')
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $query = "
CREATE TABLE {$this->schema}emp_sal(empno CHAR(4),
                 empname VARCHAR(10),
                 dept_no CHAR(3))
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $query = "
INSERT INTO {$this->schema}emp_sal VALUES('0010', 'Smith', 'A00'),
                      ('0020', 'Ngan', 'B00'),
                      ('0030', 'Lu', 'B00'),
                      ('0040', 'Wheeler', 'B00'),
                      ('0050', 'Burke', 'C00'),
                      ('0060', 'Edwards', 'C00'),
                      ('0070', 'Lea', 'C00')
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }


    $this->commit();

  } // FK_Two_Tables_Create

  // helping function
  public function FK_Two_Tables_Display()
  {
    $query = "
SELECT DEPTNO, DEPTNAME FROM {$this->schema}emp_dept
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    // Execute the query
    $DataFromTabledept = $this->PDOconn->query($query);
    $toPrintToScreen = "
| DEPTNO | DEPTNAME
|--------|---------------
";
    $this->format_Output($toPrintToScreen);
    if($DataFromTabledept)
    {
      // retrieve and display the result from the xquery
      while($Dept = $DataFromTabledept->fetch(PDO::FETCH_ASSOC))
      {
         $this->format_Output(sprintf("| %6s | %s \n",
                                          $Dept['DEPTNO'],
                                          $Dept['DEPTNAME']
                                      )
                              );

      }
    }
    else
    {
      $stmtError = $DataFromTableSalaryChange->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }

    $query = "
SELECT EMPNO, EMPNAME, DEPT_NO FROM {$this->schema}emp_sal
";

    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    // Execute the query
    $DataFromTableemp = $this->PDOconn->query($query);
    $toPrintToScreen = "
| EMPNO | EMPNAME    | DEPT_NO
|-------|------------|----------
";
    $this->format_Output($toPrintToScreen);
    if($DataFromTableemp)
    {
      // retrieve and display the result from the xquery
      while($Dept = $DataFromTableemp->fetch(PDO::FETCH_ASSOC))
      {
         $this->format_Output(sprintf("| %5s | %10s | %s\n",
                                          $Dept['EMPNO'],
                                          $Dept['EMPNAME'],
                                          ($Dept['DEPT_NO'] === null ? "-" : $Dept['DEPT_NO'])
                                      )
                              );

      }
    }
    else
    {
      $stmtError = $DataFromTableSalaryChange->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }

  } // FK_Two_Tables_Display

  // helping function
  public function FK_Two_Tables_Drop()
  {

    $toPrintToScreen = "
------------------------------------------------------------------------------
|    Drop tables created for FOREIGN KEY sample functions
------------------------------------------------------------------------------
";
    $this->format_Output($toPrintToScreen);

    $query = "
DROP TABLE {$this->schema}emp_dept
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $query = "
DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $this->commit();
  } // FK_Two_Tables_Drop


  // helping function
  public function FK_Create($ruleClause)
  {
    $query = "
ALTER TABLE {$this->schema}emp_sal
    ADD CONSTRAINT fk_dept
    FOREIGN KEY(dept_no)\n
    REFERENCES {$this->schema}emp_dept(deptno)
    $ruleClause
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

  } // FK_Create


  // helping function
  public function FK_Drop()
  {
    $query = "
ALTER TABLE {$this->schema}emp_sal DROP CONSTRAINT fk_dept
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();
  } // FK_Drop

  // This function demonstrates how to use a 'NOT NULL' constraint.
  public function demo_NOT_NULL()
  {
     $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TABLE
  COMMIT
  INSERT
  DROP TABLE
TO SHOW A 'NOT NULL' CONSTRAINT.
";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "

Create a table called emp_sal with a 'NOT NULL' constraint
";

    $this->format_Output($toPrintToScreen);

    $query = "
  CREATE TABLE {$this->schema}emp_sal(lastname VARCHAR(10) NOT NULL,
                      firstname VARCHAR(10),
                       salary DECIMAL(7, 2))
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Insert a row in the table emp_sal with NULL as the lastname.
This insert will fail with an expected error.
";
    $this->format_Output($toPrintToScreen);

    $query = "
  INSERT INTO {$this->schema}emp_sal VALUES(NULL, 'PHILIP', 17000.00)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Drop the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();
  } // demo_NOT_NULL

  // This function demonstrates how to use a 'UNIQUE' constraint.
  public function demo_UNIQUE()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TABLE
  COMMIT
  INSERT
  ALTER TABLE
  DROP TABLE
TO SHOW A 'UNIQUE' CONSTRAINT.
";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "

Create a table called emp_sal with a 'UNIQUE' constraint
";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}emp_sal(lastname VARCHAR(10) NOT NULL,
                    firstname VARCHAR(10) NOT NULL,
                    salary DECIMAL(7, 2),
                    CONSTRAINT unique_cn
                    UNIQUE(lastname, firstname))
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Insert two rows into the table emp_sal that have the same lastname
and firstname values. The insert will fail with an expected error
because the rows violate the PRIMARY KEY constraint.
";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}emp_sal VALUES('SMITH', 'PHILIP', 17000.00),
                            ('SMITH', 'PHILIP', 21000.00)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Drop the 'UNIQUE' constraint on the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  ALTER TABLE {$this->schema}emp_sal DROP CONSTRAINT unique_cn
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Drop the table {$this->schema}emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $this->commit();

  } // demo_UNIQUE

  // This function demonstrates how to use a 'PRIMARY KEY' constraint.
  public function demo_PRIMARY_KEY()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TABLE
  COMMIT
  INSERT
  ALTER TABLE
  DROP TABLE
TO SHOW A 'PRIMARY KEY' CONSTRAINT.
";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "

Create a table called emp_sal with a 'PRIMARY KEY' constraint
";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}emp_sal(lastname VARCHAR(10) NOT NULL,
                     firstname VARCHAR(10) NOT NULL,
                     salary DECIMAL(7, 2),
                     CONSTRAINT pk_cn
                     PRIMARY KEY(lastname, firstname))
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Insert two rows into the table emp_sal that have the same lastname
 and firstname values. The insert will fail with an expected error
 because the rows violate the PRIMARY KEY constraint.
";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO emp_sal {$this->schema}VALUES('SMITH', 'PHILIP', 17000.00),
                            ('SMITH', 'PHILIP', 21000.00)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Drop the 'PRIMARY KEY' constraint on the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  ALTER TABLE {$this->schema}emp_sal DROP CONSTRAINT pk_cn
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Drop the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();
  } // demo_PRIMARY_KEY

  // This function demonstrates how to use a 'CHECK' constraint.
  public function demo_CHECK()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TABLE
  COMMIT
  INSERT
  ALTER TABLE
  DROP TABLE
TO SHOW A 'CHECK' CONSTRAINT.
";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "

Create a table called emp_sal with a 'CHECK' constraint
";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}emp_sal(lastname VARCHAR(10),
                     firstname VARCHAR(10),
                     salary DECIMAL(7, 2),
                     CONSTRAINT check_cn
                     CHECK(salary < 25000.00))
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Insert a row in the table emp_sal that violates the rule defined
 in the 'CHECK' constraint. This insert will fail with an expected
 error.
";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}emp_sal VALUES('SMITH', 'PHILIP', 27000.00)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Drop the 'CHECK' constraint on the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  ALTER TABLE {$this->schema}emp_sal DROP CONSTRAINT check_cn
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Drop the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();
  } // demo_CHECK

  // This function demonstrates how to use an 'INFORMATIONAL' constraint.
  public function demo_CHECK_INFO()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TABLE
  COMMIT
  INSERT
  ALTER TABLE
  DROP TABLE
TO SHOW AN 'INFORMATIONAL' CONSTRAINT.
";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "

Create a table called emp_sal with a 'CHECK' constraint
";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}emp_sal(empno INTEGER NOT NULL PRIMARY KEY,
                  name VARCHAR(10),
                  firstname VARCHAR(20),
                  salary INTEGER CONSTRAINT minsalary
                         CHECK (salary >= 25000)
                         NOT ENFORCED
                         ENABLE QUERY OPTIMIZATION)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Insert data that doesn't satisfy the constraint 'minsalary'.
 database manager does not enforce the constraint for IUD operations

TO SHOW NOT ENFORCED OPTION

";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}emp_sal VALUES(1, 'SMITH', 'PHILIP', 1000)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Alter the constraint to make it ENFORCED by database manager

This is expected to fail because a row exists that violates the constraint

";
    $this->format_Output($toPrintToScreen);
    $query = "
  ALTER TABLE {$this->schema}emp_sal ALTER CHECK minsalary ENFORCED
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Delete entries from emp_sal Table
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Alter the constraint to make it ENFORCED by database manager

TO SHOW ENFORCED OPTION
";
    $this->format_Output($toPrintToScreen);
    $query = "
  ALTER TABLE {$this->schema}emp_sal ALTER CHECK minsalary ENFORCED
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();


    $toPrintToScreen = "

Insert table with data not conforming to the constraint 'minsalary'
 database manager enforces the constraint for IUD operations
";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}emp_sal VALUES(1, 'SMITH', 'PHILIP', 1000)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
     try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Drop table
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

  } // demo_CHECK_INFO

  // This function demonstrates how to use a 'WITH DEFAULT' constraint.
  public function demo_WITH_DEFAULT()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  CREATE TABLE
  COMMIT
  INSERT
  ALTER TABLE
  DROP TABLE
TO SHOW A 'WITH DEFAULT' CONSTRAINT.
";
    $this->format_Output($toPrintToScreen);

    $toPrintToScreen = "

Create a table called emp_sal with a 'WITH DEFAULT' constraint
";
    $this->format_Output($toPrintToScreen);
    $query = "
CREATE TABLE {$this->schema}emp_sal(lastname VARCHAR(10),
                     firstname VARCHAR(10),
                     salary DECIMAL(7, 2)
  WITH DEFAULT 17000.00)
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Insert three rows into the table emp_sal, without any value for the
 the third column. Since the third column is defined with a default
 value of 17000.00, the third column for each of these three rows
 will be set to 17000.00.
";
    $this->format_Output($toPrintToScreen);
    $query = "
INSERT INTO {$this->schema}emp_sal(lastname, firstname)
    VALUES('SMITH' , 'PHILIP'),
          ('PARKER', 'JOHN'  ),
          ('PEREZ' , 'MARIA' )
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();

    $toPrintToScreen = "

Retrieve and display the data in the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  SELECT FIRSTNAME, LASTNAME, SALARY FROM {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

    $DataFromTableEmp_sal = $this->PDOconn->query($query);

    if($DataFromTableEmp_sal)
    {
      $toPrintToScreen = "
| FIRSTNAME  |  LASTNAME  | SALARY
--------------------------------------
";
      $this->format_Output($toPrintToScreen);
      // retrieve and display the result from the xquery
      while($SalaryEntry = $DataFromTableEmp_sal->fetch(PDO::FETCH_ASSOC))
      {
         $this->format_Output(sprintf("| %10s | %10s | %s\n",
                                          $SalaryEntry['FIRSTNAME'],
                                          $SalaryEntry['LASTNAME'],
                                          $SalaryEntry['SALARY']
                                      )
                              );
       }
    }
    else
    {
      $stmtError = $DataFromTableSalaryChange->errorInfo();
      $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
    }

    $toPrintToScreen = "

Drop the table emp_sal
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DROP TABLE {$this->schema}emp_sal
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }
    $this->commit();
  } // demo_WITH_DEFAULT

  // This function demonstrates how to insert into a foreign key
  public function demo_FK_On_Insert_Show()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  COMMIT
  INSERT
  ALTER TABLE
  ROLLBACK
TO SHOW HOW A FOREIGN KEY WORKS ON INSERT.
";
    $this->format_Output($toPrintToScreen);

    // display the initial content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // create a foreign key on the 'emp_sal' table that reference the 'emp_dept'
    // table
    $this->FK_Create("");


    $toPrintToScreen = "

Insert an entry into the parent table, 'emp_dept'
";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}emp_dept VALUES('D00', 'SALES')
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Insert an entry into the child table, 'emp_sal'

This is expected to fail because there is not a key of the value ‘0080’ in the table emp_dept

";
    $this->format_Output($toPrintToScreen);
    $query = "
  INSERT INTO {$this->schema}emp_sal VALUES('0080', 'Pearce', 'E03')
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the final content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    $this->commit();

    // drop the foreign key
    $this->FK_Drop();
  } // demo_FK_On_Insert_Show

  // This function demonstrates how to use an 'ON UPDATE NO ACTION'
  // foreign key
  public function demo_FK_ON_UPDATE_NO_ACTION()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  COMMIT
  INSERT
  ALTER TABLE
  ROLLBACK
TO SHOW AN 'ON UPDATE NO ACTION' FOREIGN KEY.
";
    $this->format_Output($toPrintToScreen);

    // display the initial content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // create an 'ON UPDATE NO ACTION' foreign key
    $this->FK_Create("ON UPDATE NO ACTION");


    $toPrintToScreen = "

Update parent table

This change will violate the Foreign Key Constraint
the update is expected to fail.

";
    $this->format_Output($toPrintToScreen);
    $query = "
  UPDATE {$this->schema}emp_dept SET deptno = 'E01' WHERE deptno = 'A00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Update the parent table, 'emp_dept'

";
    $this->format_Output($toPrintToScreen);
    $query = "
  UPDATE {$this->schema}emp_dept
    SET deptno = CASE
             WHEN deptno = 'A00' THEN 'B00'
             WHEN deptno = 'B00' THEN 'A00'
                END
    WHERE deptno = 'A00' OR deptno = 'B00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Update the child table, 'emp_sal'

This change will violate the Foreign Key Constraint
the update is expected to fail.

";
    $this->format_Output($toPrintToScreen);
    $query = "
  UPDATE {$this->schema}emp_sal SET dept_no = 'G11' WHERE empname = 'Wheeler'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the final content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    $this->commit();

    // drop the foreign key
    $this->FK_Drop();
  } // demo_FK_ON_UPDATE_NO_ACTION

  // This function demonstrates how to use an 'ON UPDATE RESTRICT'
  // foreign key
  public function demo_FK_ON_UPDATE_RESTRICT()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  COMMIT
  INSERT
  ALTER TABLE
  ROLLBACK
TO SHOW AN 'ON UPDATE RESTRICT' FOREIGN KEY.
";
    $this->format_Output($toPrintToScreen);

    // display the initial content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // create an 'ON UPDATE RESTRICT' foreign key
    $this->FK_Create("ON UPDATE RESTRICT");


    $toPrintToScreen = "

Update the parent table, 'emp_dept', with data that violates the 'ON
 UPDATE RESTRICT' foreign key. An error is expected to be returned.
";
    $this->format_Output($toPrintToScreen);
    $query = "
  UPDATE {$this->schema}emp_dept SET deptno = 'E01' WHERE deptno = 'A00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Update the parent table, 'emp_dept', with data that violates the 'ON
 UPDATE RESTRICT' foreign key. An error is expected to be returned.
";
    $this->format_Output($toPrintToScreen);
    $query = "
  UPDATE {$this->schema}emp_dept
    SET deptno = CASE
                 WHEN deptno = 'A00' THEN 'B00'
                 WHEN deptno = 'B00' THEN 'A00'
               END
    WHERE deptno = 'A00' OR deptno = 'B00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Update the child table, 'emp_sal', with data that violates the 'ON
 UPDATE RESTRICT' foreign key. An error is expected to be returned.
";
    $this->format_Output($toPrintToScreen);
    $query = "
  UPDATE {$this->schema}emp_sal SET dept_no = 'G11' WHERE empname = 'Wheeler'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->format_Output("\n|~~~~~~~~EXPECTED ERROR~~~~~~~~|\n");
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the final content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    $this->commit();

    // drop the foreign key
    $this->FK_Drop();

  } // demo_FK_ON_UPDATE_RESTRICT

  // This function demonstrates how to use an 'ON DELETE CASCADE' foreign key
  public function demo_FK_ON_DELETE_CASCADE()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  COMMIT
  INSERT
  ALTER TABLE
  ROLLBACK
TO SHOW AN 'ON DELETE CASCADE' FOREIGN KEY.
";
    $this->format_Output($toPrintToScreen);

    // display the initial content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // create an 'ON DELETE CASCADE' foreign key
    $this->FK_Create("ON DELETE CASCADE");

    $toPrintToScreen = "

Delete from the parent table, 'emp_dept'
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_dept WHERE deptno = 'C00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    $toPrintToScreen = "

Display the content of the 'emp_dept' and 'emp_sal' table
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_sal WHERE empname = 'Wheeler'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();


    $this->commit();

    // drop the foreign key
    $this->FK_Drop();

  } // demo_FK_ON_DELETE_CASCADE

  // This function demonstrates how to use an 'ON DELETE SET NULL'
  // foreign key
  public function demo_FK_ON_DELETE_SET_NULL()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  COMMIT
  INSERT
  ALTER TABLE
  ROLLBACK
TO SHOW AN 'ON DELETE SET NULL' FOREIGN KEY.
";
    $this->format_Output($toPrintToScreen);


    // display the initial content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // create an 'ON DELETE SET NULL' foreign key
    $this->FK_Create("ON DELETE SET NULL");


    $toPrintToScreen = "

Delete from the parent table, 'emp_dept'
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_dept WHERE deptno = 'C00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    $toPrintToScreen = "

Delete from the child table, 'emp_sal'
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_sal WHERE empname = 'Wheeler'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the final content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    $this->commit();

    // drop the foreign key
    $this->FK_Drop();

  } // demo_FK_ON_DELETE_SET_NULL

  // This function demonstrates how to use an 'ON DELETE NO ACTION'
  // foreign key
  public function demo_FK_ON_DELETE_NO_ACTION()
  {
    $toPrintToScreen = "
----------------------------------------------------------
USE THE SQL STATEMENTS:
  COMMIT
  INSERT
  ALTER TABLE
  ROLLBACK
TO SHOW AN 'ON DELETE NO ACTION' FOREIGN KEY.
";
    $this->format_Output($toPrintToScreen);

    // display the initial content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // create an 'ON DELETE NO ACTION' foreign key
    $this->FK_Create("ON DELETE NO ACTION");

    $toPrintToScreen = "

Delete from the parent table, 'emp_dept'

";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_dept WHERE deptno = 'C00'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }


    $toPrintToScreen = "

Delete from the child table, 'emp_sal'
";
    $this->format_Output($toPrintToScreen);
    $query = "
  DELETE FROM {$this->schema}emp_sal WHERE empname = 'Wheeler'
";
    $this->format_Output($query);
    //Removing Excess white space.
    $query = preg_replace('/\s+/', " ", $query);

     // Execute the query
    try
    {
      $this->PDOconn->exec($query);
      if(strcmp($this->PDOconn->errorCode(), "00000"))
      {
        $stmtError = $InsertNewEmployee_stmt->errorInfo();
        $this->format_Output("\n\n" . $stmtError[0] . " - " . $stmtError[1] . ", " . $stmtError[2] . "\n\n");
      }
      else
      {
        $this->format_Output("Succeeded \n");
      }
    }
    catch (PDOException $e)
    {
      $this->format_Output($e->getMessage() . "\n\n");
    }

    // display the final content of the 'emp_dept' and 'emp_sal' table
    $this->FK_Two_Tables_Display();

    // roll back the transaction
    $this->commit();

    // drop the foreign key
    $this->FK_Drop();
  } // demo_FK_ON_DELETE_NO_ACTION
} // TbConstr


$Run_Sample = new TableConstraints();

$Run_Sample->demo_NOT_NULL();
$Run_Sample->demo_UNIQUE();
$Run_Sample->demo_PRIMARY_KEY();
$Run_Sample->demo_CHECK();
$Run_Sample->demo_CHECK_INFO();
$Run_Sample->demo_WITH_DEFAULT();

$Run_Sample->FK_Two_Tables_Create();

$Run_Sample->demo_FK_On_Insert_Show();
$Run_Sample->demo_FK_ON_UPDATE_NO_ACTION();
$Run_Sample->demo_FK_ON_UPDATE_RESTRICT();
$Run_Sample->demo_FK_ON_DELETE_CASCADE();
$Run_Sample->demo_FK_ON_DELETE_SET_NULL();
$Run_Sample->demo_FK_ON_DELETE_NO_ACTION();

$Run_Sample->FK_Two_Tables_Drop();


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
