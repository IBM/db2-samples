# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

package TJWH::TimeBits;
use Carp qw(cluck confess);
use File::stat;
use Scalar::Util qw(blessed);
use TJWH::Basic;
use Time::Local;
use Time::HiRes qw(gettimeofday);
use POSIX qw(floor);
my $useDateParse;
BEGIN
{
    $useDateParse = eval { require Date::Parse };
}
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw
    (
        findFailureTime
        getTimeFromString
        getTimeFromStringAssume
        getTimeFromEpoch
        getTimeFromEpochUTC
        getTimeNow
        subtractTimestampsPermissive
        subtractTimestamps
        epochToFormat
   );                           # symbols to be exported always

@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $timeMatch =
    [
     [qr/(\d{4})-(\d{2})-(\d{2})-(\d{2})\.(\d{2})\.(\d{2}\.\d{6})/,
      sub {
          # DB2 time format
          my ($filename, $year, $mon, $mday, $hour, $mm, $ss) = @_;
          return new TJWH::TimeBits($year, $mon, $mday, $hour, $mm, $ss);
      }],
     [qr/inode \d+ secs (\d+) nsecs (\d+) /,
      sub {
          # GPFS trace information
          my ($filename, $epoch, $nsecs) = @_;
          return getTimeFromEpoch($epoch, $nsecs/1000);
      }],
     [qr@(\d{2})/(\d{2})/(\d{4})\s+(\d{2}:\d{2}:\d{2} [AP]M)(\.\d{6})?@,
      sub {
          # GblRes output
          # 12/10/2009 02:39:21 PM.584802 T(4126747552) _GBD Stop command timed out for resource 0x6264 0x5f32
          # MM/DD/YYYY HH:mm:ss
          my ($filename, $month, $day, $year, $hms, $microsec) = @_;
          $microsec = 0 unless defined $microsec;
          if ($useDateParse)
          {
              my ($ss,$mm,$hh) = Date::Parse::strptime($hms);
              return new TJWH::TimeBits($year, $month, $day, $hh, $mm, $ss + $microsec);
          }
          else
          {
              warn "Could not parse $4: Perl module Date::Parse not found.\n";
          }
      }],
     [qr@(\d{2})/(\d{2})/(\d{2})\s+(\d{2}:\d{2}:\d{2} [AP]M)(\.\d{6})@,
      sub {
          # RecoveryRM output [00] 20/05/11 12:24:00 AM.647626 T(25217904)
          #  _RCD CHARMSubscriber::updateNodeMbrs() leavings^D
          #  (HA_GS_HOST_MEMBERSHIP_GROUP Group): s_count = 1 DD/MM/YY
          #  HH:mm:ss
          my ($filename, $day, $month, $year, $junk, $microsec) = @_;
          if ($useDateParse)
          {
              my ($ss,$mm,$hh) = Date::Parse::strptime($4);
              return new TJWH::TimeBits(2000 + $year, $month, $day, $hh, $mm, $ss + $microsec);
          }
          else
          {
              warn "Could not parse $4: Perl module Date::Parse not found.\n";
          }
      }],
     [qr@(\d{2})/(\d{2})/(\d{2})\s+(\d{2}:\d{2}:\d{2} [AP]M)@,
      sub {
          # iostat Linux timestamp
          # : 20/05/20 04:56:36 PM
          my ($filename, $day, $month, $year, $junk) = @_;
          if ($useDateParse)
          {
              my ($ss,$mm,$hh) = Date::Parse::strptime($junk);
              return new TJWH::TimeBits(2000 + $year, $month, $day, $hh, $mm, $ss);
          }
          else
          {
              warn "Could not parse $junk: Perl module Date::Parse not found.\n";
          }
      }],
     [qr@(\w{3}\s+\w{3}\s+\d+\s+\d{2}:\d{2}:\d{2})\s+(\w{3})\s(\d{4})@,
      sub {
          # GPFS logs and iostat timestamps
          # Wed Jul  3 17:32:36 IST 2013
          # Wed Feb 2 11:46:50 EST 2011 gpfsready: runact -c IBM.PeerDomain
          my ($filename, $string, $zone, $year) = @_;
          if ($useDateParse)
          {
              print "Reading $string:\n  ".
                  (join "\n - ", (Date::Parse::strptime($string)))."\n" if $debug;
              my ($ss,$mm,$hh,$day,$month) = Date::Parse::strptime($string);
              confess "month is not defined" unless defined $month;
              confess "day is not defined" unless defined $day;
              return new TJWH::TimeBits($year, $month + 1, $day, $hh, $mm, $ss);
          }
          else
          {
              warn "Could not parse $1: Perl module Date::Parse not found.\n";
          }
      }],
     [qr@(\w{3}\s+\w{3}\s+\d+\s+\d{2}:\d{2}:(\d{2}(\.\d+))\s(\d+))@,
      sub {
          # GPFS logs
          # Fri Mar 19 02:46:21.345 2010 GPFS: 6027-1710 Connecting to 10.0.1.21 pcoral8b-ib
          my ($filename, $string, $sec) = @_;
          if ($useDateParse)
          {
              my ($ss_junk,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime($string);
              confess "year is not defined" unless defined $year;
              confess "month is not defined" unless defined $month;
              confess "day is not defined" unless defined $day;
              return new TJWH::TimeBits(1900 + $year, $month + 1, $day, $hh, $mm, $sec);
          }
          else
          {
              warn "Could not parse $1: Perl module Date::Parse not found.\n";
          }
      }],
     [qr@(\d{2})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2}):(\d{2}\.?\d*)@,
      sub {
          # From jstrace files
          # [01] 03/09/10 17:10:44.866133 T(2349) _CFD PeerDomainRcp::updateCritRsrcProtection Entered.
          # DD/MM/YY hh:mm:ss.nnnnnn
          my ($filename, $month, $day, $year, $hour, $min, $sec) = @_;
          return new TJWH::TimeBits(2000 + $3, $1, $2, $4, $5, $6);
      }],
     [qr@^(\w{3}\s+\d+\s\d+:\d+:\d+)\s@,
      sub {
          # Linux syslog
          # Jul  6 12:04:05 coralm211 in.rshd[3230]: connect from 9.26.92.199 (9.26.92.199)
          # Jul  6 12:04:05 coralm211 rshd[3230]: pam_rhosts_auth(rsh:auth): allowed to dtw@coralm211.torolab.ibm.com as dtw
          # Here we have to GUESS the year.
          if ($useDateParse)
          {
              my ($filename, $string) = @_;
              my ($ss,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime($string);
              if (defined $filename and -f $filename)
              {
                  my $time = new TJWH::TimeBits(1900, $month + 1, $day, $hh, $mm, $ss);
                  $time->yearFromMtime($filename);
                  return $time;
              }
              else
              {
                  # Otherwise assume it was done recently
                  my ($j1, $j2, $j3, $j4, $j5, $year) = localtime();
                  return new TJWH::TimeBits($year + 1900, $month + 1, $day, $hh, $mm, $ss);
              }
          }
          else
          {
              warn "Could not parse $1: Perl module Date::Parse not found.\n";
          }
      }],
     [qr@(\d{2})/(\d{2})\s+(\d{2}):(\d{2}):(\d{2}\.?\d*)@,
      sub {
          # From nims output
          # 03/25 17:10:06.080: nmPrintStats: en0:  rx:27069045 fr:135886 er:0 intr:131347 bcast:0 mcast:0
          # MM/DD hh:mm:ss.nnn
          # Here we have to GUESS the year.
          # If we have the file and it is valid, use the mtime
          my ($filename, $month, $day, $hour, $min, $sec) = @_;
          if (defined $filename and -f $filename)
          {
              my $time = new TJWH::TimeBits(1900, $month, $day, $hour, $min, $sec);
              $time->yearFromMtime($filename);
              return $time;
          }
          else
          {
              # Otherwise assume it was done recently
              my ($j1, $j2, $j3, $j4, $j5, $year) = localtime();
              return new TJWH::TimeBits($year + 1900, $month, $day, $hour, $min, $sec);
          }
      }],
     [qr@(\w{3} \d{2}\s+\d{2}:\d{2}:\d{2}\.?\d*)\s+(\d{4})?@,
      sub {
          # From cthags output
          # Nov 21 20:18:28 TRACE_FYI : /usr/sbin/rsct/bin/cthagsglsmp 9 0  input arguments:
          # Mon DD hh:mm:ss
          # or
          # on Tue Jul 26 10:48:57 1998
          if ($useDateParse)
          {
              my ($filename, $string, $maybeYear) = @_;
              my ($ss,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime($string);
              if (defined $maybeYear)
              {
                  my $time = new TJWH::TimeBits($maybeYear, $month + 1, $day, $hh, $mm, $ss);
                  return $time;
              } else {
                  # Here we have to GUESS the year
                  # If we have the file and it is valid, use the mtime
                  if (defined $filename and -f $filename)
                  {
                      my $time = new TJWH::TimeBits(1900, $month + 1, $day, $hh, $mm, $ss);
                      $time->yearFromMtime($filename);
                      return $time;
                  }
                  else
                  {
                      # Otherwise assume it was done recently
                      my ($j1, $j2, $j3, $j4, $j5, $year) = localtime();
                      return new TJWH::TimeBits($year + 1900, $month + 1, $day, $hh, $mm, $ss);
                  }
              }
          }
          else
          {
              warn "Could not parse $1: Perl module Date::Parse not found.\n";
          }
      }],
     [qr/(\d{4})-(\d{2})-(\d{2})[@ _](\d{2}):(\d{2}):(\d{2}\.?\d*)/,
      sub {
          # From the MCR utils
          # time_killed:2010-05-04 15:10:48.607
          # or from the cluster output
          # ==> 2010-07-15_09:58:49.170818 on pcoral1-ib.svl.ibm.com
          # or from the GPFS fsmgr output (can also have @ between date and time)
          # 2011-02-09 13:11:48 |    1.123     1|   0.102|   0.000|   1.001     1     1|    0.016    1|
          my ($filename, $year, $mon, $mday, $hour, $mm, $ss) = @_;
          return new TJWH::TimeBits($year, $mon, $mday,
                                    $hour, $mm, $ss);
      }],
     [qr/(\d{4})-(\w{3})-(\d{2})-(\d{2})[.](\d{2})[.](\d{2}\.\d+)/,
      sub {
          # From the older epochToLocalTime output as printed by hirestime/hiresdate
          # 2010-May-14-05.46.42.067297 :: Software failure for DB2 member
          my ($filename, $year, $monstr, $mday, $hour, $mm, $ss) = @_;
          my ($mon) = grep { $abbr[$_] eq $monstr } 0 .. $#abbr;
          if (not defined $mon)
          {
              confess "WARNING: Unknown month string monstr\n";
          }
          else
          {
              return new TJWH::TimeBits($year, $mon + 1, $mday,
                                        $hour, $mm, $ss);
          }
      }],
     [qr@([a-zA-Z]{3})\s+(\d+),\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s+([AP]M)@,
      sub {
          # Java logger output
          # Sep 28, 2011 10:06:05 PM com.ibm.db2.perf.sdtw.query execute
          my ($filename, $monstr, $mday, $year, $hour, $mm, $ss, $pm) = @_;
          my ($mon) = grep { $abbr[$_] eq $monstr } 0 .. $#abbr;
          if (not defined $mon)
          {
              confess "WARNING: Unknown month string $monstr\n";
          }
          else
          {
              my $time = new TJWH::TimeBits($year, $mon + 1, $mday,
                                            $hour, $mm, $ss);
              if ($pm eq 'AM')
              {
                  # do nothing
              }
              elsif ($pm eq 'PM')
              {
                  # We need to add twelve hours
                  $time->addSeconds(12 * 60 * 60);
              }
              return $time;
          }
      }],
     [qr@(\d+)-([a-zA-Z]{3})-(\d{4})\s+(\d{1,2}):(\d{2})(:\d{2})?\s+([AP]M)@,
      sub {
          # 2-Jan-2019 11:47 AM - from ServRTC
          my ($filename, $mday, $monstr, $year, $hour, $mm, $ss, $pm) = @_;
          my ($mon) = grep { $abbr[$_] eq $monstr } 0 .. $#abbr;
          $ss = 0 unless defined $ss;
          if (not defined $mon)
          {
              confess "WARNING: Unknown month string $monstr\n";
          }
          else
          {
              my $time = new TJWH::TimeBits($year, $mon + 1, $mday,
                                            $hour, $mm, $ss);
              if ($pm eq 'AM')
              {
                  # do nothing
              }
              elsif ($pm eq 'PM')
              {
                  # We need to add twelve hours
                  $time->addSeconds(12 * 60 * 60);
              }
              return $time;
          }
      }],
     [qr#(\d{2})/(\d{2})/(\d{4}) (\d{1,2})[:](\d{2})\s([AP]M)#,
      sub {
          # "01/07/2020 6:11 AM" - day/month/year
          my ($filename, $day, $mon, $year, $hour, $mm, $pm) = @_;
          my $time = new TJWH::TimeBits($year, $mon, $day,
                                        $hour, $mm, 0);
          if ($pm eq 'AM')
          {
              # do nothing
          }
          elsif ($pm eq 'PM')
          {
              # We need to add twelve hours
              $time->addSeconds(12 * 60 * 60);
          }
          return $time;
      }],
     [qr#(LOAD|BUILD).*(\d{2})/(\d{2})/(\d{4}) (\d{2})[:.](\d{2})[:.](\d{2}\.\d{6})#,
      sub {
          # Completed LOAD phase at 03/18/2017 15:21:45.957686
          my ($filename, $phase, $mon, $day, $year, $hour, $mm, $ss) = @_;
          return new TJWH::TimeBits($year, $mon, $day,
                                    $hour, $mm, $ss);
      }],
     [qr@(\d{2})/(\d{2})/(\d{4}) (\d{2})[:.](\d{2})[:.](\d{2}\.\d{6})@,
      sub {
          # BEGIN rocmDB2Cleanup 06/24/2010 15:43:47.684560
          my ($filename, $mon, $day, $year, $hour, $mm, $ss) = @_;
          return new TJWH::TimeBits($year, $mon, $day,
                                    $hour, $mm, $ss);
      }],
     [qr@\s*(\d{10})[.:](\d{6})\D@,
      sub {
          # Epoch time to microseconds accuracy (gettimeofday). Also CAPD uses
          # an epoch seconds:microseconds format so we throw that in here as
          # well.
          my ($filename, $epoch, $microseconds) = @_;
          my ($ss,$mm,$hh,$day,$month,$year) = localtime($epoch);
          return new TJWH::TimeBits(1900 + $year, $month + 1, $day,
                                    $hh, $mm, $ss + $microseconds/1000000);
      }],
     [qr@\s*(\d{10})[.:](\d{9})\D@,
      sub {
          # Epoch time to nanoseconds accuracy - e.g. GPFS finishTime trace
          my ($filename, $epoch, $nanoseconds) = @_;
          my ($ss,$mm,$hh,$day,$month,$year) = localtime($epoch);
          return new TJWH::TimeBits(1900 + $year, $month + 1, $day,
                                    $hh, $mm, $ss + $nanoseconds/1000000000);
      }],
     [qr@(^|[_ -])(\d{4})[-]?(\d{2})[-]?(\d{2})-(\d{2})\.(\d{2})\.(\d{2})(\.\d+)?\s*@,
      sub {
          # dateComment output
          # == 1279033686 20100713-08.08.06 Issuing kill -9 2740650 2138940 on pcoral5-ib.svl.ibm.com ==
          # Some scripts
          # runDTW-crazy-reboot-4members-70ratio-150clients-21600secs-10int-dpsdbcb+cf20160909-20160909-13.52.51/
          my ($filename, $junk, $year, $mon, $mday, $hour, $mm, $ss, $fract) = @_;
          $ss += $fract if defined $fract;
          return new TJWH::TimeBits($year, $mon, $mday, $hour, $mm, $ss);
      }],
     [qr@(\d{2})/(\d{2})/(\d{4}) (\d{2})[:.](\d{2})[:.](\d{2})@,
      sub {
          # DB2 start/stop formats
          # 10/13/2010 12:05:34     0   0   SQL1026N  The database manager is already active.
          # 10/13/2010 12:05:34     1   0   SQL1026N  The database manager is already active.
          # 10/13/2010 12:05:34     3   0   SQL1026N  The database manager is already active.
          # 10/13/2010 12:05:34     2   0   SQL1026N  The database manager is already active.
          my ($filename, $mon, $mday, $year, $hour, $mm, $ss) = @_;
          return new TJWH::TimeBits($year, $mon, $mday, $hour, $mm, $ss);
      }],
     [qr/^\w+=(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})=/,
      sub {
          # Bldinfo update lines
          # viewname=20110117131334=db2_v98fp4_defects_aix64_s110116
          # build_site=20110117131348=toro
          # status=20110117131400=constructed
          my ($filename, $year, $mon, $mday, $hour, $mm, $ss) = @_;
          return new TJWH::TimeBits($year, $mon, $mday, $hour, $mm, $ss);
      }],
    ];

sub new
{
    my ($class,
        $year,
        $month,
        $day,
        $hour,
        $minute,
        $second,
        $fraction) = @_;

    my $this = {
                year     => 0,
                month    => 0,
                day      => 0,
                hour     => 0,
                minute   => 0,
                second   => 0,
                epoch    => undef,
                utc      => undef,
                original => undef,
               };

    bless $this, $class;

    # Check that we aren't dealing with a zero'd input
    if (defined $year   and $year   == 0 and
        defined $month  and $month  == 0 and
        defined $day    and $day    == 0 and
        defined $hour   and $hour   == 0 and
        defined $minute and $minute == 0 and
        defined $second and $second == 0
       )
    {
        # We do this to distinguish between initializing TimeBits with an
        # invalid time and the uninitialized state
        return;
    }
    else
    {
        # Call the private methods for each piece of time
        $this->year($year) if defined $year;
        $this->month($month) if defined $month;
        $this->day($day) if defined $day;
        $this->hour($hour) if defined $hour;
        $this->minute($minute) if defined $minute;
        if (defined $fraction)
        {
            $this->second($second + $fraction) if defined $second;
        }
        else
        {
            $this->second($second) if defined $second;
        }

        return $this;
    }
}

sub copy
{
    my ($this, $other) = @_;
    confess "this is not defined" unless defined $this;
    confess "other is not defined" unless defined $other;
    $other->verifyEpoch if $debug;

    $this->year     ($other->year);
    $this->month    ($other->month);
    $this->day      ($other->day);
    $this->hour     ($other->hour);
    $this->minute   ($other->minute);
    $this->second   ($other->second);
    $this->original ($other->original);
    if ($other->utc)
    {
        $this->utc($other->utc);
    }
    else
    {
        $this->{utc} = undef;
    }
    if ($other->epoch)
    {
        $this->{epoch} = $other->epoch;
    }
    else
    {
        $this->{epoch} = undef;
    }
    if ($debug)
    {
        eval { $this->verifyEpoch; };
        if ($@)
        {
            confess "$@\nCompare this:\n".(Data::Dumper::Dumper $this);
        }
    }
    return $this;
}

# This routine gives a new TJWH::TimeBits object based on arbitrary strings.
sub getTimeFromString
{
    # Filename is optional. It is only needed when the year can't be
    # determined from the date string. In these scenarios, the ctime for the
    # file will be used to determine the year.
    my ($line, $filename) = @_;
    return unless defined $line;

    # All times have at LEAST three two-digit numbers
    return unless $line =~ m/\d{2}.*\d{2}.*\d{2}/;

    my $time;
    my $index;
    for ($index = 0; $index < scalar @{ $timeMatch }; $index++)
    {
        if ($line =~ $timeMatch->[$index]->[0])
        {
            eval {
                $time = &{$timeMatch->[$index]->[1]}($filename,
                                                     $1, $2, $3, $4, $5,
                                                     $6, $7, $8, $9, $10);
            };
            if ($@)
            {
                cluck "$filename: $line failed to correctly determine time using test $index: $timeMatch->[$index]->[0]\n$@\n";
                $time = undef;
            }
        }
        last if defined $time;
    }

    # Speed tweak - most of the time, we only have a few time stamp formats in
    # a file - keep the ones we've seen near the start
    if (defined $time)
    {
        warn "Moving matcher at position $index to top\n" if $debug;
        unshift @{ $timeMatch }, splice @{ $timeMatch }, $index, 1;
    }

    # Record the line we were given if we recognised it
    $time->original($line) if $time;

    # If we didn't recognise the time in the line, we'll be returning undef here
    return $time;
}

# This routine deals with the scenarios where only the time of day is
# recorded. Base is updated on every call - any time that the apparent time
# goes backwards will be treated as having wrapped by one day.
sub getTimeFromStringAssume
{
    my ($line, $base) = @_;
    return unless defined $line;
    confess "base is not defined" unless defined $base;
    confess "base is not a TJWH::TimeBits" unless blessed $base and $base->isa('TJWH::TimeBits');

    if ($line =~ m/(\d{2}):(\d{2}):(\d{2}\.*\d*)( [AP]M)?/)
    {
        my $tb;
        unless (defined $4 and $4 eq ' PM')
        {
            $tb = new TJWH::TimeBits($base->year, $base->month, $base->day, $1, $2, $3 );
        }
        else
        {
            $tb = new TJWH::TimeBits($base->year, $base->month, $base->day, $1, $2 + 12, $3 );
        }
        if ($debug)
        {
            $base->verifyEpoch;
            print "Base time        : ".$base->formatTime." epoch: ".$base->epoch."\n";
            print "Intermediate time: ".$tb->formatTime." epoch: ".$tb->epoch."\n";
        }

        # If the result is before the base time, add one day to base and fix
        # up the result
        if ($tb->isBefore($base))
        {
            $base->addSeconds(60 * 60 * 24);
            $tb->year ($base->year);
            $tb->month($base->month);
            $tb->day  ($base->day);
            $tb->{epoch} = undef;
        }
        $base->copy($tb);

        print "Assumed time:".$tb->formatTime."\n" if $debug;
        return $tb;
    }

    return;
}

sub getTimeFromEpoch
{
    my ($epoch, $microseconds) = @_;
    confess "Epoch must be either an integer or a float: got $epoch\n"
        unless $epoch =~ m/\d+\.?\d*/;
    confess "Microseconds must be either an integer or a float: got $microseconds\n"
        if defined $microseconds and $microseconds !~ m/^\d+\.?\d*$/;

    $microseconds = 0 unless defined $microseconds;

    my $fraction = 0;
    if ($epoch =~ m/^\d+\.(\d+)/)
    {
        my $int = floor($epoch);
        $fraction = $epoch - $int;
    }

    my ($ss,$mm,$hh,$day,$month,$year) = localtime($epoch);
    my $time = new TJWH::TimeBits(1900 + $year, $month + 1, $day,
                                  $hh, $mm, $ss + $fraction + $microseconds/1000000);

    return $time;
}

sub getTimeFromEpochUTC
{
    my ($epoch, $microseconds) = @_;
    confess "Epoch must be either an integer or a float: got $epoch\n"
        unless $epoch =~ m/\d+\.?\d*/;
    confess "Microseconds must be either an integer or a float: got $microseconds\n"
        if defined $microseconds and $microseconds !~ m/^\d+\.?\d*$/;
    $microseconds = 0 unless defined $microseconds;

    my ($ss,$mm,$hh,$day,$month,$year) = gmtime($epoch);
    my $time = new TJWH::TimeBits(1900 + $year, $month + 1, $day,
                                  $hh, $mm, $ss + $microseconds/1000000);

    return $time;
}

sub getTimeNow
{
    my ($epoch, $microseconds) = gettimeofday;
    return getTimeFromEpoch($epoch, $microseconds);
}

sub findFailureTime
{
    my ($directory) = @_;
    confess "Directory must be defined\n" unless defined $directory;
    confess "$directory is not a directory\n" unless -d $directory;

    my $failureTime;
    my @interleavedFiles = glob "$directory/interleaved-timings.txt*";
    if (scalar @interleavedFiles)
    {
        cluck "Too many interleaved files: ".(scalar @interleavedFiles)."\n" unless scalar @interleavedFiles == 1;
        my $file = shift @interleavedFiles;
        print "Opening $file\n" if $verbose;
        my $fh = TJWH::Basic::openFile($file);
        confess "Failed to open $file\n" unless defined $fh;
        while (my $line = <$fh>)
        {
            chomp $line;
            if ($line =~ m/(failure|kill) time/)
            {
                $failureTime = getTimeFromString($line);
                print "Determining throughput prior to ".
                    ($failureTime->formatTime)."\n" if $verbose;
                last if defined $failureTime;
            }
        }
        close $fh;
    }
    else
    {
        print "No timing information is available for $directory\n";
    }

    return $failureTime;
}

# When the year is set to zero, this allows a filename to be examined to set
# the year
sub yearFromMtime
{
    my ($this, $filename) = @_;

    my $s = stat $filename or return undef;
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime($s->mtime);
    $this->year(1900 + $year);

    return $this;
}

sub year {
    my ($this, $year) = @_;

    if (defined $year)
    {
        cluck "Unexpected year $year\n".Data::Dumper::Dumper $this if $year < -1000 or $year > 3000;
        $this->{year} = $year;
    }

    return $this->{year};
}

sub month {
    my ($this, $month) = @_;

    if (defined $month)
    {
        confess "Bad month number $month\n" unless $month > 0 and $month <= 12;
        $this->{month} = $month;
    }

    return $this->{month};
}

sub day {
    my ($this, $day) = @_;

    if (defined $day)
    {
        confess "Bad day number $day\n" unless $day > 0 and $day <= 31;
        $this->{day} = $day;
    }

    return $this->{day};
}

sub hour {
    my ($this, $hour) = @_;

    if (defined $hour)
    {
        confess "Bad hour number $hour\n" unless $hour >= 0 and $hour < 24;
        $this->{hour} = $hour;
    }

    return $this->{hour};
}

sub minute {
    my ($this, $minute) = @_;

    if (defined $minute)
    {
        confess "Bad minute number $minute\n" unless $minute >= 0 and $minute < 60;
        $this->{minute} = $minute;
    }

    return $this->{minute};
}

sub second {
    my ($this, $second) = @_;

    if (defined $second)
    {
        confess "Bad second number $second\n" unless $second >= 0 and $second < 60;
        $this->{second} = $second;
    }

    return $this->{second};
}

sub original {
    my ($this, $original) = @_;

    if (defined $original)
    {
        $this->{original} = $original;
    }

    return $this->{original};
}

# Times are assumed to be in local time. If this time stamp is in UTC, then
# set this.
sub utc {
    my ($this, $utc) = @_;
    confess "this is not defined\n" unless defined $this;

    if (defined $utc)
    {
        $this->{utc} = $utc;
    }

    return $this->{utc};
}

# For scenarios with incomplete timestamps (like HH:MM::SS) we need a safe
# method to establish the current day. This is the Midnight Lock - every time
# we find a time that is earlier than the base time, we enable the midnight
# lock to avoid incrementing the base time until we are past it again.
sub midLock {
    my ($this, $midLock) = @_;

    if (defined $midLock)
    {
        $this->{midLock} = $midLock;
    }

    return $this->{midLock};
}


# Print out the time, optionally specifying a format
# The default output is consistent with the db2diag.log entries
sub formatTime
{
    my ($this, $format) = @_;
    confess "this is not defined\n" unless defined $this;
    $format = "%04d-%02d-%02d-%02d.%02d.%09.6f" unless defined $format;

    return sprintf $format,
        $this->{year},
            $this->{month},
                $this->{day},
                    $this->{hour},
                        $this->{minute},
                            $this->{second};
}

# Print out the time.
# This is a shorter form with no subsecond information.
sub formatTimeShort
{
    my ($this) = @_;
    confess "this is not defined\n" unless defined $this;

    return $this->formatTime('%04d%02d%02d-%02d.%02d.%02d');
}

sub formatDate
{
    my ($this, $format) = @_;
    confess "this is not defined\n" unless defined $this;
    $format = "%04d-%02d-%02d" unless defined $format;

    return sprintf $format,
        $this->{year},
            $this->{month},
                $this->{day};
}

# Return true if this is before other
sub isBefore
{
    my ($this, $other) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "other is not defined\n" unless defined $other;
    # If this is not set
    if ($this->{month} == 0)
    {
        return 1;
    }
    # Or other is not set
    elsif ($other->{month} == 0)
    {
        return 0;
    }

    return 1 if $this->epoch < $other->epoch;
    return 0;
}

# Return true if this is after other
sub isAfter
{
    my ($this, $other) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "other is not defined\n" unless defined $other;
    # If this is not set
    if ($this->{month} == 0)
    {
        return 0;
    }
    # Or other is not set
    elsif ($other->{month} == 0)
    {
        return 1;
    }

    return 1 if $this->epoch > $other->epoch;
    return 0;
}

# Return true if this is before or equal to other
sub isBeforeEq
{
    my ($this, $other) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "other is not defined\n" unless defined $other;

    # If this is not set
    if ($this->{month} == 0)
    {
        return 1;
    }
    # Or other is not set
    elsif ($other->{month} == 0)
    {
        if ($this->{month} == 0)
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }

    return 1 if $this->epoch <= $other->epoch;
    return 0;
}

# Return true if this is after or equal to other
sub isAfterEq
{
    my ($this, $other) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "other is not defined\n" unless defined $other;
    # If this is not set
    if ($this->{month} == 0)
    {
        if ($other->{month} == 0)
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    # Or other is not set
    elsif ($other->{month} == 0)
    {
        return 1;
    }

    return 1 if $this->epoch >= $other->epoch;
    return 0;
}

sub isSet
{
    my ($this) = @_;
    return 1 if $this->{month} > 0;
    return 0;
}

# If the time format was in local time, then get the epoch based on
# localtime. If we have been told that it is UTC, use timegm
sub epoch
{
    my ($this) = @_;
    confess "this is not defined\n" unless defined $this;
    # If we haven't seen a real date, all the time bits are zero. Throw
    # undefined back to the user.
    return undef if $this->{month} == 0 or $this->{day} == 0;
    unless ($this->{epoch})
    {
        # Note that timegm() and timelocal() assume that four digit years are
        # actually the correct year and not 1900 years in the future (i.e. 2010
        # really is 2010 and not 3910). Ergo, don't subtract 1900 from the year.
        if ($this->utc)
        {
            eval {
                $this->{epoch} = timegm(int($this->second),
                                        $this->minute,
                                        $this->hour,
                                        $this->day,
                                        $this->month - 1,
                                        $this->year);
            };
            if ($@)
            {
                confess "Failed to get UTC epoch: $@\n".
                    (Data::Dumper::Dumper $this);
            }

        }
        else
        {
            eval {
                $this->{epoch} = timelocal(int($this->second),
                                           $this->minute,
                                           $this->hour,
                                           $this->day,
                                           $this->month - 1,
                                           $this->year);
            };
            if ($@)
            {
                if ($@ =~ m/Day too big/)
                {
                    cluck "Warning: Year larger than Y2038 and 32bit localtime: $@\n"
                }
                else
                {
                    confess "Failed to get localtime epoch: $@\n".
                        (Data::Dumper::Dumper $this);
                }
            }
        }

        # Neither timegm or timelocal will cope with seconds=59.87, for
        # example. That's why we int() the seconds above, and repair the damage
        # here.
        my $int = int $this->second;
        $this->{epoch} += ($this->second - $int);
    }
    return $this->{epoch};
}

sub verifyEpoch
{
    my ($this) = @_;
    my $currentEpoch = $this->{epoch};
    if ($currentEpoch)
    {
        $this->{epoch} = undef;
        my $newEpoch = $this->epoch;
        if ($newEpoch != $currentEpoch)
        {
            confess "Original epoch $currentEpoch does not match calculated epoch $newEpoch\n".
            Data::Dumper::Dumper $this;
        }
    }
    return;
}

sub addSeconds
{
    my ($this, $seconds) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "seconds must be defined\n" unless defined $seconds;
    confess "Seconds $seconds is not a valid number\n"
        unless $seconds =~ m/^[-+]?\d+(\.\d+)?(e[-+]\d+)?$/;

    $this->verifyEpoch if $debug;

    # All manipulation is done to the epoch seconds.
    $this->epoch unless defined $this->{epoch};
    $this->{epoch} += $seconds;
    my $epoch = $this->{epoch};
    print "New epoch: $epoch\n" if $debug;

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime($epoch);
    $this->{utc} = undef;
    $this->second($sec + $epoch - int $epoch);
    $this->minute($min);
    $this->hour($hour);
    $this->day($mday);
    $this->month($mon + 1);
    $this->year($year + 1900);

    $this->verifyEpoch if $debug;
    return $this;
}

# We provide this for convenience
sub subtractSeconds
{
    my ($this, $seconds) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "seconds must be defined\n" unless defined $seconds;
    confess "Seconds $seconds is not a valid number\n"
        unless $seconds =~ m/^[-+]?\d+(\.\d+)?(e[-+]\d+)?$/;

    return $this->addSeconds(-1 * $seconds);
}

# Find out the number of seconds in $this - $other.
sub subtract
{
    my ($this, $other) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "other is not defined\n" unless defined $other;
    confess "this epoch is not defined\n" unless defined $this->epoch;
    confess "other epoch is not defined\n" unless defined $other->epoch;

    die "\$this must be a TJWH::TimeBits type - actually is ".(ref $this)."\n" unless ref $this eq "TJWH::TimeBits";
    die "\$other must be a TJWH::TimeBits type - actually is ".(ref $other)."\n" unless ref $other eq "TJWH::TimeBits";

    return $this->epoch - $other->epoch;
}

# Subtract two timestamps, possibly in different formats, returning the number
# of seconds between the times. The sense of the subtraction is first -
# second.

# Bad inputs are silently swallowed and the result is undef for these scenarios.
sub subtractTimestampsPermissive
{
    my ($first, $second) = @_;
    return unless defined $first and defined $second;
    my ($ftb, $stb);
    eval { $ftb = getTimeFromString($first) };
    return unless $ftb;
    eval { $stb = getTimeFromString($second) };
    return unless $stb;

    return $ftb->subtract($stb);
}

# One or the other strings being empty gives 0 seconds
sub subtractTimestamps
{
    my ($first, $second) = @_;
    return unless defined $first and defined $second;
    my ($ftb, $stb);
    eval { $ftb = getTimeFromString($first) };
    eval { $stb = getTimeFromString($second) };
    return undef unless defined $ftb or defined $stb;
    if ((defined $ftb and not defined $stb) or
        (defined $stb and not defined $ftb))
    {
        return 0;
    }

    return $ftb->subtract($stb);
}

# Convert epoch times (including fractions) to DB2 format.
sub epochToFormat
{
    my ($epoch) = @_;
    my $seconds = int $epoch;
    my $fraction = ($epoch - $seconds);
    my ($ss,$mm,$hh,$day,$month,$year) = localtime($seconds);
    my $tb = new TJWH::TimeBits(1900 + $year, $month + 1, $day,
                                $hh, $mm, $ss + $fraction);
    return $tb->formatTime;
}

1;
