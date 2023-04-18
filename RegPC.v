
module RegPC(
    input clk,
    input en,
    // NextPC:
    // 00 - pc_IF + 4
    // 01 - pc_EX + imm
    // 11 - rs1 + imm
    input[1:0] NextPC,
    input[31:0] pc_EX,
    input[31:0] imm,
    input[31:0] rs1,

    output[31:0] PCOut
);
reg [31:0] pc /*verilator public*/;
assign PCOut = pc;

wire [31:0] pc_src1 = (NextPC == 2'b00) ? pc : ((NextPC == 2'b01) ? pc_EX : rs1);
wire [31:0] pc_src2 = (NextPC[0:0]) ? imm : 4;
always @(posedge clk) begin
    if (en) begin
        pc <= pc_src1 + pc_src2;
    end
end

endmodule