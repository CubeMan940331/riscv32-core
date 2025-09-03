// control pipeline register
// stall or insert nop
module PipelineCtrl(
    input br_flush

    ,input EX_stall

// Pipeline control
    ,output reg pc_en
    
    ,output reg ID_en
    ,output reg ID_clear

    ,output reg EX_en
    ,output reg EX_clear

    ,output reg WB_en
    ,output reg WB_clear
);

always @(*)begin
    pc_en=1;

    ID_en=1;
    ID_clear=0;

    EX_en=1;
    EX_clear=0;

    WB_en=1;
    WB_clear=0;

    if(br_flush)begin
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
