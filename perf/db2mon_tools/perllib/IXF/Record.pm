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
# IXF/Record.pm - A single record in the IXF file (basically a pretty wrapper
# over IXF::RecordRaw)
#

package IXF::Record;

use strict;
use warnings;

use IXF::RecordRaw;
use IXF::Field;

my $debug;

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

sub fields
{
  my $self = shift;
  $self->assert_raw;

  # Add each FieldRaw to a Field
  my @fields = ();
  foreach my $rawfield ($self->raw->fields)
  {
    my $f = IXF::Field->new($rawfield);
    push @fields, $f;
  }

  return @fields;
}

sub field
{
  my $self = shift;
  $self->assert_raw;

  my $name = shift;

  return IXF::Field->new($self->raw->field($name));
}

sub debug_print
{
  my $self = shift;

  $_->debug_print foreach $self->fields;
}

sub assert_raw
{
  my $self = shift;
  die "RecordRaw not defined" unless defined $self->{raw};
}

1;

