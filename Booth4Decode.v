module Booth4Decode (
    input [2:0] code,
    input [31:0] multiplicand,
    input unsign,
    output reg [33:0] booth_out //sign + 32 bits << 1/0 = 34 bits
);

    wire [31:0] neg_multiplicand;
    
    assign neg_multiplicand = -multiplicand;

    always @(*) begin

        case(code)
            3'b000: booth_out = 34'b0;
            3'b001: booth_out = {{2{(unsign ? 1'b0 : multiplicand[31])}}, multiplicand}; // if unsign, append 2 `0`s since booth out should be pos, else append sign
            3'b010: booth_out = {{2{(unsign ? 1'b0 : multiplicand[31])}}, multiplicand};
            3'b011: booth_out = {(unsign ? 1'b0 : multiplicand[31]), multiplicand, 1'b0}; // 2 m, if unsign, append 1 `0` since booth out should be pos, else append sign
            3'b100: booth_out = {(unsign ? 1'b1 : neg_multiplicand[31]), neg_multiplicand, 1'b0}; // -2 m, if unsign, append 1 `1` since booth out should be pos, else append sign
            3'b101: booth_out = {{2{(unsign ? 1'b1 : neg_multiplicand[31])}}, neg_multiplicand}; // if unsign, append 2 `1`s since booth out should be neg, else append sign
            3'b110: booth_out = {{2{(unsign ? 1'b1 : neg_multiplicand[31])}}, neg_multiplicand};
            3'b111: booth_out = 34'b0;

            default: booth_out = 34'bx;
        endcase
    end

endmodule
