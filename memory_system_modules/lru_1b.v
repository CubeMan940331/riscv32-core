`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/18 19:15:11
// Design Name: 
// Module Name: lru_1b
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


module lru_1b(
    input clk,
    input hit,
    input [8:0]index,
    output lru
);
    wire lru_i = hit ? (lru ? 0: 1) : lru;
    status_ramd_1x512 lru_arr (.a(index), .d(lru_i), .clk(clk), .we(hit), .spo(lru));
endmodule
