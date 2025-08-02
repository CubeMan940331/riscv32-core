module MUL_Reg #(
    parameter SIZE = 16
)
(
    input wire clk,
    input wire rst_n,
    input wire [63:0] partial_i [SIZE-1:0],
    input wire [1:0] sign_i,
    input wire higher_i,

    output wire [63:0] partial_o [SIZE-1:0],
    output wire [1:0] sign_o,
    output wire higher_o
);
    integer i;

    reg [63:0] partial_r [SIZE-1:0];
    reg [1:0] sign_r;
    reg higher_r;

    genvar g_i;
    generate
        for (g_i = 0; g_i < SIZE; g_i = g_i + 1) assign partial_o[g_i] = partial_r[g_i];
    endgenerate

    assign sign_o = sign_r;
    assign higher_o = higher_r;

    always @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            for (i = 0; i < SIZE; i = i + 1) partial_r[i] <= 0;
            sign_r <= 0;
            higher_r <= 0;
        end else begin
            for (i = 0; i < SIZE; i = i + 1) partial_r[i] <= partial_i[i];
            sign_r <= sign_i;
            higher_r <= higher_i;
        end
    end

endmodule
