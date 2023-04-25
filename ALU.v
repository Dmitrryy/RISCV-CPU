
`include "CONSTANT.v"

module ALU(input [31:0] a,b,
           input [3:0] ALUop,
           output reg[31:0] ALUOut,
           output reg zero
);
always @(*) begin 
  case (ALUop)
    `ALU_ADD:  ALUOut = a + b;
    `ALU_SUB:  ALUOut = a - b;
    `ALU_AND:  ALUOut = a & b;
    `ALU_OR:   ALUOut = a | b;
    `ALU_XOR:  ALUOut = a ^ b;
    `ALU_SHL:  ALUOut = a << b[4:0];
    `ALU_SHR:  ALUOut = a >> b[4:0];
    `ALU_SHA:  ALUOut = $signed(a)>>>$signed(b[4:0]);
    `ALU_SLT:  ALUOut = {{31{1'b0}}, $signed(a) < $signed(b)};
    `ALU_SLTU: ALUOut = {{31{1'b0}} , a < b};
    `ALU_A:    ALUOut = a;
    `ALU_B:    ALUOut = b;
    //by default do nothing
    default: ;
   endcase 
   zero = (ALUOut == 0);
   //over<=0;
end
endmodule

