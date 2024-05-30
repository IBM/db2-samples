##############################################################################
## Licensed Materials - Property of IBM
##
## (C) COPYRIGHT International Business Machines Corp. 2014
## All Rights Reserved.
##
## SPDX-License-Identifier: Apache-2.0
##
## US Government Users Restricted Rights - Use, duplication or
## disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##############################################################################

#
# IXF/IO.pm - Read and write from files
#

package IXF::IO;
use base qw(Exporter);
use subs qw( read_data );
@EXPORT = qw( read_data );

use strict;
use warnings;

sub read_data
{
  my ($fh, $len) = @_;

  my $str = "";

  if ($len > 0)
  {
    read $fh, $str, $len or return undef;
  }
  elsif ($len < 0)
  {
    # Read as much as possible
    my $buf;
    $len = 10240;
    while (1)
    {
      my $actual = read $fh, $buf, $len;
      print "Error reading ($!)" and return undef unless defined $actual;
      $str .= $buf;
      last if ($actual < $len);
    }
  }

  return $str;
}

1;

