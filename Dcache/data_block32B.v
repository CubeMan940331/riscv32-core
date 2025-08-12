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


module data_block32B(
    input clk,
    input cpu_wr,
    input mem_wr,
    input [3:0]mask,
    input [8:0]index,
    input [2:0]word_offset, // equal to the first three of 5 bits offset.
    input [31:0]cpu_data_i,
    input [255:0]mem_data_i,
    output [31:0]cpu_data_o,
    output [255:0]mem_data_o
    );
    
    // parameter definition //
    wire [7:0] word_ena = (1 << word_offset);
    wire [31:0] word_o [0:7];
    reg  [3:0] wea [0:7];
    reg [31:0] data_i[0:7];
    
    // write policy //
    integer i;
    always@(*)begin
        for(i = 0; i < 8 ; i = i + 1)begin
            if(cpu_wr)begin
                wea[i] = word_ena[i] ? mask : 0;
                data_i[i] = word_ena[i] ? cpu_data_i : 0; end
            else if(mem_wr)begin
                wea[i] = 4'hf;
                data_i[i] = mem_data_i[i*32 + 31 -: 32]; end
            else begin
            wea[i] = 4'b0000;
            data_i[i] = 32'h00000000; end
        end 
    end    
    
    // Instance contruction //  //是否要採用enable pin???
    data_ram_32x512 w0 (.clka(clk), .wea(wea[0]), .addra(index), .dina(data_i[0]), .douta(word_o[0]));
    data_ram_32x512 w1 (.clka(clk), .wea(wea[1]), .addra(index), .dina(data_i[1]), .douta(word_o[1]));
    data_ram_32x512 w2 (.clka(clk), .wea(wea[2]), .addra(index), .dina(data_i[2]), .douta(word_o[2]));
    data_ram_32x512 w3 (.clka(clk), .wea(wea[3]), .addra(index), .dina(data_i[3]), .douta(word_o[3]));
    data_ram_32x512 w4 (.clka(clk), .wea(wea[4]), .addra(index), .dina(data_i[4]), .douta(word_o[4]));
    data_ram_32x512 w5 (.clka(clk), .wea(wea[5]), .addra(index), .dina(data_i[5]), .douta(word_o[5]));
    data_ram_32x512 w6 (.clka(clk), .wea(wea[6]), .addra(index), .dina(data_i[6]), .douta(word_o[6]));
    data_ram_32x512 w7 (.clka(clk), .wea(wea[7]), .addra(index), .dina(data_i[7]), .douta(word_o[7]));
    
    // read policy //
    assign cpu_data_o = word_o[word_offset];
    assign mem_data_o = {word_o[7],word_o[6],word_o[5],word_o[4],word_o[3],word_o[2],word_o[1],word_o[0]};
    
    //reset發生時，不清空(直接將valid改成0就好)
    
endmodule
