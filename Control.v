`include "riscv_defs.v"
/* verilator lint_off UNUSEDSIGNAL */
module Control (
    input [31:0] inst,
    // WB stage
    output reg reg_wr_en_o,
    output reg [2:0] reg_w_sel_o, // 0: pc_p4, 1: ALU, 2: mem, 3:csr, 4: FPU
    
    // LSU
    output reg mem_wr_en_o,
    output reg mem_rd_en_o,
    output reg [3:0] mem_ctrl_o,
    
    // Branch
    output reg is_j_o,
    output reg is_br_o,
    output reg [2:0] cmp_op_o,
    
    // ALU
    output reg [3:0] ALU_ctrl_o,
    output reg ALU_sel1_o, // 0: PC, 1: rs1
    output reg ALU_sel2_o, // 0: rs2, 1: imm

    // CSR
    output reg is_csr_o,
    output reg [2:0] csr_op_o,
    output reg is_csr_imm_o, // is csr[r w]i

    output is_impl_o
);

// decode
wire [6:0] opcode = inst[6:0];
wire [2:0] funct3 = inst[14:12];
wire [6:0] funct7 = inst[31:25];
wire [11:0] imm12 = inst[31:20];

assign is_impl_o = is_impl_w;
assign reg_wr_en_o = reg_wr_en_w;
assign mem_wr_en_o = mem_wr_en_w;
assign mem_rd_en_o = mem_rd_en_w;
assign mem_ctrl_o = mem_ctrl_r;
assign is_j_o = is_j_w;
assign is_br_o = is_br_w;
assign ALU_ctrl_o = alu_ctrl_r;
assign cmp_op_o = cmp_op_r;
assign is_csr_o = is_csr_w;
assign csr_op_o = csr_op_w;
assign is_csr_imm_o = is_csr_imm_w;
assign ALU_sel1_o = alu_sel1_w;
assign ALU_sel2_o = alu_sel2_w;
assign reg_w_sel_o = reg_w_sel_r;

// 0: PC, 1: rs1
wire alu_sel1_w = ((inst&`INST_ADDI_MASK) == `INST_ADDI)   ||
                  ((inst&`INST_SLTI_MASK) == `INST_SLTI)   ||
                  ((inst&`INST_SLTIU_MASK) == `INST_SLTIU) ||
                  ((inst&`INST_ANDI_MASK) == `INST_ANDI)   ||
                  ((inst&`INST_ORI_MASK) == `INST_ORI)     ||
                  ((inst&`INST_XORI_MASK) == `INST_XORI)   ||
                  ((inst&`INST_SLLI_MASK) == `INST_SLLI)   ||
                  ((inst&`INST_SRLI_MASK) == `INST_SRLI)   ||
                  ((inst&`INST_SRAI_MASK) == `INST_SRAI)   ||
                  ((inst&`INST_ADD_MASK) == `INST_ADD)     ||
                  ((inst&`INST_SLT_MASK) == `INST_SLT)     ||
                  ((inst&`INST_SLTU_MASK) == `INST_SLTU)   ||
                  ((inst&`INST_AND_MASK) == `INST_AND)     ||
                  ((inst&`INST_OR_MASK) == `INST_OR)       ||
                  ((inst&`INST_XOR_MASK) == `INST_XOR)     ||
                  ((inst&`INST_SLL_MASK) == `INST_SLL)     ||
                  ((inst&`INST_SRL_MASK) == `INST_SRL)     ||
                  ((inst&`INST_SUB_MASK) == `INST_SUB)     ||
                  ((inst&`INST_SRA_MASK) == `INST_SRA)     ||
                  ((inst&`INST_JALR_MASK) == `INST_JALR);
// 0: rs2, 1: imm
wire alu_sel2_w = ((inst&`INST_ADDI_MASK) == `INST_ADDI)   ||
                  ((inst&`INST_SLTI_MASK) == `INST_SLTI)   ||
                  ((inst&`INST_SLTIU_MASK) == `INST_SLTIU) ||
                  ((inst&`INST_ANDI_MASK) == `INST_ANDI)   ||
                  ((inst&`INST_ORI_MASK) == `INST_ORI)     ||
                  ((inst&`INST_XORI_MASK) == `INST_XORI)   ||
                  ((inst&`INST_SLLI_MASK) == `INST_SLLI)   ||
                  ((inst&`INST_SRLI_MASK) == `INST_SRLI)   ||
                  ((inst&`INST_SRAI_MASK) == `INST_SRAI)   ||
                  ((inst&`INST_LUI_MASK) == `INST_LUI)     ||
                  ((inst&`INST_AUIPC_MASK) == `INST_AUIPC) ||
                  ((inst&`INST_JAL_MASK) == `INST_JAL)     ||
                  ((inst&`INST_JALR_MASK) == `INST_JALR)   ||
                  ((inst&`INST_BEQ_MASK) == `INST_BEQ)     ||
                  ((inst&`INST_BNE_MASK) == `INST_BNE)     ||
                  ((inst&`INST_BLT_MASK) == `INST_BLT)     ||
                  ((inst&`INST_BGE_MASK) == `INST_BGE)     ||
                  ((inst&`INST_BLTU_MASK) == `INST_BLTU)   ||
                  ((inst&`INST_BGEU_MASK) == `INST_BGEU)   ;

wire is_impl_w =((inst&`INST_ADDI_MASK) == `INST_ADDI)   ||
                ((inst&`INST_SLTI_MASK) == `INST_SLTI)   ||
                ((inst&`INST_SLTIU_MASK) == `INST_SLTIU) ||
                ((inst&`INST_ANDI_MASK) == `INST_ANDI)   ||
                ((inst&`INST_ORI_MASK) == `INST_ORI)     ||
                ((inst&`INST_XORI_MASK) == `INST_XORI)   ||
                ((inst&`INST_SLLI_MASK) == `INST_SLLI)   ||
                ((inst&`INST_SRLI_MASK) == `INST_SRLI)   ||
                ((inst&`INST_SRAI_MASK) == `INST_SRAI)   ||
                ((inst&`INST_LUI_MASK) == `INST_LUI)     ||
                ((inst&`INST_AUIPC_MASK) == `INST_AUIPC) ||
                ((inst&`INST_ADD_MASK) == `INST_ADD)     ||
                ((inst&`INST_SLT_MASK) == `INST_SLT)     ||
                ((inst&`INST_SLTU_MASK) == `INST_SLTU)   ||
                ((inst&`INST_AND_MASK) == `INST_AND)     ||
                ((inst&`INST_OR_MASK) == `INST_OR)       ||
                ((inst&`INST_XOR_MASK) == `INST_XOR)     ||
                ((inst&`INST_SLL_MASK) == `INST_SLL)     ||
                ((inst&`INST_SRL_MASK) == `INST_SRL)     ||
                ((inst&`INST_SUB_MASK) == `INST_SUB)     ||
                ((inst&`INST_SRA_MASK) == `INST_SRA)     ||
                // J-Type
                ((inst&`INST_JAL_MASK) == `INST_JAL)   ||
                ((inst&`INST_JALR_MASK) == `INST_JALR) ||
                ((inst&`INST_BEQ_MASK) == `INST_BEQ)   ||
                ((inst&`INST_BNE_MASK) == `INST_BNE)   ||
                ((inst&`INST_BLT_MASK) == `INST_BLT)   ||
                ((inst&`INST_BGE_MASK) == `INST_BGE)   ||
                ((inst&`INST_BLTU_MASK) == `INST_BLTU) ||
                ((inst&`INST_BGEU_MASK) == `INST_BGEU) ||
                ((inst&`INST_LB_MASK) == `INST_LB)     ||
                ((inst&`INST_LBU_MASK) == `INST_LBU)   ||
                ((inst&`INST_LH_MASK) == `INST_LH)     ||
                ((inst&`INST_LHU_MASK) == `INST_LHU)   ||
                ((inst&`INST_LW_MASK) == `INST_LW)     ||
                ((inst&`INST_SB_MASK) == `INST_SB)     ||
                ((inst&`INST_SH_MASK) == `INST_SH)     ||
                ((inst&`INST_SW_MASK) == `INST_SW)     ||
                // Zicsr
                ((inst&`INST_CSRRW_MASK) == `INST_CSRRW)   ||
                ((inst&`INST_CSRRS_MASK) == `INST_CSRRS)   ||
                ((inst&`INST_CSRRC_MASK) == `INST_CSRRC)   ||
                ((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI) ||
                ((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI) ||
                ((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI) ||
                ((inst&`INST_ECALL_MASK) == `INST_ECALL)   ;

wire reg_wr_en_w = ((inst&`INST_ADDI_MASK) == `INST_ADDI)    ||
                    ((inst&`INST_SLTI_MASK) == `INST_SLTI)   ||
                    ((inst&`INST_SLTIU_MASK) == `INST_SLTIU) ||
                    ((inst&`INST_ANDI_MASK) == `INST_ANDI)   ||
                    ((inst&`INST_ORI_MASK) == `INST_ORI)     ||
                    ((inst&`INST_XORI_MASK) == `INST_XORI)   ||
                    ((inst&`INST_SLLI_MASK) == `INST_SLLI)   ||
                    ((inst&`INST_SRLI_MASK) == `INST_SRLI)   ||
                    ((inst&`INST_SRAI_MASK) == `INST_SRAI)   ||
                    ((inst&`INST_LUI_MASK) == `INST_LUI)     ||
                    ((inst&`INST_AUIPC_MASK) == `INST_AUIPC) ||
                    ((inst&`INST_ADD_MASK) == `INST_ADD)     ||
                    ((inst&`INST_SLT_MASK) == `INST_SLT)     ||
                    ((inst&`INST_SLTU_MASK) == `INST_SLTU)   ||
                    ((inst&`INST_AND_MASK) == `INST_AND)     ||
                    ((inst&`INST_OR_MASK) == `INST_OR)       ||
                    ((inst&`INST_XOR_MASK) == `INST_XOR)     ||
                    ((inst&`INST_SLL_MASK) == `INST_SLL)     ||
                    ((inst&`INST_SRL_MASK) == `INST_SRL)     ||
                    ((inst&`INST_SUB_MASK) == `INST_SUB)     ||
                    ((inst&`INST_SRA_MASK) == `INST_SRA)     ||
                    // Jump
                    ((inst&`INST_JAL_MASK) == `INST_JAL)   ||
                    ((inst&`INST_JALR_MASK) == `INST_JALR) ||
                    // load
                    ((inst&`INST_LB_MASK) == `INST_LB)   ||
                    ((inst&`INST_LBU_MASK) == `INST_LBU) ||
                    ((inst&`INST_LH_MASK) == `INST_LH)   ||
                    ((inst&`INST_LHU_MASK) == `INST_LHU) ||
                    ((inst&`INST_LW_MASK) == `INST_LW)   ||
                    // CSR
                    ((inst&`INST_CSRRW_MASK) == `INST_CSRRW)   ||
                    ((inst&`INST_CSRRS_MASK) == `INST_CSRRS)   ||
                    ((inst&`INST_CSRRC_MASK) == `INST_CSRRC)   ||
                    ((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI) ||
                    ((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI) ||
                    ((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI) ;
                    // FPU
                    // TODO

wire mem_rd_en_w = ((inst&`INST_LB_MASK) == `INST_LB)    ||
                    ((inst&`INST_LBU_MASK) == `INST_LBU) ||
                    ((inst&`INST_LH_MASK) == `INST_LH)   ||
                    ((inst&`INST_LHU_MASK) == `INST_LHU) ||
                    ((inst&`INST_LW_MASK) == `INST_LW)   ;
                    // FPU
                    // ((inst&`INST_FLW_MASK) == `INST_FLW) ||
                    // ((inst&`INST_FLD_MASK) == `INST_FLD);
                    
wire mem_wr_en_w = ((inst&`INST_SB_MASK) == `INST_SB) ||
                    ((inst&`INST_SH_MASK) == `INST_SH)||
                    ((inst&`INST_SW_MASK) == `INST_SW);
                    // FPU
                    // ((inst&`INST_FSW_MASK) == `INST_FSW) ||
                    // ((inst&`INST_FSD_MASK) == `INST_FSD);

wire is_j_w = ((inst&`INST_JAL_MASK) == `INST_JAL)  ||
              ((inst&`INST_JALR_MASK) == `INST_JALR);

wire is_br_w = ((inst&`INST_BEQ_MASK) == `INST_BEQ)   ||
               ((inst&`INST_BNE_MASK) == `INST_BNE)   ||
               ((inst&`INST_BLT_MASK) == `INST_BLT)   ||
               ((inst&`INST_BGE_MASK) == `INST_BGE)   ||
               ((inst&`INST_BLTU_MASK) == `INST_BLTU) ||
               ((inst&`INST_BGEU_MASK) == `INST_BGEU) ;

wire is_csr_w = ((inst&`INST_CSRRW_MASK) == `INST_CSRRW)    ||
                ((inst&`INST_CSRRS_MASK) == `INST_CSRRS)    ||
                ((inst&`INST_CSRRC_MASK) == `INST_CSRRC)    ||
                ((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI)  ||
                ((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI)  ||
                ((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI)  ||
                ((inst & `INST_ECALL_MASK) == `INST_ECALL)  ||
                ((inst & `INST_EBREAK_MASK) == `INST_EBREAK)||
                ((inst & `INST_ERET_MASK) == `INST_ERET)    ;

wire is_csr_imm_w = ((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI)  ||
                    ((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI)  ||
                    ((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI)  ;

wire is_alu_w = ((inst&`INST_ADDI_MASK) == `INST_ADDI)   ||
                ((inst&`INST_SLTI_MASK) == `INST_SLTI)   ||
                ((inst&`INST_SLTIU_MASK) == `INST_SLTIU) ||
                ((inst&`INST_ANDI_MASK) == `INST_ANDI)   ||
                ((inst&`INST_ORI_MASK) == `INST_ORI)     ||
                ((inst&`INST_XORI_MASK) == `INST_XORI)   ||
                ((inst&`INST_SLLI_MASK) == `INST_SLLI)   ||
                ((inst&`INST_SRLI_MASK) == `INST_SRLI)   ||
                ((inst&`INST_SRAI_MASK) == `INST_SRAI)   ||
                ((inst&`INST_LUI_MASK) == `INST_LUI)     ||
                ((inst&`INST_AUIPC_MASK) == `INST_AUIPC) ||
                ((inst&`INST_ADD_MASK) == `INST_ADD)     ||
                ((inst&`INST_SLT_MASK) == `INST_SLT)     ||
                ((inst&`INST_SLTU_MASK) == `INST_SLTU)   ||
                ((inst&`INST_AND_MASK) == `INST_AND)     ||
                ((inst&`INST_OR_MASK) == `INST_OR)       ||
                ((inst&`INST_XOR_MASK) == `INST_XOR)     ||
                ((inst&`INST_SLL_MASK) == `INST_SLL)     ||
                ((inst&`INST_SRL_MASK) == `INST_SRL)     ||
                ((inst&`INST_SUB_MASK) == `INST_SUB)     ||
                ((inst&`INST_SRA_MASK) == `INST_SRA)     ||
                // Jump
                ((inst&`INST_JAL_MASK) == `INST_JAL)     ||
                ((inst&`INST_JALR_MASK) == `INST_JALR)   ;
                // FPU
                // TODO

wire is_lsu_w = ((inst&`INST_LB_MASK) == `INST_LB)   ||
                ((inst&`INST_LBU_MASK) == `INST_LBU) ||
                ((inst&`INST_LH_MASK) == `INST_LH)   ||
                ((inst&`INST_LHU_MASK) == `INST_LHU) ||
                ((inst&`INST_LW_MASK) == `INST_LW)   ||
                ((inst&`INST_SB_MASK) == `INST_SB)   ||
                ((inst&`INST_SH_MASK) == `INST_SH)   ||
                ((inst&`INST_SW_MASK) == `INST_SW)   ;
                // FPU
                // TODO

wire [2:0] csr_op_w = {3{is_csr_w}} & funct3;

reg [3:0] alu_ctrl_r;
reg [3:0] mem_ctrl_r;
reg [2:0] cmp_op_r;
reg [2:0] reg_w_sel_r;
always @(*) begin
    alu_ctrl_r = 4'b0000;
    mem_ctrl_r = 4'b0000;
    cmp_op_r   = 3'b000;
    
    // alu_ctrl
    if (is_alu_w | is_j_w | is_br_w) begin
        if      ((inst&`INST_ADD_MASK) == `INST_ADD)     alu_ctrl_r = `ALU_ADD;              // ADD
        else if ((inst&`INST_SUB_MASK) == `INST_SUB)     alu_ctrl_r = `ALU_SUB;              // SUB
        else if ((inst&`INST_AND_MASK) == `INST_AND)     alu_ctrl_r = `ALU_AND;              // AND
        else if ((inst&`INST_OR_MASK) == `INST_OR)       alu_ctrl_r = `ALU_OR;               // OR
        else if ((inst&`INST_XOR_MASK) == `INST_XOR)     alu_ctrl_r = `ALU_XOR;              // XOR
        else if ((inst&`INST_SLL_MASK) == `INST_SLL)     alu_ctrl_r = `ALU_SHIFTL;           // SLL
        else if ((inst&`INST_SRL_MASK) == `INST_SRL)     alu_ctrl_r = `ALU_SHIFTR;           // SRL
        else if ((inst&`INST_SRA_MASK) == `INST_SRA)     alu_ctrl_r = `ALU_SHIFTR_ARITH;     // SRA
        else if ((inst&`INST_SLT_MASK) == `INST_SLT)     alu_ctrl_r = `ALU_LESS_THAN_SIGNED; // SLT
        else if ((inst&`INST_SLTU_MASK) == `INST_SLTU)   alu_ctrl_r = `ALU_LESS_THAN;        // SLTU
        else if ((inst&`INST_SLTI_MASK) == `INST_SLTI)   alu_ctrl_r = `ALU_LESS_THAN_SIGNED; // SLTI
        else if ((inst&`INST_SLTIU_MASK) == `INST_SLTIU) alu_ctrl_r = `ALU_LESS_THAN;        // SLTIU
        else if ((inst&`INST_SLLI_MASK) == `INST_SLLI)   alu_ctrl_r = `ALU_SHIFTL;           // SLLI
        else if ((inst&`INST_SRLI_MASK) == `INST_SRLI)   alu_ctrl_r = `ALU_SHIFTR;           // SRLI
        else if ((inst&`INST_SRAI_MASK) == `INST_SRAI)   alu_ctrl_r = `ALU_SHIFTR_ARITH;     // SRAI
        else if ((inst&`INST_ANDI_MASK) == `INST_ANDI)   alu_ctrl_r = `ALU_AND;              // ANDI
        else if ((inst&`INST_ORI_MASK) == `INST_ORI)     alu_ctrl_r = `ALU_OR;               // ORI
        else if ((inst&`INST_XORI_MASK) == `INST_XORI)   alu_ctrl_r = `ALU_XOR;              // XORI
        else if ((inst&`INST_ADDI_MASK) == `INST_ADDI)   alu_ctrl_r = `ALU_ADD;              // ADDI
        else if ((inst&`INST_AUIPC_MASK) == `INST_AUIPC) alu_ctrl_r = `ALU_ADD;              // AUIPC
        else if ((inst&`INST_LUI_MASK) == `INST_LUI)     alu_ctrl_r = `ALU_NONE;             // LUI(PASS-B)
        else if(is_j_w | is_br_w)                        alu_ctrl_r = `ALU_ADD;              // B+J
        else                                             alu_ctrl_r = `ALU_NONE;             // NOP(PASS-B)
    end

    // mem_ctrl
    if (is_lsu_w) begin
        if      ((inst&`INST_LB_MASK) == `INST_LB)   mem_ctrl_r = 4'b1001; // LB
        else if ((inst&`INST_LBU_MASK) == `INST_LBU) mem_ctrl_r = 4'b1010; // LBU
        else if ((inst&`INST_LH_MASK) == `INST_LH)   mem_ctrl_r = 4'b1011; // LH
        else if ((inst&`INST_LHU_MASK) == `INST_LHU) mem_ctrl_r = 4'b1100; // LHU
        else if ((inst&`INST_LW_MASK) == `INST_LW)   mem_ctrl_r = 4'b1101; // LW
        else if ((inst&`INST_SB_MASK) == `INST_SB)   mem_ctrl_r = 4'b0001; // SB
        else if ((inst&`INST_SH_MASK) == `INST_SH)   mem_ctrl_r = 4'b0010; // SH
        else if ((inst&`INST_SW_MASK) == `INST_SW)   mem_ctrl_r = 4'b0100; // SW
        else mem_ctrl_r = 4'b0000;                                         // undefined
    end

    
    if (is_br_w) begin
        if      ((inst&`INST_BEQ_MASK) == `INST_BEQ)   cmp_op_r = 3'b000; // BEQ
        else if ((inst&`INST_BNE_MASK) == `INST_BNE)   cmp_op_r = 3'b001; // BNE
        else if ((inst&`INST_BLT_MASK) == `INST_BLT)   cmp_op_r = 3'b010; // BLT
        else if ((inst&`INST_BGE_MASK) == `INST_BGE)   cmp_op_r = 3'b011; // BGE
        else if ((inst&`INST_BLTU_MASK) == `INST_BLTU) cmp_op_r = 3'b100; // BLTU
        else if ((inst&`INST_BGEU_MASK) == `INST_BGEU) cmp_op_r = 3'b101; // BGEU
        else cmp_op_r = 3'b111;                                           // NONE
    end

    // 0: pc_p4, 1: ALU, 2: mem, 3:csr, 4: FPU
    if      ((inst&`INST_JALR_MASK) == `INST_JALR)   reg_w_sel_r = 0;
    else if ((inst&`INST_JAL_MASK) == `INST_JAL)     reg_w_sel_r = 0;
    else if ((inst&`INST_LUI_MASK) == `INST_LUI)     reg_w_sel_r = 1;
    else if ((inst&`INST_AUIPC_MASK) == `INST_AUIPC) reg_w_sel_r = 1;
    else if (is_alu_w)                               reg_w_sel_r = 1; // ALUout
    else if (is_lsu_w)                               reg_w_sel_r = 2; // memory
    else if (is_csr_w)                               reg_w_sel_r = 3; // CSR read data path
    else                                             reg_w_sel_r = 0; // default PC+4
end

endmodule
