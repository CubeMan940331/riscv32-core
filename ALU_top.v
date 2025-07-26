/* verilator lint_off UNUSEDSIGNAL */
`include "riscv_defs.v"
module ALU_top(
    input [3:0] ALU_ctrl,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] out
);

reg [2:0]  Oper;
reg        invB;
reg [31:0] ALU_out;
reg        Overflow;
reg        Zero;

ALU m_ALU(
    .InA(a),
    .InB(b),
    .Cin(0),
    .Oper(Oper),
    .invA(0),
    .invB(invB),
    .Sign(1),

    .Out(ALU_out),
    .Ofl(Overflow),
    .Zero(Zero)
);

/*
ALU_NONE            
ALU_SHIFTL          
ALU_SHIFTR          
ALU_SHIFTR_ARITH    
ALU_ADD             
ALU_SUB             
ALU_AND             
ALU_OR              
ALU_XOR             
ALU_LESS_THAN       
ALU_LESS_THAN_SIGNED
*/
always @(*) begin
    Oper=3'b100;
    invB=0;
    out = 32'h0;
    case (ALU_ctrl)
        `ALU_ADD: Oper = 3'b100; // ADD
        `ALU_SUB: begin
            Oper = 3'b100; // ADD
            invB = 1; // -B
        end
        `ALU_AND: Oper = 3'b101; // AND
        `ALU_OR:  Oper = 3'b110; // OR
        `ALU_XOR: Oper = 3'b111; // XOR
        `ALU_SHIFTL: begin
            Oper = 3'b001; // SLL
            out = ALU_out;
        end
        `ALU_SHIFTR: begin
            Oper = 3'b011; // SRL
            out = ALU_out;
        end
        `ALU_SHIFTR_ARITH: begin
            Oper = 3'b010; // SRA
            out = ALU_out;
        end
        `ALU_LESS_THAN: begin
            out = ALU_out;
        end
        `ALU_LESS_THAN_SIGNED: begin
            Oper = 3'b100; // SLT
            invB=1; // -B
            out = Zero ? 32'h0 : 32'h1; // Set result to 1 if less than
        end
        `ALU_NONE: begin
            out = b;
        end
        default:;
    endcase
end


endmodule
