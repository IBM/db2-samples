########################################################################
#
#   Licensed Materials - Property of IBM
#
#   (C) Copyright IBM Corp. 2013. All Rights Reserved
#
#   US Government Users Restricted Rights - Use, duplication or disclosure
#   restricted by GSA ADP Schedule Contract with IBM Corp.
#
#   File Name = hadrCalculator.pl
#   Function  = Compute DB2 logging rate in various HADR sync modes.
#
#########################################################################

# On Unix, this program can be directly executed if it has "x" file permission.
# On Windows, execute via "perl" command.

# "eval" loads this script with no hardwired path to "perl".
# "eval" is first evaluated as shell command, which invokes "perl".
# Then it is ignored by perl because of "if 0".

eval 'exec perl -w -S $0 ${1+"$@"}'
   if 0;

use strict;
use Getopt::Long;

# Suppress sourcing of users' .kshrc files in invoked shells
delete $ENV{'ENV'};

# Set STDOUT and STDERR to unbuffered
select STDERR; $| = 1;
select STDOUT; $| = 1;

my($myName,$usage,$help,$verbose) = "";

($myName = $0) =~ s@.*[/\\]@@;
$usage = "Run $myName -help for usage.\n";

#-----------------------------------------------------------------------------
sub Usage()
{
   print <<EOF
+----------------------------------------------------------------------------+
|  IBM DB2 HADR Calculator V1.0                                              |
|  Licensed Material, Property of IBM.                                       |
|  Copyright IBM Corp. 2013. All Rights Reserved.                            |
+----------------------------------------------------------------------------+
Usage: $myName [options] <inputFile1> <inputFile2> ... <inputFileN>

HADR calculator annotates db2logscan output with theoretical HADR data rate.
When no input file is specified, stdin is read. Output is written to stdout.
Options are: (<s> indicates string. <n> indicates integer. <f> indicates float
number)

-syncmode <s>   Specify one or more HADR sync modes. Modes are
                SYNC, NEARSYNC, ASYNC, or SUPERASYNC (case insensitive).
                Multiple modes can be specified as comma delimited list.
                Default "SYNC,NEARSYNC,ASYNC".

-network <f1> <f2> Specify primary-standby network speed as <f1> MBytes/sec with
                   round trip time of <f2> second.

-disk <f1> <f2>    Specify disk write speed as <f1> MBytes/sec with overhead
                   of <f2> second per write.
EOF
}
#-----------------------------------------------------------------------------

my $modeString = "SYNC,NEARSYNC,ASYNC";
my @network;
my @disk;

if ($#ARGV < 0)
{
   &Usage();
   exit 0;
}

GetOptions (
   "syncmode=s"     => \$modeString,
   "network=f{2}"   => \@network,
   "disk=f{2}"      => \@disk,
   "verbose"        => \$verbose,
   "help"           => \$help

) or die $usage;

if ($help)
{
   &Usage();
   exit 0;
}

$modeString = uc($modeString);

my @modeList = split(/, */, $modeString);

my $networkRate = $network[0];
my $networkRRT  = $network[1];

my $diskRate    = $disk[0];
my $diskLatency = $disk[1];

if (! defined $networkRate || ! defined $diskRate)
{
   printf STDERR "$myName: Network and disk speed are required parameters\n";
   die $usage;
}

print "$myName: Network speed $networkRate MB/s, $networkRRT second round trip time\n";
print "$myName: Disk speed $diskRate MB/s, $diskLatency second overhead per write\n\n";

my $rcuFlushSize = 16; # RCU uses fixed 16 page log shipping size.
my $rcuFlushTime = 0;
my $rcuRate      = 0;

&getHadrRate("ASYNC", $rcuFlushSize, \$rcuFlushTime, \$rcuRate);

if ($#ARGV < 0)
{
   printf "$myName: Reading from stdin.\n";
}

my %maxExpFlushSize;
my %maxMaxFlushSize;

my $lineNum     = 0;
my $logRateLine = 0;

my @words;

my $emptyNote = "   ";
my $note      = $emptyNote;  # "?" notes.

while (<>)
{
   $lineNum++;

   #Distribution of log write rate (unit is MB/s):
   #Total 99 numbers, Sum 66.530, Min 0.004, Max 7.306, Avg 0.672

   $logRateLine = $lineNum if ($_ =~ "Distribution of log write rate");

   if ($logRateLine > 0 && $lineNum == $logRateLine + 1)
   {
      chomp($_);
      @words = split(/ +/, $_);
      my $avgLogRate = $words[$#words];  # Last field

      $note = $emptyNote;

      if    ($avgLogRate > $rcuRate       ) {$note = "???";}
      elsif ($avgLogRate > $rcuRate * .75 ) {$note = "?? ";}
      elsif ($avgLogRate > $rcuRate * .5  ) {$note = "?  ";}

      print $_;

      printf("\nAverage rate   $emptyNote %7.3f MB/s", $avgLogRate);

      printf("\nREMOTE CATCHUP $note ");
      &printRate($rcuFlushSize, $rcuFlushTime, $rcuRate);
      printf("\n");

      next;
   }

   if ($_ !~ /^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d +[\d\.]+ MB\/s/)
   {
      print $_;
      next;
   }

   chomp($_);

#2013-02-26 15:32:09  7.307 MB/s, 60 sec,  17.6 pg/f, 0.009435 sec/f,  15.9 pg/tr, 0.186589 sec/tr, 0.008580 sec/cmt, nOpenTrans  22.7
#0          1         2     3     4  5     6    7     8        9       10   11     12       13      14       15       16          17

   @words = split(/ +/, $_);

   my $actualRate   = $words[ 2];
   my $actFlushSize = $words[ 6];
   my $actFlushTime = $words[ 8];
   my $transSize    = $words[10];
   my $transTime    = $words[12];
   my $nOpenTrans   = $words[17];

   my $indent = "\n";

   print "\n$_";
   printf $indent;

   printf("%-10s %s ", "actual", $emptyNote);

   &printRate($actFlushSize, $actFlushTime, $actualRate);

   foreach my $syncmode (@modeList)
   {
      # We can at least achieve this rate using actual flush size.
      my $minFlushSize = $actFlushSize;
      my $minFlushTime = 0;
      my $minRate      = 0;

      $minFlushSize = $rcuFlushSize if ($syncmode eq "SUPERASYNC");

      &getHadrRate($syncmode, $minFlushSize, \$minFlushTime, \$minRate);

      # Max rate is achieved using max flush size.
      my $maxFlushSize = &max($minFlushSize, $transSize * $nOpenTrans);
      my $maxFlushTime = 0;
      my $maxRate      = 0;

      $maxFlushSize = $rcuFlushSize if ($syncmode eq "SUPERASYNC");

      &getHadrRate($syncmode, $maxFlushSize, \$maxFlushTime, \$maxRate);

      my $expFlushSize = 0;
      my $expFlushTime = 0;
      my $expRate      = 0;

      if ($actualRate <= $minRate)
      {
         $expFlushSize = $minFlushSize;
         $expFlushTime = $minFlushTime;
         $expRate      = $minRate;
      }
      elsif ($actualRate >= $maxRate)
      {
         $expFlushSize = $maxFlushSize;
         $expFlushTime = $maxFlushTime;
         $expRate      = $maxRate;
      }
      else
      {
         &getHadrFlushSize($syncmode,      $actualRate,
                           $minFlushSize,  $minFlushTime,  $minRate,
                           $maxFlushSize,  $maxFlushTime,  $maxRate,
                           \$expFlushSize, \$expFlushTime, \$expRate);
      }

      if (   !defined $maxExpFlushSize{$syncmode}
          || $maxExpFlushSize{$syncmode} < $expFlushSize)
      {
         $maxExpFlushSize{$syncmode} = $expFlushSize;
      }

      if (   !defined $maxMaxFlushSize{$syncmode}
          || $maxMaxFlushSize{$syncmode} < $maxFlushSize)
      {
         $maxMaxFlushSize{$syncmode} = $maxFlushSize;
      }

      $note = $emptyNote;

      if ($actualRate > $minRate)
      {
         if    ($actualRate > $maxRate / 2) {$note = "???";}
         elsif ($actualRate > $maxRate / 4) {$note = "?? ";}
         else                               {$note = "?  ";}
      }

      printf $indent;

      printf("%-10s %s ", $syncmode, $note);

      &printRate($expFlushSize, $expFlushTime, $expRate);

      printf(", min ");
      &printRate($minFlushSize, $minFlushTime, $minRate);

      printf(", max ");
      &printRate($maxFlushSize, $maxFlushTime, $maxRate);
   }

   printf "\n";
}

if ($logRateLine == 0)
{
   printf "\nREMOTE CATCHUP $emptyNote ";
   &printRate($rcuFlushSize, $rcuFlushTime, $rcuRate);
   printf "\n";
}

printf "\n";

foreach my $syncmode (@modeList)
{
   printf("%-10s ", $syncmode);

   printf("Max flush size: predicted %3d pages, workload max %3d pages\n",
      (defined $maxExpFlushSize{$syncmode}? $maxExpFlushSize{$syncmode} : 0),
      (defined $maxMaxFlushSize{$syncmode}? $maxMaxFlushSize{$syncmode} : 0));
}
#-----------------------------------------------------------------------------
# Prints rate at given flush size.
sub printRate()
{
   my $flushSize = $_[0];
   my $flushTime = $_[1];
   my $rate      = $_[2];

   printf("%7.3f MB/s@ %3d pg/f %.6f s/f", $rate, $flushSize, $flushTime);
}
#-----------------------------------------------------------------------------
sub min()
{
   return $_[0] < $_[1]? $_[0]: $_[1];
}
#-----------------------------------------------------------------------------
sub max()
{
   return $_[0] > $_[1]? $_[0]: $_[1];
}
#-----------------------------------------------------------------------------
# Compute logging rate for a given HADR syncmode and flushSize.
# Input:  syncmode flushSize flushTimeRef rateRef
# Output: $$flushTimeRef $$rateRef
# Return: void

sub getHadrRate()
{
   my $syncmode     = $_[0];
   my $flushSize    = $_[1];
   my $flushTimeRef = $_[2];
   my $rateRef      = $_[3];

   my $flushMB = $flushSize * 4096 / 1024 / 1024;

   my $writeTime = $diskLatency + $flushMB / $diskRate;
   my $sendTime  = $flushMB / $networkRate;

   my $flushTime = 0;

   if ($syncmode eq "SYNC")
   {
      $flushTime = $writeTime + $sendTime + $writeTime + $networkRRT;
   }
   elsif ($syncmode eq "NEARSYNC")
   {
      $flushTime = &max($writeTime, $sendTime + $networkRRT);
   }
   elsif ($syncmode eq "ASYNC" || $syncmode eq "SUPERASYNC")
   {
      $flushTime = &max($writeTime, $sendTime);
   }
   else
   {
      printf STDERR "\n$myName: ERROR: Unknown sync mode $syncmode\n";
      exit 1;
   }

   $$flushTimeRef = $flushTime;
   $$rateRef      = $flushMB / $flushTime;
}
#-----------------------------------------------------------------------------
# Compute flushSize for a given HADR syncmode and target rate
# Input:  syncmode targetRate
#         minFlushSize minFlushTime minRate
#         maxFlushSize maxFlushTime maxRate
#         flushSizeRef flushTimeRef rateRef
# Output: $$flushSize $$flushTimeRef $$rateRef
#         Output fields set to zero if target rate cannot be achieved.
# Return: void

sub getHadrFlushSize()
{
   my $syncmode     = $_[0];
   my $targetRate   = $_[1];

   my $minFlushSize = $_[2];
   my $minFlushTime = $_[3];
   my $minRate      = $_[4];

   my $maxFlushSize = $_[5];
   my $maxFlushTime = $_[6];
   my $maxRate      = $_[7];

   my $flushSizeRef = $_[8];
   my $flushTimeRef = $_[9];
   my $rateRef      = $_[10];

   if (  $maxFlushSize < $minFlushSize
      || $maxFlushSize < 0
      || $minFlushSize < 0)
   {
      printf("getHadrFlushSize(): Invalid argument.\n");
      return;
   }

   if ($targetRate < $minRate || $targetRate > $maxRate)
   {
      $$flushSizeRef = 0;
      $$flushTimeRef = 0;
      $$rateRef      = 0;

      return;
   }

   if ($maxFlushSize - $minFlushSize <= 1)
   {
      $$flushSizeRef = $maxFlushSize; # Round up to max
      $$flushTimeRef = $maxFlushTime;
      $$rateRef      = $maxRate;

      return;
   }

   # Binary search.

   my $midFlushSize = ($minFlushSize + $maxFlushSize) / 2;
   my $midFlushTime = 0;
   my $midRate      = 0;

   &getHadrRate($syncmode, $midFlushSize, \$midFlushTime, \$midRate);

   if ($targetRate > $midRate)
   {
      &getHadrFlushSize($syncmode,      $targetRate,
                        $midFlushSize,  $midFlushTime,  $midRate,
                        $maxFlushSize,  $maxFlushTime,  $maxRate,
                        $flushSizeRef,  $flushTimeRef,  $rateRef);
   }
   else
   {
      &getHadrFlushSize($syncmode,      $targetRate,
                        $minFlushSize,  $minFlushTime,  $minRate,
                        $midFlushSize,  $midFlushTime,  $midRate,
                        $flushSizeRef,  $flushTimeRef,  $rateRef);
   }
}
#-----------------------------------------------------------------------------
