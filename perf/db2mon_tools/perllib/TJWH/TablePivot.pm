# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;
use warnings;
use Data::Dumper;

# Take a TJWH::Table, turn it on its side, formatting the data as we do so
package TJWH::TablePivot;
use TJWH::Table;
use TJWH::TableIterator;
use Carp qw(cluck confess);
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(setHeadersFromColumns); # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

sub new
{
    my ($proto, $table) = @_;
    my $class = ref($proto) || $proto;

    my $this = {
                table => undef,
                pivot => undef,
                headers => [],
               };

    bless $this, $class;
    $this->pivot($table);

    return $this;
}

sub pivot
{
    my ($this, $table) = @_;

    if (defined $table)
    {
        confess "$table is not a TJWH::Table: ".Dumper $table
            unless ref $table eq 'TJWH::Table';
        $this->{table} = $table;

        # These are the names we will apply to the new table for each of the
        # rows we find. The "Headings" column is always set.
        my @headers = $this->headers;

        # The incoming table should have the formatting all straightened
        # out. However, we need to "freeze" the data using that formatting.
        my $pivot = new TJWH::Table;
        $pivot->caption($table->caption);
        my @row = $table->columnNames;
        my $width = longestStringLength(@row);

        $pivot->appendColumn(
                             "Headings",
                             "%-".$width."s",
                             @row,
                            );

        if ($table->numberOfRows)
        {
            my $ti = new TJWH::TableIterator($table);
            do
            {
                @row = $ti->getFormattedRow;

                # Set the header to the supplied one or generate as necessary
                my $header = shift @headers;
                $header = "Row ".$ti->rowIndex unless $header;

                $width = longestStringLength(@row);
                $pivot->appendColumn(
                                     $header,
                                     "%".$width."s",
                                     @row,
                                    );
            } while ($ti->next);
        }
        $pivot->type($table->type);
        $this->{pivot} = $pivot;
    }

    return $this->{pivot};
}

sub table
{
    my ($this) = @_;
    return $this->{table};
}

sub headers {
    my ($this, @headers) = @_;

    if (scalar @headers)
    {
        $this->{headers} = [ @headers ];
    }
    return @{ $this->{headers} };
}

sub longestStringLength
{
    my (@rest) = @_;

    my $maximum = 0;
    foreach my $value (@rest)
    {
        next unless defined $value;
        $maximum = length $value if length $value > $maximum;
    }
    return $maximum;
}

# ------------------------------------------------------------------------
#
# Utility functions
#
sub setHeadersFromColumns
{
    my ($table, @columns) = @_;
    confess "table is not defined" unless defined $table;
    map {
        confess "$_ is not a column in table $table\n -  ".
            (join "\n -  ", $table->columnNames)."\n"
                unless $table->existsColumnName($_)
            } @columns;

    my $ti = new TJWH::TableIterator($table);
    $ti->autoMove(1);
    my @headers = ();
    while ($ti->active)
    {
        my $rh = $ti->getRowHash;
        push @headers, (join "; ", map {
            $rh->{$_}
        } @columns);
    }

    return @headers;
}

1;
