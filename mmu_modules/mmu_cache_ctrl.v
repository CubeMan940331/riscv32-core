// // -----------------------------------------------
// // Dcache Signal Control
// // -----------------------------------------------

module mmu_cache_ctrl(
     input clk_i
    ,input rst_i

    ,input mmu_dcache_rd_i
    ,input mmu_dcache_wr_i
    ,input dcache_mmu_rdy_i
    ,output mmu_dcache_rd_o
    ,output mmu_dcache_wr_o
    ,output dcache_valid_o

    ,input mmu_icache_rd_i
    ,input icache_mmu_rdy_i
    ,output mmu_icache_rd_o
    ,output icache_valid_o
);

reg i_available_pre;
reg i_rd_r;
reg i_valid_r;

reg dcache_rd_r;
reg dcache_wr_r;

wire i_available = icache_mmu_rdy_i && i_available_pre;

assign mmu_dcache_rd_o = mmu_dcache_rd_i && dcache_mmu_rdy_i;
assign mmu_dcache_wr_o = mmu_dcache_wr_i && dcache_mmu_rdy_i;

assign dcache_valid_o = dcache_mmu_rdy_i && (dcache_rd_r || dcache_wr_r);

assign icache_valid_o = i_rd_r && i_available;
assign mmu_icache_rd_o = mmu_icache_rd_i && i_available_pre;

always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)begin
        i_available_pre <= 1;
        i_rd_r <= 0;
        i_valid_r <= 0;
        
        dcache_rd_r <= 0;
        dcache_wr_r <= 0;
    end else begin
        
        i_rd_r <= mmu_icache_rd_i;
        i_valid_r <= i_rd_r && i_available;
        i_available_pre <= icache_mmu_rdy_i;

        dcache_rd_r <= mmu_dcache_rd_i;
        dcache_wr_r <= mmu_dcache_wr_i;
    end
end

endmodule
