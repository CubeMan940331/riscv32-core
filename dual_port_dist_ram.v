//////////////////////////////////////////////////////////////////////////////////
// Company: CAS lab
// Create Date: 01/12/2025 09:33:08 PM
// Module Name: dual_port_dist_ram
//////////////////////////////////////////////////////////////////////////////////

// Reference: Dual port distributed RAM example from Xilinx
// https://docs.amd.com/r/2022.2-English/ug901-vivado-synthesis/Dual-Port-RAM-with-Asynchronous-Read-Coding-Example-Verilog


module dual_port_dist_ram #(XLEN = 32, ADDR_WIDTH = 10, DATA_ENTRY = 1024)
(
    input  clk,

    input  we,
    input  [ADDR_WIDTH-1:0] a,
    input  [ADDR_WIDTH-1:0] dpra,
    input  [XLEN-1      :0] di,
    output [XLEN-1      :0] spo,
    output [XLEN-1      :0] dpo
);

(*ram_style = "distributed"*) reg [XLEN-1:0] ram [DATA_ENTRY-1:0] /*verilator public*/;

initial begin
    $readmemb("TEST_INSTRUCTIONS.txt", ram);
end

always @(posedge clk) begin
    if (we) ram[a] <= di;
end

assign spo = ram[a];
assign dpo = ram[dpra];

endmodule 
