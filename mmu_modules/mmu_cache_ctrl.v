// // -----------------------------------------------
// // Dcache Signal Control
// // -----------------------------------------------

module mmu_cache_ctrl(
     input clk_i
    ,input rst_i

    ,input mmu_dcache_rd_i
    ,input mmu_dcache_wr_i
    ,input dcache_mmu_available_i
    ,output mmu_dcache_rd_o
    ,output mmu_dcache_wr_o
    ,output dcache_valid_o

    ,input mmu_icache_rd_i
    ,input icache_mmu_available_i
    ,output mmu_icache_rd_o
    ,output icache_valid_o
);

reg i_available_pre;
reg i_rd_r;
reg i_valid_r;

reg d_available_pre;
reg dcache_rd_r;
reg dcache_wr_r;
reg stall_r;

wire d_available = dcache_mmu_available_i && d_available_pre;
wire i_available = icache_mmu_available_i && i_available_pre;

assign dcache_valid_o  = (dcache_rd_r || (dcache_wr_r && !stall_r) ) && d_available;
assign mmu_dcache_rd_o = mmu_dcache_rd_i && d_available_pre;
assign mmu_dcache_wr_o = mmu_dcache_wr_i && d_available_pre;


// assign icache_valid_o = i_rd_r && i_available;
assign icache_valid_o = i_valid_r;
assign mmu_icache_rd_o = mmu_icache_rd_i && i_available_pre;

always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)begin
        d_available_pre <= 1;
        i_available_pre <= 1;
        dcache_rd_r <= 0;
        dcache_wr_r <= 0;
        i_rd_r <= 0;
        stall_r <= 0;
        i_valid_r <= 0;
    end else begin
        d_available_pre <= dcache_mmu_available_i;
        i_available_pre <= icache_mmu_available_i;
        dcache_rd_r <= mmu_dcache_rd_i;
        dcache_wr_r <= mmu_dcache_wr_i;
        i_rd_r <= mmu_icache_rd_i;
        i_valid_r <= i_rd_r && i_available;
        
        if(stall_r)
            stall_r <= !d_available;
        else
            stall_r <= mmu_dcache_wr_i;

    end
end

endmodule
