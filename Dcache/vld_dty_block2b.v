`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/17 01:42:04
// Design Name: 
// Module Name: vld_dty_block2b
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


module vld_dty_block2b(
    input clk,
    input cpu_wr,
    input mem_wr,
    input [8:0]index,
    output vld_o,
    output dty_o
);
    // parameter definition //
    reg vld_i, dty_i;
    wire wr = cpu_wr | mem_wr ;
    
    // 這裡的write跟tag一樣必須是hit才會寫
    always@(*)begin
        if(cpu_wr | mem_wr)begin
            vld_i <= 1;
            dty_i <= cpu_wr ? 1 : 0;
        end 
    end
            
    
    status_ramd_1x512 vld (.a(index), .d(vld_i), .clk(clk), .we(wr), .spo(vld_o));//有init data時可能會從mem寫入?
    status_ramd_1x512 dty (.a(index), .d(dty_i), .clk(clk), .we(wr), .spo(dty_o));
endmodule
