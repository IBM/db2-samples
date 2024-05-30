##############################################################################
## Licensed Materials - Property of IBM
##
## (C) COPYRIGHT International Business Machines Corp. 2014
## All Rights Reserved.
##
## SPDX-License-Identifier: Apache-2.0
##
## US Government Users Restricted Rights - Use, duplication or
## disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##############################################################################

#
# IXF/RecordRaw.pm - A single record in the IXF file
#

package IXF::RecordRaw;

use strict;
use warnings;

use IXF::IO;
use open IN => ':bytes';

# The fields available in each type of record, minus the record length and type
# fields (in order they appear)
my %record_fields = (
  'H' => [qw(IXFHID IXFHVERS IXFHPROD IXFHDATE IXFHTIME IXFHHCNT IXFHSBCP
             IXFHDBCP IXFHFIL1)],
  'T' => [qw(IXFTNAML IXFTNAME IXFTQULL IXFTQUAL IXFTSRC IXFTDATA IXFTFORM
             IXFTMFRM IXFTLOC IXFTCCNT IXFTFIL1 IXFTDESC IXFTPKNM IXFTDSPC
             IXFTISPC IXFTLSPC)],
  'C' => [qw(IXFCNAML IXFCNAME IXFCNULL IXFCDEF IXFCSLCT IXFCKPOS IXFCCLAS
             IXFCTYPE IXFCSBCP IXFCDBCP IXFCLENG IXFCDRID IXFCPOSN IXFCDESC
             IXFCLOBL IXFCUDTL IXFCUDTN IXFCDEFL IXFCDEFV IXFCREF IXFCNDIM
             IXFCDSIZ)],
  'D' => [qw(IXFDRID IXFDFIL1 IXFDCOLS)],
  'A' => [qw(IXFAPPID IXFADATA)],
);

sub new
{
  my $class = shift;
  my $self = { };
  bless $self, $class;
  return $self;
}

sub read
{
  # $fh is assumed to have been opened in binary mode
  my ($self, $fh) = @_;

  # Array containing all fields
  my @fields;

  # Read the record length indicator (use "IXFHRECL" because all record length
  # indicators are the same)
  my $recl = IXF::FieldRaw->new("IXFHRECL");
  my $len = $recl->read($fh);
  return 0 unless defined $len;
  $len = $1 if $len =~ /^(?:0|\s)*(\d+)$/;
  $self->length($len);

  # Read the record type
  my $rect = IXF::FieldRaw->new("IXFHRECT");
  my $type = $rect->read($fh);
  return 0 unless defined $type;
  $self->type($type);

  # Set the proper names
  $recl->name("IXF${type}RECL");
  $rect->name("IXF${type}RECT");
  push @fields, ($recl, $rect);

  $len--; # Account for the already-seen type
  my $recorddata = read_data($fh, $len);

  # Figure out what fields we should find for this record type
  my @fieldnames = @{ $record_fields{$self->type} };

  # Now the fields can read themselves
  my $fhstr;
  open $fhstr, '<', \$recorddata;
  binmode $fhstr;
  foreach my $name (@fieldnames)
  {
    my $field = IXF::FieldRaw->new($name);
    my $ret = $field->read($fhstr);
    return 0 unless defined $ret;
    push @fields, $field;
  }
  close $fhstr;

  $self->fields(@fields);

  #$self->debug_print;

  return 1;
}

sub length
{
  my $self = shift;

  if (@_)
  {
    $self->{length} = shift;

    die "Negative length record" if ($self->{length} < 0);
  }

  return $self->{length};
}

sub type
{
  my $self = shift;

  if (@_)
  {
    my $t = shift;
    $self->{type} = $t;

    die "Unknown record type '$t'" unless defined $record_fields{$t};
  }

  return $self->{type};
}

sub fields
{
  my $self = shift;

  if (@_)
  {
    $self->{fields} = [];
    push @{ $self->{fields} }, @_;
  }

  return @{ $self->{fields} };
}

sub field
{
  my $self = shift;
  my $name = shift;

  foreach ($self->fields)
  {
    return $_ if $_->name eq $name;
  }

  return undef;
}

sub debug_print
{
  my $self = shift;

  $_->debug_print foreach $self->fields;
}

1;

