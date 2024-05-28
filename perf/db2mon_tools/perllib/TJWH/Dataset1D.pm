# -*- cperl -*-

# Represent one dimension of a Gnuplot dataset

use strict;
use warnings;
use Data::Dumper;

package TJWH::Dataset1D;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp qw(cluck confess);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

sub new
{
    my ($class) = @_;

    my $this = {
                data        => [],    # Data points
                filename    => undef, # File where the data can be found
                columnIndex => undef, # Column in the data file (1-index)
                style       => undef, # lines, dots, etc.
                title       => undef, # Name of this data set
                minimum     => undef, # Minimum value to display
                maximum     => undef, # Maximum value to display
                axis        => undef, # One of x1, x2, y1 or y2, or undefined
                other       => undef, # Another TJWH::Dataset1D that this is
                                      # related to (as in X-Y plots)
               };

    bless $this, $class;

    return $this;
}

sub data {
    my ($this, @data) = @_;

    if (scalar @data)
    {
        $this->{data} = [ @data ];
    }

    return @{ $this->{data} };
}

sub number {
    my ($this) = @_;
    return scalar @{ $this->{data} };
}

# Return a specific piece of data
sub dataRow {
    my ($this, $rowNumber) = @_;
    confess "row number must be defined\n" unless defined $rowNumber;
    confess "row number must be an integer\n" unless $rowNumber =~ m/^\d+$/;
    confess "row number out of range\n" unless $rowNumber >= 0 and $rowNumber < $this->number;

    return $this->{data}->[$rowNumber];
}

sub addData
{
    my ($this, @data) = @_;
    confess "No data supplied\n" unless scalar @data;

    push @{ $this->{data} }, @data;

    return $this->data;
}

sub filename {
    my ($this, $filename) = @_;

    if (defined $filename)
    {
        $this->{filename} = $filename;
    }

    return $this->{filename};
}

sub columnIndex {
    my ($this, $columnIndex) = @_;

    if (defined $columnIndex)
    {
        $this->{columnIndex} = $columnIndex;
    }

    return $this->{columnIndex};
}

# Valid styles
# with <style> { {linestyle | ls <line_style>}
#                | {{linetype | lt <line_type>}
#                   {
#                       linewidth | lw <line_width>;
#                   }
#                   {
#                       linecolor | lc <colorspec>;
#                   }
#                   {
#                       pointtype | pt <point_type>;
#                   }
#                   {
#                       pointsize | ps <point_size>;
#                   }
#                   {
#                       fill | fs <fillstyle>;
#                   }
#                   {
#                       nohidden3d;
#                   }
#                   {
#                       nocontours;
#                   }
#                   {
#                       nosurface;
#                   }
#                   {
#                       palette;
#                   }
#                  }
#              }
#     where <style> is one of
#     lines
#     points
#     linespoints
#     dots
#     impulses
#     labels
#     steps
#     fsteps
#     histeps
#     errorbars
#     errorlines
#     financebars
#     vectors
#     xerrorbar
#     xerrorlines
#     xyerrorbars
#     xyerrorlines
#     yerrorbars
#     yerrorlines
#     or
#     boxes
#     boxerrorbars
#     boxxyerrorbars
#     candlesticks
#     filledcurves
#     histograms
#     image
#     rgbimage
#     rgbalpha
#     circles
#     pm3d
sub isValidStyle
{
    my ($this, $style) = @_;
    # FIXME - stub for now
    return 1;
}

sub style {
    my ($this, $style) = @_;

    if (defined $style)
    {
        confess "Bad style $style\n" unless $this->isValidStyle($style);
        $this->{style} = $style;
    }

    return $this->{style};
}

sub title {
    my ($this, $title) = @_;

    if (defined $title)
    {
        $title =~ s/[_^]/ /g; # Don't allow special characters
        $this->{title} = $title;
    }

    return $this->{title};
}

sub minimum {
    my ($this, $minimum) = @_;

    if (defined $minimum)
    {
        if (defined $this->maximum)
        {
            confess "Bad minimum $minimum is more than current maximum: ".$this->maximum."\n"
                unless $minimum > $this->maximum;
        }
        $this->{minimum} = $minimum;
    }

    return $this->{minimum};
}

sub maximum {
    my ($this, $maximum) = @_;

    if (defined $maximum)
    {
        if (defined $this->minimum)
        {
            confess "Bad maximum $maximum is less than current minimum: ".$this->minimum."\n"
                unless $maximum > $this->minimum;
        }
        $this->{maximum} = $maximum;
    }

    return $this->{maximum};
}
sub axis {
    my ($this, $axis) = @_;

    if (defined $axis)
    {
        confess "Bad axis designator: $axis" unless $axis =~ m/^[xy][12]$/;
        $this->{axis} = $axis;

        # Check the axis combination if we have another dataset
        $this->combineAxes($this->other) if defined $this->other;
    }

    return $this->{axis};
}

# If both datasets specify an axis, then we can check and combine them
sub combineAxes
{
    my ($this, $other) = @_;
    confess "Other must have type TJWH::Dataset1D: has ".ref $other."\n"
        unless ref $other eq "TJWH::Dataset1D";

    # Give the caller "undefined" if there is no combination
    return unless defined $this->axis;
    return unless defined $other->axis;

    my $fullAxis;
    my $otherAxis = $this->other->axis;
    if (defined $otherAxis)
    {

        if ($otherAxis =~ m/^x[12]$/)
        {
            if ($this->axis =~ m/^y[12]$/)
            {
                $fullAxis = "$otherAxis".$this->axis;
            }
        }
        elsif ($otherAxis =~ m/^y[12]$/)
        {
            if ($this->axis =~ m/^x[12]$/)
            {
                $fullAxis = $this->axis."$otherAxis";
            }
        }
        confess "Incompatible axes:\n  this=".$this->axis."\n  other=$otherAxis\n"
            unless defined $fullAxis;
    }
    return $fullAxis;
}

sub other {
    my ($this, $other) = @_;

    if (defined $other)
    {
        confess "Other must have type TJWH::Dataset1D: has ".ref $other."\n"
            unless ref $other eq "TJWH::Dataset1D";
        confess "Data point mismatch:\n".
            "  this ".(scalar $this->data)." datapoints\n".
                "  other ".(scalar $other->data)." datapoints\n".
                    "this = ". Data::Dumper::Dumper $this.
                        "\nother = ".Data::Dumper::Dumper $other
                    unless scalar $this->data == scalar $other->data;
        $this->{other} = $other;
    }

    return $this->{other};
}

# Given the name of the data file, built a plot line suitable for gnuplot. The
# column index for the data file must already have been set for this dataset
sub plotLine
{
    my ($this, $dataName) = @_;
    confess "No column index has been set for this" unless defined $this->columnIndex;
    confess "No related dataset has been set" unless defined $this->other;
    confess "No column index has been set for other" unless defined $this->other->columnIndex;

    $dataName = $this->filename unless defined $dataName;
    confess "dataName must be defined\n" unless defined $dataName;
    confess "dataName $dataName is not a file\n" unless -f $dataName;

    my $fullAxis = $this->combineAxes($this->other);
    my $string = "\"".$dataName."\"".
        (
         " using ".$this->other->columnIndex.":".$this->columnIndex.
         (
          # Set the style
          $this->style ?
          " with ".$this->style :
          ""
         ).
         (
          # Name for this data set - will appear in legend
          $this->title ?
          " title \"".$this->title."\"" :
          ""
         ).
         (
          # Build an axes string
          defined $fullAxis ?
          " axes $fullAxis" :
          ""
         )
        );
    return $string;
}

1;
