module FRegister #(parameter FLEN = 32)(
    input clk,
    input rst_n,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rs3,

    input wr_en,
    input [4:0] rd,
    input [FLEN-1:0] data_i,         // 32-bit for RVF/D
    
    output [FLEN-1:0] rd_data1_o,
    output [FLEN-1:0] rd_data2_o,
    output [FLEN-1:0] rd_data3_o
);
    reg [FLEN-1:0] fregs [0:31];     // Floating-point registers f0..f31

    assign rd_data1_o = fregs[rs1];
    assign rd_data2_o = fregs[rs2];
    assign rd_data3_o = fregs[rs3];

    always @(negedge clk, negedge rst_n) begin
        if (~rst_n) begin
            fregs[0]  <= 0;  fregs[1]  <= 0;       fregs[2]  <= 0;  fregs[3]  <= 0;
            fregs[4]  <= 0;  fregs[5]  <= 0;       fregs[6]  <= 0;  fregs[7]  <= 0;
            fregs[8]  <= 0;  fregs[9]  <= 0;       fregs[10] <= 0;  fregs[11] <= 0;
            fregs[12] <= 0;  fregs[13] <= 0;       fregs[14] <= 0;  fregs[15] <= 0;
            fregs[16] <= 0;  fregs[17] <= 0;       fregs[18] <= 0;  fregs[19] <= 0;
            fregs[20] <= 0;  fregs[21] <= 0;       fregs[22] <= 0;  fregs[23] <= 0;
            fregs[24] <= 0;  fregs[25] <= 0;       fregs[26] <= 0;  fregs[27] <= 0;
            fregs[28] <= 0;  fregs[29] <= 0;       fregs[30] <= 0;  fregs[31] <= 0;
        end
        else if (wr_en) begin
            fregs[rd] <= data_i;
        end
    end

endmodule
