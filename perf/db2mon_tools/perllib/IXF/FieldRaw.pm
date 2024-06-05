##############################################################################
## Licensed Materials - Property of IBM
##
## (C) COPYRIGHT International Business Machines Corp. 2014, 2015
## All Rights Reserved.
##
## SPDX-License-Identifier: Apache-2.0
##
## US Government Users Restricted Rights - Use, duplication or
## disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##############################################################################

#
# IXF/FieldRaw.pm - A single field in the IXF file
#

package IXF::FieldRaw;

use strict;
use warnings;

use IXF::IO;

# Make a list of valid field types
our %valid_fields = ();
add_valid_fields();

sub new
{
  my $class = shift;
  my $self = { };
  bless $self, $class;

  $self->name(shift);

  # IF this is a valid field, use the properties provided
  my $f = $valid_fields{$self->name};

  if (defined $f)
  {
    $self->length($f->length);
    $self->type($f->type);
    $self->comments($f->comments);
  }
  else
  {
    $self->length(shift);
    $self->type(shift);
    $self->comments(shift);
  }

  $self->data(undef);

  return $self;
}

sub read
{
  my ($self, $fh) = @_;

  my $str = read_data($fh, $self->length);
  $self->data($str);

  return $self->data;
}

sub name
{
  my $self = shift;

  $self->{name} = shift if (@_);
  return $self->{name};
}

sub length
{
  my $self = shift;

  if (@_)
  {
    $self->{length} = shift;

    # -1 indicates variable length field
    $self->{length} = -1 if (defined $self->{length} and $self->{length} < 0);
  }

  return $self->{length};
}

sub type
{
  my $self = shift;

  $self->{type} = shift if (@_);
  return $self->{type};
}

sub comments
{
  my $self = shift;

  $self->{comments} = shift if (@_);
  return $self->{comments};
}

sub data
{
  my $self = shift;

  $self->{data} = shift if (@_);
  return $self->{data};
}

sub debug_print
{
  my $self = shift;

  print "Field (name: " . $self->name . ", length: " . $self->length . ", type: " . $self->type . ", comments: " . $self->comments . ", data: \"" . $self->data . "\")\n";
}

sub add_valid_fields
{
  # See http://www-01.ibm.com/support/knowledgecenter/SSEPGG_10.5.0/com.ibm.db2.luw.admin.dm.doc/doc/r0004668.html

  # Add header record fields
  add_valid_field("IXFHRECL" , 6   , "record length");
  add_valid_field("IXFHRECT" , 1   , "record type = H");
  add_valid_field("IXFHID"   , 3   , "IXF identifier");
  add_valid_field("IXFHVERS" , 4   , "IXF version");
  add_valid_field("IXFHPROD" , 12  , "product");
  add_valid_field("IXFHDATE" , 8   , "date written");
  add_valid_field("IXFHTIME" , 6   , "time written");
  add_valid_field("IXFHHCNT" , 5   , "heading record count");
  add_valid_field("IXFHSBCP" , 5   , "single byte code page");
  add_valid_field("IXFHDBCP" , 5   , "double byte code page");
  add_valid_field("IXFHFIL1" , 2   , "reserved");

  # Add table record fields
  add_valid_field("IXFTRECL" , 6   , "record length");
  add_valid_field("IXFTRECT" , 1   , "record type = T");
  add_valid_field("IXFTNAML" , 3   , "name length");
  add_valid_field("IXFTNAME" , 256 , "name of data");
  add_valid_field("IXFTQULL" , 3   , "qualifier length");
  add_valid_field("IXFTQUAL" , 256 , "qualifier");
  add_valid_field("IXFTSRC"  , 12  , "data source");
  add_valid_field("IXFTDATA" , 1   , "data convention = C");
  add_valid_field("IXFTFORM" , 1   , "data format = M");
  add_valid_field("IXFTMFRM" , 5   , "machine format = PC");
  add_valid_field("IXFTLOC"  , 1   , "data location = I");
  add_valid_field("IXFTCCNT" , 5   , "C record count");
  add_valid_field("IXFTFIL1" , 2   , "reserved");
  add_valid_field("IXFTDESC" , 30  , "data description");
  add_valid_field("IXFTPKNM" , 257 , "primary key name");
  add_valid_field("IXFTDSPC" , 257 , "reserved");
  add_valid_field("IXFTISPC" , 257 , "reserved");
  add_valid_field("IXFTLSPC" , 257 , "reserved");

  # Add column descriptor record fields
  add_valid_field("IXFCRECL" , 6   , "record length");
  add_valid_field("IXFCRECT" , 1   , "record type = C");
  add_valid_field("IXFCNAML" , 3   , "column name length");
  add_valid_field("IXFCNAME" , 256 , "column name");
  add_valid_field("IXFCNULL" , 1   , "column allows nulls");
  add_valid_field("IXFCDEF"  , 1   , "column has defaults");
  add_valid_field("IXFCSLCT" , 1   , "column selected flag");
  add_valid_field("IXFCKPOS" , 2   , "position in primary key");
  add_valid_field("IXFCCLAS" , 1   , "data class");
  add_valid_field("IXFCTYPE" , 3   , "data type");
  add_valid_field("IXFCSBCP" , 5   , "single byte code page");
  add_valid_field("IXFCDBCP" , 5   , "double byte code page");
  add_valid_field("IXFCLENG" , 5   , "column data length");
  add_valid_field("IXFCDRID" , 3   , "D record identifier");
  add_valid_field("IXFCPOSN" , 6   , "column position");
  add_valid_field("IXFCDESC" , 30  , "column description");
  add_valid_field("IXFCLOBL" , 20  , "lob column length");
  add_valid_field("IXFCUDTL" , 3   , "UDT name length");
  add_valid_field("IXFCUDTN" , 256 , "UDT name");
  add_valid_field("IXFCDEFL" , 3   , "default value length");
  add_valid_field("IXFCDEFV" , 254 , "default value");
  add_valid_field("IXFCREF"  , 1   , "reference type");
  add_valid_field("IXFCNDIM" , 2   , "number of dimensions");
  add_valid_field("IXFCDSIZ" ,-1   , "size of each dimension");

  # Add data record fields
  add_valid_field("IXFDRECL" , 6   , "record length");
  add_valid_field("IXFDRECT" , 1   , "record type = D");
  add_valid_field("IXFDRID"  , 3   , "D record identifier");
  add_valid_field("IXFDFIL1" , 4   , "reserved");
  add_valid_field("IXFDCOLS", -1   , "variable columnar data");

  # Add application record fields
  add_valid_field("IXFARECL" , 6   , "record length");
  add_valid_field("IXFARECT" , 1   , "record type = A");
  add_valid_field("IXFAPPID" , 12  , "application identifier");
  add_valid_field("IXFADATA" ,-1   , "variable application-specific data");
}

sub add_valid_field
{
  my ($name, $length, $comment, $type) = @_;
  $type = "CHARACTER" unless defined $type;

  $valid_fields{$name} = IXF::FieldRaw->new($name, $length, $type, $comment);
}

1;

