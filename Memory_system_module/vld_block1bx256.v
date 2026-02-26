`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/22 23:47:58
// Design Name: 
// Module Name: vld_block1bx256
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


module vld_block1bx256(
    input clk,
    input write,
    input vld_i,
    input [7:0]index,
    output vld_o
);
    
	status_ramd_1x256 vld(.a(index), .d(vld_i), .clk(clk), .we(write), .spo(vld_o));
endmodule
