`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/23 00:11:50
// Design Name: 
// Module Name: tag_block19bx256
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tag_block19bx256(
    input clk,
    input write,
    input [7:0]index,
    input [18:0]tag_i,
    output [18:0]tag_o
);
    tag_ramd_19x256 tag (.a(index), .d(tag_i), .clk(clk), .we(write), .spo(tag_o));
endmodule
