module BranchCmp (
    input is_br,
    input  is_j,
    input [2:0] cmp_op,
    input signed [31:0] rs1,rs2,
    output reg pc_sel
);
// 0 beq
// 1 bne
// 2 blt
// 3 bge
// 4 bltu
// 5 bgeu

// pc_sel=0: pc_p4
// pc_sel=1: ALU_out

always @(*)begin
    case(cmp_op)
        3'b000: pc_sel = (is_br & (rs1 == rs2)) | is_j; // beq
        3'b001: pc_sel = (is_br & (rs1 != rs2)) | is_j; // bne
        3'b010: pc_sel = (is_br & (rs1 < rs2)) | is_j; // blt
        3'b011: pc_sel = (is_br & (rs1 >= rs2)) | is_j; // bge
        3'b100: pc_sel = (is_br & ($unsigned(rs1) < $unsigned(rs2))) | is_j; // bltu
        3'b101: pc_sel = (is_br & ($unsigned(rs1) >= $unsigned(rs2))) | is_j; // bgeu
        default: pc_sel = 0; // default case
    endcase
end

endmodule
