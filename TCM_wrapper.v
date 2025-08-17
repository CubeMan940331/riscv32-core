//////////////////////////////////////////////////////////////////////////////////
// Company: CAS lab
// Create Date: 01/12/2025 09:48:40 PM
// Module Name: TCM_wrapper
//////////////////////////////////////////////////////////////////////////////////
`define ACTUAL_MEM_ENTRY 4096

module TCM_wrapper
(
    input clk,

    // Data memory ports
    input       [3:0] d_rd_mode, // [3]=sign , [2]=word , [1]=half , [0]=byte
    input             d_rd_en,
    output reg [31:0] d_rd_data, 
    input      [31:0] d_addr,
    input             d_wr_valid,
    input      [31:0] d_wr_data,
    
    // Instruction memory ports
    input      [31:0] i_addr,
    output     [31:0] i_data
);

wire [31:0] rd_buf_d;
wire [31:0] wr_buf_d;
wire [31:0] rd_buf_i;

// read buffer
always @(*) begin
    if(d_rd_en) begin
        if(d_rd_mode[2]) begin // LW
            d_rd_data = {rd_buf_d[7:0], rd_buf_d[15:8], rd_buf_d[23:16], rd_buf_d[31:24]};
        end
        else if(d_rd_mode[1]) begin  // LH /LHU
            if(d_rd_mode[3]) begin   // signed
                if(d_addr[1]) begin // LH
                    d_rd_data = {{16{rd_buf_d[23]}}, rd_buf_d[23:16], rd_buf_d[31:24]};
                end
                else begin
                    d_rd_data = {{16{rd_buf_d[7]}}, rd_buf_d[7:0], rd_buf_d[15:8]};
                end
            end
            else begin // LHU
                if(d_addr[1]) begin
                    d_rd_data = {16'b0, rd_buf_d[23:16], rd_buf_d[31:24]};
                end
                else begin
                    d_rd_data = {16'b0, rd_buf_d[7:0], rd_buf_d[15:8]};
                end
            end
        end
        else if(d_rd_mode[0]) begin // LB / LBU
            if(d_rd_mode[3]) begin  // signed 
                case (d_addr[1:0])
                    2'b00: d_rd_data = {{24{rd_buf_d[31]}}, rd_buf_d[31:24]};
                    2'b01: d_rd_data = {{24{rd_buf_d[23]}}, rd_buf_d[23:16]};
                    2'b10: d_rd_data = {{24{rd_buf_d[15]}}, rd_buf_d[15: 8]};
                    2'b11: d_rd_data = {{24{rd_buf_d[ 7]}}, rd_buf_d[ 7: 0]};
                endcase
            end
            else begin              // unsigned
                case (d_addr[1:0])
                    2'b00: d_rd_data = {8'b0, 8'b0, 8'b0, rd_buf_d[31:24]};
                    2'b01: d_rd_data = {8'b0, 8'b0, 8'b0, rd_buf_d[23:16]};
                    2'b10: d_rd_data = {8'b0, 8'b0, 8'b0, rd_buf_d[15: 8]};
                    2'b11: d_rd_data = {8'b0, 8'b0, 8'b0, rd_buf_d[ 7: 0]};
                endcase
            end
        end
        else begin
            d_rd_data = 32'd0;
        end
    end
    else begin
        d_rd_data = 32'd0;
    end
end
// instruction buffer
assign i_data   = {rd_buf_i [7:0], rd_buf_i [15:8], rd_buf_i [23:16], rd_buf_i [31:24]};
// write buffer
assign wr_buf_d = d_rd_mode[2] ? {d_wr_data[7:0], d_wr_data[15:8], d_wr_data[23:16], d_wr_data[31:24]} :
               d_rd_mode[1] ? {d_wr_data[7:0], d_wr_data[15:8], 16'b0} :
               d_rd_mode[0] ? {d_wr_data[7:0], 24'b0} :
               32'b0;

dual_port_dist_ram #(.XLEN(32), .ADDR_WIDTH($clog2(`ACTUAL_MEM_ENTRY)), .DATA_ENTRY(`ACTUAL_MEM_ENTRY))
dual_port_dist_ram_inst
(
    .clk  (clk),
    .we   (d_wr_valid),
    .a    (d_addr[$clog2(`ACTUAL_MEM_ENTRY)+1:2]),
    .dpra (i_addr[$clog2(`ACTUAL_MEM_ENTRY)+1:2]),
    .di   (wr_buf_d),
    .spo  (rd_buf_d),
    .dpo  (rd_buf_i)
);

endmodule
