module PipelineCPU (
    input clk,
    input rst_n,
    output signed [31:0] r [0:31]
);
//================================================================
//wires

// PC
wire pc_sel;
wire pc_en;
wire [31:0]pc_out;
wire [31:0]pc_in;
wire [31:0]pc_p4;

// inst mem
wire [31:0]inst_out;

// IF_ID_Reg
wire IFID_clear;
wire IFID_enable;

wire [31:0]IFID_pc_out;
wire [31:0]IFID_pc4_out;
wire [31:0]IFID_inst_out;

// ================================
// Control Logic
wire regWrite;
wire [1:0] regWSrc;
wire memWrite;
wire memRead;
wire [3:0] memCtrl; //word byte half
wire isJump;
wire isBranch;
wire PCorR1;
wire immorR2;
wire [3:0] ALUCtrl;
wire [2:0] cmpOp;

// Register File
wire [31:0]regData_in;
wire [31:0]regData1_out;
wire [31:0]regData2_out;

// imm
wire [31:0]imm_out;

// ================================================================
// ID_EX_Reg
wire IDEX_enable;
wire IDEX_clear;
// data_out
wire [31:0] IDEX_pc4_out;
wire [31:0] IDEX_pc_out;
wire [31:0] IDEX_readData1_out;
wire [31:0] IDEX_readData2_out;
wire [31:0] IDEX_imm_out;
wire [4:0]  IDEX_rd_out;
wire [4:0]  IDEX_rs1_out;
wire [4:0]  IDEX_rs2_out;
// control_out
wire IDEX_regWrite_out;
wire [1:0] IDEX_regWSrc_out;
// mem
wire IDEX_memRead_out;
wire IDEX_memWrite_out;
wire [3:0] IDEX_memCtrl_out;
// Br and Jump
wire IDEX_isJump_out;
wire IDEX_isBranch_out;
// ALU
wire IDEX_PCorR1_out;
wire IDEX_immorR2_out;
wire [3:0]IDEX_ALUCtrl_out;
// cmpOp
wire [2:0]IDEX_cmpOp_out;

wire [2:0]IDEX_funct3_out;
wire IDEX_funct7_out;

// ================================================================
// EX_MEM_Reg
wire [31:0] EX_MEM_pc4_out;
wire [31:0] EX_MEM_ALURes_out;
wire [31:0] EX_MEM_writeData_out;
wire [4:0]  EX_MEM_rd_out;

wire        EX_MEM_regWrite_out;
wire [1:0]  EX_MEM_regWSrc_out;
wire        EX_MEM_memWrite_out;
wire        EX_MEM_memRead_out;
wire [3:0]  EX_MEM_memCtrl_out;

// ALU
wire [31:0]ALU_in1;
wire [31:0]ALU_in2;
wire [31:0]ALU_out;
wire zero_flag;

// memory
wire [31:0]memData_out;

// MEM_WB_Reg
wire [31:0] MEM_WB_pc4_out;
wire [31:0] MEM_WB_ALURes_out;
wire [31:0] MEM_WB_memData_out;
wire [4:0]  MEM_WB_rd_out;
// control_out
wire        MEM_WB_regWrite_out;
wire [1:0]  MEM_WB_regWSrc_out;

wire [31:0] fw_data1, fw_data2;
wire brTaken;

// Forwarding
wire [1:0] EX_forward1_sel;
wire [1:0] EX_forward2_sel;

// Hazerd
wire hazardIDEn;
wire hazardEXClear;

//================================================================
//componets

Forwarding_Unit m_Forward(
    .ex_Rs1(IDEX_rs1_out),
    .ex_Rs2(IDEX_rs2_out),
    .mem_Rd(EX_MEM_rd_out),
    .mem_RegWrite(EX_MEM_regWrite_out),
    .wb_Rd(MEM_WB_rd_out),
    .wb_RegWrite(MEM_WB_regWrite_out),
    .ex_ForwardA(EX_forward1_sel),
    .ex_ForwardB(EX_forward2_sel)
);

HazardDetection m_Hazard(
    .ex_MemRead(IDEX_memRead_out),
    .ex_Rd(IDEX_rd_out),
    .id_R1(IFID_inst_out[19:15]),
    .id_R2(IFID_inst_out[24:20]),
    .hazardPCEn(pc_en),
    .hazardIDEn(hazardIDEn),
    .hazardEXClear(hazardEXClear)
);

assign IFID_enable = hazardIDEn;
assign IFID_clear = brTaken;

assign IDEX_enable = 1;
assign IDEX_clear = hazardEXClear | brTaken;

// ================================
// instruction fetch stage

PC m_PC(
    .clk(clk),
    .rst_n(rst_n),
    .enable(pc_en),
    .pc_in(pc_in),
    .pc_out(pc_out)
);
Adder m_PC_p4(
    .a(pc_out),
    .b(32'd4),
    .sum(pc_p4)
);
Mux2to1 #(.size(32)) m_PC_MUX(
    .sel(pc_sel),
    .s0(pc_p4),
    .s1(ALU_out),
    .out(pc_in)
);

InstructionMemory m_InstMem(
    .readAddr(pc_out),
    .inst(inst_out)
);

// ================================
// instruction decode stage
IF_ID_Reg m_IF_ID_Reg(
    .clk(clk),
    .rst_n(rst_n),

    .clear(IFID_clear),
    .enable(IFID_enable),

    .pc_i(pc_out),
    .pc_4_i(pc_p4),
    .pc_o(IFID_pc_out),
    .pc_4_o(IFID_pc4_out),

    .inst_i(inst_out),
    .inst_o(IFID_inst_out)
);

Register m_Register(
    .clk(clk),
    .rst_n(rst_n),

    .regWrite(MEM_WB_regWrite_out),//write enable

    .readReg1(IFID_inst_out[19:15]),//addr
    .readReg2(IFID_inst_out[24:20]),//addr
    
    .writeReg(MEM_WB_rd_out),//addr
    .writeData(regData_in),
    
    .readData1(regData1_out),
    .readData2(regData2_out)
);

// ======= for validation =======
// == Dont change this section ==
assign r = m_Register.regs;
// ======= for vaildation =======

Control m_Control(
    .inst(IFID_inst_out),
    .regWrite(regWrite),
    .regWSrc(regWSrc),
    .memWrite(memWrite),
    .memRead(memRead),
    .memCtrl(memCtrl),
    .isJump(isJump),
    .isBranch(isBranch),
    .PCorR1(PCorR1),
    .immorR2(immorR2),
    .ALUCtrl(ALUCtrl),
    .cmpOp(cmpOp)
);

ImmGen m_ImmGen(
    .inst(IFID_inst_out),
    .imm(imm_out)
);

// ================================
// execution stage

ID_EX_Reg m_ID_EX_Reg(
    .clk(clk),
    .rst_n(rst_n),
    .enable(IDEX_enable),
    .clear(IDEX_clear),
    // data_in
    .pc4_i(IFID_pc4_out),
    .pc_i(IFID_pc_out),

    .readData1_i(regData1_out),
    .readData2_i(regData2_out),

    .imm_i(imm_out),

    .rd_i(IFID_inst_out[11:7]),
    .rs1_i(IFID_inst_out[19:15]),
    .rs2_i(IFID_inst_out[24:20]),
    // control_in
    .regWrite_i(regWrite),
    .regWSrc_i(regWSrc),
    // mem
    .memRead_i(memRead),
    .memWrite_i(memWrite),
    .memCtrl_i(memCtrl),
    // Br and Jump
    .isJump_i(isJump),
    .isBranch_i(isBranch),

    // ALU
    .PCorR1_i(PCorR1),
    .immorR2_i(immorR2),
    .ALUCtrl_i(ALUCtrl),

    .cmpOp_i(cmpOp),

    .funct3_i(IDEX_funct3_out),
    .funct7_i(IDEX_funct7_out),
    //=================================
    // data_out
    .pc4_o(IDEX_pc4_out),
    .pc_o(IDEX_pc_out),
    .readData1_o(IDEX_readData1_out),
    .readData2_o(IDEX_readData2_out),
    .imm_o(IDEX_imm_out),
    .rd_o(IDEX_rd_out),
    .rs1_o(IDEX_rs1_out),
    .rs2_o(IDEX_rs2_out),

    // control_out
    .regWrite_o(IDEX_regWrite_out),
    .regWSrc_o(IDEX_regWSrc_out),
    // mem
    .memRead_o(IDEX_memRead_out),
    .memWrite_o(IDEX_memWrite_out),
    .memCtrl_o(IDEX_memCtrl_out),
    // Br and Jump
    .isJump_o(IDEX_isJump_out),
    .isBranch_o(IDEX_isBranch_out),

    // ALU
    .PCorR1_o(IDEX_PCorR1_out),
    .immorR2_o(IDEX_immorR2_out),
    .ALUCtrl_o(IDEX_ALUCtrl_out),

    .cmpOp_o(IDEX_cmpOp_out),

    .funct3_o(IDEX_funct3_out),
    .funct7_o(IDEX_funct7_out)
);

Mux3to1 #(.size(32)) m_EX_forward1_MUX(
    .sel(EX_forward1_sel),
    .s0(regData_in),
    .s1(IDEX_readData1_out),
    .s2(EX_MEM_ALURes_out),
    .out(fw_data1)
);
Mux2to1 #(.size(32)) m_ALU_SRC1_MUX(
    .sel(IDEX_PCorR1_out),
    .s0(IDEX_pc_out),
    .s1(fw_data1),
    .out(ALU_in1)
);

Mux3to1 #(.size(32)) m_EX_forward2_MUX(
    .sel(EX_forward2_sel),
    .s0(regData_in),
    .s1(IDEX_readData2_out),
    .s2(EX_MEM_ALURes_out),
    .out(fw_data2)
);
Mux2to1 #(.size(32)) m_ALU_SRC2_MUX(
    .sel(IDEX_immorR2_out),
    .s0(fw_data2),
    .s1(IDEX_imm_out),
    .out(ALU_in2)
);

ALU m_ALU(
    .ALUCtl(IDEX_ALUCtrl_out),
    .A(ALU_in1),
    .B(ALU_in2),
    .ALUOut(ALU_out)
);

BranchComp m_BranchComp(
    .isBranch(IDEX_isBranch_out),
    .isJump(IDEX_isJump_out),
    .cmpOp(IDEX_cmpOp_out),
    .rs1(fw_data1),
    .rs2(fw_data2),
    .brTaken(brTaken)
);

assign pc_sel = brTaken;

// ================================
// mem access stage

EX_MEM_Reg m_EX_MEM_Reg(
    .clk(clk),
    .rst_n(rst_n),
    // data_in
    .pc4_i(IDEX_pc4_out),
    .ALURes_i(ALU_out),
    .writeData_i(fw_data2),
    .rd_i(IDEX_rd_out),
    // control_in
    .regWrite_i(IDEX_regWrite_out),
    .regWSrc_i(IDEX_regWSrc_out),

    .memWrite_i(IDEX_memWrite_out),
    .memRead_i(IDEX_memRead_out),
    .memCtrl_i(IDEX_memCtrl_out),
    // ===================================
    // data_out
    .pc4_o(EX_MEM_pc4_out),
    .ALURes_o(EX_MEM_ALURes_out),
    .writeData_o(EX_MEM_writeData_out),
    .rd_o(EX_MEM_rd_out),
    // control_out
    .regWrite_o(EX_MEM_regWrite_out),
    .regWSrc_o(EX_MEM_regWSrc_out),
    .memWrite_o(EX_MEM_memWrite_out),
    .memRead_o(EX_MEM_memRead_out),
    .memCtrl_o(EX_MEM_memCtrl_out)
);

DataMemory m_DataMemory(
    .rst_n(rst_n),
    .clk(clk),
    .memWrite(EX_MEM_memWrite_out),
    .memRead(EX_MEM_memRead_out),
    .memCtrl(EX_MEM_memCtrl_out),
    .address(EX_MEM_ALURes_out),
    .writeData(EX_MEM_writeData_out),
    .readData(memData_out)
);

//================================
//write back stage

MEM_WB_Reg m_MEM_WB_Reg(
    .clk(clk),
    .rst_n(rst_n),

    .pc4_i(EX_MEM_pc4_out),
    .ALURes_i(EX_MEM_ALURes_out),
    .memData_i(memData_out),
    .rd_i(EX_MEM_rd_out),
    // control_in
    .regWrite_i(EX_MEM_regWrite_out),
    .regWSrc_i(EX_MEM_regWSrc_out),
    // ===================================
    // data_out
    .pc4_o(MEM_WB_pc4_out),
    .ALURes_o(MEM_WB_ALURes_out),
    .memData_o(MEM_WB_memData_out),
    .rd_o(MEM_WB_rd_out),
    // control_out
    .regWrite_o(MEM_WB_regWrite_out),
    .regWSrc_o(MEM_WB_regWSrc_out)
);

Mux3to1 #(.size(32)) m_Mux_WriteData(
    .sel(MEM_WB_regWSrc_out),
    .s0(MEM_WB_pc4_out),
    .s1(MEM_WB_ALURes_out),
    .s2(MEM_WB_memData_out),
    .out(regData_in)
);

endmodule
