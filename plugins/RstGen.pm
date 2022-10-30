#!/usr/bin/env perl

package RstGen;
use strict;
use warnings FATAL => qw(all);

use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);

use eFuncPrint;

=head1 RstGen

  &eFunc::RstGen("");

  Optional Inputs:
    -clk clk_name    :  name of logic working on clock
    -output name     :  name suffix of output signals
    
    -en    en_ctrl   :  enable/disable ctrl signal name
    -test            :  generate test logic(OCC) if enabled

=cut

use base ("Exporter");
our @EXPORT = qw(RstGen);

sub RstGen {
    my $args = shift;
    @ARGV = shellwords($args);
    
    #================================
    # OPTIONS
    #================================
    my $clk     = "clk";
    my $osuffix = "suffix";
    
    my $en    = "";
    my $test  = 0;
    
    GetOptions (
               'clk=s'     => \$clk,
               'output=s'  => \$osuffix,
               'en=s'      => \$en,
               'test=s'    => \$test,
               )  or die "Unrecognized options @ARGV";
    
    #================================

    vprintl("\n//| =========================================================\n");
	vprintl("//| RstGen function is still underconstruction, need more time\n");
	vprintl("//| any suggestion or solotion or contribution is really welcome!\n");
    vprintl("//| =========================================================\n\n");

    #================================
}

1;
