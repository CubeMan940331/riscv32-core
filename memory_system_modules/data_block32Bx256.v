`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/22 20:59:29
// Design Name: 
// Module Name: data_block32Bx256
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

//8KB 
//ofs = 5 bits, idx = 8 bits, tag = 32 - 8 - 5 =19
module data_block32Bx256(
    input clk,
    input mem_wr,
    input [255:0]mem_data,
    input [7:0]index,
    input [2:0]word_ofs,
    output [31:0]cpu_inst_o
);
    reg [31:0]data_i[0:7];
    wire [31:0]data_o[0:7];
    
    integer i;
    always@(*)begin
        for(i = 0; i < 8 ; i = i + 1)begin
                data_i[i] = mem_data[i*32 + 31 -: 32];
        end
    end  
    
    data_ram_32x256 b0(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[0]), .douta(data_o[0]));
    data_ram_32x256 b1(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[1]), .douta(data_o[1]));
    data_ram_32x256 b2(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[2]), .douta(data_o[2]));
    data_ram_32x256 b3(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[3]), .douta(data_o[3]));
    data_ram_32x256 b4(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[4]), .douta(data_o[4]));
    data_ram_32x256 b5(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[5]), .douta(data_o[5]));
    data_ram_32x256 b6(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[6]), .douta(data_o[6]));
    data_ram_32x256 b7(.clka(clk), .wea(mem_wr), .addra(index), .dina(data_i[7]), .douta(data_o[7]));

    assign cpu_inst_o = data_o[word_ofs];
endmodule
