# -*- cperl -*-

use strict;
use warnings;
use utf8;
binmode( STDOUT, 'utf8:' ); # Allow output of UTF8 to STDOUT

package TJWH::BasicStats;
require Exporter;
use TJWH::Basic qw(isaNumber);
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(
                   count
                   mean
                   variance
                   cofv
                   stdev
                   sum
                   minimum
                   maximum
                   front
                   back
                   range
                   median
                   mad
                   mode
                   cov
                   average
                   total
                   same
                   normalRange
                   madRange
                   estimateMean
              ); # symbols to be exported always
@EXPORT_OK = qw($debug sumOfSquares);        # symbols to be exported on demand

our $debug = 0;
our $precision = '%.3f';

# ------------------------------------------------------------------------
#
# Statistics subroutines
#
# Count the number of DEFINED values
sub count
{
    return scalar grep { defined $_ } @_
}

# The mean (or "average" to the lay person)
sub mean
{
    my @numbers = grep { isaNumber($_) } @_;

    # If we have inputs, then we can calculate a mean
    if (scalar @numbers > 0.0)
    {
        return sum(@numbers)/count(@numbers);
    }
    else
    {
        return undef;
    }
}

# Sample variance (we are estimating, not measuring a population)
sub variance
{
    my @numbers = grep { isaNumber($_) } @_;
    my $number = count(@numbers);
    # We must have at least two points for a positive variance
    if ($number > 1)
    {
        return (sumOfSquares(@numbers)/($number - 1)) - ($number)*mean(@numbers)*mean(@numbers)/($number - 1);
    }
    else
    {
        # for 1 point, the variance is 0 by definition
        return 0.0;
    }
}

# Coefficient of Variance (NaN variant)
sub cofv
{
    my @numbers = grep { isaNumber($_) } @_;
    my $mean = mean(@numbers);
    my $stdev = stdev(@numbers);

    if (defined $mean and defined $stdev)
    {
        if ($mean != 0)
        {
            return $stdev/$mean;
        }
        else
        {
            return "NaN";
        }
    }

    return;
}

# Coefficient of Variance (zero variant)
sub cov
{
    my @numbers = grep { isaNumber($_) } @_;
    my $mean = mean(@numbers);
    my $stdev = stdev(@numbers);

    if ($mean != 0)
    {
        return $stdev/$mean;
    }
    else
    {
        return 0;
    }

    return;
}

# Standard deviation based on _sample_ variance
sub stdev
{
    my @numbers = grep { isaNumber($_) } @_;
    my $variance = variance(@numbers);
    # Occasionally numerical underflow makes the variance go slightly
    # negative
    return sqrt $variance if $variance >= 0;
    return 0;
}

# Simple sum of an array
sub sum
{
    my $total = 0;
    my @numbers = grep { isaNumber($_) } @_;
    foreach (@numbers)
    {
        $total += $_ if defined $_;
    }
    return $total;
}

# Simple sum of squares
sub sumOfSquares
{
    my @numbers = grep { isaNumber($_) } @_;
    my $total = 0;
    foreach (@numbers)
    {
        $total += ($_)*($_) if defined $_;
    }
    return $total;
}

# Minimum of an array of numbers
sub minimum
{
    my ($minimum, @rest) = @_;
    foreach my $value (grep { isaNumber($_) } @rest)
    {
        if ($minimum > $value)
        {
            $minimum = $value;
        }
    }

    return $minimum;
}

# Maximum of an array of numbers
sub maximum
{
    my ($maximum, @rest) = @_;
    foreach my $value (grep { isaNumber($_) } @rest)
    {
        if ($maximum < $value)
        {
            $maximum = $value;
        }
    }
    return $maximum;
}

# Front of an lexically ordered array (first)
sub front
{
    my ($front, @rest) = @_;
    foreach my $value (@rest)
    {
        if ($front gt $value)
        {
            $front = $value;
        }
    }

    return $front;
}

# Back of a lexically ordered array (last)
sub back
{
    my ($back, @rest) = @_;
    foreach my $value (@rest)
    {
        if ($back lt $value)
        {
            $back = $value;
        }
    }
    return $back;
}

# Difference between highest and lowest value
sub range
{
    my @rest = @_;

    return maximum(@rest) - minimum(@rest);
}

# Median value from an array
sub median
{
    my @rest = sort { $a <=> $b } grep { isaNumber($_) } grep { defined $_ } @_;
    my $median;
    my $middle = int (scalar @rest / 2); # Note this rounds DOWN
    if (scalar @rest % 2 == 1)
    {
        # If the array has an odd number of values, then the middle value is correct
        return $rest[$middle];
    }
    else
    {
        # For an even length list, the mean of the two middle values should be returned
        return ($rest[$middle] + $rest[$middle - 1])/2;
    }

    return undef;
}
# Median Absolute Deviation
# https://en.wikipedia.org/wiki/Median_absolute_deviation
# Subtract the median from all the values, return the median of the resulting set.
sub mad
{
    my @rest = sort { $a <=> $b } grep { isaNumber($_) } grep { defined $_ } @_;
    my $median = median(@rest);

    my @deviations = map { abs($_ - $median) } @rest;
    return median(@deviations);
}

# Not everything is numbers - this one returns the most common defined
# occurrence from any array. Supplying an empty array or an array of undefined
# scalars returns undefined.
sub mode
{
    my @array = grep { defined $_ } @_;

    my $result;
    my %freq;
    map { $freq{$_}++ } @array;
    my $max = -1;
    foreach my $string (keys %freq)
    {
        if ($freq{$string} > $max)
        {
            print "String $string occurs $freq{$string} times\n" if $debug;
            $result = $string;
            $max = $freq{$string};
        }
    }
    return $result;
}

# Common usage functions
#
# average returns mode for arrays including strings, and means for arrays of numbers
sub average
{
    my @arrays = @_;
    my $string;
    foreach (@arrays)
    {
        if (defined $_ and not isaNumber($_))
        {
            return mode(@arrays);
        }
    }
    return mean(@arrays);
}

# total returns sum() for numbers, and tries to handle strings a bit.
sub total
{
    my @arrays = @_;
    return unless @arrays;

    my $string;
    foreach (@arrays)
    {
        if (defined $_ and not isaNumber($_))
        {
            # Build a list of unique names
            my %list;
            foreach (@arrays)
            {
                $list{$_}++;
            }
            if (scalar keys %list == 1)
            {
                return $arrays[0]; # All the same
            } else
            {
                return "Various";
            }
        }
    }
    return sum(@arrays);
}

# Same or different - simply indicate whether the defined values are all the
# same or not
sub same
{
    my @array = @_;

    my $count = 0;
    my $lookup;
    foreach (@array)
    {
        $count ++;
        $lookup->{$_}++;
        if ($count != $lookup->{$_})
        {
            return "Different";
        }
    }
    return "Same";
}

# Show the mean ± standard deviation for the sample
sub normalRange
{
    my (@array) = @_;

    return "" unless @array;

    my $mean = mean(@array);
    my $stdev = stdev(@array);

    return sprintf "$precision±$precision", $mean, $stdev;
}

# Show the median ± mad (median absolute deviation) for the sample
sub madRange
{
    my (@array) = @_;

    return "" unless @array;

    my $median = median(@array);
    my $mad = mad(@array);

    return sprintf "$precision±$precision", $median, $mad;
}

# Show the normal estimate for the MEAN of the sample
sub estimateMean
{
    my (@array) = @_;

    return "" unless @array;

    my $mean = mean(@array);
    my $stdev = stdev(@array);
    my $count = count(@array);

    my $stdevMean = $stdev / sqrt ($count);

    return sprintf "$precision±$precision", $mean, $stdevMean;
}

1;
