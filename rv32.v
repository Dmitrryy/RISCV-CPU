

module REG_PIPE
#(parameter width = 32) (
input clk, reset, stall,
input [width-1 : 0]     valIn,
output reg [width-1 :0] valOut
);
always @(posedge clk)
begin
    if(reset)
        valOut <= 0;
    else begin
        valOut <= (stall) ? valOut : valIn;
    end
end
endmodule // Reg


module rv32(input clk, output reg [31:0] c, output reg [31:0] v_pc, output reg valid, output[31:0] alu_c);

// public for initialize
reg [31:0] pc /*verilator public*/;

// [31:0] - fetced instr
// [63:32] - pc
// [64:64] - is valid
reg [64:0] FE_DE = 0;
wire FE_DE_v = FE_DE[64:64];
wire [31:0]FE_DE_pc = FE_DE[63:32];
wire [31:0]FE_DE_inst = FE_DE[31:0];

// [31:0] - rs1 val
// [63:32] - rs2 val
// [95:64] - imm val
// [99:96] - reg # to WB
// [131:100] - pc
// [135:132] - alu op
// [136:136] - is valid
reg [136:0] DE_EX = 0;


//reg [64:0] EX_MEM = 0;
//reg [64:0] MEM_WB = 0;

// fetch
//=--------------------------------------------------------
wire [31:0] fetched_instr;
wire fetch_v;
MEM instr_mem(.i_clk(clk), .addr(pc >> 2), .width(3'b000), .we(0), .data(pc), .out_data(fetched_instr), .valid(fetch_v));
REG_PIPE #(width = 65) fe_de_fence(.clk(clk), .reset(0), .stall(!fetch_v), .valIn({1, pc, fetched_instr}), .valOut(FE_DE));

// decode
//=--------------------------------------------------------
wire [4:0] rs1_id, rs2_id, rd_id;
wire [3:0] alu_op;
wire [31:0] imm32, rs1, rs2;
DECODER DE_module(.instr(FE_DE_inst), .rs1_id(rs1_id), .rs2_id(rs2_id), .rd_id(rd_id), .imm32(imm32), .alu_op(alu_op));
// TODO .we(WB_A3), .data(WB_RES)
RGF RegFile(.clk(clk), .rn1(rs1_id), .rn2(rs2_id), .we(0), .wn(rd_id), .data(0), .val1(rs1), .val2(rs2));
REG_PIPE #(width = 133) fe_de_fence(.clk(clk), .reset(0), .stall(0), .valIn({1, alu_op, FE_DE[63:32], rd_id, imm32, rs2, rs1}), .valOut(DE_EX));


// execution
//=--------------------------------------------------------
wire [31:0] alu_res;
wire alu_over;
ALU EX_alu(.clk(clk), .a(), .b(), .ALUop(DE_EX[135:132]), .ALUOut(alu_res), .over(alu_over));


always @(posedge clk)
begin
    // write fetch results
    if(!FE_DE_v && fetch_v) begin
        FE_DE = {1, pc, fetched_instr};
    end

    // DE results
    if(!DE_EX[132:132] && FE_DE[64:64]) begin
        DE_EX = {1, FE_DE[63:32], rd_id, imm32, rs2, rs1};
    end
end


always @(negedge clk)
begin
    pc <= pc + 4;
    c <= FE_DE_inst;
    v_pc <= FE_DE_pc;
    valid <= FE_DE_v;
end

reg [31:0] b  = 5 ;
reg [3:0] op = {1'b0,1'b0,1'b0,clk};
/* verilator lint_off UNUSED */
reg over = 0;


ALU alu_1(.clk(clk), .a(pc), .b(b), .ALUop(op), .ALUOut(alu_c), .over(over));


endmodule