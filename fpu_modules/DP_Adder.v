module DP_Adder (
    input [63:0]    operand_a,
    input [63:0]    operand_b,
    input           is_subtraction,
    input [2:0]     rounding_mode,
    output [63:0]   result,
    output reg      flag_invalid,
    output reg      flag_overflow,
    output reg      flag_underflow,
    output reg      flag_inexact
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
    
    // --- 1. Special Value Handling ---
    reg normal_path_enable;
    reg eff_sign_b;

    // --- 2. Normal Path ---
    reg [10:0] exp_diff;
    reg [56:0] mant_larger, temp_smaller, mant_smaller, mant_sum;
    reg lsb, g_bit, r_bit, s_bit, round_up, eff_sub;

    always @(*) begin
        // init
        flag_invalid=0; flag_overflow=0; flag_underflow=0; flag_inexact=0;
        final_sign=0; final_exp='0; final_mant='0;
        normal_path_enable=1;

        // --- 1. Special Value Handling ---
        eff_sign_b = sign_b_dec ^ is_subtraction; // e.g. a-(-b) = a+b
        if (is_a_nan || is_b_nan) begin
            normal_path_enable = 0;
            flag_invalid = 1;
            final_sign = 0; final_exp = '1; final_mant = {1'b1, 52'h80000_00000000}; // NAN
        end else if (is_a_infinity) begin
            normal_path_enable = 0;
            if (is_b_infinity && sign_a_dec != eff_sign_b) begin
                flag_invalid = 1;
                final_sign = 0; final_exp = '1; final_mant = {1'b1, 52'h80000_00000000}; // NAN
            end else begin
                final_sign = sign_a_dec; final_exp = '1; final_mant = '0; // INF
            end
        end else if (is_b_infinity) begin
            normal_path_enable = 0;
            final_sign = eff_sign_b; final_exp = '1; final_mant = '0; // INF
        end else if (is_a_zero) begin
            normal_path_enable = 0;
            final_sign = eff_sign_b; final_exp = exp_b_dec; final_mant = mant_b_dec; // B
        end else if (is_b_zero) begin
            normal_path_enable = 0;
            final_sign = sign_a_dec; final_exp = exp_a_dec; final_mant = mant_a_dec; // A
        end

        // init
        exp_diff='0;
        mant_larger='0; temp_smaller='0; mant_smaller='0; mant_sum='0;
        lsb=0; g_bit=0; r_bit=0; s_bit=0; round_up=0;
        eff_sub=0;

        // --- 2. Normal Path ---
        if (normal_path_enable) begin
            if ((exp_a_dec > exp_b_dec) || ((exp_a_dec == exp_b_dec) && (mant_a_dec >= mant_b_dec))) begin
                final_sign = sign_a_dec;
                final_exp = exp_a_dec;
                exp_diff = exp_a_dec - exp_b_dec;
                mant_larger = {1'b0, mant_a_dec, 3'b0}; 
                temp_smaller = {1'b0, mant_b_dec, 3'b0};
                if(exp_diff == 1 && is_b_denormal && !eff_sign_b) exp_diff = '0;
            end else begin
                final_sign = sign_b_dec;
                final_exp = exp_b_dec;
                exp_diff = exp_b_dec - exp_a_dec;
                mant_larger = {1'b0, mant_b_dec, 3'b0}; 
                temp_smaller = {1'b0, mant_a_dec, 3'b0};
                if(exp_diff == 1 && is_a_denormal && !sign_a_dec) exp_diff = '0;
            end
            s_bit = (exp_diff > 55) ? |temp_smaller : |(temp_smaller & ((57'd1 << exp_diff) - 1));
            mant_smaller = (temp_smaller >> exp_diff) | {56'b0, s_bit};

            eff_sub = (sign_a_dec != eff_sign_b);
            if (eff_sub) mant_sum = mant_larger - mant_smaller; else mant_sum = mant_larger + mant_smaller;

            if (mant_sum == 0) begin
                final_sign = (rounding_mode==3'b010) & sign_a_dec & eff_sign_b; final_exp='0; final_mant='0; normal_path_enable=0;
            end
            
            if (normal_path_enable) begin
                if (mant_sum[56]) begin // Addition overflow
                    mant_sum >>= 1; final_exp += 1;
                end

                // Subtract clear leading zero for implicit bit 1
                for (int i = 55; i >= 3; i--) begin
                    if (!mant_sum[55]) begin
                        mant_sum <<= 1; final_exp -= 1;
                    end else begin
                        i = 0;
                    end
                end
                
                begin
                    lsb = mant_sum[3]; g_bit |= mant_sum[2]; r_bit |= mant_sum[1]; s_bit |= mant_sum[0];
                    flag_inexact = g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up = 1'b0; // RTZ
                        3'b010: round_up = flag_inexact & final_sign; // RDN
                        3'b011: round_up = flag_inexact & ~final_sign; // RUP
                        3'b100: round_up = g_bit; //RMM
                        default: round_up = 1'b0;
                    endcase
                    if(round_up) mant_sum += 8; // 1000 (lsb|g|r|s)
                    if (mant_sum[56]) begin mant_sum >>= 1; final_exp += 1; end
                    final_mant = mant_sum[55:3];
                end

                if (final_exp > 2046) begin
                    flag_overflow=1; flag_inexact=1; final_exp='1; final_mant='0;
                end else if (final_exp == 0) begin
                    flag_underflow=1; final_exp='0;
                end
            end
        end
    end
endmodule
