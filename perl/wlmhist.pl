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
# SOURCE FILE NAME: wlmhist.pl
#
# TITLE: Generate historical data
#
# PURPOSE: Generates historical data for activities that are captured
#          in the event_activity and event_activitystmt logical data 
#          groups.
#
# DETAILS: This tool will extract information from the event_activity
#          and event_activitystmt logical data groups (such as the activity
#          statement) based on user input and for each activity extracted
#          it will:
#          - run explain on the activity
#          - extract information from the explain tables
#          - message the extracted information
#          - insert historical data into the wlmhist table (which this tool
#            will create if the it does not exist)
# 
#          Data from the wlmhist table as well as from the 
#          event_activity logical data group will be used as input to 
#          the wlmhistrep tool to generate historical reports
#
# FORMAT: wlmhist.pl dbname user password [fromTime toTime workloadid
#         serviceClassName serviceSubclassName activityTable activityStmtTable]
#         Use - to bypass any optoinal parameters.
#
# OUTPUT FILE: data put into the wlmhist table.                     
##########################################################################

select STDERR; $|=1;
select STDOUT; $|=1;

use strict;
use warnings; 
use DBI;
use Data::Dumper;

# access the module for historical common functions 
#--------------------------------------------------
use DB2WlmHist;

# check and parse the command line arguments
# call the subroutine WLMArgChk to verify the arguments passed in.
#------------------------------------------------------------------
my ($database, $user, $password, $fromTime, $toTime, $workloadId,
    $serviceClassName, $serviceSubClassName, $activity, $activityStmt) 
          = WLMArgChk(@ARGV);
my $schemaName;

# If the activity and activitystmt parms were not specified, set their
# defaults
#---------------------------------------------------------------------
my $activityTable;
$schemaName = $user;

# hang on to the activity table name without the schema to be used later to
# determine whether we are in EEE or EE
if ($activity eq "-")
{
  $activityTable = "ACTIVITY_DB2ACTIVITIES";
  $activity = "$schemaName.ACTIVITY_DB2ACTIVITIES";
} else {
  $activityTable = $activity;
  $activity = "$schemaName.$activity";
}
if ($activityStmt eq "-")
{
  $activityStmt = "$schemaName.ACTIVITYSTMT_DB2ACTIVITIES";
} else {
  $activityStmt = "$schemaName.$activityStmt";
}


# declare return code, statement handler, database handler and local variable
#----------------------------------------------------------------------------
my ($rc, $sth, $dbh, $i, $numberProcessed, $numberProcessedSucc);

my @tables;     # Will contain all the table names that we have
                # accessed during the historical generate.  This is
                # a performance enhancement so that we don't have to 
                # perform a query for every table..if it has already been
                # accessed, then it will, instead, already be in this list


print "Generate historical data for database of $database \n";

# Set value indicating how many queries to process before doing a commit.
# This is for performance reasons so we are not committing all the time
#-----------------------------------------------------------------------
my $numRequestsToProcess = 100;

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
              or die "Can't connect to $database: $DBI::errstr";
}

print "\n  Connected to database.\n";


# Call the subroutine CreateWLMHISTTable to create the WLMHIST table
#--------------------------------------------------------------------
$rc = CreateWLMHISTTable();
if ($rc != 0)
{
  die "\nFailed to create WLMHIST table.\n";
}
  
# Call routine to remove any information from the explain tables
# that may have been added from the last run but somehow were not
# removed
#------------------------------------------------------------------
RemoveInfoFromExplainTables(1);

# Call routine to determine whether or not we are on EE or EEE
#--------------------------------------------------------------
my $isEEE = CheckPartition($dbh, $schemaName, $activityTable);

# call the subroutine MainGenerate to extract the activity text for
# all activities that meet the criteria specified by the input arguments and
# for each activity, run explain on it, extract information from the
# explain tables, massage the data and then insert that data into the 
# WLMHIST table
#----------------------------------------------------------------------------
$numberProcessed = 0;
$numberProcessedSucc = 0;
$rc = MainGenerate($schemaName, $fromTime, $toTime, $workloadId, $serviceClassName, $serviceSubClassName);
if (!defined $rc)
{
  die "\nSomething went wrong with generating historical data\n";
}

# disconnect from the database
#-------------------------------
print "\n  Disconnecting from database...\n";
$dbh->disconnect
  or die $DBI::errstr;

print "\n  Disconnected from database.\n";
print "\n  Total number of activities processed by historical generator: $numberProcessed Total number of activities processed successfully: $numberProcessedSucc \n\n";

##########################################################################
# Description : Checks and parses the command line arguments
# Input       : An array containing the command line arguments that was 
#               passed to the calling function
# Output      : Database name, user name, password, schemaName, fromTime, 
#               toTime, workloadId, serviceClassName, serviceSubclassName             
###########################################################################
sub WLMArgChk
{
  my $arg_c = @_; # number of arguments passed to the function
  my @arg_l; # arg_l holds the values to be returned to calling function
  my $i = 0;

  if($arg_c > 10 or $arg_c < 3 or ($arg_c == 1 and (($_[0] eq "?") or
                                  ($_[0] eq "-?") or
                                  ($_[0] eq "/?") or
                                  ($_[0] eq "-h") or
                                  ($_[0] eq "/h") or
                                  ($_[0] eq "-help" ) or
                                  ($_[0] eq "/help" ) ) ) or
      ($arg_c == 2 and $_[1] eq "-") or
      ($arg_c == 3 and $_[2] eq "-") or
      ($arg_c > 3 and ($_[1] eq "-" or $_[2] eq "-")))
  {
    die << "EOT";
Usage: 
 wlmhist.pl dbAlias userId passwd [fromTime toTime workloadid serviceClassName serviceSubclassName activityTable activityStmtTable] 

 Use - to bypass optional parameters.

 The from_time and to_time must be specified in timestamp format
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
  if ($arg_c <= 10)
  {
    $i = 3;
    while ($i <= 10)
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
# Description : Creates the wlmhist table if it does not already exist
# Input       : None 
# Output      : Returns 0 on success, exits otherwise
#######################################################################
sub CreateWLMHISTTable
{
  # Uppercase the user to use in 
  #------------------------------
  $schemaName =~ tr/a-z/A-Z/;

  # prepare and execute SQL statement to determine if the wlmhist table
  # already exists or not 
  #---------------------------------------------------------------------
  my $selectStmt = "select count(*) from sysibm.systables where name = 'WLMHIST' and creator ='$schemaName'";
  my $numberFound = 0;
  $sth = PrepareExecuteSql($dbh, $selectStmt);
  $numberFound = $sth->fetchrow();

  # commit the transaction or call TransRollback() from DB2SampUtil.pm 
  # if it fails
  #--------------------------------------------------------------------
  $dbh->commit() or 
    TransRollback($dbh);
  $sth->finish;

  # Only create the table if it does not yet exist  
  #------------------------------------------------
  if ($numberFound == 0)
  {
    
    # SQL to create the wlm hist table
    #---------------------------------
    my $sql = 
     "CREATE TABLE $schemaName.WLMHIST".
     "(ACTIVITY_ID BIGINT not null, UOW_ID INTEGER not null, ".
       "APPL_ID VARCHAR(64) not null, ".
       "ACTIVITY_SECONDARY_ID SMALLINT not null,  ".
       "ACTIVITY_TYPE VARCHAR(64) not null, ".
       "OBJECT_TYPE char(1), OBJECT_SCHEMA VARCHAR(128), ".
       "OBJECT_NAME VARCHAR(128), TABLE_SCHEMA VARCHAR(128) not null, ".
       "TABLE_NAME VARCHAR(128) not null, TIME_CREATED TIMESTAMP not null, ".
       "TIME_STARTED TIMESTAMP not null, TIME_COMPLETED TIMESTAMP not null, ".
       "CREATOR VARCHAR(128) not null)";

    # prepare and execute the SQL statement.
    # call the subroutine PrepareExecuteSql() from DB2WlmHist.pm
    #-------------------------------------------------------------
    $sth = PrepareExecuteSql($dbh, $sql); 

    # commit the transaction or call TransRollback() from DB2WlmHist.pm 
    # if it fails
    #---------------------------------------------------------------------
    $dbh->commit() or 
      TransRollback($dbh);
    $sth->finish;
  } 
  else 
  {
    print "\n  WLMHIST table already exists\n";
  }
 

  return 0;
} # CreateWLMHISTTable

#######################################################################
# Description : Main subroutine for generating historical data
# Input       : None 
# Output      : Returns 0 on success, exits otherwise
#######################################################################
sub MainGenerate
{
  my ($stmtText, $timeCreated, $timeStarted, $timeCompleted, $activityId, $uowId, $applicationId, $activitySecondaryId, $activityType, $creator, $compEnv);
 
  # set up SQL to run that will select the stmt text for all of the
  # activities based on input parameters/filters
  #----------------------------------------------------------------
  my $fromTimeText = "";
  my $toTimeText = "";
  my $workloadIdText = "";
  my $serviceClassText = "";
  my $serviceSubClassText = "";
  my $checkPartitionText = "";
  if ($fromTime ne "-")
  {
    $fromTimeText = " and a1.time_started > timestamp('$fromTime')";  
  }
  if ($toTime ne "-")
  {
    $toTimeText = " and a1.time_started <= timestamp('$toTime')";  
  }
  if ($workloadId ne "-")
  {
    $workloadIdText = " and a1.workload_id = ".$workloadId;
  }
  if ($serviceClassName ne "-")
  {
    $serviceClassText = " and a1.service_superclass_name = '$serviceClassName'";
  }
  if ($serviceSubClassName ne "-")
  {
    $serviceSubClassText = " and a1.service_subclass_name = '$serviceSubClassName'";
  }
 
  # If this is EEE, then we want to make sure we only get the activities 
  # from the coord partition.
  #---------------------------------------------------------------------- 
  if ($isEEE)
  {
    $checkPartitionText = 
              "a1.partition_number = a1.coord_partition_num and ";
  }

  # Query to extract the activity text from the monitor activity table.
  # Only extract DML
  #---------------------------------------------------------------------
  my $sqlToGetStmt = 
       "select a2.stmt_text, a1.time_created, a1.time_started, ".
              "a1.time_completed, a1.activity_id, a1.uow_id, a1.appl_id, ".
              "a1.activity_secondary_id, ".
              "a1.activity_type, a1.session_auth_id, a2.comp_env_desc ".
       "from $activity as a1, $activityStmt as a2 ".
       "where a1.activity_id = a2.activity_id and a1.uow_id = a2.uow_id and ".
              "a1.appl_id = a2.appl_id and ".
              "a1.activity_secondary_id = a2.activity_secondary_id and ".
              "$checkPartitionText".
              "partial_record = 0 and ".
              "appl_name != 'DB2HMON' and ".
              "(a1.activity_type = 'DML' or a1.activity_type = 'READ_DML' or ".
               "a1.activity_type = 'WRITE_DML') ".
        "$fromTimeText $toTimeText $workloadIdText $serviceClassText ".
        "$serviceSubClassText";

  my $sqlToRunExplain = qq(explain all set querytag = 'DB2WLMQUERY' for);
  my $sqlToSetComp = "set compilation environment = ?";
  my $sqlToRunExplainStmt = "";
  my ($cth, $tth);

  # Prepare and execute SQL to fetch the information from the monitor
  # tables
  #-----------------------------------------------------------------------
  $sth = PrepareExecuteSql($dbh, $sqlToGetStmt); 

  my $compEnvLength = 0;

  my $i = 0;
  # Fetch activities and for each:
  # - set the compilation env
  # - run explain
  # - extract info from explain tables
  # - insert info into wlmhist table
  # - remove info from explain tables for activity
  #-------------------------------------------------
  while (($stmtText, $timeCreated, $timeStarted, $timeCompleted, 
          $activityId, $uowId, $applicationId, $activitySecondaryId, 
          $activityType, $creator, 
          $compEnv) = $sth->fetchrow())
  {

    # Only try generating historical data for activities that
    # have a compilation environment
    #--------------------------------------------------------
    $compEnvLength = length($compEnv);
    if ($compEnvLength > 0)
    {

      # Set the compilation environment
      #---------------------------------
      $cth = $dbh->prepare($sqlToSetComp); 
      $cth->execute($compEnv);
      $cth->finish;
     
 
      # Set up SQL to run explain on activity statement
      #-------------------------------------------------
      $sqlToRunExplainStmt = "$sqlToRunExplain $stmtText";

      # Execute the explain statement
      #-------------------------------------------
      $tth = $dbh->do($sqlToRunExplainStmt) or
            print("\n Error running explain ".$DBI::errstr." for statement ".$stmtText."\n\n");

      if (defined $tth)
      {
        $numberProcessedSucc++;
      }
      
      # Call routine to extract the information from the explain tables
      # and insert it into the wlmhist table    
      #-----------------------------------------------------------------
      $rc = ExtractExplainInfo($activityId, $uowId, $applicationId, $activitySecondaryId, $activityType, $timeCreated, $timeStarted, $timeCompleted, $creator );

      # Call routine to remove the information just added from the 
      # explain tables
      #------------------------------------------------------------
      $rc = RemoveInfoFromExplainTables(0);

      # Increment counter and commit after every 10 activities. 
      #---------------------------------------------------------
      $i = $i + 1;
      $numberProcessed++;
      if ($i >= $numRequestsToProcess)
      {
        $dbh->commit();
        $i = 0;
        print "\n $numberProcessed activities processed....\n";
      }

    }
  }
  $sth->finish;
  $dbh->commit();
} #MainGenerate

#######################################################################
# Description : Extracts information from the explain tables and
#               inserts them into the wlmhist table
# Input       : Variables used to filter down what to extract from the
#               explain tables.  Filter consists of:
#               - activity_id
#               - uow_id
#               - application_id
#               - activity_secondary_id
#               - activity_type
#               - time_created
#               - time_completed
#               - creator
# Output      : Returns 0 on success, exits otherwise
#######################################################################
sub ExtractExplainInfo
{
  # Get input variables
  #--------------------
  my ( $activityId,
       $uowId,
       $applicationId,
       $activitySecondaryId,
       $activityType,
       $timeCreated,
       $timeStarted,
       $timeCompleted,
       $creator) = @_;

  # variables that will contain information extracted from the explain tables
  #--------------------------------------------------------------------------
  my ($exRequester, $exTime, $exSourceName, $exSourceSchema, $exSourceVersion, $exSourceType, $exObjectSchema, $exObjectName, $exStatementType, $exColumnNames);

  # Set up SQL to run extract information from the explain tables.  
  #----------------------------------------------------------------
  my $sqlToGetInfo = 
       "SELECT S2.explain_requester, S2.explain_time, S2.source_name, ".
              "S2.source_schema, S2.source_version, S2.source_type, ".
              "S2.object_schema, S2.object_name, S1.statement_type, ".
              "S2.column_names ".
       "FROM $schemaName.EXPLAIN_STATEMENT S1, $schemaName.EXPLAIN_STREAM S2 ".
       "WHERE S1.explain_requester = S2.explain_requester AND ".
             "S1.explain_time = S2.explain_time AND ".
             "S1.source_name = S2.source_name AND ".
             "S1.source_schema = S2.source_schema AND ".
             "S1.source_version = S2.source_version AND ".
             "S1.explain_level = S2.explain_level AND ".
             "S1.stmtno = S2.stmtno AND ".
             "S1.sectno = S2.sectno AND ".
             "S1.querytag = 'DB2WLMQUERY' order by S1.explain_time desc";

  # prepare and execute the SQL statement to fetch all the 
  # information from the explain tables.
  #----------------------------------------------------------
  my $eth = PrepareExecuteSql($dbh, $sqlToGetInfo); 
  my ($isIndex, $syscatTabName, $syscatTabSchema, $i, $numCols, @arr, $element,
      @arr2, $colName);
  my $numberOfColumns = 0;
  
  # SQL to insert information from explain tables into wlmhist table
  #------------------------------------------------------------------
  my $insertSql = 
      "insert into $schemaName.WLMHIST (".
         "ACTIVITY_ID, UOW_ID, APPL_ID, ACTIVITY_SECONDARY_ID, ACTIVITY_TYPE, ".
         "OBJECT_TYPE, ".
         "OBJECT_SCHEMA, OBJECT_NAME, TABLE_SCHEMA, TABLE_NAME, TIME_CREATED, ".
         "TIME_STARTED, TIME_COMPLETED, CREATOR) ".
      "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

  my $ith = $dbh->prepare($insertSql);

  my $rc;
  my $objectType = 'C';
  my $empty = '';

  # Loop around and fetch all the information from the explain tables
  # for this one particular activity.
  # - Massage the data
  #   - if the entry is an index, need to get the table schema and table
  #     from the syscat.indexes table.
  #   - If the entry is a column, some parsing must be done to get the 
  #     column information out
  # - Insert data into wlmhist table
  #-----------------------------------------------------------------------
  while (($exRequester, $exTime, $exSourceName, $exSourceSchema, 
          $exSourceVersion, $exSourceType, $exObjectSchema, $exObjectName, 
          $exStatementType, $exColumnNames) = 
          $eth->fetchrow())
  {
    # remove trailing blanks
    #--------------------------
    if (defined $exSourceSchema)
    {
      $exSourceSchema =~ s/\s+$//;
    }
    if (defined $exObjectSchema)
    {
      $exObjectSchema =~ s/\s+$//;
    }

    # Find out if the object is an index.  If it is, then message the data
    # and add it to the wlmhist table
    #----------------------------------------------------------------------
    if (defined $exObjectName)
    {
      ($isIndex, $syscatTabName, $syscatTabSchema) = 
         IsIndex($exObjectName, $exObjectSchema);

      if ($isIndex)
      {
        
        # remove trailing blanks
        #-------------------------
        $syscatTabSchema =~ s/\s+$//;
        $syscatTabName =~ s/\s+$//;
       
        # We know the object is an index so set the type
        #------------------------------------------------ 
        $objectType = 'I';

        # Based on information from the activity monitor tables and 
        # the explain tables, insert record into the wlmhist table
        #------------------------------------------------------------
        $rc = InsertRowToWLMHIST($activityId,
                                 $uowId,
                                 $applicationId,
                                 $activitySecondaryId,
                                 $activityType,
                                 $objectType,
                                 $exObjectSchema,
                                 $exObjectName,
                                 $syscatTabSchema,
                                 $syscatTabName,
                                 $timeCreated,
                                 $timeStarted,
                                 $timeCompleted,
                                 $creator);

        # Copy the Table name and schema into the proper variables
        # for the next insert if there are columns for this statement
        #-------------------------------------------------------------
        $exObjectSchema = $syscatTabSchema;
        $exObjectName = $syscatTabName;
      }

      # Now get the columns
      #---------------------
      $objectType = 'C';
      if (defined $exColumnNames)
      {
        # Parse through the excolumn_names which comes in the format 
        # something like q1.colname+q1.colname2.q1.RID.....
        #------------------------------------------------------------
        @arr = split('\+', $exColumnNames);
        $numCols = scalar @arr;
        for ($i = 0; $i < $numCols; $i++)
        {
          $element = $arr[$i];
        
          # Get rid of the qualifier (i.e. Q1.COLNAME..remove the Q1)
          #---------------------------------------------------------
          @arr2 = split('\.', $element);
          $colName = $arr2[1];
         
          # Get rid of any $RID$ that exists
          #----------------------------------
          if ( defined $colName and
               length($colName) > 0 and
               !($colName eq "\$RID\$"))
          {
          
            $numberOfColumns++;

            # Insert extracted information into the wlmhist table
            #----------------------------------------------------           
            $rc = InsertRowToWLMHIST($activityId,
                                     $uowId,
                                     $applicationId,
                                     $activitySecondaryId,
                                     $activityType,
                                     $objectType,
                                     $empty,
                                     $colName,
                                     $exObjectSchema,
                                     $exObjectName,
                                     $timeCreated,
                                     $timeStarted,
                                     $timeCompleted,
                                     $creator);

          }
        }
      }
      # If there were no columns, then just add an entry for the table
      # ---------------------------------------------------------------
      if ($numberOfColumns == 0)
      {
        # There were no columns so insert the table name into the wlmhist table
        #----------------------------------------------------------------------
        $rc = InsertRowToWLMHIST($activityId,
                                 $uowId,
                                 $applicationId,
                                 $activitySecondaryId,
                                 $activityType,
                                 $objectType,
                                 $empty,
                                 $empty,
                                 $exObjectSchema,
                                 $exObjectName,
                                 $timeCreated,
                                 $timeStarted,
                                 $timeCompleted,
                                 $creator);


      }
    }

  }
  $eth->finish;
  return 0;
} #ExtractExplainInfo

#######################################################################
# Description : Determines whether an entry is an index or not.   
# Input       : Object name, Object schema
# Output      : - value indicating whether it is an index or not   
#               - table name (if index)
#               - table schema (if index)
#######################################################################
sub IsIndex
{
  my @arg_l; # arg_l holds the values to be returned to calling function
  my ($exObjName,
      $exObjSchema) = @_;
  my $isIndex = 0;
  my ($tableName, $tableSchema);

  # Set up SQL to run extract table name and schema for index from
  # index table
  #-----------------------------------------------------------------
  my $sqlToCheckIndex = 
       "SELECT tabname, tabschema ".
        "from SYSCAT.INDEXES ".
        "where indname = '$exObjName' and indschema = '$exObjSchema'";

  # prepare and execute the SQL statement to find out if the index 
  # exists and if it does, to get the table name and table schema for
  # that index
  #-------------------------------------------------------------------
  my $ith = $dbh->prepare($sqlToCheckIndex);
  my $rc = $ith->execute();
  if (!defined $rc)
  {
    print("\n error ".$ith->err."\n");
  }
  # Fetch information from the syscat.indexes table
  #------------------------------------------------
  ($tableName, $tableSchema) = $ith->fetchrow();
  if (defined $tableName)
  {
    $isIndex = 1;
  }

  $arg_l[0] = $isIndex;
  $arg_l[1] = $tableName;
  $arg_l[2] = $tableSchema;
  $ith->finish;
  return @arg_l;
} #IsIndex

#######################################################################
# Description : Removes the information from the explain tables   
# Input       : docommit - indicates whether or not to perform
#                          a commit after removing the items from the
#                          explain tables
# Output      : RC will be 0 if it delete was successful   
#######################################################################
sub RemoveInfoFromExplainTables
{
  
  my $doCommit = $_[0];

  # Set up SQL to run extract all the information from the explain 
  # tables that have a query tag of DB2WLMQUERY
  #-----------------------------------------------------------------
  my $sqlToGetExpInfo = 
     "SELECT explain_requester, explain_time, source_name, source_schema, ".
            "source_version from $schemaName.explain_statement ".
      "where querytag = 'DB2WLMQUERY' order by explain_time";

  my ($exRequester, $exTime, $exSourceName, $exSourceSchema, 
      $exSourceVersion, $i);
  
  # Set up SQL to delete the information from the explain tables   
  # that we added in ( with query tag DB2WLMQUERY from above query)
  #-----------------------------------------------------------------
  my $sqlToDelExpInfo = 
       "DELETE from $schemaName.explain_instance ".
          "where explain_requester = ? and explain_time = ? and ".
                "source_name = ? and source_schema = ? and source_version = ?";
 
  my $dth = $dbh->prepare($sqlToDelExpInfo) or
          TransRollback($dbh);

  # prepare and execute the SQL statement to find all of the rows  
  # in the explain tables with the query tag of DB2WLMQUERY to remove 
  # from the explain tables
  #-------------------------------------------------------------------
  my $eth = $dbh->prepare($sqlToGetExpInfo) or
          TransRollback($dbh);

  my $rc = $eth->execute() or
          TransRollback($dbh);

  if (!defined $rc)
  {
    print("\n error ".$eth->err."\n");
  }

  # Loop around and find all the entries in the explain table that
  # we added in as a result of this historical generator.  
  #----------------------------------------------------------------
  $i = 0;
  while (($exRequester, $exTime, $exSourceName, $exSourceSchema, 
          $exSourceVersion) = 
          $eth->fetchrow())
  {
    # fill in all of the ? with the proper values for the delete
    #------------------------------------------------------------
    $dth->bind_param_inout(1, \$exRequester, 128) or die $dth->errstr;
    $dth->bind_param_inout(2, \$exTime, 128) or die $dth->errstr;
    $dth->bind_param_inout(3, \$exSourceName, 128) or die $dth->errstr;
    $dth->bind_param_inout(4, \$exSourceSchema, 128) or die $dth->errstr;
    $dth->bind_param_inout(5, \$exSourceVersion, 64) or die $dth->errstr;
        
    # Execute insert
    #----------------
    $rc = $dth->execute() or 
          TransRollback($dbh);
    if (!defined $rc)
    {
      print("\nrc not defined for insert errorstring ". $dth->err."\n");
    }

    # Increment counter and commit after every 10 activities only
    # if we are called to do a commit.  We are only doing it every
    # 10 activities to help improve the performance
    #-------------------------------------------------------------
    $i = $i + 1;
    if ($i > $numRequestsToProcess and $doCommit)
    {
      $dbh->commit();
      $i = 0;
    }

  }
  
  # do finial commit at end if we are told to commit
  #-------------------------------------------------
  if ($doCommit)
  {
    $dbh->commit() or TransRollback($dbh);
  }

  $dth->finish;
  return $rc;
} #RemoveInfoFromExplainTables

#######################################################################
# Description : Verifies that the table exists.  If it was an alias
#               it will get the real name of the table
# Input       : Table name, Table schema
# Output      : Table name, Table schema   
#######################################################################
sub CheckTable
{
  # Set up SQL to run extract all the information from the explain 
  # tables that have a query tag of DB2WLMQUERY
  #-----------------------------------------------------------------
  my @arg_l; # arg_l holds the values to be returned to the calling function
  my ($tabSchema,
      $tabName) = @_;

  my $objectType = ""; # will hold the result from the select to determine whether
                  # the table was a view, alias, or table

  my $sqlToGetTable = 
    "SELECT CASE TYPE ".
       "WHEN 'T' then 'TABLE' ".
       "WHEN 'V' then 'VIEW' ".
       "WHEN 'A' then 'ALIAS' ".
       "else 'SUMMARY' end ".
    "from SYSCAT.TABLES WHERE tabschema = ? and tabname = ?";
  
  my ($i, $rc, $found);

  # First check to determine whether we have seen this table or not
  #----------------------------------------------------------------
  my $numTables = scalar @tables;
  $found = 0;
  for ($i = 0; $i < $numTables; $i++)
  {
    
    if ($tables[$i] eq ($tabSchema.".".$tabName))
    {
      $found = 1;
      last;
    }
  }
   
  # The table was not found in the table array so we have to
  # do a query to make sure it exists in the syscat.systables table
  #-----------------------------------------------------------------
  if (!$found)
  {
    my $tth = $dbh->prepare($sqlToGetTable);
    $tth->bind_param_inout(1, \$tabSchema, 128);
    $tth->bind_param_inout(2, \$tabName, 128);
  
    my $rc = $tth->execute();
    if (!defined $rc)
    {
      print("\n error finding table".$tth->err."\n");
    }
    else
    {
      ($objectType) = $tth->fetchrow();
      $tth->finish;

      # If it was an alias, then we need to find the proper table
      # name from the systables table
      if (defined $objectType)
      {
        if ($objectType eq "ALIAS")
        {
          my $sqlToGetAliasTable = 
             "select base_tabschema, base_tabname ".
             "from syscat.tables ".
             "where tabschema = ? and tabname = ?";

          my $ath = $dbh->prepare($sqlToGetAliasTable);
          $ath->bind_param_inout(1, \$tabSchema, 128);
          $ath->bind_param_inout(2, \$tabName, 128);
          $rc = $ath->execute();
          if (!defined $rc)
          {
            print("\n error finding alias table".$ath->err."\n");
          }
          else
          {
            ($tabSchema, $tabName) = $ath->fetchrow();
            $found = 1;
          }
          $ath->finish;
 
        }
        else
        {
          # Add the table to the list of tables so we don't have to
          # query this table again from the tables
          #---------------------------------------------------------
          $tables[$numTables] = $tabSchema.".".$tabName;
          $found = 1;
        }
      }
    }
  }
  $arg_l[0] = $found;
  $arg_l[1] = $tabSchema;
  $arg_l[2] = $tabName;

  return @arg_l;
} #CheckTable

#######################################################################
# Description : Inserts a row to the WLMHIST table.
# Input       : Values for each column.  Consists of:
#               - activity id
#               - uow id
#               - application id
#               - activity secondary id
#               - activity type
#               - object type (i.e. column or index)
#               - object schema
#               - object name   
#               - table schema
#               - table name
#               - time created
#               - time started
#               - time completed
#               - user
# Output      : rc   
#######################################################################
sub InsertRowToWLMHIST
{
  my $rc;

  my ($activityId,
      $uowId,
      $applId,
      $activitySecondaryId,
      $actType,
      $objType,
      $objSchema,
      $objName,
      $tabSchema,
      $tabName,
      $timeCreated,
      $timeStarted,
      $timeCompleted,
      $thisUser) = @_;

  my $empty = '';

  # SQL to insert information from explain tables into wlmhist table
  #------------------------------------------------------------------
  my $insertsql = 
      "insert into $schemaName.WLMHIST ".
            "(ACTIVITY_ID, UOW_ID, APPL_ID, ACTIVITY_SECONDARY_ID, ".
             "ACTIVITY_TYPE, OBJECT_TYPE, ".
             "OBJECT_SCHEMA, OBJECT_NAME, TABLE_SCHEMA, TABLE_NAME, ".
             "TIME_CREATED, TIME_STARTED, TIME_COMPLETED, CREATOR) ".
      "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

  my $ith = $dbh->prepare($insertsql);

  # Check if table exists and also if the table was
  # an alias, then get the proper table name
  #--------------------------------------------------
  my @arr = CheckTable($tabSchema, $tabName);
  if ($arr[0])
  {
    $tabSchema = $arr[1];
    $tabName = $arr[2];

    # fill in all of the ? with the proper values for the insert
    #------------------------------------------------------------
    $ith->bind_param_inout(1, \$activityId, 8);
    $ith->bind_param_inout(2, \$uowId, 4);
    $ith->bind_param_inout(3, \$applId, 64);
    $ith->bind_param_inout(4, \$activitySecondaryId, 2);
    $ith->bind_param_inout(5, \$actType, 64);
    $ith->bind_param_inout(6, \$objType, 1);
    $ith->bind_param_inout(7, \$objSchema, 128);
    $ith->bind_param_inout(8, \$objName, 128);
    $ith->bind_param_inout(9, \$tabSchema, 128);
    $ith->bind_param_inout(10, \$tabName, 128);
    $ith->bind_param_inout(11, \$timeCreated, 128);
    $ith->bind_param_inout(12, \$timeStarted, 128);
    $ith->bind_param_inout(13, \$timeCompleted, 128);
    $ith->bind_param_inout(14, \$thisUser, 128);
      
    # Execute insert
    #----------------
    $rc = $ith->execute();
    if (!defined $rc)
    {
      print("\nrc not defined for insert of index errorstring ". 
            $ith->err."\n");
    }

  }
  $ith->finish;

  return $rc;
} #InsertRowToWLMHIST

