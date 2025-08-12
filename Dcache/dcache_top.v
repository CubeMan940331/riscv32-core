`timescale 1ns / 1ps

module dcache_top(
	input clk,
	input rst_n,
	
	// LSU interface //
	input [17:0] tag_i,
	input [8:0] idx_i,
	input [2:0] word_offset_i,
	input [3:0] mask,
	input [31:0] data_i,
	input req_wr,
	input req_rd,
	
	output [31:0]data_o,
	output stall_cpu,
	output cache_available
);
 
    // Memory interface signals
    wire mem_available;
    wire [255:0] mem_data_i;
    wire wr_mem_done;
    wire rd_mem_done;
    wire req_wr_mem;
    wire req_rd_mem;
    wire [31:0] addr_o;
    
    // Output signals
    wire [255:0] mem_data_o;

    //-------------------------------------------
    // Design instantiation
    //-------------------------------------------
    d_cache32Bx512x2w u_cache (
        .clk(clk),
        .rst_n(rst_n),
        .tag_i(tag_i),
        .idx_i(idx_i),
        .word_offset(word_offset_i),
        .cpu_data_i(data_i),
        .mask(mask),
        .cpu_req_wr(req_wr),
        .cpu_req_rd(req_rd),
        .mem_available(mem_available),
        .mem_data_i(mem_data_i),
        .wr_mem_done(wr_mem_done),
        .rd_mem_done(rd_mem_done),
        .req_wr_mem(req_wr_mem),
        .req_rd_mem(req_rd_mem),
        .addr_o(addr_o),
        .cpu_data_o(data_o),
        .mem_data_o(mem_data_o),
        .signal_stall(stall_cpu),
        .cache_available(cache_available)
    );
    
    //-------------------------------------------
    // Pseudo-memory model
    //-------------------------------------------
    pseudo_mem u_mem (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr_o[31:5]),
        .data_i(mem_data_o),
        .wr_req(req_wr_mem),
        .rd_req(req_rd_mem),
        .mem_available(mem_available),
        .wr_done(wr_mem_done),
        .rd_done(rd_mem_done),
        .data_o(mem_data_i)
    );

   
endmodule

//-------------------------------------------
// Simplified pseudo-memory model (immediate response version)
//-------------------------------------------
module pseudo_mem(
    input clk,
    input rst_n,
    input [26:0] addr,
    input [255:0] data_i,
    input wr_req,
    input rd_req,
    output reg mem_available,
    output reg wr_done,
    output reg rd_done,
    output reg [255:0] data_o
);
    reg [255:0] mem [0:2047];
    reg [1:0] wr_cnt;
    reg [1:0] rd_cnt;

    integer i;
    always @(posedge clk or negedge rst_n) begin
		data_o <= 0;
        if (!rst_n) begin
            for (i = 0; i < 2048; i = i + 1) begin
                mem[i] <= 0;
            end
            wr_cnt <= 0;
            rd_cnt <= 0;
            mem_available <= 1;
        end
        else if (wr_req) begin
            mem_available <= 0;
            mem[addr] <= (wr_cnt == 0) ? data_i : mem[addr];
            wr_cnt <= wr_cnt + 1;
        end
        else if (rd_req) begin
            data_o <= mem[addr];
            mem_available <= 0;
            rd_cnt <= rd_cnt + 1;
        end
        else begin 
            mem_available <= 1;
            wr_cnt <= 0;
            rd_cnt <= 0;
        end
    end
    
    always @(*) begin
        if (rd_cnt == 2)
            rd_done = 1;
        else if (wr_cnt == 3)
            wr_done = 1;
        else
            {rd_done, wr_done} = 0;
    end
endmodule