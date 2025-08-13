`include "LSU.v"
`include "MMU.v"

module mem_top(
     input          clk_i
    ,input          rst_i
    ,input  [31:0]  mmu_sapt_i
    ,input  [31:0]  lsu_opcode_i
    ,input          lsu_opcode_valid_i
    ,input  [ 4:0]  lsu_opcode_rd_i
    ,input  [31:0]  lsu_opcode_ra_data_i
    ,input  [31:0]  lsu_opcode_rb_data_i

    ,output [31:0]  lsu_writeback_data_o
    ,output         lsu_writeback_valid_o
    ,output [ 4:0]  lsu_writeback_rd_o
    ,output         stall_o

    ,output [ 5:0]  exception_o
);

// Parameter 
localparam ADDR_MIN = 32'h00000000;
localparam ADDR_MAX = 32'h08000000; // 64 * 2KB
localparam ICACHE_ADDR_MIN = 32'h00000400;
localparam ICACHE_ADDR_MAX = 32'h00000000;

localparam TAG_START    = 14;
localparam IDX_START    = 5;
localparam OFFSET_START = 2;


// Fetch
wire [31:0] fetch_mmu_pc;
wire        fetch_mmu_rd;

assign fetch_mmu_pc = 32'h0;
assign fetch_mmu_rd = 0;

// Icache
wire [31:0] icache_mmu_value;
wire        icache_mmu_valid;

assign icache_mmu_value = 32'h0;
assign icache_mmu_valid = 0;

// LSU
wire [31:0] lsu_mmu_addr;
wire [31:0] lsu_mmu_data;
wire        lsu_mmu_rd;
wire [ 3:0] lsu_mmu_wr;
wire        lsu_mmu_dflush;
wire        lsu_mmu_dinvalidafte;
wire        lsu_mmu_writeback;
wire        lsu_stall_o;
wire [ 5:0] lsu_exception_o;

// MMU
wire [31:0] mmu_fetch_value;
wire        mmu_fetch_valid;
wire        mmu_inst_fault;
wire [31:0] mmu_lsu_data;
wire        mmu_lsu_valid;
wire        mmu_lsu_load_fault;
wire        mmu_lsu_store_fault;
wire [31:0] mmu_dcache_addr;
wire [31:0] mmu_dcache_data;
wire        mmu_dcache_rd;
wire        mmu_dcache_wr;
wire [ 3:0] mmu_dcache_mask;
wire        mmu_dcache_flush;
wire        mmu_dcache_writeback;
wire        mmu_dcache_invalidate;
wire [31:0] mmu_icache_addr;
wire        mmu_icache_valid;
wire [ 5:0] mmu_exception_o;

// Dcache
wire [31:0] dcache_mmu_data;
// wire        dcache_stall_cpu;
wire        dcache_mmu_available;

// Output
assign exception_o = (lsu_exception_o != 6'b0)?lsu_exception_o:
                     (mmu_exception_o != 6'b0)?mmu_exception_o:
                     6'b0;

assign stall_o = lsu_stall_o;

mmu #(
    .ADDR_MIN(ADDR_MIN),
    .ADDR_MAX(ADDR_MAX),
    .ICACHE_ADDR_MIN(ICACHE_ADDR_MIN),
    .ICACHE_ADDR_MAX(ICACHE_ADDR_MAX) 
) u_mmu (
    .clk_i               (clk_i               ),
    .rst_i               (rst_i               ),
    .satp_i              (mmu_sapt_i              ),
    .fetch_pc_i          (fetch_mmu_pc          ),
    .fetch_rd_i          (fetch_mmu_rd          ),
    .lsu_in_addr_i       (lsu_mmu_addr       ),
    .lsu_in_data_i       (lsu_mmu_data       ),
    .lsu_in_rd_i         (lsu_mmu_rd         ),
    .lsu_in_wr_i         (lsu_mmu_wr         ),
    .lsu_in_flush_i      (lsu_mmu_dflush      ),
    .lsu_in_invalidate_i (lsu_mmu_dinvalidafte ),
    .lsu_in_writeback_i  (lsu_mmu_writeback  ),
    .dcache_in_value_i   (dcache_mmu_data   ),
    .dcache_in_valid_i   (dcache_valid),
    .icache_in_value_i   (icache_mmu_value   ),
    .icache_in_valid_i   (icache_mmu_valid      ),
    .fetch_out_value_o   (mmu_fetch_value   ),
    .fetch_out_valid_o   (mmu_fetch_valid   ),
    .lsu_out_value_o     (mmu_lsu_data     ),
    .lsu_out_valid_o     (mmu_lsu_valid     ),
    .dcache_addr_o       (mmu_dcache_addr       ),
    .dcache_value_o      (mmu_dcache_data      ),
    .dcache_rd_o         (mmu_dcache_rd         ),
    .dcache_wr_o         (mmu_dcache_wr         ),
    .dcache_mask_o       (mmu_dcache_mask       ),
    .dcache_flush_o      (mmu_dcache_flush      ),
    .dcache_invalidate_o (mmu_dcache_invalidate ),
    .dcache_writeback_o  (mmu_dcache_writeback  ),
    .icache_addr_o       (mmu_icache_addr       ),
    .icache_valid_o      (mmu_icache_valid      ),
    .load_fault_o        (mmu_lsu_load_fault        ),
    .store_fault_o       (mmu_lsu_store_fault       ),
    .inst_fault_o        (mmu_inst_fault        ),
    .mmu_exception_o     (mmu_exception_o     )
);

lsu u_lsu(
    .clk_i             (clk_i             ),
    .rst_i             (rst_i             ),
    .opcode_opcode_i   (lsu_opcode_i   ),
    .opcode_rd_i       (lsu_opcode_rd_i       ),
    .opcode_ra_data_i  (lsu_opcode_ra_data_i  ),
    .opcode_rb_data_i  (lsu_opcode_rb_data_i  ),
    .opcode_valid_i    (lsu_opcode_valid_i    ),
    .mmu_value_i       (mmu_lsu_data       ),
    .mmu_valid_i       (mmu_lsu_valid       ),
    .mmu_load_fault    (mmu_lsu_load_fault    ),
    .mmu_store_fault   (mmu_lsu_store_fault   ),
    .mmu_addr_o        (lsu_mmu_addr        ),
    .mmu_data_o        (lsu_mmu_data        ),
    .mmu_rd_o          (lsu_mmu_rd          ),
    .mmu_wr_o          (lsu_mmu_wr          ),
    .mmu_dflush_o      (lsu_mmu_dflush      ),
    .mmu_dinvalidate_o (lsu_mmu_dinvalidafte ),
    .mmu_dwriteback_o  (lsu_mmu_writeback  ),
    .writeback_value_o (lsu_writeback_data_o ),
    .writeback_rd_o    (lsu_writeback_rd_o    ),
    .writeback_valid_o (lsu_writeback_valid_o ),
    .stall_o           (lsu_stall_o           ),
    .exception_o       (lsu_exception_o       )
);

reg [31:0] dcache_in_addr_r;
reg [31:0] dcache_in_value_r;
reg        dcache_wr_r;
reg        dcache_rd_r;
reg        pre_available;
wire       dcache_valid;

wire debug_w;
assign debug_w = !(dcache_mmu_data == 32'h0);
assign dcache_valid = (pre_available)?(dcache_mmu_available && dcache_rd_r):0;

always @(posedge clk_i or negedge rst_i) begin
    if(!rst_i)begin
        dcache_in_value_r  <= 32'h0;
        dcache_wr_r        <= 0;
        dcache_rd_r        <= 0;
        pre_available      <= 1;

    end else begin
        dcache_in_addr_r   <= mmu_dcache_addr;
        dcache_in_value_r  <= mmu_dcache_data;
        dcache_wr_r        <= mmu_dcache_wr;
        pre_available <= dcache_mmu_available;

        if(dcache_rd_r && dcache_mmu_available)
            dcache_rd_r        <= (dcache_mmu_available && debug_w)?mmu_dcache_rd:dcache_rd_r;
        else
            dcache_rd_r        <= (dcache_mmu_available)?mmu_dcache_rd:dcache_rd_r;
    end 
end

dcache_top u_dcache_top(
    .clk             (clk_i             ),
    .rst_n           (rst_i           ),
    .tag_i           (dcache_in_addr_r[31:TAG_START]           ),
    .idx_i           (dcache_in_addr_r[TAG_START-1:IDX_START]           ),
    .word_offset_i   (dcache_in_addr_r[IDX_START-1:OFFSET_START]   ),
    .mask            (mmu_dcache_mask      ),
    .data_i          (dcache_in_value_r          ),
    .req_wr          (dcache_wr_r          ),
    .req_rd          (dcache_rd_r),
    .data_o          (dcache_mmu_data          ),
    // .stall_cpu       (dcache_stall_cpu       ),
    .cache_available (dcache_mmu_available )
);



endmodule