`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/20 14:13:53
// Design Name: 
// Module Name: dcache_dma_ctrl
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


module dcache_dma_ctrl(

	// cpu interface //
    input cpu_req_wr_i,
    input cpu_req_rd_i,
	
	// MMU interface
    input cacheable_i,
    
    // dma interface
    output reg req_wr_dma,
    output reg req_rd_dma,
    
    // dcache to axi bus interface
    output reg req_wr_d,
    output reg req_rd_d
);  
    always@(*)begin
        req_wr_d <= 0;
        req_rd_d <= 0;
        req_wr_dma <= 0;
        req_rd_dma <= 0;
        if(cacheable_i)begin
            req_wr_d <= cpu_req_wr_i;
            req_rd_d <= cpu_req_rd_i;
        end
        else begin
            req_wr_dma <= cpu_req_wr_i;
            req_rd_dma <= cpu_req_rd_i;
        end
    end

    
    
endmodule
