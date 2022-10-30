#!/usr/bin/env perl

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
