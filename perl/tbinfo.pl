#!/usr/bin/perl
########################################################################
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
#########################################################################
#
# SOURCE FILE NAME: tbinfo.pl
#
# SAMPLE: How to get information about a table
#
# SQL STATEMENTS USED:
#         SELECT 
#
# OUTPUT FILE: tbinfo.out (available in the online documentation)
##########################################################################
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
###########################################################################

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

# declare return code, statement handler, database handler and local variable
my ($rc, $sth, $dbh, $colname, $typename, $length, $scale, $tableName);
      
print "THIS SAMPLE SHOWS HOW TO GET INFORMATION ABOUT A TABLE.\n";

# connect to the database 
print "\n  Connecting to database...\n";
$dbh = DBI->connect($database, $user, $password)
            || die "Can't connect to $database: $DBI::errstr";
print "\n  Connected to database.\n";
   
$tableName = 'STAFF'; # tableName can be assigned name of any table about
                         # which information is to be obtained 
                 
print "------------------------------------------------------------------";

# get the table schema name 
$rc = GetSchemaName();
if($rc != 0) 
{
   die "\nError: Getting the table schema name failed\n";
}

print "------------------------------------------------------------------";

# get info for table columns 
$rc = GetColumnInfo();
if($rc != 0) 
{
   die "\nError: Getting the column information for the table failed\n";
}

# disconnect from the database 
print "\n  Disconnecting from database.";
$dbh->disconnect
  || die "Can't disconnect from database: $DBI::errstr";
print "\n  Disconnected from database.\n";

##########################################################################
# Description: How to get the schema name for a table
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
##########################################################################
sub GetSchemaName
{
  
  my $sql;

  print "\nUSE THE SQL STATEMENT:";
  print "\n  SELECT INTO ";
  print "\nTO GET A TABLE SCHEMA NAME \n";
  
  print "\n  Execute the statement\n";
  print "      SELECT tabschema \n"; 
  print "        FROM syscat.tables \n";
  print "        WHERE tabname = \'\$tableName\' \n";
  print "    for\n";
  print "      tableName = '$tableName'.\n";

  $sql = qq(SELECT tabschema FROM syscat.tables 
               WHERE tabname = '$tableName');
  
  # prepare and execute the SQL statement
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql); 
  
  # fetch the schema name into a variable for display 
  my $tabschema = $sth->fetchrow();
  print "\n  Table Schema name is: $tabschema\n";
  
  # no more data to be fetched from statement handle
  $sth->finish;
  
  return 0;
} # GetSchemaName

##########################################################################
# Description: How to get the column information for a table
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
##########################################################################
sub GetColumnInfo
{  
 
  my $sql;

  print "\nTO GET TABLE COLUMN INFORMATION.\n";
  print "\n  Get info for '$tableName' table columns:\n"; 
  print "      column name          data type      data size\n";
  print "      -------------------- -------------- ----------\n";
  
  $sql = qq(SELECT colname, typename, length, scale
               FROM syscat.columns WHERE tabname='$tableName');  

  # prepare and execute the SQL statement
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # fetch each row to display the column information for table 'STAFF'
  while(($colname, $typename, $length, $scale) = $sth->fetchrow()) 
  {
    printf("      %-20s %-14s %s", $colname, $typename, $length);  
    if($scale  != 0)
    {
      print ", $scale"; 
    }
    print "\n";  
  }
  
  # no more data to be fetched from statement handle
  $sth->finish;

  return 0;
} # GetColumnInfo
