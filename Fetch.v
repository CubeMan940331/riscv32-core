module Fetch (
     input clk
    ,input rst_n

    ,input en

    ,input EX_is_br
    ,input EX_is_j_out
    ,input EX_is_csr_br
    ,input [31:0] EX_pc_target
    ,input [31:0] csr_pc_target

    ,output [31:0] pc_o
);

reg [31:0] pc_in;

wire [31:0] bp_nx_pc_out;
wire bp_pred_taken_out;
wire ID_bp_pred_taken_out;
wire EX_bp_pred_taken_out;

BP_top m_bp(
     .clk(clk)
    ,.rst_n(rst_n)
    ,.pc_f_i(pc_out)
    ,.pc_ex_i(EX_pc_out)
    ,.is_jump_i(EX_is_j_out)
    ,.is_branch_i(EX_is_br_out)
    ,.branch_taken_ex_i(br_taken)
    ,.branch_target_ex_i(EX_pc_target)
    ,.predict_taken_ex_i(EX_bp_pred_taken_out)

    ,.predict_taken_o(bp_pred_taken_out)
    ,.next_fetch_pc_o(bp_nx_pc_out)
    ,.misprediction_o(bp_mispred_out)
);

PC m_PC(
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .pc_i(pc_in),
    .pc_o(pc_o)
);

always @(*) begin
    if (EX_is_csr_br) pc_in = csr_pc_target;
    else pc_in = bp_nx_pc_out;
end


endmodule