`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 20:45:30
// Design Name: 
// Module Name: new_icache
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


module new_icache(
    input clk,
    input rst_n,
    input [18:0]tag_i,
    input [7:0]idx_i,
    input [4:0]ofs_i,
    input invalidate_i,
    output reg icache_rdy_o,
    output reg [31:0]cpu_inst_o,
	
	// mem interface
    input [255:0]mem_data_i,
    input mem_rdy_i,
	input mem_init_complete_i,
    input rd_mem_end_i,
    output reg req_rd_mem_o,
    output reg [31:0]mem_addr_o
);
    
    // parameter def //
    reg fifo_en;
	wire fifo;
    reg wr0,wr1;
    reg [255:0]mem_data;
	wire [31:0]cpu_inst_0,cpu_inst_1;
    
    // hit_miss & replacement policy //
    reg comp_mode;
	wire [18:0]tag_0,tag_1;
	wire vld_0,vld_1;
    wire match1 = vld_1 & (tag_i == tag_1);
    wire match0 = vld_0 & (tag_i == tag_0);
    wire hit = comp_mode & (match1 | match0);
    reg vld_i;
    
    // FSM //
    parameter IDLE = 0, UPDATE = 1;
    reg cs,ns;
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            cs <= IDLE;
        else if(mem_init_complete_i)
            cs <= ns;
		else 
			cs <= IDLE;
    end
    
    always@(*)begin
        comp_mode = 0;
        cpu_inst_o = 0;
        fifo_en = 0;
        mem_addr_o = 0;
        icache_rdy_o = 1;
        req_rd_mem_o = 0;
		mem_data = 0;
		wr1 = 0;
		wr0 = 0;
		ns = 0;
		vld_i = 1;
        case(cs)
            IDLE : begin
				comp_mode = 1;
				if(invalidate_i)begin
				    ns = IDLE;
				    vld_i = 0;
				    if(match0|match1)
				        {wr1,wr0} = match1 ? 2'b10 : 2'b01;
				    else
				        {wr1,wr0} = 2'b00;
				end
				else if(hit)begin
					ns = IDLE;
					cpu_inst_o = match0 ? cpu_inst_0 : cpu_inst_1; end
				else begin
					if(mem_rdy_i)begin
						ns = UPDATE;
						icache_rdy_o = 0;
						req_rd_mem_o = 1;
						mem_addr_o = {tag_i, idx_i, 5'd0}; end
					else begin
						ns = IDLE;
						icache_rdy_o = 0; end
				end
            end
            UPDATE : begin
				icache_rdy_o = 0;
				mem_addr_o = {tag_i, idx_i, 5'd0};
				if(rd_mem_end_i)begin
					mem_data = mem_data_i;
					{wr1,wr0} = fifo ? 2'b10 : 2'b01;
					fifo_en = 1;
					ns = IDLE; end
				else
					ns = UPDATE; 
            end
        endcase
    end
                
    
        // Instance construction //
    fifo_block1bx256 f0(.clk(clk), .en(fifo_en), .index(idx_i), .fifo(fifo));    

    way_32Bx256 w0(
        .clk(clk),
        .write(wr0),
        .tag_i(tag_i),
        .index(idx_i),
        .word_offset(ofs_i[4:2]),
        .mem_data(mem_data),
        .vld_i(vld_i),
        .tag_o(tag_0),
        .cpu_inst_o(cpu_inst_0),
        .vld_o(vld_0)
    );
    
    way_32Bx256 w1(
        .clk(clk),
        .write(wr1),
        .tag_i(tag_i),
        .index(idx_i),
        .word_offset(ofs_i[4:2]),
        .mem_data(mem_data),
        .vld_i(vld_i),
        .tag_o(tag_1),
        .cpu_inst_o(cpu_inst_1),
        .vld_o(vld_1)
    );
    
endmodule
