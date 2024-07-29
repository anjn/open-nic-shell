`timescale 1ns/1ps

import axi_vip_pkg::*;
import axi4stream_vip_pkg::*;

import axi_lite_vip_0_pkg::*;
import axis_h2c_vip_0_pkg::*;

module qdma_sim (
    input  logic         sys_clk,
    input  logic         sys_clk_gt,
    input  logic         sys_rst_n,
    output logic         user_lnk_up,
    output logic [ 15:0] pci_exp_txp,
    output logic [ 15:0] pci_exp_txn,
    input  logic [ 15:0] pci_exp_rxp,
    input  logic [ 15:0] pci_exp_rxn,
    output logic         axi_aclk,
    output logic         axi_aresetn,
    input  logic         usr_irq_in_vld,
    input  logic [ 10:0] usr_irq_in_vec,
    input  logic [  7:0] usr_irq_in_fnc,
    output logic         usr_irq_out_ack,
    output logic         usr_irq_out_fail,
    output logic [255:0] h2c_byp_out_dsc,
    output logic         h2c_byp_out_st_mm,
    output logic [  1:0] h2c_byp_out_dsc_sz,
    output logic [ 10:0] h2c_byp_out_qid,
    output logic         h2c_byp_out_error,
    output logic [  7:0] h2c_byp_out_func,
    output logic [ 15:0] h2c_byp_out_cidx,
    output logic [  2:0] h2c_byp_out_port_id,
    output logic         h2c_byp_out_vld,
    input  logic         h2c_byp_out_rdy,
    output logic [  3:0] h2c_byp_out_fmt,
    output logic [255:0] c2h_byp_out_dsc,
    output logic         c2h_byp_out_st_mm,
    output logic [ 10:0] c2h_byp_out_qid,
    output logic [  1:0] c2h_byp_out_dsc_sz,
    output logic         c2h_byp_out_error,
    output logic [  7:0] c2h_byp_out_func,
    output logic [ 15:0] c2h_byp_out_cidx,
    output logic [  2:0] c2h_byp_out_port_id,
    output logic         c2h_byp_out_vld,
    input  logic         c2h_byp_out_rdy,
    output logic [  3:0] c2h_byp_out_fmt,
    output logic [  6:0] c2h_byp_out_pfch_tag,
    input  logic [ 63:0] c2h_byp_in_st_csh_addr,
    input  logic [  2:0] c2h_byp_in_st_csh_port_id,
    input  logic [ 10:0] c2h_byp_in_st_csh_qid,
    input  logic         c2h_byp_in_st_csh_error,
    input  logic [  7:0] c2h_byp_in_st_csh_func,
    input  logic         c2h_byp_in_st_csh_vld,
    output logic         c2h_byp_in_st_csh_rdy,
    input  logic [  6:0] c2h_byp_in_st_csh_pfch_tag,
    input  logic [ 63:0] h2c_byp_in_st_addr,
    input  logic [ 15:0] h2c_byp_in_st_len,
    input  logic         h2c_byp_in_st_eop,
    input  logic         h2c_byp_in_st_sop,
    input  logic         h2c_byp_in_st_mrkr_req,
    input  logic [  2:0] h2c_byp_in_st_port_id,
    input  logic         h2c_byp_in_st_sdi,
    input  logic [ 10:0] h2c_byp_in_st_qid,
    input  logic         h2c_byp_in_st_error,
    input  logic [  7:0] h2c_byp_in_st_func,
    input  logic [ 15:0] h2c_byp_in_st_cidx,
    input  logic         h2c_byp_in_st_no_dma,
    input  logic         h2c_byp_in_st_vld,
    output logic         h2c_byp_in_st_rdy,
    output logic         tm_dsc_sts_vld,
    output logic [  2:0] tm_dsc_sts_port_id,
    output logic         tm_dsc_sts_qen,
    output logic         tm_dsc_sts_byp,
    output logic         tm_dsc_sts_dir,
    output logic         tm_dsc_sts_mm,
    output logic         tm_dsc_sts_error,
    output logic [ 10:0] tm_dsc_sts_qid,
    output logic [ 15:0] tm_dsc_sts_avl,
    output logic         tm_dsc_sts_qinv,
    output logic         tm_dsc_sts_irq_arm,
    input  logic         tm_dsc_sts_rdy,
    output logic [ 15:0] tm_dsc_sts_pidx,
    input  logic [ 15:0] dsc_crdt_in_crdt,
    input  logic [ 10:0] dsc_crdt_in_qid,
    input  logic         dsc_crdt_in_dir,
    input  logic         dsc_crdt_in_fence,
    input  logic         dsc_crdt_in_vld,
    output logic         dsc_crdt_in_rdy,
    output logic [ 31:0] m_axil_awaddr,
    output logic [ 54:0] m_axil_awuser,
    output logic [  2:0] m_axil_awprot,
    output logic         m_axil_awvalid,
    input  logic         m_axil_awready,
    output logic [ 31:0] m_axil_wdata,
    output logic [  3:0] m_axil_wstrb,
    output logic         m_axil_wvalid,
    input  logic         m_axil_wready,
    input  logic         m_axil_bvalid,
    input  logic [  1:0] m_axil_bresp,
    output logic         m_axil_bready,
    output logic [ 31:0] m_axil_araddr,
    output logic [ 54:0] m_axil_aruser,
    output logic [  2:0] m_axil_arprot,
    output logic         m_axil_arvalid,
    input  logic         m_axil_arready,
    input  logic [ 31:0] m_axil_rdata,
    input  logic [  1:0] m_axil_rresp,
    input  logic         m_axil_rvalid,
    output logic         m_axil_rready,
    output logic [511:0] m_axis_h2c_tdata,
    output logic [ 31:0] m_axis_h2c_tcrc,
    output logic [ 10:0] m_axis_h2c_tuser_qid,
    output logic [  2:0] m_axis_h2c_tuser_port_id,
    output logic         m_axis_h2c_tuser_err,
    output logic [ 31:0] m_axis_h2c_tuser_mdata,
    output logic [  5:0] m_axis_h2c_tuser_mty,
    output logic         m_axis_h2c_tuser_zero_byte,
    output logic         m_axis_h2c_tvalid,
    output logic         m_axis_h2c_tlast,
    input  logic         m_axis_h2c_tready,
    input  logic [511:0] s_axis_c2h_tdata,
    input  logic [ 31:0] s_axis_c2h_tcrc,
    input  logic         s_axis_c2h_ctrl_marker,
    input  logic [  2:0] s_axis_c2h_ctrl_port_id,
    input  logic [  6:0] s_axis_c2h_ctrl_ecc,
    input  logic [ 15:0] s_axis_c2h_ctrl_len,
    input  logic [ 10:0] s_axis_c2h_ctrl_qid,
    input  logic         s_axis_c2h_ctrl_has_cmpt,
    input  logic [  5:0] s_axis_c2h_mty,
    input  logic         s_axis_c2h_tvalid,
    input  logic         s_axis_c2h_tlast,
    output logic         s_axis_c2h_tready,
    input  logic [511:0] s_axis_c2h_cmpt_tdata,
    input  logic [  1:0] s_axis_c2h_cmpt_size,
    input  logic [ 15:0] s_axis_c2h_cmpt_dpar,
    input  logic         s_axis_c2h_cmpt_tvalid,
    input  logic [ 10:0] s_axis_c2h_cmpt_ctrl_qid,
    input  logic [  1:0] s_axis_c2h_cmpt_ctrl_cmpt_type,
    input  logic [ 15:0] s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
    input  logic [  2:0] s_axis_c2h_cmpt_ctrl_port_id,
    input  logic         s_axis_c2h_cmpt_ctrl_marker,
    input  logic         s_axis_c2h_cmpt_ctrl_user_trig,
    input  logic [  2:0] s_axis_c2h_cmpt_ctrl_col_idx,
    input  logic [  2:0] s_axis_c2h_cmpt_ctrl_err_idx,
    output logic         s_axis_c2h_cmpt_tready,
    input  logic         s_axis_c2h_cmpt_ctrl_no_wrb_marker,
    output logic         axis_c2h_status_drop,
    output logic         axis_c2h_status_valid,
    output logic         axis_c2h_status_cmp,
    output logic         axis_c2h_status_error,
    output logic         axis_c2h_status_last,
    output logic [ 10:0] axis_c2h_status_qid,
    output logic         axis_c2h_dmawr_cmp,
    input  logic         soft_reset_n,
    output logic         phy_ready,
    output logic [  7:0] qsts_out_op,
    output logic [ 63:0] qsts_out_data,
    output logic [  2:0] qsts_out_port_id,
    output logic [ 12:0] qsts_out_qid,
    output logic         qsts_out_vld,
    input  logic         qsts_out_rdy
);

    // Unused ports
    assign usr_irq_out_ack        = '0;
    assign usr_irq_out_fail       = '0;
    assign h2c_byp_out_dsc        = '0;
    assign h2c_byp_out_st_mm      = '0;
    assign h2c_byp_out_dsc_sz     = '0;
    assign h2c_byp_out_qid        = '0;
    assign h2c_byp_out_error      = '0;
    assign h2c_byp_out_func       = '0;
    assign h2c_byp_out_cidx       = '0;
    assign h2c_byp_out_port_id    = '0;
    assign h2c_byp_out_vld        = '0;
    assign h2c_byp_out_fmt        = '0;
    assign c2h_byp_out_dsc        = '0;
    assign c2h_byp_out_st_mm      = '0;
    assign c2h_byp_out_qid        = '0;
    assign c2h_byp_out_dsc_sz     = '0;
    assign c2h_byp_out_error      = '0;
    assign c2h_byp_out_func       = '0;
    assign c2h_byp_out_cidx       = '0;
    assign c2h_byp_out_port_id    = '0;
    assign c2h_byp_out_vld        = '0;
    assign c2h_byp_out_fmt        = '0;
    assign c2h_byp_out_pfch_tag   = '0;
    assign c2h_byp_in_st_csh_rdy  = '1;
    assign h2c_byp_in_st_rdy      = '1;
    assign tm_dsc_sts_vld         = '0;
    assign tm_dsc_sts_port_id     = '0;
    assign tm_dsc_sts_qen         = '0;
    assign tm_dsc_sts_byp         = '0;
    assign tm_dsc_sts_dir         = '0;
    assign tm_dsc_sts_mm          = '0;
    assign tm_dsc_sts_error       = '0;
    assign tm_dsc_sts_qid         = '0;
    assign tm_dsc_sts_avl         = '0;
    assign tm_dsc_sts_qinv        = '0;
    assign tm_dsc_sts_irq_arm     = '0;
    assign dsc_crdt_in_rdy        = '1;
    assign axis_c2h_status_drop   = '0;
    assign axis_c2h_status_valid  = '0;
    assign axis_c2h_status_cmp    = '0;
    assign axis_c2h_status_error  = '0;
    assign axis_c2h_status_last   = '0;
    assign axis_c2h_status_qid    = '0;
    assign axis_c2h_dmawr_cmp     = '0;
    assign qsts_out_op            = '0;
    assign qsts_out_data          = '0;
    assign qsts_out_port_id       = '0;
    assign qsts_out_qid           = '0;
    assign qsts_out_vld           = '0;

    assign s_axis_c2h_tready      = '1;
    assign s_axis_c2h_cmpt_tready = '1;

    // 250MHz clock
    initial begin
        axi_aclk = '0;
        forever #2ns axi_aclk = ~axi_aclk;
    end

    // Reset
    assign axi_aresetn = sys_rst_n & soft_reset_n;

    initial begin
        user_lnk_up = '1;  // Not used in the shell
        phy_ready   = '1;  // Not used in the shell
    end

    //==================================================
    // axil vip
    //==================================================
    axi_lite_vip_0 axil_vip_inst (
        .aclk          (axi_aclk      ),
        .aresetn       (axi_aresetn   ),
        .m_axi_awaddr  (m_axil_awaddr ),
        .m_axi_awprot  (m_axil_awprot ),
        .m_axi_awvalid (m_axil_awvalid),
        .m_axi_awready (m_axil_awready),
        .m_axi_wdata   (m_axil_wdata  ),
        .m_axi_wstrb   (m_axil_wstrb  ),
        .m_axi_wvalid  (m_axil_wvalid ),
        .m_axi_wready  (m_axil_wready ),
        .m_axi_bresp   (m_axil_bresp  ),
        .m_axi_bvalid  (m_axil_bvalid ),
        .m_axi_bready  (m_axil_bready ),
        .m_axi_araddr  (m_axil_araddr ),
        .m_axi_arprot  (m_axil_arprot ),
        .m_axi_arvalid (m_axil_arvalid),
        .m_axi_arready (m_axil_arready),
        .m_axi_rdata   (m_axil_rdata  ),
        .m_axi_rresp   (m_axil_rresp  ),
        .m_axi_rvalid  (m_axil_rvalid ),
        .m_axi_rready  (m_axil_rready )
    );

    axi_lite_vip_0_mst_t agent;
    axi_transaction rd_transaction, wr_transaction;
    logic [31:0] axil_read_data;

    task automatic init_axil_agent;
        agent = new("axil master vip agent", axil_vip_inst.inst.IF);
        agent.start_master();

        rd_transaction = agent.rd_driver.create_transaction("read transaction");
        wr_transaction = agent.wr_driver.create_transaction("write transaction");
    endtask

    task automatic axil_read(logic [31:0] addr);
        rd_transaction.set_read_cmd(addr);
        rd_transaction.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        agent.rd_driver.send(rd_transaction);
        agent.rd_driver.wait_rsp(rd_transaction);
        axil_read_data = rd_transaction.get_data_beat(0);
        $timeformat(-6, 3, " us", 12);
        $display("********** read  %08h : %08h @ %t", addr, axil_read_data, $realtime);
    endtask

    task automatic axil_write(logic [31:0] addr, logic [31:0] data);
        wr_transaction.set_write_cmd(addr);
        wr_transaction.set_data_block(data);
        agent.wr_driver.send(wr_transaction);
        $timeformat(-6, 3, " us", 12);
        $display("********** write %08h : %08h @ %t", addr, data, $realtime);
    endtask

    //==================================================
    // axis h2c vip
    //==================================================
    logic [48:0] m_axis_h2c_tuser;

    assign m_axis_h2c_tcrc            = '0;
    assign m_axis_h2c_tuser_port_id   = '0;
    assign m_axis_h2c_tuser_err       = '0;
    assign m_axis_h2c_tuser_zero_byte = '0;

    axis_h2c_vip_0 axis_h2c_vip_inst (
        .aclk          (axi_aclk         ),
        .aresetn       (axi_aresetn      ),
        .m_axis_tvalid (m_axis_h2c_tvalid),
        .m_axis_tready (m_axis_h2c_tready),
        .m_axis_tdata  (m_axis_h2c_tdata ),
        .m_axis_tlast  (m_axis_h2c_tlast ),
        .m_axis_tuser  (m_axis_h2c_tuser )
    );

    assign {m_axis_h2c_tuser_mdata, m_axis_h2c_tuser_mty, m_axis_h2c_tuser_qid} = m_axis_h2c_tuser;

    axis_h2c_vip_0_mst_t   h2c_agent;
    axi4stream_transaction h2c_wr_transaction;

    task automatic init_h2c_agent;
        h2c_agent = new("axis h2c master vip agent", axis_h2c_vip_inst.inst.IF);
        h2c_agent.start_master();

        h2c_wr_transaction = h2c_agent.driver.create_transaction("write transaction");
    endtask

    task automatic h2c_write(logic [511:0] data, logic [31:0] mdata, logic [5:0] mty,
                             logic [10:0] qid, logic last);
        h2c_wr_transaction.set_data_beat(data);
        h2c_wr_transaction.set_user_beat({mdata, mty, qid});
        h2c_wr_transaction.set_last(last);
        h2c_wr_transaction.set_delay(0);
        h2c_agent.driver.send(h2c_wr_transaction);
    endtask

    task automatic h2c_write_packet();
        int size = 100;
        int num_beat = (size + 63) / 64;
        logic [7:0] data;
        for (int i = 0; i < num_beat; i++) begin
            data = i;
            h2c_write({64{data}}, size, i == num_beat - 1 ? 64 * num_beat - size : 0, 0,
                      i == num_beat - 1);
        end
    endtask

endmodule

