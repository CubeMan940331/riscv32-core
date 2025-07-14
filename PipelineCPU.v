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
wire pc_sel;
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

// Control Logic ==============
wire reg_wr_en;
// 0: pc_p4, 1: ALU, 2: mem
wire [1:0] reg_w_sel;
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
wire [1:0] EX_reg_w_sel_out;
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

// ALU ========================
wire [31:0] ALU_in1;
wire [31:0] ALU_in2;
wire [31:0] ALU_out;
wire zero_flag;

// BranchCmp ==================
wire br_taken;

// MEM_Reg ====================
wire [31:0] MEM_pc_p4_out;
wire [31:0] MEM_ALU_out;
wire [31:0] MEM_reg_rd_data2_out; 
wire [4:0]  MEM_rd_out;

wire        MEM_reg_wr_en_out;
wire [1:0]  MEM_reg_w_sel_out;
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
// control_out
wire        WB_reg_wr_en_out;
wire [1:0]  WB_reg_w_sel_out;

// EX Forward Mux =============
wire [31:0] EX_fwd_data1;
wire [31:0] EX_fwd_data2;

// Forward ====================
wire [1:0] EX_fwd1_sel;
wire [1:0] EX_fwd2_sel;

// Hazerd =====================
wire hazardIDEn;
wire hazardEXClear;

//componets
//================================================================

ForwardUnit m_Forward(
    .EX_rs1(EX_rs1_out),
    .EX_rs2(EX_rs2_out),
    .MEM_rd(MEM_rd_out),
    .MEM_reg_wr_en(MEM_reg_wr_en_out),
    .WB_rd(WB_rd_out),
    .WB_reg_wr_en(WB_reg_wr_en_out),
    .EX_fwd_sel1(EX_fwd1_sel),
    .EX_fwd_sel2(EX_fwd2_sel)
);

HazardUnit m_Hazard(
    .EX_mem_rd_en   (EX_mem_rd_en_out),
    .EX_rd          (EX_rd_out),
    .ID_rs1         (ID_inst_out[19:15]),
    .ID_rs2         (ID_inst_out[24:20]),
    .pc_en          (pc_en),
    .ID_en          (hazardIDEn),
    .EX_clear       (hazardEXClear)
);

assign ID_en = hazardIDEn;
assign ID_clear = br_taken;

assign EX_en = 1;
assign EX_clear = hazardEXClear | br_taken;

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

Mux2to1 #(.size(32)) m_PC_MUX(
    .sel(pc_sel),
    .s0(pc_p4),
    .s1(ALU_out),
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
    .imm(decode_imm)
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
    .cmp_op(cmp_op)
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

    .cmp_op_o(EX_cmp_op_out),

    .funct3_o(EX_funct3_out),
    .funct7_o(EX_funct7_out)
);

Mux3to1 #(.size(32)) m_EX_fwd1_MUX(
    .sel(EX_fwd1_sel),
    .s0(reg_data_in),
    .s1(EX_reg_rd_data1_out),
    .s2(MEM_ALU_out),
    .out(EX_fwd_data1)
);
Mux2to1 #(.size(32)) m_ALU_SRC1_MUX(
    .sel(EX_ALU_sel1_out),
    .s0(EX_pc_out),
    .s1(EX_fwd_data1),
    .out(ALU_in1)
);

Mux3to1 #(.size(32)) m_EX_forward2_MUX(
    .sel(EX_fwd2_sel),
    .s0(reg_data_in),
    .s1(EX_reg_rd_data2_out),
    .s2(MEM_ALU_out),
    .out(EX_fwd_data2)
);
Mux2to1 #(.size(32)) m_ALU_SRC2_MUX(
    .sel(EX_ALU_sel2_out),
    .s0(EX_fwd_data2),
    .s1(EX_imm_out),
    .out(ALU_in2)
);

ALU m_ALU(
    .ALU_ctrl(EX_ALU_ctrl_out),
    .a(ALU_in1),
    .b(ALU_in2),
    .out(ALU_out)
);

BranchCmp m_BranchCmp(
    .is_br(EX_is_br_out),
    .is_j(EX_is_j_out),
    .cmp_op(EX_cmp_op_out),
    .reg_rd_data1(EX_fwd_data1),
    .reg_rd_data2(EX_fwd_data2),
    .br_taken(br_taken)
);

assign pc_sel = br_taken;

// ================================
// mem access stage

MEM_Reg m_EX_MEM_Reg(
    .clk(clk),
    .rst_n(rst_n),
    // data_in
    .pc_p4_i(EX_pc_p4_out),
    .ALU_i(ALU_out),
    .reg_rd_data2_i(EX_fwd_data2),
    .rd_i(EX_rd_out),
    // control_in
    .reg_wr_en_i(EX_reg_wr_en_out),
    .reg_w_sel_i(EX_reg_w_sel_out),

    .mem_wr_en_i(EX_mem_wr_en_out),
    .mem_rd_en_i(EX_mem_rd_en_out),
    .mem_ctrl_i(EX_mem_ctrl_out),
    // ===================================
    // data_out
    .pc_p4_o(MEM_pc_p4_out),
    .ALU_o(MEM_ALU_out),
    .reg_rd_data2_o(MEM_reg_rd_data2_out),
    .rd_o(MEM_rd_out),
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
    // control_in
    .reg_wr_en_i(MEM_reg_wr_en_out),
    .reg_w_sel_i(MEM_reg_w_sel_out),
    // ===================================
    // data_out
    .pc_p4_o(WB_pc_p4_out),
    .ALU_o(WB_ALU_out),
    .mem_data_o(WB_mem_data_out),
    .rd_o(WB_rd_out),
    // control_out
    .reg_wr_en_o(WB_reg_wr_en_out),
    .reg_w_sel_o(WB_reg_w_sel_out)
);

Mux3to1 #(.size(32)) m_Mux_WriteData(
    .sel(WB_reg_w_sel_out),
    .s0(WB_pc_p4_out),
    .s1(WB_ALU_out),
    .s2(WB_mem_data_out),
    .out(reg_data_in)
);

endmodule
