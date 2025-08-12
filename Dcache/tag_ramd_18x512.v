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


module tag_ramd_18x512(
    input [8:0]a,
    input [17:0]d,
	input clk,
    input we,
    output [17:0]spo
);
    reg [17:0] ram [0:511];
	
	integer i;
	initial begin
		for( i = 0; i < 512; i = i + 1)begin
			ram[i] = 0;
		end
	end
		
    always@(posedge clk)begin
		ram[a] = we ? d : ram[a];
	end
	
	assign spo = ram[a];
	
    
    //reset發生時，不清空(直接將valid改成0就好)
    
endmodule
