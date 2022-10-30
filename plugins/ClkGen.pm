#!/usr/bin/env perl

package ClkGen;
use strict;
use warnings FATAL => qw(all);

use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);

use eFuncPrint;

=head1 ClkGen

  &eFunc::ClkGen("[-clk clk_name>] [-output clk_name>] [-divide div_by_N] [-src0 src0] ... [src17 src17] [-en en_ctrl] [-test]");

  Optional Inputs:
    -clk clk_name    :  name of logic working on clock
    -output clk_name :  name of output clock
    
    -srcN  clk_src_N :  input clk soruce, from src0 to src7
    -divide divN     :  clk-divider of div_by_N
    -en    en_ctrl   :  enable/disable ctrl signal name
    -test            :  generate test logic(OCC) if enabled

=cut

use base ("Exporter");
our @EXPORT = qw(ClkGen);

sub ClkGen {
    my $args = shift;
    @ARGV = shellwords($args);
    
    #================================
    # OPTIONS
    #================================
    my $clk   = "clk";
    my $oclk  = "clk_out";
    my $divn  = "1";
    my $src0  = "";
    my $src1  = "";
    my $src2  = "";
    my $src3  = "";
    my $src4  = "";
    my $src5  = "";
    my $src6  = "";
    my $src7  = "";
    
    my $en;
    my $test  = 0;
    
    GetOptions (
               'clk=s'     => \$clk,
               'output=s'  => \$oclk,
               'en=s'      => \$en,
               'test=s'    => \$test,
               'divn=s'    => \$divn,
               'src0=s'    => \$src0,
               'src1=s'    => \$src1,
               'src2=s'    => \$src2,
               'src3=s'    => \$src3,
               'src4=s'    => \$src4,
               'src5=s'    => \$src5,
               'src6=s'    => \$src6,
               'src7=s'    => \$src7,
               )  or die "Unrecognized options @ARGV";
    
    #================================
    vprintl("\n//| =========================================================\n");
	vprintl("//| ClkGen function is still underconstruction, need more time\n");
	vprintl("//| any suggestion or solotion or contribution is reall welcome!\n");
    vprintl("//| =========================================================\n\n");

    #================================
}

1;
