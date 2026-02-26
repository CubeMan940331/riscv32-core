`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/27 22:09:15
// Design Name: 
// Module Name: mem_sys_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
// Dependencies: 
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module mem_sys_top (
    // A. DDR2 
    output [12:0] DDR2_0_addr, output [2:0] DDR2_0_ba, output DDR2_0_cas_n,
    output [0:0] DDR2_0_ck_n, output [0:0] DDR2_0_ck_p, output [0:0] DDR2_0_cke,
    output [0:0] DDR2_0_cs_n, output [1:0] DDR2_0_dm, inout  [15:0] DDR2_0_dq,
    inout  [1:0] DDR2_0_dqs_n, inout  [1:0] DDR2_0_dqs_p, output [0:0] DDR2_0_odt,
    output DDR2_0_ras_n, output DDR2_0_we_n,
    
    // B. 
    input sys_rst_n_i,
    input mig_ref_clk_i,
    input mig_sys_clk_i,
    input cpu_clk_i,
    
    // C. 
    output mmcm_locked_o,
    output init_calib_complete_o, output ui_addn_clk_o,
    output ui_clk_sync_rst_o, output rom_rst_busy_o, output sram_busy_o,

    // ----------------------------------------------------
    // 1. CPU 
    // ----------------------------------------------------
    // A. CDMA 
    input [31:0] cpu_cdma_addr_i,
    input [31:0] cpu_cdma_data_i,
    output [31:0] cpu_cdma_data_o,
    input except_complete_i,
    output cdma_rdy_o,
    output cdma_exception_o,
    output cdma_introut_o,
    
    // B. D-Cache 
    input  cpu_req_wr_i,
    input  cpu_req_rd_i,
    input  cacheable_i,
    input  [17:0] dtag_i,
    input  [8:0] didx_i,
    input  [2:0] dword_ofs_i,
    input  [31:0] cpu_ddata_i,
    input  [3:0] dmask_i,
    output [31:0] cpu_ddata_o,
    output dcache_rdy_o,
    output dcache_exception_o,
    input  dcache_except_complete_i,
    input  dcache_invalidate_i,
    input  dcache_flush_i,
    input  dcache_writeback_i,
    
    // C. I-Cache 
    input  [18:0] itag_i,
    input  [7:0] iidx_i,
    input  [4:0] iofs_i,
    input  icache_invalidate_i,
    output icache_rdy_o,
    output icache_exception_o,
    input  icache_except_complete_i,
    
    // E. IF-Selector 
    output if_ready_o,
    output [31:0] inst_o
);

    wire req_wr_d, req_rd_d;
    wire req_wr_dma, req_rd_dma;
    
    wire [31:0] dcache_mem_addr_w;
    wire dcache_rm_vld_w, dcache_wm_vld_w;
    wire dcache_rm_rdy_w, dcache_wm_rdy_w;
    wire dcache_rm_complete_w, dcache_wm_complete_w;
    wire dcache_rm_success_w, dcache_wm_success_w;
    wire [255:0] dcache_rm_data_w, dcache_wm_data_w;
    
    wire [31:0] icache_mem_addr_w;
    wire icache_req_rm_w;
    wire icache_rm_rdy_w;
    wire icache_rm_complete_w;
    wire icache_rm_success_w;
    wire [255:0] icache_rm_data_w;
    wire [31:0] pc_i;
    wire [31:0] inst_icache_o;
    wire [31:0] inst_bootrom_o;
    wire [3:0] axi_id_c = 4'b0000;
    
    // A. D-Cache 
    dcache_dma_ctrl u_dcache_dma_ctrl (
        .cpu_req_wr_i(cpu_req_wr_i),
        .cpu_req_rd_i(cpu_req_rd_i),
        .cacheable_i(cacheable_i),
        .req_wr_dma(req_wr_dma),
        .req_rd_dma(req_rd_dma),
        .req_wr_d(req_wr_d), 
        .req_rd_d(req_rd_d)  
    );
    
    // B. D-Cache 核心
    dcache_plus u_dcache_plus (
        .clk(cpu_clk_i),
        .rst_n(sys_rst_n_i),
        
        // CPU 
        .tag_i(dtag_i),
        .idx_i(didx_i),
        .word_ofs_i(dword_ofs_i),
        .cpu_data_i(cpu_ddata_i),
        .mask_i(dmask_i),
        .cpu_req_wr(req_wr_d), 
        .cpu_req_rd(req_rd_d), 
        .cpu_data_o(cpu_ddata_o),
        .dcache_rdy_o(dcache_rdy_o),
        .exception(dcache_exception_o),
        .except_complete(dcache_except_complete_i),
        
        // MMU 
        .invalidate_i(dcache_invalidate_i),
        .flush_i(dcache_flush_i),
        .writeback_i(dcache_writeback_i),
        
        // Mem 
        .mem_addr(dcache_mem_addr_w),
        .rm_rdy(dcache_rm_rdy_w),
        .rm_data(dcache_rm_data_w),
        .rm_success(dcache_rm_success_w),
        .rm_complete(dcache_rm_complete_w),
        .rm_vld(dcache_rm_vld_w),
        .wm_rdy(dcache_wm_rdy_w),
        .wm_data(dcache_wm_data_w),
        .wm_vld(dcache_wm_vld_w),
        .wm_success(dcache_wm_success_w),
        .wm_complete(dcache_wm_complete_w)
    );
    
    // C. I-Cache 
    icache_plus u_icache_plus (
        .clk(cpu_clk_i),
        .rst_n(sys_rst_n_i),
        .tag_i(itag_i),
        .idx_i(iidx_i),
        .ofs_i(iofs_i),
        .invalidate_i(icache_invalidate_i),
        .icache_rdy_o(icache_rdy_o),
        .cpu_inst_o(inst_icache_o),
        .exception(icache_exception_o),
        .except_complete(icache_except_complete_i),
        
        // Mem 
        .rm_rdy(icache_rm_rdy_w),
        .mem_addr(icache_mem_addr_w),
        .rm_success(icache_rm_success_w),
        .rm_complete(icache_rm_complete_w),
        .req_rm(icache_req_rm_w),
        .rm_data(icache_rm_data_w)
    );
    
    
    // D. AXI Bus 
    axi_bus u_axi_bus (
        
        .DDR2_0_addr(DDR2_0_addr), .DDR2_0_ba(DDR2_0_ba), .DDR2_0_cas_n(DDR2_0_cas_n),
        .DDR2_0_ck_n(DDR2_0_ck_n), .DDR2_0_ck_p(DDR2_0_ck_p), .DDR2_0_cke(DDR2_0_cke),
        .DDR2_0_cs_n(DDR2_0_cs_n), .DDR2_0_dm(DDR2_0_dm), .DDR2_0_dq(DDR2_0_dq),
        .DDR2_0_dqs_n(DDR2_0_dqs_n), .DDR2_0_dqs_p(DDR2_0_dqs_p), .DDR2_0_odt(DDR2_0_odt),
        .DDR2_0_ras_n(DDR2_0_ras_n), .DDR2_0_we_n(DDR2_0_we_n),
        
        .cdma_addr_i_0(cpu_cdma_addr_i),
        .cdma_data_i_0(cpu_cdma_data_i),
        .cdma_data_out_0(cpu_cdma_data_o),
        .cdma_except_complete_0(except_complete_i),
        .cdma_exception_0(cdma_exception_o),
        .cdma_rdy_0(cdma_rdy_o),
        .req_rd_dma_0(req_rd_dma),  
        .req_wr_dma_0(req_wr_dma),  
        .cdma_introut_0(cdma_introut_o),
        
        .cpu_clk(cpu_clk_i),
        .mig_ref_clk(mig_ref_clk_i),
        .mig_sys_clk(mig_sys_clk_i),
        .rst_n(sys_rst_n_i),
        .sys_rst_0(sys_rst_n_i),
        
        .mmcm_locked_0(mmcm_locked_o), 
        .sram_busy(sram_busy_o),
        .init_calib_complete_0(init_calib_complete_o),
        .ui_addn_clk_0_0(ui_addn_clk_o),
        .ui_clk_sync_rst_0(ui_clk_sync_rst_o),
        
        .icache_mem_addr(icache_mem_addr_w),
        .icache_req_rm(icache_req_rm_w),
        .icache_rm_complete(icache_rm_complete_w),
        .icache_rm_data(icache_rm_data_w),
        .icache_rm_rdy(icache_rm_rdy_w),
        .icache_rm_success(icache_rm_success_w),
        
        .mem_addr_0(dcache_mem_addr_w),
        
        .rm_vld_0(dcache_rm_vld_w),
        .rm_complete_0(dcache_rm_complete_w),
        .rm_data_0(dcache_rm_data_w),
        .rm_rdy_0(dcache_rm_rdy_w),
        .rm_success_0(dcache_rm_success_w),
        .wm_vld_0(dcache_wm_vld_w),
        .wm_complete_0(dcache_wm_complete_w),
        .wm_data_0(dcache_wm_data_w),
        .wm_rdy_0(dcache_wm_rdy_w),
        .wm_success_0(dcache_wm_success_w),
        .s_axi_arid(axi_id_c), 
        .s_axi_awid(axi_id_c)
    );
    
    // E. IF Selector
    IF_selector u_if_selector(
        .pc_i(pc_i),
        .icache_ready_i(icache_rdy_o),
        .inst_icache_i(inst_icache_o),
        .inst_bootrom_i(inst_bootrom_o),
        .if_ready_o(if_ready_o),
        .inst_o(inst_o)
    );
    
    assign pc_i = {itag_i,iidx_i,iofs_i};
    BootROM_128KB u_bootrom (
      .clka(cpu_clk_i),    // input wire clka
      .addra(pc_i),  // input wire [12 : 0] addra
      .douta(inst_bootrom_o)  // output wire [127 : 0] douta
    );
endmodule
