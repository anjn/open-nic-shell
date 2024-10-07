`timescale 1ns/1ps

module box_250mhz_p4_dummy #(
    parameter TDATA_W         = 1024,
    parameter USERMETA_W      = 1024+64
) (
    input                       s_axis_tvalid,
    input         [TDATA_W-1:0] s_axis_tdata,
    input       [TDATA_W/8-1:0] s_axis_tkeep,
    input                       s_axis_tlast,
    output                      s_axis_tready,

    output                      m_axis_tvalid,
    output        [TDATA_W-1:0] m_axis_tdata,
    output      [TDATA_W/8-1:0] m_axis_tkeep,
    output                      m_axis_tlast,
    input                       m_axis_tready,

    input      [USERMETA_W-1:0] user_metadata_in,
    input                       user_metadata_in_valid,

    output     [USERMETA_W-1:0] user_metadata_out,
    output                      user_metadata_out_valid,

    input                       aclk,
    input                       aresetn
);

    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tdata  = s_axis_tvalid;
    assign m_axis_tkeep  = s_axis_tvalid;
    assign m_axis_tlast  = s_axis_tvalid;

    assign s_axis_tready = m_axis_tready;

    assign user_metadata_out = user_metadata_in;
    assign user_metadata_out_valid = user_metadata_in_valid;

endmodule



