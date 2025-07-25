//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------

module ALU(
    input  [31:0] InA,
    input  [31:0] InB,
    input         Cin,
    input  [2:0]  Oper,
    input         invA,
    input         invB,
    input         Sign,
    output [31:0] Out,
    output        Ofl,
    output        Zero
);

wire [31:0] shift_out; 
wire [31:0] invertA, invertB, A, B;
wire signA, signB, sign_result;
wire sign_ofl, unsign_ofl;

reg [31:0] result;
reg Ofl_result, Zero_result;

Shifter shifter(
    .In(A),
    .ShAmt(B[3:0]),
    .Oper(Oper[1:0]),
    .Out(shift_out)
);

// First Bit of A, B, result
assign signA = A[31];
assign signB = B[31];
assign sign_result = result[31];

// Inverter
assign invertA = ~InA + 1;
assign invertB = ~InB + 1;
assign A = (invA)?invertA:InA;
assign B = (invB)?invertB:InB;

// Overflow Detection
assign sign_ofl = (~signA & ~signB & sign_result) | (signA & signB & ~sign_result);
assign unsign_ofl = (signA & signB) | (signA & ~sign_result) | (signB & ~sign_result); 

// Result Assign
assign Out = result;
assign Ofl = Ofl_result; 
assign Zero = Zero_result;

always @(*)begin
    case(Oper)
        3'b100: result = A + B + Cin;
        3'b101: result = A & B;
        3'b110: result = A | B;
        3'b111: result = A ^ B;
        default: result = shift_out;
    endcase

    case (Oper)
        3'b100:  Ofl_result = (Sign)?sign_ofl:unsign_ofl;
        default: Ofl_result = 1'b0;
    endcase
    
    Zero_result = (Out == 32'b0);
end

endmodule

//-----------------------------------------------------------------
// Barrel Shifter
//-----------------------------------------------------------------
module Shifter(
    input [31:0] In,
    input [3:0] ShAmt,
    input [1:0] Oper,
    output [31:0] Out
);

reg [31:0] left_rotate_1, left_rotate_2, left_rotate_4, left_rotate_8;
reg [31:0] shift_left_1, shift_left_2, shift_left_4, shift_left_8;
reg [31:0] ari_right_1, ari_right_2, ari_right_4, ari_right_8;
reg [31:0] shift_right_1, shift_right_2, shift_right_4, shift_right_8;
reg [31:0] result;

always @(In or ShAmt or Oper)begin
    left_rotate_1 = 32'h0;
    left_rotate_2 = 32'h0;
    left_rotate_4 = 32'h0;
    left_rotate_8 = 32'h0;

    shift_left_1  = 32'h0;
    shift_left_2  = 32'h0;
    shift_left_4  = 32'h0;
    shift_left_8  = 32'h0;

    ari_right_1   = 32'h0;
    ari_right_2   = 32'h0;
    ari_right_4   = 32'h0;
    ari_right_8   = 32'h0;

    shift_right_1 = 32'h0;
    shift_right_2 = 32'h0;
    shift_right_4 = 32'h0;
    shift_right_8 = 32'h0;

    result = 32'h0;

    case(Oper)
        2'b00: // Left Rotate
        begin
            if (ShAmt[0] == 1'b1)   left_rotate_1 = {In[30:0],In[31]};
            else    left_rotate_1 = In;
            
            if (ShAmt[1] == 1'b1)   left_rotate_2 = {left_rotate_1[29:0],left_rotate_1[31:30]};
            else    left_rotate_2 = left_rotate_1;

            if (ShAmt[2] == 1'b1)   left_rotate_4 = {left_rotate_2[27:0],left_rotate_2[31:28]};
            else    left_rotate_4 = left_rotate_2;

            if (ShAmt[3] == 1'b1)   left_rotate_8 = {left_rotate_4[23:0],left_rotate_4[31:24]};
            else    left_rotate_8 = left_rotate_4;

            result = left_rotate_8;
        end
        2'b01: // shift left logical
        begin 
            if (ShAmt[0]) shift_left_1 = {In[31:0], 1'b0};
            else          shift_left_1 = In;

            if (ShAmt[1]) shift_left_2 = {shift_left_1[29:0], 2'b00};
            else          shift_left_2 = shift_left_1;

            if (ShAmt[2]) shift_left_4 = {shift_left_2[27:0], 4'b0000};
            else          shift_left_4 = shift_left_2;

            if (ShAmt[3]) shift_left_8 = {shift_left_4[23:0], 8'b00000000};
            else          shift_left_8 = shift_left_4;

            result = shift_left_8;
        end
        2'b10: // shift right arithmetic
        begin
            if (ShAmt[0]) ari_right_1 = {In[31], In[31:1]};
            else          ari_right_1 = In;

            if (ShAmt[1]) ari_right_2 = {{2{ari_right_1[31]}}, ari_right_1[31:2]};
            else          ari_right_2 = ari_right_1;

            if (ShAmt[2]) ari_right_4 = {{4{ari_right_2[31]}}, ari_right_2[31:4]};
            else          ari_right_4 = ari_right_2;

            if (ShAmt[3]) ari_right_8 = {{8{ari_right_4[31]}}, ari_right_4[31:8]};
            else          ari_right_8 = ari_right_4;

            result = ari_right_8;
        end
        2'b11: // shift right
        begin
            if (ShAmt[0]) shift_right_1 = {1'b0, In[31:1]};
            else          shift_right_1 = In;

            if (ShAmt[1]) shift_right_2 = {2'b00, shift_right_1[31:2]};
            else          shift_right_2 = shift_right_1;

            if (ShAmt[2]) shift_right_4 = {4'b0000, shift_right_2[31:4]};
            else          shift_right_4 = shift_right_2;

            if (ShAmt[3]) shift_right_8 = {8'b00000000, shift_right_4[31:8]};
            else          shift_right_8 = shift_right_4;

            result = shift_right_8;
        end
        default: result = In;
    endcase
end

assign Out = result;

endmodule