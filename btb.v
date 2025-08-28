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
     input              clk_i,
     input              rst_i,
     input  [31:0]      pc_f_i,
     input              update_en_i,
     input  [31:0]      update_pc_i,
     input              update_taken_i,
     input  [31:0]      update_target_i,

    //Output
     output             hit_o,
     output [31:0]      target_o
);

    reg valid_ram [0:BTB_SIZE-1];
    reg [31:0] target_ram [0:BTB_SIZE-1];
    reg [TAG_BITS-1:0] tag_ram [0:BTB_SIZE-1];

    wire [INDEX_BITS-1:0] fetch_index = pc_f_i[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   fetch_tag   = pc_f_i[31 -: TAG_BITS];

    wire [INDEX_BITS-1:0] update_index = update_pc_i[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag   = update_pc_i[31 -: TAG_BITS];
    
    assign hit_o = valid_ram[fetch_index] && (tag_ram[fetch_index] == fetch_tag);
    assign target_o = hit_o ? target_ram[fetch_index] : 32'b0;

    integer i;

    always @(posedge clk_i or negedge rst_i) begin
        if (~rst_i) begin
            for (i = 0; i < BTB_SIZE; i = i + 1) begin
                valid_ram[i] <= 1'b0;
                target_ram[i] <= 32'b0;
                tag_ram[i] <= {TAG_BITS{1'b0}};
            end
        end else if (update_en_i && update_taken_i) begin
            tag_ram[update_index]   <= update_tag;
            target_ram[update_index] <= update_target_i;
            valid_ram[update_index] <= 1'b1;
        end
    end

endmodule
