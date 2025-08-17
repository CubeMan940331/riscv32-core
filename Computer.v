module Computer(
    input clk,
    input rst_n
);

wire [31:0] i_mem_addr;
wire [31:0] inst;

wire d_mem_wr_en;
wire d_mem_rd_en;
wire [3:0] d_mem_ctrl;
wire [31:0] d_mem_addr;
wire [31:0] d_mem_wr_data;
wire [31:0] d_mem_rd_data;

TCM_wrapper m_TCM_wrapper(
    .clk(clk),
    
    .i_addr(i_mem_addr),
    .i_data(inst),
    
    .d_rd_mode(d_mem_ctrl),
    .d_rd_en(d_mem_rd_en),
    .d_rd_data(d_mem_rd_data),
    .d_addr(d_mem_addr),
    .d_wr_valid(d_mem_wr_en),
    .d_wr_data(d_mem_wr_data)
);

PipelineCPU m_core0(
    .clk(clk),
    .rst_n(rst_n),
    
    .i_mem_addr(i_mem_addr),
    .inst(inst),
    
    .d_mem_ctrl(d_mem_ctrl),
    .d_mem_addr(d_mem_addr),
    .d_mem_wr_en(d_mem_wr_en),
    .d_mem_rd_en(d_mem_rd_en),
    .d_mem_wr_data(d_mem_wr_data),
    .d_mem_rd_data(d_mem_rd_data)
);

endmodule
