//-----------------------------------------------------------------
// LSU
//-----------------------------------------------------------------

`include"../riscv_defs.v"

module lsu
#(
     parameter LENGTH   = 32
    ,parameter DEPTH    = 8
)
(   
     input           clk_i
    ,input           rst_i
    ,input   [31:0]  opcode_opcode_i
    ,input   [31:0]  opcode_ra_data_i
    ,input   [31:0]  opcode_rb_data_i
    ,input   [31:0]  opcode_fp_data_i
    ,input           opcode_valid_i
    
    ,input   [31:0]  ex_mem_imm_i
    ,input           ex_mem_rd_i
    ,input           ex_mem_wr_i
    ,input   [ 3:0]  ex_mem_ctrl_i

    ,input   [31:0]  mmu_value_i
    ,input           mmu_valid_i
    ,input           mmu_load_fault
    ,input           mmu_store_fault

    ,output  [31:0]  mmu_addr_o
    ,output  [31:0]  mmu_data_o
    ,output          mmu_rd_o
    ,output          mmu_wr_o
    ,output  [ 3:0]  mmu_mask_o
    ,output          mmu_dflush_o
    ,output          mmu_dinvalidate_o
    ,output          mmu_dwriteback_o

    ,output  reg [31:0]  writeback_value_o
    ,output          writeback_valid_o

    ,output  [5:0]   exception_o
);

// --------------------------------------------
//  Parameter Declaration
// --------------------------------------------

localparam DATASIZE = 77;

// --------------------------------------------
//  Register Declaration
// --------------------------------------------

// Opcode
wire is_fp_inst = ex_mem_ctrl_i[3] && ex_mem_wr_i;

wire [31:0] ra_data = opcode_ra_data_i;
wire [31:0] rb_data = (is_fp_inst)?opcode_fp_data_i:opcode_rb_data_i;

// Memory
reg [31:0] mem_addr_r;
reg [31:0] mem_data_wr_r;
reg        mem_rd_r;
reg        mem_wr_r;
reg [ 3:0] mem_mask_r;

// Queue
reg [ DATASIZE-1:0] data_q_i;

// --------------------------------------------
//  Wire Declaration
// --------------------------------------------

// Queue
wire [DATASIZE-1:0] resp_data_o;
wire                resp_accept_o;
wire                resp_valid_o;
wire        [31:0]  resp_addr;
wire        [31:0]  resp_data;
wire                resp_lb;
wire                resp_lh;
wire                resp_lw;
wire                resp_signed;
wire                resp_rd;
wire                resp_wr;
wire        [ 3:0]  resp_mask;
wire        [ 2:0]  resp_u_type;

// --------------------------------------------
//  Opcode 
// --------------------------------------------

wire lb_inst = ex_mem_ctrl_i[0] && ex_mem_rd_i && opcode_valid_i;
wire lh_inst = ex_mem_ctrl_i[1] && ex_mem_rd_i && opcode_valid_i;
wire lw_inst = ex_mem_ctrl_i[2] && ex_mem_rd_i && opcode_valid_i;
wire sb_inst = ex_mem_ctrl_i[0] && ex_mem_wr_i && opcode_valid_i;
wire sh_inst = ex_mem_ctrl_i[1] && ex_mem_wr_i && opcode_valid_i;
wire sw_inst = ex_mem_ctrl_i[2] && ex_mem_wr_i && opcode_valid_i;
wire sign_inst = ex_mem_ctrl_i[3] && ex_mem_rd_i;

wire ld_inst = (lb_inst || lh_inst || lw_inst);
wire st_inst = (sb_inst || sh_inst || sw_inst);


wire csrrw_inst = ((opcode_opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW);

// CSRRW Instruction
wire dflush, dwriteback, dinvalidate;

assign dflush       = opcode_valid_i && (opcode_opcode_i[31:20] == `CSR_DFLUSH);
assign dwriteback   = opcode_valid_i && (opcode_opcode_i[31:20] == `CSR_DWRITEBACK);
assign dinvalidate  = opcode_valid_i && (opcode_opcode_i[31:20] == `CSR_DINVALIDATE);

assign mmu_dflush_o = dflush && csrrw_inst;
assign mmu_dwriteback_o = dwriteback && csrrw_inst;
assign mmu_dinvalidate_o = dinvalidate && csrrw_inst;

// --------------------------------------------
//  Error Detection
// --------------------------------------------

reg unaligned_1_r;
reg unaligned_2_r; 

wire addr_unaligned = unaligned_1_r || unaligned_2_r;

always @(*)begin
    unaligned_1_r = 0;
    unaligned_2_r = 0;

    if(lw_inst || sw_inst)
        unaligned_2_r = (mem_addr_r[1:0] != 2'b0);
    else if (lh_inst || sh_inst)
        unaligned_1_r = (mem_addr_r[1:0] == 2'b11);
end


assign exception_o = (resp_rd && mmu_load_fault)?`EXCEPTION_PAGE_FAULT_LOAD:
                     (resp_wr && mmu_store_fault)?`EXCEPTION_PAGE_FAULT_STORE:
                     6'h0;

// --------------------------------------------
//  Unaligned Control
// -------------------------------------------- 

reg u_state;
reg u_rd;
reg u_wr;
reg u_sign;
reg u_lh;
reg [31:0] u_addr;
reg [31:0] u_data;
reg [2:0] u_type;

always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)
    begin
        u_state <= 0;
        u_rd <= 0;
        u_wr <= 0;
        u_type <= 3'h0;
        u_sign <= 0;
        u_lh <= 0;
    end
    else
    begin
        if(unaligned_1_r && (mem_addr_r[1:0] == 2'b11))
        begin
            u_state <= 1;
            u_rd <= ld_inst;
            u_wr <= st_inst;
            u_type <= 3'h1;
            u_data <= rb_data;
            u_addr <= mem_addr_r + 4;
            u_sign <= sign_inst;
            u_lh <= 1;
        end
        else if(unaligned_2_r)
        begin
            u_state <= 1;
            u_rd <= ld_inst;
            u_wr <= st_inst;
            u_data <= rb_data;
            u_addr <= mem_addr_r + 4;
            u_sign <= 0;
            u_lh <= 0;

            case(mem_addr_r[1:0])
            2'b01:  u_type <= 3'h2;
            2'b10:  u_type <= 3'h3;
            2'b11:  u_type <= 3'h4;
            default:u_type <= 3'h0;
            endcase
        end
        else
        begin
            u_state <= 0;
            u_rd <= 0;
            u_wr <= 0;
            u_type <= 3'h0;
            u_sign <= 0;
            u_lh <= 0;
        end
    end
end

// --------------------------------------------
//  MMU
// -------------------------------------------- 

assign mmu_addr_o   = {resp_addr[31:2],2'b00};
assign mmu_data_o   = resp_data;
assign mmu_rd_o     = resp_valid_o && resp_rd && !mmu_valid_i;
assign mmu_wr_o     = resp_valid_o && resp_wr && !mmu_valid_i;
// assign mmu_rd_o     = resp_valid_o && resp_rd;
// assign mmu_wr_o     = resp_valid_o && resp_wr;
assign mmu_mask_o   = (mmu_wr_o)?resp_mask: (mmu_rd_o)?4'hf: 4'h0;

// --------------------------------------------
//  Input Address & Data Control
// --------------------------------------------

always @(*)begin
    mem_rd_r = 0;
    mem_wr_r = 0;
    mem_mask_r = 0;
    mem_addr_r = 32'b0;
    mem_data_wr_r = 32'b0;

    mem_rd_r = ld_inst || u_rd;
    mem_wr_r = st_inst || u_wr;

    mem_addr_r = ra_data + ex_mem_imm_i;
        
    // write setting
    if (sw_inst || lw_inst)begin
        case(mem_addr_r[1:0])
        2'b11:   mem_data_wr_r = {rb_data[7:0],24'h000000};
        2'b10:   mem_data_wr_r = {rb_data[15:0],16'h0000};
        2'b01:   mem_data_wr_r = {rb_data[23:0],8'h00};
        2'b00:   mem_data_wr_r = rb_data;
        endcase

        case(mem_addr_r[1:0])
        2'b11: mem_mask_r = 4'b1000;
        2'b10: mem_mask_r = 4'b1100;
        2'b01: mem_mask_r = 4'b1110;
        2'b00: mem_mask_r = 4'b1111;
        endcase
    end else if (sh_inst || lh_inst)begin
        case(mem_addr_r[1:0])
        2'b11:   mem_data_wr_r  = {rb_data[7:0],24'h0};
        2'b10:   mem_data_wr_r  = {rb_data[15:0],16'h0000};
        2'b01:   mem_data_wr_r  = {8'h00, rb_data[15:0], 8'h00};
        2'b00:   mem_data_wr_r  = {16'h0000,rb_data[15:0]};
        endcase

        case(mem_addr_r[1:0])
        2'b11:   mem_mask_r = 4'b1000;
        2'b10:   mem_mask_r = 4'b1100;
        2'b01:   mem_mask_r = 4'b0110;
        2'b00:   mem_mask_r = 4'b0011;
        endcase
    end else if (sb_inst || lb_inst)begin
        case(mem_addr_r[1:0])
        2'b11:   mem_data_wr_r = {rb_data[7:0],24'h000000};
        2'b10:   mem_data_wr_r = {{8'h00,rb_data[7:0]},16'h0000};
        2'b01:   mem_data_wr_r = {{16'h0000,rb_data[7:0]},8'h00};
        2'b00:   mem_data_wr_r = {24'h000000,rb_data[7:0]};
        endcase

        case(mem_addr_r[1:0])
        2'b11:   mem_mask_r = 4'b1000;
        2'b10:   mem_mask_r = 4'b0100;
        2'b01:   mem_mask_r = 4'b0010;
        2'b00:   mem_mask_r = 4'b0001;
        endcase
    end


    if(u_type == 3'h1)
    begin
        mem_mask_r = 4'b0001;
        mem_data_wr_r = {24'h000000,u_data[15:8]};
        mem_addr_r = u_addr;
    end
    else if(u_type == 3'h2)
    begin
        mem_mask_r = 4'b0001;
        mem_data_wr_r = {24'h000000,u_data[31:24]};
        mem_addr_r = u_addr;
    end
    else if(u_type == 3'h3)
    begin
        mem_mask_r = 4'b0011;
        mem_data_wr_r = {16'h0000,u_data[31:16]};
        mem_addr_r = u_addr;
    end
    else if(u_type == 3'h4)
    begin
        mem_mask_r = 4'b0111;
        mem_data_wr_r = {8'h00,u_data[31:8]};
        mem_addr_r = u_addr;
    end
end

// --------------------------------------------
//  Queue 
// --------------------------------------------

wire push_q = ((mem_rd_r || mem_wr_r ) && resp_accept_o) || u_state;
// wire pop_q = mmu_valid_i && resp_valid_o && pop_pre;
wire pop_q = mmu_valid_i && resp_valid_o;
wire mem_sign = sign_inst || u_sign;
wire mem_lb = lb_inst || u_lh;

assign {resp_addr, resp_data, resp_lb, resp_lh, resp_lw, resp_signed, resp_rd, resp_wr, resp_mask, resp_u_type} = resp_data_o; 

reg pop_pre;
always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)
        pop_pre <= 0;
    else
        pop_pre <= pop_q;
end

always @(*)begin
    data_q_i = {(DATASIZE){1'b0}};

    if (ld_inst || u_rd)
        data_q_i = {mem_addr_r, 32'b0, mem_lb, lh_inst, lw_inst, mem_sign, mem_rd_r, 1'b0, mem_mask_r, u_type};
    else if (st_inst || u_wr)
        data_q_i = {mem_addr_r, mem_data_wr_r, mem_lb, lh_inst, lw_inst, mem_sign, 1'b0, mem_wr_r, mem_mask_r, u_type};
    else 
        data_q_i = {(DATASIZE){1'b0}};
end

// LSU Queue Unit
lsu_queue #(
    .DATASIZE(DATASIZE), 
    .LENGTH(LENGTH), 
    .DEPTH(DEPTH)
) LDQ (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .data_i(data_q_i),
    .push_i(push_q),
    .accept_o(resp_accept_o),

    .pop_i(pop_q),
    .data_o(resp_data_o),
    .valid_o(resp_valid_o)      
);

// --------------------------------------------
//  Writeback
// --------------------------------------------

reg [31:0] writeback_value_r;
reg [31:0] writeback_value_pre;
reg [ 3:0] writeback_mask_pre;
reg        resp_valid_pre;

assign writeback_valid_o = {resp_valid_pre, resp_valid_o} == 2'b10;

always @(posedge clk_i or negedge rst_i) begin
    if(!rst_i)
    begin
        writeback_value_o <= 32'h0;
        writeback_value_pre <= 32'h0;
        resp_valid_pre <= 0;
    end
    else
    begin
        case(resp_u_type)
        3'h1: writeback_value_o <= {writeback_value_r[23:0], writeback_value_pre[ 7:0]};
        3'h2: writeback_value_o <= {writeback_value_r[ 7:0], writeback_value_pre[23:0]};
        3'h3: writeback_value_o <= {writeback_value_r[15:0], writeback_value_pre[15:0]};
        3'h4: writeback_value_o <= {writeback_value_r[23:0], writeback_value_pre[ 7:0]};
        default: writeback_value_o <= writeback_value_r; 
        endcase

        resp_valid_pre <= resp_valid_o;
        writeback_value_pre <= (mmu_valid_i)?writeback_value_r:writeback_value_pre; 
    end
end

always @(*)begin
    writeback_value_r = 32'b0;

    case(resp_mask)
    4'b0001: writeback_value_r = {24'b0, mmu_value_i[7:0]};
    4'b0010: writeback_value_r = {24'b0, mmu_value_i[15:8]};
    4'b0100: writeback_value_r = {24'b0, mmu_value_i[23:16]};
    4'b1000: writeback_value_r = {24'b0, mmu_value_i[31:24]};
    4'b0011: writeback_value_r = {16'b0, mmu_value_i[15:0]};
    4'b0110: writeback_value_r = {16'b0, mmu_value_i[23:8]};
    4'b1100: writeback_value_r = {16'b0, mmu_value_i[31:16]};
    4'b0111: writeback_value_r = {8'b0, mmu_value_i[23:0]};
    4'b1110: writeback_value_r = {8'b0, mmu_value_i[31:8]};
    4'b1111: writeback_value_r = mmu_value_i;
    default: writeback_value_r = 32'b0;
    endcase

    if(resp_signed && resp_lh && writeback_value_r[15])
        writeback_value_r = {16'hFFFF, writeback_value_r[15:0]};
    else if(resp_signed && resp_lb && writeback_value_r[7])
        writeback_value_r = {24'hFFFFFF, writeback_value_r[7:0]};
    
end

endmodule
