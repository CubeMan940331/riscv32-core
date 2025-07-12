module IF_ID_Reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire        clear,
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_4_i,
    output wire [31:0] pc_o,
    output wire [31:0] pc_4_o,
    input  wire [31:0] inst_i,
    output wire [31:0] inst_o
);

    PipelineRegister #(.WIDTH(32)) reg_pc   (.clk(clk), .rst_n(rst_n), .flush(clear), .enable(enable), .data_i(pc_i),   .data_o(pc_o));
    PipelineRegister #(.WIDTH(32)) reg_pc4  (.clk(clk), .rst_n(rst_n), .flush(clear), .enable(enable), .data_i(pc_4_i), .data_o(pc_4_o));
    PipelineRegister #(.WIDTH(32)) reg_inst (.clk(clk), .rst_n(rst_n), .flush(clear), .enable(enable), .data_i(inst_i), .data_o(inst_o));
endmodule
