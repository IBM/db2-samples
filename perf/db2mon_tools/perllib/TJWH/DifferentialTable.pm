# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

package TJWH::DifferentialTable;
use Carp qw(cluck confess);
use TJWH::Table;
use TJWH::TableIterator;
use TJWH::TimeBits qw(subtractTimestampsPermissive);
use Scalar::Util qw(blessed);
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

sub new
{
    my ($proto, $table) = @_;
    my $class = ref($proto) || $proto;

    my $this = {
                table  => undef,
                ignore => {},
                keep   => "current",
               };

    bless $this, $class;
    $this->table($table);

    return $this;
}

sub table {
    my ($this, $table) = @_;

    if (defined $table)
    {
        confess "table ($table) is not a blessed reference\n"
            unless blessed $table;
        confess "table ($table) is not a TJWH::Table"
            unless $table->isa("TJWH::Table");
        $this->{table} = $table;
    }

    return $this->{table};
}

# In a differential table, we subtract the current row from the previous
# row. For String columns and any ignored, we need to decide whether we
# display the:
#  - previous value
#  - current value
#  - changed: whether the current value is same or different to the previous
sub keep {
    my ($this, $keep) = @_;
    if (defined $keep)
    {
        confess "keep ($keep) does not match current|previous|changed" unless $keep =~ m/current|previous|changed/;
        $this->{keep} = $keep;
    }

    return $this->{keep};
}

# We track the column indices that should NOT be subtracted/compared.
sub ignore {
    my ($this, @ignores) = @_;
    foreach my $ignore (@ignores)
    {
        my $columnIndex = $this->table->getColumnIndex($ignore);
        confess "Bad columnIndex $columnIndex is not an integer\n"
            unless $columnIndex =~ m/^\d+$/;
        $this->{ignore}->{$columnIndex}++;;
    }

    return $this->{ignore};
}

# By default, all columns will be considered for comparison.
sub compare
{
    my ($this, $index) = @_;
    confess "Bad index $index is not an integer\n" unless $index =~ m/^\d+$/;
    if (defined $this->{ignore}->{$index})
    {
        return 0;
    }
    return 1;
}

sub differential
{
    my ($this) = @_;
    confess "this->table is not defined" unless defined $this->table;

    my $diff = new TJWH::Table;
    $diff->inheritDescription($this->table);

    my %makeNumeric; # List of columns to make numeric after subtraction (e.g. Timestamps)

    my $ti = new TJWH::TableIterator($this->table);
    $ti->autoMove(1);
    my @previous = $ti->getRow;
    while ($ti->active)
    {
        my @current = $ti->getRow;
        my @newRow;
        for (my $index = 0; $index < scalar @current; $index++)
        {
            # If we are going to compare this column
            if ($this->compare($index))
            {
                if ($this->table->tjwhFormat($index)->isNumber)
                {
                    if (defined $current[$index] and defined $previous[$index])
                    {
                        my $difference;
                        eval {
                            $difference = $current[$index] - $previous[$index];
                        };

                        if ($@) {
                            push @newRow, undef;
                        }
                        else {
                            push @newRow, $difference;
                        }
                    }
                    else
                    {
                        push @newRow, undef;
                    }
                }
                else
                {
                    my $difference;
                    if ($this->table->columnName($index) =~ m/^TIMESTAMP$|^CURRENT_TIME(STAMP)?$/)
                    {
                        $difference =
                            subtractTimestampsPermissive($current[$index], $previous[$index]);
                        $makeNumeric{$index}++ if defined $difference;
                        push @newRow, $difference;
                    }
                    elsif ($this->keep eq 'previous')
                    {
                        push @newRow, $previous[$index];
                    }
                    elsif ($this->keep eq 'current')
                    {
                        push @newRow, $current[$index];
                    }
                    elsif ($this->keep eq 'changed')
                    {
                        if ($current[$index] eq $previous[$index])
                        {
                            push @newRow, "Same";
                        }
                        else
                        {
                            push @newRow, "Different";
                        }
                    }
                }
            }
            # Otherwise, only honour the 'previous' mode - we will consider
            # 'changed' == current
            else
            {
                if ($this->keep eq 'previous')
                {
                    push @newRow, $previous[$index];
                }
                else
                {
                    push @newRow, $current[$index];
                }
            }
        }
        $diff->appendRow(@newRow);
        @previous = @current;
    }

    # Finally, fix up the formats for timestamp columns that are now numeric
    $diff->autoFormat(keys %makeNumeric) if keys %makeNumeric;

    return $diff;
}


1;
