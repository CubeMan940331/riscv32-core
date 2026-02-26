`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/20 23:14:19
// Design Name: 
// Module Name: dcache_plus
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


module dcache_plus(
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
	output reg exception,
	input except_complete,
	
	// MMU interface
	input invalidate_i,
	input flush_i,
	input writeback_i,
	
	// mem interface //
	output reg [31:0] mem_addr,
	// AR, R
    input rm_rdy,
	input [255:0]rm_data,
	input rm_success,
	input rm_complete,
	output reg rm_vld,
	
	// AW, W
	input wm_rdy,
    output reg [255:0]wm_data,
    output reg wm_vld,
    
    //B
    input wm_success,
    input wm_complete 
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
    reg hold_wb;
	
    // replacement related parameter  //
    wire lru;
	reg do_lru;
    wire is_dty = lru ? dty_1 : dty_0;

    // hit_miss & replacement policy //
    reg [1:0]vld_out_data;
	wire vld_0,vld_1;
    wire match1 = vld_1 & (tag_i == tag_1);
    wire match0 = vld_0 & (tag_i == tag_0);
	wire match = match0 | match1;
	wire comp_mode = cpu_req_rd | cpu_req_wr; 
    wire hit =  comp_mode & match;
	
    
    // FSM parameter //
    parameter IDLE = 0;    // decide hit when cpu rd/wr or don't do anything when cpu doesn't give command
	parameter WM = 1;      // 
	parameter WMEND = 2;
	parameter RM = 3;
	parameter RMEND = 4;
	parameter EXP = 5;
	parameter RECOMP = 6;  // Recompare when miss
	parameter WM_ALL = 7;   // WB ALL dirty data blocks when flush
	parameter WM_ALL_END = 8;
	parameter WM_ALL_SET = 9;

    reg [3:0]cs, ns;
    
    reg [9:0]wmall_cnt;
    reg skip_wb;
	
	// signal hold //
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			hold_cpu_wr      <= 0;
			hold_tag_i       <= 0;
			hold_idx_i       <= 0;
			hold_word_ofs	 <= 0;
			hold_data_i      <= 0;
			hold_wb          <= 0;
			hold_mask        <= 0;end
		else if(cs == IDLE)begin 
			hold_cpu_wr      <=  cpu_req_wr;
            hold_tag_i       <=  tag_i;
            hold_idx_i       <=  idx_i;
            hold_word_ofs <=  word_ofs_i;
            hold_data_i      <=  cpu_data_i;
            hold_wb          <=  writeback_i;
            hold_mask        <=  mask_i; end
        else begin
			hold_cpu_wr      <=  hold_cpu_wr;
            hold_tag_i       <=  hold_tag_i;
            hold_idx_i       <=  hold_idx_i;
            hold_word_ofs <=  hold_word_ofs;
            hold_data_i      <=  hold_data_i;
            hold_wb          <= hold_wb;
            hold_mask        <=  hold_mask; end
    end
    
    // state control //
    always@(posedge clk or negedge rst_n)begin //state update
        if(!rst_n)
            cs <= 0;
        else
            cs <= ns;
    end
    
    
    
	// state transfer & cache update//
    always@(*)begin
        do_lru = 0;
        vld_i = 0;
        wr_vld = 2'b00;
        cpu_wr = 2'b00;
        dty_i = 0;
        wr_dty = 2'b00;
        mem_wr = 2'b00;
        ns = IDLE;
        exception = 0;
		case(cs)
			IDLE :  if(flush_i)
						ns = WM_ALL_SET;
					else if(invalidate_i) begin //update cache
						ns = IDLE;
						if(match)begin
                            wr_vld = match0 ? 2'b01 : 2'b10;
                            vld_i = 1;
                            wr_dty = 1;
                            dty_i = 0;
                        end
					end
					else if(writeback_i)
						ns = WM;
					else if(!comp_mode)
						ns = IDLE;
					else if(hit)begin //update lru& cache
						ns = IDLE;
						do_lru = 1;
						cpu_wr = match0 ? {1'b0,cpu_req_wr} : {cpu_req_wr,1'b0};
						dty_i = cpu_req_wr;
						wr_dty = cpu_wr;
					end
					else if(is_dty)
						ns = WM;
					else
						ns = RM;
			WM : 	if(wm_rdy)
						ns = WMEND;
					else
						ns = WM;
			WMEND: 	if(wm_complete & wm_success)begin //update cache block&status
						ns = hold_wb ? IDLE : RM;
						dty_i = 0;
						wr_dty = lru ? 2'b10 : 2'b01;
					end
				    else if(wm_complete & ~wm_success)
				        ns = EXP;
					else
						ns = WMEND;
			RM : 	if(rm_rdy)
						ns = RMEND;
					else
						ns = RM;
			RMEND : if(rm_complete & rm_success)begin
						ns = RECOMP;
					    mem_wr = lru ? 2'b10 : 2'b01;
						wr_dty = mem_wr;
						wr_vld = mem_wr;
						vld_i = 1;
					end
				    else if(rm_complete ^ rm_success)
				        ns = EXP;
					else 
						ns = RMEND;
			RECOMP: begin
			            ns = IDLE;
                        cpu_wr = hold_cpu_wr ? (match0 ? 2'b01 : 2'b10) : 2'b00; 
                        do_lru = 1;
			        end                
		    WM_ALL_SET :                     
                    if(skip_wb)begin
			            ns = (wmall_cnt==1023) ?  IDLE : WM_ALL_SET;
						wr_dty = wmall_cnt[0] ? 2'b10 : 2'b01;
						wr_vld = wr_dty;
						vld_i = 0;
					end
					else
						ns = WM_ALL;
			WM_ALL :if(wm_rdy)
			            ns = WM_ALL_END;
					else
						ns = WM_ALL;
		    WM_ALL_END : 
                    if(wm_complete & wm_success) begin
						ns = (wmall_cnt==1023)? IDLE : WM_ALL_SET;
						wr_dty = wmall_cnt[0] ? 2'b10 : 2'b01;
						wr_vld = wr_dty;
						vld_i = 0;					
					end
				    else if(wm_complete & ~wm_success)
				        ns = EXP;
					else
						ns = WM_ALL_END;
		    EXP   : begin    
		                ns = except_complete ? IDLE : EXP;
		                exception = 1;
		            end
			default:ns = IDLE;
		endcase
	end

    
	// Define cache input
	always@(*)begin
		if(cs == IDLE)begin
			cache_tag_i = tag_i;
			cache_idx_i = idx_i;
			cache_ofs_i = word_ofs_i;
			cache_mask = mask_i;
			cache_mem_data_i = 0;
			cache_cpu_data_i = cpu_data_i;end
		else if(cs == WM)begin //RO cache, tag & data
			cache_tag_i = 0;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_mem_data_i = 0;
			cache_cpu_data_i = 0;end
		else if(cs == WMEND)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mem_data_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end
		else if(cs == RM)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mem_data_i = 0;
			cache_mask = 0;
			cache_cpu_data_i = 0;end
		else if(cs == RMEND)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_mem_data_i = rm_data;
			cache_cpu_data_i = 0;end	
		else if(cs == RECOMP)begin
			cache_tag_i = hold_tag_i;
			cache_idx_i = hold_idx_i;
			cache_ofs_i = hold_word_ofs;
			cache_mask = hold_mask;
			cache_mem_data_i = 0;
			cache_cpu_data_i = hold_data_i;end
		else if(cs == WM_ALL_SET)begin
			cache_tag_i = 0;
			cache_idx_i = wmall_cnt[9:1];
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_mem_data_i = 0;
			cache_cpu_data_i = 0;end
		else if(cs == WM_ALL)begin
			cache_tag_i = 0;
			cache_idx_i = wmall_cnt[9:1];
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_mem_data_i = 0;
			cache_cpu_data_i = 0;end
		else if(cs == WM_ALL_END)begin
			cache_tag_i = 0;
			cache_idx_i = wmall_cnt[9:1];
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_mem_data_i = 0;
			cache_cpu_data_i = 0;end
		else begin
			cache_tag_i = 0;
			cache_idx_i = 0;
			cache_ofs_i = 0;
			cache_mask = 0;
			cache_mem_data_i = 0;
			cache_cpu_data_i = 0;end	
	end
	
	// cnt
	always@(posedge clk or negedge rst_n)begin
	   if(!rst_n)begin
	       wmall_cnt <= 0;
	   end
	   else if(WM_ALL_SET)begin
	       wmall_cnt <= skip_wb ? wmall_cnt + 1 : wmall_cnt ;
	   end
	   else if(WM_ALL_END)
	       wmall_cnt <= (wm_complete & wm_success) ? wmall_cnt + 1 : wmall_cnt ;
	   else
	       wmall_cnt <= 0;
	end
	
	always@(*)begin
	       skip_wb = wmall_cnt[0] ? dty_1 : dty_0;
	end
	
	// WM/RM setting
	always@(*)begin
       rm_vld = 0;
       wm_vld = 0;
       wm_data = 0;
       mem_addr = 0;
	   if(cs == WM)begin
	       wm_vld = 1;
	       wm_data = lru ? mem_data_o1 : mem_data_o0;
	       mem_addr = {lru? tag_1 : tag_0, hold_idx_i,5'd0};
	   end
	   else if(cs == WM_ALL)begin
	       wm_vld = 1;
	       wm_data = wmall_cnt[0] ? mem_data_o1 : mem_data_o0;
	       mem_addr = {{wmall_cnt[0] ? tag_1 : tag_0},wmall_cnt[9:1],5'd0};
	   end
	   else if(cs == RM)begin
	       rm_vld = 1;
	       mem_addr = {cache_tag_i,cache_idx_i,5'd0};
	   end
    end
    
    assign dcache_rdy_o = (cs == IDLE);
    
    //cpu data out
    //always@(*)begin
    //    cpu_data_o = match0 ? cpu_data_o0 : cpu_data_o1; 
    //end
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            vld_out_data <= 0;
        else if(cs == IDLE)
            vld_out_data <= hit ? {match1, match0} : 0;
        else if(cs == RECOMP)
            vld_out_data <= {match1, match0};
    end
    
    always@(*)begin
        if(vld_out_data[0])
            cpu_data_o = cpu_data_o0;
        else if(vld_out_data[1])
            cpu_data_o = cpu_data_o1;
        else
            cpu_data_o = 0;
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
