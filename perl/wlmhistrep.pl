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
# SOURCE FILE NAME: wlmhistrep.pl
#
# TITLE: Generate historical analysis reports
#
# PURPOSE: Generates historical analysis reports based on user input and 
#          input from the wlmhist table.
#
# DETAILS: This tool is used in conjunction with the wlmhist.pl that      
#          generates historical data and puts the information in wlmhist
#          table.  This tool reads the information from the wlmhist table
#          generates the following reports depending on input from the user:
#          - Tables Hit - shows the list of tables that have been accessed
#          - Tables Not Hit - shows the list of non-system tables that have 
#                             not been accessed 
#          - Indexes Hit - shows the list of indexes that have been accessed
#          - Indexes Not Hit - shows the list of indexes that have not been 
#                              accessed
#          - Submitters Hit - shows the list of users that have run DML 
#
# FORMAT: wlmhistrep.pl dbAlias userId passwd [outputFile report schemaName 
#         fromTime toTime submitter]
#         Use - to bypass optional parameters.
#
# OUTPUT FILE: Selected Report either to the screen or to the file
#              specified by the user
##########################################################################

select STDERR; $|=1;
select STDOUT; $|=1;

use strict;
use warnings; 
use DBI;
use Data::Dumper;

# access the module for historical common functions 
#----------------------------------------------------
use DB2WlmHist;

# For Format
use FileHandle;
use English;

# check and parse the command line arguments
# call the subroutine WLMArgChk to verify the arguments passed in.
#------------------------------------------------------------------
my ($database, $user, $password, $outFile, $report, $schemaName, $fromTime, 
    $toTime, $submitter) = WLMArgChk(@ARGV);


# extract the database name.  It current shows up as db2:db2:databasename
#------------------------------------------------------------------------
my ($databaseText, @arr);
@arr = split(':', $database);
$databaseText= $arr[2];

# Determine whether we will be printing the report to a file or to STDOUT
# and output parameters that were passed in
#-------------------------------------------------------------------------
my $outToFile = 0;
if ($outFile ne "-")
{
  $outToFile = 1;
  open FILE, ">$outFile" or die "\n Unable to open file $outFile\n";

  print FILE "\n Input Parameters ";
  print FILE "\n ---------------- ";
  print FILE "\n Database:                                 ";
  print FILE "$databaseText";
  print FILE "\n User:                                     ";
  print FILE "$user";
  print FILE "\n Output File:                              ";
  print FILE "$outFile";
  print FILE "\n Reports:                                  ";
  print FILE "$report";
  print FILE "\n Schema:                                   ";
  print FILE "$schemaName";
  print FILE "\n From Time:                                ";
  print FILE "$fromTime";
  print FILE "\n To Time:                                  ";
  print FILE "$toTime";
  print FILE "\n Submitter:                                ";
  print FILE "$submitter";
  
  close(FILE);
}

if ($schemaName eq "-")
{
  $schemaName = $user;
}
# Uppercase the schemaName and the submitter 
#--------------------------------------------
$schemaName =~ tr/a-z/A-Z/;
$submitter =~ tr/a-z/A-Z/;


# declare return code, statement handler, database handler and local variable
#----------------------------------------------------------------------------
my ($rc, $sth, $dbh, $i, $tablesHit, $tablesNotHit, $indexesHit, $indexesNotHit, $usersHit);

# defines for the different reports
#-----------------------------------
$tablesHit = "A";
$tablesNotHit = "B";
$indexesHit = "C";
$indexesNotHit = "D";
$usersHit = "E";

print "Generate historical data reports for database $databaseText .\n";

# connect to the database
#------------------------
print "\n  Connecting to database...\n";

if ($password eq "-")
{
  $dbh = DBI->connect($database, "", "", {AutoCommit => 0})
              or die "Can't connect to $database: $DBI::errstr";
}
else 
{
  $dbh = DBI->connect($database, $user, $password, {AutoCommit => 0})
              or die "Can't connect to $database : $DBI::errstr";
}

print "\n  Connected to database.\n";


# call the subroutine MainReport to generate the requested report. 
#----------------------------------------------------------------------------
$rc = 0;
$rc = MainReport();
if (!defined $rc)
{
  die "\nSomething went wrong with generating historical data report\n";
}

# disconnect from the database
#-------------------------------
print "\n  Disconnecting from database...\n";
$dbh->disconnect
  or die $DBI::errstr;
print "\n  Disconnected from database.\n";


##########################################################################
# Description : Checks and parses the command line arguments
# Input       : An array containing the command line arguments that was 
#               passed to the calling function
# Output      : Database name, user name, password, outputfile, report, 
#               schemaName, fromTime, toTime, submitter
###########################################################################
sub WLMArgChk
{
  my $arg_c = @_; # number of arguments passed to the function
  my @arg_l; # arg_l holds the values to be returned to calling function
  my $i = 0;

  if($arg_c > 9 or $arg_c < 3 or ($arg_c == 1 and (($_[0] eq "?") or
                                  ($_[0] eq "-?") or
                                  ($_[0] eq "/?") or
                                  ($_[0] eq "-h") or
                                  ($_[0] eq "/h") or
                                  ($_[0] eq "-help") or
                                  ($_[0] eq "/help"))) or
      ($arg_c == 2 and $_[1] eq "-") or
      ($arg_c == 3 and $_[2] eq "-") or 
      ($arg_c > 3 and ($_[1] eq "-" or $_[2] eq "-")))

  {
    die << "EOT";
Usage: 
 wlmhistrep.pl dbAlias userId passwd [outputFile report schemaName fromTime toTime submitter]

 Use - to bypass optional parameters.

 "report" can be any combination from the following letters: 
    A - Tables Hit 
    B - Tables Not Hit 
    C - Indexes Hit 
    D - Indexes Not Hit 
    E - Submitters 

 The from_time and to_time must be specified in timestamp format.
   For example 2007-06-06-17.00.00

EOT
  }   

  # Set the database, user, password arguments
  #-------------------------------------------
  $arg_l[0] = "dbi:DB2:".$_[0];
  $arg_l[1] = $_[1];
  $arg_l[2] = $_[2];

  # Rest of the arguments are optional so if they are not specified
  # set them to - for now
  #----------------------------------------------------------------
  if ($arg_c <= 9)
  {
    $i = 3;
    while ($i <= 9)
    {
      if ($i < $arg_c)
      {
        $arg_l[$i] = $_[$i];
      } 
      else 
      {
        $arg_l[$i] = "-";
      }
      $i = $i + 1;
    }
  }

  return @arg_l;
} # WLM ArgChk

#######################################################################
# Description : Main subroutine for creating the reports for the 
#               historical data
# Input       : None 
# Output      : Returns 0 on success, exits otherwise
#######################################################################
sub MainReport
{


  # If the report param was not specified, then we
  # will generate all the available reports
  #------------------------------------------------
  if ($report eq "-")
  {
    $report = "ABCDE";
  } 
  else
  {
    # Uppercase the report input
    #---------------------------
    $report =~ tr/a-z/A-Z/;
  }

  # Tables Hit
  #----------- 
  if ( ($report =~ s/$tablesHit/$tablesHit/g) >= 1)
  {
    TablesHitReport();
  }

  # Tables Not Hit
  #-----------------
  if ( ($report =~ s/$tablesNotHit/$tablesNotHit/g) >= 1)
  {
    TablesNotHitReport();
  }

  # Indexes Hit
  #-----------------
  if ( ($report =~ s/$indexesHit/$indexesHit/g) >= 1)
  {
    IndexesHitReport();
  }

  # Indexes Not Hit
  #-----------------
  if ( ($report =~ s/$indexesNotHit/$indexesNotHit/g) >= 1)
  {
    IndexesNotHitReport();
  }

  # Users Hit
  #------------
  if ( ($report =~ s/$usersHit/$usersHit/g) >= 1)
  {
    SubmittersHitReport();
  }


  return 0;
} # MainReport

#######################################################################
# Description : Routine to extract the data and print out the    
#               Tables Hit report
# Input       :
# Output      : Tables Hit report
#             : Returns 0 on success, exits otherwise
#######################################################################
sub TablesHitReport
{

  # Set up filters through parameters specified by the user that will be
  # added on to the query to filter what is extracted for the report
  #---------------------------------------------------------------------
  my $numberWritten = 0;
  my $fromTimeText = "";
  my $toTimeText = "";
  my $submitterText = "";
  if ($fromTime ne "-")
  {
    $fromTimeText = " and (time_started > ".
                           "timestamp('$fromTime')) ";  
  }
  if ($toTime ne "-")
  {
    $toTimeText = " and (time_started <= ".
                         "timestamp('$toTime')) ";  
  }
  if ($submitter ne "-")
  {
    $submitterText = " and (creator = '$submitter') ";  
  }
 

  # Query to extract the information from the wlmhist table for the    
  # tables hit report
  #---------------------------------------------------------------------
  my $sqlToGetReport = 
   "WITH TOTALHITS (total) AS ".
     "(Select sum(z.total_hits) ".
      "from (SELECT DISTINCT X.table_name, X.table_schema, ".
                            "sum(X.NUMBER_OF_HITS) TOTAL_HITS ".
             "FROM (SELECT y.activity_ID, y.uow_id, y.appl_id, ".
                          "y.activity_secondary_id, y.TABLE_NAME, ".
                          "y.TABLE_SCHEMA, COUNT(*) NUMBER_OF_HITS ".
                    "FROM ".
                         "(SELECT distinct activity_id, uow_id, appl_id, ".
                                 "activity_secondary_id, ".
                                 "table_name, table_schema, creator ".
                          "from $schemaName.WLMHIST ".
                          "where activity_id is not null ".
                              "$fromTimeText $toTimeText $submitterText ".
                                 ") as y ".
                           "GROUP BY y.TABLE_NAME, y.table_schema, ".
                                     "y.activity_ID, y.uow_id, y.appl_id, ".
                                     "y.activity_secondary_id, ".
                                     "y.creator ) as X ".
                    "group by X.Table_Name, x.Table_schema) as z) ".
   "SELECT DISTINCT X.table_name, X.table_schema, ".
                   "(cast(sum(number_of_hits) as DOUBLE)/TOTALHITS.total)*100,".
                   " sum(X.NUMBER_OF_HITS) TOTAL_HITS ".
   "FROM TOTALHITS, ".
        "(SELECT y.activity_ID, y.uow_id, y.appl_id, y.activity_secondary_id, ".
                "y.TABLE_NAME, ".
                "y.TABLE_SCHEMA, COUNT(*) NUMBER_OF_HITS ".
         "FROM ".
               "(SELECT distinct activity_id, uow_id, appl_id, ".
                                "activity_secondary_id, table_name, ".
                                "table_schema, creator ".
                 "from $schemaName.WLMHIST ".
                 "where activity_id is not null ".
                     "$fromTimeText $toTimeText $submitterText ".
                              ") as y ".
                 "GROUP BY y.TABLE_NAME, y.table_schema, y.activity_ID, ".
                           "y.uow_id, y.appl_id, y.activity_secondary_id ) as X ".
         "group by X.Table_Name, x.Table_schema, TOTALHITS.TOTAL";
  
  # Set up the header for the report
  #------------------------------------
format TablesHitTopFormat =

                TABLES HIT REPORT FOR DATABASE @<<<<<<<<<<<<<<<<<<<<
                                               $databaseText
              _______________________________________________________


TABLE NAME                     TABLE SCHEMA         % HITS        TOTAL HITS
______________________         __________________   _____________ ____________

.

  # Prepare and execute SQL to fetch the information from the wlmhist
  # table
  #-----------------------------------------------------------------------
  my $sth = PrepareExecuteSql($dbh, $sqlToGetReport); 

  # Variables to be filled in from query to table
  #-------------------------------------------------
  my ($tableName, $tableSchema, $percntHits, $totalHits) = "";
   
format TablesHitFormat = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<< @###.######## @###########
$tableName,                     $tableSchema,     $percntHits,  $totalHits
.

  # Name the format for both the top of the report and the body of
  # the report
  #-----------------------------------------------------------------
  STDOUT->format_name("TablesHitFormat");
  STDOUT->format_top_name("TablesHitTopFormat");

  # If we are to output to a file, open the file now and write out the 
  # title of the report
  #-------------------------------------------------------------------
  if ($outToFile == 1)
  { 
    open TablesHitTopFormat, ">>$outFile";
    write(TablesHitTopFormat);
    close(TablesHitTopFormat);

    open TablesHitFormat, ">>$outFile";
  }

  # Loop around to fetch and write out each row
  #--------------------------------------------
  while (($tableName, $tableSchema, $percntHits, $totalHits) = 
          $sth->fetchrow())
  {
    
    $outToFile ? write(TablesHitFormat) : write;
    $numberWritten++;
  }

  # If nothing was written, the write out at least the header to the report
  #------------------------------------------------------------------------
  if ($numberWritten == 0)
  {
    $tableName = "";
    $tableSchema = "";
    $percntHits = 0;
    $totalHits = 0;
    $outToFile ? write(TablesHitFormat) : write;
  }
  
  
  if ($outToFile)
  {
    print TablesHitFormat "\n \n";
    close(TablesHitFormat);
  } 
  else 
  {
    print "\n \n";
  }

  # Set format to top of next page
  #-------------------------------
  $- = 0;

  $sth->finish;
  $dbh->commit;
  return;
} # TablesHitReport

#######################################################################
# Description : Routine to extract the data and print out the    
#               Tables Not Hit report
# Input       :
# Output      : Tables Not Hit report
#             : Returns 0 on success, exits otherwise
#######################################################################
sub TablesNotHitReport
{
  # Set up filters through parameters specified by the user that will be
  # added on to the query to filter what is extracted for the report
  #---------------------------------------------------------------------
  my $numberWritten = 0;
  my $fromTimeText = "";
  my $toTimeText = "";
  my $submitterText = "";
  if ($fromTime ne "-")
  {
    $fromTimeText = " and (time_started > ".
                             "timestamp('$fromTime')) ";  
  }
  if ($toTime ne "-")
  {
    $toTimeText = " and (time_started <= ".
                             "timestamp('$toTime')) ";  

  }
  if ($submitter ne "-")
  {
    $submitterText = " and (creator = '$submitter') ";  
  }


  # Query to extract the information from the wlmhist table for the    
  # tables not hit report
  #---------------------------------------------------------------------
  my $sqlToGetReport2 = 
       "SELECT DISTINCT tabname, tabschema, create_time ".
       "FROM syscat.tables ".
       "WHERE definer != 'SYSIBM' AND ".
             "tabschema != 'DB2QP' AND ".
             "(tabname, tabschema) NOT IN ".
                "(SELECT DISTINCT y.table_name, y.table_schema ".
                  "FROM ".
                     "(SELECT distinct activity_id, uow_id, appl_id, ".
                                      "activity_secondary_id, ".
                                      "table_name, table_schema, ".
                                      "creator ".
                       "FROM $schemaName.WLMHIST ".
                       "where activity_id is not null ".
                                "$fromTimeText $toTimeText $submitterText ".
                               ") as y ".
                       "GROUP BY y.Table_Name, y.table_schema) ".
                 "GROUP BY tabschema, tabname, create_time ".
                 "ORDER BY tabschema, tabname ";

  # Set up the header for the report
  #------------------------------------
format TablesNotHitTopFormat =

                TABLES NOT HIT REPORT FOR DATABASE @<<<<<<<<<<<<<<<<<<<<
                                                   $databaseText
              __________________________________________________________


TABLE NAME                     TABLE SCHEMA         CREATE TIME
____________________________   __________________   __________________________

.
 

 
  # Prepare and execute SQL to fetch the information from the wlmhist
  # table
  #-----------------------------------------------------------------------
  my $sth = PrepareExecuteSql($dbh, $sqlToGetReport2); 

  # Variables to be filled in from query to table
  #-------------------------------------------------
  my ($tableName, $tableSchema, $createTime);

  format TablesNotHitFormat = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<
$tableName,                    $tableSchema,        $createTime
.

  # Name the format for both the top of the report and the body of
  # the report
  #-----------------------------------------------------------------
  STDOUT->format_name("TablesNotHitFormat");
  STDOUT->format_top_name("TablesNotHitTopFormat");

  # If we are to output to a file, open the file now and write out the 
  # title of the report
  #-------------------------------------------------------------------
  if ($outToFile == 1)
  { 
    open TablesNotHitTopFormat, ">>$outFile";
    write (TablesNotHitTopFormat);
    close (TablesNotHitTopFormat);

    open TablesNotHitFormat, ">>$outFile";
  } 
  
  # Loop around to fetch and write out each row
  #---------------------------------------------
  while (($tableName, $tableSchema, $createTime) = 
          $sth->fetchrow())
  {
    $outToFile ? write(TablesNotHitFormat) : write;
    $numberWritten++;
  }

  # If nothing was written, the write out at least the header to the report
  #------------------------------------------------------------------------
  if ($numberWritten == 0)
  {
    $tableName = "";
    $tableSchema = "";
    $createTime = "";
    $outToFile ? write(TablesNotHitFormat) : write;
  }
  
  if ($outToFile)
  {
    print TablesNotHitFormat "\n \n";
    close (TablesNotHitFormat);
  } 
  else 
  {
    print "\n \n";
  }

  # Set format to top of next page
  #--------------------------------
  $- = 0;

  $sth->finish;
  $dbh->commit;
  return;
} # TablesNotHitReport

#######################################################################
# Description : Routine to extract the data and print out the    
#               Indexes Hit report
# Input       :
# Output      : Indexes Hit report
#             : Returns 0 on success, exits otherwise
#######################################################################
sub IndexesHitReport
{
  # Set up filters through parameters specified by the user that will be
  # added on to the query to filter what is extracted for the report
  #---------------------------------------------------------------------
  my $numberWritten = 0;
  my $fromTimeText = "";
  my $toTimeText = "";
  my $submitterText = "";
  if ($fromTime ne "-")
  {
    $fromTimeText = " and ($schemaName.WLMHIST.time_started > ".
                              "timestamp('$fromTime')) ";  
  }
  if ($toTime ne "-")
  {
    $toTimeText = " and ($schemaName.WLMHIST.time_started <= ".
                              "timestamp('$toTime')) ";  
  }
  if ($submitter ne "-")
  {
    $submitterText = " and ($schemaName.WLMHIST.creator = '$submitter')";  
  }

  # Query to extract the information from the wlmhist table for the    
  # indexes hit report
  #---------------------------------------------------------------------
  my $sqlToGetReport = 
     "WITH q (total_hits) as(select sum (column_hits) ".
     "from (SELECT $schemaName.WLMHIST.table_name, ".
                  "$schemaName.WLMHIST.table_schema, ".
                  "$schemaName.WLMHIST.object_name, ".
                  "$schemaName.WLMHIST.object_schema, ".
                  "count( * ) column_hits from $schemaName.WLMHIST ".
           "where ( $schemaName.WLMHIST.object_type = 'I') AND ".
                   "( $schemaName.WLMHIST.object_name != '' ) ".
                   "$fromTimeText $toTimeText $submitterText ".
           "group by $schemaName.WLMHIST.table_name, ".
                    "$schemaName.WLMHIST.table_schema, ".
                    "$schemaName.WLMHIST.object_name, ".
                    "$schemaName.WLMHIST.object_schema ".
           "order by 4 desc) as x) ".
     "SELECT $schemaName.WLMHIST.table_name, $schemaName.WLMHIST.table_schema, ".
            "$schemaName.WLMHIST.object_name, ".
            "$schemaName.WLMHIST.object_schema, ".
            "(cast(count(*) as DOUBLE)/q.total_hits)*100 percent, ".
            "count(*) from $schemaName.WLMHIST, q ".
     "where ( $schemaName.WLMHIST.object_type = 'I') AND ".
            "( $schemaName.WLMHIST.object_name != '' ) ".
            "$fromTimeText $toTimeText $submitterText ".
     "group by $schemaName.WLMHIST.table_name, ".
              "$schemaName.WLMHIST.table_schema, ".
              "$schemaName.WLMHIST.object_name, ".
              "$schemaName.WLMHIST.object_schema, ".
              "q.total_hits ".
     "order by 4 desc ";


  
  # Set up the header for the report
  #------------------------------------
format IndexesHitTopFormat =

               INDEXES HIT REPORT FOR DATABASE @<<<<<<<<<<<<<<<<<<<<
                                               $databaseText
              _______________________________________________________


TABLE NAME         TABLE SCHEMA    OBJECT NAME        OBJECT SCHEMA   TOTAL HITS
__________________ _______________ __________________ _______________ __________

.

  # Prepare and execute SQL to fetch the information from the wlmhist
  # table
  #-----------------------------------------------------------------------
  my $sth = PrepareExecuteSql($dbh, $sqlToGetReport); 

  # Variables to be filled in from fetch from tables
  #---------------------------------------------------
  my ($tableName, $tableSchema, $objectName, $objectSchema, $pcntHits, $totalHits);

  # Set up format for report
  #-------------------------
format IndexesHitFormat = 
@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @#########
$tableName,        $tableSchema,   $objectName,       $objectSchema,  $totalHits
.

  # Name the format for both the top of the report and the body of
  # the report
  #-----------------------------------------------------------------
  STDOUT->format_name("IndexesHitFormat");
  STDOUT->format_top_name("IndexesHitTopFormat");

  # If we are to output to a file, open the file now and write out the 
  # title of the report
  #-------------------------------------------------------------------
  if ($outToFile == 1)
  { 
    open IndexesHitTopFormat, ">>$outFile";
    write(IndexesHitTopFormat);
    close(IndexesHitTopFormat);

    open IndexesHitFormat, ">>$outFile";
  }

  # Loop around to fetch and write out each row
  #---------------------------------------------
  while (($tableName, $tableSchema, $objectName, $objectSchema, 
          $pcntHits, $totalHits) = $sth->fetchrow())
  {
    $outToFile ? write(IndexesHitFormat) : write;
    $numberWritten++;
  }

  # If nothing was written, the write out at least the header to the report
  #------------------------------------------------------------------------
  if ($numberWritten == 0)
  {
    $tableName = "";
    $tableSchema = "";
    $objectName = "";
    $objectSchema = "";
    $totalHits = 0;
    $outToFile ? write(IndexesHitFormat) : write;
  }

  if ($outToFile)
  {
    print IndexesHitFormat "\n \n";
    close(IndexesHitFormat);
  } 
  else 
  {
    print "\n \n";
  }

  # Set format to top of next page
  #-------------------------------
  $- = 0;

  $sth->finish;
  $dbh->commit;
  return;
} # IndexesHitReport

#######################################################################
# Description : Routine to extract the data and print out the    
#               Indexes Not Hit report
# Input       :  
# Output      : Indexes Not Hit report
#             : Returns 0 on success, exits otherwise
#######################################################################
sub IndexesNotHitReport
{
  # Set up filters through parameters specified by the user that will be
  # added on to the query to filter what is extracted for the report
  #---------------------------------------------------------------------
  my $numberWritten = 0;
  my $fromTimeText = "";
  my $toTimeText = "";
  my $submitterText = "";
  if ($fromTime ne "-")
  {
    $fromTimeText = " and (y.time_started > ".
                         "timestamp('$fromTime'))";  
  }
  if ($toTime ne "-")
  {
    $toTimeText = " and (y.time_started <= timestamp('$toTime'))";  
  }
  if ($submitter ne "-")
  {
    $submitterText = " and (y.creator = '$submitter')";  
  }


  # Query to extract the information from the wlmhist table for the    
  # indexes not hit report
  #---------------------------------------------------------------------
  my $sqlToGetReport = 
     "SELECT DISTINCT tabname, tabschema, indname, indschema, definer, ".
                     "indextype ".
     "FROM syscat.indexes ".
     "WHERE (indname) NOT IN ".
        "(SELECT DISTINCT X.object_name ".
         "FROM ".
           "(SELECT y.object_name ".
            "FROM ".
                 "(SELECT DISTINCT table_schema, table_name, object_name, ".
                                "object_type, activity_id, uow_id, appl_id, ".
                                "activity_secondary_id, creator, time_started ".
                  "FROM $schemaName.WLMHIST) AS y ".
                  "WHERE  y.object_type = 'I' ".
                          "$fromTimeText $toTimeText $submitterText ".
                  "GROUP BY y.table_schema, y.table_name, y.object_name, ".
                           "y.object_type, y.activity_id, y.uow_id, ".
                           "y.appl_id, y.activity_secondary_id) as X ".
            "GROUP BY X.object_name) ".
         "GROUP BY tabschema, tabname, indname, indschema, definer, ".
                   "indextype ".
         "ORDER BY indname";

  # Set up the header for the report
  #------------------------------------
format IndexesNotHitTopFormat =

               INDEXES NOT HIT REPORT FOR DATABASE @<<<<<<<<<<<<<<<<<<<<
                                                   $databaseText
              ___________________________________________________________


TABLE NAME         TABLE SCHEMA    INDEX NAME         INDEX SCHEMA    INDEX TYPE
__________________ _______________ __________________ _______________ __________

.

  # Prepare and execute SQL to fetch the information from the wlmhist
  # table
  #-----------------------------------------------------------------------
  my $sth = PrepareExecuteSql($dbh, $sqlToGetReport); 

  # Variables to be filled in from fetch from tables
  #---------------------------------------------------
  my ($tableName, $tableSchema, $indexName, $indexSchema, $indexDefiner, $indexType);


  # Set up format for report
  #-------------------------
format IndexesNotHitFormat = 
@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<
$tableName,        $tableSchema,   $indexName,        $indexSchema,   $indexType
.

  # Name the format for both the top of the report and the body of
  # the report
  #-----------------------------------------------------------------
  STDOUT->format_name("IndexesNotHitFormat");
  STDOUT->format_top_name("IndexesNotHitTopFormat");

  # If we are to output to a file, open the file now and write out the 
  # title of the report
  #-------------------------------------------------------------------
  if ($outToFile == 1)
  { 
    open IndexesNotHitTopFormat, ">>$outFile";
    write (IndexesNotHitTopFormat);
    close (IndexesNotHitTopFormat);

    open IndexesNotHitFormat, ">>$outFile";
  } 

  # Loop around to fetch and write out each row
  #---------------------------------------------
  while (($tableName, $tableSchema, $indexName, $indexSchema, $indexDefiner, $indexType) = 
          $sth->fetchrow())
  {
    $outToFile ? write(IndexesNotHitFormat) : write;
    $numberWritten++;
  }

  # If nothing was written, the write out at least the header to the report
  #------------------------------------------------------------------------
  if ($numberWritten == 0)
  {
    $tableName = "";
    $tableSchema = "";
    $indexName = "";
    $indexSchema = "";
    $indexDefiner = "";
    $indexType = "";
    $outToFile ? write(IndexesNotHitFormat) : write;
  }

  if ($outToFile)
  {
    print IndexesNotHitFormat "\n \n";
    close (IndexesNotHitFormat);
  } 
  else 
  {
    print "\n \n";
  }

  # Set format to top of next page
  #--------------------------------
  $- = 0;

  $sth->finish;
  $dbh->commit;
  return;
} # IndexesNotHitReport

#######################################################################
# Description : Routine to extract the data and print out the    
#               Submitters Hit report
# Input       : Indexes Not Hit report
# Output      : Returns 0 on success, exits otherwise
#######################################################################
sub SubmittersHitReport
{
  # Set up filters through parameters specified by the user that will be
  # added on to the query to filter what is extracted for the report
  #---------------------------------------------------------------------
  my $numberWritten = 0;
  my $fromTimeText = "";
  my $toTimeText = "";
  my $submitterText = "";
  my $fromTimeText2 = "";
  my $toTimeText2 = "";
  my $submitterText2 = "";
  if ($fromTime ne "-")
  {
    $fromTimeText = " and (x.time_started > ".
                      "timestamp('$fromTime'))";  
    $fromTimeText2 = " and (t.time_started > ".
                      "timestamp('$fromTime'))";  
  }
  if ($toTime ne "-")
  {
    $toTimeText = " and (x.time_started <= timestamp('$toTime'))";  
    $toTimeText2 = " and (t.time_started <= timestamp('$toTime'))";  
  }
  if ($submitter ne "-")
  {
    $submitterText = " and (x.creator = '$submitter')";  
    $submitterText2 = " and (t.creator = '$submitter')";  
  }


  # Query to extract the information from the wlmhist table for the    
  # submitters hit report
  #---------------------------------------------------------------------
  my $sqlToGetReport = 
     "WITH Q (TOTAL_HITS) as ".
     "(SELECT SUM(TABLE_HITS) ".
      "from ".
        "(SELECT COUNT(*) TABLE_HITS ".
         "from ".
              "(SELECT DISTINCT activity_id, uow_id, appl_id, ".
                               "activity_secondary_id, time_started, ".
                               "time_created, creator ".
               "from $schemaName.WLMHIST) as X ".
          "where (x.time_started is not null ) ".   
                 "$fromTimeText $toTimeText $submitterText ) as Y) ".
     "SELECT T.CREATOR, (CAST(COUNT(*) as DOUBLE)/Q.TOTAL_HITS)*100 PERCENT, ".
            "COUNT(*) TOTALHITS, sum(timestampdiff(2, ".
            "char(time_started - time_created))) TOTALELPTIME, ".
            "sum(timestampdiff(2, ".
            "char(time_started - time_created)))/count(*) AVGELPTIME ".
     "from Q, ".
          "(SELECT DISTINCT activity_id, ".
                           "uow_id, ".
                           "appl_id, ".
                           "activity_secondary_id, ".
                           "time_started, time_created, ".
                           "creator from $schemaName.WLMHIST) as T ".
     "where ( t.time_started is not null ) ".
               "$fromTimeText2 $toTimeText2 $submitterText2 ".
     "group by T.CREATOR, Q.TOTAL_HITS ".
     "order by 2 desc";

  
  # Set up the header for the report
  #------------------------------------
format SubmittersHitTopFormat =

               SUBMITTERS HIT REPORT FOR DATABASE @<<<<<<<<<<<<<<<<<<<<
                                                  $databaseText
              ___________________________________________________________


SUBMITTER         TOTAL ELAPSED TIME  AVG ELAPSED TIME  % QUERIES     # QUERIES
_________________ __________________  ________________  ____________  _________

.

  # Prepare and execute SQL to fetch the information from the wlmhist
  # table
  #-----------------------------------------------------------------------
  my $sth = PrepareExecuteSql($dbh, $sqlToGetReport); 

  # Variables to be filled in from fetch from tables
  #-------------------------------------------------
  my ($userName, $totElapsedTime, $avgElapsedTime, $percQueries, $numberQueries);

  # Set up format for report
  #-------------------------
format SubmittersHitFormat = 
@<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<  @###.#######   @<<<<<<<<
$userName,        $totElapsedTime,    $avgElapsedTime,   $percQueries,  $numberQueries
.

  # Name the format for both the top of the report and the body of
  # the report
  #-----------------------------------------------------------------
  STDOUT->format_name("SubmittersHitFormat");
  STDOUT->format_top_name("SubmittersHitTopFormat");

  # If we are to output to a file, open the file now and write out the 
  # title of the report
  #-------------------------------------------------------------------
  if ($outToFile == 1)
  { 
    open SubmittersHitTopFormat, ">>$outFile";
    write (SubmittersHitTopFormat);
    close (SubmittersHitTopFormat);

    open SubmittersHitFormat, ">>$outFile";
  } 

  # Loop around to fetch and write out each row
  #---------------------------------------------
  while (($userName, $percQueries, $numberQueries, $totElapsedTime, 
          $avgElapsedTime) = $sth->fetchrow())
  {
    $outToFile ? write(SubmittersHitFormat) : write;
    $numberWritten++;
  }

  # If nothing was written, the write out at least the header to the report
  #------------------------------------------------------------------------
  if ($numberWritten == 0)
  {
    $userName = "";
    $totElapsedTime = ""; 
    $avgElapsedTime = "";
    $percQueries = 0;
    $numberQueries = 0;
    $outToFile ? write(SubmittersHitFormat) : write;
  }

  if ($outToFile)
  {
    print SubmittersHitFormat "\n \n";
    close (SubmittersHitFormat);
  } 
  else 
  {
    print "\n \n";
  }

  # Set format to top of next page
  #--------------------------------
  $- = 0;

  $sth->finish;
  $dbh->commit;
  return;
} # SubmittersHitReport


