//##############################################################################################################
//##############################################################################################################
//##############################################################################################################
//###                         Copyright 2022 Wilson Chen                                                     ###
//###            Licensed under the Apache License, Version 2.0 (the "License");                             ###
//###            You may not use this file except in compliance with the License.                            ###
//###            You may obtain a copy of the License at                                                     ###
//###                    http://www.apache.org/licenses/LICENSE-2.0                                          ###
//###            Unless required by applicable law or agreed to in writing, software                         ###
//###            distributed under the License is distributed on an "AS IS" BASIS,                           ###
//###            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.                    ###
//###            See the License for the specific language governing permissions and                         ###
//###            limitations under the License.                                                              ###
//##############################################################################################################
//##############################################################################################################
//##############################################################################################################

//================================================================================================
//======= this is internal design for Async Fifo ===============
//================================================================================================
//// default module name is : async_fifo

module <:$mod_name:> 
(
        // FIFO????????
         parameter   data_width = <:$dwd:>,// FIFO????
         parameter   data_depth = <:$depth:>,// FIFO????
         parameter   address_width = <:$awd:>, // ????????????????????2^n??FIFO??????????/????????????(n+1)??????????????????????????
         input                           rst_wr,
         input                           wr_clk,
	 input                           wr_en,
         input      [data_width-1:0]     wr_din, 
         input                           rst_rd,
         input                           rd_clk,
         input                           rd_en,
         output reg [data_width-1:0]     rd_dout,
         output                          empty,
         output                          full
);
 
 
reg    [address_width:0]    wr_addr_p;//??????????
reg    [address_width:0]    rd_addr_p;//??????????
 
wire   [address_width-1:0]  wr_addr;//??RAM ????
wire   [address_width-1:0]  rd_addr;//??RAM ????
 
wire   [address_width:0]    wr_addr_gray;//??????????????????????
reg    [address_width:0]    wr_addr_gray_d1;
reg    [address_width:0]    wr_addr_gray_d2;//????????????????????????????????????
 
wire   [address_width:0]    rd_addr_gray;//??????????????????????
reg    [address_width:0]    rd_addr_gray_d1;
reg    [address_width:0]    rd_addr_gray_d2;//????????????????????????????????????";

<:
   if ($noram == 1) {
	    $OUT .= "                 reg    [data_width-1:0] FIFO_DFF_ARRAY [data_depth-1:0];// DFF Array????????FIFO????";
	}
:>

// ??????????
always@(posedge write_clk or negedge rst_n)begin
    if(!rst_n)
        wr_addr_p <='h0;
    else if(write_en && (~full))// ????????????
        wr_addr_p <= wr_addr_p + 1;
    else 
        wr_addr_p <= wr_addr_p;
end
 
assign wr_addr = wr_addr_p[address_width-1:0];// ????RAM????????????????????address_width??
 
// ????
always@(posedge write_clk) begin
	if(write_en && (~full))// ????????????
        FIFO_RAM[wr_addr] <= data_in;
    else
        FIFO_RAM[wr_addr] <= FIFO_RAM[wr_addr]; 
end
 
 
// ??????????      
always@(posedge read_clk or negedge rst_n)begin
    if(!rst_n)
        rd_addr_p <='h0;
    else if(read_en && (~empty))// ????????????
        rd_addr_p <= rd_addr_p + 1;
    else 
        rd_addr_p <= rd_addr_p;
end
 
assign rd_addr = rd_addr_p[address_width-1:0];// ????RAM????????????????????address_width??

<: 
	if ($noram == 1) {
	$OUT .= "
// ????
always@(posedge read_clk)begin
	if(read_en && (~empty))// ????????????
        data_out <= FIFO_DFF_ARRAY[rd_addr];
    else
        data_out <='h0;
end
";

	} else {
		$OUT .= "
	// You need to replace your sram for you project a/o foundary
	mem_foundary_wrap mem_inst (
	   .wclk(wr_clk),
	   .rclk(rd_clk),
	   .wen(wr_en),
	   .ren(rd_en),
	   .waddr(wr_ptr),
	   .raddr(rd_ptr),
	   .din(wr_din),
	   .dout(rd_dout)
	);
	";
	}
:>
 
// ????????????????????????
assign wr_addr_gray = (wr_addr_p >> 1) ^ wr_addr_p;
assign rd_addr_gray = (rd_addr_p >> 1) ^ rd_addr_p;
 
//????????????????????->????????
always@(posedge write_clk)begin// ??????
    rd_addr_gray_d1 <= rd_addr_gray;
    rd_addr_gray_d2 <= rd_addr_gray_d1;
end
 
// ??????->????????
always@(posedge read_clk )begin// ??????
    wr_addr_gray_d1 <= wr_addr_gray;
    wr_addr_gray_d2 <= wr_addr_gray_d1;
end
 
//????????????
assign full = (wr_addr_gray == {~(rd_addr_gray_d2[address_width:address_width-1]),rd_addr_gray_d2[address_width-2:0]}) ;//????????????????????????
assign empty = (rd_addr_gray == wr_addr_gray_d2 );// ??????????????????????
 
endmodule

