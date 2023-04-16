
`include "CONSTANT.v"

module ALU(input [31:0] a,b,
           input [3:0] ALUop,
           output reg[31:0] ALUOut,
           output reg zero
);
always @(*) begin 
  case (ALUop)
    `ALU_ADD: ALUOut=a+b;
    `ALU_SUB: ALUOut=a-b;
    `ALU_AND: ALUOut=a&b;
    `ALU_OR: ALUOut=a|b;
    `ALU_XOR: ALUOut=a^b;
    //left shift logical
    `ALU_SHL: ALUOut=a<<b[4:0];
    //right shift logical
    `ALU_SHR: ALUOut=a>>b[4:0];
    //arithmetic right shift
    `ALU_SHA: ALUOut=$signed(a)>>>$signed(b[4:0]);
    //set less than
    `ALU_SLT: ALUOut=$signed(a) < $signed(b)? 32'b1:32'b0;
    //set less than unsigned
    `ALU_SLTU: ALUOut=a < b ? 32'b1:32'b0;
    `ALU_A: ALUOut = a;
    `AKU_B: ALUOut = b;
    //by default do nothing
    default: ;
   endcase 
   zero = (ALUOut == 0);
   //over<=0;
end
endmodule

