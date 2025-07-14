module BranchCmp (
    input is_br,
    input  is_j,
    input [2:0] cmp_op,
    input signed [31:0] reg_rd_data1,
    input signed [31:0] reg_rd_data2,
    output reg br_taken
);
// 0 beq
// 1 bne
// 2 blt
// 3 bge
// 4 bltu
// 5 bgeu

// br_taken=0: pc_p4
// br_taken=1: ALU_out

always @(*)begin
    case(cmp_op)
        3'b000: br_taken = (is_br & (reg_rd_data1 == reg_rd_data2)) | is_j; // beq
        3'b001: br_taken = (is_br & (reg_rd_data1 != reg_rd_data2)) | is_j; // bne
        3'b010: br_taken = (is_br & (reg_rd_data1 < reg_rd_data2)) | is_j; // blt
        3'b011: br_taken = (is_br & (reg_rd_data1 >= reg_rd_data2)) | is_j; // bge
        3'b100: br_taken = (is_br & ($unsigned(reg_rd_data1) < $unsigned(reg_rd_data2))) | is_j; // bltu
        3'b101: br_taken = (is_br & ($unsigned(reg_rd_data1) >= $unsigned(reg_rd_data2))) | is_j; // bgeu
        default: br_taken = 0; // default case
    endcase
end

endmodule
