`include "riscv_defs.v"
module PipelineCPU (
    input clk,
    input rst_n,

    output [31:0] i_mem_addr,
    input  [31:0] inst,
    output i_req,
    output i_mem_invalidate,
    input i_ready,
    input i_mem_exception,

    output [3:0]  d_mem_ctrl,
    output        d_mem_wr_en,
    output        d_mem_rd_en,
    output [31:0] d_mem_addr,
    output [31:0] d_mem_wr_data,
    output        d_mem_writeback,
    output        d_mem_invalidate,
    output        d_mem_flush,
    output        d_mem_cacheable,
    input  [31:0] d_mem_rd_data,
    input         d_mem_available,
    input  [1:0]  d_mem_exception,

    output [31:0] cdma_data_o,
    output [31:0] cdma_addr_o,
    input         cdma_rdy_i,
    input  [31:0] cdma_data_i,
    input  [1:0]  cdma_exception_i
);
//wires
//================================================================

// PC =========================
wire pc_en;
wire [31:0]pc_out;
wire [31:0]pc_p4;

// IF =========================
wire IF_stall;
wire fetch_req;

// ID_Reg =====================
wire ID_clear;
wire ID_en;

wire ID_pc_valid_out;
wire [31:0] ID_pc_out;
wire [31:0] ID_pc_p4_out;
wire [31:0] ID_inst_out;

// Decode ========================
wire [31:0]   decode_imm;

wire [4:0]    decode_rs1;
wire [4:0]    decode_rs2;
wire [4:0]    decode_rs3;
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

// MUL/DIV
wire is_MUL_DIV;
wire [2:0] MUL_DIV_ctrl;

// CSR
wire is_csr;
wire [2:0] csr_op;
wire is_csr_imm; // is csr[r w]i

// FPU
wire is_f_ext;
wire is_fpu;
wire FPU_sel1; // 0: freg_rd_data1, 1: reg_rd_data1

// ByPass
wire [1:0] bypass_sel;

// Fence
wire fetch_invalid;

// Register File ==============
wire [31:0] wb_data_in;
wire [31:0] reg_data1_out;
wire [31:0] reg_data2_out;

wire [31:0] freg_data1_out;
wire [31:0] freg_data2_out;
wire [31:0] freg_data3_out;

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
wire [31:0] EX_imm_out;
// reg addr
wire [4:0]  EX_rd_out;
wire [4:0]  EX_rs1_out;
wire [4:0]  EX_rs2_out;
wire [4:0]  EX_rs3_out;
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
wire [3:0] EX_ALU_ctrl_out;
// MUL/DIV
wire EX_is_MUL_DIV_out;
wire [2:0] EX_MUL_DIV_ctrl_out;
// CSR
wire EX_is_csr_out;
wire [2:0] EX_csr_op_out;
wire EX_is_csr_imm_out;
wire [11:0] EX_csr_addr_out;
wire [31:0] csr_satp_out;
// FPU
wire EX_is_f_ext;
wire EX_is_fpu_out;
wire EX_FPU_sel1_out;
// ByPass
wire [1:0] EX_bypass_sel_out;
// Fence
wire EX_fetch_invalid_out;

wire EX_pc_missalign_out;

wire EX_start, EX_done;
// ALU ========================
wire [31:0] ALU_out;
wire ALU_exception;

// BranchCmp ==================
wire br_taken; // indicate inst branch

// MUL/DIV ====================
wire MUL_DIV_start, MUL_DIV_done;
wire [31:0] MUL_DIV_out;

// LSU =========================
wire LSU_start, LSU_done;

wire        lsu_fetch_valid;
wire [31:0] lsu_fetch_inst;
wire [31:0] lsu_mmu_pc;
wire        lsu_mmu_i_rd;
wire [31:0] lsu_mmu_addr;
wire [31:0] lsu_mmu_data;
wire        lsu_mmu_rd;
wire        lsu_mmu_wr;
wire [ 3:0] lsu_mmu_mask;
wire        lsu_mmu_dflush;
wire        lsu_mmu_dinvalidafte;
wire        lsu_mmu_dwriteback;
wire        lsu_mmu_iinvalidate;
wire [31:0] lsu_writeback_value_o;
wire        lsu_writeback_valid_o;
wire        except_inst_ma;
wire        except_page_fault_load;
wire        except_page_fault_store;

// MMU =========================
wire [31:0] mmu_sapt;
wire [31:0] mmu_fetch_value;
wire        mmu_fetch_valid;
wire        mmu_lsu_ex_except;
wire [31:0] mmu_lsu_inst;
wire        mmu_lsu_i_valid;
wire [31:0] mmu_lsu_data;
wire        mmu_lsu_d_valid;
wire        mmu_lsu_rd_except;
wire        mmu_lsu_wr_except;

// CSR =========================
wire SYS_start, SYS_done;
wire [31:0] csr_br_target;
wire [31:0] csr_rd_data; // output of CSRFile
wire [`EXCEPTION_W-1:0] csr_exception;
wire        csr_br_taken;
wire [31:0] csr_interrupt;
// FPU =========================
wire FPU_start, FPU_done;
wire [31:0] FPU_out; // output of FPU

// ByPass ======================
wire [31:0] bypass_out;

// WB_Reg =====================
wire WB_en;
wire WB_clear;
wire WB_is_impl_out;
wire WB_pc_valid_out /* verilator public */;
wire [31:0] WB_pc_out /* verilator public */;
wire [4:0]  WB_rd_out;

// control_out
wire        WB_reg_wr_en_out;
wire        WB_freg_wr_en_out;

// Forward ====================
wire [31:0] EX_fwd_data1;
wire [31:0] EX_fwd_data2;

//componets
//================================================================
wire br_flush;

PipelineCtrl m_PipelineCtrl(
    .br_flush(br_flush),
    
    .IF_stall(IF_stall),
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
wire [31:0] bp_nx_pc_out;
wire [31:0] bp_pred_target_out;
wire [31:0] ID_bp_pred_target_out;
wire [31:0] EX_bp_pred_target_out;
wire bp_pred_taken_out;
wire ID_bp_pred_taken_out;
wire EX_bp_pred_taken_out;

Fetch m_Fetch(
     .clk(clk)
    ,.rst_n(rst_n) 
    ,.en(pc_en)
// inst. mem interface
    ,.i_req_o(fetch_req)
    ,.i_ready_i(lsu_fetch_valid)
// feed back from EX
    ,.EX_pc_i(EX_pc_out)

    ,.EX_bp_pred_taken_i(EX_bp_pred_taken_out)
    ,.EX_bp_pred_pc_i(EX_bp_pred_target_out)

    ,.EX_is_br_i(EX_is_br_out)
    ,.EX_br_taken_i(br_taken) // inst br taken
    ,.EX_br_target_i({ALU_out[31:2], 2'b0}) // not support compress
    ,.EX_pc_p4_i(EX_pc_p4_out)
    
    ,.EX_csr_br_taken_i(csr_br_taken)
    ,.EX_csr_br_target_i(csr_br_target)
    ,.EX_done_i(EX_done)
    ,.EX_pc_valid_i(EX_pc_valid_out)
// output
    ,.IF_stall_o(IF_stall)
    ,.br_flush_o(br_flush)

    ,.bp_pred_taken_o(bp_pred_taken_out)
    ,.bp_pred_target_o(bp_pred_target_out)
    
    ,.pc_o(pc_out)
    ,.pc_p4_o(pc_p4)
);

Decode m_ID(
    .clk(clk),
    .rst_n(rst_n),

    .en(ID_en),
    .clear(ID_clear),

    .pc_i(pc_out),
    .pc_p4_i(pc_p4),
    .inst_i(lsu_fetch_inst),

    .bp_pred_taken_i(bp_pred_taken_out),
    .bp_pred_target_i(bp_pred_target_out),
    
    .pc_valid_o(ID_pc_valid_out),
    .pc_o(ID_pc_out),
    .pc_p4_o(ID_pc_p4_out),
    .inst_o(ID_inst_out),
    .bp_pred_taken_o(ID_bp_pred_taken_out),
    .bp_pred_target_o(ID_bp_pred_target_out),

    .rs1_o(decode_rs1),
    .rs2_o(decode_rs2),
    .rs3_o(decode_rs3),
    .rd_o(decode_rd),
    .csr_addr_o(decode_csr_addr),

    .imm_o(decode_imm),

    .reg_wr_en_o(reg_wr_en),
    .freg_wr_en_o(freg_wr_en),
    .reg_w_sel_o(reg_w_sel),
    
    .mem_wr_en_o(mem_wr_en),
    .mem_rd_en_o(mem_rd_en),
    .mem_ctrl_o(mem_ctrl),

    .is_j_o(is_j),
    .is_br_o(is_br),
    .cmp_op_o(cmp_op),

    .ALU_ctrl_o(ALU_ctrl),
    .ALU_sel1_o(ALU_sel1),
    .ALU_sel2_o(ALU_sel2),

    .is_MUL_DIV_o(is_MUL_DIV),
    .MUL_DIV_ctrl_o(MUL_DIV_ctrl),

    .is_csr_o(is_csr),
    .csr_op_o(csr_op),
    .is_csr_imm_o(is_csr_imm),

    .is_f_ext_o(is_f_ext),
    .is_fpu_o(is_fpu),
    .FPU_sel1_o(FPU_sel1),

    .bypass_sel_o(bypass_sel),
    
    .fetch_invalid_o(fetch_invalid),
    
    .is_impl_o(is_impl)
);

Register m_Register(
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(WB_reg_wr_en_out),//write enable

    .rs1(decode_rs1),//addr
    .rs2(decode_rs2),//addr
    
    .rd(WB_rd_out),//addr
    .data_i(wb_data_in),
    
    .rd_data1_o(reg_data1_out),
    .rd_data2_o(reg_data2_out)
);

FRegister m_FRegister(
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(WB_freg_wr_en_out),//write enable

    .rs1(decode_rs1),//addr
    .rs2(decode_rs2),//addr
    .rs3(decode_rs3),//addr
    
    .rd(WB_rd_out),//addr
    .data_i(wb_data_in),
    
    .rd_data1_o(freg_data1_out),
    .rd_data2_o(freg_data2_out),
    .rd_data3_o(freg_data3_out)
);

wire [31:0] EX_freg_fwd_data1;
wire [31:0] EX_freg_fwd_data2;
wire [31:0] EX_freg_fwd_data3;
wire [31:0] FPU_in1;

Exec m_EX(
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
    .bp_pred_taken_i(ID_bp_pred_taken_out),
    .bp_pred_target_i(ID_bp_pred_target_out),
    // data
    .reg_rd_data1_i(reg_data1_out),
    .reg_rd_data2_i(reg_data2_out),
    .freg_rd_data1_i(freg_data1_out),
    .freg_rd_data2_i(freg_data2_out),
    .freg_rd_data3_i(freg_data3_out),
    .imm_i(decode_imm),
    // reg addr
    .rd_i(decode_rd),
    .rs1_i(decode_rs1),
    .rs2_i(decode_rs2),
    .rs3_i(decode_rs3),
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
    // MUL/DIV
    .is_MUL_DIV_i(is_MUL_DIV),
    .MUL_DIV_ctrl_i(MUL_DIV_ctrl),
    // CSR
    .csr_addr_i(decode_csr_addr),
    .is_csr_i(is_csr),
    .csr_op_i(csr_op),
    .is_csr_imm_i(is_csr_imm),
    // FPU
    .is_f_ext_i(is_f_ext),
    .is_fpu_i(is_fpu),
    .FPU_sel1_i(FPU_sel1), // 0: freg_rd_data1, 1: reg_rd_data1
    // bypass
    .bypass_sel_i(bypass_sel),
    // Fence
    .fetch_invalid_i(fetch_invalid),

    .WB_rd_i(WB_rd_out),
    .WB_reg_wr_en_i(WB_reg_wr_en_out),
    .WB_freg_wr_en_i(WB_freg_wr_en_out),
    .wb_data_i(wb_data_in),
// outputs =====================
    // sys
    .is_impl_o(EX_is_impl_out),
    .pc_valid_o(EX_pc_valid_out),
    .inst_o(EX_inst_out),
    .pc_o(EX_pc_out),
    .pc_p4_o(EX_pc_p4_out),
    .bp_pred_taken_o(EX_bp_pred_taken_out),
    .bp_pred_target_o(EX_bp_pred_target_out),
    // data
    .reg_fwd_data1_o(EX_fwd_data1),
    .reg_fwd_data2_o(EX_fwd_data2),
    .freg_fwd_data1_o(EX_freg_fwd_data1),
    .freg_fwd_data2_o(EX_freg_fwd_data2),
    .freg_fwd_data3_o(EX_freg_fwd_data3),
    .imm_o(EX_imm_out),
    // reg addr
    .rd_o(EX_rd_out),
    .rs1_o(EX_rs1_out),
    .rs2_o(EX_rs2_out),
    .rs3_o(EX_rs3_out),
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
    .br_taken_o(br_taken),
    // ALU
    .ALU_ctrl_o(EX_ALU_ctrl_out),
    .ALU_o(ALU_out),
    .ALU_exception_o(ALU_exception),
    // MUL/DIV
    .is_MUL_DIV_o(EX_is_MUL_DIV_out),
    .MUL_DIV_ctrl_o(EX_MUL_DIV_ctrl_out),
    // CSR
    .csr_addr_o(EX_csr_addr_out),
    .is_csr_o(EX_is_csr_out),
    .csr_op_o(EX_csr_op_out),
    .is_csr_imm_o(EX_is_csr_imm_out),
    // FPU
    .is_f_ext_o(EX_is_f_ext),
    .FPU_src1_o(FPU_in1),
    .is_fpu_o(EX_is_fpu_out),
    .FPU_sel1_o(EX_FPU_sel1_out),
    // bypass
    .bypass_sel_o(EX_bypass_sel_out),
    .bypass_o(bypass_out),
    // fetch
    .fetch_invalid_o(EX_fetch_invalid_out)

    ,.pc_missalign_o(EX_pc_missalign_out)
// EX control ==================
    ,.csr_exception_i(csr_exception)
    ,.EX_start_o(EX_start)
    ,.MUL_DIV_start_o(MUL_DIV_start)
    ,.FPU_start_o(FPU_start)
    ,.LSU_start_o(LSU_start)

    ,.MUL_DIV_done_i(MUL_DIV_done)
    ,.FPU_done_i(FPU_done)
    ,.LSU_done_i(LSU_done)
    ,.SYS_done_i(SYS_done)

    ,.EX_done_o(EX_done)
);

// MUL/DIV =====================
MUL_DIV_top m_MUL_DIV_top(
    .clk(clk),
    .rst_n(rst_n),

    .data1(EX_fwd_data1),
    .data2(EX_fwd_data2),
    
    .MUL_DIV_start(MUL_DIV_start),
    .MUL_DIV_ctrl(EX_MUL_DIV_ctrl_out),
    .MUL_DIV_out(MUL_DIV_out),
    .MUL_DIV_done(MUL_DIV_done)
);

// FPU =========================
wire [4:0] FPU_flags;
FPU_top m_FPU(
    .clk(clk),
    .rst_n(rst_n),
    .FPU_start(FPU_start),

    .opcode(EX_inst_out[6:0]),
    .func7(EX_inst_out[31:25]),         // func7 code to select the function
    .func3(EX_inst_out[14:12]),         // Rounding mode for arithmetic operations (if 111 swap to frm)
    .frm(csr_rd_data[2:0]),             // Rounding mode (dynamic from frm)
    .rs2(EX_inst_out[24:20]),           // For selecting convert type

    .operand_a(FPU_in1),                // Operand A 
    .operand_b(EX_freg_fwd_data2),      // Operand B 
    .operand_c(EX_freg_fwd_data3),      // Operand C
    .result_out(FPU_out),               // Result of the operation
    .fflags(FPU_flags),
    .FPU_done(FPU_done)
);

// LSU =========================
assign LSU_done = lsu_writeback_valid_o;

lsu u_lsu (
    .clk_i             (clk),
    .rst_i             (rst_n),

    // Instruction
    .fetch_rd_i        (fetch_req),
    .fetch_pc_i        (pc_out),
    .fetch_valid_o     (lsu_fetch_valid),
    .fetch_inst_o      (lsu_fetch_inst),
    .mmu_i_valid_i     (mmu_lsu_i_valid),
    .mmu_i_inst_i      (mmu_lsu_inst),
    .mmu_i_rd_o        (lsu_mmu_i_rd),
    .mmu_i_pc_o        (lsu_mmu_pc),

    // Data
    .opcode_inst_i     (EX_inst_out),
    .opcode_ra_data_i  (EX_fwd_data1),
    .opcode_rb_data_i  (EX_fwd_data2),
    .opcode_fp_data_i  (EX_freg_fwd_data2),
    .opcode_valid_i    (LSU_start),
    .ex_mem_imm_i      (EX_imm_out),
    .ex_mem_rd_i       (EX_mem_rd_en_out),
    .ex_mem_wr_i       (EX_mem_wr_en_out),
    .ex_mem_ctrl_i     (EX_mem_ctrl_out),
    .mmu_value_i       (mmu_lsu_data),
    .mmu_valid_i       (mmu_lsu_d_valid),
    .mmu_addr_o        (lsu_mmu_addr),
    .mmu_data_o        (lsu_mmu_data),
    .mmu_rd_o          (lsu_mmu_rd),
    .mmu_wr_o          (lsu_mmu_wr),
    .mmu_mask_o        (lsu_mmu_mask),
    .mmu_dflush_o      (lsu_mmu_dflush),
    .mmu_dinvalidate_o (lsu_mmu_dinvalidafte),
    .mmu_dwriteback_o  (lsu_mmu_dwriteback),
    .mmu_iinvalidate_o (lsu_mmu_iinvalidate),
    .writeback_value_o (lsu_writeback_value_o),
    .writeback_valid_o (lsu_writeback_valid_o),

    // Exception 
    .mmu_read_excpt_i  (mmu_lsu_rd_except),
    .mmu_write_excpt_i (mmu_lsu_wr_except),
    .mmu_exe_excpt_i   (mmu_lsu_ex_except),
    .except_inst_ma    (except_inst_ma),
    .except_page_fault_load(except_page_fault_load),
    .except_page_fault_store(except_page_fault_store)
);

// // MMU =========================
wire [1:0] mmu_priv = 2'b0; // temp setting

assign cdma_data_o = d_mem_wr_data;
assign cdma_addr_o = d_mem_addr;

mmu u_mmu(
    .clk_i               (clk),
    .rst_i               (rst_n),
    .satp_i              (csr_satp_out),
    .priv_i              (mmu_priv),

    // lsu interface
    .fetch_pc_i          (lsu_mmu_pc),
    .fetch_rd_i          (lsu_mmu_i_rd), 
    .lsu_in_addr_i       (lsu_mmu_addr),
    .lsu_in_data_i       (lsu_mmu_data),
    .lsu_in_rd_i         (lsu_mmu_rd),
    .lsu_in_wr_i         (lsu_mmu_wr),
    .lsu_in_mask_i       (lsu_mmu_mask),
    .lsu_in_flush_i      (lsu_mmu_dflush),
    .lsu_in_invalidate_i (lsu_mmu_dinvalidafte),
    .lsu_in_writeback_i  (lsu_mmu_dwriteback),
    .lsu_in_i_invalidate_i(lsu_mmu_iinvalidate),
    
    .fetch_out_value_o   (mmu_lsu_inst),
    .fetch_out_valid_o   (mmu_lsu_i_valid),
    .lsu_out_value_o     (mmu_lsu_data),
    .lsu_out_valid_o     (mmu_lsu_d_valid),

    // data cache interface
    .dcache_in_value_i   (d_mem_rd_data),
    .dcache_in_valid_i   (d_mem_available),

    .dcache_addr_o       (d_mem_addr),
    .dcache_value_o      (d_mem_wr_data),
    .dcache_rd_o         (d_mem_rd_en),
    .dcache_wr_o         (d_mem_wr_en),
    .dcache_mask_o       (d_mem_ctrl),
    .dcache_flush_o      (d_mem_flush),
    .dcache_invalidate_o (d_mem_invalidate),
    .dcache_writeback_o  (d_mem_writeback),
    .d_cachable_o        (d_mem_cacheable),

    // cdma interface
    .cdma_data_i         (cdma_data_i),
    .cdma_rdy_i          (cdma_rdy_i),
    
    // instruction cache interface
    .icache_in_value_i   (inst),
    .icache_in_valid_i   (i_ready),
    .icache_addr_o       (i_mem_addr),
    .icache_rd_o         (i_req),
    .icache_invalidate_o (i_mem_invalidate),

    // exception
    .icache_exception_i  (i_mem_exception),
    .dcache_exception_i  (d_mem_exception),
    .cdma_exception_i    (cdma_exception_i),
    .read_except_o       (mmu_lsu_rd_except),
    .write_except_o      (mmu_lsu_wr_except),
    .exe_except_o        (mmu_lsu_ex_except)
);

// CSR =========================
assign SYS_start = EX_start && (
    EX_is_csr_out ||
    ((csr_exception&`EXCEPTION_TYPE_MASK)==`EXCEPTION_EXCEPTION) ||
    csr_br_taken
);
CSR m_CSR(
    .clk(clk),
    .rst_n(rst_n),
    .inst(EX_inst_out),
    .inst_valid(!EX_pc_valid_out || EX_is_impl_out),
    
    .csr_op_i(EX_csr_op_out),
    .is_csr_i(EX_is_csr_out),
    .is_csr_imm_i(EX_is_csr_imm_out),
    .rs1_i(EX_rs1_out),
    .imm_i(EX_imm_out),
    .reg_rd_data1_i(EX_fwd_data1),
    
    .is_fpu_done_i(FPU_done),
    .fpu_flags_i(FPU_flags),
    .is_f_ext_i(EX_is_f_ext),
    
    .pc_misalign_i(EX_pc_missalign_out),
    .alu_exception_i(ALU_exception),
    .i_cache_exception_i(0),
    .d_cache_exception_i(0),
    .dma_exception_i(0),
    .interrupt_i(0),

    .csr_wr_addr_i(EX_csr_addr_out),
    
    .exception_pc_i(EX_pc_out),
    .except_inst_ma_i(except_inst_ma),
    .except_page_fault_load_i(except_page_fault_load),
    .except_page_fault_store_i(except_page_fault_store),
    .csr_rd_addr_i(EX_csr_addr_out),

    .csr_branch_o(csr_br_taken),
    .csr_target_o(csr_br_target),
    .interrupt_o(csr_interrupt),
    .csr_exception_o(csr_exception),
    
    .csr_rd_data_o(csr_rd_data),
    .csr_satp_o(csr_satp_out)

    ,.d_mem_addr_i(d_mem_addr)
    ,.d_mem_rd_en_i(d_mem_rd_en)
    ,.d_mem_wr_en_i(d_mem_wr_en)
);

assign SYS_done = SYS_start;

//================================
//write back stage
Writeback m_WB(
    .clk(clk),
    .rst_n(rst_n),
    .en(WB_en),
    .clear(WB_clear),
    
    .is_impl_i(EX_is_impl_out),
    .pc_valid_i(EX_pc_valid_out),
    .pc_i(EX_pc_out),
    .pc_p4_i(EX_pc_p4_out),
    .rd_i(EX_rd_out),
    .exception_i(csr_exception),

    .bypass_i(bypass_out),
    .ALU_i(ALU_out),
    .MUL_DIV_i(MUL_DIV_out),
    .FPU_i(FPU_out),
    .mem_data_i(lsu_writeback_value_o),
    .csr_rd_data_i(csr_rd_data),
    
    // control_in
    .reg_wr_en_i(EX_reg_wr_en_out),
    .freg_wr_en_i(EX_freg_wr_en_out),
    .reg_w_sel_i(EX_reg_w_sel_out),
    // ===================================
    // data_out
    .is_impl_o(WB_is_impl_out),
    .pc_valid_o(WB_pc_valid_out),
    .pc_o(WB_pc_out),
    .rd_o(WB_rd_out),
    
    .wb_data_o(wb_data_in),

    // control_out
    .reg_wr_en_o(WB_reg_wr_en_out),
    .freg_wr_en_o(WB_freg_wr_en_out)
);

endmodule
