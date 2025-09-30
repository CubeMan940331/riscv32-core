`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
//
// Create Date: 2025/09/19 00:45:38
// Design Name: 
// Module Name: cpu_axiCdma_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: AXI4-Lite Master interface to control a slave device.
//
// Dependencies: 
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// This module provides the interface for an AXI4-Lite Master.
// Control logic must be implemented elsewhere.
//////////////////////////////////////////////////////////////////////////////////

module cpu_axiCdma_bridge (   
    
    /////////////////////////////////////////////////////////////////////////
    //                    No implement of read behavior                    //
    /////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////
    //                                       //
    //           CPU interface             //
    //                                       //
    ///////////////////////////////////////////
    input aclk,
    input aresetn,
    
    input req_rd_dma,
    input req_wr_dma,
    input [31:0] cdma_addr_i,
    input [31:0] cdma_data_i,
    
    output reg [31:0]cdma_data_out,
    input cdma_except_complete,
    output reg cdma_exception,
    output cdma_rdy,
    //

    
    ///////////////////////////////////////////
    //                                       //
    //           AXI interface             //
    //                                       //
    ///////////////////////////////////////////
    
    // AXI4-Lite Master WA Channel
    output          m_axi_lite_awvalid,
    input           m_axi_lite_awready,
    output reg[31:0]  m_axi_lite_awaddr,
    
    // AXI4-Lite Master WD Channel
    output          m_axi_lite_wvalid,
    input           m_axi_lite_wready,
    output reg [31:0]  m_axi_lite_wdata,
    
    // AXI4-Lite Master B Channel
    input           m_axi_lite_bvalid,
    output   reg    m_axi_lite_bready,
    input   [1:0]   m_axi_lite_bresp,

    // AXI4-Lite Master RA Channel
    output   reg     m_axi_lite_arvalid,
    input           m_axi_lite_arready,
    output  reg [31:0]  m_axi_lite_araddr,
    
    // AXI4-Lite Master RD Channel
    input           m_axi_lite_rvalid,
    output   reg    m_axi_lite_rready,
    input   [31:0]  m_axi_lite_rdata,
    input   [1:0]   m_axi_lite_rresp
);  
    //
    //parameter CMDA_CTRL = 6'h00;
    //parameter CMDA_STATUS = 6'h04;
    //parameter CMDA_SOURCE_ADDR = 6'h18;
    //parameter CMDA_AIM_ADDR = 6'h20;
    //parameter CMDA_BTT = 6'h28;
    
    wire waw_rdy = m_axi_lite_awready & m_axi_lite_wready;
    reg  waw_vld;
    assign m_axi_lite_wvalid = waw_vld;
    assign m_axi_lite_awvalid = waw_vld;
    
    //FSM
    parameter IDLE = 0;
    parameter WRITE = 1;
    parameter WRESP = 2;
    parameter READ = 3;
    parameter RRESP = 4;
    parameter EXCP = 5;
    
    reg [2:0]cs;
    
    assign cdma_rdy = (cs==IDLE);
    
    always@(posedge aclk or negedge aresetn)begin
        if(!aresetn)begin
            cs <= IDLE;
            m_axi_lite_awaddr <= 0;
            m_axi_lite_wdata <= 0;
            waw_vld <= 0;
            m_axi_lite_araddr <= 0;
            m_axi_lite_arvalid <= 0;
            m_axi_lite_bready <= 0;
            m_axi_lite_rready <= 0;
            cdma_exception <= 0;
            cdma_data_out <= 0;
        end
        else begin
            case(cs)
                IDLE :  if(req_wr_dma)begin
                            cs <= WRITE;
                            m_axi_lite_awaddr <= cdma_addr_i;
                            m_axi_lite_wdata <= cdma_data_i;
                            waw_vld <= 1;
                        end
                        else if(req_rd_dma)begin
                            cs <= READ;
                            m_axi_lite_araddr <= cdma_addr_i;
                            m_axi_lite_arvalid <= 1;
                        end
                        else
                            cs <= IDLE;
                WRITE : if(waw_vld & waw_rdy)begin
                            cs <= WRESP;
                            waw_vld <= 0;
                            m_axi_lite_bready <= 1;
                        end
                        else
                            cs <= WRITE;
                WRESP : if(m_axi_lite_bready & m_axi_lite_bvalid)begin
                            m_axi_lite_bready <= 0;
                            if(m_axi_lite_bresp == 0)
                                cs <= IDLE;
                            else begin
                                cs <= EXCP;
                                cdma_exception <= 1;
                            end
                        end
                        else
                            cs <= WRESP;
                READ :  if(m_axi_lite_arvalid & m_axi_lite_arready)begin
                            cs <= RRESP;
                            m_axi_lite_arvalid <= 0;
                            m_axi_lite_rready <= 1;
                            cdma_data_out <= m_axi_lite_rdata;
                        end
                        else 
                            cs <= READ;
                RRESP : if(m_axi_lite_rvalid & m_axi_lite_rready)begin
                            m_axi_lite_rready <= 0;
                            if(m_axi_lite_rresp == 0)
                                cs <= IDLE;
                            else begin
                                cs <= EXCP;
                                cdma_exception <= 1;
                            end
                        end
                        else
                            cs <= RRESP;   
                EXCP :  if(cdma_except_complete)begin
                            cs <= IDLE;
                            cdma_exception <= 0;
                        end
                        else
                            cs <= EXCP;
                default : cs <= IDLE;
            endcase
        end
    end
    
endmodule