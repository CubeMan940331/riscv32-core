module InstructionMemory #(parameter size = 2048)(
    input [31:0] address,
    output [31:0] inst
);
    integer i;
    reg [7:0] insts [size-1:0];

    assign inst = (address >= size) ? 32'h00000013 : {insts[address], insts[address + 1], insts[address + 2], insts[address + 3]};

    initial begin
        for(i=0;i<size;++i) insts[i]=0;
        $readmemb("TEST_INSTRUCTIONS.txt", insts);
    end

endmodule
