module DataMemory
#(parameter SIZE = 65536)          // in BYTES (must be >= maximum address+4)
(
    input  wire        rst_n,      // active-low asynchronous reset
    input  wire        clk,        // rising-edge clock
    input  wire        memWrite,   // 1 = store
    input  wire        memRead,    // 1 = load
    input  wire [3:0]  memCtrl,    // [3]=sign , [2]=word , [1]=half , [0]=byte
    input  wire [31:0] address,    // byte address
    input  wire [31:0] writeData,  // store data (little-endian)
    output reg  [31:0] readData    // load data (extended)
);

reg [7:0] mem [0:SIZE-1];

always @(posedge clk) begin
    if (memWrite) begin
        // SW
        if (memCtrl[2]) begin
            mem[address   ] <= writeData[ 7: 0];
            mem[address +1] <= writeData[15: 8];
            mem[address +2] <= writeData[23:16];
            mem[address +3] <= writeData[31:24];
        end
        // SH
        else if (memCtrl[1]) begin
            mem[address   ] <= writeData[ 7: 0];
            mem[address +1] <= writeData[15: 8];
        end
        // SB
        else if (memCtrl[0]) begin
            mem[address    ] <= writeData[ 7: 0];
        end
    end
end

// --------------------------------------------------------
// Combinational read path (single-cycle latency)
// --------------------------------------------------------
reg [7:0]  byte_data;
reg [15:0] half_data;

always @(*) begin
	byte_data = 8'h00;
	half_data = 16'h0000;
	if (!memRead) begin
		readData = 32'h00000000;
	end
	else if (memCtrl[2]) begin        // LW
		readData = {  mem[address +3],
					  mem[address +2],
					  mem[address +1],
					  mem[address   ]};
	end
	else if (memCtrl[1]) begin             // LH / LHU
		half_data = { mem[address +1], mem[address] };
		if (memCtrl[3])                    // signed
			readData = { {16{half_data[15]}}, half_data };   // sign-extend
		else                               // unsigned
			readData = { 16'h0000, half_data };
	end
	else if (memCtrl[0]) begin             // LB / LBU
		byte_data = mem[address];
		if (memCtrl[3])                    // signed
			readData = { {24{byte_data[7]}}, byte_data };
		else                               // unsigned
			readData = { 24'h000000, byte_data };
	end
	else begin
		readData = 32'hXXXXXXXX;           // illegal size code
	end
end

endmodule
