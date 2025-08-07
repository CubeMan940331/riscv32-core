`include "riscv_defs.v"
/* verilator lint_off UNUSEDSIGNAL */
module PipelineCPU (
    input clk,
    input rst_n,

    output [31:0] i_mem_addr,
    input  [31:0] inst,

    output [3:0] d_mem_ctrl,
    output d_mem_wr_en,
    output d_mem_rd_en,
    output [31:0] d_mem_addr,
    output [31:0] d_mem_wr_data,
    input  [31:0] d_mem_rd_data
);
//wires
//================================================================

// PC =========================
wire [1:0] pc_sel;
wire pc_en;
wire [31:0]pc_in;
wire [31:0]pc_out;
wire [31:0]pc_p4;

assign i_mem_addr = pc_out;

// ID_Reg =====================
wire ID_clear;
wire ID_en;

wire ID_pc_valid_out;
wire [31:0] ID_pc_out;
wire [31:0] ID_pc_p4_out;
wire [31:0] ID_inst_out;

// Decode ========================
wire [31:0]   decode_imm;
wire [6:0]    decode_opcode;
wire [2:0]    decode_funct3;
wire [6:0]    decode_funct7;

wire [4:0]    decode_rs1;
wire [4:0]    decode_rs2;
wire [4:0]    decode_rd;

wire [11:0]   decode_csr_addr;

// Control Logic ==============
wire is_impl;
wire reg_wr_en;
// 0: pc_p4, 1: ALU, 2: mem
wire [2:0] reg_w_sel;
wire mem_wr_en;
wire mem_rd_en;
wire [3:0] mem_ctrl;
wire is_j;
wire is_br;
// 0: PC, 1: rs1
wire ALU_sel1;
// 0: rs2, 1: imm
wire ALU_sel2;
wire [3:0] ALU_ctrl;
wire [2:0] cmp_op;
// csr
wire trap_ecall;
wire trap_ebreak;
wire inst_mret;

wire is_csr;
wire [2:0] csr_op;
wire is_csr_imm; // is csr[r w]i
wire csr_wr_en;
wire csr_sel; // rs1 or imm

wire [31:0] csr_rd_data;

// Register File ==============
wire [31:0] reg_data_in;
wire [31:0] reg_data1_out;
wire [31:0] reg_data2_out;

// EX_Reg =====================
wire EX_en;
wire EX_clear;
// data_out
wire EX_is_impl_out;
wire EX_pc_valid_out;
wire [31:0] EX_inst_out;
wire [31:0] EX_pc_out;
wire [31:0] EX_pc_p4_out;
wire [31:0] EX_reg_rd_data1_out;
wire [31:0] EX_reg_rd_data2_out;
wire [31:0] EX_imm_out;
wire [4:0]  EX_rd_out;
wire [4:0]  EX_rs1_out;
wire [4:0]  EX_rs2_out;
// control_out
wire EX_reg_wr_en_out;
wire [2:0] EX_reg_w_sel_out;
// mem
wire EX_mem_rd_en_out;
wire EX_mem_wr_en_out;
wire [3:0] EX_mem_ctrl_out;
// Br and Jump
wire EX_is_j_out;
wire EX_is_br_out;
// ALU
wire EX_ALU_sel1_out;
wire EX_ALU_sel2_out;
wire [3:0] EX_ALU_ctrl_out;
// BranchCmp
wire [2:0] EX_cmp_op_out;

wire [2:0] EX_funct3_out;
wire EX_funct7_out;

wire EX_done;
// ALU ========================
wire [31:0] ALU_out;

// BranchCmp ==================
wire br_taken; // indicate any branch happen (trigger by inst, csr unit)
wire [31:0] csr_pc_target;

// WB_Reg =====================
wire WB_en;
wire WB_clear;
wire WB_is_impl_out;
wire WB_pc_valid_out /* verilator public */;
wire [31:0] WB_pc_out /* verilator public */;
wire [31:0] WB_pc_p4_out;
wire [31:0] WB_ALU_out;
wire [31:0] WB_mem_data_out;
wire [4:0]  WB_rd_out;
wire [31:0] WB_csr_rd_data_out;
// control_out
wire        WB_reg_wr_en_out;
wire [2:0]  WB_reg_w_sel_out;

// Forward ====================
wire [1:0] EX_fwd1_sel;
wire [1:0] EX_fwd2_sel;

// Hazerd =====================
wire [3:0] stall;

//componets
//================================================================

PipelineCtrl m_PipelineCtrl(
    .br_taken(br_taken),
    .EX_stall(!EX_done),

    .pc_en(pc_en),
    .ID_en(ID_en),
    .ID_clear(ID_clear),
    .EX_en(EX_en),
    .EX_clear(EX_clear),
    .WB_en(WB_en),
    .WB_clear(WB_clear)
);

// ================================
// Instruction Fetch stage

PC m_PC(
    .clk(clk),
    .rst_n(rst_n),
    .en(pc_en),
    .pc_i(pc_in),
    .pc_o(pc_out)
);
assign pc_p4 = pc_out+4;

Mux3to1 #(.size(32)) m_PC_MUX(
    .sel(pc_sel),
    .s0(pc_p4),
    .s1(ALU_out),
    .s2(csr_pc_target),
    .out(pc_in)
);

// ================================
// Instruction Decode stage
ID_Reg m_ID_Reg(
    .clk(clk),
    .rst_n(rst_n),

    .en(ID_en),
    .clear(ID_clear),

    .pc_valid_i(1),
    .pc_valid_o(ID_pc_valid_out),
    .pc_i(pc_out),
    .pc_p4_i(pc_p4),
    .pc_o(ID_pc_out),
    .pc_p4_o(ID_pc_p4_out),

    .inst_i(inst),
    .inst_o(ID_inst_out)
);

Register m_Register(
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(WB_reg_wr_en_out & WB_is_impl_out),//write enable

    .rs1(ID_inst_out[19:15]),//addr
    .rs2(ID_inst_out[24:20]),//addr
    
    .rd(WB_rd_out),//addr
    .data_i(reg_data_in),
    
    .rd_data1_o(reg_data1_out),
    .rd_data2_o(reg_data2_out)
);

DecodeUnit m_DecodeUnit(
    .inst(ID_inst_out),
    .opcode(decode_opcode),
    .funct3(decode_funct3),
    .funct7(decode_funct7),
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .rd(decode_rd),
    .imm(decode_imm),

    .csr_addr(decode_csr_addr)
);

Control m_Control(
    .is_impl(is_impl),
    .inst(ID_inst_out),
    .reg_wr_en(reg_wr_en),
    .reg_w_sel(reg_w_sel),
    .mem_wr_en(mem_wr_en),
    .mem_rd_en(mem_rd_en),
    .mem_ctrl(mem_ctrl),
    .is_j(is_j),
    .is_br(is_br),
    .ALU_sel1(ALU_sel1),
    .ALU_sel2(ALU_sel2),
    .ALU_ctrl(ALU_ctrl),
    .cmp_op(cmp_op),
    
    .is_csr(is_csr),
    .csr_op(csr_op),
    .is_csr_imm(is_csr_imm),
    .csr_sel(csr_sel)
);

// ================================
// Execution stage
EX_Stage m_EX(
    .clk(clk),
    .rst_n(rst_n),
// Pipeline Reg ================
    .en(EX_en),
    .clear(EX_clear),
// inputs
    // data_in
    .is_impl_i(is_impl),
    .pc_valid_i(ID_pc_valid_out),
    .inst_i(ID_inst_out),
    .pc_p4_i(ID_pc_p4_out),
    .pc_i(ID_pc_out),

    .reg_rd_data1_i(reg_data1_out),
    .reg_rd_data2_i(reg_data2_out),

    .imm_i(decode_imm),

    .rd_i(decode_rd),
    .rs1_i(decode_rs1),
    .rs2_i(decode_rs2),
    // control_in
    .reg_wr_en_i(reg_wr_en),
    .reg_w_sel_i(reg_w_sel),
    // mem
    .mem_rd_en_i(mem_rd_en),
    .mem_wr_en_i(mem_wr_en),
    .mem_ctrl_i(mem_ctrl),
    // Br and Jump
    .is_j_i(is_j),
    .is_br_i(is_br),

    // ALU
    .ALU_sel1_i(ALU_sel1),
    .ALU_sel2_i(ALU_sel2),
    .ALU_ctrl_i(ALU_ctrl),

    .cmp_op_i(cmp_op),
    // CSR
    .csr_addr_i(decode_csr_addr),
    .is_csr_i(is_csr),
    .csr_op_i(csr_op),
    .is_csr_imm_i(is_csr_imm),
    .csr_sel_i(csr_sel),
// outputs
    .done_o(EX_done),
    // data_out
    .is_impl_o(EX_is_impl_out),
    .pc_valid_o(EX_pc_valid_out),
    .pc_o(EX_pc_out),
    .pc_p4_o(EX_pc_p4_out),

    .rs1_o(EX_rs1_out),
    .rs2_o(EX_rs2_out),
    .rd_o(EX_rd_out),
    // control_out
    .reg_wr_en_o(EX_reg_wr_en_out),
    .reg_w_sel_o(EX_reg_w_sel_out),
    // ALU
    .ALU_o(ALU_out),
    // CSR
    .csr_rd_data_o(csr_rd_data),
    // Branch Output
    .br_taken_o(br_taken),
    .pc_sel_o(pc_sel),
    .csr_pc_target_o(csr_pc_target),
    // D-mem Output
    .d_mem_ctrl_o(d_mem_ctrl),
    .d_mem_wr_en_o(d_mem_wr_en),
    .d_mem_rd_en_o(d_mem_rd_en),
    .d_mem_addr_o(d_mem_addr),
    .d_mem_wr_data_o(d_mem_wr_data),
// Forwarding ==================
    .WB_data_i(reg_data_in),
    .WB_rd_i(WB_rd_out),
    .WB_reg_wr_en_i(WB_reg_wr_en_out)
);

//================================
//write back stage

WB_Reg m_MEM_WB_Reg(
    .clk(clk),
    .rst_n(rst_n),
    .en(WB_en),
    .clear(WB_clear),
    
    .is_impl_i(EX_is_impl_out),
    .pc_valid_i(EX_pc_valid_out),
    .pc_i(EX_pc_out),
    .pc_p4_i(EX_pc_p4_out),
    .ALU_i(ALU_out),
    .mem_data_i(d_mem_rd_data),
    .rd_i(EX_rd_out),
    .csr_rd_data_i(csr_rd_data),
    // control_in
    .reg_wr_en_i(EX_reg_wr_en_out),
    .reg_w_sel_i(EX_reg_w_sel_out),
    // ===================================
    // data_out
    .is_impl_o(WB_is_impl_out),
    .pc_valid_o(WB_pc_valid_out),
    .pc_o(WB_pc_out),
    .pc_p4_o(WB_pc_p4_out),
    .ALU_o(WB_ALU_out),
    .mem_data_o(WB_mem_data_out),
    .rd_o(WB_rd_out),
    .csr_rd_data_o(WB_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(WB_reg_wr_en_out),
    .reg_w_sel_o(WB_reg_w_sel_out)
);

Mux4to1 #(.size(32)) m_Mux_WriteData(
    .sel(WB_reg_w_sel_out[1:0]),
    .s0(WB_pc_p4_out),
    .s1(WB_ALU_out),
    .s2(WB_mem_data_out),
    .s3(WB_csr_rd_data_out),
    .out(reg_data_in)
);

endmodule
