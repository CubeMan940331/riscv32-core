module DP_Encoder (
    input         sign_in,
    input  [10:0] exponent_in,
    input  [52:0] mantissa_in,
    output [63:0] fp_out
);
    assign fp_out = {sign_in, exponent_in, mantissa_in[51:0]};
endmodule
