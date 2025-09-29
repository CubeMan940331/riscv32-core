`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 20:38:40
// Design Name: 
// Module Name: new_dcache
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


module new_dcache(
    input clk,
    input rst_n,
    
	// cpu interface //
    input [17:0]tag_i,
    input [8:0]idx_i,
    input [2:0]word_ofs_i,
    input [31:0]cpu_data_i,
    input [3:0]mask_i,
    input cpu_req_wr,
    input cpu_req_rd,
	output reg [31:0]cpu_data_o,
    output dcache_rdy_o, 
	
	// MMU interface
	input invalidate_i,
	input flush_i, 
	input writeback_i,

	// mem interface //
	input mem_init_complete_i,
    input mem_rdy_i, 
	input [255:0]mem_data_i, 
	output reg wr_mem_end_o,
	input rd_mem_end_i,
    output reg req_wr_mem,
    output reg req_rd_mem,
    output reg [31:0]mem_addr_o,
    output reg [255:0]mem_data_o
);  
    
    
	// way parameter //
	wire [17:0] tag_0,tag_1;
    reg [1:0]cpu_wr;
    reg [1:0]mem_wr;  
	reg [1:0]wr_vld;
	reg [1:0]wr_dty;
	reg vld_i;
	reg dty_i;
	wire dty_0,dty_1;
    reg [17:0]cache_tag_i;
    reg [8:0]cache_idx_i;
    reg [2:0]cache_ofs_i; 
	reg [3:0]cache_mask;
    reg [31:0]cache_cpu_data_i;
    reg [255:0]cache_mem_data_i;
    
    wire [31:0]cpu_data_o1,cpu_data_o0;
    wire [255:0]mem_data_o1,mem_data_o0;
	
	// hold signal //
	reg hold_cpu_wr;
    reg [17:0]hold_tag_i;
    reg [8:0]hold_idx_i;
    reg [2:0]hold_word_ofs;
    reg [31:0]hold_data_i;
    reg [3:0]hold_mask;
	
    // replacement related parameter  //
    wire lru;
	reg do_lru;
    wire is_dty = lru ? dty_1 : dty_0;

    // hit_miss & replacement policy //
	wire vld_0,vld_1;
    wire match1 = vld_1 & (tag_i == tag_1);
    wire match0 = vld_0 & (tag_i == tag_0);
	wire match = match0 | match1;
	wire comp_mode = (~(flush_i | invalidate_i)) & (cpu_req_rd | cpu_req_wr); 
    wire hit =  comp_mode & match;
	
    
	//為了解決CDC問題，應該用另一個submodule來處理
    // FSM parameter //
	parameter INIT = 0;    // wait for DDR2 activation
    parameter IDLE = 1;    // decide hit when cpu rd/wr or don't do anything when cpu doesn't give command
	parameter WM = 2;      // 
	//parameter WMEND = 3;
	parameter RM = 4;
	parameter RMEND = 5;
	parameter RECOMP = 6;  // Recompare when miss
	parameter WMALL = 7;   // WB ALL dirty data blocks when flush
	//parameter WMALLEND = 8;
	//parameter ABANDON = 9; // CLEAN the cache line when invalidate
    reg [2:0]cs, ns;
	
	//reg wm_all_end;
	//reg clean_end;
	reg do_wb;

	// decide write mem;
	reg [9:0]dcache_cnt;
	reg skip_wb;
	
	// signal hold //
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			hold_cpu_wr      <= 0;
			hold_tag_i       <= 0;
			hold_idx_i       <= 0;
			hold_word_ofs	 <= 0;
			hold_data_i      <= 0;
			hold_mask        <= 0;end
		else if(cs == IDLE)begin //或用 state判斷???
			hold_cpu_wr      <=  cpu_req_wr;
            hold_tag_i       <=  tag_i;
            hold_idx_i       <=  idx_i;
            hold_word_ofs <=  word_ofs_i;
            hold_data_i      <=  cpu_data_i;
            hold_mask        <=  mask_i; end
        else begin
			hold_cpu_wr      <=  hold_cpu_wr;
            hold_tag_i       <=  hold_tag_i;
            hold_idx_i       <=  hold_idx_i;
            hold_word_ofs <=  hold_word_ofs;
            hold_data_i      <=  hold_data_i;
            hold_mask        <=  hold_mask; end
    end
    
    // state control //
    always@(posedge clk or negedge rst_n)begin //state update
        if(!rst_n)
            cs <= 0;
        else
            cs <= ns;
    end
	
	// state transfer //
    always@(*)begin
		case(cs)
			INIT : 	if(mem_init_complete_i)
						ns = IDLE;
					else
						ns = INIT;
			IDLE :  if(flush_i)
						ns = WMALL;
					else if(invalidate_i)
						ns = IDLE;
					else if(writeback_i)
						ns = WM;
					else if(!comp_mode)
						ns = IDLE;
					else if(hit)
						ns = IDLE;
					else if(is_dty)
						ns = WM;
					else
						ns = RM;
			WM : 	if(mem_rdy_i)
						ns = do_wb ? IDLE : RM;
					else
						ns = WM;
			RM : 	if(mem_rdy_i)
						ns = RMEND;
					else
						ns = RM;
			RMEND : if(rd_mem_end_i)
						ns = RECOMP;
					else 
						ns = RMEND;
			RECOMP: if(flush_i)
						ns = WMALL;
					else
						ns = IDLE;
			WMALL :	if(mem_rdy_i)
						ns = wr_mem_end_o ? IDLE : WMALL;
					else
						ns = WMALL;
			default:ns = IDLE;
		endcase
	end
	
	//////////////////////////////////////
	// Define all behavior of any state //
	//////////////////////////////////////
	
	// define cache rd/wr
	always@(*)begin
		if(cs==IDLE)begin
			if(hit)begin
				cpu_wr = cpu_req_wr ? (match0 ? 2'b01 : 2'b10) : 2'b00; 
				cpu_data_o = match0 ? cpu_data_o0 : cpu_data_o1; 
				do_lru = 1; end 
			else begin
				cpu_wr = 0; 
				cpu_data_o = 0; 
				do_lru = 0; end
		end
		else if(cs==RECOMP)begin
				cpu_wr = hold_cpu_wr ? (match0 ? 2'b01 : 2'b10) : 2'b00; 
				cpu_data_o = match0 ? cpu_data_o0 : cpu_data_o1; 
				do_lru = 1; end 
		else begin
				cpu_wr = 0; 
				cpu_data_o = 0; 
				do_lru = 0; end	
	end
	
	// Define cache input
	always@(*)begin
		if(cs == IDLE)begin
			cache_tag_i = tag_i;
			cache_idx_i = idx_i;
			cache_ofs_i = word_ofs_i;
			cache_mask = mask_i;
			cache_cpu_data_i = cpu_data_i;end
		else if(cs == WM)begin
			cache_tag_i = 0;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end
		// else if(cs == WMEND)begin
			// cache_tag_i = 0;
			// cache_idx_i = hold_idx_i;
			// cache_ofs_i = 0;
			// cache_mask = 0;
			// cache_cpu_data_i = 0;end
		else if(cs == RM)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end
		else if(cs == RMEND)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end	
		else if(cs == RECOMP)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = hold_word_ofs;
			cache_mask = hold_mask;
			cache_cpu_data_i = hold_data_i;end
		else if(cs == WMALL)begin
			cache_tag_i = 0;
			cache_idx_i = dcache_cnt[9:1];
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end
		// else if(cs == ABANDON)begin
			// cache_tag_i = 0;
			// cache_idx_i = hold_idx_i;
			// cache_ofs_i = 0;
			// cache_mask = 0;
			// cache_cpu_data_i = 0;end
		else begin
			cache_tag_i = 0;
			cache_idx_i = 0;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end	
	end

	// define read request //
	always@(*)begin
		if(cs == RM)
			req_rd_mem = 1;
		else 
			req_rd_mem = 0;
	end
		
	// decide read mem 
	always@(*)begin
		if(cs == RMEND)begin
			cache_mem_data_i = rd_mem_end_i ? mem_data_i : 0;
			mem_wr = rd_mem_end_i ? (lru ? 2'b10 : 2'b01) : 2'b00; end
		else  begin
			mem_wr = 0;
			cache_mem_data_i = 0; end
	end
	
	// define wb situation //
	always@(posedge clk)begin //or change to combinational
		if(cs == IDLE)
			do_wb = writeback_i ? 1 : 0;
		else
			do_wb = do_wb; 
	end
	
	// decide write mem;
	always@(posedge clk)begin
		if(cs == WMALL)
			dcache_cnt = (mem_rdy_i | skip_wb) ? dcache_cnt +1 :dcache_cnt;
		else
			dcache_cnt = 0;
	end
	
	// output to mem control
	wire wm_all_vld = dcache_cnt[0]? vld_1 : vld_0;
	wire wm_all_dty = dcache_cnt[0]? dty_0 : dty_1;
	always@(*)begin
		wr_mem_end_o = 0;
		if(cs == WM)begin
			wr_mem_end_o = 1;
			req_wr_mem = 1;
			skip_wb = 0;
			mem_addr_o = {lru? tag_1[12:0] : tag_0[12:0], hold_idx_i,5'd0};
			mem_data_o = lru ? mem_data_o1 : mem_data_o0; end
		// else if(cs == WMEND)begin
			// wr_mem_end_o = 1;
			// req_wr_mem = 1;
			// skip_wb = 0;
			// mem_addr_o = {lru? tag_1 : tag_0, hold_idx_i,5'd16};
			// mem_data_o = lru ? mem_data_o1[255:128] : mem_data_o0[255:128];	end		
		else if(cs == WMALL)begin
			mem_addr_o = {{dcache_cnt[0] ? tag_1[12:0] : tag_0[12:0]},dcache_cnt[9:1],dcache_cnt[0] ? 5'd16 : 5'd0};
			mem_data_o = dcache_cnt[0] ? mem_data_o1 : mem_data_o0;
			if(!wm_all_vld)begin
				skip_wb = 1;
				req_wr_mem = 0;
				wr_mem_end_o = 0; end
			else if(!wm_all_dty)begin
				skip_wb = 1;
				req_wr_mem = 0;
				wr_mem_end_o = 0; end
			else begin
				skip_wb = 0;
				req_wr_mem = 1;
				if(dcache_cnt == 1023)
					wr_mem_end_o = 1; end
		end 
		else begin
			skip_wb = 0;
			req_wr_mem = 0;
			mem_addr_o = 0;
			mem_data_o = 0;
			wr_mem_end_o = 0;end
	end
	
	// output to cpu control
	assign dcache_rdy_o = (ns == IDLE);
	
	
	// control vld&dirty of cache
	always@(*)begin
		if(cs == IDLE)begin
			if(invalidate_i)begin
				if(match)begin
					wr_vld = match0 ? 2'b01 : 2'b10;
					vld_i = 1;
					wr_dty = 1;
					dty_i = 0; end
				else begin
					wr_vld = 0;
					vld_i = 0;
					wr_dty = 0;
					dty_i = 0; end	
			end
			else if(hit)begin
				wr_vld = 0;
				vld_i = 0;
				wr_dty = cpu_wr;
				dty_i = 1; end
			else begin
				wr_vld = 0;
				vld_i = 0;
				wr_dty = 0;
				dty_i = 0; end
		end
		else if(cs == WM)begin 
			wr_vld = 0;
			vld_i = 0;
			wr_dty = lru ? 2'b10 : 2'b01;
			dty_i =  0; end	
		else if(cs == RMEND)begin
			wr_vld = mem_wr;
			vld_i = 1;
			wr_dty = lru ? 2'b10 : 2'b01;
			dty_i =  0; end
		else if(cs == WMALL)begin
			if(!skip_wb)begin
				wr_vld = mem_rdy_i ? (dcache_cnt[0] ? 2'b10 : 2'b01) : 2'b00;
				vld_i =  0;
				wr_dty = 0;
				dty_i =  0; end				
			else begin
				wr_vld = dcache_cnt[0] ? 2'b10 : 2'b01;
				vld_i =  0;
				wr_dty = 0;
				dty_i =  0; end			
		end
		else begin
				wr_vld = 0;
				vld_i =  0;
				wr_dty = 0;
				dty_i =  0; end
	end

	
	
    // instance construction //
    lru_1b lru_arr(clk, do_lru, cache_idx_i, lru);
	
    way_32Bx512 way0(
        .clk(clk),
        .cpu_wr(cpu_wr[0]),
        .mem_wr(mem_wr[0]),
		.wr_vld(wr_vld[0]),
		.wr_dty(wr_dty[0]),
		.vld_i(vld_i),
		.dty_i(dty_i),
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
        .cpu_wr(cpu_wr[1]),
        .mem_wr(mem_wr[1]),
		.wr_vld(wr_vld[1]),
		.wr_dty(wr_dty[1]),
		.vld_i(vld_i),
		.dty_i(dty_i),
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
