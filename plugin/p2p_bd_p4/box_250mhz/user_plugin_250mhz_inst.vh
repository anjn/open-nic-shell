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

initial begin
  if (USE_PHYS_FUNC != 1) begin
    $fatal("No implementation for USE_PHYS_FUNC = %d", USE_PHYS_FUNC);
  end
  if (NUM_PHYS_FUNC != 2) begin
    $fatal("No implementation for NUM_PHYS_FUNC = %d", NUM_PHYS_FUNC);
  end
  if (NUM_CMAC_PORT != 1) begin
    $fatal("No implementation for NUM_CMAC_PORT = %d", NUM_CMAC_PORT);
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

wire [63:0] axis_qdma_c2h_0_tuser;
wire [63:0] axis_qdma_c2h_1_tuser;
wire [63:0] axis_adap_tx_250mhz_tuser;

assign m_axis_qdma_c2h_tuser_dst[`getvec(16, 0)] = 16'h0001;
assign m_axis_qdma_c2h_tuser_src[`getvec(16, 0)] = axis_qdma_c2h_0_tuser[15:0];
assign m_axis_qdma_c2h_tuser_size[`getvec(16, 0)] = axis_qdma_c2h_0_tuser[31:16];

assign m_axis_qdma_c2h_tuser_dst[`getvec(16, 1)] = 16'h0002;
assign m_axis_qdma_c2h_tuser_src[`getvec(16, 1)] = axis_qdma_c2h_1_tuser[15:0];
assign m_axis_qdma_c2h_tuser_size[`getvec(16, 1)] = axis_qdma_c2h_1_tuser[31:16];

assign m_axis_adap_tx_250mhz_tuser_dst = 16'h0040;
assign m_axis_adap_tx_250mhz_tuser_src = axis_adap_tx_250mhz_tuser[15:0];
assign m_axis_adap_tx_250mhz_tuser_size = axis_adap_tx_250mhz_tuser[31:16];

box_250mhz_bd_wrapper box_250mhz_bd_inst (
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

    // Inputs
    .s_axis_qdma_h2c_0_tdata(s_axis_qdma_h2c_tdata[`getvec(512, 0)]),
    .s_axis_qdma_h2c_0_tkeep(s_axis_qdma_h2c_tkeep[`getvec(64, 0)]),
    .s_axis_qdma_h2c_0_tlast(s_axis_qdma_h2c_tlast[0]),
    .s_axis_qdma_h2c_0_tready(s_axis_qdma_h2c_tready[0]),
    .s_axis_qdma_h2c_0_tuser({16'd0, 16'd2, 16'd1, s_axis_qdma_h2c_tuser_src[`getvec(16, 0)]}), // Port1 -> Port2
    .s_axis_qdma_h2c_0_tvalid(s_axis_qdma_h2c_tvalid[0]),

    .s_axis_qdma_h2c_1_tdata(s_axis_qdma_h2c_tdata[`getvec(512, 1)]),
    .s_axis_qdma_h2c_1_tkeep(s_axis_qdma_h2c_tkeep[`getvec(64, 1)]),
    .s_axis_qdma_h2c_1_tlast(s_axis_qdma_h2c_tlast[1]),
    .s_axis_qdma_h2c_1_tready(s_axis_qdma_h2c_tready[1]),
    .s_axis_qdma_h2c_1_tuser({16'd0, 16'd255, 16'd255, s_axis_qdma_h2c_tuser_src[`getvec(16, 1)]}),
    .s_axis_qdma_h2c_1_tvalid(s_axis_qdma_h2c_tvalid[1]),

    .s_axis_adap_rx_250mhz_tdata,
    .s_axis_adap_rx_250mhz_tkeep,
    .s_axis_adap_rx_250mhz_tlast,
    .s_axis_adap_rx_250mhz_tready,
    .s_axis_adap_rx_250mhz_tuser({16'd0, 16'd1, 16'd2, s_axis_adap_rx_250mhz_tuser_src}),
    .s_axis_adap_rx_250mhz_tvalid,

    // Outputs
    .m_axis_qdma_c2h_0_tdata(m_axis_qdma_c2h_tdata[`getvec(512, 0)]),
    .m_axis_qdma_c2h_0_tkeep(m_axis_qdma_c2h_tkeep[`getvec(64, 0)]),
    .m_axis_qdma_c2h_0_tlast(m_axis_qdma_c2h_tlast[0]),
    .m_axis_qdma_c2h_0_tready(m_axis_qdma_c2h_tready[0]),
    .m_axis_qdma_c2h_0_tuser(axis_qdma_c2h_0_tuser),
    .m_axis_qdma_c2h_0_tvalid(m_axis_qdma_c2h_tvalid[0]),

    .m_axis_qdma_c2h_1_tdata(m_axis_qdma_c2h_tdata[`getvec(512, 1)]),
    .m_axis_qdma_c2h_1_tkeep(m_axis_qdma_c2h_tkeep[`getvec(64, 1)]),
    .m_axis_qdma_c2h_1_tlast(m_axis_qdma_c2h_tlast[1]),
    .m_axis_qdma_c2h_1_tready(m_axis_qdma_c2h_tready[1]),
    .m_axis_qdma_c2h_1_tuser(axis_qdma_c2h_1_tuser),
    .m_axis_qdma_c2h_1_tvalid(m_axis_qdma_c2h_tvalid[1]),

    .m_axis_adap_tx_250mhz_tdata,
    .m_axis_adap_tx_250mhz_tkeep,
    .m_axis_adap_tx_250mhz_tlast,
    .m_axis_adap_tx_250mhz_tready,
    .m_axis_adap_tx_250mhz_tuser(axis_adap_tx_250mhz_tuser),
    .m_axis_adap_tx_250mhz_tvalid
);

