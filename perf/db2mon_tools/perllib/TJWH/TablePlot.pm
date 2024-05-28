# -*- cperl -*-

# This is equivalent to the plotChart method in TJWH::Table, except we are
# aiming to produce the Gnuplot output directly, rather than use Chart::Graph::Gnuplot

use strict;
use warnings;
use Data::Dumper;

package TJWH::TablePlot;
require Exporter;
use Carp qw(cluck confess);
use File::Temp;
use Scalar::Util qw(blessed);
use TJWH::Basic;
use TJWH::BasicStats;
use TJWH::TimeBits;
use TJWH::Dataset1D;
use TJWH::PlotABC;
use vars qw(@ISA);
@ISA = qw(TJWH::PlotABC);

our $debug;
our $verbose;

my $gnuplotSupportsMouse;
BEGIN
{
    my $rc = system "gnuplot -e 'set terminal svg mouse enhanced size 800,600' 2> /dev/null";
    $gnuplotSupportsMouse = 1 if $rc == 0;
}

sub new
{
    my ($proto, $table) = @_;
    my $class = ref($proto) || $proto;

    my $this = $class->SUPER::new;

    # Original data source
    $this->{table} = undef;
    # type Graph data
    $this->{xAxis} = undef;    # TJWH::Dataset1D
    $this->{yAxes} = [];       # Array of TJWH::Dataset1D
    $this->{style} = "points"; # Default to simple points for chart

    bless $this, $class; # Reconsecrate
    $this->table($table);

    return $this;
}

sub style {
    my ($this, $style) = @_;

    if (defined $style)
    {
        # Should check this is a valid Gnuplot style...
        $this->{style} = $style;
    }

    return $this->{style};
}

# The same arguments as TJWH::Table::plotChart
sub plotChart
{
    my ($this,
        $table,
        $title,
        $filename,
        $style,
        $xAxisLabel, $yAxisLabel,
        $xAxis, @yAxes) = @_;

    unlink $filename if -f $filename;

    $this->setupPlot($table,
                     $title, $filename, $style,
                     $xAxisLabel, $yAxisLabel,
                     $xAxis, @yAxes);
    $this->generateScript;
    $this->executeScript;

    return 1 if -f $filename and -s $filename;
    return;
}

sub createChart
{
    my ($this,
        $optionsRef,
        $xAxis, @yAxes,
       ) = @_;

    confess "xAxis is not defined" unless defined $xAxis;
    confess "yAxes is not defined" unless @yAxes;

    if ($debug)
    {
        print "TJWH::TablePlot::createChart ";
        print Data::Dumper::Dumper $optionsRef;
        print "\n";
    }

    # Call the appropriate methods, supplying the appropriate arguments
    foreach my $key (keys %$optionsRef)
    {
        print "eval \$this->$key(\"$optionsRef->{$key}\")\n" if $debug;
        eval "\$this->$key(\"$optionsRef->{$key}\")";
        if ($@)
        {
            cluck $@;
            confess "Failed to call $key method with arguments $optionsRef->{$key}\n";
        }
    }

    confess "this->table is not defined" unless defined $this->table;
    my $table = $this->table;
    unless ($table->numberOfRows)
    {
        warn "No data for $table->{caption}\n";
        return;
    }

    # Take the ranges from the table
    $this->xMin($table->xmin);
    $this->xMax($table->xmax);
    $this->yMin($table->ymin);
    $this->yMax($table->ymax);

    # Any chart attributes defined in table info
    $this->width($table->{info}->{chartWidth});
    $this->height($table->{info}->{chartHeight});

    $this->buildDatasets($xAxis, @yAxes);
    $this->setTerminal;

    # keep the scripts if we are debugging.
    $this->keep if $debug;
    $this->generateScript;
    $this->executeScript;
    my $filename = $this->filename;
    if (-f $filename and -s $filename)
    {
        print "Chart $filename created successfully\n";
        return 1;
    }
    else
    {
        print "Chart $filename failed\n";
        return 0;
    }
    return;
}

sub setupPlot
{
    my ($this,
        $table,
        $title,
        $filename,
        $style,
        $xAxisLabel, $yAxisLabel,
        $xAxis, @yAxes) = @_;

    $this->table($table);
    $this->title($title);
    $this->filename($filename);
    $this->xAxisLabel($xAxisLabel);
    $this->yAxisLabel($yAxisLabel);
    $this->style($style);

    # Take the ranges from the table
    $this->xMin($table->xmin);
    $this->xMax($table->xmax);
    $this->yMin($table->ymin);
    $this->yMax($table->ymax);

    # Any chart attributes defined in table info
    $this->width($table->{info}->{chartWidth});
    $this->height($table->{info}->{chartHeight});

    $this->buildDatasets($xAxis, @yAxes);

    return $this;
}

sub buildDatasets
{
    my ($this, $xAxis, @yAxes) = @_;
    confess "this is not defined" unless defined $this;
    confess "xAxis is not defined" unless defined $xAxis;
    confess "yAxes is not defined" unless @yAxes;

    my $table = $this->table;
    confess "table is not defined" unless defined $table;
    unless ($table->numberOfRows)
    {
        cluck "Table $table->{caption} has no data to chart\n";
        return;
    }

    # Build the data sets
    if ($xAxis ne "generate")
    {
        my @xdata = ();
        # If the xAxis is numeric, we'll use it as it is
        if ($table->columnFormat($xAxis) !~ m/s$/)
        {
            @xdata = $table->getNumbersForColumn($xAxis);
        }
        else
        {
            # If the x-axis looks like it is a time axis, then convert the
            # data to the epoch seconds
            if (defined $this->xAxisLabel and
                $this->xAxisLabel =~ m/time/i)
            {
                foreach my $time ($table->getColumn($xAxis))
                {
                    my $timebits = getTimeFromString($time);
                    if (defined $timebits)
                    {
                        # Pretend this is UTC as gnuplot will assume it is
                        # local and will convert to UTC.
                        $timebits->utc(1);
                        push @xdata, $timebits->epoch;
                    }
                }
            }
            else
            {
                # if the xAxis is a string, we'll convert it to numeric and build the
                # xtics for the mapping.
                print "TJWH::Table: data is strings: format=".
                    $table->columnFormat($xAxis)."\n"
                        if defined $debug;

                my @xNames = $table->getColumn($xAxis);
                # Avoid subscript/superscript characters
                foreach (@xNames)
                {
                    s/[_^]/ /g;
                }
                @xdata = 0 .. $#xNames;
                my @xTics = ();

                # Now if there are too many entries, then don't include
                # everything.
                if ($#xdata <= $this->xTicsLimit)
                {
                    push @xTics, map { [ $xNames[$_], $_ ] } @xdata;
                }
                else
                {
                    my $step = int(scalar @xdata / $this->xTicsLimit);
                    for (my $i = 0; $i <= $#xdata; $i += $step)
                    {
                        push @xTics, [ $xNames[$i], $i ];
                    }
                }
                $this->xTics(@xTics);
            }
        }
        if (@xdata)
        {
            $this->xAxis($table->columnName($xAxis), @xdata);
        }
        else
        {
            # No x-data points here, so nothing to do.
            cluck "No data for table ".$table->caption." with xAxis $xAxis\n";
            return;
        }
    }

    foreach my $yAxis (@yAxes)
    {
        my @ydata = $table->getNumeric($yAxis);
        if ($xAxis eq "generate")
        {
            $this->xAxis("generated", 0 .. $#ydata);
            $xAxis = -1; # So subsequent passes through this loop don't repeat
                         # this operation
        }
        unless (@ydata)
        {
            warn "There are no numbers in column $yAxis: ".
                $table->columnName($yAxis)."\n";
            next;
        }
        $this->addYAxis($table->columnName($yAxis),
                        @ydata);
    }
    return $this;
}

sub generateScript
{
    my ($this) = @_;
    return $this if defined $this->scriptName;

    my $tmpDir = "$ENV{'HOME'}/tmp";
    mkdir $tmpDir unless -d $tmpDir;
    confess "Can't create $tmpDir\n" unless -d $tmpDir;

    unless ($this->xAxis)
    {
        print "Warning: There is no data to plot\n";
        print Data::Dumper::Dumper $this if $debug;
        # Ensure that there is no old script name left over.
        $this->{scriptName} = undef;
        return;
    }

    my $counter = 0;
    while (-f "$tmpDir/gnuplot-script-$counter.plt")
    {
        $counter++;
        confess "Too many script files in $tmpDir: $counter\n" if $counter > 1000;
    }
    $this->scriptName("$tmpDir/gnuplot-script-$counter.plt");

    # Write all the data we have stored into the data set file so that gnuplot
    # can find it
    $this->generateDataset;

    # Rebuild the terminal
    $this->setTerminal;

    # Write a Gnuplot script
    open SCRIPT, ">".$this->scriptName or
        confess "Failed to open $this->{scriptName} for write: $!\n";
    print SCRIPT "# Gnuplot script written by TJWH::TablePlot\n".
        "# Based on\n# ".($this->table->caption)."\n";

    # If the xaxis looks like Time, set the time defaults
    if ($this->xAxisLabel =~ m/time|epoch/i)
    {
        print SCRIPT
            ("set xdata time\n".     # Format xaxis as a time axis
             "set timefmt \"%s\"\n". # Seconds since 1970
             "set format x \"%y-%m-%d\\n%H:%M:%S\"\n");
        my $elapsed = range($this->xAxis->data);
        my $xInterval = ( int( $elapsed / 60 ) + 1 ) * 10;
        print SCRIPT "set xtics $xInterval\n";
    }

    print SCRIPT "set title \"".$this->title."\"\n" if $this->title;
    print SCRIPT "set xlabel \"".$this->xAxisLabel."\"\n" if $this->xAxisLabel;
    print SCRIPT "set ylabel \"".$this->yAxisLabel."\"\n" if $this->yAxisLabel;

    if ($this->xTics)
    {
        print SCRIPT "set xtics rotate by 90\n";
        print SCRIPT "set xtics (".
            (join ", ",
             map { "\"$_->[0]\" $_->[1]" } $this->xTics
            ).")\n";
    }

    if ($this->yTics)
    {
        print SCRIPT "set ytics (".
            (join ", ",
             map { "\"$_->[0]\" $_->[1]" } $this->yTics
            ).")\n";
    }

    if ($this->xMin or $this->xMax)
    {
        my $xMin = $this->xMin;
        $xMin = "" unless defined $xMin;
        my $xMax = $this->xMax;
        $xMax = "" unless defined $xMax;
        # Time formats must be quoted, even epoch times.
        if ($this->xAxisLabel =~ m/time/i)
        {
            print SCRIPT "set xrange [\"$xMin\":\"$xMax\"]\n";
        }
        else
        {
            print SCRIPT "set xrange [$xMin:$xMax]\n";
        }
    }

    print SCRIPT $this->setYRange;
    print SCRIPT $this->extras if $this->extras;
    print SCRIPT $this->terminal;
    print SCRIPT "set output \"$this->{filename}\"\n";

    # Build the plot command with the appropriate styles, data set titles, etc.
    print SCRIPT $this->getPlotline;

    # If we have labels, print them now
    foreach my $label ($this->labels)
    {
        print SCRIPT $label->line."\n";
    }

    close SCRIPT;

    return $this;
}

sub getPlotline
{
    my ($this) = @_;

    # Apply the current axis style before plotting - it may have changed since
    # the axes were created
    foreach my $axis ($this->yAxes)
    {
        $axis->style($this->style);
    }

    return "plot ".
        (join ", \\\n     ",
         map { $_->plotLine } $this->yAxes).
             "\n";
}

sub generateDataset
{
    my ($this) = @_;
    return $this if defined $this->{dataName};

    # All the data placed in here will be written out to a data file for
    # gnuplot to read.
    my @dataset = ($this->xAxis, $this->yAxes);

    $this->{dataName} = "$this->{scriptName}.data";
    open DATASET, ">$this->{dataName}"
        or confess "Failed to open $this->{scriptName}.data for write\n";

    print DATASET "# Dataset from\n# ".$this->table->caption."\n";

    # Numeric data poses no issues but strings must be delimited by quotes if
    # they include whitespace
    # Gnuplot can take undefined values in data sets - these are denoted by ?
    # Lines drawn will skip over undefined values
    foreach my $rowIndex (0 .. ($this->xAxis->number - 1))
    {
        print DATASET join " ", map { defined $_ ? $_ : '?' } map { $_->dataRow($rowIndex) } @dataset;
        print DATASET "\n";
    }
    close DATASET;

    # Tell the datasets where their data is stored
    map { $_->filename($this->{dataName}) } @dataset;

    return $this;
}

sub table
{
    my ($this, $table) = @_;

    if (defined $table)
    {
        confess "table is not a TJWH::Table" unless blessed $table and $table->isa('TJWH::Table');
        $this->{table} = $table;
    }

    return $this->{table};
}

sub xAxis {
    my ($this, $name, @data) = @_;
    if (defined $name)
    {
        confess "No data points specified for x axis" unless scalar @data;
        my $dataset = new TJWH::Dataset1D;
        $dataset->title($name);
        $dataset->data(@data);
        $dataset->columnIndex(1);
        $dataset->axis("x1"); # Normal x axis
        $this->{xAxis} = $dataset;
    }

    return $this->{xAxis};
}

sub yAxes {
    my ($this) = @_;

    return @{ $this->{yAxes} };
}

sub xAxisName {
    my ($this) = @_;

    return $this->xAxis->title;
}

sub yAxesNames {
    my ($this, @yAxesNames) = @_;

    if (scalar @yAxesNames)
    {
        $this->{yAxesNames} = [ @yAxesNames ];
    }

    return map { $_->title } @{ $this->{yAxes} };
}

sub addYAxis {
    my ($this, $name, @yAxis) = @_;
    confess "yAxis name not specified\n" unless defined $name;
    confess "yAxis data points not specified\n" unless scalar @yAxis;
    confess "xAxis data points must be defined first\n" unless defined $this->xAxis;

    my $dataset = new TJWH::Dataset1D;
    $dataset->data(@yAxis);
    $dataset->axis("y1"); # Normal, left-hand side y-axis
    $dataset->style($this->style);
    $dataset->title($name);
    $dataset->other($this->xAxis);
    $dataset->columnIndex( 2 + $this->numberOfYAxes );

    push @{ $this->{yAxes} }, $dataset;

    return @{ $this->{yAxes} };
}

sub numberOfYAxes
{
    my ($this) = @_;
    return scalar @{ $this->{yAxes} };
}

1;
