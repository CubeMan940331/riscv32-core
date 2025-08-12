module status_ramd_1x512(
    input [8:0]a,
    input d,
	input clk,
    input we,
    output spo
);
    reg ram [0:511];
	
	integer i;
	initial begin
		for( i = 0; i < 512; i = i + 1)begin
			ram[i] = 0;
		end
	end
	
    always@(posedge clk)begin
		ram[a] = we ? d : ram[a];
	end
	
	assign spo = ram[a];

    
    //reset發生時，不清空(直接將valid改成0就好)
    
endmodule