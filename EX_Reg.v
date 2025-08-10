module EX_Reg (
    input wire        clk,
    input wire        rst_n,
    input wire        en,
    input wire        clear,
//=================================
    // input
    // data
    input  wire        is_impl_i,
    input  wire        pc_valid_i,
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_p4_i,
    input  wire [31:0] inst_i,
    
    input  wire [31:0] reg_rd_data1_i,
    input  wire [31:0] reg_rd_data2_i,
    input  wire [31:0] freg_rd_data1_i,
    input  wire [31:0] freg_rd_data2_i,
    
    input  wire [31:0] imm_i,
    
    input  wire [4:0]  rd_i,
    input  wire [4:0]  rs1_i,
    input  wire [4:0]  rs2_i,
    // reg
    input wire        reg_wr_en_i,
    input wire        freg_wr_en_i,
    input wire [2:0]  reg_w_sel_i,
    // mem
    input wire        mem_wr_en_i,
    input wire        mem_rd_en_i,
    input wire [3:0]  mem_ctrl_i,
    // Br and Jump
    input wire        is_j_i,
    input wire        is_br_i,
    // ALU
    input wire        ALU_sel1_i,
    input wire        ALU_sel2_i,
    input wire [3:0]  ALU_ctrl_i,
    // cmp
    input wire [2:0]  cmp_op_i,
    
    // csr
    input wire [11:0] csr_addr_i,

    input wire is_csr_i,
    input wire [2:0] csr_op_i,
    input wire is_csr_imm_i, // is csr[r w]i

    // fpu
    input wire is_fpu_i,
    input wire FPU_sel1_i,

    input wire [1:0] bypass_sel_i,

    input wire [2:0]  funct3_i,
    input wire        funct7_i,
//=================================
    // output
    // data
    output wire         is_impl_o,
    output  wire        pc_valid_o,
    output  wire [31:0] pc_o,
    output  wire [31:0] pc_p4_o,
    output wire [31:0] inst_o,
    
    output wire [31:0] reg_rd_data1_o,
    output wire [31:0] reg_rd_data2_o,
    output wire [31:0] freg_rd_data1_o,
    output wire [31:0] freg_rd_data2_o,
    
    output wire [31:0] imm_o,
    
    output wire [4:0]  rd_o,
    output wire [4:0]  rs1_o,
    output wire [4:0]  rs2_o,
    
    // reg
    output wire        reg_wr_en_o,
    output wire        freg_wr_en_o,
    output wire [2:0]  reg_w_sel_o,
    // mem
    output wire        mem_wr_en_o,
    output wire        mem_rd_en_o,
    output wire [3:0]  mem_ctrl_o,
    // Br and Jump
    output wire        is_j_o,
    output wire        is_br_o,
    // ALU
    output wire        ALU_sel1_o,
    output wire        ALU_sel2_o,
    output wire [3:0]  ALU_ctrl_o,
    // cmp
    output wire [2:0]  cmp_op_o,
    // csr
    output wire [11:0] csr_addr_o,

    output wire is_csr_o,
    output wire [2:0] csr_op_o,
    output wire is_csr_imm_o, // is csr[r w]i

    // fpu
    output wire is_fpu_o,
    output wire FPU_sel1_o,

    output wire [1:0] bypass_sel_o,

    output wire [2:0]  funct3_o,
    output wire        funct7_o
);
    // data
    PipelineRegister #(.WIDTH( 1)) reg_is_impl   (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(is_impl_i),   .data_o(is_impl_o));
    PipelineRegister #(.WIDTH( 1)) reg_pc_valid  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .data_i(pc_valid_i),   .data_o(pc_valid_o));
    PipelineRegister #(.WIDTH(32)) reg_inst      (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(inst_i),     .data_o(inst_o));
    PipelineRegister #(.WIDTH(32)) reg_pc        (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(pc_i),      .data_o(pc_o));
    PipelineRegister #(.WIDTH(32)) reg_pc_p4     (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(pc_p4_i),   .data_o(pc_p4_o));
    
    PipelineRegister #(.WIDTH(32)) reg_rd_data1  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_rd_data1_i), .data_o(reg_rd_data1_o));
    PipelineRegister #(.WIDTH(32)) reg_rd_data2  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_rd_data2_i), .data_o(reg_rd_data2_o));
    PipelineRegister #(.WIDTH(32)) reg_frd_data1 (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(freg_rd_data1_i), .data_o(freg_rd_data1_o));
    PipelineRegister #(.WIDTH(32)) reg_frd_data2 (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(freg_rd_data2_i), .data_o(freg_rd_data2_o));
    
    PipelineRegister #(.WIDTH(32)) reg_imm       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(imm_i),      .data_o(imm_o));
    PipelineRegister #(.WIDTH(5))  reg_rd        (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rd_i),       .data_o(rd_o));
    PipelineRegister #(.WIDTH(5))  reg_rs1       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rs1_i),      .data_o(rs1_o));
    PipelineRegister #(.WIDTH(5))  reg_rs2       (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(rs2_i),      .data_o(rs2_o));

    // control
    PipelineRegister #(.WIDTH(1))  reg_reg_wr_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_wr_en_i), .data_o(reg_wr_en_o));
    PipelineRegister #(.WIDTH(1))  reg_freg_wr_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(freg_wr_en_i), .data_o(freg_wr_en_o));
    PipelineRegister #(.WIDTH(3))  reg_reg_w_sel (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(reg_w_sel_i), .data_o(reg_w_sel_o));
    // mem
    PipelineRegister #(.WIDTH(1))  reg_mem_rd_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(mem_rd_en_i), .data_o(mem_rd_en_o));
    PipelineRegister #(.WIDTH(1))  reg_mem_wr_en (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(mem_wr_en_i), .data_o(mem_wr_en_o));
    PipelineRegister #(.WIDTH(4))  reg_mem_ctrl  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(mem_ctrl_i), .data_o(mem_ctrl_o));
    // Br and Jump
    PipelineRegister #(.WIDTH(1))  reg_is_j      (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_j_i), .data_o(is_j_o));
    PipelineRegister #(.WIDTH(1))  reg_is_br     (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_br_i), .data_o(is_br_o));
    // ALU
    PipelineRegister #(.WIDTH(1))  reg_ALU_sel1  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(ALU_sel1_i), .data_o(ALU_sel1_o));
    PipelineRegister #(.WIDTH(1))  reg_ALU_sel2  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(ALU_sel2_i), .data_o(ALU_sel2_o));
    PipelineRegister #(.WIDTH(4))  reg_ALU_ctrl  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(ALU_ctrl_i), .data_o(ALU_ctrl_o));
    // cmp
    PipelineRegister #(.WIDTH(3))  reg_cmp_op    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(cmp_op_i), .data_o(cmp_op_o));
    // csr
    PipelineRegister #(.WIDTH(12)) reg_csr_addr  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(csr_addr_i), .data_o(csr_addr_o));
    PipelineRegister #(.WIDTH(1))  reg_is_csr    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_csr_i), .data_o(is_csr_o));
    PipelineRegister #(.WIDTH(3))  reg_csr_op    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(csr_op_i), .data_o(csr_op_o));
    PipelineRegister #(.WIDTH(1))  reg_is_csr_imm (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_csr_imm_i), .data_o(is_csr_imm_o));
    // fpu
    PipelineRegister #(.WIDTH(1))  reg_is_fpu    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(is_fpu_i), .data_o(is_fpu_o));
    PipelineRegister #(.WIDTH(1))  reg_FPU_sel1  (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(FPU_sel1_i), .data_o(FPU_sel1_o));
    // bypass
    PipelineRegister #(.WIDTH(2))  reg_bypass_sel (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(bypass_sel_i), .data_o(bypass_sel_o));

    // funct3 and funct7
    PipelineRegister #(.WIDTH(3))  reg_funct3    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(funct3_i), .data_o(funct3_o));
    PipelineRegister #(.WIDTH(1))  reg_funct7    (.clk(clk), .rst_n(rst_n), .clear(clear), .en(en),  .data_i(funct7_i), .data_o(funct7_o));
endmodule
