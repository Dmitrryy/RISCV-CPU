
module RV32(
    input clk,
    input rst,

    output Exception, valid_out,
    output logic [31:0] pc_out, imm_out,
    output logic [4:0] rs1n_out, rs2n_out, rdn_out
);
// hazard unit
//=--------------------------------------------------------
// RAW register hazard
//   inputs
wire RegWrite_MEM, RegWrite_WB;
wire [4:0] rs1n_EX, rs2n_EX, rdn_MEM, rdn_WB;
//   outputs
wire [1:0] ForwardSrc1_EX, ForwardSrc2_EX;
// Data hazard with stall
//   inputs
wire MemToReg_EX;
wire [4:0] rs1n_ID, rs2n_ID, rdn_EX;
//   outputs
wire Flush_EX, Stall_ID, Stall_IF;
// Branch control hazard
wire BranchIsTaken_EX;
// exception command (ecall, fence ...)
wire Exception_WB;
assign Exception = Exception_WB;

HAZARD hazard(
RegWrite_MEM, RegWrite_WB, rs1n_EX, rs2n_EX, rdn_MEM, rdn_WB, 
ForwardSrc1_EX, ForwardSrc2_EX,

MemToReg_EX, rs1n_ID, rs2n_ID, rdn_EX,
Flush_EX, Stall_ID, Stall_IF
);

// instruction fetch
//=--------------------------------------------------------
wire [31:0] pc_IF;
wire [31:0] pc_EX;
// signals from ex
wire [31:0] imm32_EX, rs1_val_EX;
wire [1:0] NextPC_EX;
wire [1:0] TakenNextPC_EX = (BranchIsTaken_EX) ? NextPC_EX : 2'b00;
wire PCEn = !Stall_IF & !Exception_WB;
RegPC pc_module(clk, PCEn, TakenNextPC_EX, pc_EX, imm32_EX, rs1_val_EX, pc_IF);

wire [31:0] instr_IF;
MEM #(.N(17), .DW(32)) imem(clk, pc_IF >> 2, 3'b010 /*32w*/, 0/*we*/, 0, instr_IF);

wire [31:0] pc_ID, instr_ID;
wire Enable_ID = !Stall_ID & !Exception_WB;
wire rst_ID = rst | BranchIsTaken_EX;
RegPipe #(.W(64)) fence_ID(clk, rst_ID, Enable_ID, 
{pc_IF, instr_IF}, 
{pc_ID, instr_ID}
);

// instruction decode
//=--------------------------------------------------------
// signal from WB
wire[31:0] Result_WB;
// decoded info
wire [4:0] rdn_ID;
wire [31:0] rs1_val_ID, rs2_val_ID, imm32_ID;
wire [3:0] alu_op_ID;
wire [2:0] mem_width_ID;
wire MemToReg_ID, MemWrite_ID, ALUSrc1_ID, RegWrite_ID, Branch_ID, InvertBranchTriger_ID, Jump_ID, Exception_ID, valid_ID;
wire[1:0] ALUSrc2_ID, NextPC_ID;
DECODER decoder(instr_ID, 
    rs1n_ID, rs2n_ID, rdn_ID, imm32_ID, // decoded instruction
    mem_width_ID ,alu_op_ID, 
    MemToReg_ID, MemWrite_ID, ALUSrc1_ID, ALUSrc2_ID, RegWrite_ID, Branch_ID, InvertBranchTriger_ID, Jump_ID, NextPC_ID,
    Exception_ID, valid_ID
);
RGF reg_file(clk, rs1n_ID, rs2n_ID, RegWrite_WB, rdn_WB, Result_WB, //input
    rs1_val_ID, rs2_val_ID // out
);
// pipe register
wire [2:0] mem_width_EX;
wire [3:0] alu_op_EX;
wire [31:0] rs2_val_EX;
wire MemWrite_EX, ALUSrc1_EX, RegWrite_EX, Branch_EX, InvertBranchTriger_EX
, Jump_EX, Exception_EX, valid_EX;
wire [1:0] ALUSrc2_EX;

wire PipeRegRst_EX = rst | Flush_EX | BranchIsTaken_EX;
wire PipeRegEn_EX = !Exception_WB;
RegPipe #(.W(150)) fence_ex_vals(clk, PipeRegRst_EX, PipeRegEn_EX, 
    {pc_ID, rs1_val_ID, rs2_val_ID, imm32_ID, rs1n_ID, rs2n_ID, rdn_ID, alu_op_ID, mem_width_ID}, 
    {pc_EX, rs1_val_EX, rs2_val_EX, imm32_EX, rs1n_EX, rs2n_EX, rdn_EX, alu_op_EX, mem_width_EX}
);
RegPipe #(.W(13)) fence_ex_flags(clk, PipeRegRst_EX, PipeRegEn_EX,
    {MemToReg_ID, MemWrite_ID, ALUSrc1_ID, ALUSrc2_ID, RegWrite_ID, Branch_ID, InvertBranchTriger_ID, Jump_ID, NextPC_ID, Exception_ID, valid_ID},
    {MemToReg_EX, MemWrite_EX, ALUSrc1_EX, ALUSrc2_EX, RegWrite_EX, Branch_EX, InvertBranchTriger_EX, Jump_EX, NextPC_EX, Exception_EX, valid_EX}
);

// execution
//=--------------------------------------------------------
// forwarding registers
wire [31:0] rs1_val_forwarded_EX = (ForwardSrc1_EX[1:1]) ? ALUOut_MEM : ((ForwardSrc1_EX[0:0]) ? Result_WB : rs1_val_EX);
wire [31:0] rs2_val_forwarded_EX = (ForwardSrc2_EX[1:1]) ? ALUOut_MEM : ((ForwardSrc2_EX[0:0]) ? Result_WB : rs2_val_EX);

wire[31:0] ALUSrc1_val_EX = (ALUSrc1_EX) ? pc_EX : rs1_val_forwarded_EX;
wire[31:0] ALUSrc2_val_EX = (ALUSrc2_EX == 2'b00) ? rs2_val_forwarded_EX : ((ALUSrc2_EX == 2'b01) ? imm32_EX : 4); 
wire[31:0] ALUOut_EX;
wire ALUZero_EX;
ALU alu(ALUSrc1_val_EX, ALUSrc2_val_EX, alu_op_EX, ALUOut_EX, ALUZero_EX);
// branch logic
assign BranchIsTaken_EX = (Jump_EX) || (Branch_EX && (InvertBranchTriger_EX ^ (ALUOut_EX != 0)));

// EX to MEM pipe register
wire [31:0] pc_MEM, ALUOut_MEM, MemWriteData_MEM;
wire [2:0] mem_width_MEM;
wire MemToReg_MEM, MemWrite_MEM, Exception_MEM, valid_MEM;
wire PipeRegRst_MEM = rst;
wire PipeRegEn_MEM = !Exception_WB;
RegPipe #(.W(96)) fence_mem_values(clk, PipeRegRst_MEM, PipeRegEn_MEM, 
{pc_EX , ALUOut_EX , rs2_val_forwarded_EX}, 
{pc_MEM, ALUOut_MEM, MemWriteData_MEM    }
);
RegPipe #(.W(13)) fence_mem_flags(clk, PipeRegRst_MEM, PipeRegEn_MEM,
{mem_width_EX , MemToReg_EX , MemWrite_EX , RegWrite_EX , rdn_EX , Exception_EX , valid_EX },
{mem_width_MEM, MemToReg_MEM, MemWrite_MEM, RegWrite_MEM, rdn_MEM, Exception_MEM, valid_MEM}
);
wire[31:0] imm32_MEM;
wire [4:0] rs1n_MEM, rs2n_MEM;
RegPipe #(.W(42)) debug_pipe_MEM(clk, PipeRegRst_MEM, PipeRegEn_MEM,
{imm32_EX , rs1n_EX , rs2n_EX },
{imm32_MEM, rs1n_MEM, rs2n_MEM}
);

// memory
//=--------------------------------------------------------
wire[31:0] ReadData_MEM;
MEM #(.N(17), .DW(32)) dmem(clk, ALUOut_MEM >> 2 , mem_width_MEM, MemWrite_MEM, MemWriteData_MEM, ReadData_MEM);

// MEM to WB pipe register
wire[31:0] ReadData_WB, ALUOut_WB;
wire MemToReg_WB, valid_WB;
wire PipeRegRst_WB = rst;
wire PipeRegEn_WB = !Exception_WB;
RegPipe #(.W(64)) fence_wb_vals(clk, PipeRegRst_WB, PipeRegEn_WB, 
{ReadData_MEM, ALUOut_MEM}, 
{ReadData_WB , ALUOut_WB });
RegPipe #(.W(9)) fence_wb_flags(clk, PipeRegRst_WB, PipeRegEn_WB, 
{RegWrite_MEM, MemToReg_MEM, rdn_MEM, Exception_MEM, valid_MEM}, 
{RegWrite_WB , MemToReg_WB , rdn_WB , Exception_WB , valid_WB });
// debug info pipe
wire[31:0] imm32_WB, pc_WB;
wire [4:0] rs1n_WB, rs2n_WB;
RegPipe #(.W(74)) debug_pipe_WB(clk, PipeRegRst_WB, PipeRegEn_WB,
{pc_MEM, imm32_MEM, rs1n_MEM, rs2n_MEM},
{pc_WB , imm32_WB , rs1n_WB , rs2n_WB}
);

assign pc_out = pc_WB;
assign rs1n_out = rs1n_WB;
assign rs2n_out = rs2n_WB;
assign rdn_out = rdn_WB;
assign imm_out = imm32_WB;
assign valid_out = valid_WB;

// write back
//=--------------------------------------------------------
assign Result_WB = (MemToReg_WB) ? ReadData_WB : ALUOut_WB;


endmodule
