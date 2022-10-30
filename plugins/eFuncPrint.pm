#!/usr/bin/env perl

package eFuncPrint;
use strict;
use warnings FATAL => qw(all);
 
use base ("Exporter");
our @EXPORT = qw(
    vprintl
    );

sub vprintl {
  my @list = @_;
  foreach my $item (@list) {
    &HDLGen::vprintl("$item");
  } 
} 
    

1;
