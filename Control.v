`include "riscv_defs.v"
module Control (
    input [31:0] inst,
    // WB stage
    output reg_wr_en_o,
    output freg_wr_en_o,
    output [2:0] reg_w_sel_o, // 0: pc_p4, 1: ALU, 2: mem, 3:csr, 4: FPU, 5: bypass, 6: MUL_DIV_top
    
    // LSU
    output mem_wr_en_o,
    output mem_rd_en_o,
    output [3:0] mem_ctrl_o,
    
    // Branch
    output is_j_o,
    output is_br_o,
    output [2:0] cmp_op_o,
    
    // ALU
    output [3:0] ALU_ctrl_o,
    output ALU_sel1_o, // 0: PC, 1: rs1
    output ALU_sel2_o, // 0: rs2, 1: imm

    // MUL/DIV
    output is_MUL_DIV_o,
    output [2:0] MUL_DIV_ctrl_o,

    // CSR
    output is_csr_o,
    output [2:0] csr_op_o,
    output is_csr_imm_o, // is csr[r w]i

    // FPU
    output is_fpu_o,
    output FPU_sel1_o, // 0: fs1, 1: rs1
    output is_f_ext_o,

    // Bypass
    output [1:0] bypass_sel_o,

    // Fence
    output fetch_invalid_o,

    output is_impl_o
);

// declare
wire [2:0] funct3 = inst[14:12];
reg  [3:0] alu_ctrl_r;
reg  [3:0] mem_ctrl_r;
reg  [2:0] cmp_op_r;
reg  [2:0] reg_w_sel_r;
reg  [1:0] bypass_sel_r;

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
                // M-Ext
                ((inst&`INST_MUL_MASK) == `INST_MUL)        ||
                ((inst&`INST_MULH_MASK) == `INST_MULH)      ||
                ((inst&`INST_MULHSU_MASK) == `INST_MULHSU)  ||
                ((inst&`INST_MULHU_MASK) == `INST_MULHU)    ||
                ((inst&`INST_DIV_MASK) == `INST_DIV)        ||
                ((inst&`INST_DIVU_MASK) == `INST_DIVU)      ||
                ((inst&`INST_REM_MASK) == `INST_REM)        ||
                ((inst&`INST_REMU_MASK) == `INST_REMU)      ||
                // Zicsr
                ((inst&`INST_CSRRW_MASK) == `INST_CSRRW)   ||
                ((inst&`INST_CSRRS_MASK) == `INST_CSRRS)   ||
                ((inst&`INST_CSRRC_MASK) == `INST_CSRRC)   ||
                ((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI) ||
                ((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI) ||
                ((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI) ||
                ((inst&`INST_ECALL_MASK) == `INST_ECALL)   ||
                ((inst&`INST_MRET_MASK) == `INST_MRET)     ||
                // Zifencei
                ((inst&`INST_IFENCE_MASK) == `INST_IFENCE) ||
                // fence
                ((inst&`INST_FENCE_MASK) == `INST_FENCE) ||
                // Wfi
                ((inst&`INST_WFI_MASK) == `INST_WFI)       ||
                // RVF
                ((inst&`INST_FMADD_MASK) == `INST_FMADD)         ||
                ((inst&`INST_FMSUB_MASK) == `INST_FMSUB)         ||
                ((inst&`INST_FNMSUB_MASK) == `INST_FNMSUB)       ||
                ((inst&`INST_FNMADD_MASK) == `INST_FNMADD)       ||
                ((inst&`INST_FADD_MASK) == `INST_FADD)           ||
                ((inst&`INST_FSUB_MASK) == `INST_FSUB)           ||
                ((inst&`INST_FMUL_MASK) == `INST_FMUL)           ||
                ((inst&`INST_FDIV_MASK) == `INST_FDIV)           ||
                ((inst&`INST_FSQRT_MASK) == `INST_FSQRT)         ||
                ((inst&`INST_FSGNJ_MASK) == `INST_FSGNJ)         ||
                ((inst&`INST_FSGNJN_MASK) == `INST_FSGNJN)       ||
                ((inst&`INST_FSGNJX_MASK) == `INST_FSGNJX)       ||
                ((inst&`INST_FMIN_MASK) == `INST_FMIN)           ||
                ((inst&`INST_FMAX_MASK) == `INST_FMAX)           ||
                ((inst&`INST_FEQ_MASK) == `INST_FEQ)             ||
                ((inst&`INST_FLT_MASK) == `INST_FLT)             ||
                ((inst&`INST_FLE_MASK) == `INST_FLE)             ||
                ((inst&`INST_FCLASS_MASK) == `INST_FCLASS)       ||
                ((inst&`INST_FLW_MASK) == `INST_FLW)             ||
                ((inst&`INST_FSW_MASK) == `INST_FSW)             ||
                ((inst&`INST_FCVT_W_S_MASK) == `INST_FCVT_W_S)   ||
                ((inst&`INST_FCVT_WU_S_MASK) == `INST_FCVT_WU_S) ||
                ((inst&`INST_FCVT_S_W_MASK) == `INST_FCVT_S_W)   ||
                ((inst&`INST_FCVT_S_WU_MASK) == `INST_FCVT_S_WU) ||
                ((inst&`INST_FMV_W_X_MASK) == `INST_FMV_W_X)     ||
                ((inst&`INST_FMV_X_W_MASK) == `INST_FMV_X_W)     ;

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
                    // M-Ext
                    ((inst&`INST_MUL_MASK) == `INST_MUL)        ||
                    ((inst&`INST_MULH_MASK) == `INST_MULH)      ||
                    ((inst&`INST_MULHSU_MASK) == `INST_MULHSU)  ||
                    ((inst&`INST_MULHU_MASK) == `INST_MULHU)    ||
                    ((inst&`INST_DIV_MASK) == `INST_DIV)        ||
                    ((inst&`INST_DIVU_MASK) == `INST_DIVU)      ||
                    ((inst&`INST_REM_MASK) == `INST_REM)        ||
                    ((inst&`INST_REMU_MASK) == `INST_REMU)      ||
                    // CSR
                    ((inst&`INST_CSRRW_MASK) == `INST_CSRRW)   ||
                    ((inst&`INST_CSRRS_MASK) == `INST_CSRRS)   ||
                    ((inst&`INST_CSRRC_MASK) == `INST_CSRRC)   ||
                    ((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI) ||
                    ((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI) ||
                    ((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI) ||
                    // RVF/D
                    ((inst&`INST_FEQ_MASK) == `INST_FEQ)             ||
                    ((inst&`INST_FLT_MASK) == `INST_FLT)             ||
                    ((inst&`INST_FLE_MASK) == `INST_FLE)             ||
                    ((inst&`INST_FCLASS_MASK) == `INST_FCLASS)       ||
                    ((inst&`INST_FCVT_W_S_MASK) == `INST_FCVT_W_S)   ||
                    ((inst&`INST_FCVT_WU_S_MASK) == `INST_FCVT_WU_S) ||
                    ((inst&`INST_FMV_X_W_MASK) == `INST_FMV_X_W)     ;

wire mem_rd_en_w = ((inst&`INST_LB_MASK) == `INST_LB)    ||
                    ((inst&`INST_LBU_MASK) == `INST_LBU) ||
                    ((inst&`INST_LH_MASK) == `INST_LH)   ||
                    ((inst&`INST_LHU_MASK) == `INST_LHU) ||
                    ((inst&`INST_LW_MASK) == `INST_LW)   ||
                    // FPU
                    ((inst&`INST_FLW_MASK) == `INST_FLW) ||
                    ((inst&`INST_FLD_MASK) == `INST_FLD);
                    
wire mem_wr_en_w = ((inst&`INST_SB_MASK) == `INST_SB)   ||
                   ((inst&`INST_SH_MASK) == `INST_SH)   ||
                   ((inst&`INST_SW_MASK) == `INST_SW)   ||
                   // FPU
                   ((inst&`INST_FSW_MASK) == `INST_FSW) ||
                   ((inst&`INST_FSD_MASK) == `INST_FSD);

wire is_j_w = ((inst&`INST_JAL_MASK) == `INST_JAL)  ||
              ((inst&`INST_JALR_MASK) == `INST_JALR);

wire is_br_w = ((inst&`INST_BEQ_MASK) == `INST_BEQ)   ||
               ((inst&`INST_BNE_MASK) == `INST_BNE)   ||
               ((inst&`INST_BLT_MASK) == `INST_BLT)   ||
               ((inst&`INST_BGE_MASK) == `INST_BGE)   ||
               ((inst&`INST_BLTU_MASK) == `INST_BLTU) ||
               ((inst&`INST_BGEU_MASK) == `INST_BGEU) ;

wire is_MUL_DIV_w = ((inst&`INST_MUL_MASK) == `INST_MUL)        ||
                    ((inst&`INST_MULH_MASK) == `INST_MULH)      ||
                    ((inst&`INST_MULHSU_MASK) == `INST_MULHSU)  ||
                    ((inst&`INST_MULHU_MASK) == `INST_MULHU)    ||
                    ((inst&`INST_DIV_MASK) == `INST_DIV)        ||
                    ((inst&`INST_DIVU_MASK) == `INST_DIVU)      ||
                    ((inst&`INST_REM_MASK) == `INST_REM)        ||
                    ((inst&`INST_REMU_MASK) == `INST_REMU)      ;

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

wire is_lsu_w = ((inst&`INST_LB_MASK) == `INST_LB)   ||
                ((inst&`INST_LBU_MASK) == `INST_LBU) ||
                ((inst&`INST_LH_MASK) == `INST_LH)   ||
                ((inst&`INST_LHU_MASK) == `INST_LHU) ||
                ((inst&`INST_LW_MASK) == `INST_LW)   ||
                ((inst&`INST_SB_MASK) == `INST_SB)   ||
                ((inst&`INST_SH_MASK) == `INST_SH)   ||
                ((inst&`INST_SW_MASK) == `INST_SW)   ||
                // F Extension
                ((inst&`INST_FLW_MASK) == `INST_FLW)  ||
                ((inst&`INST_FSW_MASK) == `INST_FSW);

wire freg_wr_en_w = ((inst&`INST_FMADD_MASK) == `INST_FMADD)         ||
                    ((inst&`INST_FMSUB_MASK) == `INST_FMSUB)         ||
                    ((inst&`INST_FNMSUB_MASK) == `INST_FNMSUB)       ||
                    ((inst&`INST_FNMADD_MASK) == `INST_FNMADD)       ||
                    ((inst&`INST_FADD_MASK) == `INST_FADD)           ||
                    ((inst&`INST_FSUB_MASK) == `INST_FSUB)           ||
                    ((inst&`INST_FMUL_MASK) == `INST_FMUL)           ||
                    ((inst&`INST_FDIV_MASK) == `INST_FDIV)           ||
                    ((inst&`INST_FSQRT_MASK) == `INST_FSQRT)         ||
                    ((inst&`INST_FSGNJ_MASK) == `INST_FSGNJ)         ||
                    ((inst&`INST_FSGNJN_MASK) == `INST_FSGNJN)       ||
                    ((inst&`INST_FSGNJX_MASK) == `INST_FSGNJX)       ||
                    ((inst&`INST_FMIN_MASK) == `INST_FMIN)           ||
                    ((inst&`INST_FMAX_MASK) == `INST_FMAX)           ||
                    ((inst&`INST_FLW_MASK) == `INST_FLW)             ||
                    ((inst&`INST_FCVT_S_W_MASK) == `INST_FCVT_S_W)   ||
                    ((inst&`INST_FCVT_S_WU_MASK) == `INST_FCVT_S_WU) ||
                    ((inst&`INST_FMV_W_X_MASK) == `INST_FMV_W_X)     ||
                    ((inst&`INST_FLD_MASK) == `INST_FLD)             ||
                    ((inst&`INST_FCVT_D_W_MASK) == `INST_FCVT_D_W)   ||
                    ((inst&`INST_FCVT_D_WU_MASK) == `INST_FCVT_D_WU) ||
                    ((inst&`INST_FCVT_S_D_MASK) == `INST_FCVT_S_D)   ||
                    ((inst&`INST_FCVT_D_S_MASK) == `INST_FCVT_D_S)   ;

wire is_fpu_w = ((inst&`INST_FMADD_MASK) == `INST_FMADD)         ||
                ((inst&`INST_FMSUB_MASK) == `INST_FMSUB)         ||
                ((inst&`INST_FNMSUB_MASK) == `INST_FNMSUB)       ||
                ((inst&`INST_FNMADD_MASK) == `INST_FNMADD)       ||
                ((inst&`INST_FADD_MASK) == `INST_FADD)           ||
                ((inst&`INST_FSUB_MASK) == `INST_FSUB)           ||
                ((inst&`INST_FMUL_MASK) == `INST_FMUL)           ||
                ((inst&`INST_FDIV_MASK) == `INST_FDIV)           ||
                ((inst&`INST_FSQRT_MASK) == `INST_FSQRT)         ||
                ((inst&`INST_FSGNJ_MASK) == `INST_FSGNJ)         ||
                ((inst&`INST_FSGNJN_MASK) == `INST_FSGNJN)       ||
                ((inst&`INST_FSGNJX_MASK) == `INST_FSGNJX)       ||
                ((inst&`INST_FMIN_MASK) == `INST_FMIN)           ||
                ((inst&`INST_FMAX_MASK) == `INST_FMAX)           ||
                ((inst&`INST_FEQ_MASK) == `INST_FEQ)             ||
                ((inst&`INST_FLT_MASK) == `INST_FLT)             ||
                ((inst&`INST_FLE_MASK) == `INST_FLE)             ||
                ((inst&`INST_FCLASS_MASK) == `INST_FCLASS)       ||
                ((inst&`INST_FCVT_W_S_MASK) == `INST_FCVT_W_S)   ||
                ((inst&`INST_FCVT_WU_S_MASK) == `INST_FCVT_WU_S) ||
                ((inst&`INST_FCVT_S_W_MASK) == `INST_FCVT_S_W)   ||
                ((inst&`INST_FCVT_S_WU_MASK) == `INST_FCVT_S_WU) ||
                ((inst&`INST_FCVT_W_D_MASK) == `INST_FCVT_W_D)   ||
                ((inst&`INST_FCVT_WU_D_MASK) == `INST_FCVT_WU_D) ||
                ((inst&`INST_FCVT_D_W_MASK) == `INST_FCVT_D_W)   ||
                ((inst&`INST_FCVT_D_WU_MASK) == `INST_FCVT_D_WU) ||
                ((inst&`INST_FCVT_S_D_MASK) == `INST_FCVT_S_D)   ||
                ((inst&`INST_FCVT_D_S_MASK) == `INST_FCVT_D_S)   ;

wire FPU_sel1_w = ((inst&`INST_FCVT_S_W_MASK) == `INST_FCVT_S_W)   ||
                  ((inst&`INST_FCVT_S_WU_MASK) == `INST_FCVT_S_WU) ;

wire fetch_invalid_w = ((inst&`INST_FENCE_MASK) == `INST_FENCE)   ||
                       ((inst&`INST_IFENCE_MASK) == `INST_IFENCE) ||
                       ((inst&`INST_SFENCE_MASK) == `INST_SFENCE) ;

wire is_f_ext_w = ((inst&`INST_FMADD_MASK) == `INST_FMADD)         ||
                  ((inst&`INST_FMSUB_MASK) == `INST_FMSUB)         ||
                  ((inst&`INST_FNMSUB_MASK) == `INST_FNMSUB)       ||
                  ((inst&`INST_FNMADD_MASK) == `INST_FNMADD)       ||
                  ((inst&`INST_FADD_MASK) == `INST_FADD)           ||
                  ((inst&`INST_FSUB_MASK) == `INST_FSUB)           ||
                  ((inst&`INST_FMUL_MASK) == `INST_FMUL)           ||
                  ((inst&`INST_FDIV_MASK) == `INST_FDIV)           ||
                  ((inst&`INST_FSQRT_MASK) == `INST_FSQRT)         ||
                  ((inst&`INST_FSGNJ_MASK) == `INST_FSGNJ)         ||
                  ((inst&`INST_FSGNJN_MASK) == `INST_FSGNJN)       ||
                  ((inst&`INST_FSGNJX_MASK) == `INST_FSGNJX)       ||
                  ((inst&`INST_FMIN_MASK) == `INST_FMIN)           ||
                  ((inst&`INST_FMAX_MASK) == `INST_FMAX)           ||
                  ((inst&`INST_FEQ_MASK) == `INST_FEQ)             ||
                  ((inst&`INST_FLT_MASK) == `INST_FLT)             ||
                  ((inst&`INST_FLE_MASK) == `INST_FLE)             ||
                  ((inst&`INST_FCLASS_MASK) == `INST_FCLASS)       ||
                  ((inst&`INST_FLW_MASK) == `INST_FLW)             ||
                  ((inst&`INST_FSW_MASK) == `INST_FSW)             ||
                  ((inst&`INST_FCVT_W_S_MASK) == `INST_FCVT_W_S)   ||
                  ((inst&`INST_FCVT_WU_S_MASK) == `INST_FCVT_WU_S) ||
                  ((inst&`INST_FCVT_S_W_MASK) == `INST_FCVT_S_W)   ||
                  ((inst&`INST_FCVT_S_WU_MASK) == `INST_FCVT_S_WU) ||
                  ((inst&`INST_FMV_X_W_MASK) == `INST_FMV_X_W)     ||
                  ((inst&`INST_FMV_W_X_MASK) == `INST_FMV_W_X)     ||
                  // double
                  ((inst&`INST_FCVT_W_D_MASK) == `INST_FCVT_W_D)   ||
                  ((inst&`INST_FCVT_WU_D_MASK) == `INST_FCVT_WU_D) ||
                  ((inst&`INST_FCVT_D_W_MASK) == `INST_FCVT_D_W)   ||
                  ((inst&`INST_FCVT_D_WU_MASK) == `INST_FCVT_D_WU) ||
                  ((inst&`INST_FCVT_S_D_MASK) == `INST_FCVT_S_D)   ||
                  ((inst&`INST_FCVT_D_S_MASK) == `INST_FCVT_D_S)   ;

wire [2:0] MUL_DIV_ctrl_w = {3{is_MUL_DIV_w}} & funct3;

wire [2:0] csr_op_w = {3{is_csr_w}} & funct3;

assign is_impl_o = is_impl_w;
assign reg_wr_en_o = reg_wr_en_w;
assign mem_wr_en_o = mem_wr_en_w;
assign mem_rd_en_o = mem_rd_en_w;
assign mem_ctrl_o = mem_ctrl_r;
assign is_j_o = is_j_w;
assign is_br_o = is_br_w;
assign ALU_ctrl_o = alu_ctrl_r;
assign is_MUL_DIV_o = is_MUL_DIV_w;
assign MUL_DIV_ctrl_o = MUL_DIV_ctrl_w;
assign cmp_op_o = cmp_op_r;
assign is_csr_o = is_csr_w;
assign csr_op_o = csr_op_w;
assign is_csr_imm_o = is_csr_imm_w;
assign ALU_sel1_o = alu_sel1_w;
assign ALU_sel2_o = alu_sel2_w;
assign reg_w_sel_o = reg_w_sel_r;
assign is_fpu_o = is_fpu_w;
assign FPU_sel1_o = FPU_sel1_w;
assign freg_wr_en_o = freg_wr_en_w;
assign is_f_ext_o = is_f_ext_w;
assign bypass_sel_o = bypass_sel_r;
assign fetch_invalid_o = fetch_invalid_w;

always @(*) begin
    alu_ctrl_r   = 4'b0000;
    mem_ctrl_r   = 4'b0000;
    cmp_op_r     = 3'b000;
    bypass_sel_r = 2'b00;
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
        else if ((inst&`INST_LUI_MASK) == `INST_LUI)     alu_ctrl_r = `ALU_NONE;             // NOP
        else if(is_j_w | is_br_w)                        alu_ctrl_r = `ALU_ADD;              // B+J
        else                                             alu_ctrl_r = `ALU_NONE;             // NOP
    end

    // mem_ctrl
    if (is_lsu_w) begin
        if      ((inst&`INST_LB_MASK) == `INST_LB)   mem_ctrl_r = 4'b1001; // LB
        else if ((inst&`INST_LBU_MASK) == `INST_LBU) mem_ctrl_r = 4'b0001; // LBU

        else if ((inst&`INST_LH_MASK) == `INST_LH)   mem_ctrl_r = 4'b1010; // LH
        else if ((inst&`INST_LHU_MASK) == `INST_LHU) mem_ctrl_r = 4'b0010; // LHU

        else if ((inst&`INST_LW_MASK) == `INST_LW)   mem_ctrl_r = 4'b0100; // LW
        
        else if ((inst&`INST_SB_MASK) == `INST_SB)   mem_ctrl_r = 4'b0001; // SB
        else if ((inst&`INST_SH_MASK) == `INST_SH)   mem_ctrl_r = 4'b0010; // SH
        else if ((inst&`INST_SW_MASK) == `INST_SW)   mem_ctrl_r = 4'b0100; // SW

        else if ((inst&`INST_FLW_MASK) == `INST_FLW) mem_ctrl_r = 4'b0100; // FLW
        else if ((inst&`INST_FSW_MASK) == `INST_FSW) mem_ctrl_r = 4'b1100; // FSW
        else mem_ctrl_r = 4'b0000;                                         // undefined
    end

    // cmp_op
    if (is_br_w) begin
        if      ((inst&`INST_BEQ_MASK) == `INST_BEQ)   cmp_op_r = 3'b000; // BEQ
        else if ((inst&`INST_BNE_MASK) == `INST_BNE)   cmp_op_r = 3'b001; // BNE
        else if ((inst&`INST_BLT_MASK) == `INST_BLT)   cmp_op_r = 3'b010; // BLT
        else if ((inst&`INST_BGE_MASK) == `INST_BGE)   cmp_op_r = 3'b011; // BGE
        else if ((inst&`INST_BLTU_MASK) == `INST_BLTU) cmp_op_r = 3'b100; // BLTU
        else if ((inst&`INST_BGEU_MASK) == `INST_BGEU) cmp_op_r = 3'b101; // BGEU
        else                                           cmp_op_r = 3'b111; // NONE
    end

    // bypass_sel
    if      ((inst&`INST_LUI_MASK) == `INST_LUI)         bypass_sel_r = 1;
    else if ((inst&`INST_FMV_W_X_MASK) == `INST_FMV_W_X) bypass_sel_r = 2;
    else if ((inst&`INST_FMV_X_W_MASK) == `INST_FMV_X_W) bypass_sel_r = 3;
    // impl as nop, but still need something to start
    else if ((inst&`INST_FENCE_MASK) == `INST_FENCE)     bypass_sel_r = 1;
    else                                                 bypass_sel_r = 0;

    // 0: pc_p4, 1: ALU, 2: mem, 3:csr, 4: FPU, 5: bypass
    // reg_w_sel
    if      (is_j_w)                                 reg_w_sel_r = 0;
    else if (|bypass_sel_r)                          reg_w_sel_r = 5; // bypass
    else if (is_alu_w)                               reg_w_sel_r = 1; // ALUout
    else if (is_lsu_w)                               reg_w_sel_r = 2; // memory
    else if (is_csr_w)                               reg_w_sel_r = 3; // CSR read data path
    else if (is_fpu_w)                               reg_w_sel_r = 4; // FPU result
    else if (is_MUL_DIV_w)                           reg_w_sel_r = 6;
    else                                             reg_w_sel_r = 0; // default PC+4
end

endmodule
