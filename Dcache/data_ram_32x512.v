`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 16:56:04
// Design Name: 
// Module Name: data_block32B
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


module data_ram_32x512(
    input clka,
    input [3:0]wea,
    input [8:0]addra,
    input [31:0]dina,
    output reg [31:0]douta
    );
    reg [31:0] ram [0:511];
	
    always@(posedge clka)begin
		ram[addra][31:24] <= wea[3] ? dina[31:24] : ram[addra][31:24];
		ram[addra][23:16] <= wea[2] ? dina[23:16] : ram[addra][23:16];
		ram[addra][15:8] <= wea[1] ? dina[15:8] : ram[addra][15:8];
		ram[addra][7:0] <= wea[0] ? dina[7:0] : ram[addra][7:0];
	end
	
    always@(posedge clka)begin
		douta <= ram[addra];
	end

endmodule
