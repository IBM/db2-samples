# -*- cperl -*-

# This class allows us to step forwards and backwards through a table, one row
# or more at a time.
#
# If the bounds of the table are reached or exceeded, the position in the
# table gets unset. To reset it, use the begin or end methods or explicitly
# specify a valid row index.

use strict;
use warnings;
use Data::Dumper;

package TJWH::TableIterator;
use TJWH::Table qw($noValue);
use Carp qw(cluck confess);
require Exporter;
use Scalar::Util qw(blessed);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK = qw(searchAndReplace
                combineTables
                combineTablesMatchCaption
                cleanTable
                $debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

sub new
{
    my ($class, $table) = @_;

    my $this = {
                table    => undef,
                rowIndex => undef, # Row index in the table. If the end of the
                                   # table is reached, then this will be undef.
                autoMove => undef, # If set, fetching a row will automatically
                                   # move the position in the table forward or
                                   # backward by this count
               };

    bless $this, $class;

    $this->table($table) if defined $table;

    return $this;
}

sub table {
    my ($this, $table) = @_;

    # if we were given something usable
    if (defined $table)
    {
        confess "Table $table is not a TJWH::Table"
            unless blessed $table and
                $table->isa('TJWH::Table');
        return unless $table->numberOfRows;

        $this->{table} = $table;

        my %dupCheck;
        map { $dupCheck{$_}++ } $table->columnNames;
        foreach my $dup (grep { $dupCheck{$_} > 1 } keys %dupCheck)
        {
            print "Warning: Column name $dup occurs $dupCheck{$dup} times\n".
                "in table ".($table->caption)."\n";
        }

        $this->begin;  # Position at the start of table
    }

    return $this->{table};
}

# Set or retrieve the position in the table
sub rowIndex {
    my ($this, $rowIndex) = @_;

    if (defined $rowIndex)
    {
        if ($rowIndex >= 0 and $rowIndex < $this->table->numberOfRows)
        {
            $this->{rowIndex} = $rowIndex;
        }
        else
        {
            print "New row index is outside the size of the table\n" if $verbose;
            $this->{rowIndex} = undef;
            return undef;
        }
    }

    return $this->{rowIndex};
}

# If rows get deleted from the table, we might have rowIndex after the end of
# the table. We'll treat that as not active, and we'll unset rowIndex if that happens.
sub active
{
    my ($this) = @_;

    if (defined $this->rowIndex and
        $this->rowIndex >= $this->table->numberOfRows)
    {
        $this->{rowIndex} = undef;
    }
    return 1 if defined $this->rowIndex;
    return;
}

sub autoMove
{
    my ($this, $autoMove) = @_;

    if (defined $autoMove)
    {
        confess "Automove must be an integer\n" unless $autoMove =~ m/^-?\d+$/;
        $this->{autoMove} = $autoMove;
    }

    return $this->{autoMove};
}

sub noAutoMove
{
    my ($this) = @_;

    $this->{autoMove} = undef;
    return $this->{autoMove};
}

# Move to the next line if it exists. next always return $this unless there is
# no table or no rows.
#
# Standard usage would be
#   do { print "Row: ".(join ",", $ti->getRow)."\n"; } while ($ti->next);
# or
#   $ti->next->getRowHash;
sub next
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;
    return undef unless defined $this->rowIndex;
    if ($this->rowIndex < ($this->table->numberOfRows - 1))
    {
        $this->rowIndex($this->rowIndex + 1);
    }
    else
    {
        # We make our position unknown once we run off the end of the table
        $this->{rowIndex} = undef;
        return undef;
    }
    return $this;
}

# Move to the previous line if it exists.
sub previous
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;
    if ($this->rowIndex > 0)
    {
        $this->rowIndex($this->rowIndex - 1);
    }
    else
    {
        # We make our position unknown once we run off the start of the table
        $this->{rowIndex} = undef;
        return undef;
    }

    return $this;
}

# Go to the first line in the table if the table has rows
sub begin
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;

    $this->rowIndex(0);
    return $this;
}

# Go to the last line in the table if the table has rows
sub end
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;

    $this->rowIndex($this->table->numberOfRows - 1);
    return $this;
}

# Get the values in the row
sub getRow
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;
    return undef unless defined $this->rowIndex;

    my @row = $this->table->getRow($this->rowIndex);
    if (defined $this->autoMove)
    {
        $this->rowIndex($this->rowIndex + $this->autoMove);
    }
    return @row;
}

# Apply the formatting to the row values prior to returning them
sub getFormattedRow
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;
    return undef unless defined $this->rowIndex;

    my @row = $this->table->getRow($this->rowIndex);
    my @headers = $this->table->headers;

    my @output = ();

    foreach my $value (@row)
    {
        my $format = shift @headers;
        # Carry undefined values over
        unless (defined $value)
        {
            push @output, undef;
            next;
        }
        if ($value eq $noValue)
        {
            push @output, $noValue;
            next;
        }
        if (defined $format)
        {
            no warnings;
            my $string = sprintf $format->formatData, $value;
            push @output, $string;;
        }
        else
        {
            # If we ran out of formatters, just return the value as is
            push @output, $value;
        }
    }

    map {
        $_ && do {
            s/^\s+//g;
            s/\s+$//g;
        };
    } @output;

    return @output;
}

sub getRowHash
{
    my ($this) = @_;
    return undef unless $this->table and $this->table->numberOfRows;
    return undef unless defined $this->rowIndex;

    my $rowHash = $this->table->getRowHash($this->rowIndex);
    confess "Undefined $rowHash" unless defined $rowHash;
    if (defined $this->autoMove)
    {
        $this->rowIndex($this->rowIndex + $this->autoMove);
    }

    return $rowHash;
}

sub searchAndReplace
{
    my ($table, $search, $replace) = @_;
    confess "table is not defined" unless defined $table;
    confess "search is not defined" unless defined $search;
    confess "replace is not defined" unless defined $replace;
    confess "Table $table is not a TJWH::Table"
        unless blessed $table and
        $table->isa('TJWH::Table');

    my $ti = new TJWH::TableIterator($table);
    my $clean = new TJWH::Table;
    $clean->inheritDescription($table);
    while ($ti->active)
    {
        my @row = $ti->getRow;
        print "Row has ".(scalar @row)." values\n" if $debug;
        foreach my $value (@row)
        {
            next unless defined $value;
            $value =~ s/$search/$replace/mg;
        }
        $ti->next;
        $clean->appendRow(@row);
    }

    return $clean;
}

sub combineTables {
    my (@rest) = @_;
    return unless @rest;

    my $st = new TJWH::Table;
    $st->inheritDescription($rest[0]);
    $st->insertColumn(0, "Caption", "%-4s");
    foreach my $table (@rest)
    {
        my $ti = new TJWH::TableIterator($table);
        while (defined $ti->rowIndex)
        {
            $st->appendRow($table->caption, $ti->getRow);
            $ti->next;
        }
    }
    $st->caption('Combined results from '.(scalar @rest).' tables');
    $st->autoWidth;
    return $st;
}

sub combineTablesMatchCaption {
    my ($match, @rest) = @_;
    confess "match is not defined" unless defined $match;

    return unless @rest;

    my $st = new TJWH::Table;
    $st->inheritDescription($rest[0]);
    $st->insertColumn(0, "Caption", "%-4s");

    my ($caption, $name, $remnant);
    foreach my $table (@rest)
    {
        my $ti = new TJWH::TableIterator($table);
        while (defined $ti->rowIndex)
        {
            if ($table->caption =~ qr/$match/)
            {
                ($name, $remnant) = ($1,$2);
                $caption = $name unless $caption;
                $st->appendRow($remnant, $ti->getRow);
            }
            else
            {
                $st->appendRow($table->caption, $ti->getRow);
            }
            $ti->next;
        }
    }
    $caption = 'Combined results from '.(scalar @rest).' tables' unless $caption;
    $st->caption($caption);
    $st->autoWidth;
    return $st;
}

sub cleanTable
{
    my ($result) = @_;
    confess "result is not defined" unless defined $result;
    confess "result is not a TJWH::Table"
        unless blessed $result and $result->isa('TJWH::Table');

    my $ti = new TJWH::TableIterator($result);
    my $clean = new TJWH::Table;
    $clean->inheritDescription($result);
    while ($ti->active)
    {
        my @row = $ti->getRow;
        print "Row has ".(scalar @row)." values\n" if $debug;
        foreach my $value (@row)
        {
            next unless defined $value;
            $value =~ s/[\n\r]/ /mg; # Remove line feeds
            $value =~ s/\s+/ /mg;    # Collapse whitespace
            $value =~ s/[^!-~\s]//g; # Remove non-ascii chars
        }
        $ti->next;
        $clean->appendRow(@row);
    }

    return $clean;
}

1;
