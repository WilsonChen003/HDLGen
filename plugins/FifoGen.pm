#!/usr/bin/env perl

package FifoGen;
use strict;
use warnings FATAL => qw(all);

use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);

use eFuncPrint;

=head1 FifoGen

  &eFunc::FifoGen("");

  Optional Inputs:
    -clk clk_name    :  name of logic working on clock
    -output name     :  name suffix of output signals
    
    -reset  rst_name :  enable/disable ctrl signal name
    -test            :  generate test logic(OCC) if enabled

=cut

use base ("Exporter");
our @EXPORT = qw(FifoGen);

sub FifoGen {
    my $args = shift;
    @ARGV = shellwords($args);
    
    #================================
    # OPTIONS
    #================================
    my $clk     = "clk";
    my $osuffix = "suffix";
    
    my $reset = "";
    my $test  = 0;
    
    GetOptions (
               'clk=s'     => \$clk,
               'output=s'  => \$osuffix,
               'reset=s'   => \$reset,
               'test=s'    => \$test,
               )  or die "Unrecognized options @ARGV";
    
    #================================

    vprintl("\n//| =========================================================\n");
	vprintl("//| FifoGen function is still underconstruction, need more time\n");
	vprintl("//| any suggestion or solotion or contribution is really welcome!\n");
    vprintl("//| =========================================================\n\n");

    #================================
}

1;
