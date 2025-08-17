/* verilator lint_off UNUSEDSIGNAL */
`include "riscv_defs.v"
module CSR (
    input  [31:0]               inst,
    input                       inst_valid,
    input  [2:0]                csr_op_i,
    input                       is_csr_i,
    input                       is_csr_imm_i,
    input  [1:0]                cur_priv_i,
    input  [31:0]               imm_i,
    input  [31:0]               reg_rd_data1_i,     // reg value
    input  [31:0]               csr_old_i,          // read from CSR file
    input                       is_fpu_done_i,
    input  [4:0]                fpu_flags_i,

    output [31:0]               csr_rd_data_o,      // read data
    output                      csr_wr_valid_o,     // valid write
    output [31:0]               csr_wr_data_o,      // wb data
    output [`EXCEPTION_W-1:0]   csr_exception_o     // exception code
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
    ((csr_op_i == 3'b01) && (inst[19:15] != 5'b0))) || // write on RO
    (cur_priv_i < inst[29:28]) // illegal privilege level
);
always @(*) begin
    wdata = csr_old_i;
    if(is_fpu_done_i) begin 
        wdata = {27'b0, fpu_flags_i}; // FPU flags write-in
    end else begin
        case (csr_op_i[1:0])
            2'b01: begin          // CSRRW / CSRRWI
                wdata = (is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            2'b10: begin          // CSRRS / CSRRSI
                wdata = csr_old_i | (is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            2'b11: begin          // CSRRC / CSRRCI
                wdata = csr_old_i & ~(is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            default: begin
                wdata = csr_old_i;
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
        csr_rd_data_r = csr_old_i; // read from CSR file
    end

    // CSR time(e1) exception generation
    if ((inst & `INST_ECALL_MASK) == `INST_ECALL)
        csr_exception_r = `EXCEPTION_ECALL + {4'b0, cur_priv_i};
    else if ((inst & `INST_ERET_MASK) == `INST_ERET)
        csr_exception_r = `EXCEPTION_ERET_U + {4'b0, cur_priv_i};
    else if ((inst & `INST_EBREAK_MASK) == `INST_EBREAK)
        csr_exception_r = `EXCEPTION_BREAKPOINT;
    else if (is_fpu_done_i)
        csr_exception_r = `EXCEPTION_FPU;
    else if (!inst_valid || csr_fault_w)
        csr_exception_r = `EXCEPTION_ILLEGAL_INSTRUCTION;
        // Fence / MMU settings cause a pipeline flush TODO: SATP_update_w
    else if ((inst & `INST_IFENCE_MASK) == `INST_IFENCE)
        csr_exception_r = `EXCEPTION_FENCE;
    else
        csr_exception_r = `EXCEPTION_W'b0; // no exception
    
    // CSR write
    if(is_csr_i || is_fpu_done_i) begin
        csr_wr_data_r = wdata;
    end else begin
        csr_wr_data_r = 32'h0; // no write
    end
end

assign csr_wr_data_o    = csr_wr_data_r;
assign csr_exception_o  = csr_exception_r;
assign csr_wr_valid_o   = csr_wr_valid_r;
assign csr_rd_data_o    = csr_rd_data_r;

endmodule
