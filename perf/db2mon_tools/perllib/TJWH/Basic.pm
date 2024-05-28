# -*- cperl -*-
#
# Really simple routines for everyday use.
#
# Updates of note:
#  - make writeFile a LOT safer to avoid truncated files on full file systems

use strict;
use warnings;
use Data::Dumper;

package TJWH::Basic;
require Exporter;
use Time::HiRes qw(gettimeofday);
use Digest::MD5;
use Cwd qw(getcwd abs_path);
use File::Basename qw(basename dirname);
use File::Copy;
use File::Find;
use File::Spec qw(abs2rel);
use File::Temp;
use Sys::Hostname qw(hostname);
use Text::CSV;

use utf8;
binmode STDOUT, ":utf8";

use Carp qw(cluck confess);
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT    = qw(
                   addPath
                   areArrayContentsEqual
                   areArraysEqual
                   arrayMatches
                   collapseWhitespace
                   csvToArray
                   dateComment
                   differenceOfArrays
                   differenceOfArraysUnique
                   executeCommand
                   executeCommandWithOutput
                   fileSize
                   findDirsMatching
                   findDirPathMatching
                   findFilesMatching
                   getOS
                   getSignature
                   hiresDateComment
                   hiresDateCommentReturn
                   hiresDateCommentAppend
                   hiresDateCommentStderr
                   hiresEpoch
                   iecUnits
                   inArray
                   intersectionOfArrays
                   isUniqueArray
                   isaNumber
                   killProcesses
                   linkDuplicates
                   ctime
                   mtime
                   openFile
                   prefixSuffix
                   randomAlphanumeric
                   randomString
                   readFile
                   siUnits
                   stripWhitespace
                   unionOfArrays
                   unionOfArraysUnique
                   uniqueArray
                   uniqueFiles
                   unpackArchive
                   verifyExecutable
                   writeFile
               );                 # symbols to be exported always
@EXPORT_OK = qw($debug $verbose); # symbols to be exported on demand

our $debug = 0;
our $verbose = 0;

# Append new directories to the PATH if they don't already exist
sub addPath
{
    my @dirs = @_;
    my %paths;
    map { $paths{$_}++ } split /:/, $ENV{'PATH'};

    foreach my $dir (@dirs)
    {
        if (-d $dir)
        {
            $ENV{'PATH'} .= ":$dir" unless $paths{$dir};
        }
        else
        {
           warn "$dir is not a directory\n";
        }
    }

    return;
}

# If this walks like a number or talks like a number ...
sub isaNumber
{
    my ($number) = @_;

    if (defined $number and $number =~ m/^\s*[-+]?\d+\.?\d*([Ee][-+]?\d+)?\s*$/)
    {
        return 1;
    }

    return 0;
}

sub getOS
{
    my ($host, $user) = @_;
    my ($rc, $OS) = executeCommandWithOutput("uname", $host, $user);
    chomp $OS;
    return $OS;
}

sub dateComment
{
    my (@rest) = @_;

    my $time = time();
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime $time;

    printf "== %04d-%02d-%02d %02d.%02d.%02d ".(join " ", @rest)." ==\n",
        $year + 1900, $mon, $mday+1, $hour, $min, $sec;

    return;
}

# Split the suffix from a filename so we can add information without changing
# the suffix. If there is no suffix, default to png
sub prefixSuffix {
    my ($filename) = @_;

    confess "No filename given" unless $filename;
    my ($prefix, $suffix) = ($filename, "png");
    if ($filename =~ m/(.*)\.(\w+)$/)
    {
        $prefix = $1;
        $suffix = $2;
    }

    return ($prefix, $suffix);
}

sub hiresEpoch
{
    my ($epoch, $microseconds) = gettimeofday;
    return $epoch + $microseconds/1000000;
}

sub hiresDateComment
{
    my @rest = @_;
    my ($epoch, $microseconds) = gettimeofday;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($epoch);
    printf "%04d-%02d-%02d-%02d.%02d.%02d.%06d :: ",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $microseconds;
    print "".(join " ", @rest)."\n"; # This could be arbitrary text including
                                     # % characters that printf would error on
    return;
}

sub hiresDateCommentReturn
{
    my @rest = @_;
    my ($epoch, $microseconds) = gettimeofday;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($epoch);
    printf "%04d-%02d-%02d-%02d.%02d.%02d.%06d :: ",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $microseconds;
    print "".(join " ", @rest)."\r"; # This could be arbitrary text including
                                     # % characters that printf would error on
    return;
}

sub hiresDateCommentAppend
{
    my @rest = @_;
    my ($epoch, $microseconds) = gettimeofday;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($epoch);
    print "".(join " ", @rest); # This could be arbitrary text including %
                                # characters that printf would error on
    printf " :: %04d-%02d-%02d-%02d.%02d.%02d.%06d\n",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $microseconds;
    return;
}

sub hiresDateCommentStderr
{
    my @rest = @_;
    my ($epoch, $microseconds) = gettimeofday;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($epoch);
    printf STDERR "%04d-%02d-%02d-%02d.%02d.%02d.%06d :: ".(join " ", @rest)."\n",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $microseconds;
    return;
}

sub executeCommand
{
    my ($command, $host, $user, $transport, $options) = @_;
    unless (defined $command)
    {
        cluck "Command must be defined\n";
        return;
    }
    $transport = "rsh" unless defined $transport;
    $options = "" unless defined $options;

    # Use public key auth only for ssh (no prompting for passwords)
    if ($transport eq "ssh" )
    {
        $options .= " -o PreferredAuthentications=publickey";
    }

    my $execute = $command;
    if ($host)
    {
        if ($user)
        {
            $execute = "$transport $options $host -l $user ".
                "'test -e ~/.profile && . ~/.profile; ".
                    "export PATH=\${PATH}:$ENV{TJWHTOOLS_INSTALL_ROOT}/bin:".
                        "$ENV{TJWHTOOLS_INSTALL_ROOT}/bin; $command'";
        }
        else
        {
            $execute = "$transport $options $host ".
                "'test -e ~/.profile && . ~/.profile; ".
                    "export PATH=\${PATH}:$ENV{TJWHTOOLS_INSTALL_ROOT}/bin:".
                        "$ENV{TJWHTOOLS_INSTALL_ROOT}/bin; $command'";
        }
    }
    print "=> $execute\n" if $verbose;
    my $rc = system $execute;
    if ($rc == -1)
    {
        warn "Failed to execute $execute\n";
    }
    elsif ($rc & 127)
    {
        warn sprintf("$execute died with signal %d, %s coredump\n",
            ($rc & 127),  ($rc & 128) ? 'with' : 'without');
    }
    elsif ($rc)
    {
        warn "$execute returned rc=".($rc >> 8)."\n";
    }
    return $rc >> 8;
}

sub executeCommandWithOutput
{
    my ($command, $host, $user, $transport) = @_;
    unless (defined $command)
    {
        cluck "Command must be defined\n";
        return;
    }
    $transport = "rsh" unless defined $transport;
    if ($transport eq "ssh" )
    {
        $transport = "ssh -o PreferredAuthentications=publickey"
    }

    my $execute = $command;
    if ($host)
    {
        if ($user)
        {
            $execute = "$transport $host -l $user ".
                "'export PATH=\${PATH}:$ENV{TJWHTOOLS_INSTALL_ROOT}/bin:".
                    "$ENV{TJWHTOOLS_INSTALL_ROOT}/bin; $command'";
        }
        else
        {
            $execute = "$transport $host ".
                "'export PATH=\${PATH}:$ENV{TJWHTOOLS_INSTALL_ROOT}/bin:".
                    "$ENV{TJWHTOOLS_INSTALL_ROOT}/bin; $command'";
        }
    }
    print "=> $execute\n" if $verbose;

    my $rc = 0;

    # Unset the record separator so we collect all the output from the command
    # in one shot
    my $oldForwardSlash = $/;
    undef $/;
    open OUTPUT, "$execute |" or do {
        $rc = $!;
        if ($rc != 0)
        {
            cluck "Command $execute exited with return code $rc\n";
        }
        return ($rc, undef);
    };
    my $output = <OUTPUT>;
    close OUTPUT;

    # Pick up the error from close (if any)
    $rc = $? >> 8;

    # Set the record separator back to the return character
    $/ = $oldForwardSlash;

    return ($rc, $output);
}

# Find all files in the given paths matching the regular expression supplied.
sub findFilesMatching
{
    my ($match, @paths) = @_;
    confess "paths is not defined" unless @paths;

    my @files = ();
    find(sub {
             /$match/ and push @files, "$File::Find::dir/$_" if -f $_;
         },
         @paths);

    return @files;
}

# Find all files in the given paths matching the regular expression supplied.
sub findDirsMatching
{
    my ($match, @paths) = @_;
    confess "paths is not defined" unless @paths;

    my @files = ();
    find(sub {
             /$match/ and push @files, "$File::Find::dir/$_" if -d $_;
         },
         @paths);

    return @files;
}

# Find all directories whose full path matches the regular expression supplied.
sub findDirPathMatching
{
    my ($match, @paths) = @_;
    confess "paths is not defined" unless @paths;

    my @files = ();
    find(sub {
             $File::Find::dir =~ /$match/ and push @files, "$File::Find::dir/$_" if -d $_;
         },
         @paths);

    return @files;
}

# Return a list of files with unique contents. Strips out empty files.
sub uniqueFiles
{
    my (@filenames) = @_;
    my @uniques = ();
    $| = 1;

    print "Detecting duplicate contents in ".scalar @filenames."\n" if $verbose;
    print " - ".(join "\n - ", @filenames)."\n" if $debug;
    # First, find out how large the files are
    my %sizes;
    foreach my $path (@filenames)
    {
        my $size = fileSize($path);
        push @{ $sizes{$size} }, $path if $size and -f $path;
    }

    # Now for all the files that are the same size, compute the md5sums
    foreach my $size (keys %sizes)
    {
        my $fileCount = scalar @{ $sizes{$size} };
        print "Examining $fileCount files with $size bytes\n" if $debug;
        if ($fileCount < 2) {
            push @uniques, $sizes{$size}->[0];
            next;
        }

        my %signatures;
        foreach my $path (@{ $sizes{$size} })
        {
            my $fh;
            open $fh, $path or next;
            binmode($fh);
            my $sig = Digest::MD5->new->addfile(*$fh)->hexdigest;
            close $fh;
            if (defined $signatures{$sig})
            {
                print "$path: $size bytes appears to be identical to $signatures{$sig}\n" if $debug;
                next;
            }
            else
            {
                print "$path: $size bytes has md5 signature $sig\n" if $debug;
                $signatures{$sig} = $path;
                push @uniques, $path;
            }
        }
    }

    return @uniques;
}

# Delete duplicate files, linking all duplicates to the first instance
sub linkDuplicates
{
    my (@filenames) = @_;
    my @uniques = ();
    $| = 1;

    print "Detecting duplicate contents in ".scalar @filenames." files.\n" if $verbose;
    # First, find out how large the files are
    my %sizes;
    foreach my $path (@filenames)
    {
        confess "Bad path $path"
            unless defined $path and -e $path;
        if (-l $path)
        {
            warn "Symlinks are ignored: $path\n" if $verbose;
            next;
        }
        my $size = fileSize($path);
        push @{ $sizes{$size} }, $path if $size and -f $path;
    }

    # Now for all the files that are the same size, compute the md5sums
    my $saved = 0;
    my $count = 0;
    foreach my $size (keys %sizes)
    {
        next if $size == 0;
        my $fileCount = scalar @{ $sizes{$size} };
        print "Examining $fileCount files with $size bytes\n" if $debug;
        next if $fileCount < 2;
        my %signatures;
        foreach my $path (@{ $sizes{$size} })
        {
            my $sig = getSignature($path);
            if (defined $signatures{$sig})
            {
                print "$path: $size bytes appears to be identical to $signatures{$sig}\n" if $verbose;
                unlink $path;
                $saved += $size;
                $count++;
                my $rc = relativeLink($signatures{$sig}, $path);
                warn "Failed to link $signatures{$sig} to $path: rc=$rc\n" if $rc;
                next;
            }
            else
            {
                print "$path: $size bytes has md5 signature $sig\n" if $debug;
                $signatures{$sig} = $path;
                push @uniques, $path;
            }
        }
        print Data::Dumper::Dumper \%signatures if $debug;
    }

    print "Saved $saved bytes of storage in $count files\n" if $verbose;
    return ($saved, $count);
}

sub getSignature
{
    my ($file) = @_;
    confess "file is not defined" unless defined $file;
    confess "file ($file) is not a file" unless -f $file;

    print "Obtaining signature for $file\n" if $debug;
    my $fh;
    open $fh, $file or next;
    binmode($fh);
    my $sig = Digest::MD5->new->addfile(*$fh)->hexdigest;
    close $fh;
    print "MD5SUM signature for $file: $sig\n" if $debug;

    return $sig;
}

# Given any two paths, create a relative link from source to target.
# Source must exist, target must NOT
sub relativeLink
{
    my ($source, $target) = @_;
    confess "source is not defined" unless defined $source;
    confess "target is not defined" unless defined $target;
    confess "source $source is not a file or directory" unless -f $source or -d $source;
    confess "target ($target) exists" if -e $target;

    my $cwd = getcwd();
    my $relative = File::Spec->abs2rel($source, dirname($target));

    # Jump into the target directory and create the link.
    # Quote every file element to avoid issues with spaces
    my $rc = executeCommand
        (
         "cd \"".dirname($target)."\" && ".
         "test -e \"$relative\" && ".
         "ln -s \"$relative\" \"".basename($target)."\""
        );
    return $rc;
}

sub mtime
{
    my ($file) = @_;
    my $mtime;
    if (-e $file)
    {
        $mtime = (stat $file)[9];
        print "Modification time for $file: $mtime\n" if $verbose;
    }
    else
    {
       print "$file does not exist\n";
    }

    return $mtime;
}

sub ctime
{
    my ($file) = @_;
    my $ctime;
    if (-e $file)
    {
        $ctime = (stat $file)[9];
        print "Create time for $file: $ctime\n" if $verbose;
    }
    else
    {
        print "$file does not exist\n";
    }

    return $ctime;
}

sub fileSize
{
    my ($file) = @_;
    my $size = 0;
    if (-f $file)
    {
        $size = (stat $file)[7];
    }
    else
    {
       warn "$file is not a file\n";
    }
    return $size;
}

# This is intended both to tell the caller how to unpack a given archive and
# also to indicate that this is an archive we can unpack.
sub unpackArchive
{
    my ($archive, $targetDir) = @_;
    if ($targetDir)
    {
        confess "$targetDir is not a valid directory" unless -d $targetDir;
    }

    my $tarExe = 'tar';
    if ($^O =~ m/aix/i)
    {
        $tarExe = 'gtar';
    }

    return unless $archive =~ m/\.(zip|tar)/;
    my $unpackCommand;
    if ($archive =~ m/\.tar\.gz$/)
    {
        $unpackCommand = "gunzip -c $archive | $tarExe xvf -";
        $unpackCommand .= " -C $targetDir" if $targetDir;
    }
    elsif ($archive =~ m/\.tar\.bz2$/)
    {
        $unpackCommand = "bunzip2 -c $archive | $tarExe xvf -";
        $unpackCommand .= " -C $targetDir" if $targetDir;
    }
    elsif ($archive =~ m/\.tar\.xz$/)
    {
        $unpackCommand = "xz --decompress --stdout $archive | $tarExe xvf -";
        $unpackCommand .= " -C $targetDir" if $targetDir;
    }
    elsif ($archive =~ m/\.tar\.Z$/)
    {
        $unpackCommand = "uncompress -c $archive | $tarExe xvf -";
        $unpackCommand .= " -C $targetDir" if $targetDir;
    }
    elsif ($archive =~ m/\.tar$/)
    {
        $unpackCommand = "$tarExe xvf $archive";
        $unpackCommand .= " -C $targetDir" if $targetDir;
    }
    elsif ($archive =~ m/\.zip$/i)
    {
        $unpackCommand = "unzip ".
            ($targetDir ? "-d $targetDir " :"").
                "$archive";
    }
    else
    {
        return;
    }
    return $unpackCommand;
}

# Open a file that MAY be compressed or be special (i.e. representing STDIN)
sub openFile
{
    my ($filename) = @_;

    # Failing to read from $fh to EOF when using Pipes will give a broken pipe
    # error. Ignore these
    $SIG{PIPE}='IGNORE';

    my $fh;
    if (-f $filename)
    {
        print "TJWH::Basic: openFile: Opening $filename\n" if $debug;
        if ($filename =~ m/\.bz2$/)
        {
            open $fh, "bunzip2 -c $filename |" or Carp::confess "Can't open $filename for read (bunzip2): $!\n";
        }
        elsif ($filename =~ m/\.gz$/)
        {
            open $fh, "gunzip -c $filename |" or Carp::confess "Can't open $filename for read (gunzip): $!\n";
        }
        elsif ($filename =~ m/\.Z$/)
        {
            open $fh, "uncompress -c $filename |" or Carp::confess "Can't open $filename for read (uncompress): $!\n";
        }
        else
        {
            open $fh, $filename or Carp::confess "Can't open $filename for read: $!\n";
        }
    }
    # Read from STDIN
    elsif ($filename eq "-")
    {
        $fh = *STDIN;
    }
    else
    {
       Carp::cluck "Filename $filename is not recognized\n";
    }
    return *$fh if $fh;
    return;
}

# Create a random string of alphanumeric characters
sub randomAlphanumeric
{
    my ($length) = @_;
    confess "length is not defined" unless defined $length;
    confess "length ($length} is not an integer\n" unless $length =~ m/\d+/ and $length >= 0;

    my $result = "";
    my @characters = ("A".."Z", "a".."z", "0".."9");
    for (my $i = 0; $i < $length; $i++)
    {
        $result .= $characters[int rand @characters];
    }
    return $result;
}

# Create a random string of alphanumeric characters from the ASCII and Latin sets
sub randomString
{
    my ($length) = @_;
    confess "length is not defined" unless defined $length;
    confess "length ($length} is not an integer\n" unless $length =~ m/\d+/ and $length >= 0;

    my $result = "";
    my @codepoints = (0x0021 .. 0x007E, # "!".."~" ASCII without control codepoints
                      0x00A1 .. 0x00FF, # "¡".."ÿ" Basic Latin 1
                      0x0100 .. 0x017F, # "Ā".."ſ" Latin Extended A
                      0x0180 .. 0x024F, # "ƀ".."ɏ" Latin Extended B
                      );
    for (my $i = 0; $i < $length; $i++)
    {
        $result .= chr($codepoints[int rand @codepoints]);
    }
    return $result;
}

# Read (possibly compressed) file into an array
sub readFile
{
    my ($filename) = @_;
    Carp::confess "$filename is not a file\n" unless -f $filename;

    my $fh = openFile $filename or Carp::confess "Failed to open $filename for read: $!\n";
    my @contents = <$fh>;
    close $fh;

    return @contents;
}

# We write to a temporary file and then copy it over. If the file looks a bit
# short after writing it, don't copy it over.
#
# Returns a non-zero error code if the write fails.
sub writeFile
{
    my ($filename, @rest) = @_;

    my $temp = File::Temp->new;
    my $bytesWritten = 0;
    if (defined $temp)
    {
        my $tempFilename = $temp->filename;

        my $oh;
        open $oh, ">$tempFilename" or do
        {
            Carp::cluck "Failed to open (for $filename): $!\n";
            return 0;
        };
        print "Writing to $tempFilename (for $filename)\n" if $debug or $verbose;
        foreach my $entry (@rest)
        {
            print "==> $entry\n" if $debug;
            print $oh $entry or do
            {
                Carp::cluck "Could not write $entry into $tempFilename (for $filename) after $bytesWritten bytes:\n$!\n";
                return 1;
            };
            $bytesWritten += length $entry;
        }
        close $oh or do
        {
            Carp::cluck "Failed to write (for $filename): $!\n";
            return 0;
        };

        my $size = -s $tempFilename;
        if ($size == 0 and $bytesWritten != 0)
        {
            Carp::cluck "Zero length file (should be $bytesWritten): $tempFilename\n";
            return 0;
        }

        if ($size < $bytesWritten)
        {
            Carp::cluck "Size mismatch:\n  file size: $size\n  expected size: $bytesWritten\n";
            return 0;
        }
        if ($debug)
        {
            print "Size of temporary file: $size\n";
            print "Bytes written: $bytesWritten\n";
        }

        File::Copy::copy $tempFilename, $filename or do
            {
                Carp::cluck "Failed to move $tempFilename to $filename: $!\n";
                return 0;
            };

        unless (-s $filename == -s $tempFilename)
        {
            # Make a backup somewhere and then throw an exception
            my $flatten = $filename;
            $flatten =~ tr#/#_#;
            my $backup = "/tmp/$flatten";
            File::Copy::copy $tempFilename, $flatten;
            Carp::confess "Write file failed - backup made in $flatten\n";
        }

        print "$filename completed\n" if $debug or $verbose;
    }
    else
    {
        print "Could not create temporary file\n";
        return 1;
    }

    return 0 if -f $filename;
    return 1;
}

sub killProcesses
{
    my ($name, $signal, $hostname, $user) = @_;
    confess "name is not defined\n" unless defined $name;
    $hostname = hostname unless defined $hostname;
    $signal = 9 unless defined $signal;
    # Don't need to define user

    my ($rc, $output) = executeCommandWithOutput("ps -eo user,pid,comm",
                                                 $hostname,
                                                 $user);
    if ($rc)
    {
        print "Failed to get process list from $hostname: rc=$rc\n$output\n";
        return;
    }
    foreach my $line (split /\n/, $output)
    {
        chomp $line;
        if ($line =~ m/^\s*(\w+)\s+(\d+)\s+(.*)$/)
        {
            my ($user, $pid, $comm) = ($1, $2, $3);
            if ($comm =~ m/$name/)
            {
                # Use system kill executable because we may be remote
                print "Sending pid $pid signal $signal on host $hostname\n" if $verbose;
                executeCommand("kill -$signal $pid &",
                               $hostname,
                               $user);
            }
        }
        elsif ($line =~ m/^\s*USER/)
        {
            # Skip the header
            next;
        }
        else
        {
           print "Failed to understand $line\n";
        }
    }
    return;
}

# Convenience utility for working with input lists (typically seen in options processing)
sub csvToArray
{
    my (@inputs) = @_;
    my @results = ();

    my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
    foreach my $entry (@inputs)
    {
        $csv->parse($entry);
        push @results, $csv->fields ();
    }

    return @results;
}

sub stripWhitespace
{
    my ($string) = @_;
    $string =~ s/^\s+//g;
    $string =~ s/\s+$//g;
    return $string;
}

sub collapseWhitespace
{
    my ($string) = @_;
    $string =~ s/\s+/ /g;
    return $string;
}

# Check that an executable can be found in the PATH
sub verifyExecutable
{
    my ($exe) = @_;
    confess "exe is not defined\n" unless defined $exe;

    my $command = `which $exe`;
    chomp $command;
    unless ($command)
    {
        print "$exe can't be found.\n";
        return 0;
    }
    elsif (! -x $command)
    {
        print "$command can't be executed.\n";
        return 0;
    }
    return 1;
}

# Read a SI unit string and convert to a floating point representation
#  Factor Name  Symbol
#  1024   yotta Y
#  1021   zetta Z
#  1018   exa   E
#  1015   peta  P
#  1012   tera  T
#  109    giga  G
#  106    mega  M
#  103    kilo  k
#  102    hecto h
#  101    deka  da
#
#  Factor Name  Symbol
#  10-1   deci  d
#  10-2   centi c
#  10-3   milli m
#  10-6   micro µ
#  10-9   nano  n
#  10-12  pico  p
#  10-15  femto f
#  10-18  atto  a
#  10-21  zepto z
#  10-24  yocto y

# Multiples of 1000 (Système International Units)
sub siUnits
{
    my ($string) = @_;

    if ($string =~ m/([+-]?\d+\.?\d*)([yzafpnumcdkMGTPEZY]|da)$/)
    {
        my ($base, $suffix) = ($1, $2);
        return $base * 10 if $suffix eq 'da';
        # We'll be tolerant of folks who don't understand that k is lower case
        return $base * 1000 if $suffix eq 'k' or $suffix eq 'K';
        return $base * 1000000 if $suffix eq 'M';
        return $base * 1000000000 if $suffix eq 'G';
        return $base * 1000000000000 if $suffix eq 'T';
        return $base * 1000000000000000 if $suffix eq 'P';
        return $base * 1000000000000000000 if $suffix eq 'E';
        return $base * 1000000000000000000000 if $suffix eq 'Z';
        return $base * 1000000000000000000000000 if $suffix eq 'Y';
        return $base / 10 if $suffix eq 'd';
        return $base / 100 if $suffix eq 'c';
        return $base / 1000 if $suffix eq 'm';
        return $base / 1000000 if $suffix eq 'u';
        return $base / 1000000000 if $suffix eq 'n';
        return $base / 1000000000000 if $suffix eq 'p';
        return $base / 1000000000000000 if $suffix eq 'f';
        return $base / 1000000000000000000 if $suffix eq 'a';
        return $base / 1000000000000000000000 if $suffix eq 'z';
        return $base / 1000000000000000000000000 if $suffix eq 'y';
        confess "Unrecognized suffix: $suffix for $string\n";
    }

    return $string;
}

# Multiples of 1024 (KiB), etc) (International Electrotechnical Commission Units)
sub iecUnits
{
    my ($string) = @_;

    if ($string =~ m/([+-]?\d+\.?\d*)([yzafpnumcdkMGTPEZY]|da)(iB)?$/)
    {
        my ($base, $suffix) = ($1, $2);
        return $base * 1024 if $suffix eq 'k' or $suffix eq 'K';
        return $base * 1024 * 1024 if $suffix eq 'M';
        return $base * 1024 * 1024 * 1024 if $suffix eq 'G';
        return $base * 1024 * 1024 * 1024 * 1024 if $suffix eq 'T';
        return $base * 1024 * 1024 * 1024 * 1024 * 1024 if $suffix eq 'P';
        return $base * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 if $suffix eq 'E';
        return $base * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 if $suffix eq 'Z';
        return $base * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 if $suffix eq 'Y';

        # For now, we'll assume that IEC units only apply for multiplication.
        confess "Unrecognized suffix: $suffix for $string\n";

        # and these can be of purely academic interest
        return $base / 1024 if $suffix eq 'm';
        return $base / ( 1024 * 1024 ) if $suffix eq 'u';
        return $base / ( 1024 * 1024 * 1024 ) if $suffix eq 'n';
        return $base / ( 1024 * 1024 * 1024 * 1024 ) if $suffix eq 'p';
        return $base / ( 1024 * 1024 * 1024 * 1024 * 1024 ) if $suffix eq 'f';
        return $base / ( 1024 * 1024 * 1024 * 1024 * 1024 * 1024 ) if $suffix eq 'a';
        return $base / ( 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 ) if $suffix eq 'z';
        return $base / ( 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 ) if $suffix eq 'y';
    }

    return $string;
}

# ------------------------------------------------------------------------
# Several variants for comparing arrays. These are intended to be used in
# predicates and return 1 for equivalency, 0 otherwise

# Order matters: each array has the same contents in the same order
sub areArraysEqual
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    return 0 unless $#$arrayRef1 == $#$arrayRef2;

    for (my $counter = 0; $counter <= $#$arrayRef1; $counter ++)
    {
        return 0 unless @{ $arrayRef1 }[$counter] eq @{ $arrayRef2 }[$counter];
    }
    return 1;
}

# Contents matter: this one checks that the contents of the two arrays are
# equivalent
sub areArrayContentsEqual
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    return 0 unless $#$arrayRef1 == $#$arrayRef2;

    my %itemCounter;
    foreach my $item (@{ $arrayRef1 })
    {
        $itemCounter{$item}++;
    }
    foreach my $item (@{ $arrayRef2 })
    {
        $itemCounter{$item}--;
    }

    foreach my $key (keys %itemCounter)
    {
        return 0 unless $itemCounter{$key} == 0;
    }
    return 1;
}

sub inArray
{
    my ($test, $arrayRef) = @_;

    foreach my $value (@$arrayRef)
    {
        return 1 if $value eq $test;
    }
    return 0;
}

# Unique intersection of two arrays, stripping duplicates
sub intersectionOfArrays
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    my (%lookup1, %lookup2);
    map { $lookup1{$_} = 1 } @$arrayRef1;
    map { $lookup2{$_} = 1 } @$arrayRef2;

    return grep { $lookup1{$_} } keys %lookup2;
}

# Difference of two arrays, where there are entries in the first array and not
# the second
sub differenceOfArraysUnique
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    my (%lookup);
    map { $lookup{$_}++ } @$arrayRef1;
    map { $lookup{$_}-- } @$arrayRef2;

    return grep { $lookup{$_} > 0 } sort keys %lookup;
}

# Difference of two arrays, where there are entries in one array and not
# the second
sub differenceOfArrays
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    my (%lookup);
    map { $lookup{$_}++ } @$arrayRef1;
    map { $lookup{$_}-- } @$arrayRef2;

    return grep { $lookup{$_} != 0 } sort keys %lookup;
}

# Duplicates in the inputs will be stripped
sub unionOfArraysUnique
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    my %lookup;
    map { $lookup{$_} ++ } (@$arrayRef1, @$arrayRef2);

    return keys %lookup;
}

# Duplicates in the inputs will be preserved
sub unionOfArrays
{
    my ($arrayRef1, $arrayRef2) = @_;
    confess "Two arguments must be supplied\n" unless scalar @_ == 2;
    confess "Need an ARRAY reference for arrayRef1 - got a ".ref $arrayRef1." instead\n"
        unless ref $arrayRef1 eq "ARRAY";
    confess "Need an ARRAY reference for arrayRef2 - got a ".ref $arrayRef2." instead\n"
        unless ref $arrayRef2 eq "ARRAY";

    my %lookup;
    map { $lookup{$_} ++ } (@$arrayRef1, @$arrayRef2);
    my @results = ();
    foreach my $key (keys %lookup)
    {
        push @results, map { $key } 1 .. $lookup{$key};
    }

    return @results;
}

# Remove duplicates from an array, preserving order
sub uniqueArray
{
    my @array = @_;

    my @results = ();
    my %lookup;

    foreach (@array)
    {
        push @results, $_ unless defined $lookup{$_};
        $lookup{$_}++;
    }

    return @results;
}

# Check that an array has unique entries
sub isUniqueArray
{
    my @array = @_;
    my %lookup;

    foreach (@array)
    {
        return 0 if defined $lookup{$_};
        $lookup{$_}++;
    }

    return 1;
}

# Check to see if any element in the array matches the search term
sub arrayMatches
{
    my ($m, @array) = @_;
    foreach (@array)
    {
        if (m/$m/)
        {
            return 1;
        }
    }
    return 0;
}

1;
