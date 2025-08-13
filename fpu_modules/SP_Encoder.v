module SP_Encoder (
    input         sign_in,
    input  [7:0] exponent_in,
    input  [23:0] mantissa_in,
    output [31:0] fp_out
);
    assign fp_out = {sign_in, exponent_in, mantissa_in[22:0]};
endmodule
