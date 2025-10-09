`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/08 00:46:39
// Design Name: 
// Module Name: IF_selector
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


module IF_selector(
    input [31:0]pc_i,
    input icache_ready_i,
    input [31:0]inst_icache_i,
    input [31:0]inst_bootrom_i,
    output reg if_ready_o,
    output reg [31:0]inst_o
);
    parameter MAX_ROM_ADDR = 32'h0002_0000; //The real Max address of ROM is this one minus 1
    
    
    always@(*)begin
        if(pc_i < MAX_ROM_ADDR)begin
            if_ready_o = 1;
            inst_o = inst_bootrom_i;
        end
        else begin
            if_ready_o = icache_ready_i;
            inst_o = inst_icache_i;    
        end
    end  
    
    
endmodule
