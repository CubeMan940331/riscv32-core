// -----------------------------------------------
// Dcache Signal Control
// -----------------------------------------------

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

reg dcache_available_pre;
reg dcache_valid_r;

assign dcache_valid_o  = dcache_valid_r && dcache_mmu_available_i;
assign mmu_dcache_rd_o = mmu_dcache_rd_i && dcache_available_pre;
assign mmu_dcache_wr_o = mmu_dcache_wr_i && dcache_available_pre;

reg icache_available_pre;
reg icache_valid_r;

assign icache_valid_o = icache_valid_r && icache_mmu_available_i;
assign mmu_icache_rd_o = mmu_icache_rd_i && icache_available_pre;

always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)begin
        dcache_available_pre <= 1;
        dcache_valid_r <= 0;
        icache_available_pre <= 1;
        icache_valid_r <= 0;
    end else begin
        dcache_available_pre <= dcache_mmu_available_i;
        dcache_valid_r <= (mmu_dcache_rd_i || mmu_dcache_wr_i) && dcache_mmu_available_i;
        icache_available_pre <= icache_mmu_available_i;
        icache_valid_r <= mmu_icache_rd_i && icache_mmu_available_i;
    end
end

endmodule