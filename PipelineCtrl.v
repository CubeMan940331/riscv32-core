module PipelineCtrl(
    input  wire br_flush,
    input  wire IF_stall,
    input  wire EX_stall,

    output wire pc_en,

    output wire ID_en,
    output wire ID_clear,

    output wire EX_en,
    output wire EX_clear,

    output wire WB_en,
    output wire WB_clear
);

// Enables
assign pc_en = ~EX_stall;
assign ID_en = ~EX_stall;
assign EX_en = ~EX_stall;
assign WB_en = 1'b1;

// Clears
assign ID_clear = IF_stall | br_flush;
assign EX_clear = br_flush;
assign WB_clear = EX_stall;

endmodule
