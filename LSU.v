//-----------------------------------------------------------------
// LSU
//-----------------------------------------------------------------

`include"riscv_defs.v"

module lsu
#(
     parameter LENGTH   = 16
    ,parameter DEPTH    = 4
)
(   
     input           clk_i
    ,input           rst_i
    ,input   [31:0]  opcode_opcode_i
    ,input   [ 4:0]  opcode_rd_i
    ,input   [31:0]  opcode_ra_data_i
    ,input   [31:0]  opcode_rb_data_i
    ,input           opcode_valid_i
    

    ,input  [31:0]  mmu_value_i
    ,input          mmu_valid_i
    ,input          mmu_load_fault
    ,input          mmu_store_fault

    ,output  [31:0]  mmu_addr_o
    ,output  [31:0]  mmu_data_o
    ,output          mmu_rd_o
    ,output  [ 3:0]  mmu_wr_o
    ,output          mmu_dflush_o
    ,output          mmu_dinvalidate_o
    ,output          mmu_dwriteback_o

    ,output  [31:0]  writeback_value_o
    ,output  [ 4:0]  writeback_rd_o
    ,output          writeback_valid_o
    ,output          stall_o

    ,output  [5:0]   exception_o
);

// --------------------------------------------
//  Parameter Declaration
// --------------------------------------------

localparam DATASIZE = 78;

// --------------------------------------------
//  Register Declaration
// --------------------------------------------

// Opcode
reg  [31:0] ra_data;
reg  [31:0] rb_data;

// Memory
reg [31:0] mem_addr_r;
reg [31:0] mem_data_wr_r;
reg        mem_rd_r;
reg [ 3:0] mem_wr_r;

// Queue
reg [ DATASIZE-1:0] data_q_i;

// FSM & ACT
reg     fsm_state;
reg     cache_act_r;
reg     cache_hit_r;
reg     mem_act_r;


// --------------------------------------------
//  Wire Declaration
// --------------------------------------------

// Opcode
wire ld_inst;
wire st_inst;

wire lb_inst, lh_inst, lw_inst;
wire sb_inst, sh_inst, sw_inst;
wire sign_inst;

wire csrrw_inst;

// Queue
wire                is_load_i;
wire [DATASIZE-1:0] resp_data_o;
wire                resp_accept_o;
wire                resp_valid_o;
wire        [31:0]  resp_addr;
wire        [31:0]  resp_data;
wire                resp_lb;
wire                resp_lh;
wire                resp_lw;
wire                resp_signed;
wire                resp_is_load;
wire        [ 3:0]  resp_wr;
wire        [ 4:0]  resp_rd;

// --------------------------------------------
//  Error Detection
// --------------------------------------------

reg unaligned_r;

wire addr_unaligned;

assign addr_unaligned = unaligned_r;

assign exception_o = (addr_unaligned && mem_rd_r)?`EXCEPTION_MISALIGNED_LOAD: 
                     (addr_unaligned && (|mem_wr_r))?`EXCEPTION_MISALIGNED_STORE:
                     (resp_is_load && mmu_load_fault)?`EXCEPTION_FAULT_LOAD:
                     ((|resp_wr) && mmu_store_fault)?`EXCEPTION_FAULT_STORE:
                     5'h0;

always @(*)begin
    unaligned_r = 32'b0;

    if(opcode_valid_i && (lw_inst || sw_inst))
        unaligned_r = (mem_addr_r[1:0] != 2'b0);
    else if (opcode_valid_i && (lh_inst || sh_inst))
        unaligned_r = mem_addr_r[0];
    else 
        unaligned_r = 1'b0;
end


// --------------------------------------------
//  Opcode 
// --------------------------------------------

assign ld_inst = opcode_valid_i && (lb_inst || lh_inst || lw_inst);
assign st_inst = opcode_valid_i && (sb_inst || sh_inst || sw_inst);

assign lb_inst = ((opcode_opcode_i & `INST_LB_MASK) == `INST_LB) || ((opcode_opcode_i & `INST_LBU_MASK) == `INST_LBU);
assign lh_inst = ((opcode_opcode_i & `INST_LH_MASK) == `INST_LH) || ((opcode_opcode_i & `INST_LBU_MASK) == `INST_LHU);
assign lw_inst = ((opcode_opcode_i & `INST_LW_MASK) == `INST_LW) || ((opcode_opcode_i & `INST_LBU_MASK) == `INST_LWU);

assign sb_inst = ((opcode_opcode_i & `INST_LB_MASK) == `INST_SB);
assign sh_inst = ((opcode_opcode_i & `INST_LH_MASK) == `INST_SH);
assign sw_inst = ((opcode_opcode_i & `INST_LW_MASK) == `INST_SW);

assign sign_inst = ((opcode_opcode_i & `INST_LB_MASK) == `INST_LB) ||
                   ((opcode_opcode_i & `INST_LH_MASK) == `INST_LH) ||
                   ((opcode_opcode_i & `INST_LW_MASK) == `INST_LW);

assign csrrw_inst = ((opcode_opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW);

// CSRRW Instruction
wire dflush, dwriteback, dinvalidate;

assign dflush       = opcode_valid_i && (opcode_opcode_i[31:20] == `CSR_DFLUSH);
assign dwriteback   = opcode_valid_i && (opcode_opcode_i[31:20] == `CSR_DWRITEBACK);
assign dinvalidate  = opcode_valid_i && (opcode_opcode_i[31:20] == `CSR_DINVALIDATE);

assign mmu_dflush_o = dflush && csrrw_inst;
assign mmu_dwriteback_o = dwriteback && csrrw_inst;
assign mmu_dinvalidate_o = dinvalidate && csrrw_inst;

always @(*)
begin
    ra_data = 32'b0;
    rb_data = 32'b0;

    ra_data = opcode_ra_data_i;
    rb_data = opcode_rb_data_i;    
end

// --------------------------------------------
//  MMU
// --------------------------------------------

assign mmu_addr_o   = resp_addr;
assign mmu_data_o   = resp_data;
assign mmu_valid_o  = resp_valid_o;
assign mmu_rd_o     = resp_is_load;
assign mmu_wr_o     = resp_wr;

// --------------------------------------------
//  Input Address & Data Control
// --------------------------------------------

always @(*)begin
    mem_addr_r = 32'b0;
    mem_data_wr_r = 32'b0;
    mem_wr_r = 4'b0;

    // address setting
    if (ld_inst)
        mem_addr_r = ra_data + { {20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]};
    else if (st_inst) 
        mem_addr_r = ra_data + { {20{opcode_opcode_i[31]}}, opcode_opcode_i[31:25], opcode_opcode_i[11:7]};
    
    // read setting
    mem_rd_r = ld_inst;
        
    // write setting
    if (sw_inst)begin
        mem_data_wr_r = rb_data;
        mem_wr_r = 4'b1111;
    end else if (sh_inst)begin
        case(mem_addr_r[1:0])
        2'b10: 
        begin
            mem_data_wr_r  = {rb_data[15:0],16'h0000};
            mem_wr_r    = 4'b1100;
        end
        default:
        begin
            mem_data_wr_r  = {16'h0000,rb_data[15:0]};
            mem_wr_r    = 4'b0011;
        end
        endcase
    end else if (sb_inst)begin
        case(mem_addr_r[1:0])
        2'b11:
        begin
            mem_data_wr_r = {rb_data[7:0],24'h000000};
            mem_wr_r = 4'b1000;
        end
        2'b10:
        begin
            mem_data_wr_r = {{8'h00,rb_data[7:0]},16'h0000};
            mem_wr_r = 4'b0100;
        end
        2'b01:
        begin
            mem_data_wr_r = {{16'h0000,rb_data[7:0]},8'h00};
            mem_wr_r = 4'b0010;
        end
        2'b00:
        begin
            mem_data_wr_r = {24'h000000,rb_data[7:0]};
            mem_wr_r = 4'b0001;
        end
        default: begin
            mem_data_wr_r = 32'b0;
            mem_wr_r = 4'b0000;
        end
        endcase
    end else
        mem_wr_r = 4'b0000;
end

// --------------------------------------------
//  Queue 
// --------------------------------------------

assign is_load_i = ld_inst;
assign {resp_addr, resp_data, resp_lb, resp_lh, resp_lw, resp_signed, resp_is_load, resp_wr, resp_rd} = resp_data_o; 

// LSU Queue Unit
lsu_queue #(
    .DATASIZE(DATASIZE), 
    .LENGTH(LENGTH), 
    .DEPTH(DEPTH)
) LDQ (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .data_i(data_q_i),
    .push_i((mem_rd_r || (|mem_wr_r) ) && resp_accept_o && opcode_valid_i),
    .accept_o(resp_accept_o),

    .pop_i(mmu_valid_i && resp_valid_o),
    .data_o(resp_data_o),
    .valid_o(resp_valid_o)      
);

always @(*)begin
    data_q_i = {(DATASIZE){1'b0}};

    if (ld_inst)
        data_q_i = {mem_addr_r, 32'b0, lb_inst, lh_inst, lw_inst, sign_inst, is_load_i, 4'b0, opcode_rd_i};
    else if (st_inst)
        data_q_i = {mem_addr_r, mem_data_wr_r, lb_inst, lh_inst, lw_inst, sign_inst, is_load_i, mem_wr_r, 5'b0};
    else 
        data_q_i = {(DATASIZE){1'b0}};
end

// --------------------------------------------
//  Stall
// --------------------------------------------

assign stall_o = (~resp_accept_o && (ld_inst || st_inst)) || (dwriteback || dinvalidate || dflush);

// --------------------------------------------
//  Writeback
// --------------------------------------------

reg [31:0] writeback_value_r;

assign writeback_value_o = writeback_value_r;
assign writeback_valid_o = mmu_valid_i;
assign writeback_rd_o    = resp_rd;

always @(*)begin
    writeback_value_r = 32'b0;

    if (resp_lb && mmu_valid_i)
    begin
        case (resp_addr[1:0])
        2'h3: writeback_value_r = {24'b0, mmu_value_i[31:24]};
        2'h2: writeback_value_r = {24'b0, mmu_value_i[23:16]};
        2'h1: writeback_value_r = {24'b0, mmu_value_i[15:8]};
        2'h0: writeback_value_r = {24'b0, mmu_value_i[7:0]};
        endcase

        if (resp_signed && writeback_value_r[7])
            writeback_value_r = {24'hFFFFFF, writeback_value_r[7:0]};
    end
    else if (resp_lh && mmu_valid_i)
    begin
        case(resp_addr[1])
        1'b0: writeback_value_r = {16'h0, mmu_value_i[31:16]};
        1'b1: writeback_value_r = {16'h0, mmu_value_i[15:0]};
        default: writeback_value_r = 32'b0;
        endcase 

        if (resp_signed && mmu_value_i[15])
            writeback_value_r = {16'hFFFF, writeback_value_r[15:0]};
    end else if(resp_lw && mmu_valid_i)
    begin
        writeback_value_r = mmu_value_i;
    end
    else
        writeback_value_r = 32'h0;

end

endmodule


//-----------------------------------------------------------------
// LSU Queue
//-----------------------------------------------------------------

module lsu_queue
#(
    parameter DATASIZE = 32, 
    parameter LENGTH = 32,  // Memory number of queue.
    parameter DEPTH = 8     // Maximal element of queue.
)  
(
    input clk_i,
    input rst_i,
    input [DATASIZE-1:0] data_i,
    input push_i,
    input pop_i,
    
    output [DATASIZE-1:0] data_o,
    output accept_o,                // Push success
    output valid_o                  // Pop success
);

localparam ADDRSIZE = 32;

reg [DATASIZE-1:0] ram_q[LENGTH-1:0];
reg [ADDRSIZE-1:0] wr_ptr;
reg [ADDRSIZE-1:0] rd_ptr;
reg [ADDRSIZE-1:0] count;

wire empty = (count == 0);
wire full  = (count == DEPTH);
wire accept = ~full;
wire valid  = ~empty;

integer i;

assign data_o   = ram_q[rd_ptr];
assign accept_o = accept;
assign valid_o  = valid;

always @(posedge clk_i or negedge rst_i) begin
    if (~rst_i) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count  <= 0;
        for (i = 0; i < LENGTH; i = i + 1) begin
            ram_q[i] <= 0;
        end
    end else begin
        // Push
        if (accept && push_i) begin
            ram_q[wr_ptr] <= data_i;
            wr_ptr <= (wr_ptr == LENGTH - 1) ? 0 : wr_ptr + 1;
        end

        // Pop
        if (valid && pop_i) begin
            rd_ptr <= (rd_ptr == LENGTH - 1) ? 0 : rd_ptr + 1;
        end

        // Count Element
        case ({accept && push_i, valid && pop_i})
            2'b10: count <= count + 1;
            2'b01: count <= count - 1;
            default: count <= count;
        endcase

    end
end

endmodule

