# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

package TJWH::MultiSelect;
use Carp qw(cluck confess);
use Scalar::Util qw(blessed);
use TJWH::Table;
use TJWH::Basic qw(stripWhitespace openFile);
use TJWH::TimeBits qw(getTimeFromString);
use File::Basename qw(basename dirname);
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
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $this = {
                filename     => undef,
                usebase      => undef,
                usedir       => undef,
                fullname     => undef,
                caption      => undef,
                cmatch       => undef,
                prematch     => undef,
                fh           => undef,
                active       => undef,
                tables       => [],
                separator    => undef,
                columnWidths => [],
                headings     => undef,
                latest       => undef,
               };

    bless $this, $class;

    return $this;
}

sub filename {
    my ($this, $filename) = @_;

    if (defined $filename)
    {
        confess "$filename is not a file" unless -f $filename or $filename eq '-';
        $this->{filename} = $filename;
        $this->caption($filename) unless $this->caption;
    }

    return $this->{filename};
}

sub usebase {
    my ($this, $usebase) = @_;

    if (defined $usebase)
    {
        $this->{usebase} = $usebase;
    }

    return $this->{usebase};
}

sub usedir {
    my ($this, $usedir) = @_;

    if (defined $usedir)
    {
        $this->{usedir} = $usedir;
    }

    return $this->{usedir};
}

sub fullname {
    my ($this, $fullname) = @_;

    if (defined $fullname)
    {
        $this->{fullname} = $fullname;
    }

    return $this->{fullname};
}

sub caption {
    my ($this, $caption) = @_;

    if (defined $caption)
    {
        $this->{caption} = $caption;
    }

    return $this->{caption};
}

# Automatically set caption if the line matches this
sub cmatch {
    my ($this, $cmatch) = @_;

    if (defined $cmatch)
    {
        $this->{cmatch} = $cmatch;
    }

    return $this->{cmatch};
}

# Automatically set caption based on previous line contents if this line
# matches prematch
sub prematch
{
    my ($this, $prematch) = @_;

    if (defined $prematch)
    {
        $this->{prematch} = $prematch;
    }

    return $this->{prematch};
}

sub fh {
    my ($this, $fh) = @_;

    if (defined $fh)
    {
        $this->{fh} = $fh;
    }

    return $this->{fh};
}

sub active {
    my ($this, $active) = @_;

    if (defined $active)
    {
        confess "active ($active) is not a TJWH::Table"
            unless ref $active eq "TJWH::Table";
        $this->{active} = $active;
    }

    cluck "TJWH::MultiSelect active=".$this->{active}."\n" if $debug;
    return $this->{active};
}

sub tables {
    my ($this, @tables) = @_;

    if (scalar @tables)
    {
        $this->{tables} = [@tables];
    }

    return @{ $this->{tables} };
}

sub separator {
    my ($this, $separator) = @_;

    if (defined $separator)
    {
        $this->{separator} = $separator;
        # describe output has two whitespace characters between each
        # column. To munge this into our world, we extend the width of each
        # column by one for every column except the last.
        $separator =~ s/\s\s/- /g;
        $this->columnWidths(map { length $_ } split /\s/, $separator);
    }

    return $this->{separator};
}

sub columnWidths {
    my ($this, @columnWidths) = @_;

    if (scalar @columnWidths)
    {
        $this->{columnWidths} = [@columnWidths];
    }

    return @{ $this->{columnWidths} };
}

sub headings {
    my ($this, @headings) = @_;

    # Sometimes there is just a line of -. We don't want that to be considered a table.

    # Cope with multiple header lines
    if (@headings)
    {
        # Set up the active table
        confess "this->active is defined!" if defined $this->active;

        my $table = new TJWH::Table;
        my $caption = $this->caption;
        $caption .= " ".$this->latest->formatTime if defined $this->latest;
        $table->info({ 'latest' => $this->latest->formatTime }) if defined $this->latest;
        $table->caption($caption);
        my @headers;
        foreach my $heading (@headings)
        {
            next unless defined $heading;
            $this->{headings} .= $heading;
            my $index = 0;
            foreach my $width ($this->columnWidths)
            {
                my $limit = length $heading;
                last if $limit == 0;
                $width = $limit if $width > $limit;
                my $currentHeader = substr $heading, 0, $width;
                if (length $heading > $width)
                {
                    $heading = substr $heading, $width + 1;
                }
                else
                {
                   $heading = "";
                }
                confess "currentHeader is not defined" unless defined $currentHeader;
                $headers[$index] .= " " if $headers[$index];
                $headers[$index] .= stripWhitespace $currentHeader;
                $index++;
            }
        }
        if (scalar @headers == scalar $this->columnWidths)
        {
            $table->columnNames(@headers);
            $table->columnFormats(map { "%${_}s" } $this->columnWidths);
            $this->active($table);
        }
        else
        {
            cluck "INFO:: ".$this->filename.": line $.: ".
                "Mismatch between the number of headers:".scalar @headers.
                " and the number of widths:".scalar $this->columnWidths."\n" if $verbose;
        }
    }

    return $this->{headings};
}

sub latest
{
    my ($this, $line) = @_;

    # We're looking for monitor start (and stop times).
    # MONITOR_START_TIME
    # --------------------------
    # 2017-03-14-14.14.44.909446
    if ($line and $line =~ m/^\d{4}-\d{2}-\d{2}-\d{2}\.\d{2}\.\d{2}\.\d{6}/)
    {
        my $tb = getTimeFromString($line);
        $this->{latest} = $tb if $tb and
            (not defined $this->{latest} or $this->{latest}->isBefore($tb));
    }
    return $this->{latest};
}

sub timestamp {
    my ($this, $timestamp) = @_;

    if (defined $timestamp)
    {
        $this->{timestamp} = $timestamp;
    }

    return $this->{timestamp};
}

sub captionts {
    my ($this, $captionts) = @_;

    if (defined $captionts)
    {
        confess "captionts is not a TJWH::TimeBits" unless blessed $captionts and $captionts->isa('TJWH::TimeBits');

        $this->{captionts} = $captionts;
    }

    return $this->{captionts};
}


sub addActive {
    my ($this) = @_;

    confess "No active table" unless $this->active;

    $this->addTable($this->active);
    $this->{active} = undef;

    return $this;
}

sub addTable {
    my ($this, @tables) = @_;

    foreach my $table (@tables)
    {
        confess "table ($table) is not a TJWH::Table" unless ref $table eq "TJWH::Table";
        push @{ $this->{tables} }, $table;
    }

    return @{ $this->{tables} };
}

sub addRow {
    my ($this, $line) = @_;
    return if $line =~ m/^\s*$/;
    return unless $this->active;

    my @row = ();
    foreach my $width ($this->columnWidths)
    {
        my $limit = length $line;
        last if $limit == 0;
        $width = $limit if $width > $limit;
        my $currentData = substr $line, 0, $width;
        if (length $line > $width)
        {
            $line = substr $line, $width + 1;
        } else {
            $line = "";
        }
        confess "currentData is not defined" unless defined $currentData;
        push @row, stripWhitespace $currentData;
    }
    # If there is data left over on this line, append it to the last column
    $row[$#row] .= $line if $line;

    $this->active->appendRow(@row);

    return $this;
}

sub parse
{
    my ($this) = @_;
    confess "filename or fh is not defined" unless defined $this->filename or defined $this->fh;

    my $fh = $this->fh;
    unless ($fh)
    {
        confess "No filename has been set\n" unless defined $this->filename;
        $fh = openFile($this->filename);
        return unless $fh;
    }

    # Any extra identifying information
    my $captionSuffix = "";
    $captionSuffix .= " :".(basename $this->filename) if $this->usebase;
    $captionSuffix .= " :".(dirname $this->filename) if $this->usedir;
    $captionSuffix .= " :".($this->filename) if $this->fullname;

    # Pull multiple lines at the start
    my $earliest = <$fh>;
    unless ($earliest) {
        $this->{active} = undef;
        return;
    }
    chomp $earliest;
    if ($earliest =~ m/\r$/)
    {
        die "DOS file detected - consider running:\ndos2unix $this->{filename}\n";
    }

    $this->latest($earliest);
    my $previous = <$fh>;
    unless ($previous)
    {
        $this->{active} = undef;
        return;
    }
    chomp $previous;
    $this->latest($previous);
    while (my $line = <$fh>)
    {
        chomp $line;
        # Automatically set the caption for the table
        if (defined $this->cmatch and $line =~ $this->cmatch)
        {
            $this->caption($line.$captionSuffix);
        }
        if (defined $this->prematch and $line =~ $this->prematch)
        {
            $this->caption($previous.$captionSuffix);
        }

        $this->latest($line);
        if ($line =~ m/^[-]+[ -]*$/)
        {
            # Occassionally we get dash separators in the middle of a table, so
            # only set headings if we are currently NOT building a table
            if ($this->active)
            {
                # We still want a row in the table - add an empty row
                $this->active->appendRow($this->active->emptyRow);
            }
            else
            {
                $this->separator($line); # The dashes represent the separator of headings from actual data
                $this->headings($earliest, $previous); # The previous lines have the headings
            }
        }
        elsif ($line =~ m/^$/)
        {
            $this->addActive($this->active) if $this->active;
        }
        else
        {
            $this->addRow($line);
        }
        $earliest = $previous;
        $previous = $line;
    }
    close $fh unless $this->fh;
    $this->addActive($this->active) if $this->active;

    return $this;
}

1;
