module DataMemory
#(parameter SIZE = 65536)          // in BYTES (must be >= maximum address+4)
(
    input  wire        rst_n,      // active-low asynchronous reset
    input  wire        clk,        // rising-edge clock

	input  wire [31:0] i_addr,
	output wire [31:0] inst,
    output wire        i_available_o,
    
	input  wire        wr_en,   // 1 = store
    input  wire        rd_en,    // 1 = load
    input  wire [3:0]  ctrl,    // [3]=sign , [2]=word , [1]=half , [0]=byte
    
	input  wire [31:0] address,    // byte address
    input  wire [31:0] data_i,  // store data (little-endian)
    output reg  [31:0] data_o,    // load data (extended)
	output wire 	   available_o
);

reg [7:0] mem [0:SIZE-1] /* verilator public */;
assign inst = i_addr<SIZE ? {mem[i_addr+3], mem[i_addr+2], mem[i_addr+1], mem[i_addr+0]}: 32'h0;
assign i_available_o = 1;
assign available_o = 1;
always @(posedge clk) begin
    // if (wr_en) begin
    //     // SW
    //     if (ctrl[2]) begin
    //         mem[address   ] <= data_i[ 7: 0];
    //         mem[address +1] <= data_i[15: 8];
    //         mem[address +2] <= data_i[23:16];
    //         mem[address +3] <= data_i[31:24];
    //     end
    //     // SH
    //     else if (ctrl[1]) begin
    //         mem[address   ] <= data_i[ 7: 0];
    //         mem[address +1] <= data_i[15: 8];
    //     end
    //     // SB
    //     else if (ctrl[0]) begin
    //         mem[address    ] <= data_i[ 7: 0];
    //     end
    // end

	if(ctrl[3] && wr_en)
		mem[address+3] <= data_i[31:24];
	if(ctrl[2] && wr_en)
		mem[address+2] <= data_i[23:16];
	if(ctrl[1] && wr_en) 
		mem[address+1] <= data_i[15:8];
	if(ctrl[0] && wr_en)
		mem[address  ] <= data_i[7:0];
end

// --------------------------------------------------------
// Combinational read path (single-cycle latency)
// --------------------------------------------------------
// reg [7:0]  byte_data;
// reg [15:0] half_data;

// always @(*) begin
// 	byte_data = 8'h00;
// 	half_data = 16'h0000;
// 	if (!rd_en) begin
// 		data_o = 32'h00000000;
// 	end
// 	else if (ctrl[2]) begin        // LW
// 		data_o = {  mem[address +3],
// 					  mem[address +2],
// 					  mem[address +1],
// 					  mem[address   ]};
// 	end
// 	else if (ctrl[1]) begin             // LH / LHU
// 		half_data = { mem[address +1], mem[address] };
// 		if (ctrl[3])                    // signed
// 			data_o = { {16{half_data[15]}}, half_data };   // sign-extend
// 		else                               // unsigned
// 			data_o = { 16'h0000, half_data };
// 	end
// 	else if (ctrl[0]) begin             // LB / LBU
// 		byte_data = mem[address];
// 		if (ctrl[3])                    // signed
// 			data_o = { {24{byte_data[7]}}, byte_data };
// 		else                               // unsigned
// 			data_o = { 24'h000000, byte_data };
// 	end
// 	else begin
// 		data_o = 32'hXXXXXXXX;           // illegal size code
// 	end
// end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		data_o <= 32'h0;
	end else begin
		data_o <= {mem[address+3], mem[address+2], mem[address+1], mem[address]};
	end	
end

endmodule
