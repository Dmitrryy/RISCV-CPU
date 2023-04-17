`include "CONSTANT.v"


module DECODER (
    input [31:0] instr,
    
    output [4:0]rs1_id,
    output [4:0]rs2_id,
    output [4:0]rd_id,
    output [31:0] imm32,
    output [2:0] mem_width,

    // control unit out
    output reg [3:0] ALU_op,
    output reg MemToReg, MemWrite,
    // ALUSrc1:
    // 0 - rs1
    // 1 - pc
    // ALUSrc2:
    // 00 - rs2
    // 01 - imm
    // 11 - 4
    output reg ALUSrc1, 
    output reg [1:0] ALUSrc2,
    output reg /*RegDst,*/ RegWrite,
    output reg Branch, InvertBranchTriger,
    // NextPC:
    // 00 - pc + 4
    // 01 - pc + imm
    // 11 - rs1 + imm
    output logic [1:0] NextPC
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
assign mem_width = funct3;

// opcodes
assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

//immediates calculations 
//=--------------------------------------------------------
wire [31:0] i_imm_32, s_imm_32, b_imm_32, u_imm_32, j_imm_32, shamt_32;
assign i_imm_32 = { {20{instr[31]}}, instr[31:20]}; // I-type
assign s_imm_32 = { {20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
assign b_imm_32 = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; //B-type
assign u_imm_32 = { instr[31:12], 12'b000000000000}; // U-type
assign j_imm_32 = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type 

assign shamt_32 = {27'b000000000000000000000000000, instr[24:20]};

assign imm32 =  (opcode == I_TYPE && funct3 == 3'b001)? shamt_32:  //SLLI
                (opcode == I_TYPE && funct3 == 3'b101)? shamt_32:  //SRLI
                (opcode == I_TYPE)? i_imm_32:  //I-type
                (opcode == LOAD  )? i_imm_32:  //Load
                (opcode == STORE )? s_imm_32:  //S-type
                (opcode == BRANCH)? b_imm_32:  //Branches
                (opcode == JAL   )? j_imm_32:  //JAL
                (opcode == JALR  )? i_imm_32:  //JALR
                (opcode == AUIPC )? u_imm_32:  //Auipc
                (opcode == LUI   )? u_imm_32:  //Lui
                0;  //default 

// control unit
//=--------------------------------------------------------
always @(*) begin
    case(opcode)
        R_TYPE: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b00;
            Branch = 0;
            RegWrite = 1;
            NextPC = 2'b00; // pc + 4
            if (funct3 == 3'b000) begin 
                if (funct7 == 7'b0000000) begin 
                    ALU_op = `ALU_ADD;
                end else begin 
                    ALU_op = `ALU_SUB;
                end 
            end else if (funct3 == 3'b010) begin 
                ALU_op = `ALU_SLT;
            end else if (funct3 == 3'b100) begin 
                ALU_op = `ALU_XOR;
            end else if (funct3 == 3'b111) begin 
                ALU_op = `ALU_AND;
            end else if (funct3 == 3'b001) begin
                ALU_op = `ALU_SHL;
            end else if (funct3 == 3'b011) begin
                ALU_op = `ALU_SLTU;
            end else if (funct3 == 3'b110) begin
                ALU_op = `ALU_OR;
            end else if (funct3 == 3'b101) begin
                if (funct7 == 7'b0000000) begin
                    ALU_op = `ALU_SHR;
                end else begin 
                    ALU_op = `ALU_SHA;
                end 
            end 
        end
        I_TYPE: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            Branch = 0;
            RegWrite = 1;
            NextPC = 2'b00; // pc + 4
            if (funct3 == 3'b000) begin
                ALU_op = `ALU_ADD; //addi 
            end else if (funct3 == 3'b001) begin
                ALU_op = `ALU_SHL; //slli
            end else if (funct3 == 3'b010) begin
                ALU_op = `ALU_SLT; //slti
            end else if (funct3 == 3'b011) begin
                ALU_op = `ALU_SLTU; //sltiu
            end else if (funct3 == 3'b100) begin 
                ALU_op = `ALU_XOR; //xori
            end else if (funct3 == 3'b101) begin 
                if (funct7 == 7'b0000000) begin 
                    ALU_op = `ALU_SHR; //srli
                end else begin 
                    ALU_op = `ALU_SHA; //srai
                end
            end else if (funct3 == 3'b110) begin
                ALU_op = `ALU_OR; //ori
            end else if (funct3 == 3'b111) begin 
                ALU_op = `ALU_AND; //andi
            end
        end
        STORE: begin
            MemToReg = 0;
            MemWrite = 1;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            Branch = 0;
            RegWrite = 0;
            NextPC = 2'b00; // pc + 4
            ALU_op = `ALU_ADD;
        end
        LOAD: begin
            MemToReg = 1;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            Branch = 0;
            RegWrite = 1;
            NextPC = 2'b00; // pc + 4
            ALU_op = `ALU_ADD;
        end
        BRANCH: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b00; // rs2
            Branch = 1;
            RegWrite = 0;
            NextPC = 2'b01; // pc + imm
            if (funct3 == 3'b000) begin 
                ALU_op = `ALU_SUB; //beq
                InvertBranchTriger = 1;
            end else if (funct3 == 3'b001) begin 
                ALU_op = `ALU_SUB; //bne
                InvertBranchTriger = 0;
            end else if (funct3 == 3'b100) begin 
                ALU_op = `ALU_SLT; //blt
                InvertBranchTriger = 0;
            end else if (funct3 == 3'b101) begin 
                ALU_op = `ALU_SLT; //bge
                InvertBranchTriger = 1;
            end else if (funct3 == 3'b110) begin 
                ALU_op = `ALU_SLTU; //bltu
                InvertBranchTriger = 0;
            end else if (funct3 == 3'b111) begin 
                ALU_op = `ALU_SLTU; //bgeu
                InvertBranchTriger = 1;
            end
        end
        JALR: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b11; // 4
            Branch = 1;
            RegWrite = 1;
            // next pc is rs1 + imm
            NextPC = 2'b11;
        end
        JAL: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b11; // 4
            Branch = 1;
            RegWrite = 1;
            // next pc is pc + imm
            NextPC = 2'b01;
        end
        AUIPC: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b01; // imm
            ALU_op = `ALU_ADD;
            Branch = 0;
            RegWrite = 1;
            NextPC = 2'b00; // pc + 4
        end
        LUI: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            ALU_op = `ALU_B;
            Branch = 0;
            RegWrite = 1;
            NextPC = 2'b00; // pc + 4
        end
        default: $display("Unsapported instraction type");
    endcase
end

endmodule
