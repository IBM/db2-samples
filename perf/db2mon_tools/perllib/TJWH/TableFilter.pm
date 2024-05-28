# -*- cperl -*-
#
# These are manipulation routines to take one table and create a new one.
#

use strict;
use warnings;
use Data::Dumper;

package TJWH::TableFilter;
require Exporter;
use TJWH::TableIterator;

# Include basic statistics functions for use in evaluate subroutine
use TJWH::BasicStats;
# Include time functions for use in evaluate subroutine
use TJWH::TimeBits;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp qw(cluck confess);

@ISA       = qw(Exporter);
@EXPORT    = qw(
                   tableFilter
                   tablePredicate
                   tableFilterColumn
                   tableFilterHeader
                   tableFilterSubroutine
                   tableFilterRowhash
              );                  # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand

our $debug = 0;
our $verbose = 0;

# Create a new table containing only the rows which match the criteria given
#
# $condition should contain the condition being applied to the values in the given column.
sub tableFilterColumn
{
    my ($table, $columnIndex, $condition) = @_;
    confess "Table must be defined\n" unless defined $table;
    confess "ColumnIndex must be defined\n" unless defined $columnIndex;
    $columnIndex = $table->getColumnIndex($columnIndex);

    my $tableFilter = new TJWH::Table;

    # Duplicate the information in the table header
    $tableFilter->inheritDescription($table);

    foreach my $row ($table->rows)
    {
        my @values = @{ $row };
        if (eval "$values[$columnIndex] $condition")
        {
            $tableFilter->appendRow(@{ $row });
        }
    }

    return $tableFilter;
}

# $condition should contain the condition being applied to the values in the
# given column. All headers matching the header will be used to filter the
# result. If no matching headers are found, a copy of the original table is returned.
sub tableFilterHeader
{
    my ($table, $columnHeader, $condition) = @_;

    my @indexes = $table->getIndexForHeader($columnHeader);
    my $tableFilter = $table;
    foreach my $columnIndex (@indexes)
    {
        $tableFilter = tableFilterColumn($tableFilter, $columnIndex, $condition);
    }

    return $tableFilter;
}

# Create a new table containing only the rows which match the criteria given
#
# $condition should contain the condition being applied to the values in the
# row.  Arrays @columns and @values contain the row contents, along with array
# reference $row. A hash lookup $rh is also available.
sub tableFilter
{
    my ($table, $condition) = @_;
    print "Condition: $condition\n" if $debug;
    confess "table is not defined" unless defined $table;
    confess "table is not a TJWH::Table" unless blessed $table and $table->isa('TJWH::Table');
    confess "condition is not defined" unless defined $condition;
    confess "condition is empty" unless $condition;

    my $tableFilter = new TJWH::Table;

    # Duplicate the information in the table header
    $tableFilter->inheritDescription($table);

    my $ti = new TJWH::TableIterator($table);
    while (defined $ti->rowIndex)
    {
        # These variables are here to let the caller have some good choices
        # for evaluating conditions
        my $row = [ $ti->getRow ];
        my @values = @{ $row };
        my @columns;
        *columns = \@values;
        my $rh = $ti->getRowHash;
        if (eval $condition)
        {
            $tableFilter->appendRow(@{ $row });
        }
        $ti->next;
    }

    return $tableFilter;
}

# More "SQL like" predicate language with some checks on column names
sub tablePredicate
{
    my ($table, $predicate) = @_;
    confess "table is not defined" unless defined $table;
    confess "table is not a TJWH::Table" unless blessed $table and $table->isa('TJWH::Table');

    confess "predicate is not defined" unless defined $predicate;

    my $lookup;
    foreach my $name ($table->columnNames)
    {
        $lookup->{$name} ++;
    }

    # Start off by removing any leading whitespace
    my $remnant = $predicate;
    $remnant =~ s/^\s+//g;

    # Ensuring we have trailing whitespace
    $remnant .= " ";

    # The rewrite will be added to @pieces
    my @pieces;
    my $fragment;
    while ($remnant =~ m/^(\S+)\s+(.*)$/)
    {
        ($fragment, $remnant) = ($1, $2);
        if ($lookup->{$fragment})
        {
            push @pieces, "\$rh->{$fragment}";
        } elsif ($fragment eq '=')
        {
            push @pieces, '==';
        } else
        {
            push @pieces, $fragment;
        }
    }

    my $evaluate = join " ", @pieces;
    return tableFilter($table, $evaluate);
}

# Create a new table containing only the rows which match the criteria given
#
# This is a smorgasbord approach - you can provide extra arguments that will
# be fed to the subroutine you provide along with an array reference into the
# current row.
sub tableFilterSubroutine
{
    my ($table, $subroutine, @args) = @_;
    confess "Table must be defined\n" unless defined $table;
    confess "Subroutine must be defined\n" unless defined $subroutine;
    confess "Subroutine must have type code\n" unless ref $subroutine eq "CODE";

    my $tableFilter = new TJWH::Table;

    # Duplicate the information in the table header
    $tableFilter->inheritDescription($table);

    foreach my $row ($table->rows)
    {
        if ($subroutine->($row, @args))
        {
            $tableFilter->appendRow(@{ $row });
        }
    }

    return $tableFilter;
}

# And this variant provides a hash for each row instead of an array
sub tableFilterRowhash
{
    my ($table, $subroutine, @args) = @_;
    confess "Table must be defined\n" unless defined $table;
    confess "Subroutine must be defined\n" unless defined $subroutine;
    confess "Subroutine must have type code\n" unless ref $subroutine eq "CODE";

    my $tableFilter = new TJWH::Table;

    # Duplicate the information in the table header
    $tableFilter->inheritDescription($table);

    my $ti = new TJWH::TableIterator($table);
    while (defined $ti->rowIndex)
    {
        print "Examining row ".$ti->rowIndex."\n" if $debug;
        if ($subroutine->($ti->getRowHash, @args))
        {
            $tableFilter->appendRow($ti->getRow);
            print "Accepted\n" if $debug;
        }
        else
        {
            print "Rejected\n" if $debug;
        }
        $ti->next;
    }

    return $tableFilter;
}


1;
