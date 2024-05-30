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
# IXF/Field.pm - A single field in the IXF file (basically a pretty wrapper
# over IXF::FieldRaw)
#

package IXF::Field;

use strict;
use warnings;

use IXF::FieldRaw;
use Carp qw(cluck confess);

# Types:
#   1 : string
#   2 : numeric
#   3 : boolean (Y/N)
#   4 : null-terminated string
#   5 : space-padded string
#   9 : other/unsupported/reserved
our %field_types =
    (
  # Header record fields
     "IXFHRECL" => 2,
     "IXFHRECT" => 1,
     "IXFHID"   => 1,
     "IXFHVERS" => 1,
     "IXFHPROD" => 1,
     "IXFHDATE" => 9,
     "IXFHTIME" => 9,
     "IXFHHCNT" => 2,
     "IXFHSBCP" => 9,
     "IXFHDBCP" => 9,
     "IXFHFIL1" => 1,

     # Table record fields
     "IXFTRECL" => 2,
     "IXFTRECT" => 1,
     "IXFTNAML" => 2,
     "IXFTNAME" => 1,
     "IXFTQULL" => 2,
     "IXFTQUAL" => 1,
     "IXFTSRC"  => 1,
     "IXFTDATA" => 1,
     "IXFTFORM" => 1,
     "IXFTMFRM" => 1,
     "IXFTLOC"  => 1,
     "IXFTCCNT" => 2,
     "IXFTFIL1" => 1,
     "IXFTDESC" => 5,
     "IXFTPKNM" => 4,
     "IXFTDSPC" => 9,
     "IXFTISPC" => 9,
     "IXFTLSPC" => 9,

     # Column descriptor record fields
     "IXFCRECL" => 2,
     "IXFCRECT" => 1,
     "IXFCNAML" => 2,
     "IXFCNAME" => 1,
     "IXFCNULL" => 3,
     "IXFCDEF"  => 3,
     "IXFCSLCT" => 3,
     "IXFCKPOS" => 2,
     "IXFCCLAS" => 1,
     "IXFCTYPE" => 2,
     "IXFCSBCP" => 9,
     "IXFCDBCP" => 9,
     "IXFCLENG" => 9,
     "IXFCDRID" => 9,
     "IXFCPOSN" => 2,
     "IXFCDESC" => 9,
     "IXFCLOBL" => 2,
     "IXFCUDTL" => 2,
     "IXFCUDTN" => 1,
     "IXFCDEFL" => 2,
     "IXFCDEFV" => 1,
     "IXFCREF"  => 9,
     "IXFCNDIM" => 2,
     "IXFCDSIZ" => 2,

     # Data record fields
     "IXFDRECL" => 2,
     "IXFDRECT" => 1,
     "IXFDRID"  => 2,
     "IXFDFIL1" => 9,
     "IXFDCOLS" => 9,

     # TODO Application record fields
     "IXFARECL" => 2,
     "IXFARECT" => 1,
     "IXFAPPID" => 1,
     "IXFADATA" => 9,
    );

sub new
{
  my $class = shift;
  my $self = { };
  bless $self, $class;

  $self->raw(shift);

  return $self;
}

sub raw
{
  my $self = shift;

  $self->{raw} = shift if (@_);
  return $self->{raw};
}

sub name
{
  my $self = shift;
  $self->assert_raw;
  return $self->raw->name;
}

sub length
{
  my $self = shift;
  $self->assert_raw;
  return $self->raw->length;
}

sub type
{
  my $self = shift;
  $self->assert_raw;
  return $self->raw->type;
}

sub comments
{
  my $self = shift;
  $self->assert_raw;
  return $self->raw->comments;
}

# TODO merge data and data_with_length into a single data sub with optional
# max length parameter
sub data
{
  my $self = shift;
  $self->assert_raw;

  my $name = $self->name;
  my $type = $field_types{$name};
  unless (defined $type) {
      warn "Cannot find type for $name";
      return $self->raw->data;
  }

  return $self->data_as_string if $type == 1;
  return $self->data_as_numeric if $type == 2;
  return $self->data_as_boolean if $type == 3;
  return $self->data_as_null_string if $type == 4;
  return $self->data_as_padded_string if $type == 5;

  # Unsupported, default to string
  #print "WARNING: Unsupported type for $name\n";
  return $self->raw->data;
}

sub data_with_length
{
  my $self = shift;
  $self->assert_raw;

  my $len = shift;
  my $name = $self->name;
  my $type = $field_types{$name};
  confess "Cannot find type for $name" unless $type;

  return $self->data_as_string_with_length($len) if $type == 1;

  # Unsupported, default to string
  #print "WARNING: Unsupported type for $name\n";
  return $self->raw->data;
}

sub data_as_string
{
  my $self = shift;
  $self->assert_raw;

  # Just return the data as is
  return $self->raw->data;
}

sub data_as_string_with_length
{
  my $self = shift;
  $self->assert_raw;

  # String, will be left-aligned
  my $len = shift;
  return substr($self->raw->data, 0, $len);
}

sub data_as_numeric
{
  my $self = shift;
  $self->assert_raw;

  # Follow the rules for numeric data specified at
  # http://www-01.ibm.com/support/knowledgecenter/SSEPGG_10.5.0/com.ibm.db2.luw.admin.dm.doc/doc/r0004667.html
  $_ = $self->raw->data;

  return $1 if /^(?:0|\s)*(\d+)$/;

  cluck "Invalid number: $_";
}

sub data_as_boolean
{
  my $self = shift;
  $self->assert_raw;

  $_ = $self->raw->data;

  return 0 if /^N$/;
  return 1 if /^Y$/;

  confess "Invalid boolean: $_";
}

sub data_as_null_string
{
  my $self = shift;
  $self->assert_raw;

  $_ = $self->raw->data;
  s/\x00.*$//;

  return $_;
}

sub data_as_padded_string
{
  my $self = shift;
  $self->assert_raw;

  $_ = $self->raw->data;
  s/(^\s+|\s+$)//g;

  return $_;
}

sub assert_raw
{
  my $self = shift;
  confess "FieldRaw not defined" unless defined $self->{raw};
}

sub debug_print
{
  my $self = shift;

  print "Field (name: " . $self->name . ", length: " . $self->length . ", type: " . $self->type . ", comments: " . $self->comments . ", data: \"" . $self->data . "\")\n";
}

1;

