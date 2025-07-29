// control pipeline register
// stall or insert nop
module PipelineCtrl(
    input inst_br_taken,
    input csr_br_taken,
    input [3:0] stall,
    
    output reg pc_en,
    
    output reg ID_en,
    output reg ID_clear,

    output reg EX_en,
    output reg EX_clear,

    output reg MEM_en,
    output reg MEM_clear
);
/*
stall
0: not stall
1: stall for IF
2: stall for ID
3: stall for EX
4: stall for MEM
5: stall for WB

only stall for EX for now
*/

always @(*)begin
    pc_en=1;

    ID_en=1;
    ID_clear=0;

    EX_en=1;
    EX_clear=0;

    MEM_en=1;
    MEM_clear=0;

    if(csr_br_taken) begin
        // branch determined at MEM stage
        // clear Id, EX next clock
        ID_clear=1;
        EX_clear=1;
        MEM_clear=1;
    end
    else if(inst_br_taken)begin
        // branch determined at EX stage
        // clear Id, EX next clock
        ID_clear=1;
        EX_clear=1;
    end
    else case(stall)
        4'd3: begin
            // freeze IF, ID
            pc_en=0;
            ID_en=0;
            // insert nop to EX
            EX_clear = 1;
        end
        default:;
    endcase
end
endmodule
