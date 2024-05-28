# -*- cperl -*-

use strict;
use warnings;
use Data::Dumper;

package TJWH::CalculatedTable;
use Carp qw(cluck confess);
require Exporter;
use TJWH::Calculation;
use TJWH::Table;
use TJWH::TableIterator;
use TJWH::BasicStats qw(sum mean median);
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
                title        => "Report",
                source       => undef, # Original table supplied
                result       => undef, # New table with the calculated columns
                group        => [],    # List of column names to group over
                include      => undef, # Include all tokens found in the calculations
                calculations => [],    # Array of calculations
                tokenFreq    => {},
                tokens       => [],
                elapsed      => undef, # Elapsed time for some calculations
                describe     => undef, # Add the calculation information to the
                                       # report caption
               };

    bless $this, $class;

    return $this;
}

sub title {
    my ($this, $title) = @_;

    if (defined $title)
    {
        $this->{title} = $title;
    }

    return $this->{title};
}

sub report {
    my ($this, $report) = @_;

    if (defined $report)
    {
        $this->{report} = $report;
    }

    return $this->{report};
}

sub source {
    my ($this, $source) = @_;

    if (defined $source)
    {
        confess "source ($source) is not a TJWH::Table"
            unless blessed $source and $source->isa("TJWH::Table");

        $this->{source} = $source;
    }

    return $this->{source};
}

sub result {
    my ($this, $result) = @_;

    if (defined $result)
    {
        $this->{result} = $result;
    }

    return $this->{result};
}

sub group {
    my ($this, @group) = @_;
    if (scalar @group)
    {
        $this->{group} = [@group];
    }

    return @{ $this->{group} };
}

sub include {
    my ($this, $include) = @_;

    if (defined $include)
    {
        $this->{include} = $include;
    }

    return $this->{include};
}

sub calculations {
    my ($this, @calculations) = @_;

    foreach my $calc (@calculations)
    {
        $this->addCalculation($calc);
    }

    return @{ $this->{calculations} };
}

sub addCalculation {
    my ($this, $calc) = @_;

    confess "calc is not defined" unless defined $calc;
    confess "calc ($calc) is not a TJWH::Calculation" unless ref $calc eq "TJWH::Calculation";

    push @{ $this->{calculations} }, $calc;

    return $this;
}

sub tokens {
    my ($this, @tokens) = @_;

    foreach my $token (@tokens)
    {
        $this->addToken($token);
    }

    return @{ $this->{tokens} };
}

sub addToken {
    my ($this, $token) = @_;

    # Check to see if we already have a column with this name in the
    # calculation list. Ignore it if we do.
    unless (grep { $_->name eq $token } $this->calculations)
    {
        if ($this->{token}->{$token})
        {
            $this->{token}->{$token}++;
        }
        else
        {
            $this->{token}->{$token} = 1;
            push @{ $this->{tokens} }, $token;
        }
    }
    return @{ $this->{tokens} };
}

sub elapsed {
    my ($this, $elapsed) = @_;

    if (defined $elapsed)
    {
        confess "elapsed ($elapsed) is not a number" unless $elapsed =~ m/\d+\.\d*/;
        $this->{elapsed} = $elapsed;
    }

    return $this->{elapsed};
}

sub describe {
    my ($this, $describe) = @_;

    if (defined $describe)
    {
        $this->{describe} = $describe;
    }

    return $this->{describe};
}

sub generateReport {
    my ($this) = @_;

    $this->{result} = undef;

    my %seenAggregates;

    if ($this->source and $this->source->numberOfRows)
    {
        my %lcMap;
        map { $lcMap{lc $_} = $_ } $this->source->columnNames;

        my @valid = ();
        CALC: foreach my $calc ($this->calculations)
        {
            # Take the original expression
            my $expression = $calc->expression;
            my ($stuff, $token);
            my $code = "";
            # Build a valid expression for the source table by converting
            # words (NOT non-whitespace!!!) to references. Because we scan
            # for words, we walk over mathematical constructs, adding those
            # as we go. Thankfully underscores are treated as word
            # characters, so col_name_like_this is matched once.
            while ($expression =~ m/^(\W*)(\w+)(.*)/)
            {
                ($stuff, $token, $expression) = ($1, $2, $3);
                # if it looks like an aggregation over a column name,
                # replace it with the appropriate aggregation lookup
                if ($token =~ m/^(sum|mean|median)$/) {
                    my $function = $token;
                    my $current = $expression;
                    if ($expression =~ m/\s*[(]\s*(\w+)\s*[)](.*)/)
                    {
                        ($token, $expression) = ($1, $2);
                        if (exists $lcMap{lc $token}) {
                            $code .= "${stuff}\$${function}Lookup->{".(lc $token)."}";
                            $seenAggregates{$function}++;
                            # and make a note that we saw this token
                            $this->addToken($lcMap{lc $token});
                        } else {
                            warn "Unexpected contents of $function ( ) - got '$token', expected one of:\n  ".
                                (join "\n  ", sort keys %lcMap)."\n";
                            next CALC;
                        }
                    } else {
                        warn "Syntax error follows $stuff $function ... expected ( column_name ), got $current\n";
                        next CALC;
                    }
                }
                # If it looks like a column name, replace it with a hash deref
                elsif (exists $lcMap{lc $token}) {
                    $code .= "${stuff}\$rh->{$lcMap{lc $token}}";
                    # and make a note that we saw this token
                    $this->addToken($lcMap{lc $token});
                }
                # If it is a number, keep it intact.
                elsif ($token =~ m/\d+\.?\d*/) {
                    $code .= "${stuff}$token";
                }
                else {
                    # Some calculations need a time period to calculate
                    # rates. If we have that information, use it
                    if ($this->elapsed and $token =~ m/ts_delta/)
                    {
                        $code .= $stuff.$this->elapsed;
                    } else {
                        # If we can't account for this string, don't continue - this
                        # calculation probably can't be applied
                        print "Token $token not found in source table.\n" if $debug;
                        next CALC;
                    }
                }
            }

            # Weld the last piece onto the code
            $code .= $expression;
            $calc->code($code);
            if ($debug)
            {
                print "Original expression: $calc->{expression}\n";
                print "New expression     : $code\n";
            }

            push @valid, $calc;
        }

        if (@valid)
        {
            my $result = new TJWH::Table;
            $result->columnNames(($this->include ? $this->tokens : ()),
                                 map { $_->name } @valid);
            $result->columnFormats
                (($this->include ? map { "%-4s" } $this->tokens : ()),
                 map { "%".$_->precision.".".$_->precision."f" } @valid);
            $result->caption($this->title." table for ".$this->source->caption.
                             (defined $this->describe ? "\n - ".
                              (join "\n - ", map { $_->name.": ".$_->expression } @valid)
                              : ""));

            # Support basic aggregates
            my ($sumLookup, $meanLookup, $medianLookup);
            foreach my $fn (keys %seenAggregates)
            {
                foreach my $name ($this->source->columnNames) {
                    my $evalMe = "\$${fn}Lookup->{lc \$name} = $fn(\$this->source->getNumbersForColumn(\$name))";
                    print "\$name = \"$name\"; $evalMe\n" if $debug;
                    eval $evalMe;
                }
            }

            my $ti = new TJWH::TableIterator($this->source);
            while ($ti->active)
            {
                my $rh = $ti->getRowHash;
                my @row = ();
                if ($this->include)
                {
                    foreach my $col ($this->tokens)
                    {
                        push @row, $rh->{$col};
                    }
                }
                foreach my $calc (@valid)
                {
                    # need to enforce scalar context for the eval, because the
                    # presence of parentheses in the code expression can
                    # change things around...
                    my $result = eval "$calc->{code}";
                    push @row, $result;
                }
                $result->appendRow(@row);
                $ti->next;
            }
            $this->result($result);
        }
    }

    return $this->result;
}

1;
