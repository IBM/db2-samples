# -*- cperl -*-
# (c) Copyright IBM Corp. 2024 All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#
# Utilities for controlling tasks, often asynchronously.
#

use strict;
use warnings;
use TJWH::BasicStats;
use POSIX qw(mkfifo);
use Data::Dumper;

package TJWH::JobControl;
require Exporter;
use Storable qw(nstore retrieve);
use Carp qw(confess cluck);
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(
                   simultaneousTasks
                   simultaneousTasksEval
                   simultaneousTasksEvalAndPrint
                   simultaneousSubroutines
                   simultaneousSubroutinesWithResults
                   taskQueue
                   taskQueueEval
                   taskQueueSubroutines
                   taskQueueSubroutinesWithResults
                   runBackgroundTasks
                   runBackgroundSubroutines
              );                  # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand

our $verbose;
our $debug;

our $fifoPath = "/tmp/jobcontrol.fifo";
our $fifoLock = "$fifoPath.lock";

# The inputs to this subroutine is a list of system tasks to handle
# simultaneously. simultaneousTasks will exit when the last task completes.
sub simultaneousTasks
{
    my @taskList = @_;
    my %childProcs = ();
    my $errorCount = 0;

    # Attempt to clean up if we hit a timeout
    my $existingAlrm = $SIG{'ALRM'};
    $SIG{'ALRM'} = sub {
        warn "Warning: simultaneousTasks caught SIGALRM - cleaning up processes\n";
        foreach my $pid (keys %childProcs)
        {
            warn "Warning: Sending SIGKILL to $pid\n";
            kill -KILL, $pid;
        }
        $existingAlrm->(@_) if defined $existingAlrm;
        return -1;
    };

    my $total = scalar @taskList;
    warn "About to run the following tasks:\n  ".( join "\n  ", @taskList )."\n" if $verbose;
    system("date") if $verbose;
    foreach my $task (@taskList)
    {
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid\n" if $verbose;
            $childProcs{$pid} = 1;
        }
        else
        {
            # Child process
            warn "Executing $task of $total\n" if $verbose;
            my $rc = system ($task);
            warn "Completed $task of $total with return code ".($rc << 8)."\n" if $verbose;
            exit $rc;
        }
    }

    while (scalar keys %childProcs > 0)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        my $childRc = $?;
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if (scalar keys %childProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
                system ("date") if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n" if $verbose;
            }
        }
        else
        {
            $errorCount++ if $childRc;
            if ($verbose)
            {
                warn "Child with process ID $pidExit completed with non-zero return code: $childRc\n";
            }
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    if ($verbose)
    {
        warn "All children have exited\n";
        system ("date");

        warn "One child exited with an error\n" if $errorCount == 1;
        warn "$errorCount children exited with errors\n" if $errorCount > 1;
    }

    return $errorCount;
}

# The inputs to this subroutine is a list of perl tasks to handle
# simultaneously. simultaneousTasksEval will exit when the last task
# completes.
sub simultaneousTasksEval
{
    my @taskList = @_;
    my %childProcs = ();
    my $total = scalar @taskList;

    # Attempt to clean up if we hit a timeout
    my $existingAlrm = $SIG{'ALRM'};
    $SIG{'ALRM'} = sub {
        warn "Warning: simultaneousTasksEval caught SIGALRM - cleaning up processes\n";
        foreach my $pid (keys %childProcs)
        {
            warn "Warning: Sending SIGKILL to $pid\n";
            kill -KILL, $pid;
        }
        $existingAlrm->(@_) if defined $existingAlrm;
        return -1;
    };

    warn "About to run the following tasks:\n  ".( join "\n  ", @taskList )."\n" if $verbose;
    system("date");
    foreach my $task (@taskList)
    {
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid\n" if $verbose;
            $childProcs{$pid} = 1;
        }
        else
        {
            # Child process
            warn "Executing $task of $total\n" if $verbose;
            my $rc = eval $task;
            cluck $@ if $@;
            warn "Child: finished $task of $total with rc $rc\n" if defined $rc and $verbose;
            warn "Child: finished $task of $total with undefined rc\n" if (! defined $rc) and $verbose;
            exit $rc if defined $rc;
            exit;
        }
    }

    while (scalar keys %childProcs > 0)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        my $childRc = $?;
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if (scalar keys %childProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
                system ("date") if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n" if $verbose;
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    warn "All children have exited\n" if $verbose;
    system ("date");
}

# The inputs to this subroutine is a list of closures to execute
# simultaneously. simultaneousTasks will exit when the last task
# completes. These subroutines should not take arguments.
sub simultaneousSubroutines
{
    my @taskList = @_;
    my %childProcs = ();
    my $errorCount = 0;
    my $total = scalar @taskList;

    if (grep { ref $_ ne 'CODE' } @taskList)
    {
        confess "There are elements in the subroutine list that are NOT code\n".
            Data::Dumper::Dumper \@taskList;
    }

    # Attempt to clean up if we hit a timeout
    my $existingAlrm = $SIG{'ALRM'};
    $SIG{'ALRM'} = sub {
        warn "Warning: simultaneousSubroutines caught SIGALRM - cleaning up processes\n";
        foreach my $pid (keys %childProcs)
        {
            warn "Warning: Sending SIGKILL to $pid\n";
            kill 'KILL', $pid;
        }
        $existingAlrm->(@_) if defined $existingAlrm;
        return -1;
    };

    warn "About to run @taskList subroutines:\n" if $verbose;
    system("date") if $verbose;
    foreach my $task (@taskList)
    {
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid\n" if $verbose;
            $childProcs{$pid} = 1;
        }
        else
        {
            # Child process
            warn "Executing subroutine $task of $total\n" if $verbose;
            my $rc = &{ $task };
            if ($verbose)
            {
                warn "Completed $task of $total with return code $rc\n" if defined $rc;
                warn "Completed $task of $total with no return code\n" unless defined $rc;
            }
            exit $rc if defined $rc;
            exit;
        }
    }

    while (scalar keys %childProcs > 0)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        my $childRc = $?;
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if (scalar keys %childProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
                system ("date") if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n" if $verbose;
            }
        }
        else
        {
            $errorCount ++ if $childRc;
            if ($verbose)
            {
                warn "Child with process ID $pidExit completed with return code: $childRc\n";
            }
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    warn "All children have exited\n" if $verbose;
    system ("date") if $verbose;

    warn "One child exited with an error\n" if $verbose and $errorCount == 1;
    warn "$errorCount children exited with errors\n" if $verbose and $errorCount > 1;

    return $errorCount;
}

# The inputs to this subroutine is a list of closures to execute
# simultaneously. simultaneousTasks will exit when the last task
# completes. These subroutines should not take arguments.
#
# The results are provided as an array of array references. Each subroutines
# output is in an individual array reference.
sub simultaneousSubroutinesWithResults
{
    my @taskList = @_;

    # Find a unique stem for the result files
    my $fileSeed;
    do
    {
        $fileSeed = "/tmp/jobControl-$$-".rand(time())."-".time();
    } while (glob "$fileSeed-*");

    my %childProcs = ();
    my $errorCount = 0;
    my $total = scalar @taskList;

    if (grep { ref $_ ne 'CODE' } @taskList)
    {
        confess "There are elements in the subroutine list that are NOT code\n".
            Data::Dumper::Dumper \@taskList;
    }

    warn "About to run @taskList subroutines:\n" if $verbose;
    system("date") if $verbose;

    my $index = 0;
    foreach my $task (@taskList)
    {
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid\n" if $verbose;
            $childProcs{$pid} = 1;
        }
        else
        {
            # Child process
            warn "Executing subroutine $task of $total\n" if $verbose;
            # We'll catch problems and report exceptions
            eval {
                my $results = [ &{ $task } ];
                # We collect the results as an array reference and store it in a file
                nstore $results, "$fileSeed-$index";
            };
            if ($@)
            {
                warn "Failed $index of $total: $task failed:\n$@";
                exit -1;
            }
            warn "Completed $task of $total\n" if $verbose;
            exit;
        }
        $index++;
    }

    while (scalar keys %childProcs > 0)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        my $childRc = $?;
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if (scalar keys %childProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
                system ("date") if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n" if $verbose;
            }
        }
        else
        {
            $errorCount ++ if $childRc;
            if ($verbose)
            {
                warn "Child with process ID $pidExit completed with return code: $childRc\n";
            }
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    warn "All children have exited\n" if $verbose;
    system ("date") if $verbose;

    warn "One child exited with an error\n" if $verbose and $errorCount == 1;
    warn "$errorCount children exited with errors\n" if $verbose and $errorCount > 1;

    my @results = ();
    for (my $index = 0; $index < $total; $index++)
    {
        $results[$index] = undef;
        $results[$index] = retrieve "$fileSeed-$index" if -f "$fileSeed-$index";
        unlink "$fileSeed-$index";
    }
    return @results;
}

# The inputs to this subroutine is a list of perl tasks to handle
# simultaneously. simultaneousTasksEvalAndPrint will exit when the last task
# completes. It returns an array of array references containing the output
# from the child processes.
sub simultaneousTasksEvalAndPrint
{
    my @taskList = @_;
    my %childProcs = ();
    my @output;
    my $total = scalar @taskList;

    warn "About to run the following tasks:\n  ".( join "\n  ", @taskList )."\n" if $verbose;
    system("date") if $verbose;

    my %taskHash;
    my $taskIndex = 0;
    foreach my $task (@taskList)
    {
        my $childFifopath = "$fifoPath.$taskIndex";
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid for task $taskIndex $task\n" if $verbose;
            $taskHash{$taskIndex} = $task;
            $taskIndex++;
            $childProcs{$pid} = 1;
            unless (-p $childFifopath)
            {
                warn "Creating FIFO $childFifopath\n" if $verbose;
                unlink $childFifopath;
                POSIX::mkfifo($childFifopath, 0700);
            }
        }
        else
        {
            # Child process - each child writes to its own FIFO
            warn "Executing $task: $taskIndex of $total\n" if $verbose;
            my $output = eval $task;
            my $childRc = $?;
            cluck $@ if $@;
            open FIFO, "> $childFifopath" or die "Can't open fifoPath $fifoPath: $!\n";
            my $result = "JOBCONTROL-START\n$output\nJOBCONTROL-END\n";
            warn $result if $verbose;
            print FIFO $result;
            close FIFO;
            warn "Child: finished $task: $taskIndex of $total with no output\n"
                if (! defined $output) and $verbose;
            exit $childRc;
        }
    }

    my $reportCount = 0;
    while (scalar keys %childProcs > 0)
    {
        # We have to read from each of the ACTIVE fifos to allow each child to
        # complete (because FIFOs are blocking).
        for (my $index = 0; $index < $taskIndex; $index ++)
        {
            if (defined $taskHash{$index})
            {
                my $childFifopath = "$fifoPath.$index";
                my $task;
                open FIFO, "$childFifopath" or die "Can't open fifoPath $childFifopath: $!\n";
                while (my $line = <FIFO>)
                {
                    chomp $line;
                    # First line of an exchange
                    $line =~ m/^JOBCONTROL-START$/ && do {
                        $output[$index] = [];
                        next;
                    };
                    # Last line of an exchange
                    $line =~ m/^JOBCONTROL-END$/ && do {
                        delete $taskHash{$index};
                        unlink $childFifopath;
                        last;
                    };
                    # Anything else is real output
                    push @{ $output[$index] }, $line;
                }
                close FIFO;
            }
        }

        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if (scalar keys %childProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
                system ("date") if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n" if $verbose;
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }

    warn "All children have exited\n" if $verbose;
    system ("date") if $verbose;

    warn "At exit: @output\n" if $verbose;

    return @output;
}

# ------------------------------------------------------------------------------
# This is a throttled version of simultaneousTasks which limits the number of
# simultaneous tasks to a given number.
#
# Inputs: maximum number of simultaneous tasks
#         task1
#         task2
#         ...
#         taskN
#
sub taskQueue
{
    my ($throttle, @taskList) = @_;
    my %childProcs = ();
    my $totalProcs = scalar @taskList;
    my $total = $totalProcs;

    warn "taskQueue: Start: $totalProcs processes are queued\n" if $debug;
    warn "taskQueue: Start: $throttle processes may run simultaneously\n" if $debug;

    my $iterate = 0;
    while ($totalProcs > 0)
    {
        system("date") if $verbose;
        warn "taskQueue: Initial ".(scalar keys %childProcs)." <=> ".(TJWH::BasicStats::minimum ($throttle, $totalProcs))."\n" if $debug;

        # While we have less than the specified number of forks, create child processes
        while ($totalProcs > 0 and scalar keys %childProcs < $throttle)
        {
            $iterate++;
            print STDERR "taskQueue: Pass $iterate of $total\r";
            warn "taskQueue: Balance ".(scalar keys %childProcs)." <=> ".(TJWH::BasicStats::minimum ($throttle, $totalProcs))."\n" if $debug;
            my $pid = fork();
            my $task = shift @taskList; # Take a task from the list
            my $dispatched = 0;
            if ($pid)
            {
                # Parent process
                warn "Parent has spawned child $pid\n" if $verbose;
                $childProcs{$pid} = 1;
                $totalProcs --;
            }
            else
            {
                # Child process
                warn "Child: starting $task of $total\n" if $verbose;
                my $rc = system($task);
                warn "Child: finished $task of $total with rc ".($rc << 8)."\n" if $verbose;
                exit $rc;
            }
        }

        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    while (scalar keys %childProcs)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    return;
}

# ------------------------------------------------------------------------------
# This is a throttled version of simultaneousTasksEval which limits the number of
# simultaneous tasks to a given number.
#
# Inputs: maximum number of simultaneous tasks
#         task1
#         task2
#         ...
#         taskN
#
sub taskQueueEval
{
    my ($throttle, @taskList) = @_;

    my %childProcs = ();
    my $totalProcs = scalar @taskList;
    my $total = $totalProcs;

    while ($totalProcs > 0)
    {
        system("date") if $verbose;

        # While we have less than the specified number of forks, create child processes
        while ($totalProcs > 0 and scalar keys %childProcs < $throttle)
        {
            my $pid = fork();
            my $task = shift @taskList; # Take a task from the list
            my $dispatched = 0;
            if ($pid)
            {
                # Parent process
                warn "Parent has spawned child $pid\n" if $verbose;
                $childProcs{$pid} = 1;
                $totalProcs --;
            }
            else
            {
                # Child process
                warn "Child: starting $task of $total\n" if $verbose;
                my $rc = eval $task;
                cluck $@ if $@;
                warn "Child: finished $task of $total with rc $rc\n"
                    if defined $rc and $verbose;
                warn "Child: finished $task of $total with undefined rc\n"
                    if (not defined $rc) and $verbose;
                exit $rc;
            }
        }

        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    while (scalar keys %childProcs)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    return;
}

# Really this is here to make it easier to debug taskQueueSubroutines stuff by providing a
# fork-free code path
sub loopTasks
{
    my (@taskList) = @_;

    my $total = scalar @taskList;
    my $index = 0;
    foreach my $code (@taskList)
    {
        $index++;
        confess "code ($code) is not a CODE" unless ref $code eq "CODE";
        my $rc = &{ $code };
        if (defined $rc)
        {
            warn "Completed $index of $total with return code $rc\n" if $verbose;
        }
        else
        {
            warn "Completed $index of $total with undefined return code\n" if $verbose;
        }
    }

    return;
}

# Throttled version of simultaneousSubroutines
sub taskQueueSubroutines
{
    my ($throttle, @taskList) = @_;

    if ($throttle == 1)
    {
        loopTasks(@taskList);
        return;
    }

    my %childProcs = ();
    my $totalProcs = scalar @taskList;
    my $total = $totalProcs;

    warn "taskQueue: Start: $totalProcs processes are queued\n" if $debug;
    warn "taskQueue: Start: $throttle processes may run simultaneously\n" if $debug;

    my $iterate = 0;
    while ($totalProcs > 0)
    {
        system("date") if $verbose;
        warn "taskQueue: Initial ".(scalar keys %childProcs)." <=> ".(TJWH::BasicStats::minimum ($throttle, $totalProcs))."\n" if $debug;

        # While we have less than the specified number of forks, create child processes
        while ($totalProcs > 0 and scalar keys %childProcs < $throttle)
        {
            $iterate++;
            print STDERR "taskQueue: Pass $iterate of $total\r";
            warn "taskQueue: Balance ".(scalar keys %childProcs)." <=> ".(TJWH::BasicStats::minimum ($throttle, $totalProcs))."\n" if $debug;
            my $pid = fork();
            my $task = shift @taskList; # Take a task from the list
            my $dispatched = 0;
            if ($pid)
            {
                # Parent process
                warn "Parent has spawned child $pid\n" if $verbose;
                $childProcs{$pid} = 1;
                $totalProcs --;
            }
            else
            {
                # Child process
                warn "Executing subroutine $task of $total\n" if $verbose;
                my $rc = &{ $task };
                if (defined $rc)
                {
                    warn "Completed $task of $total with return code $rc\n" if $verbose;
                    exit $rc;
                }
                else
                {
                    warn "Completed $task of $total with undefined return code\n" if $verbose;
                    exit;
                }
            }
        }

        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    while (scalar keys %childProcs)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    return;
}


# Really this is here to make it easier to debug
# taskQueueSubroutinesWithResults stuff by providing a fork-free code path
sub loopTasksWithResults
{
    my (@taskList) = @_;

    my $total = scalar @taskList;
    my $index = 0;

    # Find a unique stem for the result files
    my $fileSeed;
    do
    {
        $fileSeed = "/tmp/jobControl-$$-".rand(time())."-".time();
    } while (glob "$fileSeed-*");

    foreach my $code (@taskList)
    {
        confess "code ($code) is not a CODE" unless ref $code eq "CODE";
        # We'll catch problems and report exceptions
        eval {
            my $results = [ &{ $code } ];
            # We collect the results as an array reference and store it in a file
            nstore $results, "$fileSeed-$index";
        };
        if ($@)
        {
            warn "Failed $index of $total: $code failed:\n$@";
            exit -1;
        }
        warn "Completed $index of $total\n" if $verbose;
        $index++;
    }

    my @results = ();
    for (my $index = 0; $index < $total; $index++)
    {
        $results[$index] = undef;
        $results[$index] = retrieve "$fileSeed-$index" if -f "$fileSeed-$index";
        unlink "$fileSeed-$index";
    }
    return @results;
}

# Throttled version of simultaneousSubroutinesWithResults
sub taskQueueSubroutinesWithResults
{
    my ($throttle, @taskList) = @_;

    if ($throttle == 1)
    {
        return loopTasksWithResults(@taskList);
    }

    select(STDERR);
    $| = 1;
    select(STDOUT); # default
    $| = 1;

    # Find a unique stem for the result files
    my $fileSeed;
    do
    {
        $fileSeed = "/tmp/jobControl-$$-".rand(time())."-".time();
    } while (glob "$fileSeed-*");

    my %childProcs = ();
    my $totalProcs = scalar @taskList;
    my $total = $totalProcs;

    warn "taskQueue: Start: $totalProcs processes are queued\n" if $debug;
    warn "taskQueue: Start: $throttle processes may run simultaneously\n" if $debug;

    my $iterate = 0;
    my $index = 0;
    while ($totalProcs > 0)
    {
        system("date") if $verbose;
        warn "taskQueue: Initial ".(scalar keys %childProcs)." <=> ".(TJWH::BasicStats::minimum ($throttle, $totalProcs))."\n" if $debug;

        # While we have less than the specified number of forks, create child processes
        while ($totalProcs > 0 and scalar keys %childProcs < $throttle)
        {
            $iterate++;
            print STDERR "taskQueue: Pass $iterate of $total\r";
            warn "taskQueue: Balance ".(scalar keys %childProcs)." <=> ".(TJWH::BasicStats::minimum ($throttle, $totalProcs))."\n" if $debug;
            my $pid = fork();
            my $task = shift @taskList; # Take a task from the list
            my $dispatched = 0;
            if ($pid)
            {
                # Parent process
                warn "Parent has spawned child $pid\n" if $verbose;
                $childProcs{$pid} = 1;
                $totalProcs --;
            }
            else
            {
                # Child process
                warn "Executing subroutine $task of $total\n" if $verbose;
                # We'll catch problems and report exceptions
                eval {
                    my $results = [ &{ $task } ];
                    # We collect the results as an array reference and store it in a file
                    nstore $results, "$fileSeed-$index";
                };
                if ($@)
                {
                    warn "Failed $index of $total: $task failed:\n$@";
                    exit -1;
                }
                warn "Completed $task of $total\n" if $verbose;
                exit;
            }
            $index++;
        }

        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }
    while (scalar keys %childProcs)
    {
        # Now wait for a child to exit
        my $pidExit = wait();
        if ($pidExit == -1)
        {
            # Either there are no children left, in which case we should check
            # that $totalProcs is zero or something funny has happened.
            if ($totalProcs == 0)
            {
                warn "All children have exited\n" if $verbose;
            }
            else
            {
                die "Ooops - ran out of children unexpectedly\n";
            }
        }
        else
        {
            # one of our children has exited - remove it from consideration.
            delete $childProcs{$pidExit};
        }
    }

    my @results = ();
    for (my $index = 0; $index < $total; $index++)
    {
        $results[$index] = undef;
        $results[$index] = retrieve "$fileSeed-$index" if -f "$fileSeed-$index";
        unlink "$fileSeed-$index";
    }
    return @results;
}

# This is a fire-and-forget subroutine. The pids for the children are
# returned to the caller. No errors are reported
sub runBackgroundTasks
{
    my @taskList = @_;
    my %childProcs = ();
    my $errorCount = 0;

    my $total = scalar @taskList;
    warn "About to run the following tasks:\n  ".( join "\n  ", @taskList )."\n" if $verbose;
    system("date") if $verbose;
    foreach my $task (@taskList)
    {
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid\n" if $verbose;
            $childProcs{$pid} = 1;
        }
        else
        {
            # Child process
            warn "Executing $task of $total\n" if $verbose;
            my $rc = system ($task);
            warn "Completed $task of $total with return code ".($rc << 8)."\n" if $verbose;
            exit $rc;
        }
    }

    return sort keys %childProcs;
}

# This is a fire-and-forget subroutine. The pids for the children are
# returned to the caller.
sub runBackgroundSubroutines
{
    my @taskList = @_;
    my %childProcs = ();
    my $total = scalar @taskList;

    if (grep { ref $_ ne 'CODE' } @taskList)
    {
        confess "There are elements in the subroutine list that are NOT code\n".
            Data::Dumper::Dumper \@taskList;
    }

    warn "About to run @taskList subroutines:\n" if $verbose;
    system("date") if $verbose;
    foreach my $task (@taskList)
    {
        my $pid = fork();
        if ($pid)
        {
            # Parent process
            warn "Parent has spawned child $pid\n" if $verbose;
            $childProcs{$pid} = 1;
        }
        else
        {
            # Child process
            warn "Executing subroutine $task of $total\n" if $verbose;
            my $rc = &{ $task };
            warn "Completed $task of $total with return code $rc\n" if $verbose;
            exit $rc;
        }
    }

    return keys %childProcs;
}

1;
