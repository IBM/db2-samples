# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;
use Carp qw(cluck confess);

package TJWH::Formats;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK $debug);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand

# This class is intended to help format data.
sub new
{
    my ($class) = @_;

    my $this = {
                'name'     => "-",      # Name of the column
                'string'   => "s",      # string formatter
                'number'   => "f",      # number formatter
                'width'    => 12,       # width of the column in characters
                'scale'    => 3,        # number of decimal places
                'data'     => 'number', # default to 'data is a number'
                'substring' => undef,   # Whether to truncate the data to the width
               };

    bless $this, $class;
    return $this;
}

sub name
{
    my ($this, $name) = @_;

    if (defined $name)
    {
        $this->{name} = $name;
    }
    return $this->{name};
}

sub width
{
    my ($this, $width) = @_;

    if (defined $width)
    {
        $this->{width} = $width;
    }
    return $this->{width};
}

sub scale
{
    my ($this, $scale) = @_;

    if (defined $scale)
    {
        if ($scale =~ m/^\d+$/)
        {
            $this->{scale} = $scale;
        }
    }
    Carp::confess "Bad value for scale: ".$this->{scale}."\n" unless $this->{scale} =~ m/^\d+$/;
    return $this->{scale};
}

sub isNumber
{
    my ($this, $number) = @_;

    if (defined $number)
    {
        if ($number)
        {
            $this->{data} = 'number';
        }
    }
    return $this->{data} eq 'number';
}

sub isString
{
    my ($this, $string) = @_;

    if (defined $string)
    {
        if ($string)
        {
            $this->{data} = 'string';
        }
    }
    return $this->{data} eq 'string';
}

sub formatString
{
    my $this = shift;
    return "\%$this->{width}$this->{string}"
}

sub substring
{
    my ($this, $substring) = @_;

    if (defined $substring)
    {
        if ($substring eq "last" or $substring eq "first")
        {
            $this->{substring} = $substring;
        }
        else
        {
            Carp::confess "Unrecognised substring type: $substring\n";
        }
    }
    return $this->{substring};
}

sub formatNumber
{
    my $this = shift;
    my $format;
    if (defined $this->{scale} and $this->{scale} > 0)
    {
        $format = "\%$this->{width}.$this->{scale}$this->{number}"
    }
    else
    {
        $format = "\%$this->{width}$this->{number}";
    }
    print "DEBUG: formatNumber returns $format\n" if $debug;
    return $format;
}

# For data, we'll use whatever representation we have described.
# Zero padding is not yet supported
sub formatData
{
    my ($this, $format) = @_;
    if (defined $format)
    {
        print Data::Dumper::Dumper "formatData entry: ", $format if $debug;
        # Floating point or decimal style representations
        if ($format =~ m/^\s*[%](([-+]?\d+)[.](\d+))?([aAeEfFgG])\s*$/)
        {
            if (defined $1) {
                $this->{width} = $2;
                $this->{scale} = $3;
                $this->{scale} = 0 unless defined $this->{scale};
            } else {
                # Sensible defaults for unspecified width.scale
                $this->{width} = 4;
                $this->{scale} = 3;
            }
            $this->{number} = $4;
            print "DEBUG: $format ", $this->{width}, $this->{scale}, $this->{number}, "\n" if $debug;
            $this->isNumber(1);
        }
        # Integer and whole number representaitons, possibly in other bases (octal, hexadecimal)
        elsif ($format =~ m/^\s*[%]([-+]?\d+)?([diIouxXeaAEfFgG])\s*$/)
        {
            if (defined $1) {
                $this->{width} = $1;
            } else {
                $this->{width} = 4; # Default to 4 chars if no length is specified
            }
            $this->{scale} = 0;
            $this->{number} = $2;
            $this->isNumber(1);
            print "DEBUG: $format ", $this->{width}, $this->{scale}, $this->{number}, "\n" if $debug;
        }
        elsif ($format =~ m/^\s*[%]([-+]?\d*)([s])\s*$/)
        {
            $this->{width} = $1 if defined $1;
            $this->{string} = $2;
            $this->isString(1);
        }
        else
        {
            Carp::confess "Unsupported format $format\n";
        }
        print Data::Dumper::Dumper "formatData exit: ", $format if $debug;
    }

    if ($this->isString)
    {
        return $this->formatString;
    }
    elsif ($this->isNumber)
    {
        return $this->formatNumber;
    }
    return undef;
}

# Apply any formatting to the actual value (such as substring)
sub formatValue
{
    my ($this, $value) = @_;

    my $result = $value;
    if ($this->isString)
    {
        if (defined $this->{substring})
        {
            my $width = abs $this->{width};
            if (defined $value)
            {
                if (length $value > $width)
                {
                    if ($this->{substring} eq "first")
                    {
                        $result = substr $value, 0, $width;
                    }
                    elsif ($this->{substring} eq "last")
                    {
                        $result = substr $value, $width - length $value; # intentionally negative
                    }
                    else
                    {
                        Carp::confess "Unrecognised type for substring",$this->{substring},"\n";
                    }
                }
            }
            else
            {
               $result = "";
            }
        }
    }
    return $result;
}

# For headers, we'll always use the string representation
sub formatHeader
{
    my $this = shift;
    return $this->formatString;
}

sub dump
{
    my $this = shift;
    print Data::Dumper::Dumper $this;
    return;
}

1;

