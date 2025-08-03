`include "riscv_defs.v"

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
wire reg_wr_en;
// 0: pc_p4, 1: ALU, 2: mem, 3: csr, 4: MUL, 5: DIV
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
// mul/div
wire [2:0] MUL_DIV_ctrl;
// csr
wire trap_ecall;
wire trap_ebreak;
wire inst_mret;

wire is_csr;
wire [2:0] csr_op;
wire is_csr_imm; // is csr[r w]i
wire csr_wr_en;
wire csr_sel; // rs1 or imm

// Register File ==============
wire [31:0] reg_data_in;
wire [31:0] reg_data1_out;
wire [31:0] reg_data2_out;

// EX_Reg =====================
wire EX_en;
wire EX_clear;
// data_out
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
// MUL/DIV
wire [2:0] EX_MUL_DIV_ctrl_out;
//csr
wire [11:0]  EX_csr_addr_out;
wire EX_trap_ecall_out;
wire EX_trap_ebreak_out;
wire EX_inst_mret_out;

wire EX_is_csr_out;
wire [2:0] EX_csr_op_out;
wire EX_is_csr_imm_out; // is csr[r w]i
wire EX_csr_wr_en_out;
wire EX_csr_sel_out; // rs1 or imm

wire [2:0] EX_funct3_out;
wire EX_funct7_out;

// ALU ========================
wire [31:0] ALU_in1;
wire [31:0] ALU_in2;
wire [31:0] ALU_out;
wire zero_flag;

// MUL/DIV ========================
wire [31:0] MUL_out;
wire [31:0] DIV_out;

// BranchCmp ==================
wire br_taken; // indicate any branch happen (trigger by inst, csr unit)

// CSR ========================
wire [31:0] csr_wr_data; // from CSR to CSRFile
wire [31:0] csr_rd_data; // output of CSRFile
wire [31:0] csr_pc_target;
wire csr_is_br;

// CSRFile=====================
wire [1:0] csr_priv;
wire [31:0] csr_mstatus;
//wire [31:0] csr_satp;
wire [31:0] csr_interrupt;

// EX_Sub_Reg ====================
// EX1
wire [31:0] EX1_pc_p4_out;
wire [31:0] EX1_ALU_out;
wire [31:0] EX1_reg_rd_data2_out; 
wire [4:0]  EX1_rd_out;
wire [31:0] EX1_csr_rd_data_out;

wire        EX1_reg_wr_en_out;
wire [2:0]  EX1_reg_w_sel_out;
wire        EX1_mem_wr_en_out;
wire        EX1_mem_rd_en_out;
wire [3:0]  EX1_mem_ctrl_out;
// EX2
wire [31:0] EX2_pc_p4_out;
wire [31:0] EX2_ALU_out;
wire [31:0] EX2_reg_rd_data2_out; 
wire [4:0]  EX2_rd_out;
wire [31:0] EX2_csr_rd_data_out;

wire        EX2_reg_wr_en_out;
wire [2:0]  EX2_reg_w_sel_out;
wire        EX2_mem_wr_en_out;
wire        EX2_mem_rd_en_out;
wire [3:0]  EX2_mem_ctrl_out;
// EX3
wire [31:0] EX3_pc_p4_out;
wire [31:0] EX3_ALU_out;
wire [31:0] EX3_reg_rd_data2_out; 
wire [4:0]  EX3_rd_out;
wire [31:0] EX3_csr_rd_data_out;

wire        EX3_reg_wr_en_out;
wire [2:0]  EX3_reg_w_sel_out;
wire        EX3_mem_wr_en_out;
wire        EX3_mem_rd_en_out;
wire [3:0]  EX3_mem_ctrl_out;

// MEM_Reg ====================
wire [31:0] MEM_pc_p4_out;
wire [31:0] MEM_ALU_out;
wire [31:0] MEM_reg_rd_data2_out; 
wire [4:0]  MEM_rd_out;
wire [31:0] MEM_csr_rd_data_out;

wire        MEM_reg_wr_en_out;
wire [2:0]  MEM_reg_w_sel_out;
wire        MEM_mem_wr_en_out;
wire        MEM_mem_rd_en_out;
wire [3:0]  MEM_mem_ctrl_out;

assign d_mem_ctrl = MEM_mem_ctrl_out;
assign d_mem_wr_en = MEM_mem_wr_en_out;
assign d_mem_rd_en = MEM_mem_rd_en_out;
assign d_mem_addr = MEM_ALU_out;
assign d_mem_wr_data = MEM_reg_rd_data2_out;

// WB_Reg =====================
wire [31:0] WB_pc_p4_out;
wire [31:0] WB_ALU_out;
wire [31:0] WB_mem_data_out;
wire [4:0]  WB_rd_out;
wire [31:0] WB_csr_rd_data_out;
// control_out
wire        WB_reg_wr_en_out;
wire [2:0]  WB_reg_w_sel_out;

// EX Forward Mux =============
wire [31:0] EX_fwd_ALU1;
wire [31:0] EX_fwd_ALU2;
wire [31:0] EX_fwd_csr1;
wire [31:0] EX_fwd_csr2;
wire [31:0] EX_fwd_data1;
wire [31:0] EX_fwd_data2;

// Forward ====================
wire [1:0] EX_fwd1_stg_sel;
wire [1:0] EX_fwd2_stg_sel;
wire [1:0] EX_fwd1_sel;
wire [1:0] EX_fwd2_sel;

// Hazerd =====================
wire [3:0] stall;

//componets
//================================================================

ForwardUnit m_Forward(
    .EX_rs1(EX_rs1_out),
    .EX_rs2(EX_rs2_out),

    .EX1_rd(EX1_rd_out),
    .EX2_rd(EX2_rd_out),
    .EX3_rd(EX3_rd_out),
    .EX1_reg_wr_en(EX1_reg_wr_en_out),
    .EX2_reg_wr_en(EX2_reg_wr_en_out),
    .EX3_reg_wr_en(EX3_reg_wr_en_out),
    .EX1_reg_w_sel(EX1_reg_w_sel_out),
    .EX2_reg_w_sel(EX2_reg_w_sel_out),
    .EX3_reg_w_sel(EX3_reg_w_sel_out),

    .MEM_rd(MEM_rd_out),
    .MEM_reg_wr_en(MEM_reg_wr_en_out),
    .MEM_reg_w_sel(MEM_reg_w_sel_out),

    .WB_rd(WB_rd_out),
    .WB_reg_wr_en(WB_reg_wr_en_out),

    .EX_fwd_stg_sel1(EX_fwd1_stg_sel),
    .EX_fwd_stg_sel2(EX_fwd2_stg_sel),
    .EX_fwd_sel1(EX_fwd1_sel),
    .EX_fwd_sel2(EX_fwd2_sel)
);

HazardUnit m_Hazard(
    .EX_mem_rd_en   (EX_mem_rd_en_out),
    .EX_rd          (EX_rd_out),
    .ID_rs1         (ID_inst_out[19:15]),
    .ID_rs2         (ID_inst_out[24:20]),
    .stall          (stall)
);

PipelineCtrl m_PipelineCtrl(
    .br_taken(br_taken),
    .stall(stall),

    .pc_en(pc_en),
    .ID_en(ID_en),
    .ID_clear(ID_clear),
    .EX_en(EX_en),
    .EX_clear(EX_clear)
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

    .wr_en(WB_reg_wr_en_out),//write enable

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
    .MUL_DIV_ctrl(MUL_DIV_ctrl),

    .trap_ecall(trap_ecall),
    .trap_ebreak(trap_ebreak),
    .inst_mret(inst_mret),
    
    .is_csr(is_csr),
    .csr_op(csr_op),
    .is_csr_imm(is_csr_imm),
    .csr_wr_en(csr_wr_en),
    .csr_sel(csr_sel)
);

// ================================
// Execution stage

EX_Reg m_EX_Reg(
    .clk(clk),
    .rst_n(rst_n),
    .en(EX_en),
    .clear(EX_clear),
    // data_in
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

    // MUL/DIV
    .MUL_DIV_ctrl_i(MUL_DIV_ctrl),

    // csr
    .csr_addr_i(decode_csr_addr),

    .trap_ecall_i(trap_ecall),
    .trap_ebreak_i(trap_ebreak),
    .inst_mret_i(inst_mret),

    .is_csr_i(is_csr),
    .csr_op_i(csr_op),
    .is_csr_imm_i(is_csr_imm),
    .csr_wr_en_i(csr_wr_en),
    .csr_sel_i(csr_sel),

    .funct3_i(decode_funct3),
    .funct7_i(decode_funct7[5]),
    //=================================
    // data_out
    .pc_p4_o(EX_pc_p4_out),
    .pc_o(EX_pc_out),
    .reg_rd_data1_o(EX_reg_rd_data1_out),
    .reg_rd_data2_o(EX_reg_rd_data2_out),
    .imm_o(EX_imm_out),
    .rd_o(EX_rd_out),
    .rs1_o(EX_rs1_out),
    .rs2_o(EX_rs2_out),

    // control_out
    .reg_wr_en_o(EX_reg_wr_en_out),
    .reg_w_sel_o(EX_reg_w_sel_out),
    // mem
    .mem_rd_en_o(EX_mem_rd_en_out),
    .mem_wr_en_o(EX_mem_wr_en_out),
    .mem_ctrl_o(EX_mem_ctrl_out),
    // Br and Jump
    .is_j_o(EX_is_j_out),
    .is_br_o(EX_is_br_out),

    // ALU
    .ALU_sel1_o(EX_ALU_sel1_out),
    .ALU_sel2_o(EX_ALU_sel2_out),
    .ALU_ctrl_o(EX_ALU_ctrl_out),
    // BranchCmp
    .cmp_op_o(EX_cmp_op_out),
    // MUL/DIV
    .MUL_DIV_ctrl_o(EX_MUL_DIV_ctrl_out),
    // csr
    .csr_addr_o(EX_csr_addr_out),
    .trap_ebreak_o(EX_trap_ebreak_out),
    .trap_ecall_o(EX_trap_ecall_out),
    .inst_mret_o(EX_inst_mret_out),
    .is_csr_o(EX_is_csr_out),
    .csr_op_o(EX_csr_op_out),
    .is_csr_imm_o(EX_is_csr_imm_out),
    .csr_wr_en_o(EX_csr_wr_en_out),
    .csr_sel_o(EX_csr_sel_out),

    .funct3_o(EX_funct3_out),
    .funct7_o(EX_funct7_out)
);

Mux4to1 #(.size(32)) m_EX_fwd1_ALU_MUX(
    .sel(EX_fwd1_stg_sel),
    .s0(EX1_ALU_out),
    .s1(EX2_ALU_out),
    .s2(EX3_ALU_out),
    .s3(MEM_ALU_out),
    .out(EX_fwd_ALU1)
);

Mux4to1 #(.size(32)) m_EX_fwd1_csr_MUX(
    .sel(EX_fwd1_stg_sel),
    .s0(EX1_csr_rd_data_out),
    .s1(EX2_csr_rd_data_out),
    .s2(EX3_csr_rd_data_out),
    .s3(MEM_csr_rd_data_out),
    .out(EX_fwd_csr1)
);

Mux4to1 #(.size(32)) m_EX_fwd1_MUX(
    .sel(EX_fwd1_sel),
    .s0(reg_data_in),
    .s1(EX_reg_rd_data1_out),
    .s2(EX_fwd_ALU1),
    .s3(EX_fwd_csr1),
    .out(EX_fwd_data1)
);
Mux2to1 #(.size(32)) m_ALU_SRC1_MUX(
    .sel(EX_ALU_sel1_out),
    .s0(EX_pc_out),
    .s1(EX_fwd_data1),
    .out(ALU_in1)
);

Mux4to1 #(.size(32)) m_EX_fwd2_ALU_MUX(
    .sel(EX_fwd2_stg_sel),
    .s0(EX1_ALU_out),
    .s1(EX2_ALU_out),
    .s2(EX3_ALU_out),
    .s3(MEM_ALU_out),
    .out(EX_fwd_ALU2)
);

Mux4to1 #(.size(32)) m_EX_fwd2_csr_MUX(
    .sel(EX_fwd2_stg_sel),
    .s0(EX1_csr_rd_data_out),
    .s1(EX2_csr_rd_data_out),
    .s2(EX3_csr_rd_data_out),
    .s3(MEM_csr_rd_data_out),
    .out(EX_fwd_csr2)
);

Mux4to1 #(.size(32)) m_EX_fwd2_MUX(
    .sel(EX_fwd2_sel),
    .s0(reg_data_in),
    .s1(EX_reg_rd_data2_out),
    .s2(EX_fwd_ALU2),
    .s3(EX_fwd_csr2),
    .out(EX_fwd_data2)
);
Mux2to1 #(.size(32)) m_ALU_SRC2_MUX(
    .sel(EX_ALU_sel2_out),
    .s0(EX_fwd_data2),
    .s1(EX_imm_out),
    .out(ALU_in2)
);

ALU_top m_ALU(
    .ALU_ctrl(EX_ALU_ctrl_out),
    .a(ALU_in1),
    .b(ALU_in2),
    .out(ALU_out)
);

WallaceMultiplier m_WallaceMultiplier(
    .clk(clk),
    .rst_n(rst_n),
    .multiplicand(ALU_in1), 
    .multiplier(ALU_in2),
    .MUL_DIV_ctrl(EX_MUL_DIV_ctrl_out),
    .MUL_out(MUL_out)
);

SRTDivider m_SRTDivider(
    .clk(clk),
    .rst_n(rst_n),
    .remainder(ALU_in1), 
    .divisor(ALU_in2),
    .MUL_DIV_ctrl(EX_MUL_DIV_ctrl_out),
    .DIV_out(DIV_out)
);

BranchUnit m_BranchUnit(
    .is_br(EX_is_br_out),
    .is_j(EX_is_j_out),
    .is_csr_br(csr_is_br),

    .cmp_op(EX_cmp_op_out),
    .reg_rd_data1(EX_fwd_data1),
    .reg_rd_data2(EX_fwd_data2),
    
    .br_taken(br_taken),
    .pc_sel(pc_sel)
);

CSRFile m_CSRFile(
    .clk(clk)
    ,.rst_n(rst_n)
    // csr access
    ,.cpu_id_i(0)
    ,.misa_i(`MISA_RV32 | `MISA_RVI)

    ,.exception_i(EX_trap_ecall_out ? `EXCEPTION_ECALL_M: 
                 (EX_trap_ebreak_out ? 6'd0 :
                 (EX_inst_mret_out ? `EXCEPTION_ERET_M : 0)))
    ,.exception_pc_i(EX_pc_out)
    ,.exception_addr_i(0) // only consider ecall for now

    ,.csr_rd_addr_i(EX_csr_addr_out)
    ,.csr_rd_data_o(csr_rd_data)
    
    ,.csr_wr_en_i(EX_csr_wr_en_out)
    ,.csr_wr_addr_i(EX_csr_addr_out)
    ,.csr_wr_data_i(csr_wr_data)

    ,.csr_branch_o(csr_is_br)
    ,.csr_target_o(csr_pc_target)

    // CSR registers
    ,.priv_o(csr_priv)
    ,.mstatus_o(csr_mstatus)
    //,.satp_o(csr_satp)

    ,.interrupt_o(csr_interrupt)
);

CSR m_CSR(
    .csr_op_i(EX_csr_op_out),
    .is_csr_imm_i(EX_is_csr_imm_out),
    .imm_i(EX_imm_out),
    .reg_rd_data1_i(EX_fwd_data1),
    .csr_old_i(csr_rd_data),

    .csr_wdata_o(csr_wr_data)
);

// ================================
// Execution sub stages

EX_Sub_Reg m_EX_1_Reg(
    .clk(clk),
    .rst_n(rst_n),
    // data_in
    .pc_p4_i(EX_pc_p4_out),
    .ALU_i(ALU_out),
    .reg_rd_data2_i(EX_fwd_data2),
    .rd_i(EX_rd_out),
    .csr_rd_data_i(csr_rd_data),
    // control_in
    .reg_wr_en_i(EX_reg_wr_en_out),
    .reg_w_sel_i(EX_reg_w_sel_out),

    .mem_wr_en_i(EX_mem_wr_en_out),
    .mem_rd_en_i(EX_mem_rd_en_out),
    .mem_ctrl_i(EX_mem_ctrl_out),
    // ===================================
    // data_out
    .pc_p4_o(EX1_pc_p4_out),
    .ALU_o(EX1_ALU_out),
    .reg_rd_data2_o(EX1_reg_rd_data2_out),
    .rd_o(EX1_rd_out),
    .csr_rd_data_o(EX1_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(EX1_reg_wr_en_out),
    .reg_w_sel_o(EX1_reg_w_sel_out),
    .mem_wr_en_o(EX1_mem_wr_en_out),
    .mem_rd_en_o(EX1_mem_rd_en_out),
    .mem_ctrl_o(EX1_mem_ctrl_out)
);

EX_Sub_Reg m_EX_2_Reg(
    .clk(clk),
    .rst_n(rst_n),
    // data_in
    .pc_p4_i(EX1_pc_p4_out),
    .ALU_i(EX1_ALU_out),
    .reg_rd_data2_i(EX1_reg_rd_data2_out),
    .rd_i(EX1_rd_out),
    .csr_rd_data_i(EX1_csr_rd_data_out),
    // control_in
    .reg_wr_en_i(EX1_reg_wr_en_out),
    .reg_w_sel_i(EX1_reg_w_sel_out),

    .mem_wr_en_i(EX1_mem_wr_en_out),
    .mem_rd_en_i(EX1_mem_rd_en_out),
    .mem_ctrl_i(EX1_mem_ctrl_out),
    // ===================================
    // data_out
    .pc_p4_o(EX2_pc_p4_out),
    .ALU_o(EX2_ALU_out),
    .reg_rd_data2_o(EX2_reg_rd_data2_out),
    .rd_o(EX2_rd_out),
    .csr_rd_data_o(EX2_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(EX2_reg_wr_en_out),
    .reg_w_sel_o(EX2_reg_w_sel_out),
    .mem_wr_en_o(EX2_mem_wr_en_out),
    .mem_rd_en_o(EX2_mem_rd_en_out),
    .mem_ctrl_o(EX2_mem_ctrl_out)
);

EX_Sub_Reg m_EX_3_Reg(
    .clk(clk),
    .rst_n(rst_n),
    // data_in
    .pc_p4_i(EX2_pc_p4_out),
    .ALU_i(EX2_ALU_out),
    .reg_rd_data2_i(EX2_reg_rd_data2_out),
    .rd_i(EX2_rd_out),
    .csr_rd_data_i(EX2_csr_rd_data_out),
    // control_in
    .reg_wr_en_i(EX2_reg_wr_en_out),
    .reg_w_sel_i(EX2_reg_w_sel_out),

    .mem_wr_en_i(EX2_mem_wr_en_out),
    .mem_rd_en_i(EX2_mem_rd_en_out),
    .mem_ctrl_i(EX2_mem_ctrl_out),
    // ===================================
    // data_out
    .pc_p4_o(EX3_pc_p4_out),
    .ALU_o(EX3_ALU_out),
    .reg_rd_data2_o(EX3_reg_rd_data2_out),
    .rd_o(EX3_rd_out),
    .csr_rd_data_o(EX3_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(EX3_reg_wr_en_out),
    .reg_w_sel_o(EX3_reg_w_sel_out),
    .mem_wr_en_o(EX3_mem_wr_en_out),
    .mem_rd_en_o(EX3_mem_rd_en_out),
    .mem_ctrl_o(EX3_mem_ctrl_out)
);

// ================================
// mem access stage

MEM_Reg m_EX_MEM_Reg(
    .clk(clk),
    .rst_n(rst_n),
    // data_in
    .pc_p4_i(EX3_pc_p4_out),
    .ALU_i(EX3_ALU_out),
    .reg_rd_data2_i(EX3_reg_rd_data2_out),
    .rd_i(EX3_rd_out),
    .csr_rd_data_i(EX3_csr_rd_data_out),
    // control_in
    .reg_wr_en_i(EX3_reg_wr_en_out),
    .reg_w_sel_i(EX3_reg_w_sel_out),

    .mem_wr_en_i(EX3_mem_wr_en_out),
    .mem_rd_en_i(EX3_mem_rd_en_out),
    .mem_ctrl_i(EX3_mem_ctrl_out),
    // ===================================
    // data_out
    .pc_p4_o(MEM_pc_p4_out),
    .ALU_o(MEM_ALU_out),
    .reg_rd_data2_o(MEM_reg_rd_data2_out),
    .rd_o(MEM_rd_out),
    .csr_rd_data_o(MEM_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(MEM_reg_wr_en_out),
    .reg_w_sel_o(MEM_reg_w_sel_out),
    .mem_wr_en_o(MEM_mem_wr_en_out),
    .mem_rd_en_o(MEM_mem_rd_en_out),
    .mem_ctrl_o(MEM_mem_ctrl_out)
);

//================================
//write back stage

WB_Reg m_MEM_WB_Reg(
    .clk(clk),
    .rst_n(rst_n),

    .pc_p4_i(MEM_pc_p4_out),
    .ALU_i(MEM_ALU_out),
    .mem_data_i(d_mem_rd_data),
    .rd_i(MEM_rd_out),
    .csr_rd_data_i(MEM_csr_rd_data_out),
    // control_in
    .reg_wr_en_i(MEM_reg_wr_en_out),
    .reg_w_sel_i(MEM_reg_w_sel_out),
    // ===================================
    // data_out
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
