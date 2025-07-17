//-----------------------------------------------------------------
// Barrel Shifter
//-----------------------------------------------------------------
module shifter(
    input [15:0] In,
    input [3:0] ShAmt,
    input [1:0] Oper,
    output [15:0] Out
);

reg [15:0] left_rotate_1, left_rotate_2, left_rotate_4, left_rotate_8;
reg [15:0] shift_left_1, shift_left_2, shift_left_4, shift_left_8;
reg [15:0] ari_right_1, ari_right_2, ari_right_4, ari_right_8;
reg [15:0] shift_right_1, shift_right_2, shift_right_4, shift_right_8;
reg [15:0] result;

always @(*)begin
    case(Oper)
        2'b00: // Left Rotate
        begin
            if (ShAmt[0] == 1'b1)   left_rotate_1 = {In[14:0],In[15]};
            else    left_rotate_1 = In;
            
            if (ShAmt[1] == 1'b1)   left_rotate_2 = {left_rotate_1[13:0],left_rotate_1[15:14]};
            else    left_rotate_2 = left_rotate_1;

            if (ShAmt[2] == 1'b1)   left_rotate_4 = {left_rotate_2[11:0],left_rotate_2[15:12]};
            else    left_rotate_4 = left_rotate_2;

            if (ShAmt[3] == 1'b1)   left_rotate_8 = {left_rotate_4[7:0],left_rotate_4[15:8]};
            else    left_rotate_8 = left_rotate_4;

            result = left_rotate_8;
        end
        2'b01: // shift left logical
        begin 
            if (ShAmt[0]) shift_left_1 = {In[14:0], 1'b0};
            else          shift_left_1 = In;

            if (ShAmt[1]) shift_left_2 = {shift_left_1[13:0], 2'b00};
            else          shift_left_2 = shift_left_1;

            if (ShAmt[2]) shift_left_4 = {shift_left_2[11:0], 4'b0000};
            else          shift_left_4 = shift_left_2;

            if (ShAmt[3]) shift_left_8 = {shift_left_4[7:0], 8'b00000000};
            else          shift_left_8 = shift_left_4;

            result = shift_left_8;
        end
        2'b10: // shift right arithmetic
        begin
            if (ShAmt[0]) ari_right_1 = {In[15], In[15:1]};
            else          ari_right_1 = In;

            if (ShAmt[1]) ari_right_2 = {{2{ari_right_1[15]}}, ari_right_1[15:2]};
            else          ari_right_2 = ari_right_1;

            if (ShAmt[2]) ari_right_4 = {{4{ari_right_2[15]}}, ari_right_2[15:4]};
            else          ari_right_4 = ari_right_2;

            if (ShAmt[3]) ari_right_8 = {{8{ari_right_4[15]}}, ari_right_4[15:8]};
            else          ari_right_8 = ari_right_4;

            result = ari_right_8;
        end
        2'b11: // shift right
        begin
            if (ShAmt[0]) shift_right_1 = {1'b0, In[15:1]};
            else          shift_right_1 = In;

            if (ShAmt[1]) shift_right_2 = {2'b00, shift_right_1[15:2]};
            else          shift_right_2 = shift_right_1;

            if (ShAmt[2]) shift_right_4 = {4'b0000, shift_right_2[15:4]};
            else          shift_right_4 = shift_right_2;

            if (ShAmt[3]) shift_right_8 = {8'b00000000, shift_right_4[15:8]};
            else          shift_right_8 = shift_right_4;

            result = shift_right_8;
        end
        default: result = In;
    endcase
end

assign Out = result;

endmodule