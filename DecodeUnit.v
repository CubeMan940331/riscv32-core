
module DecodeUnit(
    input  [31:0]   inst_i,
    input           is_fpu_i,
    
    output [6:0]    opcode,
    output [2:0]    funct3,
    output [6:0]    funct7,
    
    output [4:0]    rs1,
    output [4:0]    rs2,
    output [4:0]    rs3,
    output [4:0]    rd,

    output reg signed [31:0]   imm,

    output [11:0]   csr_addr_o
);

parameter CSR_FRM = 12'h002;

assign opcode = inst_i[6:0];
assign funct3 = inst_i[14:12];
assign funct7 = inst_i[31:25];

assign rs1 = inst_i[19:15];
assign rs2 = inst_i[24:20];
assign rs3 = inst_i[31:27];
assign rd  = inst_i[11:07];

always @(*)begin
    case(opcode)
        7'b0010011, // I ADDI SLLI SLTI SLTIU XORI SRLI SRAI ORI ANDI
        7'b0000011, // I LB LH LW LBU LHU
        7'b0000111, // I FLW FLD
        7'b1100111: // JALR
            // {imm[31:20]}
            imm = {{20{inst_i[31]}}, inst_i[31:20]}; 
        7'b1110011: // CSR
            // {zero imm[24:20]}
            imm = {27'b0, inst_i[19:15]}; 
        7'b0100011, // S SB SH SW
        7'b0100111: // S FSW FSD
            // {imm[11:5], imm[4:0]}
            imm = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};

        7'b1100011: // B BEQ BNE BLT BGE BLTU BGEU
            // {imm[12], imm[10:5], imm[4:1], 0}
            imm = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};

        7'b1101111: // J JAL
            // {imm[20], imm[10:1], imm[11], imm[19:12], 0}
            imm = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};

        7'b0110111, // U LUI
        7'b0010111: // U AUIPC
            // {imm[31:12]}
            imm={inst_i[31:12], 12'b0};
        default:
            imm = 32'b0;
    endcase
end

always@(*)begin
    csr_addr_o = inst_i[31:20];
    if(is_fpu_i) csr_addr_o = CSR_FRM;
end

endmodule
