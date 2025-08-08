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

// Register File ==============
wire [31:0] reg_data_in;
wire [31:0] reg_data1_out;
wire [31:0] reg_data2_out;

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
wire [31:0] EX_imm_out;
// reg addr
wire [4:0]  EX_rd_out;
wire [4:0]  EX_rs1_out;
wire [4:0]  EX_rs2_out;
// WB stage
wire EX_reg_wr_en_out;
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
assign d_mem_ctrl = MEM_mem_ctrl_out;
assign d_mem_wr_en = MEM_mem_wr_en_out;
assign d_mem_rd_en = MEM_mem_rd_en_out;
assign d_mem_addr = MEM_mem_addr_out;
assign d_mem_wr_data = MEM_mem_wr_data_out;

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
wire EX_fwd1_sel;
wire EX_fwd2_sel;
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
    
    .EX_fwd_sel1(EX_fwd1_sel),
    .EX_fwd_sel2(EX_fwd2_sel)
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
    .inst(ID_inst_out),
    .is_impl_o(is_impl),
    .reg_wr_en_o(reg_wr_en),
    .reg_w_sel_o(reg_w_sel),
    .mem_wr_en_o(mem_wr_en),
    .mem_rd_en_o(mem_rd_en),
    .mem_ctrl_o(mem_ctrl),
    .is_j_o(is_j),
    .is_br_o(is_br),
    .ALU_sel1_o(ALU_sel1),
    .ALU_sel2_o(ALU_sel2),
    .ALU_ctrl_o(ALU_ctrl),
    .cmp_op_o(cmp_op),
    
    .is_csr_o(is_csr),
    .csr_op_o(csr_op),
    .is_csr_imm_o(is_csr_imm)
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
    .imm_i(decode_imm),
    // reg addr
    .rd_i(decode_rd),
    .rs1_i(decode_rs1),
    .rs2_i(decode_rs2),
    // WB stage
    .reg_wr_en_i(reg_wr_en),
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
    .imm_o(EX_imm_out),
    // reg addr
    .rd_o(EX_rd_out),
    .rs1_o(EX_rs1_out),
    .rs2_o(EX_rs2_out),
    // WB stage
    .reg_wr_en_o(EX_reg_wr_en_out),
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

// done logic
assign EX_done = (!EX_pc_valid_out) | 
    ALU_done | 
    Br_done | 
    LSU_done | 
    SYS_done | 
    0; // (FU_done && !(|FU_err)) | ...

// Forwarding ==================
Mux2to1 #(.size(32)) m_EX_fwd1_MUX(
    .sel(EX_fwd1_sel),
    .s0(reg_data_in),
    .s1(EX_reg_rd_data1_out),
    .out(EX_fwd_data1)
);
Mux2to1 #(.size(32)) m_EX_fwd2_MUX(
    .sel(EX_fwd2_sel),
    .s0(reg_data_in),
    .s1(EX_reg_rd_data2_out),
    .out(EX_fwd_data2)
);

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

// LSU =========================
// not implemented yet, a simple one is used
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
        MEM_mem_wr_data_out <= EX_fwd_data2;
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
assign SYS_done = csr_wr_en | (|csr_exception) | csr_br_taken;

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
