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


package eFunc;
use strict;
use base qw(Exporter);
use warnings FATAL => qw(all);

# add plugin below, and check the usege in each package in the directory
use ClkGen;
use RstGen;
use PmuGen;
use FuseGen;
use MemGen;
use AsyncGen;
use FifoGen;
 
1;
