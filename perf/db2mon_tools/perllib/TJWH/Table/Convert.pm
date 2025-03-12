# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Add common conversion capabilities to table columns

use strict;
use warnings;
use Data::Dumper;

package TJWH::Table::Convert;
use Carp qw(cluck confess);
use Scalar::Util qw(blessed);
use Storable qw(dclone);
use TJWH::Basic;
use TJWH::TableIterator;
use TJWH::TimeBits qw(getTimeFromString);
require Exporter;
use vars qw(@ISA);
@ISA = qw(TJWH::Table);

our $debug;
our $verbose;

sub new
{
    my ($proto, $table) = @_;
    my $class = ref($proto) || $proto;

    my $this;
    if (defined $table and
        blessed $table and
        $table->isa('TJWH::Table'))
    {
        # If we are given an existing and valid table, clone it and rebless it
        $this = dclone $table;
    }
    else
    {
        # Otherwise create a new object based on TJWH::Table
        $this = $class->SUPER::new;
    }

    $this->{origin} = undef;    # Reference to TJWH::Table if supplied

    bless $this, $class;

    return $this;
}

sub convertSIUnits
{
    my ($this, $column, $newFormat) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;
    # newFormat is optional

    $this->changeColumn(
                         $column,
                         sub {
                             my ($value) = @_;
                             return siUnits($value);
                         },
                        );

    $this->columnFormat($column, $newFormat) if $newFormat;
    return $this;
}

sub convertIECUnits
{
    my ($this, $column, $newFormat) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;
    # newFormat is optional

    $this->changeColumn(
                         $column,
                         sub {
                             my ($value) = @_;
                             return iecUnits($value);
                         },
                        );

    $this->columnFormat($column, $newFormat) if $newFormat;

    return $this;
}

sub convertHex
{
    my ($this, $column, $newFormat) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;
    $this->changeColumn(
                         $column,
                         sub {
                             my ($value) = @_;
                             return hex $value;
                         },
                        );

    $this->columnFormat($column, $newFormat) if $newFormat;

    return $this;
}

# Return epoch seconds from any time-based string found in the column
sub convertToEpoch
{
    my ($this, $column, $newFormat) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;

    $this->changeColumn(
                        $column,
                        sub {
                            my ($value) = @_;
                            my $tb = getTimeFromString($value);
                            return $tb->epoch if $tb;
                            return 0;
                        },
                       );
    $this->columnFormat($column, "%4d");
    $this->columnFormat($column, $newFormat) if $newFormat;
    return $this;
}

# Return a timestamp from any time-based string found in the column
sub convertToTimestamp
{
    my ($this, $column, $newFormat) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;

    $this->changeColumn(
                        $column,
                        sub {
                            my ($value) = @_;
                            my $tb = getTimeFromString($value);
                            return $tb->formatTime if $tb;
                            return "";
                        },
                       );

    $this->columnFormat($column, $newFormat) if $newFormat;
    return $this;
}

1;

