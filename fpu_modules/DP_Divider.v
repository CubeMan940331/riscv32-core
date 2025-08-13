module DP_Divider (
    input [63:0] operand_a,
    input [63:0] operand_b,
    input [2:0]  rounding_mode,
    output reg [63:0] result,
    output reg       flag_invalid,
    output reg       flag_divbyzero,
    output reg       flag_overflow,
    output reg       flag_underflow,
    output reg       flag_inexact
);
    // operand a
    reg sign_a_dec;
    reg [10:0] exp_a_dec;
    reg [52:0] mant_a_dec;
    reg is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // operand b
    reg sign_b_dec;
    reg [10:0] exp_b_dec;
    reg [52:0] mant_b_dec;
    reg is_b_zero, is_b_infinity, is_b_nan, is_b_denormal;

    // result
    reg final_sign;
    reg [10:0] final_exp;
    reg [52:0] final_mant;
    
    // Decode / Encode
    DP_Decoder decoder_a ( .fp_in(operand_a), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    DP_Decoder decoder_b ( .fp_in(operand_b), .sign_out(sign_b_dec), .exponent_out(exp_b_dec), .mantissa_out(mant_b_dec), .is_zero(is_b_zero), .is_infinity(is_b_infinity), .is_nan(is_b_nan), .is_denormal(is_b_denormal) );
    DP_Encoder encoder ( .sign_in(final_sign), .exponent_in(final_exp), .mantissa_in(final_mant), .fp_out(result) );

    // local variables
    reg normal_path_enable;

    int exp_diff;
    reg [52:0] mant_a_div;
    reg [52:0] mant_b_div;

    localparam div_precision = 80;
    reg [div_precision + 52:0] dividend;
    reg [div_precision + 52:0] divisor;
    reg [1 + div_precision + 52:0] quotient;

    reg lsb, g_bit, r_bit, s_bit, round_up;

    always @(*) begin
        // init
        flag_invalid=0; flag_divbyzero=0; flag_overflow=0; flag_underflow=0; flag_inexact=0;
        normal_path_enable = 1;
        final_exp = '0; final_mant = '0;

        // --- 1. Special Value Handling ---
        final_sign = sign_a_dec ^ sign_b_dec;
        if ((is_a_nan || is_b_nan) || (is_a_infinity && is_b_infinity) || (is_a_zero && is_b_zero)) begin
            normal_path_enable = 0; flag_invalid = 1; final_exp = '1; final_mant = {1'b1, 52'h80000_00000000}; // NAN
        end else if (is_b_zero) begin
            normal_path_enable = 0; flag_divbyzero = 1; final_exp = '1; final_mant = '0; // Inf
        end else if (is_a_infinity) begin
            normal_path_enable = 0; final_exp = '1; final_mant = '0; // Inf
        end else if (is_a_zero) begin
            normal_path_enable = 0; final_exp = '0; final_mant = '0; // zero
        end else if (is_b_infinity) begin
            normal_path_enable = 0; final_exp = '0; final_mant = '0; // zero
        end

        // init
        exp_diff = 1023;
        mant_a_div = mant_a_dec; mant_b_div = mant_b_dec;
        dividend = '0; divisor = '0; quotient = '0;
        lsb = 0; g_bit = 0; r_bit = 0; s_bit = 0; round_up = 0;

        // --- 2. Normal Path ---
        if (normal_path_enable) begin
            // --- 2a. Exponent ---
            exp_diff += ($signed({21'b0, exp_a_dec}) - 1023) - ($signed({21'b0, exp_b_dec}) - 1023);
                // denormal
                if (is_a_denormal) begin
                    for (int i = 52 ; i > 0 ; i--) begin
                        if (!mant_a_div[52]) begin exp_diff -= 1; mant_a_div <<= 1; end
                        else begin i = 0; end
                    end
                end
                if (is_b_denormal) begin
                    for (int i = 52 ; i > 0 ; i--) begin
                        if (!mant_b_div[52]) begin exp_diff += 1; mant_b_div <<= 1; end
                        else begin i = 0; end
                    end
                end
            
            if (mant_a_div < mant_b_div) begin exp_diff -= 1; end // carry

            // --- 2b. Division ---
            dividend = {mant_a_div, {div_precision{1'b0}}};
            divisor = {{div_precision{1'b0}}, mant_b_div};
            quotient[div_precision + 52:0] = dividend / divisor;

            // --- 2c. Post-Division leading zero ---
            for (;!quotient[div_precision + 52];) begin
                quotient <<= 1;
            end
            
            // --- 2d. Rounding Logic ---
            lsb = quotient[div_precision];
            g_bit = quotient[div_precision-1];
            r_bit = quotient[div_precision-2];
            s_bit = |quotient[div_precision-3:0];
            flag_inexact = g_bit | r_bit | s_bit;
            case (rounding_mode)
                3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                3'b001: round_up = 1'b0; // RTZ
                3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                3'b100: round_up = flag_inexact; //RMM
                default: round_up = 1'b0;
            endcase
            if (round_up) begin quotient += {53'b0, 1'b1, {div_precision{1'b0}}}; end
            if (quotient[div_precision + 53]) begin
                quotient >>= 1;
                exp_diff += 1;
            end

            // OF / UF
            if (exp_diff < -52) begin
                normal_path_enable = 0;
                flag_underflow = 1;
                flag_inexact = 1;
                final_exp = '0; final_mant = '0; // 0
            end
            else if (exp_diff > 2046) begin
                normal_path_enable = 0;
                flag_overflow = 1;
                flag_inexact = 1;
                final_exp = '1; final_mant = '0; // Inf
            end

            if (normal_path_enable) begin
                // put denormal back
                for (; exp_diff < 0 ; exp_diff++) begin quotient >>= 1; end

                // result
                final_exp = exp_diff[10:0];
                final_mant = quotient[div_precision + 52 : div_precision];
            end
        end
    end
endmodule
