# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

# Abstract Base Class for all Plot objects

package TJWH::PlotABC;
use Carp qw(cluck confess);
use TJWH::Basic;
use TJWH::PlotLabels;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw();                # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

my $gnuplotSupportsMouse;
my $gnuplotSupportsBoxPlot;
BEGIN
{
    my $rc = system "gnuplot -e 'set terminal svg mouse enhanced size 800 600' 2> /dev/null";
    $gnuplotSupportsMouse = 1 if $rc == 0;
    $rc = system "gnuplot -e 'set style boxplot' 2> /dev/null";
    $gnuplotSupportsBoxPlot = 1 if $rc == 0;
}

sub isMouseSupported
{
    return $gnuplotSupportsMouse;
}

sub stripFormattingChars
{
    my ($string) = @_;

    if (defined $string)
    {
        # Certain characters are interpretted as text formatting.
        # This includes:
        #  _ subscript
        #  ^ superscript
        #  / italics
        # Plus we really don't want quotes
        #
        # Strip them
        $string =~ s#[_^/'"]# #g;
    }
    return $string;
}

sub new
{
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $this = {
                # Outputs
                filename   => undef, # Output filename
                prefix     => undef, # Filename without the trailing extension
                extension  => undef, # Output extension (svg, png, etc)
                scriptName => undef, # gnuplot script
                dataName   => undef, # data file generated from chosen columns
                                     # in table
                keep       => undef, # If not defined, the gnuplot files will
                                     # be deleted after use
                # Graph attributes
                title      => undef,
                xAxisLabel => undef,
                yAxisLabel => undef,
                xMin       => undef,
                xMax       => undef,
                yMin       => undef,
                yMax       => undef,
                xTics      => [],    # Xtics, if needed
                xTicsLimit => 32,    # Maximum number of xTics
                yTics      => [],    # Xtics, if needed
                yTicsLimit => 32,    # Maximum number of xTics

                labels     => [],    # Array of TJWH::PlotLabels

                # Plot attributes
                width      => 1000,  # Width of plot in pixels
                height     => 800,   # Height of plot in pixels
                extras     => undef, # Anything to add before the plot command
                terminal   => undef, # terminal to use for gnuplot output
               };

    bless $this, $class;

    $this->keep if $debug or $ENV{KEEP_GNUPLOT_SCRIPTS};

    return $this;
}

sub filename {
    my ($this, $filename) = @_;

    if (defined $filename)
    {
        $this->{filename} = $filename;
        # If this filename has an extension, set it
        if ($filename =~ m/^(.*)\.([^.]+)$/)
        {
            $this->{prefix} = $1;
            $this->{extension} = $2;
        }
        else
        {
            # Default to SVG
            $this->{prefix} = $filename;
            $this->{extension} = "svg";
        }

        # Now select a terminal for the chart output
        $this->setTerminal;
    }

    return $this->{filename};
}

sub prefix {
    my ($this) = @_;

    return $this->{prefix};
}

sub extension {
    my ($this) = @_;

    return $this->{extension};
}

sub scriptName {
    my ($this, $scriptName) = @_;

    if (defined $scriptName)
    {
        # Set and secure the script
        $this->{scriptName} = $scriptName;
        my $fh;
        open $fh, ">$scriptName" or confess "Failed to write empty script $scriptName: $!";
        close $fh;
    }

    return $this->{scriptName};
}

sub dataName {
    my ($this, $dataName) = @_;

    if (defined $dataName)
    {
        $this->{dataName} = $dataName;
    }

    return $this->{dataName};
}

sub keep {
    my ($this) = @_;

    $this->{keep} = 1;

    return $this->{keep};
}

sub remove {
    my ($this) = @_;

    $this->{keep} = undef;

    return $this->{keep};
}

sub title {
    my ($this, $title) = @_;

    if (defined $title)
    {
        # Certain characters are interpretted as text formatting. Strip them
        $this->{title} = stripFormattingChars($title);
    }

    return $this->{title};
}

sub xAxisLabel {
    my ($this, $xAxisLabel) = @_;

    if (defined $xAxisLabel)
    {
        $this->{xAxisLabel} = stripFormattingChars($xAxisLabel);
    }

    return $this->{xAxisLabel};
}

sub yAxisLabel {
    my ($this, $yAxisLabel) = @_;

    if (defined $yAxisLabel)
    {
        $this->{yAxisLabel} = stripFormattingChars($yAxisLabel);
    }

    return $this->{yAxisLabel};
}

sub xMin {
    my ($this, $xMin) = @_;

    if (defined $xMin)
    {
        $this->{xMin} = $xMin;
    }

    return $this->{xMin};
}

sub xMax {
    my ($this, $xMax) = @_;

    if (defined $xMax)
    {
        $this->{xMax} = $xMax;
    }

    return $this->{xMax};
}

sub yMin {
    my ($this, $yMin) = @_;

    if (defined $yMin)
    {
        $this->{yMin} = $yMin;
    }

    return $this->{yMin};
}

sub yMax {
    my ($this, $yMax) = @_;

    if (defined $yMax)
    {
        $this->{yMax} = $yMax;
    }

    return $this->{yMax};
}

sub xTics {
    my ($this, @xTics) = @_;

    if (@xTics)
    {
        $this->{xTics} = [];
        $this->addXTics(@xTics);
    }

    return @{ $this->{xTics} };
}

sub addXTics
{
    my ($this, @xTics) = @_;

    foreach my $xTic (@xTics)
    {
        confess "xTic entry must have type ARRAY\n".Data::Dumper::Dumper $xTic
            unless ref $xTic eq 'ARRAY';
        confess "xTic entry must have exactly two members\n".Data::Dumper::Dumper $xTic
            unless $#{ $xTic } == 1;

        $xTic->[0] = stripFormattingChars($xTic->[0]);

        push @{ $this->{xTics} }, $xTic;
    }

    return @{ $this->{xTics} };
}

sub xTicsLimit {
    my ($this, $xTicsLimit) = @_;

    if (defined $xTicsLimit)
    {
        if (isaNumber($xTicsLimit) and
            $xTicsLimit > 0)
        {
            $this->{xTicsLimit} = $xTicsLimit;
        }
        else
        {
            confess "Bad xtics limit: $xTicsLimit\n";
        }
    }
    return $this->{xTicsLimit};
}

sub yTics {
    my ($this, @yTics) = @_;

    if (@yTics)
    {
        $this->{yTics} = [];
        $this->addYTics(@yTics);
    }

    return @{ $this->{yTics} };
}

sub addYTics
{
    my ($this, @yTics) = @_;

    foreach my $yTic (@yTics)
    {
        confess "yTic entry must have type ARRAY\n".Data::Dumper::Dumper $yTic
            unless ref $yTic eq 'ARRAY';
        confess "yTic entry must have exactly two members\n".Data::Dumper::Dumper $yTic
            unless $#{ $yTic } == 1;

        $yTic->[0] = stripFormattingChars($yTic->[0]);

        push @{ $this->{yTics} }, @yTics;
    }

    return @{ $this->{yTics} };
}

sub yTicsLimit {
    my ($this, $yTicsLimit) = @_;

    if (defined $yTicsLimit)
    {
        if (isaNumber($yTicsLimit) and
            $yTicsLimit > 0)
        {
            $this->{yTicsLimit} = $yTicsLimit;
        }
        else
        {
            confess "Bad ytics limit: $yTicsLimit\n";
        }
    }
    return $this->{yTicsLimit};
}

sub labels {
    my ($this, @labels) = @_;

    if (@labels)
    {
        $this->{labels} = [];
        $this->addLabel(@labels);
    }

    return @{ $this->{labels} };
}

sub addLabels {
    my ($this, @labels) = @_;

    foreach my $label (@labels)
    {
        confess "label ($label) is not a TJWH::PlotLabels"
            unless ref $label eq "TJWH::PlotLabels";
        push @{ $this->{labels} }, $label;
    }

    return @{ $this->{labels} };
}

sub width {
    my ($this, $width) = @_;

    if (defined $width)
    {
        confess "Bad width $width" unless $width =~ m/^\d+$/ and $width > 50;
        $this->{width} = $width;
    }

    return $this->{width};
}

sub height {
    my ($this, $height) = @_;

    if (defined $height)
    {
        confess "Bad height $height" unless $height =~ m/^\d+$/ and $height > 50;
        $this->{height} = $height;
    }

    return $this->{height};
}

# We keep adding extras to the existing string
sub extras {
    my ($this, $extras) = @_;

    if (defined $extras)
    {
        $this->{extras} .= $extras;
    }

    return $this->{extras};
}

sub terminal {
    my ($this, $terminal) = @_;

    if (defined $terminal)
    {
        $this->{terminal} = $terminal;
    }

    return $this->{terminal};
}

sub setTerminal
{
    my ($this) = @_;
    confess "Filename must be defined\n" unless defined $this->filename;
    confess "Extension must be defined\n" unless defined $this->extension;

    my $output = "";
    # Safest to set the terminal first
    if ($this->extension eq "eps")
    {
        $output .= "set terminal postscript eps color\n";
    }
    elsif ($this->extension eq "svg")
    {
        $output .= "set terminal svg size $this->{width} $this->{height} ".
            ($gnuplotSupportsMouse ? "mouse " : "").
                "enhanced font \"Helvetica,12\"\n";
    }
    elsif ($this->extension eq "js")
    {
        # Javascript function names can be all sorts of things. All we need is
        # some sanity so stick to basic alphanumeric plus underscore.
        my $function = $this->prefix;
        $function =~ s/[^a-zA-Z0-9_]/_/g;
        $output .= "set terminal canvas solid butt size $this->{width},$this->{height} fsize 10".
            " lw 1 fontscale 1 name \"$function\" jsdir \"http://so3.torolab.ibm.com/js\"\n";
    }
    elsif ($this->extension eq "html")
    {
        # Javascript function names can be all sorts of things. All we need is
        # some sanity so stick to basic alphanumeric plus underscore.
        my $function = $this->prefix;
        $function =~ s/[^a-zA-Z0-9_]/_/g;
        $output .= "set terminal canvas solid butt size $this->{width},$this->{height} fsize 10".
            " lw 1 fontscale 1 standalone mousing jsdir \"http://so3.torolab.ibm.com/js\"\n";
    }
    elsif ($this->extension eq "png")
    {
        $output .= "set terminal png size $this->{width},$this->{height} \n";
    }
    else
    {
        confess "Unsupported extension: $this->{extension}\n";
    }

    $this->terminal($output);

    return $this->terminal;
}

sub setXRange
{
    my ($this) = @_;
    my $output = "";
    if ($this->xMin or $this->xMax)
    {
        my $xMin = $this->xMin;
        $xMin = "" unless defined $xMin;
        my $xMax = $this->xMax;
        $xMax = "" unless defined $xMax;
        $output = "set xrange [$xMin:$xMax]\n";
    }

    return $output;
}

sub setYRange
{
    my ($this) = @_;
    my $output = "";
    if ($this->yMin or $this->yMax)
    {
        my $yMin = $this->yMin;
        $yMin = "" unless defined $yMin;
        my $yMax = $this->yMax;
        $yMax = "" unless defined $yMax;
        $output = "set yrange [$yMin:$yMax]\n";
    }

    return $output;
}

sub DESTROY
{
    my ($this) = @_;

    my $script = $this->scriptName;
    if (defined $script and -f $script)
    {
        if ($this->{keep})
        {
            print "Kept Gnuplot script: $script\n";
        }
        else
        {
            unlink $script;
        }
    }

    my $data = $this->dataName;
    if (defined $data and -f $data)
    {
        if ($this->{keep})
        {
            print "Kept Gnuplot data file: $data\n";
        }
        else
        {
            unlink $data;
        }
    }

    return;
}

sub executeScript
{
    my ($this) = @_;

    my $rc;
    if (defined $this->scriptName)
    {
        my $script = $this->scriptName;
        $rc = executeCommand("gnuplot $script");
    }

    return $rc;
}

1;
