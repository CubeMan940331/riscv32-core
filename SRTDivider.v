module SRTDivider (
    input clk,
    input rst_n,
    input wire [31:0] remainder,
    input wire [31:0] divisor,

    input wire [2:0] MUL_DIV_ctrl,

    output wire [31:0] DIV_out
);

    // start
    wire unsign;
    wire rem;
    assign unsign = MUL_DIV_ctrl[0];
    assign rem = MUL_DIV_ctrl[1];

    wire remainder_sign;
    wire divisor_sign;
    assign remainder_sign = remainder[31];
    assign divisor_sign = divisor[31];

    wire [31:0] abs_remainder;
    wire [31:0] abs_divisor;
    assign abs_remainder = remainder_sign & (~unsign) ? -remainder : remainder;
    assign abs_divisor = divisor_sign & (~unsign) ? -divisor : divisor;

    // for normalize
    wire [65:0] r_o;
    wire [33:0] d_o;
    wire [4:0] shift_o;

    // processing
    reg [65:0] r_1 [15:0]; // sign + 65 bits 
    reg [65:0] r_2 [15:0];

    reg [31:0] pos_q [15:0];
    reg [31:0] neg_q [15:0];

    // end
    wire [31:0] quotient;
    wire [31:0] remain;

    wire [31:0] q;
    wire [65:0] r;

    assign q = pos_q[15] - neg_q[15];
    assign r = r_1[15] + r_2[15];

    wire [31:0] q_out;
    wire [33:0] r_out;

    assign q_out = r_pos_q_o[3] - r_neg_q_o[3];
    assign r_out = (r_r_1_o[3][65:32] + r_r_2_o[3][65:32]) >>> r_shift_o[3];

    assign quotient = (r_r_sign_o[3] ^ r_d_sign_o[3]) & (~r_unsign_o[3]) ? -q_out : q_out;
    assign remain = r_r_sign_o[3] & (~r_unsign_o[3]) ? -r_out[31:0] : r_out[31:0];

    assign DIV_out = r_rem_o[3] ? remain : quotient;

    // reg
    wire [33:0] r_d_o [3:0]; // 4
    wire [33:0] r_neg_d_o [3:0];
    wire [65:0] r_r_1_o [3:0];
    wire [65:0] r_r_2_o [3:0];
    wire [31:0] r_pos_q_o [3:0];
    wire [31:0] r_neg_q_o [3:0];
    wire [4:0] r_shift_o [3:0];
    wire r_r_sign_o [3:0];
    wire r_d_sign_o [3:0];
    wire r_unsign_o [3:0];
    wire r_rem_o [3:0];

    // stage EX0
    DivideLeftShift m_DivideLeftShift(
        .r(abs_remainder),
        .d(abs_divisor),
        .r_o(r_o),
        .d_o(d_o),
        .shift_o(shift_o)
    );

    QuotientSelect m_QuotientSelect_0(
        .r_1_i(r_o),
        .r_2_i(66'b0),
        .d(d_o),
        .neg_d(-d_o),
        .pos_q(32'b0),
        .neg_q(32'b0),
        .r_1_o(r_1[0]),
        .r_2_o(r_2[0]),
        .pos_q_o(pos_q[0]),
        .neg_q_o(neg_q[0])
    );

    QuotientSelect m_QuotientSelect_1(
        .r_1_i(r_1[0]),
        .r_2_i(r_2[0]),
        .d(d_o),
        .neg_d(-d_o),
        .pos_q(pos_q[0]),
        .neg_q(neg_q[0]),
        .r_1_o(r_1[1]),
        .r_2_o(r_2[1]),
        .pos_q_o(pos_q[1]),
        .neg_q_o(neg_q[1])
    );

    DIV_Reg m_DIV_0_Reg(
        .clk(clk),
        .rst_n(rst_n),
        .d_i(d_o),
        .neg_d_i(-d_o),
        .r_1_i(r_1[1]),
        .r_2_i(r_2[1]),
        .pos_q_i(pos_q[1]),
        .neg_q_i(neg_q[1]),
        .shift_i(shift_o),
        .r_sign_i(remainder_sign),
        .d_sign_i(divisor_sign),
        .unsign_i(unsign),
        .rem_i(rem),

        .d_o(r_d_o[0]),
        .neg_d_o(r_neg_d_o[0]),
        .r_1_o(r_r_1_o[0]),
        .r_2_o(r_r_2_o[0]),
        .pos_q_o(r_pos_q_o[0]),
        .neg_q_o(r_neg_q_o[0]),
        .shift_o(r_shift_o[0]),
        .r_sign_o(r_r_sign_o[0]),
        .d_sign_o(r_d_sign_o[0]),
        .unsign_o(r_unsign_o[0]),
        .rem_o(r_rem_o[0])
    );

    // stage EX1
    QuotientSelect m_QuotientSelect_2(
        .r_1_i(r_r_1_o[0]),
        .r_2_i(r_r_2_o[0]),
        .d(r_d_o[0]), // last reg
        .neg_d(r_neg_d_o[0]), // last reg
        .pos_q(r_pos_q_o[0]),
        .neg_q(r_neg_q_o[0]),
        .r_1_o(r_1[2]),
        .r_2_o(r_2[2]),
        .pos_q_o(pos_q[2]),
        .neg_q_o(neg_q[2])
    );

    genvar g_i;
    generate
        for (g_i = 3; g_i < 7; g_i = g_i + 1) begin: m_QuotientSelect_3_6 // 4
            QuotientSelect m_QuotientSelect(
                .r_1_i(r_1[g_i - 1]),
                .r_2_i(r_2[g_i - 1]),
                .d(r_d_o[0]), // last reg
                .neg_d(r_neg_d_o[0]), // last reg
                .pos_q(pos_q[g_i - 1]),
                .neg_q(neg_q[g_i - 1]),
                .r_1_o(r_1[g_i]),
                .r_2_o(r_2[g_i]),
                .pos_q_o(pos_q[g_i]),
                .neg_q_o(neg_q[g_i])
            );
        end
    endgenerate

    DIV_Reg m_DIV_1_Reg(
        .clk(clk),
        .rst_n(rst_n),
        .d_i(r_d_o[0]),
        .neg_d_i(r_neg_d_o[0]),
        .r_1_i(r_1[6]), // 2+5=7
        .r_2_i(r_2[6]),
        .pos_q_i(pos_q[6]),
        .neg_q_i(neg_q[6]),
        .shift_i(r_shift_o[0]),
        .r_sign_i(r_r_sign_o[0]),
        .d_sign_i(r_d_sign_o[0]),
        .unsign_i(r_unsign_o[0]),
        .rem_i(r_rem_o[0]),

        .d_o(r_d_o[1]),
        .neg_d_o(r_neg_d_o[1]),
        .r_1_o(r_r_1_o[1]),
        .r_2_o(r_r_2_o[1]),
        .pos_q_o(r_pos_q_o[1]),
        .neg_q_o(r_neg_q_o[1]),
        .shift_o(r_shift_o[1]),
        .r_sign_o(r_r_sign_o[1]),
        .d_sign_o(r_d_sign_o[1]),
        .unsign_o(r_unsign_o[1]),
        .rem_o(r_rem_o[1])
    );

    // stage EX2
    QuotientSelect m_QuotientSelect_7(
        .r_1_i(r_r_1_o[1]),
        .r_2_i(r_r_2_o[1]),
        .d(r_d_o[1]), // last reg
        .neg_d(r_neg_d_o[1]), // last reg
        .pos_q(r_pos_q_o[1]),
        .neg_q(r_neg_q_o[1]),
        .r_1_o(r_1[7]),
        .r_2_o(r_2[7]),
        .pos_q_o(pos_q[7]),
        .neg_q_o(neg_q[7])
    );

    generate
        for (g_i = 8; g_i < 12; g_i = g_i + 1) begin: m_QuotientSelect_8_11 // 4
            QuotientSelect m_QuotientSelect(
                .r_1_i(r_1[g_i - 1]),
                .r_2_i(r_2[g_i - 1]),
                .d(r_d_o[1]), // last reg
                .neg_d(r_neg_d_o[1]), // last reg
                .pos_q(pos_q[g_i - 1]),
                .neg_q(neg_q[g_i - 1]),
                .r_1_o(r_1[g_i]),
                .r_2_o(r_2[g_i]),
                .pos_q_o(pos_q[g_i]),
                .neg_q_o(neg_q[g_i])
            );
        end
    endgenerate

    DIV_Reg m_DIV_2_Reg(
        .clk(clk),
        .rst_n(rst_n),
        .d_i(r_d_o[1]),
        .neg_d_i(r_neg_d_o[1]),
        .r_1_i(r_1[11]), // 7+5=12
        .r_2_i(r_2[11]),
        .pos_q_i(pos_q[11]),
        .neg_q_i(neg_q[11]),
        .shift_i(r_shift_o[1]),
        .r_sign_i(r_r_sign_o[1]),
        .d_sign_i(r_d_sign_o[1]),
        .unsign_i(r_unsign_o[1]),
        .rem_i(r_rem_o[1]),

        .d_o(r_d_o[2]),
        .neg_d_o(r_neg_d_o[2]),
        .r_1_o(r_r_1_o[2]),
        .r_2_o(r_r_2_o[2]),
        .pos_q_o(r_pos_q_o[2]),
        .neg_q_o(r_neg_q_o[2]),
        .shift_o(r_shift_o[2]),
        .r_sign_o(r_r_sign_o[2]),
        .d_sign_o(r_d_sign_o[2]),
        .unsign_o(r_unsign_o[2]),
        .rem_o(r_rem_o[2])
    );

    // stage EX3
    QuotientSelect m_QuotientSelect_12(
        .r_1_i(r_r_1_o[2]),
        .r_2_i(r_r_2_o[2]),
        .d(r_d_o[2]), // last reg
        .neg_d(r_neg_d_o[2]), // last reg
        .pos_q(r_pos_q_o[2]),
        .neg_q(r_neg_q_o[2]),
        .r_1_o(r_1[12]),
        .r_2_o(r_2[12]),
        .pos_q_o(pos_q[12]),
        .neg_q_o(neg_q[12])
    );

    generate
        for (g_i = 13; g_i < 16; g_i = g_i + 1) begin: m_QuotientSelect_13_15 // 3
            QuotientSelect m_QuotientSelect(
                .r_1_i(r_1[g_i - 1]),
                .r_2_i(r_2[g_i - 1]),
                .d(r_d_o[2]), // last reg
                .neg_d(r_neg_d_o[2]), // last reg
                .pos_q(pos_q[g_i - 1]),
                .neg_q(neg_q[g_i - 1]),
                .r_1_o(r_1[g_i]), // final output 15
                .r_2_o(r_2[g_i]), // final output 15
                .pos_q_o(pos_q[g_i]), // final output 15
                .neg_q_o(neg_q[g_i]) // final output 15
            );
        end
    endgenerate

    DIV_Reg m_DIV_3_Reg(
        .clk(clk),
        .rst_n(rst_n),
        .d_i(r_d_o[2]),
        .neg_d_i(r_neg_d_o[2]),
        .r_1_i(r), // remainder 1&2 is added to know if the r is pos or neg 
        .r_2_i(r[65] ? {r_d_o[2], 32'b0} : 0), // if r is neg, restore 1 divisor
        .pos_q_i(pos_q[15]),
        .neg_q_i(r[65] ? {neg_q[15][31:2], |(neg_q[15][1:0]), ~neg_q[15][0]} : neg_q[15]), // if r is neg, restore quotient by -1
        .shift_i(r_shift_o[2]),
        .r_sign_i(r_r_sign_o[2]),
        .d_sign_i(r_d_sign_o[2]),
        .unsign_i(r_unsign_o[2]),
        .rem_i(r_rem_o[2]),

        .d_o(r_d_o[3]),
        .neg_d_o(r_neg_d_o[3]),
        .r_1_o(r_r_1_o[3]),
        .r_2_o(r_r_2_o[3]),
        .pos_q_o(r_pos_q_o[3]),
        .neg_q_o(r_neg_q_o[3]),
        .shift_o(r_shift_o[3]),
        .r_sign_o(r_r_sign_o[3]),
        .d_sign_o(r_d_sign_o[3]),
        .unsign_o(r_unsign_o[3]),
        .rem_o(r_rem_o[3])
    );

endmodule
