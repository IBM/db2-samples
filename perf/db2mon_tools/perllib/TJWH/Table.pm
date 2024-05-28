# -*- cperl -*-
#
# Perl-based table object
#
# It provides
#  - rows
#  - variable numbers of columns per row
#  - optional headers
#
# Various output methods

use strict;
use warnings;
use utf8;
binmode( STDOUT, 'utf8:' );     # Allow output of UTF8 to STDOUT

use File::Temp;
use TJWH::Basic qw(isaNumber);
use TJWH::BasicStats;
use TJWH::Formats;
use TJWH::TablePlot;

package TJWH::Table;
require Exporter;
use TJWH::TimeBits qw(subtractTimestamps);
use Storable qw(nstore dclone);
use Carp qw(cluck confess);
use Scalar::Util qw(blessed);
use Data::Dumper;

use IXF::File;
use IXF::FileRaw;

use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(
                   readTableFromCSV
                   readTableFromIXF
                   readTableFromFile
                   coalesceTables
              ); # symbols to be exported always
@EXPORT_OK = qw(
                   sortNumericalSuffix
                   $debug
                   $verbose
                   $noValue
              ); # symbols to be exported on demand
use TJWH::Basic;

my $alwaysInteger = [
                     qw(
                           LONG_OBJECT_L_PAGES
                           XDA_OBJECT_L_PAGES
                           DATA_SHARING_REMOTE_LOCKWAIT_COUNT
                           DATA_SHARING_REMOTE_LOCKWAIT_TIME
                           COL_OBJECT_L_PAGES
                      )];

our $noValue = "N/A";
our $debug;
our $verbose;

sub new
{
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    # Soak up the arguments into the object
    my $this =
    {
     'headers'    => [],     # Array of headers (array of TJWH::Format objects)
     'data'       => [],     # Actual data
     'caption'    => "",     # Title of table
     'maxCols'    => 0,      # Number of columns detected
     'type'       => "text", # Output type
     'output'     => undef,  # Output filename for any table
     'short'      => undef,  # Some operations (like group) create long captions.
     'first'      => undef,  # Only print the first N rows
     'multi'      => undef,  # If defined, headers may span multiple lines
     'xrange'     => undef,  # X min:max
     'xmin'       => undef,  # Minimum x value
     'xmax'       => undef,  # Maximum x value
     'yrange'     => undef,  # Y min:max
     'ymin'       => undef,  # Minimum y value
     'ymax'       => undef,  # Maximum y value
     'attributes' => "",     # Extra table attributes applied for Wiki formats
     'autolimit'  => 100,    # Number of rows to examine for autoformat
     'info'       => {},     # Arbitrary extra information for internal use
    };

    # Bless this and get on with it!
    bless $this, $class;
    return $this;
}

sub headers
{
    my ($this) = @_;

    # Check the headers all have values
    foreach my $header (@{ $this->{headers} })
    {
       cluck "Undefined header in ".Dumper $this->{headers}."\n" unless defined $header;
    }

    return @{ $this->{headers} };
}

# Return an array of references to the row arrays
sub rows
{
    my ($this) = @_;

    return @{ $this->{data} };
}

# Return an array of references to the row arrays to be displayed
sub visibleRows
{
    my ($this) = @_;

    # If no limits have been set, show the entire row set
    return @{ $this->{data} } unless defined $this->first;

    my $maxRow = scalar @{ $this->{data} };
    # If the table is smaller than the limit, show everything
    if ($maxRow < $this->first)
    {
        return @{ $this->{data} };
    }
    # Otherwise return a slice
    else
    {
        return @{ $this->{data} }[0 .. ($this->first - 1)];
    }
    return;
}

sub caption
{
    my ($this, $caption) = @_;
    if (defined $caption)
    {
        $this->{caption} = $caption;
    }
    return $this->{caption};
}

sub output
{
    my ($this, $output) = @_;
    if (defined $output)
    {
        $this->{output} = $output;
    }
    return $this->{output};
}

sub short {
    my ($this, $short) = @_;

    if (defined $short)
    {
        $this->{short} = $short;
    }

    return $this->{short};
}

sub multi {
    my ($this, $multi) = @_;

    if (defined $multi)
    {
        $this->{multi} = $multi;
    }

    return $this->{multi};
}

sub type
{
    my ($this, $type) = @_;

    if (defined $type)
    {
        if (isValidType($type))
        {
            $this->{type} = $type;
        }
        else
        {
            cluck "Unknown type for table output: $type\n";
        }
    }
    return $this->{type};
}

sub xrange {
    my ($this, $xrange) = @_;

    if (defined $xrange)
    {
        $this->{xrange} = $xrange; # info only
        return unless $xrange =~ m/:/;
        my ($xmin, $xmax) = split /\s*:\s*/, $xrange;
        $this->xmin($xmin) if isaNumber($xmin);
        $this->xmax($xmax) if isaNumber($xmax);
    }

    return $this->{xrange};
}

sub yrange {
    my ($this, $yrange) = @_;

    if (defined $yrange)
    {
        $this->{yrange} = $yrange; # info only
        return unless $yrange =~ m/:/;
        my ($ymin, $ymax) = split /\s*:\s*/, $yrange;
        $this->ymin($ymin) if isaNumber($ymin);
        $this->ymax($ymax) if isaNumber($ymax);
    }

    return $this->{yrange};
}

sub xmin {
    my ($this, $xmin) = @_;

    if (defined $xmin)
    {
        $this->{xmin} = $xmin;
    }

    return $this->{xmin};
}

sub xmax {
    my ($this, $xmax) = @_;

    if (defined $xmax)
    {
        $this->{xmax} = $xmax;
    }

    return $this->{xmax};
}

sub ymin {
    my ($this, $ymin) = @_;

    if (defined $ymin)
    {
        $this->{ymin} = $ymin;
    }

    return $this->{ymin};
}

sub ymax {
    my ($this, $ymax) = @_;

    if (defined $ymax)
    {
        $this->{ymax} = $ymax;
    }

    return $this->{ymax};
}

sub first {
    my ($this, $first) = @_;

    if (defined $first)
    {
        confess "first ($first) does not match \\d" unless $first =~ m/^\d+$/;
        confess "first ($first) must be greater than zero" unless $first > 0;
        $this->{first} = $first;
    }

    return $this->{first};
}

sub autolimit {
    my ($this, $autolimit) = @_;

    if (defined $autolimit)
    {
        confess "autolimit ($autolimit) is not a number" unless isaNumber($autolimit);
        $this->{autolimit} = $autolimit;
    }

    return $this->{autolimit};
}


sub attributes {
    my ($this, $attributes) = @_;

    if (defined $attributes)
    {
        # To avoid repeating attributes, we consume the line
        my %attrHash;
        while (length $attributes > 0)
        {
            # Strip leading whitespace
            $attributes =~ s/^\s+//g;
            # If this is a table class declaration, lose it
            if ($attributes =~ m/^class=("wiki[^"]+")\s*/)
            {
                $attributes =~ s/^class=("wiki[^"]+")\s*//g;
            }
            elsif ($attributes =~ m/^(\S+)=("[^"]+")\s*/)
            {
                $attrHash{$1} = $2;
                $attributes =~ s/^(\S+)=("[^"]+")\s*//g;
            }
            elsif ($attributes =~ m/^(\S+)=('[^']+')\s*/)
            {
                $attrHash{$1} = $2;
                $attributes =~ s/^(\S+)=('[^']+')\s*//g;
            }
            elsif ($attributes =~ m/^(\S+)=(\S+)\s*/)
            {
                $attrHash{$1} = $2;
                $attributes =~ s/^(\S+)=(\S+)\s*//;
            }
            elsif ($attributes =~ m/^(\S+)\s*/)
            {
                $attrHash{$1} = undef;
                $attributes =~ s/^(\S+)\s*//g;
            }
            else
            {
                print "Warnining:Didn't understand remaining attributes: $attributes\n";
                $attributes="";
            }
        }

        foreach my $key (keys %attrHash)
        {
            if (defined $attrHash{$key})
            {
                $attributes .= " $key=$attrHash{$key}";
            }
            else
            {
                $attributes .= " $key";
            }
        }

        $this->{attributes} = $attributes;
    }

    return $this->{attributes};
}

# Provide a mechanism to hang extra internal data on the table.
sub info
{
    my ($this, $hash) = @_;

    if (defined $hash)
    {
        confess "hash ($hash) is not a HASH" unless ref $hash eq "HASH";
        foreach my $key (keys %{ $hash })
        {
            $this->{info}->{$key} = $hash->{$key};
        }
    }

    return $this->{info};
}

# ------------------------------------------------------------------------
# Column methods
#
#
# Add new column names with default formatting to the existing headers
sub columnNames
{
    my ($this, @rest) = @_;
    my @headers = ();
    if (@rest)
    {
        foreach my $name (@rest)
        {
            my $format = new TJWH::Formats;
            $format->name($name);
            push @{ $this->{headers} }, $format;
        }
    }
    # Update the number of columns
    $this->{maxCols} = scalar @{ $this->{headers} } ;

    return map { $_->name } @{ $this->{headers} };
}

sub columnName
{
    my ($this, $index, $name) = @_;
    confess "Index is not defined\n" unless defined $index;
    $index = $this->getColumnIndex($index);
    confess "Index $index is out of range: 0 - ", $this->numberOfHeaders,"\n"
        unless $index >= 0 and $index < $this->numberOfHeaders;

    if ($name)
    {
        unless ( @{ $this->{headers} }[$index] )
        {
            my $format = new TJWH::Formats;
            $format->name($name);
            @{ $this->{headers} }[$index] = $format;
        }
        @{ $this->{headers} }[$index]->name($name);
    }

    return @{ $this->{headers} }[$index]->name;
}

# Set the column names with default formatting to this list
sub resetColumnNames
{
    my ($this, @rest) = @_;
    $this->{headers} = [];
    return $this->columnNames(@rest);
}

# Get the TJWH::format object for this column
sub tjwhFormat
{
    my ($this, $index) = @_;
    confess "Index is not defined\n" unless defined $index;
    $index = $this->getColumnIndex($index);

    return @{ $this->{headers} }[$index];
}

# Get/Set the column format using the familiar printf style. Only a subset of
# formats are supported. All others will die horribly. The default format is
# numerical.
sub columnFormats
{
    my ($this, @rest) = @_;
    if (scalar @rest > 0)
    {
        for (my $count = 0; $count <= $#rest; $count++)
        {
            $this->columnFormat($count, $rest[$count]);
        }
    }
    return map { $_->formatData } $this->headers ;
}

sub columnFormat
{
    my ($this, $index, $format) = @_;
    confess "Index is not defined\n" unless defined $index;
    $index = $this->getColumnIndex($index);

    my $formatRef = $this->tjwhFormat($index);
    return unless defined $formatRef;
    if (defined $format)
    {
        $formatRef->formatData($format);
    }

    return $formatRef->formatData;
}

sub columnSubstrings
{
    my ($this, @rest) = @_;
    if (scalar @rest > 0)
    {
        for (my $count = 0; $count <= $#rest; $count++)
        {
            $this->columnSubstring($count, $rest[$count]);
        }
    }
    return map { $_->substring } $this->headers ;
}

sub columnSubstring
{
    my ($this, $index, $substring) = @_;
    my $formatRef = $this->tjwhFormat($index);
    if (defined $substring)
    {
        $formatRef->substring($substring);
    }

    return $formatRef->substring;
}

# Get/Set the column width in characters. Does not affect other formatting.
sub columnWidth
{
    my ($this, $index, $width) = @_;
    my $formatRef = $this->tjwhFormat($index);
    if (defined $width)
    {
        confess "Width must be an integer: $width" unless $width =~ m/^[-+]?\d+/;
        $formatRef->width($width);
    }
    return $formatRef->width;
}

# Find the widest value in this column and set the width to it.
sub columnWidthAuto
{
    my ($this, $index) = @_;
    my $formatRef = $this->tjwhFormat($index);
    my $originalWidth = $formatRef->width;
    my $sign = 1;
    print "Entry Format code for column $index ".
        $this->columnName($index).": ".$formatRef->formatData."\n" if $debug;

    # Remember whether we are left or right justified
    $sign = -1 if $formatRef->{width} < 0;

    # With a zero width, sprintf prints out the shortest possible representation
    $formatRef->width(0);

    # Start with the header and work through all the values in the column.
    my $maximumWidth = $this->minimumColumnWidth($index);
    print "Widest column header $index: $maximumWidth\n" if $debug;
    my @values = $this->getColumn($index);
    my $first;
    foreach my $value (@values)
    {
        print "Testing $value\n" if defined $debug and $debug > 1;
        my $result = $noValue;
        if (defined $value and $value ne $noValue)
        {
            no warnings;
            $result = sprintf $formatRef->formatData, $value;
            # For this debug to have validity, it must match the numeric
            # checks in autoFormat
            if ($debug and
                $formatRef->formatData !~ /%\d*s/ and
                $value !~ m/^[+-]?\d+(\.\d+)?([eE][-+]?\d+)?$/)
            {
                cluck "Type mismatch from sprintf\n";
                $this->dumpTable;
            }
        }
        if (length $result > $maximumWidth)
        {
            $maximumWidth = length $result;
        }
    }
    print "Widest column after values $index: $maximumWidth\n" if $debug;
    # If the column has substring set AND the maximum width is less than the
    # original width, it's okay to shrink it
    if ($formatRef->substring)
    {
        if ($maximumWidth < abs($originalWidth))
        {
            $formatRef->width($sign * $maximumWidth);
        }
        else
        {
            $formatRef->width($originalWidth);
        }
    }
    else
    {
        $formatRef->width($sign * $maximumWidth);
    }
    return $formatRef->width;
}

# Find the thinest column width based on the header name alone
sub minimumColumnWidth {
    my ($this, $index) = @_;

    if ($this->multi) {
        return length longestWord($this->tjwhFormat($index)->name);
    } else {
        return length sprintf "%s", $this->tjwhFormat($index)->name;
    }
}

# Get/Set the column scale in characters. Whole number (integer) formats will convert to
# decimal formats if scale is set > 0. Hex or Octal formats will refuse to set scale non-zero.
sub columnScale
{
    my ($this, $index, $scale) = @_;
    my $formatRef = $this->tjwhFormat($index);
    if (defined $scale)
    {
        confess "Width must be positive integer: $scale" unless $scale =~ m/^[+]?\d+/ and $scale > 0;
        $formatRef->scale($scale);
        if ($scale > 0) {
            if ($formatRef->{number} =~ m/^[diu]$/)
            {
                $formatRef->{number} = "f";
            } elsif ($formatRef->{number} =~ m/^[ox]$/i) {
                cluck "Can't set octal or hex representations to non-zero scale $scale\n";
                $formatRef->scale(0);
            }
        }
    }
    return $formatRef->scale;
}

# Number of columns can be greater than the number of headers
sub numberOfColumns
{
    my ($this) = @_;
    if ($this->{maxCols} < $this->numberOfHeaders)
    {
        $this->{maxCols} = $this->numberOfHeaders;
    }
    return $this->{maxCols};
}

sub numberOfHeaders
{
    my ($this) = @_;
    return scalar $this->headers;
}

sub numberOfRows
{
    my ($this) = @_;

    return scalar @{ $this->{data} };
}

# Just get the numbers for this column
sub getNumbersForColumn
{
    my ($this, $colIndex) = @_;
    $colIndex = $this->getColumnIndex($colIndex);
    return unless defined $colIndex;

    my @column = ();
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex]
            and @{$row}[$colIndex] =~ m/^\s*[-+]?\d+\.?\d*([eE][-+]?\d+)?\s*$/)
        {
            push @column, @{$row}[$colIndex];
        }
    }

    return @column;
}

# Just get the numbers and NULLS for this column.
# Convert N/A, <null>, NULL, etc to undef
# Example usage in TJWH::TablePlot::generateDataSet
sub getNumeric
{
    my ($this, $colIndex) = @_;
    $colIndex = $this->getColumnIndex($colIndex);
    return unless defined $colIndex;

    my @column = ();
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex] )
        {
            if (@{$row}[$colIndex] =~ m/^\s*[-+]?\d+\.?\d*([eE][-+]?\d+)?\s*$/)
            {
                push @column, @{$row}[$colIndex];
            }
            elsif (@{$row}[$colIndex] eq $noValue)
            {
                push @column, undef;
            }
            elsif (@{$row}[$colIndex] =~ m!^<?null>?$!i)
            {
                push @column, undef;
            }
            else {
                print "Skipping string @{$row}[$colIndex] in column $colIndex\n" if $debug;
            }
        }
        else
        {
            push @column, undef;
        }
    }

    return @column;
}

# Get numbers based on column name
sub getNumbersForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    return $this->getNumbersForColumn($colIndex) if defined $colIndex;
    return;
}

sub describe {
    my ($this) = @_;

    my $describe = new TJWH::Table;
    $describe->columnNames("Heading", "Format");
    $describe->columnFormats("%-8s", "%-8s");
    foreach my $header ($this->headers)
    {
        $describe->appendRow($header->name, $header->formatData);
    }
    $describe->autoWidth;

    return $describe;
}

# ------------------------------------------------------------------------
# Row methods

# Ensure that every row has the same number of columns
sub padRows
{
    my ($this) = @_;

    for (my $index = 0; $index < $this->numberOfRows; $index++)
    {
        my $addColumns = $this->{maxCols} - scalar @{ $this->{data}->[$index] };
        for (my $add = 0; $add < $addColumns; $add++)
        {
            push @{ $this->{data}->[$index] }, undef;
        }
    }

    return $this;
}

# ------------------------------------------------------------------------
# Wipe the slate clean
sub blankData
{
    my ($this) = @_;
    $this->{headers} = [];
    $this->{data} = [];
    $this->{maxCols} = 0;
    return;
}

# Find out which column(s) a given header represents
sub getIndexForHeader
{
    my ($this, $header) = @_;

    my @matchingIndexes = ();
    my @headers = $this->columnNames;
    if (scalar @headers > 0)
    {
        @matchingIndexes = grep { $headers[$_] eq $header } 0 .. $#headers;
        if (defined $debug)
        {
            cluck "Warning: multiple headers match $header\n  ",
                (join ", ", @matchingIndexes),
                    "\n" unless scalar @matchingIndexes <= 1;
        }
    }

    cluck "No headers match $header in :\n  ".(join "\n  ", @headers)."\n" unless scalar @matchingIndexes > 0;
    return shift @matchingIndexes;
}

# getIndexForHeader is a "noisy" subroutine - it complains if you give it
# junk. Most of the time that is what you need. However, if you are working
# with row hashes, tables with automatically added columns and other such
# dynamic constructs, you may need to quietly check whether you already have a
# column for your data.
sub existsColumnName
{
    my ($this, $column) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;
    if ($column =~ m/^\d+$/) {
        if ($column >= 0 and $column < $this->numberOfHeaders)
        {
            return 1;
        }
    } else {
        my $columnLookup;
        map {$columnLookup->{$this->columnName($_)} = $_} 0 .. $#{ $this->{headers} };
        return defined $columnLookup->{$column} ? 1 : 0;
    }
}

# Useful routine for taking column index or header and returning the index, if valid
sub getColumnIndex
{
    my ($this, $column) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;

    my $columnIndex;
    if ($column =~ m/^[0-9]+$/)
    {
        $this->{maxCols} = $this->numberOfHeaders unless $this->{maxCols};
        if ($column >= 0 and $column < $this->{maxCols})
        {
            $columnIndex = $column;
        }
        else
        {
            cluck "getColumnIndex: index $column is out of range\n";
            print Data::Dumper::Dumper $this;
        }
    }
    else
    {
        $columnIndex = $this->getIndexForHeader($column);
    }
    confess "No column index found for $column" unless defined $columnIndex;
    return $columnIndex;
}

# Find matching headers
sub getMatchingHeaders
{
    my ($this, $match) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "match is not defined\n" unless defined $match;

    return grep { $_ =~ m/$match/ } $this->columnNames;
}

# Find exact match of column name
sub getHeader
{
    my ($this, $match) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "match is not defined\n" unless defined $match;

    return grep { $_ eq $match } $this->columnNames;
}

# Return the N-th column of data (starting from zero)) or column matching the
# given name. If the column is not defined for every row then only the subset
# which are defined are returned.
sub getColumn
{
    my ($this, $column) = @_;
    confess "this is not defined\n" unless defined $this;
    confess "column is not defined\n" unless defined $column;
    my @column = ();

    my $colIndex = $this->getColumnIndex($column);
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex])
        {
            push @column, @{$row}[$colIndex];
        }
    }
    return @column;
}

# Return the unique values for the N-th column of data (starting from zero) or
# column matching the given name.
sub getColumnUnique
{
    my ($this, $column) = @_;
    my %unique;
    map { $unique{$_}++ } $this->getColumn($column);

    return sort keys %unique;
}

# Return the N-th column of data (starting from zero) as references to the
# actual data. If the column is not defined for every row then only the subset
# which are defined are returned.
sub getColumnReferences
{
    my ($this, $colIndex) = @_;
    my @column = ();
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex])
        {
            push @column, \@{$row}[$colIndex];
        }
    }
    return @column;
}

# Append a row to the set
sub appendRow
{
    my ($this, @rest) = @_;

    cluck "Empty row being added\n" unless @rest;

    # If the new row does not cover all the defined columns, add undef entries to the remaining columns
    my $padColumns = $this->{maxCols} - scalar @rest;
    while ($padColumns > 0)
    {
        push @rest, undef;
        $padColumns--;
    }

    push @{ $this->{data} }, [ @rest ];

    # Ensure that we always have a formatter for new columns, even if we don't
    # have a proper name.
    while (scalar @{ $this->{headers} } < scalar @rest)
    {
        $this->columnNames("-");
    }
    return $this->{data};
}

# Glue the rows from an other table onto the end of this one
sub appendTable
{
    my ($this, $other) = @_;

    if (areArraysEqual([$this->columnNames],
                       [$other->columnNames]))
    {
        push @{ $this->{data} }, @{ $other->{data} };
    }
    else
    {
        confess "Incompatible tables this=$this and other=$other\n".
            "This:$this ".$this->caption." columns:\n  ".(join "\n  ", $this->columnNames).
                "\nOther:$other ".$other->caption." columns:\n  ".(join "\n  ", $other->columnNames)."\n";
    }

    # Ensure we keep maxCols up to date
    $this->{maxCols} = $other->{maxCols} if $this->{maxCols} < $other->{maxCols};

    return $this;
}

# Prepend a row to the set
sub prependRow
{
    my ($this, @rest) = @_;

    cluck "Empty row being added at start\n" unless @rest;
    unshift @{ $this->{data} }, [ @rest ];

    if (scalar @rest > $this->{maxCols})
    {
        $this->{maxCols} = scalar @rest;
    }
    # Ensure that we always have a formatter for new columns, even if we don't
    # have a proper name.
    while (scalar @{ $this->{headers} } < $this->{maxCols})
    {
        $this->columnNames("-");
    }
    return $this->{data};
}

# Some times you want the data in a more flexible structure than an
# array. This maps a row hash where the keys are column names back to the base
# row and appends it to the table. Unrecognized column names are dropped.
sub appendRowHash
{
    my ($this, $hashRef) = @_;
    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';
    return $this->appendRow($this->convertHashToRow($hashRef));
}

# This will add columns as needed to the table before appending the row hash
sub appendRowHashAddCol
{
    my ($this, $hashRef) = @_;
    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';
    return $this->appendRow($this->convertHashToRow($hashRef));
}

sub prependRowHash
{
    my ($this, $hashRef) = @_;
    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';
    return $this->prependRow($this->convertHashToRow($hashRef));
}

# It's often useful to provide totals for columns at the end of tables
sub addTotalRow
{
    my ($this) = @_;
    my @formats = $this->headers;
    my @totals = map { $formats[$_]->isNumber ?
                           $this->sumForColumn($_) :
                               "Total"
                           }  0 .. $#formats;
    $this->appendRow(map { ($_->isNumber) ?
                               0 : "----" } @formats);
    $this->appendRow(@totals);

    return;
}

# Return the N-th row of the data (starting from zero) as an array.
sub getRow
{
    my ($this, $rowIndex) = @_;
    confess "Row index is not defined\n" unless defined $rowIndex;
    confess "Row index $rowIndex must be a valid integer\n"
        unless $rowIndex =~ m/^\d+$/;
    confess "Row index $rowIndex is outside the range  0 .. ".($#{ $this->{data} })."\n"
        unless ($rowIndex >= 0 and $rowIndex <= $#{ $this->{data} });

    return @{ @{ $this->{data} }[$rowIndex] };
}

# Return the N-th row of the data (starting from zero) as a reference to a
# hash where each column name is a key.
sub getRowHash
{
    my ($this, $rowIndex) = @_;
    confess "Row index is not defined\n" unless defined $rowIndex;
    confess "Row index $rowIndex must be a valid integer\n"
        unless $rowIndex =~ m/^\d+$/;
    confess "Row index $rowIndex is outside the range  0 .. ".($#{ $this->{data} })."\n"
        unless ($rowIndex >= 0 and $rowIndex <= $#{ $this->{data} });

    my @row = $this->getRow($rowIndex);
    my @names = $this->columnNames;

    cluck "Row has more entries compared to the column names:\n".
        "Number of row entries: ".(scalar @row)."\n".
        "Number of column names: ".(scalar @names)."\n".
        "=> Column names:\n  ".(join "\n  ", @names)."\n".
        "=> Row entries: \n  ".(join "\n  ", @row)."\n"
        unless scalar @row <= scalar @names;

    my $hashRef;
    while (scalar @names)
    {
        $hashRef->{shift @names} = shift @row;
    }

    return $hashRef;
}

# Convert a hash where the keys are column names to a row format (all keys
# must map);
sub convertHashToRowStrict
{
    my ($this, $hashRef) = @_;
    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';

    my @row = ();
    foreach my $colName ($this->columnNames)
    {
        confess "No entry for $colName\n" unless exists $hashRef->{$colName};
        push @row, $hashRef->{$colName};
    }
    return @row;
}

# Convert a hash where the keys are column names to a row format (not all
# values need be filled in)
sub convertHashToRow
{
    my ($this, $hashRef) = @_;
    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';

    my @row = ();
    foreach my $colName ($this->columnNames)
    {
        print "No entry for $colName\n" if defined $debug and not defined $hashRef->{$colName};
        push @row, defined $hashRef->{$colName} ?
            $hashRef->{$colName} : $noValue;
    }
    return @row;
}

sub convertHashToRowAddCol
{
    my ($this, $hashRef) = @_;
    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';

    # First check the columns to see if we have any new entries - add columns
    # for those and then go strict
    foreach my $key (keys %$hashRef)
    {
        unless ($this->existsColumnName($key))
        {
            $this->appendColumnCalculate($key, "%-4s", sub { return undef });
        }
    }

    return convertHashToRowStrict($hashRef);
}

# Just get a hash with the column names filled in, but no values
sub getEmptyRowHash
{
    my ($this) = @_;

    my $hashRef;
    foreach my $name ($this->columnNames)
    {
        $hashRef->{$name} = undef;
    }

    return $hashRef;
}

# Alter the contents of the N-th row
sub updateRow
{
    my ($this, $rowIndex, @rest) = @_;
    confess "Row index is not defined\n" unless defined $rowIndex;
    confess "Row index $rowIndex must be a valid integer\n"
        unless $rowIndex =~ m/^\d+$/;
    confess "Row index $rowIndex is outside the range\n"
        unless ($rowIndex >= 0 and $rowIndex <= $#{ $this->{data} });

    cluck "Row is being updated with empty data\n" unless @rest;
    @{ $this->{data} }[$rowIndex] = [ @rest ];

    if (scalar @rest > $this->{maxCols})
    {
        $this->{maxCols} = scalar @rest;
    }
    # Ensure that we always have a formatter for new columns, even if we don't
    # have a proper name.
    while (scalar @{ $this->{headers} } < $this->{maxCols})
    {
        $this->columnNames("-");
    }

    return @{ $this->{data} }[$rowIndex];
}

# Alter the contents of the N-th row using a hash
sub updateRowHash
{
    my ($this, $rowIndex, $hashRef) = @_;
    confess "Row index is not defined\n" unless defined $rowIndex;
    confess "Row index $rowIndex must be a valid integer\n"
        unless $rowIndex =~ m/^\d+$/;
    confess "Row index $rowIndex is outside the range\n"
        unless ($rowIndex >= 0 and $rowIndex <= $#{ $this->{data} });

    confess "hashRef is not defined\n" unless defined $hashRef;
    confess "hashRef must have type 'HASH': has ".ref $hashRef."\n" unless ref $hashRef eq 'HASH';
    return $this->updateRow($rowIndex, $this->convertHashToRow($hashRef));
}

# Delete a row (zero indexed)
sub deleteRow
{
    my ($this, $rowIndex, $numberOfRows) = @_;
    confess "Row index is not defined\n" unless defined $rowIndex;
    confess "Row index $rowIndex must be a valid integer\n"
        unless $rowIndex =~ m/^\d+$/;
    confess "Row index $rowIndex is outside the range\n"
        unless ($rowIndex >= 0 and $rowIndex <= $#{ $this->{data} });
    $numberOfRows = 1 unless defined $numberOfRows;
    confess "Number of rows must be an integer\n" unless $numberOfRows =~ m/^\d+$/;

    # Remove the entry (which is an ARRAY ref) and update the data member.
    my @rows = $this->rows;
    my @deleted = splice @rows, $rowIndex, $numberOfRows;
    $this->{data} = [ @rows ];
    return @deleted;
}

sub truncateTable {
    my ($this, $numberOfRows) = @_;
    confess "this is not defined" unless defined $this;
    confess "numberOfRows is not defined" unless defined $numberOfRows;
    confess "numberOfRows does not match \\d+" unless $numberOfRows =~ m/^\d+$/;
    return $this if $numberOfRows > $#{ $this->{data} };
    confess "Row index $numberOfRows is outside the range 1..$#{ $this->{data} }\n"
        unless ($numberOfRows >= 1 and $numberOfRows <= $#{ $this->{data} });

    my @rows = $this->rows;
    $this->{data} = [ @rows[ 0 .. $numberOfRows - 1 ] ];
    return $this;
}

# Delete all rows
sub deleteAllRows
{
    my ($this) = @_;
    $this->{data} = [ ];
    return $this;
}

# Pick a subset of rows from the data, leaving $length entries
sub subset
{
    my ($this, $offset, $length) = @_;
    print "Selecting $offset, $length from dataset\n" if $debug;

    my @dataSet = @{ $this->{data} };
    return unless @dataSet;     # no data, no need to take a slice

    confess "Offset must be within the range 0 .. ".(scalar @dataSet - 1)."\n"
        unless $offset >=0 and $offset < scalar @dataSet;
    confess "Length must be positive\n" unless $length >=0;

    if ($length + $offset > scalar @dataSet)
    {
        $length = scalar @dataSet - $offset;
    }

    $this->{data} = [ @dataSet[$offset .. ($offset + $length - 1)] ];
    if (scalar @{ $this->{data} } != $length)
    {
        print "Expected to get $length rows\n";
        print "Actually got ".(scalar @{ $this->{data} })." rows\n";
        confess "Returned bad data";
    }

    return;
}

# Reverse the order of rows.
sub reverseRows
{
    my ($this) = @_;
    $this->{data} = [ reverse @{ $this->{data} } ];
    return;
}

# ------------------------------------------------------------------------
#
# Arithmetic on columns
#
sub addToColumn
{
    my ($this, $colIndex, $add) = @_;
    $colIndex = $this->getColumnIndex($colIndex);

    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex]
            and @{$row}[$colIndex] =~ m/^\s*[-+]?\d+\.?\d*([eE][-+]?\d+)?\s*$/)
        {
            @{$row}[$colIndex] += $add;
        }
    }
    return;
}

sub multiplyColumn
{
    my ($this, $colIndex, $multiply) = @_;
    $colIndex = $this->getColumnIndex($colIndex);

    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex]
            and @{$row}[$colIndex] =~ m/^\s*[-+]?\d+\.?\d*([eE][-+]?\d+)?\s*$/)
        {
            @{$row}[$colIndex] *= $multiply;
        }
    }
    return;
}

sub divideColumn
{
    my ($this, $colIndex, $divide) = @_;
    $colIndex = $this->getColumnIndex($colIndex);

    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex]
            and @{$row}[$colIndex] =~ m/^\s*[-+]?\d+\.?\d*([eE][-+]?\d+)?\s*$/)
        {
            @{$row}[$colIndex] /= $divide;
        }
    }
    return;
}

# ------------------------------------------------------------------------
#
# Arithmetic between columns
#
# This routine requires two tables with the same column names for the column
# to be joined and the column to be subtracted
sub subtractColumn
{
    my ($this, $other, $joinColumn, $subtractColumn, $subtractFormat) = @_;
    $subtractFormat = "%8d" unless defined $subtractFormat;

    my $join = $this->joinTable($other,
                                $joinColumn,
                                $joinColumn,
                                "Current ",
                                "Subtract ");
    my $insertColumn =
        $join->insertColumnCalculate
            ($join->numberOfColumns,
             "Difference", $subtractFormat,
             sub {
                 my ($rowHash) = @_;
                 return
                     $rowHash->{"Current $subtractColumn"} -
                         $rowHash->{"Subtract $subtractColumn"};
             }
            );

    return $join;
}

# ------------------------------------------------------------------------
#
# String manipulation on columns
#
sub regexpReplaceColumn
{
    my ($this, $column, $from, $to) = @_;
    confess "column is not defined\n" unless defined $column;
    confess "from is not defined\n" unless defined $from;
    confess "to is not defined\n" unless defined $to;

    my $colIndex = $this->getColumnIndex($column);
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex])
        {
            @{$row}[$colIndex] =~ s/$from/$to/g;
        }
    }

    return;
}

# Classic perl - pass me an arbitrary subroutine to alter each piece of data
# in this column
sub changeColumn
{
    my ($this, $column, $subRef) = @_;
    confess "column is not defined\n" unless defined $column;
    confess "subRef is not defined\n" unless defined $subRef;
    confess "subRef is not a subroutine\n" unless ref $subRef eq "CODE";

    my $colIndex = $this->getColumnIndex($column);
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex])
        {
            print "Before:  @{$row}[$colIndex]\n" if $debug;
            @{$row}[$colIndex] = &{ $subRef }(@{$row}[$colIndex]);
            print "After :  @{$row}[$colIndex]\n" if $debug;
        }
    }
    return;
}

# Expert version of changeColumn - first parameter is a hash reference to the
# current row data
sub changeColumnUsingRow
{
    my ($this, $column, $subRef) = @_;
    confess "column is not defined\n" unless defined $column;
    confess "subRef is not defined\n" unless defined $subRef;
    confess "subRef is not a subroutine\n" unless ref $subRef eq "CODE";

    my $colIndex = $this->getColumnIndex($column);
    my @names = $this->columnNames;

    foreach my $row (@{ $this->{data} } )
    {
        # We provide a rowHash so that the subroutine can access data in
        # other columns in the row
        my $rowHash;
        for (my $counter = 0; $counter < scalar @names; $counter ++)
        {
            $rowHash->{$names[$counter]} = @{$row}[$counter];
        }

        if (defined @{$row}[$colIndex])
        {
            print "Before:  @{$row}[$colIndex]\n" if $debug;
            @{$row}[$colIndex] = &{ $subRef }($rowHash, @{$row}[$colIndex]);
            print "After :  @{$row}[$colIndex]\n" if $debug;
        }
    }
    return;
}

# Subtract each row from the previous row. Great for monotonically increasing counters
sub differential
{
    my ($this, $column) = @_;

    my $colIndex = $this->getColumnIndex($column);
    my $previous;
    print "Column $column for ".$this->caption."\n" if $debug;
    foreach my $row (@{ $this->{data} } )
    {
        if (defined @{$row}[$colIndex])
        {
            if (defined $previous)
            {
                my $current = @{$row}[$colIndex];
                print "Current $current <-> Previous $previous\n" if $debug;
                @{$row}[$colIndex] = $current - $previous;
                $previous = $current;
            }
            else
            {
                $previous = @{$row}[$colIndex];
                @{$row}[$colIndex] = 0;
            }
            print "After :  @{$row}[$colIndex]\n" if $debug;
        }
    }

    return;
}

# Sort table given a column to sort on, smallest to largest, and an optional
# subroutine
sub sortTable
{   my ($this, $column, $sortSub) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");

    my $columnIndex = $this->getColumnIndex($column);
    confess "Column $column not recognized\n" unless defined $columnIndex;

    # Choose the sort based on the column type
    my $format = $this->tjwhFormat($columnIndex);
    my $sortMe;
    if (defined $sortSub)
    {
        confess "Bad sort subroutine type: ".(ref $sortSub)."\n" unless ref $sortSub eq "CODE";
        $sortMe = sub {
            my $aContent = $a->[$columnIndex];
            my $bContent = $b->[$columnIndex];
            return $sortSub->($aContent, $bContent);
        };
    }
    else
    {
        if ($format->isNumber)
        {
            $sortMe = sub {
                unless (defined $a->[$columnIndex]) {
                    return -1 if defined $b->[$columnIndex];
                    return 0;
                }
                unless (defined $b->[$columnIndex]) {
                    return 1;
                }
                return $a->[$columnIndex] <=> $b->[$columnIndex]
            };
        }
        else
        {
            $sortMe = sub {
                unless (defined $a->[$columnIndex]) {
                    return -1 if defined $b->[$columnIndex];
                    return 0;
                }
                unless (defined $b->[$columnIndex]) {
                    return 1;
                }
                return $a->[$columnIndex] cmp $b->[$columnIndex]
            };
        }
    }

    confess "sortMe is undefined\n" unless defined $sortMe;
    confess "Bad sort subroutine\n" unless ref $sortMe eq "CODE";

    my @rows = $this->rows;     # Array of array references
    $this->{data} = [ sort $sortMe @rows ];

    return $this;
}

# Convenience function to sort a table over multiple columns
sub sortColumns {
    my ($this, @sortColumns) = @_;

    foreach my $name (@sortColumns)
    {
        next unless $this->existsColumnName($name);
        $this->sortTable($name);
    }

    return $this;
}


# Sort table given a column to sort on, smallest to largest, trying to use any
# numeric prefix
sub sortTableNumericPrefix
{   my ($this, $column) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");

    my $columnIndex = $this->getColumnIndex($column);
    confess "Column $column not recognized\n" unless defined $columnIndex;

    my @rows = $this->rows;     # Array of array references
    $this->{data} =
        [ sort {
            my ($a, $b) = @_;
            my ($aPref, $bPref);
            if ($a =~ m/^\s*(\d+(\.\d+)?)/)
            {
                $aPref = $1;
            }
            if ($b =~ m/^\s*(\d+(\.\d+)?)/)
            {
                $bPref = $1;
            }
            if (defined $aPref and defined $bPref)
            {
                return $aPref <=> $bPref;
            } else {
                return $a cmp $b;
            }
        } @rows ];

    return $this;
}

# Sort table given a column to sort on, largest first
sub reverseSortTable
{
    my ($this, $column) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");

    my $columnIndex = $this->getColumnIndex($column);
    confess "Column $column not recognized\n" unless defined $columnIndex;

    # Choose the sort based on the column type
    my $format = $this->tjwhFormat($columnIndex);
    my $sortMe;
    if ($format->isNumber)
    {
        $sortMe = sub {
            unless (defined $a->[$columnIndex]) {
                return 1 if defined $b->[$columnIndex];
                return 0;
            }
            unless (defined $b->[$columnIndex]) {
                return -1;
            }
            return $b->[$columnIndex] <=> $a->[$columnIndex]
        };
    }
    else
    {
        $sortMe = sub {
            unless (defined $a->[$columnIndex]) {
                return 1 if defined $b->[$columnIndex];
                return 0;
            }
            unless (defined $b->[$columnIndex]) {
                return -1;
            }
            return $b->[$columnIndex] cmp $a->[$columnIndex]
        };
    }
    my @rows = $this->rows;
    $this->{data} = [ sort $sortMe @rows ];

    return $this;
}

sub sortNumericalSuffix
{
    # Sort routine for arrays of strings with trailing numbers (possibly with
    # filename extensions)
    my ($aPrefix,
        $bPrefix,
        $aNumber,
        $bNumber,
        $aSuffix,
        $bSuffix);

    if (not defined $_[0])
    {
        if (not defined $_[1])
        {
            return 0;
        }
        else
        {
            return -1;
        }
    }
    elsif (not defined $_[1])
    {
        return 1;
    }

    if ($_[0] =~ m/([^0-9]+)(\d+\.?\d*)([^0-9]+)?$/)
    {
        ($aPrefix, $aNumber, $aSuffix) = ($1, $2, $3);
        $aSuffix = "nothing" unless defined $aSuffix;
        print "A recognized: $aPrefix, $aNumber, $aSuffix\n" if $debug;
    }
    else
    {
        $aPrefix = $_[0];
        $aNumber = 0;
        $aSuffix = "";
        print "A not recognized: $aPrefix, $aNumber, $aSuffix\n" if $debug;
    }
    if ($_[1] =~ m/([^0-9]+)(\d+\.?\d*)([^0-9]+)?$/)
    {
        ($bPrefix, $bNumber, $bSuffix) = ($1, $2, $3);
        $bSuffix = "nothing" unless defined $bSuffix;
        print "B recognized: $bPrefix, $bNumber, $bSuffix\n" if $debug;
    }
    else
    {
        $bPrefix = $_[1];
        $bNumber = 0;
        $bSuffix = "";
        print "B not recognized: $bPrefix, $bNumber, $bSuffix\n" if $debug;
    }
    # Must have parentheses for this to work
    return
        ($aPrefix cmp $bPrefix or
         $aNumber <=> $bNumber or
         $aSuffix cmp $bSuffix or
         $_[0] cmp $_[1]);
}

sub sanity {
    my ($this, $sanity) = @_;

    if ($this->type =~ m/(fit)?org\d*/)
    {
        $this->sanityOrg;
    }

    return $this->{sanity};
}

# Remove any constructs that will break org tables
sub sanityOrg {
    my ($this) = @_;

    # In-place replace any pipe symbols
    for (my $rowIndex = 0; $rowIndex < $this->numberOfRows; $rowIndex++)
    {
        foreach my $value (@{ $this->{data}[$rowIndex] })
        {
            $value =~ s/[|][|]/_CONCAT_/g; # Replace SQL || concat operator
            $value =~ s/[|]/_PIPE_/g;
        }
    }

    return $this;
}

# ------------------------------------------------------------------------
#
# Insert column
#
# The data supplied will be inserted into all the rows starting
# from the first row. If there are still rows outstanding, then zero will be
# inserted into numeric columns and empty strings will be inserted into string columns.
sub insertColumn
{
    my ($this, $index, $name, $format, @data) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    confess "name is not defined\n" unless defined $name;
    confess "format is not defined\n" unless defined $format;

    # We have to be a little bit careful calling getColumnIndex blindly:
    # because we are inserting a column, we might have been given an index
    # that doesn't exist or is out of range.
    $index = $this->getColumnIndex($index) unless $index =~ m/^\d+$/;
    # Index must be numeric now
    confess "Bad index $index is not between 0 and ".
        $this->numberOfColumns."\n"
            unless $index >=0 and $index <= $this->numberOfColumns;

    # Sort out the header
    my $formatRef = new TJWH::Formats;
    $formatRef->name($name);
    $formatRef->formatData($format);
    splice @{ $this->{headers} }, $index, 0, $formatRef;

    # Now splice in the provided data.
    foreach my $row ($this->rows)
    {
        my $nextData = shift @data;
        unless (defined $nextData)
        {
            $nextData = 0;
            $nextData = "" if $format =~ m/s/;
        }
        splice @{$row}, $index, 0, $nextData;
    }
    # If we still have data left over, then we have to invent new rows
    while (@data)
    {
        my @row = ();
        for (my $i = 0; $i < $index - 1; $i++)
        {
            push @row, undef;
        }
        $this->appendRow(@row, shift @data);
    }

    # Remember to increase the number of data columns
    $this->{maxCols}++;

    return $this;
}

# Just like insertColumn, except here the index is calculated for you.
sub appendColumn
{
    my ($this, $name, $format, @data) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    confess "name is not defined\n" unless defined $name;
    confess "format is not defined\n" unless defined $format;

    return $this->insertColumn($this->numberOfHeaders, $name, $format, @data);
}

# Append a new column based on processing values in other columns
#
sub insertColumnCalculate
{
    my ($this, $index, $name, $format, $subRef, @extra) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    confess "Index must be numeric: $index\n" unless $index =~ m/^\d+$/;
    confess "Index must be between 0 and ".($this->numberOfHeaders)."\n"
        unless $index >= 0 and $index <= $this->numberOfHeaders;
    confess "format must be defined\n" unless defined $format;

    # Sort out the header
    my $formatRef = new TJWH::Formats;
    $formatRef->name($name);
    $formatRef->formatData($format);

    # Now calculate the provided values using the subroutine provided
    my @names = $this->columnNames;
    foreach my $row (@{ $this->{data} } )
    {
        # We provide a rowHash so that the subroutine can access data in
        # other columns in the row
        my $rowHash;
        for (my $counter = 0; $counter < scalar @names; $counter ++)
        {
            $rowHash->{$names[$counter]} = @{$row}[$counter];
        }

        my $value = &{ $subRef }($rowHash, @extra);
        if ($index == $this->numberOfHeaders)
        {
            push @{ $row }, $value;
        }
        else
        {
            confess "$index is greater the number of elements in row: ".
                scalar @$row."\n  ".
                    (join "\n  ", @{$row}).
                        "\n".Data::Dumper::Dumper $this if $index > scalar @$row;
            splice @{$row}, $index, 0, $value;
        }
    }

    # Now splice in the new column name
    splice @{ $this->{headers} }, $index, 0, $formatRef;

    # Remember to increase the number of data columns
    $this->{maxCols}++;

    return $this;
}

# Just like insertColumnCalculate, except here the index is calculated for you.
sub appendColumnCalculate
{
    my ($this, $name, $format, $subRef, @extra) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    confess "name is not defined\n" unless defined $name;
    confess "format is not defined\n" unless defined $format;

    return $this->insertColumnCalculate($this->numberOfHeaders, $name, $format, $subRef, @extra);
}


# ------------------------------------------------------------------------
#
# Delete column(s)
#
sub deleteColumn
{
    my ($this, @columns) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    foreach my $column (@columns)
    {
        confess "column $column does not exist in table\n -  ".
            (join "\n -  ", $this->columnNames)."\n"
                unless $this->existsColumnName($column);

        my $colIndex = $this->getColumnIndex($column);
        splice @{ $this->{headers} }, $colIndex, 1;

        # Now delete this column in the provided data.
        foreach my $row ($this->rows)
        {
            splice @{$row}, $colIndex, 1 if $colIndex <= $#{ $row };
        }

        # Remember to decrease the number of data columns
        $this->{maxCols}--;
    }

    return $this;
}

sub deleteColumnMaybe
{
    my ($this, @columns) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    foreach my $column (@columns)
    {
        unless ($this->existsColumnName($column))
        {
            warn "column $column does not exist in table\n" if $verbose;
            next;
        }

        my $colIndex = $this->getColumnIndex($column);
        splice @{ $this->{headers} }, $colIndex, 1;

        # Now delete this column in the provided data.
        foreach my $row ($this->rows)
        {
            splice @{$row}, $colIndex, 1 if $colIndex <= $#{ $row };
        }

        # Remember to decrease the number of data columns
        $this->{maxCols}--;
    }

    return $this;
}

# For joins, we need to generate a (mostly) empty row for outer joins
sub emptyRow {
    my ($this, $override) = @_;

    # override is a hash of columnName => values which are not empty. We will
    # fill in all the other values in the row with "empty" markers ('-' or
    # 0). We do this so we can visually identify these values and do
    # arithmetic.
    my $indexOverride;

    if (defined $override)
    {
        confess "override ($override) is not a HASH" unless ref $override eq "HASH";
        foreach my $name (keys %$override)
        {
            confess "Unexpected column name $name" unless $this->existsColumnName($name);
        }
        # Remap names to numerical column indexes
        map { $indexOverride->{$this->getColumnIndex($_)} = $override->{$_} } keys %$override;
    }

    my @row;
    for (my $i = 0; $i < $this->numberOfHeaders; $i++)
    {
        if (exists $indexOverride->{$i})
        {
            push @row, $indexOverride->{$i};
        }
        else
        {
            if ($this->tjwhFormat($i)->isNumber)
            {
                push @row, 0;
            }
            else
            {
                push @row, '-';
            }
        }
    }

    return @row;
}

# ------------------------------------------------------------------------
#
# Join table returns a new table, joining the two tables based on values found
# in the specified column(s). No attempt is made to delete the duplicate
# column(s).
#
# Columns from each table can have prefixes applied to distinguish them
#
sub joinTable
{
    my ($this, $other, $thisColumn, $otherColumn, $thisMarker, $otherMarker, $joinMethod) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    confess "Other must be a TJWH::Table\n" unless blessed $other and $other->isa("TJWH::Table");
    confess "thisColumn must be defined\n" unless defined $thisColumn;
    $otherColumn = $thisColumn unless defined $otherColumn;
    $thisMarker = "" unless defined $thisMarker;
    $otherMarker = "" unless defined $otherMarker;
    $joinMethod = "inner" unless defined $joinMethod;

    # We'll make these joins over multiple key columns
    $thisColumn = [ $thisColumn ] unless ref $thisColumn eq 'ARRAY';
    $otherColumn = [ $otherColumn ] unless ref $otherColumn eq 'ARRAY';

    my @thisColumnIndexes = map { $this->getColumnIndex($_) } @$thisColumn;
    my @otherColumnIndexes = map { $other->getColumnIndex($_) } @$otherColumn;

    my %thisLookup;             # Hash of arrays
    my %otherLookup;            # Hash of arrays

    # Generate lookups based on the key column
    foreach my $row ($this->rows)
    {
        my $value = join '|', map { defined $_ ? $_ : 'undefined' } map { $row->[$_] } @thisColumnIndexes;
        $thisLookup{$value} = [] unless $thisLookup{$value};
        push @{ $thisLookup{$value} }, $row;
    }
    foreach my $row ($other->rows)
    {
        my $value = join '|', map { defined $_ ? $_ : 'undefined' } map { $row->[$_] } @otherColumnIndexes;
        $otherLookup{$value} = [] unless $otherLookup{$value};
        push @{ $otherLookup{$value} }, $row;
    }

    # Balance the two lookups so both have equivalent key sets
    foreach my $key (keys %thisLookup)
    {
        unless (defined $otherLookup{$key})
        {
            if ($joinMethod eq 'outer' or $joinMethod eq 'left_outer') {
                my @pieces = split /[|]/, $key;
                my $override;
                foreach my $name (@{ $otherColumn })
                {
                    $override->{$name} = shift @pieces;
                }
                push @{ $otherLookup{$key} }, [$other->emptyRow($override)];
            } else {
                delete $thisLookup{$key};
            }
        }
    }
    foreach my $key (keys %otherLookup)
    {
        unless (defined $thisLookup{$key})
        {
            if ($joinMethod eq 'outer' or $joinMethod eq 'left_outer') {
                my @pieces = split /[|]/, $key;
                my $override;
                foreach my $name (@{ $thisColumn })
                {
                    $override->{$name} = shift @pieces;
                }
                push @{ $thisLookup{$key} }, [$this->emptyRow($override)];
            } else {
                delete $otherLookup{$key};
            }
        }
    }

    # Now build the new table with the "this" rows on the left and the "other"
    # rows on the right.
    my $table = new TJWH::Table;
    $table->caption("Join of ".$this->caption.
                    " with ".$other->caption.
                    " over ".(join ", ", @$thisColumn).
                    " and ".(join ", ", @$otherColumn));
    $table->columnNames((map { $thisMarker.$_ } $this->columnNames),
                        (map { $otherMarker.$_ } $other->columnNames));
    $table->columnFormats($this->columnFormats,
                          $other->columnFormats);

    foreach my $key (keys %thisLookup)
    {
        foreach my $thisRow (@{ $thisLookup{$key} })
        {
            foreach my $otherRow (@{ $otherLookup{$key} })
            {
                $table->appendRow( @{ $thisRow },
                                   @{ $otherRow });
            }
        }
    }

    # Merge any info slots
    $table->info($other->info);
    $table->info($this->info); # this overwrites other

    return $table;
}

# ------------------------------------------------------------------------
#
# Subtract table returns a new table, subtracting the two tables based on
# values found in the specified column(s).
#
# The subtraction result is $other - $this
#
sub subtractTable
{
    my ($this, $other, $thisColumn, $joinMethod, $protectColumn, $validate) = @_;
    confess "This must be a TJWH::Table\n" unless blessed $this and $this->isa("TJWH::Table");
    confess "Other must be a TJWH::Table\n" unless blessed $other and $other->isa("TJWH::Table");
    confess "thisColumn must be defined\n" unless defined $thisColumn;
    # joinMethod is optional
    # protectColumn is optional
    # validate

    if (defined $joinMethod) {
        $joinMethod = lc $joinMethod;
        confess "joinMethod ($joinMethod) is not one of inner, outer, left_outer or right_outer "
            unless $joinMethod=~ m/^(inner|(left_|right_)?outer)$/;
    } else {
        $joinMethod = "left_outer";
    }

    # We'll make these joins over multiple key columns
    $thisColumn = [ $thisColumn ] unless ref $thisColumn eq 'ARRAY';

    # Ensure we have at least one join column
    unless (scalar @$thisColumn) {
        cluck "No join columns specified\n";
        return;
    }

    # Make a list of indices that we will NOT subtract. This includes the join
    # columns and any extra columns we want unchanged
    my $protectMap = {};
    if (defined $protectColumn) {
        $protectColumn = [ $protectColumn ] unless ref $protectColumn eq 'ARRAY';
    } else {
        $protectColumn = [];
    }
    foreach my $column (@$thisColumn, @$protectColumn) {
        if ($this->existsColumnName($column)) {
            $protectMap->{$this->getColumnIndex($column)}++;
        }
    }

    my @columnIndexes = map { $this->getColumnIndex($_) } @$thisColumn;
    my %thisLookup;             # Hash of arrays
    my %otherLookup;            # Hash of arrays
    # Generate lookups based on the key column
    foreach my $row ($this->rows)
    {
        my $value = join '|', map { defined $_ ? $_ : 'undefined' } map { $row->[$_] } @columnIndexes;
        $thisLookup{$value} = [] unless $thisLookup{$value};
        push @{ $thisLookup{$value} }, $row;
    }
    foreach my $row ($other->rows)
    {
        my $value = join '|', map { defined $_ ? $_ : 'undefined' } map { $row->[$_] } @columnIndexes;
        $otherLookup{$value} = [] unless $otherLookup{$value};
        push @{ $otherLookup{$value} }, $row;
    }

    # Balance the two lookups so both have equivalent key sets. There are
    # multiple ways to do this:
    #  - inner - only keys that exist in both sets will get results
    #  - outer - any key that exists in either sets will get results
    #  - left_outer - any key in OTHER will get results
    #  - right_outer - any key in THIS will get results
    foreach my $key (keys %thisLookup) {
        print "Examining this key $key\n" if $debug;
        unless (defined $otherLookup{$key}) {
            if ($joinMethod eq 'outer' or $joinMethod eq 'right_outer') {
                push @{ $otherLookup{$key} }, [$other->emptyRow];
            } else {
                warn "$joinMethod: Deleting key $key from $this->{caption}\n" if $debug;
                delete $thisLookup{$key};
            }
        }
    }
    foreach my $key (keys %otherLookup) {
        print "Examining other key $key\n" if $debug;
        unless (defined $thisLookup{$key}) {
            if ($joinMethod eq 'outer' or $joinMethod eq 'left_outer') {
                push @{ $thisLookup{$key} }, [$this->emptyRow];
            } else {
                warn "$joinMethod: Deleting key $key from $other->{caption}\n" if $debug;
                delete $otherLookup{$key};
            }
        }
    }

    print "Number of this keys: ".(scalar (keys %thisLookup))."\n" if $debug;
    print "Number of other keys: ".(scalar (keys %otherLookup))."\n" if $debug;

    # Now build the new table
    my $table = new TJWH::Table;
    $table->caption($other->caption. " - ".$this->caption.
                    " joined on ".(join ", ", @$thisColumn));
    $table->columnNames($this->columnNames);
    # Need to be careful - tables with no rows are "unformatted". Assume
    # that at least one of these tables must have rows to actually do any
    # calculations.
    if ($this->numberOfRows) {
        $table->columnFormats($this->columnFormats);
    } else {
        $table->columnFormats($other->columnFormats);
    }

    my %timeStampDiffs;

    my $errors = 0;
    foreach my $key (keys %thisLookup) {
        foreach my $thisRow (@{ $thisLookup{$key} }) {
            foreach my $otherRow (@{ $otherLookup{$key} }) {
                my @row;
                for (my $i = 0; $i <= $#$thisRow; $i++) {
                    if (defined $validate) {
                        my $base = $thisRow->[$i];
                        my $compare = $otherRow->[$i];

                        if ($table->tjwhFormat($i)->isNumber) {
                            $base    = 0 unless defined $base;
                            $compare = 0 unless defined $compare;
                        } else {
                            $base    = "" unless defined $base;
                            $compare = "" unless defined $compare;
                        }
                        $base = stripWhitespace($base);
                        $compare = stripWhitespace($compare);
                        no warnings;
                        if ($table->tjwhFormat($i)->isNumber and $compare == $base) {
                            push @row, 'SAME';
                        } elsif ($table->tjwhFormat($i)->isString and $compare eq $base) {
                            push @row, 'SAME';
                        } else {
                            $errors++;
                            push @row, "|$compare".'<->'."$base|";
                        }

                    } else {
                        if ($protectMap->{$i}) {
                            push @row, $otherRow->[$i];
                        } else {
                            my $base = $thisRow->[$i];
                            my $compare = $otherRow->[$i];
                            if (defined $base or defined $compare)
                            {
                                if ($table->tjwhFormat($i)->isNumber) {
                                    $base = 0 unless defined $base;
                                    $compare = 0 unless defined $compare;
                                    push @row, $compare - $base;
                                } else {
                                    $base = "" unless defined $base;
                                    $compare = "" unless defined $compare;
                                    if ($base eq $compare) {
                                        push @row, $base;
                                    } else {
                                        # Try subtract if these are timestamps
                                        my $secs = subtractTimestamps($compare, $base);
                                        if (defined $secs) {
                                            $timeStampDiffs{$i}++;
                                            push @row, $secs;
                                        } else {
                                            push @row, "$compare <-> $base";
                                        }
                                    }
                                }
                            } else {
                                # If both values are NULL, return NULL
                                push @row, undef;
                            }
                        }
                    }
                }
                $table->appendRow(@row);
            }
        }
    }
    # If the method is outer, we might have some timestamp diffs that are zero
    # and really should be some value. Do a scan of any TIMESTAMP column and fix it up.
    # We use the columns flagged in $timeStampDiffs
    foreach my $key (sort keys %timeStampDiffs)
    {
        print "TJWH::Table::subtract: found timestamp diff column $key\n" if $debug;
        my %values;
        foreach my $entry ($table->getNumbersForColumn($key))
        {
            $values{$entry}++ if $entry; # ignore zeros and undef
        }
        my @list = keys %values;
        my $count = scalar @list;
        if ($count == 1)
        {
            print "TJWH::Table::subtract: found single value timestamp diff for column $key\n" if $debug;
            my $update = pop @list;
            $table->changeColumn($key, sub { return $update });
        }
    }

    # Make sure we have some sane types to return
    $table->autoFormat;

    if ($validate)
    {
        if ($errors)
        {
            $table->caption("ERROR: there are $errors differences between the two tables\n".
                            $table->caption);
        }
        else
        {
            $table->caption("SUCCESS: The two tables are identical\n". $table->caption);
        }
    }

    return $table;
}


# ------------------------------------------------------------------------
#
# Statistics
#

# Given a column number (starting from 0), return the mean for that column
sub meanForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result;
    if ($this->tjwhFormat($colIndex)->isNumber)
    {
        $result = TJWH::BasicStats::mean($this->getNumbersForColumn($colIndex));
    }
    else
    {
        $result = TJWH::BasicStats::mode($this->getColumn($colIndex));
    }
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column number (starting from 0), return the median value for that column
sub medianForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result;
    if ($this->tjwhFormat($colIndex)->isNumber)
    {
        print "DEBUG: median for median\n" if $debug;
        $result = TJWH::BasicStats::median($this->getNumbersForColumn($colIndex));
    }
    else
    {
        print "DEBUG: mode for median\n" if $debug;
        $result = TJWH::BasicStats::mode($this->getColumn($colIndex));
    }
    $result = $noValue unless defined $result;
    return $result;
}

# Return the most common value for a column
sub modeForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result = TJWH::BasicStats::mode($this->getColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column number (starting from 0), return the sum of that column
sub sumForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result = TJWH::BasicStats::sum($this->getNumbersForColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column number (starting from 0), return the standard deviation for that column
sub stdevForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result =  TJWH::BasicStats::stdev($this->getNumbersForColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column number (starting from 0), return the standard deviation for that column
sub cofvForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result =  TJWH::BasicStats::cofv($this->getNumbersForColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column number (starting from 0), return the minimum for that column
sub minForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result = TJWH::BasicStats::minimum($this->getNumbersForColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column number (starting from 0), return the maximum for that column
sub maxForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result = TJWH::BasicStats::maximum($this->getNumbersForColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

#  Range for a column
sub rangeForColumn
{
    my ($this, $column) = @_;
    my $colIndex = $this->getColumnIndex($column);

    my $result = TJWH::BasicStats::range($this->getNumbersForColumn($colIndex));
    $result = $noValue unless defined $result;
    return $result;
}

# Given a column header, return the average for that column
sub meanForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $mean;
    if (defined $colIndex)
    {
        $mean = $this->meanForColumn($colIndex);
    }
    return $mean;
}

# Given a column header, return the average for that column
sub medianForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $median;
    if (defined $colIndex)
    {
        $median = $this->medianForColumn($colIndex);
    }
    return $median;
}

# Given a column number (starting from 0), return the average for that column
sub sumForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $sum;
    if (defined $colIndex)
    {
        $sum = $this->sumForColumn($colIndex);
    }
    return $sum;
}

# Given a column number (starting from 0), return the standard deviation for that column
sub stdevForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $stdev;
    if (defined $colIndex)
    {
        $stdev = $this->stdevForColumn($colIndex);
    }
    return $stdev;
}

# Given a column number (starting from 0), return the standard deviation for that column
sub cofvForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $cofv;
    if (defined $colIndex)
    {
        $cofv = $this->cofvForColumn($colIndex);
    }
    return $cofv;
}

# Given a column number (starting from 0), return the minimum for that column
sub minForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $min;
    if (defined $colIndex)
    {
        $min = $this->minForColumn($colIndex);
    }
    return $min;
}

# Given a column number (starting from 0), return the maximum for that column
sub maxForHeader
{
    my ($this, $header) = @_;
    my $colIndex = $this->getIndexForHeader($header);
    my $max;
    if (defined $colIndex)
    {
        $max = $this->maxForColumn($colIndex);
    }
    return $max;
}

# ------------------------------------------------------------------------
#
# Table methods
#
# Create a lookup hash based on two columns from a table. This is useful for
# simple join operations
sub makeLookup
{
    my ($this, $keyColumn, $valueColumn, $lookup) = @_;
    confess "Key column must be defined\n" unless defined $keyColumn;
    confess "Value column must be defined\n" unless defined $valueColumn;
    $lookup = {} unless defined $lookup;
    confess "lookup ($lookup) is not a HASH" unless ref $lookup eq 'HASH';

    $keyColumn = $this->getColumnIndex($keyColumn);
    $valueColumn = $this->getColumnIndex($valueColumn);
    # lookup is optional - if passed in, key/value pairs will be populated
    foreach my $row ($this->rows)
    {
        $lookup->{@$row[$keyColumn]} = @$row[$valueColumn];
    }

    return $lookup;
}

sub autoWidth
{
    my ($this) = @_;
    my $totalWidth = 0;
    my @headers = $this->headers;
    print "Before autowidth\n" if $debug;
    print Data::Dumper::Dumper $this->headers if $debug;
    for (my $i = 0; $i <= $#headers; $i++)
    {
        next if $i >= $this->{maxCols};
        $totalWidth += $this->columnWidthAuto($i);
    }
    print "After autowidth\n" if $debug;
    print Data::Dumper::Dumper $this->headers if $debug;
    return $totalWidth;
}

sub autoFormat
{
    my ($this, @columnIndices) = @_;
    confess "this is not defined" unless defined $this;

    # We may have more headers than columns. It's really not advisable to
    # attempt to format a non-existent column
    @columnIndices = (0 .. $this->{maxCols} - 1 ) unless @columnIndices;

    foreach my $index (@columnIndices)
    {
        # $index may be a name, not a number
        my @column;
        eval {
            @column = $this->getColumn($index);
        };
        if ($@)
        {
            warn "$@" if $debug;
            next;
        }
        my $isNumber = 1;
        my $scale = 1;
        my $precision = 0;
        my $seen = 0;
        my $plusMinus = 0;
        foreach my $value (@column)
        {
            # Track how many values we've inspected and quit if we have looked
            # at enough to be reasonably certain
            $seen++ if defined $value and $value !~ m!^($noValue|<?null>?)$!i ;
            last if defined $this->autolimit and $seen > $this->autolimit;

            $value =~ s/^\s+//g;
            $value =~ s/\s+$//g;
            next if (not defined $value) or ($value eq '');

            $plusMinus ++ if $value =~ m/±/;

            # Force decimal representation (e.g. 2.84046603469422e-06 -> 0.000002)
            if ($value =~ m/^[+-]?\d+(\.\d+)?[eE][+-](\d+)$/)
            {
               $value = sprintf "%.6f", $value;
            }

            if ($value =~ m/^([+-]?\d+)\.?(\d+)?$/)
            {
                my ($integer, $fraction) = ($1, $2);
                my $currentScale;
                if (defined $fraction)
                {
                    $fraction =~ s/0+$//g;
                    $currentScale = (length $integer) + (length $fraction) + 1;
                }
                else
                {
                    $currentScale = length $integer;
                }

                if ($currentScale > $scale)
                {
                    $scale = $currentScale;
                }

                if (defined $fraction and
                    length $fraction > $precision)
                {
                    $precision = length $fraction;
                }
            }
            elsif ($noValue and $value =~ m!$noValue!)
            {
                # skip this one.
            }
            elsif ($value =~ m!^<?null>?$!i)
            {
                # skip this one.
            }
            else
            {
                print "TJWH::Table::autoFormat: Value $value isn't numeric\n"
                    if $debug;
                $isNumber = 0;
                if (length $value > $scale)
                {
                    $scale = length $value;
                }
                last;
            }
            confess "Index $index: precision > scale : ".
                "$precision > $scale after $value \n".
                    Data::Dumper::Dumper [ $this->getColumn($index) ] if $precision > $scale;
        }

        # If we had no values at all, then set the type to string to avoid
        # printing zeros, unless this is a known Integer column
        if ($seen == 0 and not inArray($this->columnName($index), $alwaysInteger))
        {
            $isNumber = 0;
        }

        # If we have some crazy precisions, then reduce both precision and
        # scale to something more managable
        my $maxPrec = 3;
        if ($precision > $maxPrec)
        {
            $scale -= ($precision - $maxPrec);
            $precision = $maxPrec;
        }
        print "DEBUG:\n  ".
            (
             join "\n  ", map { eval "sprintf \"$_ = \$$_\"" }
             qw(index scale precision maxPrec)
            )."\n" if $debug;

        # Produce a printf style format for this column
        if ($isNumber)
        {
            # right-justify numbers
            if ($precision)
            {
                $this->columnFormat($index,"%"."${scale}.${precision}f");
            }
            else
            {
                $this->columnFormat($index,"%"."${scale}d");
            }
        }
        else
        {
            confess "scale can't be negative for strings during autoformat: $scale\n" if $scale < 0;
            # left-justify strings UNLESS they fit certain patterns....
            if ($plusMinus)
            {
                $this->columnFormat($index, '%'."${scale}s");
            } else
            {
                $this->columnFormat($index, '%-'."${scale}s");
            }
        }
    }

    return $this->columnFormats;
}

# Inherit the caption, column names, column formats, info and type from another
# table.
sub inheritDescription
{
    my ($this, $other) = @_;

    $this->caption($other->caption);
    # Used to just copy over names and formats - but that misses substrings
    # $this->columnNames($other->columnNames);
    # $this->columnFormats($other->columnFormats);
    # Duplicate the headers
    $this->{headers} = [ @{ $other->{headers} } ];

    $this->type($other->type);
    $this->multi($other->multi);
    $this->info($other->info);

    # We might have ranges set for charting
    $this->xrange($other->xrange);
    $this->xmin($other->xmin);
    $this->xmax($other->xmax);
    $this->yrange($other->yrange);
    $this->ymin($other->ymin);
    $this->ymax($other->ymax);

    return $this;
}

# ------------------------------------------------------------------------
#
# Outputs
#
# Print the table using the formats given,
sub printText
{
    my ($this) = @_;
    my @formats = $this->headers;

    my $formatHeader = join " ", map {$_->formatHeader} @formats;
    print $this->{caption}."\n" if $this->{caption} ne "";
    if (not defined $this->{multi})
    {
        printf "$formatHeader\n" , map {$_->name} @formats;
    }
    else
    {
        # Multiline headers are cooler in every respect
        my @headerNames = map {$_->name} @formats;
        my $emptyCount = 0;
        while ($emptyCount < scalar @headerNames)
        {
            my @thisRow ;
            for (my $index = 0; $index < scalar @headerNames; $index++)
            {
                if (defined $headerNames[$index])
                {
                    my ($current, $rest) = nextWord($headerNames[$index]);
                    my $word;
                    if (defined $rest)
                    {
                        ($word, $rest) = nextWord($rest);
                        # Widths are negative for string columns so be careful
                        # about signs
                        while (length "$current $word" <= abs $formats[$index]->width and defined $rest)
                        {
                            $current = "$current $word";
                            ($word, $rest) = nextWord($rest);
                        }
                    }
                    if ($this->type =~ m/ctext/)
                    {
                        # Add spaces to center it up
                        my $pad = " "x(((abs $formats[$index]->width) - length $current) / 2);
                        if ($formats[$index]->width > 0)
                        {
                            # Spaces on the right
                            $current .= $pad;
                        } else
                        {
                            # Spaces on the left;
                            $current = $pad.$current;
                        }
                    }
                    $thisRow[$index] = $current;
                    if (defined $word)
                    {
                        if (defined $rest)
                        {
                            $headerNames[$index] = "$word $rest";
                        }
                        else
                        {
                            $headerNames[$index] = $word;
                        }
                    }
                    else
                    {
                        $headerNames[$index] = undef;
                        $emptyCount++;
                    }
                }
                else
                {
                    $thisRow[$index] = "";
                }
            }
            last unless grep { m/\S/ } @thisRow;
            printf "$formatHeader\n", @thisRow;
        }
    }

    print "".(join " ", map { "-"x(abs $_->width) } @formats)."\n";

    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        if ($lastindex > $#formats )
        {
            confess "Too many entries in row: $lastindex > $#formats\n";
        }
        my $formatData = join " ", map { $_->formatData } @formats[0 .. $lastindex];
        printf "$formatData\n", map {
            $formats[$_]->formatValue(@{ $row }[$_])
        } 0 .. $lastindex;
    }

    return;
}

# Print the table using Emacs Org mode formatting
sub printOrg
{
    my ($this) = @_;
    my @formats = $this->headers;

    my $formatHeader = "| ".(join " | ", map {$_->formatHeader} @formats)." |";
    my $indent = 2;
    if ($this->type =~ m/org(\d+)/)
    {
        $indent = $1;
    }

    # Treat named tables differently to general captions
    if ($this->{caption} =~ m/^#[+]NAME:/) {
        print "$this->{caption}\n";
    } else {
        print '*'x$indent ." ".$this->{caption}."\n" if $this->{caption} ne "";
    }

    if (not defined $this->{multi})
    {
        printf "$formatHeader\n" , map {$_->name} @formats;
    }
    else
    {
        # Multiline headers are cooler in every respect
        my @headerNames = map {$_->name} @formats;

        my $emptyCount = 0;
        while ($emptyCount < scalar @headerNames)
        {
            my @thisRow ;
            for (my $index = 0; $index < scalar @headerNames; $index++)
            {
                if (defined $headerNames[$index])
                {
                    my ($current, $rest) = nextWord($headerNames[$index]);
                    my $word;
                    if (defined $rest)
                    {
                        ($word, $rest) = nextWord($rest);
                        while (length "$current $word" <= $formats[$index]->width and
                               defined $rest)
                        {
                            $current = "$current $word";
                            ($word, $rest) = nextWord($rest);
                        }
                    }
                    $thisRow[$index] = $current;
                    if (defined $word)
                    {
                        if (defined $rest)
                        {
                            $headerNames[$index] = "$word $rest";
                        }
                        else
                        {
                            $headerNames[$index] = $word;
                        }
                    }
                    else
                    {
                        $headerNames[$index] = undef;
                        $emptyCount++;
                    }
                }
                else
                {
                    $thisRow[$index] = "";
                }
            }
            last unless grep { m/\S/ } @thisRow;
            printf "$formatHeader\n", @thisRow;
        }
    }

    print "|-".(join "-+-", map { "-"x(abs $_->width) } @formats)."-|\n";

    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        my $formatData = "| ".(join " | ", map { $_->formatData } @formats[0 .. $lastindex])." |";
        printf "$formatData\n", map {
            $formats[$_]->formatValue(@{ $row }[$_])
        } 0 .. $lastindex;
    }

    return;
}

# Print the table using Github Flavoured Markdown (GFM)
# Note: Markdown does not have a table layout
sub printMd
{
    my ($this) = @_;
    my @formats = $this->headers;

    my $formatHeader = "| ".(join " | ", map {$_->formatHeader} @formats)." |";
    my $indent = 2;
    if ($this->type =~ m/(gfm|md)(\d+)/)
    {
        $indent = $1;
    }

    # Print markdown headers, default at level 2 but can be set with -type md3 to set level 3, etc.
    print '#'x$indent ." ".$this->{caption}.' '.'#'x$indent ."\n" if $this->{caption} ne "";

    if (not defined $this->{multi})
    {
        printf "$formatHeader\n" , map {$_->name} @formats;
    }
    else
    {
        # Multiline headers are cooler in every respect
        my @headerNames = map {$_->name} @formats;

        my $emptyCount = 0;
        while ($emptyCount < scalar @headerNames)
        {
            my @thisRow ;
            for (my $index = 0; $index < scalar @headerNames; $index++)
            {
                if (defined $headerNames[$index])
                {
                    my ($current, $rest) = nextWord($headerNames[$index]);
                    my $word;
                    if (defined $rest)
                    {
                        ($word, $rest) = nextWord($rest);
                        while (length "$current $word" <= $formats[$index]->width and
                               defined $rest)
                        {
                            $current = "$current $word";
                            ($word, $rest) = nextWord($rest);
                        }
                    }
                    $thisRow[$index] = $current;
                    if (defined $word)
                    {
                        if (defined $rest)
                        {
                            $headerNames[$index] = "$word $rest";
                        }
                        else
                        {
                            $headerNames[$index] = $word;
                        }
                    }
                    else
                    {
                        $headerNames[$index] = undef;
                        $emptyCount++;
                    }
                }
                else
                {
                    $thisRow[$index] = "";
                }
            }
            last unless grep { m/\S/ } @thisRow;
            printf "$formatHeader\n", @thisRow;
        }
    }

    # Print the header seperator line including left and right aligned
    #
    # Left :---
    # Right ---:
    # Center :---:
    #
    print "|".(join "|", map {
        ($_->width < 0 ? ":" :" ").
        "-"x TJWH::BasicStats::maximum(3,(abs $_->width)). # Must be a miniumum of three minus signs
        ($_->width > 0 ? ":" :" ")
    } @formats)."|\n";

    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        my $formatData = "| ".(join " | ", map { $_->formatData } @formats[0 .. $lastindex])." |";
        printf "$formatData\n", map {
            $formats[$_]->formatValue(@{ $row }[$_])
        } 0 .. $lastindex;
    }

    return;
}

# Print the table in wiki format
sub printWiki
{
    my ($this) = @_;
    my @formats = $this->headers;

    my $formatHeader = join " !! ", map {$_->formatHeader} @formats;
    print "{|".($this->attributes)." class=\"wikitable\"\n";

    # Add <br> tags to the end of the lines in the caption
    my $caption = $this->caption;
    $caption =~ s/\n/<br>\n/g;

    print "|+ ", $caption, "\n";
    if (not $this->multi)
    {
        printf "! $formatHeader\n" , map { $_->name } @formats;
    }
    else
    {
        # Multiline headers are experimental
        print map { "! $_\n" } $this->breaklineHeaders;
    }

    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        my $formatData = join " || ", map { $_->formatData } @formats[0 .. $lastindex];
        printf "|-\n| $formatData\n", @{ $row };
    }

    print "|}\n";

    return;
}

sub breaklineHeaders
{
    my ($this) = @_;
    my @formats = $this->headers;
    my @headerNames = map { $_->name } @formats;
    my @breaklineHeaders = ();

    for (my $index = 0; $index < scalar @headerNames; $index++)
    {
        if (defined $headerNames[$index])
        {
            my ($current, $rest) = nextWord($headerNames[$index]);
            my $word;
            while (defined $rest)
            {
                ($word, $rest) = nextWord($rest);
                if (length "$current $word" > $formats[$index]->width)
                {
                    $breaklineHeaders[$index] .= "$current<br>";
                    $current = $word;
                }
                else
                {
                    $current .= " $word";
                }
            }
            if (defined $current)
            {
                $breaklineHeaders[$index] .= "$current"
            }
        }
        else
        {
            $breaklineHeaders[$index] = "";
        }
    }

    return @breaklineHeaders;
}

sub printWikiSortable
{
    my ($this) = @_;
    my @formats = $this->headers;

    my $formatHeader = join " !! ", map {$_->formatHeader} @formats;
    print "{|".($this->attributes)." class=\"wikitable sortable\"\n";
    # Add <br> tags to the end of the lines in the caption
    my $caption = $this->caption;
    $caption =~ s/\n/<br>\n/g;

    print "|+ ", $caption, "\n";
    if (not $this->multi)
    {
        printf "! $formatHeader\n" , map { $_->name } @formats;
    }
    else
    {
        # Multiline headers are experimental
        print map { "! $_\n" } $this->breaklineHeaders;
    }

    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        my $formatData = join " || ", map { $_->formatData } @formats[0 .. $lastindex];
        printf "|-\n| $formatData\n", @{ $row };
    }
    print "|}\n";

    return;
}

sub printCsv
{
    my ($this) = @_;
    my @formats = $this->headers;

    # We actually don't want to pad these formats out at all for CSV. Set the
    # width to zero
    my @originalWidths = map { $formats[$_]->width } 0 .. $#formats;

    # For now, the multiline setting is ignored for CSV output
    map { $formats[$_]->width(0) } 0 .. $#formats;

    my $formatHeader = join "\",\"", map {$_->formatHeader} @formats;
    my $formatData = join ",", map {$_->isNumber ?
                                        $_->formatData :
                                            "\"".$_->formatData."\""} @formats;

    my $caption = $this->{caption};
    $caption =~ s/["]//g;
    # print "\"$caption\"\n" if $caption ne "";
    printf "\"${formatHeader}\"\n" , map {$_->name} @formats;
    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        my @values = @{ $row };
        # As we use double quotes for sting markup, switch all double quotes
        # in values to single quotes
        foreach my $element (@values)
        {
            $element =~ s/["]/'/g;
        }
        printf "$formatData\n", @values;
    }

    # Restore the original widths
    map { $formats[$_]->width($originalWidths[$_]) } 0 .. $#formats;

    return;
}

sub printTab
{
    my ($this) = @_;
    my @formats = $this->headers;

    # We actually don't want to pad these formats out at all for CSV. Set the
    # width to zero
    my @originalWidths = map { $formats[$_]->width } 0 .. $#formats;

    # For now, the multiline setting is ignored for CSV output
    map { $formats[$_]->width(0) } 0 .. $#formats;

    my $formatHeader = join "\t", map {$_->formatHeader} @formats;
    my $formatData = join "\t", map {$_->formatData} @formats;

    my $caption = $this->{caption};
    $caption =~ s/["]//g;
    print "\"$caption\"\n" if $caption ne "";
    printf "${formatHeader}\n" , map {$_->name} @formats;
    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $lastindex = $#{ $row };
        my @values = @{ $row };
        # As we use double quotes for string markup, switch all double quotes
        # in values to single quotes
        foreach my $element (@values)
        {
            $element =~ s/["]/'/g;
        }
        printf "$formatData\n", @values;
    }

    # Restore the original widths
    map { $formats[$_]->width($originalWidths[$_]) } 0 .. $#formats;

    return;
}

sub printHtml
{
    my ($this) = @_;
    my @formats = $this->headers;

    # Start the table and write the caption and table hadings out
    print "<table border=\"1\">\n";
    my $caption = join "<br>", ( split /\n/, $this->caption );
    print "<caption>$caption</caption>\n" if $this->caption;
    my $formatHeader = join "", map { "  <th>$_</th>\n" } map {$_->name} @formats;
    print "<tr>\n$formatHeader</tr>\n";

    # now process the rows
    foreach my $row ($this->visibleRows)
    {
        no warnings;
        my $formatData = "  <td>".
            (join "</td>\n  <td>", map { $_->formatData } @formats[0 .. $#{ $row }]).
                "</td>\n";
        printf "<tr>\n$formatData</tr>\n", @{ $row };
    }

    # and finish the table
    print "</table>\n";

    return;
}

sub storeTable
{
    my ($this) = @_;

    my $base = $this->output;
    unless (defined $base)
    {
        $base = $this->caption;
        warn "No output file specified for store - using $base";
    }

    my $counter = 0;
    while (-e "$base-$counter.store")
    {
        $counter++;
    }

    my $output = "$base-$counter.store";
    nstore \$this, $output;
    confess "Failed to write $output" unless -f $output;
    confess "$output is empty" unless -s $output;
    return;
}

# Convenience routine for tidying up and printing a table
sub qPrint
{
    my ($this, $type) = @_;
    $this->multi(1);
    $this->autoWidth;
    $this->type($type) if defined $type;
    $this->printTable;
    return;
}

sub printTable
{
    my ($this) = @_;
    confess "this is not defined" unless defined $this;

    # Allow the type to specify multiple output formats and destinations
    my ($type, $output);
    foreach my $part (csvToArray $this->type)
    {
        if ($part =~ m/^(\w+):(.*)$/)
        {
            ($type, $output) = ($1, $2);
        }
        else
        {
            $type = $part;
            $output = $this->output;
        }

        # If we are just storing the table to a file, do it and return
        if ($type eq "store")
        {
            $this->storeTable;
            return;
        }

        # If we want to save this output to a file, do the redirect now
        my $saveOut;
        if (defined $output)
        {
            # Automatic file names need a little care to avoid overwriting
            # existing files by accident....
            if ($output =~ m/^_AUTO_$/i)
            {
                # Create a plausible name from the caption and type
                $output = $this->caption.".".$type;
                my $counter = 0;
                while (-f $output)
                {
                    warn "$output already exists\n";
                    $counter++;
                    $output = $this->caption.(sprintf "-%04d.", $counter).$this->type;
                }
            }

            open $saveOut, ">&STDOUT";
            # Use append so we don't wipe out the data in subsequent calls
            open STDOUT, ">>$output"
                or die "Couldn't redirect STDOUT to $output:$!\n";
            select STDOUT; $| = 1;
        }

        if ($type eq "text" or $type eq "ctext" or $type eq "txt" or $type eq "fit")
        {
            $this->fitWidth if $type eq "fit";
            $this->printText;
        }
        elsif ($type eq "wiki")
        {
            $this->printWiki;
        }
        elsif ($type eq "wikisort")
        {
            $this->printWikiSortable;
        }
        elsif ($type eq "csv")
        {
            $this->printCsv;
        }
        elsif ($type eq "tab")
        {
            $this->printTab;
        }
        elsif ($type eq "html")
        {
            $this->printHtml;
        }
        elsif ($type =~ m/^(fit)?org\d*$/)
        {
            $this->fitWidth if $type =~ m/^fitorg/;
            $this->printOrg;
        }
        elsif ($type =~ m/^(gfm|md)\d*$/)
        {
            $this->printMd;
        }
        else
        {
            cluck "Unrecognized table output type: ".$type."\n";
        }

        if (defined $output)
        {
            close STDOUT or die "Failed to close redirected STDOUT: $!\n";
            open STDOUT, ">&", $saveOut or
                die "Failed to reopen STDOUT after writing to $output to ",
                Data::Dumper::Dumper $saveOut;
        }
    }
    return;
}

# Make the Table fit the terminal by squeezing down the column widths
sub fitWidth{
    my ($this) = @_;

    # We'll only handle table width for text-based output
    return unless $this->type =~ m/^(fit|org|txt|c?text)/;

    my $columns = 80;
    # If we are given an COLUMNS environment variable, trust it and use it if
    # it is numeric
    if (defined $ENV{'COLUMNS'} and
        $ENV{'COLUMNS'} =~ m/^\d+$/ and
        $ENV{'COLUMNS'} > 0)
    {
        $columns = $ENV{'COLUMNS'};
    }
    else
    {
        # Try to find the current terminal width.
        open my $fh, "-|", "tput cols";
        $columns = <$fh>;
        close $fh;
        unless ($columns)
        {
            warn "No output from tput cols\n";
            return;
        }
        unless ($columns =~ m/^\d+$/) {
            warn "fitWidth: Unexpected output from tput cols: $columns\n";
            return;
        }
    }

    # Start off by counting the single-spaces between the columns
    my $totalWidth = $#{ $this->{headers} };

    # Org-mode column gaps are 3 wide ' | ' and
    #     two extra 2-wide sidebars '| ' and ' |'
    $totalWidth = (3*$totalWidth) + 4 if $this->type =~ m/^(fit)?org/;

    # Map the difference between current and minimum widths to column index
    # for STRING columns
    my $widthMap;
    my $shrinkWidth = 0; # Shrinkable width of all the strings
    for (my $index = 0; $index <= $#{$this->{headers}}; $index++)
    {
        $totalWidth += abs $this->{headers}->[$index]->{width};
        if ($this->{headers}->[$index]->isString)
        {
            $widthMap->{$index} =
                (abs $this->{headers}->[$index]->{width}) - $this->minimumColumnWidth($index);
            $shrinkWidth += $widthMap->{$index};
        }
    }
    # If the table fits, we're done
    return if $totalWidth <= $columns;

    # If the numeric data overflows the screen even with the strings set to
    # minimum width, squeeze all the strings to minimum and get out
    if ($columns < $totalWidth - $shrinkWidth)
    {
        foreach my $index (keys %$widthMap)
        {
            my $h = $this->tjwhFormat($index);
            $h->width($this->minimumColumnWidth($index));
            $h->substring("first");
        }
        return;
    }

    # Iterate until the table fits
    while ($totalWidth > $columns)
    {
        my $delta = $totalWidth - $columns;

        # We need to sort the string columns by current shrinkable width,
        # largest to smallest
        my @widths = sort { $widthMap->{$b} <=> $widthMap->{$a} } keys %{ $widthMap };

        # Find the difference in shrinkable width (considering multiple
        # columns with the same shrinkable width)
        my $first = shift @widths;
        my $compare;
        my $counter = 0;
        do
        {
            $counter++;
            $compare = shift @widths;
        } while (defined $compare and $widthMap->{$first} == $widthMap->{$compare});

        my $reduce;
        if (defined $compare)
        {
            $reduce = int (($widthMap->{$first} - $widthMap->{$compare}) / $counter);
        }
        else
        {
            # All the string columns have the same width, so pick one and squeeze
            $reduce = int ($delta / $counter);
        }
        # Ensure that we are making the table thinner
        $reduce = 1 if $reduce < 1;

        # Don't reduce further than needed to meet the requested table width
        $reduce = $delta if $reduce > $delta;
        $widthMap->{$first} -= $reduce;
        $totalWidth -= $reduce;
    }

    # Apply the new widths adding the remaining shrinkable width to the minimum width
    foreach my $index (keys %$widthMap)
    {
        my $h = $this->tjwhFormat($index);
        $h->width(-1 * ($this->minimumColumnWidth($index) + $widthMap->{$index}));
        $h->substring("first");
    }

    return $this;
}

# This is essentially the same as printTable, but the result is passed back to
# the caller as an array of strings.
sub getTable
{
    my ($this) = @_;

    my $currentOutput = $this->output;
    my $temp = File::Temp->new();
    $this->output($temp->filename);
    $this->printTable;
    my @result = readFile($temp->filename);

    # We DON'T use the method call here because $currentOutput may be undefined
    $this->{output} = $currentOutput;

    foreach (@result)
    {
        chomp;
    }

    return @result;
}

# When printing charts, we can infer
# - data labels from the table headers,
# - type from the filename
sub plotChart
{
    my ($this, $title,
        $filename,
        $style,
        $xAxisLabel, $yAxisLabel,
        $xAxis, @yAxes) = @_;

    unlink $filename if -f $filename;

    my $tp = new TJWH::TablePlot;
    $tp->setupPlot($this,
                   $title,
                   $filename,
                   $style,
                   $xAxisLabel, $yAxisLabel,
                   $xAxis, @yAxes);
    # keep the scripts if we are debugging.
    $tp->keep if $debug;
    $tp->generateScript;
    $tp->executeScript;

    return $filename if -f $filename;
    return 0;
}

# Multiple types may be specified as csv
sub isValidType
{
    my $type = shift;

    foreach my $part (csvToArray $type)
    {
        # Cut off any trailing filename
        if ($part =~ m/^(\w+):(.*)$/)
        {
            $part = $1;
        }
        if ($part !~ m/^(c?text|txt|fit|org(\d*)|fitorg(\d*)|md|gfm|wiki(|sort)|csv|tab|html|store)$/)
        {
            return 0;
        }
    }
    return 1;
}

# Dump the table
sub dumpTable
{
    my ($this) = @_;
    print Data::Dumper::Dumper $this->{headers};
    print Data::Dumper::Dumper $this->{data};
    return;
}

# ========================================================================
#
# Public exported subroutines
#
sub readTableFromCSV
{
    my ($filename) = @_;

    unless (-f $filename)
    {
        print "Warning: $filename is not a file\n";
        return;
    }
    my $table = new TJWH::Table;
    my $fh = openFile($filename);
    unless ($fh)
    {
        print "Failed to open $filename\n";
        return;
    }
    $table->caption($filename);

    # Note: could use Text::CSV directly here on the original file for better performance
    while (my $line = <$fh>)
    {
        chomp $line;
        my @array = TJWH::Basic::csvToArray($line);
        # The first line may be a caption
        if ($#array == 0 and $table->numberOfColumns == 0)
        {
            $table->caption("$filename: $array[0]");
        }
        elsif (scalar $table->columnNames == 0)
        {
            $table->columnNames(@array);
        }
        else
        {
            $table->appendRow(@array);
        }
    }
    close $fh;

    if ($table->numberOfRows)
    {
        $table->autoFormat;
        $table->autoWidth;
    }

    return $table;
}

# Allow reading IXF direct from compressed files
sub readTableFromIXF
{
    my ($filename) = @_;

    unless (-f $filename) {
        print "Warning: $filename is not a file\n";
        return;
    }

    my $table = new TJWH::Table;

    # Don't expect LOBs to load properly if you don't tell the IXF reader
    # where the original file is
    my $fr = IXF::FileRaw->new;
    $fr->filename($filename);

    my $fh = openFile($filename);
    if ($fh)
    {
        $fr->read_from_fh($fh);
        my $f = IXF::File->new($fr);
        $table->caption($filename);
        $table->columnNames($f->columns);
        foreach my $row ($f->rows)
        {
            $table->appendRow(@$row);
        }

        $table->autoFormat if $table->numberOfRows;
        close $fh;
    }

    return $table;
}

sub readTableFromFile
{
    my ($filename) = @_;
    confess "filename is not defined" unless defined $filename;
    unless (-f $filename) {
        cluck "Warning: $filename is not a file\n";
        return;
    }

    my $table;
    if ($filename =~ m/\.ixf(\.(gz|bz2|xz|Z))?$/i) {
        $table = readTableFromIXF($filename);
    } elsif ($filename =~ m/\.csv(\.(gz|bz2|xz|Z))?$/i) {
        $table = readTableFromCSV($filename);
    } elsif ($filename =~ m/.store$/i) {
        eval {
            $table = retrieve($filename);
        };
        if ($@) {
            warn "Failed to retrieve $filename\n$@\n";
            $table = undef;
        }
    } else {
        cluck "Not sure how to read $filename\n";
        return;
    }

    return $table;
}

# Take an array of tables with identical columns, return one new table with
# all the rows from all the tables.
sub coalesceTables {
    my (@rest) = @_;
    return unless @rest;
    foreach my $entry (@rest)
    {
        confess "entry ($entry) is not a TJWH::Table"
            unless blessed $entry and $entry->isa("TJWH::Table");
    }

    my $coalesce = dclone (shift @rest);
    foreach my $entry (@rest)
    {
        $coalesce->appendTable($entry);
    }

    return $coalesce;
}

# ========================================================================
#
# Private subroutines
#
# Get the next word from the input string, returning the remnant as well
sub nextWord
{
    my ($string) = @_;
    confess "String must be defined\n" unless defined $string;
    # If the string is only whitespace or empty, return it
    if ($string =~ m/^(\s*)$/)
    {
        return ($string, undef);
    }
    elsif ($string =~ m/\s*(\S+)\s*(.*)/)
    {
        return ($1, $2);
    }

    print "Unexpected string: $string\n";
    return (undef, undef);
}

sub longestWord
{
    my ($string) = @_;
    confess "String must be defined\n" unless defined $string;
    my $longestWord = "";
    # If the string is only whitespace or empty, return the empty string
    if ($string !~ m/^(\s*)$/)
    {
        my ($current, $rest) = nextWord($string);
        do
        {
            if (length $current > length $longestWord)
            {
                $longestWord = $current;
            }
            ($current, $rest) = nextWord($rest);
        } while (defined $rest);
    }
    return $longestWord;
}
1;
