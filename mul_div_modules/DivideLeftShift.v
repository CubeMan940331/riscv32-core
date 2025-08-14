module DivideLeftShift (
    input [31:0] r,
    input [31:0] d,
    output reg [65:0] r_o, //66
    output reg [33:0] d_o, //34
    output reg [4:0] shift_o
);
    integer i;

    wire [33:0] mask;
    assign mask = 34'h080000000;

    always @(*) begin

        r_o = {{34{1'b0}}, r};
        d_o = {{2'b0}, d};
        shift_o = 0;

        for (i = 0; i < 32; i = i + 1) begin
            if (~|(mask & d_o)) begin
                r_o = r_o << 1;
                d_o = d_o << 1;
                shift_o = shift_o + 1;
            end
        end
        
    end

endmodule
