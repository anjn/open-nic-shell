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
// This module implements an AXI-Stream buffer that supports dropping incomplete
// packets.  Packets can be dropped before and in the cycle that `tlast` is
// asserted.  Dropped packets do not show on the master interface.  To drop a
// packet, pull up `s_drop` for one cycle.
`timescale 1ns/1ps
module box_250mhz_buffer #(
  parameter TDATA_W         = 1024,
  parameter MIN_PKT_LEN     = 64,
  parameter MAX_PKT_LEN     = 9600,
  parameter PKT_CAP         = 1.5
) (
  input                  s_axis_tvalid,
  input    [TDATA_W-1:0] s_axis_tdata,
  input  [TDATA_W/8-1:0] s_axis_tkeep,
  input                  s_axis_tlast,
  input           [63:0] s_axis_tuser,
  output                 s_axis_tready,

  output                 m_axis_tvalid,
  output   [TDATA_W-1:0] m_axis_tdata,
  output [TDATA_W/8-1:0] m_axis_tkeep,
  output                 m_axis_tlast,
  output          [15:0] m_axis_tdest,
  output         [127:0] m_axis_tuser,
  input                  m_axis_tready,

  input                  aclk,
  input                  aresetn
);

    wire [15:0] axis_tuser;
    wire [15:0] axis_tuser_size;

    assign m_axis_tuser = {32'd0, axis_tuser_size, axis_tuser, 32'd0, axis_tuser_size, axis_tuser};

    axi_stream_packet_buffer #(
        .CLOCKING_MODE   ("common_clock"),
        .CDC_SYNC_STAGES (2             ),
        .TDATA_W         (TDATA_W       ),
        .TID_W           (1             ),
        .TDEST_W         (16            ),
        .TUSER_W         (16            ),
        .MIN_PKT_LEN     (MIN_PKT_LEN   ),
        .MAX_PKT_LEN     (MAX_PKT_LEN   ),
        .PKT_CAP         (PKT_CAP       )
    ) inst (
        .s_axis_tvalid     (s_axis_tvalid      ),
        .s_axis_tdata      (s_axis_tdata       ),
        .s_axis_tkeep      (s_axis_tkeep       ),
        .s_axis_tlast      (s_axis_tlast       ),
        .s_axis_tid        (1'b0               ),
        .s_axis_tdest      (s_axis_tuser[47:32]),
        .s_axis_tuser      (s_axis_tuser[15:0] ),
        .s_axis_tready     (s_axis_tready      ),

        .drop              (1'b0               ),
        .drop_busy         (                   ),

        .m_axis_tvalid     (m_axis_tvalid      ),
        .m_axis_tdata      (m_axis_tdata       ),
        .m_axis_tkeep      (m_axis_tkeep       ),
        .m_axis_tlast      (m_axis_tlast       ),
        .m_axis_tid        (                   ),
        .m_axis_tdest      (m_axis_tdest       ),
        .m_axis_tuser      (axis_tuser         ),
        .m_axis_tuser_size (axis_tuser_size    ),
        .m_axis_tready     (m_axis_tready      ),

        .s_aclk            (aclk               ),
        .s_aresetn         (aresetn            ),
        .m_aclk            (aclk               )
    );

endmodule

