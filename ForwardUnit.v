module ForwardUnit (
    input wire [4:0] EX_rs1, // rs1 in EX stage
    input wire [4:0] EX_rs2, // rs2 in EX stage

    input wire [4:0] MEM_rd, // rd in MEM stage
    input wire       MEM_reg_wr_en,
    input wire [2:0] MEM_reg_w_sel,
    
    input wire [4:0] WB_rd,
    input wire       WB_reg_wr_en,

    output reg [1:0] EX_fwd_sel1,
    output reg [1:0] EX_fwd_sel2
);

always @(*) begin
    EX_fwd_sel1 = 2'b01;
    if (MEM_reg_wr_en && (MEM_rd != 5'd0) && (MEM_rd == EX_rs1))begin
        if(MEM_reg_w_sel == 3'b001) // ALU result
            EX_fwd_sel1 = 2'b10; // fwd from MEM to EX
        else if (MEM_reg_w_sel == 3'b011) // CSR result
            EX_fwd_sel1 = 2'b11; // fwd from MEM CSR to EX
    end else if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs1))
        EX_fwd_sel1 = 2'b00;  // fwd from WB to EX

    EX_fwd_sel2 = 2'b01;
    if (MEM_reg_wr_en && (MEM_rd != 5'd0) && (MEM_rd == EX_rs2))begin
        if(MEM_reg_w_sel == 3'b001) // ALU result
            EX_fwd_sel2 = 2'b10; // fwd from MEM to EX
        else if (MEM_reg_w_sel == 3'b011) // CSR result
            EX_fwd_sel2 = 2'b11; // fwd from MEM CSR to EX
    end else if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs2))
        EX_fwd_sel2 = 2'b00; // fwd from WB to EX

end

endmodule
