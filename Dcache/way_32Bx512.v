`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/17 10:24:00
// Design Name: 
// Module Name: way_32Bx512
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


module way_32Bx512(
    input clk,
    input rst_n,
    input cpu_wr,
    input mem_wr,
    input [3:0]mask, //更上層不論是mem或cpu寫到cache，都要給mask
    input [17:0]tag_i,
    input [8:0]index,
    input [2:0]word_offset, // equal to the first three of 5 bits offset.
    input [31:0]cpu_data_i,
    input [255:0]mem_data_i,
    
    output [31:0]cpu_data_o,
    output [255:0]mem_data_o,
    output vld_o,
    output dty_o,
    output [17:0]tag_o
);
    // parameter definition //
    wire write = cpu_wr | mem_wr;
    
    // instance struction //
    vld_dty_block2b s_arr(.clk(clk), .cpu_wr(cpu_wr), .mem_wr(mem_wr), .index(index), .vld_o(vld_o), .dty_o(dty_o));
    tag_block18b t_arr (.clk(clk), .write(write), .index(index), .tag_i(tag_i), .tag_o(tag_o));
    data_block32B d_arr (.clk(clk), .cpu_wr(cpu_wr), .mem_wr(mem_wr), .mask(mask), .index(index), .word_offset(word_offset), .cpu_data_i(cpu_data_i), .mem_data_i(mem_data_i), .cpu_data_o(cpu_data_o), .mem_data_o(mem_data_o));
    
    // input logic //
    
    
    // output logic //
    
endmodule
