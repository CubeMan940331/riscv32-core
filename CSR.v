module CSR (
    input  [2:0]  csr_op_i,
    input         is_csr_imm_i,
    input  [31:0] imm_i,
    input  [31:0] reg_rd_data1_i,  // reg value
    input  [31:0] csr_old_i,       // read from CSR file

    output [31:0] csr_wdata_o     // wb data
);
    reg  [31:0] wdata;
    always @(*) begin
        wdata = csr_old_i;

        case (csr_op_i)
            3'b01: begin          // CSRRW / CSRRWI
                wdata = (is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            3'b10: begin          // CSRRS / CSRRSI
                wdata = csr_old_i | (is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            3'b11: begin          // CSRRC / CSRRCI
                wdata = csr_old_i & ~(is_csr_imm_i ? imm_i : reg_rd_data1_i);
            end
            default: begin
                wdata = csr_old_i;
            end
        endcase
    end

    assign csr_wdata_o = wdata;

endmodule
