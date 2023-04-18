
module RGF(
    input clk,
    input [4:0] rn1,
    input [4:0] rn2,
    input we, // write enable
    input [4:0] wn, // write reg
    input [31:0] data,

    output [31:0] val1, // read value of rn1
    output [31:0] val2  // read value of rn2
);

reg [31:0] registers [31:0] /*verilator public*/;

// read registers
assign val1 = (rn1 == 0) ? 0 : registers[rn1];
assign val2 = (rn2 == 0) ? 0 : registers[rn2];

// write to register wn
always @(negedge clk) begin
    if(we && wn !=0) begin
        registers[wn] <= data;
    end
end

endmodule
