#! /usr/bin/perl
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
# SOURCE FILE NAME: DB2WlmHist.pm
#
# SAMPLE: Defines common functions like prepare and execute SQL statements
#         and roll back if an error occurs that will be used for the
#         WLM Historical Generator and the WLM Historical Reports tools
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
##########################################################################/
use strict;
use warnings; 
use DBI;
use Data::Dumper;

package DB2WlmHist;
our (@ISA, @EXPORT, $VERSION);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(CheckPartition PrepareExecuteSql TransRollback);
$VERSION = 1.00;
##########################################################################
# Description : Determines whether we are using EE activity tables or
#               EEE activity tables.  This is done by querying the
#               activity logical data group to determine whether
#               there is a partition_number column in the table.
# Input       : Datbase handler, Table name 
# Output      : Statement Handler.
##########################################################################
sub CheckPartition
{
  # get the database handler and sql into local variables
  my ($dbh_loc, $schema, $table) = @_;
  
  # declare return code and statement handle
  my ($rc, $sth, $isEEE); 
  $isEEE = 0;

  # Get the column information for the activity table
  $sth = $dbh_loc->column_info(undef, $schema, $table, "%");
  my $col_ref = $sth->fetchall_arrayref;
  # If there is a partition_number column, then we know we
  # are on EEE
  for my $row(@$col_ref)
  {
    if ($row->[3] eq "PARTITION_NUMBER")
    {
      $isEEE = 1;
      return $isEEE;
    }
  }

  return $isEEE;   # return whether we are in EEE or not
} # CheckPartition

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
    or TransRollback($dbh_loc);

  # execute the prepared SQL statement or call TransRollback() if it fails
  $rc = $sth->execute()
    or TransRollback($dbh_loc); 

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
  my ($rc, $sth, $num_handles, $i, $handle);

  # rollback the transaction
  print "\n  Rolling back the transaction...\n";

  $rc = $dbh_loc->rollback()
    or die "The transaction couldn't be rolled back: $DBI::errstr";

  print "\n  The transaction was rolled back.\n";
 
  # get the number of active statement handles currently used 
  $num_handles = $dbh_loc->{ActiveKids};

  # close all the active statement handles
  for ($i = 0; $i < $num_handles; $i++)
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
    or die "Disconnecting from the database failed: $DBI::errstr";

  print "\n  Disconnected from the database.\n";

  die "\nExiting the sample\n";
} # TransRollback
1; # to always return true to the calling function
