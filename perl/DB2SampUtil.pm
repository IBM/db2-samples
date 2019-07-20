
#!/usr/bin/perl
##########################################################################
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
# SOURCE FILE NAME: DB2SampUtil.pm
#
# SAMPLE: Defines common functions like command line argument checking 
#         Also, functions to prepare and execute an SQL statement, and 
#         roll back if an error occurs.
#
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
##########################################################################/
use strict;
use warnings; 
use DBI;

##########################################################################
# Description : Checks and parses the command line arguments
# Input       : An array containing the command line arguments that was 
#               passed to the calling function
# Output      : Database name, user name and password 
###########################################################################
sub CmdLineArgChk
{
my $arg_c = @_; # number of arguments passed to the function
my @arg_l; # arg_l holds the values to be returned to calling function

if($arg_c > 3 || $arg_c == 1 && ( ( $_[0] eq "?" ) ||
                                  ( $_[0] eq "-?" ) ||
                                  ( $_[0] eq "/?" ) ||
                                  ( $_[0] eq "-h" ) ||
                                  ( $_[0] eq "/h" ) ||
                                  ( $_[0] eq "-help" ) ||
                                  ( $_[0] eq "/help" ) ) )
{
  die "Usage: prog_name [dbAlias] [userId passwd] \n" ;
}   

# Use all defaults
if($arg_c == 0)
{
  $arg_l[0] = "dbi:DB2:sample";
  $arg_l[1] = "";
  $arg_l[2] = "";
}

# dbAlias specified
if($arg_c == 1)
{
  $arg_l[0] = "dbi:DB2:".$_[0];
  $arg_l[1] = "";
  $arg_l[2] = "";
}

# userId & passwd specified
if($arg_c == 2)
{
  $arg_l[0] = "dbi:DB2:sample";
  $arg_l[1] = $_[0];
  $arg_l[2] = $_[1];
}

# dbAlias, userId & passwd specified
if($arg_c == 3)
{
  $arg_l[0] = "dbi:DB2:".$_[0];
  $arg_l[1] = $_[1];
  $arg_l[2] = $_[2];
}

return @arg_l;
} # CmdLineArgChk

##########################################################################
# Description : Prepares and Exectes the SQL statement
# Input       : Datbase handler, SQL statement 
# Output      : Statement Handler.
##########################################################################
sub PrepareExecuteSql
{
  # get the database handler and sql into local variables
  my ($dbh_loc, $sql_loc) = @_;
  
  # declare return code and statement handle
  my ($rc, $sth); 
  
  # prepare the SQL statement or call TransRollback() if it fails
  $sth = $dbh_loc->prepare($sql_loc)
    || &TransRollback($dbh_loc);

  # execute the prepared SQL statement or call TransRollback() if it fails
  $rc = $sth->execute()
    || &TransRollback($dbh_loc); 

  return $sth;   # return the statement handler
} # PrepareExecuteSql

##########################################################################
# Description : Rollback the transaction and reset the database connection
# Input       : Database handler
# Output      : None
##########################################################################
sub TransRollback
{
  # get the database handler into local variables
  my ($dbh_loc) = @_;
  
  # declare return code, statement handler and local variables
  my ($rc, $sth, $no_handles, $i, $handle);

  # rollback the transaction
  print "\n  Rolling back the transaction...\n";

  $rc = $dbh_loc->rollback()
    || die "The transaction couldn't be rolled back: $DBI::errstr";

  print "\n  The transaction was rolled back.\n";
 
  # get the number of active statement handles currently used 
  $no_handles = $dbh_loc->{ActiveKids};

  # close all the active statement handles
  for ($i = 0; $i < $no_handles; $i++)
  {
     if($i == 0)
     {
       # no more data to be fetched from the first statement handle
       $sth->finish;
     }
     else
     {
       $handle = "\$sth$i";  # to get the subsequent statement handles
       eval "$handle->finish";
     }
  }

  # reset the connection
  print "\n  Disconnecting from the database...\n";

  $rc = $dbh_loc->disconnect()
    || die "Disconnecting from the database failed: $DBI::errstr";

  print "\n  Disconnected from the database.\n";

  die "\nExiting the sample\n";
} # TransRollback
1; # to always return true to the calling function
