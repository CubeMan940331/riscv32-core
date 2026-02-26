// -----------------------------------------------
// Dcache Signal Control
// -----------------------------------------------

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

reg i_cache_rd_r;
assign mmu_icache_rd_o = mmu_icache_rd_i && icache_mmu_rdy_i && !i_cache_rd_r;
assign icache_valid_o = icache_mmu_rdy_i && i_cache_rd_r;

reg d_cache_req_r;
assign mmu_dcache_rd_o = mmu_dcache_rd_i && dcache_mmu_rdy_i && !d_cache_req_r;
assign mmu_dcache_wr_o = mmu_dcache_wr_i && dcache_mmu_rdy_i && !d_cache_req_r;
assign dcache_valid_o = dcache_mmu_rdy_i && d_cache_req_r;

always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)begin
        i_cache_rd_r <= 0;
        d_cache_req_r <= 0;
    end else begin
        i_cache_rd_r <= (i_cache_rd_r)? !icache_mmu_rdy_i : mmu_icache_rd_i;
        d_cache_req_r <= (d_cache_req_r)? !dcache_mmu_rdy_i : (mmu_dcache_rd_i || mmu_dcache_wr_i); 
    end
end

// I cache Control (same clock)
// reg i_available_pre;
// reg i_rd_r;
// reg i_valid_r;
// wire i_available = icache_mmu_rdy_i && i_available_pre;

// assign icache_valid_o = i_rd_r && i_available;
// assign mmu_icache_rd_o = mmu_icache_rd_i && i_available_pre;

// always @(posedge clk_i or negedge rst_i)begin
//     if(!rst_i)begin
//         i_available_pre <= 1;
//         i_rd_r <= 0;
//         i_valid_r <= 0;
//     end else begin        
//         i_rd_r <= mmu_icache_rd_i;
//         i_valid_r <= i_rd_r && i_available;
//         i_available_pre <= icache_mmu_rdy_i;
//     end
// end

endmodule
