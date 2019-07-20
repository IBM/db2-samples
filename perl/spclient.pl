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
# SOURCE FILE NAME: spclient.pl
#
# SAMPLE: Call various stored procedures
#
#         This file contains eleven functions that call stored procedures:
#
#  (1) callOutLanguage: Calls a stored procedure that returns the 
#      implementation language of the stored procedure library
#        Parameter types used: OUT CHAR(8)
#  (2) callOutParameter: Calls a stored procedure that returns median 
#      salary of employee salaries
#        Parameter types used: OUT DOUBLE                    
#  (3) callInParameters: Calls a stored procedure that accepts 3 salary 
#      values and updates employee salaries in the EMPLOYEE table based 
#      on these values for a given department.
#        Parameter types used: IN DOUBLE
#                              IN DOUBLE
#                              IN DOUBLE
#                              IN CHAR(3)
#  (4) callInoutParameter: Calls a stored procedure that accepts an input
#      value and returns the median salary of those employees in the
#      EMPLOYEE table who earn more than the input value. Demonstrates how 
#      to use null indicators in a client application. The stored procedure
#      has to be implemented in the following parameter styles for it to be
#      compatible with this client application.
#        Parameter style for a C stored procedure: SQL
#        Parameter style for a Java(JDBC/SQLJ) stored procedure: JAVA
#        Parameter types used: INOUT DOUBLE
#  (5) callClobExtract: Calls a stored procedure that extracts and returns a 
#      portion of a CLOB data type
#        Parameter types used: IN CHAR(6)
#                              OUT VARCHAR(1000)
#  (6) callDBINFO: Calls a stored procedure that receives a DBINFO
#      structure and returns elements of the structure to the client
#        Parameter types used: IN CHAR(8)
#                              OUT DOUBLE
#                              OUT CHAR(128)
#                              OUT CHAR(8)
#  (7) callProgramTypeMain: Calls a stored procedure implemented with
#       PROGRAM TYPE MAIN parameter style
#         Parameter types used: IN CHAR(8)
#                               OUT DOUBLE
#  (8) callAllDataTypes: Calls a stored procedure that uses a variety of 
#      common data types (not DECIMAL, GRAPHIC, VARGRAPHIC, BLOB, CLOB, DBCLOB).
#      This sample shows only a subset of DB2 supported data types. For a  
#      full listing of DB2 data types, please see the SQL Reference.
#        Parameter types used: INOUT SMALLINT
#                              INOUT INTEGER
#                              INOUT BIGINT
#                              INOUT REAL
#                              INOUT DOUBLE
#                              OUT CHAR(1)
#                              OUT CHAR(15)
#                              OUT VARCHAR(12)
#                              OUT DATE
#                              OUT TIME
#  (9) callOneResultSet: Calls a stored procedure that return a result set to
#      the client application
#        Parameter types used: IN DOUBLE
#  (10) callTwoResultSets: Calls a stored procedure that returns two result 
#       sets to the client application
#        Parameter types used: IN DOUBLE
#  (11) callGeneralExample: Call a stored procedure inplemented with 
#       PARAMETER STYLE GENERAL 
#        Parameter types used: IN INTEGER
#                              OUT INTEGER
#                              OUT CHAR(33) 
#
#         The file "DB2SampUtil.pm" contains functions for error-checking and
#         rolling back a transaction in case of error. 
#
# SQL STATEMENTS USED:
#         CALL
#         ROLLBACK
#         SELECT
#
# EXTERNAL DEPENDENCIES:
#      For successful precompilation, the sample database must exist 
#      (see DB2's db2sampl command).
#
#      The stored procedures called from this program must have been built
#      and cataloged in the database (see the instructions in spserver.sqc
#      or spserver.c).
#
# OUTPUT FILE: spclient.out (available in the online documentation)
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
use DBD::DB2;
use DBD::DB2::Constants;

# access the module for DB2 Sample Utility functions
use DB2SampUtil;

# check and parse the command line arguments
# call the subroutine CmdLineArgChk from DB2SampUtil.pm
my ($database, $user, $password) = CmdLineArgChk(@ARGV);

# declare return code, statement handler, database handler and local variables
my ($rc, $sth, $dbh);
my ($outLang, $testLangSql, $testLangC, $testLangJava, $median) = (0);

print "HOW TO CALL VARIOUS STORED PROCEDURES.\n";

# connect to the database
print "\n  Connecting to '$database' database...";
$dbh = DBI->connect($database, $user, $password, {AutoCommit => 0})
        || die "Can't connect to $database: $DBI::errstr";
print "\n  Connected to database.\n";


# call the subroutine CallOutLanguage
$rc = CallOutLanguage($outLang);
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure OUT_LANGUAGE failed\n";
}

# we assume that all the remaining stored procedures are also written in
# the same language as $outLang and set the following variables accordingly.
# This would help us in invoking only those stored procedures that are
# supported in that particular language.   
# index function returns position of the first occurrence of second string 
# in the first string and -1 in case the second string is not a part of the
# first 
$testLangSql = index($outLang, "SQL");
$testLangC = index($outLang, "C");
$testLangJava = index($outLang, "JAVA");

# call the subroutine CallOutParameter
$rc = CallOutParameter($median);
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure OUT_PARAM failed\n";
}

# call the subroutine CallInParameters
$rc = CallInParameters();
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure IN_PARAM failed\n";
}

# call the subroutine CallInoutParameter
printf "\nCALL stored procedure named INOUT_PARAM \n";
printf "using the median returned by the call to OUT_PARAM \n";
$rc = CallInoutParameter($median); 
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure INOUT_PARAM failed\n";
} 

# call INOUT_PARAM stored procedure two more times to intentionally show
# two different errors.  The first error depicts a NULL value condition that
# is returned when 'undef' is passed to the stored procedure.  The second  
# error shown is the result of a NOT FOUND error that is raised when no rows  
# are found to satisfy a query in the procedure.  No row is found because the 
# query depends on the procedure's input parameter value which is too high.
print "\nCALL stored procedure INOUT_PARAM again\n";
print "using a NULL input value\n";
print "\n**************** Expected Error ******************\n\n";
$rc = CallInoutParameter(undef);
printf "**************************************************\n";
  
print "\nCALL stored procedure INOUT_PARAM again \n";
print "using a value that returns a NOT FOUND error from the ";
print "stored procedure\n";
print "\n**************** Expected Error ******************\n\n";
$rc = CallInoutParameter(99999.99);
printf "**************************************************\n";

# call the subroutine CallClobExtract 
if ($testLangC == 0) 
{ 
  # warn the user that the CLI stored procedure requires a change 
  # to the UDF_MEM_SZ variable 
  print "\n  If the CLOB EXTRACT stored procedure is implemented\n";
  print "  using CLI, you must increase the value of the UDF_MEM_SZ\n";
  print "  database manager configuration variable to at least two\n";
  print "  pages larger than the size of the input arguments and\n";
  print "  the result of the stored procedure. To do this, issue\n";
  print "  the following command from the CLP:\n";
  print "    db2 UPDATE DBM CFG USING UDF_MEM_SZ 2048\n";
  print "  For the change to take effect, you must then stop and\n";
  print "  restart the DB2 server by issuing the following\n";
  print "  commands from the CLP:\n";
  print "    db2stop\n";
  print "    db2start\n";
} 
$rc = CallClobExtract(); 
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure CLOB_EXTRACT failed\n";
} 

if ($testLangC != 0) 
{ 
  # stored procedures of PARAMETER STYLE DB2SQL, DBINFO, or PROGRAM TYPE  
  # MAIN can only be implemented by LANGUAGE C stored procedures. 
  # If language != "C", we know that those stored procedures are 
  # not implemented, and therefore do not call them. 
} 
else 
{ 
  # call the subroutine CallDBINFO 
  $rc = CallDBINFO(); 
  if ($rc != 0)
  {
    print"\nRollback the transaction.\n";
    $dbh->rollback();
    print "\nError: Call to stored procedure DBINFO_EXAMPLE failed\n";
  } 
   
  # call the subroutine CallProgramTypeMain 
  $rc = CallProgramTypeMain(); 
  if ($rc != 0)
  {
    print"\nRollback the transaction.\n";
    $dbh->rollback();
    print "\nError: Call to stored procedure MAIN_EXAMPLE failed\n";
  } 
}

########################################################################
# Perl applications do not provide direct support for the DECIMAL
# data type.
# The following programming languages can be used to directly manipulate
# the DECIMAL type:
#          - JDBC
#          - SQLJ
#          - SQL routines
#          - .NET common language runtime languages (C#, Visual Basic)
# Please see the SpClient implementation for one of the above languages
# to see this functionality.
########################################################################

# call the subroutine CallAllDataTypes
$rc = CallAllDataTypes();
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure ALL_DATA_TYPES failed\n";
}

# call the subroutine CallOneResultSet
$rc = CallOneResultSet($median);
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure ONE_RESULT_SET failed\n";
}

# call the subroutine CallTwoResultSets
$rc = CallTwoResultSets($median);
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure TWO_RESULT_SETS failed\n";
}

# call the subroutine CallGeneralExample
$rc = CallGeneralExample(16);
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure GENERAL_EXAMPLE failed\n";
}

# call the subroutine CallGeneralExample
$rc = CallGeneralWithNullsExample(2);
if ($rc != 0)
{
  print"\nRollback the transaction.\n";
  $dbh->rollback();
  print "\nError: Call to stored procedure GENERAL_EXAMPLE failed\n";
}
  
# call GENERAL_WITH_NULLS_EXAMPLE stored procedure again 
# GENERAL_WITH_NULLS_EXAMPLE to depict NULL value        
print "\nCALL stored procedure GENERAL_WITH_NULLS_EXAMPLE again\n";
print "using a NULL input value\n";
printf "\n**************** Expected Error ******************\n";
$rc = CallGeneralWithNullsExample(undef);
printf "\n**************************************************\n";
 
# no more data to be fetched from statement handle
$sth->finish;

print"\nRollback the transaction.\n";
$dbh->rollback();

print"\n  Disconnecting from sample...";
$dbh->disconnect();
print"\n  Disconnected from sample.\n";

##########################################################################
# Description: Call OUT_LANGUAGE stored procedure 
# Input      : string outLang which gets updated after the call to 
#              OUT_LANGUAGE 
# Output     : Returns 0 on success 
##########################################################################
sub CallOutLanguage
{ 
  # declare local variables
  my $callStmt = qq(CALL OUT_LANGUAGE (?)); 
  $outLang = $_[0];

  $rc = -1;
  printf("\nCALL stored procedure named OUT_LANGUAGE");
  
  eval    
  {
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
      || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param_inout(1, \$outLang, 8, { 'TYPE' => SQL_VARCHAR })
      || die $sth->errstr;
    
    # execute call statement
    $sth->execute()
      || die $sth->errstr;

    print "\nStored procedure returned successfully.";
    print "\nStored procedures are implemented in LANGUAGE $outLang\n";

    # no more data to be fetched from statement handle
    $sth->finish;

    $dbh->rollback();                
    $rc = 0;
  };
    
  return $rc; 
} # CallOutLanguage

##########################################################################
# Description: Call OUT_PARAM stored procedure
# Input      : Median
# Output     : Returns 0 on success 
##########################################################################
sub CallOutParameter
{
  # declare local variables
  my $outMedian;
  
  $rc = -1;
  $median = $_[0];
  
  printf("\nCALL stored procedure named OUT_PARAM\n");
 
  my $callStmt = qq(CALL OUT_PARAM (?));
  eval
  {
    # prepare call  statement
    my $sth = $dbh->prepare($callStmt)
      || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param_inout(1, \$outMedian, 31, { 'TYPE' => SQL_DOUBLE })
      || die $sth->errstr;

    # execute call statement
    $sth->execute()
      || die $sth->errstr; 
          
    print "Stored procedure returned successfully.\n";
    # display the median salary returned as an output parameter   
    printf("Median salary returned from OUT_PARAM = %8.2f\n", $outMedian);
  
    $median = $outMedian;
  
    # no more data to be fetched from statement handle
    $sth->finish;
   
    $dbh->rollback();
    $rc = 0;
   }; 
  
  return $rc;
} # CallOutParameter

##########################################################################
# Description: Call IN_PARAMS stored procedure
# Input      : None
# Output     : Returns 0 on success
##########################################################################
sub CallInParameters
{

  # declare local variables 
  my $inLowsal = 15000;
  my $inMedsal = 20000;
  my $inHighsal = 25000;
  my $inDept = 'E11';
  my ($selectStmt, $callStmt, $sumSalary);
  
  $rc = -1;
  printf("\nCALL stored procedure named IN_PARAMS");
  
  $selectStmt = qq(SELECT SUM(salary) 
                     FROM employee 
                     WHERE workdept = '$inDept');

  eval
  {
    # prepare and execute the SQL statement
    # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
    $sth = PrepareExecuteSql($dbh, $selectStmt);

    # fetch the sum into a variable for display
    my $sumSalary = $sth->fetchrow();
    printf("\nSum of salaries for dept %s = %8.2f before calling IN_PARAMS\n",
           $inDept, $sumSalary);

    my $callStmt = qq(CALL IN_PARAMS (?, ?, ?, ?));
  
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
      || die $sth->errstr;            
 
    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inLowsal, { 'TYPE' => SQL_DOUBLE })
       || die $sth->errstr;
    $sth->bind_param(2, $inMedsal, { 'TYPE' => SQL_DOUBLE })
       || die $sth->errstr;
    $sth->bind_param(3, $inHighsal, { 'TYPE' => SQL_DOUBLE })
       || die $sth->errstr;
    $sth->bind_param(4, $inDept, { 'TYPE' => SQL_VARCHAR })
       || die $sth->errstr;
  
    # execute call statement
    $sth->execute()
       || die $sth->errstr;

    print "Stored procedure returned successfully.\n";
    # display the sum salaries for the affected department   
 
    $selectStmt = qq(SELECT SUM(salary)
                       FROM employee 
                       WHERE workdept = '$inDept');
  
    # prepare and execute the SQL statement
    # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm
    $sth = PrepareExecuteSql($dbh, $selectStmt);

    # fetch the sum into a variable for display
    $sumSalary = $sth->fetchrow();
    printf("Sum of salaries for dept %s = %9.2f after calling IN_PARAMS\n",
           $inDept, $sumSalary); 
    
    # no more data to be fetched from statement handle
    $sth->finish;

    $dbh->rollback();
    $rc = 0;
  };  
  
  return $rc;
} # CallInParameters

##########################################################################
# Description : Call INOUT_PARAM stored procedure
# Input       : Median value returned from CallOutParameter function
# Output      : Returns 0 on success
##########################################################################
sub CallInoutParameter
{
   
  # declare local variables
  my $inoutMedianSalary = $_[0];
  my $callStmt = qq(CALL INOUT_PARAM (?));

  $rc = -1;

  eval
  {
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
      || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param_inout(1, \$inoutMedianSalary, 31, { 'TYPE' => SQL_DOUBLE })
      || die $sth->errstr;
 
    # execute call statement
    $sth->execute()
      || die $sth->errstr;
   
    # check that the stored procedure executed successfully
    if (defined $inoutMedianSalary)
    {
      print "Stored procedure returned successfully.\n";
      printf("Median salary returned from INOUT_PARAM = %8.2f\n",
             $inoutMedianSalary);
    }
  
    # no more data to be fetched from statement handle
    $sth->finish;

    $dbh->rollback();
    $rc = 0;
  };  
    
  return $rc;
} # CallInoutParameter

##########################################################################
# Description: Call CLOB_EXTRACT stored procedure
# Input      : Median value returned from CallClobExtract function
# Output     : Returns 0 on success
##########################################################################
sub CallClobExtract
{
  
  # declare local variables
  my $inEmpno = '000140';  
  my $callStmt = qq(CALL CLOB_EXTRACT (?, ?));
  my $outResume;
  
  $rc = -1;  
  # call CLOB_EXTRACT stored procedure      
  print "\nCALL stored procedure named CLOB_EXTRACT\n"; 

  
  
  eval
  {
    # prepare call statement
    $sth = $dbh->prepare($callStmt)
       || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inEmpno, { 'TYPE' => SQL_CHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(2, \$outResume, 1000, { 'TYPE' => SQL_VARCHAR })
       || die $sth->errstr;
 
    # execute call statement
    $sth->execute()
      || die $sth->errstr;

    print "Stored procedure returned successfully.\n";
    print "Resume section returned from CLOB_EXTRACT =\n$outResume";

    # no more data to be fetched from statement handle
    $sth->finish;
  
    $dbh->rollback();
    $rc = 0;
  };
    
  return $rc;
} # CallClobExtract

##########################################################################
# Description: Call DBINFO_EXAMPLE stored procedure
# Input      : None
# Output     : Returns 0 on success
##########################################################################
sub CallDBINFO
{

  #declare local variables
  my $inJob = "CLERK";
  my $callStmt = qq(CALL DBINFO_EXAMPLE (?, ?, ?, ?));
  my ($outSalary, $outDbname, $outDbversion);
  $rc = -1;
  # call DBINFO_EXAMPLE stored procedure      
  print "\nCALL stored procedure named DBINFO_EXAMPLE\n"; 
   
  eval
  {
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
       || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inJob, { 'TYPE' => SQL_CHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(2, \$outSalary, 31, { 'TYPE' => SQL_DOUBLE })
       || die $sth->errstr;
    $sth->bind_param_inout(3, \$outDbname, 128, { 'TYPE' => SQL_CHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(4, \$outDbversion, 8, { 'TYPE' => SQL_CHAR })
       || die $sth->errstr;
  
    # execute call statement
    $sth->execute()
      || die $sth->errstr;
  
    print "Stored procedure returned successfully.\n";
    printf("Average salary for job %s = %9.2f\n", $inJob, $outSalary);
    print "Database name from DBINFO structure = $outDbname\n";
    print "Database version from DBINFO structure = $outDbversion\n";

    # no more data to be fetched from statement handle
    $sth->finish;
  
    $dbh->rollback();
    $rc = 0;
  };
    
  return $rc;
} # CallDBINFO

##########################################################################
# Description: Call MAIN_EXAMPLE stored procedure
# Input      : None
# Output     : Returns 0 on success
##########################################################################
sub CallProgramTypeMain
{

  # declare local variables
  my $inJob = "DESIGNER";
  my $callStmt = qq(CALL MAIN_EXAMPLE (?, ?));
  my $outSalary;
  $rc = -1;
  
  # call MAIN_EXAMPLE stored procedure      
  print "\nCALL stored procedure named MAIN_EXAMPLE\n"; 

  eval
  {
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
       || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inJob, { 'TYPE' => SQL_CHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(2, \$outSalary, 31, { 'TYPE' => SQL_DOUBLE })
       || die $sth->errstr;

    # execute call statement
    $sth->execute()
      || die $sth->errstr;
  
    print "Stored procedure returned successfully.\n";
    printf("Average salary for job %s = %9.2f\n", 
            $inJob, $outSalary);

    # no more data to be fetched from statement handle
    $sth->finish;
    
    $dbh->rollback();
    $rc = 0;
  };
    
  return $rc;
} # CallProgramTypeMain

##########################################################################
# Description: Call ALL_DATA_TYPES stored procedure
# Input      : None
# Output     : Returns 0 on success
##########################################################################
sub CallAllDataTypes
{
  # declare local variables
  my $inoutSmallint = 32000;
  my $inoutInteger = 2147483000;
  my $inoutBigint = 2147480000;
  
  # maximum value of BIGINT is 9223372036854775807 
  # but some platforms only support 32-bit integers 
  my $inoutReal = 100000;
  my $inoutDouble = 2500000;  
  my ($outChar, $outChars, $outVarchar, $outDate, $outTime);

  my $callStmt = qq(CALL ALL_DATA_TYPES (?, ?, ?, ?, ?, 
                                         ?, ?, ?, ?, ?));
  
  $rc = -1;
  # call ALL_DATA_TYPES stored procedure      
  print "\nCALL stored procedure named ALL_DATA_TYPES\n"; 
    
  eval
  {
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
      || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param_inout(1, \$inoutSmallint, 10, { 'TYPE' => SQL_SMALLINT  })
       || die $sth->errstr;
    $sth->bind_param_inout(2, \$inoutInteger, 10, { 'TYPE' => SQL_INTEGER })
       || die $sth->errstr;
    $sth->bind_param_inout(3, \$inoutBigint, 10, { 'TYPE' => SQL_BIGINT })
       || die $sth->errstr;
    $sth->bind_param_inout(4, \$inoutReal, 15, { 'TYPE' => SQL_REAL })
       || die $sth->errstr;
    $sth->bind_param_inout(5, \$inoutDouble, 31, { 'TYPE' => SQL_DOUBLE })
       || die $sth->errstr;
    $sth->bind_param_inout(6, \$outChar, 1, { 'TYPE' => SQL_CHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(7, \$outChars, 15, { 'TYPE' => SQL_VARCHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(8, \$outVarchar, 12, { 'TYPE' => SQL_VARCHAR })
       || die $sth->errstr;
    $sth->bind_param_inout(9, \$outDate, 10, { 'TYPE' => SQL_TYPE_DATE })
       || die $sth->errstr;
    $sth->bind_param_inout(10, \$outTime, 8, { 'TYPE' => SQL_TYPE_TIME })
       || die $sth->errstr;

    # execute call statement
    $sth->execute()
      || die $sth->errstr;

    print "Stored procedure returned successfully.\n";
    # display the sum salaries for the affected department 
   
    printf("Value of SMALLINT = %d\n", $inoutSmallint);
    printf("Value of INTEGER = %d\n", $inoutInteger);
    printf("Value of BIGINT = %d\n", $inoutBigint);
    printf("Value of REAL = %.2f\n", $inoutReal);
    printf("Value of DOUBLE = %.2f\n", $inoutDouble);
    printf("Value of CHAR(1) = %s\n", $outChar);
    printf("Value of CHAR(15) = %s\n", $outChars);
    printf("Value of VARCHAR(12) = %s\n", $outVarchar);
    printf("Value of DATE = %s\n", $outDate);
    printf("Value of TIME = %s\n", $outTime);

    # no more data to be fetched from statement handle
    $sth->finish;
  
    $dbh->rollback();
    $rc = 0;
  };   
  
  return $rc;
} # CallAllDataTypes

##########################################################################
# Description: Call ONE_RESULT_SET stored procedure
# Input      : Median value returned from CallOutParameter function
# Output     : Returns 0 on success
##########################################################################
sub CallOneResultSet
{
  
  # declare local variables
  my $inSalary = $_[0];
  my ($numCols,  $outName, $outJob, $outSalary);
  my $callStmt = qq(CALL ONE_RESULT_SET (?));
  
  $rc = -1;
  
  # call ONE_RESULT_SET stored procedure      
  print "\nCALL stored procedure named ONE_RESULT_SET\n"; 

  eval
  {
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
       || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inSalary, { 'TYPE' => SQL_DOUBLE  })
       || die $sth->errstr;
  
    # execute call statement
    $sth->execute()
      || die $sth->errstr;

    $numCols = $sth->{NUM_OF_FIELDS};  
    print "Result set returned $numCols columns\n";
  
    # bind column 1 to variable 
    $sth->bind_col(1, \$outName); 

    # bind column 2 to variable 
    $sth->bind_col(2, \$outJob); 

    # bind column 3 to variable 
    $sth->bind_col(3, \$outSalary); 
 
    print "Stored procedure returned successfully.\n";
    print "\nFirst result set returned from ONE_RESULT_SET";
    print "\n------Name------,  --JOB--, ---Salary--  \n";
    while ($sth->fetchrow())
    {
      printf("%16s,%9s,    %.2f\n", $outName, $outJob, $outSalary);
    }

    # no more data to be fetched from statement handle
    $sth->finish;
    
    $dbh->rollback();
    $rc = 0;
  };  
  
  return $rc;
} # CallOneResultSet

########################################################################## 
# Description: Call TWO_RESULT_SETS stored procedure 
# Input      : Median value returned from CallOutParameter function 
# Output     : Returns 0 on success 
########################################################################## 
sub CallTwoResultSets 
{ 

  # declare local variables
  my $inSalary = $_[0];  
  my ($numCols, $outName, $outJob, $outSalary);
  my $callStmt = qq(CALL TWO_RESULT_SETS (?)); 
  
  $rc = -1;
  
  # call TWO_RESULT_SETS stored procedure 
  print "\nCALL stored procedure named TWO_RESULT_SETS\n"; 
 
  eval
  {
    # prepare call  statement 
    $sth = $dbh->prepare($callStmt) 
       || die $sth->errstr;
 
    # bind a value with a placeholder embedded in the prepared statement 
    $sth->bind_param(1, $inSalary, { 'TYPE' => SQL_DOUBLE  }) 
       || die $sth->errstr; 
 
    # execute call statement 
    $sth->execute() 
      || die $sth->errstr; 
 
    $numCols = $sth->{NUM_OF_FIELDS}; 
    print "Result set returned $numCols columns\n"; 
 
    # bind column 1 to variable 
    $sth->bind_col(1, \$outName); 
 
    # bind column 2 to variable 
    $sth->bind_col(2, \$outJob); 

    # bind column 3 to variable 
    $sth->bind_col(3, \$outSalary); 
 
    print "Stored procedure returned successfully\n"; 
    
    # fetch the first result set 
    print "\nFirst result set returned from TWO_RESULT_SETS"; 
    print "\n------Name------,  --JOB--, ---Salary--  \n"; 
    while ($sth->fetchrow()) 
    { 
      printf("%16s, %9s,    %.2f\n", $outName, $outJob, $outSalary); 
    } 
 
    # fetch the remaining result sets 
    while ($sth->{db2_more_results}) 
    { 
      print "\nNext result set returned from TWO_RESULT_SETS"; 
      print "\n------Name------,  --JOB--, ---Salary--  \n"; 
      while ($sth->fetchrow()) 
      { 
        printf("%16s, %9s,    %.2f\n", $outName, $outJob, $outSalary); 
      } 
    } 
 
    # no more data to be fetched from statement handle
    $sth->finish; 
   
    $dbh->rollback();
    $rc = 0;
  };  
  
  return $rc; 
} # CallTwoResultSets 

########################################################################## 
# Description: Call GENERAL_EXAMPLE stored procedure 
# Input      : Education Level
# Output     : Returns 0 on success 
########################################################################## 
sub CallGeneralExample
{
  # declare local variables
  my $inEdLevel = $_[0];
  my $callStmt = qq(CALL GENERAL_EXAMPLE (?, ?, ?)); 
  my ($outSqlrc, $outMsg, $numCols, $firstnme, $lastname, $workdept); 
  $rc = -1;
    
  # call GENERAL_EXAMPLE stored procedure 
  print "\nCALL stored procedure named GENERAL_EXAMPLE\n"; 

  eval
  {  
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
       || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inEdLevel, { 'TYPE' => SQL_INTEGER })
       || die $sth->errstr;
    $sth->bind_param_inout(2, \$outSqlrc, 10, { 'TYPE' => SQL_INTEGER })
       || die $sth->errstr;
    $sth->bind_param_inout(3, \$outMsg, 32, { 'TYPE' => SQL_CHAR })
      || die $sth->errstr;

    # execute call statement
    $sth->execute()
      || die $sth->errstr;
 
    if ($outSqlrc == 0)
    {
      $numCols = $sth->{NUM_OF_FIELDS};  
      print "Result set returned $numCols columns\n";
  
      # bind column 1 to variable 
      $sth->bind_col(1, \$firstnme); 

      # bind column 2 to variable 
      $sth->bind_col(2, \$lastname); 

      # bind column 3 to variable 
      $sth->bind_col(3, \$workdept); 
    
      print "Stored procedure returned successfully.\n";
      printf("\n-----FIRSTNME-------LASTNAME-----WORKDEPT--\n");

      while (($firstnme, $lastname, $workdept) = $sth->fetchrow())
      {
        printf("%12s,       %-10s, %3s\n", $firstnme, $lastname, $workdept);
      }
    }
    else
    {
      print "Stored procedure returned SQLCODE $outSqlrc";
      print "With Error: $outMsg \n";
    }

    # no more data to be fetched from statement handle
    $sth->finish;
  
    $dbh->rollback();
    $rc = 0;
  };  
  
  return $rc;
} # CallGeneralExample

########################################################################## 
# Description: Call GENERAL_WITH_NULLS_EXAMPLE stored procedure 
# Input      : Quarter
# Output     : Returns 0 on success 
########################################################################## 
sub CallGeneralWithNullsExample
{
  
  # declare local variables
  my $inQuarter = $_[0];
  my ($outSqlrc, $numCols, $salesPerson, $region, $sales, $outMsg);
  my $callStmt = qq(CALL GENERAL_WITH_NULLS_EXAMPLE (?, ?, ?)); 
  
  $rc = -1;
  # call GENERAL_WITH_NULLS_EXAMPLE stored procedure 
  print "\nCALL stored procedure named GENERAL_WITH_NULLS_EXAMPLE\n"; 

  eval
  {  
    # prepare call  statement
    $sth = $dbh->prepare($callStmt)
       || die $sth->errstr;

    # bind a value with a placeholder embedded in the prepared statement
    $sth->bind_param(1, $inQuarter, { 'TYPE' => SQL_INTEGER })
       || die $sth->errstr;
    $sth->bind_param_inout(2, \$outSqlrc, 10, { 'TYPE' => SQL_INTEGER })
       || die $sth->errstr;
    $sth->bind_param_inout(3, \$outMsg, 32, { 'TYPE' => SQL_CHAR })
      || die $sth->errstr;

    # execute call statement
    $sth->execute()
      || die $sth->errstr;
     
    if ($outSqlrc == 0)
    {
      $numCols = $sth->{NUM_OF_FIELDS};  
      print "Result set returned $numCols columns\n";
  
      # bind column 1 to variable 
      $sth->bind_col(1, \$salesPerson); 

      # bind column 2 to variable 
      $sth->bind_col(2, \$region); 

      # bind column 3 to variable 
      $sth->bind_col(3, \$sales); 
 
      print "Stored procedure returned successfully.\n";
      printf("\n---SALES_PERSON---REGION-----------SALES--\n");

      while (($salesPerson, $region, $sales) = $sth->fetchrow())
      {
        printf("  %-10s,    %-15s", $salesPerson, $region);
        if (defined $sales)
        {  
          printf(",  %-1d\n", $sales);
        }
        else
        {
          print ",  - \n";
        } 
      }
    }
    else
    {
      print "Stored procedure returned SQLCODE $outSqlrc";
      print "\nWith Error: $outMsg \n";
    }

    # no more data to be fetched from statement handle
    $sth->finish;
  
    $dbh->rollback();
    $rc = 0;
  };  
  
  return $rc;
} # CallGeneralWithNullsExample
