module SP_Fused (
    input [31:0]    operand_a,
    input [31:0]    operand_b,
    input [31:0]    operand_c,
    input           is_subtraction,
    input           is_negative,
    input [2:0]     rounding_mode,
    output reg [31:0]   result,
    output reg      flag_invalid,
    output reg      flag_overflow,
    output reg      flag_underflow,
    output reg      flag_inexact
);
    wire [31:0] mult_result;
    wire mult_invalid, mult_overflow, mult_underflow, mult_inexact;
    wire [31:0] adder_result;
    wire adder_invalid, adder_overflow, adder_underflow, adder_inexact;

    SP_Multiplier multiplier ( .operand_a(operand_a), .operand_b(operand_b), .rounding_mode(rounding_mode), .result(mult_result), .flag_invalid(mult_invalid), .flag_overflow(mult_overflow), .flag_underflow(mult_underflow), .flag_inexact(mult_inexact) );
    SP_Adder adder ( .operand_a({(is_negative) ? ~mult_result[31] : mult_result[31], mult_result[30:0]}), .operand_b(operand_c), .is_subtraction(is_subtraction), .rounding_mode(rounding_mode), .result(adder_result), .flag_invalid(adder_invalid), .flag_overflow(adder_overflow), .flag_underflow(adder_underflow), .flag_inexact(adder_inexact) );

    always @(*) begin
        flag_invalid = mult_invalid | adder_invalid;
        flag_overflow = mult_overflow | adder_overflow;
        flag_underflow = mult_underflow | adder_underflow;
        flag_inexact = mult_inexact | adder_inexact;
        result = adder_result;
    end
endmodule
