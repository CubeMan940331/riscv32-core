module SP_Classifier (
    input           clk,
    input           rst_n,
    input           start,
    input  [31:0]   fp_in,
    output [9:0]    result,
    output          done
);
    // intermediate logic
    wire is_exp_max = (fp_in[30:23] == 8'hFF);
    wire is_exp_zero = (fp_in[30:23] == 0);
    wire is_mant_zero = (fp_in[22:0] == 0);

    // set flag
    wire is_zero      = is_exp_zero && is_mant_zero;
    wire is_infinity  = is_exp_max  && is_mant_zero;
    wire is_nan       = is_exp_max  && !is_mant_zero;
    wire is_denormal  = is_exp_zero && !is_mant_zero;
    wire is_normal = ~(is_zero | is_infinity | is_nan | is_denormal);

    assign result[0] = fp_in[31] && is_infinity;    // -infinity
    assign result[1] = fp_in[31] && is_normal;      // -normal
    assign result[2] = fp_in[31] && is_denormal;    // -denormal
    assign result[3] = fp_in[31] && is_zero;        // -0
    assign result[4] = ~fp_in[31] && is_zero;       // +0
    assign result[5] = ~fp_in[31] && is_denormal;   // +denormal
    assign result[6] = ~fp_in[31] && is_normal;     // +normal
    assign result[7] = ~fp_in[31] && is_infinity;   // +infinity
    assign result[8] = is_nan && ~fp_in[22];        // SNaN
    assign result[9] = is_nan && fp_in[22];         // QNaN

    assign done = start;
endmodule
