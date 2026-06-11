// placeholder for CLINT (Core Local Interruptor) module
module CLINT (
    input         clk,
    input         rst_n,

    input  [31:0] addr_i,
    input         wr_en_i,
    input         rd_en_i,
    input  [3:0]  wr_mask_i,
    input  [31:0] wr_data_i,
    output reg [31:0] rd_data_o,
    output        available_o,

    output        mtip_o,
    output        msip_o
);

localparam [31:0] CLINT_BASE          = 32'h2000_0000;
localparam [31:0] CLINT_MSIP          = CLINT_BASE + 32'h0000;
localparam [31:0] CLINT_MTIMECMP_LO   = CLINT_BASE + 32'h0008;
localparam [31:0] CLINT_MTIMECMP_HI   = CLINT_BASE + 32'h000c;
localparam [31:0] CLINT_MTIME_LO      = CLINT_BASE + 32'h0010;
localparam [31:0] CLINT_MTIME_HI      = CLINT_BASE + 32'h0014;

reg [63:0] mtime_q;
reg [63:0] mtimecmp_q;
reg        msip_q;

function [31:0] apply_wmask;
    input [31:0] old_data;
    input [31:0] new_data;
    input [3:0]  mask;
    begin
        apply_wmask = old_data;
        if (mask[0]) apply_wmask[7:0]   = new_data[7:0];
        if (mask[1]) apply_wmask[15:8]  = new_data[15:8];
        if (mask[2]) apply_wmask[23:16] = new_data[23:16];
        if (mask[3]) apply_wmask[31:24] = new_data[31:24];
    end
endfunction

reg [63:0] mtime_next_r;
reg [63:0] mtimecmp_next_r;
reg        msip_next_r;

always @(*) begin
    mtime_next_r    = mtime_q + 64'd1;
    mtimecmp_next_r = mtimecmp_q;
    msip_next_r     = msip_q;

    if (wr_en_i) begin
        case (addr_i)
            CLINT_MSIP:
                msip_next_r = |(apply_wmask({31'b0, msip_q}, wr_data_i, wr_mask_i) & 32'h0000_0001);
            CLINT_MTIMECMP_LO:
                mtimecmp_next_r[31:0] = apply_wmask(mtimecmp_q[31:0], wr_data_i, wr_mask_i);
            CLINT_MTIMECMP_HI:
                mtimecmp_next_r[63:32] = apply_wmask(mtimecmp_q[63:32], wr_data_i, wr_mask_i);
            CLINT_MTIME_LO:
                mtime_next_r[31:0] = apply_wmask(mtime_q[31:0], wr_data_i, wr_mask_i);
            CLINT_MTIME_HI:
                mtime_next_r[63:32] = apply_wmask(mtime_q[63:32], wr_data_i, wr_mask_i);
            default: begin
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mtime_q    <= 64'b0;
        mtimecmp_q <= 64'hffff_ffff_ffff_ffff;
        msip_q     <= 1'b0;
    end else begin
        mtime_q    <= mtime_next_r;
        mtimecmp_q <= mtimecmp_next_r;
        msip_q     <= msip_next_r;
    end
end

always @(*) begin
    case (addr_i)
        CLINT_MSIP:        rd_data_o = {31'b0, msip_q};
        CLINT_MTIMECMP_LO: rd_data_o = mtimecmp_q[31:0];
        CLINT_MTIMECMP_HI: rd_data_o = mtimecmp_q[63:32];
        CLINT_MTIME_LO:    rd_data_o = mtime_q[31:0];
        CLINT_MTIME_HI:    rd_data_o = mtime_q[63:32];
        default:           rd_data_o = 32'b0;
    endcase
end

assign available_o = 1'b1;
assign mtip_o      = (mtime_q >= mtimecmp_q);
assign msip_o      = msip_q;

endmodule
