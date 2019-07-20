#!/usr/bin/perl
############################################################################
# (c) Copyright IBM Corp. 2007 All rights reserved.
# 
# The following sample of source code ("Sample") is owned by International 
# Business Machines Corporation or one of its subsidiaries ("IBM") and is 
# copyrighted and licensed, not sold. You may use, copy, modify, and 
# distribute the Sample in any form without payment to IBM, for the purpose of 
# assisting you in the development of your applications.
# 
# The Sample code is provided to you on an "AS IS" basis, without warranty of 
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
# not allow for the exclusion or limitation of implied warranties, so the above 
# limitations or exclusions may not apply to you. IBM shall not be liable for 
# any damages you suffer as a result of using, copying, modifying or 
# distributing the Sample, even if IBM has been advised of the possibility of 
# such damages.
############################################################################
#
# SOURCE FILE NAME: tbsel.pl
#
# SAMPLE: How to select from each of: insert, update, delete
#
# CREATING TABLES FOR THIS SAMPLE (Must be done prior to compiling/running
# the sample):
# Enter "tbselinit" while in the samples/perl directory to create the
# tables used by this sample.  The tbselinit script (UNIX and Linux)
# or tbselinit.bat batch file (Windows) connects to the database,
# runs tbseldrop.db2 to drop the tables if they previously existed, runs
# tbselcreate.db2 which creates the sample tables, then disconnects from
# the database.
#
# SQL STATEMENTS USED:
#         INCLUDE
#         INSERT
#         SELECT FROM INSERT
#         SELECT FROM UPDATE
#         SELECT FROM DELETE
#         DROP TABLE
#
# OUTPUT FILE: tbsel.out (available in the online documentation)
############################################################################
#
# For more information on the sample programs, see the README file.
#
# For information on developing Perl applications, see the Application
# Development Guide.
#
# For information on using SQL statements, see the SQL Reference.
#
# For the latest information on programming, building, and running DB2
# applications, visit the DB2 application development website:
#     http://www.software.ibm.com/data/db2/udb/ad
############################################################################
select STDERR; $|=1;
select STDOUT; $|=1;

use DBI;
use strict;
use warnings; 


# access the module for DB2 Sample Utility functions
use DB2SampUtil;

# check and parse the command line arguments
my ($database, $user, $password) = CmdLineArgChk(@ARGV);

# declare return code, statement handler, database handler and local variable
my ($rc, $sth, $dbh);

print "\nTHIS SAMPLE SHOWS HOW TO SELECT FROM EACH OF: INSERT, UPDATE,";
print " DELETE.\n";

# connect to the database
print "\n  Connecting to '$database' database...\n";
$dbh = DBI->connect($database, $user, $password, {AutoCommit =>0})
            || die "Can't connect to $database: $DBI::errstr";
print "  Connected to database.\n";

# call the Insert subroutine
Insert();

# call the Print subroutine
Print();

# call the Buy_company subroutine       
Buy_company();
       
# call the Print subroutine again
Print();

# call the Drop subroutine       
Drop();

# disconnect from the database
print "\n  Disconnecting from database...";
$dbh->disconnect
  || die "Can't disconnect from database: $DBI::errstr";
print "\n  Disconnected from database.\n";


#############################################################################
# Description: The Insert subroutine populates the tables used by this
#              sample.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub Insert 
{
  my $sql;

  # please see tbselcreate.db2 for the table definitions.
  # The context for this sample is that of a Company B taking over
  # a Company A.  This sample illustrates how company B incorporates
  # data from table company_b into table company_a.

  print "\nINSERT INTO company_a VALUES";
  print "\n (5275, 'Sanders', 20, 'Mgr', 15, 18357.50),";
  print "\n (5265, 'Pernal', 20, 'Sales', 1, 18171.25),";
  print "\n (5791, 'O\'Brien', 38, 'Sales', 10, 18006.00)\n";

  # populate table company_a with data. 
  $sql = qq(INSERT INTO company_a
                 VALUES(5275, 'Sanders', 20, 'Mgr', 15, 18357.50),
                       (5265, 'Pernal', 20, 'Sales', 1, 18171.25),
                       (5791, 'O\'\'Brien', 38, 'Sales', 10, 18006.00));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  print "\nINSERT INTO company_b VALUES\n";
  print " (default, 'Naughton', 38, 'Clerk', 0,";
  print " 12954.75, 'No Benefits', 0), \n";
  print " (default, 'Yamaguchi', 42, 'Clerk', 6,";
  print " 10505.90, 'Basic Health Coverage', 0),\n";
  print " (default, 'Fraye', 51, 'Mgr', 6,";
  print " 21150.00, 'Basic Health Coverage', 0), \n";
  print " (default, 'Williams', 51, 'Sales', 6,";
  print " 19456.50, 'Basic Health Coverage', 0), \n";
  print " (default, 'Molinare', 10, 'Mgr', 7,";
  print " 22959.20, 'Basic Health Coverage', 0)\n";

  # populate table company_b with data.  
  $sql = qq(INSERT INTO company_b
               VALUES(default, 'Naughton', 38, 'Clerk', 0,
                        12954.75, 'No Benefits', 0),
                     (default, 'Yamaguchi', 42, 'Clerk', 6,
                        10505.90, 'Basic Health Coverage', 0),
                     (default, 'Fraye', 51, 'Mgr', 6,
                        21150.00, 'Basic Health Coverage', 0),
                     (default, 'Williams', 51, 'Sales', 6,
                        19456.50, 'Basic Health Coverage', 0),
                     (default, 'Molinare', 10, 'Mgr', 7,
                        22959.20, 'Basic Health Coverage', 0));

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # Insert

#############################################################################
# Description: The Buy_company function encapsulates the table updates after 
#              Company B takes over Company A. Each employee from table
#              company_a is allocated a benefits package. The employee data
#              is moved into table company_b. Each employee's salary is 
#              increased by 5%. The old and new salaries are recorded in a
#              table salary_change.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub Buy_company
{
  # declare local variables  
  my ($id, $name, $department, $job, $years, $salary, $benefits);
  
  # the following SELECT statement references a DELETE statement in its
  # FROM clause.  It deletes all rows from company_a, selecting all deleted
  # rows into the cursor c1.

  my $sql = qq(SELECT ID, NAME, DEPARTMENT, JOB, YEARS, SALARY
                 FROM OLD TABLE (DELETE FROM company_a));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # the following while loop iterates through each employee of table
  # company_a.   

  while (($id,$name,$department,$job,$years,$salary) = $sth->fetchrow_array)
  {
    # The following if statement sets the new employee's benefits based on
    # their years of experience.
    if($years > 14)
    {
      $benefits = 'Advanced Health Coverage and Pension Plan';
    }
    elsif($years > 9)
    {
      $benefits = 'Advanced Health Coverage';
    }
    elsif($years > 4)
    {
      $benefits = 'Basic Health Coverage';
    }
    else
    {
      $benefits = 'No Benefits';
    }
    
    # escape the ' character, if any, in the employee name.
    $_ = $name;
    s/\'/\'\'/;
    $name = $_;

    # the following SELECT statement references an INSERT statement in its
    # FROM clause.  It inserts an employee record from host variables into
    # table company_b.  The current employee ID from the cursor is selected
    # into the host variable new_id.  The keywords FROM FINAL TABLE
    # determine that the value in new_id is the value of ID after the
    # INSERT statement is complete.
    #
    # Note that the ID column in table company_b is generated and without
    # the SELECT statement an additional query would have to be made in
    # order to retrieve the employee's ID number.
    
    $sql = qq(SELECT ID FROM FINAL TABLE(INSERT INTO company_b 
                   VALUES(default, '$name', $department, '$job',
                            $years, $salary, '$benefits', $id)));

    # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
    my $sth1 = PrepareExecuteSql($dbh, $sql);
    
    my ($new_id) = $sth1->fetchrow_array;

    # no more data to be fetched from statement handle
    $rc = $sth1->finish;
    
    # the following SELECT statement references an UPDATE statement in its
    # FROM clause.  It updates an employee's salary by giving them a 5%
    # raise.  The employee's id, old salary and current salary are all read
    # into host variables for later use in this function.

    # the INCLUDE statement works by creating a temporary column to keep
    # track of the old salary.  This temporary column is only available
    # for this statement and is gone once the statement completes.  The
    # only way to keep this data after the statement completes is to
    # read it into a host variable.

    $sql = qq(SELECT ID, OLD_SALARY, SALARY 
                   FROM FINAL TABLE (UPDATE company_b INCLUDE
                                    (OLD_SALARY DECIMAL(7,2))
                                    SET OLD_SALARY = SALARY,
                                        SALARY = SALARY * 1.05
                                    WHERE ID = $new_id));
    
    # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
    $sth1 = PrepareExecuteSql($dbh, $sql);

    my ($id, $old_salary, $salary) = $sth1->fetchrow_array;

    # no more data to be fetched from statement handle
    $rc = $sth1->finish;

    # this INSERT statement inserts an employee's id, old salary and current
    # salary into the salary_change table.

    $sql = qq(INSERT INTO salary_change 
                   VALUES($id, $old_salary, $salary));

    # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
    $sth1 = PrepareExecuteSql($dbh, $sql);
    
    # no more data to be fetched from statement handle
    $rc = $sth1->finish;
  }
  
  # the following DELETE statement references a SELECT statement in its FROM
  # clause.  It lays off the highest paid manager.  This DELETE statement
  # removes the manager from the table company_b.
  $sql = qq(DELETE FROM 
                 (SELECT * FROM company_b 
                    ORDER BY SALARY DESC FETCH FIRST ROW ONLY));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # the following UPDATE statement references a SELECT statement in its FROM
  # clause.  It gives the most senior employee a $10000 bonus.  This UPDATE
  # statement raises the employee's salary in the table company_b.
  $sql = qq(UPDATE (SELECT MAX(YEARS) OVER() AS max_years,
                              YEARS,
                              SALARY
                       FROM company_b)
                      SET SALARY = SALARY + 10000
                      WHERE max_years = YEARS);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # no more data to be fetched from statement handles
  $rc = $sth->finish;
    
  return 0;
} # Buy_company

#############################################################################
# Description: The Print function outputs the data in the tables: company_a,
#              company_b and salary_change. For each table, a while loop and 
#              cursor are used to fetch and display row data.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub Print
{
  # declare local variables  
  my ($id, $sql, $name, $department, $job, $years, $salary);
  my ($benefits, $old_id, $old_salary);

  $sql = qq(SELECT ID,
                      NAME,
                      DEPARTMENT,
                      JOB,
                      YEARS,
                      SALARY
                        FROM company_a);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "\nSELECT * FROM company_a\n\n";
  print "ID     NAME      DEPARTMENT JOB   YEARS  SALARY\n";
  print "------ --------- ---------- ----- ------ ---------\n";

  while (($id,$name,$department,$job,$years,$salary) = $sth->fetchrow_array)
  {
    printf "%-6d %-9s %-10d %-5s %-7d %-9.2f\n", 
                             $id, $name, $department, $job, $years, $salary;
  }    

  $sql = qq(SELECT ID,
                      NAME,
                      DEPARTMENT,
                      JOB,
                      YEARS,
                      SALARY,
                      BENEFITS,
                      OLD_ID
                 FROM company_b);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "\nSELECT * FROM company_b\n\n";
  print "ID     NAME      DEPARTMENT JOB   YEARS  SALARY    BENEFITS                                           OLD_ID\n";
  print "------ --------- ---------- ----- ------ ---------"; 
  print " -------------------------------------------------- ------\n";

  while (($id,
          $name,
          $department,
          $job,
          $years,
          $salary,
          $benefits,
          $old_id) = $sth->fetchrow_array)
  {
    printf "%-6d %-9s %-10d %-5s %-7d %-8.2f %-50s %-6d\n\n",
                                      $id, $name, $department, $job, $years,
                                                $salary, $benefits, $old_id;
  }

  $sql = qq(SELECT ID, OLD_SALARY, SALARY FROM salary_change);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "\nSELECT * FROM salary_change\n\n";
  print "ID     OLD_SALARY SALARY\n";
  print "------ ---------- ---------\n";

  while (($id,$old_salary,$salary) = $sth->fetchrow_array)
  {
    printf "%-8d %-9.2f %-8.2f\n", $id, $old_salary, $salary;
  }

  # no more data to be fetched from statement handles
  $rc = $sth->finish;

  return 0;
} # Print

#############################################################################
# Description: The Drop function drops the tables used by this sample.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub Drop
{

  my $sql;

  print "\nDROP TABLE company_a\n";
  $sql = qq(drop table company_a);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql); 

  print "\nDROP TABLE company_b\n";
  $sql = qq(drop table company_b);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "\nDROP TABLE salary_change\n";
  $sql = qq(drop table salary_change);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
 
  # commit the transaction or call TransRollback() from DB2SampUtil.pm 
  # if it fails
  $dbh->commit() || 
    TransRollback($dbh);

  # no more data to be fetched from statement handles
  $rc = $sth->finish;

  return 0;
} # Drop 
