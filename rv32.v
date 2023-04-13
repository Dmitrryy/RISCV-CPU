
module rv32(input clk, input[31:0] pc, input [2:0]w, input we, output [31:0] c, output[31:0] alu_c);

//reg [31:0] pc = 0;

// [0:31] - fetced instr
// [63:32] - pc
// [64:64] - is valid
//reg [64:0] FE_DE = 0;
//reg [64:0] DE_EX = 0;
//reg [64:0] EX_MEM = 0;
//reg [64:0] MEM_WB = 0;


MEM instr_mem(.i_clk(clk), .addr(pc), .width(w), .we(we), .data(pc), .out_data(c));

always @(negedge clk)
begin
    //pc <= pc + 4;
end

always @(posedge clk)
begin
    
end



reg [31:0] b  = 5 ;
reg [3:0] op = {1'b0,1'b0,1'b0,clk};
/* verilator lint_off UNUSED */
reg over = 0;


ALU alu_1(.clk(clk), .a(pc), .b(b), .ALUop(op), .ALUOut(alu_c), .over(over));


endmodule