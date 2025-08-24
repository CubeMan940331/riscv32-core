module WallaceMultiplier (
    input clk,
    input rst_n,
    input start,
    input wire [31:0] multiplicand, 
    input wire [31:0] multiplier,

    input wire [2:0] MUL_DIV_ctrl,

    output wire [31:0] MUL_out,
    output wire MUL_done
);
        
    //start
    wire higher;
    wire [1:0] sign;
    assign higher = ~(MUL_DIV_ctrl == 3'b000);
    assign sign = MUL_DIV_ctrl[1:0];

    //EX0
    wire [63:0] partial_0_temp [2:0];
    wire [63:0] partial_0 [15:0];
    wire [33:0] booth [16:0];

    //EX0
    wire [63:0] partial_1 [7:0];

    //EX1
    wire [63:0] partial_2 [3:0];

    //EX1
    wire [63:0] partial_3 [1:0];

    //reg
    wire [((64 * 8) - 1):0] partial_1_flat;
    wire [((64 * 2) - 1):0] partial_3_flat;
    wire [((64 * 8) - 1):0] partial_1_flat_o;
    wire [((64 * 2) - 1):0] partial_3_flat_o;

    wire [63:0] partial_1_o [7:0];
    wire [63:0] partial_3_o [1:0];
    wire [1:0] r_sign_o [1:0];
    wire r_higher_o [1:0];
    wire r_start_o [1:0];

    //result
    wire [63:0] partial_sum;
    assign partial_sum = partial_3_o[0] + partial_3_o[1];
    assign MUL_out = r_higher_o[1] ? partial_sum[63:32] : partial_sum[31:0];
    assign MUL_done = r_start_o[1];

    Booth4Decode m_booth_decoder_0 (
        .multiplicand(multiplicand), // ALU A
        .code({multiplier[1:0], 1'b0}), // ALU B
        .unsign(&sign[1:0]),
        .booth_out(booth[0])
    );
    assign partial_0[0] = {{30{booth[0][33]}}, booth[0]}; // append 30 + (sign + 33 bits) = 64 bits

    genvar g_i;
    generate
        for (g_i = 1; g_i < 14; g_i = g_i + 1) begin: m_booth_decoders_1_13
            Booth4Decode m_booth_decoder (
                .multiplicand(multiplicand), // ALU A
                .code(multiplier[(2 * g_i) + 1: (2 * g_i) - 1]), // ALU B
                .unsign(&sign[1:0]),
                .booth_out(booth[g_i])
            );

            assign partial_0[g_i] = {{(30 - (g_i * 2)){booth[g_i][33]}}, {booth[g_i]}, {(g_i * 2){1'b0}}};
        end
        for (g_i = 14; g_i < 16; g_i = g_i + 1) begin: m_booth_decoders_14_15
            Booth4Decode m_booth_decoder (
                .multiplicand(multiplicand), // ALU A
                .code(multiplier[(2 * g_i) + 1: (2 * g_i) - 1]), // ALU B
                .unsign(&sign[1:0]),
                .booth_out(booth[g_i])
            );

            assign partial_0_temp[g_i - 14] = {{(30 - (g_i * 2)){booth[g_i][33]}}, {booth[g_i]}, {(g_i * 2){1'b0}}};
        end
    endgenerate

    Booth4Decode m_booth_decoder_16 (
        .multiplicand(multiplicand), // ALU A
        .code({{2{~sign[1] & multiplier[31]}}, multiplier[31]}), // mulhsu / mulhu ? append 0 to multiplier : append sign bit
        .unsign(&sign[1:0]),
        .booth_out(booth[16])
    );
    assign partial_0_temp[2] = {{booth[16][31:0]}, {32{1'b0}}}; // booth can only be 1 or 0 in this part, so only 32 bits needed

    Compressor32 m_compressor_l0(
        .in1(partial_0_temp[0]),
        .in2(partial_0_temp[1]),
        .in3(partial_0_temp[2]),
        .out1(partial_0[14]),
        .out2(partial_0[15])
    );

    // 16 -> 8
    generate
        for (g_i = 0; g_i < 4; g_i = g_i + 1) begin: m_compressors_l1
            Compressor42 m_compressor (
                .in1(partial_0[((g_i * 4) + 0)]),
                .in2(partial_0[((g_i * 4) + 1)]),
                .in3(partial_0[((g_i * 4) + 2)]),
                .in4(partial_0[((g_i * 4) + 3)]),
                .out1(partial_1[((g_i * 2) + 0)]),
                .out2(partial_1[((g_i * 2) + 1)])
            );
        end
    endgenerate

    generate
        for (g_i = 0; g_i < 8; g_i = g_i + 1) begin: partial_1_flatten
            assign partial_1_flat[(64 * (g_i + 1) - 1):(64 * g_i)] = partial_1[g_i];
        end
    endgenerate

    MUL_Reg #(.SIZE(8)) m_MUL_0_Reg(
        .clk(clk),
        .rst_n(rst_n),
        .partial_i(partial_1_flat),
        .sign_i(sign),
        .higher_i(higher),
        .start_i(start),

        .partial_o(partial_1_flat_o),
        .sign_o(r_sign_o[0]),
        .higher_o(r_higher_o[0]),
        .start_o(r_start_o[0])
    );

    generate
        for (g_i = 0; g_i < 8; g_i = g_i + 1) begin: partial_1_o_unflatten
            assign partial_1_o[g_i] = partial_1_flat_o[(64 * (g_i + 1) - 1):(64 * g_i)];
        end
    endgenerate

    // 8 -> 4
    generate
        for (g_i = 0; g_i < 2; g_i = g_i + 1) begin: m_compressors_l2
            Compressor42 m_compressor (
                .in1(partial_1_o[((g_i * 4) + 0)]),
                .in2(partial_1_o[((g_i * 4) + 1)]),
                .in3(partial_1_o[((g_i * 4) + 2)]),
                .in4(partial_1_o[((g_i * 4) + 3)]),
                .out1(partial_2[((g_i * 2) + 0)]),
                .out2(partial_2[((g_i * 2) + 1)])
            );
        end
    endgenerate

    generate
        for (g_i = 0; g_i < 1; g_i = g_i + 1) begin: m_compressors_l3
            Compressor42 m_compressor (
                .in1(partial_2[((g_i * 4) + 0)]),
                .in2(partial_2[((g_i * 4) + 1)]),
                .in3(partial_2[((g_i * 4) + 2)]),
                .in4(partial_2[((g_i * 4) + 3)]),
                .out1(partial_3[((g_i * 2) + 0)]),
                .out2(partial_3[((g_i * 2) + 1)])
            );
        end
    endgenerate

    generate
        for (g_i = 0; g_i < 2; g_i = g_i + 1) begin: partial_3_flatten
            assign partial_3_flat[(64 * (g_i + 1) - 1):(64 * g_i)] = partial_3[g_i];
        end
    endgenerate

    MUL_Reg #(.SIZE(2)) m_MUL_3_Reg(
        .clk(clk),
        .rst_n(rst_n),
        .partial_i(partial_3_flat),
        .sign_i(r_sign_o[0]),
        .higher_i(r_higher_o[0]),
        .start_i(r_start_o[0]),

        .partial_o(partial_3_flat_o),
        .sign_o(r_sign_o[1]),
        .higher_o(r_higher_o[1]),
        .start_o(r_start_o[1])
    );

    generate
        for (g_i = 0; g_i < 2; g_i = g_i + 1) begin: partial_3_o_unflatten
            assign partial_3_o[g_i] = partial_3_flat_o[(64 * (g_i + 1) - 1):(64 * g_i)];
        end
    endgenerate

endmodule  
