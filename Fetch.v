module Fetch (
     input clk
    ,input rst_n

    ,input en
// feed back from EX for bp
    ,input [31:0] EX_pc_i
    
    ,input EX_bp_pred_taken_i
    ,input [31:0] EX_bp_pred_pc_i
    
    ,input EX_is_br_i
    ,input EX_br_taken_i
    ,input [31:0] EX_br_target_i
    ,input [31:0] EX_pc_p4_i
    
    ,input EX_csr_br_taken_i
    ,input [31:0] EX_csr_br_target_i
// output
    ,output br_flush_o
    
    ,output bp_pred_taken_o
    ,output [31:0] bp_pred_target_o
    
    ,output [31:0] pc_o
    ,output [31:0] pc_p4_o
);

reg [31:0] pc_in;

BP_top m_bp(
     .clk(clk)
    ,.rst_n(rst_n)
    
    ,.pc_f_i(pc_o)

    ,.pc_ex_i(EX_pc_i)
    ,.is_branch_i(EX_is_br_i)
    ,.branch_taken_ex_i(EX_br_taken_i)
    ,.branch_target_ex_i(EX_br_target_i)

    ,.predict_taken_o(bp_pred_taken_o)
    ,.predict_target_o(bp_pred_target_o) // pred pc if pred taken is true
);

PC m_PC(
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .pc_i(pc_in),
    .pc_o(pc_o)
);

// EX next pc logic
reg [31:0] EX_pc_nx_r;
always @(*) begin
    if(EX_csr_br_taken_i) EX_pc_nx_r = EX_csr_br_target_i;
    else if(EX_br_taken_i) EX_pc_nx_r = EX_br_target_i;
    else EX_pc_nx_r = EX_pc_p4_i;
end

// br_flush logic
reg br_flush_r;
always @(*) begin
    if(EX_bp_pred_taken_i) br_flush_r = EX_pc_nx_r != EX_bp_pred_pc_i;
    else br_flush_r = EX_pc_nx_r != EX_pc_p4_i;
end

// pc_in logic
always @(*) begin
    if(br_flush_r) pc_in = EX_pc_nx_r;
    else if(bp_pred_taken_o) pc_in = bp_pred_target_o;
    else pc_in = pc_p4_o;
end

assign br_flush_o = br_flush_r;
assign pc_p4_o = pc_o + 4;

endmodule
