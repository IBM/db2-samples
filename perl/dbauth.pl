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
# SOURCE FILE NAME: dbauth.pl
#
# SAMPLE: How to grant, display, and revoke authorities at database level 
#
# SQL STATEMENTS USED:
#         SELECT INTO
#         GRANT (Database Authorities)
#         REVOKE (Database Authorities)
#
# OUTPUT FILE: dbauth.out (available in the online documentation)
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
# call the subroutine CmdLineArgChk() from DB2SampUtil.pm
my ($database, $user, $password) = CmdLineArgChk(@ARGV);

# declare return code, statement handler, database handler and local variable
my ($rc, $sth, $dbh, $i);

sub DbAuthGrant();
sub DbAuthForAnyUserOrGroupDisplay();
sub DbAuthRevoke();

print "\nTHIS SAMPLE SHOWS ";
print "\nHOW TO GRANT/DISPLAY/REVOKE AUTHORITIES AT DATABASE LEVEL.\n";

# connect to the database
print "\n  Connecting to database...\n";
$dbh = DBI->connect($database, $user, $password, {AutoCommit =>0})
            || die "Can't connect to $database: $DBI::errstr";
print "\n  Connected to database.\n";


# call the subroutine DbAuthGrant
$rc = DbAuthGrant();
if ($rc != 0)
{
  print "\nGranting Database authorities at Database level failed\n";
}

# call the subroutine DbAuthForAnyUserOrGroupDisplay 
$rc = DbAuthForAnyUserOrGroupDisplay();
if ($rc != 0)
{
  print "\nDisplay of Database authorities for any user at Database\n";
  print "level failed\n";
}

# call the subroutine DbAuthRevoke
$rc = DbAuthRevoke();
if ($rc != 0)
{
  print "\nRevoke Database authorities from user at Database\n";
  print "level failed\n";
}

# disconnect from the database
print "\n  Disconnecting from database.\n";
$dbh->disconnect
  || die $DBI::errstr;
print "  Disconnected from database.\n";


#########################################################################
# Description: How to grant authorities at database level 
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#########################################################################
sub DbAuthGrant()
{
  my $sql;
  
  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  GRANT (Database Authorities)\n";
  print "  COMMIT\n";
  print "TO GRANT AUTHORITIES AT DATABASE LEVEL.\n";

  # grant user authorities at database level
  print "\n  GRANT CONNECT, CREATETAB, BINDADD ON DATABASE";
  print " TO USER user1\n";

  $sql = qq(GRANT CONNECT, CREATETAB, BINDADD ON DATABASE TO USER user1);  

  # prepare and execute the SQL statement
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "  COMMIT\n";
  # commit the transaction or call TransRollback() from DB2SampUtil.pm 
  # if it fails
  $dbh->commit() || 
    TransRollback($dbh);

  # no more data to be fetched from statement handle
  $sth->finish;

  return 0; 
} # DbAuthGrant


#########################################################################
# Description: How to display authorities for any user at database level 
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#########################################################################
sub DbAuthForAnyUserOrGroupDisplay()
{
  my $sql;

  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENT:\n";
  print "  SELECT INTO\n";
  print "TO DISPLAY AUTHORITIES FOR ANY USER AT DATABASE LEVEL.\n";

  print "\n  SELECT granteetype, dbadmauth, createtabauth, bindaddauth,\n";
  print "         connectauth, nofenceauth, implschemaauth, loadauth\n";
  print "    FROM syscat.dbauth\n";
  print "    WHERE grantee = 'USER1'\n";

  $sql = qq(SELECT granteetype, dbadmauth, createtabauth, bindaddauth,
                  connectauth, nofenceauth, implschemaauth, loadauth
    FROM syscat.dbauth
    WHERE grantee = 'USER1');

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  my ($granteetype, $dbadmauth, $createtabauth, $bindaddauth,
    $connectauth, $nofenceauth, $implschemaauth, $loadauth) =
    $sth->fetchrow_array;

  # check for problems which may have terminated the fetch early
  die $sth->errstr if $sth->err; 
 
  print "\n  Grantee Type      = ", $granteetype, "\n";
  print "  DBADM auth.       = ", $dbadmauth,   "\n";
  print "  CREATETAB auth.   = ", $createtabauth, "\n";
  print "  BINDADD auth.     = ", $bindaddauth, "\n";
  print "  CONNECT auth.     = ", $connectauth, "\n";
  print "  NO_FENCE auth.    = ", $nofenceauth, "\n";
  print "  IMPL_SCHEMA auth. = ", $implschemaauth, "\n";
  print "  LOAD auth.        = ", $loadauth, "\n";

  # no more data to be fetched from statement handle
  $sth->finish;
  
  return 0;
} # DbAuthForAnyUserOrGroupDisplay()


#########################################################################
# Description: How to revoke authorities at database level
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
#########################################################################
sub DbAuthRevoke()
{
  my $sql;

  print "\n-----------------------------------------------------------";
  print "\nUSE THE SQL STATEMENTS:\n";
  print "  REVOKE (Database Authorities)\n";
  print "  COMMIT\n";
  print "TO REVOKE AUTHORITIES AT DATABASE LEVEL.\n";

  # revoke user authorities at database level
  print "\n  REVOKE CONNECT, CREATETAB, BINDADD ON DATABASE ";
  print "FROM USER user1\n";

  $sql = qq(REVOKE CONNECT, CREATETAB, BINDADD ON DATABASE FROM user1);

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);

  print "  COMMIT\n";
  # commit the transaction or call TransRollback() from DB2SampUtil.pm 
  # if it fails
  $dbh->commit() || 
    TransRollback($dbh);

  # no more data to be fetched from statement handle
  $sth->finish;

  return 0;
} # DbAuthRevoke()
