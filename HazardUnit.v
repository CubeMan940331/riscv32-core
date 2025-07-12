module HazardUnit(
    input  wire        EX_mem_rd_en,
    input  wire [4:0]  EX_rd,
    input  wire [4:0]  ID_rs1,
    input  wire [4:0]  ID_rs2,

    output reg         pc_en,
    output reg         ID_en,
    output reg         EX_clear
);

always @(*) begin

    pc_en = 1'b1;
    ID_en = 1'b1;
    EX_clear = 1'b0;

    if(
        EX_mem_rd_en && 
        EX_rd != 5'd0 &&
        (EX_rd == ID_rs1 || EX_rd == ID_rs2)
    ) begin
        // insert nop in EX stage
        pc_en = 1'b0;
        ID_en = 1'b0;
        EX_clear = 1'b1;
    end
end

endmodule
