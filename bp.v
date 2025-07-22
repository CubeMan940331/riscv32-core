module bp
#(
      parameter INDEX_BITS = 8
     ,parameter TAG_BITS = 12
)
(
    //Input
     input        clk_i
    ,input        rst_i
    ,input [31:0] pc_f_i
    ,input [31:0] pc_ex_i
    ,input        is_branch_i
    ,input        branch_taken_ex_i
    ,input [31:0] branch_target_ex_i
    ,input        predict_taken_ex_i
    
    //Output
    ,output        misprediction_o     //To flush invalid instructions from the pipeline.
    ,output [31:0] next_fetch_pc_o
);

    wire        hit_w;
    wire [31:0] target_w;
    wire        predict_taken_w;
    wire [31:0] predict_target_w;
    
    assign misprediction_o  = predict_taken_ex_i ^ branch_taken_ex_i;
    assign predict_target_w = (predict_taken_w && hit_w) ? target_w : pc_f_i + 32'b0100;
    assign next_fetch_pc_o  = misprediction_o ? branch_target_ex_i : predict_target_w;
    
    bht_2bit
    #(
          .INDEX_BITS(INDEX_BITS)
    ) u_bht_2bit (
          .clk_i(clk_i)
         ,.rst_i(rst_i)
         ,.pc_f_i(pc_f_i)
         ,.update_en_i(is_branch_i)
         ,.update_pc_i(pc_ex_i)
         ,.update_taken_i(branch_taken_ex_i)
         
         ,.predict_taken_o(predict_taken_w)
    );
    
    btb 
    #(
          .INDEX_BITS(INDEX_BITS)
         ,.TAG_BITS(TAG_BITS)
    ) u_btb (
          .clk_i(clk_i)
         ,.rst_i(rst_i)
         ,.pc_f_i(pc_f_i)
         ,.update_en_i(is_branch_i)
         ,.update_pc_i(pc_ex_i)
         ,.update_taken_i(branch_taken_ex_i)
         ,.update_target_i(branch_target_ex_i)
         
         ,.hit_o(hit_w)
         ,.target_o(target_w)
    );
    
    
endmodule