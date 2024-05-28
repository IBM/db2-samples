# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

package TJWH::TableUtils;
use TJWH::TimeBits qw(getTimeFromString);
use TJWH::Basic qw(isaNumber);
use TJWH::BasicStats qw(sum mean);
use Carp qw(cluck confess);
use Scalar::Util qw(blessed);
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK =
    qw (
           removeEmptyColumns
           removeEmptyRows
           shortenCaption
           shortenPhrase
           totalTable
           totalTableExcept
           $debug $verbose
      ); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

sub shortenPhrase
{
    my ($phrase, $smatch, $options) = @_;
    confess "phrase is not defined" unless defined $phrase;
    confess "smatch is not defined" unless defined $smatch;
    confess "smatch ($smatch) is not a ARRAY" unless ref $smatch eq "ARRAY";
    confess "options ($options) is not a HASH" if defined $options and ref $options ne "HASH";
    my @sparts;
    unless ($options->{minimal})
    {
        # If this is a run directory, grab it
        if ($phrase =~ m/run\.((aix|lnx)\d+_\d+)\./)
        {
            push @sparts, $1;
        }

        # If there is a useful time string, use it
        my $tb = getTimeFromString($phrase);
        if ($tb)
        {
            push @sparts, $tb->formatTimeShort;
        }

        # If the phrase indicates the MON_GET_fn* get the fn
        if ($phrase =~ m/(mon[-_. ]get[-_. ][^-_. ]+)[-_. ]/i)
        {
            my $tf = $1;
            # Prune if necessary
            $tf =~ s/(DIFF|_start|_stop)$//gi;
            push @sparts, $tf;
        }
    }

    # If we were given something to look for in the phrase, add that as well
    foreach (@{$smatch})
    {
        if ($phrase =~ m/($_)/)
        {
            if (defined $2)
            {
                push @sparts, $2;
            }
            else
            {
                push @sparts, $1;
            }
        }
    }
    return "".(join " ", grep { defined $_ } @sparts);
}

sub shortenCaption {
    my ($table, $smatch, $options) = @_;
    confess "table is not defined" unless defined $table;
    confess "table is not a TJWH::Table" unless blessed $table and $table->isa('TJWH::Table');
    confess "smatch is not defined" unless defined $smatch;
    confess "smatch ($smatch) is not a ARRAY" unless ref $smatch eq "ARRAY";
    confess "options ($options) is not a HASH" if defined $options and ref $options ne "HASH";

    my $caption = $table->caption;
    $table->caption(shortenPhrase($caption,
                                  $smatch,
                                  $options));

    return $table;
}

sub totalTable
{
    my ($table) = @_;

    my $st = new TJWH::Table;
    $st->inheritDescription($table);
    my @row = ();
    for (my $i = 0; $i < $st->numberOfColumns; $i++)
    {
        if ($st->tjwhFormat($i)->isNumber)
        {
            push @row, sum($table->getColumn($i));
        }
        else
        {
            push @row, 'TOTAL';
        }
    }
    $st->appendRow(@row);
    $st->autoFormat;
    $st->info($table->info);

    $table = $st;
    return $table;
}

# Add up all the data except for column names specified (which are averaged).
# This is needed when we are summing over counters from performance monitors
# but we don't want to sum over the elapsed time column.
sub totalTableExcept
{
    my ($table, @except) = @_;

    # Make the name search easier
    my $lookup;
    map { $lookup->{$_}++ } @except;

    my $st = new TJWH::Table;
    $st->inheritDescription($table);
    my @row = ();
    for (my $i = 0; $i < $st->numberOfColumns; $i++)
    {
        if ($st->tjwhFormat($i)->isNumber)
        {
            if ($lookup->{$st->columnName($i)})
            {
                push @row, mean($table->getColumn($i));
            } else
            {
                push @row, sum($table->getColumn($i));
            }
        }
        else
        {
            push @row, 'TOTAL';
        }
    }
    $st->appendRow(@row);
    $st->autoFormat;
    $st->info($table->info);

    $table = $st;
    return $table;
}

# In-place deletion of empty columns
sub removeEmptyColumns
{
    my ($table, @except) = @_;
    confess "table is not defined" unless defined $table;
    confess "table is not a TJWH::Table" unless blessed $table and $table->isa('TJWH::Table');

    my $lookup;
    # Count all the occurrences of actual values (skip blank and undef entries)
    map { $lookup->{$_}++ } grep { $_ } @except;

    # Starting from the last column, look for columns which are entirely zero,
    # undefined or empty strings
    for (my $i = $table->numberOfColumns - 1; $i >=0; $i--)
    {
        # Skip exception columns entirely
        next if $lookup->{$table->columnName($i)};
        my @data = $table->getColumn($i);
        my $valid = 0;
        foreach my $value (@data)
        {
            if ($value)
            {
                if (isaNumber($value))
                {
                    if ($value != 0)
                    {
                        $valid = 1;
                    }
                } else
                {
                    # Entries from select output may have a single - in a column to indicate a null.
                    # Columns that are entirely comprised of "-" are also removed.
                    if ($value ne "-")
                    {
                        $valid = 1;
                    }
                }
                last if $valid;
            }
        }
        $table->deleteColumn($i) unless $valid;
    }
    return $table;
}

# In-place deletion of empty rows
sub removeEmptyRows
{
    my ($table, @except) = @_;
    confess "table is not defined" unless defined $table;
    confess "table ($table) is not a TJWH::Table" unless ref $table eq "TJWH::Table";

    my $lookup;
    map { $lookup->{$_}++ } @except;

    # Starting from the last row, look for rows which are entirely zero,
    # undefined or empty strings except for the key columns
    for (my $i = $table->numberOfRows - 1; $i >=0; $i--)
    {
        my $rh = $table->getRowHash($i);
        my $dataEntries = 0;
        foreach my $name (keys %{$rh})
        {
            next if $lookup->{$name};
            if (defined $rh->{$name})
            {
                if ($rh->{$name} =~ m/\d+/)
                {
                    $dataEntries++ unless $rh->{$name} == 0;
                }
                else
                {
                    $dataEntries++ unless $rh->{$name} eq '';
                }
            }
            last if $dataEntries;
        }
        print "$i Data entries found: $dataEntries\n" if $debug;
        $table->deleteRow($i) if $dataEntries == 0;
    }

    return;
}

# Trivial hash combiner (not suitable for deep structures, does not overwrite)
sub mergeHashes
{
    my (@hashes) = @_;

    my $result;
    foreach my $h (@hashes)
    {
        confess "h ($h) is not a HASH" unless ref $h eq "HASH";
        foreach my $key (keys %$h)
        {
            $result->{$key} = $h->{$key} unless exists $result->{$key};
        }
    }
    return $result;
}

1;
