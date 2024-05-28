# -*- cperl -*-
#
# Take a table (TJWH::Table) and produce a new table with stats for the
# all the columns
#

use strict;
use warnings;

package TJWH::TableStat;
use Carp qw(cluck confess);
use Scalar::Util 'blessed';
use Data::Dumper;
use TJWH::BasicStats;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(
                   tableStat
                   tableMean
                   tableSum
                   tableSummary
                   tableDiffColumns
              ); # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand

our $debug = 0;
our $verbose = 0;

# Statistics for numeric columns
sub tableStat
{
    my ($table, $tableStat, @columnNames) = @_;

    Carp::confess "Table is not defined\n" unless defined $table;
    Carp::confess "$table is not a table\n"
            unless blessed $table and $table->isa('TJWH::Table');

    print Dumper $table if $debug;

    @columnNames = $table->columnNames unless @columnNames;
    print "Column Names:\n  ".( join "\n  ", @columnNames)."\n" if $debug;

    unless (defined $tableStat)
    {
        $tableStat = new TJWH::Table;
        $tableStat->caption("Statistics for ".$table->caption);
        $tableStat->columnNames("Column",
                                "Number",
                                "Sum",
                                "Mean",
                                "Median",
                                "St.dev",
                                "Minimum",
                                "Maximum");
        $tableStat->columnFormats("%-12s",
                                  "%8d",
                                  "%8.3f",
                                  "%8.3f",
                                  "%8.3f",
                                  "%8.3f",
                                  "%8.3f",
                                  "%8.3f");
        $tableStat->type($table->type);
    }

    my @headers = $table->columnNames;
    for (my $i = 0; $i < $table->{maxCols}; $i++)
    {
        my @numbers = $table->getNumbersForColumn($i)
            if $table->tjwhFormat($i)->isNumber;
        if (scalar @numbers > 0)
        {
            $tableStat->appendRow($headers[$i],
                                  scalar @numbers,
                                  $table->sumForColumn($i),
                                  $table->meanForColumn($i),
                                  $table->medianForColumn($i),
                                  $table->stdevForColumn($i),
                                  $table->minForColumn($i),
                                  $table->maxForColumn($i));
        }
        else
        {
            print "Column $i is not numeric - omitted\n" if $verbose;
        }
    }
    $tableStat->autoWidth;

    return $tableStat;
}

# Summarise String columns
sub tableSummary
{
    my ($table, $tableStat) = @_;

    Carp::confess "Table is not defined\n" unless defined $table;
    Carp::confess "$table is not a table\n" unless ref $table eq "TJWH::Table";

    my @columnNames = $table->columnNames;
    print "Column Names:\n  ".( join "\n  ", @columnNames)."\n" if $debug;

    unless (defined $tableStat)
    {
        $tableStat = new TJWH::Table;
        $tableStat->caption("Summary for ".$table->caption);
        $tableStat->columnNames("Column",
                                "Number",
                                "Most common",
                                "First",
                                "Last");
        $tableStat->columnFormats("%-12s",
                                  "%8d",
                                  "%-4s",
                                  "%-4s",
                                  "%-4s");
        $tableStat->type($table->type);
    }

    my @headers = $table->columnNames;
    for (my $i = 0; $i < $table->{maxCols}; $i++)
    {
        my @numbers = $table->getNumbersForColumn($i)
            if $table->tjwhFormat($i)->isNumber;
        unless (@numbers)
        {
            my @column = $table->getColumn($i);
            $tableStat->appendRow($headers[$i],
                                  scalar @column,
                                  mode(@column),
                                  front(@column),
                                  back(@column),
                                 );
        }
    }
    $tableStat->autoWidth;

    return $tableStat;
}

# Create or add a row to a table summarizing the mean results
sub tableMean
{
    my ($table, $tableMean) = @_;
    Carp::confess "Table is not defined\n" unless defined $table;
    Carp::confess "$table is not a table\n" unless ref $table eq "TJWH::Table";

    my @columnNames = $table->columnNames;
    print "Column Names:\n  ".( join "\n  ", @columnNames)."\n" if $debug;

    unless (defined $tableMean)
    {
        $tableMean = new TJWH::Table;
        $tableMean->caption("Means") ;
        $tableMean->columnNames("Table", @columnNames);
        $tableMean->columnFormats("%-20s", $table->columnFormats);
    }

    $tableMean->appendRow($table->caption,
                          map { $table->tjwhFormat($_)->isNumber ?
                                    $table->meanForColumn($_) :
                                    $table->modeForColumn($_) }  0 .. $#columnNames);

    return $tableMean;
}

# Create or add a row to a table summarizing the sum of the results
sub tableSum
{
    my ($table, $tableSum) = @_;
    Carp::confess "Table is not defined\n" unless defined $table;
    Carp::confess "$table is not a table\n" unless ref $table eq "TJWH::Table";

    my @columnNames = $table->columnNames;
    print "Column Names:\n  ".( join "\n  ", @columnNames)."\n" if $debug;

    unless (defined $tableSum)
    {
        $tableSum = new TJWH::Table;
        $tableSum->caption("Sums") ;
        $tableSum->columnNames("Table", @columnNames);
        $tableSum->columnFormats("%-20s", $table->columnFormats);
    }

    $tableSum->appendRow($table->caption,
                          map { $table->tjwhFormat($_)->isNumber ?
                                    $table->sumForColumn($_) :
                                    $table->modeForColumn($_) }  0 .. $#columnNames);

    return $tableSum;
}

# This calculates the difference between the last two columns and creates a
# new column
sub tableDiffColumns
{
    my ($table, $switch) = @_;

    my $diffTable = new TJWH::Table;
    $diffTable->caption("Difference between ".$table->caption);
    $diffTable->columnNames($table->columnNames, "Difference");
    $diffTable->columnFormats($table->columnFormats, "%10s");

    foreach my $row ($table->rows)
    {
        my $last = @{ $row }[-1];
        my $penultimate = @{ $row }[-2];
        my $difference = "Unknown";
        if (($last =~ m/^[+-]?\d+([.]\d+)?$/) and ($penultimate =~ m/^[+-]?\d+([.]\d+)?$/))
        {
            $difference = $last - $penultimate;
            $difference *= -1 if $switch;
        }
        else
        {
            $last =~ s/^\s+//g;
            $last =~ s/\s+$//g;
            $penultimate =~ s/^\s+//g;
            $penultimate =~ s/\s+$//g;
            if ($last ne $penultimate)
            {
                $difference = "Different";
            }
            else
            {
                $difference = "Same";
            }
        }
        $diffTable->appendRow(@{ $row }, $difference);
    }

    return $diffTable;
}

1;
