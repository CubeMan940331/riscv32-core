`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/17 01:13:52
// Design Name: 
// Module Name: tag_block18b
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


module tag_block18b(
    input clk,
    input write,
    input [8:0]index,
    input [17:0]tag_i,
    output [17:0]tag_o
);
    // parameter definition //
    
    
    // write behavior  // 在更上層，tag_block的write和data_block不一樣，默認應該是read，直到hit才變write
    // none
    
    // read behavior //
    // none
    
    // instance contruction //
    tag_ramd_18x512 tag (.a(index), .d(tag_i), .clk(clk), .we(write), .spo(tag_o));
    
    //reset發生時，不清空(直接將valid改成0就好)
    
endmodule
