module ImmGen (
    input [31:0] inst,
    output reg signed [31:0] imm
);

always @(*)begin
    case(inst[6:0])
        7'b0010011, // I ADDI SLLI SLTI SLTIU XORI SRLI SRAI ORI ANDI
        7'b0000011, // I LB LH LW LBU LHU
        7'b1100111: // JALR
            // {imm[31:20]}
            imm = {{20{inst[31]}}, inst[31:20]}; 

        7'b0100011: // S SB SH SW
            // {imm[11:5], imm[4:0]}
            imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

        7'b1100011: // B BEQ BNE BLT BGE BLTU BGEU
            // {imm[12], imm[10:5], imm[4:1], 0}
            imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};

        7'b1101111: // J JAL
            // {imm[20], imm[10:1], imm[11], imm[19:12], 0}
            imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

        7'b0110111, // U LUI
        7'b0010111: // U AUIPC
            // {imm[31:12]}
            imm={inst[31:12], 12'b0};
        default:
            imm = 32'b0;
    endcase
end

endmodule
