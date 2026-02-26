//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Thu Oct  9 20:39:57 2025
//Host        : LAPTOP-AHEFCFON running 64-bit major release  (build 9200)
//Command     : generate_target axi_bus.bd
//Design      : axi_bus
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "axi_bus,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=axi_bus,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=8,numReposBlks=8,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=3,numPkgbdBlks=0,bdsource=USER,da_board_cnt=1,da_bram_cntlr_cnt=1,da_clkrst_cnt=7,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "axi_bus.hwdef" *) 
module axi_bus
   (DDR2_0_addr,
    DDR2_0_ba,
    DDR2_0_cas_n,
    DDR2_0_ck_n,
    DDR2_0_ck_p,
    DDR2_0_cke,
    DDR2_0_cs_n,
    DDR2_0_dm,
    DDR2_0_dq,
    DDR2_0_dqs_n,
    DDR2_0_dqs_p,
    DDR2_0_odt,
    DDR2_0_ras_n,
    DDR2_0_we_n,
    cdma_addr_i_0,
    cdma_data_i_0,
    cdma_data_out_0,
    cdma_except_complete_0,
    cdma_exception_0,
    cdma_introut_0,
    cdma_rdy_0,
    cpu_clk,
    icache_mem_addr,
    icache_req_rm,
    icache_rm_complete,
    icache_rm_data,
    icache_rm_rdy,
    icache_rm_success,
    init_calib_complete_0,
    mem_addr_0,
    mig_ref_clk,
    mig_sys_clk,
    mmcm_locked_0,
    req_rd_dma_0,
    req_wr_dma_0,
    rm_complete_0,
    rm_data_0,
    rm_rdy_0,
    rm_success_0,
    rm_vld_0,
    rst_n,
    s_axi_arid,
    s_axi_awid,
    sram_busy,
    sys_rst_0,
    ui_addn_clk_0_0,
    ui_clk_sync_rst_0,
    wm_complete_0,
    wm_data_0,
    wm_rdy_0,
    wm_success_0,
    wm_vld_0);
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 ADDR" *) (* X_INTERFACE_MODE = "Master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DDR2_0, AXI_ARBITRATION_SCHEME TDM, BURST_LENGTH 8, CAN_DEBUG false, CAS_LATENCY 11, CAS_WRITE_LATENCY 11, CS_ENABLED true, DATA_MASK_ENABLED true, DATA_WIDTH 8, MEMORY_TYPE COMPONENTS, MEM_ADDR_MAP ROW_COLUMN_BANK, SLOT Single, TIMEPERIOD_PS 1250" *) output [12:0]DDR2_0_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 BA" *) output [2:0]DDR2_0_ba;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 CAS_N" *) output DDR2_0_cas_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 CK_N" *) output [0:0]DDR2_0_ck_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 CK_P" *) output [0:0]DDR2_0_ck_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 CKE" *) output [0:0]DDR2_0_cke;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 CS_N" *) output [0:0]DDR2_0_cs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 DM" *) output [1:0]DDR2_0_dm;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 DQ" *) inout [15:0]DDR2_0_dq;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 DQS_N" *) inout [1:0]DDR2_0_dqs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 DQS_P" *) inout [1:0]DDR2_0_dqs_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 ODT" *) output [0:0]DDR2_0_odt;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 RAS_N" *) output DDR2_0_ras_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR2_0 WE_N" *) output DDR2_0_we_n;
  input [31:0]cdma_addr_i_0;
  input [31:0]cdma_data_i_0;
  output [31:0]cdma_data_out_0;
  input cdma_except_complete_0;
  output cdma_exception_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 INTR.CDMA_INTROUT_0 INTERRUPT" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME INTR.CDMA_INTROUT_0, PortWidth 1, SENSITIVITY LEVEL_HIGH" *) output cdma_introut_0;
  output cdma_rdy_0;
  input cpu_clk;
  input [31:0]icache_mem_addr;
  input icache_req_rm;
  output icache_rm_complete;
  output [255:0]icache_rm_data;
  output icache_rm_rdy;
  output icache_rm_success;
  output init_calib_complete_0;
  input [31:0]mem_addr_0;
  input mig_ref_clk;
  input mig_sys_clk;
  output mmcm_locked_0;
  input req_rd_dma_0;
  input req_wr_dma_0;
  output rm_complete_0;
  output [255:0]rm_data_0;
  output rm_rdy_0;
  output rm_success_0;
  input rm_vld_0;
  input rst_n;
  input [3:0]s_axi_arid;
  input [3:0]s_axi_awid;
  output sram_busy;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.SYS_RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.SYS_RST_0, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input sys_rst_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.UI_ADDN_CLK_0_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.UI_ADDN_CLK_0_0, CLK_DOMAIN axi_bus_mig_7series_0_0_ui_clk, FREQ_HZ 200000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0" *) output ui_addn_clk_0_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.UI_CLK_SYNC_RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.UI_CLK_SYNC_RST_0, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) output ui_clk_sync_rst_0;
  output wm_complete_0;
  input [255:0]wm_data_0;
  output wm_rdy_0;
  output wm_success_0;
  input wm_vld_0;

  wire [12:0]DDR2_0_addr;
  wire [2:0]DDR2_0_ba;
  wire DDR2_0_cas_n;
  wire [0:0]DDR2_0_ck_n;
  wire [0:0]DDR2_0_ck_p;
  wire [0:0]DDR2_0_cke;
  wire [0:0]DDR2_0_cs_n;
  wire [1:0]DDR2_0_dm;
  wire [15:0]DDR2_0_dq;
  wire [1:0]DDR2_0_dqs_n;
  wire [1:0]DDR2_0_dqs_p;
  wire [0:0]DDR2_0_odt;
  wire DDR2_0_ras_n;
  wire DDR2_0_we_n;
  wire [127:0]Sram_8KB_douta;
  wire [31:0]axi_cdma_0_m_axi_araddr;
  wire [1:0]axi_cdma_0_m_axi_arburst;
  wire [3:0]axi_cdma_0_m_axi_arcache;
  wire [7:0]axi_cdma_0_m_axi_arlen;
  wire [2:0]axi_cdma_0_m_axi_arprot;
  wire [2:0]axi_cdma_0_m_axi_arsize;
  wire axi_cdma_0_m_axi_arvalid;
  wire [31:0]axi_cdma_0_m_axi_awaddr;
  wire [1:0]axi_cdma_0_m_axi_awburst;
  wire [3:0]axi_cdma_0_m_axi_awcache;
  wire [7:0]axi_cdma_0_m_axi_awlen;
  wire [2:0]axi_cdma_0_m_axi_awprot;
  wire [2:0]axi_cdma_0_m_axi_awsize;
  wire axi_cdma_0_m_axi_awvalid;
  wire axi_cdma_0_m_axi_bready;
  wire axi_cdma_0_m_axi_rready;
  wire [127:0]axi_cdma_0_m_axi_wdata;
  wire axi_cdma_0_m_axi_wlast;
  wire [15:0]axi_cdma_0_m_axi_wstrb;
  wire axi_cdma_0_m_axi_wvalid;
  wire axi_cdma_0_s_axi_lite_arready;
  wire axi_cdma_0_s_axi_lite_awready;
  wire [1:0]axi_cdma_0_s_axi_lite_bresp;
  wire axi_cdma_0_s_axi_lite_bvalid;
  wire [31:0]axi_cdma_0_s_axi_lite_rdata;
  wire [1:0]axi_cdma_0_s_axi_lite_rresp;
  wire axi_cdma_0_s_axi_lite_rvalid;
  wire axi_cdma_0_s_axi_lite_wready;
  wire axi_sram_ctrl_BRAM_PORTA_CLK;
  wire [12:0]axi_sram_ctrl_bram_addr_a;
  wire axi_sram_ctrl_bram_en_a;
  wire axi_sram_ctrl_bram_rst_a;
  wire [15:0]axi_sram_ctrl_bram_we_a;
  wire [127:0]axi_sram_ctrl_bram_wrdata_a;
  wire axi_sram_ctrl_s_axi_arready;
  wire axi_sram_ctrl_s_axi_awready;
  wire [1:0]axi_sram_ctrl_s_axi_bresp;
  wire axi_sram_ctrl_s_axi_bvalid;
  wire [127:0]axi_sram_ctrl_s_axi_rdata;
  wire axi_sram_ctrl_s_axi_rlast;
  wire [1:0]axi_sram_ctrl_s_axi_rresp;
  wire axi_sram_ctrl_s_axi_rvalid;
  wire axi_sram_ctrl_s_axi_wready;
  wire [31:0]cdma_addr_i_0;
  wire [31:0]cdma_data_i_0;
  wire [31:0]cdma_data_out_0;
  wire cdma_except_complete_0;
  wire cdma_exception_0;
  wire cdma_introut_0;
  wire cdma_rdy_0;
  wire [31:0]cpu_axiCdma_bridge_0_m_axi_araddr;
  wire cpu_axiCdma_bridge_0_m_axi_arvalid;
  wire [31:0]cpu_axiCdma_bridge_0_m_axi_awaddr;
  wire cpu_axiCdma_bridge_0_m_axi_awvalid;
  wire cpu_axiCdma_bridge_0_m_axi_bready;
  wire cpu_axiCdma_bridge_0_m_axi_rready;
  wire [31:0]cpu_axiCdma_bridge_0_m_axi_wdata;
  wire cpu_axiCdma_bridge_0_m_axi_wvalid;
  wire cpu_clk;
  wire [31:0]dcache_axiBus_bridge_0_M_AXI_ARADDR;
  wire [1:0]dcache_axiBus_bridge_0_M_AXI_ARBURST;
  wire [3:0]dcache_axiBus_bridge_0_M_AXI_ARCACHE;
  wire [3:0]dcache_axiBus_bridge_0_M_AXI_ARID;
  wire [7:0]dcache_axiBus_bridge_0_M_AXI_ARLEN;
  wire dcache_axiBus_bridge_0_M_AXI_ARLOCK;
  wire [2:0]dcache_axiBus_bridge_0_M_AXI_ARPROT;
  wire [3:0]dcache_axiBus_bridge_0_M_AXI_ARQOS;
  wire [2:0]dcache_axiBus_bridge_0_M_AXI_ARSIZE;
  wire [15:0]dcache_axiBus_bridge_0_M_AXI_ARUSER;
  wire dcache_axiBus_bridge_0_M_AXI_ARVALID;
  wire [31:0]dcache_axiBus_bridge_0_M_AXI_AWADDR;
  wire [1:0]dcache_axiBus_bridge_0_M_AXI_AWBURST;
  wire [3:0]dcache_axiBus_bridge_0_M_AXI_AWCACHE;
  wire [3:0]dcache_axiBus_bridge_0_M_AXI_AWID;
  wire [7:0]dcache_axiBus_bridge_0_M_AXI_AWLEN;
  wire dcache_axiBus_bridge_0_M_AXI_AWLOCK;
  wire [2:0]dcache_axiBus_bridge_0_M_AXI_AWPROT;
  wire [3:0]dcache_axiBus_bridge_0_M_AXI_AWQOS;
  wire [2:0]dcache_axiBus_bridge_0_M_AXI_AWSIZE;
  wire [15:0]dcache_axiBus_bridge_0_M_AXI_AWUSER;
  wire dcache_axiBus_bridge_0_M_AXI_AWVALID;
  wire dcache_axiBus_bridge_0_M_AXI_BREADY;
  wire dcache_axiBus_bridge_0_M_AXI_RREADY;
  wire [255:0]dcache_axiBus_bridge_0_M_AXI_WDATA;
  wire dcache_axiBus_bridge_0_M_AXI_WLAST;
  wire [31:0]dcache_axiBus_bridge_0_M_AXI_WSTRB;
  wire dcache_axiBus_bridge_0_M_AXI_WVALID;
  wire [31:0]icache_axiBus_bridge_0_M_AXI_ARADDR;
  wire [1:0]icache_axiBus_bridge_0_M_AXI_ARBURST;
  wire [3:0]icache_axiBus_bridge_0_M_AXI_ARCACHE;
  wire [3:0]icache_axiBus_bridge_0_M_AXI_ARID;
  wire [7:0]icache_axiBus_bridge_0_M_AXI_ARLEN;
  wire icache_axiBus_bridge_0_M_AXI_ARLOCK;
  wire [2:0]icache_axiBus_bridge_0_M_AXI_ARPROT;
  wire [3:0]icache_axiBus_bridge_0_M_AXI_ARQOS;
  wire [2:0]icache_axiBus_bridge_0_M_AXI_ARSIZE;
  wire [15:0]icache_axiBus_bridge_0_M_AXI_ARUSER;
  wire icache_axiBus_bridge_0_M_AXI_ARVALID;
  wire [3:0]icache_axiBus_bridge_0_M_AXI_RID;
  wire icache_axiBus_bridge_0_M_AXI_RREADY;
  wire [31:0]icache_mem_addr;
  wire icache_req_rm;
  wire icache_rm_complete;
  wire [255:0]icache_rm_data;
  wire icache_rm_rdy;
  wire icache_rm_success;
  wire init_calib_complete_0;
  wire [31:0]mem_addr_0;
  wire mig_7series_0_s_axi_arready;
  wire mig_7series_0_s_axi_awready;
  wire [1:0]mig_7series_0_s_axi_bresp;
  wire mig_7series_0_s_axi_bvalid;
  wire [127:0]mig_7series_0_s_axi_rdata;
  wire mig_7series_0_s_axi_rlast;
  wire [1:0]mig_7series_0_s_axi_rresp;
  wire mig_7series_0_s_axi_rvalid;
  wire mig_7series_0_s_axi_wready;
  wire mig_7series_0_ui_clk;
  wire mig_ref_clk;
  wire mig_sys_clk;
  wire mmcm_locked_0;
  wire req_rd_dma_0;
  wire req_wr_dma_0;
  wire rm_complete_0;
  wire [255:0]rm_data_0;
  wire rm_rdy_0;
  wire rm_success_0;
  wire rm_vld_0;
  wire rst_n;
  wire [3:0]s_axi_arid;
  wire [3:0]s_axi_awid;
  wire [26:0]smartconnect_0_M00_AXI_araddr;
  wire [1:0]smartconnect_0_M00_AXI_arburst;
  wire [3:0]smartconnect_0_M00_AXI_arcache;
  wire [7:0]smartconnect_0_M00_AXI_arlen;
  wire [0:0]smartconnect_0_M00_AXI_arlock;
  wire [2:0]smartconnect_0_M00_AXI_arprot;
  wire [3:0]smartconnect_0_M00_AXI_arqos;
  wire [2:0]smartconnect_0_M00_AXI_arsize;
  wire smartconnect_0_M00_AXI_arvalid;
  wire [26:0]smartconnect_0_M00_AXI_awaddr;
  wire [1:0]smartconnect_0_M00_AXI_awburst;
  wire [3:0]smartconnect_0_M00_AXI_awcache;
  wire [7:0]smartconnect_0_M00_AXI_awlen;
  wire [0:0]smartconnect_0_M00_AXI_awlock;
  wire [2:0]smartconnect_0_M00_AXI_awprot;
  wire [3:0]smartconnect_0_M00_AXI_awqos;
  wire [2:0]smartconnect_0_M00_AXI_awsize;
  wire smartconnect_0_M00_AXI_awvalid;
  wire smartconnect_0_M00_AXI_bready;
  wire smartconnect_0_M00_AXI_rready;
  wire [127:0]smartconnect_0_M00_AXI_wdata;
  wire smartconnect_0_M00_AXI_wlast;
  wire [15:0]smartconnect_0_M00_AXI_wstrb;
  wire smartconnect_0_M00_AXI_wvalid;
  wire [12:0]smartconnect_0_M02_AXI_araddr;
  wire [1:0]smartconnect_0_M02_AXI_arburst;
  wire [3:0]smartconnect_0_M02_AXI_arcache;
  wire [7:0]smartconnect_0_M02_AXI_arlen;
  wire [0:0]smartconnect_0_M02_AXI_arlock;
  wire [2:0]smartconnect_0_M02_AXI_arprot;
  wire [2:0]smartconnect_0_M02_AXI_arsize;
  wire smartconnect_0_M02_AXI_arvalid;
  wire [12:0]smartconnect_0_M02_AXI_awaddr;
  wire [1:0]smartconnect_0_M02_AXI_awburst;
  wire [3:0]smartconnect_0_M02_AXI_awcache;
  wire [7:0]smartconnect_0_M02_AXI_awlen;
  wire [0:0]smartconnect_0_M02_AXI_awlock;
  wire [2:0]smartconnect_0_M02_AXI_awprot;
  wire [2:0]smartconnect_0_M02_AXI_awsize;
  wire smartconnect_0_M02_AXI_awvalid;
  wire smartconnect_0_M02_AXI_bready;
  wire smartconnect_0_M02_AXI_rready;
  wire [127:0]smartconnect_0_M02_AXI_wdata;
  wire smartconnect_0_M02_AXI_wlast;
  wire [15:0]smartconnect_0_M02_AXI_wstrb;
  wire smartconnect_0_M02_AXI_wvalid;
  wire smartconnect_0_S00_AXI_arready;
  wire [255:0]smartconnect_0_S00_AXI_rdata;
  wire smartconnect_0_S00_AXI_rlast;
  wire [1:0]smartconnect_0_S00_AXI_rresp;
  wire smartconnect_0_S00_AXI_rvalid;
  wire smartconnect_0_S01_AXI_arready;
  wire smartconnect_0_S01_AXI_awready;
  wire [1:0]smartconnect_0_S01_AXI_bresp;
  wire smartconnect_0_S01_AXI_bvalid;
  wire [127:0]smartconnect_0_S01_AXI_rdata;
  wire smartconnect_0_S01_AXI_rlast;
  wire [1:0]smartconnect_0_S01_AXI_rresp;
  wire smartconnect_0_S01_AXI_rvalid;
  wire smartconnect_0_S01_AXI_wready;
  wire smartconnect_0_S02_AXI_arready;
  wire smartconnect_0_S02_AXI_awready;
  wire [3:0]smartconnect_0_S02_AXI_bid;
  wire [1:0]smartconnect_0_S02_AXI_bresp;
  wire smartconnect_0_S02_AXI_bvalid;
  wire [255:0]smartconnect_0_S02_AXI_rdata;
  wire [3:0]smartconnect_0_S02_AXI_rid;
  wire smartconnect_0_S02_AXI_rlast;
  wire [1:0]smartconnect_0_S02_AXI_rresp;
  wire smartconnect_0_S02_AXI_rvalid;
  wire smartconnect_0_S02_AXI_wready;
  wire sram_busy;
  wire sys_rst_0;
  wire ui_addn_clk_0_0;
  wire ui_clk_sync_rst_0;
  wire wm_complete_0;
  wire [255:0]wm_data_0;
  wire wm_rdy_0;
  wire wm_success_0;
  wire wm_vld_0;

  axi_bus_mig_7series_0_0 AXI_mig_7series
       (.aresetn(rst_n),
        .clk_ref_i(mig_ref_clk),
        .ddr2_addr(DDR2_0_addr),
        .ddr2_ba(DDR2_0_ba),
        .ddr2_cas_n(DDR2_0_cas_n),
        .ddr2_ck_n(DDR2_0_ck_n),
        .ddr2_ck_p(DDR2_0_ck_p),
        .ddr2_cke(DDR2_0_cke),
        .ddr2_cs_n(DDR2_0_cs_n),
        .ddr2_dm(DDR2_0_dm),
        .ddr2_dq(DDR2_0_dq),
        .ddr2_dqs_n(DDR2_0_dqs_n),
        .ddr2_dqs_p(DDR2_0_dqs_p),
        .ddr2_odt(DDR2_0_odt),
        .ddr2_ras_n(DDR2_0_ras_n),
        .ddr2_we_n(DDR2_0_we_n),
        .init_calib_complete(init_calib_complete_0),
        .mmcm_locked(mmcm_locked_0),
        .s_axi_araddr(smartconnect_0_M00_AXI_araddr),
        .s_axi_arburst(smartconnect_0_M00_AXI_arburst),
        .s_axi_arcache(smartconnect_0_M00_AXI_arcache),
        .s_axi_arid(s_axi_arid),
        .s_axi_arlen(smartconnect_0_M00_AXI_arlen),
        .s_axi_arlock(smartconnect_0_M00_AXI_arlock),
        .s_axi_arprot(smartconnect_0_M00_AXI_arprot),
        .s_axi_arqos(smartconnect_0_M00_AXI_arqos),
        .s_axi_arready(mig_7series_0_s_axi_arready),
        .s_axi_arsize(smartconnect_0_M00_AXI_arsize),
        .s_axi_arvalid(smartconnect_0_M00_AXI_arvalid),
        .s_axi_awaddr(smartconnect_0_M00_AXI_awaddr),
        .s_axi_awburst(smartconnect_0_M00_AXI_awburst),
        .s_axi_awcache(smartconnect_0_M00_AXI_awcache),
        .s_axi_awid(s_axi_awid),
        .s_axi_awlen(smartconnect_0_M00_AXI_awlen),
        .s_axi_awlock(smartconnect_0_M00_AXI_awlock),
        .s_axi_awprot(smartconnect_0_M00_AXI_awprot),
        .s_axi_awqos(smartconnect_0_M00_AXI_awqos),
        .s_axi_awready(mig_7series_0_s_axi_awready),
        .s_axi_awsize(smartconnect_0_M00_AXI_awsize),
        .s_axi_awvalid(smartconnect_0_M00_AXI_awvalid),
        .s_axi_bready(smartconnect_0_M00_AXI_bready),
        .s_axi_bresp(mig_7series_0_s_axi_bresp),
        .s_axi_bvalid(mig_7series_0_s_axi_bvalid),
        .s_axi_rdata(mig_7series_0_s_axi_rdata),
        .s_axi_rlast(mig_7series_0_s_axi_rlast),
        .s_axi_rready(smartconnect_0_M00_AXI_rready),
        .s_axi_rresp(mig_7series_0_s_axi_rresp),
        .s_axi_rvalid(mig_7series_0_s_axi_rvalid),
        .s_axi_wdata(smartconnect_0_M00_AXI_wdata),
        .s_axi_wlast(smartconnect_0_M00_AXI_wlast),
        .s_axi_wready(mig_7series_0_s_axi_wready),
        .s_axi_wstrb(smartconnect_0_M00_AXI_wstrb),
        .s_axi_wvalid(smartconnect_0_M00_AXI_wvalid),
        .sys_clk_i(mig_sys_clk),
        .sys_rst(sys_rst_0),
        .ui_addn_clk_0(ui_addn_clk_0_0),
        .ui_clk(mig_7series_0_ui_clk),
        .ui_clk_sync_rst(ui_clk_sync_rst_0));
  axi_bus_blk_mem_gen_0_2 Sram_8KB
       (.addra(axi_sram_ctrl_bram_addr_a[8:0]),
        .clka(axi_sram_ctrl_BRAM_PORTA_CLK),
        .dina(axi_sram_ctrl_bram_wrdata_a),
        .douta(Sram_8KB_douta),
        .ena(axi_sram_ctrl_bram_en_a),
        .rsta(axi_sram_ctrl_bram_rst_a),
        .rsta_busy(sram_busy),
        .wea(axi_sram_ctrl_bram_we_a));
  axi_bus_axi_cdma_0_0 axi_cdma_0
       (.cdma_introut(cdma_introut_0),
        .m_axi_aclk(cpu_clk),
        .m_axi_araddr(axi_cdma_0_m_axi_araddr),
        .m_axi_arburst(axi_cdma_0_m_axi_arburst),
        .m_axi_arcache(axi_cdma_0_m_axi_arcache),
        .m_axi_arlen(axi_cdma_0_m_axi_arlen),
        .m_axi_arprot(axi_cdma_0_m_axi_arprot),
        .m_axi_arready(smartconnect_0_S01_AXI_arready),
        .m_axi_arsize(axi_cdma_0_m_axi_arsize),
        .m_axi_arvalid(axi_cdma_0_m_axi_arvalid),
        .m_axi_awaddr(axi_cdma_0_m_axi_awaddr),
        .m_axi_awburst(axi_cdma_0_m_axi_awburst),
        .m_axi_awcache(axi_cdma_0_m_axi_awcache),
        .m_axi_awlen(axi_cdma_0_m_axi_awlen),
        .m_axi_awprot(axi_cdma_0_m_axi_awprot),
        .m_axi_awready(smartconnect_0_S01_AXI_awready),
        .m_axi_awsize(axi_cdma_0_m_axi_awsize),
        .m_axi_awvalid(axi_cdma_0_m_axi_awvalid),
        .m_axi_bready(axi_cdma_0_m_axi_bready),
        .m_axi_bresp(smartconnect_0_S01_AXI_bresp),
        .m_axi_bvalid(smartconnect_0_S01_AXI_bvalid),
        .m_axi_rdata(smartconnect_0_S01_AXI_rdata),
        .m_axi_rlast(smartconnect_0_S01_AXI_rlast),
        .m_axi_rready(axi_cdma_0_m_axi_rready),
        .m_axi_rresp(smartconnect_0_S01_AXI_rresp),
        .m_axi_rvalid(smartconnect_0_S01_AXI_rvalid),
        .m_axi_wdata(axi_cdma_0_m_axi_wdata),
        .m_axi_wlast(axi_cdma_0_m_axi_wlast),
        .m_axi_wready(smartconnect_0_S01_AXI_wready),
        .m_axi_wstrb(axi_cdma_0_m_axi_wstrb),
        .m_axi_wvalid(axi_cdma_0_m_axi_wvalid),
        .s_axi_lite_aclk(cpu_clk),
        .s_axi_lite_araddr(cpu_axiCdma_bridge_0_m_axi_araddr[5:0]),
        .s_axi_lite_aresetn(rst_n),
        .s_axi_lite_arready(axi_cdma_0_s_axi_lite_arready),
        .s_axi_lite_arvalid(cpu_axiCdma_bridge_0_m_axi_arvalid),
        .s_axi_lite_awaddr(cpu_axiCdma_bridge_0_m_axi_awaddr[5:0]),
        .s_axi_lite_awready(axi_cdma_0_s_axi_lite_awready),
        .s_axi_lite_awvalid(cpu_axiCdma_bridge_0_m_axi_awvalid),
        .s_axi_lite_bready(cpu_axiCdma_bridge_0_m_axi_bready),
        .s_axi_lite_bresp(axi_cdma_0_s_axi_lite_bresp),
        .s_axi_lite_bvalid(axi_cdma_0_s_axi_lite_bvalid),
        .s_axi_lite_rdata(axi_cdma_0_s_axi_lite_rdata),
        .s_axi_lite_rready(cpu_axiCdma_bridge_0_m_axi_rready),
        .s_axi_lite_rresp(axi_cdma_0_s_axi_lite_rresp),
        .s_axi_lite_rvalid(axi_cdma_0_s_axi_lite_rvalid),
        .s_axi_lite_wdata(cpu_axiCdma_bridge_0_m_axi_wdata),
        .s_axi_lite_wready(axi_cdma_0_s_axi_lite_wready),
        .s_axi_lite_wvalid(cpu_axiCdma_bridge_0_m_axi_wvalid));
  axi_bus_axi_bram_ctrl_0_1 axi_sram_ctrl
       (.bram_addr_a(axi_sram_ctrl_bram_addr_a),
        .bram_clk_a(axi_sram_ctrl_BRAM_PORTA_CLK),
        .bram_en_a(axi_sram_ctrl_bram_en_a),
        .bram_rddata_a(Sram_8KB_douta),
        .bram_rst_a(axi_sram_ctrl_bram_rst_a),
        .bram_we_a(axi_sram_ctrl_bram_we_a),
        .bram_wrdata_a(axi_sram_ctrl_bram_wrdata_a),
        .s_axi_aclk(cpu_clk),
        .s_axi_araddr(smartconnect_0_M02_AXI_araddr),
        .s_axi_arburst(smartconnect_0_M02_AXI_arburst),
        .s_axi_arcache(smartconnect_0_M02_AXI_arcache),
        .s_axi_aresetn(rst_n),
        .s_axi_arlen(smartconnect_0_M02_AXI_arlen),
        .s_axi_arlock(smartconnect_0_M02_AXI_arlock),
        .s_axi_arprot(smartconnect_0_M02_AXI_arprot),
        .s_axi_arready(axi_sram_ctrl_s_axi_arready),
        .s_axi_arsize(smartconnect_0_M02_AXI_arsize),
        .s_axi_arvalid(smartconnect_0_M02_AXI_arvalid),
        .s_axi_awaddr(smartconnect_0_M02_AXI_awaddr),
        .s_axi_awburst(smartconnect_0_M02_AXI_awburst),
        .s_axi_awcache(smartconnect_0_M02_AXI_awcache),
        .s_axi_awlen(smartconnect_0_M02_AXI_awlen),
        .s_axi_awlock(smartconnect_0_M02_AXI_awlock),
        .s_axi_awprot(smartconnect_0_M02_AXI_awprot),
        .s_axi_awready(axi_sram_ctrl_s_axi_awready),
        .s_axi_awsize(smartconnect_0_M02_AXI_awsize),
        .s_axi_awvalid(smartconnect_0_M02_AXI_awvalid),
        .s_axi_bready(smartconnect_0_M02_AXI_bready),
        .s_axi_bresp(axi_sram_ctrl_s_axi_bresp),
        .s_axi_bvalid(axi_sram_ctrl_s_axi_bvalid),
        .s_axi_rdata(axi_sram_ctrl_s_axi_rdata),
        .s_axi_rlast(axi_sram_ctrl_s_axi_rlast),
        .s_axi_rready(smartconnect_0_M02_AXI_rready),
        .s_axi_rresp(axi_sram_ctrl_s_axi_rresp),
        .s_axi_rvalid(axi_sram_ctrl_s_axi_rvalid),
        .s_axi_wdata(smartconnect_0_M02_AXI_wdata),
        .s_axi_wlast(smartconnect_0_M02_AXI_wlast),
        .s_axi_wready(axi_sram_ctrl_s_axi_wready),
        .s_axi_wstrb(smartconnect_0_M02_AXI_wstrb),
        .s_axi_wvalid(smartconnect_0_M02_AXI_wvalid));
  axi_bus_cpu_axiCdma_bridge_0_0 cpu_axiCdma_bridge_0
       (.aclk(cpu_clk),
        .aresetn(rst_n),
        .cdma_addr_i(cdma_addr_i_0),
        .cdma_data_i(cdma_data_i_0),
        .cdma_data_out(cdma_data_out_0),
        .cdma_except_complete(cdma_except_complete_0),
        .cdma_exception(cdma_exception_0),
        .cdma_rdy(cdma_rdy_0),
        .m_axi_lite_araddr(cpu_axiCdma_bridge_0_m_axi_araddr),
        .m_axi_lite_arready(axi_cdma_0_s_axi_lite_arready),
        .m_axi_lite_arvalid(cpu_axiCdma_bridge_0_m_axi_arvalid),
        .m_axi_lite_awaddr(cpu_axiCdma_bridge_0_m_axi_awaddr),
        .m_axi_lite_awready(axi_cdma_0_s_axi_lite_awready),
        .m_axi_lite_awvalid(cpu_axiCdma_bridge_0_m_axi_awvalid),
        .m_axi_lite_bready(cpu_axiCdma_bridge_0_m_axi_bready),
        .m_axi_lite_bresp(axi_cdma_0_s_axi_lite_bresp),
        .m_axi_lite_bvalid(axi_cdma_0_s_axi_lite_bvalid),
        .m_axi_lite_rdata(axi_cdma_0_s_axi_lite_rdata),
        .m_axi_lite_rready(cpu_axiCdma_bridge_0_m_axi_rready),
        .m_axi_lite_rresp(axi_cdma_0_s_axi_lite_rresp),
        .m_axi_lite_rvalid(axi_cdma_0_s_axi_lite_rvalid),
        .m_axi_lite_wdata(cpu_axiCdma_bridge_0_m_axi_wdata),
        .m_axi_lite_wready(axi_cdma_0_s_axi_lite_wready),
        .m_axi_lite_wvalid(cpu_axiCdma_bridge_0_m_axi_wvalid),
        .req_rd_dma(req_rd_dma_0),
        .req_wr_dma(req_wr_dma_0));
  axi_bus_dcache_axiBus_bridge_0_0 dcache_axiBus_bridge
       (.M_AXI_ARADDR(dcache_axiBus_bridge_0_M_AXI_ARADDR),
        .M_AXI_ARBURST(dcache_axiBus_bridge_0_M_AXI_ARBURST),
        .M_AXI_ARCACHE(dcache_axiBus_bridge_0_M_AXI_ARCACHE),
        .M_AXI_ARID(dcache_axiBus_bridge_0_M_AXI_ARID),
        .M_AXI_ARLEN(dcache_axiBus_bridge_0_M_AXI_ARLEN),
        .M_AXI_ARLOCK(dcache_axiBus_bridge_0_M_AXI_ARLOCK),
        .M_AXI_ARPROT(dcache_axiBus_bridge_0_M_AXI_ARPROT),
        .M_AXI_ARQOS(dcache_axiBus_bridge_0_M_AXI_ARQOS),
        .M_AXI_ARREADY(smartconnect_0_S02_AXI_arready),
        .M_AXI_ARSIZE(dcache_axiBus_bridge_0_M_AXI_ARSIZE),
        .M_AXI_ARUSER(dcache_axiBus_bridge_0_M_AXI_ARUSER),
        .M_AXI_ARVALID(dcache_axiBus_bridge_0_M_AXI_ARVALID),
        .M_AXI_AWADDR(dcache_axiBus_bridge_0_M_AXI_AWADDR),
        .M_AXI_AWBURST(dcache_axiBus_bridge_0_M_AXI_AWBURST),
        .M_AXI_AWCACHE(dcache_axiBus_bridge_0_M_AXI_AWCACHE),
        .M_AXI_AWID(dcache_axiBus_bridge_0_M_AXI_AWID),
        .M_AXI_AWLEN(dcache_axiBus_bridge_0_M_AXI_AWLEN),
        .M_AXI_AWLOCK(dcache_axiBus_bridge_0_M_AXI_AWLOCK),
        .M_AXI_AWPROT(dcache_axiBus_bridge_0_M_AXI_AWPROT),
        .M_AXI_AWQOS(dcache_axiBus_bridge_0_M_AXI_AWQOS),
        .M_AXI_AWREADY(smartconnect_0_S02_AXI_awready),
        .M_AXI_AWSIZE(dcache_axiBus_bridge_0_M_AXI_AWSIZE),
        .M_AXI_AWUSER(dcache_axiBus_bridge_0_M_AXI_AWUSER),
        .M_AXI_AWVALID(dcache_axiBus_bridge_0_M_AXI_AWVALID),
        .M_AXI_BID(smartconnect_0_S02_AXI_bid),
        .M_AXI_BREADY(dcache_axiBus_bridge_0_M_AXI_BREADY),
        .M_AXI_BRESP(smartconnect_0_S02_AXI_bresp),
        .M_AXI_BVALID(smartconnect_0_S02_AXI_bvalid),
        .M_AXI_RDATA(smartconnect_0_S02_AXI_rdata),
        .M_AXI_RID(smartconnect_0_S02_AXI_rid),
        .M_AXI_RLAST(smartconnect_0_S02_AXI_rlast),
        .M_AXI_RREADY(dcache_axiBus_bridge_0_M_AXI_RREADY),
        .M_AXI_RRESP(smartconnect_0_S02_AXI_rresp),
        .M_AXI_RVALID(smartconnect_0_S02_AXI_rvalid),
        .M_AXI_WDATA(dcache_axiBus_bridge_0_M_AXI_WDATA),
        .M_AXI_WLAST(dcache_axiBus_bridge_0_M_AXI_WLAST),
        .M_AXI_WREADY(smartconnect_0_S02_AXI_wready),
        .M_AXI_WSTRB(dcache_axiBus_bridge_0_M_AXI_WSTRB),
        .M_AXI_WVALID(dcache_axiBus_bridge_0_M_AXI_WVALID),
        .aclk(cpu_clk),
        .aresetn(rst_n),
        .mem_addr(mem_addr_0),
        .rm_complete(rm_complete_0),
        .rm_data(rm_data_0),
        .rm_rdy(rm_rdy_0),
        .rm_success(rm_success_0),
        .rm_vld(rm_vld_0),
        .wm_complete(wm_complete_0),
        .wm_data(wm_data_0),
        .wm_rdy(wm_rdy_0),
        .wm_success(wm_success_0),
        .wm_vld(wm_vld_0));
  axi_bus_icache_axiBus_bridge_0_0 icache_axiBus_bridge_0
       (.M_AXI_ARADDR(icache_axiBus_bridge_0_M_AXI_ARADDR),
        .M_AXI_ARBURST(icache_axiBus_bridge_0_M_AXI_ARBURST),
        .M_AXI_ARCACHE(icache_axiBus_bridge_0_M_AXI_ARCACHE),
        .M_AXI_ARID(icache_axiBus_bridge_0_M_AXI_ARID),
        .M_AXI_ARLEN(icache_axiBus_bridge_0_M_AXI_ARLEN),
        .M_AXI_ARLOCK(icache_axiBus_bridge_0_M_AXI_ARLOCK),
        .M_AXI_ARPROT(icache_axiBus_bridge_0_M_AXI_ARPROT),
        .M_AXI_ARQOS(icache_axiBus_bridge_0_M_AXI_ARQOS),
        .M_AXI_ARREADY(smartconnect_0_S00_AXI_arready),
        .M_AXI_ARSIZE(icache_axiBus_bridge_0_M_AXI_ARSIZE),
        .M_AXI_ARUSER(icache_axiBus_bridge_0_M_AXI_ARUSER),
        .M_AXI_ARVALID(icache_axiBus_bridge_0_M_AXI_ARVALID),
        .M_AXI_RDATA(smartconnect_0_S00_AXI_rdata),
        .M_AXI_RID(icache_axiBus_bridge_0_M_AXI_RID),
        .M_AXI_RLAST(smartconnect_0_S00_AXI_rlast),
        .M_AXI_RREADY(icache_axiBus_bridge_0_M_AXI_RREADY),
        .M_AXI_RRESP(smartconnect_0_S00_AXI_rresp),
        .M_AXI_RVALID(smartconnect_0_S00_AXI_rvalid),
        .aclk(cpu_clk),
        .aresetn(rst_n),
        .mem_addr(icache_mem_addr),
        .req_rm(icache_req_rm),
        .rm_complete(icache_rm_complete),
        .rm_data(icache_rm_data),
        .rm_rdy(icache_rm_rdy),
        .rm_success(icache_rm_success));
  axi_bus_smartconnect_0_0 smartconnect_0
       (.M00_AXI_araddr(smartconnect_0_M00_AXI_araddr),
        .M00_AXI_arburst(smartconnect_0_M00_AXI_arburst),
        .M00_AXI_arcache(smartconnect_0_M00_AXI_arcache),
        .M00_AXI_arlen(smartconnect_0_M00_AXI_arlen),
        .M00_AXI_arlock(smartconnect_0_M00_AXI_arlock),
        .M00_AXI_arprot(smartconnect_0_M00_AXI_arprot),
        .M00_AXI_arqos(smartconnect_0_M00_AXI_arqos),
        .M00_AXI_arready(mig_7series_0_s_axi_arready),
        .M00_AXI_arsize(smartconnect_0_M00_AXI_arsize),
        .M00_AXI_arvalid(smartconnect_0_M00_AXI_arvalid),
        .M00_AXI_awaddr(smartconnect_0_M00_AXI_awaddr),
        .M00_AXI_awburst(smartconnect_0_M00_AXI_awburst),
        .M00_AXI_awcache(smartconnect_0_M00_AXI_awcache),
        .M00_AXI_awlen(smartconnect_0_M00_AXI_awlen),
        .M00_AXI_awlock(smartconnect_0_M00_AXI_awlock),
        .M00_AXI_awprot(smartconnect_0_M00_AXI_awprot),
        .M00_AXI_awqos(smartconnect_0_M00_AXI_awqos),
        .M00_AXI_awready(mig_7series_0_s_axi_awready),
        .M00_AXI_awsize(smartconnect_0_M00_AXI_awsize),
        .M00_AXI_awvalid(smartconnect_0_M00_AXI_awvalid),
        .M00_AXI_bready(smartconnect_0_M00_AXI_bready),
        .M00_AXI_bresp(mig_7series_0_s_axi_bresp),
        .M00_AXI_bvalid(mig_7series_0_s_axi_bvalid),
        .M00_AXI_rdata(mig_7series_0_s_axi_rdata),
        .M00_AXI_rlast(mig_7series_0_s_axi_rlast),
        .M00_AXI_rready(smartconnect_0_M00_AXI_rready),
        .M00_AXI_rresp(mig_7series_0_s_axi_rresp),
        .M00_AXI_rvalid(mig_7series_0_s_axi_rvalid),
        .M00_AXI_wdata(smartconnect_0_M00_AXI_wdata),
        .M00_AXI_wlast(smartconnect_0_M00_AXI_wlast),
        .M00_AXI_wready(mig_7series_0_s_axi_wready),
        .M00_AXI_wstrb(smartconnect_0_M00_AXI_wstrb),
        .M00_AXI_wvalid(smartconnect_0_M00_AXI_wvalid),
        .M01_AXI_arready(1'b0),
        .M01_AXI_awready(1'b0),
        .M01_AXI_bresp({1'b0,1'b0}),
        .M01_AXI_bvalid(1'b0),
        .M01_AXI_rdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .M01_AXI_rlast(1'b0),
        .M01_AXI_rresp({1'b0,1'b0}),
        .M01_AXI_rvalid(1'b0),
        .M01_AXI_wready(1'b0),
        .M02_AXI_araddr(smartconnect_0_M02_AXI_araddr),
        .M02_AXI_arburst(smartconnect_0_M02_AXI_arburst),
        .M02_AXI_arcache(smartconnect_0_M02_AXI_arcache),
        .M02_AXI_arlen(smartconnect_0_M02_AXI_arlen),
        .M02_AXI_arlock(smartconnect_0_M02_AXI_arlock),
        .M02_AXI_arprot(smartconnect_0_M02_AXI_arprot),
        .M02_AXI_arready(axi_sram_ctrl_s_axi_arready),
        .M02_AXI_arsize(smartconnect_0_M02_AXI_arsize),
        .M02_AXI_arvalid(smartconnect_0_M02_AXI_arvalid),
        .M02_AXI_awaddr(smartconnect_0_M02_AXI_awaddr),
        .M02_AXI_awburst(smartconnect_0_M02_AXI_awburst),
        .M02_AXI_awcache(smartconnect_0_M02_AXI_awcache),
        .M02_AXI_awlen(smartconnect_0_M02_AXI_awlen),
        .M02_AXI_awlock(smartconnect_0_M02_AXI_awlock),
        .M02_AXI_awprot(smartconnect_0_M02_AXI_awprot),
        .M02_AXI_awready(axi_sram_ctrl_s_axi_awready),
        .M02_AXI_awsize(smartconnect_0_M02_AXI_awsize),
        .M02_AXI_awvalid(smartconnect_0_M02_AXI_awvalid),
        .M02_AXI_bready(smartconnect_0_M02_AXI_bready),
        .M02_AXI_bresp(axi_sram_ctrl_s_axi_bresp),
        .M02_AXI_bvalid(axi_sram_ctrl_s_axi_bvalid),
        .M02_AXI_rdata(axi_sram_ctrl_s_axi_rdata),
        .M02_AXI_rlast(axi_sram_ctrl_s_axi_rlast),
        .M02_AXI_rready(smartconnect_0_M02_AXI_rready),
        .M02_AXI_rresp(axi_sram_ctrl_s_axi_rresp),
        .M02_AXI_rvalid(axi_sram_ctrl_s_axi_rvalid),
        .M02_AXI_wdata(smartconnect_0_M02_AXI_wdata),
        .M02_AXI_wlast(smartconnect_0_M02_AXI_wlast),
        .M02_AXI_wready(axi_sram_ctrl_s_axi_wready),
        .M02_AXI_wstrb(smartconnect_0_M02_AXI_wstrb),
        .M02_AXI_wvalid(smartconnect_0_M02_AXI_wvalid),
        .S00_AXI_araddr(icache_axiBus_bridge_0_M_AXI_ARADDR),
        .S00_AXI_arburst(icache_axiBus_bridge_0_M_AXI_ARBURST),
        .S00_AXI_arcache(icache_axiBus_bridge_0_M_AXI_ARCACHE),
        .S00_AXI_arid(icache_axiBus_bridge_0_M_AXI_ARID),
        .S00_AXI_arlen(icache_axiBus_bridge_0_M_AXI_ARLEN),
        .S00_AXI_arlock(icache_axiBus_bridge_0_M_AXI_ARLOCK),
        .S00_AXI_arprot(icache_axiBus_bridge_0_M_AXI_ARPROT),
        .S00_AXI_arqos(icache_axiBus_bridge_0_M_AXI_ARQOS),
        .S00_AXI_arready(smartconnect_0_S00_AXI_arready),
        .S00_AXI_arsize(icache_axiBus_bridge_0_M_AXI_ARSIZE),
        .S00_AXI_aruser(icache_axiBus_bridge_0_M_AXI_ARUSER),
        .S00_AXI_arvalid(icache_axiBus_bridge_0_M_AXI_ARVALID),
        .S00_AXI_rdata(smartconnect_0_S00_AXI_rdata),
        .S00_AXI_rid(icache_axiBus_bridge_0_M_AXI_RID),
        .S00_AXI_rlast(smartconnect_0_S00_AXI_rlast),
        .S00_AXI_rready(icache_axiBus_bridge_0_M_AXI_RREADY),
        .S00_AXI_rresp(smartconnect_0_S00_AXI_rresp),
        .S00_AXI_rvalid(smartconnect_0_S00_AXI_rvalid),
        .S01_AXI_araddr(axi_cdma_0_m_axi_araddr),
        .S01_AXI_arburst(axi_cdma_0_m_axi_arburst),
        .S01_AXI_arcache(axi_cdma_0_m_axi_arcache),
        .S01_AXI_arlen(axi_cdma_0_m_axi_arlen),
        .S01_AXI_arlock(1'b0),
        .S01_AXI_arprot(axi_cdma_0_m_axi_arprot),
        .S01_AXI_arqos({1'b0,1'b0,1'b0,1'b0}),
        .S01_AXI_arready(smartconnect_0_S01_AXI_arready),
        .S01_AXI_arsize(axi_cdma_0_m_axi_arsize),
        .S01_AXI_arvalid(axi_cdma_0_m_axi_arvalid),
        .S01_AXI_awaddr(axi_cdma_0_m_axi_awaddr),
        .S01_AXI_awburst(axi_cdma_0_m_axi_awburst),
        .S01_AXI_awcache(axi_cdma_0_m_axi_awcache),
        .S01_AXI_awlen(axi_cdma_0_m_axi_awlen),
        .S01_AXI_awlock(1'b0),
        .S01_AXI_awprot(axi_cdma_0_m_axi_awprot),
        .S01_AXI_awqos({1'b0,1'b0,1'b0,1'b0}),
        .S01_AXI_awready(smartconnect_0_S01_AXI_awready),
        .S01_AXI_awsize(axi_cdma_0_m_axi_awsize),
        .S01_AXI_awvalid(axi_cdma_0_m_axi_awvalid),
        .S01_AXI_bready(axi_cdma_0_m_axi_bready),
        .S01_AXI_bresp(smartconnect_0_S01_AXI_bresp),
        .S01_AXI_bvalid(smartconnect_0_S01_AXI_bvalid),
        .S01_AXI_rdata(smartconnect_0_S01_AXI_rdata),
        .S01_AXI_rlast(smartconnect_0_S01_AXI_rlast),
        .S01_AXI_rready(axi_cdma_0_m_axi_rready),
        .S01_AXI_rresp(smartconnect_0_S01_AXI_rresp),
        .S01_AXI_rvalid(smartconnect_0_S01_AXI_rvalid),
        .S01_AXI_wdata(axi_cdma_0_m_axi_wdata),
        .S01_AXI_wlast(axi_cdma_0_m_axi_wlast),
        .S01_AXI_wready(smartconnect_0_S01_AXI_wready),
        .S01_AXI_wstrb(axi_cdma_0_m_axi_wstrb),
        .S01_AXI_wvalid(axi_cdma_0_m_axi_wvalid),
        .S02_AXI_araddr(dcache_axiBus_bridge_0_M_AXI_ARADDR),
        .S02_AXI_arburst(dcache_axiBus_bridge_0_M_AXI_ARBURST),
        .S02_AXI_arcache(dcache_axiBus_bridge_0_M_AXI_ARCACHE),
        .S02_AXI_arid(dcache_axiBus_bridge_0_M_AXI_ARID),
        .S02_AXI_arlen(dcache_axiBus_bridge_0_M_AXI_ARLEN),
        .S02_AXI_arlock(dcache_axiBus_bridge_0_M_AXI_ARLOCK),
        .S02_AXI_arprot(dcache_axiBus_bridge_0_M_AXI_ARPROT),
        .S02_AXI_arqos(dcache_axiBus_bridge_0_M_AXI_ARQOS),
        .S02_AXI_arready(smartconnect_0_S02_AXI_arready),
        .S02_AXI_arsize(dcache_axiBus_bridge_0_M_AXI_ARSIZE),
        .S02_AXI_aruser(dcache_axiBus_bridge_0_M_AXI_ARUSER),
        .S02_AXI_arvalid(dcache_axiBus_bridge_0_M_AXI_ARVALID),
        .S02_AXI_awaddr(dcache_axiBus_bridge_0_M_AXI_AWADDR),
        .S02_AXI_awburst(dcache_axiBus_bridge_0_M_AXI_AWBURST),
        .S02_AXI_awcache(dcache_axiBus_bridge_0_M_AXI_AWCACHE),
        .S02_AXI_awid(dcache_axiBus_bridge_0_M_AXI_AWID),
        .S02_AXI_awlen(dcache_axiBus_bridge_0_M_AXI_AWLEN),
        .S02_AXI_awlock(dcache_axiBus_bridge_0_M_AXI_AWLOCK),
        .S02_AXI_awprot(dcache_axiBus_bridge_0_M_AXI_AWPROT),
        .S02_AXI_awqos(dcache_axiBus_bridge_0_M_AXI_AWQOS),
        .S02_AXI_awready(smartconnect_0_S02_AXI_awready),
        .S02_AXI_awsize(dcache_axiBus_bridge_0_M_AXI_AWSIZE),
        .S02_AXI_awuser(dcache_axiBus_bridge_0_M_AXI_AWUSER),
        .S02_AXI_awvalid(dcache_axiBus_bridge_0_M_AXI_AWVALID),
        .S02_AXI_bid(smartconnect_0_S02_AXI_bid),
        .S02_AXI_bready(dcache_axiBus_bridge_0_M_AXI_BREADY),
        .S02_AXI_bresp(smartconnect_0_S02_AXI_bresp),
        .S02_AXI_bvalid(smartconnect_0_S02_AXI_bvalid),
        .S02_AXI_rdata(smartconnect_0_S02_AXI_rdata),
        .S02_AXI_rid(smartconnect_0_S02_AXI_rid),
        .S02_AXI_rlast(smartconnect_0_S02_AXI_rlast),
        .S02_AXI_rready(dcache_axiBus_bridge_0_M_AXI_RREADY),
        .S02_AXI_rresp(smartconnect_0_S02_AXI_rresp),
        .S02_AXI_rvalid(smartconnect_0_S02_AXI_rvalid),
        .S02_AXI_wdata(dcache_axiBus_bridge_0_M_AXI_WDATA),
        .S02_AXI_wlast(dcache_axiBus_bridge_0_M_AXI_WLAST),
        .S02_AXI_wready(smartconnect_0_S02_AXI_wready),
        .S02_AXI_wstrb(dcache_axiBus_bridge_0_M_AXI_WSTRB),
        .S02_AXI_wvalid(dcache_axiBus_bridge_0_M_AXI_WVALID),
        .aclk(cpu_clk),
        .aclk1(mig_7series_0_ui_clk),
        .aresetn(rst_n));
endmodule
