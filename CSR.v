/* verilator lint_off UNUSEDSIGNAL */
`include "riscv_defs.v"
module CSR (
    input                       clk,
    input                       rst_n,
    input  [31:0]               inst,
    input                       inst_valid,
    input  [2:0]                csr_op_i,
    input                       is_csr_i,
    input                       is_csr_imm_i,
    input  [4:0]                rs1_i,             // CSR rs1
    input  [31:0]               imm_i,
    input  [31:0]               reg_rd_data1_i,     // reg value

    input                       is_fpu_done_i,
    input  [4:0]                fpu_flags_i,
    input                       is_f_ext_i,
    input  [11:0]               csr_wr_addr_i,

    input  [31:0]               exception_pc_i,
    input  [11:0]               csr_rd_addr_i,

    output                      csr_branch_o,
    output [31:0]               csr_target_o,
    output [31:0]               interrupt_o,
    output [`EXCEPTION_W-1:0]   csr_exception_o,

    output [31:0]               csr_rd_data_o,       // read data

    output [31:0]               csr_satp_o

    // memory interface
    ,input  [31:0] d_mem_addr_i
    ,input         d_mem_wr_en_i
    ,input         d_mem_rd_en_i
);

//-----------------------------------------------------------------
// CSR File
//-----------------------------------------------------------------
wire [31:0] csr_mstatus;
wire [31:0] csr_rd_data_old;          // read from CSR file
wire [1:0]  csr_priv;

CSRFile m_CSRFile(
    .clk(clk),
    .rst_n(rst_n),
    .cpu_id_i(0),
    .misa_i(`MISA_RV32 | `MISA_RVU | `MISA_RVI | `MISA_RVM | `MISA_RVF),
    .exception_i(csr_exception_r),
    .exception_pc_i(exception_pc_i),
    .exception_addr_i(0),

    .csr_rd_addr_i(csr_rd_addr_i),
    .csr_rd_data_o(csr_rd_data_old),

    .csr_wr_en_i(csr_wr_valid_r),
    .csr_wr_addr_i(csr_rd_addr_i),
    .csr_wr_data_i(csr_wr_data_r),

    .csr_branch_o(csr_branch_o),
    .csr_target_o(csr_target_o),

    .priv_o(csr_priv),
    .mstatus_o(csr_mstatus),
    .interrupt_o(interrupt_o),
    .satp_o(csr_satp_o)
    
    ,.d_mem_addr_i(d_mem_addr_i)
    ,.d_mem_rd_en_i(d_mem_rd_en_i)
    ,.d_mem_wr_en_i(d_mem_wr_en_i)
);

//-----------------------------------------------------------------
// CSR handling
//-----------------------------------------------------------------
reg                     csr_wr_valid_r;
reg [31:0]              csr_rd_data_r;
reg [31:0]              csr_wr_data_r;
reg [`EXCEPTION_W-1:0]  csr_exception_r;
reg [31:0]              wdata;
wire csr_fault_w = is_csr_i && inst_valid &&( // CSR op is valid
    ((inst[31:30] == 2'd3) && 
    ((csr_op_i == 3'b01) || ((csr_op_i == 3'b11) && ((is_csr_imm_i && (imm_i !=0)) || !is_csr_imm_i && (rs1_i != 0))))) || // RO but write/clear
    ((csr_wr_addr_i == `CSR_FFLAGS || csr_wr_addr_i == `CSR_FRM || csr_wr_addr_i == `CSR_FCSR) && csr_mstatus[`SR_FS_R] == `SR_FS_OFF) || // read/write FPU CSRs when FPU off
    (csr_priv < inst[29:28]) // illegal privilege level
);
always @(*) begin
    wdata = csr_rd_data_old;
    if(is_fpu_done_i) begin 
        wdata = {27'b0, fpu_flags_i}; // FPU flags write-in
    end else begin
        case (csr_op_i[1:0])
            2'b01: begin          // CSRRW / CSRRWI
                wdata = (is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            2'b10: begin          // CSRRS / CSRRSI
                wdata = csr_rd_data_old | (is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            2'b11: begin          // CSRRC / CSRRCI
                wdata = csr_rd_data_old & ~(is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            default: begin
                wdata = csr_rd_data_old;
            end
        endcase
    end
end

//-----------------------------------------------------------------
// CSR Read Write / CSR exceptions generation
//-----------------------------------------------------------------
always @(*) begin
    // CSR read
    csr_wr_valid_r = !csr_fault_w && (inst[19:15] != 5'b0); // no fault and not RO
    if(!inst_valid || csr_fault_w) begin
        csr_rd_data_r = inst; // record for xtval?
    end else begin
        csr_rd_data_r = csr_rd_data_old; // read from CSR file
    end

    // CSR time(e1) exception generation
    if ((inst & `INST_ECALL_MASK) == `INST_ECALL)
        csr_exception_r = `EXCEPTION_ECALL + {4'b0, csr_priv};
    else if ((inst & `INST_ERET_MASK) == `INST_ERET)
        csr_exception_r = `EXCEPTION_ERET_U + {4'b0, csr_priv};
    else if ((inst & `INST_EBREAK_MASK) == `INST_EBREAK)
        csr_exception_r = `EXCEPTION_BREAKPOINT;
    else if (csr_mstatus[`SR_FS_R] == `SR_FS_OFF && is_f_ext_i)
        csr_exception_r = `EXCEPTION_ILLEGAL_INSTRUCTION;
    else if (is_fpu_done_i && csr_mstatus[`SR_FS_R] != `SR_FS_OFF)
        csr_exception_r = `EXCEPTION_FPU;
    else if ((inst & `INST_IFENCE_MASK) == `INST_IFENCE)
        csr_exception_r = `EXCEPTION_FENCE;
    else if (!inst_valid || csr_fault_w)
        csr_exception_r = `EXCEPTION_ILLEGAL_INSTRUCTION;
        // Fence / MMU settings cause a pipeline flush TODO: SATP_update_w
    else
        csr_exception_r = `EXCEPTION_W'b0; // no exception
    
    // CSR write
    if(is_csr_i || is_fpu_done_i) begin
        csr_wr_data_r = wdata;
    end else begin
        csr_wr_data_r = 32'h0; // no write
    end
end

assign csr_rd_data_o    = csr_rd_data_r;
assign csr_exception_o  = csr_exception_r;

endmodule
