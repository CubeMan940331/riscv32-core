module HazardUnit(
    input  wire        EX_mem_rd_en,
    input  wire [4:0]  EX_rd,
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
        EX_mem_rd_en && 
        EX_rd != 5'd0 &&
        (EX_rd == ID_rs1 || EX_rd == ID_rs2)
    ) stall = 3;
end

endmodule
