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
initial begin
  if (USE_PHYS_FUNC == 0) begin
    $fatal("No implementation for USE_PHYS_FUNC = %d", 0);
  end
  if (NUM_PHYS_FUNC != 1 || NUM_PHYS_FUNC != NUM_CMAC_PORT) begin
    $fatal("No implementation for NUM_PHYS_FUNC (%d) != NUM_CMAC_PORT (%d)",
      NUM_PHYS_FUNC, NUM_CMAC_PORT);
  end
end

localparam C_NUM_USER_BLOCK = 1;

// Make sure for all the unused reset pair, corresponding bits in
// "mod_rst_done" are tied to 0
assign mod_rst_done[15:C_NUM_USER_BLOCK] = {(16-C_NUM_USER_BLOCK){1'b1}};

wire axil_aresetn;
wire axis_aresetn;

// Reset is clocked by the 125MHz AXI-Lite clock
generic_reset #(
  .NUM_INPUT_CLK  (2),
  .RESET_DURATION (100)
) user_reset_inst (
  .mod_rstn     (mod_rstn[0]),
  .mod_rst_done (mod_rst_done[0]),
  .clk          ({axis_aclk, axil_aclk}),
  .rstn         ({axis_aresetn, axil_aresetn})
);

box_250mhz_bd_wrapper (
    .axil_aclk,
    .axil_aresetn,
    .axis_aclk,
    .axis_aresetn,

    .s_axil_araddr(s_axil_araddr[8:0]),
    .s_axil_arready,
    .s_axil_arvalid,
    .s_axil_awaddr(s_axil_awaddr[8:0]),
    .s_axil_awready,
    .s_axil_awvalid,
    .s_axil_bready,
    .s_axil_bresp,
    .s_axil_bvalid,
    .s_axil_rdata,
    .s_axil_rready,
    .s_axil_rresp,
    .s_axil_rvalid,
    .s_axil_wdata,
    .s_axil_wready,
    .s_axil_wstrb(4'b1111),
    .s_axil_wvalid,

    .s_axis_qdma_h2c_tdata,
    .s_axis_qdma_h2c_tkeep,
    .s_axis_qdma_h2c_tlast,
    .s_axis_qdma_h2c_tready,
    .s_axis_qdma_h2c_tuser({s_axis_qdma_h2c_tuser_size, s_axis_qdma_h2c_tuser_src, s_axis_qdma_h2c_tuser_dst}),
    .s_axis_qdma_h2c_tvalid,

    .m_axis_qdma_c2h_tdata,
    .m_axis_qdma_c2h_tkeep,
    .m_axis_qdma_c2h_tlast,
    .m_axis_qdma_c2h_tready,
    .m_axis_qdma_c2h_tuser({m_axis_qdma_c2h_tuser_size, m_axis_qdma_c2h_tuser_src, m_axis_qdma_c2h_tuser_dst}),
    .m_axis_qdma_c2h_tvalid,

    .m_axis_adap_tx_250mhz_tdata,
    .m_axis_adap_tx_250mhz_tkeep,
    .m_axis_adap_tx_250mhz_tlast,
    .m_axis_adap_tx_250mhz_tready,
    .m_axis_adap_tx_250mhz_tuser({m_axis_adap_tx_250mhz_tuser_size, m_axis_adap_tx_250mhz_tuser_src, m_axis_adap_tx_250mhz_tuser_dst}),
    .m_axis_adap_tx_250mhz_tvalid,

    .s_axis_adap_rx_250mhz_tdata,
    .s_axis_adap_rx_250mhz_tkeep,
    .s_axis_adap_rx_250mhz_tlast,
    .s_axis_adap_rx_250mhz_tready,
    .s_axis_adap_rx_250mhz_tuser({s_axis_adap_rx_250mhz_tuser_size, s_axis_adap_rx_250mhz_tuser_src, s_axis_adap_rx_250mhz_tuser_dst}),
    .s_axis_adap_rx_250mhz_tvalid
);

