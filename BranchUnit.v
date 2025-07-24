module BranchUnit (
    input is_br,
    input  is_j,
    input is_csr_br,
    
    input [2:0] cmp_op,
    input signed [31:0] reg_rd_data1,
    input signed [31:0] reg_rd_data2,
    
    output br_taken, // indicate any branch happen (trigger by inst, csr unit)
    output reg [1:0] pc_sel
);
// 0 beq
// 1 bne
// 2 blt
// 3 bge
// 4 bltu
// 5 bgeu

reg is_inst_br;
always @(*)begin
    case(cmp_op)
        3'b000: is_inst_br = (is_br & (reg_rd_data1 == reg_rd_data2)) | is_j; // beq
        3'b001: is_inst_br = (is_br & (reg_rd_data1 != reg_rd_data2)) | is_j; // bne
        3'b010: is_inst_br = (is_br & (reg_rd_data1 < reg_rd_data2)) | is_j; // blt
        3'b011: is_inst_br = (is_br & (reg_rd_data1 >= reg_rd_data2)) | is_j; // bge
        3'b100: is_inst_br = (is_br & ($unsigned(reg_rd_data1) < $unsigned(reg_rd_data2))) | is_j; // bltu
        3'b101: is_inst_br = (is_br & ($unsigned(reg_rd_data1) >= $unsigned(reg_rd_data2))) | is_j; // bgeu
        default: is_inst_br = 0; // default case
    endcase
end

// pc_sel = 0: pc_p4
// pc_sel = 1: ALU_out
// pc_sel = 2: csr_pc_target
// priority: csr_br > inst_br
always @(*)begin
    if(is_csr_br) pc_sel=2;
    else if(is_inst_br) pc_sel=1;
    else pc_sel=0;
end

assign br_taken = is_inst_br | is_csr_br;

endmodule
