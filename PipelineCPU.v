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
// WB stage
wire reg_wr_en;
wire freg_wr_en;
wire [2:0] reg_w_sel; // 0: pc_p4, 1: ALU, 2: mem

// LSU
wire mem_wr_en;
wire mem_rd_en;
wire [3:0] mem_ctrl;

// Branch
wire is_j;
wire is_br;
wire [2:0] cmp_op;

// ALU
wire ALU_sel1; // 0: PC, 1: rs1
wire ALU_sel2; // 0: rs2, 1: imm
wire [3:0] ALU_ctrl;

// CSR
wire is_csr;
wire [2:0] csr_op;
wire is_csr_imm; // is csr[r w]i

// FPU
wire is_fpu;
wire FPU_sel1; // 0: freg_rd_data1, 1: reg_rd_data1

// ByPass
wire [1:0] bypass_sel;

// Register File ==============
wire [31:0] wb_data_in;
wire [31:0] reg_data1_out;
wire [31:0] reg_data2_out;

wire [31:0] freg_data1_out;
wire [31:0] freg_data2_out;

// EX_Reg =====================
wire EX_en;
wire EX_clear;
// sys
wire EX_is_impl_out;
wire EX_pc_valid_out;
wire [31:0] EX_inst_out;
wire [31:0] EX_pc_out;
wire [31:0] EX_pc_p4_out;
// data
wire [31:0] EX_reg_rd_data1_out;
wire [31:0] EX_reg_rd_data2_out;
wire [31:0] EX_freg_rd_data1_out;
wire [31:0] EX_freg_rd_data2_out;
wire [31:0] EX_imm_out;
// reg addr
wire [4:0]  EX_rd_out;
wire [4:0]  EX_rs1_out;
wire [4:0]  EX_rs2_out;
// WB stage
wire EX_reg_wr_en_out;
wire EX_freg_wr_en_out;
wire [2:0] EX_reg_w_sel_out;
// MEM
wire EX_mem_rd_en_out;
wire EX_mem_wr_en_out;
wire [3:0] EX_mem_ctrl_out;
// Branch
wire EX_is_j_out;
wire EX_is_br_out;
wire [2:0] EX_cmp_op_out;
// ALU
wire EX_ALU_sel1_out;
wire EX_ALU_sel2_out;
wire [3:0] EX_ALU_ctrl_out;
// CSR
wire EX_is_csr_out;
wire [2:0] EX_csr_op_out;
wire EX_is_csr_imm_out;
wire [11:0] EX_csr_addr_out;
// FPU
wire EX_is_fpu_out;
wire EX_FPU_sel1_out;
// ByPass
wire [1:0] EX_bypass_sel_out;

wire EX_start, EX_done;
// ALU ========================
wire ALU_start, ALU_done;
wire [31:0] ALU_in1;
wire [31:0] ALU_in2;
wire [31:0] ALU_out;

// BranchCmp ==================
wire Br_start, Br_done;
wire br_taken; // indicate any branch happen (trigger by inst, csr unit)

// LSU =========================
wire LSU_start, LSU_done;

wire [31:0] lsu_opcode_in;
wire        lsu_opcode_valid_in;
wire [31:0] lsu_opcode_ra_in;
wire [31:0] lsu_opcode_rb_in;
wire [ 4:0] lsu_opcode_rd_in; 

wire [31:0] lsu_mmu_addr;
wire [31:0] lsu_mmu_data;
wire        lsu_mmu_rd;
wire [ 3:0] lsu_mmu_wr;
wire        lsu_mmu_dflush;
wire        lsu_mmu_dinvalidafte;
wire        lsu_mmu_dwriteback;
wire [31:0] lsu_writeback_value_o;
wire        lsu_writeback_valid_o;
wire [ 4:0] lsu_writeback_rd_o;
wire        lsu_stall_o;
wire [ 5:0] lsu_exception_o;

// MMU =========================
wire [31:0] mmu_fetch_value;
wire        mmu_fetch_valid;
wire        mmu_inst_fault;
wire [31:0] mmu_lsu_data;
wire        mmu_lsu_valid;
wire        mmu_lsu_load_fault;
wire        mmu_lsu_store_fault;
wire [31:0] mmu_dcache_addr;
wire [31:0] mmu_dcache_data;
wire        mmu_dcache_rd;
wire        mmu_dcache_wr;
wire [ 3:0] mmu_dcache_mask;
wire        mmu_dcache_flush;
wire        mmu_dcache_writeback;
wire        mmu_dcache_invalidate;
wire [31:0] mmu_icache_addr;
wire        mmu_icache_rd;

wire [31:0] icache_mmu_inst_in;
wire        icache_mmu_valid_in;

// CSR =========================
wire SYS_start, SYS_done;
wire [31:0] csr_pc_target;
wire [31:0] csr_rd_data; // output of CSRFile
wire [31:0] csr_wr_data; // output of CSR
wire        csr_wr_en;
wire [1:0]  csr_priv;
wire [`EXCEPTION_W-1:0] csr_exception;
wire        csr_br_taken;
wire [31:0] csr_mstatus;
wire [31:0] csr_interrupt;
// FPU =========================
wire FPU_start, FPU_done;
wire [63:0] FPU_out; // output of FPU

// ByPass ======================
wire bypass_start, bypass_done;
wire [31:0] bypass_out;

// WB_Reg =====================
wire WB_en;
wire WB_clear;
wire WB_is_impl_out;
wire WB_pc_valid_out /* verilator public */;
wire [31:0] WB_pc_out /* verilator public */;
wire [31:0] WB_pc_p4_out;
wire [4:0]  WB_rd_out;

wire [31:0] WB_ALU_out;
wire [31:0] WB_mem_data_out;
wire [31:0] WB_csr_rd_data_out;
wire [31:0] WB_FPU_out;
wire [31:0] WB_bypass_out;
// control_out
wire        WB_reg_wr_en_out;
wire        WB_freg_wr_en_out;
wire [2:0]  WB_reg_w_sel_out;

// Forward ====================
wire EX_fwd1_sel;
wire EX_fwd2_sel;
wire EX_freg_fwd_sel1;
wire EX_freg_fwd_sel2;
wire [31:0] EX_fwd_data1;
wire [31:0] EX_fwd_data2;

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

ForwardUnit m_Forward(
    .EX_rs1(EX_rs1_out),
    .EX_rs2(EX_rs2_out),
    
    .WB_rd(WB_rd_out),
    .WB_reg_wr_en(WB_reg_wr_en_out),
    .WB_freg_wr_en(WB_freg_wr_en_out),
    
    .EX_fwd_sel1(EX_fwd1_sel),
    .EX_fwd_sel2(EX_fwd2_sel),
    .EX_freg_fwd_sel1(EX_freg_fwd_sel1),
    .EX_freg_fwd_sel2(EX_freg_fwd_sel2)
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
    .data_i(wb_data_in),
    
    .rd_data1_o(reg_data1_out),
    .rd_data2_o(reg_data2_out)
);


FRegister m_FRegister(
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(WB_freg_wr_en_out & WB_is_impl_out),//write enable

    .rs1(decode_rs1),//addr
    .rs2(decode_rs2),//addr
    
    .rd(WB_rd_out),//addr
    .data_i(wb_data_in),
    
    .rd_data1_o(freg_data1_out),
    .rd_data2_o(freg_data2_out)
);

DecodeUnit m_DecodeUnit(
    .inst_i(ID_inst_out),
    .is_fpu_i(is_fpu),

    .opcode(decode_opcode),
    .funct3(decode_funct3),
    .funct7(decode_funct7),
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .rd(decode_rd),
    .imm(decode_imm),

    .csr_addr_o(decode_csr_addr)
);

Control m_Control(
    .inst(ID_inst_out),
    .is_impl_o(is_impl),
    
    .reg_wr_en_o(reg_wr_en),
    .freg_wr_en_o(freg_wr_en),
    .reg_w_sel_o(reg_w_sel),
    
    .mem_wr_en_o(mem_wr_en),
    .mem_rd_en_o(mem_rd_en),
    .mem_ctrl_o(mem_ctrl),
    
    .is_j_o(is_j),
    .is_br_o(is_br),
    .cmp_op_o(cmp_op),
    
    .ALU_sel1_o(ALU_sel1),
    .ALU_sel2_o(ALU_sel2),
    .ALU_ctrl_o(ALU_ctrl),
    
    .is_csr_o(is_csr),
    .csr_op_o(csr_op),
    .is_csr_imm_o(is_csr_imm),

    .is_fpu_o(is_fpu),
    .FPU_sel1_o(FPU_sel1), // 0: freg_rd_data1, 1: reg_rd_data1

    .bypass_sel_o(bypass_sel)
);

// ================================
// Execution stage

EX_Reg m_EX_Reg(
    .clk(clk),
    .rst_n(rst_n),
    .en(EX_en),
    .clear(EX_clear),
// inputs =====================
    // sys
    .is_impl_i(is_impl),
    .pc_valid_i(ID_pc_valid_out),
    .inst_i(ID_inst_out),
    .pc_i(ID_pc_out),
    .pc_p4_i(ID_pc_p4_out),

    // data
    .reg_rd_data1_i(reg_data1_out),
    .reg_rd_data2_i(reg_data2_out),
    .freg_rd_data1_i(freg_data1_out),
    .freg_rd_data2_i(freg_data2_out),
    .imm_i(decode_imm),
    // reg addr
    .rd_i(decode_rd),
    .rs1_i(decode_rs1),
    .rs2_i(decode_rs2),
    // WB stage
    .reg_wr_en_i(reg_wr_en),
    .freg_wr_en_i(freg_wr_en),
    .reg_w_sel_i(reg_w_sel),
    // LSU
    .mem_rd_en_i(mem_rd_en),
    .mem_wr_en_i(mem_wr_en),
    .mem_ctrl_i(mem_ctrl),
    // Branch
    .is_j_i(is_j),
    .is_br_i(is_br),
    .cmp_op_i(cmp_op),

    // ALU
    .ALU_sel1_i(ALU_sel1),
    .ALU_sel2_i(ALU_sel2),
    .ALU_ctrl_i(ALU_ctrl),

    // CSR
    .csr_addr_i(decode_csr_addr),
    .is_csr_i(is_csr),
    .csr_op_i(csr_op),
    .is_csr_imm_i(is_csr_imm),

    // FPU
    .is_fpu_i(is_fpu),
    .FPU_sel1_i(FPU_sel1), // 0: freg_rd_data1, 1: reg_rd_data1

    .bypass_sel_i(bypass_sel),

    .funct3_i(),
    .funct7_i(),
// outputs =====================
    // sys
    .is_impl_o(EX_is_impl_out),
    .pc_valid_o(EX_pc_valid_out),
    .inst_o(EX_inst_out),
    .pc_o(EX_pc_out),
    .pc_p4_o(EX_pc_p4_out),
    // data
    .reg_rd_data1_o(EX_reg_rd_data1_out),
    .reg_rd_data2_o(EX_reg_rd_data2_out),
    .freg_rd_data1_o(EX_freg_rd_data1_out),
    .freg_rd_data2_o(EX_freg_rd_data2_out),
    .imm_o(EX_imm_out),
    // reg addr
    .rd_o(EX_rd_out),
    .rs1_o(EX_rs1_out),
    .rs2_o(EX_rs2_out),
    // WB stage
    .reg_wr_en_o(EX_reg_wr_en_out),
    .freg_wr_en_o(EX_freg_wr_en_out),
    .reg_w_sel_o(EX_reg_w_sel_out),
    // LSU
    .mem_rd_en_o(EX_mem_rd_en_out),
    .mem_wr_en_o(EX_mem_wr_en_out),
    .mem_ctrl_o(EX_mem_ctrl_out),
    // Branch
    .is_j_o(EX_is_j_out),
    .is_br_o(EX_is_br_out),
    .cmp_op_o(EX_cmp_op_out),

    // ALU
    .ALU_sel1_o(EX_ALU_sel1_out),
    .ALU_sel2_o(EX_ALU_sel2_out),
    .ALU_ctrl_o(EX_ALU_ctrl_out),

    // CSR
    .csr_addr_o(EX_csr_addr_out),
    .is_csr_o(EX_is_csr_out),
    .csr_op_o(EX_csr_op_out),
    .is_csr_imm_o(EX_is_csr_imm_out),

    // FPU
    .is_fpu_o(EX_is_fpu_out),
    .FPU_sel1_o(EX_FPU_sel1_out),

    // bypass
    .bypass_sel_o(EX_bypass_sel_out),

    .funct3_o(),
    .funct7_o()
);

// EX ctrl =====================
// start logic
/*
set to 0 if
    - first cycle of execution
    - not executing
set to 1 if
    - not the first cycle of execution
*/
reg started;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) started <= 0;
    else begin     
        if(EX_done || !(EX_pc_valid_out && EX_is_impl_out)) started <= 0;
        else if((EX_pc_valid_out && EX_is_impl_out) && !started)
            started <= 1;
    end
end
// on for the first cycle of execution
assign EX_start = (!started) && (EX_pc_valid_out && EX_is_impl_out);

// FU start logic
assign ALU_start = EX_start && (|EX_ALU_ctrl_out || EX_inst_out[6:0]==55);
assign Br_start  = EX_start && (EX_is_br_out || EX_is_j_out); // only deal with inst br
assign LSU_start = EX_start && (EX_mem_wr_en_out || EX_mem_rd_en_out);
assign FPU_start = EX_start && EX_is_fpu_out;
assign SYS_start = EX_start && (EX_is_csr_out || (|csr_exception) || csr_br_taken);
assign bypass_start = EX_start && (|EX_bypass_sel_out);

// done logic
assign EX_done = (!EX_pc_valid_out) | (!EX_is_impl_out) |
    ALU_done | 
    Br_done | 
    LSU_done | 
    SYS_done | 
    FPU_done | 
    bypass_done |
    0; // (FU_done && !(|FU_err)) | ...

// Forwarding ==================
Mux2to1 #(.size(32)) m_EX_fwd1_MUX(
    .sel(EX_fwd1_sel),
    .s0(wb_data_in),
    .s1(EX_reg_rd_data1_out),
    .out(EX_fwd_data1)
);
Mux2to1 #(.size(32)) m_EX_fwd2_MUX(
    .sel(EX_fwd2_sel),
    .s0(wb_data_in),
    .s1(EX_reg_rd_data2_out),
    .out(EX_fwd_data2)
);
wire [31:0] EX_freg_fwd_data1;
wire [31:0] EX_freg_fwd_data2;
Mux2to1 #(.size(32)) m_EX_freg_fwd1_MUX(
    .sel(EX_freg_fwd_sel1),
    .s0(wb_data_in),
    .s1(EX_freg_rd_data1_out),
    .out(EX_freg_fwd_data1)
);
Mux2to1 #(.size(32)) m_EX_freg_fwd2_MUX(
    .sel(EX_freg_fwd_sel2),
    .s0(wb_data_in),
    .s1(EX_freg_rd_data2_out),
    .out(EX_freg_fwd_data2)
);

// BypassUnit ==================
BypassUnit m_BypassUnit(
    .bypass_sel(EX_bypass_sel_out),
    .imm(EX_imm_out),
    .reg_data1(EX_fwd_data1),
    .freg_data1(EX_freg_fwd_data1),
    .result_o(bypass_out)
);
assign bypass_done = bypass_start;

// ALU =========================
Mux2to1 #(.size(32)) m_ALU_SRC1_MUX(
    .sel(EX_ALU_sel1_out),
    .s0(EX_pc_out),
    .s1(EX_fwd_data1),
    .out(ALU_in1)
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
assign ALU_done = ALU_start;

// Branch ======================
BranchUnit m_BranchUnit(
    .is_br(EX_is_br_out),
    .is_j(EX_is_j_out),
    .is_csr_br(csr_br_taken),

    .cmp_op(EX_cmp_op_out),
    .reg_rd_data1(EX_fwd_data1),
    .reg_rd_data2(EX_fwd_data2),
    
    .br_taken(br_taken),
    .pc_sel(pc_sel)
);
assign Br_done = Br_start;

// FPU =========================
assign FPU_done = FPU_start;
wire [31:0] FPU_in1;
wire [4:0] FPU_flags;
Mux2to1 #(.size(32)) m_FPU_SRC1_MUX(
    .sel(EX_FPU_sel1_out),
    .s0(EX_freg_fwd_data1),
    .s1(EX_fwd_data1),
    .out(FPU_in1)
);
FPU_Top m_FPU(
    .clk(clk),
    .rst_n(rst_n),
    .frm(csr_rd_data[2:0]),
    .func7(EX_inst_out[31:25]),         // Operation code to select the function
    .func3(EX_inst_out[14:12]),         // Rounding mode for arithmetic operations
    .rs2(EX_inst_out[24:20]),           // For selecting convert type
    .operand_a({32'h0,FPU_in1}),      // Operand A (can be FP64, FP32, INT32, UINT32)
    .operand_b({32'h0,EX_freg_fwd_data2}),      // Operand B (can be FP64, FP32)
    .result_out(FPU_out),     // Result of the operation
    .fflags(FPU_flags)
);

// LSU =========================
lsu u_lsu(
    .clk_i             (clk),
    .rst_i             (rst_n),
    .opcode_opcode_i   (EX_inst_out),
    .opcode_rd_i       (decode_rd),
    .opcode_ra_data_i  (EX_reg_rd_data1_out),
    .opcode_rb_data_i  (EX_reg_rd_data2_out),
    .opcode_valid_i    (LSU_start), //
    .mmu_value_i       (mmu_lsu_data),
    .mmu_valid_i       (mmu_lsu_valid),
    .mmu_load_fault    (mmu_lsu_load_fault),
    .mmu_store_fault   (mmu_lsu_store_fault),
    .mmu_addr_o        (lsu_mmu_addr),
    .mmu_data_o        (lsu_mmu_data),
    .mmu_rd_o          (lsu_mmu_rd),
    .mmu_wr_o          (lsu_mmu_wr),
    .mmu_dflush_o      (lsu_mmu_dflush),
    .mmu_dinvalidate_o (lsu_mmu_dinvalidafte),
    .mmu_dwriteback_o  (lsu_mmu_dwriteback),
    .writeback_value_o (lsu_writeback_value_o),
    .writeback_rd_o    (lsu_writeback_rd_o),
    .writeback_valid_o (lsu_writeback_valid_o),
    .stall_o           (lsu_stall_o),
    .exception_o       (lsu_exception_o)
);

assign lsu_opcode_valid_in = LSU_start;
assign LSU_done = lsu_writeback_valid_o;

// MMU =========================
wire dcache_valid_i_f = 1;
wire icache_valid_i_f = 0;
wire fetch_rd_f = 0;
wire [31:0] satp_i_f = 32'h0;

mmu u_mmu(
    .clk_i               (clk),
    .rst_i               (rst_n),
    .satp_i              (satp_i_f), //
    .fetch_pc_i          (pc_out),
    .fetch_rd_i          (fetch_rd_f), //
    .lsu_in_addr_i       (lsu_mmu_addr),
    .lsu_in_data_i       (lsu_mmu_data),
    .lsu_in_rd_i         (lsu_mmu_rd),
    .lsu_in_wr_i         (lsu_mmu_wr),
    .lsu_in_flush_i      (lsu_mmu_dflush),
    .lsu_in_invalidate_i (lsu_mmu_dinvalidafte),
    .lsu_in_writeback_i  (lsu_mmu_dwriteback),
    .dcache_in_value_i   (d_mem_rd_data),
    .dcache_in_valid_i   (dcache_valid_i_f), //
    .icache_in_value_i   (icache_mmu_inst_in),
    .icache_in_valid_i   (icache_mmu_valid_in),
    .fetch_out_value_o   (mmu_fetch_value),
    .fetch_out_valid_o   (mmu_fetch_valid),
    .lsu_out_value_o     (mmu_lsu_data),
    .lsu_out_valid_o     (mmu_lsu_valid),
    .dcache_addr_o       (mmu_dcache_addr),
    .dcache_value_o      (mmu_dcache_data),
    .dcache_rd_o         (mmu_dcache_rd),
    .dcache_wr_o         (mmu_dcache_wr),
    .dcache_mask_o       (mmu_dcache_mask),
    .dcache_flush_o      (mmu_dcache_flush),
    .dcache_invalidate_o (mmu_dcache_invalidate),
    .dcache_writeback_o  (mmu_dcache_writeback),
    .icache_addr_o       (mmu_icache_addr),
    .icache_rd_o         (mmu_icache_rd),
    .load_fault_o        (mmu_lsu_load_fault),
    .store_fault_o       (mmu_lsu_store_fault),
    .inst_fault_o        (mmu_inst_fault)
);

assign icache_mmu_inst_in = inst;
assign icache_mmu_valid_in = 0;
// assign i_mem_addr = mmu_icache_addr;

assign d_mem_ctrl = mmu_dcache_mask;
assign d_mem_wr_en = mmu_dcache_wr;
assign d_mem_rd_en = mmu_dcache_rd;
assign d_mem_addr = mmu_dcache_addr;
assign d_mem_wr_data = mmu_dcache_data;

// CSR =========================
wire [31:0] csr_rd_data_xtval;
CSR m_CSR(
    .inst(EX_inst_out),
    .inst_valid(1),
    .csr_op_i(EX_csr_op_out),
    .is_csr_i(EX_is_csr_out),
    .is_csr_imm_i(EX_is_csr_imm_out),
    .cur_priv_i(csr_priv),
    .imm_i(EX_imm_out),
    .reg_rd_data1_i(EX_fwd_data1),
    .csr_old_i(csr_rd_data),
    .is_fpu_done_i(FPU_done),
    .fpu_flags_i(FPU_flags),

    .csr_rd_data_o(csr_rd_data_xtval),
    .csr_wr_valid_o(csr_wr_en),
    .csr_wr_data_o(csr_wr_data),
    .csr_exception_o(csr_exception) // generate csr related exceptions
);

CSRFile m_CSRFile(
    .clk(clk),
    .rst_n(rst_n),

    .cpu_id_i(0),
    .misa_i(`MISA_RV32 | `MISA_RVI),

    .exception_i(csr_exception),
    .exception_pc_i(EX_pc_out),
    .exception_addr_i(0),

    .csr_rd_addr_i(EX_csr_addr_out),
    .csr_rd_data_o(csr_rd_data),

    .csr_wr_en_i(csr_wr_en),
    .csr_wr_addr_i(EX_csr_addr_out),
    .csr_wr_data_i(csr_wr_data),

    .csr_branch_o(csr_br_taken),
    .csr_target_o(csr_pc_target),

    .priv_o(csr_priv),
    .mstatus_o(csr_mstatus),
    .interrupt_o(csr_interrupt)
);
assign SYS_done = SYS_start;

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
    .rd_i(EX_rd_out),

    .bypass_i(bypass_out),
    .ALU_i(ALU_out),
    .FPU_i(FPU_out[31:0]),
    .mem_data_i(lsu_writeback_value_o),
    .csr_rd_data_i(csr_rd_data),
    
    // control_in
    .reg_wr_en_i(EX_reg_wr_en_out),
    .freg_wr_en_i(EX_freg_wr_en_out), // TODO
    .reg_w_sel_i(EX_reg_w_sel_out),
    // ===================================
    // data_out
    .is_impl_o(WB_is_impl_out),
    .pc_valid_o(WB_pc_valid_out),
    .pc_o(WB_pc_out),
    .pc_p4_o(WB_pc_p4_out),
    .rd_o(WB_rd_out),
    
    .bypass_o(WB_bypass_out),
    .ALU_o(WB_ALU_out),
    .FPU_o(WB_FPU_out),
    .mem_data_o(WB_mem_data_out),
    .csr_rd_data_o(WB_csr_rd_data_out),
    // control_out
    .reg_wr_en_o(WB_reg_wr_en_out),
    .freg_wr_en_o(WB_freg_wr_en_out),
    .reg_w_sel_o(WB_reg_w_sel_out)
);

Mux6to1 #(.size(32)) m_Mux_WriteData(
    .sel(WB_reg_w_sel_out),
    .s0(WB_pc_p4_out),
    .s1(WB_ALU_out),
    .s2(WB_mem_data_out),
    .s3(WB_csr_rd_data_out),
    .s4(WB_FPU_out),
    .s5(WB_bypass_out),
    .out(wb_data_in)
);

endmodule
