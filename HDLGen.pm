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

package HDLGen;

#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#========================================= Public Packages ==================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
use Getopt::Long qw(GetOptions);
use File::Basename;
use File::Find;
use XML::Simple;
use XML::SAX::Expat; ### FIXME: this is strange as not used at all, but pp need it! 
use JSON;
use Data::Dumper;
use Cwd qw/abs_path/;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
#============================================================================================================#
#========================================= End of Public Packages ===========================================#
#============================================================================================================#

### Add Script Dir as include paths, most for all PlugIn APIs ###
use lib abs_path(dirname(__FILE__)) . '/plugins';


#============================================================================================================#
#========================= Inhouse Packages for internal developed functions ================================#
#============================================================================================================#
#require "eFunc.pm";
use eFunc;
require "HDLGenIpxIntf.pm";
#============================================================================================================#
#================================ End of Inhouse Packages ===================================================#
#============================================================================================================#

#### Default Search path is current & parent dir
#### can update this arrays by //:SRC <path_to_add>
our(@SRC_PATH)= ("./"); 

#============================================================================================================#
our %HDLGen_Top=();
our $CurInst =""; 
our @VOUT=(); ### for finally Verilog output
#============================================================================================================#
local $CODEGEN_DEBUG_MODE= "";
local $AUTO_DEF = "";
local $AUTO_INST = "";

my %AutoWires ; ### Hash table for auto wire/reg define
my %AutoRegs  ; ### Hash table for auto wire/reg define
my %AutoInstWires ; ### Hash table for auto instance wires define
my $vout_autowirereg = 0;
my $vout_autoinstwire = 0;

my $inc_updated = "0";


my($input_src, $output_vlg, $verbose, $debug, $usage) = ("", "", "", "", "");
GetOptions(
    'verbose'     => \$verbose,
    'input=s'     => \$input_src,
    'output=s'    => \$output_vlg,
    'debug'       => \$debug,
    'usage'       => \$usage,
);

if ($verbose ) {
   print("--- Verbose Debug Infomation is turned on ---\n");
}
$CODEGEN_DEBUG_MODE = "1" if ($verbose && $debug);

if ($usage) {
   &Version();
   select STDOUT;
   print <<EOF;
   --------------------------------------------------------------------------------------------------------------
   --------------------------------------------------------------------------------------------------------------
   --- This is a script to read in HDL design file with emdedded Perl/Python scripts in
   --- and generate final HDL files with Perl/Python scripts parsed & executed
   EX:
EOF

   print <<EOF;
      --> $0 -i HDL_Design.src
      --> $0 -i HDL_Design.src -o HDL_Design_NewName.v ( default is HDL_Design.v )
      --> $0 -i HDL_Design.src -d ( run with debug option )
EOF

   RESET;
   print <<EOF;
             will print info and store internal data structures,
             Perl/Python scripts are stored in .eperl.pl or .epython.py
EOF
   print YELLOW <<EOF;
      NOTE: 
             Currently "&AutoDef" for auto wire a/o reg defines is not perfect, or has bugs yet
             this tool can only parse wire signals as simple as: 
EOF

   print GREEN <<EOF;
                                               assign wire_sig[m:n] = left_sig<[q:p]>
EOF

   RESET;
   print YELLOW <<EOF;
             or parse reg  signals as simple as: 
EOF
   print GREEN <<EOF;
                                                reg_sig<[m:n]> <= dd'h/b...
                                            or: reg_sig        <= dd{1'x...
                                            or: reg_sig        <= left_sig[q:p]
EOF
   RESET;
   print <<EOF;
   --------------------------------------------------------------------------------------------------------------
   --------------------------------------------------------------------------------------------------------------

EOF
    exit;
}


if ($debug ne "") {
   system("rm -r .eperl.pl") if (-e ".eperl.pl");
   system("rm -r .epython.py") if (-e ".epython.py");
}

#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#=========================================== Main Function ==================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
open(V_IN, "<$input_src") or die "!!! Error: can't find input soruce file of ($input_src) \n\n";

$input_src =~ /(\w+)\.(\w+)$/;
if ($output_vlg eq "") {
    $output_vlg = "$1".".v";
}
my $output_vxp = "."."$1".".${2}p";

if ($debug ne "") {
  open(VXP_OUT, ">$output_vxp") or die "!!! Error: output file of ($output_vxp) can\'t create!\n";
}

my($escript_n) = 0;
my($PerlBegin) = 0;
my($PythonBegin) = 0;
#============================================================================================================#
#============================================================================================================#
#===================================== Main Loop to handle 1 input file =====================================#
#============================================================================================================#
#============================================================================================================#
while (<V_IN>) {
  ### Handle Auto Wire/Reg define
  if ($_ =~ /&?AutoDef/) {
	  $AUTO_DEF = "AutoDef";
  	  push @VOUT, "//|: &AutoDef;\n";
	  $vout_autowirereg = 1;
     
  } elsif ($_ =~ /&?AutoInstWire/) {
	  $AUTO_INST = "AutoInstWire";
  	  push @VOUT, "//|: &AutoInstWire;\n";
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
         print VXP_OUT "###$_" if ($debug ne "");
      }
  } elsif ($_ =~ /^\s*&?Instance \s*(.*)\s*/) {
     &PerlGen($_,$escript_n);
  } else {
	  if ( ( ($AUTO_DEF eq "AutoDef") or ($AUTO_INST eq "AutoInstWire") ) ) {
            &ParseWireReg($_);
	  }
	  &RplcLine($_); 
      print VXP_OUT "###$_" if ($debug ne "");
  }
} ### end of while
close(V_IN);
close(VXP_OUT) if ($debug ne "");

#### Finally print out Verilog ###
open(V_OUT, ">$output_vlg") or die "!!! Error: output file of ($output_vlg) can\'t create!\n";
&PrintVOUT();
close(V_OUT);

print STDOUT BOLD GREEN " ------<<<<<< $output_vlg generated >>>>>>------ \n\n";
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#============================================ End of Main Function ==========================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#


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
  push @INC, $src_path;
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

#============================================================================================================#
#============================================================================================================#
#------ Perl Script Handler ------#
#============================================================================================================#
#============================================================================================================#
sub PerlGen {
   my($SubName)="PerlGen";
   my($eperl)="$_[0]";
   my($eperl_num)="$_[1]";
   my(@eperl)=();
   my($eperl_script)="";
   my($CmdError)="";
   my($exa_line)="";

   $eperl =~ s/^(\s*)(\/\/):\s*//; ### remove //:
   $INDENT = $1;
   if ( ($eperl =~ /^(Begin)/) or ($PerlBegin eq "1") ) {
        $eperl_script = "";
		if ($PerlBegin eq "1") {
             $eperl_script .= "$_";
             push @eperl, "$_";  
		}
	    my $inst =0; ### if Instance found
        while (<V_IN>) {
             if ($_ =~ /^\s*(\/\/):End/) {
				 $PerlBegin = 0;
		         last;
	          }
	         my $eline = "";
	         if ($_ =~ /^\s*&?Instance \s*(.*)\s*/) {
		         my @eperl_array, $ep_done;
		         ($eline,$ep_done,@eperl_array) = &InstanceParser($_);
                 push @eperl, @eperl_array;  
                 $eperl_script .= "$eline";
				 $eline = ""; ### FIXME: temp fix to handle Instance in for loop
		         last if ($ep_done eq "1");
	          } else {
		        $eline = "$_";
             }
             $eperl_script .= "$eline";
             push @eperl, "$_";  
         } ### end of while
   } elsif ($eperl =~ /^\s*&?Instance \s*(.*)\s*/) {
	   my @eperl_array, $ep_done;
	   ($eline,$ep_done,@eperl_array) = &InstanceParser($eperl);
       push @eperl, @eperl_array;  
       $eperl_script .= "$eline";
	   last if ($ep_done eq "1");
   } else {
        push @eperl, "$eperl";
        $eperl_script .= "$eperl";
        while (<V_IN>) {
          if ( $_ !~ /\/\/:Begin/ ) { 
            if ($_ =~ s/\s*(\/\/):// ) {
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
     
   if ($debug ne "") {
      open(PL, ">>.eperl.pl");
      print PL "\n###=========== Begin script_$eperl_num ==============\n";
      print PL "$eperl_script";
      print PL "###============= End script_$eperl_num ==============\n\n";
      close(PL);
    }
    if ($debug ne "") {
      print VXP_OUT "\n###============= Begin script_$eperl_num ==============\n";
      print VXP_OUT "$eperl_script";
      print VXP_OUT "###============= End of script_$eperl_num ==============\n\n";
    }
    
    push @VOUT, "//| --- ePerl generated code Begin (DO NOT EDIT BELOW!) ---\n" ;
    foreach $eperl (@eperl) {
        push @VOUT, "//| $eperl";
    }
    &EvalEperl($eperl_script);
    push @VOUT, "//| --- ePerl generated code End (DO NOT EDIT ABOVE!) ---\n\n" ;
	$exa_line = &RplcLine($exa_line);
}
#============================================================================================================#
#============================================================================================================#
#===================================## Perl Script Handler end ==============================================#
#============================================================================================================#
#============================================================================================================#

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
  $CmdErr = eval("$ePerl");
  print STDOUT BOLD RED " !!!ePerl Error when run script:\n $ePerl\n CmdErr:\n  $@\n" if ($@);
}

#================================================================================#
#------ if Verilog line contain ${var} then need to replace ------#
#------ NOTE: such ${var} must be defined as "our" type!    ------#
#================================================================================#
sub RplcLine {
  my ($line) = shift;
  if ($line =~ /\$\{\w+\}/) {
	  $line =~ s/\\n/\\\\n/g;
      $line =~ s/\$$/\\\$/;
	  my $p_line = "vprintl qq\001".$line."\001;";
	  eval($p_line);
  } else {
    push @VOUT, "$line";
  }
}

#============================================================================================================#
#============================================================================================================#
#------ Python Script Handler ------#
#============================================================================================================#
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

   ### FIXME: put Python script into a file then exe is not a good idea, need improve later
   $epython =~ s/\s*\/\/#//;
   $epython_script .= "#!/usr/bin/env python\n";
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
         push @epython, "$_";
         $_ =~s/\^$py_pre//;
         $epython_script .= "$_";
      }
   } else {
     push @epython, "$epython";
     $epython =~ s/(^\s*)//;
     $py_pre =$1;
     $epython_script .= "$epython";
     while (<V_IN>) {
	     if ($_ =~ s/^\s*\/\/#//) {
		     push @epython, "$_";
		     $_ =~ s/^${py_pre}//;
		     $epython_script .= "$_";
	     } else {
		     $exa_line = $_;
		     last;
	     }
     }
   }

   if ($debug ne "") {
     print VXP_OUT "\n###=========== Begin script_$epython_num ==============\n";
     print VXP_OUT "$epython_f";
     print VXP_OUT "###============= End of script_$epython_num ==============\n\n";
   }

   push @VOUT, "///: ePython generated code Begin (DO NOT EDIT BELOW!)\n" ;
   foreach $epython (@epython) {
       push @VOUT, "//#|$epython";
   }
   my $ePython_out= &EvalEpython($epython_script);
   push @VOUT, $ePython_out;
   push @VOUT, "///: ePython generated code End (DO NOT EDIT ABOVE!)\n\n" ;
   push @VOUT, "$exa_line";
}

#============================================================================================================#
#=============================== eval Perl Script and return an array =======================================#
#============================================================================================================#
sub EvalEpython {
  my ($ePython) = shift;
  my ($CmrErr);
  ### FIXME: so far I just can image let Python output into a file and then readin that file to push into @VOUT
  my $epython_f = ".epython.py";
  system("rm -r $epython_f") if (-e "$epython_f");
  open(EPYTHON,">$epython_f") or die "!!! Error: temp file of $epython_f can\'t create!\n";
  print EPYTHON "\n###=========== Begin script_$epython_num ==============\n";
  print EPYTHON "$ePython";
  print EPYTHON "###============= End of script_$epython_num ==============\n\n";
  system("chmod +x $epython_f");
  close(EPYTHON);

  open(PTMP,">.epython.out") or die "!!! Error: can't open ./.epython.out !!!\n";
  open(STDOUT, ">&PTMP"); ### redirect STDOUT to output file
  $CMdErr= system("python $epython_f");
  print STDOUT BOLD RED " !!!ePython Error when run script:\n $ePython\n CmdErr:\n  $@\n" if ($@);
  close(STD_OUT);
  open(STDOUT,">>/dev/tty");  ### restore to default STDOUT
  open(PTMP,"<.epython.out");
  my $epython_out = do { local $/; <PTMP> };
  close(PTMP);
  system("rm -rf .epython.py") if ($debug eq "");
  system("rm -rf .epython.out") if ($debug eq "");
  return($epython_out);
}

#============================================================================================================#
#============================================================================================================#
#=================================== Python Script Handler end ==============================================#
#============================================================================================================#
#============================================================================================================#
	
#============================================================================================================#
#==================== Parse Verilog wire/reg define line ====================================================#
#============================================================================================================#
### Only parse signals before "=" or "<=", then store to Hash
sub ParseWireReg {
   my($SubName)="ParseWireReg";
   my($vlg_line) = shift;

   ### get reg define
   if ($vlg_line =~ /\s*^reg/ ) {
      if ($vlg_line !~ /\[/) { ### 1-bit signal
         ##### FIXME: how to handl multi-signal define in 1 line??? 
		 if ( $vlg_line =~ /reg\s*(\w*)/) {
	         my $reg_sig = $1;
			 $AutoRegs->{"$reg_sig"}->{"exists"} = "1";
		 } else {
           &HDLGenErr($SubName," reg signal define($vlg_line) has no signal name! ") if ($CODEGEN_DEBUG_MODE);
		 }
	  } else { ### multi-bits
		 if ( $vlg_line =~ /reg\s*\[(.*)\]\s*(\w*)/) {
	         my $reg_wd = $1;
	         my $reg_sig = $2;
			 $AutoRegs->{"$reg_sig"}->{"exists"} = "1";
		 } else {
           &HDLGenErr($SubName," reg signal define($vlg_line) has no signal name! ") if ($CODEGEN_DEBUG_MODE);
	     }
	  }
	  return;
   }
   ### get wire define
   if ($vlg_line =~ /\s*^wire/ ) {
      if ($vlg_line !~ /\[/) { ### 1-bit signal
         ##### FIXME: how to handl multi-signal define in 1 line??? 
		 if ( $vlg_line =~ /wire\s*(\w*)/) {
	         my $reg_sig = $1;
			 $AutoWires->{"$reg_sig"}->{"exists"} = "1";
		 } else {
           &HDLGenErr($SubName," wire signal define($vlg_line) has no signal name! ") if ($CODEGEN_DEBUG_MODE);
		 }
	  } else { ### multi-bits
		 if ( $vlg_line =~ /wire\s*\[(.*)\]\s*(\w*)/) {
	         my $reg_sig = $2;
			 $AutoWires->{"$reg_sig"}->{"exists"} = "1";
		 } else {
           &HDLGenErr($SubName," wire signal define($vlg_line) has no signal name! ") if ($CODEGEN_DEBUG_MODE);
	     }
	  }
	  return;
   }

   ### ***************************************************************************************
   ### below code is to parse logic but not definition, so need to bypass for Non AutoDef case
   ### ***************************************************************************************
   if ($AUTO_DEF eq "AutoDef") {
      ### Parse Reg
      if ( ($vlg_line =~ /(\w*)\s*<=\s*(\d+)\'/) or ($vlg_line =~ /(\w*)\s*<=\s*\{?(\d+)\{/) ) {
 	    my $reg_sig = $1;
 	    my $reg_wd = $2 - 1;
 	    return if (exists($AutoReg->{"$reg_sig"}->{"exists"}));
 	    if ( $reg_wd eq "0" ) {
 	       $AutoRegs->{"$reg_sig"}->{"width"} = "1";
 	    } else {
 	       $AutoRegs->{"$reg_sig"}->{"width"} = "$reg_wd:0";
 	    }
 	    $AutoReg->{"$reg_sig"}->{"exists"} = "1";
      } elsif ($vlg_line =~ /(\S*)\s*<=\s*(\S*)/ ) { ### left has no width but right may have
 	    my $reg_sig = $1;
 	    my $reg_right = $2;
 	    my $reg_wd = 0;
 	    $reg_wd = ":" if ($reg_sig =~ /\[.*\]/);
 	    return if (exists($AutoReg->{"$reg_sig"}->{"exists"}));
 	    if ( ($reg_sig =~ /(\w+)\[(.*)\]/) or ($reg_right =~ /(\w+)\[(.*)\]/) ) { ### multi-bit signal
 	        $reg_sig = $1 if ($reg_wd ne "0");
 	  	    $reg_wd = $2;
 	        return if (exists($AutoReg->{"$reg_sig"}->{"exists"}));
			return if ( $reg_right =~ /\{/);
 	        if ( !exists($AutoRegs->{"$reg_sig"}) ) {
 	  		    $AutoRegs->{"$reg_sig"}->{"width"} = "$reg_wd";
 	  	    } else { ### need to parse & compare if bit width need increase
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
 	    } else { ### 1-bit signal
 	  	    if ($reg_right =~ /\[(.*)\]/) {
 	  	        my $reg_wd = $1;
 	  	    }
 	          if ( !exists($AutoRegs->{"$reg_sig"}) ) {
 	  	          $AutoRegs->{"$reg_sig"}->{"width"} = "1";
 	  	    }
 	    }
	    return;
      }  ### end of if "<="

      ### Parse Wire
      if ($vlg_line =~ /assign\s*(\S*)\s*=\s*(\S*)/ ) {
         my $reg_sig = $1;
         my $reg_right = $2;
         my $reg_wd = 0;
         $reg_wd = ":" if ($reg_sig =~ /\[.*\]/);
         return if (exists($AutoWires->{"$reg_sig"}->{"exists"}));
		 return if ( $reg_right =~ /\{/);
         if ( ($reg_sig =~ /(\w*)\[(.*)\]/) or ($reg_right =~ /(\w*)\[(.*)\]/) ) { ### multi-bit signal
             $reg_sig = $1 if ($reg_wd ne "0");
       	     $reg_wd = $2;
             if ( !exists($AutoWires->{"$reg_sig"}) ) {
       		    $AutoWires->{"$reg_sig"}->{"width"} = "$reg_wd";
       	     } else { ### need to parse & compare if bit width need increase
       		    my $reg_wd_exist = $AutoWires->{"$reg_sig"}->{"width"};
       		    $reg_wd =~ /(\d*)\s*:(\d*)/;
       		    my $reg_wd_msb = $1;
       		    my $reg_wd_lsb = $2;
       		    $reg_wd_exist =~ /(\d*)\s*:(\d*)/;
       		    my $reg_wd_exist_msb = $1;
       		    my $reg_wd_exist_lsb = $2;
       		    if ($reg_wd_lsb >= $reg_wd_exist_msb) {
       		        $reg_wd = $reg_wd_msb.":$reg_wd_exist_lsb";
       		    } elsif ($reg_wd_msb > $reg_wd_exist_msb) {
       		        $reg_wd = $reg_wd_msb.":$reg_wd_exist_lsb";
       		    }
       		    $AutoWires->{"$reg_sig"}->{"width"} = "$reg_wd";
       	     }
         } else {
             if ( !exists($AutoWires->{"$reg_sig"}) ) {
       		    $AutoWires->{"$reg_sig"}->{"width"} = "1";
       	     }
        }
        return;
     }  ### end of "assign" 

  } ### end of "AutoDef"

}

#============================================================================================================#
#------ Print auto wire & reg defines ------#
#------ FIXME: unmature or unperfect yet, has bugs so far ------#
#============================================================================================================#
sub  PrintAutoSigs {
   my($SubName)="PrintAutoSigs";
   my $sig_length = 0;
   ### Wires
   for my $sig_name (sort(keys(%$AutoWires))) {
       $sig_length = length($sig_name) if (length($sig_name) > $sig_length);
   }
   $sig_length +=3;
   for my $sig_name (sort(keys(%$AutoWires))) {
	   next if ($sig_name eq "");
	   if (!exists($AutoWires->{$sig_name}->{"exists"}) ) { 
		   my $width = $AutoWires->{"$sig_name"}->{"width"};
		   if ( $width eq "1" ) {
			   $width = "";
		   } else {
		       $width = "["."$width"."]";
	       }
		   my $line_pt = sprintf("wire %-12s %-${sig_length}s", $width, $sig_name);  
		   ### NOTE: here need to use print as not in @VOUT
		   print "$line_pt;\n";
	   }
   }
   ### Regs
   for my $sig_name (sort(keys(%$AutoWires))) {
       $sig_length = length($sig_name) if (length($sig_name) > $sig_length);
   }
   $sig_length +=3;
   for my $sig_name (sort(keys(%$AutoRegs))) {
	   next if ($sig_name eq "");
	   if (!exists($AutoRegs->{"$sig_name"}->{"exists"}) ) {
		   my $width = $AutoRegs->{$sig_name}->{"width"};
		   if ( $width eq "1" ) {
			   $width = "";
		   } else {
		       $width = "["."$width"."]";
	       }
		   my $line_pt = sprintf("reg  %-12s %-${sig_length}s", $width, $sig_name);  
		   ### NOTE: here need to use print as not in @VOUT
		   print "$line_pt;\n";
	   }
   }
}


#============================================================================================================#
#------ Print All &Instance module's wire defines, NO duplication ------#
#============================================================================================================#
sub  PrintAutoInstWires {
   my($SubName)="PrintAutoInstWires";
   my $sig_length = 0;
   my $inst = "";
   my $auto_inst = ();
   for $wire (keys(%$AutoInstWires)) {
       $inst = $AutoInstWires->{$wire}->{"inst"};
	   $auto_inst->{"$inst"}->{"$wire"} = $AutoInstWires->{$wire}->{"width"};
       $sig_length = length($wire) if (length($wire) > $sig_length);
   }
   $sig_length +=3;

   for my $inst (sort(keys(%$auto_inst))) {
     print  "// ------ wires of Instance: $inst ------\n" ;
     my $cur_inst = $auto_inst->{$inst};
     for my $sig_name (sort(keys(%$cur_inst))) {
         next if ($sig_name eq ""); ### FIXME: uknown "" key exists
         if ( (exists($AutoWires->{$sig_name}->{"exists"})) or (exists($AutoRegs->{$sig_name}->{"exists"})) ) {
		     next;
		 } else {
             my $width = $cur_inst->{"$sig_name"};
             if ( $width eq "1" ) {
                     $width = "";
             } elsif ( $width =~ /:/) {
                 $width = "[${width}]";
		     }else {
                 $width = "[${width}:0]";
             }
             my $line_pt = sprintf("wire %-12s %-${sig_length}s", $width, $sig_name);
             print "$line_pt;\n";
        }
     }
   }
}
#============================================================================================================#


#============================================================================================================#
#------ Instance args Handler ------#
#============================================================================================================#
sub InstanceParser {
  my $SubName = "InstanceParser";
  my($eline) = shift;
  my(@eperl_array) = ();
  my($eperl_script)= "";
  my $ep_done = 0;

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
      } elsif ($_ =~ /^\s*&?Connect \s*(.*)\s*;/) {
		 my $call_arg = $1; 
		 #$call_arg =~ s/\$(\d+)/\${$1}/g; 
         $eline = "&Connect(\"$call_arg\");\n";
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
         &HDLGenInfo($SubName," --- Instance Connection Done @ £º $exa_line \n") if ($CODEGEN_DEBUG_MODE);
	     last;
      }
	  $eperl_script .= "$eline";
      push @eperl_array, "$_";  
  }
  &HDLGenInfo($SubName," ---  Instance Get£º $eperl_script \n") if ($CODEGEN_DEBUG_MODE);
  return($eperl_script,$ep_done, @eperl_array);
}
#============================================================================================================#

#============================================================================================================#
#------ Module Instance Handler ------#
#============================================================================================================#
#--- &Instance module_name u_mod_int;
#--- &Instance module_name #( .parameter_name(para_value), .parameter_name(para_value)) inst_name;
#--- &Instance module_name 
#---     #( .parameter_name(para_value), 
#---        .parameter_name(para_value)
#---        ) 
#---      inst_name;
sub Instance {
  my($inst_line) = shift;
  my $mod_name = "";
  my $mod_para = "";
  my $mod_inst = "";
  my $ipx_file = "";
  my $SubName = "Instance";

  if ( $inst_line =~ /\n/ ) { ### multi-line
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
  }
  $mod_inst = "u_$mod_name" if ($mod_inst eq ""); 

  $CurInst = $mod_inst;
  &HDLGenInfo($SubName," --- mod_name==$mod_name, mod_parm==$mod_parm, CurInst==$CurInst \n") if ($CODEGEN_DEBUG_MODE);
  if ($ipx_file ne "") {
     $mod_name=&ParseInstIPX($mod_inst,$mod_parm,$ipx_file);
     $mod_name .= "\n" if ($mod_parm ne "");
     $mod_parm .= "\n" if ($mod_parm ne "");
  } else {
     &ParseInstVlg($mod_inst,$mod_parm,$mod_name);
  }
  $HDLGen_Top->{"$CurInst"}->{"connect_list"}=0;
  push @VOUT, "$mod_name $mod_parm $mod_inst (\n";

}
#============================================================================================================#

#============================================================================================================#
#------ finf Verilog/SV source file in search paths ------#
#============================================================================================================#
sub WantVlg {
    my($VlgName)=$_[0];
    my $return_file="";
    File::Find::find( { wanted => sub {
			  my $vlg_file = $File::Find::name;
                          if ( $vlg_file  =~ /$VlgName(.v|.sv)$/ ) {
			     $return_file=$vlg_file; 
                             return;
                          }
                          }} , @SRC_PATH);
    return($return_file);
}

#============================================================================================================#
#------ find file in search paths ------#
#============================================================================================================#
sub WantFile {
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
       &HDLGenErr("WantFile"," --- can NOT find src file of ($FName) in all src paths!\n");
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
	&HDLGenInfo($SubName, " --- mod_inst=$mod_inst, mod_parm=$mod_parm, mod_name=$mod_name\n") if ($CODEGEN_DEBUG_MODE);

    $HDLGen_Top->{"$mod_inst"}->{"module"}="$mod_name";
    $HDLGen_Top->{"$mod_inst"}->{"parameter"}="$mod_parm";

    my($in_vlg)="";
    $in_vlg = &WantVlg($mod_name); 
    if ( $in_vlg eq "" ) {
	   &HDLGenErr($SubName,"--- cannot find Verilog module file of $mod_name.v in @SRC_PATH\n");
	   die;
    }
    open(VLG_IN, "<$in_vlg") or die " !!! (&ParseInstVlg): Verilog/SV source file ($in_vlg.v/sv) cannot be open !!! \n";
    
    my $module_end   = "0";
    my $module_start = "0";
    while(<VLG_IN>) {
        chomp($_);
		if ( ($_ =~ /^\s*\/\//) or !($_ =~ /\S/) ) {
            next ;
		}
	    if ( $_ =~ /module \s*${mod_name}/) {
	       $module_start = "1";
	    } elsif ( ($_ =~/\);/) && ($module_start eq "1") ) {
	        $module_end = "1";
	        &HDLGenInfo($SubName, " --- found ); on cur line:$_") if ($CODEGEN_DEBUG_MODE);
	        last if (exists $HDLGen_Top->{"$mod_inst"}->{"input"}); 
        } elsif ( ($_ =~ /^\s*always/) or ($_ =~ /^s*assign/) ) { 
	        last; 
	    } elsif ($_ =~ /endmodule/ ) {
	        $module_end = "2";
	        last;
	    }

	    if ($_ =~ /^\s*,?input/) {
	       &HDLGenInfo($SubName, " --- find input line as: $_") if ($CODEGEN_DEBUG_MODE);
	       my($i_sig,$p_width)=&ParsePorts("$_");
		   if ($i_sig =~ /,/) {
	              my @p_array = split(",",$i_sig);
	              foreach my $pp (@p_array) {
	                  $HDLGen_Top->{"$mod_inst"}->{"input"}->{"$pp"}->{"width"}="$p_width";
	              }
               } else {
	              $HDLGen_Top->{"$mod_inst"}->{"input"}->{"$i_sig"}->{"width"}="$p_width";
               }
        } elsif ($_ =~ /^\s*,?output/) {
	       &HDLGenInfo($SubName, " --- find output line as: $_") if ($CODEGEN_DEBUG_MODE);
	       my($o_sig,$p_width)=&ParsePorts("$_");
	       $HDLGen_Top->{"$mod_inst"}->{"output"}->{"$o_sig"}->{"width"}="$p_width";
	    }
     } ### end of while VLG_IN
     close(VLG_IN);
}
#============================================================================================================#
	       
#============================================================================================================#
#------ Pasre Verilog source file and get all inputs & outputs------#
#============================================================================================================#
###&ParseInstIPX($mod_inst,$mod_parm,$mod_name);
sub ParseInstIPX{
    my($SubName)="ParseInstIPX";
    my($mod_inst)=shift;
	chomp($mod_inst);
    my($mod_parm)=shift;
    my($ipx_file)=shift;
	my($mod_name)=$ipx_file;
	&HDLGenInfo($SubName, " --- mod_inst=$mod_inst, mod_parm=$mod_parm, ipx_file=$ipx_file\n") if ($CODEGEN_DEBUG_MODE);


	$ipx_file = &WantFile($ipx_file);
    my $IP_XACT = &ReadXML($ipx_file);
	$mod_name = $IP_XACT->{"name"};

    if ($debug) {
        open(XXML,">.$ipx_file.hash");
        print XXML Dumper($IP_XACT);
        close(XXML);
    }

	my($I) = $IP_XACT->{"busInterfaces"}->{"busInterface"};
    foreach my $intf (keys(%$I)) {
        my $intf_hash = ();
        my @P = $I->{$intf}->{portMaps}->{portMap};
        foreach $pp (@P) {
            foreach $ppp (@$pp) {
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
        &AddInterface($intf, $intf_hash);
    }

    my($P) = $IP_XACT->{"model"}->{"ports"}->{"port"};
	foreach my $port (keys(%$P)) {
		my $port_hash = $P->{"$port"}->{"wire"};
		my $p_width = 0;
		if (exists($port_hash->{vector})) {
		   my $left  = $port_hash->{vector}->{left}; 
		   my $right = $port_hash->{vector}->{right}; 
		   ### for special cases
		   if (exists($left->{"expression"})) {
		   	$left = $left->{"expression"};
		   }
		   if (exists($right->{"expression"})) {
		   	$right = $right->{"expression"};
		   }
           $p_width = $left - $right + 1;
	   } else {
		   $p_width = "1";
	   }
		if ($port_hash->{"direction"} =~ /in/) {
	       $HDLGen_Top->{"$mod_inst"}->{"input"}->{"$port"}->{"width"}="$p_width";
	   } elsif ($port_hash->{"direction"} =~ /out/) {
	       $HDLGen_Top->{"$mod_inst"}->{"output"}->{"$port"}->{"width"}="$p_width";
	   }
	}

    $HDLGen_Top->{"$mod_inst"}->{"module"}="$mod_name";
    $HDLGen_Top->{"$mod_inst"}->{"parameter"}="$mod_parm";
	return($mod_name);
}
#============================================================================================================#

#============================================================================================================#
#------ Module Instance Handler ------#
#============================================================================================================#
#--- &Connect  -final -up <-interface|input|output> AHB3 \${1}_suffix; --- final==final conn can't be overrided
#--- &ConnectDone --- unneccesary 
sub Connect {
  my($SubName)="Connect";
  my ($call_arg) = join (" ", @_);
  &HDLGenInfo($SubName,"--- \$call args==$call_arg\n") if ($CODEGEN_DEBUG_MODE);

  my ($type) = ""; 
  my ($srch) = "";
  my ($rplc) = "";
  my ($rule) = "";
  my ($intf) = "";
  my ($final) = "0"; 
  my ($up) = "0"; 
  if ($call_arg =~ s/-final//) {
     $final = 1;
  }
  if ($call_arg =~ s/-up(case)?//) {
     $up = 2; 
  }
  if ($call_arg =~ s/-low//) {
     $up = 1; 
  }
  if ($call_arg =~ /-interface \s*(\w+) \s*(.*)\s*$/) {
      $type = "interface";
      $intf = $1;
      $rplc = $2;
      $srch = "/(.*)/";
  } elsif ( $call_arg =~ /(-input|-output|-inout)?\s*(\S*)\s+(\S+)\s*$/) {
      $type = $1;
      $srch = $2;
      $rplc = $3;
      $type =~ s/-// if ($type);
      $type = "port" if ($type eq ""); 
  } else {
      &HDLGenErr($SubName," --- syntax is wrong @: &Connect $call_arg\n");
      exit(1);
  }

  if ($srch =~ /^\w+$/ && $rplc =~ /^\w+$/) { 
    $rule = "exact";
  } elsif ($srch =~ /^\//) { 
    $rule = "s".$srch.$rplc."/";
  } else { 
    my $srch_new = '^'.$srch.'$' unless ($srch =~ s/^\/(.*?)\/$/$1/);
    $rule = "s/${srch_new}/${rplc}/";
  }

  my $conn_item = $HDLGen_Top->{"$CurInst"}->{"connect_list"} + 1;
  $HDLGen_Top->{"$CurInst"}->{"connect_list"}=$conn_item;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item} = {};
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{srch} = $srch;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{rplc} = $rplc;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{type} = $type;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{intf} = $intf;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{rule} = $rule;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{used} = 0;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{final} = $final;
  $HDLGen_Top->{"$CurInst"}->{connect}->{$conn_item}->{up} = $up;

}
#============================================================================================================#

#============================================================================================================#
#------ Call Connect by update Hash------#
#============================================================================================================#
sub ConnectDone {
  my($SubName)="ConnectDone";
  my(@AllPorts)=();
  my($C)=$HDLGen_Top->{"$CurInst"};
  my($type)="";
 
  foreach my $in_p (keys %{$HDLGen_Top->{"$CurInst"}->{"input"}}) {
	push @AllPorts, $in_p;
  }
  foreach my $out_p (keys %{$HDLGen_Top->{"$CurInst"}->{"output"}}) {
	push @AllPorts, $out_p;
  }
  foreach my $inout (keys %{$HDLGen_Top->{"$CurInst"}->{"inout"}}) {
	push @AllPorts, $inout;
  }

  foreach my $port (@AllPorts) {
      if (exists ($C->{"input"}->{$port}) ) {
          $type = "input";
      } elsif (exists ($C->{"output"}->{$port}) ) {
          $type = "output";
      } elsif (exists ($C->{"inout"}->{$port}) ) {
          $type = "inout";
      }

      my $all_conn = $C->{connect_list};
      if ($all_conn > "0") {
          foreach my $conn (1..$all_conn) {
                last if ( exists ($C->{"$type"}->{"$port"}->{"final"}) );

                my $conn_new=$port;
                &HDLGenInfo($SubName, " --- current connect_item == $conn\n") if ($CODEGEN_DEBUG_MODE);
                my $CC = $C->{"connect"}->{$conn};
                next if ( ($CC->{type} ne "port") && ($CC->{type} ne "interface") && ($CC->{type} ne "$type") );

                my $used = 0;
                if (exists $CC->{rule}) {
                  if ($CC->{rule} eq "exact") {
                    if ($CC->{srch} eq $port) {
                      $conn_new = $CC->{rplc}; 
                      $used = 1;
                    }
                  } else {
		            if ($CC->{type} eq "interface") {
                       my $intf_name = $CC->{intf};
		               my $intf_h = &GetIntf($intf_name); 
				       my $port_UC = uc($port);
			           if ( !(exists $intf_h->{$port}) and (!(exists $intf_h->{$port_UC})) ) {
					     next;
				       }
		            } 
            	    my $eval = "\$used = \$conn_new =~ $CC->{rule}";
            	    eval ($eval); # conn
            	    &HDLGenErr($SubName,"connection eval ($eval) failure: $@") if ($@);
                  }
                }
                &HDLGenInfo($SubName, " --- cur_port:$port, replaced by $conn_new\n") if ($CODEGEN_DEBUG_MODE);
                next unless ($used); 

		        if ( $CC->{"up"} eq "2") { 
		           $conn_new = uc($conn_new);
			    } elsif ( $CC->{"up"} eq "1") { 
		           $conn_new = lc($conn_new);
				}
				$conn_new =~ s/\s//;
                $C->{"$type"}->{"$port"}->{"connect"} = $conn_new;
                $C->{"$type"}->{"$port"}->{"final"} = "1" if ( $CC->{final} eq "1");
          }### end of foreach connect_list
      }### end of $all_conn 
  } ### end of foreach
  if ($debug) {
     open(INST_HASH,">.$CurInst.hash") or die "!!! Error: cannot create debug file of (.$CurrInst.hash) !!!\n";
     print INST_HASH Dumper($C);
     close(INST_HASH);
  }
  &PrintConnect();

}
#============================================================================================================#


#============================================================================================================#
#------ Real Print Connections ------#
#============================================================================================================#
sub PrintConnect {
  my($SubName)="PrintConnect";
  my($C)=$HDLGen_Top->{"$CurInst"};
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

  foreach my $port (sort(keys %{$C->{"input"}})) {
	  $port_length = length($port) if (length($port) > $port_length);
      my $conn = $port;
      if (exists $C->{"input"}->{$port}->{"connect"}) { 
          $conn = $C->{"input"}->{$port}->{"connect"};
      }
	  $conn_length = length($conn) if (length($conn) > $conn_length);
	  push(@clk_rst, $port) if ($port =~ /clk|clock|rst|reset/); 
  }
  foreach my $port (sort(keys %{$C->{"output"}})) {
	  $port_length = length($port) if (length($port) > $port_length);
      my $conn = $port;
      if (exists $C->{"output"}->{$port}->{"connect"}) { 
          $conn = $C->{"output"}->{$port}->{"connect"};
	  }
	  $conn_length = length($conn) if (length($conn) > $conn_length);
  }
  $port_length +=1;
  $conn_length +=8;

  foreach my $cr (sort(@clk_rst)) {
	  my $port = $cr;
	  my $conn = $C->{"input"}->{"$cr"}->{"connect"};
	  my $width= $C->{"input"}->{"$cr"}->{"width"};
	  delete($C->{"input"}->{"$port"});
	  $conn = "$cr" if ($conn eq "");
	  my $line_pt =	sprintf("%-${port_length}s%-${conn_length}s", $port, "($conn)");  
      if ($first_line) {
    	  push @VOUT,"    .$line_pt //|<-i\n";
      } else {
    	  push @VOUT,"   ,.$line_pt //|<-i\n";
      }
      delete($C->{"input"}->{"$port"});
      $first_line = 0;
	  if ( $AUTO_INST eq "" ) {
	     push @wire_array, "[$width], $conn";
	  } else {
		 $conn =~ s/\[.*\]//; 
		 if (exists($AutoInstWires->{"$conn"})) {
	        $AutoInstWires->{"$conn"}->{"inst"} .= " & $CurInst";
		 } else {
	        $AutoInstWires->{"$conn"}->{"inst"} = "$CurInst";
		 }
	     $AutoInstWires->{"$conn"}->{"width"} = "$width";
	  }
  }

  foreach my $port (sort(keys %{$C->{"input"}})) {
	  $port_length = length($port) if (length($port) > $port_length);
      my $conn = $port;
      my $width = $C->{"input"}->{$port}->{"width"};

      if (exists $C->{"input"}->{$port}->{"connect"}) { 
          $conn = $C->{"input"}->{$port}->{"connect"};
	  }

	  if ($width ne "1") {
		  if ($width =~ /:/) {
	          $conn .= "[${width}]" if ($conn !~ /:/);
	      } else {
			  $width--;
			  $width= "${width}:0";
	          $conn .= "[${width}]" if ($conn !~ /:/);
		  }
      }

	  $line_pt =	sprintf("%-${port_length}s%-${conn_length}s", $port, "($conn)");  
      if ($first_line) {
		  push @VOUT,"    .$line_pt //|<-i\n";
          $first_line = 0;
      } else {
		  push @VOUT,"   ,.$line_pt //|<-i\n";
      }
      
	  if ( $AUTO_INST eq "" ) { 
	     push @wire_array, "[$width], $conn";
	  } else {
		 $conn =~ s/\[.*\]//; 
		 if (exists($AutoInstWires->{"$conn"})) {
	        $AutoInstWires->{"$conn"}->{"inst"} .= " & $CurInst";
		 } else {
	        $AutoInstWires->{"$conn"}->{"inst"} = "$CurInst";
		 }
	     $AutoInstWires->{"$conn"}->{"width"} = "$width";
	  }

  }
  foreach my $port (sort(keys %{$C->{"output"}})) {
      my $conn = $port;
      if (exists $C->{"output"}->{$port}->{"connect"}) { 
          $conn = $C->{"output"}->{$port}->{"connect"};
      }

      my $width = $C->{"output"}->{$port}->{"width"};

	  if ($width ne "1") {
		  if ($width =~ /:/) {
	          $conn .= "[${width}]" if ($conn !~ /:/);
	      } else {
			  $width--;
			  $width= "${width}:0";
	          $conn .= "[${width}]" if ($conn !~ /:/);
		  }
      }

	  $line_pt =	sprintf("%-${port_length}s%-${conn_length}s", $port, "($conn)");  
      push @VOUT, "   ,.$line_pt //|>-o\n";

	  if ( $AUTO_INST eq "" ) {
	     push @wire_array, "[$width], $conn";
	  } else {
		 $conn =~ s/\[.*\]//; 
		 if (exists($AutoInstWires->{"$conn"})) {
	        $AutoInstWires->{"$conn"}->{"inst"} .= " & $CurInst";
		 } else {
	        $AutoInstWires->{"$conn"}->{"inst"} = "$CurInst";
		 }
	     $AutoInstWires->{"$conn"}->{"width"} = "$width";
	  }

  }
  push @VOUT, "   );\n\n";

  if ( $AUTO_INST eq "" ) { 
     push @VOUT, "// ---------------------------------------------------------------------------------------\n";
     push @VOUT, "// --- Below Code is for Instance signal define, you need to manually copy/move/modify ---\n";
     push @VOUT, "// --- Recommended way is to use &AutoInstWire at correct place to list these wires    ---\n";
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
sub PrintRTLHdr {
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!                                                       !!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!    DO NOT EDIT - GENERATED BY HDLGEN - DO NOT EDIT    !!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!                                                       !!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
}

#============================================================================================================#
sub PrintVOUT {
	select(V_OUT);
	&PrintRTLHdr() ;
	foreach my $line (@VOUT) {
		if ($vout_autowirereg eq "1" ) {
			if ($line eq  "//|: &AutoDef;\n") {
			   $vout_autowirereg = 0;
		       print("$line");
  	           print "//| ================================================================================\n";
  	           print "//| ============ Below Wires & Regs are auto-generated by &AutoDef =================\n";
  	           print "//| ============ these definition may be not perfect or correct    =================\n";
  	           print "//| ============ yout may need to manually update/correct          =================\n";
  	           print "//| ================================================================================\n";
               &PrintAutoSigs();
  	           print "//| ============================= End of Auto Wires/Regs ===========================\n";
  	           print "//| ================================================================================\n\n";
		   } else {
		       print("$line");
		   }
	    } elsif ($vout_autoinstwire eq "1") {
			if ($line eq  "//|: &AutoInstWire;\n") { ### Question: should "eq" quick than "=~"?
			   $vout_autoinstwire = 0;
		       print("$line");
  	           print "//| ====================================================================================\n";
  	           print "//| =========== Below Wires are for all &Instance modules by &AutoInstWire =============\n";
			   print "//| =========== These definition may be not correct(for reg signals)       =============\n";
  	           print "//| =========== You may need to manually update/correct                    =============\n";

               &PrintAutoInstWires();
  	           print "//| ========================= End of Instance Wires/Regs ===============================\n";
  	           print "//| ====================================================================================\n\n";
		     } else {
		         print("$line");
		     }
	     } else {
		      print("$line");
		 }
    }
}


sub Version {
	print BOLD BLUE <<EOF;

         *********************************************
         ****** Current HDLGen Version is V0.91 ******
         *********************************************
EOF

}
#============================================================================================================#
### End of Package ####
#============================================================================================================#
1;

