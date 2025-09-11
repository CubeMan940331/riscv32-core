module BP_top
#(
      parameter INDEX_BITS = 11
     ,parameter GHR_BITS = 4
     ,parameter TAG_BITS = 12
)
(
    //Input
     input        clk
    ,input        rst_n
    ,input [31:0] pc_f_i
    ,input [31:0] pc_ex_i
    ,input [ 1:0] inst_type_i
    ,input        branch_taken_ex_i
    ,input [31:0] branch_target_ex_i
    
    //Output
    ,output        predict_taken_o
    ,output [31:0] predict_target_o // bp_pred
);

    wire        inst_is_j_w;
    wire        hit_w;
    wire [31:0] target_w;
    wire        predict_taken_w;
    
    gshare_bht
    #(
          .INDEX_BITS(INDEX_BITS)
         ,.GHR_BITS(GHR_BITS) 
    ) u_gshare_bht (
          .clk(clk)
         ,.rst_n(rst_n)
         ,.pc_f_i(pc_f_i)
         ,.update_en_i(inst_type_i)
         ,.update_pc_i(pc_ex_i)
         ,.update_taken_i(branch_taken_ex_i)
         
         ,.predict_taken_o(predict_taken_w)
    );
    
    btb 
    #(
          .INDEX_BITS(INDEX_BITS) 
         ,.TAG_BITS(TAG_BITS)
    ) u_btb (
          .clk(clk)
         ,.rst_n(rst_n)
         ,.pc_f_i(pc_f_i)
         ,.update_en_i(inst_type_i)
         ,.update_pc_i(pc_ex_i)
         ,.update_taken_i(branch_taken_ex_i)
         ,.update_target_i(branch_target_ex_i)
         
         ,.inst_is_j_o(inst_is_j_w)
         ,.hit_o(hit_w)
         ,.target_o(target_w)
    );
     
    assign predict_taken_o = (inst_is_j_w || predict_taken_w) && hit_w;
    assign predict_target_o = target_w;

endmodule
