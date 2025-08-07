`include "riscv_defs.v"
/* verilator lint_off UNUSEDSIGNAL */
module Control (
    input [31:0] inst,

    output reg reg_wr_en,
    output reg [2:0] reg_w_sel, // 0: pc_p4, 1: ALU, 2: mem, 3:csr, 4: FPU
    output reg mem_wr_en,
    output reg mem_rd_en,
    output reg [3:0] mem_ctrl,
    output reg is_j,
    output reg is_br,
    output reg ALU_sel1, // 0: PC, 1: rs1
    output reg ALU_sel2, // 0: rs2, 1: imm
    output reg [3:0] ALU_ctrl,
    output reg [2:0] cmp_op,

    output reg is_csr,
    output reg [2:0] csr_op,
    output reg is_csr_imm, // is csr[r w]i
    output reg csr_sel, // rs1 or imm

    output reg is_impl
);

// decode
wire [6:0] opcode = inst[6:0];
wire [2:0] funct3 = inst[14:12];
wire [6:0] funct7 = inst[31:25];
wire [11:0] imm12 = inst[31:20];

always @(*) begin
    reg_wr_en = 1'b0;
    reg_w_sel = 3'b000;
    mem_wr_en = 1'b0;
    mem_rd_en = 1'b0;
    mem_ctrl = 4'b0000;
    is_j = 1'b0;
    is_br = 1'b0;
    ALU_sel1 = 1'b0;
    ALU_sel2 = 1'b0;
    ALU_ctrl = `ALU_NONE;
    cmp_op = 3'b000;

    is_csr=0;
    csr_op=0;
    is_csr_imm=0;
    csr_sel=0;

    case (opcode)
        // R-Type (ADD SUB SLL SLT SLTU XOR SRL SRA OR AND)
        7'b0110011: begin
            case(funct3)
                3'b000:  ALU_ctrl = (funct7[5]) ? `ALU_SUB : `ALU_ADD; // SUB : ADD
                3'b001:  ALU_ctrl = `ALU_SHIFTL; // SLL
                3'b010:  ALU_ctrl = `ALU_LESS_THAN_SIGNED; // SLT
                3'b011:  ALU_ctrl = `ALU_LESS_THAN; // SLTU
                3'b100:  ALU_ctrl = `ALU_XOR; // XOR
                3'b101:  ALU_ctrl = (funct7[5]) ? `ALU_SHIFTR_ARITH : `ALU_SHIFTR; // SRA : SRL
                3'b110:  ALU_ctrl = `ALU_OR; // OR
                3'b111:  ALU_ctrl = `ALU_AND; // AND
                default: ALU_ctrl = `ALU_NONE; // PASS
            endcase
            reg_wr_en = 1'b1;
            ALU_sel1   = 1'b1;  // R1
            ALU_sel2  = 1'b0;  // R2
            reg_w_sel  = 3'b001; // ALUout
        end

        // I-Type (ADDI SLLI SLTI SLTIU XORI SRLI SRAI ORI ANDI)
        7'b0010011: begin
            case(funct3)
                3'b000:  ALU_ctrl = `ALU_ADD; // ADDI
                3'b001:  ALU_ctrl = `ALU_SHIFTL; // SLLI
                3'b010:  ALU_ctrl = `ALU_LESS_THAN_SIGNED; // SLTI
                3'b011:  ALU_ctrl = `ALU_LESS_THAN; // SLTIU
                3'b100:  ALU_ctrl = `ALU_XOR; // XORI
                3'b101:  ALU_ctrl = (funct7[5]) ? `ALU_SHIFTR_ARITH : `ALU_SHIFTR; // SRAI : SRLI
                3'b110:  ALU_ctrl = `ALU_OR; // ORI
                3'b111:  ALU_ctrl = `ALU_AND; // ANDI
                default: ALU_ctrl = `ALU_NONE; // PASS
            endcase
            reg_wr_en = 1'b1;
            ALU_sel1   = 1'b1;  // R1
            ALU_sel2  = 1'b1; // immediate
            reg_w_sel  = 3'b001; // ALUout
        end

        // Load-Type (LB LH LW LBU LHU)
        7'b0000011: begin
            case(funct3)
                3'b000:  mem_ctrl = 4'b1001; // LB
                3'b001:  mem_ctrl = 4'b1010; // LH
                3'b010:  mem_ctrl = 4'b0100; // LW
                3'b100:  mem_ctrl = 4'b0001; // LBU
                3'b101:  mem_ctrl = 4'b0010; // LHU
                default: mem_ctrl = 4'b0000; // undefined
            endcase
            // ALU_ctrl  = `ALU_ADD; // ADD // don't use ALU
            reg_wr_en = 1'b1;
            ALU_sel1   = 1'b1;  // R1
            ALU_sel2  = 1'b1;  // immediate
            mem_rd_en  = 1'b1;
            reg_w_sel  = 3'b010; // memory
        end

        // S-Type (SB SH SW)
        7'b0100011: begin
            case(funct3)
                3'b000:  mem_ctrl = 4'b0001; // SB
                3'b001:  mem_ctrl = 4'b0010; // SH
                3'b010:  mem_ctrl = 4'b0100; // SW
                default: mem_ctrl = 4'b0000; // undefined
            endcase
            // ALU_ctrl  = `ALU_ADD; // ADD // don't use ALU
            ALU_sel1   = 1'b1;     // R1
            ALU_sel2   = 1'b1;    // immediate
            mem_wr_en  = 1'b1;
        end

        // B-Type (BEQ BNE BLT BGE BLTU BGEU)
        7'b1100011: begin
            case(funct3)
                3'b000:  cmp_op = 3'b000; // BEQ
                3'b001:  cmp_op = 3'b001; // BNE
                3'b100:  cmp_op = 3'b010; // BLT
                3'b101:  cmp_op = 3'b011; // BGE
                3'b110:  cmp_op = 3'b100; // BLTU
                3'b111:  cmp_op = 3'b101; // BGEU
                default: cmp_op = 3'b111; // undefined
            endcase
            ALU_ctrl  = `ALU_ADD; // ADD
            ALU_sel1   = 1'b0;     // PC
            ALU_sel2  = 1'b1;     // immediate
            is_br = 1'b1;
        end

        // JAL
        7'b1101111: begin
            ALU_ctrl  = `ALU_ADD; // ADD
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b000;    // PC+4
            ALU_sel1   = 1'b0;     // PC
            ALU_sel2  = 1'b1;     // immediate
            is_j   = 1'b1;
        end

        // JALR
        7'b1100111: begin
            ALU_ctrl  = `ALU_ADD; // ADD
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b000;    // PC+4
            is_j   = 1'b1;
            ALU_sel1   = 1'b1;     // R1
            ALU_sel2  = 1'b1;     // immediate
        end

        // AUIPC
        7'b0010111: begin
            ALU_ctrl  = `ALU_ADD; // ADD
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b001;    // ALUout
            ALU_sel1   = 1'b0;     // PC
            ALU_sel2  = 1'b1;     // immediate
        end

        // LUI
        7'b0110111: begin
            ALU_ctrl  = `ALU_NONE; // PASS B
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b001;      // ALUout
            ALU_sel2  = 1'b1;       // imm
        end
        // CSR-Type (ECALL EBREAK MRET URET* SRET* CSRRW CSRRS CSRRC CSRRWI CSRRSI CSRRCI)
        7'b1110011: begin
            is_csr = 1'b1;
            csr_op = funct3;
            is_csr_imm = funct3[2];
            
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b011; // CSR read data path
            csr_sel  = is_csr_imm;
        end
        // FPU
        // R4-Type (fmadd fmsub fnmsub fnmadd)
        7'b1000011, // fmadd
        7'b1000111, // fmsub
        7'b1001011, // fnmsub
        7'b1001111: begin // fnmadd
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b100; // FPU out
        end
        // R-Type both (fadd fsub fmul fdiv fsqrt fsgnj fsgnjn fsgnjx fmin fmax feq flt fle fclass)
        // R-Type RVF only (fcvt.w.s fcvt.wu.s fcvt.s.w fcvt.s.wu fmv.x.w fmv.w.x)
        // R-Type RVD only (fcvt.w.d fcvt.wu.d fcvt.d.w fcvt.d.wu fcvt.s.d fcvt.d.s)
        7'b1010011: begin
            reg_wr_en = 1'b1;
            reg_w_sel  = 3'b100; // FPU out
        end
        // I-Type (flw fld)
        7'b0000111: begin
            reg_wr_en = 1'b1;
            mem_rd_en = 1'b1;
            reg_w_sel = 3'b100; // FPU out
        end
        // S-Type (fsw fsd)
        7'b0100111: begin
            mem_wr_en = 1'b1;
        end
        default:;
    endcase
end

always @(*) begin
    is_impl = 0;
    // orginized according to the risc-v manual
// Unprivileged
// 2 RV32I Base Integer Instruction Set
// 2.4 Integer Computational Instructions
// 2.4.1 Integer Register-Immediate Instructions
    if     ((inst&`INST_ADDI_MASK) == `INST_ADDI) begin
        is_impl = 1;
    end
    else if((inst&`INST_SLTI_MASK) == `INST_SLTI) begin
        is_impl = 1;
    end
    else if((inst&`INST_SLTIU_MASK) == `INST_SLTIU) begin
        is_impl = 1;
    end
    else if((inst&`INST_ANDI_MASK) == `INST_ANDI) begin
        is_impl = 1;
    end
    else if((inst&`INST_ORI_MASK) == `INST_ORI) begin
        is_impl = 1;
    end
    else if((inst&`INST_XORI_MASK) == `INST_XORI) begin
        is_impl = 1;
    end
    else if((inst&`INST_SLLI_MASK) == `INST_SLLI) begin
        is_impl = 1;
    end
    else if((inst&`INST_SRLI_MASK) == `INST_SRLI) begin
        is_impl = 1;
    end
    else if((inst&`INST_SRAI_MASK) == `INST_SRAI) begin
        is_impl = 1;
    end
    else if((inst&`INST_LUI_MASK) == `INST_LUI) begin
        is_impl = 1;
    end
    else if((inst&`INST_AUIPC_MASK) == `INST_AUIPC) begin
       is_impl = 1; 
    end
// 2.4.2 Integer Register-Register Operations
    else if((inst&`INST_ADD_MASK) == `INST_ADD) begin
        is_impl = 1;
    end
    else if((inst&`INST_SLT_MASK) == `INST_SLT) begin
        is_impl = 1;
    end
    else if((inst&`INST_SLTU_MASK) == `INST_SLTU) begin
        is_impl = 1;
    end
    else if((inst&`INST_AND_MASK) == `INST_AND) begin
        is_impl = 1;
    end
    else if((inst&`INST_OR_MASK) == `INST_OR) begin
        is_impl = 1;
    end
    else if((inst&`INST_XOR_MASK) == `INST_XOR) begin
        is_impl = 1;
    end
    else if((inst&`INST_SLL_MASK) == `INST_SLL) begin
        is_impl = 1;
    end
    else if((inst&`INST_SRL_MASK) == `INST_SRL) begin
        is_impl = 1;
    end
    else if((inst&`INST_SUB_MASK) == `INST_SUB) begin
        is_impl = 1;
    end
    else if((inst&`INST_SRA_MASK) == `INST_SRA) begin
        is_impl = 1;
    end
// 2.4.3 NOP
    // addi x0,x0,0
// 2.5 Control Transfer INstructions
// 2.5.1 Unconditional Jumps
    else if((inst&`INST_JAL_MASK) == `INST_JAL) begin
        is_impl = 1;
    end
    else if((inst&`INST_JALR_MASK) == `INST_JALR) begin
        is_impl = 1;
    end
// 2.5.2 Conditional Branches
    else if((inst&`INST_BEQ_MASK) == `INST_BEQ) begin
        is_impl = 1;
    end
    else if((inst&`INST_BNE_MASK) == `INST_BNE) begin
        is_impl = 1;
    end
    else if((inst&`INST_BLT_MASK) == `INST_BLT) begin
        is_impl = 1; 
    end
    else if((inst&`INST_BLTU_MASK) == `INST_BLTU) begin
        is_impl = 1;
    end
    else if((inst&`INST_BGE_MASK) == `INST_BGE) begin
        is_impl = 1;
    end
    else if((inst&`INST_BGEU_MASK) == `INST_BGEU) begin
        is_impl = 1;
    end
// 2.6 Load and Store Instructions
    else if((inst&`INST_LB_MASK) == `INST_LB) begin
        is_impl = 1;
    end
    else if((inst&`INST_LBU_MASK) == `INST_LBU) begin
        is_impl = 1;
    end
    else if((inst&`INST_LH_MASK) == `INST_LH) begin
        is_impl = 1;
    end
    else if((inst&`INST_LHU_MASK) == `INST_LHU) begin
        is_impl = 1;
    end
    else if((inst&`INST_LW_MASK) == `INST_LW) begin
        is_impl = 1;
    end
    else if((inst&`INST_SB_MASK) == `INST_SB) begin
        is_impl = 1;
    end
    else if((inst&`INST_SH_MASK) == `INST_SH) begin
        is_impl = 1;
    end
    else if((inst&`INST_SW_MASK) == `INST_SW) begin
        is_impl = 1;
    end
// 2.7 Memory Ordering Instructions
    // Ignored for now
// 2.8 Environment Call and Breakpoints
    else if((inst&`INST_ECALL_MASK) == `INST_ECALL) begin
        is_impl = 1; // skip this for now
    end
    else if((inst&`INST_EBREAK_MASK) == `INST_EBREAK) begin
        is_impl = 0; // skip this for now
    end
// 2.9 HINT Instructions
    // Ignored
    
// 5 Zifencei Extension
    // Ignored for now
    
// 6 Zicsr
    else if((inst&`INST_CSRRW_MASK) == `INST_CSRRW) begin
        is_impl = 1; //skip this for now
    end
    else if((inst&`INST_CSRRS_MASK) == `INST_CSRRS) begin
        is_impl = 1; //skip this for now
    end
    else if((inst&`INST_CSRRC_MASK) == `INST_CSRRC) begin
        is_impl = 1; // skip this for now
    end
    else if((inst&`INST_CSRRWI_MASK) == `INST_CSRRWI) begin
        is_impl = 1; // skip this for now
    end
    else if((inst&`INST_CSRRSI_MASK) == `INST_CSRRSI) begin
        is_impl = 1; // skip this for now
    end
    else if((inst&`INST_CSRRCI_MASK) == `INST_CSRRCI) begin
        is_impl = 1; // skip this for now
    end

// 12 M Extension

end

endmodule
