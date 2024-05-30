##############################################################################
## Licensed Materials - Property of IBM
##
## (C) COPYRIGHT International Business Machines Corp. 2014
## All Rights Reserved.
##
## US Government Users Restricted Rights - Use, duplication or
## disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##############################################################################

#
# IXF/FileRaw.pm
#

package IXF::FileRaw;

use strict;
use warnings;

use IXF::RecordRaw;
use IXF::FieldRaw;

use Cwd qw(abs_path);

use open IN =>':bytes';

sub new
{
  my $class = shift;
  my $self = {
              filename => undef,
             };
  bless $self, $class;
  return $self;
}

sub read_from_file
{
  my ($self, $filename, $verbose) = @_;

  unless (-f $filename)
  {
      warn "$filename is not a file\n";
      return;
  }

  $self->filename($filename);

  # Open the file in binary mode
  open my $fh, $self->filename or die "Error opening input file $self->{filename} ($!)";
  $self->read_from_fh($fh, $verbose);
  close $fh;
  return;
}

sub read_from_fh
{
  my ($self, $fh, $verbose) = @_;

  # Ensure binary mode
  binmode($fh);

  # Now read each record in order as per
  # http://www-01.ibm.com/support/knowledgecenter/SSEPGG_10.5.0/com.ibm.db2.luw.admin.dm.doc/doc/r0004667.html

  my @records;

  # First record must be of type 'H'
  my $h = IXF::RecordRaw->new;
  $h->read($fh) or die "Expected: record of type 'H'";
  $h->type ne 'H' and die "Expected: record of type 'H'";
  push @records, $h;

  my $c_cnt = 0;

  # Find the table record
  while (1)
  {
    my $r = IXF::RecordRaw->new;
    $r->read($fh) or die "Expected: record of type 'T'";
    push @records, $r;

    if ($r->type eq 'T')
    {
      # Get the number of C records
      $c_cnt = $r->field("IXFTCCNT")->data;
      last;
    }

    $r->type ne 'A' and die "Expected: record of type 'T'";
  }

  # Read the column descriptor records
  while ($c_cnt)
  {
    my $r = IXF::RecordRaw->new;
    $r->read($fh) or die "Expected: record of type 'C'";
    push @records, $r;

    if ($r->type eq 'C')
    {
      $c_cnt--;
      next;
    }

    $r->type ne 'A' and die "Expected: record of type 'C'";
  }

  # Read the data records
  while (1)
  {
    my $r = IXF::RecordRaw->new;
    $r->read($fh) or last;
    push @records, $r;

    $r->type eq 'A' or $r->type eq 'D' or die "Expected: record of type 'D'";
  }

  $self->records(@records);
  $self->verbose_print if $verbose;

  return;
}

sub filename {
    my ($self, $filename) = @_;

    if (defined $filename)
    {
        die "$filename is not a file\n" unless -f $filename;
        # Store the absolute path to the file so we can find related data (LOBs/XML)
        $self->{filename} = abs_path $filename;
    }

    return $self->{filename};
}

sub records
{
  my $self = shift;

  if (@_)
  {
    $self->{records} = [];
    push @{ $self->{records} }, @_;
  }

  return @{ $self->{records} };
}

sub column_records
{
  my $self = shift;
  return $self->get_records_of_type('C');
}

sub data_records
{
  my $self = shift;
  return $self->get_records_of_type('D');
}

sub get_records_of_type
{
  my $self = shift;
  my $type = shift;

  my @r = ();

  foreach ($self->records)
  {
    push @r, $_ if $_->type eq $type;
  }

  return @r;
}

sub debug_print
{
  my $self = shift;

  $_->debug_print foreach ($self->records);
}

sub verbose_print
{
  print "TODO :(\n";
}

1;

