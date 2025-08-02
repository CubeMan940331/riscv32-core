module DIV_Reg (
    input wire clk,
    input wire rst_n,
    input wire [33:0] d_i,
    input wire [33:0] neg_d_i,
    input wire [65:0] r_1_i,
    input wire [65:0] r_2_i,
    input wire [31:0] pos_q_i,
    input wire [31:0] neg_q_i,
    input wire [4:0] shift_i,
    input wire r_sign_i, 
    input wire d_sign_i,
    input wire unsign_i,
    input wire rem_i,

    output wire [33:0] d_o,
    output wire [33:0] neg_d_o,
    output wire [65:0] r_1_o,
    output wire [65:0] r_2_o,
    output wire [31:0] pos_q_o,
    output wire [31:0] neg_q_o,
    output wire [4:0] shift_o,
    output wire r_sign_o, 
    output wire d_sign_o,
    output wire unsign_o,
    output wire rem_o
);

    reg [33:0] d_r, neg_d_r;
    reg [65:0] r_1_r, r_2_r;
    reg [31:0] pos_q_r, neg_q_r;
    reg [4:0] shift_r;
    reg r_sign_r, d_sign_r, unsign_r, rem_r;

    assign d_o = d_r;
    assign neg_d_o = neg_d_r;
    assign r_1_o = r_1_r;
    assign r_2_o = r_2_r;
    assign pos_q_o = pos_q_r;
    assign neg_q_o = neg_q_r;
    assign shift_o = shift_r;
    assign r_sign_o = r_sign_r;
    assign d_sign_o = d_sign_r;
    assign unsign_o = unsign_r;
    assign rem_o = rem_r;

    always @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            d_r <= 0;
            neg_d_r <= 0;
            r_1_r <= 0;
            r_2_r <= 0;
            pos_q_r <= 0;
            neg_q_r <= 0;
            shift_r <= 0;
            r_sign_r <= 0;
            d_sign_r <= 0;
            unsign_r <= 0;
            rem_r <= 0;
        end else begin
            d_r <= d_i;
            neg_d_r <= neg_d_i;
            r_1_r <= r_1_i;
            r_2_r <= r_2_i;
            pos_q_r <= pos_q_i;
            neg_q_r <= neg_q_i;
            shift_r <= shift_i;
            r_sign_r <= r_sign_i;
            d_sign_r <= d_sign_i;
            unsign_r <= unsign_i;
            rem_r <= rem_i;
        end
    end

endmodule
