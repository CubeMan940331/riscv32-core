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
    
    //I cache interface
    input i_claim,
    output reg d_claim,
    
    output [2:0]dcs ,
    
    // mem interface //
    input mem_available,
    input wr_mem_available,
    output reg wr_mem_end,
	input [127:0]mem_data_i,
	input rd_mem_done,
	input mem_rd_data_rdy,
	output reg app_en,
    output reg req_wr_mem,
    output reg req_rd_mem,
    output reg [26:0]addr_o,
    output reg [127:0]mem_data_o
);  
    // parameter difinition //
    wire [17:0] tag_0,tag_1;
    wire lru;
    reg comp_mode;
    reg [1:0]cpu_wr;
    reg [1:0]mem_wr;  
	wire dty_0,dty_1;
    wire is_dty = lru ? dty_1 : dty_0;
    reg d_req;
    
    reg [17:0]cache_tag_i;
    reg [8:0]cache_idx_i;
    reg [2:0]cache_ofs_i; 
	reg [3:0]cache_mask;
    
    reg [31:0]cache_cpu_data_i;
    reg [255:0]cache_mem_data_i;
    reg [127:0]mem_temp;
    
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
    parameter IDLE = 0, WM1 = 1, WM2 = 2, WR = 3, RM1 = 4, RM2 = 5, COMP = 6;
    reg [2:0]cs, ns;
    
    assign dcs = cs;
    
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
		d_claim = 0;
		app_en = 0;
		mem_temp = mem_temp;
		wr_mem_end = 0;
        case(cs)
            IDLE : begin
                mem_temp = 0;
                if(cpu_req_wr | cpu_req_rd)begin
                    comp_mode = 1;
                    if(hit)begin
                        ns = IDLE;
                        cpu_wr = cpu_req_wr ? (match0 ? 2'b01 : 2'b10) : 2'b00; 
						cpu_data_o = match0 ? cpu_data_o0 : cpu_data_o1; end        
					else begin
					   if((!mem_available)|(i_claim))begin
					        ns = IDLE;
                            signal_stall = 1; end
                        else if(is_dty)begin
                            d_claim = 1;
                            ns = WM1;
							addr_o = {lru? tag_1 : tag_0, idx_i,5'd0};
                            cache_available = 0;
                            req_wr_mem = 0; end
                        else begin
                            d_claim = 1;
                            ns = RM1;
                            cache_available = 0;
							mem_wr = lru ? 2'b10 : 2'b01;
                            req_rd_mem = 1;
                            addr_o = {tag_i , idx_i,5'd0}; end
                    end
                end else
                    ns <= IDLE;
            end
            WM1 : begin
                req_wr_mem = 0;
                d_claim = 1;
                cache_available = 0;
				cache_idx_i = hold_idx_i;
				addr_o = {lru? tag_1 : tag_0, hold_idx_i,5'd0};
				mem_data_o = lru ? mem_data_o1[127:0] : mem_data_o0[127:0];
				if(mem_available)begin
					ns = WM2;
					app_en = 1;
                    addr_o = {lru? tag_1 : tag_0, hold_idx_i,5'd16};
                    mem_data_o = lru ? mem_data_o1[255:128] : mem_data_o0[255:128];
					req_wr_mem = 1; end
				else begin
                    ns = WM1; end
            end
            WM2 : begin
                req_wr_mem = 0;
                d_claim = 1;
                cache_available = 0;
				cache_idx_i = hold_idx_i;
				addr_o = {lru? tag_1 : tag_0, hold_idx_i,5'd16};
				mem_data_o = lru ? mem_data_o1[255:128] : mem_data_o0[255:128];
				if(wr_mem_available & mem_available)begin
					ns = WR;
					app_en = 0;
					wr_mem_end = 1;
					req_wr_mem = 1; end
				else begin
                    ns = WM2; end
            end
            WR : begin
				d_claim = 1;
				cache_available = 0;
				cache_tag_i = hold_tag_i;
				cache_idx_i = hold_idx_i;
				addr_o = {hold_tag_i, hold_idx_i, 5'd0};
                if (!mem_available) begin
                    ns = WR;
                end else begin
                    req_rd_mem = 1;
                    app_en = 1;
                    ns = RM1;
                end
            end
			RM1 : begin
				d_claim = 1;
				cache_available = 0;
				cache_tag_i = hold_tag_i;
				cache_idx_i = hold_idx_i;
				addr_o = {hold_tag_i, hold_idx_i, 5'd16};
				if(mem_rd_data_rdy && rd_mem_done)begin
                    if (mem_available) begin
                        req_rd_mem = 1;
                        app_en = 1;
                        ns = RM2;
                    end else begin
                        ns = RM1;
                    end
					mem_temp = mem_data_i; end
				else
					ns = RM1;
            end
			RM2 : begin
				d_claim = 1;
				cache_available = 0;
				cache_tag_i = hold_tag_i;
				cache_idx_i = hold_idx_i;
				addr_o = {hold_tag_i, hold_idx_i, 5'd16};
				if(mem_rd_data_rdy && rd_mem_done)begin
                    if (mem_available) begin
                        ns = COMP;
                        cache_mem_data_i = {mem_data_i, mem_temp};
					    mem_wr = lru ? 2'b10 : 2'b01; 
                    end else begin
                        ns = RM2;
                    end 
                end
				else
					ns = RM2;
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
