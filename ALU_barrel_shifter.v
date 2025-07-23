//-----------------------------------------------------------------
// Barrel Shifter
//-----------------------------------------------------------------
module shifter(
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

            if (ShAmt[1]) shift_left_2 = {shift_left_1[29:0], 2'h0};
            else          shift_left_2 = shift_left_1;

            if (ShAmt[2]) shift_left_4 = {shift_left_2[27:0], 4'h0};
            else          shift_left_4 = shift_left_2;

            if (ShAmt[3]) shift_left_8 = {shift_left_4[23:0], 8'h00};
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

            if (ShAmt[1]) shift_right_2 = {2'h0, shift_right_1[31:2]};
            else          shift_right_2 = shift_right_1;

            if (ShAmt[2]) shift_right_4 = {4'h0, shift_right_2[31:4]};
            else          shift_right_4 = shift_right_2;

            if (ShAmt[3]) shift_right_8 = {8'h00, shift_right_4[31:8]};
            else          shift_right_8 = shift_right_4;

            result = shift_right_8;
        end
        default: result = In;
    endcase
end

assign Out = result;

endmodule