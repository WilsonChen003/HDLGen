#!/usr/bin/env perl
		
##############################################################################################################
##############################################################################################################
##############################################################################################################
###                         Copyright 2022~2023 Wilson Chen                                                ###
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


package HDLGen;

#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#========================================= Public Packages ==================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
use File::Basename;
use File::Find;
use Cwd qw/abs_path/;
use Term::ANSIColor qw(:constants);
use Getopt::Long qw(GetOptions);
use XML::Simple;
use Verilog::Netlist;
use JSON;
use Data::Dumper;

$Term::ANSIColor::AUTORESET = 1;
#============================================================================================================#
#========================================= End of Public Packages ===========================================#
#============================================================================================================#

use lib abs_path(dirname(__FILE__)) . '/plugins';


#============================================================================================================#
#========================= Inhouse Packages for internal developed functions ================================#
#============================================================================================================#
use eFunc;

use HDLGenIpxIntf;


our(@SRC_PATH)= ("./"); 

#============================================================================================================#
our $CurMod_Top=();
our $CurInst ="";
our $CurIPX = ();
our @VOUT=();
our $AutoWires = ();
our $AutoRegs  = ();
our $AutoWarnings = ();
our $AutoInstSigs =();
our $vout_autowirereg  = 0;
our $vout_autoinstwire = 0;
our $vout_autoinst_warning = 0;
our $verilog2001  = 0;

our $AUTO_DEF  = "";
our $AUTO_INST = "";
our $AUTO_DONE = 0;


my($escript_n)   = 0;
my($epython_num) = 0;
my($epython_f)   = "";
my($PerlBegin)   = 0;
my($PythonBegin) = 0;

my($InstIfdef) = "";
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#=============================================== Sub Functions ==============================================#
#============================================================================================================#
#============================================================================================================#


#============================================================================================================#
#------ Update Inc Env ------#
#============================================================================================================#
sub SRC{
  my $src_path = shift;
  push @SRC_PATH, $src_path;
}

#============================================================================================================#
#------ Print Info ------#
#============================================================================================================#
sub HDLGenInfo {
    my($SubName)=shift;
    my($InfoMsg)=shift;
    print STDOUT BOLD BLUE " ---(&$SubName) Info: $InfoMsg\n";
}


#============================================================================================================#
#------ Print Error ------#
#============================================================================================================#
sub HDLGenErr {
    my($SubName)=shift;
    my($ErrMsg)=shift;
    print STDOUT BOLD RED " ---(&$SubName) Error: $ErrMsg\n";
}


#============================================================================================================#
#=========================================== Sub Functions ==================================================#
#============================================================================================================#

#============================================================================================================#
#------ initlize all global vars ------#
#============================================================================================================#
sub Initial {

    $CurMod_Top =();
    $CurInst    ="";
    $CurIPX     =();
    @VOUT       =();
    $AutoWarnings  =();
    $AutoWires  =();
    $AutoRegs   =();
    $AutoInstSigs  =();
    $vout_autoportlist     = 0;
    $vout_autowirereg  = 0;
    $vout_autoinstwire = 0;
    $vout_autoinst_warning = 0;

    $AUTO_DEF  = "";
    $AUTO_INST = "";
    $AUTO_DONE = "0";

    $escript_n   = 0;
    $epython_num = 0;
    $epython_f   = "";
    $PerlBegin   = 0;
    $PythonBegin = 0;

    @SRC_PATH= ("./"); 
	$Expt_Intf = ();

    $InstIfdef = "";  

}

#============================================================================================================#
#------ Process 1 file ------#
#============================================================================================================#
sub ProcessOneFile {
	my $hdl_in = shift;
	my $hdl_out= shift;

	&Initial();

    open(V_IN, "<$hdl_in") or die "!!! Error: can't find input soruce file of ($hdl_in) \n\n";
    
    $hdl_in =~ /(\w+)\.(\w+)$/;
    if ($hdl_out eq "") {
        $hdl_out = "$1".".v";
    }
    my $output_vxp = "."."$1".".${2}p";
    
    if ($main::debug ne "") {
      open(VXP_OUT, ">$output_vxp") or die "!!! Error: output file of ($output_vxp) can\'t create!\n";
    }
    
    my $port_psr_done = 0;
    #============================================================================================================#
    #============================================================================================================#
    #===================================== Main Loop to handle 1 input file =====================================#
    #============================================================================================================#
    #============================================================================================================#
    while (<V_IN>) {
      if ($_ =~ /^\s*module \s*(\S*)/) {
		  $CurMod_Top->{"module"}=$1;
    	  push @VOUT, "$_";
	  } elsif ($_ =~ /^\s*\/\/:\s*&?AutoDef/) {
    	  $AUTO_DEF = "AutoDef";
      	  push @VOUT, "//|: &AutoDef;\n";
    	  $vout_autowirereg = 1;
		  $port_psr_done = 1;
      } elsif ($_ =~ /^\s*\/\/:\s*&?AutoInstSig/) {
    	  $AUTO_INST = "AutoInstSig";
      	  push @VOUT, "//|: &AutoInstSig;\n";
    	  $vout_autoinstwire = 1;
      } elsif ( ($PerlBegin eq "1") or ($PythonBegin eq "1") ) {
          &PerlGen($_,$escript_n);
      } elsif ($_ =~ /^\s*(\/\/)/ ) {
          if ($_ =~ /^\s*(\/\/):/) {
             if ($_ =~ m/:\s*&?PerlRequire (\S+)/) {
                 require $1;
       	         next;
             } elsif ($_ =~ m/:\s*&?PerlInc (\S+)/) {
                 push @INC, "$1";
    	         next;
             } elsif ($_ =~ m/:\s*&?SRC (\S+)/) {
                 &SRC($1);
    	         next;
             } 
    	     $escript_n++;
             &PerlGen($_,$escript_n);
          } elsif ( $_ =~ /^\s*(\/\/)#/) {
             &PythonGen($_,$escript_n);
          } else { 
    		 push @VOUT, "$_";
             print VXP_OUT "###$_" if ($main::debug ne "");
          }
      } elsif ($_ =~ /^\s*&?Instance \s*(.*)\s*/) {
         &PerlGen($_,$escript_n);
      } else {
		  if ($port_psr_done eq "0") {
		      if ($_ =~ /^\s*,?(input|output|inout)/) {
		          $verilog2001 = 1 if ($_ =~ / (wire|reg|logic|bit)/);
		    	  $port_psr_done = 1;
		      }
		  }

    	  if ( ( ($AUTO_DEF eq "AutoDef") or ($AUTO_INST eq "AutoInstSig") ) ) {
                &ParseWireReg($_);
    	  }
    	  &RplcLine($_); 
          print VXP_OUT "###$_" if ($main::debug ne "");
      }
    }
    close(V_IN);
    close(VXP_OUT) if ($main::debug ne "");
    
    open(V_OUT, ">$hdl_out") or die "!!! Error: output file of ($hdl_out) can\'t create!\n";
    &PrintVOUT();
    close(V_OUT);
    
    print STDOUT BOLD GREEN " ------<<<<<< $hdl_out generated >>>>>>------ \n\n";
}
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#


#============================================================================================================#
#------ Perl Script Handler ------#
#============================================================================================================#
sub PerlGen {
   my($SubName)="PerlGen";
   my($eperl)="$_[0]";
   my($eperl_num)="$_[1]";
   my(@eperl)=();
   my($eperl_script)="";
   my($CmdError)="";
   my($exa_line)="";

   &HDLGenInfo("$SubName", " current Src input_line == $eperl") if ($main::HDLGEN_DEBUG_MODE);
   $eperl =~ s/^(\s*)(\/\/):\s*//;
   &HDLGenInfo("$SubName", "eperl_line after replace == $eperl") if ($main::HDLGEN_DEBUG_MODE);
   if ( ($eperl =~ /^(Begin)/) or ($PerlBegin eq "1") ) {
        $eperl_script = "";
		if ($PerlBegin eq "1") {
             &HDLGenInfo($SubName, "---current eperl_line = $_") if ($main::HDLGEN_DEBUG_MODE);
             $eperl_script .= "$_";
             push @eperl, "$_";  
		}
	    my $inst =0;
        while (<V_IN>) {
             if ($_ =~ /^\s*(\/\/):End/) {
				 $PerlBegin = 0;
                 &HDLGenInfo($SubName, "---find End, current eperl_line = $_") if ($main::HDLGEN_DEBUG_MODE);
		         last;
	          }
             &HDLGenInfo($SubName, "---current eperl_line = $_") if ($main::HDLGEN_DEBUG_MODE);
	         my $eline = "";
	         if ($_ =~ /^\s*&?Instance \s*(.*)\s*/) {
		         my (@eperl_array, $ep_done);
		         ($eline,$ep_done,@eperl_array) = &InstanceParser($_);
                 &HDLGenInfo($SubName, "--- current ep_done=$ep_done; current eline = $eline;  --- current array = @eperl_array") if ($main::HDLGEN_DEBUG_MODE);
                 push @eperl, @eperl_array;  
                 $eperl_script .= "$eline";
				 $eline = "";
		         last if ($ep_done eq "1");
	          } else {
		        $eline = "$_";
             }
             $eperl_script .= "$eline";
             push @eperl, "$_";  
         }
         &HDLGenInfo($SubName, "---current eperl_script = $eperl_script") if ($main::HDLGEN_DEBUG_MODE);
   } elsif ($eperl =~ /^\s*&?Instance \s*(.*)\s*/) {
	   my ($eline,@eperl_array, $ep_done);
	   ($eline,$ep_done,@eperl_array) = &InstanceParser($eperl);
       push @eperl, @eperl_array;  
       $eperl_script .= "$eline";
	   last if ($ep_done eq "1");
   } else {
        push @eperl, "$eperl";
        $eperl_script .= "$eperl";
        while (<V_IN>) {
          if ( $_ !~ /^(\s*)\/\/:Begin/ ) { 
            if ($_ =~ s/\s*(\/\/):// ) {
                &HDLGenInfo($SubName,"---current eperl_line = $_") if ($main::HDLGEN_DEBUG_MODE);
                $eperl_script .= "$_";
                push @eperl, "$_";
            } else {
               $exa_line = $_;
               last;
            }
          } else {
			  $PerlBegin = 1;
			  last;
		  }
        }
     }
     
    &HDLGenInfo($SubName," get ePerl script==\n$eperl_script\n") if ($main::verbose ne "");
    if ($main::debug ne "") {
       open(PL, ">>.eperl.pl");
       print PL "\n###=========== Begin script_$eperl_num ==============\n";
       print PL "$eperl_script";
       print PL "###============= End script_$eperl_num ==============\n\n";
       close(PL);
     }
     if ($main::debug ne "") {
       print VXP_OUT "\n###============= Begin script_$eperl_num ==============\n";
       print VXP_OUT "$eperl_script";
       print VXP_OUT "###============= End of script_$eperl_num ==============\n\n";
     }
     
     push @VOUT, "//| --- ePerl generated code Begin (DO NOT EDIT BELOW!) ---\n" ;
        foreach $eperl (@eperl) {
            push @VOUT, "//| $eperl";
        }
     my @ePerl_out= &EvalEperl($eperl_script);
     push @VOUT, "//| --- ePerl generated code End (DO NOT EDIT ABOVE!) ---\n\n" ;
	 &RplcLine($exa_line);
}
#================================================================================#
#------ Perl Script Handler End ------#
#================================================================================#

#================================================================================#
#------ eval Perl Script and return an array ------#
#================================================================================#
sub EvalEperl {
  my ($ePerl) = shift;
  my ($CmrErr);
  if ( $ePerl !~ /vprint/) {
     $ePerl =~ s/print\(/vprintl(/g;
     $ePerl =~ s/print\s*"/vprintl "/g;
	 if ($ePerl =~ /<</) {
        $ePerl =~ s/print\s*<</vprintl <</g;
	} elsif ( $ePerl =~ / qq/ ){
        $ePerl =~ s/print\s*qq/vprintl qq/g;
	}
  }
  my $CmdErr = eval("$ePerl");
  print STDOUT " !!!ePerl Error when run script:\n $ePerl\n CmdErr:\n  $@\n" if ($@);
}

#================================================================================#
#------ if Verilog line contain ${var} then need to replace ------#
#------ NOTE: such ${var} must be defined as "our" type!    ------#
#================================================================================#
sub RplcLine {
  my ($line) = shift;
  
  #==========================================================
  #==========================================================
  if ($line =~ /parameter \s*(\S+)\s*=\s*(\d+)/) { 
      $CurMod_Top->{"parameter"}->{"$1"}="$2";
      push @VOUT, "$line";
  } elsif ($line =~ /parameter \s*(\S+)\s*=\s*(.*)/) {
	  my $parm = $1;
	  my $parm_val = $2;
	  if (exists($CurMod_Top->{"parameter"})) {
		  my $Parm_Hash = $CurMod_Top->{"parameter"};
		  foreach my $pm (keys(%$Parm_Hash)) {
			  my $pm_val = $Parm_Hash->{"$pm"};
			  $parm_val =~ s/$pm/$pm_val/g;
		  }
		  $parm_val =eval($parm_val);
      $CurMod_Top->{"parameter"}->{"$parm"}="$parm_val";
	  }
      push @VOUT, "$line";
  }elsif ($line =~ /\$\{\w+\}/) {
	  $line =~ s/\\n/\\\\n/g;
      $line =~ s/\$$/\\\$/;
	  my $p_line = "vprintl(\"$line\");";
	  eval($p_line);
  } else {
    push @VOUT, "$line";
  }
}

#================================================================================#
#------ change print to push into OUT array ------#
#================================================================================#
sub vprintl {
  my @list = @_;
  foreach my $item (@list) {
	  if ($item =~ /\n/) {
	     push @VOUT, "$item";
	  } else {
	     push @VOUT, "$item\n";
	 }
  } 
} 
#================================================================================#
#------ change print to push into OUT array ------#
#================================================================================#
sub vprinti {
  my @list = @_;
  my $item;
  my $line;
  foreach $item (@list) {
    foreach $line (split ("\n", $item)) {
      next unless ($line =~ s/^\s*\|\s?//);
	  if ($line =~ /\n/) {
	     push @VOUT, "$line";
	 } else {
	     push @VOUT, "$line\n";
	 }
    }
  }
}

#================================================================================#
#------ a way to call any shell/perl/python script ------#
#================================================================================#
sub CallCmd {
  my $call_cmd = shift;

  if ( $call_cmd =~ /\.p[l|m]/) {
      system("perl $call_cmd");
  } elsif ( $call_cmd =~ /\.py/) {
      system("python $call_cmd");
  } else {
      system("$call_cmd");
  }
  if ($@) {
	  print STDOUT " ---!!!--- call Cmd Failed as: $@ ---!!!---\n";
  }
}

#================================================================================#
#------ eval Perl Script and return an array ------#
#================================================================================#
sub EvalEpython {
  my ($ePython) = shift;
  my ($CmrErr);

  my $epython_f = "./.epython.py";
  open(EPYTHON,">$epython_f") or die "!!! Error: temp file of $epython_f can\'t create!\n";
  print EPYTHON "$ePython";
  system("chmod +x $epython_f");
  close(EPYTHON);

  my $CmdErr= system("$epython_f > .epython.out");
  print STDOUT " !!!ePython Error when run script:\n $ePython\n CmdErr:\n  $CmdErr\n" if ($CmdErr);

  open(POUT,"<.epython.out");
  my $epython_out = do { local $/; <POUT> };
  close(POUT);
  system("rm $epython_f") if ($main::debug eq "");
  system("rm .epython.out") if ($main::debug eq "");
  return($epython_out);
}

#============================================================================================================#
#------ Python Script Handler ------#
#============================================================================================================#
sub PythonGen {
   my($SubName)="PythonGen";
   my($epython)="$_[0]";
   my($epython_num)="$_[1]";
   my(@epython)=();
   my($epython_script)="";
   my($exa_line)="";
   my($CmdError)="";
   my($py_pre)="";

   $epython =~ s/\s*\/\/#//;
   $epython_script .= "#!/usr/bin/env python3\n";
   $epython_script .= "import os\n";
   $epython_script .= "import sys\n";
   $epython_script .= "import math\n";
   $epython_script .= "import random\n\n";

   if ($epython =~ /^Begin/) {
      my $in_line = <V_IN>;
      return if ($in_line =~ /^\s*\/\/#End/);
      $in_line =~ s/(^\s*)//;
      $py_pre = $1;
      push @epython, "$in_line";
      $epython_script .= "$in_line";
      while (<V_IN>) {
         last if ($_ =~ /^\s*\/\/#End/);
         &HDLGenInfo($SubName,"  epython_line = $_") if ($main::HDLGEN_DEBUG_MODE);
         push @epython, "$_";
         $_ =~s/\^$py_pre//;
         $epython_script .= "$_";
      }
   } else {
     push @epython, "$epython";
     $epython =~ s/(^\s*)//;
     $py_pre =$1;
     &HDLGenInfo($SubName,"1st ePython line = $epython\n") if ($main::HDLGEN_DEBUG_MODE);
     $epython_script .= "$epython";
     while (<V_IN>) {
	     if ($_ =~ s/^\s*\/\/#//) {
		     &HDLGenInfo($SubName,"ePython_line=$_\n") if ($main::HDLGEN_DEBUG_MODE);
		     push @epython, "$_";
		     $_ =~ s/^${py_pre}//;
		     $epython_script .= "$_";
	     } else {
		     $exa_line = $_;
		     last;
	     }
     }
   }
   &HDLGenInfo($SubName, " Get ePython script = @epython \n") if ( $main::HDLGEN_DEBUG_MODE );

   if ($main::debug ne "") {
     print VXP_OUT "\n###=========== Begin script_$epython_num ==============\n";
     print VXP_OUT "$epython_f";
     print VXP_OUT "###============= End of script_$epython_num ==============\n\n";
   }

   push @VOUT, "//|# ePython generated code Begin (DO NOT EDIT BELOW!)\n" ;
      foreach $epython (@epython) {
          push @VOUT, "//#$epython";
      }
   my $ePython_out= &EvalEpython($epython_script);
   push @VOUT, $ePython_out;
   push @VOUT, "//|# ePython generated code End (DO NOT EDIT ABOVE!)\n\n" ;
   push @VOUT, "$exa_line";
}
#================================================================================#
#================================================================================#
	
#============================================================================================================#
#------ Parse Verilog Wire/Reg define ------#
#============================================================================================================#
sub ParseWireReg {
   my($SubName)="ParseWireReg";
   my($vlg_line) = shift;

   if ($AUTO_DEF eq "AutoDef") {
      &ParseReg($vlg_line);
   }

}

sub ParseReg {
   my($vlg_line) = shift;
      if ( ($vlg_line =~ /(\w*)\s*<=\s*(\d+)\'/) or ($vlg_line =~ /(\w*)\s*<=\s*\{?(\d+)\{/) ) {
 	    my $reg_sig = $1;
 	    my $reg_wd = $2 - 1;
 	    return if (exists($CurMod_Top->{"regs"}->{"$reg_sig"}));
 	    return if (exists($AutoRegs->{"$reg_sig"}->{"done"}));
 	    if ( $reg_wd eq "0" ) {
 	       $AutoRegs->{"$reg_sig"}->{"width"} = "1";
	   } elsif ($reg_wd =~ /:/) {
 	       $AutoRegs->{"$reg_sig"}->{"width"} = "$reg_wd";
 	    } else {
 	       $AutoRegs->{"$reg_sig"}->{"width"} = "$reg_wd:0";
 	    }
 	    $AutoRegs->{"$reg_sig"}->{"done"} = "1";
      } elsif ($vlg_line =~ /(\S*)\s*<=\s*(\S*)/ ) {
 	    my $reg_sig = $1;
 	    my $reg_right = $2;
 	    my $reg_wd = 0;
 	    $reg_wd = ":" if ($reg_sig =~ /\[.*\]/);
 	    return if (exists($CurMod_Top->{"regs"}->{"$reg_sig"}));
 	    return if (exists($AutoRegs->{"$reg_sig"}->{"done"}));
 	    return if ( $reg_right =~ /\{/);
 	    if ( ($reg_sig =~ /(\w+)\[(.*)\]/) or ($reg_right =~ /(\w+)\[(.*)\]/) ) {
 	        $reg_sig = $1 if ($reg_wd ne "0");
 	  	    $reg_wd = $2;
 	        return if (exists($CurMod_Top->{"regs"}->{"$reg_sig"}));
 	        if ( !exists($AutoRegs->{"$reg_sig"}) ) {
 	  		    $AutoRegs->{"$reg_sig"}->{"width"} = "$reg_wd";
 	  	    } else {
 	  		  my $reg_wd_exist = $AutoRegs->{"$reg_sig"}->{"width"};
 	  		  $reg_wd =~ /(\d+)\s*:(\d+)/;
 	  		  my $reg_wd_msb = $1;
 	  		  my $reg_wd_lsb = $2;
 	  		  $reg_wd_exist =~ /(\d+)\s*:(\d+)/;
 	  		  my $reg_wd_exist_msb = $1;
 	  		  my $reg_wd_exist_lsb = $2;
 	  		  if ($reg_wd_lsb >= $reg_wd_exist_msb) {
 	  			  $reg_wd = $reg_wd_msb.":$reg_wd_exist_lsb";
 	  		  } elsif ($reg_wd_msb > $reg_wd_exist_msb) {
 	  			  $reg_wd = $reg_wd_msb.":$reg_wd_exist_lsb";
 	  		  }
 	  		  $AutoRegs->{"$reg_sig"}->{"width"} = "$reg_wd";
 	  	   }
 	    } else {
 	  	  if ($reg_right =~ /\[(.*)\]/) {
 	  		  $reg_wd = $1;
 	  	  } else {
			  $reg_wd = 1;
		  }
 	      $AutoRegs->{"$reg_sig"}->{"width"} = "1";
 	    }
	    return;
      }
}


#============================================================================================================#
#------ Instance args Handler ------#
#============================================================================================================#
sub InstanceParser {
  my $SubName = "InstanceParser";
  my($eline) = shift;
  my(@eperl_array) = ();
  my($eperl_script)= "";
  my $ep_done = 0;
  my $exa_line ="";

  my $inst_arg = "";

  $InstIfdef = "";  ### clear per instance var

  my $inst_arg = "";
  if ( $eline =~ /^\s*&?Instance \s*(.*)\s*;/ ) {
	  $inst_arg = $1;
      push @eperl_array, "$eline";  
  } elsif ( $eline =~ /^\s*&?Instance \s*(\S*)\s*$/ ) {
	  $inst_arg = "$1\n";
      push @eperl_array, "$eline";  
      while (<V_IN>) {
		  $inst_arg .= $_;
          push @eperl_array, "$_";  
		  last if ( $_ =~ /^\s*\)\s*$/ );
	  }
	  my $next_line = <V_IN>;
	  $next_line =~ s/\s//g;
      push @eperl_array, "//| $next_line";  
	  $next_line =~ s/;//;
	  $inst_arg .= $next_line;
  }
  $eline = "&Instance(\"$inst_arg\");\n";
  $eperl_script .= "$eline";

  my $C_done = 0;
  while (<V_IN>) {
      if ($_ =~ /^\s*(#|\/\/):End/) {
         if ($C_done ne "1") {
	         $eline = "&ConnectDone();\n";
             $eperl_script .= "$eline";
	      }
	      $ep_done = 1;
		  $C_done = 1;
		  $PerlBegin = 0;
	      last;
	  ### Handle ifdef on port		  
      } elsif ($_ =~ /^\s*\`ifdef/) {
          $InstIfdef .= "$_";
          while (<V_IN>) {
              $InstIfdef .= "$_";
	          if ( $_ =~ /^\s*\`endif/ ) { ### parameter done
				  last;
			  }

	      }
      } elsif ($_ =~ /^\s*&?Connect \s*(.*)\s*;/) {
		 my $call_arg = $1; 
         $eline = "&Connect(\"$call_arg\");\n";
      } elsif ($_ =~ /^\s*&?AddParam \s*(.*)\s*;/) {
		 my $call_arg = $1; 
         $eline = "&AddParam(\"$call_arg\");\n";
      } elsif ($_ =~ /^\s*(#|\/\/)/) {
         $eline = "$_";
	     $eline =~ s/\/\//#/;
      } elsif ($_ =~ /^\s*&?ConnectDone/) {
         $eline = "&ConnectDone();\n";
         $eperl_script .= "$eline";
         push @eperl_array, "$_";  
	     $C_done =1;
	     last;
      } elsif ( $_ =~ /^\s*\}/) {
	     $eline = "$_";
      } else {
         $eline = "&ConnectDone();\n";
         $eperl_script .= "$eline";
         $exa_line = $_;
		 if ($exa_line =~ /^\s*\}/) {
	        $eperl_script .= "$exa_line";
		 }
	     $C_done =1;
         &HDLGenInfo($SubName," --- Instance Connection Done @ £º $exa_line \n") if ($main::HDLGEN_DEBUG_MODE);
	     last;
      }
	  $eperl_script .= "$eline";
      push @eperl_array, "$_";  
  }
  &HDLGenInfo($SubName," ---  Instance Get£º $eperl_script \n") if ($main::HDLGEN_DEBUG_MODE);
  return($eperl_script,$ep_done, @eperl_array);
}
#============================================================================================================#

#============================================================================================================#
#------ Module Instance Handler ------#
#============================================================================================================#
sub Instance {
  my($inst_line) = shift;
  my $mod_name = "";
  my $mod_para = "";
  my $mod_inst = "";
  my $mod_parm = "";
  my $ipx_file = "";
  my $js_file = "";
  my $SubName = "Instance";

  if ( $inst_line =~ /\n/ ) {
	  my @line_array = split("\n", $inst_line);
	  $mod_name  = shift(@line_array);
	  $mod_inst  = pop(@line_array);
	  chomp($mod_inst);
	  $mod_parm  = join("\n",@line_array);
  } elsif ( $inst_line =~ /\S+\s*$/ ) {
      if ($inst_line =~ /#\(.+\)/) {
          $inst_line =~ /(\S+)\s+(#\(.+\))\s+(\S+)/;
          $mod_name = $1;
          $mod_parm = $2;
          $mod_inst = $3;
      } else {
          $inst_line =~ /(\S+)\s*(\S+)?/;
          $mod_name = $1;
          $mod_parm = "";
          $mod_inst = $2;
      }
  }
  else {
      die($0," ---!!!--- Verilog Module instane wrong@ $inst_line ---!!!---\n");
  }
  
  if ($mod_name =~ /\.xml/) {
	  $ipx_file = $mod_name;
	  $mod_name =~ s/\.xml//;
  } elsif ($mod_name =~ /\.json/i) {
	  $js_file = $mod_name;
	  $mod_name =~ s/\.json|\.JSON//;
  }
	  
  $mod_inst = "u_$mod_name" if ($mod_inst eq ""); 

  $CurInst = $mod_inst;
  if ($ipx_file ne "") {
     $mod_name=&ParseInstIPX($mod_inst,$mod_parm,$ipx_file);
     $mod_name .= "\n" if ($mod_parm ne "");
     $mod_parm .= "\n" if ($mod_parm ne "");
  } elsif ($js_file ne "") {
     $mod_name=&ParseInstJSON($mod_inst,$mod_parm,$js_file);
     $mod_name .= "\n" if ($mod_parm ne "");
     $mod_parm .= "\n" if ($mod_parm ne "");
  } else {
     &ParseInstVlg($mod_inst,$mod_parm,$mod_name);
  }
  &HDLGenInfo($SubName," --- mod_name==$mod_name, mod_parm==$mod_parm, CurInst==$CurInst \n") if ($main::HDLGEN_DEBUG_MODE);

  $CurMod_Top->{"inst"}->{"$CurInst"}->{"connect_list"}=0;

  $CurMod_Top->{"inst"}->{"$mod_inst"}->{"module"}="$mod_name";
  $CurMod_Top->{"inst"}->{"$mod_inst"}->{"parameter"}="$mod_parm";
  $CurMod_Top->{"inst"}->{"$mod_inst"}->{"instance"}="$mod_inst";

}
#============================================================================================================#

#============================================================================================================#
#------ Pasre Verilog source file and get all inputs & outputs------#
#============================================================================================================#
sub FindVlg {
    my($VlgName)=$_[0];
    my $return_file="";
    File::Find::find( { wanted => sub {
			              my $vlg_file = $File::Find::name;
                          if ( $vlg_file  =~ /$VlgName(.v|.sv)$/ ) {
			                 $return_file=$vlg_file; 
                             return;
                          }
                          }} , @SRC_PATH);
    if ($return_file ne "") {
        return($return_file);
    } else {
       &HDLGenErr("FindVlg"," --- can NOT find src file of ($VlgName) in all src paths!\n");
	   exit(1);
    }
}

#============================================================================================================#
#------ Pasre Verilog source file and get all inputs & outputs------#
#============================================================================================================#
sub FindFile {
    my($FName)=$_[0];
    my $return_file="";
    File::Find::find( { wanted => sub {
			              my $file = $File::Find::name;
                          if ( $file  =~ /$FName$/ ) {
			                 $return_file=$file; 
                             return;
                          }
                          }} , @SRC_PATH);
    if ($return_file ne "") {
       return($return_file);
    } else {
       &HDLGenErr("FindFile"," --- can NOT find src file of ($FName) in all src paths!\n");
	   exit(1);
    }
}
#============================================================================================================#

#============================================================================================================#
#------ Pasre Verilog source file and get all inputs & outputs------#
#============================================================================================================#
sub ParseInstVlg{
    my($SubName)="ParseInstVlg";
    my($mod_inst)=shift;
    my($mod_parm)=shift;
    my($mod_name)=shift;


    my($in_vlg)="";
    $in_vlg = &FindVlg($mod_name); 



    if ( $in_vlg eq "" ) {
	   die;
    } 
    open(VLG_IN, "<$in_vlg") or die " !!! (&ParseInstVlg): Verilog/SV source file ($in_vlg.v/sv) cannot be open !!! \n";
    
    my $module_end   = "0";
    my $module_start = "0";
	my $df_num = 0;
    while(<VLG_IN>) {
        chomp($_);
		if ( ($_ =~ /^\s*\/\//) or !($_ =~ /\S/) ) {
            next ;
		}
		if ( $_ =~ /\s*`define/) {
           $CurMod_Top->{"inst"}->{"$mod_inst"}->{"define"}->{"$df_num"}="$_";
		   $df_num++;
		   next;
		}
	    if ( $_ =~ /module \s*${mod_name}/) {
	       $module_start = "1";
	    } elsif ( ($_ =~/\);/) && ($module_start eq "1") ) {
	        $module_end = "1";
	        &HDLGenInfo($SubName, " --- found ); on cur line:$_") if ($main::HDLGEN_DEBUG_MODE);
	        last if (exists $CurMod_Top->{"inst"}->{"$mod_inst"}->{"input"});
        } elsif ( ($_ =~ /^\s*always/) or ($_ =~ /^s*assign/) ) {
	        last; 
	    } elsif ($_ =~ /endmodule/ ) {
	        $module_end = "2";
	        last;
	    }

	    if ($_ =~ /^\s*,?input/) {
	       &HDLGenInfo($SubName, " --- find input line as: $_") if ($main::HDLGEN_DEBUG_MODE);
	       my($i_sig,$p_width)=&ParsePorts("$_");
		   if ($i_sig =~ /,/) {
	              my @p_array = split(",",$i_sig);
	              foreach my $pp (@p_array) {
	                  $CurMod_Top->{"inst"}->{"$mod_inst"}->{"input"}->{"$pp"}->{"width"}="$p_width";
	              }
               } else {
	              $CurMod_Top->{"inst"}->{"$mod_inst"}->{"input"}->{"$i_sig"}->{"width"}="$p_width";
               }
        } elsif ($_ =~ /^\s*,?output/) {
	       &HDLGenInfo($SubName, " --- find output line as: $_") if ($main::HDLGEN_DEBUG_MODE);
	       my($o_sig,$p_width)=&ParsePorts("$_");
	       $CurMod_Top->{"inst"}->{"$mod_inst"}->{"output"}->{"$o_sig"}->{"width"}="$p_width";
	    }
     }
     close(VLG_IN);
}
#============================================================================================================#
	       
#============================================================================================================#
#------ Pasre IPXACT source file and get all inputs & outputs & interfaces------#
#============================================================================================================#
sub ParseInstIPX{
    my($SubName)="ParseInstIPX";
    my($mod_inst)=shift;
	chomp($mod_inst);
    my($mod_parm)=shift;
    my($ipx_file)=shift;

	my $mod_name = &ParseIPX($ipx_file);
    my $IPX_intf = $CurIPX->{"$mod_name"}->{"busInterfaces"};
	foreach my $intf (keys(%$IPX_intf)) {
		my $intf_hash = $IPX_intf->{"$intf"};
        &AddIntf($intf, $intf_hash);
	}

	&HDLGenInfo($SubName, " --- mod_name=$mod_name, mod_inst=$mod_inst, mod_parm=$mod_parm\n") if ($main::HDLGEN_DEBUG_MODE);

    my $IPX_port = $CurIPX->{"$mod_name"}->{"ports"};
	foreach my $port (keys(%$IPX_port)) {
        my $port_sig = $IPX_port->{"$port"};
	    my @p_sig = split(":",$port_sig);
	    if ($p_sig[0] =~ /input/) {
	        $CurMod_Top->{"inst"}->{"$mod_inst"}->{"input"}->{"$port"}->{"width"}="$p_sig[1]";
	    } elsif ($p_sig[0] =~ /output/) {
	        $CurMod_Top->{"inst"}->{"$mod_inst"}->{"output"}->{"$port"}->{"width"}="$p_sig[1]";
	    }
   }

   $CurMod_Top->{"inst"}->{"$mod_inst"}->{"module"}="$mod_name";
   $CurMod_Top->{"inst"}->{"$mod_inst"}->{"parameter"}="$mod_parm";

   return($mod_name);
}

#============================================================================================================#
#------ Pasre IPXACT source file and get all inputs & outputs & interfaces------#
#============================================================================================================#
sub ParseIPX {
    my($ipx_file)=shift;
	my $mod_name = basename($ipx_file);

	$ipx_file = &FindFile($ipx_file);
    my $IP_XACT = &ReadXML($ipx_file);
	$mod_name = $IP_XACT->{"name"} if (exists($IP_XACT->{"name"}));
	&HDLGenInfo("ParseIPX", " --- mod_name=$mod_name\n") if ($main::HDLGEN_DEBUG_MODE);

    if ($main::debug) {
        open(XXML,">.$ipx_file.hash");
        print XXML Dumper($IP_XACT);
        close(XXML);
    }

	my($I) = $IP_XACT->{"busInterfaces"}->{"busInterface"};
    my($P) = $IP_XACT->{"model"}->{"ports"}->{"port"};
    foreach my $intf (keys(%$I)) {
        my $intf_hash = ();
        my @P = $I->{$intf}->{portMaps}->{portMap};
        foreach my $pp (@P) {
            foreach my $ppp (@$pp) {
            my $pppp = $ppp->{physicalPort};
            my $p_name = $pppp->{name};
            my $p_width = $pppp->{vector}->{left} - $pppp->{vector}->{right} + 1;
            my $inout ="port";
            if (exists($P->{$p_name}->{wire}->{direction})) {
      	        $inout = "$P->{$p_name}->{wire}->{direction}"."put";
            }
            $intf_hash->{"$p_name"} = "$inout: $p_width";
            }
        }
        $CurIPX->{"$mod_name"}->{"busInterfaces"}->{"$intf"} = $intf_hash;
    }

	foreach my $port (keys(%$P)) {
		my $port_hash = $P->{"$port"}->{"wire"};
		my $p_width = 0;
		if (exists($port_hash->{vector})) {
		   my $left  = $port_hash->{vector}->{left}; 
		   my $right = $port_hash->{vector}->{right}; 
		   if (ref($left) eq "HASH") {
		       if (exists($left->{"expression"})) {
		       	$left = $left->{"expression"};
		       }
	       }
		   if (ref($right) eq "HASH") {
		      if (exists($right->{"expression"})) {
		      	$right = $right->{"expression"};
		      }
		   }
           $p_width = $left - $right + 1;
	    } else {
		   $p_width = "1";
	    }

		if ($port_hash->{"direction"} =~ /in/) {
	       $CurIPX->{"$mod_name"}->{"ports"}->{"$port"}="input:$p_width";
	   } elsif ($port_hash->{"direction"} =~ /out/) {
	       $CurIPX->{"$mod_name"}->{"ports"}->{"$port"}="output:$p_width";
	   } else {
	       $CurIPX->{"$mod_name"}->{"ports"}->{"$port"}="wire:$p_width";
	   }
	}

	return($mod_name);
}


#============================================================================================================#
#------ Pasre JSON source file and get all inputs & outputs & interfaces------#
#============================================================================================================#
sub ParseInstJSON {
  my $SubName = "ParseInstJSON";
  my($mod_inst)=shift;
  chomp($mod_inst);
  my($mod_parm)=shift;
  my($json_file)=shift;

  my $json_text = ();
  my $intf_name = "";
  my $JSON_hash = "";
  my $mod_name  = "";
  my $intf_hash = ();
  my $port_hash = ();

  $json_file = &FindFile($json_file);
  if ( -e $json_file ) {
      open(JSON, "<$json_file") or die "!!! Error: can't find input JSON file of ($json_file) \n\n";
      $json_text = do { local $/; <JSON> };
      close(JSON);
      $JSON_hash = decode_json($json_text);
      
	  $mod_name = $JSON_hash->{"module"} if (exists($JSON_hash->{"module"}));

	  $intf_hash = $JSON_hash->{"busInterfaces"};
      foreach $intf_name (keys(%$intf_hash)) {
          &AddIntf($intf_name, $intf_hash->{$intf_name},1);
      }

	  $port_hash = $JSON_hash->{"ports"};
      foreach my $port (keys(%$port_hash)) {
		my $port_sig = $port_hash->{"$port"};
	    my @p_sig = split(":",$port_sig);
	    if ($p_sig[0] =~ /input/) {
	        $CurMod_Top->{"inst"}->{"$mod_inst"}->{"input"}->{"$port"}->{"width"}="$p_sig[1]";
	    } elsif ($p_sig[0] =~ /output/) {
	        $CurMod_Top->{"inst"}->{"$mod_inst"}->{"output"}->{"$port"}->{"width"}="$p_sig[1]";
	    }
      }
  } else {
	  &HDLGenErr("ParseInstJSON"," JSON file $json_file doesn't exist");
	  exit(1); 
  }

  $CurMod_Top->{"inst"}->{"$mod_inst"}->{"module"}="$mod_name";
  $CurMod_Top->{"inst"}->{"$mod_inst"}->{"parameter"}="$mod_parm";
  return($mod_name);

}


#============================================================================================================#
#------ Module Instance Handler ------#
#============================================================================================================#
sub Connect {
  my($SubName)="Connect";
  my ($call) = join (" ", @_);
  &HDLGenInfo($SubName,"--- \$call args==$call\n") if ($main::HDLGEN_DEBUG_MODE);

  my ($type) = "";
  my ($srch) = "";
  my ($rplc) = "";
  my ($rule) = "";
  my ($intf) = "";
  my ($final) = "0";
  my ($up) = "0";
  if ($call =~ s/-final//) {
     $final = 1;
  }
  if ($call =~ s/-up(case)?//) {
     $up = 2;
  }
  if ($call =~ s/-low//) {
     $up = 1;
  }
  if ($call =~ /-interface \s*(\w+) \s*(.*)\s*$/) {
      $type = "interface";
      $intf = $1;
      $rplc = $2;
      $srch = "/(.*)/";
  } elsif ( $call =~ /(-input|-output|-inout)?\s*(\S*)\s+(\S+)\s*$/) {
      $type = $1;
      $srch = $2;
      $rplc = $3;
      $type =~ s/-// if ($type);
      $type = "port" if ($type eq ""); 
  } else {
      &HDLGenErr($SubName," --- syntax is wrong @: &Connect $call\n");
  }

  if ($srch =~ /^\w+$/ && $rplc =~ /^\w+$/) {
    $rule = "mapping";
  } elsif ($srch =~ /^\//) {
    $rule = "s".$srch.$rplc."/";
  } else {
    my $conn_new = '^'.$srch.'$' unless ($srch =~ s/^\/(.*?)\/$/$1/);
    $rule = "s/${conn_new}/${rplc}/";
  }

  my $conn_item = $CurMod_Top->{"inst"}->{"$CurInst"}->{"connect_list"} + 1;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{"connect_list"}=$conn_item;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item} = {};
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{srch} = $srch;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{rplc} = $rplc;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{type} = $type;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{intf} = $intf;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{rule} = $rule;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{used} = 0;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{final} = $final;
  $CurMod_Top->{"inst"}->{"$CurInst"}->{connect}->{$conn_item}->{up} = $up;

}
#============================================================================================================#
#============================================================================================================#
#------ AddParam as a new opened issue for paramater instance------#
#============================================================================================================#
sub AddParam {
  my($SubName)="AddParam";
  my ($call) = join (" ", @_);
  &HDLGenInfo($SubName,"--- \$call args==$call\n") if ($main::HDLGEN_DEBUG_MODE);

  my ($param)  = "";
  my ($pm_val) = "";

  if ($call =~ /(\w+) \s*(.*)\s*$/) {
	  $param  = $1;
	  $pm_val = $2;
	  $CurMod_Top->{"inst"}->{"$CurInst"}->{"param"}->{$param} = $pm_val;
  }

}

#============================================================================================================#
#------ Call Connect by update Hash------#
#============================================================================================================#
sub ConnectDone {
  my($SubName)="ConnectDone";
  my(@AllPorts)=();
  my($CI)=$CurMod_Top->{"inst"}->{"$CurInst"};
  my($type)="";
 
  foreach my $in_p (keys %{$CurMod_Top->{"inst"}->{"$CurInst"}->{"input"}}) {
	push @AllPorts, $in_p;
  }
  foreach my $out_p (keys %{$CurMod_Top->{"inst"}->{"$CurInst"}->{"output"}}) {
	push @AllPorts, $out_p;
  }
  foreach my $inout (keys %{$CurMod_Top->{"inst"}->{"$CurInst"}->{"inout"}}) {
	push @AllPorts, $inout;
  }

  foreach my $port (@AllPorts) {
      if (exists ($CI->{"input"}->{$port}) ) {
          $type = "input";
      } elsif (exists ($CI->{"output"}->{$port}) ) {
          $type = "output";
      } elsif (exists ($CI->{"inout"}->{$port}) ) {
          $type = "inout";
      }

      my $all_conn = $CI->{connect_list};
      if ($all_conn > "0") {
          foreach my $conn (1..$all_conn) {
                last if ( exists ($CI->{"$type"}->{"$port"}->{"final"}) );

                my $conn_new=$port;
                &HDLGenInfo($SubName, " --- current connect_item == $conn\n") if ($main::HDLGEN_DEBUG_MODE);
                my $IC = $CI->{"connect"}->{$conn};
                next if ( ($IC->{type} ne "port") && ($IC->{type} ne "interface") && ($IC->{type} ne "$type") );
                my $used = 0;
                if (exists $IC->{rule}) {
                  if ($IC->{rule} eq "mapping") {
                    if ($IC->{srch} eq $port) {
                      $conn_new = $IC->{rplc}; 
                      $used = 1;
                    }
                  } else {
		            if ($IC->{type} eq "interface") {
                    my $intf_name = $IC->{intf};
		            my $intf_h = &GetIntf($intf_name); 
				    my $port_UC = uc($port);
			        if ( !(exists $intf_h->{$port}) and (!(exists $intf_h->{$port_UC})) ) {
					  next;
				  }
		      } 
            	      my $eval = "\$used = \$conn_new =~ $IC->{rule}";
            	      eval ($eval);
            	      &HDLGenErr($SubName,"connection eval ($eval) failure: $@") if ($@);
                  }
                }
                &HDLGenInfo($SubName, " --- cur_port:$port, replaced by $conn_new\n") if ($main::HDLGEN_DEBUG_MODE);
                next unless ($used);

		        if ( $IC->{"up"} eq "2") { 
		           $conn_new = uc($conn_new);
			    } elsif ( $IC->{"up"} eq "1") { 
		           $conn_new = lc($conn_new);
				}
				$conn_new =~ s/\s//;
                $CI->{"$type"}->{"$port"}->{"connect"} = $conn_new;
                $CI->{"$type"}->{"$port"}->{"final"} = "1" if ( $IC->{final} eq "1");
          }
      }
  }
  if ($main::debug) {
     open(INST_HASH,">.$CurInst.hash") or die "!!! Error: cannot create debug file of (.$CurInst.hash) !!!\n";
     print INST_HASH Dumper($CI);
     close(INST_HASH);
  }

  if (exists($CurMod_Top->{"inst"}->{"$CurInst"}->{"param"})) {
	 my $mod_name = $CurMod_Top->{"inst"}->{"$CurInst"}->{"module"};
	 my $mod_inst = $CurMod_Top->{"inst"}->{"$CurInst"}->{"instance"};
     push @VOUT, "$mod_name\n";
     &PrintParam();
     push @VOUT, "  $mod_inst (\n";
  } else {
	 my $mod_name = $CurMod_Top->{"inst"}->{"$CurInst"}->{"module"};
	 my $mod_parm = $CurMod_Top->{"inst"}->{"$CurInst"}->{"parameter"};
	 my $mod_inst = $CurMod_Top->{"inst"}->{"$CurInst"}->{"instance"};
     push @VOUT, "$mod_name $mod_parm $mod_inst (\n";
  }
  &PrintConnect();

}
#============================================================================================================#


#============================================================================================================#
#============================================================================================================#
sub PrintDefine {
	my $cur_inst = shift;

    if (exists($CurMod_Top->{"inst"}->{"$cur_inst"}->{"define"})) {
        my $df_hash = $CurMod_Top->{"inst"}->{"$cur_inst"}->{"define"};
        foreach my $define (%$df_hash) {
      	  print "$df_hash->{$define}\n";
        }
    }
}

#============================================================================================================#
#------ Real Print Connections ------#
#============================================================================================================#
sub PrintParam {
  my($SubName)="PrintParam";
  my($param_hash) = $CurMod_Top->{"inst"}->{"$CurInst"}->{"param"};

  push @VOUT,"   #(\n";
  my $first_line = 1;
  foreach my $param (keys(%$param_hash)) {
	  my $pm_val = $param_hash->{$param};

      if ($first_line) {
          push @VOUT,"       .${param}($pm_val)";
		  $first_line = 0;
      } else {
          push @VOUT,",\n       .${param}($pm_val)";
      }
  }
  push @VOUT,"\n    )\n";

}
#============================================================================================================#

#============================================================================================================#
#------ Real Print Connections ------#
#============================================================================================================#
sub PrintConnect {
  my($SubName)="PrintConnect";
  my($CI)=$CurMod_Top->{"inst"}->{"$CurInst"};
  my($type)="";
  my @wire_array = ();
  my $first_line = 1;

  if ( $AUTO_INST eq "" ) {
     my($inst_w_file)=".$CurInst.wires";
     open(INST_WIRE, ">$inst_w_file") or die " !!! (PrintConnect: file ($inst_w_file) cannot be created!!! \n";
  }

  my $port_length=0;
  my $conn_length=0;
  my $line_pt="";
  my @clk_rst = ();

  foreach my $port (sort(keys %{$CI->{"input"}})) {
	  $port_length = length($port) if (length($port) > $port_length);
      my $conn = $port;
      if (exists $CI->{"input"}->{$port}->{"connect"}) { 
          $conn = $CI->{"input"}->{$port}->{"connect"};
      }
	  $conn_length = length($conn) if (length($conn) > $conn_length);
	  push(@clk_rst, $port) if ($port =~ /clk|clock|rst|reset/i); 
  }
  foreach my $port (sort(keys %{$CI->{"output"}})) {
	  $port_length = length($port) if (length($port) > $port_length);
      my $conn = $port;
      if (exists $CI->{"output"}->{$port}->{"connect"}) { 
          $conn = $CI->{"output"}->{$port}->{"connect"};
	  }
	  $conn_length = length($conn) if (length($conn) > $conn_length);
  }
  $port_length +=1;
  $conn_length +=8;

   ### handle ifdef first since all port may need it
  if ($InstIfdef ne "") {
      push @VOUT,"$InstIfdef";
      my @ifdef_array = split("\n",$InstIfdef);
	  my $ifdef = $ifdef_array[0];
      foreach $if_port (@ifdef_array) {
		  if ($if_port =~ /ifdef \s*(\w*)/) {
			  $ifdef = $1; 
		  } elsif ($if_port =~ /endif/) {
			  next;
		  } else {
	          if ( $AUTO_INST ne "" ) { ### auto signal
			     $if_port =~ /.(\w*)\s*\(\s*(\w*)\s*\)/;
			     my $port = $1;
			     my $conn = $2;
	             my $width= 0;
				 if (exists($CI->{"input"}->{"$port"})) {
	                $width= $CI->{"input"}->{"$port"}->{"width"};
	                $AutoInstSigs->{"$conn"}->{"direction"} = "input";
			     } else {
	                $width= $CI->{"output"}->{"$port"}->{"width"};
	                $AutoInstSigs->{"$conn"}->{"direction"} = "output";
				 }
		         ### use wire name to remove duplication
		         if (exists($AutoInstSigs->{"$conn"})) {
	                $AutoInstSigs->{"$conn"}->{"inst"} .= " & $CurInst";
		         } else {
	                $AutoInstSigs->{"$conn"}->{"inst"} = "$CurInst";
		         }
	             $AutoInstSigs->{"$conn"}->{"width"} = "$width";
	             $AutoInstSigs->{"$conn"}->{"ifdef"} = "$ifdef";
			 }
		  }
	  }
  }


  foreach my $cr (sort(@clk_rst)) {
	  my $port = $cr;
	  my $conn = $CI->{"input"}->{"$cr"}->{"connect"};
	  my $width= $CI->{"input"}->{"$cr"}->{"width"};
	  delete($CI->{"input"}->{"$port"});
	  $conn = "$cr" if ($conn eq "");
	  my $line_pt =	sprintf("%-${port_length}s%-${conn_length}s", $port, "($conn");  
      if ($first_line) {
    	  push @VOUT,"    .$line_pt";
		  $first_line = 0;
      } else {
    	  push @VOUT,"), //|<-i\n    .$line_pt";
      }
      delete($CI->{"input"}->{"$port"});
      $first_line = 0;
	  if ( $AUTO_INST eq "" ) {
	     push @wire_array, "[$width], $conn";
	  } else {
		 $conn =~ s/\[.*\]//; 
		 if (exists($AutoInstSigs->{"$conn"})) {
	        $AutoInstSigs->{"$conn"}->{"inst"} .= " & $CurInst";
		 } else {
	        $AutoInstSigs->{"$conn"}->{"inst"} = "$CurInst";
		 }
	     $AutoInstSigs->{"$conn"}->{"width"} = "$width";
	     $AutoInstSigs->{"$conn"}->{"direction"} = "input";
	  }
  }

  my $IP = $CI->{"input"};
  my $OP = $CI->{"output"};
  if (@clk_rst) {
     if (%$IP) {
        push @VOUT, "), //|<-i\n";
     } elsif (%$OP) {
        push @VOUT, "), //|<-i\n";
     }
  }

  $first_line = 1;

  foreach my $port (sort(keys %{$CI->{"input"}})) {
	  $port_length = length($port) if (length($port) > $port_length);
      my $conn    = $port;
	  my $conn_pt = "";
      my $width = $CI->{"input"}->{$port}->{"width"};
      my $wire_bits  = "";

      if (exists $CI->{"input"}->{$port}->{"connect"}) { 
          $conn = $CI->{"input"}->{$port}->{"connect"};
	  }
      $conn_pt = $conn;

	  if ($width ne "1") {
		  if ($width =~ /:/) {
	          $conn_pt .= "[${width}]" if ($conn !~ /:|'/);
	      } else {
			  $width--;
			  $width= "${width}:0";
	          $conn_pt .= "[${width}]" if ($conn !~ /:|'/);
		  }
      }

	  $line_pt =	sprintf("%-${port_length}s%-${conn_length}s", $port, "($conn_pt");  
      if ($first_line) {
		  push @VOUT,"    .$line_pt";
          $first_line = 0;
      } else {
		  push @VOUT,"), //|<-i\n    .$line_pt";
      }
      
	  if ( $AUTO_INST eq "" ) {
	     push @wire_array, "[$width], $conn";
	  } else {
		 my $c_msb =0;
	 	 my $c_lsb =0;
		 next if ($conn =~ /'/); 
		 if ($conn =~ /\[(.*)\]/) {
            $wire_bits = $1;
		    $conn =~ s/\[.*\]//;
		 }

		 if (exists($AutoInstSigs->{"$conn"})) {
	        $AutoInstSigs->{"$conn"}->{"inst"} .= " & $CurInst";
		 } else {
	        $AutoInstSigs->{"$conn"}->{"inst"} = "$CurInst";
	        $AutoInstSigs->{"$conn"}->{"direction"} = "input";
		 }

		 if ($wire_bits eq "") {
	        $AutoInstSigs->{"$conn"}->{"width"} = "$width"; 
		 } else {
			if (!exists($AutoInstSigs->{"$conn"}->{"width"})) {
	           $AutoInstSigs->{"$conn"}->{"width"} = "$width";
	           $AutoInstSigs->{"$conn"}->{"wire_bits"} = "$wire_bits";
	           if ($wire_bits =~ /:/) {
				   $AutoInstSigs->{"$conn"}->{"auto_width"}= "$wire_bits";
			   } else {
				   $AutoInstSigs->{"$conn"}->{"auto_width"}= "$wire_bits:$wire_bits";
			   }
		    } else {
			    my $wire_bits_existed = $AutoInstSigs->{$conn}->{"wire_bits"};
				my $fnd_num = grep /$wire_bits/, $wire_bits_existed;
				if ($fnd_num ne "1") {
			        $AutoInstSigs->{"$conn"}->{"wire_bits"} .= " $wire_bits";
					my $w_msb =0;
					my $w_lsb =0;
					if ($wire_bits =~ /:/) {
						$wire_bits =~ /(\d+)\s*:\s*(\d+)/;
						$w_msb = $1;
						$w_lsb = $2
					} else {
						$w_msb = $wire_bits;
						$w_lsb = $wire_bits;
					}
					my $p_msb =0;
					my $p_lsb =0;
			        my $auto_width = $AutoInstSigs->{$conn}->{"auto_width"};
					$auto_width =~ /(\d+):(\d+)/;
					$p_msb = $1;
					$p_lsb = $2;
					$p_msb = $w_msb if ($w_msb > $p_msb);
					$p_lsb = $w_lsb if ($w_lsb < $p_msb);
	                $AutoInstSigs->{"$conn"}->{"auto_width"}= "$p_msb:$p_lsb";
				}
			} 
		 } 
	  }

	  $CurMod_Top->{"connections"}->{"input"}->{"$conn"} = 0;
  }

  if (%$IP) {
	  if (%$OP) {
          push @VOUT, "), //|<-i\n";
      }
  }
  $first_line = 1;

  foreach my $port (sort(keys %{$CI->{"output"}})) {
      my $conn = $port;
	  my $conn_pt = "";
      if (exists $CI->{"output"}->{$port}->{"connect"}) { 
          $conn = $CI->{"output"}->{$port}->{"connect"};
      }
      $conn_pt = $conn;

      my $width = $CI->{"output"}->{$port}->{"width"};
      my $wire_bits  = "";

	  if ($width ne "1") {
		  if ($width =~ /:/) {
	          $conn .= "[${width}]" if ($conn !~ /:|'/);
	      } else {
			  $width--;
			  $width= "${width}:0";
	          $conn .= "[${width}]" if ($conn !~ /:|'/);
		  }
      }

	  $line_pt =	sprintf("%-${port_length}s%-${conn_length}s", $port, "($conn");  
	  if ($first_line eq "1") {
         push @VOUT, "    .$line_pt";
		 $first_line = 0 ;
	  } else {
         push @VOUT, "), //|>-o\n    .$line_pt";
	  }

	  if ( $AUTO_INST eq "" ) {
	     push @wire_array, "[$width], $conn";
	  } else {
		 my $c_msb =0;
	 	 my $c_lsb =0;
		 next if ($conn =~ /'/); 
		 if ($conn =~ /\[(.*)\]/) {
            $wire_bits = $1;
		    $conn =~ s/\[.*\]//;
		 }

		 if (exists($AutoInstSigs->{"$conn"})) {
	        $AutoInstSigs->{"$conn"}->{"inst"} .= " & $CurInst";
		 } else {
	        $AutoInstSigs->{"$conn"}->{"inst"} = "$CurInst";
	        $AutoInstSigs->{"$conn"}->{"direction"} = "output";
		 }

		 if ($wire_bits eq "") {
	        $AutoInstSigs->{"$conn"}->{"width"} = "$width"; 
		 } else {
			if (!exists($AutoInstSigs->{"$conn"}->{"width"})) {
	           $AutoInstSigs->{"$conn"}->{"width"} = "$width";
	           $AutoInstSigs->{"$conn"}->{"wire_bits"} = "$wire_bits";
	           if ($wire_bits =~ /:/) {
				   $AutoInstSigs->{"$conn"}->{"auto_width"}= "$wire_bits";
			   } else {
				   $AutoInstSigs->{"$conn"}->{"auto_width"}= "$wire_bits:$wire_bits";
			   }
		    } else {
			    my $wire_bits_existed = $AutoInstSigs->{$conn}->{"wire_bits"};
				my $fnd_num = grep /$wire_bits/, $wire_bits_existed;
				if ($fnd_num ne "1") {
			        $AutoInstSigs->{"$conn"}->{"wire_bits"} .= " $wire_bits";
					my $w_msb =0;
					my $w_lsb =0;
					if ($wire_bits =~ /:/) {
						$wire_bits =~ /(\d+)\s*:\s*(\d+)/;
						$w_msb = $1;
						$w_lsb = $2
					} else {
						$w_msb = $wire_bits;
						$w_lsb = $wire_bits;
					}
					my $p_msb =0;
					my $p_lsb =0;
			        my $auto_width = $AutoInstSigs->{$conn}->{"auto_width"};
					$auto_width =~ /(\d+):(\d+)/;
					$p_msb = $1;
					$p_lsb = $2;
					$p_msb = $w_msb if ($w_msb > $p_msb);
					$p_lsb = $w_lsb if ($w_lsb < $p_msb);
	                $AutoInstSigs->{"$conn"}->{"auto_width"}= "$p_msb:$p_lsb";
				}
			} 
		 } 
	  }
	  $CurMod_Top->{"connections"}->{"output"}->{"$conn"} = 0;
  }

  if (%$OP) {
     push @VOUT, ")  //|>-o\n";
     push @VOUT, "   );\n\n";
  } elsif (%$IP) {
     push @VOUT, ")  //|<-i\n";
     push @VOUT, "   );\n\n";
  } else {
     push @VOUT, ")  //|<-i\n";
     push @VOUT, "   );\n\n";
 }

  if ( $AUTO_INST eq "" ) {
     push @VOUT, "// ---------------------------------------------------------------------------------------\n";
     push @VOUT, "// --- Below Code is for Instance signal define, you need to manually copy/move/modify ---\n";
     push @VOUT, "// --- Recommended way is to use &AutoInstSig at correct place to list these wires    ---\n";
     my($wd, $cn);
     foreach my $w_line (@wire_array) {
   	   ($wd, $cn)  = split(",",$w_line);
   	   $line_pt = sprintf("//  wire %-12s %-${conn_length}s", $wd, $cn);  
   	   push @VOUT, "$line_pt;\n";
     }
     push @VOUT, "// ---------------------------------------------------------------------------------------\n";
  }

}


#============================================================================================================#
#------ parse all assignments which provided by Verilog::Netlist ------#
#============================================================================================================#
sub ParseContAssign {
   my($LHS) = shift;
   my($RHS) = shift;

   my $width= 0;
   my $name = "$LHS";
   if ($LHS =~ /,/) {
	   $LHS =~ s/\n|\s//;
	   $LHS =~ s/^\{|\}$//;
	   my @LHS_list = split(",",$LHS);
	   foreach my $wire (@LHS_list) {
         &ParseAutoWidth($wire,"wire");
       }
   } else {
	   if ($name =~ /\[(.*)\]/) {
	     $name =~ s/\[(.*)\]//;
         $AutoWires->{"$name"}->{"width"} = $1;
         $AutoWires->{"$name"}->{"done"}  = 1;
	   } 

	   if ($RHS =~ /,/) {
	      my $cur_width =0;
		  $width = 0;
	      $RHS =~ s/\n|\s//;
	      $RHS =~ s/^\{//;
	      $RHS =~ s/\}$// if ($RHS !~ /\{/);
	      my @RHS_list = split(",",$RHS);
	      foreach my $wire (@RHS_list) {
             $cur_width = &ParseAutoWidth($wire,"wire");
	         $width += $cur_width;
          }
       } else {
          my $cur_width = &ParseAutoWidth($RHS,"wire");
		  $width = $cur_width;
	   }
	   $width-- if ($width > 1);

       if ( !exists($AutoWires->{"$name"}->{"done"}) ) {
		   if ( ($width ne "0") and ($width ne "1") ) {
              if ($width =~ /:/) {
				  $AutoWires->{"$name"}->{"width"} = "${width}";
			  } else {
				  $AutoWires->{"$name"}->{"width"} = "${width}:0";
			  }
		   } else {
              $AutoWires->{"$name"}->{"width"} = "${width}";
		   }
	   }
   }
}


#============================================================================================================#
#------ Parse 1 single signal which may have [...] or not, can accumulate bit-width ------#
#============================================================================================================#
sub ParseAutoWidth {
	my($wire) = shift;
	my($type) = shift;
	my $width = 0;
	my $cur_width = 0;
	my $name  = "";

	my $AutoHash;
	if ($type eq "wire") {
		$AutoHash = $AutoWires;
	} elsif ($type eq "reg") {
		$AutoHash = $AutoRegs;
	} else {
		die(" !!! not support signal type other than wire or reg !!!\n");
	}

	
	my $CurParam = $CurMod_Top->{"parameter"};
	foreach my $parm (keys(%$CurParam)) {
		my $parm_val = $CurParam->{"$parm"};
		$wire =~ s/$parm/$parm_val/g;
	}

    if ($wire =~ /\{?\s*(\d+)\{/ ) {
	   $cur_width = $1;
	   return($cur_width);
	}
    if ($wire =~ /(\d+)\'/ ) {
	   $cur_width = $1;
	   return($cur_width);
	}

	if ( $wire =~ /(\w*)\[(.*)\]/ )  {
       $name = $1;
       $width = $2;
	   $cur_width = $width;
       my $width_msb = 0;
       my $width_lsb = 0;

	   if ($width =~ /:/) {
          $width =~ /(\S+)\s*:\s*(\S+)/;
          $width_msb = $1;
          $width_lsb = $2;
		  if ($width_msb =~ /-|\+|\*/) {
			  $width_msb = eval($width_msb);
		  }
		  if ($width_lsb =~ /-|\+|\*/) {
			  $width_lsb = eval($width_lsb);
		  }
		  $width = $width_msb.":$width_lsb";
		  $cur_width = $width_msb - $width_lsb + 1;
	   } else {
	       if ($width =~ /-|\+|\*/) {
		       $width = eval($width);
		   }
	      $width = "$width".":$width";
		  $cur_width = 1;
	   }

       if ( !exists($AutoHash->{"$name"}) ) {
          $AutoHash->{"$name"}->{"width"} = "$width";
       } else {
          my $width_exist = $AutoHash->{"$name"}->{"width"};
          $width_exist =~ /(\w+)*:(\w+)/;
          my $width_exist_msb = $1;
          my $width_exist_lsb = $2;
          if ($width_lsb >= $width_exist_msb) {
              $width = $width_msb.":$width_exist_lsb";
          } elsif ($width_msb > $width_exist_msb) {
              $width = $width_msb.":$width_exist_lsb";
          }
          $AutoHash->{"$name"}->{"width"} = "$width";
       }
     } else {
       if ( !exists($AutoHash->{"$name"}) ) {
          $AutoHash->{"$name"}->{"width"} = "1";
       }
	 }
	 return($cur_width);
}



#============================================================================================================#
#------ Placehold for Always block ------#
#============================================================================================================#
#sub ProcessAlways {
#  my $line = shift;
#
#  my $begin = 0;
#  my $end   = 0;
#  if ($line =~ /^\s*always/) {
#	  if ($line =~ /begin/) {
#		  $begin++;
#	  }
#

#============================================================================================================#
#------ Update All Auto Port/Reg/Wire/InstSig hash ------#
#============================================================================================================#
sub UpdateAutos {
    if ( ($AUTO_DEF eq "AutoDef") or ($AUTO_INST eq "AutoInstSig") ) {
		my $mod_name = $CurMod_Top->{"module"};
        $temp_v = ".$mod_name".".vpp";
		open(V_SRC,">$temp_v");
		select(V_SRC);
	    
		my($C)=$CurMod_Top->{"inst"};
        foreach my $inst (%$C) {
			&PrintDefine($inst);
		}
	    foreach my $line (@VOUT) {
			print V_SRC "$line";
		}
		close(V_SRC);
		my $nl = new Verilog::Netlist (link_read=>0, link_read_nonfatal=>1);
        $nl->read_libraries();
        $nl->read_file (filename=>"./$temp_v");
        $nl->link();
		system("rm ./.temp.v");
        foreach my $mod ($nl->top_modules_sorted) {
			my ($name, $type, $width) = ("","","");
	        foreach my $net ($mod->nets_sorted) {
				$name = $net->name;
				$type = $net->decl_type;
				$width= $net->data_type;
				if ($type eq "port") {
				   my $port = $mod->find_port($name);
				   my $dirct = $port->direction;
				   $dirct .= "put" if ($dirct ne "inout");
				   if ($width ne "") {
					   $width =~ s/reg //;
					   $width =~ s/\[|\]//g;
				   } else {
					   $width = 1;
				   }
				   $CurMod_Top->{"ports"}->{"$dirct"}->{"$name"} = $width;
			    } elsif ($type eq "net") {
				   if ($width ne "") {
					   $width =~ s/\[|\]//g;
				   } else {
					   $width = 1;
				   }
				   $CurMod_Top->{"wires"}->{"$name"} = $width;
			    } else {
				   $width = s/reg //;
				   if ($width ne "") {
					   $width =~ s/\[|\]//g;
				   } else {
					   $width = 1;
				   }
			       $CurMod_Top->{"regs"}->{"$name"} = $width;
			    }
            }

	        foreach my $cont ($mod->statements) {
		        my @text = $cont->verilog_text;
				&ParseContAssign($text[2], $text[4]);
	        }
		}


		foreach my $reg (keys(%$AutoRegs)) {
			delete($AutoRegs->{"$reg"}) if (exists($CurMod_Top->{"regs"}->{"$reg"}));
			if ($verilog2001 eq "1") {
			   delete($AutoRegs->{"$reg"}) if (exists($CurMod_Top->{"ports"}->{"input"}->{"$reg"}));
			   delete($AutoRegs->{"$reg"}) if (exists($CurMod_Top->{"ports"}->{"output"}->{"$reg"}));
			}
		}
		foreach my $wire (keys(%$AutoWires)) {
			delete($AutoWires->{"$wire"}) if (exists($CurMod_Top->{"wires"}->{"$wire"}));
			if ($verilog2001 eq "1") {
			   delete($AutoWires->{"$wire"}) if (exists($CurMod_Top->{"ports"}->{"input"}->{"$wire"}));
			   delete($AutoWires->{"$wire"}) if (exists($CurMod_Top->{"ports"}->{"output"}->{"$wire"}));
			}
		}
        foreach my $sig (keys(%$AutoInstSigs)) {
			if ($verilog2001 eq "1") {
			   delete($AutoInstSigs->{"$sig"}) if (exists($CurMod_Top->{"ports"}->{"input"}->{"$sig"}));
			   delete($AutoInstSigs->{"$sig"}) if (exists($CurMod_Top->{"ports"}->{"output"}->{"$sig"}));
			   next;
			}
			if (exists($CurMod_Top->{"wires"}->{"$sig"})) {
			   delete($AutoInstSigs->{"$sig"});
			   next;
		    }
			if (exists($CurMod_Top->{"regs"}->{"$sig"})) {
			   delete($AutoInstSigs->{"$sig"});
			   next;
		    }
			if (exists($AutoWires->{"$sig"})) {
			   delete($AutoWires->{"$sig"});
			   next;
		    }
			if (exists($AutoRegs->{"$sig"})) {
			   delete($AutoRegs->{"$sig"});
	           $AutoInstSigs->{"$sig"}->{"reg"} = "1";
			}
	   }
    }

    &UpdateAutoWarning();

	$AUTO_DONE = 1;

}
#============================================================================================================#


#============================================================================================================#
#------ Update Auto Port hash ------#
#============================================================================================================#
sub UpdateAutoWarning {
   my($SubName)="UpdateAutoWarning";

   my $Inputs  = $CurMod_Top->{"connections"}->{"input"};
   my $Outputs = $CurMod_Top->{"connections"}->{"output"};
   foreach my $in (keys(%$Inputs)) {
   	  $Inputs->{"$in"} = 1 if (exists($Outputs->{"$in"}));
   }
   foreach my $out (keys(%$Outputs)) {
   	  $Outputs->{"$out"} = 1 if (exists($Inputs->{"$out"}));
   }

   for my $sig (keys(%$AutoInstSigs)) {
	   next if ($CurMod_Top->{"ports"}->{"input"}->{"$sig"});
	   next if ($CurMod_Top->{"ports"}->{"output"}->{"$sig"});
	   next if ($CurMod_Top->{"connections"}->{"input"}->{"$sig"} eq 1);
	   next if ($CurMod_Top->{"connections"}->{"output"}->{"$sig"} eq 1);
	   next if ($CurMod_Top->{"regs"}->{"$sig"});
	   next if ($CurMod_Top->{"wires"}->{"$sig"});
	   next if ($AutoRegs->{"$sig"});
	   next if ($AutoWires->{"$sig"});
	   my $inst = $AutoInstSigs->{"$sig"}->{"inst"};
	   $AutoWarnings->{"$inst"}->{"$sig"}->{"direction"} = $AutoInstSigs->{"$sig"}->{"direction"};
       my $width = $AutoInstSigs->{"$sig"}->{"width"};
	   if (exists($AutoInstSigs->{$sig}->{"auto_width"})) {
              $width = $AutoInstSigs->{$sig}->{"auto_width"};
	   }
	   $AutoWarnings->{"$inst"}->{"$sig"}->{"width"} = $width;
   }

}
#============================================================================================================#


#============================================================================================================#
#------ Print auto wire & reg defines ------#
#------ FIXME: unmature or unperfect yet, has bugs so far by 2023/01 ! ------#
#============================================================================================================#
sub  PrintAutoSigs {
   my($SubName)="PrintAutoSigs";
   my $sig_length = 0;
   for my $sig_name (sort(keys(%$AutoWires))) {
       $sig_length = length($sig_name) if (length($sig_name) > $sig_length);
   }
   $sig_length +=3;
   for my $sig_name (sort(keys(%$AutoWires))) {
	   next if ($sig_name eq "");
	   if (!exists($AutoWires->{$sig_name}->{"exists"}) ) { 
		   my $width = $AutoWires->{"$sig_name"}->{"width"};
		   if ( ($width eq "1") or ($width eq "0") ) {
			   $width = "";
		   } else {
		       $width = "["."$width"."]";
	       }
		   my $line_pt = sprintf("wire %-12s %-${sig_length}s", $width, $sig_name);  
		   print "$line_pt;\n";
	   }
   }
   for my $sig_name (sort(keys(%$AutoRegs))) {
       $sig_length = length($sig_name) if (length($sig_name) > $sig_length);
   }
   $sig_length +=3;
   for my $sig_name (sort(keys(%$AutoRegs))) {
	   next if ($sig_name eq "");
	   if (!exists($AutoRegs->{"$sig_name"}->{"exists"}) ) {
		   my $width = $AutoRegs->{$sig_name}->{"width"};
		   if ( ($width eq "1") or ($width eq "0") ) {
			   $width = "";
		   } else {
		       $width = "["."$width"."]";
	       }
		   my $line_pt = sprintf("reg  %-12s %-${sig_length}s", $width, $sig_name);  
		   print "$line_pt;\n";
	   }
   }
}


#============================================================================================================#
#------ Print All &Instance module's wire defines, NO duplication ------#
#============================================================================================================#
sub  PrintAutoInstSigs {
   my($SubName)="PrintAutoInstSigs";
   my $sig_length = 0;
   my $inst = "";
   my $auto_inst = ();
   for my $wire (keys(%$AutoInstSigs)) {
       $inst = $AutoInstSigs->{$wire}->{"inst"};
	   $auto_inst->{"$inst"}->{"$wire"} = $AutoInstSigs->{$wire}->{"width"};
       $sig_length = length($wire) if (length($wire) > $sig_length);
   }
   $sig_length +=3;

   for my $inst (sort(keys(%$auto_inst))) {
     print  "// ------ signals of Instance: $inst ------\n" ;
     my $cur_inst = $auto_inst->{$inst};
     for my $sig_name (sort(keys(%$cur_inst))) {
         next if ($sig_name eq "");
         if ( (exists($AutoWires->{$sig_name}->{"exists"})) or (exists($AutoRegs->{$sig_name}->{"exists"})) ) {
		   next;
		 } else {
           my $width = $cur_inst->{"$sig_name"};
		   if (exists($AutoInstSigs->{$sig_name}->{"auto_width"})) {
              $width = $AutoInstSigs->{$sig_name}->{"auto_width"};
		   }

           if ( $width eq "1" ) {
                   $width = "";
           } elsif ( $width =~ /:/) {
               $width = "[${width}]";
		   }else {
               $width = "[${width}:0]";
           }
           my $line_pt = sprintf("%-12s %-${sig_length}s", $width, $sig_name);
		   if (exists($AutoInstSigs->{"$sig_name"}->{"reg"})) {
			   $line_pt = "reg  "."$line_pt";
		   } else {
			   $line_pt = "wire "."$line_pt";
		   }

		   if (exists($AutoInstSigs->{"$sig_name"}->{"ifdef"})) {
              print "`ifdef $AutoInstSigs->{$sig_name}->{\"ifdef\"}\n";
              print "$line_pt;\n";
              print "`endif\n";
		  } else {
              print "$line_pt;\n";
		  }
        }
     }
   }
   if ($main::debug ne "") {
	   open(INST,">.AutoInstSigs.wires");
	   print INST Dumper(%$AutoInstSigs);
	   close(INST);
   }

}
#============================================================================================================#

#============================================================================================================#
#------ Print All Instance ports which has no Source or Sink as Warning ------#
#============================================================================================================#
sub PrintAutoWarning {
	if (%$AutoWarnings) {
	    print "// ======================================================================\n";
	    print "// !!!!!!!!!!!!!!!!!!!!!! Warning! Warining! Warning ! !!!!!!!!!!!!!!!!!!\n";
	    print "// !!!!!!!!! below signals are Instance's ports no connection ! !!!!!!!!!\n";
	    print "// !!!!!!!!! please carefully check if they're correct or need fix !!!!!!\n";
	    print "// ======================================================================\n";
	    foreach my $inst (sort(keys(%$AutoWarnings))) {
	        print "// ---------------- instance : $inst ---------------\n";
	    	my $I = $AutoWarnings->{"$inst"};
	        foreach my $sig (keys(%$I)) {
	    	   my $dirct = $I->{"$sig"}->{"direction"};
	    	   my $width = $I->{"$sig"}->{"width"};
	    	   printf("//-:  %6s %10s %20s\n", $dirct,"[$width]",$sig);
	       }
	    }
	    print "// ======================================================================\n";
	    print "// ==================== End of Unconnected Ports ========================\n";
	    print "// ======================================================================\n\n";
        $vout_autoinst_warning = 1;
	    print STDOUT BOLD RED "\n !!! Be carefully: some Instance's port has NO source or sink !!!\n";
	    print STDOUT BOLD RED " !!!       Please search & check \"Warninng\" in output RTL     !!!\n\n";
	}
}

#============================================================================================================#
sub PrintRTLHdr {
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!                                                       !!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!    GENERATED BY HDLGEN - EDIT ONLY WHEN NECESSARY     !!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!                                                       !!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
}

#============================================================================================================#
sub PrintVOUT {

	&UpdateAutos() if ($AUTO_DONE eq "0");

	select(V_OUT);
	&PrintRTLHdr() ;
	my($C)=$CurMod_Top->{"inst"};
    foreach my $inst (%$C) {
		&PrintDefine($inst);
	}
	foreach my $line (@VOUT) {
		if ($vout_autowirereg eq "1" ) {
			if ($line eq  "//|: &AutoDef;\n") {
			   $vout_autowirereg = 0;
		       print("$line");
  	           print "//| ================================================================================\n";
  	           print "//| ============ Below Wires & Regs are auto-generated by &AutoDef =================\n";
  	           print "//| ============ these definitions may be not perfect or correct   =================\n";
  	           print "//| ============ you may need to manually update/correct           =================\n";
  	           print "//| ================================================================================\n";
               &PrintAutoSigs();
  	           print "//| ============================= End of Auto Wires/Regs ===========================\n";
  	           print "//| ================================================================================\n\n";
		   } else {
		       print("$line");
		   }
	    } elsif ($vout_autoinstwire eq "1") {
			if ($line eq  "//|: &AutoInstSig;\n") {
			   $vout_autoinstwire = 0;
		       print("$line");
  	           print "//| ====================================================================================\n";
  	           print "//| ======== Below Wires are for all &Instance modules by &AutoInstSig  ===============\n";
  	           print "//| ============ you may need to manually update/correct                 ===============\n";
               &PrintAutoInstSigs();
  	           print "//| ========================= End of Instance Wires/Regs ===============================\n";
  	           print "//| ====================================================================================\n\n";
		       &PrintAutoWarning();
			
		     } else {
		         print("$line");
		     }
	     } else {
		      print("$line");
		 }
    }
}
#============================================================================================================#


#============================================================================================================#
#------ Translate IPXACT file's module name, ports, interfaces into JSON, for integration & debug ------#
#============================================================================================================#
sub TransIPX {
  my $IPX_file = shift;

  my $mod_name = &ParseIPX($IPX_file);


  my $JS_file = $mod_name.".IPX.JSON";
  open JS_F,">","$JS_file";

  print JS_F "{\n";
  print JS_F "    \"module\" : \"$mod_name\",\n\n";

  my $first_intf = 1;

  if (exists($CurIPX->{"$mod_name"}->{"busInterfaces"})) {
     print JS_F "    \"busInterfaces\" : {\n";
     my $intf_hash = $CurIPX->{"$mod_name"}->{"busInterfaces"};
     foreach my $intf_name (keys(%$intf_hash)) {
		if ($first_intf) {
	        print JS_F "        \"$intf_name\" : {\n";
			$first_intf = 0;
	    } else {
	        print JS_F ",\n        \"$intf_name\" : {\n";
		}

        my $first_line = 1;
       	my $Out_Intf = $intf_hash->{"$intf_name"};
        foreach my $sig (keys(%$Out_Intf)) {
            my $port = $Out_Intf->{"$sig"};
            if ($first_line) {
               print JS_F "           \"$sig\" : \"$port\" ";
          	   $first_line = 0;
            } else {
               print JS_F ",\n           \"$sig\" : \"$port\" ";
            }
        }
        print JS_F "\n        }";
     }
     print JS_F "\n    },\n\n";
  }

  print JS_F "    \"ports\" : {\n";

  my $IPX_port = $CurIPX->{"$mod_name"}->{"ports"};
  my $first_line = 1;
  foreach my $port (keys(%$IPX_port)) {
	 my $sig = $IPX_port->{"$port"};
     if ($first_line) {
        print JS_F "           \"$port\" : \"$sig\" ";
        $first_line = 0;
     } else {
        print JS_F ",\n           \"$port\" : \"$sig\" ";
     }
  }
  print JS_F "\n    }\n\n";

  print JS_F "}";

  print STDOUT " ---<<< TOP JSON file of \"$mod_name\" is translated >>>---\n";
}
#============================================================================================================#

#============================================================================================================#
#------  print out current Moduloe's name/port/interface into JSON file ------#
#============================================================================================================#
sub GenModJson {
  my $Mod_name = shift;
  $Mod_name = $CurMod_Top->{"module"} if ($Mod_name eq "");

  my $JS_file = $Mod_name.".JSON";
  open JS_F,">","$JS_file";

  my $pt_line = "";
  my $intf_hash = ();

  print JS_F <<EOF;
{
    "module" : "$Mod_name",
EOF

  if (exists($Expt_Intf->{"busInterfaces"})) {
      print JS_F <<EOF;

    "busInterfaces" : {
EOF

      my $first_intf = 1;
      $intf_hash = $Expt_Intf->{"busInterfaces"};
      foreach my $intf_name (keys(%$intf_hash)) {
            if ($first_intf) {
                print JS_F "        \"$intf_name\" : {\n";
        		$first_intf = 0;
            } else {
                print JS_F ",\n        \"$intf_name\" : {\n";
        	}
            my $first_line = 1;
        	my $Out_Intf = $intf_hash->{"$intf_name"};
            foreach my $sig (keys(%$Out_Intf)) {
				if ( (exists($CurMod_Top->{"ports"}->{"input"}->{"$sig"})) or (exists($CurMod_Top->{"ports"}->{"input"}->{"$sig"})) ) {
                    my $port = $Out_Intf->{"$sig"};
                    if ($first_line) {
        		       $pt_line = sprintf("           \"%-16s\" : \"%s\"", $sig, $port);
              	       $first_line = 0;
                    } else {
        		       $pt_line = sprintf(",\n           \"%-16s\" : \"%s\"", $sig, $port);
                    }
        		    print JS_F "$pt_line";
			    } else {
					print STDOUT BOLD YELLOW " !!!--- port(\"$sig\") of interface(\"$intf_name\") not on module top, please double check ---!!!\n";
				}
            }
            print JS_F "\n        }";
      } 
      print JS_F "\n    },\n\n";

      print JS_F "    \"ports\" : {\n";
      foreach my $intf_name (keys(%$intf_hash)) {
         my $first_line = 1;
         my $pt_done = 0;
         my $Out_Intf = $intf_hash->{"$intf_name"};
         foreach my $sig (keys(%$Out_Intf)) {
			 if ( (exists($CurMod_Top->{"ports"}->{"input"}->{"$sig"})) or (exists($CurMod_Top->{"ports"}->{"input"}->{"$sig"})) ) {
                 my $port = $Out_Intf->{"$sig"};
                 if ($first_line) {
        	         $pt_line = sprintf("           \"%-16s\" : \"%s\"", $sig, $port);
           	         $first_line = 0;
                 } else {
        	         $pt_line = sprintf(",\n           \"%-16s\" : \"%s\"", $sig, $port);
                 }
        	     print JS_F "$pt_line";
				 $pt_done = 1;
			 }
         }
         print JS_F ",\n\n" if ($pt_done eq "1");
      }
  } else {
      print JS_F "    \"ports\" : {\n";
  }

  &UpdateAutos() if ($AUTO_DONE eq "0");
  my $CurPorts=$CurMod_Top->{"ports"}->{"input"};
  my $first_line = 1;
  foreach my $port (keys(%$CurPorts)) {
	  next if (exists($Expt_Intf->{"ports"}->{"$port"}));
	  my $width = $CurPorts->{"$port"};
	  if ($width =~ /(.*):/) {
		  $width = $1;
		  if ($width !~ /[a-zA-Z]/) {
		     $width +=1;
		  } else {
             &HDLGenInfo("GenModJson", " --- find PARAMETER($width) in JSON, please double check \n");
		  }
	  }
      if ($first_line) {
		 $pt_line = sprintf("           \"%-16s\" : \"input:%s\"", $port, $width);
         $first_line = 0;
      } else {
		 $pt_line = sprintf(",\n           \"%-16s\" : \"input:%s\"", $port, $width);
      }
	  print JS_F "$pt_line";
  }
  $first_line = 1;
  $CurPorts=$CurMod_Top->{"ports"}->{"output"};
  foreach my $port (keys(%$CurPorts)) {
	  next if (exists($Expt_Intf->{"ports"}->{"$port"}));
	  my $width = $CurPorts->{"$port"};
	  if ($width =~ /(.*):/) {
		  $width = $1;
		  if ($width !~ /[a-zA-Z]/) {
		     $width +=1;
		  } else {
             &HDLGenInfo("GenModJson", " --- find PARAMETER($width) in JSON, please double check \n");
		  }
	  }
      if ($first_line) {
		 $pt_line = sprintf(",\n\n           \"%-16s\" : \"output:%s\"", $port, $width);
         $first_line = 0;
      } else {
		 $pt_line = sprintf(",\n           \"%-16s\" : \"output:%s\"", $port, $width);
      }
	  print JS_F "$pt_line";
  }

  $first_line = 1;
  $intf_hash = $Expt_Intf->{"ports"};
  foreach my $sig (keys(%$intf_hash)) {
		my $port = $intf_hash->{"$sig"};
        if ($first_line) {
           $pt_line = sprintf(",\n\n           \"%-16s\" : \"%s\"", $sig, $port );
           $first_line = 0;
        } else {
           $pt_line = sprintf(",\n           \"%-16s\" : \"%s\"", $sig, $port );
        }
        print JS_F "$pt_line";
  }


  print JS_F "\n    }\n\n";
  print JS_F "}";

  print STDOUT " ---<<< TOP JSON file of \"$Mod_name\" is generated >>>---\n";
}
#============================================================================================================#




#============================================================================================================#
#============================================================================================================#
1;

