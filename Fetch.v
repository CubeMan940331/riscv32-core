module Fetch (
     input clk
    ,input rst_n

// inst. mem interface
    ,output i_req_o
    ,input i_ready_i

    ,input en
// feed back from EX for bp
    ,input [31:0] EX_pc_i
    
    ,input EX_bp_pred_taken_i
    ,input [31:0] EX_bp_pred_pc_i
    
    ,input EX_is_br_i
    ,input EX_br_taken_i
    ,input [31:0] EX_br_target_i
    ,input [31:0] EX_pc_p4_i
    
    ,input EX_csr_br_taken_i
    ,input [31:0] EX_csr_br_target_i
    ,input EX_done_i
    ,input EX_pc_valid_i
// output
    ,output IF_stall_o
    ,output br_flush_o
    
    ,output bp_pred_taken_o
    ,output [31:0] bp_pred_target_o
    
    ,output [31:0] pc_o
    ,output [31:0] pc_p4_o
);
reg rst_done;
reg first_req;

reg [1:0] state, state_nx; // 0 ready, 2 wait mem, 3 wait pipeline
localparam F_READY = 0;
localparam F_WAIT_MEM = 2;
localparam F_WAIT_PIPE = 3;

reg [31:0] pc_in_r;
wire [31:0] pc_in;

reg [31:0] EX_pc_nx_r;
reg [31:0] EX_pc_nx_q;
wire [31:0] EX_pc_nx_w;

reg br_flush_r;
reg br_flush_q;
wire br_flush_w;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        first_req <= 0;
        rst_done <= 0;
    end
    else begin
        rst_done <= 1;
        first_req <= ~rst_done;
    end    
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) state <= 2;
    else state <= state_nx;
end
always @(*) case (state)
    F_READY: begin
        if(br_flush_w) begin
            // need another memory access
            if(i_ready_i) state_nx = F_READY;
            else state_nx = F_WAIT_MEM; // wait current request to finish
        end
        else begin
            if(i_ready_i && en) state_nx = F_READY;
            else if(i_ready_i) state_nx = F_WAIT_PIPE;
            else state_nx = F_WAIT_MEM;
        end
    end
    F_WAIT_MEM: begin
        if(br_flush_w) begin
            if(i_ready_i) state_nx = F_READY;
            else state_nx = F_WAIT_MEM;
        end
        else begin
            if(i_ready_i && en) state_nx = F_READY;
            else if(i_ready_i) state_nx = F_WAIT_PIPE;
            else state_nx = F_WAIT_MEM;
        end
    end
    F_WAIT_PIPE: begin
        if(br_flush_w) state_nx = F_READY;
        else begin
            if(en) state_nx = F_READY;
            else state_nx = F_WAIT_PIPE;
        end
    end
    default: state_nx = F_READY;
endcase

BP_top m_bp(
     .clk(clk)
    ,.rst_n(rst_n)
    
    ,.pc_f_i(pc_o)

    ,.pc_ex_i(EX_pc_i)
    ,.is_branch_i(EX_is_br_i)
    ,.branch_taken_ex_i(EX_br_taken_i)
    ,.branch_target_ex_i(EX_br_target_i)

    ,.predict_taken_o(bp_pred_taken_o)
    ,.predict_target_o(bp_pred_target_o) // pred pc if pred taken is true
);

PC m_PC(
    .clk(clk),
    .rst_n(rst_n),
    .en(state_nx==0),
    .pc_i(pc_in),
    .pc_o(pc_o)
);

// EX next pc logic
always @(*) begin
    if(EX_csr_br_taken_i) EX_pc_nx_r = EX_csr_br_target_i;
    else if(EX_br_taken_i) EX_pc_nx_r = EX_br_target_i;
    else EX_pc_nx_r = EX_pc_p4_i;
end
always @(posedge clk) begin
    if(EX_done_i && EX_pc_valid_i) EX_pc_nx_q <= EX_pc_nx_r;
    else EX_pc_nx_q <= EX_pc_nx_q;
end
assign EX_pc_nx_w = (EX_done_i && EX_pc_valid_i) ? EX_pc_nx_r: EX_pc_nx_q;

// br_flush logic
always @(*) begin
    if(!(EX_done_i && EX_pc_valid_i)) br_flush_r = 0;
    else if(EX_bp_pred_taken_i) br_flush_r = EX_pc_nx_r != EX_bp_pred_pc_i;
    else br_flush_r = EX_pc_nx_r != EX_pc_p4_i;
end
always @(posedge clk) begin
    if(state_nx==0) br_flush_q <= 0; // clear the register at read
    else if(EX_done_i && EX_pc_valid_i) br_flush_q <= br_flush_r;
    else br_flush_q <= br_flush_q;
end
assign br_flush_w = (EX_done_i && EX_pc_valid_i)? br_flush_r: br_flush_q;

// pc_in logic
always @(*) begin
    if(br_flush_w) pc_in_r = EX_pc_nx_w;
    else if(bp_pred_taken_o) pc_in_r = bp_pred_target_o;
    else pc_in_r = pc_p4_o;
end
assign pc_in = pc_in_r;

assign br_flush_o = br_flush_r;
assign pc_p4_o = pc_o + 4;

assign i_req_o = state==0 | first_req;
assign IF_stall_o = state_nx!=0 || br_flush_w;

endmodule
