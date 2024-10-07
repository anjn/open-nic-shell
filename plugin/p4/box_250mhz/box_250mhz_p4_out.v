`timescale 1ns/1ps

module box_250mhz_p4_out #(
    parameter TDATA_W         = 1024,
    parameter MIN_PKT_LEN     = 64,
    parameter MAX_PKT_LEN     = 9600,
    parameter PKT_CAP         = 1.5,
    parameter USERMETA_W      = 1024+64
) (
    input                  s_axis_tvalid,
    input    [TDATA_W-1:0] s_axis_tdata,
    input  [TDATA_W/8-1:0] s_axis_tkeep,
    input                  s_axis_tlast,
    output                 s_axis_tready,

    output                 m_axis_tvalid,
    output   [TDATA_W-1:0] m_axis_tdata,
    output [TDATA_W/8-1:0] m_axis_tkeep,
    output                 m_axis_tlast,
    output          [15:0] m_axis_tdest,
    output         [127:0] m_axis_tuser,
    input                  m_axis_tready,

    input [USERMETA_W-1:0] user_metadata_out,
    input                  user_metadata_out_valid,

    input                  aclk,
    input                  aresetn
);

    wire [USERMETA_W-1:0] user_metadata;

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
        .s_axis_tvalid     (s_axis_tvalid       ),
        .s_axis_tdata      (s_axis_tdata        ),
        .s_axis_tkeep      (s_axis_tkeep        ),
        .s_axis_tlast      (s_axis_tlast        ),
        .s_axis_tid        (1'b0                ),
        .s_axis_tdest      (user_metadata[47:32]),
        .s_axis_tuser      (user_metadata[15:0] ),
        .s_axis_tready     (s_axis_tready       ),

        .drop              (1'b0                ),
        .drop_busy         (                    ),

        .m_axis_tvalid     (m_axis_tvalid       ),
        .m_axis_tdata      (m_axis_tdata        ),
        .m_axis_tkeep      (m_axis_tkeep        ),
        .m_axis_tlast      (m_axis_tlast        ),
        .m_axis_tid        (                    ),
        .m_axis_tdest      (m_axis_tdest        ),
        .m_axis_tuser      (axis_tuser          ),
        .m_axis_tuser_size (axis_tuser_size     ),
        .m_axis_tready     (m_axis_tready       ),

        .s_aclk            (aclk                ),
        .s_aresetn         (aresetn             ),
        .m_aclk            (aclk                )
    );

    reg [USERMETA_W-1:0] user_metadata_r;

    always @(posedge aclk)
        if (user_metadata_out_valid)
            user_metadata_r <= user_metadata_out;

    assign user_metadata = user_metadata_out_valid ? user_metadata_out : user_metadata_r;

endmodule

