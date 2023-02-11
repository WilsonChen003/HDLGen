#!/usr/bin/env perl

#============================================================================================================#
#============================================================================================================#
#========================================= Public Packages ==================================================#
#============================================================================================================#
#============================================================================================================#
use strict;
use File::Basename;
use Getopt::Long qw(GetOptions);
use Cwd qw/abs_path/;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
#============================================================================================================#
#========================================= End of Public Packages ===========================================#
#============================================================================================================#

### Add Script Dir as include paths, most for all PlugIn APIs ###
use lib abs_path(dirname(__FILE__)) . '/plugins';

our $HDLGEN_ROOT = $ENV{"HDLGEN_ROOT"};
if ($HDLGEN_ROOT eq "") {
	print STDOUT BOLD RED " !!! ERROR !!! : HDLGEN_ROOT is not defined!\n\n";
	exit(1);
}

#============================================================================================================#
#========================= Inhouse Packages for internal developed functions ================================#
#============================================================================================================#
#require "HDLGen.pm";
use HDLGen;
#============================================================================================================#
#================================ End of Inhouse Packages ===================================================#
#============================================================================================================#

our($input_src, $output_vlg, $input_flist,$verbose, $debug, $clean, $usage) = ("", "", "", "", "", "", "");
GetOptions(
    'verbose'     => \$verbose,
    'input=s'     => \$input_src,
    'output=s'    => \$output_vlg,
    'f=s'         => \$input_flist,
    'debug'       => \$debug,
    'clean'       => \$clean,
    'usage'       => \$usage,
);

if ($verbose ) {
   print("--- Verbose Debug Infomation is turned on ---\n");
}

our $HDLGEN_DEBUG_MODE = 0;
$HDLGEN_DEBUG_MODE = "1" if ($verbose && $debug);


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
#

if ($usage) {
	&Usage();
} elsif ($input_flist eq "") {
	if ( $input_src eq "" ) {
		&Usage();
	} else {
	    &HDLGen::ProcessOneFile($input_src, $output_vlg);
	}
} else {
    open(LIST_IN, "<$input_flist") or die "!!! Error: can't find input list file of ($input_flist) \n\n";
	while (<LIST_IN>) {
		chomp();
		&HDLGen::ProcessOneFile($input_src, "");
	}
}


sub Version {
	print BOLD BLUE <<EOF;

         *********************************************
         ****** Current HDLGen Version is V1.13 ******
         *********************************************
EOF

}

sub Usage {
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
#============================================================================================================#
#============================================================================================================#
#============================================ End of Main Function ==========================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
