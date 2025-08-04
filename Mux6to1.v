module Mux6to1 #(
    parameter size = 32
)
(
    input [2:0] sel,
    input signed [size-1:0] s0,
    input signed [size-1:0] s1,
    input signed [size-1:0] s2,
    input signed [size-1:0] s3,
    input signed [size-1:0] s4,
    input signed [size-1:0] s5,
    output reg signed [size-1:0] out
);

always @(*)begin
    case(sel)
        3'b000: out = s0;
        3'b001: out = s1;
        3'b010: out = s2;
        3'b011: out = s3;
        3'b100: out = s4;
        3'b101: out = s5;
        default: out = 32'b0; //default
    endcase
end

endmodule
