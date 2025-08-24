// -----------------------------------------------------------------
// mmu_reg
// -----------------------------------------------------------------
//
// Target: Store lsu input information for returning valid signal.
//
// -----------------------------------------------------------------

module mmu_reg(
     input clk_i
    ,input rst_i

    // Control
    ,input        update_i

    // Data
    ,input [31:0] addr_i
    ,input [31:0] data_i
    ,input        rd_i
    ,input        wr_i
    ,input [ 3:0] mask_i

    ,output reg [31:0] addr_o
    ,output reg [31:0] data_o
    ,output reg        rd_o
    ,output reg        wr_o
    ,output reg [ 3:0] mask_o 
);

always @(posedge clk_i or negedge rst_i) begin
    if(rst_i)
    begin
        addr_o <= 0;
        data_o <= 0;
        rd_o <= 0;
        wr_o <= 0;
        mask_o <= 0;
    end
    else
    begin
        if(update_i)
        begin
            addr_o <= addr_i;
            data_o <= data_i;
            rd_o <= rd_i;
            wr_o <= wr_i;
            mask_o <= mask_i;
        end   
    end
end

endmodule