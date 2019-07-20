#!/usr/bin/perl
#############################################################################
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
#############################################################################
#
# SOURCE FILE NAME: tbtrig.pl 
#
# SAMPLE: How to use a trigger on a table
#
# SQL STATEMENTS USED:
#         SELECT
#         CREATE TABLE
#         DROP
#         CREATE TRIGGER
#         INSERT
#         DELETE
#         UPDATE
#
# OUTPUT FILE: tbtrig.out (available in the online documentation)
#############################################################################
#
# For more information on the sample programs, see the README file.
#
# For information on developing perl applications, see the Application
# Development Guide.
#
# For information on using SQL statements, see the SQL Reference.
#
# For the latest information on programming, building, and running DB2
# applications, visit the DB2 application development website:
#     http://www.software.ibm.com/data/db2/udb/ad
#############################################################################

select STDERR; $|=1;
select STDOUT; $|=1;

use strict;
use warnings; 
use DBI;

# access the module for DB2 Sample Utility functions
use DB2SampUtil;

# check and parse the command line arguments 
# call the subroutine CmdLineArgChk from DB2SampUtil.pm
my ($database, $user, $password) = CmdLineArgChk(@ARGV);

# declare return code, statement handler, database handler
my ($rc, $sth, $dbh);


print "\nTHIS SAMPLE SHOWS HOW TO USE TRIGGERS.\n";

# connect to the database
print "\n  Connecting to database...\n";
$dbh = DBI->connect($database, $user, $password, {AutoCommit =>0})
            || die "Can't connect to $database: $DBI::errstr";
print "  Connected to database.\n";

# call the TbBeforeInsertTriggerUse subroutine
TbBeforeInsertTriggerUse();

# call the TbAfterInsertTriggerUse subroutine
TbAfterInsertTriggerUse();

# call the TbBeforeDeleteTriggerUse subroutine
TbBeforeDeleteTriggerUse();

# call the TbBeforeUpdateTriggerUse subroutine
TbBeforeUpdateTriggerUse();

# call the TbAfterUpdateTriggerUse subroutine
TbAfterUpdateTriggerUse();

# disconnect from the database
print "\n  Disconnecting from database...";
$dbh->disconnect
  || die "Can't disconnect from database: $DBI::errstr";
print "\n  Disconnected from database.\n";


#############################################################################
# Description: The StaffTbContentDisplay subroutine displays the contents of
#              the 'staff' table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub StaffTbContentDisplay
{
  my ($id, $name, $dept, $job, $years, $salary, $comm) = "0" ;

  print "\n  Select * from staff where id <= 50\n";
  print "    ID  NAME     DEPT JOB   YEARS SALARY   COMM\n";
  print "    --- -------- ---- ----- ----- -------- --------\n";

  my $sql = qq(SELECT * FROM staff WHERE id <= 50);

  # prepare the sql statement 
  $sth = $dbh->prepare($sql);

  # execute the sql statement
  $sth->execute;

  while (($id, $name, $dept, $job, $years, $salary, $comm)
                                                      = $sth->fetchrow_array)
  {
    printf "    %3d %-8.8s %4d", $id, $name, $dept;
    if(defined $job) 
    {
      printf " %-5.5s", $job;
    }
    else
    {
      print "     -";
    }
    
    if(defined $years)
    {
      printf " %5d", $years;
    }
    else
    {
      print "     -";
    }
    
    printf " %7.2f", $salary;
    if(defined $comm)
    {
      printf " %7.2f\n", $comm;
    }
    else
    {
      print "       -\n";
    }
  }
  
  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # StaffTbContentDisplay

#############################################################################
# Description: The StaffStatsTbCreate subroutine creates the table 
#              'staff_stats' for the TbAfterInsertTriggerUse subroutine.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub StaffStatsTbCreate
{ 
  print "\n  CREATE TABLE staff_stats(nbemp SMALLINT)\n";

  my $sql = qq(CREATE TABLE staff_stats(nbemp SMALLINT));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  print "\n  INSERT INTO staff_stats VALUES(SELECT COUNT(*) FROM staff)\n";

  $sql = qq(INSERT INTO staff_stats VALUES(SELECT COUNT(*) FROM staff));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # StaffStatsTbCreate

#############################################################################
# Description: The StaffStatsTbContentDisplay subroutine displays the 
#              contents of the 'staff_stats' table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub StaffStatsTbContentDisplay
{ 
  print "\n  SELECT nbemp FROM staff_stats\n";
  print "    NBEMP\n";
  print "    -----\n";

  my $sql = qq(SELECT * FROM staff_stats);

  # prepare the sql statement
  $sth = $dbh->prepare($sql);
  
  # execute the statement
  $sth->execute;

  my ($nbemp) = $sth->fetchrow;
  printf "    %5d\n", $nbemp;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # StaffStatsTbContentDisplay

#############################################################################
# Description: The StaffStatsTbDrop subroutine drops the table 'staff_stats'
#              that is used by the TbAfterInsertTriggerUse subroutine.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub StaffStatsTbDrop
{ 
  print "\n  DROP TABLE staff_stats\n";
  
  my $sql = qq(DROP TABLE staff_stats);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # StaffStatsTbDrop

#############################################################################
# Description: The SalaryStatusTbCreate subroutine creates the table 
#              'salary_status' for the TbBeforeUpdateTriggerUse subroutine.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub SalaryStatusTbCreate
{ 
  print "\n  CREATE TABLE salary_status(emp_name VARCHAR(9),";
  print "\n                             sal DECIMAL(7, 2),";
  print "\n                             status CHAR(15))\n";

  my $sql = qq(CREATE TABLE salary_status(emp_name VARCHAR(9),
                                          sal DECIMAL(7, 2),
                                          status CHAR(15)));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
 
  print "\n  INSERT INTO salary_status\n";
  print "  SELECT name, salary, 'Not Defined'\n";
  print "  FROM staff\n";
  print "  WHERE id <= 50\n";

  $sql = qq(INSERT INTO salary_status
                 SELECT name, salary, 'Not Defined'
                   FROM staff 
                   WHERE id <= 50);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # SalaryStatusTbCreate

#############################################################################
# Description: The SalaryStatusTbContentDisplay subroutine displays the 
#              contents of the 'salary_status' table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub SalaryStatusTbContentDisplay
{ 
  my ($emp_name, $sal, $status);
  print "\n  Select * from salary_status\n";
  print "    EMP_NAME   SALARY   STATUS          \n";
  print "    ---------- -------- ----------------\n";

  my $sql = qq(SELECT * FROM salary_status);

  # prepare the sql statement
  $sth = $dbh->prepare($sql);

  # execute the statement
  $sth->execute;

  while(($emp_name, $sal, $status) = $sth->fetchrow_array)
  {
     printf "    %-10s %7.2f %-15s\n", $emp_name, $sal, $status;
  }

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # SalaryStatusTbContentDisplay

#############################################################################
# Description: The SalaryStatusTbDrop subroutine drops the table
#              'salary_status' that is used by the TbBeforeUpdateTriggerUse
#              subroutine.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub SalaryStatusTbDrop
{ 
  print "\n  DROP TABLE salary_status\n";
  
  my $sql = qq(DROP TABLE salary_status);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # SalaryStatusTbDrop

#############################################################################
# Description: The SalaryHistoryTbCreate subroutine creates the table 'salary_
#              history' for the TbAfterUpdateTriggerUse subroutine.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub SalaryHistoryTbCreate
{ 
  print "\n  CREATE TABLE salary_history(employee_name VARCHAR(9),";
  print "\n                              salary_record DECIMAL(7, 2),";
  print "\n                              change_date DATE)\n";

  my $sql = qq(CREATE TABLE salary_history(employee_name VARCHAR(9),
                                           salary_record DECIMAL(7, 2),
                                           change_date DATE));
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;
  
  return 0;
} # SalaryHistoryTbCreate

#############################################################################
# Description: The SalaryHistoryTbContentDisplay subroutine displays the 
#              contents of the 'salary_history' table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub SalaryHistoryTbContentDisplay
{ 
  my ($employee_name, $salary_record, $change_date);

  print "\n  Select * from salary_history\n";
  print "    EMPLOYEE_NAME  SALARY_RECORD  CHANGE_DATE\n";
  print "    -------------- -------------- -----------\n";

  my $sql = qq(SELECT * FROM salary_history);
  
  # prepare the sql statement
  $sth = $dbh->prepare($sql);

  # execute the sql statement
  $sth->execute;

  while(($employee_name, $salary_record, $change_date)
                                                     = $sth->fetchrow_array)
  {
    printf "    %-14s %14.2f %-15s\n", $employee_name, $salary_record,
                                       $change_date;
  }

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # SalaryHistoryTbContentDisplay

#############################################################################
# Description: The SalaryHistoryTbDrop subroutine drops the table 
#              'salary_history' that is used by the TbAfterUpdateTriggerUse
#              subroutine.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub SalaryHistoryTbDrop
{ 
  print "\n  DROP TABLE salary_history\n";

  my $sql = qq(DROP TABLE salary_history);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # SalaryHistoryTbDrop

#############################################################################
# Description: The TbBeforeInsertTriggerUse subroutine illustrates 'BEFORE
#              INSERT' trigger.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub TbBeforeInsertTriggerUse
{ 
  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  CREATE TRIGGER\n";
  print "  COMMIT\n";
  print "  INSERT\n";
  print "  DROP TRIGGER\n";
  print "TO SHOW A 'BEFORE INSERT' TRIGGER.\n";

  # display initial table content
  $rc = StaffTbContentDisplay();

  print "\n  CREATE TRIGGER min_sal";
  print "\n    NO CASCADE BEFORE";
  print "\n    INSERT ON staff";
  print "\n    REFERENCING NEW AS newstaff";
  print "\n    FOR EACH ROW";
  print "\n    BEGIN ATOMIC";
  print "\n      SET newstaff.salary =";
  print "\n        CASE";
  print "\n          WHEN newstaff.job = 'Mgr' AND ";
  print                  "newstaff.salary < 17000.00";
  print "\n            THEN 17000.00";
  print "\n          WHEN newstaff.job = 'Sales' AND ";
  print                  "newstaff.salary < 14000.00";
  print "\n            THEN 14000.00";
  print "\n          WHEN newstaff.job = 'Clerk' AND ";
  print                  "newstaff.salary < 10000.00";
  print "\n            THEN 10000.00";
  print "\n          ELSE newstaff.salary";
  print "\n        END;";
  print "\n    END\n";

  my $sql = qq(CREATE TRIGGER min_sal
    NO CASCADE BEFORE
    INSERT ON staff
    REFERENCING NEW AS newstaff
    FOR EACH ROW
    BEGIN ATOMIC
      SET newstaff.salary =
        CASE
          WHEN newstaff.job = 'Mgr' AND newstaff.salary < 17000.00
            THEN 17000.00
          WHEN newstaff.job = 'Sales' AND newstaff.salary < 14000.00
            THEN 14000.00
          WHEN newstaff.job = 'Clerk' AND newstaff.salary < 10000.00
            THEN 10000.00
          ELSE newstaff.salary
        END;
    END);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # insert into the table using values
  print "\n  Invoke the statement\n";
  print "    INSERT INTO staff(id, name, dept, job, salary)\n";
  print "      VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),\n";
  print "            (35, 'Hachey', 38, 'Mgr', 21270.00),\n";
  print "            (45, 'Wagland', 38, 'Sales', 11575.00)\n";

  $sql = qq(INSERT INTO staff(id, name, dept, job, salary)
                 VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),
                       (35, 'Hachey', 38, 'Mgr', 21270.00),
                       (45, 'Wagland', 38, 'Sales', 11575.00));

  # execute the sql statement
  $sth = $dbh->do($sql);

  # display final content of the table
  $rc = StaffTbContentDisplay();

  # rollback transaction
  print "\n  Rollback the transaction.\n";
  $rc = $dbh->rollback;

  print "\n  DROP TRIGGER min_sal\n";

  $sql = qq(DROP TRIGGER min_sal);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # TbBeforeInsertTriggerUse

#############################################################################
# Description: The TbAfterInsertTriggerUse subroutine illustrates 'AFTER 
#              INSERT' trigger.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub TbAfterInsertTriggerUse
{ 
  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  CREATE TRIGGER\n";
  print "  COMMIT\n";
  print "  INSERT\n";
  print "  DROP TRIGGER\n";
  print "TO SHOW AN 'AFTER INSERT' TRIGGER.\n";

  # create staff_stats table 
  $rc = StaffStatsTbCreate();

  if($rc != 0)
  {
    return $rc;
  }

  # display staff_stats table content 
  $rc = StaffStatsTbContentDisplay();

  print "\n  CREATE TRIGGER new_hire AFTER";
  print "\n    INSERT ON staff";
  print "\n    FOR EACH ROW";
  print "\n    BEGIN ATOMIC";
  print "\n      UPDATE staff_stats SET nbemp = nbemp + 1;";
  print "\n    END\n";

  my $sql = qq(CREATE TRIGGER new_hire AFTER
                 INSERT ON staff
                 FOR EACH ROW
                 BEGIN ATOMIC
                   UPDATE staff_stats SET nbemp = nbemp + 1;
                 END);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
 
  # commit the transaction
  $rc = $dbh->commit;

  # insert into the table using values 
  print "\n  Invoke the statement\n";
  print "    INSERT INTO staff(id, name, dept, job, salary)\n";
  print "      VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),\n";
  print "            (35, 'Hachey', 38, 'Mgr', 21270.00),\n";
  print "            (45, 'Wagland', 38, 'Sales', 11575.00)\n";

  $sql = qq(INSERT INTO staff(id, name, dept, job, salary)
                 VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),
                       (35, 'Hachey', 38, 'Mgr', 21270.00),
                       (45, 'Wagland', 38, 'Sales', 11575.00));

  # execute the sql statement
  $sth = $dbh->do($sql);

  # display staff_stats table content 
  $rc = StaffStatsTbContentDisplay();

  # rollback transaction 
  print "\n  Rollback the transaction.\n";
  $rc = $dbh->rollback;
  
  print "\n  DROP TRIGGER new_hire\n";
  
  $sql = qq(DROP TRIGGER new_hire);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit; 

  # drop staff_stats table 
  $rc = StaffStatsTbDrop();

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # TbAfterInsertTriggerUse

#############################################################################
# Description: The TbBeforeDeleteTriggerUse subroutine illustrates 'BEFORE
#              DELETE' trigger.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub TbBeforeDeleteTriggerUse
{ 
  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  CREATE TRIGGER\n";
  print "  COMMIT\n";
  print "  DELETE\n";
  print "  DROP TRIGGER\n";
  print "TO SHOW A 'BEFORE DELETE' TRIGGER.\n";

  # display initial content of the table 
  $rc = StaffTbContentDisplay();
  
  print "\n  CREATE TRIGGER do_not_delete_sales";
  print "\n    NO CASCADE BEFORE";
  print "\n    DELETE ON staff";
  print "\n    REFERENCING OLD AS oldstaff";
  print "\n    FOR EACH ROW";
  print "\n    WHEN(oldstaff.job = 'Sales')";
  print "\n    BEGIN ATOMIC";
  print "\n      SIGNAL SQLSTATE '75000' ";
  print "('Sales can not be deleted now.');";
  print "\n    END\n";

  my $sql = qq(CREATE TRIGGER do_not_delete_sales
                 NO CASCADE BEFORE
                 DELETE ON staff
                 REFERENCING OLD AS oldstaff
                 FOR EACH ROW
                 WHEN(oldstaff.job = 'Sales')
                 BEGIN ATOMIC
                   SIGNAL SQLSTATE '75000' ('Sales can not be deleted now.');
                 END);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # delete table 
  print "\n  Invoke the statement\n";
  print "    DELETE FROM staff WHERE id <= 50\n";

  $sql = qq(DELETE FROM staff WHERE id <= 50);
  
  # disable DBI error message printing 
  $dbh->{PrintError} = 0;

  # execute the sql statement
  $sth = $dbh->do($sql);

  if($DBI::err == -438)
  {
    print "  SQL0438N Sales can not be deleted now. SQLSTATE = $DBI::state\n";
  }
  
  # enable DBI error message printing
  $dbh->{PrintError} = 1;

  # display final content of the table 
  $rc = StaffTbContentDisplay();

  # rollback transaction 
  print "\n  Rollback the transaction.\n";
  $rc = $dbh->rollback;

  print "\n  DROP TRIGGER do_not_delete_sales\n";

  $sql = qq(drop trigger do_not_delete_sales);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # TbBeforeDeleteTriggerUse

#############################################################################
# Description: The TbBeforeUpdateTriggerUse subroutine illustrates 'BEFORE
#              UPDATE' trigger.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub TbBeforeUpdateTriggerUse
{ 
  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  CREATE TRIGGER\n";
  print "  COMMIT\n";
  print "  UPDATE\n";
  print "  DROP TRIGGER\n";
  print "TO SHOW A 'BEFORE UPDATE' TRIGGER.\n";

  # create salary_status table 
  $rc = SalaryStatusTbCreate();
  if ($rc != 0)
  {
    return $rc;
  }

  # display salary_status table content 
  $rc = SalaryStatusTbContentDisplay();
  
  my $sql = qq(CREATE TRIGGER sal_status 
                 NO CASCADE BEFORE 
                 UPDATE OF sal
                 ON salary_status 
                 REFERENCING NEW AS new OLD AS old 
                 FOR EACH ROW 
                 BEGIN ATOMIC
                   SET new.status = 
                     CASE 
                       WHEN new.sal < old.sal THEN 'Decreasing' 
                       WHEN new.sal > old.sal THEN 'Increasing' 
                     END;
                 END);
 
  print "\n  CREATE TRIGGER salary_status";
  print "\n    NO CASCADE BEFORE";
  print "\n    UPDATE OF sal";
  print "\n    ON salary_status";
  print "\n    REFERENCING NEW AS new OLD AS old";
  print "\n    FOR EACH ROW";
  print "\n    BEGIN ATOMIC";
  print "\n      SET new.status =";
  print "\n        CASE";
  print "\n          WHEN new.sal < old.sal THEN 'Decreasing'";
  print "\n          WHEN new.sal > old.sal THEN 'Increasing'";
  print "\n        END;";
  print "\n    END\n";

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # update table 
  print "\n  Invoke the statement\n";
  print "    UPDATE salary_status SET sal = 18000.00\n";
  
  $sql = qq(UPDATE salary_status SET sal = 18000.00);
  
  # execute the sql statement 
  $sth = $dbh->do($sql);
 
  # display salary_status table content 
  $rc = SalaryStatusTbContentDisplay();
  
  # rollback transaction 
  print "\n  Rollback the transaction.\n";
  $rc = $dbh->rollback;
  
  print "\n  DROP TRIGGER sal_status\n";
  
  $sql = qq(drop trigger sal_status);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;
  
  # drop salary_status table 
  $rc = SalaryStatusTbDrop();

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # TbBeforeUpdateTriggerUse

#############################################################################
# Description: The TbAfterUpdateTriggerUse subroutine illustrates 'AFTER 
#              UPDATE' trigger.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub TbAfterUpdateTriggerUse
{ 
  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  CREATE TRIGGER\n";
  print "  COMMIT\n";
  print "  UPDATE\n";
  print "  DROP TRIGGER\n";
  print "TO SHOW AN 'AFTER UPDATE' TRIGGER.\n";
 
  # create salary_history table 
  $rc = SalaryHistoryTbCreate();  
 
  # display salary_history table content 
  $rc = SalaryHistoryTbContentDisplay();

  my $sql = qq(CREATE TRIGGER sal_history 
                 AFTER 
                 UPDATE OF salary ON staff 
                 REFERENCING NEW AS newstaff 
                 FOR EACH ROW 
                 BEGIN ATOMIC 
                   INSERT INTO salary_history 
                     VALUES(newstaff.name, newstaff.salary, CURRENT DATE);
                 END);
  print "\n  CREATE TRIGGER sal_history";
  print "\n    AFTER";
  print "\n    UPDATE OF salary ON staff";
  print "\n    REFERENCING NEW AS newstaff";
  print "\n    FOR EACH ROW";
  print "\n    BEGIN ATOMIC";
  print "\n      INSERT INTO salary_history";
  print "\n        VALUES(newstaff.name, newstaff.salary, CURRENT DATE);";
  print "\n    END\n";

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
 
  # commit the transaction
  $rc = $dbh->commit;

  # update table 
  print "\n  Invoke the statement\n";
  print "    UPDATE staff SET salary = 20000.00 WHERE name = 'Sanders'\n";

  $sql = qq(UPDATE staff SET salary = 20000.00 WHERE name = 'Sanders');

  # execute the sql statement
  $sth = $dbh->do($sql);
 
  print "\n  Invoke the statement\n";
  print "    UPDATE staff SET salary = 21000.00 WHERE name = 'Sanders'\n";

  $sql = qq(UPDATE staff SET salary = 21000.00 WHERE name = 'Sanders');

  # execute the sql statement
  $sth = $dbh->do($sql);

  print "\n  Invoke the statement\n";
  print "    UPDATE staff SET salary = 23000.00 WHERE name = 'Sanders'\n";
 
  $sql = qq(UPDATE staff SET salary = 23000.00 WHERE name = 'Sanders');

  # execute the sql statement
  $sth = $dbh->do($sql);

  print "\n  Invoke the statement\n";
  print "    UPDATE staff SET salary = 20000.00 WHERE name = 'Hanes'\n";

  $sql = qq(UPDATE staff SET salary = 20000.00 WHERE name = 'Hanes');

  # execute the sql statement
  $sth = $dbh->do($sql);

  print "\n  Invoke the statement\n";
  print "    UPDATE staff SET salary = 21000.00 WHERE name = 'Hanes'\n";

  $sql = qq(UPDATE staff SET salary = 21000.00 WHERE name = 'Hanes');
 
  # execute the sql statement
  $sth = $dbh->do($sql);
 
  # display salary_history table content 
  $rc = SalaryHistoryTbContentDisplay();
  
  # rollback transaction 
  print "\n  Rollback the transaction.\n";
  $rc = $dbh->rollback;

  print "\n  DROP TRIGGER sal_history\n";
  
  $sql = qq(drop trigger sal_history);
  
  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  # commit the transaction
  $rc = $dbh->commit;

  # drop salary_history table 
  $rc = SalaryHistoryTbDrop();

  # no more data to be fetched from statement handle
  $rc = $sth->finish;

  return 0;
} # TbAfterUpdateTriggerUse
