`include "riscv_defs.v"
/* verilator lint_off UNUSEDSIGNAL */
module Control (
    input [31:0] inst,

    output reg reg_wr_en,
    output reg [2:0] reg_w_sel, // 0: pc_p4, 1: ALU, 2: mem, 3: csr, 4: MUL, 5: DIV
    output reg mem_wr_en,
    output reg mem_rd_en,
    output reg [3:0] mem_ctrl,
    output reg is_j,
    output reg is_br,
    output reg ALU_sel1, // 0: PC, 1: rs1
    output reg ALU_sel2, // 0: rs2, 1: imm
    output reg [3:0] ALU_ctrl,
    output reg [2:0] cmp_op,
    output reg [2:0] MUL_DIV_ctrl,

    output reg trap_ecall,
    output reg trap_ebreak,
    output reg inst_mret,

    output reg is_csr,
    output reg [2:0] csr_op,
    output reg is_csr_imm, // is csr[r w]i
    output reg csr_wr_en,
    output reg csr_sel // rs1 or imm
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
    MUL_DIV_ctrl = 3'b000;

    is_csr=0;
    csr_op=0;
    is_csr_imm=0;
    csr_wr_en=0;
    csr_sel=0;
    trap_ebreak = 1'b0;
    inst_mret = 1'b0;
    trap_ecall = 1'b0;

    case (opcode)
        // R-Type (ADD SUB SLL SLT SLTU XOR SRL SRA OR AND MUL MULH MULHSU MULHU DIV DIVU REM REMU)
        7'b0110011: begin
            case(funct7)
                7'b0000001: begin
                    case(funct3)
                        3'b000:  MUL_DIV_ctrl = `MUL_LOWER; // MUL
                        3'b001:  MUL_DIV_ctrl = `MUL_HIGHER; // MULH
                        3'b010:  MUL_DIV_ctrl = `MUL_SIGNED_UNSIGNED; // MULHSU
                        3'b011:  MUL_DIV_ctrl = `MUL_UNSIGNED; // MULHU
                        3'b100:  MUL_DIV_ctrl = `DIV_SIGNED; // DIV
                        3'b101:  MUL_DIV_ctrl = `DIV_UNSIGNED; // DIVU
                        3'b110:  MUL_DIV_ctrl = `DIV_SIGNED_REM; // REM
                        3'b111:  MUL_DIV_ctrl = `DIV_UNSIGNED_REM; // REMU
                        default:; // PASS
                    endcase
                    reg_wr_en = 1'b1;
                    ALU_sel1   = 1'b1;  // R1
                    ALU_sel2  = 1'b0;  // R2
                    reg_w_sel  = funct3[2] ? 3'b101 : 3'b100; // DIV / MUL
                end
                default: begin
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
            endcase
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
            ALU_ctrl  = `ALU_ADD; // ADD
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
            ALU_ctrl  = `ALU_ADD; // ADD
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
            case(funct3)
                3'b000: begin
                    case (imm12)
                        12'h000: trap_ecall  = 1'b1;   // ECALL
                        12'h001: trap_ebreak = 1'b1;   // EBREAK
                        12'h302: inst_mret   = 1'b1;   // MRET
                        default:;
                    endcase
                end
                default: begin // ALL CSR
                    is_csr = 1'b1;
                    csr_op = funct3;
                    is_csr_imm = funct3[2];
                    csr_wr_en = (funct3 == 3'b001 || funct3 == 3'b011 || funct3 == 3'b101);
                    
                    reg_wr_en = 1'b1;
                    reg_w_sel  = 3'b011; // CSR read data path
                    csr_sel  = is_csr_imm;
                end
            endcase
        end

        default:;
    endcase
end

endmodule
