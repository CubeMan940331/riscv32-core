module SP_Sqrt (
    input [31:0] operand_a,
    input [2:0]  rounding_mode,
    output reg [31:0] result,
    output reg       flag_invalid,
    output reg       flag_inexact
);
    // operand a
    reg sign_a_dec;
    reg [7:0] exp_a_dec;
    reg [23:0] mant_a_dec;
    reg is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_a), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );

    reg normal_path_enable;

    // reg for evil trick
    localparam loops = 5;
    localparam threehalfs = 32'h3fc00000; // 1.5
    reg [31:0] mult_result_0, mult_result_1 [loops:0], mult_result_2 [loops:0], mult_result_3[loops+1:0];
    reg [31:0] sub_result [loops:0];
    reg [31:0] div_result;
    reg [31:0] mult_check_result;
    reg mult_check_inexact;

    // evil trick
    SP_Multiplier mult0 ( .operand_a(operand_a), .operand_b(32'h3f000000), .rounding_mode(3'b001), .result(mult_result_0), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact() );

    genvar i;
    generate
        for (i = 0 ; i < loops+1 ; i++) begin
            SP_Multiplier mult1 ( .operand_a(mult_result_3[i]), .operand_b(mult_result_3[i]), .rounding_mode(3'b001), .result(mult_result_1[i]), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact() );
            SP_Multiplier mult2 ( .operand_a(mult_result_1[i]), .operand_b(mult_result_0), .rounding_mode(3'b001), .result(mult_result_2[i]), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact() );
            SP_Adder sub ( .operand_a(threehalfs), .operand_b(mult_result_2[i]), .is_subtraction(1'b1), .rounding_mode(3'b001), .result(sub_result[i]), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact() );
            SP_Multiplier mult3 ( .operand_a(mult_result_3[i]), .operand_b(sub_result[i]), .rounding_mode(3'b001), .result(mult_result_3[i+1]), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact() );
        end
    endgenerate

    SP_Divider sp_divider_inst ( .operand_a(32'h3F800000), .operand_b(mult_result_3[loops+1]), .rounding_mode(rounding_mode), .result(div_result), .flag_invalid(), .flag_divbyzero(), .flag_overflow(), .flag_underflow(), .flag_inexact() );

    // evil init
    assign mult_result_3[0] = 32'h5f3759df - (operand_a >> 1);

    SP_Multiplier mult_check ( .operand_a(div_result), .operand_b(div_result), .rounding_mode(rounding_mode), .result(mult_check_result), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact(mult_check_inexact) );

    always @(*) begin
        // --- Default assignments ---
        flag_invalid=0; flag_inexact=0;
        normal_path_enable = 1;
        result = '0;

        // --- 1. Special Value Handling ---
        if (is_a_nan) begin normal_path_enable = 0; flag_invalid = 1; result = 32'h7fc00000; end // NAN
        else if (sign_a_dec == 1'b1 && !is_a_zero) begin normal_path_enable = 0; flag_invalid = 1; result = 32'h7fc00000; end // NAN
        else if (is_a_zero) begin normal_path_enable = 0; result = {sign_a_dec, 31'b0}; end // zero
        else if (is_a_infinity) begin normal_path_enable=0; result = 32'h7f800000; end // Inf

        // --- 2. Normal Path ---
        if (normal_path_enable) begin
            result = div_result;
            flag_inexact = (operand_a != mult_check_result) | mult_check_inexact;
        end
    end
endmodule
