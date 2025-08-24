module SP_Sqrt (
    input           clk,
    input           rst_n,
    input               start,
    input [31:0]        operand_a,
    input [2:0]         rounding_mode,
    output reg [31:0]   result,
    output reg          flag_invalid,
    output reg          flag_inexact,
    output reg          done
);
    // operand a
    reg  [31:0] operand_a_reg;
    wire sign_a_dec;
    wire [7:0] exp_a_dec;
    wire [23:0] mant_a_dec;
    wire is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_a_reg), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );

    reg [3:0] state;
    localparam  WAITING = 4'd0,
                SPECIAL_VAL = 4'd1,
                NORMALIZE = 4'd2,
                SUB = 4'd3,
                MULTIPLY = 4'd4,
                DIV = 4'd5,
                FINAL_CHECK = 4'd6,
                READY = 4'd8;

    // reg for evil trick
    reg sub_start, mult_start, div_start;
    wire sub_done, mult_done, div_done;
    wire mult_inexact;
    reg [31:0] sub_b, mult_a, mult_b, div_b;
    wire [31:0] sub_result, mult_result, div_result;
    reg [31:0] y, x2;
    localparam loops = 5;
    reg [3:0] loop;
    reg [3:0] mult_time;
    localparam one = 32'h3F800000; // 1.0
    localparam onehalf = 32'h3f000000; // 0.5
    localparam threehalfs = 32'h3fc00000; // 1.5

    // evil trick
    SP_Adder sp_adder_inst ( .clk(clk), .rst_n(rst_n), .start(sub_start), .operand_a(threehalfs), .operand_b(sub_b), .is_subtraction(1'b1), .rounding_mode(3'b001), .result(sub_result), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact(), .done(sub_done) );
    SP_Multiplier sp_multiplier_inst ( .clk(clk), .rst_n(rst_n), .start(mult_start), .operand_a(mult_a), .operand_b(mult_b), .rounding_mode(3'b001), .result(mult_result), .flag_invalid(), .flag_overflow(), .flag_underflow(), .flag_inexact(mult_inexact), .done(mult_done) );
    SP_Divider sp_divider_inst ( .clk(clk), .rst_n(rst_n), .start(div_start), .operand_a(one), .operand_b(div_b), .rounding_mode(rounding_mode), .result(div_result), .flag_invalid(), .flag_divbyzero(), .flag_overflow(), .flag_underflow(), .flag_inexact(), .done(div_done) );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= WAITING;
            done <= 0;
        end else begin
            case (state)
                WAITING: begin
                    flag_invalid <= 0;
                    flag_inexact <= 0;
                    done <= 0;
                    if (start) begin
                        operand_a_reg <= operand_a;
                        y <= 32'h5f3759df - (operand_a >> 1);
                        state <= SPECIAL_VAL;
                    end
                end

                SPECIAL_VAL: begin
                    if (is_a_nan) begin flag_invalid <= 1; result <= 32'h7fc00000; state <= READY; end // NAN
                    else if (sign_a_dec == 1'b1 && !is_a_zero) begin flag_invalid <= 1; result <= 32'h7fc00000; state <= READY; end // NAN
                    else if (is_a_zero) begin result <= {sign_a_dec, 31'b0}; state <= READY; end // zero
                    else if (is_a_infinity) begin result <= 32'h7f800000; state <= READY; end // Inf
                    else begin
                        mult_a <= operand_a_reg;
                        mult_b <= onehalf;
                        mult_start <= 1;
                        mult_time <= 0;
                        loop <= 1;
                        state <= MULTIPLY;
                    end
                end

                MULTIPLY: begin
                    if (mult_done) begin
                        case (mult_time)
                            0: begin
                                x2 <= mult_result;
                                mult_a <= y;
                                mult_b <= y;
                                mult_start <= 1;
                                mult_time <= mult_time + 1;
                            end
                            1: begin
                                mult_a <= x2;
                                mult_b <= mult_result;
                                mult_start <= 1;
                                mult_time <= mult_time + 1;
                            end
                            2: begin
                                sub_b <= mult_result;
                                sub_start <= 1;
                                state <= SUB;
                                mult_time <= mult_time + 1;
                            end
                            3: begin
                                if (loop < loops) begin
                                    loop <= loop + 1;
                                    mult_a <= mult_result;
                                    mult_b <= mult_result;
                                    y <= mult_result;
                                    mult_start <= 1;
                                    mult_time <= 1;
                                end else begin
                                    div_b <= y;
                                    div_start <= 1;
                                    state <= DIV;
                                    mult_time <= mult_time + 1;
                                end
                            end
                            4: begin
                                flag_inexact <= (operand_a_reg != mult_result) | mult_inexact;
                                state <= READY;
                            end
                        endcase
                    end else begin
                        mult_start <= 0;
                    end
                end

                SUB: begin
                    if (sub_done) begin
                        mult_a <= y;
                        mult_b <= sub_result;
                        mult_start <= 1;
                        state <= MULTIPLY;
                    end else begin
                        sub_start <= 0;
                    end
                end

                DIV: begin
                    if (div_done) begin
                        result <= div_result;
                        mult_a <= div_result;
                        mult_b <= div_result;
                        mult_start <= 1;
                        state <= MULTIPLY;
                    end else begin
                        div_start <= 0;
                    end
                end

                READY: begin
                    done <= 1;
                    state <= WAITING;
                end

                default: begin
                    done <= 1;
                    state <= WAITING;
                end
            endcase
        end
    end

endmodule
