module SP_Compare (
    input           clk,
    input           rst_n,
    input           start,
    input [31:0]    operand_a,
    input [31:0]    operand_b,
    input [2:0]     func3,
    output reg      flag_cmp,
    output reg      flag_invalid,
    output          done
);
    // operand a
    wire sign_a_dec;
    wire [7:0] exp_a_dec;
    wire [23:0] mant_a_dec;
    wire is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // operand b
    wire sign_b_dec;
    wire [7:0] exp_b_dec;
    wire [23:0] mant_b_dec;
    wire is_b_zero, is_b_infinity, is_b_nan, is_b_denormal;

    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_a), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    SP_Decoder decoder_b ( .fp_in(operand_b), .sign_out(sign_b_dec), .exponent_out(exp_b_dec), .mantissa_out(mant_b_dec), .is_zero(is_b_zero), .is_infinity(is_b_infinity), .is_nan(is_b_nan), .is_denormal(is_b_denormal) );

    // Local params
    localparam CMP_EQ = 3'b010;
    localparam CMP_LT = 3'b001;
    localparam CMP_LE = 3'b000;

    // Local variables
    wire is_a_snan = is_a_nan & !mant_a_dec[22];
    wire is_b_snan = is_b_nan & !mant_b_dec[22];
    reg temp_eq, temp_gt, temp_lt, flag_eq, flag_gt, flag_lt, flag_unordered;

    always @(*) begin
        // init
        flag_cmp = 0;
        temp_eq=0; temp_gt=0; temp_lt=0; flag_eq=0; flag_gt=0; flag_lt=0; flag_unordered=0;

        // Invalid flag is set for SNaN in comparison
        flag_invalid = (is_a_snan | is_b_snan) && (func3 == CMP_EQ);

        // --- Comparison Logic ---
        // Path 1: At least one operand is NaN
        if (is_a_nan || is_b_nan) begin
            flag_unordered = 1'b1;
            if (func3 != CMP_EQ) begin flag_invalid = 1'b1; end
        end
        // Path 2: Both operands are Zero (+0 or -0)
        else if (is_a_zero && is_b_zero) begin
            // Per IEEE 754, +0 and -0 are equal in comparisons
            flag_eq = 1'b1;
        end
        // Path 3: Operands have different signs (and are not both zero)
        else if (sign_a_dec != sign_b_dec) begin
            if (sign_a_dec) begin // A is negative, B is positive
                flag_lt = 1'b1; 
            end else begin // A is positive, B is negative
                flag_gt = 1'b1;
            end
        end
        // Path 4: Operands have the same sign (and are not NaN or Zero)
        else begin 
            // Compare as if they were unsigned integers (sign bit is the same)
            // The decoded format (exp, mant) allows for direct magnitude comparison.
            temp_gt = ({exp_a_dec, mant_a_dec} > {exp_b_dec, mant_b_dec});
            temp_lt = ({exp_a_dec, mant_a_dec} < {exp_b_dec, mant_b_dec});
            temp_eq = ({exp_a_dec, mant_a_dec} == {exp_b_dec, mant_b_dec});

            // If both numbers are negative, the sense of the comparison is inverted.
            // A larger magnitude negative number is "less than".
            if (sign_a_dec) begin
                flag_lt = temp_gt;
                flag_gt = temp_lt;
                flag_eq = temp_eq;
            end else begin
                flag_lt = temp_lt;
                flag_gt = temp_gt;
                flag_eq = temp_eq;
            end
        end

        case (func3)
            CMP_EQ: flag_cmp = (flag_unordered) ? 0 : flag_eq;
            CMP_LT: flag_cmp = (flag_unordered) ? 0 : flag_lt;
            CMP_LE: flag_cmp = (flag_unordered) ? 0 : flag_eq | flag_lt;
            default: flag_cmp = 0; 
        endcase
    end

    assign done = start;

endmodule
