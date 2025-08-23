module SP_Fsgnj (
    input           clk,
    input           rst_n,
    input               start,
    input  [31:0]       operand_a,
    input  [31:0]       operand_b,
    input  [2:0]        func3,
    output [31:0]       result,
    output              done
);
    reg [31:0] temp_result;

    always @(*) begin
        case (func3)
            3'b000: temp_result = {operand_b[31], operand_a[30:0]};
            3'b001: temp_result = {~operand_b[31], operand_a[30:0]};
            3'b010: temp_result = {operand_a[31] ^ operand_b[31], operand_a[30:0]};
            default: temp_result = {operand_b[31], operand_a[30:0]};
        endcase
    end

    assign result = temp_result;
    assign done = start;
endmodule
