module Computer(
    input clk,
    input rst_n
);
wire i_req, i_ready;
wire [31:0] i_mem_addr;
wire [31:0] inst;

wire d_mem_wr_en;
wire d_mem_rd_en;
wire d_mem_available;
wire i_mem_available;
wire [3:0] d_mem_ctrl;
wire [31:0] d_mem_addr;
wire [31:0] d_mem_wr_data;
wire [31:0] d_mem_rd_data;

DataMemory #(.SIZE(65536))
m_DataMemory(
    .rst_n(rst_n),
    .clk(clk),
    
    .i_addr(i_mem_addr),
    .inst(inst),
    .i_available_o(i_mem_available),
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
    .i_mem_available(i_mem_available),
    .i_req(i_req),
    .i_ready(i_ready),
    
    .d_mem_ctrl(d_mem_ctrl),
    .d_mem_addr(d_mem_addr),
    .d_mem_wr_en(d_mem_wr_en),
    .d_mem_rd_en(d_mem_rd_en),
    .d_mem_wr_data(d_mem_wr_data),
    .d_mem_rd_data(d_mem_rd_data),
    .d_mem_available(d_mem_available)
);

endmodule
