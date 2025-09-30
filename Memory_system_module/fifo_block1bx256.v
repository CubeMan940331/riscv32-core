`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/23 01:07:56
// Design Name: 
// Module Name: fifo_block1bx256
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


module fifo_block1bx256(
    input clk,
    input en,
    input [7:0]index,
    output fifo
);
    wire fifo_i = ~fifo;
    status_ramd_1x256 fifo_arr (.a(index), .d(fifo_i), .clk(clk), .we(en), .spo(fifo));
endmodule
