# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

package TJWH::TableGroup;
require Exporter;
use TJWH::BasicStats;
use TJWH::Basic qw(uniqueArray);
use TJWH::Table;
use Scalar::Util qw(blessed);
use Carp qw(cluck confess);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(
                   groupByColumnIndex
                   groupByColumnName
                   groupAggregate
                   aggregateTable
                   aggregateSumTable
                   aggregateMeanTable
                   aggregateCountTable
                   aggregateEval
              ); # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug = 0;
our $verbose = 0;

sub new
{
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $this = {
                table        => undef,
                columns      => [],
                targetColumn => undef,
                function     => undef,
               };

    bless $this, $class;

    return $this;
}

# ------------------------------------------------------------------------
#
# Member functions
#
sub table {
    my ($this, $table) = @_;

    if (defined $table)
    {
        confess "table is not a TJWH::Table"
            unless blessed $table and $table->isa('TJWH::Table');
        $this->{table} = $table;
    }

    return $this->{table};
}

sub columns {
    my ($this, @columns) = @_;

    if (scalar @columns)
    {
        confess "this->table is not defined" unless defined $this->table;
        $this->{columns} = [@columns] if $this->verifyColumn(@columns);
    }

    return @{ $this->{columns} };
}

sub function {
    my ($this, $function) = @_;

    if (defined $function)
    {
        confess "function ($function) is not a CODE"
            unless ref $function eq "CODE";
        $this->{function} = $function;
    }

    return $this->{function};
}

sub targetColumn {
    my ($this, $targetColumn) = @_;

    if (defined $targetColumn)
    {
        confess "this->table is not defined" unless defined $this->table;
        $this->{targetColumn} = $targetColumn
            if $this->verifyColumn($targetColumn);
    }

    return $this->{targetColumn};
}

sub verifyColumn {
    my ($this, @rest) = @_;
    confess "this->table is not defined" unless defined $this->table;
    return 0 unless @rest;
    foreach my $name (@rest)
    {
        if ($name =~ m/^\d+/)
        {
            next if $name >= 0 and $name < $this->table->numberOfHeaders;
            confess "Column index $name is outside the range 0 .. ".
                ($this->table->numberOfHeaders - 1)."\n";
        }
        else
        {
            unless ($this->table->existsColumnName($name))
            {
                confess "Can't find column name $name in table - has:\n  ".
                    (join "\n  ", $this->table->columnNames)."\n";
            }
        }
    }
    return 1;
}

# ------------------------------------------------------------------------
#
# Processing functions
#

sub group {
    my ($this) = @_;
    confess "this is not defined" unless defined $this;
    confess "this->table is not defined" unless defined $this->table;
    confess "this->columns is not defined" unless scalar $this->columns;

    my @columns = map { $this->table->getColumnIndex($_) } $this->columns;

    my %groups;
    my @order;
    foreach my $row ($this->table->rows)
    {
        my @components = ();
        my @captions = ();
        foreach my $col (@columns)
        {
            my $value = @{ $row }[$col];
            $value = "undefined" unless defined $value;
            $value =~ s/[|]//g; # Strip pipe symbols (if any) as we will use
                                # these for a signature
            push @components, $value;
            push @captions, '"'.$this->table->columnName($col)."\"=$value";
        }
        my $signature = join "|", @components;
        unless (exists $groups{$signature})
        {
            $groups{$signature} = new TJWH::Table;
            if ($this->table->short)
            {
                my $caption = join "; ",@components;
                # Some captions may have some comma-seperated entries. Space
                # these out to make the text flow in Gnuplot and Mediawiki.
                $caption =~ s/,([^ ])/, $1/g;
                $groups{$signature}->caption($caption);
            }
            else
            {
                $groups{$signature}->caption($this->table->caption." grouped by ".(join ", ",@captions));
            }
            $groups{$signature}->columnNames($this->table->columnNames);
            $groups{$signature}->columnFormats($this->table->columnFormats);

            # Inherit the original table type (text, csv, wiki, etc)
            $groups{$signature}->type($this->table->type);
            push @order, $signature;
        }
        $groups{$signature}->appendRow(@{ $row });
    }

    return map { $groups{$_} } @order;
}

sub aggregateStatistics {
    my ($this) = @_;
    confess "this is not defined" unless defined $this;
    confess "this->targetColumn is not defined"
        unless defined $this->targetColumn;
    confess "this->columns is not defined" unless scalar $this->columns;

    my $result = new TJWH::Table;
    $result->caption($this->table->caption.
                     " $this->{targetColumn} aggregated over ".
                     (join ", ", $this->columns));
    $result->columnNames
        (
         $this->columns,
         map { "$_ ".$this->targetColumn } ("Count",
                                            "Min",
                                            "Max",
                                            "Mean",
                                            "Median",
                                            "StDev",)
        );
    $result->columnFormats
        (
         (map { $this->table->columnFormat($_) } $this->columns),
         "%8d", "%8.3f", "%8.3f", "%8.3f", "%8.3f",
        );

    $this->table->short(1);
    foreach my $gt (groupByColumnName($this->table, $this->columns))
    {
        my @groupValues = split /\s*;\s*/, $gt->caption;
        my @targetValues = $gt->getNumbersForHeader($this->targetColumn);
        $result->appendRow
            (
             @groupValues,
             count(@targetValues),
             minimum(@targetValues),
             maximum(@targetValues),
             mean(@targetValues),
             median(@targetValues),
             stdev(@targetValues),
            );
    }

    return $result;
}

sub aggregateCount
{
    my ($this) = @_;
    confess "this is not defined" unless defined $this;
    confess "this->columns is not defined" unless scalar @{$this->columns};

    my $result = new TJWH::Table;
    $result->caption($this->table->caption.
                     " aggregated over ".
                     (join ", ", $this->columns));
    $result->columnNames
        (
         $this->columns,
         "Count",
        );
    $result->columnFormats
        (
         (map { $this->table->columnFormat($_) } $this->columns),
         "%8d",
        );

    $this->table->short(1);
    foreach my $gt (groupByColumnName($this->table, $this->columns))
    {
        my @groupValues = split /\s*;\s*/, $gt->caption;
        $result->appendRow ( @groupValues, $gt->numberOfRows);
    }
    return $result;
}

sub aggregateSum
{
    my ($this) = @_;
    confess "this is not defined" unless defined $this;
    confess "this->columns is not defined" unless scalar $this->columns;

    my $result = new TJWH::Table;
    $result->caption($this->table->caption.
                     " aggregated over ".
                     (join ", ", $this->columns));
    $result->columnNames
        (
         $this->columns,
         "Sum(".$this->targetColumn.")",
        );
    $result->columnFormats
        (
         (map { $this->table->columnFormat($_) } $this->columns),
         "%8.3f",
        );

    $this->table->short(1);
    foreach my $gt (groupByColumnName($this->table, $this->columns))
    {
        my @groupValues = split /\s*;\s*/, $gt->caption;
        my @targetValues = $gt->getNumbersForHeader($this->targetColumn);
        $result->appendRow
            (
             @groupValues,
             sum(@targetValues),
            );
    }
    return $result;
}

sub aggregateMean
{
    my ($this) = @_;
    confess "this is not defined" unless defined $this;
    confess "this->columns is not defined" unless scalar $this->columns;

    my $result = new TJWH::Table;
    $result->caption($this->table->caption.
                     " aggregated over ".
                     (join ", ", $this->columns));
    $result->columnNames
        (
         $this->columns,
         "Mean(".$this->targetColumn.")",
        );
    $result->columnFormats
        (
         (map { $this->table->columnFormat($_) } $this->columns),
         "%8.3f",
        );

    $this->table->short(1);
    foreach my $gt (groupByColumnName($this->table, $this->columns))
    {
        my @groupValues = split /\s*;\s*/, $gt->caption;
        my @targetValues = $gt->getNumbersForHeader($this->targetColumn);
        $result->appendRow
            (
             @groupValues,
             mean(@targetValues),
            );
    }
    return $result;
}

# ------------------------------------------------------------------------
#
# External (legacy) subroutines
#

# Group a table based on selected columns. Note this does NOT require a sort
# to split groups properly, so this is a slightly different beast to a SQL
# Group By. The result is an array of new tables, each with a specific subset
# based on unique values in the given columns. Result tables are ordered by
# discovery order.
sub groupByColumnIndex
{
    my ($table, @columns) = @_;

    my $tg = new TJWH::TableGroup;
    $tg->table($table);
    $tg->columns(@columns);

    return $tg->group;
}

sub groupByColumnName
{
    my ($table, @names) = @_;
    my $tg = new TJWH::TableGroup;
    $tg->table($table);
    $tg->columns(@names);

    return $tg->group;
}

# Generate a report for a table by aggregating over the distinct contents of
# the given group columns
sub aggregateTable
{
    my ($table, $targetColumn, @columns) = @_;
    confess "table is not defined" unless defined $table;
    confess "targetColumn is not defined" unless defined $targetColumn;
    confess "columns is empty" unless @columns;

    my $tg = new TJWH::TableGroup;
    $tg->table($table);
    $tg->targetColumn($targetColumn);
    $tg->columns(@columns);

    return $tg->aggregateStatistics;
}

# Generate a report for a table by summing over
sub aggregateSumTable
{
    my ($table, $targetColumn, @columns) = @_;

    confess "table is not defined" unless defined $table;
    confess "columns is empty" unless @columns;

    my $tg = new TJWH::TableGroup;
    $tg->table($table);
    $tg->targetColumn($targetColumn);
    $tg->columns(@columns);

    return $tg->aggregateSum;
}

# Generate a report for a table by mean aggregate
sub aggregateMeanTable
{
    my ($table, $targetColumn, @columns) = @_;

    confess "table is not defined" unless defined $table;
    confess "columns is empty" unless @columns;

    my $tg = new TJWH::TableGroup;
    $tg->table($table);
    $tg->targetColumn($targetColumn);
    $tg->columns(@columns);

    return $tg->aggregateMean;
}

# Generate a report for a table by counting rows for each of the distinct
# contents of the given grouping columns
sub aggregateCountTable
{
    my ($table, @columns) = @_;

    confess "table is not defined" unless defined $table;
    confess "columns is empty" unless @columns;

    my $tg = new TJWH::TableGroup;
    $tg->table($table);
    $tg->columns(@columns);

    return $tg->aggregateCount;
}

# Take a table, break into many sub-tables based on multiple columns and
# optionally aggregate each of those sub-tables back into a single table using
# the supplied aggregateFn.
sub groupAggregate
{
    my ($table, $groupBy, $aggregateFn) = @_;
    confess "table is not defined" unless defined $table;
    confess "table is not a TJWH::Table" unless blessed $table and $table->isa('TJWH::Table');
    confess "groupBy is not defined" unless defined $groupBy;
    confess "groupBy ($groupBy) is not a ARRAY" unless ref $groupBy eq "ARRAY";
    foreach my $name (@{ $groupBy })
    {
        unless ($table->existsColumnName($name))
        {
            confess "Table $table does not have column name $name\n";
        }
    }

    my @results = groupByColumnName($table, @{ $groupBy });
    if ($aggregateFn)
    {
        return aggregateEval($groupBy, \@results, $aggregateFn);
    }
    else
    {
        return @results;
    }
}

sub aggregateEval
{
    my ($groupBy, $results, $aggregateFn) = @_;
    confess "groupBy is not defined" unless defined $groupBy;
    confess "groupBy ($groupBy) is not a ARRAY" unless ref $groupBy eq "ARRAY";
    confess "results is not defined" unless defined $results;
    confess "results ($results) is not a ARRAY" unless ref $results eq "ARRAY";
    for (my $index = 0; $index < scalar @{ $results }; $index++) {
        confess "results->[$index] is not a TJWH::Table"
            unless blessed $results->[$index] and $results->[$index]->isa('TJWH::Table');
    }
    confess "aggregateFn is not defined" unless defined $aggregateFn;
    # Could add a check here that this function actually works...

    my $gLookup;
    map { $gLookup->{$results->[0]->getColumnIndex($_)}++ } @$groupBy;

    my $aggTable = new TJWH::Table;
    $aggTable->columnNames($results->[0]->columnNames);
    $aggTable->caption($aggregateFn." over ".$results->[0]->caption);
    foreach my $t (@{ $results })
    {
        my @row;
        my @first = $t->getRow(0);
        for (my $index = 0; $index < $t->numberOfColumns; $index++)
        {
            if ($gLookup->{$index})
            {
                push @row, $first[$index];
            }
            else
            {
                # Do SOMETHING sane if we hit a string column.
                if ($t->{headers}->[$index]->isString)
                {
                    push @row, join ",", uniqueArray($t->getColumn($index));
                }
                else
                {
                    push @row, eval "$aggregateFn(".
                        (join ", ", $t->getNumbersForColumn($index)).
                        ")";
                }
            }
        }
        $aggTable->appendRow(@row);
    }

    return $aggTable;
}

1;
