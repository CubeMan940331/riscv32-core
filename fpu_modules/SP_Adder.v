module SP_Adder (
    input           clk,
    input           rst_n,
    input           start,
    input [31:0]    operand_a,
    input [31:0]    operand_b,
    input           is_subtraction,
    input [2:0]     rounding_mode,
    output [31:0]   result,
    output reg      flag_invalid,
    output reg      flag_overflow,
    output reg      flag_underflow,
    output reg      flag_inexact,
    output reg      done
);
    // operand a
    reg  [31:0] operand_a_reg;
    wire sign_a_dec;
    wire [7:0] exp_a_dec;
    wire [23:0] mant_a_dec;
    wire is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // operand b
    reg  [31:0] operand_b_reg;
    wire sign_b_dec;
    wire [7:0] exp_b_dec;
    wire [23:0] mant_b_dec;
    wire is_b_zero, is_b_infinity, is_b_nan, is_b_denormal;

    // result
    reg final_sign;
    reg [7:0] final_exp;
    reg [23:0] final_mant;
    
    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_a_reg), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    SP_Decoder decoder_b ( .fp_in(operand_b_reg), .sign_out(sign_b_dec), .exponent_out(exp_b_dec), .mantissa_out(mant_b_dec), .is_zero(is_b_zero), .is_infinity(is_b_infinity), .is_nan(is_b_nan), .is_denormal(is_b_denormal) );
    SP_Encoder encoder ( .sign_in(final_sign), .exponent_in(final_exp), .mantissa_in(final_mant), .fp_out(result) );
    
    // --- 1. Special Value Handling ---
    reg [3:0] state;
    localparam  WAITING = 4'd0,
                SPECIAL_VAL = 4'd1,
                NORMAL_CAL_0 = 4'd2,
                NORMAL_CAL_1 = 4'd3,
                NORMAL_CAL_2 = 4'd4,
                ROUNDING_0 = 4'd5,
                ROUNDING_1 = 4'd6,
                READY = 4'd8;
    integer i;
    wire eff_sign_b = sign_b_dec ^ is_subtraction; // e.g. a-(-b) = a+b
    wire eff_sub = (sign_a_dec != eff_sign_b);

    // --- 2. Normal Path ---
    reg [7:0] exp_diff;
    reg [27:0] mant_larger, temp_smaller, mant_smaller, mant_sum;
    reg lsb, g_bit, r_bit, s_bit, round_up;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= WAITING;
            done <= 0;
        end else begin
            case (state)
                WAITING: begin
                    flag_invalid <= 0;
                    flag_overflow <= 0;
                    flag_underflow <= 0;
                    flag_inexact <= 0;
                    done <= 0;
                    if (start) begin
                        operand_a_reg <= operand_a;
                        operand_b_reg <= operand_b;
                        state <= SPECIAL_VAL;
                    end
                end

                // --- 1. Special Value Handling ---
                SPECIAL_VAL: begin
                    if (is_a_nan || is_b_nan) begin
                        flag_invalid <= 1;
                        final_sign <= 0; final_exp <= 8'hFF; final_mant <= {2'b11, 22'b0}; // NAN
                        state <= READY;
                    end else if (is_a_infinity) begin
                        if (is_b_infinity && sign_a_dec != eff_sign_b) begin
                            flag_invalid <= 1;
                            final_sign <= 0; final_exp <= 8'hFF; final_mant <= {2'b11, 22'b0}; // NAN
                        end else begin
                            final_sign <= sign_a_dec; final_exp <= 8'hFF; final_mant <= 0; // INF
                        end
                        state <= READY;
                    end else if (is_b_infinity) begin
                        final_sign <= eff_sign_b; final_exp <= 8'hFF; final_mant <= 0; // INF
                        state <= READY;
                    end else if (is_a_zero) begin
                        final_sign <= eff_sign_b; final_exp <= exp_b_dec; final_mant <= mant_b_dec; // B
                        state <= READY;
                    end else if (is_b_zero) begin
                        final_sign <= sign_a_dec; final_exp <= exp_a_dec; final_mant <= mant_a_dec; // A
                        state <= READY;
                    end else begin
                        state <= NORMAL_CAL_0;
                    end
                end

                NORMAL_CAL_0: begin
                    if ((exp_a_dec > exp_b_dec) || ((exp_a_dec == exp_b_dec) && (mant_a_dec >= mant_b_dec))) begin
                        final_sign <= sign_a_dec;
                        final_exp <= exp_a_dec;
                        exp_diff <= (exp_a_dec == exp_b_dec + 1 && is_b_denormal && !eff_sign_b) ? 0 : exp_a_dec - exp_b_dec;
                        mant_larger <= {1'b0, mant_a_dec, 3'b0}; 
                        temp_smaller <= {1'b0, mant_b_dec, 3'b0};
                        mant_smaller <= ({1'b0, mant_b_dec, 3'b0} >> ((exp_a_dec == exp_b_dec + 1 && is_b_denormal && !eff_sign_b) ? 8'b0 : exp_a_dec - exp_b_dec));
                    end else begin
                        final_sign <= sign_b_dec;
                        final_exp <= exp_b_dec;
                        exp_diff <= (exp_b_dec == exp_a_dec + 1 && is_a_denormal && !sign_a_dec) ? 0 : exp_b_dec - exp_a_dec;
                        mant_larger <= {1'b0, mant_b_dec, 3'b0}; 
                        temp_smaller <= {1'b0, mant_a_dec, 3'b0};
                        mant_smaller <= ({1'b0, mant_a_dec, 3'b0} >> ((exp_b_dec == exp_a_dec + 1 && is_a_denormal && !sign_a_dec) ? 8'b0 : exp_b_dec - exp_a_dec));
                    end
                    state <= NORMAL_CAL_1;
                end

                NORMAL_CAL_1: begin
                    s_bit <= (exp_diff > 26) ? |temp_smaller : |(temp_smaller & ((28'd1 << exp_diff) - 1));
                    if (eff_sub) begin
                        mant_sum <= mant_larger - mant_smaller;
                    end else begin
                        mant_sum <= mant_larger + mant_smaller;
                    end
                    state <= NORMAL_CAL_2;
                end

                NORMAL_CAL_2: begin
                    if (mant_sum[27]) begin // Addition overflow
                        mant_sum <= mant_sum >> 1;
                        final_exp <= final_exp + 1;
                    end else if (!mant_sum[26]) begin
                        mant_sum <= mant_sum << 1;
                        final_exp <= final_exp - 1;
                    end else begin
                        lsb <= mant_sum[3];
                        g_bit <= mant_sum[2];
                        r_bit <= mant_sum[1];
                        s_bit <= s_bit | mant_sum[0];
                        state <= ROUNDING_0;
                    end
                end

                ROUNDING_0: begin
                    flag_inexact <= g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up <= g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up <= 1'b0; // RTZ
                        3'b010: round_up <= (g_bit | r_bit | s_bit) & final_sign; // RDN
                        3'b011: round_up <= (g_bit | r_bit | s_bit) & ~final_sign; // RUP
                        3'b100: round_up <= (g_bit | r_bit | s_bit); //RMM
                        default: round_up <= 1'b0;
                    endcase
                    state <= ROUNDING_1;
                end

                ROUNDING_1: begin
                    if (round_up) begin
                        mant_sum <= mant_sum + 8; // 1000 (lsb|g|r|s)
                        round_up <= 0;
                    end else if (mant_sum[27]) begin
                        if (final_exp == 254) begin
                            flag_overflow <= 1; flag_inexact <= 1;
                            final_exp <= 8'hFF; final_mant <= 0;
                        end else begin
                            final_mant <= mant_sum[27:4];
                            final_exp <= final_exp + 1;
                        end
                        state <= READY;
                    end else begin
                        final_mant <= mant_sum[26:3];
                        if (final_exp > 254) begin
                            flag_overflow <= 1; flag_inexact <= 1;
                            final_exp <= 8'hFF; final_mant <= 0;
                        end else if (final_exp == 0) begin
                            flag_underflow <= 1; final_exp <= 0;
                        end
                        state <= READY;
                    end
                end

                READY: begin
                    done <= 1;
                    state <= WAITING;
                end

                default: begin
                    final_sign <= 0;
                    final_exp <= 0;
                    final_mant <= 0;
                    done <= 0;
                end
            endcase
        end
    end

endmodule
