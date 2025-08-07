module ForwardUnit (
    input wire [4:0] EX_rs1, // rs1 in EX stage
    input wire [4:0] EX_rs2, // rs2 in EX stage
    
    input wire [4:0] WB_rd,
    input wire       WB_reg_wr_en,

    output reg EX_fwd_sel1,
    output reg EX_fwd_sel2
);

always @(*) begin
    EX_fwd_sel1 = 1;
    if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs1))
        EX_fwd_sel1 = 0;  // fwd from WB to EX

    EX_fwd_sel2 = 1;
    if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs2))
        EX_fwd_sel2 = 0; // fwd from WB to EX

end

endmodule
