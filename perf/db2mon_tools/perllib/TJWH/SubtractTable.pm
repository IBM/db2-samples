# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);

package TJWH::SubtractTable;
use Carp qw(cluck confess);
require Exporter;
use TJWH::TableUtils qw(
                           removeEmptyColumns
                      );

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(); # symbols to be exported always
@EXPORT_OK = qw(getJoinColumns
                getProtectedColumns
                guessMonitor
                removeEmptyColumnsProtect
                $debug
                $verbose
                $joinMap
                $protectMap
              ); # symbols to be exported on demand
$VERSION = '0.01';

our $debug;
our $verbose;

# map from file or table name to a list of columns that will be the join condition
our $joinMap =
{
 '_GROUP_BUFFERPOOL[- ._]'                         => [ qw(MEMBER) ],
 '_BUFFERPOOL[- ._]'                               => [ qw(BP_NAME MEMBER) ],
 '_TABLESPACE[- ._]'                               => [ qw(TBSP_NAME MEMBER) ],
 '_TABLE[- ._]'                                    => [ qw(TABSCHEMA TABNAME MEMBER TAB_TYPE TAB_FILE_ID DATA_PARTITION_ID TBSP_ID INDEX_TBSP_ID LONG_TBSP_ID) ],
 '_APPL_LOCKWAIT[- ._]'                            => [ qw(LOCK_NAME REQ_APPLICATION_HANDLE REQ_AGENT_TID) ],
 '_CONNECTION[- ._]|monConnection'                 => [ qw(APPLICATION_HANDLE APPLICATION_NAME
                                                           APPLICATION_ID MEMBER
                                                           CONNECTION_START_TIME
                                                         ) ],
 '_CONTAINER[- ._]'                                => [ qw(TBSP_NAME TBSP_ID MEMBER CONTAINER_NAME) ],
 '_INDEX[- ._]'                                    => [ qw(TABSCHEMA TABNAME MEMBER IID DATA_PARTITION_ID) ],
 '_PKG_CACHE_STMT[- ._]|monPkgCacheStm'            => [ qw(MEMBER EXECUTABLE_ID) ],
 '_WORKLOAD[- ._]|monWorkload'                     => [ qw(WORKLOAD_NAME MEMBER) ],
 '_DATABASE[- ._]'                                 => [ qw(MEMBER) ],
 '_CF_SYS_RESOURCES[- ._]'                         => [ qw(NAME VALUE DATATYPE) ],
 '_CF_WAIT_TIME[- ._]'                             => [ qw(MEMBER HOSTNAME ID CF_CMD_NAME) ],
 '_CF_CMD[- ._]'                                   => [ qw(HOSTNAME ID CF_CMD_NAME) ],
 '_CF[- ._]'                                       => [ qw(HOST_NAME ID DB_NAME) ],
 '_TIMESTAMP[- ._]'                                => [ qw(ID) ],
 '_INSTANCE[- ._]'                                 => [ qw(MEMBER) ],
 '_UNIT_OF_WORK[- ._]'                             => [ qw(SERVICE_SUPERCLASS_NAME
                                                           SERVICE_SUBCLASS_NAME
                                                           SERVICE_CLASS_ID
                                                           APPLICATION_ID
                                                           MEMBER) ],
 '_LOCKS[- ._]'                                    => [ qw(APPLICATION_HANDLE MEMBER LOCK_NAME) ],
 '_SERVERLIST[- ._]'                               => [ qw(MEMBER HOSTNAME) ],
 '_PAGE_ACCESS_INFO[- ._]'                         => [ qw(MEMBER TABSCHEMA TABNAME OBJTYPE DATA_PARTITION_ID IID) ],
 '_MEMORY_SET[- ._]'                               => [ qw(MEMBER HOST_NAME DB_NAME MEMORY_SET_TYPE MEMORY_SET_ID) ],
 '_TRANSACTION_LOG[- ._]|monTransactionLog'        => [ qw(MEMBER) ],
 '_EXTENDED_LATCH_WAIT[- ._]|monExtendedLatchWait' => [ qw(MEMBER LATCH_NAME) ],
};

# List of numeric columns that NEVER should be subtracted
my @protectAlways = qw (
                           MEMBER
                      );
# Map from file or table name to a list of columns that will protected (not be
# operated upon) by operations such as subtract.  These columns are typically
# identifiers or timestamps where retaining static values is appropriate.
# Note that join keys are automatically protected and do not need to be
# listed.
# [- ._]
our $protectMap =
{
 '_TABLESPACE[- ._]'     => [ qw(TABLESPACE_MIN_RECOVERY_TIME TBSP_LAST_RESIZE_TIME) ],
 '_TABLE[- ._]'          => [ qw(
                                    DATA_SHARING_STATE_CHANGE_TIME
                                    TAB_TYPE
                                    TAB_FILE_ID
                                    DATA_PARTITION_ID
                                    TBSP_ID
                                    INDEX_TBSP_ID
                                    LONG_TBSP_ID
                                    DATA_SHARING_STATE
                                    TAB_ORGANIZATION
                               ) ],
 '_LOCKWAIT[- ._]'       => [ qw(LOCK_WAIT_START_TIME) ],
 '_LOCKS?[- ._]'          => [ qw(
                                    LOCK_OBJECT_TYPE_ID
                                    LOCK_OBJECT_TYPE
                                    LOCK_MODE
                                    LOCK_CURRENT_MODE
                                    LOCK_STATUS
                                    LOCK_ATTRIBUTES
                                    LOCK_RELEASE_FLAGS
                                    LOCK_RRIID
                                    TBSP_ID
                                    TAB_FILE_ID
                               )],
 '_CONNECTION[- ._]'     => [ qw(
                                    CLIENT_ACCTNG
                                    CLIENT_APPLNAME
                                    CLIENT_HOSTNAME
                                    CLIENT_IPADDR
                                    CLIENT_PID
                                    CLIENT_PLATFORM
                                    CLIENT_PRDID
                                    CLIENT_PROTOCOL
                                    CLIENT_USERID
                                    CLIENT_WRKSTNNAME
                                    CONNECTION_START_TIME
                                    CURRENT_ISOLATION
                                    EXECUTION_ID
                                    INTRA_PARALLEL_STATE
                                    LAST_EXECUTABLE_ID
                                    LAST_REQUEST_TYPE
                                    MEMBER_SUBSET_ID
                                    PREV_UOW_STOP_TIME
                                    SESSION_AUTH_ID
                                    SYSTEM_AUTH_ID
                                    UID_SQL_STMTS
                                    UOW_COMP_STATUS
                                    UOW_START_TIME
                                    UOW_STOP_TIME
                                    WORKLOAD_OCCURRENCE_STATE
                               ) ],
 '_PKG_CACHE_STMT[- ._]' => [ qw(
                                    EFFECTIVE_ISOLATION
                                    PACKAGE_NAME
                                    PACKAGE_SCHEMA
                                    PACKAGE_VERSION_ID
                                    QUERY_DATA_TAG_LIST
                                    ROUTINE_ID
                                    SECTION_TYPE
                                    SEMANTIC_ENV_ID
                                    STMT_PKG_CACHE_ID
                                    STMT_TEXT
                                    STMT_TYPE_ID
                                    VALID
                                    INSERT_TIMESTAMP LAST_METRICS_UPDATE MAX_COORD_STMT_EXEC_TIMESTAMP
                               ) ],
 '_DATABASE[- ._]'       => [ qw(
                                    ACTIVE_HASH_JOINS
                                    ACTIVE_SORTS
                                    APPLS_CUR_CONS
                                    APPLS_IN_DB2
                                    DB_CONN_TIME
                                    LAST_BACKUP
                                    LOCK_LIST_IN_USE
                                    NUM_ASSOC_AGENTS
                                    NUM_COORD_AGENTS
                                    NUM_LOCKS_HELD
                                    NUM_LOCKS_WAITING
                                    NUM_POOLED_AGENTS
                                    SORT_HEAP_ALLOCATED
                                    SORT_SHRHEAP_ALLOCATED
                               ) ],
 '_INSTANCE[- ._]'       => [ qw(DB2START_TIME) ],
 '_UNIT_OF_WORK[- ._]'   => [ qw(
                                    CLIENT_HOSTNAME
                                    CURRENT_ISOLATION
                                    EXECUTION_ID
                                    INTRA_PARALLEL_STATE
                                    LAST_EXECUTABLE_ID
                                    LAST_REQUEST_TYPE
                                    MEMBER_SUBSET_ID
                                    SESSION_AUTH_ID
                                    UOW_COMP_STATUS
                                    UOW_ID
                                    WORKLOAD_OCCURRENCE_STATE
                                    WORKLOAD_OCCURRENCE_ID
                                    WORKLOAD_NAME
                                    UOW_START_TIME UOW_STOP_TIME PREV_UOW_STOP_TIME
                               ) ],
};

# Constructor
sub new
{
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $this = {
                baseline       => undef,
                comparison     => undef,
                joinMethod     => "left_outer",
                joinColumns    => [],
                protectColumns => [],
               };

    bless $this, $class;

    return $this;
}

sub baseline {
    my ($this, $baseline) = @_;

    if (defined $baseline)
    {
        confess "baseline is not a TJWH::Table"
            unless blessed $baseline and $baseline->isa('TJWH::Table');

        $this->{baseline} = $baseline;
    }

    return $this->{baseline};
}

sub comparison {
    my ($this, $comparison) = @_;

    if (defined $comparison)
    {
        confess "comparison is not a TJWH::Table"
            unless blessed $comparison and $comparison->isa('TJWH::Table');

        $this->{comparison} = $comparison;
    }

    return $this->{comparison};
}

sub joinMethod {
    my ($this, $joinMethod) = @_;

    if (defined $joinMethod)
    {
        confess "joinMethod ($joinMethod) is not valid"
            unless $joinMethod =~ m/^(inner|(left_|right_)?outer)$/;
        $this->{joinMethod} = $joinMethod;
    }

    return $this->{joinMethod};
}

sub joinColumns {
    my ($this, @joinColumns) = @_;
    if (scalar @joinColumns)
    {
        $this->{joinColumns} = [@joinColumns];
    }

    return @{ $this->{joinColumns} };
}

sub protectColumns {
    my ($this, @protectColumns) = @_;
    if (scalar @protectColumns)
    {
        $this->{protectColumns} = [@protectColumns];
    }

    return @{ $this->{protectColumns} };
}

sub subtract {
    my ($this) = @_;

    confess "this->{baseline} is not defined" unless defined $this->{baseline};
    confess "this->{comparison} is not defined" unless defined $this->{comparison};

    unless (scalar $this->joinColumns)
    {
        my @cols = getJoinColumns($this->baseline->caption);
        unless (@cols)
        {
            warn "No join columns were found or could be chosen from table $this->{baseline}->{caption}\n";
            return;
        }
        $this->joinColumns(@cols);
    }

    unless (scalar $this->protectColumns)
    {
        my @cols = getProtectedColumns($this->baseline->caption);
        $this->protectColumns(@cols);
    }

    my $result = $this->baseline->subtractTable
        (
         $this->comparison,
         [ $this->joinColumns ],
         $this->joinMethod,
         [ $this->joinColumns, $this->protectColumns ],
        );

    # Inner, Outer Left and Outer Right should be the same size or smaller
    # than the baseline or comparison
    if (lc $this->joinMethod ne 'outer')
    {
        # Warn when the result set is larger than either of the original data sets
        if ($result->numberOfRows > $this->baseline->numberOfRows and
            $result->numberOfRows > $this->comparison->numberOfRows)
        {
            cluck "TJWH::SubtractTable: Result set (".$result->numberOfRows.
                ") is larger than either baseline (".$this->baseline->numberOfRows.
                ") or comparison (".$this->comparison->numberOfRows.") result sets\n";
        }
    }

    # Tough to determine the sensible upper limit on outer - could be BxC^N
    # B == rows in baseline
    # C == rows in comparison
    # N == number of columns in join

    return $result;
}

# Utilities
sub getJoinColumns
{
    my ($name) = @_;

    cluck "Searching for join columns for $name\n" if $debug;
    my @joinColumns;
    foreach my $key (reverse sort keys %$joinMap)
    {
        print "Examining $key\n" if $debug;
        if ($name =~ m/$key/i)
        {
            @joinColumns = @{ $joinMap->{$key} };
            print "Found columns ".(join ", ", @joinColumns)."\n" if $debug;
            last;
        }
    }
    return @joinColumns;
}

sub guessMonitor
{
    my ($name) = @_;
    cluck "Searching method key for $name\n" if $debug;
    my @joinColumns;
    foreach my $key (reverse sort keys %$joinMap)
    {
        print "Examining $key\n" if $debug;
        if ($name =~ m/$key/i)
        {
            my $guess = $key;
            if ($guess =~ m/^_([A-Z_]+)[[]/)
            {
                $guess = uc "mon_get_$1";
            }
            return $guess;
        }
    }
    if ($name =~ m/SQL/)
    {
        warn "guessMonitor: Weak: assuming SQL refers to package cache statements";
        return "MON_GET_PKG_CACHE_STMT";
    }
    cluck "Failed to guess the correct monitor for $name\n";
    return "unknown_monitor";
}

sub getProtectedColumns
{
    my ($name) = @_;

    cluck "Searching for protected columns for $name\n" if $debug;
    my @protectColumns;
    foreach my $key (sort keys %$protectMap)
    {
        print "Examining $key\n" if $debug;
        if ($name =~ m/$key/i)
        {
            @protectColumns = (@protectAlways, @{ $protectMap->{$key} });
            warn "Found columns ".(join ", ", @protectColumns)."\n" if $debug;
            last;
        }
    }
    return @protectColumns;
}

# Remove empty columns from a table, optionally protecting a specified list of columns
sub removeEmptyColumnsProtect {
    my ($table, $protect) = @_;
    confess "table is not defined" unless defined $table;
    confess "table ($table) is not a TJWH::Table" unless ref $table eq "TJWH::Table";

    my @cols;
    if ($protect)
    {
        if ($protect eq 'auto')
        {
            @cols = getProtectedColumns($table->caption);
        }
        else
        {
            @cols = csvToArray($protect);
        }
        print "Protecting the following columns from cleaning:\n  ".
            (join "\n  ", @cols)."\n" if $debug;
    }
    removeEmptyColumns($table, @cols);

    return $table;
}

1;
