# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;
use warnings;
use Data::Dumper;

package TJWH::Calculation;
use Carp qw(cluck confess);
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
                name        => undef,
                description => "",
                expression  => undef,
                code        => undef,
                precision   => 3,
               };

    bless $this, $class;

    return $this;
}

sub name {
    my ($this, $name) = @_;
    if (defined $name)
    {
        $this->{name} = $name;
    }

    return $this->{name};
}

sub description {
    my ($this, $description) = @_;

    if (defined $description)
    {
        $this->{description} = $description;
    }

    return $this->{description};
}

sub expression {
    my ($this, $expression) = @_;

    if (defined $expression)
    {
        $this->{expression} = $expression;
    }

    return $this->{expression};
}

sub code {
    my ($this, $code) = @_;

    if (defined $code)
    {
        $this->{code} = $code;
    }

    return $this->{code};
}

sub precision {
    my ($this, $precision) = @_;

    if (defined $precision)
    {
        confess "Precision ($precision) must be an integer\n"
            unless $precision =~ m/^\d+$/;
        $this->{precision} = $precision;
    }

    return $this->{precision};
}


1;
