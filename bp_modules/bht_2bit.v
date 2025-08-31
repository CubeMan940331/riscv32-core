/* verilator lint_off BLKLOOPINIT */
module bht_2bit
//Params
#(
    parameter INDEX_BITS = 8,
    parameter BHT_SIZE = 1 << INDEX_BITS
)
//Ports
(
    //Input
     input              clk
    ,input              rst_n
    ,input  [31:0]      pc_f_i
    ,input              update_en_i
    ,input  [31:0]      update_pc_i
    ,input              update_taken_i
    
    //Output
    ,output             predict_taken_o
);
    reg [1:0] bht [0:BHT_SIZE-1];		// 2^8 = 256 entries
    
    wire [INDEX_BITS-1:0] fetch_index = pc_f_i[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] update_index = update_pc_i[INDEX_BITS+1:2];
    
    assign predict_taken_o = bht[fetch_index][1];
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin			//Initialize BHT
            for (i = 0; i < BHT_SIZE; i = i + 1)
                bht[i] <= 2'b00;
        end else if (update_en_i) begin	//The EX stage instruction is a branch
            case(bht[update_index])
                2'b11: bht[update_index] <= update_taken_i ? 2'b11 : 2'b10;
                2'b10: bht[update_index] <= update_taken_i ? 2'b11 : 2'b01;
                2'b01: bht[update_index] <= update_taken_i ? 2'b10 : 2'b00;
                2'b00: bht[update_index] <= update_taken_i ? 2'b01 : 2'b00;
            endcase
        end
    end
    

endmodule