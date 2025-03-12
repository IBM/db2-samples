##############################################################################
## Licensed Materials - Property of IBM
##
## (C) COPYRIGHT International Business Machines Corp. 2014, 2015
## All Rights Reserved.
##
## SPDX-License-Identifier: Apache-2.0
##
## US Government Users Restricted Rights - Use, duplication or
## disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##############################################################################

#
# IXF/File.pm - An entire IXF file (basically a pretty wrapper over
# IXF::FileRaw)

package IXF::File;

use strict;
use warnings;

# use bigint;

use IXF::FileRaw;
use IXF::RecordRaw;
use IXF::Record;

use Data::Dumper;
use Carp qw(confess cluck);
use Fcntl qw(:seek);

# Set the following to 1 to see all the innards.
our $debug;
sub openFile;

sub new
{
  my $class = shift;
  my $self = { };
  bless $self, $class;

  $self->raw(shift);
  $self->{lookupFH} = {};

  return $self;
}

sub raw
{
  my ($self, $raw) = @_;

  $self->{raw} = $raw if defined $raw;
  return $self->{raw};
}

sub lookupFH {
    my ($this, $filename, $fh) = @_;

    return unless defined $filename;
    if (defined $fh)
    {
        $this->{lookupFH}->{$filename} = $fh;
    }

    return $this->{lookupFH}->{$filename};
}

sub records
{
  my $self = shift;
  $self->assert_raw;

  # Add each RecordRaw to a Record
  my @records = ();
  foreach my $rawrecord ($self->raw->records)
  {
    my $r = IXF::Record->new($rawrecord);
    push @records, $r;
  }

  return @records;
}

sub columns
{
  my $self = shift;
  $self->assert_raw;

  my @columns = ();

  # Read each column record
  foreach my $c ($self->records)
  {
    next unless $c->type eq 'C';

    my $len = $c->field("IXFCNAML")->data;
    my $name = $c->field("IXFCNAME")->data_with_length($len);
    push @columns, $name;
  }

  return @columns;
}

sub rows
{
  my $self = shift;
  $self->assert_raw;

  # TODO the Record class should do most of this

  my @columns = ();

  # Read each column record
  foreach my $c ($self->records)
  {
      $c->debug_print if $debug;
      next unless $c->type eq 'C';

      my $len = $c->field("IXFCNAML")->data;
      my $name = $c->field("IXFCNAME")->data_with_length($len);
      my $nullable = $c->field("IXFCNULL")->data;
      my $colpos = $c->field("IXFCPOSN")->data;
      my $type = $c->field("IXFCTYPE")->data;
      my $xlen = $c->field("IXFCLENG")->data;
      push @columns, [$name, $nullable, $colpos, $type, $xlen];
  }

  my @rows = ();
  # Each data record has a piece of data
  my @records = $self->records;
  while (my $d = shift @records)
  {
    next unless $d->type eq 'D';

    my $data = $d->field("IXFDCOLS")->data;
    dumpData($data) if $debug;

    my @values = ();
    for (my $x = 0; $x <= $#columns; $x++)
    {
      my $col = $columns[$x];
      my $nextcol = $columns[$x + 1];

      my $nullable = $col->[1];
      my $colpos   = $col->[2];
      my $type     = $col->[3];
      my $xlen     = $col->[4];

      print "Column $x: Current colpos: $colpos\n" if $debug;

      my $value;
      # IXF files MAY have multiple data records for a single row. If they do,
      # the nextcol position will be 1.
      if (defined $nextcol and $nextcol->[2] > $colpos)
      {
          # The length of this column = pos of next - pos of this
          my $len = $nextcol->[2] - $colpos;
          warn "Column $x: Bad length $len for data ".Dumper $data.
              " at colpos $colpos: Actual data length=".length $data."\n"
              if length $data < $colpos + $len - 1;
          $value = substr($data, $colpos - 1, $len);
      }
      else
      {
          confess "Bad nextcol position $nextcol->[2] compared to colpos $colpos\n"
              if defined $nextcol and $nextcol->[2] != 1;
          # The length is until the end
          $value = substr($data, $colpos - 1);
          if (defined $nextcol and $nextcol->[2] == 1)
          {
              # Fast forward through the records to find the next D
              do {
                  $d = shift @records;
              } while ($d->type ne 'D');
              $data = $d->field("IXFDCOLS")->data;
              dumpData($data) if $debug;
          }
      }

      # Is it null?
      my $null;
      if ($nullable and $value)
      {
          # First two bytes are a null indicator - see docs for "IXFDCOLS"
          # 0x0000: not null
          # 0xFFFF: null
          my $result = unpack('H4', $value);
          $null = 1 if $result =~ m/ffff/i;
          if ($null) {
              $value = undef;
          } else {
              $value = substr($value, 2);
          }
      }

      # All types in IXF are in Little-Endian format regardless of whether
      # they originated on AIX, Linux Intel or Windows
      unless ($null or not $value)
      {
          my $len;
          # TODO support more types
          # http://www-01.ibm.com/support/knowledgecenter/SSEPGG_10.5.0/com.ibm.db2.luw.admin.dm.doc/doc/r0004669.html
          if ($type == 384) {
              # DATE - 10 character string
              $value = substr($value, 0, 10);
          }
          elsif ($type == 448) {
              # VARCHAR
              print "VARCHAR data: ", (unpack "H*",$data), "\n" if $debug;
              $len = unpack('v', $value);
              $value = substr($value, 2, $len);
          }
          elsif ($type == 452) {
              # CHAR - length is in IXFCLENG
              my $len = $xlen;
              print "CHAR: ",(Dumper $value, $xlen) if $debug;
              $value = unpack("A$xlen", $value);
          }
          elsif ($type == 480) {
              # DOUBLE FLOATING POINT
              my $len = $xlen;  # IXFCLENG must be 8; 4-byte floating-point not supported
              $value = unpack("d<", $value);
          }
          elsif ($type == 484) {
              # DECIMAL
              print Dumper (unpack 'H*', $value), $xlen if $debug;
              my $scale = int substr($xlen, 0, 3) ;
              my $precision = int substr($xlen, 3, 2);
              my $decimal = unpack("H*", $value);
              if ($scale % 2 == 0)
              {
                  $scale ++;
              }
              my $int = int substr $decimal, 0, $scale - $precision;
              my $fract = int substr $decimal, ($scale - $precision), $precision;
              my $char = substr $decimal, -1, 1;
              my $sign = ($char eq 'c' ? +1 : -1);
              print "Got scale=$scale, prec=$precision int=$int fract=$fract sign=$sign\n" if $debug;
              $value = "$int.$fract";
              $value *= $sign;
          }
          elsif ($type == 492) {
              # BIGINT
              # print "DEBUG: input value=0x".(unpack "H*", $value)."\n";
              my $small = unpack('V', substr($value, 0, 4));
              my $big = unpack('V', substr($value, 4, 4));
              my $sign = 1;
              if ($big & 0x80000000)
              {
                  $big = (~$big & 0xffffffff);
                  $small = (~$small & 0xffffffff) + 1;
                  $sign = -1;
              }
              # print "DEBUG: sign = $sign  small = $small  big = $big\n";
              $value = $small + ($big << 32);
              $value *= $sign;
              # confess "===> ERROR: *** result $value too BIG *** \n"
              #     if $value > 0x7fffffffffffffff;
              # confess "===> ERROR: *** result $value too negative *** \n"
              #     if $value < -1 * (0x8000000000000000) ;

              # print "DEBUG: result=$value\n";
           }
          elsif ($type == 496) {
              # INTEGER
              $value = unpack('i<', $value);
          }
          elsif ($type == 500) {
              # SMALLINT
              $value = unpack('v', $value);
              $value -= 0x10000 if $value > 0x7fff;
          }
          elsif ($type == 960 or $type == 964 or $type == 968)
          {
              # LOB LOCATION SPECIFIER
              $value = $self->getDataFromFile($value);
          }
          elsif ($type == 404 or # CLOB
                 $type == 408 or # BLOB
                 $type == 412    # DBCLOB
                )
          {
              print "LOB data with type $type: ", (unpack "H*",$data), "\n" if $debug;
              $len = unpack('L', $value);
              $len *= 2 if $type == 412;
              $value = substr($value, 4, $len);
          }
          elsif ($type == 988)    # XML
          {
              # XML can be stored as flat information in another
              # file
              $value = $self->getDataFromFile($value);
          }
          elsif ($type == 392) # TIMESTAMP
          {
              # Retain native timestamp format so that data can be
              # written to IXF files or inserted via DBTable without
              # having to be reformatted.
              #
              # Starting in v97 the timestamp precision is stored
              # in IXFCLENG.  If not specified the precision is 6.
              my $len = 20 + ($xlen == 0 ? 6 : $xlen);
              $value = unpack("A$len", $value);
          }
          else
          {
              warn "Unsupported type $type for column $x\n";
          }
      }

      push @values, $value;
    }

    push @rows, \@values;
  }

  # Close any open file handles
  foreach my $filename (keys %{ $self->{lookupFH} })
  {
      close $self->{lookupFH}->{$filename};
      delete $self->{lookupFH}->{$filename};
  }

  return @rows;
}

sub getDataFromFile {
    my ($self, $desc) = @_;
    confess "self is not defined" unless defined $self;
    confess "desc is not defined" unless defined $desc;

    #  3<XDS FIL='product.xml.001.xml' OFF='0' LEN='262' />
    #  5<XDS FIL='product.xml.001.xml' OFF='262' LEN='275' />
    if ($desc =~ m/XDS\s+FIL='([^']+)'\s+OFF='(\d+)'\s+LEN='(\d+)'/)
    {
        return $self->readChunk($1, $2, $3);
    }
    # LOBS
    # ibm_tjwh_mon_get_pkg_cache_stmt_start.lobs.001.lob.2270.504/
    elsif ($desc =~ m#(.*\.lobs\.\d+\.lob)\.(\d+)\.(\d+)/#)
    {
        return $self->readChunk($1, $2, $3);
    }
    else
    {
       cluck "Warning: Failed to understand descriptor: $desc\n";
    }
    return;
}

sub readChunk {
    my ($self, $filename, $offset, $length) = @_;
    confess "filename is not defined" unless defined $filename;
    confess "offset is not defined" unless defined $offset;
    confess "length is not defined" unless defined $length;

    my $fileLength;
    # Filename is usually in the same directory as the IXF file
    my $ixfname = $self->raw->filename;
    my $base;
    if ($ixfname =~ m#(.*)/[^/]+$#) {
        $base = $1;
    }
    if (-f "$base/$filename")
    {
        $filename = "$base/$filename";
        $fileLength = -s $filename;
    }
    elsif (-f $filename) {
        # Do nothing to filename
        $fileLength = -s $filename;
    }
    else
    {
        # It may also have been compressed - look for candidates
        my $dh;
        opendir $dh, '.' or confess "Failed to examine current dir: $!\n";
        my @candidates = grep { m/$filename\.(gz|bz2|xz|Z)$/ } readdir $dh;
        closedir $dh;
        if (@candidates)
        {
            $filename = shift @candidates;
        }
        elsif (defined $base)
        {
            opendir $dh, $base or confess "Failed to examine dir $base: $!\n";
            my @candidates = grep { m#$filename\.(gz|bz2|xz|Z)$# } readdir $dh;
            closedir $dh;
            if (@candidates)
            {
                $filename = "$base/".(shift @candidates);
            }
            else
            {
                confess "Couldn't find $base/$filename\n";
            }
        }
        else
        {
            confess "Couldn't find $filename\n";
        }
    }
    if (defined $fileLength)
    {
        confess "Bad offset $offset beyond end of $filename ($fileLength bytes)\n"
            unless $offset < $fileLength;
        confess "Bad length $length at offset $offset finishes ".
            "after end of $filename ($fileLength bytes)\n"
            unless $offset + $length <= $fileLength;
    }

    my $fh = $self->lookupFH($filename);
    unless ($fh)
    {
        $fh = openFile "$filename" or confess "Failed to open $filename for read: $!\n";
        binmode $fh;
        $self->lookupFH($filename, $fh);
    }

    seek $fh, $offset, SEEK_SET;
    my $result;
    # NOTE: the offset on the read() builtin is the offset in $result, not the
    # position in the file.
    read $fh, $result, $length;

    return $result;
}

sub dumpData {
    my ($data) = @_;

    print "Total data length: ".(length $data)."\n";
    my $counter = 0;
    foreach my $chunk (unpack "(H16)*", $data) {
        my $ascii = pack "H16", $chunk;
        $ascii =~ s/[^!-~\s]/ /g;
        printf "0x%04x %-16s |$ascii|\n", $counter, $chunk;
        $counter += 8;
    }
    return;
}

sub debug_print
{
  my $self = shift;

  $_->debug_print foreach $self->records;
}

sub assert_raw
{
  my $self = shift;
  die "FileRaw not defined" unless defined $self->{raw};
}

# This is a straight copy from TJWH::Basic, intended to avoid having to add
# more dependencies to this module.
# Open a file that MAY be compressed or be special # (i.e. representing STDIN)
sub openFile
{
    my ($filename) = @_;

    # Failing to read from $fh to EOF when using Pipes will give a broken pipe
    # error. Ignore these
    $SIG{PIPE}='IGNORE';

    my $fh;
    if (-f $filename)
    {
        print "IXF::File: openFile: Opening $filename\n" if $debug;
        if ($filename =~ m/\.bz2$/)
        {
            open $fh, "bunzip2 -c $filename |" or Carp::confess "Can't open $filename for read (bunzip2): $!\n";
        }
        elsif ($filename =~ m/\.gz$/)
        {
            open $fh, "gunzip -c $filename |" or Carp::confess "Can't open $filename for read (gunzip): $!\n";
        }
        elsif ($filename =~ m/\.Z$/)
        {
            open $fh, "uncompress -c $filename |" or Carp::confess "Can't open $filename for read (uncompress): $!\n";
        }
        else
        {
            open $fh, $filename or Carp::confess "Can't open $filename for read: $!\n";
        }
    }
    # Read from STDIN
    elsif ($filename eq "-")
    {
        $fh = *STDIN;
    }
    else
    {
        Carp::cluck "Filename $filename is not recognized\n";
    }
    return *$fh if $fh;
    return;
}


1;

