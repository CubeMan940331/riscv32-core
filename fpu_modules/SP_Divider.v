module SP_Divider (
    input           clk,
    input           rst_n,
    input           start,
    input [31:0]    operand_a,
    input [31:0]    operand_b,
    input [2:0]     rounding_mode,
    output [31:0]   result,
    output reg      flag_invalid,
    output reg      flag_divbyzero,
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
    wire final_sign = sign_a_dec ^ sign_b_dec;
    reg [7:0] final_exp;
    reg [23:0] final_mant;
    
    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_a_reg), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    SP_Decoder decoder_b ( .fp_in(operand_b_reg), .sign_out(sign_b_dec), .exponent_out(exp_b_dec), .mantissa_out(mant_b_dec), .is_zero(is_b_zero), .is_infinity(is_b_infinity), .is_nan(is_b_nan), .is_denormal(is_b_denormal) );
    SP_Encoder encoder ( .sign_in(final_sign), .exponent_in(final_exp), .mantissa_in(final_mant), .fp_out(result) );

    // local variables
    reg [3:0] state;
    localparam  WAITING = 4'd0,
                SPECIAL_VAL = 4'd1,
                NORMALIZE = 4'd2,
                MANT_DIV_0 = 4'd3,
                MANT_DIV_1 = 4'd4,
                NORMAL_CAL_0 = 4'd5,
                NORMAL_CAL_1 = 4'd6,
                ROUNDING_0 = 4'd7,
                ROUNDING_1 = 4'd8,
                FINAL_CHECK = 4'd9,
                READY = 4'd10;
    reg [4:0] count;
    integer i;
    integer exp_diff;
    reg [23:0] mant_a_div;
    reg [23:0] mant_b_div;

    localparam div_precision = 27;
    reg [div_precision + 23:0] dividend;
    reg [div_precision + 23:0] divisor;
    reg [div_precision + 1:0] quotient;

    reg lsb, g_bit, r_bit, s_bit, round_up;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= WAITING;
            done <= 0;
        end else begin
            case (state)
                WAITING: begin
                    flag_invalid <= 0;
                    flag_divbyzero <= 0;
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

                SPECIAL_VAL: begin
                    if ((is_a_nan || is_b_nan) || (is_a_infinity && is_b_infinity) || (is_a_zero && is_b_zero)) begin
                        flag_invalid <= 1;
                        final_exp <= 8'hFF; final_mant <= {2'b11, 22'b0}; // NAN
                        state <= READY;
                    end else if (is_b_zero) begin
                        flag_divbyzero <= 1;
                        final_exp <= 8'hFF; final_mant <= 0; // Inf
                        state <= READY;
                    end else if (is_a_infinity) begin
                        final_exp <= 8'hFF; final_mant <= 0; // Inf
                        state <= READY;
                    end else if (is_a_zero) begin
                        final_exp <= 0; final_mant <= 0; // zero
                        state <= READY;
                    end else if (is_b_infinity) begin
                        final_exp <= 0; final_mant <= 0; // zero
                        state <= READY;
                    end else begin
                        exp_diff <= 127 + ($signed({24'b0, exp_a_dec}) - 127) - ($signed({24'b0, exp_b_dec}) - 127);
                        mant_a_div <= mant_a_dec;
                        mant_b_div <= mant_b_dec;
                        state <= NORMALIZE;
                    end
                end

                NORMALIZE: begin
                    if (!mant_a_div[23]) begin
                        exp_diff <= exp_diff - 1;
                        mant_a_div <= mant_a_div << 1;
                    end else if (!mant_b_div[23]) begin
                        exp_diff <= exp_diff + 1;
                        mant_b_div <= mant_b_div << 1;
                    end else begin
                        if (mant_a_div < mant_b_div) begin exp_diff <= exp_diff - 1; end // carry

                        // --- Division ---
                        dividend <= {mant_a_div, {div_precision{1'b0}}};
                        divisor <= {mant_b_div, {div_precision{1'b0}}};
                        count <= 0;
                        state <= MANT_DIV_0;
                    end
                end

                MANT_DIV_0: begin
                    if (dividend >= divisor) begin
                        dividend <= dividend - divisor;
                        quotient <= quotient + 1;
                    end else begin
                        dividend <= dividend;
                    end
                    state <= MANT_DIV_1;
                end

                MANT_DIV_1: begin
                    if (count < div_precision-1) begin
                        divisor <= divisor >> 1;
                        quotient <= quotient << 1;
                        count <= count + 1;
                        state <= MANT_DIV_0;
                    end else begin
                        state <= NORMAL_CAL_0;
                    end
                end

                NORMAL_CAL_0: begin
                    // --- Post-Division leading zero ---
                    if(!quotient[div_precision]) begin
                        quotient <= quotient << 1;
                    end else begin
                        lsb <= quotient[div_precision-24];
                        g_bit <= quotient[div_precision-25];
                        r_bit <= quotient[div_precision-26];
                        s_bit <= |quotient[div_precision-27:0];
                        state <= ROUNDING_0;
                    end
                end

                ROUNDING_0: begin
                    flag_inexact <= g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up <= g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up <= 1'b0; // RTZ
                        3'b010: round_up <= (g_bit | r_bit | s_bit) & sign_a_dec; // RDN
                        3'b011: round_up <= (g_bit | r_bit | s_bit) & ~sign_a_dec; // RUP
                        3'b100: round_up <= (g_bit | r_bit | s_bit); //RMM
                        default: round_up <= 1'b0;
                    endcase
                    state <= ROUNDING_1;
                end

                ROUNDING_1: begin
                    if (round_up) begin
                        quotient <= quotient + {24'b0, 1'b1, {(div_precision-24){1'b0}}};
                        round_up <= 0;
                    end else if (quotient[div_precision+1]) begin
                        quotient <= quotient >> 1;
                        exp_diff <= exp_diff + 1;
                        state <= FINAL_CHECK;
                    end else begin
                        state <= FINAL_CHECK;
                    end
                end

                FINAL_CHECK: begin
                    // OF / UF
                    if (exp_diff < -23) begin
                        flag_underflow <= 1;
                        flag_inexact <= 1;
                        final_exp <= 0; final_mant <= 0; // 0
                        state <= READY;
                    end else if (exp_diff > 254) begin
                        flag_overflow <= 1;
                        flag_inexact <= 1;
                        final_exp <= 8'hFF; final_mant <= 0; // Inf
                        state <= READY;
                    end else if (exp_diff < 0) begin
                        exp_diff <= exp_diff + 1;
                        quotient <= quotient >> 1;
                    end else begin
                        // result
                        final_exp <= exp_diff[7:0];
                        final_mant <= quotient[div_precision:div_precision-23];
                        state <= READY;
                    end
                end

                READY: begin
                    done <= 1;
                    state <= WAITING;
                end

                default: begin
                    done <= 0;
                    state <= WAITING;
                end
            endcase
        end
    end
endmodule
