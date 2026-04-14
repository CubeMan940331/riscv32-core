//-----------------------------------------------------------------
// MMU
//-----------------------------------------------------------------

`include "../riscv_defs.v"

module mmu
#(
     parameter  D_ADDR_MIN = 32'h60000000
    ,parameter  D_ADDR_MAX = 32'hFFFFFFFF
    ,parameter  SUPPORT_CDMA = 0
    ,parameter  SUPPORT_ROM = 0
)
(
     input          clk_i
    ,input          rst_i
    ,input  [31:0]  satp_i
    ,input  [1:0]   priv_i

    // LSU Interface
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
    ,input          lsu_in_zero_i
    ,input          lsu_in_i_invalidate_i

    ,output [31:0]  fetch_out_value_o
    ,output         fetch_out_valid_o
    ,output [31:0]  lsu_out_value_o
    ,output         lsu_out_valid_o

    // Dcache Interface
    ,input  [31:0]  dcache_in_value_i
    ,input          dcache_in_valid_i

    ,output [31:0]  dcache_addr_o
    ,output [31:0]  dcache_value_o
    ,output         dcache_rd_o        
    ,output         dcache_wr_o        
    ,output [ 3:0]  dcache_mask_o      
    ,output reg     dcache_flush_o     
    ,output reg     dcache_invalidate_o
    ,output reg     dcache_writeback_o 
    ,output reg     dcache_zero_o
 
    // CDMA
    // only input, reuse dcache output
    ,input [31:0]   cdma_data_i
    ,input          cdma_valid_i
    ,input [1:0]    cdma_exception_i
    ,output         cdma_wr_o
    ,output         cdma_rd_o

    // Icache Interface
    ,input  [31:0]  icache_in_value_i
    ,input  [31:0]  bootrom_in_value_i
    ,input          icache_in_valid_i
    ,output [31:0]  icache_addr_o
    ,output         icache_rd_o
    ,output reg     icache_invalidate_o

    // exception 
    ,input  [1:0]   dcache_exception_i
    ,input          icache_exception_i
    ,output         read_except_o     
    ,output         write_except_o
    ,output         exe_except_o  
);

localparam PPN_SIZE             = 20;

wire itlb_req = fetch_rd_i;
wire dtlb_req = lsu_in_rd_i || lsu_in_wr_i;

wire [31:0] itlb_entry_o;
wire [31:0] dtlb_entry_o;
wire itlb_hit, dtlb_hit;
wire itlb_valid, dtlb_valid;

reg  [31:0] update_entry;
wire        is_pte;
wire        is_update;

wire        vm_enable   = satp_i[`SATP_MODE_R];
wire [ 8:0] vm_asid     = satp_i[`SATP_ASID_R];
wire [31:0] vm_ppn      = {satp_i[`SATP_PPN_R],12'b0};

wire [31:0] ptw_pte_addr_o;
wire [31:0] ptw_pte_value_o;
wire  [2:0] ptw_pte_fault_o;

reg [31:0] dcache_addr_r;
reg [31:0] icache_addr_r;
reg [ 3:0] dcache_mask_r;

// ---------------------------------------
// Output Control
//----------------------------------------

wire req_d_rd; 
wire req_d_wr;
wire req_i_rd;
wire vm_d_rd;
wire vm_d_wr;
wire vm_i_rd;

// without addr error detection 
assign req_d_rd = lsu_in_rd_i;
assign req_d_wr = lsu_in_wr_i;
assign req_i_rd = fetch_rd_i;
assign vm_d_rd = ((lsu_in_rd_i && (dtlb_hit)) || is_pte);
assign vm_d_wr = lsu_in_wr_i && dtlb_hit;
assign vm_i_rd = fetch_rd_i && itlb_hit;

// control cache output signal
wire dcache_rd_c = (vm_enable)? vm_d_rd : req_d_rd;
wire dcache_wr_c = (vm_enable)? vm_d_wr : req_d_wr;
wire icache_rd_c = (vm_enable)? vm_i_rd : req_i_rd;

wire d_flush     = (vm_enable)? (lsu_in_flush_i && dtlb_hit) : lsu_in_flush_i;
wire d_invalid   = (vm_enable)? (lsu_in_invalidate_i && dtlb_hit) : lsu_in_invalidate_i;
wire d_writeback = (vm_enable)? (lsu_in_writeback_i && dtlb_hit) : lsu_in_writeback_i;
wire d_zero      = (vm_enable)? (lsu_in_zero_i && dtlb_hit) : lsu_in_zero_i;

wire icache_valid;
wire dcache_valid;

// ============================== //
//           IF Selector          //
// ============================== //

localparam MAX_ROM_ADDR = 32'h0000_1000;
wire [31:0] fetch_value_w;
wire icache_valid_w;

generate
if (SUPPORT_ROM) begin : gen_rom_support
    assign fetch_value_w = (icache_addr_o >= MAX_ROM_ADDR)? icache_in_value_i: bootrom_in_value_i;    
    assign icache_valid_w = icache_in_valid_i || (icache_addr_o <= MAX_ROM_ADDR);
end else begin :gen_only_icache
    assign fetch_value_w = icache_in_value_i;
    assign icache_valid_w = icache_in_valid_i;
end   
endgenerate

// ============================== //
//      Data Input Selection      //
// ============================== //

wire d_cachable_w;
wire d_cachable;
reg d_cacheable_pre;    // select current input is cdma or dcache
reg d_valid;
reg [31:0] data_i;
reg [1:0] d_execption_i;

generate 
if(SUPPORT_CDMA) begin : gen_cdma_support
    /* verilator lint_off CMPCONST */
    assign d_cachable = (dcache_addr_r >= D_ADDR_MIN) && (dcache_addr_r <= D_ADDR_MAX); 
    // support for cdma and dcache selection    
    always @(posedge clk_i or negedge rst_i)begin
        if(~rst_i)begin
            d_cacheable_pre <= 1;
        end else begin
            d_cacheable_pre <= d_cachable_w;
        end
    end
end else begin : gen_only_dcache
    // always choose dcache input
    assign d_cachable = 1;
    always @(posedge clk_i or negedge rst_i)begin
        if(~rst_i)begin
            d_cacheable_pre <= 1'b1;
        end else begin
            d_cacheable_pre <= 1'b1;    
        end
    end
end
endgenerate

always @(*)begin
    if(d_cacheable_pre)begin
        d_valid = dcache_in_valid_i;
        data_i = dcache_in_value_i;
        d_execption_i = dcache_exception_i;
    end else begin
        d_valid = cdma_valid_i;
        data_i = cdma_data_i;
        d_execption_i = cdma_exception_i;
    end
end

// ---------------------------------------
// Output Cache Controler
//----------------------------------------

wire [31:0] dcache_wb_data_value;
wire [31:0] d_ctrl_addr;
wire [31:0] d_ctrl_data;

mmu_cache_ctrl u_mmu_cache_ctrl(
    .clk_i           (clk_i),
    .rst_i           (rst_i),

    // mmu internal interface
    .mmu_dcache_rd_i (dcache_rd_c),
    .mmu_dcache_wr_i (dcache_wr_c),
    .mmu_dcache_addr_i(dcache_addr_r),
    .mmu_dcache_wr_data_i(lsu_in_data_i),
    .mmu_dcache_mask_i(dcache_mask_r),
    .mmu_cachable_i  (d_cachable),
    .mmu_d_oper_i    (d_invalid || d_writeback  || d_flush),
    .dcache_valid_o  (dcache_valid),
    .dcache_wb_data_o(dcache_wb_data_value),

    .mmu_icache_rd_i (icache_rd_c),
    .mmu_icache_addr_i(icache_addr_r),

    // mmu dcache & cdma interface
    .mmu_dcache_rd_o (dcache_rd_o),
    .mmu_dcache_wr_o (dcache_wr_o),
    .mmu_dcache_addr_o(dcache_addr_o),
    .mmu_dcache_wr_data_o(dcache_value_o),
    .mmu_dcache_mask_o(dcache_mask_o),
    .mmu_dcachable_o  (d_cachable_w),
    .dcache_mmu_valid_i(d_valid),
    .dcache_wb_data_i(data_i),

    .mmu_dma_rd_o (cdma_rd_o),
    .mmu_dma_wr_o (cdma_wr_o),

    // mmu icache interface
    .icache_mmu_valid_i(icache_in_valid_i),
    .icache_valid_o  (icache_valid),
    .mmu_icache_addr_o(icache_addr_o),
    .mmu_icache_rd_o (icache_rd_o)
);

assign fetch_out_value_o    = fetch_value_w;
assign fetch_out_valid_o    = (vm_enable)?(icache_valid && itlb_hit):(icache_valid);
assign lsu_out_value_o      = dcache_wb_data_value;
assign lsu_out_valid_o      = (vm_enable)?(dcache_valid && dtlb_hit):(dcache_valid);

always @(*)begin
    dcache_addr_r = 32'h0;
    icache_addr_r = 32'h0;
    dcache_mask_r = 0;

    if(!vm_enable)
        dcache_addr_r = lsu_in_addr_i;
    else if(is_pte)
        dcache_addr_r = ptw_pte_addr_o;
    else
        dcache_addr_r = {dtlb_entry_o[29:10],lsu_in_addr_i[11:0]};
    
    if(!vm_enable)
        icache_addr_r = fetch_pc_i;
    else
        icache_addr_r = {itlb_entry_o[29:10],fetch_pc_i[11:0]};


    if(dcache_rd_c)
        dcache_mask_r = 4'hf;
    else if(dcache_wr_c)
        dcache_mask_r = lsu_in_mask_i;
    else
        dcache_mask_r = 4'h0;
end

// Others signal
always @(posedge clk_i or negedge rst_i) begin
    if(~rst_i)begin
        dcache_invalidate_o <= 1'b0;
        dcache_flush_o <= 1'b0;
        dcache_writeback_o <= 1'b0;
        dcache_zero_o <= 1'b0;
        icache_invalidate_o <= 1'b0;
    end else begin
        dcache_invalidate_o <= d_invalid;
        dcache_flush_o <= d_flush;
        dcache_writeback_o <= d_writeback;
        dcache_zero_o <= d_zero;
        icache_invalidate_o <= lsu_in_i_invalidate_i;
    end
end

// ============================= //
//      Page Fault Exeption      //
// ============================= //

// exception register
reg read_except_r;
reg write_except_r;
reg exe_except_r;

assign read_except_o = read_except_r;
assign write_except_o = write_except_r;
assign exe_except_o = exe_except_r;

always @(posedge clk_i or negedge rst_i)begin
    if(~rst_i)begin
        read_except_r <= 1'b0;
        write_except_r <= 1'b0;
        exe_except_r <= 1'b0; 
    end else begin
        read_except_r <= ptw_pte_fault_o[0] || (~dtlb_entry_o[`PAGE_READ] && dtlb_valid && lsu_in_rd_i);
        write_except_r <= ptw_pte_fault_o[1] || (~dtlb_entry_o[`PAGE_WRITE] && dtlb_valid && lsu_in_wr_i);
        exe_except_r <= ptw_pte_fault_o[2] || (~itlb_entry_o[`PAGE_EXEC] && itlb_valid && fetch_rd_i);
    end
end

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
    .valid_o  (itlb_valid),
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
    .valid_o  (dtlb_valid),
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

wire itlb_miss = itlb_req && ~itlb_hit;
wire dtlb_miss = dtlb_req && ~dtlb_hit;

wire [31:0] ptw_resp_data_i  = dcache_wb_data_value;
wire        ptw_resp_valid_i = dcache_valid;
wire        ptw_req_valid_i  = (itlb_miss || dtlb_miss) && vm_enable;
wire        ptw_error_i      = d_execption_i[0];
wire [31:0] ptw_req_addr_i;

assign ptw_req_addr_i = (itlb_req) ? fetch_pc_i : 
                        (dtlb_req) ? lsu_in_addr_i : 32'b0;

mmu_ptw ptw(
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .satp_i       (satp_i),
    .req_addr_i   (ptw_req_addr_i),
    .req_valid_i  (ptw_req_valid_i),
    .resp_data_i  (ptw_resp_data_i),
    .resp_valid_i (ptw_resp_valid_i),
    .pte_errow_i  (ptw_error_i),
    .req_target_i ({itlb_req, lsu_in_wr_i, lsu_in_rd_i}),
    .pte_addr_o   (ptw_pte_addr_o),
    .pte_value_o  (ptw_pte_value_o),
    .update_o     (is_update),
    .pte_fault_o  (ptw_pte_fault_o),
    .ptw_work_o   (is_pte)
);

endmodule
