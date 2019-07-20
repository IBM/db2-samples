:   # -*-Perl-*-
eval 'exec perl -S $0 ${1+"$@"}'
if 0;

################################################################################
#
# Description: DPF LOAD sample driver for remote file transfer.
#
# (C) COPYRIGHT International Business Machines Corp. 2005
# All Rights Reserved
# Licensed Materials - Property of IBM
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
#
# DISCLAIMER :
# This sample DPF LOAD utility file transfer command is distributed as is,
# it is not officially supported by IBM, and it may have to be modified
# to work in all environments supported by DB2 UDB.
# 
#
# PLEASE NOTE : The load file transfer command is executed from the
# database partition that is coordinating the load. It should also be
# noted that it is executed under the instance owner's user id.
# Therefore, the .netrc file required must exist under the instance
# owner's home directory. This also means that only environment
# variables set for the instance owner can be inherited by the load
# file transfer command.
#
#
# NOTE TO WINDOWS USERS : Some Windows FTP clients do not support the
# .netrc file. In that case ftp->login() command in the ftp subroutine
# has to be modified to include the correct user ID and password.
#
#
# This script expects the following input:
#
#   <logpath> <hostname> <basepipename> <nummedia> <source media list>
#
# Where:
#    <logpath>
#       A writable log path for generating any diagnostics.
#
#    <hostname>
#       The name of the remote host where the remote media (files) reside.
#
#    <basepipename>
#       A base pipename representing a location where the contents of
#       each source file should be written. It is expected that there is a
#       pipe for each source media (file), and that each pipe has a name
#       of the form <basepipename>.nnn where "nnn" is the index of the
#       source media. "nnn" must always be 3 characters, and is 0 indexed,
#       such that the pipe names for the first 3 files would have the
#       following form:
#          <basepipename>.000
#          <basepipename>.001
#          <basepipename>.002
#
#    <nummedia>
#       The number of remote media (files) to be transfered.
#
#    <source media list>
#       The actual names of the remote media (files), fully qualified.
#
################################################################################

use Net::FTP;

use POSIX ":sys_wait_h";

# Some control variables
#
# Set '$binary = 0' to perform ASCII FTP, binary FTP is the default.
# Set '$mvsdataset = 1' if the source data is a zOS dataset.
# Set '$parallel = 0' to disable parallel FTP for multiple input sources
#

$binary            = 1;
$mvsdataset        = 0;
$parallel          = 1;

$logpath = "";

if (scalar(@ARGV) >= 1)
{
    $logpath = $ARGV[0] . "/";
}

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

$logfile = $logpath . "loadFtpFtc." . ($year + 1900) . $mon . $day . $hour . $min . $sec . ".log";

open(LOGFILE, ">$logfile") || exit(-1);

if (scalar(@ARGV) < 4)
{
    &log("$0 wrong number args\n");

    for ($i = 0; $i < scalar(@ARGV); ++$i)
    {
        &log("$0 \$ARGV[" . $i . "] = '" . $ARGV[$i] . "'\n");
    }

    exit -1;
}

# Input variables
#
$logpath           = $ARGV[0];
$hostname          = $ARGV[1];
$basepipename      = $ARGV[2];
$nummedia          = $ARGV[3];

&log("\$binary($binary) \$mvsdataset($mvsdataset) \$parallel($parallel)\n");

for ($i = 0; $i < scalar(@ARGV); ++$i)
{
    &log("\$ARGV[$i]($ARGV[$i])\n");
}

# Advance the argument list so it points to the begining of the media
#
shift(@ARGV);
shift(@ARGV);
shift(@ARGV);
shift(@ARGV);

# Collect the file and pipenames
#
for ($i = 0; $i < $nummedia; $i++)
{
    $pipename[$i] = $basepipename . '.' . substr(1000+$i,1,3);

    $data[$i] = $ARGV[0];

    if ($mvsdataset)
    {
        $data[$i] = &basename($data[$i]);

        $data[$i] = "'" . $data[$i] . "'";
    }

    &log("\$data[$i]($data[$i])\n");
    &log("\$pipename[$i]($pipename[$i])\n");

    shift(@ARGV);
}

for ($i = 0; $i < $nummedia; $i++)
{
    if ($parallel)
    {
        if ($pid = fork())
        {
            # This is parent code. Not much to do but
            # store the pid so we can wait for it later.
            #
            $pidlist[$i] = $pid;
        }
        elsif (defined $pid)
        {
            # This is child code.
            #
            if (!&ftp($data[$i], $pipename[$i]))
            {
                exit 0;
            }

            exit 1;
        }
        else
        {
            # Fork error.
            #
            &log("fork error for data($data[$i]) and pipe($pipename[$i])\n");

            &log("Failure\n");

            exit -1;
        }
    }
    else
    {
        if (!&ftp($data[$i], $pipename[$i]))
        {
            &log("Failure\n");

            exit -1;
        }
    }
}

# Wait for the children.
#
if ($parallel)
{
    $rc = 1;

    for ($i = 0; $i < $nummedia; $i++)
    {
        $pid = waitpid($pidlist[$i], 0);

        $rc = $?;

        if ($pid == -1)
        {
            &log("wait(ftp($pidlist[$i])) returned -1\n");

            $rc = 0;
        }
        else
        {
            if ($pid != $pidlist[$i])
            {
                &log("wait(ftp($pidlist[$i])) returned \$pid($pid)\n");
            }

            $rc >>= 8;

            &log("ftp($pidlist[$i]) rc($rc)\n");
        }
    }

    if (!$rc)
    {
        &log("Failure\n");

        exit -1;
    }
}

&log("Success\n");

exit 0;

# Do the ftp
#
sub ftp
{
    my ($data, $pipename) = @_;

    &log("ftp: ftping $data into $pipename on $hostname\n");

    $rc = 1;

    if ($ftp = Net::FTP->new($hostname))
    {
        if (!$ftp->login())
        {
            $msg = "$hostname: ".$ftp->message();

            chop($msg);

            &log("ftp: Cannot login to $msg\n");

            $rc = 0;
        }
        else
        {
            if ($binary)
            {
                $ftp->binary();
            }

            if (!$ftp->get($data, $pipename))
            {
                $msg = $ftp->message();

                chop($msg);

                &log("ftp: get failed($msg)\n");

                $rc = 0;
            }
            else
            {
                &log("ftp: get succeeded($data)\n");
            }
        }
        $ftp->quit();
    }
    else
    {
        if (defined($ftp))
        {
            $msg = $ftp->message();

            chop($msg);

            &log("ftp: Cannot connect to $hostname($msg)\n");
        }
        else
        {
            &log("ftp: Cannot connect to $hostname($@)\n");
        }

        $rc = 0;
    }

    if ($parallel)
    {
        exit $rc;
    }
    else
    {
        return $rc;
    }
}

sub log
{
    my ($str) = @_;

    flock(LOGFILE, 2);

    print(LOGFILE $str);

    flock(LOGFILE, 8);
}

sub basename
{
    my ($path) = @_;

    @parts = split(/[\\\/]/, $path);

    return $parts[scalar(@parts) - 1];
}
