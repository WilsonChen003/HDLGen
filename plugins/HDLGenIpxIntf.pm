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


use strict;
use XML::Simple;
use XML::SAX::Expat;
use JSON;
use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);
use Data::Dumper;
use File::Basename;
use Spreadsheet::ParseExcel;

our %Our_Intf = ();
my  $MyCorp    = "MyCorp";

###------------------------------------------------------------------------------------------
###: define ABMA hash for Our_Intf connection
###------------------------------------------------------------------------------------------
### <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
### NOTE: all AMBA bus default is slave mode £¡£¡£¡
### >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$Our_Intf{"APB3"} = {
       'PCLK'   => "input:1",
       'PRESETN'=> "input:1",
       'PSEL'  => "input:1", ### new
       'PENABLE'=> "input:1",
       'PADDR'  => "input:32",
       'PWRITE' => "input:1",
       'PWDATA' => "input:32",
       'PREADY' => "output:1", ### new
       'PSLVERR'=> "output:1", ### new
       'PRDATA' => "output:32"
   };

$Our_Intf{"APB4"} = {
       'PCLK'   => "input:1",
       'PRESETN'=> "input:1",
       'PSEL'   => "input:1",
       'PENABLE'=> "input:1",
       'PSTRB'  => "input:4", ### new
       'PADDR'  => "input:32",
       'PWRITE' => "input:1",
       'PWDATA' => "input:32",
       'PREADY' => "output:1",
       'PSLVERR'=> "output:1",
       'PRDATA' => "output:32",
       'PPROT'  => "input:3" ### new
   };

 ### list AHB bus signals
$Our_Intf{"AHB2"} = {
       "HCLK"    =>"input:1",
       "HRESETn" => "input:1",
       "HSEL"    => "input:1",
       "HTRANS"  => "input:2",
       "HADDR"   => "input:32",
       "HWRITE"  => "input:1",
       "HWDATA"  => "input:32",
       "HSIZE"   => "input:3",
       "HBURST"  => "input:3",
       "HPROT"   => "input:4",
       "HREADY"  => "output:1",
       "HRDATA"  => "output:32",
       "HRESP"   => "output:2",
       "HLOCK"   => "output:1",
       "HMASTLOCK"   => "input:1",
       "HMASTER" => "input:4",
       "HGRANT"  => "input:1",
       "HSPLIT"  => "input:16"
  };

$Our_Intf{"AHB_Lite"} = {
       "HCLK"    =>"input:1",
       "HRESETn" => "input:1",
       "HSEL"    => "input:1",
       "HTRANS"  => "input:2",
       "HADDR"   => "input:32",
       "HWRITE"  => "input:1",
       "HWDATA"  => "input:32",
       "HSIZE"   => "input:3",
       "HBURST"  => "input:3",
       "HPROT"   => "input:4",
	   #       "HREADY"  => "output:1",
       "HREADYOUT"  => "output:1",
       "HRDATA"  => "output:32",
       "HRESP"   => "output:1",
       "HMASTLOCK"   => "output:1"   ### is it really necessary???
};

$Our_Intf{"AHB5"} = {
       "HCLK"    =>"input:1",
       "HRESETn" => "input:1",
       "HSEL"    => "input:1",
       "HTRANS"  => "input:2",
       "HADDR"   => "input:32",
       "HWRITE"  => "input:1",
       "HWDATA"  => "input:32",
       "HSIZE"   => "input:3",
       "HBURST"  => "input:3",
       "HPROT"   => "input:4",
       "HREADY"  => "output:1",
       "HREADYOUT"  => "output:1",
       "HRDATA"  => "output:32",
       "HRESP"   => "output:2",
       "HLOCK"   => "output:1",
       "HMASTLOCK"   => "output:1",
       "HMASTER" => "input:4",
       "HGRANT"  => "input:1",
	   #"HSPLIT"  => "input:16" ### removed
       "HEXOKAY" => "output:1",
       "HNONSEC" => "input:1",
  };

$Our_Intf{"AXI3"} = {
       "ACLK"    => "input:1",
       "ARESETn" => "input:1",
       "AWVALID" => "input:1",
       "AWREADY" => "output:1",
       "AWADDR"  => "input:32",
       "AWSIZE"  => "input:3",
       "AWBURST" => "input:4",
       "AWLEN"   => "input:4",
       "AWCACHE" => "nput:4",
       "AWLOCK"  => "input:2",
       "AWPROT"  => "input:3",
       "AWID"    => "input:6",
       "WVALID"  => "input:1",
       "WDATA"   => "input:64",
       "WID"     => "input:6", 
       "WLAST"   => "input:1",
       "WSTRB"   => "input:4",
       "WREADY"  => "output:1",
       "ARVALID" => "input:1",
       "ARREADY" => "output:1",
       "ARADDR"  => "input:32",
       "ARBURST" => "input:4",
       "ARCACHE" => "input:4",
       "ARID"    => "input:6",
       "ARLEN"   => "input:4",
       "ARLOCK"  => "input:2",
       "ARPROT"  => "input:3",
       "ARSIZE"  => "input:3",
       "RVALID"  => "output:1",
       "RDATA"   => "output:64",
       "RID"     => "output:4",
       "RLAST"   => "output:1",
       "RREADY"  => "input:1",
       "BVALID"  => "output:1",
       "BREADY"  => "input:1",
       "BID"     => "output:4",
       "BRESP"   => "output:2",
       "RRESP"   => "output:2",

       "CACTIVE" => "input",
       "CSYSACK" => "output",
       "CSYSREQ" => "input"
}; ### end of Our_Intf hash

$Our_Intf{"AXI4"} = {
       "ACLK"    => "input:1",
       "ARESETn" => "input:1",
       "AWVALID" => "input:1",
       "AWREADY" => "output:1",
       "AWADDR"  => "input:32",
       "AWSIZE"  => "input:3",
       "AWBURST" => "input:4",
       "AWLEN"   => "input:8",  ### from 4 -> 8
       "AWCACHE" => "nput:4",
       "AWLOCK"  => "input:1",  ### from 2 -> 1
       "AWPROT"  => "input:3",
       "AWID"    => "input:6",
       "WVALID"  => "input:1",
       "WDATA"   => "input:64",
	   #"WID"     => "input:6",   ### removed
       "WLAST"   => "input:1",
       "WSTRB"   => "input:4",
       "WREADY"  => "output:1",
       "ARVALID" => "input:1",
       "ARREADY" => "output:1",
       "ARADDR"  => "input:32",
       "ARBURST" => "input:4",
       "ARCACHE" => "input:4",
       "ARID"    => "input:6",
       "ARLEN"   => "input:8",  ### from 4 -> 8
       "ARLOCK"  => "input:1",  ### from 2 -> 1
       "ARPROT"  => "input:3",
       "ARSIZE"  => "input:3",
       "RVALID"  => "output:1",
       "RDATA"   => "output:64",
       "RID"     => "output:4",
       "RLAST"   => "output:1",
       "RREADY"  => "input:1",
       "BVALID"  => "output:1",
       "BREADY"  => "input:1",
       "BID"     => "output:4",
       "BRESP"   => "output:2",
       "RRESP"   => "output:2",
       "AWQOS"   => "input:4",  ### new
       "ARQOS"   => "input:4",  ### new
       "AWREGION"   => "input:4",  ### new
       "ARREGION"   => "input:4",  ### new
	   ### rarely used signals
       "AWUSER"   => "input:4",  ### new
       "ARUSER"   => "input:4",  ### new
       "WUSER"   => "input:4",  ### new
       "RUSER"   => "input:4",  ### new
       "BUSER"   => "output:4",  ### new
       ### special signals, need manual connection
       "CACTIVE" => "input",
       "CSYSACK" => "output",
       "CSYSREQ" => "input"
}; ### end of Our_Intf hash

$Our_Intf{"AXI_Lite"} = {
       "ACLK" => "input:1",
       "ARESETn" => "input:1",
       "AWVALID" => "input:1",
       "AWREADY" => "output:1",
       "AWADDR"  => "input:32",
       "AWPROT"  => "input:3",
	   #"AWSIZE"  => "input:3",   ###  removed
       #"AWBURST" => "input:4",
       #"AWLEN"   => "input:4",
       #"AWCACHE" => "nput:4",
       #"AWLOCK"  => "input:2",
	   #"AWID"    => "input:6",
       "WVALID"  => "input:1",
       "WDATA"   => "input:64",
       "WSTRB"   => "input:4",
       "WREADY"  => "output:1",
	   #"WID"     => "input:6",    ### removed
       #"WLAST"   => "input:1",
       "ARVALID" => "input:1",
       "ARREADY" => "output:1",
       "ARADDR"  => "input:32",
       "ARPROT"  => "input:3",
	   #"ARBURST" => "input:4",   ### removed
	   #"ARCACHE" => "input:4",
	   #"ARID"    => "input:6",
	   #"ARLEN"   => "input:4",
	   #"ARLOCK"  => "input:2",
	   #"ARSIZE"  => "input:3",
       "RVALID"  => "output:1",
       "RREADY"  => "input:1",
       "RDATA"   => "output:64",
       "RRESP"   => "output:2",
	   #"RID"     => "output:4",   ### removed
       #"RLAST"   => "output:1",
       "BVALID"  => "output:1",
       "BREADY"  => "input:1",
	   #"BID"     => "output:4", ### remove3d
       "BRESP"   => "output:2"

}; ### end of Our_Intf hash

$Our_Intf{"DTI"} = {
       '_valid' => "input:1",
       '_ready' => "output:1",
       '_data'  => "input:32" 
   };

###------------------------------------------------------------------------------------------
### Print an Our_Intf's all ports ####
###------------------------------------------------------------------------------------------
# &PrintIntfPort("-intf APB -awd 18 -dwd 32 -pre Test_ -l -port -end ,");
sub PrintIntfPort {
  my($SubName)="PrintIntfPort";
  my $args = shift;
  @ARGV = shellwords($args);
  my $pr_out = "";
  
  #================================
  # OPTIONS
  #================================
  my $intf_name = "";
  my $master = "";
  my $slave = "";
  my $awd = "";
  my $dwd = "";
  my $prefix = "";
  my $suffix = "";
  my $upcase = "";
  my $lowcase= "";
  my $wire= "";
  my $end  = ";"; 
  my $port = ""; 
  GetOptions (
              'intf=s'    => \$intf_name,
              'awd=s'     => \$awd,
              'dwd=s'     => \$dwd,
              'prefix=s'  => \$prefix,
              'suffix=s'  => \$suffix,
              'upcase'    => \$upcase,
              'lowcase'   => \$lowcase,
              'end=s'     => \$end,
              'wire'      => \$wire,
              'port'      => \$port,
              'master'    => \$master,
              'slave'     => \$slave,
              )  or die "Unrecognized options @ARGV";

  my $uplow = 0;
  $uplow = 1 if ($lowcase ne "");
  $uplow = 2 if ($upcase ne "");
  my $portwirereg = 0;
  $portwirereg = 1 if ($wire ne "");
  $portwirereg = 2 if ( ($wire eq "") && ($port eq "") );
  $master = 1 if ($master ne "");
  $master = 0 if ($slave ne ""); ### NOTE: Slave will override Master !

  my $chg_args = "-master $master -portwirereg $portwirereg -uplow $uplow";
  $chg_args .= " -prefix $prefix" if ($prefix ne "");
  $chg_args .= " -suffix $suffix" if ($suffix ne "");
  $chg_args .= " -awd $awd" if ($awd ne "");
  $chg_args .= " -dwd $dwd" if ($dwd ne "");

  ### here can NOT use $Our_Intf->{"$intf"} !!!
  if (!exists($Our_Intf{"$intf_name"})) {
      &HDLGenErr($SubName, "!!! NO such interface of $intf_name, pls double check !!!\n");
	  return;
  }
	  
  my($INTF)=$Our_Intf{"$intf_name"};

  my($p_io, $p_w, $port);

  my $p_w = "0";
  foreach $port (keys(%$INTF)) {
      my $line = $INTF->{$port};
	  $line =~ s/\s//g;
      my @line_a = split(":", $line);
      $p_io = $line_a[0];
	  if (scalar(@line_a) > 2) {
         $p_w  = "$line_a[1]".":$line_a[2]";
      } else {
         $p_w  = $line_a[1];
	  }

	  $chg_args .= " -sig $port -sig_io $p_io -sig_wd $p_w"; 
      ($p_io, $p_w, $port)=&ChangeSigName("$chg_args");

   	  my $pr_line = sprintf("%-8s %-16s %-16s%s", $p_io, $p_w, $port,$end);  
	  $pr_out .= "$pr_line\n"; 
  }
  push @HDLGen::VOUT, "$pr_out";

}

###------------------------------------------------------------------------------------------
### Print standard AMBA bus Our_Intf signals ####
###------------------------------------------------------------------------------------------
# &PrintAmbaBus("-type APB -awd 18 -dwd 32 -pre Test_ -l -port -end ,");
sub PrintAmbaBus {
   my($SubName)="PrintAmbaBus";
   my $args = shift;
   @ARGV = shellwords($args);
   my $pr_out = "";
   
   #================================
   # OPTIONS
   #================================
   my $type = "AXI";
   my $master = "";
   my $slave = "";
   my $awd = "";
   my $dwd = "";
   my $prefix = "";
   my $suffix = "";
   my $upcase = "";
   my $lowcase= "";
   my $wire= "";
   my $end  = ";"; ### default is signal so end with ";"
   my $port = ""; ### default is signal(reg), otherwise is Port
   GetOptions (
              'type=s'    => \$type,
              'master'    => \$master, ### default is slave
              'slave'     => \$slave, ### default is slave
              'awd=s'     => \$awd,
              'dwd=s'     => \$dwd,
              'prefix=s'  => \$prefix,
              'suffix=s'  => \$suffix,
              'upcase'    => \$upcase,
              'lowcase'   => \$lowcase,
              'end=s'     => \$end,
              'wire'      => \$wire,
              'port'      => \$port,
              )  or die "Unrecognized options @ARGV";
    
	
  my $uplow = 0;
  $uplow = 1 if ($lowcase ne "");
  $uplow = 2 if ($upcase ne "");
  my $portwirereg = 0;
  $portwirereg = 1 if ($wire ne "");
  $portwirereg = 2 if ( ($wire eq "") && ($port eq "") );
  $master = 1 if ($master ne "");
  $master = 0 if ($slave ne ""); 
  $master = 0 if ($master eq ""); 

  my $chg_args = "-master $master -portwirereg $portwirereg -uplow $uplow";
  $chg_args .= " -prefix $prefix" if ($prefix ne "");
  $chg_args .= " -suffix $suffix" if ($suffix ne "");
  $chg_args .= " -awd $awd" if ($awd ne "");
  $chg_args .= " -dwd $dwd" if ($dwd ne "");

  my $INTF;
  $INTF=$Our_Intf{"$type"};

  my($sig_def, $p_w, $p_io, $sig);

  foreach $sig (keys(%$INTF)) {
      my $line = $INTF->{$sig};
	  $line =~ s/\s//g;
      my @line_a = split(":", $line);
      $p_io = $line_a[0];
      $p_w  = $line_a[1];

	  $chg_args .= " -sig $sig -sig_io $p_io -sig_wd $p_w"; 
      ($sig_def, $p_w, $sig)=&ChangeSigName("$chg_args");

	  #write;
   	  my $pr_line = sprintf("%-8s %-16s %-16s%s", $sig_def, $p_w, $sig, $end);  
	  $pr_out .= "$pr_line\n"; 
  }
  #$~ = $CUR_OUT;
  push @HDLGen::VOUT, "$pr_out";

}


sub ChangeSigName {
   my($SubName)="PrintAmbaBus";
   my $args = shift;
   @ARGV = shellwords($args);

   my $sig = "";
   my $master = "";
   my $sig_io = "";
   my $sig_wd = "";
   my $awd = "";
   my $dwd = "";
   my $prefix = "";
   my $suffix = "";
   my $uplow = "";
   my $portwirereg = ""; 
   GetOptions (
              'sig=s'     => \$sig,
              'sig_io=s'  => \$sig_io,
              'sig_wd=s'  => \$sig_wd,
              'master=s'  => \$master, 
              'awd=s'     => \$awd,
              'dwd=s'     => \$dwd,
              'prefix=s'  => \$prefix,
              'suffix=s'  => \$suffix,
              'uplow=s'   => \$uplow,
              'portwirereg=s'   => \$portwirereg,
              )  or die "Unrecognized options @ARGV";


	  if ($sig =~ /DATA/i) {
		  $sig_wd = $dwd if ($dwd ne "");
	  } elsif ($sig =~ /ADDR/i) {
		  $sig_wd = $awd if ($awd ne "");
	  }

	  if ( ($sig !~ /CLK/i) and ($sig !~ /RESET/i) ) {
         if ($master eq "1") {  ### not slave
	       if ($sig_io =~ /input/) {
	     	  $sig_io =~ s/input/output/;
	       } elsif ($sig_io =~ /output/) {
	           $sig_io =~ s/output/input/;
	       }
	     }
	  }

	  $sig = "$prefix"."$sig" if ($prefix ne "");
	  $sig = "$sig"."$suffix" if ($suffix ne "");
	  if ($uplow eq "1") {
	     $sig = lc($sig);
	  } elsif ($uplow eq "2") {
	     $sig = uc($sig);
      }

      if ($sig_wd =~ /:/) {
          $sig_wd = "[$sig_wd]";
      } else {
		  if ($sig_wd ne "1") {
			  $sig_wd--;
              $sig_wd = "[$sig_wd:0]";
	      } else {
			  $sig_wd = " ";
		  }
      }

	  if ($portwirereg eq "1") {
		  $sig_io = "wire";
	  } elsif ($portwirereg eq "2") {
		  $sig_io = "reg";
	  }

	  return($sig_io,$sig_wd,$sig);
}

###------------------------------------------------------------------------------------------
### Read IPXACT XML and return a big hash ####
###------------------------------------------------------------------------------------------
sub ReadIPX {
  my($SubName)="ReadIpXact";
  my($ipx_in) = $_[0];
  my($ipx_v) = "ipxact:";
  my($IP_XACT)=();
  my($temp_xml)=basename($ipx_in);
  $temp_xml = ".$temp_xml".".modified";

  if ( -e $ipx_in ) {
     open(IPX_IN,"<$ipx_in");
     open(XML_TMP,">$temp_xml");
  } else {
	  &HDLGenErr("ReadIPX"," IPXACT file $ipx_in doesn't exist");
	  exit(1); 
  }

  while (<IPX_IN>) {
      if ($_ =~ /^\s*<(\w+:)component /) {
	     $ipx_v = $1;
      }
      $_ =~ s/$ipx_v//g;
      print XML_TMP "$_";
  }
  close(IPX_IN);
  close(XML_TMP);
  $IP_XACT = XMLin("./$temp_xml");
  system("rm -rf ./$temp_xml");

  if ($main::debug) {
      open(XXML,">.$ipx_in.hash");
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
      &AddInterface($intf, $intf_hash);
  }
}

###------------------------------------------------------------------------------------------
### Read IPXACT XML and return a big hash ####
###------------------------------------------------------------------------------------------
sub ReadXML {
  my($SubName)="ReadXML";
  my($ipx_in) = $_[0];
  my($ipx_v) = "ipxact:";
  my($IP_XACT)=();
  my($temp_xml)=basename($ipx_in);
  $temp_xml = ".$temp_xml".".modified";

  if (-e $ipx_in) {
	  open(IPX_IN,"<$ipx_in");
      open(XML_TMP,">$temp_xml");
  } else {
	  &HDLGenErr("ReadXML"," IPXACT file $ipx_in doesn't exist");
	  exit(1);
  }

  while (<IPX_IN>) {
      if ($_ =~ /^\s*<(\w+:)component /) {
	      $ipx_v = $1;
      }
      $_ =~ s/$ipx_v//g;
      print XML_TMP "$_";
  }
  close(IPX_IN);
  close(XML_TMP);
  $IP_XACT = XMLin("./$temp_xml");
  system("rm -rf ./$temp_xml");

  if ($main::debug) {
      open(XXML,">.$ipx_in.hash");
      print XXML Dumper($IP_XACT);
      close(XXML);
  }

  return($IP_XACT);
}

###------------------------------------------------------------------------------------------
###------ get Interface hash------#
###------------------------------------------------------------------------------------------
sub GetIntf {
  my($SubName)="GetIntf";
  my $i_name = "$_[0]";
 
  if (exists $Our_Intf{"$i_name"}) {
      print STDOUT "find Our_Intf hash as: $Our_Intf{$i_name}\n" if ($main::HDLGEN_DEBUG_MODE);
      return($Our_Intf{"$i_name"});
  } else {
      &HDLGenErr($SubName, "!!! no Our_Intf hash of \$Our_Intf{$i_name} !!!\n") if ($main::HDLGEN_DEBUG_MODE);
      return("NULL");
      exit;
  }

}

###------------------------------------------------------------------------------------------
###------ get Interface hash------#
###------------------------------------------------------------------------------------------
sub ShowIntf {
  my($SubName)="GetIntf";
  my $i_name = "$_[0]";
 
  if (exists $Our_Intf{"$i_name"}) {
	  open(INTF,">./$i_name.intf");
      print STDOUT BOLD YELLOW "   --- Show hash of \"$i_name\"---\n";# if ($main::HDLGEN_DEBUG_MODE);
	  print INTF "#--- Show interface of \"$i_name\" ---#\n";
	  print INTF "  \"$i_name\" = (\n";
	  my $i_hash = $Our_Intf{"$i_name"};
	  foreach my $i_sig (keys(%$i_hash)) {
			  print INTF "      \"$i_sig\" => \"$i_hash->{$i_sig}\",\n";
	  }
	  print INTF "  );\n";
	  close(INTF);
  } else {
      &HDLGenErr($SubName, "!!! no Our_Intf hash of \$Our_Intf{$i_name} !!!\n");# if ($main::HDLGEN_DEBUG_MODE);
      return("NULL");
      exit;
  }

}

###------------------------------------------------------------------------------------------
### Add Interface to $Our_Intf hash ####
###------------------------------------------------------------------------------------------
# &AddInterface("IntfName", Hash_Addr, <intf_ovr>);, 0 means no change
sub AddInterface {
  my $intf_name = shift; ### this is hash name
  my $intf_addr = shift; ### here is address pls note!
  my $intf_ovr  = 0;
     $intf_ovr =  shift; ### this is optional
  my $SubName = "AddInterface";
  #print TSDOUT "intf_ovr = $intf_ovr\n";

  if (exists $Our_Intf{"$intf_name"}) {
      &HDLGenInfo($SubName, " !!! you're updating existing Interface of ($intf_name), please double check this is expected !!!\n") if ($intf_ovr eq "0");
      $Our_Intf{"$intf_name"} = $intf_addr if ($intf_ovr);
  } else {
      &HDLGenInfo($SubName, " --- adding \$Our_Intf($intf_name) ...\n") if ($main::HDLGEN_DEBUG_MODE);
      $Our_Intf{"$intf_name"} = $intf_addr;
  }
  if ($main::debug) {
    open(INTF,">.Our_Intf_hash");
    print INTF Dumper(%Our_Intf);
    close(INTF);
  }

}

###------------------------------------------------------------------------------------------
### Read IPXACT XML and return a big hash ####
###------------------------------------------------------------------------------------------
sub AddIntfByIPX {
  my($SubName)="AddIntfByIPX";
  my($ipx_in) = $_[0];
  my($ipx_v) = "ipxact:";
  my($IP_XACT)=();
  my($temp_xml)=basename($ipx_in);
  $temp_xml = ".$temp_xml".".modified";

  if (-e $ipx_in) {
      $IP_XACT = &ReadXML($ipx_in);
  } else {
	  &HDLGenErr("AddIntfByIPX"," IPXACT file $ipx_in doesn't exist");
	  exit(1);
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
      &AddInterface($intf, $intf_hash);
  }
}

###------------------------------------------------------------------------------------------
### Add Our_Intf from JSON to $Our_Intf hash ####
###------------------------------------------------------------------------------------------
# &AddIntfByJson("IntfName", , <intf_ovr>);
sub AddIntfByJson {
  my $json_file = shift; 
  my $json_text = ();
  my $intf_name = "";
  my $intf_hash = "";
  my $SubName = "AddIntfByJson";

  if ( -e $json_file ) {
      open(JSON, "<$json_file") or die "!!! Error: can't find input JSON file of ($json_file) \n\n";
      $json_text = do { local $/; <JSON> };
      close(JSON);
      $intf_hash = decode_json($json_text);
      
      foreach $intf_name (keys(%$intf_hash)) {
          &AddInterface($intf_name, $intf_hash->{$intf_name},1);
      }
  } else {
	  &HDLGenErr("AddIntfByJson"," JSON file $json_file doesn't exist");
	  exit(1); 
  }
}

###------------------------------------------------------------------------------------------
### Add Our_Intf from RTL to $Our_Intf hash ####
###------------------------------------------------------------------------------------------
# &AddIntfByRTL("RTL_File","intf_name", "key");
sub AddIntfByRTL {
  my $rtl_file  = shift;
  my $intf_name = shift; 
  my $key_word  = shift; 
  my $SubName = "AddIntfByRTL";

  my $port_hash = &ParseRtlVlg($rtl_file);
  if ($key_word ne "") {
      foreach my $port (keys(%$port_hash)) {
	     if ($port=~ /$key_word/) {
             $Our_Intf{"$intf_name"}{"$port"} = $port_hash->{"$port"};
		 }
	 }
  } else { 
     $Our_Intf{"$intf_name"} = $port_hash;
  }

}

###------------------------------------------------------------------------------------------
### Add Our_Intf from SV RTL to $Our_Intf hash ####
###------------------------------------------------------------------------------------------
# &AddIntfBySV($RTL_multi-line_String);
sub AddIntfBySV {
  my $sv_code = shift; 
  my $intf_name = "";
  my $intf_hash = "";
  my $SubName = "AddIntfBySV";

  $intf_hash = &ParseSVIntf("$sv_code");
  foreach $intf_name (keys(%$intf_hash)) {
      &AddInterface($intf_name, $intf_hash->{$intf_name},1);
  }
}

###------------------------------------------------------------------------------------------
### remmove a port from Our_Intf->{"$intf_name"} ####
###------------------------------------------------------------------------------------------
# &RmIntfPort("port_name", "intf_name");
sub RmIntfPort {
  my $port_name = shift; 
  my $intf_name = shift; 
  my $SubName = "RmIntfPort";

  if (exists($Our_Intf{"$intf_name"})) {
     if (exists($Our_Intf{"$intf_name"}{"$port_name"})) {
		 delete($Our_Intf{"$intf_name"}{"$port_name"});
	 } else  {
         &HDLGenInfo($SubName," --- no such port in interface(\"$intf_name\"): $port_name \n");
	 }
  } else {
     &HDLGenInfo($SubName," --- no such interface: $intf_name \n");
  }
}

###------------------------------------------------------------------------------------------
### Add Our_Intf from a port list hash with key-word matched ####
###------------------------------------------------------------------------------------------
# &AddIntfByHash(\%port_hash, "intf_name", "test_"); ### as regular express key word
sub AddIntfByHash {
  my $port_hash = shift; 
  my $intf_name = shift; 
  my $intf_key  = "";
     $intf_key  = shift; ### this is port signal key-word
  my $SubName = "AddIntfByHash";

  foreach my $port_name (keys(%$port_hash)) {
     if ($intf_key ne "") {
        next if ($port_name !~ /$intf_key/); 
     }
     $Our_Intf{"$intf_name"}{$port_name} = $port_hash->{"$port_name"};
     $Our_Intf{"ports"}{"$port_name"} = $port_hash->{"$port_name"};
  } 
}

###------------------------------------------------------------------------------------------
### Add Our_Intf from a port name ####
###------------------------------------------------------------------------------------------
# &AddIntfByName("clk", "input:1", "intf_name"); 
sub AddIntfByName {
  my $port_name = shift; 
  my $port_wd   = shift; 
  my $intf_name = shift; 

  $Our_Intf{"busInterfaces"}{"$intf_name"}{$port_name} = $port_wd;
  $Our_Intf{"ports"}{"$port_name"} = $port_wd;
}

#============================================================================================================#
### remmove a port from Our_Intf->{"$intf_name"} ####
#============================================================================================================#
# &RmIntfPort("port_name", "intf_name");
sub RmIntfPort {
  my $port_name = shift;
  my $intf_name = shift;
  my $SubName = "RmIntfPort";

  if (exists($Our_Intf{"$intf_name"})) {
     if (exists($Our_Intf{"$intf_name"}{"$port_name"})) {
                 delete($Our_Intf{"$intf_name"}{"$port_name"});
         } else  {
         &HDLGenInfo($SubName," --- no such port in interface(\"$intf_name\"): $port_name \n");
         }
  } else {
     &HDLGenInfo($SubName," --- no such interface: $intf_name \n");
  }
}

###------------------------------------------------------------------------------------------
### Parse RTL Verilog file to get all ports   ###
### return a hash with "input" & "outut" list ###
###------------------------------------------------------------------------------------------
sub ParseRtlVlg {
  my $SubName = "ParseRtlVlg";	
  my $rtl_in = shift;
  open(RTL_IN, "<$rtl_in") or die "!!! Error: can't find input RTL file of ($rtl_in) \n\n";

  my $port_hash ;

  my $module_end   = "0";
  my $module_start = "0";
  while(<RTL_IN>) {
    chomp($_);
  	if ( ($_ =~ /^\s*\/\//) or !($_ =~ /\S/) ) {
          next ;
  	}
    if ( $_ =~ /module /) {
       $module_start = "1";
    } elsif ( ($_ =~/\);/) && ($module_start eq "1") ) {
        $module_end = "1";
        &HDLGenInfo($SubName, " --- found ); on cur line:$_") if ($main::HDLGEN_DEBUG_MODE);
    } elsif ( ($_ =~ /^\s*always/) or ($_ =~ /^s*assign/) ) { ### no port define after code begin
        last; 
    } elsif ($_ =~ /endmodule/ ) {
        $module_end = "2";
        last;
    }

    if ($_ =~ /^\s*,?input/) {
       my($i_sig,$p_width)=&ParsePorts("$_");
       &HDLGenInfo($SubName, " --- find input as: $i_sig, $p_width \n") if ($main::HDLGEN_DEBUG_MODE);
       if ($i_sig =~ /,/) { 
          my @p_array = split(",",$i_sig);
          foreach my $pp (@p_array) {
              $port_hash->{"$pp"} = "input:$p_width";
          }
       } else {
          $port_hash->{"$i_sig"} = "input:$p_width";
       }
    } elsif ($_ =~ /^\s*,?output/) {
       my($o_sig,$p_width)=&ParsePorts("$_");
       &HDLGenInfo($SubName, " --- find output as: $o_sig, $p_width \n") if ($main::HDLGEN_DEBUG_MODE);
       if ($o_sig =~ /,/) { 
          my @p_array = split(",",$o_sig);
          foreach my $pp (@p_array) {
              $port_hash->{"$pp"} = "output:$p_width";
          }
       } else {
          $port_hash->{"$o_sig"} = "output:$p_width";
       }
    } 
  } 
  close(RTL_IN);

  return($port_hash);

}

###------------------------------------------------------------------------------------------
#------ Pasre Verilog inputs & output------#
###------------------------------------------------------------------------------------------
sub ParsePorts {
    my($SubName)="ParsePorts";
    my($p_line)=shift;
    my($p_name)="";
    my($p_width)="";

    $p_line =~ s/wire //;
    $p_line =~ s/reg //;
    $p_line =~ s/\s*\/\/.*$//g;
    $p_line =~ s/(,|;)$//g;
    $p_line =~ s/^,|;//g; 
    $p_line =~ s/,\s*//g;

    &HDLGenInfo($SubName," --- port line  is:  $p_line") if ($main::HDLGEN_DEBUG_MODE);
    if ($p_line !~ /\[/) { 
	    $p_line =~ /(in|out)put\s+(\w+)/;
        return($2,1);
    } else {
	    if ($p_line =~ /\[(.*)\]\s+(\w+)/) { 
			return($2,$1);
        } else {
           &HDLGenErr($SubName," port define is wrong:$p_line, $2 $1");# if ($main::HDLGEN_DEBUG_MODE);
	 }
    }
} ### end of sub ParsePorts

###------------------------------------------------------------------------------------------
### Add Our_Intf from SV RTL to $Our_Intf hash ####
###------------------------------------------------------------------------------------------
# &ParseSVIntf($RTL_multi-line_String);
sub ParseSVIntf {
  my $sv_code = shift; ### this is json file
  my @sv_code = split("\n",$sv_code);
  my $intf_name = "";
  my $intf_hash ; 
  my $SubName = "ParseSVIntf";

  foreach my $sv (@sv_code) {
	if ($sv =~ /^\s*interface\s+(\w*)\(/) {
	   $intf_name = $1;
	   next;
    } elsif ($sv =~ /^\s*interface\s+(\w*) /) {
	   $intf_name = $1;
	   next;
    } elsif ($sv =~ /endinterface/) {
	   next;
	} elsif ( ($sv =~ /modport/) or ($sv =~ /\);/) ) {
		next;
	}
	if ( $sv =~ /\S/ ) {
		my($sig_def,$p_name,$p_width)=&ParseSVIntfLine($sv);
	    $intf_hash->{"$intf_name"}->{"$p_name"} = "$sig_def: $p_width" if ($intf_name ne "");
	}
  }
  return($intf_hash);

}

###------------------------------------------------------------------------------------------
#------ Pasre Verilog inputs & output------#
###------------------------------------------------------------------------------------------
sub ParseSVIntfLine {
    my($SubName)="ParseSVIntfLine";
    my($p_line)=shift;
    my($p_name)="";
    my($p_width)="";

    $p_line =~ s/\s*\/\/.*$//g;
    $p_line =~ s/[;|,]\s*$//g;
    $p_line =~ s/^,|;//g; 
    $p_line =~ s/,\s*/,/g;

    &HDLGenInfo($SubName," --- port line  is:  $p_line") if ($main::HDLGEN_DEBUG_MODE);
    if ($p_line !~ /\[/) { 
	    $p_line =~ /(input|output|logic|wire)\s+(\w+)/; 
        return($1,$2,1);
    } else { 
	    if ($p_line =~ /(input|output|logic|wire)\s+\[(.*)\]\s+(\w+)/) { 
	       return($1,$3,$2);
        } else {
           &HDLGenErr($SubName," port define is wrong:$p_line, $2 $1");# if ($main::HDLGEN_DEBUG_MODE);
	 }
    }
} ### end of sub ParsePorts

###------------------------------------------------------------------------------------------
### print IPXACT XML from hash ####
###------------------------------------------------------------------------------------------
# &ShowIPX("IPX_design.xml"); 
sub ShowIPX {
  my $IPX_file = shift;

  print STDOUT BOLD YELLOW " --- Show all interfaces in IPXACT($IPX_file) ---\n";
  open(IP_F,">$IPX_file.intf");
  print IP_F "###--- Below are all interfaces defined in $IPX_file ---###\n";
  my $IP_XACT = &ReadXML($IPX_file);

  my($I) = $IP_XACT->{"busInterfaces"}->{"busInterface"};
  foreach my $intf (keys(%$I)) {
	  print IP_F "\"$intf\" =>\n";
	  print IP_F "    \" ";
      my @P = $I->{$intf}->{portMaps}->{portMap};
      foreach my $pp (@P) {
          foreach my $ppp (@$pp) {
	         my $pppp = $ppp->{physicalPort};
	         my $p_name = $pppp->{name};
			 print IP_F "$p_name, ";
          }
      }
	  print IP_F "\";\n\n";
  }
  close(IP_F);
}
###------------------------------------------------------------------------------------------
### print IPXACT XML from hash ####
###------------------------------------------------------------------------------------------
# &GenIPX("IP_design", "MyCorp"); 
sub GenIPX {
    #================================

        vprintl("\n//| =========================================================\n");
        vprintl("//| GenIPX function is still underconstruction, need more time\n");
        vprintl("//| any suggestion or solotion or contribution is reall welcome!\n");
        vprintl("\n//| =========================================================\n\n");

    #================================
}	

### ====================================================================== ###
### ========== for DTI(Data Transder Interface) Valid,Ready,Data interface ========
### ====================================================================== ###
### &DTIWire("prefix", "data_width");
sub DTIWire {
	my $prefix = shift;
	my $data_width = shift;

	if ($data_width eq "") {
		&HDLGenErr("DTIWire", " data width is NOT defined !!!\n");
	} elsif ($data_width !~ /\d+/) {
		&HDLGenErr("DTIWire", " data width define is not correct as \"$data_width\"\n");
	} 

	if ($prefix eq "") {
		&HDLGenErr("DTIWire", " DTI Prefix is NOT defined!!!\n");
	}

    push @HDLGen::VOUT, "wire ${prefix}_valid;\n";
    push @HDLGen::VOUT, "wire ${prefix}_ready;\n";
    push @HDLGen::VOUT, "wire [$data_width-1:0] ${prefix}_data;\n";
}

### &DTISlave("prefix", "data_width");
sub DTISlave {
	my $prefix = shift;
	my $data_width = shift;

	if ($data_width eq "") {
		&HDLGenErr("DTISlave", " data width is NOT defined !!!\n");
	} elsif ($data_width !~ /\d+/) {
		&HDLGenErr("DTISlave", " data width define is not correct as \"$data_width\"\n");
	} 

	if ($prefix eq "") {
		&HDLGenErr("DTISlave", " DTI Prefix is NOT defined!!!\n");
	}

    push @HDLGen::VOUT, "input  ${prefix}_valid;\n";
    push @HDLGen::VOUT, "output ${prefix}_ready;\n";
    push @HDLGen::VOUT, "input  [$data_width-1:0] ${prefix}_data;\n";

}

### &DTIMaster("prefix", "data_width");
sub DTIMaster {
	my $prefix = shift;
	my $data_width = shift;

	if ($data_width eq "") {
		&HDLGenErr("DTIMaster", " data width is NOT defined !!!\n");
	} elsif ($data_width !~ /\d+/) {
		&HDLGenErr("DTIMaster", " data width define is not correct as \"$data_width\"\n");
	} 

	if ($prefix eq "") {
		&HDLGenErr("DTIMaster", " DTI Prefix is NOT defined!!!\n");
	}

    push @HDLGen::VOUT, "output ${prefix}_valid;\n";
    push @HDLGen::VOUT, "input  ${prefix}_ready;\n";
    push @HDLGen::VOUT, "output [$data_width-1:0] ${prefix}_data;\n";

}


### ====================================================================== ###
### ========== End of Package ========
### ====================================================================== ###
1;

