module SP_Multiplier (
    input [31:0] operand_a,
    input [31:0] operand_b,
    input [2:0]  rounding_mode,
    output reg [31:0] result,
    output reg       flag_invalid,
    output reg       flag_overflow,
    output reg       flag_underflow,
    output reg       flag_inexact
);
    // operand a
    reg sign_a_dec;
    reg [7:0] exp_a_dec;
    reg [23:0] mant_a_dec;
    reg is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // operand b
    reg sign_b_dec;
    reg [7:0] exp_b_dec;
    reg [23:0] mant_b_dec;
    reg is_b_zero, is_b_infinity, is_b_nan, is_b_denormal;

    // result
    reg final_sign;
    reg [7:0] final_exp;
    reg [23:0] final_mant;
    
    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_a), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    SP_Decoder decoder_b ( .fp_in(operand_b), .sign_out(sign_b_dec), .exponent_out(exp_b_dec), .mantissa_out(mant_b_dec), .is_zero(is_b_zero), .is_infinity(is_b_infinity), .is_nan(is_b_nan), .is_denormal(is_b_denormal) );
    SP_Encoder encoder ( .sign_in(final_sign), .exponent_in(final_exp), .mantissa_in(final_mant), .fp_out(result) );

    // local variables
    reg normal_path_enable;
    int exp_diff;
    reg [23:0] mant_a_mul, mant_b_mul;
    reg [47:0] mul_mant;
    reg lsb, g_bit, r_bit, s_bit, round_up;

    always @(*) begin
        // init
        flag_invalid=0; flag_overflow=0; flag_underflow=0; flag_inexact=0;
        normal_path_enable = 1;

        final_exp = '0; final_mant = '0;

        // --- 1. Special Value Handling ---
        final_sign = sign_a_dec ^ sign_b_dec;
        if (is_a_nan || is_b_nan) begin 
            normal_path_enable = 0;
            flag_invalid = 1;
            final_exp = '1; final_mant = {2'b11, 22'b0}; // NaN
        end else if ((is_a_zero && is_b_infinity)||(is_a_infinity && is_b_zero)) begin 
            normal_path_enable = 0;
            flag_invalid = 1;
            final_sign = 0; final_exp = '1; final_mant = {2'b11, 22'b0}; // NaN
        end else if (is_a_zero || is_b_zero) begin 
            normal_path_enable = 0;
            final_exp = '0; final_mant = '0; // 0
        end else if (is_a_infinity || is_b_infinity) begin 
            normal_path_enable = 0;
            final_exp = '1; final_mant = '0; // Inf
        end
        
        // init
        exp_diff = 127;
        mant_a_mul = mant_a_dec; mant_b_mul = mant_b_dec;
        mul_mant = '0;
        lsb = 0; g_bit = 0; r_bit = 0; s_bit = 0; round_up = 0;

        // --- 2. Normal Path ---
        if (normal_path_enable) begin
            // exponent
            exp_diff += ($signed({24'b0, exp_a_dec}) - 127) + ($signed({24'b0, exp_b_dec}) - 127);

                // denormal handling
                if (is_a_denormal) begin 
                    mant_a_mul <<= 1;
                    for (int i = 23 ; i > 0 ; i--) begin
                        if (!mant_a_mul[23]) begin exp_diff -= 1; mant_a_mul <<= 1; end
                        else begin i = 0; end
                    end
                end
                if (is_b_denormal) begin 
                    mant_b_mul <<= 1;
                    for (int i = 23 ; i > 0 ; i--) begin
                        if (!mant_b_mul[23]) begin exp_diff -= 1; mant_b_mul <<= 1; end
                        else begin i = 0; end
                    end
                end

            if (exp_diff < -24) begin
                normal_path_enable = 0;
                flag_underflow = 1;
                flag_inexact = 1;
                final_exp = '0; final_mant = '0; // 0
            end
            else if (exp_diff > 254) begin
                normal_path_enable = 0;
                flag_overflow = 1;
                flag_inexact = 1;
                final_exp = '1; final_mant = '0; // Inf
            end

            if(normal_path_enable) begin
                // mantissa
                mul_mant = mant_a_mul * mant_b_mul;

                    // denormal put it back
                    if (exp_diff < 0) begin mul_mant >>= 1; flag_underflow = 1; end
                    for (; exp_diff < 0 ; exp_diff++) begin
                        mul_mant >>= 1;
                    end

                    // exponent fetch
                    final_exp = exp_diff[7:0];

                if (mul_mant[47] == 1) begin final_exp += 1; mul_mant[47] = 0; end
                else begin mul_mant <<= 1; end
                
                // rounding
                lsb = mul_mant[24];
                g_bit = mul_mant[23];
                r_bit = mul_mant[22];
                s_bit = |mul_mant[21:0];
                flag_inexact = g_bit | r_bit | s_bit;
                case (rounding_mode)
                    3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                    3'b001: round_up = 1'b0; // RTZ
                    3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                    3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                    3'b100: round_up = flag_inexact; //RMM
                    default: round_up = 1'b0;
                endcase
                if (round_up) begin mul_mant += {24'b0, 1'b1, 23'b0}; end

                
                final_mant = mul_mant[47:24];
                if (flag_underflow) begin flag_underflow = |mul_mant[23:0]; end
            end
        end
    end
endmodule
