module Computer(
    input clk,
    input rst_n
);
wire i_req, i_ready;
wire [31:0] i_mem_addr;
wire [31:0] inst;
wire i_mem_available;

wire d_mem_wr_en /* verilator public */;
wire d_mem_rd_en /* verilator public */;
wire d_mem_available;
wire d_mem_flush;
wire d_mem_writeback;
wire d_mem_invalidate;
wire d_mem_cacheable;
wire [1:0] d_mem_exception = 2'b0;
wire [3:0] d_mem_ctrl;
wire [31:0] d_mem_addr /* verilator public */;
wire [31:0] d_mem_wr_data /* verilator public */;
wire [31:0] d_mem_rd_data /* verilator public */;

DataMemory #(.SIZE(65536))
m_DataMemory(
    .rst_n(rst_n),
    .clk(clk),
    
    .i_addr(i_mem_addr),
    .inst(inst),
    .i_req_i(i_req),
    .i_ready_o(i_ready),
    
    .wr_en(d_mem_wr_en),
    .rd_en(d_mem_rd_en),
    .ctrl(d_mem_ctrl),
    .address(d_mem_addr),
    .data_i(d_mem_wr_data),
    .data_o(d_mem_rd_data),
    .available_o(d_mem_available)
);

PipelineCPU m_core0(
    .clk(clk),
    .rst_n(rst_n),
    
    .i_mem_addr(i_mem_addr),
    .inst(inst),
    .i_req(i_req),
    .i_ready(i_ready),
    .i_mem_exception(1'b0),
    .i_mem_invalidate(),
    
    .d_mem_ctrl(d_mem_ctrl),
    .d_mem_wr_en(d_mem_wr_en),
    .d_mem_rd_en(d_mem_rd_en),
    .d_mem_addr(d_mem_addr),
    .d_mem_wr_data(d_mem_wr_data),
    .d_mem_rd_data(d_mem_rd_data),
    .d_mem_writeback(d_mem_writeback),
    .d_mem_invalidate(d_mem_invalidate),
    .d_mem_flush(d_mem_flush),
    .d_mem_cacheable(d_mem_cacheable),
    .d_mem_available(d_mem_available),
    .d_mem_exception(d_mem_exception),
    
    .cdma_data_o(),
    .cdma_addr_o(),
    .cdma_rdy_i(1'b0),
    .cdma_data_i(32'b0),
    .cdma_exception_i(2'b0)
);

endmodule
