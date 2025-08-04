module HazardUnit(
    input  wire        EX_reg_wr_en,
    input  wire        EX1_reg_wr_en,
    input  wire        EX2_reg_wr_en,
    input  wire        EX3_reg_wr_en,

    input  wire [2:0]  EX_reg_w_sel,
    input  wire [2:0]  EX1_reg_w_sel,
    input  wire [2:0]  EX2_reg_w_sel,
    input  wire [2:0]  EX3_reg_w_sel,

    input  wire [4:0]  EX_rd,
    input  wire [4:0]  EX1_rd,
    input  wire [4:0]  EX2_rd,
    input  wire [4:0]  EX3_rd,
    
    input  wire [4:0]  ID_rs1,
    input  wire [4:0]  ID_rs2,
    
    output reg [3:0]   stall
);

/*
stall
0: not stall
1: stall for IF
2: stall for ID
3: stall for EX
4: stall for MEM
5: stall for WB

only stall for EX for now
*/

always @(*) begin

    stall = 0;
    
    if(
        EX_reg_wr_en && 
        (EX_reg_w_sel == 3'b010 || EX_reg_w_sel == 3'b100 || EX_reg_w_sel == 3'b101) && // mem / mul / div
        EX_rd != 5'd0 &&
        (EX_rd == ID_rs1 || EX_rd == ID_rs2)
    ) stall = 3;
    else if(
        EX1_reg_wr_en && 
        (EX1_reg_w_sel == 3'b010 || EX1_reg_w_sel == 3'b100 || EX1_reg_w_sel == 3'b101) && // mem / mul / div
        EX1_rd != 5'd0 &&
        (EX1_rd == ID_rs1 || EX1_rd == ID_rs2)
    ) stall = 3;
    else if(
        EX2_reg_wr_en && 
        (EX2_reg_w_sel == 3'b010 || EX2_reg_w_sel == 3'b100 || EX2_reg_w_sel == 3'b101) && // mem / mul / div
        EX2_rd != 5'd0 &&
        (EX2_rd == ID_rs1 || EX2_rd == ID_rs2)
    ) stall = 3;
    else if(
        EX3_reg_wr_en && 
        (EX3_reg_w_sel == 3'b010 || EX3_reg_w_sel == 3'b100 || EX3_reg_w_sel == 3'b101) && // mem / mul / div
        EX3_rd != 5'd0 &&
        (EX3_rd == ID_rs1 || EX3_rd == ID_rs2)
    ) stall = 3;
end

endmodule
