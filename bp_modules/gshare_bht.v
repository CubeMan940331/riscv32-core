/* verilator lint_off BLKLOOPINIT */
module gshare_bht
//Params
#(
     parameter INDEX_BITS = 11,
     parameter GHR_BITS = 4,
     parameter BHT_SIZE = 1 << INDEX_BITS
)
//Ports
(
    //Input
     input              clk,
     input              rst_n,
     input  [31:0]      pc_f_i,
     input              update_en_i,
     input  [31:0]      update_pc_i,
     input              update_taken_i,
    
    //Output
     output             predict_taken_o
);

    reg [1:0] bht [0:BHT_SIZE-1];
    reg [GHR_BITS-1:0] ghr;

    wire [INDEX_BITS-1:0] fetch_index  = pc_f_i[INDEX_BITS+1:2] ^ {{(INDEX_BITS-GHR_BITS){1'b0}}, ghr};
    wire [INDEX_BITS-1:0] update_index = update_pc_i[INDEX_BITS+1:2] ^ {{(INDEX_BITS-GHR_BITS){1'b0}}, ghr};

    assign predict_taken_o = bht[fetch_index][1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ghr <= 0;
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                bht[i] <= 2'b00;
            end
        end else if (update_en_i) begin
            case(bht[update_index])
                2'b11: bht[update_index] <= update_taken_i ? 2'b11 : 2'b10;
                2'b10: bht[update_index] <= update_taken_i ? 2'b11 : 2'b01;
                2'b01: bht[update_index] <= update_taken_i ? 2'b10 : 2'b00;
                2'b00: bht[update_index] <= update_taken_i ? 2'b01 : 2'b00;
            endcase
            ghr <= {ghr[GHR_BITS-2:0], update_taken_i};
        end
    end

endmodule

