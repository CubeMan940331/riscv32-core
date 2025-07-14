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

DataMemory m_DataMemory(
    .rst_n      (rst_n),
    .clk        (clk),
    .wr_en      (d_mem_wr_en),
    .rd_en      (d_mem_rd_en),
    .ctrl       (d_mem_ctrl),
    .address    (d_mem_addr),
    .data_i     (d_mem_wr_data),
    .data_o     (d_mem_rd_data)
);

InstructionMemory m_InstMem(
    .address(i_mem_addr),
    .inst(inst)
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
