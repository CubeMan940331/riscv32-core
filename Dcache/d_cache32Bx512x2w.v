`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/17 11:03:47
// Design Name: 
// Module Name: d_cache32Bx512x2w
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


module d_cache32Bx512x2w(
    input clk,
    input rst_n,
    
	// cpu interface //
    input [17:0]tag_i,
    input [8:0]idx_i,
    input [2:0]word_offset,
    input [31:0]cpu_data_i,
    input [3:0]mask,
    
	
    input cpu_req_wr,
    input cpu_req_rd,
	output reg [31:0]cpu_data_o,
    output reg signal_stall,
    output reg cache_available,

	// mem interface //
    input mem_available,
	input [255:0]mem_data_i,
	input wr_mem_done,
	input rd_mem_done,
    output reg req_wr_mem,
    output reg req_rd_mem,
    output reg [31:0]addr_o,
    output reg [255:0]mem_data_o
);  
    // parameter difinition //
    wire [17:0] tag_0,tag_1;
    wire lru;
    reg comp_mode;
    reg [1:0]cpu_wr;
    reg [1:0]mem_wr;  
	wire dty_0,dty_1;
    wire is_dty = lru ? dty_1 : dty_0;
    
    reg [17:0]cache_tag_i;
    reg [8:0]cache_idx_i;
    reg [2:0]cache_ofs_i; 
	reg [3:0]cache_mask;
    
    reg [31:0]cache_cpu_data_i;
    reg [255:0]cache_mem_data_i;
    
	reg hold_cpu_wr;
    reg [17:0]hold_tag_i;
    reg [8:0]hold_idx_i;
    reg [2:0]hold_word_offset;
    reg [31:0]hold_data_i;
    reg [3:0]hold_mask;
    
    wire [31:0]cpu_data_o1,cpu_data_o0;
    wire [255:0]mem_data_o1,mem_data_o0;

    // hit_miss & replacement policy //
	wire vld_0,vld_1;
    wire match1 = vld_1 & (tag_i == tag_1);
    wire match0 = vld_0 & (tag_i == tag_0);
    wire hit = comp_mode & (match1 | match0);
    
    // FSM model //
    parameter IDLE = 0, WM = 1, RM = 2, COMP = 3;
    reg [1:0]cs, ns;
    
    // 注意data有1 cycle的latency //
    always@(posedge clk or negedge rst_n)begin //state update
        if(!rst_n)
            cs <= 0;
        else
            cs <= ns;
    end

	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			hold_cpu_wr      <= 0;
			hold_tag_i       <= 0;
			hold_idx_i       <= 0;
			hold_word_offset <= 0;
			hold_data_i      <= 0;
			hold_mask        <= 0;end
		else if(cs == IDLE)begin //或用 state判斷???
			hold_cpu_wr      <=  cpu_req_wr;
            hold_tag_i       <=  tag_i;
            hold_idx_i       <=  idx_i;
            hold_word_offset <=  word_offset;
            hold_data_i      <=  cpu_data_i;
            hold_mask        <=  mask; end
        else begin
			hold_cpu_wr      <=  hold_cpu_wr;
            hold_tag_i       <=  hold_tag_i;
            hold_idx_i       <=  hold_idx_i;
            hold_word_offset <=  hold_word_offset;
            hold_data_i      <=  hold_data_i;
            hold_mask        <=  hold_mask; end
    end

    
    always@(*)begin
        comp_mode = 0;
        cpu_wr = 0;
		mem_wr = 0;
        req_wr_mem = 0;
        req_rd_mem = 0;
        signal_stall = 0;
        cache_tag_i = tag_i;
        cache_idx_i = idx_i;
		cache_ofs_i = word_offset;
		cache_cpu_data_i = cpu_data_i;
		addr_o = 0;
		cache_mask = mask;
		cache_mem_data_i = mem_data_i;
        cache_available = 1;
		mem_data_o = 0;
		cpu_data_o = cpu_data_o0;
        case(cs)
            IDLE : begin
                if(cpu_req_wr | cpu_req_rd)begin
                    comp_mode = 1;
                    if(hit)begin
                        ns = IDLE;
                        cpu_wr = cpu_req_wr ? (match0 ? 2'b01 : 2'b10) : 2'b00; 
						cpu_data_o = match0 ? cpu_data_o0 : cpu_data_o1; end              
                    else if(is_dty)begin
                        if(mem_available)begin
                            ns = WM;
							addr_o = {lru? tag_1 : tag_0, idx_i,5'd0};
                            cache_available = 0;
                            req_wr_mem = 0; end
                        else begin
                            ns = IDLE;
                            signal_stall = 1; end
                    end 
                    else begin
                        if(mem_available)begin
                            ns = RM;
                            cache_available = 0;
							mem_wr = lru ? 2'b10 : 2'b01;
                            req_rd_mem = 1;
                            addr_o = {tag_i , idx_i,5'd0}; end
                        else begin
                            ns = IDLE;
                            signal_stall = 1; end
                    end
                end else
                    ns <= IDLE;
            end
            WM : begin
                req_wr_mem = 1;
                cache_available = 0;
				cache_idx_i = hold_idx_i;
				if(wr_mem_done)begin
					ns = RM;
					req_rd_mem = 1;
					addr_o = {hold_tag_i, hold_idx_i, 5'd0};
					req_wr_mem = 0; end
				else begin
					addr_o = {lru? tag_1 : tag_0, hold_idx_i,5'd0};
                    mem_data_o = lru ? mem_data_o1 : mem_data_o0;
                    ns = WM; end
            end
			RM : begin
				req_rd_mem = 1;
				cache_available = 0;
				cache_tag_i = hold_tag_i;
				cache_idx_i = hold_idx_i;
				addr_o = {hold_tag_i, hold_idx_i, 5'd0};
				if(rd_mem_done)begin
					cache_mem_data_i = mem_data_i;
					mem_wr = lru ? 2'b10 : 2'b01;
					ns = COMP; end
				else
					ns = RM;
            end
			COMP : begin
				comp_mode = 1;
				cache_available = 1;
				ns = IDLE;
				cpu_wr = hold_cpu_wr ? (match0 ? 2'b01 : 2'b10) : 2'b00; 
				cache_tag_i = hold_tag_i;
				cache_idx_i = hold_idx_i;
				cache_ofs_i = hold_word_offset;
				cache_mask = hold_mask;
				cache_cpu_data_i = hold_data_i;
				cpu_data_o = match0 ? cpu_data_o0 : cpu_data_o1; 
			end      
		endcase
	end
	
    // instance construction //
    lru_1b lru_arr(clk, hit, cache_idx_i, lru);
    way_32Bx512 way0(
        .clk(clk),
        .rst_n(rst_n),
        .cpu_wr(cpu_wr[0]),
        .mem_wr(mem_wr[0]),
        .mask(cache_mask),
        .tag_i(cache_tag_i),
        .index(cache_idx_i),
        .word_offset(cache_ofs_i),
        .cpu_data_i(cache_cpu_data_i),
        .mem_data_i(cache_mem_data_i),
        .cpu_data_o(cpu_data_o0),
        .mem_data_o(mem_data_o0),
        .vld_o(vld_0),
        .dty_o(dty_0),
        .tag_o(tag_0)
    );
    
    way_32Bx512 way1(
        .clk(clk),
        .rst_n(rst_n),
        .cpu_wr(cpu_wr[1]),
        .mem_wr(mem_wr[1]),
        .mask(cache_mask),
        .tag_i(cache_tag_i),
        .index(cache_idx_i),
        .word_offset(cache_ofs_i),
        .cpu_data_i(cache_cpu_data_i),
        .mem_data_i(cache_mem_data_i),
        .cpu_data_o(cpu_data_o1),
        .mem_data_o(mem_data_o1),
        .vld_o(vld_1),
        .dty_o(dty_1),
        .tag_o(tag_1)
    );
endmodule
