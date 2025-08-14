module Booth4Decode (
    input [2:0] code,
    input [31:0] multiplicand,
    input unsign,
    output reg [33:0] booth_out //sign + 32 bits << 1/0 = 34 bits
);

    wire zero;
    wire [32:0] neg_multiplicand;
    
    assign zero = ~(|multiplicand);
    assign neg_multiplicand = -{(unsign ? 1'b0 : multiplicand[31]), multiplicand}; // for signed multiplicand, neg_multiplicand = multiplicand may happen
                                                                                   // ex: 10000000 -> 10000000, append to 33 bit to avoid this: 110000000 -> 010000000

    always @(*) begin

        case(code)
            3'b000: booth_out = 34'b0;
            3'b001: booth_out = {{2{(unsign ? 1'b0 : multiplicand[31])}}, multiplicand}; // if unsign, append 2 `0`s since booth out should be pos, else append sign
            3'b010: booth_out = {{2{(unsign ? 1'b0 : multiplicand[31])}}, multiplicand};
            3'b011: booth_out = {(unsign ? 1'b0 : multiplicand[31]), multiplicand, 1'b0}; // 2 m, if unsign, append 1 `0` since booth out should be pos, else append sign
            3'b100: booth_out = {(unsign ? zero ? 1'b0 : 1'b1 : neg_multiplicand[32]), neg_multiplicand[31:0], 1'b0}; // -2 m, if unsign, append 1 `1` since booth out should be neg; if zero append `0`, else append sign
            3'b101: booth_out = {{2{(unsign ? zero ? 1'b0 : 1'b1 : neg_multiplicand[32])}}, neg_multiplicand[31:0]}; // if unsign, append 2 `1`s since booth out should be neg; if zero append `0`, else append sign
            3'b110: booth_out = {{2{(unsign ? zero ? 1'b0 : 1'b1 : neg_multiplicand[32])}}, neg_multiplicand[31:0]};
            3'b111: booth_out = 34'b0;

            default: booth_out = 34'bx;
        endcase
    end

endmodule
