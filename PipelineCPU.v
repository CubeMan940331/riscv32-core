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
wire [31:0] EX_reg_rd_data1_out;
wire [31:0] EX_reg_rd_data2_out;
wire [31:0] EX_freg_rd_data1_out;
wire [31:0] EX_freg_rd_data2_out;
wire [31:0] EX_freg_rd_data3_out;
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
wire EX_ALU_sel1_out;
wire EX_ALU_sel2_out;
wire [3:0] EX_ALU_ctrl_out;
// MUL/DIV
wire EX_is_MUL_DIV_out;
wire [2:0] EX_MUL_DIV_ctrl_out;
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
// Fence
wire EX_fetch_invalid_out;

wire EX_start, EX_done;
// ALU ========================
wire ALU_start, ALU_done;
wire [31:0] ALU_in1;
wire [31:0] ALU_in2;
wire [31:0] ALU_out;

// BranchCmp ==================
wire Br_start, Br_done;
wire br_taken; // indicate any branch happen (trigger by inst, csr unit)

// MUL/DIV ====================
wire MUL_DIV_start, MUL_DIV_done;
wire [31:0] MUL_DIV_out;

// LSU =========================
wire LSU_start, LSU_done;

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
wire [31:0] FPU_out; // output of FPU

// ByPass ======================
wire bypass_start, bypass_done;
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
wire EX_fwd1_sel;
wire EX_fwd2_sel;
wire EX_freg_fwd_sel1;
wire EX_freg_fwd_sel2;
wire EX_freg_fwd_sel3;
wire [31:0] EX_fwd_data1;
wire [31:0] EX_fwd_data2;
wire [31:0] EX_fwd_data3;

// Hazerd =====================
wire [3:0] stall;

//componets
//================================================================

PipelineCtrl m_PipelineCtrl(
    .clk(clk),
    .rst_n(rst_n),
    .br_taken(br_taken),
    
    .EX_pc_valid_i(EX_pc_valid_out),
    .EX_is_impl_i(EX_is_impl_out),
    .ALU_done_i(ALU_done),
    .Br_done_i(Br_done),
    .LSU_done_i(LSU_done),
    .FPU_done_i(FPU_done),
    .SYS_done_i(SYS_done),
    .bypass_done_i(bypass_done),
    .MUL_DIV_done_i(MUL_DIV_done),

    .EX_start(EX_start),

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
    .EX_rs3(EX_rs3_out),
    
    .WB_rd(WB_rd_out),
    .WB_reg_wr_en(WB_reg_wr_en_out),
    .WB_freg_wr_en(WB_freg_wr_en_out),
    
    .EX_fwd_sel1(EX_fwd1_sel),
    .EX_fwd_sel2(EX_fwd2_sel),
    .EX_freg_fwd_sel1(EX_freg_fwd_sel1),
    .EX_freg_fwd_sel2(EX_freg_fwd_sel2),
    .EX_freg_fwd_sel3(EX_freg_fwd_sel3)
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

Decode m_ID(
    .clk(clk),
    .rst_n(rst_n),

    .en(ID_en),
    .clear(ID_clear),

    .pc_i(pc_out),
    .pc_p4_i(pc_p4),
    .inst_i(inst),
    
    .pc_valid_o(ID_pc_valid_out),
    .pc_o(ID_pc_out),
    .pc_p4_o(ID_pc_p4_out),
    .inst_o(ID_inst_out),

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
    .cmp_op_o(EX_cmp_op_out),
    // ALU
    .ALU_src1_o(ALU_in1),
    .ALU_src2_o(ALU_in2),
    .ALU_ctrl_o(EX_ALU_ctrl_out),
    // MUL/DIV
    .is_MUL_DIV_o(EX_is_MUL_DIV_out),
    .MUL_DIV_ctrl_o(EX_MUL_DIV_ctrl_out),
    // CSR
    .csr_addr_o(EX_csr_addr_out),
    .is_csr_o(EX_is_csr_out),
    .csr_op_o(EX_csr_op_out),
    .is_csr_imm_o(EX_is_csr_imm_out),
    // FPU
    .FPU_src1_o(FPU_in1),
    .is_fpu_o(EX_is_fpu_out),
    .FPU_sel1_o(EX_FPU_sel1_out),
    // bypass
    .bypass_sel_o(EX_bypass_sel_out),
    // fetch
    .fetch_invalid_o(EX_fetch_invalid_out)
);

// BypassUnit ==================
assign bypass_start = EX_start && (|EX_bypass_sel_out);
BypassUnit m_BypassUnit(
    .bypass_sel(EX_bypass_sel_out),
    .imm(EX_imm_out),
    .reg_data1(EX_fwd_data1),
    .freg_data1(EX_freg_fwd_data1),
    .result_o(bypass_out)
);
assign bypass_done = bypass_start;

// ALU =========================
assign ALU_start = EX_start && (|EX_ALU_ctrl_out);
ALU_top m_ALU(
    .ALU_ctrl(EX_ALU_ctrl_out),
    .a(ALU_in1),
    .b(ALU_in2),
    .out(ALU_out)
);
assign ALU_done = ALU_start;

// Branch ======================
assign Br_start  = EX_start && (EX_is_br_out || EX_is_j_out); // only deal with inst br
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

// MUL/DIV =====================
assign MUL_DIV_start = EX_start && EX_is_MUL_DIV_out;
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
assign FPU_start = EX_start && EX_is_fpu_out;
wire [4:0] FPU_flags;
FPU_Top m_FPU(
    .clk(clk),
    .rst_n(rst_n),
    .opcode(EX_inst_out[6:0]),
    .func7(EX_inst_out[31:25]),         // func7 code to select the function
    .func3(EX_inst_out[14:12]),         // Rounding mode for arithmetic operations (if 111 swap to frm)
    .frm(csr_rd_data[2:0]),             // Rounding mode (dynamic from frm)
    .rs2(EX_inst_out[24:20]),           // For selecting convert type
    .operand_a(FPU_in1),                // Operand A 
    .operand_b(EX_freg_fwd_data2),      // Operand B 
    .operand_c(EX_freg_fwd_data3),      // Operand C
    .result_out(FPU_out),               // Result of the operation
    .fflags(FPU_flags)
);
assign FPU_done = FPU_start;

// LSU =========================
// not implemented yet, a simple one is used
assign LSU_start = EX_start && (EX_mem_wr_en_out || EX_mem_rd_en_out);
assign d_mem_ctrl = MEM_mem_ctrl_out;
assign d_mem_wr_en = MEM_mem_wr_en_out;
assign d_mem_rd_en = MEM_mem_rd_en_out;
assign d_mem_addr = MEM_mem_addr_out;
assign d_mem_wr_data = MEM_mem_wr_data_out;
reg MEM_mem_wr_en_out;
reg MEM_mem_rd_en_out;
reg [3:0] MEM_mem_ctrl_out;
reg [31:0] MEM_mem_addr_out;
reg [31:0] MEM_mem_wr_data_out;
reg MEM_stage_reg;
always @(posedge clk or negedge rst_n) begin
    if(LSU_start) begin
        MEM_mem_wr_en_out <= EX_mem_wr_en_out;
        MEM_mem_rd_en_out <= EX_mem_rd_en_out;
        MEM_mem_ctrl_out <= EX_mem_ctrl_out;
        MEM_mem_addr_out <= (EX_fwd_data1 + EX_imm_out);
        MEM_mem_wr_data_out <= (EX_mem_ctrl_out[3] & EX_mem_wr_en_out) ? EX_freg_fwd_data2 : EX_fwd_data2;
        MEM_stage_reg <= 1;
    end
    else begin
        MEM_mem_wr_en_out <= 0;
        MEM_mem_rd_en_out <= 0;
        MEM_mem_ctrl_out <= 0;
        MEM_mem_addr_out <= 0;
        MEM_mem_wr_data_out <= 0;
        MEM_stage_reg <= 0;
    end
end
assign LSU_done = MEM_stage_reg;

// CSR =========================
assign SYS_start = EX_start && (EX_is_csr_out || (|csr_exception) || csr_br_taken);
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

    .bypass_i(bypass_out),
    .ALU_i(ALU_out),
    .MUL_DIV_i(MUL_DIV_out),
    .FPU_i(FPU_out),
    .mem_data_i(d_mem_rd_data),
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
    .rd_o(WB_rd_out),
    
    .wb_data_o(wb_data_in),

    // control_out
    .reg_wr_en_o(WB_reg_wr_en_out),
    .freg_wr_en_o(WB_freg_wr_en_out)
);

endmodule
