
module reg_PC (
    input clk,
    input StallIF,
    input [31:0] NewPC,

    output [31:0] OutPC
);
reg [31:0] pc;
assign OutPC = pc;

always @(posedge clk) begin
    if (!StallIF)
        pc <= NewPC;
end
endmodule


module reg_ID (
    input clk,
    input StallID,
    input en,

    input [31:0] NewPC,
    input [31:0] NewInstr,

    output [31:0] OutPC,
    output [31:0] OutInstr
);
reg [31:0] saved_pc;
reg [31:0] decoded_instr;
assign OutPC = saved_pc;
assign OutInstr = decoded_instr;

always @(posedge clk) begin
    if (!StallID && en) begin
        saved_pc <= NewPC;
        decoded_instr <= NewInstr;
    end
end
endmodule

module reg_EX (
    input clk,
    input FlushE,

    input [31:0] NewDATA,
    output [31:0] OutDATA
);
reg [31:0] saved_ex;
assign OutDATA = saved_ex;

always @(posedge clk) begin
    if (!FlushE) begin
        saved_ex <= NewDATA;
    end else begin
        saved_ex <= 0;        
    end
end
endmodule

module reg_MEM (
    input clk,
    input [31:0] NewDATA,
    output [31:0] OutDATA
);
reg [31:0] saved_mem;
assign OutDATA = saved_mem;

always @(posedge clk) begin
    saved_mem <= NewDATA;
end
endmodule

module reg_WB (
    input clk,
    input [31:0] NewDATA,
    output [31:0] OutDATA
);
reg [31:0] saved_wb;
assign OutDATA = saved_wb;

always @(posedge clk) begin
    saved_wb <= NewDATA;
end
endmodule

// modeling pipeline
module pipeline (
    input clk,
    input StallIF,
    input StallID,
    input EnableID,
    input FlushE,

    // todo: vobl
    input [31:0] instr,
    output [31:0] pc_out
);

reg [31:0] pc;
wire [31:0] nextpc;
reg_PC fence_pc(clk, StallIF, pc + 4, nextpc);

wire [31:0] pc_id, instr_id;
reg_ID fence_id(clk, StallID, EnableID, nextpc, instr, pc_id, instr_id);

wire [31:0] pc_e;
reg_EX fence_ex(clk, FlushE, pc_id, pc_e);

wire [31:0] pc_mem;
reg_MEM fence_mem(clk, pc_e, pc_mem);

wire [31:0] pc_wb;
reg_WB fence_wb(clk, pc_mem, pc_wb);

assign pc_out = pc_wb;

always @(*) begin
     pc = nextpc;
end

endmodule
