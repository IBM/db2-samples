# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;
use warnings;
use Data::Dumper;

package TJWH::PlotLabels;
use Carp qw(cluck confess);
use TJWH::Basic;
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
                name      => "undef",
                x         => 0,
                y         => 0,
                rotate    => 0,
                justify   => "left",
                pointType => 1,
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

sub xPosition {
    my ($this, $xPosition) = @_;

    if (defined $xPosition)
    {
        $this->{xPosition} = $xPosition;
    }

    return $this->{xPosition};
}

sub yPosition {
    my ($this, $yPosition) = @_;

    if (defined $yPosition)
    {
        $this->{yPosition} = $yPosition;
    }

    return $this->{yPosition};
}

sub rotate {
    my ($this, $rotate) = @_;

    if (defined $rotate)
    {
        confess "rotate $rotate is not a number" unless $rotate;
        $this->{rotate} = $rotate;
    }

    return $this->{rotate};
}

sub justify {
    my ($this, $justify) = @_;

    if (defined $justify)
    {
        $this->{justify} = $justify;
    }

    return $this->{justify};
}

sub pointType {
    my ($this, $pointType) = @_;

    if (defined $pointType)
    {
        $this->{pointType} = $pointType;
    }

    return $this->{pointType};
}

sub line
{
    my ($this) = @_;
    confess "this is not defined" unless defined $this;

    return
        "set label \"".$this->name.
        "\" at ".$this->xPosition.",".$this->yPosition.
        " ". $this->justify.
        " rotate by ".$this->rotate.
        " point ".$this->pointType;
}

1;
