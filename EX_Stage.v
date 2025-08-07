`include "riscv_defs.v"
module EX_Stage(
    input clk,
    input rst_n,
// inputs ======================
    // system inputs
    input en,
    input clear,

    input  is_impl_i,
    input  pc_valid_i,
    input  [31:0] pc_i,
    input  [31:0] pc_p4_i,
    input  [31:0] inst_i,

    input [4:0] rd_i,
    input [4:0] rs1_i,
    input [4:0] rs2_i,
    // Data inputs
    input [31:0] reg_rd_data1_i,
    input [31:0] reg_rd_data2_i,

    input [31:0] imm_i,
    // Mem Control
    input mem_rd_en_i,
    input mem_wr_en_i,
    input [3:0] mem_ctrl_i,
    // Branch Control
    input is_j_i,
    input is_br_i,
    input [2:0] cmp_op_i,
    // ALU Control
    input ALU_sel1_i,
    input ALU_sel2_i,
    input [3:0] ALU_ctrl_i,
    // CSR Control
    input [11:0] csr_addr_i,
    input is_csr_i,
    input [2:0] csr_op_i,
    input is_csr_imm_i,
    input csr_sel_i,
    // WB stage control inputs
    input reg_wr_en_i,
    input [2:0] reg_w_sel_i,
// outputs =====================
    // system output
    output done_o,

    output is_impl_o,
    output pc_valid_o,
    output [31:0] pc_o,
    output [31:0] pc_p4_o,
    
    output [4:0] rs1_o,
    output [4:0] rs2_o,
    output [4:0] rd_o,
    // WB stage
    output reg_wr_en_o,
    output [2:0] reg_w_sel_o,

// Memory ======================
    output [3:0] d_mem_ctrl_o,
    output d_mem_wr_en_o,
    output d_mem_rd_en_o,
    output [31:0] d_mem_addr_o,
    output [31:0] d_mem_wr_data_o,
// Branch ======================
    output br_taken_o,
    output [1:0] pc_sel_o, // pc_p4, ALU_out, csr_pc_target
    output [31:0] csr_pc_target_o,
// ALU =========================
    output [31:0] ALU_o,
// CSR =========================
    output [31:0] csr_rd_data_o,
// Forwarding ==================
    input [31:0] WB_data_i,
    input [4:0] WB_rd_i,
    input WB_reg_wr_en_i
);
// Wires =======================
// Pipiline Reg
wire        EX_is_impl_out;
wire        EX_pc_valid_out;
wire [31:0] EX_inst_out;
wire [31:0] EX_pc_out;
wire [31:0] EX_pc_p4_out;
wire [31:0] EX_reg_rd_data1_out;
wire [31:0] EX_reg_rd_data2_out;
wire [31:0] EX_imm_out;
wire [4:0]  EX_rd_out;
wire [4:0]  EX_rs1_out;
wire [4:0]  EX_rs2_out;

wire        EX_reg_wr_en_out;
wire [2:0]  EX_reg_w_sel_out;

wire        EX_mem_rd_en_out;
wire        EX_mem_wr_en_out;
wire [3:0]  EX_mem_ctrl_out;

wire        EX_is_j_out;
wire        EX_is_br_out;

wire        EX_ALU_sel1_out;
wire        EX_ALU_sel2_out;
wire [3:0]  EX_ALU_ctrl_out;

wire [2:0]  EX_cmp_op_out;

wire [11:0] EX_csr_addr_out;

wire        EX_is_csr_out;
wire [2:0]  EX_csr_op_out;
wire        EX_is_csr_imm_out; // is csr[r w]i
wire        EX_csr_wr_en_out;
wire        EX_csr_sel_out; // rs1 or imm

wire [2:0]  EX_funct3_out;
wire        EX_funct7_out;

// Forwarding
wire [31:0] fwd_data1, fwd_data2;

// EX Ctrl
wire        EX_done;
wire        EX_start;

// ALU
wire        ALU_start;
wire        ALU_done;
wire [31:0] ALU_in1;
wire [31:0] ALU_in2;
wire [31:0] ALU_out;

// Branch
wire        Br_start;
wire        Br_done;

// LSU
wire        LSU_start;
wire        LSU_done;
wire [`EXCEPTION_W-1:0] LSU_exception;

// CSR
wire        SYS_done;
wire [31:0] csr_rd_data; // output of CSRFile
wire [31:0] csr_wr_data; // output of CSR
wire        csr_wr_en;
wire [1:0]  csr_priv;
wire [`EXCEPTION_W-1:0] csr_exception;
wire        csr_br_taken;
wire [31:0] csr_mstatus;
wire [31:0] csr_interrupt;

// Pipeline Register ===========
EX_Reg m_EX_Reg(
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .clear(clear),
    // data_in
    .is_impl_i(is_impl_i),
    .pc_valid_i(pc_valid_i),
    .inst_i(inst_i),
    .pc_p4_i(pc_p4_i),
    .pc_i(pc_i),

    .reg_rd_data1_i(reg_rd_data1_i),
    .reg_rd_data2_i(reg_rd_data2_i),

    .imm_i(imm_i),

    .rd_i(rd_i),
    .rs1_i(rs1_i),
    .rs2_i(rs2_i),
    // control_in
    .reg_wr_en_i(reg_wr_en_i),
    .reg_w_sel_i(reg_w_sel_i),
    // mem
    .mem_rd_en_i(mem_rd_en_i),
    .mem_wr_en_i(mem_wr_en_i),
    .mem_ctrl_i(mem_ctrl_i),
    // Br and Jump
    .is_j_i(is_j_i),
    .is_br_i(is_br_i),

    // ALU
    .ALU_sel1_i(ALU_sel1_i),
    .ALU_sel2_i(ALU_sel2_i),
    .ALU_ctrl_i(ALU_ctrl_i),

    .cmp_op_i(cmp_op_i),

    // csr
    .csr_addr_i(csr_addr_i),

    .is_csr_i(is_csr_i),
    .csr_op_i(csr_op_i),
    .is_csr_imm_i(is_csr_imm_i),
    .csr_sel_i(csr_sel_i),

    .funct3_i(),
    .funct7_i(),
    // =============================
    // data_out
    .is_impl_o(EX_is_impl_out),
    .pc_valid_o(EX_pc_valid_out),
    .inst_o(EX_inst_out),
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
    // csr
    .csr_addr_o(EX_csr_addr_out),
    .is_csr_o(EX_is_csr_out),
    .csr_op_o(EX_csr_op_out),
    .is_csr_imm_o(EX_is_csr_imm_out),
    .csr_sel_o(EX_csr_sel_out),

    .funct3_o(EX_funct3_out),
    .funct7_o(EX_funct7_out)
);

// Forwarding ==================
wire fwd1_sel, fwd2_sel;
ForwardUnit m_Forward(
    .EX_rs1(EX_rs1_out),
    .EX_rs2(EX_rs2_out),
    
    .WB_rd(WB_rd_i),
    .WB_reg_wr_en(WB_reg_wr_en_i),
    
    .EX_fwd_sel1(fwd1_sel),
    .EX_fwd_sel2(fwd2_sel)
);

Mux2to1 #(.size(32)) m_EX_fwd1_MUX(
    .sel(fwd1_sel),
    .s0(WB_data_i),
    .s1(EX_reg_rd_data1_out),
    .out(fwd_data1)
);
Mux2to1 #(.size(32)) m_EX_fwd2_MUX(
    .sel(fwd2_sel),
    .s0(WB_data_i),
    .s1(EX_reg_rd_data2_out),
    .out(fwd_data2)
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

// ALU =========================
Mux2to1 #(.size(32)) m_ALU_SRC1_MUX(
    .sel(EX_ALU_sel1_out),
    .s0(EX_pc_out),
    .s1(fwd_data1),
    .out(ALU_in1)
);
Mux2to1 #(.size(32)) m_ALU_SRC2_MUX(
    .sel(EX_ALU_sel2_out),
    .s0(fwd_data2),
    .s1(EX_imm_out),
    .out(ALU_in2)
);
ALU_top m_ALU(
    .ALU_ctrl(EX_ALU_ctrl_out),
    .a(ALU_in1),
    .b(ALU_in2),
    .out(ALU_out)
);
assign ALU_done=ALU_start;

// Branch ======================
BranchUnit m_BranchUnit(
    .is_br(EX_is_br_out),
    .is_j(EX_is_j_out),
    .is_csr_br(csr_br_taken),

    .cmp_op(EX_cmp_op_out),
    .reg_rd_data1(fwd_data1),
    .reg_rd_data2(fwd_data2),
    
    .br_taken(br_taken_o),
    .pc_sel(pc_sel_o)
);
assign Br_done = Br_start; // only deal with inst br

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
        MEM_mem_addr_out <= (fwd_data1 + EX_imm_out);
        MEM_mem_wr_data_out <= fwd_data2;
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
    .reg_rd_data1_i(fwd_data1),
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
    .csr_target_o(csr_pc_target_o),

    .priv_o(csr_priv),
    .mstatus_o(csr_mstatus),
    .interrupt_o(csr_interrupt)
);

assign SYS_done = csr_wr_en | (|csr_exception);


// Output ======================
assign done_o      = EX_done;

assign is_impl_o   = EX_is_impl_out;
assign pc_valid_o  = EX_pc_valid_out;
assign pc_o        = EX_pc_out;
assign pc_p4_o     = EX_pc_p4_out;
assign ALU_o       = ALU_out;

assign csr_rd_data_o = csr_rd_data;

assign rs1_o       = EX_rs1_out;
assign rs2_o       = EX_rs2_out;
assign rd_o        = EX_rd_out;
assign reg_wr_en_o = EX_reg_wr_en_out;
assign reg_w_sel_o = EX_reg_w_sel_out;

assign d_mem_ctrl_o = MEM_mem_ctrl_out;
assign d_mem_wr_en_o = MEM_mem_wr_en_out;
assign d_mem_rd_en_o = MEM_mem_rd_en_out;
assign d_mem_addr_o = MEM_mem_addr_out;
assign d_mem_wr_data_o = MEM_mem_wr_data_out;

endmodule
