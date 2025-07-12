`include "riscv_defs.v"
module ALU (
    input [3:0] ALU_ctrl,
    input signed [31:0] a,b,
    output reg signed [31:0] out
);
    always @(*) begin
        case(ALU_ctrl)
            `ALU_ADD: out = a+b;
            `ALU_SUB: out = a-b;
            `ALU_AND: out = a&b;
            `ALU_OR: out = a|b;
            `ALU_XOR: out = a^b;
            `ALU_SHIFTL: out = a << (b[4:0]);
            `ALU_SHIFTR: out = a >> (b[4:0]);
            `ALU_SHIFTR_ARITH: out = a>>> (b[4:0]);
            `ALU_LESS_THAN: out = {{31{1'b0}},$unsigned(a) < $unsigned(b)};//sltu
            `ALU_LESS_THAN_SIGNED: out = {{31{1'b0}}, a<b};//slt
            default: out = b; // pass b
        endcase
    end
endmodule
