module SP_Fsgnj (
    input  [31:0]    operand_a,
    input  [31:0]    operand_b,
    input  [2:0]     func3,
    output reg [31:0]    result
);

    always @(*) begin
        result = 0;

        case (func3)
            3'b000: result = {operand_b[31], operand_a[30:0]};
            3'b001: result = {~operand_b[31], operand_a[30:0]};
            3'b010: result = {operand_a[31] ^ operand_b[31], operand_a[30:0]};
            default: result = {operand_b[31], operand_a[30:0]};
        endcase
    end
endmodule
