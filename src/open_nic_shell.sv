// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
`include "open_nic_shell_macros.vh"
`timescale 1ns/1ps
module open_nic_shell #(
  parameter logic [31:0] BUILD_TIMESTAMP = 32'h01010000,
  parameter int          MIN_PKT_LEN     = 64,
  parameter int          MAX_PKT_LEN     = 1518,
  parameter int          USE_PHYS_FUNC   = 1,
  parameter int          NUM_PHYS_FUNC   = 1,
  parameter int          NUM_QUEUE       = 512,
  parameter int          NUM_QDMA        = 1,
  parameter int          NUM_CMAC_PORT   = 0,
  parameter int          NUM_CMAC_CORE   = NUM_CMAC_PORT,
  parameter int          NUM_XXVMAC_PORT = 1,
  parameter int          NUM_XXVMAC_CORE = (NUM_XXVMAC_PORT + 3) / 4,
  parameter int          NUM_PORT        = NUM_CMAC_PORT + NUM_XXVMAC_PORT,
  parameter int          NUM_QSFP_GT     = NUM_CMAC_PORT * 4 + NUM_XXVMAC_PORT,
  parameter int          NUM_QSFP_GT_REF = (NUM_QSFP_GT + 3) / 4
) (
// Fix the CATTRIP issue for AU280, AU50, AU55C, and AU55N custom flow
`ifdef __au280__
  output                         hbm_cattrip,
  input                    [3:0] satellite_gpio,
`elsif __au50__
  output                         hbm_cattrip,
  input                    [1:0] satellite_gpio,
`elsif __au55n__
  output                         hbm_cattrip,
  input                    [3:0] satellite_gpio,
`elsif __au55c__
  output                         hbm_cattrip,
  input                    [3:0] satellite_gpio,
`elsif __au200__
  output                   [1:0] qsfp_resetl,
  input                    [1:0] qsfp_modprsl,
  input                    [1:0] qsfp_intl,
  output                   [1:0] qsfp_lpmode,
  output                   [1:0] qsfp_modsell,
  input                    [3:0] satellite_gpio,
`elsif __au250__
  output                   [1:0] qsfp_resetl,
  input                    [1:0] qsfp_modprsl,
  input                    [1:0] qsfp_intl,
  output                   [1:0] qsfp_lpmode,
  output                   [1:0] qsfp_modsell,
  input                    [3:0] satellite_gpio,
`elsif __au45n__
  input                    [1:0] satellite_gpio,
`endif

  input                          satellite_uart_0_rxd,
  output                         satellite_uart_0_txd,

`ifdef __au45n__
// U45N has 24 PCIe lanes: x16(host CPU) + x8(ARM CPU)
  input                [23:0] pcie_rxp,
  input                [23:0] pcie_rxn,
  output               [23:0] pcie_txp,
  output               [23:0] pcie_txn,
`else
  input     [16*NUM_QDMA-1:0] pcie_rxp,
  input     [16*NUM_QDMA-1:0] pcie_rxn,
  output    [16*NUM_QDMA-1:0] pcie_txp,
  output    [16*NUM_QDMA-1:0] pcie_txn,
`endif
  input        [NUM_QDMA-1:0] pcie_refclk_p,
  input        [NUM_QDMA-1:0] pcie_refclk_n,
  input        [NUM_QDMA-1:0] pcie_rstn,

  input    [NUM_QSFP_GT-1:0] qsfp_rxp,
  input    [NUM_QSFP_GT-1:0] qsfp_rxn,
  output   [NUM_QSFP_GT-1:0] qsfp_txp,
  output   [NUM_QSFP_GT-1:0] qsfp_txn,

`ifdef __au45n__
  input                          dual0_gt_ref_clk_p,
  input                          dual0_gt_ref_clk_n,
  input                          dual1_gt_ref_clk_p,
  input                          dual1_gt_ref_clk_n,
`endif

  input      [NUM_QSFP_GT_REF-1:0] qsfp_refclk_p,
  input      [NUM_QSFP_GT_REF-1:0] qsfp_refclk_n
);

  // Parameter DRC
  initial begin
    if (MIN_PKT_LEN > 256 || MIN_PKT_LEN < 64) begin
      $fatal("[%m] Minimum packet length should be within the range [64, 256]");
    end
    if (MAX_PKT_LEN > 9600 || MAX_PKT_LEN < 256) begin
      $fatal("[%m] Maximum packet length should be within the range [256, 9600]");
    end
    if (USE_PHYS_FUNC) begin
      if (NUM_QUEUE > 2048 || NUM_QUEUE < 1) begin
        $fatal("[%m] Number of queues should be within the range [1, 2048]");
      end
      if ((NUM_QUEUE & (NUM_QUEUE - 1)) != 0) begin
        $fatal("[%m] Number of queues should be 2^n");
      end
      if (NUM_PHYS_FUNC > 4 || NUM_PHYS_FUNC < 1) begin
        $fatal("[%m] Number of physical functions should be within the range [1, 4]");
      end
      if (NUM_QDMA > 2 || NUM_QDMA < 1) begin
        $fatal("[%m] Number of QDMA should be within the range [1, 2]");
      end
    end
    if (NUM_CMAC_PORT > 2 || NUM_CMAC_PORT < 0) begin
      $fatal("[%m] Number of CMACs should be within the range [0, 2]");
    end
    if (NUM_XXVMAC_PORT > 8 || NUM_XXVMAC_PORT < 0) begin
      $fatal("[%m] Number of XXVMACs should be within the range [0, 8]");
    end
    if (NUM_PORT != NUM_PHYS_FUNC) begin
      $fatal("[%m] Number of network ports should be equal to number of physical functions");
    end
    if (NUM_QSFP_GT > 8 || NUM_QSFP_GT < 1) begin
      $fatal("[%m] Number of QSFP GTs should be within the range [0, 8]");
    end
  end

  wire [NUM_QDMA-1:0] powerup_rstn;

  wire [16*NUM_QDMA-1:0] qdma_pcie_rxp;
  wire [16*NUM_QDMA-1:0] qdma_pcie_rxn;
  wire [16*NUM_QDMA-1:0] qdma_pcie_txp;
  wire [16*NUM_QDMA-1:0] qdma_pcie_txn;

  wire [NUM_QDMA-1:0] pcie_user_lnk_up;
  wire [NUM_QDMA-1:0] pcie_phy_ready;
  wire sys_cfg_powerup_rstn;

  // BAR2-mapped master AXI-Lite feeding into system configuration block
  wire     [NUM_QDMA-1:0] axil_pcie_awvalid;
  wire  [32*NUM_QDMA-1:0] axil_pcie_awaddr;
  wire     [NUM_QDMA-1:0] axil_pcie_awready;
  wire     [NUM_QDMA-1:0] axil_pcie_wvalid;
  wire  [32*NUM_QDMA-1:0] axil_pcie_wdata;
  wire     [NUM_QDMA-1:0] axil_pcie_wready;
  wire     [NUM_QDMA-1:0] axil_pcie_bvalid;
  wire   [2*NUM_QDMA-1:0] axil_pcie_bresp;
  wire     [NUM_QDMA-1:0] axil_pcie_bready;
  wire     [NUM_QDMA-1:0] axil_pcie_arvalid;
  wire  [32*NUM_QDMA-1:0] axil_pcie_araddr;
  wire     [NUM_QDMA-1:0] axil_pcie_arready;
  wire     [NUM_QDMA-1:0] axil_pcie_rvalid;
  wire  [32*NUM_QDMA-1:0] axil_pcie_rdata;
  wire   [2*NUM_QDMA-1:0] axil_pcie_rresp;
  wire     [NUM_QDMA-1:0] axil_pcie_rready;

  wire     [NUM_QDMA-1:0] pcie_rstn_int;
  generate for (genvar i = 0; i < NUM_QDMA; i++) begin
    IBUF pcie_rstn_ibuf_inst (.I(pcie_rstn[i]), .O(pcie_rstn_int[i]));
  end
  endgenerate

// Fix the CATTRIP issue for AU280, AU50, AU55C and AU55N custom flow
//
// This pin must be tied to 0; otherwise the board might be unrecoverable
// after programming
// Connect QSFP control lines through to the CMS for AU200 and AU250
`ifdef __au280__
  OBUF hbm_cattrip_obuf_inst (.I(1'b0), .O(hbm_cattrip));
`elsif __au50__
  OBUF hbm_cattrip_obuf_inst (.I(1'b0), .O(hbm_cattrip));
`elsif __au55n__
  OBUF hbm_cattrip_obuf_inst (.I(1'b0), .O(hbm_cattrip));
`elsif __au55c__
  OBUF hbm_cattrip_obuf_inst (.I(1'b0), .O(hbm_cattrip));
`elsif __au250__
`elsif __au200__
`endif

`ifdef __zynq_family__
  zynq_usplus_ps zynq_usplus_ps_inst ();
`endif

  wire          [NUM_QDMA-1:0] axil_qdma_awvalid;
  wire       [32*NUM_QDMA-1:0] axil_qdma_awaddr;
  wire          [NUM_QDMA-1:0] axil_qdma_awready;
  wire          [NUM_QDMA-1:0] axil_qdma_wvalid;
  wire       [32*NUM_QDMA-1:0] axil_qdma_wdata;
  wire          [NUM_QDMA-1:0] axil_qdma_wready;
  wire          [NUM_QDMA-1:0] axil_qdma_bvalid;
  wire        [2*NUM_QDMA-1:0] axil_qdma_bresp;
  wire          [NUM_QDMA-1:0] axil_qdma_bready;
  wire          [NUM_QDMA-1:0] axil_qdma_arvalid;
  wire       [32*NUM_QDMA-1:0] axil_qdma_araddr;
  wire          [NUM_QDMA-1:0] axil_qdma_arready;
  wire          [NUM_QDMA-1:0] axil_qdma_rvalid;
  wire       [32*NUM_QDMA-1:0] axil_qdma_rdata;
  wire        [2*NUM_QDMA-1:0] axil_qdma_rresp;
  wire          [NUM_QDMA-1:0] axil_qdma_rready;

  wire          [NUM_PORT-1:0] axil_adap_awvalid;
  wire       [32*NUM_PORT-1:0] axil_adap_awaddr;
  wire          [NUM_PORT-1:0] axil_adap_awready;
  wire          [NUM_PORT-1:0] axil_adap_wvalid;
  wire       [32*NUM_PORT-1:0] axil_adap_wdata;
  wire          [NUM_PORT-1:0] axil_adap_wready;
  wire          [NUM_PORT-1:0] axil_adap_bvalid;
  wire        [2*NUM_PORT-1:0] axil_adap_bresp;
  wire          [NUM_PORT-1:0] axil_adap_bready;
  wire          [NUM_PORT-1:0] axil_adap_arvalid;
  wire       [32*NUM_PORT-1:0] axil_adap_araddr;
  wire          [NUM_PORT-1:0] axil_adap_arready;
  wire          [NUM_PORT-1:0] axil_adap_rvalid;
  wire       [32*NUM_PORT-1:0] axil_adap_rdata;
  wire        [2*NUM_PORT-1:0] axil_adap_rresp;
  wire          [NUM_PORT-1:0] axil_adap_rready;

  wire          [NUM_PORT-1:0] axil_cmac_awvalid;
  wire       [32*NUM_PORT-1:0] axil_cmac_awaddr;
  wire          [NUM_PORT-1:0] axil_cmac_awready;
  wire          [NUM_PORT-1:0] axil_cmac_wvalid;
  wire       [32*NUM_PORT-1:0] axil_cmac_wdata;
  wire          [NUM_PORT-1:0] axil_cmac_wready;
  wire          [NUM_PORT-1:0] axil_cmac_bvalid;
  wire        [2*NUM_PORT-1:0] axil_cmac_bresp;
  wire          [NUM_PORT-1:0] axil_cmac_bready;
  wire          [NUM_PORT-1:0] axil_cmac_arvalid;
  wire       [32*NUM_PORT-1:0] axil_cmac_araddr;
  wire          [NUM_PORT-1:0] axil_cmac_arready;
  wire          [NUM_PORT-1:0] axil_cmac_rvalid;
  wire       [32*NUM_PORT-1:0] axil_cmac_rdata;
  wire        [2*NUM_PORT-1:0] axil_cmac_rresp;
  wire          [NUM_PORT-1:0] axil_cmac_rready;

  wire                         axil_box0_awvalid;
  wire                  [31:0] axil_box0_awaddr;
  wire                         axil_box0_awready;
  wire                         axil_box0_wvalid;
  wire                  [31:0] axil_box0_wdata;
  wire                         axil_box0_wready;
  wire                         axil_box0_bvalid;
  wire                   [1:0] axil_box0_bresp;
  wire                         axil_box0_bready;
  wire                         axil_box0_arvalid;
  wire                  [31:0] axil_box0_araddr;
  wire                         axil_box0_arready;
  wire                         axil_box0_rvalid;
  wire                  [31:0] axil_box0_rdata;
  wire                   [1:0] axil_box0_rresp;
  wire                         axil_box0_rready;

  wire                         axil_box1_awvalid;
  wire                  [31:0] axil_box1_awaddr;
  wire                         axil_box1_awready;
  wire                         axil_box1_wvalid;
  wire                  [31:0] axil_box1_wdata;
  wire                         axil_box1_wready;
  wire                         axil_box1_bvalid;
  wire                   [1:0] axil_box1_bresp;
  wire                         axil_box1_bready;
  wire                         axil_box1_arvalid;
  wire                  [31:0] axil_box1_araddr;
  wire                         axil_box1_arready;
  wire                         axil_box1_rvalid;
  wire                  [31:0] axil_box1_rdata;
  wire                   [1:0] axil_box1_rresp;
  wire                         axil_box1_rready;

  // QDMA subsystem interfaces to the box running at 250MHz
  wire     [NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tvalid;
  wire [512*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tdata;
  wire  [64*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tkeep;
  wire     [NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tlast;
  wire  [16*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tuser_size;
  wire  [16*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tuser_src;
  wire  [16*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tuser_dst;
  wire     [NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_h2c_tready;

  wire     [NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tvalid;
  wire [512*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tdata;
  wire  [64*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tkeep;
  wire     [NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tlast;
  wire  [16*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tuser_size;
  wire  [16*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tuser_src;
  wire  [16*NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tuser_dst;
  wire     [NUM_PHYS_FUNC*NUM_QDMA-1:0] axis_qdma_c2h_tready;

  // Packet adapter interfaces to the box running at 250MHz
  wire          [NUM_PORT-1:0] axis_adap_tx_250mhz_tvalid;
  wire      [512*NUM_PORT-1:0] axis_adap_tx_250mhz_tdata;
  wire       [64*NUM_PORT-1:0] axis_adap_tx_250mhz_tkeep;
  wire          [NUM_PORT-1:0] axis_adap_tx_250mhz_tlast;
  wire       [16*NUM_PORT-1:0] axis_adap_tx_250mhz_tuser_size;
  wire       [16*NUM_PORT-1:0] axis_adap_tx_250mhz_tuser_src;
  wire       [16*NUM_PORT-1:0] axis_adap_tx_250mhz_tuser_dst;
  wire          [NUM_PORT-1:0] axis_adap_tx_250mhz_tready;

  wire          [NUM_PORT-1:0] axis_adap_rx_250mhz_tvalid;
  wire      [512*NUM_PORT-1:0] axis_adap_rx_250mhz_tdata;
  wire       [64*NUM_PORT-1:0] axis_adap_rx_250mhz_tkeep;
  wire          [NUM_PORT-1:0] axis_adap_rx_250mhz_tlast;
  wire       [16*NUM_PORT-1:0] axis_adap_rx_250mhz_tuser_size;
  wire       [16*NUM_PORT-1:0] axis_adap_rx_250mhz_tuser_src;
  wire       [16*NUM_PORT-1:0] axis_adap_rx_250mhz_tuser_dst;
  wire          [NUM_PORT-1:0] axis_adap_rx_250mhz_tready;

  // Packet adapter interfaces to the box running at 322MHz
  wire          [NUM_PORT-1:0] axis_adap_tx_322mhz_tvalid;
  wire      [512*NUM_PORT-1:0] axis_adap_tx_322mhz_tdata;
  wire       [64*NUM_PORT-1:0] axis_adap_tx_322mhz_tkeep;
  wire          [NUM_PORT-1:0] axis_adap_tx_322mhz_tlast;
  wire          [NUM_PORT-1:0] axis_adap_tx_322mhz_tuser_err;
  wire          [NUM_PORT-1:0] axis_adap_tx_322mhz_tready;

  wire          [NUM_PORT-1:0] axis_adap_rx_322mhz_tvalid;
  wire      [512*NUM_PORT-1:0] axis_adap_rx_322mhz_tdata;
  wire       [64*NUM_PORT-1:0] axis_adap_rx_322mhz_tkeep;
  wire          [NUM_PORT-1:0] axis_adap_rx_322mhz_tlast;
  wire          [NUM_PORT-1:0] axis_adap_rx_322mhz_tuser_err;

  // CMAC subsystem interfaces to the box running at 322MHz
  wire          [NUM_PORT-1:0] axis_cmac_tx_tvalid;
  wire      [512*NUM_PORT-1:0] axis_cmac_tx_tdata;
  wire       [64*NUM_PORT-1:0] axis_cmac_tx_tkeep;
  wire          [NUM_PORT-1:0] axis_cmac_tx_tlast;
  wire          [NUM_PORT-1:0] axis_cmac_tx_tuser_err;
  wire          [NUM_PORT-1:0] axis_cmac_tx_tready;

  wire          [NUM_PORT-1:0] axis_cmac_rx_tvalid;
  wire      [512*NUM_PORT-1:0] axis_cmac_rx_tdata;
  wire       [64*NUM_PORT-1:0] axis_cmac_rx_tkeep;
  wire          [NUM_PORT-1:0] axis_cmac_rx_tlast;
  wire          [NUM_PORT-1:0] axis_cmac_rx_tuser_err;

  wire                  [31:0] shell_rstn;
  wire                  [31:0] shell_rst_done;
  wire          [NUM_QDMA-1:0] qdma_rstn;
  wire          [NUM_QDMA-1:0] qdma_rst_done;
  wire          [NUM_PORT-1:0] adap_rstn;
  wire          [NUM_PORT-1:0] adap_rst_done;
  wire          [NUM_PORT-1:0] cmac_rstn;
  wire          [NUM_PORT-1:0] cmac_rst_done;

  wire                  [31:0] user_rstn;
  wire                  [31:0] user_rst_done;
  wire                  [15:0] user_250mhz_rstn;
  wire                  [15:0] user_250mhz_rst_done;
  wire                   [7:0] user_322mhz_rstn;
  wire                   [7:0] user_322mhz_rst_done;
  wire                         box_250mhz_rstn;
  wire                         box_250mhz_rst_done;
  wire                         box_322mhz_rstn;
  wire                         box_322mhz_rst_done;

  wire          [NUM_QDMA-1:0] axil_aclk;
  wire          [NUM_QDMA-1:0] axis_aclk;

`ifdef __au55n__
  wire                         ref_clk_100mhz;
`elsif __au55c__
  wire                         ref_clk_100mhz;
`elsif __au50__
  wire                         ref_clk_100mhz;
`elsif __au280__
  wire                         ref_clk_100mhz;
`endif

  wire          [NUM_PORT-1:0] cmac_clk;

  // Unused reset pairs must have their "reset_done" tied to 1

  // First 4-bit for QDMA subsystem
  assign qdma_rstn                    = shell_rstn[NUM_QDMA-1:0];
  assign shell_rst_done[NUM_QDMA-1:0] = qdma_rst_done;
  assign shell_rst_done[3:NUM_QDMA]   = {4-NUM_QDMA{1'b1}};

  // For each CMAC port, use the subsequent 4-bit: bit 0 for CMAC subsystem and
  // bit 1 for the corresponding adapter
  generate for (genvar i = 0; i < NUM_PORT; i++) begin: cmac_rst
    assign {adap_rstn[i], cmac_rstn[i]} = {shell_rstn[(i+1)*4+1], shell_rstn[(i+1)*4]};
    assign shell_rst_done[(i+1)*4 +: 4] = {2'b11, adap_rst_done[i], cmac_rst_done[i]};
  end: cmac_rst
  endgenerate

  generate for (genvar i = (NUM_PORT+1)*4; i < 32; i++) begin: unused_rst
    assign shell_rst_done[i] = 1'b1;
  end: unused_rst
  endgenerate

  // The box running at 250MHz takes 16+1 user reset pairs, with the extra one
  // used by the box itself.  Similarly, the box running at 322MHz takes 8+1
  // pairs.  The mapping is as follows.
  //
  // | 31    | 30    | 29 ... 24 | 23 ... 16 | 15 ... 0 |
  // ----------------------------------------------------
  // | b@250 | b@322 | Reserved  | user@322  | user@250 |
  assign user_250mhz_rstn     = user_rstn[15:0];
  assign user_rst_done[15:0]  = user_250mhz_rst_done;
  assign user_322mhz_rstn     = user_rstn[23:16];
  assign user_rst_done[23:16] = user_322mhz_rst_done;

  assign box_250mhz_rstn      = user_rstn[31];
  assign user_rst_done[31]    = box_250mhz_rst_done;
  assign box_322mhz_rstn      = user_rstn[30];
  assign user_rst_done[30]    = box_322mhz_rst_done;

  // Unused pairs must have their rst_done signals tied to 1
  assign user_rst_done[29:24] = {6{1'b1}};


  assign sys_cfg_powerup_rstn = | powerup_rstn;

`ifdef __au45n__
  assign qdma_pcie_rxp[23:0] = pcie_rxp;
  assign qdma_pcie_rxn[23:0] = pcie_rxn;
  assign qdma_pcie_txp[23:0] = pcie_txp;
  assign qdma_pcie_txn[23:0] = pcie_txn;
`else
  assign qdma_pcie_rxp       = pcie_rxp;
  assign qdma_pcie_rxn       = pcie_rxn;
  assign qdma_pcie_txp       = pcie_txp;
  assign qdma_pcie_txn       = pcie_txn;
`endif

  system_config #(
    .BUILD_TIMESTAMP (BUILD_TIMESTAMP),
    .NUM_QDMA        (NUM_QDMA),
    .NUM_CMAC_PORT   (NUM_PORT)
  ) system_config_inst (
    .s_axil_awvalid      (axil_pcie_awvalid),
    .s_axil_awaddr       (axil_pcie_awaddr),
    .s_axil_awready      (axil_pcie_awready),
    .s_axil_wvalid       (axil_pcie_wvalid),
    .s_axil_wdata        (axil_pcie_wdata),
    .s_axil_wready       (axil_pcie_wready),
    .s_axil_bvalid       (axil_pcie_bvalid),
    .s_axil_bresp        (axil_pcie_bresp),
    .s_axil_bready       (axil_pcie_bready),
    .s_axil_arvalid      (axil_pcie_arvalid),
    .s_axil_araddr       (axil_pcie_araddr),
    .s_axil_arready      (axil_pcie_arready),
    .s_axil_rvalid       (axil_pcie_rvalid),
    .s_axil_rdata        (axil_pcie_rdata),
    .s_axil_rresp        (axil_pcie_rresp),
    .s_axil_rready       (axil_pcie_rready),

    .m_axil_qdma_awvalid (axil_qdma_awvalid),
    .m_axil_qdma_awaddr  (axil_qdma_awaddr),
    .m_axil_qdma_awready (axil_qdma_awready),
    .m_axil_qdma_wvalid  (axil_qdma_wvalid),
    .m_axil_qdma_wdata   (axil_qdma_wdata),
    .m_axil_qdma_wready  (axil_qdma_wready),
    .m_axil_qdma_bvalid  (axil_qdma_bvalid),
    .m_axil_qdma_bresp   (axil_qdma_bresp),
    .m_axil_qdma_bready  (axil_qdma_bready),
    .m_axil_qdma_arvalid (axil_qdma_arvalid),
    .m_axil_qdma_araddr  (axil_qdma_araddr),
    .m_axil_qdma_arready (axil_qdma_arready),
    .m_axil_qdma_rvalid  (axil_qdma_rvalid),
    .m_axil_qdma_rdata   (axil_qdma_rdata),
    .m_axil_qdma_rresp   (axil_qdma_rresp),
    .m_axil_qdma_rready  (axil_qdma_rready),

    .m_axil_adap_awvalid (axil_adap_awvalid),
    .m_axil_adap_awaddr  (axil_adap_awaddr),
    .m_axil_adap_awready (axil_adap_awready),
    .m_axil_adap_wvalid  (axil_adap_wvalid),
    .m_axil_adap_wdata   (axil_adap_wdata),
    .m_axil_adap_wready  (axil_adap_wready),
    .m_axil_adap_bvalid  (axil_adap_bvalid),
    .m_axil_adap_bresp   (axil_adap_bresp),
    .m_axil_adap_bready  (axil_adap_bready),
    .m_axil_adap_arvalid (axil_adap_arvalid),
    .m_axil_adap_araddr  (axil_adap_araddr),
    .m_axil_adap_arready (axil_adap_arready),
    .m_axil_adap_rvalid  (axil_adap_rvalid),
    .m_axil_adap_rdata   (axil_adap_rdata),
    .m_axil_adap_rresp   (axil_adap_rresp),
    .m_axil_adap_rready  (axil_adap_rready),

    .m_axil_cmac_awvalid (axil_cmac_awvalid),
    .m_axil_cmac_awaddr  (axil_cmac_awaddr),
    .m_axil_cmac_awready (axil_cmac_awready),
    .m_axil_cmac_wvalid  (axil_cmac_wvalid),
    .m_axil_cmac_wdata   (axil_cmac_wdata),
    .m_axil_cmac_wready  (axil_cmac_wready),
    .m_axil_cmac_bvalid  (axil_cmac_bvalid),
    .m_axil_cmac_bresp   (axil_cmac_bresp),
    .m_axil_cmac_bready  (axil_cmac_bready),
    .m_axil_cmac_arvalid (axil_cmac_arvalid),
    .m_axil_cmac_araddr  (axil_cmac_araddr),
    .m_axil_cmac_arready (axil_cmac_arready),
    .m_axil_cmac_rvalid  (axil_cmac_rvalid),
    .m_axil_cmac_rdata   (axil_cmac_rdata),
    .m_axil_cmac_rresp   (axil_cmac_rresp),
    .m_axil_cmac_rready  (axil_cmac_rready),

    .m_axil_box0_awvalid (axil_box0_awvalid),
    .m_axil_box0_awaddr  (axil_box0_awaddr),
    .m_axil_box0_awready (axil_box0_awready),
    .m_axil_box0_wvalid  (axil_box0_wvalid),
    .m_axil_box0_wdata   (axil_box0_wdata),
    .m_axil_box0_wready  (axil_box0_wready),
    .m_axil_box0_bvalid  (axil_box0_bvalid),
    .m_axil_box0_bresp   (axil_box0_bresp),
    .m_axil_box0_bready  (axil_box0_bready),
    .m_axil_box0_arvalid (axil_box0_arvalid),
    .m_axil_box0_araddr  (axil_box0_araddr),
    .m_axil_box0_arready (axil_box0_arready),
    .m_axil_box0_rvalid  (axil_box0_rvalid),
    .m_axil_box0_rdata   (axil_box0_rdata),
    .m_axil_box0_rresp   (axil_box0_rresp),
    .m_axil_box0_rready  (axil_box0_rready),

    .m_axil_box1_awvalid (axil_box1_awvalid),
    .m_axil_box1_awaddr  (axil_box1_awaddr),
    .m_axil_box1_awready (axil_box1_awready),
    .m_axil_box1_wvalid  (axil_box1_wvalid),
    .m_axil_box1_wdata   (axil_box1_wdata),
    .m_axil_box1_wready  (axil_box1_wready),
    .m_axil_box1_bvalid  (axil_box1_bvalid),
    .m_axil_box1_bresp   (axil_box1_bresp),
    .m_axil_box1_bready  (axil_box1_bready),
    .m_axil_box1_arvalid (axil_box1_arvalid),
    .m_axil_box1_araddr  (axil_box1_araddr),
    .m_axil_box1_arready (axil_box1_arready),
    .m_axil_box1_rvalid  (axil_box1_rvalid),
    .m_axil_box1_rdata   (axil_box1_rdata),
    .m_axil_box1_rresp   (axil_box1_rresp),
    .m_axil_box1_rready  (axil_box1_rready),

    .shell_rstn          (shell_rstn),
    .shell_rst_done      (shell_rst_done),
    .user_rstn           (user_rstn),
    .user_rst_done       (user_rst_done),

    .satellite_uart_0_rxd (satellite_uart_0_rxd),
    .satellite_uart_0_txd (satellite_uart_0_txd),
    .satellite_gpio_0     (satellite_gpio),

  `ifdef __au280__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),
  `elsif __au55n__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),
  `elsif __au55c__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),
  `elsif __au50__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),
  `elsif __au200__
    .qsfp_resetl             (qsfp_resetl),
    .qsfp_modprsl            (qsfp_modprsl),
    .qsfp_intl               (qsfp_intl),
    .qsfp_lpmode             (qsfp_lpmode),
    .qsfp_modsell            (qsfp_modsell),
  `elsif __au250__
    .qsfp_resetl             (qsfp_resetl),
    .qsfp_modprsl            (qsfp_modprsl),
    .qsfp_intl               (qsfp_intl),
    .qsfp_lpmode             (qsfp_lpmode),
    .qsfp_modsell            (qsfp_modsell),
  `elsif __au45n__
  `endif

    .aclk                (axil_aclk),
    .aresetn             (sys_cfg_powerup_rstn)
  );

  generate for (genvar i = 0; i < NUM_QDMA; i++) begin: qdma_if
    qdma_subsystem #(
      .QDMA_ID       (i),
      .MIN_PKT_LEN   (MIN_PKT_LEN),
      .MAX_PKT_LEN   (MAX_PKT_LEN),
      .USE_PHYS_FUNC (USE_PHYS_FUNC),
      .NUM_PHYS_FUNC (NUM_PHYS_FUNC),
      .NUM_QUEUE     (NUM_QUEUE)
    ) qdma_subsystem_inst (
      .s_axil_awvalid                       (axil_qdma_awvalid[i]),
      .s_axil_awaddr                        (axil_qdma_awaddr[`getvec(32, i)]),
      .s_axil_awready                       (axil_qdma_awready[i]),
      .s_axil_wvalid                        (axil_qdma_wvalid[i]),
      .s_axil_wdata                         (axil_qdma_wdata[`getvec(32, i)]),
      .s_axil_wready                        (axil_qdma_wready[i]),
      .s_axil_bvalid                        (axil_qdma_bvalid[i]),
      .s_axil_bresp                         (axil_qdma_bresp[`getvec(2, i)]),
      .s_axil_bready                        (axil_qdma_bready[i]),
      .s_axil_arvalid                       (axil_qdma_arvalid[i]),
      .s_axil_araddr                        (axil_qdma_araddr[`getvec(32, i)]),
      .s_axil_arready                       (axil_qdma_arready[i]),
      .s_axil_rvalid                        (axil_qdma_rvalid[i]),
      .s_axil_rdata                         (axil_qdma_rdata[`getvec(32, i)]),
      .s_axil_rresp                         (axil_qdma_rresp[`getvec(2, i)]),
      .s_axil_rready                        (axil_qdma_rready[i]),

      .m_axis_h2c_tvalid                    (axis_qdma_h2c_tvalid[`getvec(NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tdata                     (axis_qdma_h2c_tdata[`getvec(512*NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tkeep                     (axis_qdma_h2c_tkeep[`getvec(64*NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tlast                     (axis_qdma_h2c_tlast[`getvec(NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tuser_size                (axis_qdma_h2c_tuser_size[`getvec(16*NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tuser_src                 (axis_qdma_h2c_tuser_src[`getvec(16*NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tuser_dst                 (axis_qdma_h2c_tuser_dst[`getvec(16*NUM_PHYS_FUNC, i)]),
      .m_axis_h2c_tready                    (axis_qdma_h2c_tready[`getvec(NUM_PHYS_FUNC, i)]),

      .s_axis_c2h_tvalid                    (axis_qdma_c2h_tvalid[`getvec(NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tdata                     (axis_qdma_c2h_tdata[`getvec(512*NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tkeep                     (axis_qdma_c2h_tkeep[`getvec(64*NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tlast                     (axis_qdma_c2h_tlast[`getvec(NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tuser_size                (axis_qdma_c2h_tuser_size[`getvec(16*NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tuser_src                 (axis_qdma_c2h_tuser_src[`getvec(16*NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tuser_dst                 (axis_qdma_c2h_tuser_dst[`getvec(16*NUM_PHYS_FUNC, i)]),
      .s_axis_c2h_tready                    (axis_qdma_c2h_tready[`getvec(NUM_PHYS_FUNC, i)]),

      .pcie_rxp                             (qdma_pcie_rxp[`getvec(16, i)]),
      .pcie_rxn                             (qdma_pcie_rxn[`getvec(16, i)]),
      .pcie_txp                             (qdma_pcie_txp[`getvec(16, i)]),
      .pcie_txn                             (qdma_pcie_txn[`getvec(16, i)]),

      .m_axil_pcie_awvalid                  (axil_pcie_awvalid[i]),
      .m_axil_pcie_awaddr                   (axil_pcie_awaddr[`getvec(32, i)]),
      .m_axil_pcie_awready                  (axil_pcie_awready[i]),
      .m_axil_pcie_wvalid                   (axil_pcie_wvalid[i]),
      .m_axil_pcie_wdata                    (axil_pcie_wdata[`getvec(32, i)]),
      .m_axil_pcie_wready                   (axil_pcie_wready[i]),
      .m_axil_pcie_bvalid                   (axil_pcie_bvalid[i]),
      .m_axil_pcie_bresp                    (axil_pcie_bresp[`getvec(2, i)]),
      .m_axil_pcie_bready                   (axil_pcie_bready[i]),
      .m_axil_pcie_arvalid                  (axil_pcie_arvalid[i]),
      .m_axil_pcie_araddr                   (axil_pcie_araddr[`getvec(32, i)]),
      .m_axil_pcie_arready                  (axil_pcie_arready[i]),
      .m_axil_pcie_rvalid                   (axil_pcie_rvalid[i]),
      .m_axil_pcie_rdata                    (axil_pcie_rdata[`getvec(32, i)]),
      .m_axil_pcie_rresp                    (axil_pcie_rresp[`getvec(2, i)]),
      .m_axil_pcie_rready                   (axil_pcie_rready[i]),

      .pcie_refclk_p                        (pcie_refclk_p[i]),
      .pcie_refclk_n                        (pcie_refclk_n[i]),
      .pcie_rstn                            (pcie_rstn_int[i]),
      .user_lnk_up                          (pcie_user_lnk_up[i]),
      .phy_ready                            (pcie_phy_ready[i]),
      .powerup_rstn                         (powerup_rstn[i]),

      .mod_rstn                             (qdma_rstn[i]),
      .mod_rst_done                         (qdma_rst_done[i]),

      .axil_cfg_aclk                        (axil_aclk[0]),
      .axil_aclk                            (axil_aclk[i]),

    `ifdef __au55n__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `elsif __au55c__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `elsif __au50__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `elsif __au280__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `endif
      .axis_master_aclk                     (axis_aclk[0]),
      .axis_aclk                            (axis_aclk[i])
    );
  end: qdma_if
  endgenerate

  generate for (genvar i = 0; i < NUM_PORT; i++) begin: cmac_port
    packet_adapter #(
      .CMAC_ID     (i),
      .MIN_PKT_LEN (MIN_PKT_LEN),
      .MAX_PKT_LEN (MAX_PKT_LEN)
    ) packet_adapter_inst (
      .s_axil_awvalid       (axil_adap_awvalid[i]),
      .s_axil_awaddr        (axil_adap_awaddr[`getvec(32, i)]),
      .s_axil_awready       (axil_adap_awready[i]),
      .s_axil_wvalid        (axil_adap_wvalid[i]),
      .s_axil_wdata         (axil_adap_wdata[`getvec(32, i)]),
      .s_axil_wready        (axil_adap_wready[i]),
      .s_axil_bvalid        (axil_adap_bvalid[i]),
      .s_axil_bresp         (axil_adap_bresp[`getvec(2, i)]),
      .s_axil_bready        (axil_adap_bready[i]),
      .s_axil_arvalid       (axil_adap_arvalid[i]),
      .s_axil_araddr        (axil_adap_araddr[`getvec(32, i)]),
      .s_axil_arready       (axil_adap_arready[i]),
      .s_axil_rvalid        (axil_adap_rvalid[i]),
      .s_axil_rdata         (axil_adap_rdata[`getvec(32, i)]),
      .s_axil_rresp         (axil_adap_rresp[`getvec(2, i)]),
      .s_axil_rready        (axil_adap_rready[i]),

      .s_axis_tx_tvalid     (axis_adap_tx_250mhz_tvalid[i]),
      .s_axis_tx_tdata      (axis_adap_tx_250mhz_tdata[`getvec(512, i)]),
      .s_axis_tx_tkeep      (axis_adap_tx_250mhz_tkeep[`getvec(64, i)]),
      .s_axis_tx_tlast      (axis_adap_tx_250mhz_tlast[i]),
      .s_axis_tx_tuser_size (axis_adap_tx_250mhz_tuser_size[`getvec(16, i)]),
      .s_axis_tx_tuser_src  (axis_adap_tx_250mhz_tuser_src[`getvec(16, i)]),
      .s_axis_tx_tuser_dst  (axis_adap_tx_250mhz_tuser_dst[`getvec(16, i)]),
      .s_axis_tx_tready     (axis_adap_tx_250mhz_tready[i]),

      .m_axis_rx_tvalid     (axis_adap_rx_250mhz_tvalid[i]),
      .m_axis_rx_tdata      (axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
      .m_axis_rx_tkeep      (axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
      .m_axis_rx_tlast      (axis_adap_rx_250mhz_tlast[i]),
      .m_axis_rx_tuser_size (axis_adap_rx_250mhz_tuser_size[`getvec(16, i)]),
      .m_axis_rx_tuser_src  (axis_adap_rx_250mhz_tuser_src[`getvec(16, i)]),
      .m_axis_rx_tuser_dst  (axis_adap_rx_250mhz_tuser_dst[`getvec(16, i)]),
      .m_axis_rx_tready     (axis_adap_rx_250mhz_tready[i]),

      .m_axis_tx_tvalid     (axis_adap_tx_322mhz_tvalid[i]),
      .m_axis_tx_tdata      (axis_adap_tx_322mhz_tdata[`getvec(512, i)]),
      .m_axis_tx_tkeep      (axis_adap_tx_322mhz_tkeep[`getvec(64, i)]),
      .m_axis_tx_tlast      (axis_adap_tx_322mhz_tlast[i]),
      .m_axis_tx_tuser_err  (axis_adap_tx_322mhz_tuser_err[i]),
      .m_axis_tx_tready     (axis_adap_tx_322mhz_tready[i]),

      .s_axis_rx_tvalid     (axis_adap_rx_322mhz_tvalid[i]),
      .s_axis_rx_tdata      (axis_adap_rx_322mhz_tdata[`getvec(512, i)]),
      .s_axis_rx_tkeep      (axis_adap_rx_322mhz_tkeep[`getvec(64, i)]),
      .s_axis_rx_tlast      (axis_adap_rx_322mhz_tlast[i]),
      .s_axis_rx_tuser_err  (axis_adap_rx_322mhz_tuser_err[i]),

      .mod_rstn             (adap_rstn[i]),
      .mod_rst_done         (adap_rst_done[i]),

      .axil_aclk            (axil_aclk[0]),
      .axis_aclk            (axis_aclk[0]),
      .cmac_clk             (cmac_clk[i])
    );
  end: cmac_port
  endgenerate

  generate for (genvar i = 0; i < NUM_CMAC_CORE; i++) begin: cmac_core
    cmac_subsystem #(
      .CMAC_ID     (i),
      .MIN_PKT_LEN (MIN_PKT_LEN),
      .MAX_PKT_LEN (MAX_PKT_LEN)
    ) cmac_subsystem_inst (
      .s_axil_awvalid               (axil_cmac_awvalid[i]),
      .s_axil_awaddr                (axil_cmac_awaddr[`getvec(32, i)]),
      .s_axil_awready               (axil_cmac_awready[i]),
      .s_axil_wvalid                (axil_cmac_wvalid[i]),
      .s_axil_wdata                 (axil_cmac_wdata[`getvec(32, i)]),
      .s_axil_wready                (axil_cmac_wready[i]),
      .s_axil_bvalid                (axil_cmac_bvalid[i]),
      .s_axil_bresp                 (axil_cmac_bresp[`getvec(2, i)]),
      .s_axil_bready                (axil_cmac_bready[i]),
      .s_axil_arvalid               (axil_cmac_arvalid[i]),
      .s_axil_araddr                (axil_cmac_araddr[`getvec(32, i)]),
      .s_axil_arready               (axil_cmac_arready[i]),
      .s_axil_rvalid                (axil_cmac_rvalid[i]),
      .s_axil_rdata                 (axil_cmac_rdata[`getvec(32, i)]),
      .s_axil_rresp                 (axil_cmac_rresp[`getvec(2, i)]),
      .s_axil_rready                (axil_cmac_rready[i]),

      .s_axis_cmac_tx_tvalid        (axis_cmac_tx_tvalid[i]),
      .s_axis_cmac_tx_tdata         (axis_cmac_tx_tdata[`getvec(512, i)]),
      .s_axis_cmac_tx_tkeep         (axis_cmac_tx_tkeep[`getvec(64, i)]),
      .s_axis_cmac_tx_tlast         (axis_cmac_tx_tlast[i]),
      .s_axis_cmac_tx_tuser_err     (axis_cmac_tx_tuser_err[i]),
      .s_axis_cmac_tx_tready        (axis_cmac_tx_tready[i]),

      .m_axis_cmac_rx_tvalid        (axis_cmac_rx_tvalid[i]),
      .m_axis_cmac_rx_tdata         (axis_cmac_rx_tdata[`getvec(512, i)]),
      .m_axis_cmac_rx_tkeep         (axis_cmac_rx_tkeep[`getvec(64, i)]),
      .m_axis_cmac_rx_tlast         (axis_cmac_rx_tlast[i]),
      .m_axis_cmac_rx_tuser_err     (axis_cmac_rx_tuser_err[i]),

      .gt_rxp                       (qsfp_rxp[`getvec(4, i)]),
      .gt_rxn                       (qsfp_rxn[`getvec(4, i)]),
      .gt_txp                       (qsfp_txp[`getvec(4, i)]),
      .gt_txn                       (qsfp_txn[`getvec(4, i)]),
      .gt_refclk_p                  (qsfp_refclk_p[i]),
      .gt_refclk_n                  (qsfp_refclk_n[i]),

`ifdef __au45n__
      .dual0_gt_ref_clk_p           (dual0_gt_ref_clk_p),
      .dual0_gt_ref_clk_n           (dual0_gt_ref_clk_n),
      .dual1_gt_ref_clk_p           (dual1_gt_ref_clk_p),
      .dual1_gt_ref_clk_n           (dual1_gt_ref_clk_n),
`endif

      .cmac_clk                     (cmac_clk[i]),

      .mod_rstn                     (cmac_rstn[i]),
      .mod_rst_done                 (cmac_rst_done[i]),
      .axil_aclk                    (axil_aclk[0])
    );
  end: cmac_core
  endgenerate

  generate for (genvar j = 0; j < NUM_XXVMAC_CORE; j++) begin: xxvmac_core
    localparam int i = NUM_CMAC_CORE + j;
    localparam int NUM_PORT_PER_CORE = NUM_XXVMAC_PORT - 4 * j < 4 ? NUM_XXVMAC_PORT - 4 * j : 4;
    xxvmac_subsystem #(
      .XXVMAC_ID   (i),
      .NUM_PORT    (NUM_PORT_PER_CORE),
      .MIN_PKT_LEN (MIN_PKT_LEN),
      .MAX_PKT_LEN (MAX_PKT_LEN)
    ) cmac_subsystem_inst (
      .s_axil_awvalid               (axil_cmac_awvalid     [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_awaddr                (axil_cmac_awaddr      [ 32 * i +:  32 * NUM_PORT_PER_CORE]),
      .s_axil_awready               (axil_cmac_awready     [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_wvalid                (axil_cmac_wvalid      [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_wdata                 (axil_cmac_wdata       [ 32 * i +:  32 * NUM_PORT_PER_CORE]),
      .s_axil_wready                (axil_cmac_wready      [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_bvalid                (axil_cmac_bvalid      [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_bresp                 (axil_cmac_bresp       [  2 * i +:   2 * NUM_PORT_PER_CORE]),
      .s_axil_bready                (axil_cmac_bready      [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_arvalid               (axil_cmac_arvalid     [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_araddr                (axil_cmac_araddr      [ 32 * i +:  32 * NUM_PORT_PER_CORE]),
      .s_axil_arready               (axil_cmac_arready     [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_rvalid                (axil_cmac_rvalid      [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axil_rdata                 (axil_cmac_rdata       [ 32 * i +:  32 * NUM_PORT_PER_CORE]),
      .s_axil_rresp                 (axil_cmac_rresp       [  2 * i +:   2 * NUM_PORT_PER_CORE]),
      .s_axil_rready                (axil_cmac_rready      [  1 * i +:   1 * NUM_PORT_PER_CORE]),

      .s_axis_xxvmac_tx_tvalid      (axis_cmac_tx_tvalid   [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axis_xxvmac_tx_tdata       (axis_cmac_tx_tdata    [512 * i +: 512 * NUM_PORT_PER_CORE]),
      .s_axis_xxvmac_tx_tkeep       (axis_cmac_tx_tkeep    [ 64 * i +:  64 * NUM_PORT_PER_CORE]),
      .s_axis_xxvmac_tx_tlast       (axis_cmac_tx_tlast    [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axis_xxvmac_tx_tuser_err   (axis_cmac_tx_tuser_err[  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .s_axis_xxvmac_tx_tready      (axis_cmac_tx_tready   [  1 * i +:   1 * NUM_PORT_PER_CORE]),

      .m_axis_xxvmac_rx_tvalid      (axis_cmac_rx_tvalid   [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .m_axis_xxvmac_rx_tdata       (axis_cmac_rx_tdata    [512 * i +: 512 * NUM_PORT_PER_CORE]),
      .m_axis_xxvmac_rx_tkeep       (axis_cmac_rx_tkeep    [ 64 * i +:  64 * NUM_PORT_PER_CORE]),
      .m_axis_xxvmac_rx_tlast       (axis_cmac_rx_tlast    [  1 * i +:   1 * NUM_PORT_PER_CORE]),
      .m_axis_xxvmac_rx_tuser_err   (axis_cmac_rx_tuser_err[  1 * i +:   1 * NUM_PORT_PER_CORE]),

      .gt_rxp                       (qsfp_rxp[i * 4 +: NUM_PORT_PER_CORE]),
      .gt_rxn                       (qsfp_rxn[i * 4 +: NUM_PORT_PER_CORE]),
      .gt_txp                       (qsfp_txp[i * 4 +: NUM_PORT_PER_CORE]),
      .gt_txn                       (qsfp_txn[i * 4 +: NUM_PORT_PER_CORE]),
      .gt_refclk_p                  (qsfp_refclk_p[i]),
      .gt_refclk_n                  (qsfp_refclk_n[i]),

      .xxvmac_clk                   (cmac_clk     [i +: NUM_PORT_PER_CORE]),
      .mod_rstn                     (cmac_rstn    [i +: NUM_PORT_PER_CORE]),
      .mod_rst_done                 (cmac_rst_done[i +: NUM_PORT_PER_CORE]),
      .axil_aclk                    (axil_aclk[0])
    );
  end: xxvmac_core
  endgenerate

  box_250mhz #(
    .MIN_PKT_LEN   (MIN_PKT_LEN),
    .MAX_PKT_LEN   (MAX_PKT_LEN),
    .USE_PHYS_FUNC (USE_PHYS_FUNC),
    .NUM_PHYS_FUNC (NUM_PHYS_FUNC),
    .NUM_QDMA      (NUM_QDMA),
    .NUM_CMAC_PORT (NUM_PORT)
  ) box_250mhz_inst (
    .s_axil_awvalid                   (axil_box0_awvalid),
    .s_axil_awaddr                    (axil_box0_awaddr),
    .s_axil_awready                   (axil_box0_awready),
    .s_axil_wvalid                    (axil_box0_wvalid),
    .s_axil_wdata                     (axil_box0_wdata),
    .s_axil_wready                    (axil_box0_wready),
    .s_axil_bvalid                    (axil_box0_bvalid),
    .s_axil_bresp                     (axil_box0_bresp),
    .s_axil_bready                    (axil_box0_bready),
    .s_axil_arvalid                   (axil_box0_arvalid),
    .s_axil_araddr                    (axil_box0_araddr),
    .s_axil_arready                   (axil_box0_arready),
    .s_axil_rvalid                    (axil_box0_rvalid),
    .s_axil_rdata                     (axil_box0_rdata),
    .s_axil_rresp                     (axil_box0_rresp),
    .s_axil_rready                    (axil_box0_rready),

    .s_axis_qdma_h2c_tvalid           (axis_qdma_h2c_tvalid),
    .s_axis_qdma_h2c_tdata            (axis_qdma_h2c_tdata),
    .s_axis_qdma_h2c_tkeep            (axis_qdma_h2c_tkeep),
    .s_axis_qdma_h2c_tlast            (axis_qdma_h2c_tlast),
    .s_axis_qdma_h2c_tuser_size       (axis_qdma_h2c_tuser_size),
    .s_axis_qdma_h2c_tuser_src        (axis_qdma_h2c_tuser_src),
    .s_axis_qdma_h2c_tuser_dst        (axis_qdma_h2c_tuser_dst),
    .s_axis_qdma_h2c_tready           (axis_qdma_h2c_tready),

    .m_axis_qdma_c2h_tvalid           (axis_qdma_c2h_tvalid),
    .m_axis_qdma_c2h_tdata            (axis_qdma_c2h_tdata),
    .m_axis_qdma_c2h_tkeep            (axis_qdma_c2h_tkeep),
    .m_axis_qdma_c2h_tlast            (axis_qdma_c2h_tlast),
    .m_axis_qdma_c2h_tuser_size       (axis_qdma_c2h_tuser_size),
    .m_axis_qdma_c2h_tuser_src        (axis_qdma_c2h_tuser_src),
    .m_axis_qdma_c2h_tuser_dst        (axis_qdma_c2h_tuser_dst),
    .m_axis_qdma_c2h_tready           (axis_qdma_c2h_tready),

    .m_axis_adap_tx_250mhz_tvalid     (axis_adap_tx_250mhz_tvalid),
    .m_axis_adap_tx_250mhz_tdata      (axis_adap_tx_250mhz_tdata),
    .m_axis_adap_tx_250mhz_tkeep      (axis_adap_tx_250mhz_tkeep),
    .m_axis_adap_tx_250mhz_tlast      (axis_adap_tx_250mhz_tlast),
    .m_axis_adap_tx_250mhz_tuser_size (axis_adap_tx_250mhz_tuser_size),
    .m_axis_adap_tx_250mhz_tuser_src  (axis_adap_tx_250mhz_tuser_src),
    .m_axis_adap_tx_250mhz_tuser_dst  (axis_adap_tx_250mhz_tuser_dst),
    .m_axis_adap_tx_250mhz_tready     (axis_adap_tx_250mhz_tready),

    .s_axis_adap_rx_250mhz_tvalid     (axis_adap_rx_250mhz_tvalid),
    .s_axis_adap_rx_250mhz_tdata      (axis_adap_rx_250mhz_tdata),
    .s_axis_adap_rx_250mhz_tkeep      (axis_adap_rx_250mhz_tkeep),
    .s_axis_adap_rx_250mhz_tlast      (axis_adap_rx_250mhz_tlast),
    .s_axis_adap_rx_250mhz_tuser_size (axis_adap_rx_250mhz_tuser_size),
    .s_axis_adap_rx_250mhz_tuser_src  (axis_adap_rx_250mhz_tuser_src),
    .s_axis_adap_rx_250mhz_tuser_dst  (axis_adap_rx_250mhz_tuser_dst),
    .s_axis_adap_rx_250mhz_tready     (axis_adap_rx_250mhz_tready),

    .mod_rstn                         (user_250mhz_rstn),
    .mod_rst_done                     (user_250mhz_rst_done),

    .box_rstn                         (box_250mhz_rstn),
    .box_rst_done                     (box_250mhz_rst_done),

    .axil_aclk                        (axil_aclk[0]),

  `ifdef __au55n__
    .ref_clk_100mhz                   (ref_clk_100mhz),
  `elsif __au55c__
    .ref_clk_100mhz                   (ref_clk_100mhz),
  `elsif __au50__
    .ref_clk_100mhz                   (ref_clk_100mhz),
  `elsif __au280__
    .ref_clk_100mhz                   (ref_clk_100mhz),
  `endif
    .axis_aclk                        (axis_aclk[0])
  );

  box_322mhz #(
    .MIN_PKT_LEN   (MIN_PKT_LEN),
    .MAX_PKT_LEN   (MAX_PKT_LEN),
    .NUM_CMAC_PORT (NUM_PORT)
  ) box_322mhz_inst (
    .s_axil_awvalid                  (axil_box1_awvalid),
    .s_axil_awaddr                   (axil_box1_awaddr),
    .s_axil_awready                  (axil_box1_awready),
    .s_axil_wvalid                   (axil_box1_wvalid),
    .s_axil_wdata                    (axil_box1_wdata),
    .s_axil_wready                   (axil_box1_wready),
    .s_axil_bvalid                   (axil_box1_bvalid),
    .s_axil_bresp                    (axil_box1_bresp),
    .s_axil_bready                   (axil_box1_bready),
    .s_axil_arvalid                  (axil_box1_arvalid),
    .s_axil_araddr                   (axil_box1_araddr),
    .s_axil_arready                  (axil_box1_arready),
    .s_axil_rvalid                   (axil_box1_rvalid),
    .s_axil_rdata                    (axil_box1_rdata),
    .s_axil_rresp                    (axil_box1_rresp),
    .s_axil_rready                   (axil_box1_rready),

    .s_axis_adap_tx_322mhz_tvalid    (axis_adap_tx_322mhz_tvalid),
    .s_axis_adap_tx_322mhz_tdata     (axis_adap_tx_322mhz_tdata),
    .s_axis_adap_tx_322mhz_tkeep     (axis_adap_tx_322mhz_tkeep),
    .s_axis_adap_tx_322mhz_tlast     (axis_adap_tx_322mhz_tlast),
    .s_axis_adap_tx_322mhz_tuser_err (axis_adap_tx_322mhz_tuser_err),
    .s_axis_adap_tx_322mhz_tready    (axis_adap_tx_322mhz_tready),

    .m_axis_adap_rx_322mhz_tvalid    (axis_adap_rx_322mhz_tvalid),
    .m_axis_adap_rx_322mhz_tdata     (axis_adap_rx_322mhz_tdata),
    .m_axis_adap_rx_322mhz_tkeep     (axis_adap_rx_322mhz_tkeep),
    .m_axis_adap_rx_322mhz_tlast     (axis_adap_rx_322mhz_tlast),
    .m_axis_adap_rx_322mhz_tuser_err (axis_adap_rx_322mhz_tuser_err),

    .m_axis_cmac_tx_tvalid           (axis_cmac_tx_tvalid),
    .m_axis_cmac_tx_tdata            (axis_cmac_tx_tdata),
    .m_axis_cmac_tx_tkeep            (axis_cmac_tx_tkeep),
    .m_axis_cmac_tx_tlast            (axis_cmac_tx_tlast),
    .m_axis_cmac_tx_tuser_err        (axis_cmac_tx_tuser_err),
    .m_axis_cmac_tx_tready           (axis_cmac_tx_tready),

    .s_axis_cmac_rx_tvalid           (axis_cmac_rx_tvalid),
    .s_axis_cmac_rx_tdata            (axis_cmac_rx_tdata),
    .s_axis_cmac_rx_tkeep            (axis_cmac_rx_tkeep),
    .s_axis_cmac_rx_tlast            (axis_cmac_rx_tlast),
    .s_axis_cmac_rx_tuser_err        (axis_cmac_rx_tuser_err),

    .mod_rstn                        (user_322mhz_rstn),
    .mod_rst_done                    (user_322mhz_rst_done),

    .box_rstn                        (box_322mhz_rstn),
    .box_rst_done                    (box_322mhz_rst_done),

    .axil_aclk                       (axil_aclk[0]),
    .cmac_clk                        (cmac_clk)
  );

endmodule: open_nic_shell
