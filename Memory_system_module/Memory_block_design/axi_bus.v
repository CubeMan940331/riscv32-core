//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Tue Sep 16 22:04:42 2025
//Host        : LAPTOP-AHEFCFON running 64-bit major release  (build 9200)
//Command     : generate_target axi_bus.bd
//Design      : axi_bus
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "axi_bus,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=axi_bus,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=5,numReposBlks=5,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,da_board_cnt=1,da_clkrst_cnt=7,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "axi_bus.hwdef" *) 
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
    M02_AXI_0_araddr,
    M02_AXI_0_arburst,
    M02_AXI_0_arcache,
    M02_AXI_0_arlen,
    M02_AXI_0_arlock,
    M02_AXI_0_arprot,
    M02_AXI_0_arqos,
    M02_AXI_0_arready,
    M02_AXI_0_arsize,
    M02_AXI_0_arvalid,
    M02_AXI_0_awaddr,
    M02_AXI_0_awburst,
    M02_AXI_0_awcache,
    M02_AXI_0_awlen,
    M02_AXI_0_awlock,
    M02_AXI_0_awprot,
    M02_AXI_0_awqos,
    M02_AXI_0_awready,
    M02_AXI_0_awsize,
    M02_AXI_0_awvalid,
    M02_AXI_0_bready,
    M02_AXI_0_bresp,
    M02_AXI_0_bvalid,
    M02_AXI_0_rdata,
    M02_AXI_0_rlast,
    M02_AXI_0_rready,
    M02_AXI_0_rresp,
    M02_AXI_0_rvalid,
    M02_AXI_0_wdata,
    M02_AXI_0_wlast,
    M02_AXI_0_wready,
    M02_AXI_0_wstrb,
    M02_AXI_0_wvalid,
    M_AXIS_MM2S_0_tdata,
    M_AXIS_MM2S_0_tkeep,
    M_AXIS_MM2S_0_tlast,
    M_AXIS_MM2S_0_tready,
    M_AXIS_MM2S_0_tvalid,
    SPI_0_0_io0_i,
    SPI_0_0_io0_o,
    SPI_0_0_io0_t,
    SPI_0_0_io1_i,
    SPI_0_0_io1_o,
    SPI_0_0_io1_t,
    SPI_0_0_ss_i,
    SPI_0_0_ss_o,
    SPI_0_0_ss_t,
    STARTUP_IO_0_cfgclk,
    STARTUP_IO_0_cfgmclk,
    STARTUP_IO_0_eos,
    STARTUP_IO_0_preq,
    S_AXIS_S2MM_0_tdata,
    S_AXIS_S2MM_0_tkeep,
    S_AXIS_S2MM_0_tlast,
    S_AXIS_S2MM_0_tready,
    S_AXIS_S2MM_0_tvalid,
    S_AXI_LITE_0_araddr,
    S_AXI_LITE_0_arready,
    S_AXI_LITE_0_arvalid,
    S_AXI_LITE_0_awaddr,
    S_AXI_LITE_0_awready,
    S_AXI_LITE_0_awvalid,
    S_AXI_LITE_0_bready,
    S_AXI_LITE_0_bresp,
    S_AXI_LITE_0_bvalid,
    S_AXI_LITE_0_rdata,
    S_AXI_LITE_0_rready,
    S_AXI_LITE_0_rresp,
    S_AXI_LITE_0_rvalid,
    S_AXI_LITE_0_wdata,
    S_AXI_LITE_0_wready,
    S_AXI_LITE_0_wvalid,
    app_wr_en,
    app_wr_mask,
    arb_addr,
    arb_cmd,
    arb_en,
    arb_rd_data,
    arb_rd_data_end,
    arb_rd_data_vld,
    arb_rd_rdy,
    arb_wr_data,
    arb_wr_end,
    arb_wr_rdy,
    cpu_clk,
    dma_clk,
    ext_spi_clk_0,
    gpu_clk,
    init_calib_complete_0,
    ip2intc_irpt_0,
    mig_ref_clk,
    mig_sys_clk,
    mmcm_locked_0,
    rst_n,
    sdcard_clk,
    ui_addn_clk_0_0,
    ui_clk_sync_rst_0);
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
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARADDR" *) (* X_INTERFACE_MODE = "Master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M02_AXI_0, ADDR_WIDTH 32, ARUSER_WIDTH 0, AWUSER_WIDTH 0, BUSER_WIDTH 0, DATA_WIDTH 32, FREQ_HZ 100000000, HAS_BRESP 1, HAS_BURST 1, HAS_CACHE 1, HAS_LOCK 1, HAS_PROT 1, HAS_QOS 1, HAS_REGION 0, HAS_RRESP 1, HAS_WSTRB 1, ID_WIDTH 0, INSERT_VIP 0, MAX_BURST_LENGTH 256, NUM_READ_OUTSTANDING 16, NUM_READ_THREADS 1, NUM_WRITE_OUTSTANDING 16, NUM_WRITE_THREADS 1, PHASE 0.0, PROTOCOL AXI4, READ_WRITE_MODE READ_WRITE, RUSER_BITS_PER_BYTE 0, RUSER_WIDTH 0, SUPPORTS_NARROW_BURST 0, WUSER_BITS_PER_BYTE 0, WUSER_WIDTH 0" *) output [31:0]M02_AXI_0_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARBURST" *) output [1:0]M02_AXI_0_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARCACHE" *) output [3:0]M02_AXI_0_arcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARLEN" *) output [7:0]M02_AXI_0_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARLOCK" *) output [0:0]M02_AXI_0_arlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARPROT" *) output [2:0]M02_AXI_0_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARQOS" *) output [3:0]M02_AXI_0_arqos;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARREADY" *) input M02_AXI_0_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARSIZE" *) output [2:0]M02_AXI_0_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 ARVALID" *) output M02_AXI_0_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWADDR" *) output [31:0]M02_AXI_0_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWBURST" *) output [1:0]M02_AXI_0_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWCACHE" *) output [3:0]M02_AXI_0_awcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWLEN" *) output [7:0]M02_AXI_0_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWLOCK" *) output [0:0]M02_AXI_0_awlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWPROT" *) output [2:0]M02_AXI_0_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWQOS" *) output [3:0]M02_AXI_0_awqos;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWREADY" *) input M02_AXI_0_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWSIZE" *) output [2:0]M02_AXI_0_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 AWVALID" *) output M02_AXI_0_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 BREADY" *) output M02_AXI_0_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 BRESP" *) input [1:0]M02_AXI_0_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 BVALID" *) input M02_AXI_0_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 RDATA" *) input [31:0]M02_AXI_0_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 RLAST" *) input M02_AXI_0_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 RREADY" *) output M02_AXI_0_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 RRESP" *) input [1:0]M02_AXI_0_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 RVALID" *) input M02_AXI_0_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 WDATA" *) output [31:0]M02_AXI_0_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 WLAST" *) output M02_AXI_0_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 WREADY" *) input M02_AXI_0_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 WSTRB" *) output [3:0]M02_AXI_0_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M02_AXI_0 WVALID" *) output M02_AXI_0_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_0 TDATA" *) (* X_INTERFACE_MODE = "Master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS_MM2S_0, FREQ_HZ 100000000, HAS_TKEEP 1, HAS_TLAST 1, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) output [31:0]M_AXIS_MM2S_0_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_0 TKEEP" *) output [3:0]M_AXIS_MM2S_0_tkeep;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_0 TLAST" *) output M_AXIS_MM2S_0_tlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_0 TREADY" *) input M_AXIS_MM2S_0_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S_0 TVALID" *) output M_AXIS_MM2S_0_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 IO0_I" *) (* X_INTERFACE_MODE = "Master" *) input SPI_0_0_io0_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 IO0_O" *) output SPI_0_0_io0_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 IO0_T" *) output SPI_0_0_io0_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 IO1_I" *) input SPI_0_0_io1_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 IO1_O" *) output SPI_0_0_io1_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 IO1_T" *) output SPI_0_0_io1_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 SS_I" *) input [0:0]SPI_0_0_ss_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 SS_O" *) output [0:0]SPI_0_0_ss_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 SPI_0_0 SS_T" *) output SPI_0_0_ss_t;
  (* X_INTERFACE_INFO = "xilinx.com:display_startup_io:startup_io:1.0 STARTUP_IO_0 cfgclk" *) (* X_INTERFACE_MODE = "Master" *) output STARTUP_IO_0_cfgclk;
  (* X_INTERFACE_INFO = "xilinx.com:display_startup_io:startup_io:1.0 STARTUP_IO_0 cfgmclk" *) output STARTUP_IO_0_cfgmclk;
  (* X_INTERFACE_INFO = "xilinx.com:display_startup_io:startup_io:1.0 STARTUP_IO_0 eos" *) output STARTUP_IO_0_eos;
  (* X_INTERFACE_INFO = "xilinx.com:display_startup_io:startup_io:1.0 STARTUP_IO_0 preq" *) output STARTUP_IO_0_preq;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_0 TDATA" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXIS_S2MM_0, FREQ_HZ 100000000, HAS_TKEEP 1, HAS_TLAST 1, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [31:0]S_AXIS_S2MM_0_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_0 TKEEP" *) input [3:0]S_AXIS_S2MM_0_tkeep;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_0 TLAST" *) input S_AXIS_S2MM_0_tlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_0 TREADY" *) output S_AXIS_S2MM_0_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_0 TVALID" *) input S_AXIS_S2MM_0_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 ARADDR" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_LITE_0, ADDR_WIDTH 16, ARUSER_WIDTH 0, AWUSER_WIDTH 0, BUSER_WIDTH 0, DATA_WIDTH 32, FREQ_HZ 100000000, HAS_BRESP 1, HAS_BURST 0, HAS_CACHE 0, HAS_LOCK 0, HAS_PROT 0, HAS_QOS 0, HAS_REGION 0, HAS_RRESP 1, HAS_WSTRB 0, ID_WIDTH 0, INSERT_VIP 0, MAX_BURST_LENGTH 1, NUM_READ_OUTSTANDING 1, NUM_READ_THREADS 1, NUM_WRITE_OUTSTANDING 1, NUM_WRITE_THREADS 1, PHASE 0.0, PROTOCOL AXI4LITE, READ_WRITE_MODE READ_WRITE, RUSER_BITS_PER_BYTE 0, RUSER_WIDTH 0, SUPPORTS_NARROW_BURST 0, WUSER_BITS_PER_BYTE 0, WUSER_WIDTH 0" *) input [9:0]S_AXI_LITE_0_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 ARREADY" *) output S_AXI_LITE_0_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 ARVALID" *) input S_AXI_LITE_0_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 AWADDR" *) input [9:0]S_AXI_LITE_0_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 AWREADY" *) output S_AXI_LITE_0_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 AWVALID" *) input S_AXI_LITE_0_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 BREADY" *) input S_AXI_LITE_0_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 BRESP" *) output [1:0]S_AXI_LITE_0_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 BVALID" *) output S_AXI_LITE_0_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 RDATA" *) output [31:0]S_AXI_LITE_0_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 RREADY" *) input S_AXI_LITE_0_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 RRESP" *) output [1:0]S_AXI_LITE_0_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 RVALID" *) output S_AXI_LITE_0_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 WDATA" *) input [31:0]S_AXI_LITE_0_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 WREADY" *) output S_AXI_LITE_0_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE_0 WVALID" *) input S_AXI_LITE_0_wvalid;
  input app_wr_en;
  input [15:0]app_wr_mask;
  input [26:0]arb_addr;
  input arb_cmd;
  input arb_en;
  output [127:0]arb_rd_data;
  output arb_rd_data_end;
  output arb_rd_data_vld;
  output arb_rd_rdy;
  input [127:0]arb_wr_data;
  input arb_wr_end;
  output arb_wr_rdy;
  input cpu_clk;
  input dma_clk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.EXT_SPI_CLK_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.EXT_SPI_CLK_0, CLK_DOMAIN axi_bus_ext_spi_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input ext_spi_clk_0;
  input gpu_clk;
  output init_calib_complete_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 INTR.IP2INTC_IRPT_0 INTERRUPT" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME INTR.IP2INTC_IRPT_0, PortWidth 1, SENSITIVITY EDGE_RISING" *) output ip2intc_irpt_0;
  input mig_ref_clk;
  input mig_sys_clk;
  output mmcm_locked_0;
  input rst_n;
  input sdcard_clk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.UI_ADDN_CLK_0_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.UI_ADDN_CLK_0_0, CLK_DOMAIN axi_bus_mig_7series_0_0_ui_clk, FREQ_HZ 200000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0" *) output ui_addn_clk_0_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.UI_CLK_SYNC_RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.UI_CLK_SYNC_RST_0, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) output ui_clk_sync_rst_0;

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
  wire [31:0]M02_AXI_0_araddr;
  wire [1:0]M02_AXI_0_arburst;
  wire [3:0]M02_AXI_0_arcache;
  wire [7:0]M02_AXI_0_arlen;
  wire [0:0]M02_AXI_0_arlock;
  wire [2:0]M02_AXI_0_arprot;
  wire [3:0]M02_AXI_0_arqos;
  wire M02_AXI_0_arready;
  wire [2:0]M02_AXI_0_arsize;
  wire M02_AXI_0_arvalid;
  wire [31:0]M02_AXI_0_awaddr;
  wire [1:0]M02_AXI_0_awburst;
  wire [3:0]M02_AXI_0_awcache;
  wire [7:0]M02_AXI_0_awlen;
  wire [0:0]M02_AXI_0_awlock;
  wire [2:0]M02_AXI_0_awprot;
  wire [3:0]M02_AXI_0_awqos;
  wire M02_AXI_0_awready;
  wire [2:0]M02_AXI_0_awsize;
  wire M02_AXI_0_awvalid;
  wire M02_AXI_0_bready;
  wire [1:0]M02_AXI_0_bresp;
  wire M02_AXI_0_bvalid;
  wire [31:0]M02_AXI_0_rdata;
  wire M02_AXI_0_rlast;
  wire M02_AXI_0_rready;
  wire [1:0]M02_AXI_0_rresp;
  wire M02_AXI_0_rvalid;
  wire [31:0]M02_AXI_0_wdata;
  wire M02_AXI_0_wlast;
  wire M02_AXI_0_wready;
  wire [3:0]M02_AXI_0_wstrb;
  wire M02_AXI_0_wvalid;
  wire [31:0]M_AXIS_MM2S_0_tdata;
  wire [3:0]M_AXIS_MM2S_0_tkeep;
  wire M_AXIS_MM2S_0_tlast;
  wire M_AXIS_MM2S_0_tready;
  wire M_AXIS_MM2S_0_tvalid;
  wire SPI_0_0_io0_i;
  wire SPI_0_0_io0_o;
  wire SPI_0_0_io0_t;
  wire SPI_0_0_io1_i;
  wire SPI_0_0_io1_o;
  wire SPI_0_0_io1_t;
  wire [0:0]SPI_0_0_ss_i;
  wire [0:0]SPI_0_0_ss_o;
  wire SPI_0_0_ss_t;
  wire STARTUP_IO_0_cfgclk;
  wire STARTUP_IO_0_cfgmclk;
  wire STARTUP_IO_0_eos;
  wire STARTUP_IO_0_preq;
  wire [31:0]S_AXIS_S2MM_0_tdata;
  wire [3:0]S_AXIS_S2MM_0_tkeep;
  wire S_AXIS_S2MM_0_tlast;
  wire S_AXIS_S2MM_0_tready;
  wire S_AXIS_S2MM_0_tvalid;
  wire [9:0]S_AXI_LITE_0_araddr;
  wire S_AXI_LITE_0_arready;
  wire S_AXI_LITE_0_arvalid;
  wire [9:0]S_AXI_LITE_0_awaddr;
  wire S_AXI_LITE_0_awready;
  wire S_AXI_LITE_0_awvalid;
  wire S_AXI_LITE_0_bready;
  wire [1:0]S_AXI_LITE_0_bresp;
  wire S_AXI_LITE_0_bvalid;
  wire [31:0]S_AXI_LITE_0_rdata;
  wire S_AXI_LITE_0_rready;
  wire [1:0]S_AXI_LITE_0_rresp;
  wire S_AXI_LITE_0_rvalid;
  wire [31:0]S_AXI_LITE_0_wdata;
  wire S_AXI_LITE_0_wready;
  wire S_AXI_LITE_0_wvalid;
  wire app_wr_en;
  wire [15:0]app_wr_mask;
  wire [26:0]arb_addr;
  wire arb_cmd;
  wire arb_en;
  wire [127:0]arb_rd_data;
  wire arb_rd_data_end;
  wire arb_rd_data_vld;
  wire arb_rd_rdy;
  wire [127:0]arb_wr_data;
  wire arb_wr_end;
  wire arb_wr_rdy;
  wire [26:0]arbiter_axi_bridge_0_M_AXI_ARADDR;
  wire [1:0]arbiter_axi_bridge_0_M_AXI_ARBURST;
  wire [3:0]arbiter_axi_bridge_0_M_AXI_ARCACHE;
  wire [7:0]arbiter_axi_bridge_0_M_AXI_ARLEN;
  wire arbiter_axi_bridge_0_M_AXI_ARLOCK;
  wire [2:0]arbiter_axi_bridge_0_M_AXI_ARPROT;
  wire [3:0]arbiter_axi_bridge_0_M_AXI_ARQOS;
  wire [2:0]arbiter_axi_bridge_0_M_AXI_ARSIZE;
  wire arbiter_axi_bridge_0_M_AXI_ARVALID;
  wire [26:0]arbiter_axi_bridge_0_M_AXI_AWADDR;
  wire [1:0]arbiter_axi_bridge_0_M_AXI_AWBURST;
  wire [3:0]arbiter_axi_bridge_0_M_AXI_AWCACHE;
  wire [7:0]arbiter_axi_bridge_0_M_AXI_AWLEN;
  wire arbiter_axi_bridge_0_M_AXI_AWLOCK;
  wire [2:0]arbiter_axi_bridge_0_M_AXI_AWPROT;
  wire [3:0]arbiter_axi_bridge_0_M_AXI_AWQOS;
  wire [2:0]arbiter_axi_bridge_0_M_AXI_AWSIZE;
  wire arbiter_axi_bridge_0_M_AXI_AWVALID;
  wire arbiter_axi_bridge_0_M_AXI_BREADY;
  wire arbiter_axi_bridge_0_M_AXI_RREADY;
  wire [127:0]arbiter_axi_bridge_0_M_AXI_WDATA;
  wire arbiter_axi_bridge_0_M_AXI_WLAST;
  wire [15:0]arbiter_axi_bridge_0_M_AXI_WSTRB;
  wire arbiter_axi_bridge_0_M_AXI_WVALID;
  wire [31:0]axi_dma_0_m_axi_mm2s_araddr;
  wire [1:0]axi_dma_0_m_axi_mm2s_arburst;
  wire [3:0]axi_dma_0_m_axi_mm2s_arcache;
  wire [7:0]axi_dma_0_m_axi_mm2s_arlen;
  wire [2:0]axi_dma_0_m_axi_mm2s_arprot;
  wire [2:0]axi_dma_0_m_axi_mm2s_arsize;
  wire axi_dma_0_m_axi_mm2s_arvalid;
  wire axi_dma_0_m_axi_mm2s_rready;
  wire [31:0]axi_dma_0_m_axi_s2mm_awaddr;
  wire [1:0]axi_dma_0_m_axi_s2mm_awburst;
  wire [3:0]axi_dma_0_m_axi_s2mm_awcache;
  wire [7:0]axi_dma_0_m_axi_s2mm_awlen;
  wire [2:0]axi_dma_0_m_axi_s2mm_awprot;
  wire [2:0]axi_dma_0_m_axi_s2mm_awsize;
  wire axi_dma_0_m_axi_s2mm_awvalid;
  wire axi_dma_0_m_axi_s2mm_bready;
  wire [127:0]axi_dma_0_m_axi_s2mm_wdata;
  wire axi_dma_0_m_axi_s2mm_wlast;
  wire [15:0]axi_dma_0_m_axi_s2mm_wstrb;
  wire axi_dma_0_m_axi_s2mm_wvalid;
  wire [31:0]axi_dma_0_m_axi_sg_araddr;
  wire [1:0]axi_dma_0_m_axi_sg_arburst;
  wire [3:0]axi_dma_0_m_axi_sg_arcache;
  wire [7:0]axi_dma_0_m_axi_sg_arlen;
  wire [2:0]axi_dma_0_m_axi_sg_arprot;
  wire [2:0]axi_dma_0_m_axi_sg_arsize;
  wire axi_dma_0_m_axi_sg_arvalid;
  wire [31:0]axi_dma_0_m_axi_sg_awaddr;
  wire [1:0]axi_dma_0_m_axi_sg_awburst;
  wire [3:0]axi_dma_0_m_axi_sg_awcache;
  wire [7:0]axi_dma_0_m_axi_sg_awlen;
  wire [2:0]axi_dma_0_m_axi_sg_awprot;
  wire [2:0]axi_dma_0_m_axi_sg_awsize;
  wire axi_dma_0_m_axi_sg_awvalid;
  wire axi_dma_0_m_axi_sg_bready;
  wire axi_dma_0_m_axi_sg_rready;
  wire [31:0]axi_dma_0_m_axi_sg_wdata;
  wire axi_dma_0_m_axi_sg_wlast;
  wire [3:0]axi_dma_0_m_axi_sg_wstrb;
  wire axi_dma_0_m_axi_sg_wvalid;
  wire axi_quad_spi_0_s_axi_arready;
  wire axi_quad_spi_0_s_axi_awready;
  wire [1:0]axi_quad_spi_0_s_axi_bresp;
  wire axi_quad_spi_0_s_axi_bvalid;
  wire [31:0]axi_quad_spi_0_s_axi_rdata;
  wire [1:0]axi_quad_spi_0_s_axi_rresp;
  wire axi_quad_spi_0_s_axi_rvalid;
  wire axi_quad_spi_0_s_axi_wready;
  wire cpu_clk;
  wire dma_clk;
  wire ext_spi_clk_0;
  wire gpu_clk;
  wire init_calib_complete_0;
  wire ip2intc_irpt_0;
  wire mig_7series_0_s_axi_arready;
  wire mig_7series_0_s_axi_awready;
  wire [3:0]mig_7series_0_s_axi_bid;
  wire [1:0]mig_7series_0_s_axi_bresp;
  wire mig_7series_0_s_axi_bvalid;
  wire [127:0]mig_7series_0_s_axi_rdata;
  wire [3:0]mig_7series_0_s_axi_rid;
  wire mig_7series_0_s_axi_rlast;
  wire [1:0]mig_7series_0_s_axi_rresp;
  wire mig_7series_0_s_axi_rvalid;
  wire mig_7series_0_s_axi_wready;
  wire mig_7series_0_ui_clk;
  wire mig_ref_clk;
  wire mig_sys_clk;
  wire mmcm_locked_0;
  wire rst_n;
  wire sdcard_clk;
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
  wire [6:0]smartconnect_0_M01_AXI_araddr;
  wire smartconnect_0_M01_AXI_arvalid;
  wire [6:0]smartconnect_0_M01_AXI_awaddr;
  wire smartconnect_0_M01_AXI_awvalid;
  wire smartconnect_0_M01_AXI_bready;
  wire smartconnect_0_M01_AXI_rready;
  wire [31:0]smartconnect_0_M01_AXI_wdata;
  wire [3:0]smartconnect_0_M01_AXI_wstrb;
  wire smartconnect_0_M01_AXI_wvalid;
  wire smartconnect_0_S00_AXI_arready;
  wire smartconnect_0_S00_AXI_awready;
  wire [1:0]smartconnect_0_S00_AXI_bresp;
  wire smartconnect_0_S00_AXI_bvalid;
  wire [127:0]smartconnect_0_S00_AXI_rdata;
  wire smartconnect_0_S00_AXI_rlast;
  wire [1:0]smartconnect_0_S00_AXI_rresp;
  wire smartconnect_0_S00_AXI_rvalid;
  wire smartconnect_0_S00_AXI_wready;
  wire smartconnect_0_S01_AXI_arready;
  wire smartconnect_0_S01_AXI_awready;
  wire [1:0]smartconnect_0_S01_AXI_bresp;
  wire smartconnect_0_S01_AXI_bvalid;
  wire [31:0]smartconnect_0_S01_AXI_rdata;
  wire smartconnect_0_S01_AXI_rlast;
  wire [1:0]smartconnect_0_S01_AXI_rresp;
  wire smartconnect_0_S01_AXI_rvalid;
  wire smartconnect_0_S01_AXI_wready;
  wire smartconnect_0_S02_AXI_arready;
  wire [127:0]smartconnect_0_S02_AXI_rdata;
  wire smartconnect_0_S02_AXI_rlast;
  wire [1:0]smartconnect_0_S02_AXI_rresp;
  wire smartconnect_0_S02_AXI_rvalid;
  wire smartconnect_0_S03_AXI_awready;
  wire [1:0]smartconnect_0_S03_AXI_bresp;
  wire smartconnect_0_S03_AXI_bvalid;
  wire smartconnect_0_S03_AXI_wready;
  wire ui_addn_clk_0_0;
  wire ui_clk_sync_rst_0;

  axi_bus_arbiter_axi_bridge_0_0 arbiter_axi_bridge_0
       (.M_AXI_ARADDR(arbiter_axi_bridge_0_M_AXI_ARADDR),
        .M_AXI_ARBURST(arbiter_axi_bridge_0_M_AXI_ARBURST),
        .M_AXI_ARCACHE(arbiter_axi_bridge_0_M_AXI_ARCACHE),
        .M_AXI_ARLEN(arbiter_axi_bridge_0_M_AXI_ARLEN),
        .M_AXI_ARLOCK(arbiter_axi_bridge_0_M_AXI_ARLOCK),
        .M_AXI_ARPROT(arbiter_axi_bridge_0_M_AXI_ARPROT),
        .M_AXI_ARQOS(arbiter_axi_bridge_0_M_AXI_ARQOS),
        .M_AXI_ARREADY(smartconnect_0_S00_AXI_arready),
        .M_AXI_ARSIZE(arbiter_axi_bridge_0_M_AXI_ARSIZE),
        .M_AXI_ARVALID(arbiter_axi_bridge_0_M_AXI_ARVALID),
        .M_AXI_AWADDR(arbiter_axi_bridge_0_M_AXI_AWADDR),
        .M_AXI_AWBURST(arbiter_axi_bridge_0_M_AXI_AWBURST),
        .M_AXI_AWCACHE(arbiter_axi_bridge_0_M_AXI_AWCACHE),
        .M_AXI_AWLEN(arbiter_axi_bridge_0_M_AXI_AWLEN),
        .M_AXI_AWLOCK(arbiter_axi_bridge_0_M_AXI_AWLOCK),
        .M_AXI_AWPROT(arbiter_axi_bridge_0_M_AXI_AWPROT),
        .M_AXI_AWQOS(arbiter_axi_bridge_0_M_AXI_AWQOS),
        .M_AXI_AWREADY(smartconnect_0_S00_AXI_awready),
        .M_AXI_AWSIZE(arbiter_axi_bridge_0_M_AXI_AWSIZE),
        .M_AXI_AWVALID(arbiter_axi_bridge_0_M_AXI_AWVALID),
        .M_AXI_BREADY(arbiter_axi_bridge_0_M_AXI_BREADY),
        .M_AXI_BRESP(smartconnect_0_S00_AXI_bresp),
        .M_AXI_BVALID(smartconnect_0_S00_AXI_bvalid),
        .M_AXI_RDATA(smartconnect_0_S00_AXI_rdata),
        .M_AXI_RLAST(smartconnect_0_S00_AXI_rlast),
        .M_AXI_RREADY(arbiter_axi_bridge_0_M_AXI_RREADY),
        .M_AXI_RRESP(smartconnect_0_S00_AXI_rresp),
        .M_AXI_RVALID(smartconnect_0_S00_AXI_rvalid),
        .M_AXI_WDATA(arbiter_axi_bridge_0_M_AXI_WDATA),
        .M_AXI_WLAST(arbiter_axi_bridge_0_M_AXI_WLAST),
        .M_AXI_WREADY(smartconnect_0_S00_AXI_wready),
        .M_AXI_WSTRB(arbiter_axi_bridge_0_M_AXI_WSTRB),
        .M_AXI_WVALID(arbiter_axi_bridge_0_M_AXI_WVALID),
        .app_addr(arb_addr),
        .app_cmd({arb_cmd,arb_cmd,arb_cmd}),
        .app_en(arb_en),
        .app_rd_data(arb_rd_data),
        .app_rd_data_end(arb_rd_data_end),
        .app_rd_data_valid(arb_rd_data_vld),
        .app_rd_rdy(arb_rd_rdy),
        .app_wdf_data(arb_wr_data),
        .app_wdf_end(arb_wr_end),
        .app_wdf_mask(app_wr_mask),
        .app_wdf_rdy(arb_wr_rdy),
        .app_wdf_wren(app_wr_en),
        .clk(cpu_clk),
        .rst_n(rst_n));
  axi_bus_axi_dma_0_0 axi_dma_0
       (.axi_resetn(rst_n),
        .m_axi_mm2s_aclk(cpu_clk),
        .m_axi_mm2s_araddr(axi_dma_0_m_axi_mm2s_araddr),
        .m_axi_mm2s_arburst(axi_dma_0_m_axi_mm2s_arburst),
        .m_axi_mm2s_arcache(axi_dma_0_m_axi_mm2s_arcache),
        .m_axi_mm2s_arlen(axi_dma_0_m_axi_mm2s_arlen),
        .m_axi_mm2s_arprot(axi_dma_0_m_axi_mm2s_arprot),
        .m_axi_mm2s_arready(smartconnect_0_S02_AXI_arready),
        .m_axi_mm2s_arsize(axi_dma_0_m_axi_mm2s_arsize),
        .m_axi_mm2s_arvalid(axi_dma_0_m_axi_mm2s_arvalid),
        .m_axi_mm2s_rdata(smartconnect_0_S02_AXI_rdata),
        .m_axi_mm2s_rlast(smartconnect_0_S02_AXI_rlast),
        .m_axi_mm2s_rready(axi_dma_0_m_axi_mm2s_rready),
        .m_axi_mm2s_rresp(smartconnect_0_S02_AXI_rresp),
        .m_axi_mm2s_rvalid(smartconnect_0_S02_AXI_rvalid),
        .m_axi_s2mm_aclk(cpu_clk),
        .m_axi_s2mm_awaddr(axi_dma_0_m_axi_s2mm_awaddr),
        .m_axi_s2mm_awburst(axi_dma_0_m_axi_s2mm_awburst),
        .m_axi_s2mm_awcache(axi_dma_0_m_axi_s2mm_awcache),
        .m_axi_s2mm_awlen(axi_dma_0_m_axi_s2mm_awlen),
        .m_axi_s2mm_awprot(axi_dma_0_m_axi_s2mm_awprot),
        .m_axi_s2mm_awready(smartconnect_0_S03_AXI_awready),
        .m_axi_s2mm_awsize(axi_dma_0_m_axi_s2mm_awsize),
        .m_axi_s2mm_awvalid(axi_dma_0_m_axi_s2mm_awvalid),
        .m_axi_s2mm_bready(axi_dma_0_m_axi_s2mm_bready),
        .m_axi_s2mm_bresp(smartconnect_0_S03_AXI_bresp),
        .m_axi_s2mm_bvalid(smartconnect_0_S03_AXI_bvalid),
        .m_axi_s2mm_wdata(axi_dma_0_m_axi_s2mm_wdata),
        .m_axi_s2mm_wlast(axi_dma_0_m_axi_s2mm_wlast),
        .m_axi_s2mm_wready(smartconnect_0_S03_AXI_wready),
        .m_axi_s2mm_wstrb(axi_dma_0_m_axi_s2mm_wstrb),
        .m_axi_s2mm_wvalid(axi_dma_0_m_axi_s2mm_wvalid),
        .m_axi_sg_aclk(cpu_clk),
        .m_axi_sg_araddr(axi_dma_0_m_axi_sg_araddr),
        .m_axi_sg_arburst(axi_dma_0_m_axi_sg_arburst),
        .m_axi_sg_arcache(axi_dma_0_m_axi_sg_arcache),
        .m_axi_sg_arlen(axi_dma_0_m_axi_sg_arlen),
        .m_axi_sg_arprot(axi_dma_0_m_axi_sg_arprot),
        .m_axi_sg_arready(smartconnect_0_S01_AXI_arready),
        .m_axi_sg_arsize(axi_dma_0_m_axi_sg_arsize),
        .m_axi_sg_arvalid(axi_dma_0_m_axi_sg_arvalid),
        .m_axi_sg_awaddr(axi_dma_0_m_axi_sg_awaddr),
        .m_axi_sg_awburst(axi_dma_0_m_axi_sg_awburst),
        .m_axi_sg_awcache(axi_dma_0_m_axi_sg_awcache),
        .m_axi_sg_awlen(axi_dma_0_m_axi_sg_awlen),
        .m_axi_sg_awprot(axi_dma_0_m_axi_sg_awprot),
        .m_axi_sg_awready(smartconnect_0_S01_AXI_awready),
        .m_axi_sg_awsize(axi_dma_0_m_axi_sg_awsize),
        .m_axi_sg_awvalid(axi_dma_0_m_axi_sg_awvalid),
        .m_axi_sg_bready(axi_dma_0_m_axi_sg_bready),
        .m_axi_sg_bresp(smartconnect_0_S01_AXI_bresp),
        .m_axi_sg_bvalid(smartconnect_0_S01_AXI_bvalid),
        .m_axi_sg_rdata(smartconnect_0_S01_AXI_rdata),
        .m_axi_sg_rlast(smartconnect_0_S01_AXI_rlast),
        .m_axi_sg_rready(axi_dma_0_m_axi_sg_rready),
        .m_axi_sg_rresp(smartconnect_0_S01_AXI_rresp),
        .m_axi_sg_rvalid(smartconnect_0_S01_AXI_rvalid),
        .m_axi_sg_wdata(axi_dma_0_m_axi_sg_wdata),
        .m_axi_sg_wlast(axi_dma_0_m_axi_sg_wlast),
        .m_axi_sg_wready(smartconnect_0_S01_AXI_wready),
        .m_axi_sg_wstrb(axi_dma_0_m_axi_sg_wstrb),
        .m_axi_sg_wvalid(axi_dma_0_m_axi_sg_wvalid),
        .m_axis_mm2s_tdata(M_AXIS_MM2S_0_tdata),
        .m_axis_mm2s_tkeep(M_AXIS_MM2S_0_tkeep),
        .m_axis_mm2s_tlast(M_AXIS_MM2S_0_tlast),
        .m_axis_mm2s_tready(M_AXIS_MM2S_0_tready),
        .m_axis_mm2s_tvalid(M_AXIS_MM2S_0_tvalid),
        .s_axi_lite_aclk(cpu_clk),
        .s_axi_lite_araddr(S_AXI_LITE_0_araddr),
        .s_axi_lite_arready(S_AXI_LITE_0_arready),
        .s_axi_lite_arvalid(S_AXI_LITE_0_arvalid),
        .s_axi_lite_awaddr(S_AXI_LITE_0_awaddr),
        .s_axi_lite_awready(S_AXI_LITE_0_awready),
        .s_axi_lite_awvalid(S_AXI_LITE_0_awvalid),
        .s_axi_lite_bready(S_AXI_LITE_0_bready),
        .s_axi_lite_bresp(S_AXI_LITE_0_bresp),
        .s_axi_lite_bvalid(S_AXI_LITE_0_bvalid),
        .s_axi_lite_rdata(S_AXI_LITE_0_rdata),
        .s_axi_lite_rready(S_AXI_LITE_0_rready),
        .s_axi_lite_rresp(S_AXI_LITE_0_rresp),
        .s_axi_lite_rvalid(S_AXI_LITE_0_rvalid),
        .s_axi_lite_wdata(S_AXI_LITE_0_wdata),
        .s_axi_lite_wready(S_AXI_LITE_0_wready),
        .s_axi_lite_wvalid(S_AXI_LITE_0_wvalid),
        .s_axis_s2mm_tdata(S_AXIS_S2MM_0_tdata),
        .s_axis_s2mm_tkeep(S_AXIS_S2MM_0_tkeep),
        .s_axis_s2mm_tlast(S_AXIS_S2MM_0_tlast),
        .s_axis_s2mm_tready(S_AXIS_S2MM_0_tready),
        .s_axis_s2mm_tvalid(S_AXIS_S2MM_0_tvalid));
  axi_bus_axi_quad_spi_0_0 axi_quad_spi_0
       (.cfgclk(STARTUP_IO_0_cfgclk),
        .cfgmclk(STARTUP_IO_0_cfgmclk),
        .eos(STARTUP_IO_0_eos),
        .ext_spi_clk(ext_spi_clk_0),
        .io0_i(SPI_0_0_io0_i),
        .io0_o(SPI_0_0_io0_o),
        .io0_t(SPI_0_0_io0_t),
        .io1_i(SPI_0_0_io1_i),
        .io1_o(SPI_0_0_io1_o),
        .io1_t(SPI_0_0_io1_t),
        .ip2intc_irpt(ip2intc_irpt_0),
        .preq(STARTUP_IO_0_preq),
        .s_axi_aclk(sdcard_clk),
        .s_axi_araddr(smartconnect_0_M01_AXI_araddr),
        .s_axi_aresetn(rst_n),
        .s_axi_arready(axi_quad_spi_0_s_axi_arready),
        .s_axi_arvalid(smartconnect_0_M01_AXI_arvalid),
        .s_axi_awaddr(smartconnect_0_M01_AXI_awaddr),
        .s_axi_awready(axi_quad_spi_0_s_axi_awready),
        .s_axi_awvalid(smartconnect_0_M01_AXI_awvalid),
        .s_axi_bready(smartconnect_0_M01_AXI_bready),
        .s_axi_bresp(axi_quad_spi_0_s_axi_bresp),
        .s_axi_bvalid(axi_quad_spi_0_s_axi_bvalid),
        .s_axi_rdata(axi_quad_spi_0_s_axi_rdata),
        .s_axi_rready(smartconnect_0_M01_AXI_rready),
        .s_axi_rresp(axi_quad_spi_0_s_axi_rresp),
        .s_axi_rvalid(axi_quad_spi_0_s_axi_rvalid),
        .s_axi_wdata(smartconnect_0_M01_AXI_wdata),
        .s_axi_wready(axi_quad_spi_0_s_axi_wready),
        .s_axi_wstrb(smartconnect_0_M01_AXI_wstrb),
        .s_axi_wvalid(smartconnect_0_M01_AXI_wvalid),
        .ss_i(SPI_0_0_ss_i),
        .ss_o(SPI_0_0_ss_o),
        .ss_t(SPI_0_0_ss_t));
  axi_bus_mig_7series_0_0 mig_7series_0
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
        .s_axi_awlen(smartconnect_0_M00_AXI_awlen),
        .s_axi_awlock(smartconnect_0_M00_AXI_awlock),
        .s_axi_awprot(smartconnect_0_M00_AXI_awprot),
        .s_axi_awqos(smartconnect_0_M00_AXI_awqos),
        .s_axi_awready(mig_7series_0_s_axi_awready),
        .s_axi_awsize(smartconnect_0_M00_AXI_awsize),
        .s_axi_awvalid(smartconnect_0_M00_AXI_awvalid),
        .s_axi_bid(mig_7series_0_s_axi_bid),
        .s_axi_bready(smartconnect_0_M00_AXI_bready),
        .s_axi_bresp(mig_7series_0_s_axi_bresp),
        .s_axi_bvalid(mig_7series_0_s_axi_bvalid),
        .s_axi_rdata(mig_7series_0_s_axi_rdata),
        .s_axi_rid(mig_7series_0_s_axi_rid),
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
        .sys_rst(rst_n),
        .ui_addn_clk_0(ui_addn_clk_0_0),
        .ui_clk(mig_7series_0_ui_clk),
        .ui_clk_sync_rst(ui_clk_sync_rst_0));
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
        .M01_AXI_araddr(smartconnect_0_M01_AXI_araddr),
        .M01_AXI_arready(axi_quad_spi_0_s_axi_arready),
        .M01_AXI_arvalid(smartconnect_0_M01_AXI_arvalid),
        .M01_AXI_awaddr(smartconnect_0_M01_AXI_awaddr),
        .M01_AXI_awready(axi_quad_spi_0_s_axi_awready),
        .M01_AXI_awvalid(smartconnect_0_M01_AXI_awvalid),
        .M01_AXI_bready(smartconnect_0_M01_AXI_bready),
        .M01_AXI_bresp(axi_quad_spi_0_s_axi_bresp),
        .M01_AXI_bvalid(axi_quad_spi_0_s_axi_bvalid),
        .M01_AXI_rdata(axi_quad_spi_0_s_axi_rdata),
        .M01_AXI_rready(smartconnect_0_M01_AXI_rready),
        .M01_AXI_rresp(axi_quad_spi_0_s_axi_rresp),
        .M01_AXI_rvalid(axi_quad_spi_0_s_axi_rvalid),
        .M01_AXI_wdata(smartconnect_0_M01_AXI_wdata),
        .M01_AXI_wready(axi_quad_spi_0_s_axi_wready),
        .M01_AXI_wstrb(smartconnect_0_M01_AXI_wstrb),
        .M01_AXI_wvalid(smartconnect_0_M01_AXI_wvalid),
        .M02_AXI_araddr(M02_AXI_0_araddr),
        .M02_AXI_arburst(M02_AXI_0_arburst),
        .M02_AXI_arcache(M02_AXI_0_arcache),
        .M02_AXI_arlen(M02_AXI_0_arlen),
        .M02_AXI_arlock(M02_AXI_0_arlock),
        .M02_AXI_arprot(M02_AXI_0_arprot),
        .M02_AXI_arqos(M02_AXI_0_arqos),
        .M02_AXI_arready(M02_AXI_0_arready),
        .M02_AXI_arsize(M02_AXI_0_arsize),
        .M02_AXI_arvalid(M02_AXI_0_arvalid),
        .M02_AXI_awaddr(M02_AXI_0_awaddr),
        .M02_AXI_awburst(M02_AXI_0_awburst),
        .M02_AXI_awcache(M02_AXI_0_awcache),
        .M02_AXI_awlen(M02_AXI_0_awlen),
        .M02_AXI_awlock(M02_AXI_0_awlock),
        .M02_AXI_awprot(M02_AXI_0_awprot),
        .M02_AXI_awqos(M02_AXI_0_awqos),
        .M02_AXI_awready(M02_AXI_0_awready),
        .M02_AXI_awsize(M02_AXI_0_awsize),
        .M02_AXI_awvalid(M02_AXI_0_awvalid),
        .M02_AXI_bready(M02_AXI_0_bready),
        .M02_AXI_bresp(M02_AXI_0_bresp),
        .M02_AXI_bvalid(M02_AXI_0_bvalid),
        .M02_AXI_rdata(M02_AXI_0_rdata),
        .M02_AXI_rlast(M02_AXI_0_rlast),
        .M02_AXI_rready(M02_AXI_0_rready),
        .M02_AXI_rresp(M02_AXI_0_rresp),
        .M02_AXI_rvalid(M02_AXI_0_rvalid),
        .M02_AXI_wdata(M02_AXI_0_wdata),
        .M02_AXI_wlast(M02_AXI_0_wlast),
        .M02_AXI_wready(M02_AXI_0_wready),
        .M02_AXI_wstrb(M02_AXI_0_wstrb),
        .M02_AXI_wvalid(M02_AXI_0_wvalid),
        .S00_AXI_araddr(arbiter_axi_bridge_0_M_AXI_ARADDR),
        .S00_AXI_arburst(arbiter_axi_bridge_0_M_AXI_ARBURST),
        .S00_AXI_arcache(arbiter_axi_bridge_0_M_AXI_ARCACHE),
        .S00_AXI_arlen(arbiter_axi_bridge_0_M_AXI_ARLEN),
        .S00_AXI_arlock(arbiter_axi_bridge_0_M_AXI_ARLOCK),
        .S00_AXI_arprot(arbiter_axi_bridge_0_M_AXI_ARPROT),
        .S00_AXI_arqos(arbiter_axi_bridge_0_M_AXI_ARQOS),
        .S00_AXI_arready(smartconnect_0_S00_AXI_arready),
        .S00_AXI_arsize(arbiter_axi_bridge_0_M_AXI_ARSIZE),
        .S00_AXI_arvalid(arbiter_axi_bridge_0_M_AXI_ARVALID),
        .S00_AXI_awaddr(arbiter_axi_bridge_0_M_AXI_AWADDR),
        .S00_AXI_awburst(arbiter_axi_bridge_0_M_AXI_AWBURST),
        .S00_AXI_awcache(arbiter_axi_bridge_0_M_AXI_AWCACHE),
        .S00_AXI_awlen(arbiter_axi_bridge_0_M_AXI_AWLEN),
        .S00_AXI_awlock(arbiter_axi_bridge_0_M_AXI_AWLOCK),
        .S00_AXI_awprot(arbiter_axi_bridge_0_M_AXI_AWPROT),
        .S00_AXI_awqos(arbiter_axi_bridge_0_M_AXI_AWQOS),
        .S00_AXI_awready(smartconnect_0_S00_AXI_awready),
        .S00_AXI_awsize(arbiter_axi_bridge_0_M_AXI_AWSIZE),
        .S00_AXI_awvalid(arbiter_axi_bridge_0_M_AXI_AWVALID),
        .S00_AXI_bready(arbiter_axi_bridge_0_M_AXI_BREADY),
        .S00_AXI_bresp(smartconnect_0_S00_AXI_bresp),
        .S00_AXI_bvalid(smartconnect_0_S00_AXI_bvalid),
        .S00_AXI_rdata(smartconnect_0_S00_AXI_rdata),
        .S00_AXI_rlast(smartconnect_0_S00_AXI_rlast),
        .S00_AXI_rready(arbiter_axi_bridge_0_M_AXI_RREADY),
        .S00_AXI_rresp(smartconnect_0_S00_AXI_rresp),
        .S00_AXI_rvalid(smartconnect_0_S00_AXI_rvalid),
        .S00_AXI_wdata(arbiter_axi_bridge_0_M_AXI_WDATA),
        .S00_AXI_wlast(arbiter_axi_bridge_0_M_AXI_WLAST),
        .S00_AXI_wready(smartconnect_0_S00_AXI_wready),
        .S00_AXI_wstrb(arbiter_axi_bridge_0_M_AXI_WSTRB),
        .S00_AXI_wvalid(arbiter_axi_bridge_0_M_AXI_WVALID),
        .S01_AXI_araddr(axi_dma_0_m_axi_sg_araddr),
        .S01_AXI_arburst(axi_dma_0_m_axi_sg_arburst),
        .S01_AXI_arcache(axi_dma_0_m_axi_sg_arcache),
        .S01_AXI_arlen(axi_dma_0_m_axi_sg_arlen),
        .S01_AXI_arlock(1'b0),
        .S01_AXI_arprot(axi_dma_0_m_axi_sg_arprot),
        .S01_AXI_arqos({1'b0,1'b0,1'b0,1'b0}),
        .S01_AXI_arready(smartconnect_0_S01_AXI_arready),
        .S01_AXI_arsize(axi_dma_0_m_axi_sg_arsize),
        .S01_AXI_arvalid(axi_dma_0_m_axi_sg_arvalid),
        .S01_AXI_awaddr(axi_dma_0_m_axi_sg_awaddr),
        .S01_AXI_awburst(axi_dma_0_m_axi_sg_awburst),
        .S01_AXI_awcache(axi_dma_0_m_axi_sg_awcache),
        .S01_AXI_awlen(axi_dma_0_m_axi_sg_awlen),
        .S01_AXI_awlock(1'b0),
        .S01_AXI_awprot(axi_dma_0_m_axi_sg_awprot),
        .S01_AXI_awqos({1'b0,1'b0,1'b0,1'b0}),
        .S01_AXI_awready(smartconnect_0_S01_AXI_awready),
        .S01_AXI_awsize(axi_dma_0_m_axi_sg_awsize),
        .S01_AXI_awvalid(axi_dma_0_m_axi_sg_awvalid),
        .S01_AXI_bready(axi_dma_0_m_axi_sg_bready),
        .S01_AXI_bresp(smartconnect_0_S01_AXI_bresp),
        .S01_AXI_bvalid(smartconnect_0_S01_AXI_bvalid),
        .S01_AXI_rdata(smartconnect_0_S01_AXI_rdata),
        .S01_AXI_rlast(smartconnect_0_S01_AXI_rlast),
        .S01_AXI_rready(axi_dma_0_m_axi_sg_rready),
        .S01_AXI_rresp(smartconnect_0_S01_AXI_rresp),
        .S01_AXI_rvalid(smartconnect_0_S01_AXI_rvalid),
        .S01_AXI_wdata(axi_dma_0_m_axi_sg_wdata),
        .S01_AXI_wlast(axi_dma_0_m_axi_sg_wlast),
        .S01_AXI_wready(smartconnect_0_S01_AXI_wready),
        .S01_AXI_wstrb(axi_dma_0_m_axi_sg_wstrb),
        .S01_AXI_wvalid(axi_dma_0_m_axi_sg_wvalid),
        .S02_AXI_araddr(axi_dma_0_m_axi_mm2s_araddr),
        .S02_AXI_arburst(axi_dma_0_m_axi_mm2s_arburst),
        .S02_AXI_arcache(axi_dma_0_m_axi_mm2s_arcache),
        .S02_AXI_arlen(axi_dma_0_m_axi_mm2s_arlen),
        .S02_AXI_arlock(1'b0),
        .S02_AXI_arprot(axi_dma_0_m_axi_mm2s_arprot),
        .S02_AXI_arqos({1'b0,1'b0,1'b0,1'b0}),
        .S02_AXI_arready(smartconnect_0_S02_AXI_arready),
        .S02_AXI_arsize(axi_dma_0_m_axi_mm2s_arsize),
        .S02_AXI_arvalid(axi_dma_0_m_axi_mm2s_arvalid),
        .S02_AXI_rdata(smartconnect_0_S02_AXI_rdata),
        .S02_AXI_rlast(smartconnect_0_S02_AXI_rlast),
        .S02_AXI_rready(axi_dma_0_m_axi_mm2s_rready),
        .S02_AXI_rresp(smartconnect_0_S02_AXI_rresp),
        .S02_AXI_rvalid(smartconnect_0_S02_AXI_rvalid),
        .S03_AXI_awaddr(axi_dma_0_m_axi_s2mm_awaddr),
        .S03_AXI_awburst(axi_dma_0_m_axi_s2mm_awburst),
        .S03_AXI_awcache(axi_dma_0_m_axi_s2mm_awcache),
        .S03_AXI_awlen(axi_dma_0_m_axi_s2mm_awlen),
        .S03_AXI_awlock(1'b0),
        .S03_AXI_awprot(axi_dma_0_m_axi_s2mm_awprot),
        .S03_AXI_awqos({1'b0,1'b0,1'b0,1'b0}),
        .S03_AXI_awready(smartconnect_0_S03_AXI_awready),
        .S03_AXI_awsize(axi_dma_0_m_axi_s2mm_awsize),
        .S03_AXI_awvalid(axi_dma_0_m_axi_s2mm_awvalid),
        .S03_AXI_bready(axi_dma_0_m_axi_s2mm_bready),
        .S03_AXI_bresp(smartconnect_0_S03_AXI_bresp),
        .S03_AXI_bvalid(smartconnect_0_S03_AXI_bvalid),
        .S03_AXI_wdata(axi_dma_0_m_axi_s2mm_wdata),
        .S03_AXI_wlast(axi_dma_0_m_axi_s2mm_wlast),
        .S03_AXI_wready(smartconnect_0_S03_AXI_wready),
        .S03_AXI_wstrb(axi_dma_0_m_axi_s2mm_wstrb),
        .S03_AXI_wvalid(axi_dma_0_m_axi_s2mm_wvalid),
        .aclk(cpu_clk),
        .aclk1(mig_7series_0_ui_clk),
        .aclk2(dma_clk),
        .aclk3(sdcard_clk),
        .aclk4(gpu_clk),
        .aresetn(rst_n));
endmodule
