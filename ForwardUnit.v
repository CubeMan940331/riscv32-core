module ForwardUnit (
    input wire [4:0] EX_rs1,
    input wire [4:0] EX_rs2,
    input wire [4:0] EX_rs3,
    input wire [4:0] WB_rd,
    input wire       WB_reg_wr_en,
    input wire       WB_freg_wr_en,

    output reg EX_fwd_sel1,
    output reg EX_fwd_sel2,
    output reg EX_freg_fwd_sel1,
    output reg EX_freg_fwd_sel2,
    output reg EX_freg_fwd_sel3
);

always @(*) begin
    // Register
    // RS1
    EX_fwd_sel1 = 1;
    if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs1))
        EX_fwd_sel1 = 0;
    // RS2
    EX_fwd_sel2 = 1;
    if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs2))
        EX_fwd_sel2 = 0;

    // FRegister
    // RS1
    EX_freg_fwd_sel1 = 1;
    if (WB_freg_wr_en && (WB_rd == EX_rs1))
        EX_freg_fwd_sel1 = 0;
    // RS2
    EX_freg_fwd_sel2 = 1;
    if (WB_freg_wr_en && (WB_rd == EX_rs2))
        EX_freg_fwd_sel2 = 0;
    // RS3
    EX_freg_fwd_sel3 = 1;
    if (WB_freg_wr_en && (WB_rd == EX_rs3))
        EX_freg_fwd_sel3 = 0;
end

endmodule
