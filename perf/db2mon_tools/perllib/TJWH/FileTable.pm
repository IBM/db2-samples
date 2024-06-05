# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;
use warnings;
use TJWH::BasicStats;
use TJWH::Table;
use Data::Dumper;

package TJWH::FileTable;
require Exporter;
use Scalar::Util qw(reftype);
use Carp qw(cluck confess);
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand

our $debug = 0;
our $verbose = 0;

sub new
{
    my ($class,
        $filename,
        $separator,
        $header,
        $hmatch,
        $skip,
        $match,
        $exclude,
        $evaluate) = @_;

    # Soak up the arguments into the object
    my $this = {
                'filename'  => $filename,       # File containing the data
                'fh'        => undef,           # File handle wins over filename
                'separator' => $separator,      # Separator for the different columns (regular expression)
                'header'    => $header,         # Headers are on this line number
                'hmatch'    => $hmatch,         # Headers match this regular expression
                'hnames'    => [],              # Header names
                'skip'      => $skip,           # Skip this many lines at the start of the file
                'match'     => $match,          # Only include lines that match this pattern
                'exclude'   => $exclude,        # Exclude lines that match this pattern
                'evaluate'  => $evaluate,       # Only include lines which evaluate this expression to true.
                'data'      => new TJWH::Table, # Actual data
                'maxCols'   => 0,               # Number of columns detected
                'search'    => undef,           # If set, the incoming data will
                'replace' => "",                # have search and replace done
                                                # prior to any other analysis
               };

    # Fix up anything which wasn't reasonably specified that we will rely on later.
    $this->{separator} = qw(\s+) unless defined $separator;
    $this->{skip} = 0 unless defined $skip;

    # Note that failure to specify a filename here isn't fatal. Attempts to
    # use an undefined filename are doomed.

    # Bless this and get on with it!
    bless $this, $class;

    print Data::Dumper::Dumper $this if $debug;

    return $this;
}

# ------------------------------------------------------------------------
# Accessor methods
#
sub filename
{
    my ($this, $filename) = @_;

    if (defined $filename)
    {
        if (-f $filename or $filename eq "-")
        {
            $this->{filename} = $filename;
        }
        else
        {
            Carp::cluck "$filename is not a file\n";
            $this->{filename} = undef;
        }
    }
    return $this->{filename};
}

sub fh {
    my ($this, $fh) = @_;

    if (defined $fh)
    {
        confess "fh ($fh) is not a GLOB" unless ref $fh eq "GLOB";
        $this->{fh} = $fh;
    }

    return $this->{fh};
}

sub separator
{
    my ($this, $separator) = @_;

    if (defined $separator)
    {
        $this->{separator} = $separator;
    }
    return $separator;
}

sub header
{
    my ($this, $header) = @_;

    if (defined $header)
    {
        $this->{header} = $header;
    }
    return $header;
}

sub hmatch
{
    my ($this, $hmatch) = @_;

    if (defined $hmatch)
    {
        $this->{hmatch} = $hmatch;
    }
    return $hmatch;
}

sub hnames {
    my ($this, @hnames) = @_;

    if (scalar @hnames)
    {
        $this->{hnames} = [@hnames];
    }

    return @{ $this->{hnames} };
}

sub skip
{
    my ($this, $skip) = @_;

    if (defined $skip)
    {
        if ($skip =~ m/\d+/ and $skip >= 0)
        {
            $this->{skip} = $skip;
        }
        else
        {
            Carp::confess "Expected an integer for the value of skip, not: $skip\n";
        }
    }
    return $skip;
}

sub match
{
    my ($this, $match) = @_;

    if (defined $match)
    {
        $this->{match} = $match;
    }
    return $match;
}

sub exclude
{
    my ($this, $exclude) = @_;

    if (defined $exclude)
    {
        $this->{exclude} = $exclude;
    }
    return $exclude;
}

sub evaluate
{
    my ($this, $evaluate) = @_;

    if (defined $evaluate)
    {
        $this->{evaluate} = $evaluate;
    }
    return $evaluate;
}

sub search {
    my ($this, $search) = @_;

    if (defined $search)
    {
        # Compile this pattern and store the result.
        $this->{search} = qr/$search/;
    }

    return $this->{search};
}

sub replace {
    my ($this, $replace) = @_;

    if (defined $replace)
    {
        $this->{replace} = $replace;
    }

    return $this->{replace}
}



# ------------------------------------------------------------------------
# Subroutines that do real work(TM)
#
sub readData
{
    my $this = shift;

    my $fh = $this->fh;
    unless (defined $fh)
    {
        unless (defined $this->{filename})
        {
            Carp::cluck "No filename is defined\n";
            return;
        }

        $fh = TJWH::Basic::openFile($this->{filename});
        unless (defined $fh)
        {
            print "$this->{filename} is not a file, skipping\n";
            next;
        }
    }

    # Start off with a clean sheet every time we come here.
    $this->blankData;

    my $lineNumber = 0;
    my $qrHmatch = qr($this->{hmatch}) if defined $this->{hmatch};
    my @headers;
    while (my $line = <$fh>)
    {
        # Use human line numbers (starting at 1)
        $lineNumber++;
        chomp $line;

        # Apply any search and replace immediately
        $line =~ s/$this->{search}/$this->{replace}/g if defined $this->search;
        $line =~ s/^\s+//g;     # Strip all leading whitespace

        # Manual headers win every time
        if (not scalar @headers and scalar $this->hnames)
        {
            $this->getTable->resetColumnNames($this->hnames);
            @headers = $this->hnames;
        }

        # If we've reached the line which contains headers, then set the headers
        if (defined $this->{header} and
            $lineNumber == $this->{header} and
            not scalar @headers)
        {
            print "Found header line:\n$line\n" if $verbose;
            $line =~ s/^\s+//g;
            @headers = split /$this->{separator}/, $line;
            $this->getTable->resetColumnNames(@headers);
            print "Headers for table:\n  ".(join "\n  ", $this->getTable->columnNames)."\n" if $verbose;
        }
        # If we reach a line that matches the hmatch and we don't yet have a
        # set of headers, then set the headers
        elsif (defined $qrHmatch and
               $line =~ m/$qrHmatch/ and
               not scalar @headers)
        {
            $line =~ s/^\s+//g;
            print "Found matching header line:\n$line\n" if $verbose;
            @headers = split /$this->{separator}/, $line;
            $this->getTable->resetColumnNames(@headers);
            print "Headers for table:\n  ".(join "\n  ", $this->getTable->columnNames)."\n" if $verbose;
        }
        elsif ($lineNumber > $this->{skip})
        {
            # Skip this line if it does not match this inclusive expression
            next if (defined $this->{match} and $line !~ m/$this->{match}/);

            # Skip this line if it does match the exclude list
            next if (defined $this->{exclude} and $line =~ m/$this->{exclude}/);

            # Get the data from this row
            my @columns = split /$this->{separator}/, $line;

            # Skip this line if the expression does not evaluate to true.
            if (defined $this->{evaluate})
            {
                # Lets make the eval have access to both @columns and $rh for
                # easier expressions
                my $rh;
                for (my $i = 0; $i < scalar @columns; $i++)
                {
                    $rh->{$headers[$i]} = $columns[$i] if defined $headers[$i];
                }

                my $result = eval $this->{evaluate};
                if ($@)
                {
                    print "Eval error: $@\n";
                }
                if (defined $result and $result <= 0)
                {
                    next;
                }
                else
                {
                    print "Eval including line: $line\n" if $verbose;
                }
            }

            if (scalar @columns > $this->{maxCols})
            {
                $this->{maxCols} = scalar @columns;
            }
            $this->{data}->appendRow(@columns);
        }
    }

    # Close this file handle IF we opened it in this subroutine
    close $fh if defined $this->filename and -f $this->{filename};

    # Tidy up the table - give it a caption and make sure it has headers for every column
    $this->getTable->caption
        ("Raw data".
         (defined $this->filename ? " for $this->{filename}" : ""));
    if (scalar $this->getTable->columnNames < $this->{maxCols})
    {
        $this->getTable->columnNames
            (
             $this->getTable->columnNames,
             map { $_ } scalar $this->getTable->columnNames .. ($this->{maxCols} - 1)
            );
    }
    $this->getTable->autoFormat;
    $this->getTable->autoWidth;

    return $this->{data};
}

# Wipe the slate clean
sub blankData
{
    my $this = shift;
    $this->{data} = new TJWH::Table;
    $this->{maxCols} = 0;
    return;
}

# Return the table associated with this data
sub getTable
{
    my $this = shift;
    return $this->{data};
}

1;
