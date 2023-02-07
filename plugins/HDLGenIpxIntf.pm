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



use strict;
use XML::Simple;
use JSON;
use Getopt::Long qw(GetOptions);
use Text::ParseWords qw(shellwords);
use Data::Dumper;
use File::Basename;

our %Our_Intf = ();
our $Expt_Intf = ();
my  $MyCorp    = "MyCorp";


#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
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
};

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
       "AWUSER"   => "input:4",  ### new
       "ARUSER"   => "input:4",  ### new
       "WUSER"   => "input:4",  ### new
       "RUSER"   => "input:4",  ### new
       "BUSER"   => "output:4",  ### new
       "CACTIVE" => "input",
       "CSYSACK" => "output",
       "CSYSREQ" => "input"
};

$Our_Intf{"AXI_Lite"} = {
       "ACLK" => "input:1",
       "ARESETn" => "input:1",
       "AWVALID" => "input:1",
       "AWREADY" => "output:1",
       "AWADDR"  => "input:32",
       "AWPROT"  => "input:3",
       "WVALID"  => "input:1",
       "WDATA"   => "input:64",
       "WSTRB"   => "input:4",
       "WREADY"  => "output:1",
       "ARVALID" => "input:1",
       "ARREADY" => "output:1",
       "ARADDR"  => "input:32",
       "ARPROT"  => "input:3",
       "RVALID"  => "output:1",
       "RREADY"  => "input:1",
       "RDATA"   => "output:64",
       "RRESP"   => "output:2",
       "BVALID"  => "output:1",
       "BREADY"  => "input:1",
       "BRESP"   => "output:2"

};

$Our_Intf{"DTI"} = {
       '_valid' => "input:1",
       '_ready' => "output:1",
       '_data'  => "input:32" 
   };

#============================================================================================================#
#============================================================================================================#
sub PrintIntfPort {
  my($SubName)="PrintIntfPort";
  my $args = shift;
  @ARGV = shellwords($args);
  my $pr_out = "";
  
  #================================
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
  $master = 0 if ($slave ne "");

  my $chg_args = "-master $master -portwirereg $portwirereg -uplow $uplow";
  $chg_args .= " -prefix $prefix" if ($prefix ne "");
  $chg_args .= " -suffix $suffix" if ($suffix ne "");
  $chg_args .= " -awd $awd" if ($awd ne "");
  $chg_args .= " -dwd $dwd" if ($dwd ne "");

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



#============================================================================================================#
#============================================================================================================#
sub PrintAmbaBus {
   my($SubName)="PrintAmbaBus";
   my $args = shift;
   @ARGV = shellwords($args);
   my $pr_out = "";
   
   #================================
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
   my $end  = ";";
   my $port = "";
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

   	  my $pr_line = sprintf("%-8s %-16s %-16s%s", $sig_def, $p_w, $sig, $end);  
	  $pr_out .= "$pr_line\n"; 
  }
  push @HDLGen::VOUT, "$pr_out";

}


#============================================================================================================#
#============================================================================================================#
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
              'master=s'  => \$master, ### default is slave
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
         if ($master eq "1") {
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

#============================================================================================================#
#============================================================================================================#
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
      &AddIntf($intf, $intf_hash);
  }

}

#============================================================================================================#
#============================================================================================================#
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



#============================================================================================================#
#============================================================================================================#
sub ShowIPXIntf{
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

#============================================================================================================#
#============================================================================================================#
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

#============================================================================================================#
#============================================================================================================#
sub ShowIntf {
  my($SubName)="GetIntf";
  my $i_name = "$_[0]";
 
  if (exists $Our_Intf{"$i_name"}) {
	  open(INTF,">./$i_name.intf");
      print STDOUT BOLD YELLOW "   --- Show hash of \"$i_name\"---\n";
	  print INTF "  \"$i_name\" : {\n";
	  my $i_hash = $Our_Intf{"$i_name"};
	  foreach my $i_sig (keys(%$i_hash)) {
			  print INTF "      \"$i_sig\" : \"$i_hash->{$i_sig}\",\n";
	  }
	  print INTF "  }\n";
	  close(INTF);
  } else {
      &HDLGenErr($SubName, "!!! no Our_Intf hash of \$Our_Intf{$i_name} !!!\n");
      return("NULL");
      exit;
  }

}

#============================================================================================================#
#============================================================================================================#
sub AddIntf {
  my $intf_name = shift;
  my $intf_addr = shift;
  my $intf_ovr  = 0;
     $intf_ovr =  shift;
  my $SubName = "AddIntf";

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

#============================================================================================================#
#============================================================================================================#
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
      &AddIntf($intf, $intf_hash);
  }
}

#============================================================================================================#
#============================================================================================================#
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
          &AddIntf($intf_name, $intf_hash->{$intf_name},1);
      }
  } else {
	  &HDLGenErr("AddIntfByJson"," JSON file $json_file doesn't exist");
	  exit(1); 
  }
}

#============================================================================================================#
#============================================================================================================#
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

#============================================================================================================#
#============================================================================================================#
sub AddIntfBySV {
  my $sv_code = shift;
  my $intf_name = "";
  my $intf_hash = "";
  my $SubName = "AddIntfBySV";

  $intf_hash = &ParseSVIntf("$sv_code");
  foreach $intf_name (keys(%$intf_hash)) {
      &AddIntf($intf_name, $intf_hash->{$intf_name},1);
  }
}

#============================================================================================================#
### remmove a port from Our_Intf->{"$intf_name"}
#============================================================================================================#
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

#============================================================================================================#
#============================================================================================================#
sub AddIntfByName {
  my $port_name = shift;
  my $port_wd   = shift;
  my $intf_name = shift;

  $Our_Intf{"busInterfaces"}{"$intf_name"}{$port_name} = $port_wd;
  $Our_Intf{"ports"}{"$port_name"} = $port_wd;
}

#============================================================================================================#
#============================================================================================================#
# &AddIntfByHash(\%port_hash, "intf_name", "test_");
sub AddIntfByHash {
  my $port_hash = shift;
  my $intf_name = shift;
  my $intf_key  = "";
     $intf_key  = shift;
  my $SubName = "AddIntfByHash";

  foreach my $port_name (keys(%$port_hash)) {
     if ($intf_key ne "") {
        next if ($port_name !~ /$intf_key/); 
     }
     $Our_Intf{"$intf_name"}{$port_name} = $port_hash->{"$port_name"};
     $Our_Intf{"ports"}{"$port_name"} = $port_hash->{"$port_name"};
  } 
}

#============================================================================================================#
#============================================================================================================#
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
    } elsif ( ($_ =~ /^\s*always/) or ($_ =~ /^s*assign/) ) {
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

#============================================================================================================#
#============================================================================================================#
sub ParsePorts {
    my($SubName)="ParsePorts";
    my($p_line)=shift;
    my($p_name)="";
    my($p_width)="";

    $p_line =~ s/\s+wire\s+/ /;
    $p_line =~ s/\s+reg\s+/ /;
    $p_line =~ s/\s+logic\s+/ /;
    $p_line =~ s/\s+bit\s+/ /;
    $p_line =~ s/\s*\/\/.*$//g;
    $p_line =~ s/,\s*$|;\s*$//g;
    $p_line =~ s/^\s*,|^\s*;//g; 
    $p_line =~ s/,\s+/,/g; 


    &HDLGenInfo($SubName," --- port line  is:  $p_line") if ($main::HDLGEN_DEBUG_MODE);
    if ($p_line !~ /\[/) {
	    $p_line =~ /(input|output|inout)\s+(\S+)/;
        return($2,1,$1);
    } else {
	    if ($p_line =~ /\[(.*)\]\s+(\S+)/) {
			return($2,$1);
        } else {
           &HDLGenErr($SubName," port define is wrong:$p_line, $2 $1");
	 }
    }
}

#============================================================================================================#
#============================================================================================================#
sub ParseSVIntf {
  my $sv_code = shift;
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

#============================================================================================================#
#============================================================================================================#
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
           &HDLGenErr($SubName," port define is wrong:$p_line, $2 $1");
	 }
    }
}


#============================================================================================================#
#============================================================================================================#
sub ExptIntf {
  my $args = shift;
  @ARGV = shellwords($args);
  my $SubName = "ExptIntf";

  my $intf_name = "";
  my $name_expt = "";
  my $up        = "";
  my $low       = "";
  my $prefix    = "";
  my $suffix    = "";
  my $master    = "0";
  my $slave     = "";

  GetOptions (
              'intf_name=s' => \$intf_name,
              'name_expt=s' => \$name_expt,
              'upcase'      => \$up,
              'lowcase'     => \$low,
              'prefix=s'    => \$prefix,
              'suffix=s'    => \$suffix,
              'master'      => \$master,
              'slave'       => \$slave,
              )  or die "Unrecognized options @ARGV";


  my $intf_addr;
  if (exists($Our_Intf{"$intf_name"})) {			  
     $intf_addr = &GetIntf("$intf_name"); 
  } else {
      &HDLGenErr($SubName, "!!! NO such Our_Intf of $intf_name, pls double check !!!\n");
	  return;
  }
  foreach my $port_name (keys(%$intf_addr)) {
      my $expt_port = "$prefix"."$port_name"."$suffix";
	  if ($up) {
		  $expt_port = uc($expt_port);
	  } elsif ($low) {
		  $expt_port = lc($expt_port);
	  }
	  my $port_line = $intf_addr->{$port_name};
	  if ( ($port_name !~ /CLK/i) and ($port_name !~ /RESET/i) ) {
        if ($master ne "") {
		  if ($port_line =~ /input/) {
			  $port_line =~ s/input/output/;
		  } elsif ($port_line =~ /output/) {
		      $port_line =~ s/output/input/;
		  }
	    }
      }
      $Expt_Intf->{"busInterfaces"}->{"$name_expt"}->{"$expt_port"} = $port_line;
  }
}

#============================================================================================================#
#============================================================================================================#
sub ExptPort {
  my $port_name = shift;
  my $port_dir  = shift;
  my $port_wd   = shift;

  &HDLGenInfo("ExptPort"," --- adding port: $port_name \n") if ($main::HDLGEN_DEBUG_MODE);

  $Expt_Intf->{"ports"}->{"$port_name"} = "$port_dir : $port_wd";
}

#============================================================================================================#
#============================================================================================================#
sub RmPort {
  my $port_name = shift;

  &HDLGenInfo("RmPort"," --- removing port: $port_name \n") if ($main::HDLGEN_DEBUG_MODE);

  my $intf_expt = $Expt_Intf->{"busInterfaces"};
  foreach my $intf_name (keys(%$intf_expt)) {
	  my $intf_hash = $Expt_Intf->{"busInterfaces"}->{"$intf_name"};
	  if (exists($intf_hash->{"$port_name"})) {
         delete($intf_hash->{"$port_name"});
	  }
  }
  delete($Expt_Intf->{"ports"}->{"$port_name"});

}


#============================================================================================================#
#============================================================================================================#
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

#============================================================================================================#
#============================================================================================================#
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

#============================================================================================================#
#============================================================================================================#
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

#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#
#============================================================================================================#


sub GenModIPX {
  #my $IP_name = shift;
  #my $corp_name = shift;
  #$corp_name = "MY_CORP" if ($corp_name eq "");

  &HDLGen::HDLGenInfo("GenModIPX", " !!!--- IPXACT exporting is not supported ---!!! \n");

}


1;

