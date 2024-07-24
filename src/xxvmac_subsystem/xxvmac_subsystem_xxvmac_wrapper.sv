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
`timescale 1ns/1ps
module xxvmac_subsystem_xxvmac_wrapper #(
  parameter int XXVMAC_ID = 0
) (
  input    [0:0] gt_rxp,
  input    [0:0] gt_rxn,
  output   [0:0] gt_txp,
  output   [0:0] gt_txn,

  input          s_axil_awvalid,
  input   [31:0] s_axil_awaddr,
  output         s_axil_awready,
  input          s_axil_wvalid,
  input   [31:0] s_axil_wdata,
  output         s_axil_wready,
  output         s_axil_bvalid,
  output   [1:0] s_axil_bresp,
  input          s_axil_bready,
  input          s_axil_arvalid,
  input   [31:0] s_axil_araddr,
  output         s_axil_arready,
  output         s_axil_rvalid,
  output  [31:0] s_axil_rdata,
  output   [1:0] s_axil_rresp,
  input          s_axil_rready,

  output         m_axis_rx_tvalid,
  output [511:0] m_axis_rx_tdata,
  output  [63:0] m_axis_rx_tkeep,
  output         m_axis_rx_tlast,
  output         m_axis_rx_tuser_err,

  input          s_axis_tx_tvalid,
  input  [511:0] s_axis_tx_tdata,
  input   [63:0] s_axis_tx_tkeep,
  input          s_axis_tx_tlast,
  input          s_axis_tx_tuser_err,
  output         s_axis_tx_tready,

  input          gt_refclk_p,
  input          gt_refclk_n,
  output         xxvmac_clk,
  input          xxvmac_sys_reset,

  input          axil_aclk
);

  initial begin
    if (XXVMAC_ID != 0) begin
      $fatal("[%m] Number of xxvmac should be within [1, 1]");
    end
  end

  wire tx_clk_out_0;
  assign xxvmac_clk = tx_clk_out_0;

  wire         axis_rx_tvalid;
  wire  [63:0] axis_rx_tdata;
  wire   [7:0] axis_rx_tkeep;
  wire         axis_rx_tlast;
  wire         axis_rx_tuser_err;

  wire         axis_tx_tvalid;
  wire  [63:0] axis_tx_tdata;
  wire   [7:0] axis_tx_tkeep;
  wire         axis_tx_tlast;
  wire         axis_tx_tuser_err;
  wire         axis_tx_tready;

  // RX FIFO
  wire  [63:0] m_axis_rx_tuser;

  assign m_axis_rx_tuser_err = |{
    m_axis_rx_tuser[ 0], m_axis_rx_tuser[ 8], m_axis_rx_tuser[16], m_axis_rx_tuser[24],
    m_axis_rx_tuser[32], m_axis_rx_tuser[40], m_axis_rx_tuser[48], m_axis_rx_tuser[56]
  };

  xxvmac_subsystem_axis_dwidth_converter_rx dwidth_conv_rx_inst (
    .aclk          (aclk),
    .aresetn       (aresetn),

    .s_axis_tvalid (axis_rx_tvalid),
    .s_axis_tready (),
    .s_axis_tdata  (axis_rx_tdata),
    .s_axis_tkeep  (axis_rx_tkeep),
    .s_axis_tlast  (axis_rx_tlast),
    .s_axis_tuser  ({ 7'b0, axis_rx_tuser_err }),

    .m_axis_tvalid (m_axis_rx_tvalid),
    .m_axis_tready (1'b1),
    .m_axis_tdata  (m_axis_rx_tdata),
    .m_axis_tkeep  (m_axis_rx_tkeep),
    .m_axis_tlast  (m_axis_rx_tlast),
    .m_axis_tuser  (m_axis_rx_tuser)
  );

  // TX FIFO
  wire  [63:0] axis_tx_tuser;
  assign axis_tx_tuser_err = axis_tx_tuser[0];

  xxvmac_subsystem_axis_dwidth_converter_tx dwidth_conv_tx_inst (
    .aclk          (aclk),
    .aresetn       (aresetn),

    .s_axis_tvalid (s_axis_tx_tvalid),
    .s_axis_tready (s_axis_tx_tready),
    .s_axis_tdata  (s_axis_tx_tdata),
    .s_axis_tkeep  (s_axis_tx_tkeep),
    .s_axis_tlast  (s_axis_tx_tlast),
    .s_axis_tuser  ({ 8 { 7'b0, s_axis_tx_tuser_err } }),

    .m_axis_tvalid (axis_tx_tvalid),
    .m_axis_tready (axis_tx_tready),
    .m_axis_tdata  (axis_tx_tdata),
    .m_axis_tkeep  (axis_tx_tkeep),
    .m_axis_tlast  (axis_tx_tlast),
    .m_axis_tuser  (axis_tx_tuser)
  );

  generate if (XXVMAC_ID == 0) begin
    xxv_ethernet_0 xxvmac_inst (
      .gt_rxp_in                        (gt_rxp),
      .gt_rxn_in                        (gt_rxn),
      .gt_txp_out                       (gt_txp),
      .gt_txn_out                       (gt_txn),

      .gt_refclk_p                      (gt_refclk_p),
      .gt_refclk_n                      (gt_refclk_n),

      .gt_refclk_out                    (),
      .rxrecclkout_0                    (),
      .rx_clk_out_0                     (),
      .tx_clk_out_0                     (tx_clk_out_0),
      .rx_core_clk_0                    (tx_clk_out_0),
      .dclk                             (axil_aclk),

      .sys_reset                        (xxvmac_sys_reset),
      .rx_reset_0                       (1'b0),
      .tx_reset_0                       (1'b0),
      .gtwiz_reset_rx_datapath_0        (1'b0),
      .gtwiz_reset_tx_datapath_0        (1'b0),
      .user_rx_reset_0                  (),
      .user_tx_reset_0                  (),
      .qpllreset_in_0                   (1'b0),

      .s_axi_aclk_0                     (axil_aclk),
      .s_axi_aresetn_0                  (xxvmac_sys_reset),

      .s_axi_awaddr_0                   (s_axil_awaddr),
      .s_axi_awvalid_0                  (s_axil_awvalid),
      .s_axi_awready_0                  (s_axil_awready),
      .s_axi_wdata_0                    (s_axil_wdata),
      .s_axi_wstrb_0                    (4'hF),
      .s_axi_wvalid_0                   (s_axil_wvalid),
      .s_axi_wready_0                   (s_axil_wready),
      .s_axi_bresp_0                    (s_axil_bresp),
      .s_axi_bvalid_0                   (s_axil_bvalid),
      .s_axi_bready_0                   (s_axil_bready),
      .s_axi_araddr_0                   (s_axil_araddr),
      .s_axi_arvalid_0                  (s_axil_arvalid),
      .s_axi_arready_0                  (s_axil_arready),
      .s_axi_rdata_0                    (s_axil_rdata),
      .s_axi_rresp_0                    (s_axil_rresp),
      .s_axi_rvalid_0                   (s_axil_rvalid),
      .s_axi_rready_0                   (s_axil_rready),

      .rx_axis_tvalid_0                 (axis_rx_tvalid),
      .rx_axis_tdata_0                  (axis_rx_tdata),
      .rx_axis_tlast_0                  (axis_rx_tlast),
      .rx_axis_tkeep_0                  (axis_rx_tkeep),
      .rx_axis_tuser_0                  (axis_rx_tuser_err),
      .rx_preambleout_0                 (),

      .tx_axis_tready_0                 (axis_tx_tready),
      .tx_axis_tvalid_0                 (axis_tx_tvalid),
      .tx_axis_tdata_0                  (axis_tx_tdata),
      .tx_axis_tlast_0                  (axis_tx_tlast),
      .tx_axis_tkeep_0                  (axis_tx_tkeep),
      .tx_axis_tuser_0                  (axis_tx_tuser_err),
      .tx_preamblein_0                  (56'b0),

      .tx_unfout_0                      (),
      .txoutclksel_in_0                 (3'b101),
      .rxoutclksel_in_0                 (3'b101),
      .gtpowergood_out_0                (),
      .pm_tick_0                        (1'b0),
      .ctl_tx_send_rfi_0                (1'b0),
      .ctl_tx_send_lfi_0                (1'b0),
      .ctl_tx_send_idle_0               (1'b0),
      .user_reg0_0                      (),

      .stat_rx_framing_err_0            (),
      .stat_rx_framing_err_valid_0      (),
      .stat_rx_local_fault_0            (),
      .stat_rx_block_lock_0             (),
      .stat_rx_valid_ctrl_code_0        (),
      .stat_rx_status_0                 (),
      .stat_rx_remote_fault_0           (),
      .stat_rx_bad_fcs_0                (),
      .stat_rx_stomped_fcs_0            (),
      .stat_rx_truncated_0              (),
      .stat_rx_internal_local_fault_0   (),
      .stat_rx_received_local_fault_0   (),
      .stat_rx_hi_ber_0                 (),
      .stat_rx_got_signal_os_0          (),
      .stat_rx_test_pattern_mismatch_0  (),
      .stat_rx_total_bytes_0            (),
      .stat_rx_total_packets_0          (),
      .stat_rx_total_good_bytes_0       (),
      .stat_rx_total_good_packets_0     (),
      .stat_rx_packet_bad_fcs_0         (),
      .stat_rx_packet_64_bytes_0        (),
      .stat_rx_packet_65_127_bytes_0    (),
      .stat_rx_packet_128_255_bytes_0   (),
      .stat_rx_packet_256_511_bytes_0   (),
      .stat_rx_packet_512_1023_bytes_0  (),
      .stat_rx_packet_1024_1518_bytes_0 (),
      .stat_rx_packet_1519_1522_bytes_0 (),
      .stat_rx_packet_1523_1548_bytes_0 (),
      .stat_rx_packet_1549_2047_bytes_0 (),
      .stat_rx_packet_2048_4095_bytes_0 (),
      .stat_rx_packet_4096_8191_bytes_0 (),
      .stat_rx_packet_8192_9215_bytes_0 (),
      .stat_rx_packet_small_0           (),
      .stat_rx_packet_large_0           (),
      .stat_rx_unicast_0                (),
      .stat_rx_multicast_0              (),
      .stat_rx_broadcast_0              (),
      .stat_rx_oversize_0               (),
      .stat_rx_toolong_0                (),
      .stat_rx_undersize_0              (),
      .stat_rx_fragment_0               (),
      .stat_rx_vlan_0                   (),
      .stat_rx_inrangeerr_0             (),
      .stat_rx_jabber_0                 (),
      .stat_rx_bad_code_0               (),
      .stat_rx_bad_sfd_0                (),
      .stat_rx_bad_preamble_0           (),
      .stat_tx_local_fault_0            (),
      .stat_tx_total_bytes_0            (),
      .stat_tx_total_packets_0          (),
      .stat_tx_total_good_bytes_0       (),
      .stat_tx_total_good_packets_0     (),
      .stat_tx_bad_fcs_0                (),
      .stat_tx_packet_64_bytes_0        (),
      .stat_tx_packet_65_127_bytes_0    (),
      .stat_tx_packet_128_255_bytes_0   (),
      .stat_tx_packet_256_511_bytes_0   (),
      .stat_tx_packet_512_1023_bytes_0  (),
      .stat_tx_packet_1024_1518_bytes_0 (),
      .stat_tx_packet_1519_1522_bytes_0 (),
      .stat_tx_packet_1523_1548_bytes_0 (),
      .stat_tx_packet_1549_2047_bytes_0 (),
      .stat_tx_packet_2048_4095_bytes_0 (),
      .stat_tx_packet_4096_8191_bytes_0 (),
      .stat_tx_packet_8192_9215_bytes_0 (),
      .stat_tx_packet_small_0           (),
      .stat_tx_packet_large_0           (),
      .stat_tx_unicast_0                (),
      .stat_tx_multicast_0              (),
      .stat_tx_broadcast_0              (),
      .stat_tx_vlan_0                   (),
      .stat_tx_frame_error_0            ()
    );
  end
  else begin
  end
  endgenerate

endmodule: xxvmac_subsystem_xxvmac_wrapper

