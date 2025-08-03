module ForwardUnit (
    input wire [4:0] EX_rs1, // rs1 in EX stage
    input wire [4:0] EX_rs2, // rs2 in EX stage

    input wire [4:0] EX1_rd, // rd in EX sub stages
    input wire [4:0] EX2_rd,
    input wire [4:0] EX3_rd,

    input wire       EX1_reg_wr_en,
    input wire       EX2_reg_wr_en,
    input wire       EX3_reg_wr_en,

    input wire [2:0] EX1_reg_w_sel,
    input wire [2:0] EX2_reg_w_sel,
    input wire [2:0] EX3_reg_w_sel,

    input wire [4:0] MEM_rd, // rd in MEM stage
    input wire       MEM_reg_wr_en,
    input wire [2:0] MEM_reg_w_sel,
    
    input wire [4:0] WB_rd,
    input wire       WB_reg_wr_en,

    output reg [1:0] EX_fwd_stg_sel1,
    output reg [1:0] EX_fwd_stg_sel2,

    output reg [1:0] EX_fwd_sel1,
    output reg [1:0] EX_fwd_sel2
);

// EX_fwd_sel 0: WB, 1: reg data from ID, 2: reg data from EX_Sub/MEM, 3: csr from EX_Sub/MEM
// EX_fwd_stg_sel 0: EX1, 1: EX2, 2: EX3, 3: MEM  

always @(*) begin
    EX_fwd_stg_sel1 = 2'b00;
    EX_fwd_sel1 = 2'b01;
    if (EX1_reg_wr_en && (EX1_rd != 5'd0) && (EX1_rd == EX_rs1))begin // EX1
        EX_fwd_stg_sel1 = 2'b00; // fwd from stage EX1
        if(EX1_reg_w_sel == 3'b001) // ALU result
            EX_fwd_sel1 = 2'b10; // fwd from EX1 to EX
        else if (EX1_reg_w_sel == 3'b011) // CSR result
            EX_fwd_sel1 = 2'b11; // fwd from EX1 CSR to EX
    end else if (EX2_reg_wr_en && (EX2_rd != 5'd0) && (EX2_rd == EX_rs1))begin // EX2
        EX_fwd_stg_sel1 = 2'b01; // fwd from stage EX2
        if(EX2_reg_w_sel == 3'b001)
            EX_fwd_sel1 = 2'b10;
        else if (EX2_reg_w_sel == 3'b011)
            EX_fwd_sel1 = 2'b11;
    end else if (EX3_reg_wr_en && (EX3_rd != 5'd0) && (EX3_rd == EX_rs1))begin // EX3
        EX_fwd_stg_sel1 = 2'b10; // fwd from stage EX3
        if(EX3_reg_w_sel == 3'b001)
            EX_fwd_sel1 = 2'b10;
        else if (EX3_reg_w_sel == 3'b011)
            EX_fwd_sel1 = 2'b11;
    end else if (MEM_reg_wr_en && (MEM_rd != 5'd0) && (MEM_rd == EX_rs1))begin // MEM
        EX_fwd_stg_sel1 = 2'b11; // fwd from stage MEM
        if(MEM_reg_w_sel == 3'b001) // ALU result
            EX_fwd_sel1 = 2'b10; // fwd from MEM to EX
        else if (MEM_reg_w_sel == 3'b011) // CSR result
            EX_fwd_sel1 = 2'b11; // fwd from MEM CSR to EX
    end else if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs1)) // WB
        EX_fwd_sel1 = 2'b00;  // fwd from WB to EX

    EX_fwd_stg_sel2 = 2'b00;
    EX_fwd_sel2 = 2'b01;
    if (EX1_reg_wr_en && (EX1_rd != 5'd0) && (EX1_rd == EX_rs2))begin // EX1
        EX_fwd_stg_sel2 = 2'b00; // fwd from stage EX1
        if(EX1_reg_w_sel == 3'b001) // ALU result
            EX_fwd_sel2 = 2'b10; // fwd from EX1 to EX
        else if (EX1_reg_w_sel == 3'b011) // CSR result
            EX_fwd_sel2 = 2'b11; // fwd from EX1 CSR to EX
    end else if (EX2_reg_wr_en && (EX2_rd != 5'd0) && (EX2_rd == EX_rs2))begin // EX2
        EX_fwd_stg_sel2 = 2'b01; // fwd from stage EX2
        if(EX2_reg_w_sel == 3'b001)
            EX_fwd_sel2 = 2'b10;
        else if (EX2_reg_w_sel == 3'b011)
            EX_fwd_sel2 = 2'b11;
    end else if (EX3_reg_wr_en && (EX3_rd != 5'd0) && (EX3_rd == EX_rs2))begin // EX3
        EX_fwd_stg_sel2 = 2'b10; // fwd from stage EX3
        if(EX3_reg_w_sel == 3'b001)
            EX_fwd_sel2 = 2'b10;
        else if (EX3_reg_w_sel == 3'b011)
            EX_fwd_sel2 = 2'b11;
    end else if (MEM_reg_wr_en && (MEM_rd != 5'd0) && (MEM_rd == EX_rs2))begin // MEM
        EX_fwd_stg_sel2 = 2'b11; // fwd from stage MEM
        if(MEM_reg_w_sel == 3'b001) // ALU result
            EX_fwd_sel2 = 2'b10; // fwd from MEM to EX
        else if (MEM_reg_w_sel == 3'b011) // CSR result
            EX_fwd_sel2 = 2'b11; // fwd from MEM CSR to EX
    end else if (WB_reg_wr_en && (WB_rd != 5'd0) && (WB_rd == EX_rs2)) // WB
        EX_fwd_sel2 = 2'b00;  // fwd from WB to EX

end

endmodule
