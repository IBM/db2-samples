#!/usr/bin/perl
#########################################################################
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
# SOURCE FILE NAME: tbpriv.pl
#
# SAMPLE: How to grant, display and revoke privileges on a table
#
# SQL STATEMENTS USED:
#         SELECT
#         GRANT
#         REVOKE
#
# OUTPUT FILE: tbpriv.out (available in the online documentation)
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
##########################################################################

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

# declare return code, statement handler, database handler and local variables
my ($rc, $sth, $dbh);
my ($granteetype, $controlauth, $alterauth,$deleteauth, $indexauth); 
my ($insertauth, $selectauth, $refauth, $updateauth, );

print "THIS SAMPLE SHOWS HOW TO GRANT, DISPLAY AND REVOKE PRIVILEGES \n";
print "ON A TABLE. \n";

# connect to the database
print "\n  Connecting to database...\n";
$dbh = DBI->connect($database, $user, $password, {AutoCommit => 0})
            || die "Can't connect to $database: $DBI::errstr";
print "\n  Connected to database.\n";

# demonstrate how to grant privileges on a table
$rc = TbPrivGrant();
if($rc == 0)
{
	die "\nError: Granting privileges on a table failed\n";
}

# demonstrate how to display privileges on a table
$rc = TbPrivDisplay();
if(not defined $rc)
{
  die "\nError: Displaying privileges on a table failed\n";
}

# demonstrate how to revoke privileges on a table
$rc = TbPrivRevoke();
if(not defined $rc)
{
  die "\nError: Revoking privileges on a table failed";
}

# disconnect from the database
print "\n  Disconnecting from database.";
$dbh->disconnect
  || die "Can't disconnect from database: $DBI::errstr";
print "\n  Disconnected from database.\n";

##########################################################################
# Description: How to grant privileges on a table
# Input      : None
# Output     : Returns 0 on success, exits otherwise 
##########################################################################
sub TbPrivGrant
{
  
  my $sql;

  print "  \n----------------------------------------------------------\n"; 
  print "USE THE SQL STATEMENTS:\n"; 
  print "  GRANT (Table, View, or Nickname Privileges)\n"; 
  print "TO GRANT PRIVILEGES ON A TABLE.\n";
  print "\n  GRANT SELECT, INSERT, UPDATE(salary, comm)\n"; 
  print "    ON TABLE staff\n"; 
  print "    TO USER user1";

  $sql = qq(GRANT SELECT, INSERT, UPDATE(salary, comm)
                ON TABLE staff
                TO USER user1);
  # prepare and execute the SQL statement
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # commit the transaction
  print "\n\n  COMMIT \n";
  $rc  = $dbh->commit;
 
  # no more data to be fetched from statement handle
  $rc = $sth->finish;
  
  return $rc;
} # TbPrivGrant

##########################################################################
# Description: How to display privileges on a table
# Input      : None
# Output     : Returns 0 on success, exits otherwise
##########################################################################
sub TbPrivDisplay
{
 
  my $sql;

  print "----------------------------------------------------------\n";
  print "USE THE SQL STATEMENT:\n";
  print "  SELECT\n";
  print "TO DISPLAY PRIVILEGES ON A TABLE.\n";
  print "\n  SELECT granteetype, controlauth, alterauth,";
  print "\n         deleteauth, indexauth, insertauth,";
  print "\n         selectauth, refauth, updateauth";
  print "\n    FROM syscat.tabauth";
  print "\n    WHERE grantee = 'USER1' AND";
  print "\n          tabname = 'STAFF'\n";

  $sql = qq(SELECT granteetype, controlauth, alterauth,
                      deleteauth, indexauth, insertauth,
                      selectauth, refauth, updateauth
                 FROM syscat.tabauth
                 WHERE grantee = 'USER1' AND
                       tabname = 'STAFF');
 
  # prepare and execute the SQL statement
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # fetch result of the query into variables for display
  ($granteetype, $controlauth, $alterauth,$deleteauth, $indexauth, 
   $insertauth, $selectauth, $refauth, $updateauth) = $sth->fetchrow();
  
  print "\n  Grantee Type     = ",$granteetype;
  print "\n  CONTROL priv.    = ",$controlauth;
  print "\n  ALTER priv.      = ",$alterauth;
  print "\n  DELETE priv.     = ",$deleteauth;
  print "\n  INDEX priv.      = ",$indexauth;
  print "\n  INSERT priv.     = ",$insertauth;
  print "\n  SELECT priv.     = ",$selectauth;
  print "\n  REFERENCES priv. = ",$refauth;
  print "\n  UPDATE priv.     = ",$updateauth;
  print "\n";
  
  # no more data to be fetched from statement handle
  $rc = $sth->finish;
  
  return $rc;
} # TbPrivDisplay

##########################################################################
# Description: How to revoke privileges on a table
# Input      : None
# Output     : Returns 0 on success, exits otherwise
##########################################################################
sub TbPrivRevoke
{
 
  my $sql;

  print "----------------------------------------------------------\n";
  print "USE THE SQL STATEMENT:\n";
  print "  REVOKE (Table, View, or Nickname Privileges)\n";
  print "TO REVOKE PRIVILEGES ON A TABLE.\n";
  print "\n  REVOKE SELECT, INSERT, UPDATE";
  print "\n    ON TABLE staff";
  print "\n    FROM USER user1";

  $sql = qq(REVOKE SELECT, INSERT, UPDATE
                 ON TABLE staff
                 FROM USER user1);

  # prepare and execute the SQL statement
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
  $sth = PrepareExecuteSql($dbh, $sql); 
  
  # commit the transaction  
  print "\n\n  COMMIT\n";
  my $rc = $dbh->commit;
  
  # no more data to be fetched from statement handle
  $rc = $sth->finish;
 
  return $rc;
} # TbPrivRevoke
