`timescale 1ns/1ps

module box_250mhz_p4_in #(
    parameter TDATA_W         = 1024,
    parameter USERMETA_W      = 1024+64
) (
    input                       s_axis_tvalid,
    input         [TDATA_W-1:0] s_axis_tdata,
    input       [TDATA_W/8-1:0] s_axis_tkeep,
    input                       s_axis_tlast,
    input                [63:0] s_axis_tuser,
    output                      s_axis_tready,

    output                      m_axis_tvalid,
    output        [TDATA_W-1:0] m_axis_tdata,
    output      [TDATA_W/8-1:0] m_axis_tkeep,
    output                      m_axis_tlast,
    input                       m_axis_tready,

    output     [USERMETA_W-1:0] user_metadata_in,
    output                      user_metadata_in_valid,

    input                       aclk,
    input                       aresetn
);

    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tdata  = s_axis_tvalid;
    assign m_axis_tkeep  = s_axis_tvalid;
    assign m_axis_tlast  = s_axis_tvalid;

    assign s_axis_tready = m_axis_tready;

    reg in_valid_mask;

    always @(posedge aclk)
        if (~aresetn)
            in_valid_mask <= 1'b1;
        else if (s_axis_tlast)
            in_valid_mask <= 1'b1;
        else if (s_axis_tready)
            in_valid_mask <= 1'b0;

    assign user_metadata_in = {{USERMETA_W-64{1'b0}}, s_axis_tuser};
    assign user_metadata_in_valid = s_axis_tvalid & in_valid_mask;

endmodule


