/* verilator lint_off BLKLOOPINIT */
module btb
//Params
#(
    parameter INDEX_BITS = 11,
    parameter TAG_BITS = 12,
    parameter BTB_SIZE = 1 << INDEX_BITS
)
//Ports
(
    //Input
     input              clk,
     input              rst_n,
     input  [31:0]      pc_f_i,
     input  [ 1:0]      update_en_i,
     input  [31:0]      update_pc_i,
     input              update_taken_i,
     input  [31:0]      update_target_i,

    //Output
     output             inst_is_j_o,
     output             hit_o,
     output [31:0]      target_o
);

    reg j_ram [0:BTB_SIZE-1];
    reg valid_ram [0:BTB_SIZE-1];
    reg [31:0] target_ram [0:BTB_SIZE-1];
    reg [TAG_BITS-1:0] tag_ram [0:BTB_SIZE-1];
    //from IF stage
    wire [INDEX_BITS-1:0] fetch_index = pc_f_i[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   fetch_tag   = pc_f_i[31 -: TAG_BITS];
    //from EX stage
    wire [INDEX_BITS-1:0] update_index = update_pc_i[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag   = update_pc_i[31 -: TAG_BITS];
    
    assign inst_is_j_o = j_ram[fetch_index];
    assign hit_o = valid_ram[fetch_index] && (tag_ram[fetch_index] == fetch_tag);
    assign target_o = hit_o ? target_ram[fetch_index] : 32'b0;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < BTB_SIZE; i = i + 1) begin
                j_ram[i] <= 1'b0;
                valid_ram[i] <= 1'b0;
                target_ram[i] <= 32'b0;
                tag_ram[i] <= {TAG_BITS{1'b0}};
            end
        end else if ((update_en_i != 0) && update_taken_i) begin
            if(update_en_i == 2) j_ram[update_index] <= 1;
            else j_ram[update_index] <= 0;
            tag_ram[update_index]   <= update_tag;
            target_ram[update_index] <= update_target_i;
            valid_ram[update_index] <= 1'b1;
        end
    end

endmodule
