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

endmodule
