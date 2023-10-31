// =====================================================
// === APB register module generated by RegGen ===
// === Please do NOT change manually            ===
// =====================================================

module test_sys_ctrl (
input pclk,
input presetn,
input psel,
input penable,
input pwrite,
input [31:0] paddr,
input [31:0] pwdata,
output reg [31:0] prdata,
output reg pready,
output reg pslverr

// field "pdc_use_arm_ctrl" of reg_sys_ctrl0 : 
,output reg[0:0] sys_ctrl0_pdc_use_arm_ctrl
// field "l2c_strip_mode" of reg_sys_ctrl0 : 
,output reg[2:0] sys_ctrl0_l2c_strip_mode
// field "smmu_mmusid" of reg_sys_ctrl0 : 
,output reg[4:0] sys_ctrl0_smmu_mmusid
// field "mem_repair_en" of reg_sys_ctrl0 : 
,output reg[0:0] sys_ctrl0_mem_repair_en
// field "mem_repair_done" of reg_sys_ctrl0 : 
,output reg[6:0] sys_ctrl0_mem_repair_done
// field "test_field0" of reg_test_reg : 
,output reg[3:0] test_reg_test_field0
// field "test_filed1" of reg_test_reg : 
,output reg[1:0] test_reg_test_filed1
);

localparam NULLRESP = 1'b0;
localparam DVA      = 1'b0;
localparam FAIL     = 1'b1;
localparam ERR      = 1'b1:

//Protocol management
reg        ready, error;
reg [1:0]  state, nstate;
reg [31:0] rdata_sel:

localparam RESET = 2'b00, IDLE = 2'b01, TRANSACTION = 2'b10, NOTREADY = 2'b11;

always @(*) begin
   nstate = state;
   case (state)
       //transition when reset is no more active
       RESET : nstate = IDLE;
       //when an access starts
       IDLE : if psel !penable)nstate TRANSACTION:
       //if ready then the APB access completes in 2 cycles
       TRANSACTION : begin if (pready | error | !psel |!penable) nstate =IDLE; else nstate = NOTREADY; end
       //data is not ready,APB access is extended
       NOTREADY:if (pready !psel !penable) nstate = IDLE;
   endcase
end

always @(negedge presetn or posedge pclk) begin
  if (!presetn) 
     state <= RESET;
  else 
     state <=nstate;
end

//
//   Protocol specific assignment to inside signals do not do something internally if the cmd is not valid
//
wire [31:0] addr, paddr[31:0];
wire [31:0] pwdata[31:0];
wire wen = pwrite & (state =TRANSACTION) & psel & penable;

// write byte enable for each reg
wire [5-1:0] wen_sys_ctrl0 = wen & (addr[31:0] == 00000010) ? {5{1'b1}} : {5{1'b0}};
wire [2-1:0] wen_test_reg = wen & (addr[31:0] == 0000001c) ? {2{1'b1}} : {2{1'b0}};

// Reg:   sys_ctrl0
// Field: pdc_use_arm_ctrl
// Type:  RW 
// Reset: 0
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     sys_ctrl0_pdc_use_arm_ctrl <= 1'h0;
  end begin
     if ( wen_sys_ctrl0[0] ) begin
        sys_ctrl0_pdc_use_arm_ctrl[1-1:0] <= pwdata[0:0];
     end
  end
end


// Reg:   sys_ctrl0
// Field: l2c_strip_mode
// Type:  RW 
// Reset: 0
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     sys_ctrl0_l2c_strip_mode <= 3'h0;
  end begin
     if ( wen_sys_ctrl0[1] ) begin
        sys_ctrl0_l2c_strip_mode[3-1:0] <= pwdata[3:1];
     end
  end
end


// Reg:   sys_ctrl0
// Field: smmu_mmusid
// Type:  RW 
// Reset: 3
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     sys_ctrl0_smmu_mmusid <= 5'h3;
  end begin
     if ( wen_sys_ctrl0[2] ) begin
        sys_ctrl0_smmu_mmusid[5-1:0] <= pwdata[8:4];
     end
  end
end


// Reg:   sys_ctrl0
// Field: mem_repair_en
// Type:  RW 
// Reset: 5
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     sys_ctrl0_mem_repair_en <= 1'h5;
  end begin
     if ( wen_sys_ctrl0[3] ) begin
        sys_ctrl0_mem_repair_en[1-1:0] <= pwdata[9:9];
     end
  end
end


// Reg:   sys_ctrl0
// Field: mem_repair_done
// Type:  RO 
// Reset: 7
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     sys_ctrl0_mem_repair_done <= 7'h7;
  end begin
     if ( wen_sys_ctrl0[4] ) begin
        sys_ctrl0_mem_repair_done <= sys_ctrl0_mem_repair_done;
        $display("%m @%t: Error writing Read-Only field of sys_ctrl0_mem_repair_done !");
     end
  end
end


// Reg:   test_reg
// Field: test_field0
// Type:  RW 
// Reset: 0
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     test_reg_test_field0 <= 4'h0;
  end begin
     if ( wen_test_reg[0] ) begin
        test_reg_test_field0[4-1:0] <= pwdata[3:0];
     end
  end
end


// Reg:   test_reg
// Field: test_filed1
// Type:  WO 
// Reset: 3
always @(negedge preset or posedge pclk) begin
  if (!preset) begin
     test_reg_test_filed1 <= 2'h3;
  end begin
     if ( wen_test_reg[1] ) begin
        test_reg_test_filed1[2-1:0] <= pwdata[5:4];
     end
  end
end

always @(*) begin
   rdata_sel = 32'h00000000;
   if (!pwrite & psel ) begin
      case (addr) 
        32'h00000010: begin
           rdata_sel[0:0] = sys_ctrl0_pdc_use_arm_ctrl[0:0]; //Control if use arm ctrl-seq HIGH enable  
           rdata_sel[3:1] = sys_ctrl0_l2c_strip_mode[2:0]; //Control L2 cache stripping mode HIGH enable  
           rdata_sel[8:4] = sys_ctrl0_smmu_mmusid[4:0]; //
           rdata_sel[9:9] = sys_ctrl0_mem_repair_en[0:0]; //
           rdata_sel[16:10] = sys_ctrl0_mem_repair_done[6:0]; //
        end
        32'h0000001c: begin
           rdata_sel[3:0] = test_reg_test_field0[3:0]; //This test comments
           rdata_sel[5:4] = 1'hxxxxxxxx; //X out for WriteOnly field: test_reg_test_filed1[1:0]; //
        end
         default: begin
            rdata_sel = 32'h00000000;
         end
    endcase
  end
end

endmodule
