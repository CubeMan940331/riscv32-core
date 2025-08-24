`include "riscv_defs.v"
module Writeback (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        en,
    input  wire        clear,
    // data_in
    input  wire        is_impl_i,
    input  wire        pc_valid_i,
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_p4_i,
    input  wire [4:0]  rd_i,
    input  wire [5:0]  exception_i,
    
    input  wire [31:0] bypass_i,
    input  wire [31:0] ALU_i,
    input  wire [31:0] MUL_DIV_i,
    input  wire [31:0] FPU_i,
    input  wire [31:0] mem_data_i,
    input  wire [31:0] csr_rd_data_i,
    // control_in
    input  wire        reg_wr_en_i,
    input wire         freg_wr_en_i,
    input  wire [2:0]  reg_w_sel_i,
    // ===================================
    // data_out
    output wire        is_impl_o,
    output wire        pc_valid_o,
    output wire [31:0] pc_o,
    output wire [ 4:0] rd_o,
    output wire [31:0] wb_data_o,

    // control_out
    output wire        reg_wr_en_o,
    output wire        freg_wr_en_o
);

// WB_Reg =====================
wire WB_is_impl_out;
wire WB_pc_valid_out /* verilator public */;
wire [31:0] WB_pc_out /* verilator public */;
wire [31:0] WB_pc_p4_out;
wire [4:0]  WB_rd_out;
wire [5:0]  WB_exception_out;

wire [31:0] WB_ALU_out;
wire [31:0] WB_MUL_DIV_out;
wire [31:0] WB_mem_data_out;
wire [31:0] WB_csr_rd_data_out;
wire [31:0] WB_FPU_out;
wire [31:0] WB_bypass_out;
// control_out
wire        WB_reg_wr_en_out;
wire        WB_freg_wr_en_out;
wire [2:0]  WB_reg_w_sel_out;

WB_Reg m_WB_Reg(
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .clear(clear),
    
    .is_impl_i(is_impl_i),
    .pc_valid_i(pc_valid_i),
    .pc_i(pc_i),
    .pc_p4_i(pc_p4_i),
    .rd_i(rd_i),
    .exception_i(exception_i),

    .bypass_i(bypass_i),
    .ALU_i(ALU_i),
    .MUL_DIV_i(MUL_DIV_i),
    .FPU_i(FPU_i[31:0]),
    .mem_data_i(mem_data_i),
    .csr_rd_data_i(csr_rd_data_i),
    
    // control_in
    .reg_wr_en_i(reg_wr_en_i),
    .freg_wr_en_i(freg_wr_en_i),
    .reg_w_sel_i(reg_w_sel_i),
    // ===================================
    // data_out
    .is_impl_o(WB_is_impl_out),
    .pc_valid_o(WB_pc_valid_out),
    .pc_o(WB_pc_out),
    .pc_p4_o(WB_pc_p4_out),
    .rd_o(WB_rd_out),
    .exception_o(WB_exception_out),

    .bypass_o(WB_bypass_out),
    .ALU_o(WB_ALU_out),
    .MUL_DIV_o(WB_MUL_DIV_out),
    .FPU_o(WB_FPU_out),
    .mem_data_o(WB_mem_data_out),
    .csr_rd_data_o(WB_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(WB_reg_wr_en_out),
    .freg_wr_en_o(WB_freg_wr_en_out),
    .reg_w_sel_o(WB_reg_w_sel_out)
);
assign is_impl_o = WB_is_impl_out;
assign pc_valid_o = WB_pc_valid_out;
assign pc_o = WB_pc_out;
assign reg_wr_en_o = (
    WB_reg_wr_en_out &
    WB_pc_valid_out &
    WB_is_impl_out &
    !((WB_exception_out&`EXCEPTION_TYPE_MASK) == `EXCEPTION_EXCEPTION)
);
assign freg_wr_en_o = (
    WB_freg_wr_en_out &
    WB_pc_valid_out &
    WB_is_impl_out &
    !((WB_exception_out&`EXCEPTION_TYPE_MASK) == `EXCEPTION_EXCEPTION)
);
assign rd_o = WB_rd_out;

// writeback select
reg [31:0] wb_data_r;
always @(*) begin
    wb_data_r = 32'b0;
    case (WB_reg_w_sel_out)
        3'b000:  wb_data_r = WB_pc_p4_out;
        3'b001:  wb_data_r = WB_ALU_out;
        3'b010:  wb_data_r = WB_mem_data_out;
        3'b011:  wb_data_r = WB_csr_rd_data_out;
        3'b100:  wb_data_r = WB_FPU_out;
        3'b101:  wb_data_r = WB_bypass_out;
        3'b110:  wb_data_r = WB_MUL_DIV_out;
        default: wb_data_r = 32'b0;
    endcase
end
assign wb_data_o = wb_data_r;

endmodule
