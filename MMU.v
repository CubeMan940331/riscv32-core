//-----------------------------------------------------------------
// MMU
//-----------------------------------------------------------------

`include "riscv_defs.v"
`include "MMU_file.v"

module mmu 
#(
     parameter  ADDR_MIN = 32'h80000000
    ,parameter  ADDR_MAX = 32'h8fffffff
    ,parameter  ICACHE_ADDR_MIN = 32'h00000000
    ,parameter  ICACHE_ADDR_MAX = 32'h00800000
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
    ,input  [ 3:0]  lsu_in_wr_i
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
    ,output [ 5:0]  mmu_exception_o
);

// ---------------------------------------
// Parameter
// ---------------------------------------

localparam PPN_SIZE             = 20;

// Page Struct
localparam PAGE_VALID           = 0;
localparam PAGE_READ            = 1;
localparam PAGE_WRITE           = 2;
localparam PAGE_EXE             = 3;
localparam PAGE_USER            = 4;
localparam PAGE_GLOBAL          = 5;
localparam PAGE_ACCESS          = 6;
localparam PAGE_DIRTY           = 7;

// ---------------------------------------
// Wire & Register
// --------------------------------------- 

wire itlb_req = fetch_rd_i;
wire dtlb_req = lsu_in_rd_i || (|lsu_in_wr_i);

wire [31:0] itlb_entry_o;
wire [31:0] dtlb_entry_o;
wire        itlb_hit;
wire        dtlb_hit;

reg  [31:0] update_entry;
wire        is_pte;
wire        is_update;

wire        vm_enable   = satp_i[`SATP_MODE_R];
// wire        vm_asid     = satp_i[`SATP_ASID_R];
// wire [31:0] vm_ppn      = {satp_i[`SATP_PPN_R],12'b0};

wire [31:0] ptw_pte_addr_o;
wire [31:0] ptw_pte_value_o;
wire        ptw_pte_fault_o;

wire        cache_interupt;
wire        icache_addr_error;
wire        dcache_addr_error;

reg [31:0] dcache_addr_r;
reg [ 3:0] dcache_mask_r;

assign cache_interupt = ((dcache_addr_r >= ICACHE_ADDR_MIN) && (dcache_addr_r <= ICACHE_ADDR_MAX));
assign icache_addr_error = !((icache_addr_o >= ADDR_MIN) && (icache_addr_o <= ADDR_MAX));
assign dcache_addr_error = !((dcache_addr_r >= ADDR_MIN) && (dcache_addr_r <= ADDR_MAX)) || cache_interupt;

// ---------------------------------------
// Output Control
//----------------------------------------

wire dcache_rd_c = ((lsu_in_rd_i && (dtlb_hit)) || is_pte) && ~dcache_addr_error;
wire dcache_wr_c = (|lsu_in_wr_i) && ~is_pte && dtlb_hit && ~dcache_addr_error;
wire dcache_valid;
wire icache_rd_c = fetch_rd_i && itlb_hit && ~icache_addr_error;
wire icache_valid;

Cache_Ctrl u_Cache_Ctrl(
    .clk_i                  (clk_i                  ),
    .rst_i                  (rst_i                  ),
    .mmu_dcache_rd_i        (dcache_rd_c        ),
    .mmu_dcache_wr_i        (dcache_wr_c        ),
    .dcache_mmu_available_i (dcache_in_valid_i ),
    .mmu_dcache_rd_o        (dcache_rd_o        ),
    .mmu_dcache_wr_o        (dcache_wr_o        ),
    .dcache_valid_o         (dcache_valid         ),
    .mmu_icache_rd_i        (icache_rd_c),
    .icache_mmu_available_i (icache_in_valid_i),
    .mmu_icache_rd_o        (icache_rd_o),
    .icache_valid_o         (icache_valid)
);

assign fetch_out_value_o    = icache_in_value_i;
assign fetch_out_valid_o    = icache_in_valid_i && itlb_hit;
assign lsu_out_value_o      = dcache_in_value_i;
assign lsu_out_valid_o      = dcache_valid && dtlb_hit;

assign icache_addr_o        = {itlb_entry_o[29:10],fetch_pc_i[11:0]};
// assign icache_rd_o          = fetch_rd_i && itlb_hit && ~icache_addr_error;

assign dcache_addr_o    = dcache_addr_r;
assign dcache_value_o   = lsu_in_data_i;
// assign dcache_rd_o      = ((lsu_in_rd_i && dtlb_hit) || is_pte) && ~dcache_addr_error;
// assign dcache_wr_o      = (|lsu_in_wr_i) && ~is_pte && dtlb_hit && ~dcache_addr_error;
assign dcache_mask_o    = dcache_mask_r;

always @(*)begin
    dcache_addr_r = 32'b0;
    dcache_mask_r = 0;

    if(is_pte)
        dcache_addr_r = ptw_pte_addr_o;
    else if(dtlb_hit)
        dcache_addr_r = {dtlb_entry_o[29:10],lsu_in_addr_i[11:0]};

    if(dcache_rd_o)
        dcache_mask_r = 4'hf;
    else if(dcache_wr_o)
        dcache_mask_r = lsu_in_wr_i;
    else
        dcache_mask_r = 4'h0;
end

assign load_fault_o     = lsu_in_rd_i && !dtlb_entry_o[PAGE_READ] && dtlb_hit;
assign store_fault_o    =  (|lsu_in_wr_i) && !dtlb_entry_o[PAGE_WRITE] && dtlb_hit;
assign inst_fault_o     = fetch_rd_i && !itlb_entry_o[PAGE_EXE] && itlb_hit;

assign mmu_exception_o  = (ptw_pte_fault_o && fetch_rd_i)?`EXCEPTION_PAGE_FAULT_INST:
                          (ptw_pte_fault_o && lsu_in_rd_i)?`EXCEPTION_PAGE_FAULT_LOAD:
                          (ptw_pte_fault_o && (|lsu_in_wr_i))?`EXCEPTION_PAGE_FAULT_STORE:6'h0;

assign dcache_invalidate_o  = lsu_in_invalidate_i;
assign dcache_flush_o       = lsu_in_flush_i;
assign dcache_writeback_o   = lsu_in_writeback_i;

// ---------------------------------------
// TLB
//----------------------------------------

reg [19:0] itlb_vpn_i;
reg [19:0] dtlb_vpn_i;

TLB #(
    .PPN_SIZE(PPN_SIZE)
)ITLB(
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .addr_i   (itlb_vpn_i),
    .entry_i  (update_entry),
    .valid_i  (itlb_req),
    .update_i (is_update),
    .hit_o    (itlb_hit),
    .entry_o  (itlb_entry_o)
);

TLB #(
    .PPN_SIZE(PPN_SIZE)
)DTLB(
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .addr_i   (dtlb_vpn_i),
    .entry_i  (update_entry),
    .valid_i  (dtlb_req),
    .update_i (is_update),
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
//---------------------------------------- // 10 /00 0000 0111

reg  [31:0] ptw_req_addr_r;

wire [31:0] ptw_resp_data_i  = dcache_in_value_i;
wire        ptw_resp_valid_i = dcache_valid;
wire        ptw_req_valid_i  = (itlb_req && ~itlb_hit) || (dtlb_req && ~dtlb_hit);
wire [31:0] ptw_req_addr_i   = ptw_req_addr_r;
wire        ptw_error_i      = dcache_addr_error && dcache_rd_o; 

always @(*)begin
    ptw_req_addr_r = 32'h0;
    
    if(itlb_req)
        ptw_req_addr_r = fetch_pc_i;
    else if(dtlb_req)
        ptw_req_addr_r = lsu_in_addr_i;
end

PTW ptw(
    .clk_i        (clk_i        ),
    .rst_i        (rst_i        ),
    .satp_i       (satp_i       ),
    .req_addr_i   (ptw_req_addr_i   ),
    .req_valid_i  (ptw_req_valid_i  ),
    .resp_data_i  (ptw_resp_data_i  ),
    .resp_valid_i (ptw_resp_valid_i ),
    .pte_errow_i  (ptw_error_i),
    .pte_addr_o   (ptw_pte_addr_o   ),
    .pte_value_o  (ptw_pte_value_o  ),
    .update_o     (is_update        ),
    .pte_fault_o  (ptw_pte_fault_o  ),
    .ptw_work_o   (is_pte)
);

endmodule