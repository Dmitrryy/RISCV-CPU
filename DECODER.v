

module DECODER (
    input [31:0] instr,
    
    output [4:0]rs1_id,
    output [4:0]rs2_id,
    output [4:0]rd_id,
    output [31:0] imm32,

    output [3:0] alu_op,

    output memtoreg, memwrite,
    output pcsrc, alusrc,
    output regdst, regwrite,
    output jump,
);

localparam [6:0]R_TYPE  = 7'b0110011,
                I_TYPE  = 7'b0010011,
                STORE   = 7'b0100011,
                LOAD    = 7'b0000011,
                BRANCH  = 7'b1100011,
                JALR    = 7'b1100111,
                JAL     = 7'b1101111,
                AUIPC   = 7'b0010111,
                LUI     = 7'b0110111;

wire [6:0] opcode;
wire [6:0] funct7;
wire [2:0] funct3;


// Read registers
assign rs1_id  = instr[19:15];
assign rs2_id  = instr[24:20];
assign rd_id = instr[11:7];

// opcodes
assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

//immediates calculations 
assign i_imm_32 = { {20{instr[31]}}, instr[31:20]}; // I-type
assign s_imm_32 = { {20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
assign b_imm_32 = { {19{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; //B-type
assign u_imm_32 = { instr[31:12], 12'b000000000000}; // U-type
assign j_imm_32 = { {11{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type 

assign shamt_32 = {27'b000000000000000000000000000, instr[24:20]};

assign imm32 =  (opcode == 7'b0010011 && funct3 == 3'b001)? shamt_32:  //SLLI
				(opcode == 7'b0010011 && funct3 == 3'b101)? shamt_32:  //SRLI
				(opcode == 7'b0010011)? i_imm_32:  //I-type
				(opcode == 7'b0000011)? i_imm_32:  //Load
				(opcode == 7'b0100011)? s_imm_32:  //S-type
				(opcode == 7'b1100011)? b_imm_32:  //Branches
				(opcode == 7'b1101111)? j_imm_32:  //JAL
				(opcode == 7'b1100111)? i_imm_32:  //JALR
				(opcode == 7'b0010111)? u_imm_32:  //Auipc
				(opcode == 7'b0110111)? u_imm_32:  //Lui
				0;  //default 

endmodule
