//-----------------------------------------------------------------
// MMU
//-----------------------------------------------------------------

`include "../riscv_defs.v"

module mmu
#(
     parameter  MMU_SUPPORT = 1 
    ,parameter  ADDR_MIN = 32'h80000000
    ,parameter  ADDR_MAX = 32'hffffffff
    ,parameter  ICACHE_ADDR_MIN = 32'h80000000
    ,parameter  ICACHE_ADDR_MAX = 32'h80010000
)
(
     input          clk_i
    ,input          rst_i
    ,input  [31:0]  satp_i

    ,input  [31:0]  fetch_pc_i
    ,input          fetch_rd_i
    ,input  [31:0]  lsu_in_addr_i
    ,input  [31:0]  lsu_in_data_i
    ,input          lsu_in_rd_i
    ,input          lsu_in_wr_i
    ,input  [ 3:0]  lsu_in_mask_i
    ,input          lsu_in_flush_i
    ,input          lsu_in_invalidate_i
    ,input          lsu_in_writeback_i

    ,input  [31:0]  dcache_in_value_i
    ,input          dcache_in_valid_i
    ,input  [31:0]  icache_in_value_i
    ,input          icache_in_valid_i

    ,output [31:0]  fetch_out_value_o
    ,output         fetch_out_valid_o
    ,output [31:0]  lsu_out_value_o
    ,output         lsu_out_valid_o

    ,output [31:0]  dcache_addr_o
    ,output [31:0]  dcache_value_o
    ,output         dcache_rd_o
    ,output         dcache_wr_o
    ,output [ 3:0]  dcache_mask_o
    ,output         dcache_flush_o
    ,output         dcache_invalidate_o
    ,output         dcache_writeback_o
    ,output [31:0]  icache_addr_o
    ,output         icache_rd_o

    ,output         load_fault_o
    ,output         store_fault_o
    ,output         inst_fault_o
);



generate
if(MMU_SUPPORT) 
begin : MMU

localparam PPN_SIZE             = 20;

wire itlb_req = fetch_rd_i;
wire dtlb_req = lsu_in_rd_i || lsu_in_wr_i;

wire [31:0] itlb_entry_o;
wire [31:0] dtlb_entry_o;
wire        itlb_hit;
wire        dtlb_hit;

reg  [31:0] update_entry;
wire        is_pte;
wire        is_update;

wire        vm_enable   = satp_i[`SATP_MODE_R];
wire [ 8:0] vm_asid     = satp_i[`SATP_ASID_R];
wire [31:0] vm_ppn      = {satp_i[`SATP_PPN_R],12'b0};

wire [31:0] ptw_pte_addr_o;
wire [31:0] ptw_pte_value_o;
wire        ptw_pte_fault_o;

reg [31:0] dcache_addr_r;
reg [31:0] icache_addr_r;
reg [ 3:0] dcache_mask_r;

// wire cache_interupt = ((dcache_addr_r >= ICACHE_ADDR_MIN) && (dcache_addr_r <= ICACHE_ADDR_MAX));
// wire icache_addr_error = !((icache_addr_r >= ADDR_MIN) && (icache_addr_r <= ADDR_MAX));
// wire dcache_addr_error = !((dcache_addr_r >= ADDR_MIN) && (dcache_addr_r <= ADDR_MAX)) || cache_interupt;

// ---------------------------------------
// Output Control
//----------------------------------------
// wire req_d_rd = lsu_in_rd_i && ~dcache_addr_error;
// wire req_d_wr = lsu_in_wr_i && ~dcache_addr_error;
// wire req_i_rd = fetch_rd_i && ~icache_addr_error;

// wire vm_d_rd = ((lsu_in_rd_i && (dtlb_hit)) || is_pte) && ~dcache_addr_error;
// wire vm_d_wr = lsu_in_wr_i && dtlb_hit && ~dcache_addr_error;
// wire vm_i_rd = fetch_rd_i && itlb_hit && ~icache_addr_error;

wire req_d_rd = lsu_in_rd_i;
wire req_d_wr = lsu_in_wr_i;
wire req_i_rd = fetch_rd_i;

wire vm_d_rd = ((lsu_in_rd_i && (dtlb_hit)) || is_pte);
wire vm_d_wr = lsu_in_wr_i && dtlb_hit;
wire vm_i_rd = fetch_rd_i && itlb_hit;

wire dcache_rd_c = (vm_enable)? vm_d_rd : req_d_rd;
wire dcache_wr_c = (vm_enable)? vm_d_wr : req_d_wr;
wire icache_rd_c = (vm_enable)? vm_i_rd : req_i_rd;

wire icache_valid;
wire dcache_valid;

mmu_cache_ctrl u_mmu_cache_ctrl(
    .clk_i                  (clk_i),
    .rst_i                  (rst_i),
    .mmu_dcache_rd_i        (dcache_rd_c),
    .mmu_dcache_wr_i        (dcache_wr_c),
    .dcache_mmu_available_i (dcache_in_valid_i),
    .mmu_dcache_rd_o        (dcache_rd_o),
    .mmu_dcache_wr_o        (dcache_wr_o),
    .dcache_valid_o         (dcache_valid),
    .mmu_icache_rd_i        (icache_rd_c),
    .icache_mmu_available_i (icache_in_valid_i),
    .mmu_icache_rd_o        (icache_rd_o),
    .icache_valid_o         (icache_valid)
);

assign fetch_out_value_o    = icache_in_value_i;
assign fetch_out_valid_o    = (vm_enable)?(icache_valid && itlb_hit):(icache_valid);
assign lsu_out_value_o      = dcache_in_value_i;
assign lsu_out_valid_o      = (vm_enable)?(dcache_valid && dtlb_hit):(dcache_valid);

assign icache_addr_o        = icache_addr_r;
assign dcache_addr_o        = dcache_addr_r;
assign dcache_value_o       = lsu_in_data_i;
assign dcache_mask_o        = dcache_mask_r;

always @(*)begin
    dcache_addr_r = 32'h0;
    icache_addr_r = 32'h0;
    dcache_mask_r = 0;

    if(!vm_enable)
        dcache_addr_r = lsu_in_addr_i;
    if(is_pte)
        dcache_addr_r = ptw_pte_addr_o;
    else if(dtlb_hit)
        dcache_addr_r = {dtlb_entry_o[29:10],lsu_in_addr_i[11:0]};
    
    if(!vm_enable)
        icache_addr_r = fetch_pc_i;
    else
        icache_addr_r = {itlb_entry_o[29:10],fetch_pc_i[11:0]};


    if(dcache_rd_o)
        dcache_mask_r = 4'hf;
    else if(dcache_wr_o)
        dcache_mask_r = lsu_in_mask_i;
    else
        dcache_mask_r = 4'h0;
end

assign load_fault_o     = lsu_in_rd_i   && ( ptw_pte_fault_o || (!dtlb_entry_o[`PAGE_READ]  && dtlb_hit));
assign store_fault_o    = lsu_in_wr_i && ( ptw_pte_fault_o || (!dtlb_entry_o[`PAGE_WRITE] && dtlb_hit));
assign inst_fault_o     = fetch_rd_i    && ( ptw_pte_fault_o || (!itlb_entry_o[`PAGE_EXEC]  && itlb_hit));

assign dcache_invalidate_o  = lsu_in_invalidate_i;
assign dcache_flush_o       = lsu_in_flush_i;
assign dcache_writeback_o   = lsu_in_writeback_i;

// ---------------------------------------
// TLB
//----------------------------------------

reg [19:0] itlb_vpn_i;
reg [19:0] dtlb_vpn_i;

mmu_tlb #(
    .PPN_SIZE(PPN_SIZE)
)ITLB(
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .addr_i   (itlb_vpn_i),
    .entry_i  (update_entry),
    .update_i (is_update && itlb_req),
    .hit_o    (itlb_hit),
    .entry_o  (itlb_entry_o)
);

mmu_tlb #(
    .PPN_SIZE(PPN_SIZE)
)DTLB(
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .addr_i   (dtlb_vpn_i),
    .entry_i  (update_entry),
    .update_i (is_update && dtlb_req),
    .hit_o    (dtlb_hit),
    .entry_o  (dtlb_entry_o)
);

always @(*)begin
    itlb_vpn_i      = 20'b0;
    dtlb_vpn_i      = 20'b0;
    update_entry    = 32'b0;

    if(is_update)
    begin
        if(itlb_req)
        begin
            itlb_vpn_i   = ptw_pte_addr_o[19:0];   
            update_entry = ptw_pte_value_o;
        end
        else if(dtlb_req)
        begin
            dtlb_vpn_i   = ptw_pte_addr_o[19:0];
            update_entry = ptw_pte_value_o;
        end
    end
    else 
    begin
        itlb_vpn_i = fetch_pc_i[31:12];
        dtlb_vpn_i = lsu_in_addr_i[31:12];
    end
end

// ---------------------------------------
// PTW
//----------------------------------------

reg  [31:0] ptw_req_addr_r;

wire itlb_miss = itlb_req && ~itlb_hit;
wire dtlb_miss = dtlb_req && ~dtlb_hit;

wire [31:0] ptw_resp_data_i  = dcache_in_value_i;
wire        ptw_resp_valid_i = dcache_valid;
wire        ptw_req_valid_i  = (itlb_miss || dtlb_miss) && vm_enable;
wire [31:0] ptw_req_addr_i   = ptw_req_addr_r;
// wire        ptw_error_i      = dcache_addr_error && dcache_rd_o; 
wire        ptw_error_i = 0;

always @(*)begin
    ptw_req_addr_r = 32'h0;
    
    if(dtlb_req)
        ptw_req_addr_r = lsu_in_addr_i;
    else if(itlb_req)
        ptw_req_addr_r = fetch_pc_i;
end

mmu_ptw ptw(
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .satp_i       (satp_i),
    .req_addr_i   (ptw_req_addr_i),
    .req_valid_i  (ptw_req_valid_i),
    .resp_data_i  (ptw_resp_data_i),
    .resp_valid_i (ptw_resp_valid_i),
    .pte_errow_i  (ptw_error_i),
    .pte_addr_o   (ptw_pte_addr_o),
    .pte_value_o  (ptw_pte_value_o),
    .update_o     (is_update),
    .pte_fault_o  (ptw_pte_fault_o),
    .ptw_work_o   (is_pte)
);

end
else 
begin : SIMPLE_MMU

mmu_cache_ctrl u_mmu_cache_ctrl(
    .clk_i                  (clk_i),
    .rst_i                  (rst_i),
    .mmu_dcache_rd_i        (lsu_in_rd_i),
    .mmu_dcache_wr_i        (lsu_in_wr_i),
    .dcache_mmu_available_i (dcache_in_valid_i),
    .mmu_dcache_rd_o        (dcache_rd_o),
    .mmu_dcache_wr_o        (dcache_wr_o),
    .dcache_valid_o         (lsu_out_valid_o),
    .mmu_icache_rd_i        (fetch_rd_i),
    .icache_mmu_available_i (icache_in_valid_i),
    .mmu_icache_rd_o        (icache_rd_o),
    .icache_valid_o         (fetch_out_valid_o)
);
    
assign fetch_out_value_o = icache_in_value_i;
assign lsu_out_value_o = dcache_in_value_i;
assign dcache_addr_o = lsu_in_addr_i;
assign dcache_value_o = lsu_in_data_i;
assign dcache_mask_o = lsu_in_mask_i;
assign dcache_flush_o = lsu_in_flush_i;
assign dcache_writeback_o = lsu_in_writeback_i;
assign dcache_invalidate_o = lsu_in_invalidate_i;
assign icache_addr_o = fetch_pc_i;
assign load_fault_o = 0;
assign store_fault_o = 0;
assign inst_fault_o = 0;

end
endgenerate


endmodule
