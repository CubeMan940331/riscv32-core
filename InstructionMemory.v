module InstructionMemory #(parameter size = 256)(
    input [31:0] readAddr,
    output [31:0] inst
);
    integer i;
    reg [7:0] insts [size-1:0];

    assign inst = (readAddr >= size) ? 32'h00000013 : {insts[readAddr], insts[readAddr + 1], insts[readAddr + 2], insts[readAddr + 3]};

    initial begin
        for(i=0;i<size;++i) insts[i]=0;
        $readmemb("TEST_INSTRUCTIONS.txt", insts);
    end

endmodule
