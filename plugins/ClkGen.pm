#!/usr/bin/env perl
		
##############################################################################################################
##############################################################################################################
##############################################################################################################
###                         Copyright 2022 Wilson Chen                                                     ###
###            Licensed under the Apache License, Version 2.0 (the "License");                             ###
###            You may not use this file except in compliance with the License.                            ###
###            You may obtain a copy of the License at                                                     ###
###                    http://www.apache.org/licenses/LICENSE-2.0                                          ###
###            Unless required by applicable law or agreed to in writing, software                         ###
###            distributed under the License is distributed on an "AS IS" BASIS,                           ###
###            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.                    ###
###            See the License for the specific language governing permissions and                         ###
###            limitations under the License.                                                              ###
##############################################################################################################
##############################################################################################################
##############################################################################################################


package ClkGen;
use strict;
use warnings FATAL => qw(all);

use Text::Template;
use JSON;


=head1 ClkGen

  &eFunc::ClkGen("mod_name", "json_file");

  Required Inputs:
    mod_name      :  generated RTL & Module name 
    json_file     :  containt all parameters template design file needs

    template_file :  design template file as verilog HDL, any parameter can be replaced by $vars in above json file
	                all Perl syntax is supported 

=cut

use base ("Exporter");
our @EXPORT = qw(ClkGen);

sub ClkGen {
    my $mod_name = shift;
    my $cfg_file = shift;

    open(MOD_OUT, ">${mod_name}.v") or die "!!! Error: can't find output module file of (${mod_name}.v) \n\n";
    #================================
    #================================
    our $clk     = "clk";
    
    my $reset = "";
    my $test  = 0;
    
    my $left  = "<:";
    my $right = ":>";
    #================================


    my $cfg_json = &HDLGen::FindFile($cfg_file);
    open(JSON, "<$cfg_json") or die "!!! Error: can't find input cfg JSON file of ($cfg_json) \n\n";
    my $json_text = do { local $/; <JSON> };
    close(JSON);
    my $cfg_hash = decode_json($json_text);
	$cfg_hash->{"mod_name"} = "$mod_name";

	my $async = $cfg_hash->{"async"};
 
    #================================
    my $result = "";

    my $tmpl_file = "$main::HDLGEN_ROOT/plugins/Design_Template/Clk.tmpl.v";
   	if (!(-e $tmpl_file)) {
   		die " !!!ERROR!!!: your ClkGen design template does NOT existe!\n";
   	}
    my $template = Text::Template->new(DELIMITERS => [$left, $right], TYPE => "FILE", SOURCE => "$tmpl_file");
    $result = $template->fill_in(HASH => \%$cfg_hash, OUTPUT => \*MOD_OUT);
    
	close(MOD_OUT);



}

1;
