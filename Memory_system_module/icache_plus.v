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


module icache_plus(
    input clk,
    input rst_n,
    input [18:0]tag_i,
    input [7:0]idx_i,
    input [4:0]ofs_i,
    input invalidate_i,
    output icache_rdy_o, //給CPU端看的
    output reg [31:0]cpu_inst_o,
	output reg exception,
	input except_complete,
	
	// mem interface
	// R,RA
	input rm_rdy,
	output reg [31:0]mem_addr,
	input rm_success,
	input rm_complete,
	output reg req_rm,
	input [255:0]rm_data
);
    // parameter def //
    reg fifo_en;
	wire fifo;
    reg wr0,wr1;
    reg [255:0]mem_data;
	wire [31:0]cpu_inst_0,cpu_inst_1;
	wire [18:0]cache_tag;
	wire [7:0]cache_idx;
	wire [4:0]cache_ofs;
    
    // hit_miss & replacement policy //
    reg [1:0]vld_out_inst;
	wire [18:0]tag_0,tag_1;
	wire vld_0,vld_1;
    wire match1 = vld_1 & (tag_i == tag_1);
    wire match0 = vld_0 & (tag_i == tag_0);
    wire hit = (match1 | match0);
    reg vld_i;
    reg wr_vld0,wr_vld1;
    
    // FSM //
    parameter IDLE = 0, RM = 1, UPDATE = 2, EXP = 3;
    reg [1:0] cs;
    
    assign icache_rdy_o = (cs == IDLE);
    assign cache_tag = (cs == IDLE) ? tag_i : mem_addr[31:13];
    assign cache_idx = (cs == IDLE) ? idx_i : mem_addr[12:5];
    assign cache_ofs = (cs == IDLE) ? ofs_i : mem_addr[4:0];
    
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            cs <= IDLE;
            {wr1, wr0} <= 2'b00;
            vld_out_inst <= 0;
            req_rm <= 0;
            fifo_en <= 0;
            {wr_vld1 ,wr_vld0} <= 2'b00;
            vld_i <= 0;
            exception <= 0;
            mem_addr <= 0;
            mem_data <= 0;
        end
        else begin
            case(cs)
                IDLE : begin
                        {wr1,wr0} <= 0;
                        vld_i <= 0;
                        if(invalidate_i)begin
                            cs <= IDLE;
                            vld_out_inst <= 0;
                            fifo_en <= 0;
                            if(match0|match1)
                                {wr_vld1 ,wr_vld0} <= match1 ? 2'b10 : 2'b01;
                            else
                                {wr_vld1 ,wr_vld0} <= 2'b00;
                        end
                        else if(hit)begin
                            cs <= IDLE;
                            fifo_en <= 1;
                            {wr_vld1 ,wr_vld0} <= 2'b00;
                            vld_out_inst <= {match1, match0};
                        end
                        else begin
                            cs <= RM;
                            fifo_en <= 0;
                            {wr_vld1 ,wr_vld0} <= 2'b00;
                            vld_out_inst <= 0;
                            mem_addr <= {tag_i, idx_i, ofs_i};//{tag_i, idx_i, 5'd0};
                            req_rm <= 1; 
                        end
                        end
                RM : begin
                        if(rm_rdy)begin
                            cs <= UPDATE;
                            req_rm <= 0; 
                        end
                        else begin
                            cs <= RM;
                        end
                        end
                UPDATE : begin  
                        if(rm_complete & rm_success)begin
                            cs <= IDLE;
                            fifo_en <= 1;
                            vld_i <= 1;
                            mem_data <= rm_data;
                            {wr1,wr0} <= fifo ? 2'b10 : 2'b01;
                            {wr_vld1 ,wr_vld0} <= fifo ? 2'b10 : 2'b01;
                            case(mem_addr[4:2])
                                7 : cpu_inst_o <= rm_data[255 : 224];
                                6 : cpu_inst_o <= rm_data[223 : 192];
                                5 : cpu_inst_o <= rm_data[191 : 160];
                                4 : cpu_inst_o <= rm_data[159 : 128];
                                3 : cpu_inst_o <= rm_data[127 : 96];
                                2 : cpu_inst_o <= rm_data[95 : 64];
                                1 : cpu_inst_o <= rm_data[63 : 32];
                                0 : cpu_inst_o <= rm_data[31 : 0];
                            endcase
                        end
                        else if(rm_complete ^ rm_success)begin
                            cs <= EXP;
                            exception <= 1;
                        end
                        else begin
                            cs <= UPDATE;
                        end
                        end
                EXP : begin
                        if(except_complete)begin
                            cs <= IDLE;
                            exception <= 0;
                        end
                        else
                            cs <= EXP;
                      end
            endcase
	    end
    end
    
    always@(*)begin
        if(vld_out_inst[0])
            cpu_inst_o =  cpu_inst_0;
        else if(vld_out_inst[1])
            cpu_inst_o =  cpu_inst_1;
        else
            cpu_inst_o = 0;
    end
    
        // Instance construction //
    fifo_block1bx256 f0(.clk(clk), .en(fifo_en), .index(idx_i), .fifo(fifo));    

    way_32Bx256 w0(
        .clk(clk),
        .write(wr0),
        .wr_vld(wr_vld0),
        .tag_i(cache_tag),
        .index(cache_idx),
        .word_offset(cache_ofs[4:2]),
        .mem_data(mem_data),
        .vld_i(vld_i),
        .tag_o(tag_0),
        .cpu_inst_o(cpu_inst_0),
        .vld_o(vld_0)
    );
    
    way_32Bx256 w1(
        .clk(clk),
        .write(wr1),
        .wr_vld(wr_vld1),
        .tag_i(cache_tag),
        .index(cache_idx),
        .word_offset(cache_ofs[4:2]),
        .mem_data(mem_data),
        .vld_i(vld_i),
        .tag_o(tag_1),
        .cpu_inst_o(cpu_inst_1),
        .vld_o(vld_1)
    );
    
endmodule
