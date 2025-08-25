// -----------------------------------------------
// TLB
// -----------------------------------------------

module mmu_tlb
#(
    parameter PPN_SIZE = 20
)
(
     input                  clk_i
    ,input                  rst_i
    ,input  [PPN_SIZE-1:0]  addr_i
    ,input  [31:0]          entry_i
    ,input                  update_i

    ,output                 hit_o
    ,output [31:0]          entry_o
);

reg [PPN_SIZE-1:0]  vpn_q;
reg [31:0]          entry_q;
reg                 tlb_valid_r;

assign hit_o   =  (addr_i == vpn_q) && tlb_valid_r;
assign entry_o = entry_q;

always @(posedge clk_i or negedge  rst_i)begin
    if(~rst_i)begin
        begin
            vpn_q       <= 20'b0;
            entry_q     <= 32'b0; 
            tlb_valid_r <= 0;   
        end
    end else begin
        if(update_i)
        begin
            vpn_q       <= addr_i;
            entry_q     <= entry_i;
            tlb_valid_r <= 1;
        end
    end

end

endmodule
