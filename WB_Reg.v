module MEM_WB_Reg (
    input  wire        clk,
    input  wire        rst_n,
    // data_in
    input  wire [31:0] pc4_i,
    input  wire [31:0] ALURes_i,
    input  wire [31:0] memData_i,
    input  wire [4:0]  rd_i,
    // control_in
    input  wire        regWrite_i,
    input  wire [1:0]  regWSrc_i,
    // ===================================
    // data_out
    output wire [31:0] pc4_o,
    output wire [31:0] ALURes_o,
    output wire [31:0] memData_o,
    output wire [4:0]  rd_o,    
    // control_out
    output wire        regWrite_o,
    output wire [1:0]  regWSrc_o
);
    wire flush = 1'b0;
    wire enable = 1'b1;
    Pipeline_Register #(.WIDTH(32)) reg_pc4      (.clk(clk), .rst_n(rst_n), .flush(flush), .enable(enable), .data_i(pc4_i),     .data_o(pc4_o));
    Pipeline_Register #(.WIDTH(32)) reg_aluRes   (.clk(clk), .rst_n(rst_n), .flush(flush), .enable(enable), .data_i(ALURes_i),  .data_o(ALURes_o));
    Pipeline_Register #(.WIDTH(32)) reg_memData  (.clk(clk), .rst_n(rst_n), .flush(flush), .enable(enable), .data_i(memData_i), .data_o(memData_o));
    Pipeline_Register #(.WIDTH(5))  reg_rd       (.clk(clk), .rst_n(rst_n), .flush(flush), .enable(enable), .data_i(rd_i),       .data_o(rd_o));
    Pipeline_Register #(.WIDTH(1))  reg_regWrite (.clk(clk), .rst_n(rst_n), .flush(flush), .enable(enable), .data_i(regWrite_i), .data_o(regWrite_o));
    Pipeline_Register #(.WIDTH(2))  reg_regWSrc  (.clk(clk), .rst_n(rst_n), .flush(flush), .enable(enable), .data_i(regWSrc_i), .data_o(regWSrc_o));
endmodule
