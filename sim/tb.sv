`timescale 1ns/1ps

`define QDMA0 dut.qdma_if[0].qdma_subsystem_inst.qdma_wrapper_inst.qdma_inst

module tb #(
    parameter logic [31:0] BUILD_TIMESTAMP = 32'h01010000,
    parameter int          MIN_PKT_LEN     = 64,
    parameter int          MAX_PKT_LEN     = 1518,
    parameter int          USE_PHYS_FUNC   = 1,
    parameter int          NUM_PHYS_FUNC   = 1,
    parameter int          NUM_QUEUE       = 512,
    parameter int          NUM_QDMA        = 1,
    parameter int          NUM_CMAC_PORT   = 0,
    parameter int          NUM_XXVMAC_PORT = 1
) ();

    localparam int         NUM_CMAC_CORE   = NUM_CMAC_PORT;
    localparam int         NUM_XXVMAC_CORE = (NUM_XXVMAC_PORT + 3) / 4;
    localparam int         NUM_MAC_STREAM  = NUM_CMAC_PORT + NUM_XXVMAC_PORT;
    localparam int         NUM_MAC_CORE    = NUM_CMAC_CORE + NUM_XXVMAC_CORE;
    localparam int         NUM_QSFP_GT     = NUM_CMAC_PORT * 4 + NUM_XXVMAC_PORT;
    localparam int         NUM_QSFP_GT_REF = (NUM_QSFP_GT + 3) / 4;

    logic [16*NUM_QDMA-1:0] pcie_rxp;
    logic [16*NUM_QDMA-1:0] pcie_rxn;
    logic [16*NUM_QDMA-1:0] pcie_txp;
    logic [16*NUM_QDMA-1:0] pcie_txn;

    logic [NUM_QDMA-1:0] pcie_refclk_p;
    logic [NUM_QDMA-1:0] pcie_refclk_n;
    logic [NUM_QDMA-1:0] pcie_rstn;

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

    open_nic_shell #(
        .NUM_CMAC_PORT(NUM_CMAC_PORT),
        .NUM_XXVMAC_PORT(NUM_XXVMAC_PORT),
        .NUM_PHYS_FUNC(NUM_PHYS_FUNC)
    ) dut(
        .*
    );

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
        `QDMA0.init_axil_agent();
        `QDMA0.init_h2c_agent();

        // PCIe reset
        pcie_rstn = '0;
        #500;
        pcie_rstn = '1;

        // reset from host
        #500;
        `QDMA0.axil_write(32'h0004, 32'hffff_ffff); // system reset
        `QDMA0.axil_write(32'h000c, 32'hffff_ffff); // shell reset
        `QDMA0.axil_write(32'h0014, 32'hffff_ffff); // user reset

        // wait reset done
        do begin
            `QDMA0.axil_read(32'h0008);
        end while (`QDMA0.axil_read_data == 0);
        do begin
            `QDMA0.axil_read(32'h0010);
        end while (`QDMA0.axil_read_data == 0);
        do begin
            `QDMA0.axil_read(32'h0018);
        end while (`QDMA0.axil_read_data == 0);

        #500;
        // ????
        `QDMA0.axil_read(32'h8024);

        if (NUM_XXVMAC_PORT > 0) begin
            // Initialize XXVMAC
            `QDMA0.axil_write(32'h8008, 32'hc000_0000); // MODE_REG
            `QDMA0.axil_write(32'h8014, 32'h0000_0000); // CONFIGURATION_RX_REG1
            `QDMA0.axil_write(32'h800c, 32'h0000_0000); // CONFIGURATION_TX_REG1
            `QDMA0.axil_write(32'h8000, 32'h0000_0001); // GT_RESET_REG
            `QDMA0.axil_write(32'h8000, 32'h0000_0000); // GT_RESET_REG
        end else begin
            // Initialize CMAC
            // https://docs.amd.com/r/en-US/pg203-cmac-usplus/With-AXI4-Lite-Interface
            `QDMA0.axil_write(32'h8014, 32'h0000_0001); // [CONFIGURATION_RX_REG1 for ctl_rx_enable]
            `QDMA0.axil_write(32'h800c, 32'h0000_0010); // [CONFIGURATION_TX_REG1 for ctl_tx_send_rfi]
            `QDMA0.axil_write(32'h8084, 32'h0000_3DFF); // [CONFIGURATION_RX_FLOW_CONTROL_CONTROL_REG1]
            `QDMA0.axil_write(32'h8088, 32'h0001_C631); // [CONFIGURATION_RX_FLOW_CONTROL_CONTROL_REG2]
            `QDMA0.axil_write(32'h8048, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG1]
            `QDMA0.axil_write(32'h804C, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG2]
            `QDMA0.axil_write(32'h8050, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG3]
            `QDMA0.axil_write(32'h8054, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG4]
            `QDMA0.axil_write(32'h8058, 32'h0000_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_QUANTA_REG5]
            `QDMA0.axil_write(32'h8034, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG1]
            `QDMA0.axil_write(32'h8038, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG2]
            `QDMA0.axil_write(32'h803C, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG3]
            `QDMA0.axil_write(32'h8040, 32'hFFFF_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG4]
            `QDMA0.axil_write(32'h8044, 32'h0000_FFFF); // [CONFIGURATION_TX_FLOW_CONTROL_REFRESH_REG5]
            `QDMA0.axil_write(32'h8030, 32'h0000_01FF); // [CONFIGURATION_TX_FLOW_CONTROL_CONTROL_REG1]
        end

        #8000;

        // Queue settings
        if (NUM_PHYS_FUNC > 0) `QDMA0.axil_write(32'h1000, 32'h0000_0008); // base queue id, number of queues
        if (NUM_PHYS_FUNC > 1) `QDMA0.axil_write(32'h2000, 32'h0008_0008); // base queue id, number of queues
        if (NUM_PHYS_FUNC > 2) `QDMA0.axil_write(32'h3000, 32'h0010_0008); // base queue id, number of queues
        if (NUM_PHYS_FUNC > 3) `QDMA0.axil_write(32'h4000, 32'h0018_0008); // base queue id, number of queues

        #1000;

        if (NUM_XXVMAC_PORT > 0) begin
            // Wait link up
            do begin
                `QDMA0.axil_read(32'h840c); // STAT_RX_BLOCK_LOCK_REG: 040C
            end while (`QDMA0.axil_read_data == 0);
        end else begin
            // Wait link up
            #20us;
            do begin
                # 2us;
                `QDMA0.axil_read(32'h8204); // STAT_RX_STATUS_REG
            end while (`QDMA0.axil_read_data[1] == 0); // [1] : stat_rx_aligned
            #1000;
            `QDMA0.axil_write(32'h800c, 32'h0000_0001); // [CONFIGURATION_TX_REG1 for ctl_tx_enable]
            #2000;
        end

        // Send packet from host
        if (NUM_PHYS_FUNC > 0) #1us `QDMA0.h2c_write_packet('h00);
        if (NUM_PHYS_FUNC > 1) #1us `QDMA0.h2c_write_packet('h08);
        if (NUM_PHYS_FUNC > 2) #1us `QDMA0.h2c_write_packet('h10);
        if (NUM_PHYS_FUNC > 3) #1us `QDMA0.h2c_write_packet('h18);

        #3000;
        $finish;
    end

endmodule
