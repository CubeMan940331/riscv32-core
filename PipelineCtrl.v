// control pipeline register
// stall or insert nop
module PipelineCtrl(
     input clk
    ,input rst_n

    ,input br_taken

// EX control
    ,input EX_pc_valid_i
    ,input EX_is_impl_i
    ,input ALU_done_i
    ,input Br_done_i
    ,input LSU_done_i
    ,input FPU_done_i
    ,input SYS_done_i
    ,input bypass_done_i
    ,input MUL_DIV_done_i

    ,output EX_start

// Pipeline control
    ,output reg pc_en
    
    ,output reg ID_en
    ,output reg ID_clear

    ,output reg EX_en
    ,output reg EX_clear

    ,output reg WB_en
    ,output reg WB_clear
);

// EX control
wire EX_stall;
wire EX_done;

// start logic
/*
set to 0 if
    - first cycle of execution
    - not executing
set to 1 if
    - not the first cycle of execution
*/
reg started;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) started <= 0;
    else begin     
        if(EX_done || !(EX_pc_valid_i && EX_is_impl_i)) started <= 0;
        else if((EX_pc_valid_i && EX_is_impl_i) && !started)
            started <= 1;
    end
end
assign EX_start = (!started) && (EX_pc_valid_i && EX_is_impl_i);
assign EX_done = (!EX_pc_valid_i) | (!EX_is_impl_i) |
    ALU_done_i | Br_done_i | LSU_done_i | FPU_done_i |
    SYS_done_i | bypass_done_i | MUL_DIV_done_i;

assign EX_stall = !EX_done;

always @(*)begin
    pc_en=1;

    ID_en=1;
    ID_clear=0;

    EX_en=1;
    EX_clear=0;

    WB_en=1;
    WB_clear=0;

    if(br_taken)begin
        // branch determined at EX stage
        // clear Id, EX next clock
        ID_clear=1;
        EX_clear=1;
    end
    else if(EX_stall) begin
        // freeze IF, ID, EX
        pc_en=0;
        ID_en=0;
        EX_en=0;
        // insert nop to WB next clock
        WB_clear=1;
    end
end
endmodule
