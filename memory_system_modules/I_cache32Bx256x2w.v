`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/23 00:16:59
// Design Name: 
// Module Name: I_cache32Bx256x2w
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

module I_cache32Bx256x2w( // WAIT不用的可能性需要探討,以及MIG是否能連續執行寫入
    input clk,
    input rst_n,
    input [18:0] tag_i,
    input [7:0] idx_i,
    input [4:0] ofs_i,
    input [127:0] mem_data_i,
    input mem_rd_data_rdy,
    input mem_available,
    input init_calib_complete,
    input d_claim,
    output reg i_claim,
    output [1:0] cso,
    output [255:0] cache_get_data,
    output m0,
    output m1,
    output hi,
    output [31:0] ins_o0,
    output [31:0] ins_o1,
    input rd_mem_done,
    output reg req_rd_mem,
    output reg [26:0] rd_mem_addr,
    output reg stall_cpu,
    output reg [31:0] cpu_inst_o
);

    // parameter def
    reg fifo_en;
    wire fifo;
    reg wr0, wr1;
    reg [255:0] mem_data_reg;  
    wire [31:0] cpu_inst_0, cpu_inst_1;
    
    // hit decision
    reg comp_mode;
    wire [18:0] tag_0, tag_1;
    wire vld_0, vld_1;
    wire match1 = vld_1 & (tag_i == tag_1);
    wire match0 = vld_0 & (tag_i == tag_0);
    wire hit = comp_mode & (match1 | match0);
    
    
    
 
    // FSM
    parameter IDLE = 0, RD1 = 1, WAIT = 2, RD2 = 3;
    reg [1:0] cs, ns;
    
    
    assign cso = cs;
    assign cache_get_data = mem_data_reg;
    assign m0 = match0;
    assign m1 = match1;
    assign hi = hit;
    assign ins_o0 = cpu_inst_0;
    assign ins_o1 = cpu_inst_1;    

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cs <= IDLE;
        else if (init_calib_complete)
            cs <= ns;
        else
            cs <= IDLE;
    end
   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_data_reg <= 256'b0;
        end else begin
            case (cs)
                IDLE: mem_data_reg <= 256'b0;
                RD1: if (mem_rd_data_rdy && rd_mem_done)
                        mem_data_reg <= {mem_data_reg[255:128], mem_data_i};
                RD2: if (mem_rd_data_rdy && rd_mem_done)
                        mem_data_reg <= {mem_data_i, mem_data_reg[127:0]};
                default: mem_data_reg <= mem_data_reg;
            endcase
        end
    end
    

    always @(*) begin
        comp_mode = 0;
        cpu_inst_o = 0;
        fifo_en = 0;
        rd_mem_addr = 0;
        stall_cpu = 0;
        req_rd_mem = 0;
        wr1 = 0;
        wr0 = 0;
        ns = IDLE;
        i_claim = 0;
        
        case (cs)
            IDLE: begin
                if (init_calib_complete) begin
                    comp_mode = 1;
                    if (hit) begin
                        cpu_inst_o = match0 ? cpu_inst_0 : cpu_inst_1;
                        ns = IDLE;
                    end else begin
                        if ((!mem_available) || d_claim) begin
                            stall_cpu = 1;
                            ns = IDLE;
                        end else begin
                            i_claim = 1;
                            stall_cpu = 1;
                            req_rd_mem = 1;
                            rd_mem_addr = {tag_i[13:0], idx_i, 5'd0};
                            ns = RD1;
                        end
                    end
                end
            end
            
            RD1: begin
                stall_cpu = 1;
                i_claim = 1;
                rd_mem_addr = {tag_i[13:0], idx_i, 5'd0};
                
                if (mem_rd_data_rdy && rd_mem_done) begin
                    if (mem_available) begin
                        req_rd_mem = 1;
                        rd_mem_addr = {tag_i[13:0], idx_i, 5'd16};
                        ns = RD2;
                    end else begin
                        ns = WAIT;
                    end
                end else begin
                    ns = RD1;
                end
            end
            
            WAIT: begin
                stall_cpu = 1;
                i_claim = 1;
                rd_mem_addr = {tag_i[13:0], idx_i, 5'd16};
                
                if (mem_available) begin
                    req_rd_mem = 1;
                    ns = RD2;
                end else begin
                    ns = WAIT;
                end
            end
            
            RD2: begin
                stall_cpu = 1;
                i_claim = 1;
                rd_mem_addr = {tag_i[13:0], idx_i, 5'd16};
                
                if (mem_rd_data_rdy && rd_mem_done) begin
                    {wr1, wr0} = fifo ? 2'b10 : 2'b01;
                    fifo_en = 1;
                    i_claim = 0;
                    ns = IDLE;
                end else begin
                    ns = RD2;
                end
            end
            
            default: ns = IDLE;
        endcase
    end
    
    fifo_block1bx256 f0(
        .clk(clk),
        .en(fifo_en),
        .index(idx_i),
        .fifo(fifo)
    );    

    way_32Bx256 w0(
        .clk(clk),
        .write(wr0),
        .tag_i(tag_i),
        .index(idx_i),
        .word_offset(ofs_i[4:2]),
        .mem_data(mem_data_reg),
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
        .mem_data(mem_data_reg),
        .tag_o(tag_1),
        .cpu_inst_o(cpu_inst_1),
        .vld_o(vld_1)
    );
    
endmodule