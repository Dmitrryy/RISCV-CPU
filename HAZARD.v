
module HAZARD(
    // RAW register hazard
    input RegWrite_MEM, RegWrite_WB,
    input[4:0] rs1n_EX,
    input[4:0] rs2n_EX,
    input[4:0] rdn_MEM,
    input[4:0] rdn_WB,
    //   10 - forward from MEM
    //   01 - forward from WB
    output logic[1:0] ForwardSrc1_EX, ForwardSrc2_EX,

    // Data hazard with stall
    input MemToReg_EX,
    input [4:0]rs1n_ID, rs2n_ID, rdn_EX,
    output Flush_EX, Stall_ID, Stall_IF

    // Branch control hazard
    
);
// RAW register hazard
//=--------------------------------------------------------
assign ForwardSrc1_EX = {2{(rs1n_EX != 0)}}
    & ((RegWrite_MEM & (rdn_MEM == rs1n_EX)) ? 2'b10 
    : ((RegWrite_WB & (rdn_WB == rs1n_EX)) ?  2'b01 : 2'b00 ));
assign ForwardSrc2_EX = {2{(rs2n_EX != 0)}} 
    & ((RegWrite_MEM & (rdn_MEM == rs2n_EX)) ? 2'b10 
    : ((RegWrite_WB & (rdn_WB == rs2n_EX)) ?  2'b01 : 2'b00 ));

// Data hazard with stall
//=--------------------------------------------------------
wire load_stall = MemToReg_EX & ((rs1n_ID == rdn_EX) || (rs2n_ID == rdn_EX));
assign Flush_EX = load_stall, Stall_ID = load_stall, Stall_IF = load_stall;


endmodule