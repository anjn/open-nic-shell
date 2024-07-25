`timescale 1ns/1ps

import axi_vip_pkg::*;
import axi4stream_vip_pkg::*;

import axi_lite_vip_0_pkg::*;
import axis_h2c_vip_0_pkg::*;

module tb;

    parameter int NUM_QDMA = 1;
    parameter int NUM_CMAC_PORT = 0;
    parameter int    NUM_CMAC_CORE   = NUM_CMAC_PORT;
    parameter int NUM_XXVMAC_PORT = 1;
    parameter int    NUM_XXVMAC_CORE = (NUM_XXVMAC_PORT + 3) / 4;
    parameter int    NUM_MAC_STREAM  = NUM_CMAC_PORT + NUM_XXVMAC_PORT;
    parameter int    NUM_MAC_CORE    = NUM_CMAC_CORE + NUM_XXVMAC_CORE;
    parameter int    NUM_QSFP_GT     = NUM_CMAC_PORT * 4 + NUM_XXVMAC_PORT;
    parameter int    NUM_QSFP_GT_REF = (NUM_QSFP_GT + 3) / 4;

    logic    [NUM_QDMA-1:0] s_axil_sim_awvalid;
    logic [32*NUM_QDMA-1:0] s_axil_sim_awaddr;
    logic    [NUM_QDMA-1:0] s_axil_sim_awready;
    logic    [NUM_QDMA-1:0] s_axil_sim_wvalid;
    logic [32*NUM_QDMA-1:0] s_axil_sim_wdata;
    logic    [NUM_QDMA-1:0] s_axil_sim_wready;
    logic    [NUM_QDMA-1:0] s_axil_sim_bvalid;
    logic  [2*NUM_QDMA-1:0] s_axil_sim_bresp;
    logic    [NUM_QDMA-1:0] s_axil_sim_bready;
    logic    [NUM_QDMA-1:0] s_axil_sim_arvalid;
    logic [32*NUM_QDMA-1:0] s_axil_sim_araddr;
    logic    [NUM_QDMA-1:0] s_axil_sim_arready;
    logic    [NUM_QDMA-1:0] s_axil_sim_rvalid;
    logic [32*NUM_QDMA-1:0] s_axil_sim_rdata;
    logic  [2*NUM_QDMA-1:0] s_axil_sim_rresp;
    logic    [NUM_QDMA-1:0] s_axil_sim_rready;

    logic     [NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tvalid;
    logic [512*NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tdata;
    logic  [32*NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tcrc;
    logic     [NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tlast;
    logic  [11*NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tuser_qid;
    logic   [3*NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tuser_port_id;
    logic     [NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tuser_err;
    logic  [32*NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tuser_mdata;
    logic   [6*NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tuser_mty;
    logic     [NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tuser_zero_byte;
    logic     [NUM_QDMA-1:0] s_axis_qdma_h2c_sim_tready;

    logic     [NUM_QDMA-1:0] m_axis_qdma_c2h_sim_tvalid;
    logic [512*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_tdata;
    logic  [32*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_tcrc;
    logic     [NUM_QDMA-1:0] m_axis_qdma_c2h_sim_tlast;
    logic     [NUM_QDMA-1:0] m_axis_qdma_c2h_sim_ctrl_marker;
    logic   [3*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_ctrl_port_id;
    logic   [7*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_ctrl_ecc;
    logic  [16*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_ctrl_len;
    logic  [11*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_ctrl_qid;
    logic     [NUM_QDMA-1:0] m_axis_qdma_c2h_sim_ctrl_has_cmpt;
    logic   [6*NUM_QDMA-1:0] m_axis_qdma_c2h_sim_mty;
    logic     [NUM_QDMA-1:0] m_axis_qdma_c2h_sim_tready;

    logic     [NUM_QDMA-1:0] m_axis_qdma_cpl_sim_tvalid;
    logic [512*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_tdata;
    logic   [2*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_size;
    logic  [16*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_dpar;
    logic  [11*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_qid;
    logic   [2*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_cmpt_type;
    logic  [16*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_wait_pld_pkt_id;
    logic   [3*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_port_id;
    logic     [NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_marker;
    logic     [NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_user_trig;
    logic   [3*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_col_idx;
    logic   [3*NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_err_idx;
    logic     [NUM_QDMA-1:0] m_axis_qdma_cpl_sim_ctrl_no_wrb_marker;
    logic     [NUM_QDMA-1:0] m_axis_qdma_cpl_sim_tready;

    logic     [NUM_MAC_STREAM-1:0] m_axis_cmac_tx_sim_tvalid;
    logic [512*NUM_MAC_STREAM-1:0] m_axis_cmac_tx_sim_tdata;
    logic  [64*NUM_MAC_STREAM-1:0] m_axis_cmac_tx_sim_tkeep;
    logic     [NUM_MAC_STREAM-1:0] m_axis_cmac_tx_sim_tlast;
    logic     [NUM_MAC_STREAM-1:0] m_axis_cmac_tx_sim_tuser_err;
    logic     [NUM_MAC_STREAM-1:0] m_axis_cmac_tx_sim_tready;

    logic     [NUM_MAC_STREAM-1:0] s_axis_cmac_rx_sim_tvalid;
    logic [512*NUM_MAC_STREAM-1:0] s_axis_cmac_rx_sim_tdata;
    logic  [64*NUM_MAC_STREAM-1:0] s_axis_cmac_rx_sim_tkeep;
    logic     [NUM_MAC_STREAM-1:0] s_axis_cmac_rx_sim_tlast;
    logic     [NUM_MAC_STREAM-1:0] s_axis_cmac_rx_sim_tuser_err;

    logic [NUM_QDMA-1:0] powerup_rstn;

    logic [16*NUM_QDMA-1:0] pcie_rxp;
    logic [16*NUM_QDMA-1:0] pcie_rxn;
    logic [16*NUM_QDMA-1:0] pcie_txp;
    logic [16*NUM_QDMA-1:0] pcie_txn;

    logic   [NUM_QSFP_GT-1:0] qsfp_rxp;
    logic   [NUM_QSFP_GT-1:0] qsfp_rxn;
    logic   [NUM_QSFP_GT-1:0] qsfp_txp;
    logic   [NUM_QSFP_GT-1:0] qsfp_txn;

    logic     [NUM_QSFP_GT_REF-1:0] qsfp_refclk_p;
    logic     [NUM_QSFP_GT_REF-1:0] qsfp_refclk_n;

    logic                      satellite_uart_0_rxd;
    logic                      satellite_uart_0_txd;
    logic                      hbm_cattrip;
    logic                [3:0] satellite_gpio;

    axi_lite_vip_0 axil_vip_inst (
        .aclk          ( shell_inst.axil_aclk[0] ),
        .aresetn       ( 1'b1                    ),
        .m_axi_awaddr  ( s_axil_sim_awaddr       ),
        .m_axi_awprot  (                         ),
        .m_axi_awvalid ( s_axil_sim_awvalid      ),
        .m_axi_awready ( s_axil_sim_awready      ),
        .m_axi_wdata   ( s_axil_sim_wdata        ),
        .m_axi_wstrb   (                         ),
        .m_axi_wvalid  ( s_axil_sim_wvalid       ),
        .m_axi_wready  ( s_axil_sim_wready       ),
        .m_axi_bresp   ( s_axil_sim_bresp        ),
        .m_axi_bvalid  ( s_axil_sim_bvalid       ),
        .m_axi_bready  ( s_axil_sim_bready       ),
        .m_axi_araddr  ( s_axil_sim_araddr       ),
        .m_axi_arprot  (                         ),
        .m_axi_arvalid ( s_axil_sim_arvalid      ),
        .m_axi_arready ( s_axil_sim_arready      ),
        .m_axi_rdata   ( s_axil_sim_rdata        ),
        .m_axi_rresp   ( s_axil_sim_rresp        ),
        .m_axi_rvalid  ( s_axil_sim_rvalid       ),
        .m_axi_rready  ( s_axil_sim_rready       ) 
    );

    axis_h2c_vip_0 axis_h2c_vip_inst (
        .aclk          ( shell_inst.axis_aclk[0]       ),
        .aresetn       ( 1'b1                          ),
        .m_axis_tvalid ( s_axis_qdma_h2c_sim_tvalid    ),
        .m_axis_tready ( s_axis_qdma_h2c_sim_tready    ),
        .m_axis_tdata  ( s_axis_qdma_h2c_sim_tdata     ),
        .m_axis_tlast  ( s_axis_qdma_h2c_sim_tlast     ),
        .m_axis_tuser  ( { 
            s_axis_qdma_h2c_sim_tuser_mdata,
            s_axis_qdma_h2c_sim_tuser_mty,
            s_axis_qdma_h2c_sim_tuser_qid
        } )
    );
    assign s_axis_qdma_h2c_sim_tcrc = '0;
    assign s_axis_qdma_h2c_sim_tuser_port_id = '0;
    assign s_axis_qdma_h2c_sim_tuser_err = '0;
    assign s_axis_qdma_h2c_sim_tuser_zero_byte = '0;

    assign m_axis_qdma_c2h_sim_tready = '1;
    assign m_axis_qdma_cpl_sim_tready = '1;

    open_nic_shell shell_inst(.*);

    // axil vip
    axi_lite_vip_0_mst_t agent;
    axi_transaction rd_transaction, wr_transaction;
    logic [31:0] axil_read_data;

    task init_axil_agent;
        agent = new("axil master vip agent", axil_vip_inst.inst.IF);
        agent.start_master();

        rd_transaction = agent.rd_driver.create_transaction("read transaction");
        wr_transaction = agent.wr_driver.create_transaction("write transaction");
    endtask

    task axil_read(
        logic [31:0] addr
    );
        rd_transaction.set_read_cmd(addr);
        rd_transaction.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        agent.rd_driver.send(rd_transaction);
        agent.rd_driver.wait_rsp(rd_transaction);
        axil_read_data = rd_transaction.get_data_beat(0);
        $display("********** read  %08h : %08h", addr, axil_read_data);
    endtask

    task axil_write(
        logic [31:0] addr,
        logic [31:0] data
    );
        wr_transaction.set_write_cmd(addr);
        wr_transaction.set_data_block(data);
        agent.wr_driver.send(wr_transaction);
        $display("********** write %08h : %08h", addr, data);
    endtask

    // axis h2c vip
    axis_h2c_vip_0_mst_t h2c_agent;
    axi4stream_transaction h2c_wr_transaction;

    task init_h2c_agent;
        h2c_agent = new("axis h2c master vip agent", axis_h2c_vip_inst.inst.IF);
        h2c_agent.start_master();

        h2c_wr_transaction = h2c_agent.driver.create_transaction("write transaction");
    endtask

    task h2c_write(
        logic [511:0] data,
        logic [31:0] mdata,
        logic [5:0] mty,
        logic [10:0] qid,
        logic last
    );
        h2c_wr_transaction.set_data_beat(data);
        h2c_wr_transaction.set_user_beat({ mdata, mty, qid });
        h2c_wr_transaction.set_last(last);
        h2c_wr_transaction.set_delay(0);
        h2c_agent.driver.send(h2c_wr_transaction);
    endtask

    task h2c_write_packet();
        int size = 100;
        int num_beat = (size + 63) / 64;
        logic [7:0] data;
        for (int i = 0; i < num_beat; i++) begin
            data = i;
            h2c_write({64{data}}, size, i == num_beat - 1 ? 64 * num_beat - size : 0, 0, i == num_beat - 1);
        end
    endtask

    // QSPF gt loopback
    always_comb begin
        qsfp_rxp = qsfp_txp;
        qsfp_rxn = qsfp_txn;
    end

    // QSFP ref clock
    initial begin
        qsfp_refclk_p = '0;
        forever #3.103030303030303ns qsfp_refclk_p = ~qsfp_refclk_p;
    end
    always_comb qsfp_refclk_n = ~qsfp_refclk_p;

    // Main
    initial begin
        init_axil_agent();
        init_h2c_agent();

        powerup_rstn = '0;

        #500;
        axil_write(32'h0004, 32'hffff_ffff); // system reset
        axil_write(32'h000c, 32'hffff_ffff); // shell reset
        axil_write(32'h0014, 32'hffff_ffff); // user reset

        #500;
        powerup_rstn = '1;

        // wait system reset done
        do begin
            axil_read(32'h0008);
        end while (axil_read_data == 0);
        do begin
            axil_read(32'h0010);
        end while (axil_read_data == 0);
        do begin
            axil_read(32'h0018);
        end while (axil_read_data == 0);

        #500;
        axil_read(32'h8024);

        axil_write(32'h8008, 32'hc000_0000); // MODE_REG
        axil_write(32'h8014, 32'h0000_0000); // CONFIGURATION_RX_REG1
        axil_write(32'h800c, 32'h0000_0000); // CONFIGURATION_TX_REG1
        axil_write(32'h8000, 32'h0000_0001); // GT_RESET_REG
        axil_write(32'h8000, 32'h0000_0000); // GT_RESET_REG

        #8000;

        axil_write(32'h1000, 32'h0000_0008); // base queue id, number of queues

        #1000;

        do begin
            axil_read(32'h840c); // STAT_RX_BLOCK_LOCK_REG: 040C
        end while (axil_read_data == 0);

        #100;

        h2c_write_packet();

        #1000;
        $finish;
    end

endmodule
