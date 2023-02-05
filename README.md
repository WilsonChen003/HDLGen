# HDLGen from Wilson Chen 2022~2023

## Overview
  HDLGen is a tool for HDL(mainly for Verilog) generation, it enables embedded Perl or Python scripts in Verilog source code,  and support Perl style variable anyway, to generate desired HDL in an easy and efficient way. 
  It supports all syntax and data structure of Perl or Python, and has a few predefined functions for signal define, module instance, port connection etc.  
  This tool also supports extended API functions in Perl style, for any function or module that you want or have from previous knowledge or project.  
  HDL and script mixed design file can be any name, while final generated RTL file will be Verilog only( as .v).

## License 
                         Copyright 2022~2023 Wilson Chen                                                     
            Licensed under the Apache License, Version 2.0 (the "License");                            
            You may not use this file except in compliance with the License.                          
            You may obtain a copy of the License at                                                  
                    http://www.apache.org/licenses/LICENSE-2.0                                      
            Unless required by applicable law or agreed to in writing, software                    
            distributed under the License is distributed on an "AS IS" BASIS,                     
            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.             
            See the License for the specific language governing permissions and                 
            limitations under the License.                                                     
   
****************************************************************************************
***any feedback, suggestion, requirement, solution, contribution, is always welcome***
****************************************************************************************
   
## What you can do with HDLGen 
RTL stitch
   * Instance module from RTL or IPXACT or JSON file as what Verilog does
   * Connect  module's port to wires with native regular express
   * Automatically generate instance's wires definitions
   * Automatically generate reg or wire definictions(not perfect but really helpful) 
   * Warning out any Instance signals which has no connection
   * Use embedded native Perl or Python to generate(print) whatever code you want

Interface manipulate
   * Add interface from IPXACT, JSON, RTL, SV code, or hash array
   * Add port to interface by name
   * Remove port from interface by name
   * Print or show interface signals for design or debug

IPXACT manipulate
   * Read in IPXACT and add all interfaces
   * Show all interfaces defined in IPXACT ( for debug )
   * Translate IPXACT into JSON file ( for debug & integration)
   * Export Interface to JSON with name changing
   * Export port or remove port to/from JSON file
   * Export interface to IPXACT by name ( **abolished** )
   * Export port to IPXACT by name ( **abolished** )
   * Export standard IPXACT for current top module ( **abolished** )
 
Function generation
   * Use embedded functions to generate differnt module or loigc you want
     * Clk, Reset, Fuse, Pmu, Fifo, Async-interface, Memories etc ( flow done, can custom design )
   * Extend your own module/logic by standard config ( in development )
	 * config can be in Verilog, JSON, YAML, EXCEL etc.
	 * then generate these logic with parameters by just a simple function call

**Based on above functions, this tool can generate a SOC in an easy and flexible way**

## What you cannot do with HDLGen 
   * Detail logic design: you still need to write RTL to implement your ideas 
   * Synthesis or simulation or verification: you need to use other EDA tools to handle
   
## Working Flow
   Different level design can use this tool with different functions a/o inputs/outputs, the main working flow is as below<br>
![Working Flow](https://github.com/WilsonChen003/HDLGen/blob/master/doc/WorkingFlow.PNG)
   
## Directory Structure   
    ├── HDLGen.bin                # Tool binary for easy adopt
    ├── HDLGen.pl                 # Tool source code
    ├── plugins                   # Tool plugin funcitons in Perl module
        ├── Design_Template         # custom module design template files
    ├── test                      # Source design code for testing
	    ├── cfg                     # JSON and XML for config
	    ├── incr                    # necessary design files
    ├── doc                       # usage introduction 

## Usage
   first you need to set shell ENV of ***HDLGEN_ROOT***, otherwise tool will report error.<br>
   plese refer to `setenv.sh`<br>
   then run command as simple as: <br>
   `cd test` <br>
   `../HDLGen.pl -i NV_NVDLA_CMAC_CORE_mac.src` or `../HDLGen.bin -i NV_NVDLA_CMAC_CORE_mac.src` <br>
   or `../HDLGen.pl -f ./src.list`<br>
   for help message you can run: <br>
   	`HDLGen.pl -usage`

### NOTE: 
* Verilog-mode for EMACS or VIM is very powerful to do AUTO Port,Reg/Wire, and Instance, but it has some limitations or inconvenient things:<br>
             --- mostly used in GUI mode but no batch mode -- ***seems NOT TURE*** <br>
	     --- Instance port/wire name change is manual hard mapping but no Regular Express --- ***NOT TRUE, RE is supproted but need 3rd file***<br>
	     --- No Warning for unconnected instance signals<br>
	     --- No Interface a/o IPXACT support<br>
	     --- No embedded Perl/Python support<br>
	     --- no function generation for inhouse/customer design
* this tool only test on Ubuntu 18.04.05 & 20.04.5 with Perl-5.34, but should work on any system have Perl5 installed
* Python script only support python3 but no python2.x (one more reason for why not Python ;-)  )            
* several Perl Modules are required, can refer to the package head in source code, here listed:<br>
                        Getopt<br>
                        JSON<br>
			Text::Template<br>
                        File::Basename<br>
                        File::Find<br>
			Verilog::Netlist<br>
                        XML::Simple<br>
                        XML::SAX::Expat; *#this is strange as not used at all, but pp need it*<br>
                        Dumper<br>
			Text::ParseWords<br>
                        Term::ANSIColor<br>
			
			
**Suggestion:**<br>
 You can first run HDLGen.pl, then install any package according to the error message,<br>
 or just run HDLGen.bin for results
	         

### Samples
**AutoDef Sample:**<br>	
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/AutoDef_Sample.PNG" width="500" height="500"/><br/>
													

**AutoInstSig Sample:**<br>
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/AutoInstSig_Sample.PNG" width="500" height="500"/><br/>

**AutoWarning Sample:**<br>
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/AutoWarning_Sample.PNG" width="500" height="500"/><br/>


**Verilog Instance Sample:**<br>
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/Instance_Sample.PNG" width="500" height="500"/><br/> 

**IPXACT Instance Sample:**<br>
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/IPXACT_Sample.PNG" width="300" height="300"/><br/>


**JSON Instance Sample:**<br>
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/JSON_Sample.PNG" width="400" height="500"/><br/>


**Design Template File Sample:**<br>
<img src="https://github.com/WilsonChen003/HDLGen/blob/master/doc/Design_Template_Sample.PNG" width="500" height="500"/><br/>



### ***Why need this tool?***<br>
  For any ASIC or SOC engineer with over 10 years experience, we may hate Verilog sometime, as Verilog HDL's syntax is TOO simple or TOO basic, it's Register Transfer Level description, we're not writing code, we're indeed designing circuit, it's very cool, but sometime we will be bored, especially when instancing module, do wire connections.<br>
   So we learned and tried different ways, we may study and learn Chisel, SpinalHDL, MyHDL PyHDL, or PyGear recently. But, when we learned, tried, finally we gave up, because they're DSL, they're not HDL! DSL is totally new language, DSL is more like a high level software language, we have to write code in a new style, no Verilog or HDL at all.<br>
   Is it safe for a project to abandon Verilog HDL? Is it safe for an experienced engineer to abandon previous skills and design logic with non-HDL code? Is it easy or friendly to learn a new language? Is that language widely used or accepted and will evolve in long term? Is there any different way to help us?<br>
   Yes, we have a different way! And it is easy to use, smoothly to move, seamlessly to adopt.<br>
   The tool is going to support you keep writing HDL while give the ability to improve your efficiency, and with ZERO learning curve, is here, named as "HDLGen".
   The way you're going to work is writing Verilog or VHDL code, the tool helps you on most boring tasks: signal define for wire a/o reg, instance modules by connections with auto wire signals defined and easy name change, connect signals with regular expression, instance JSON and IPXACT xml file as simple as HDL code natively. If any task/logic/design which is not friendly written in HDL, then you can use high level script language like Perl or Python for any code or task you want, wherever and whenever in the HDL source file, as long as you know Perl or Python script, or even shell script.<br>
   This tool supports standard AMBA bus interfaces natively. This tool also support you to manually define an interface, through SystemVerilog, Verilog, IPXACT or XML, JSON, or Hash array. <br>
   If there is any inhouse developed or accumulated design which is common for your designs, you can put as a template in this tool, then instance with any parameters you want by just as simple as one function call in HDL. <br>


__*** DSL is really cool ***__<br>
__*** But Verilog is still the King ***__<br>
__*** Connection is what you need ***__<br>
__*** And Fexibility is really helpful ***__<br>


## Thanks
***Thanks NVIDIA for giving me the chance to know how Perl is powerful to run big ASIC factory,***<br>
***Thanks NVIDIA's VIVA to let me know how Perl makes Verilog intersting and amazing.***<br>
***Thanks NVIDIA's open sourced NVDLA as a test source.***<br>
                                          
### ***Note:***
This tool was developed from scratch during the special spring time in Shanghai in 2022<br>
The things related to NVIDIA are:<br>
  * several functions' name are identical;<br>
  * several HDL files of open sourced NVDLA are used to be test source<br>
	
 ***************************************************************
 ***Please kindly let me know if there is any license issue***
 ***************************************************************

