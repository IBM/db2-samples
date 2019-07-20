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
# SOURCE FILE NAME: tbuse.pl
#
# SAMPLE: How to manipulate table data
#
# SQL STATEMENTS USED:
#         SELECT
#         INSERT
#         UPDATE
#         DELETE
#
# OUTPUT FILE: tbuse.out (available in the online documentation)
#############################################################################
#
# For more information on the sample programs, see the README file.
#
# For information on developing applications, see the Application
# Development Guide.
#
# For information on using SQL statements, see the SQL Reference.
#
# For the latest information on programming, compiling, and running DB2
# applications, visit the DB2 application development website at
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

print "\n  THIS SAMPLE SHOWS HOW TO MANIPULATE TABLE DATA\n";

# connect to the database
print "\n  Connecting to database...\n";
$dbh = DBI->connect($database, $user, $password, {AutoCommit =>0})
            || die "Can't connect to $database: $DBI::errstr";
print "  Connected to database.\n";

# perform a query with the 'org' table
BasicQuery();

# insert rows into the 'staff' table
BasicInsert();

# update a set of rows in the 'staff' table
BasicUpdate();

# delete a set of rows from the 'staff' table
BasicDelete();

# no more data to be fetched from the statement handle
$sth->finish;

# disconnect from the database
print "\n  Disconnecting from database...";
$dbh->disconnect
  || die "Can't disconnect from database: $DBI::errstr";
print "\n  Disconnected from database.\n";


#############################################################################
# Description: This subroutine demonstrates how to perform a standard query.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub BasicQuery
{
  my ($deptnumb, $location);
  print "  ----------------------------------------------------------\n";
  print "  USE THE SQL STATEMENT:\n";
  print "    SELECT\n";
  print "  TO QUERY DATA FROM A TABLE.\n";
 
  # set up and execute the query
  print "\n  Execute Statement:\n";
  print "    SELECT deptnumb, location FROM org WHERE deptnumb < 25\n";

  my $sql = qq(SELECT deptnumb, location
                 FROM org WHERE deptnumb < 25);

  # call PrepareExecuteSql subroutine defined in DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "\n  Results:\n"; 
  print "    DEPTNUMB LOCATION\n";
  print "    -------- --------------\n";

  # output the results of the query
  while (($deptnumb, $location) = $sth->fetchrow_array)
  {
    printf "      %-8d %-14s \n", $deptnumb, $location;
  }
 
  return 0;
} # BasicQuery

#############################################################################
# Description: This subroutine demonstrates how to insert rows into a table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub BasicInsert
{
  print "  ----------------------------------------------------------\n";
  print "  USE THE SQL STATEMENT:\n";
  print "    INSERT\n";
  print "  TO INSERT DATA INTO A TABLE USING VALUES.\n";

  # display contents of the 'staff' table before inserting rows
  DisplayStaffTable();

  # use the INSERT statement to insert data into the 'staff' table.
  print "\n  Invoke the statement:\n";
  print "    INSERT INTO staff(id, name, dept, job, salary)\n";
  print "      VALUES(380, 'Pearce', 38, 'Clerk', 13217.50),\n";
  print "            (390, 'Hachey', 38, 'Mgr', 21270.00),\n";
  print "            (400, 'Wagland', 38, 'Clerk', 14575.00)\n";

      
  my $sql = qq(INSERT INTO staff(id, name, dept, job, salary)
                 VALUES (380, 'Pearce', 38, 'Clerk', 13217.50),
                        (390, 'Hachey', 38, 'Mgr', 21270.00),
                        (400, 'Wagland', 38, 'Clerk', 14575.00));
  
  # execute the insert statement
  $dbh->do($sql);

  # display the content in the 'staff' table after the INSERT.
  DisplayStaffTable();

  # rollback the transaction
  printf "\n  Rollback the transaction.\n\n";
  $dbh->rollback;

  return 0;
} # BasicInsert

#############################################################################
# Description: This subroutine demonstrates how to update rows in a table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub BasicUpdate
{
  print "  ----------------------------------------------------------\n";
  print "  USE THE SQL STATEMENT:\n";
  print "    UPDATE\n";
  print "  TO UPDATE TABLE DATA USING A SUBQUERY IN THE 'SET' CLAUSE.\n";

  # display contents of the 'staff' table before updating
  DisplayStaffTable();

  # update the data of table 'staff' by using a subquery in the SET clause
  print "\n  Invoke the statement:\n";
  print "    UPDATE staff\n";
  print "      SET salary = (SELECT MIN(salary)\n";
  print "                      FROM staff\n";
  print "                      WHERE id >= 310)\n";
  print "      WHERE id = 310\n";
  
  my $sql = qq(UPDATE staff
                 SET salary = (SELECT MIN(salary)
                                 FROM staff
                                 WHERE id >= 310)
                 WHERE id = 310);

  # execute the update statement
  $dbh->do($sql);

  # display the final content of the 'staff' table
  DisplayStaffTable();
  
  # rollback the transaction
  printf "\n  Rollback the transaction.\n\n";
  $dbh->rollback;

  return 0;
} # BasicUpdate

#############################################################################
# Description: This subroutine demonstrates how to delete rows from a table.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub BasicDelete
{
  print "  ----------------------------------------------------------\n";
  print "  USE THE SQL STATEMENT:\n";
  print "    DELETE\n";
  print "  TO DELETE TABLE DATA.\n";

  # display contents of the 'staff' table
  DisplayStaffTable();

  # delete rows from the 'staff' table where id >= 310 and salary > 20000 AND job != 'Sales'
  print "\n  Invoke the statement:\n";
  print "    DELETE FROM staff WHERE id >= 310 AND salary > 20000 AND job != 'Sales'\n";

  my $sql = qq(DELETE FROM staff
                 WHERE id >= 310
                 AND salary > 20000
                 AND job != 'Sales');

  # execute the delete statement
  $dbh->do($sql);
 
  # display the final content of the 'staff' table
  DisplayStaffTable();
  
  # rollback the transaction
  printf "\n  Rollback the transaction.\n\n";
  $dbh->rollback;

  return 0;
} # BasicDelete

#############################################################################
# Description: This subroutine displays the contents from the 'staff' table. 
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#############################################################################
sub DisplayStaffTable
{
  my ($id, $name, $dept, $job, $years, $salary, $comm);

  print "  SELECT * FROM staff WHERE id >= 310\n\n";
  print "    ID  NAME     DEPT JOB   YEARS SALARY   COMM\n";
  print "    --- -------- ---- ----- ----- -------- --------\n";

  my $sql = qq(SELECT * FROM staff WHERE id >= 310);

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

  return 0;
} # DisplayStaffTable
