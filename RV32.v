
module RV32(
    input clk,
    input rst,

    // todo: vobl hazard
    input StallIF,
    input StallID,
    input EnableID,
    input FlushE,

    // todo: vobl
    input [31:0] instr,
    output [31:0] pc_out
);

// instruction fetch
//=--------------------------------------------------------
reg [31:0] pc;
wire [31:0] nextpc;
RegPipe #(.W(32)) fence_pc(clk, rst, !StallIF, pc, nextpc);

wire [31:0] fetched_instr;
MEM #(.N(12), .DW(32)) imem(clk, nextpc, 3'b010 /*32w*/, 0/*we*/, 0, fetched_instr);
wire [31:0] pc_ID, instr_ID;
RegPipe #(.W(64)) fence_ID(clk, rst, (!StallID) & EnableID, {nextpc, fetched_instr}, {pc_ID, instr_ID});

// instruction decode
//=--------------------------------------------------------
wire [4:0]rs1n_ID, rs2n_ID, rdn_ID;
wire [31:0]rs1_val_ID, rs2_val_ID, imm32_ID;
wire [3:0] alu_op_ID;
wire [2:0] mem_width_ID;
wire MemToReg_ID, MemWrite_ID, ALUSrc1_ID, RegWrite_ID, Branch_ID, InvertBranchTriger_ID;
wire[1:0] ALUSrc2_ID, NextPC_ID;
DECODER decoder(instr_ID, 
    rs1n_ID, rs2n_ID, rdn_ID, imm32_ID, // decoded instruction
    mem_width_ID ,alu_op_ID, 
    MemToReg_ID, MemWrite_ID, ALUSrc1_ID, ALUSrc2_ID, RegWrite_ID, Branch_ID, InvertBranchTriger_ID, NextPC_ID
);
//                                 TODO: WB!!
RGF reg_file(clk, rs1n_ID, rs2n_ID, 0, 0, 0, //input
    rs1_val_ID, rs2_val_ID // out
);
// pipe register
wire [4:0] rs1n_EX, rs2n_EX, rdn_EX;
wire [2:0] mem_width_EX;
wire [3:0] alu_op_EX;
wire [31:0] pc_EX;
wire [31:0] rs1_val_EX, rs2_val_EX, imm32_EX;
wire MemToReg_EX, MemWrite_EX, ALUSrc1_EX, RegWrite_EX, Branch_EX, InvertBranchTriger_EX;
wire [1:0] ALUSrc2_EX, NextPC_EX;

wire PipeRegRst_EX = rst || FlushE;
wire PipeRegEn_EX = 1;
RegPipe #(.W(150)) fence_ex_vals(clk, PipeRegRst_EX, PipeRegEn_EX, 
    {pc_ID, rs1_val_ID, rs2_val_ID, imm32_ID, rs1n_ID, rs2n_ID, rdn_ID, alu_op_ID, mem_width_ID}, 
    {pc_EX, rs1_val_EX, rs2_val_EX, imm32_EX, rs1n_EX, rs2n_EX, rdn_EX, alu_op_EX, mem_width_EX}
);
RegPipe #(.W(10)) fence_ex_flags(clk, PipeRegRst_EX, PipeRegEn_EX,
    {MemToReg_ID, MemWrite_ID, ALUSrc1_ID, ALUSrc2_ID, RegWrite_ID, Branch_ID, InvertBranchTriger_ID, NextPC_ID},
    {MemToReg_EX, MemWrite_EX, ALUSrc1_EX, ALUSrc2_EX, RegWrite_EX, Branch_EX, InvertBranchTriger_EX, NextPC_EX}
);

// execution
//=--------------------------------------------------------
wire [31:0] pc_mem;
RegPipe #(.W(32)) fence_mem(clk, rst, 1, pc_EX, pc_mem);

// memory
//=--------------------------------------------------------
wire [31:0] pc_wb;
RegPipe #(.W(32)) fence_wb(clk, rst, 1, pc_mem, pc_wb);

// write back
//=--------------------------------------------------------

assign pc_out = pc_wb;

always @(*) begin
     pc = nextpc + 4;
end

endmodule
