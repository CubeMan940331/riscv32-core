module SP_Decoder (
    input  [31:0] fp_in,

    // SP decode
    output sign_out,
    output [7:0] exponent_out,
    output [23:0] mantissa_out,

    // Flags for identifying the number type
    output is_zero,
    output is_infinity,
    output is_nan,
    output is_denormal
);

    // intermediate logic
    wire is_exp_max = (fp_in[30:23] == 8'hFF);
    wire is_exp_zero = (fp_in[30:23] == 0);
    wire is_mant_zero = (fp_in[22:0] == 0);

    // set flag
    assign is_zero      = is_exp_zero && is_mant_zero;
    assign is_infinity  = is_exp_max  && is_mant_zero;
    assign is_nan       = is_exp_max  && !is_mant_zero;
    assign is_denormal  = is_exp_zero && !is_mant_zero;

    // decoded parts
    assign sign_out = fp_in[31];
    assign exponent_out = fp_in[30:23];
    assign mantissa_out = (is_denormal) ?{1'b0, fp_in[22:0]} :{1'b1, fp_in[22:0]};

endmodule
