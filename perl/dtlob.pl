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
# SOURCE FILE NAME: dtlob.sqc 
# 
# SAMPLE: How to use the LOB data type 
#   
# Note:
# -----
# This sample program creates 2 new files, namely, Photo.GIF and Resume.TXT
# in the current working directory.
#
# SQL STATEMENTS USED: 
#         SELECT
#         INSERT
#         DELETE
# 
# OUTPUT FILE: dtlob.out (available in the online documentation) 
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
use DBD::DB2::Constants;

# access the module for DB2 Sample Utility functions
use DB2SampUtil;

# check and parse the command line arguments
# call the subroutine CmdLineArgChk from DB2SampUtil.pm
my ($database, $user, $password) = CmdLineArgChk(@ARGV);

# declare return code, statement handler, database handler
my ($rc, $sth, $dbh);

print "THIS SAMPLE SHOWS HOW TO USE THE LOB DATA TYPE.\n";

# connect to the database
print "\n  Connecting to database...";
$dbh = DBI->connect($database, $user, $password, {AutoCommit => 1})
         || die "Can't connect to $database: $DBI::errstr";
print "\n  Connected to database.\n";

# call the subroutine BlobFileuse
$rc = BlobFileUse();
if ($rc != 0)
{
  print "\nError: BlobFileUse subroutine failed\n";
}

# call the subroutine ClobUse
$rc = ClobUse();
if ($rc != 0)
{
  print "\nError: ClobUse subroutine failed\n";
}

# call the subroutine ClobFileUse
$rc = ClobFileUse();
if ($rc != 0)
{
  print "\nError: ClobFileUse subroutine failed\n";
}

# call the subroutine ClobLocatorUse
$rc = ClobLocatorUse();
if ($rc !=0)
{
  print "\nError: ClobLocatorUse subroutine failed\n";
}

# disconnect from the database
print"\n  Disconnecting from sample...";
$dbh->disconnect();
print"\n  Disconnected from sample.\n";

###########################################################################
# Description: The BlobFileUse subroutine shows how to read/write BLOB data 
#              from/to a database.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
###########################################################################
sub BlobFileUse
{  
  # format of the BLOB data
  my $photoFormat = "gif";
  
  # name of the file in which BLOB data will be stored 
  my $fileName = "Photo.GIF"; 
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE SQL STATEMENTS:\n");
  printf("  SELECT\n");
  printf("  INSERT\n");
  printf("  DELETE\n");
  printf("TO SHOW HOW TO USE A BLOB FILE.\n");
  
  # LongReadLen determines size of the buffer allocated by the DBI when
  # fetching columns containing LOB data
  $dbh->{LongReadLen} = 512 * 1024;
  
  # instruct the DBI not to truncate LOB data if it exceeds the buffer size
  $dbh->{LongTruncOk} = 0;

  # read the BLOB data into a file
  printf("\n  Read BLOB data in the file '%s'.\n", $fileName);

  my $sql = "SELECT picture FROM emp_photo". 
         "  WHERE photo_format = 'gif' AND empno = '000130'";

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # fetch the blob data
  my $blob_data = $sth->fetchrow;
  
  # no more data to be fetched from statement handle
  $sth->finish;
  
  # write the BLOB data into a file
  open FILE, ">Photo.GIF";
  binmode FILE; # this specifies that the file is to be treated in binary 
                # mode
  print FILE "$blob_data";
  close(FILE);
  
  # read the BLOB data from the file into a variable
  printf("  Write BLOB data from the file '%s'.\n", $fileName);
  open FILE, "<Photo.GIF";
  binmode FILE;
  read(FILE, $blob_data, -s FILE);
  close(FILE);
  
  # prepare the SQL statement
  $sth = $dbh->prepare("INSERT INTO emp_photo(empno, photo_format, picture)
                          VALUES('200340', 'gif', ?)")
           || print $DBI::errstr;
  
  # bind the input parameter to the INSERT statement  
  $sth->bind_param(1, $blob_data, { 'TYPE' => SQL_BLOB })
    || print $sth->errstr;
 
  # execute insert statement
  $sth->execute()
    || print $sth->errstr;
    
  # delete the new record 
  printf("  Delete the new record from the database.\n");
  $dbh->do("DELETE FROM emp_photo WHERE empno = '200340'")
    || print $sth->errstr;

  # no more data to be fetched from statement handle
  $sth->finish;
 
  return 0;  
} # BlobFileUse

###########################################################################
# Description: The ClobUse subroutine shows how to read CLOB data from a
#              database.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
###########################################################################
sub ClobUse
{
  # declare local variables
  my ($sql, $empno, $resume, @arr, $i, $resume_length); 
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE SQL STATEMENTS:\n");
  printf("  SELECT\n");
  printf("TO SHOW HOW TO USE THE CLOB DATA TYPE.\n");
  
  printf("\n  READ THE CLOB DATA:\n");

  $sql = "SELECT empno, resume FROM emp_resume".
         "  WHERE resume_format = 'ascii' AND empno = '000130'";

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # fetch the data 
  ($empno, $resume) = $sth->fetchrow();

  # get the first 15 lines of resume
  @arr = split("\n", $resume);
  $resume_length = length($resume);

  printf("\n    Empno: %s\n", $empno);
  printf("    Resume length: %d\n", $resume_length);
  printf("    First 15 lines of the resume:\n");

  for($i = 1; $i <= 15; $i++)
  { 
    printf("$arr[$i]\n");
  }

  # no more data to be fetched from statement handle
  $sth->finish;
  
  return 0;
  
} # ClobUse

###########################################################################
# Description: The ClobFileUse subroutine shows how to read/write BLOB data 
#              from/to a database to/from a file.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
###########################################################################
sub ClobFileUse
{
  # declare local variables
  my ($fileName, $sql, $clob_data);
  
  printf("\n-----------------------------------------------------------");
  printf("\nUSE THE SQL STATEMENT:\n");
  printf("  SELECT\n");
  printf("TO SHOW HOW TO WRITE CLOB DATA TO A FILE.\n");

  # specify name of the file in which clob data will be stored
  $fileName = "Resume.TXT";

  printf("\n  Read CLOB data in the file '%s'.\n", $fileName);

  $sql = "SELECT resume FROM emp_resume".
         "  WHERE resume_format = 'ascii' AND empno = '000130'";

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # fetch the clob data
  $clob_data = $sth->fetchrow();

  # write the clob data to a file
  open(FILE, ">Resume.TXT");
  print FILE "$clob_data";
  close(FILE);

  # no more data to be fetched from statement handle
  $sth->finish;

  return 0;
} # ClobFileUse

###########################################################################
# Description: The ClobLocatorUse subroutine shows how to search through 
#              CLOB data and to write CLOB data into a database.
# Input      : None
# Output     : Returns 0 on success, exits otherwise.
###########################################################################
sub ClobLocatorUse
{
  # declare local variables
  my ($sql, $resume, $str_dept, $pos1, $pos2);
  my ($str_edu, $new_resume);

  printf("\n--------------------------------------------------------");
  printf("\nUSE THE SQL STATEMENT:\n");
  printf("  SELECT \n");
  printf("  INSERT\n");
  printf("  DELETE\n");
  printf("  TO SHOW HOW TO USE THE CLOB LOCATOR.\n");

  printf("\n  **************************************************\n");
  printf("           ORIGINAL RESUME -- VIEW\n");
  printf("  **************************************************\n");

  $sql = "SELECT resume FROM emp_resume".
         "  WHERE empno = '000130' AND resume_format = 'ascii'";

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $sql);
  
  # the CLOB data in the field 'resume' is stored into the variable $resume
  $resume = $sth->fetchrow();

  # no more data to be fetched from statement handle
  $sth->finish;

  # print the CLOB data
  printf($resume);

  printf("\n  ********************************************\n");
  printf("       NEW RESUME -- CREATE\n");
  printf("  ********************************************\n");

  # escape the ' character contained in the modified resume data.
  $_ = $resume;
  s/\'/\'\'/;
  $resume = $_;
  
  # locate the 'Department Information' in the resume
  $str_dept = "Department Information";
  $pos1 = index($resume, $str_dept);
  printf("\n  Create short resume without Department Info.\n");

  # locate the 'Education' in the resume
  $str_edu = "Education";
  $pos2 = index($resume, $str_edu);

  printf("  Append Department Info at the end of Short resume.\n");

  # the variable $new_resume contains the modified resume data.
  $new_resume = substr($resume, 1, $pos1 - 1);
  $new_resume = $new_resume.substr($resume, $pos2);
  $new_resume = $new_resume.substr($resume, $pos1, $pos2 - $pos1);

  printf("  Insert the new resume in the database.\n");

  $sql = "INSERT INTO emp_resume(empno, resume_format, resume)".
         "  VALUES('200340', 'ascii', '$new_resume')";

  # prepare and execute the sql statement
  $dbh->do($sql);

  printf("\n  *************************************\n");
  printf("      NEW RESUME -- VIEW\n");
  printf("  *************************************\n");

  $sql = "SELECT resume FROM emp_resume".
         "  WHERE empno = '200340'";

  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $sql);

  # the variable $new_resume contains the modified resume data read from
  # the database. 
  $new_resume = $sth->fetchrow();

  printf($new_resume);

  printf("\n  **************************************\n");
  printf("      NEW RESUME -- DELETE\n");
  printf("  **************************************\n");

  $sql = "DELETE FROM emp_resume WHERE empno = '200340'";

  # prepare and execute the sql statement
  $dbh->do($sql);

  # no more data to be fetched from statement handle
  $sth->finish;
  
  return 0;
} # ClobLocatorUse
