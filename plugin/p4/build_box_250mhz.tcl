# Add source files
read_verilog -quiet [glob -nocomplain -directory box_250mhz "*.v"]

# Create block design
variable design_name
set design_name box_250mhz_bd
create_bd_design $design_name
source ${design_name}_script.tcl

# Update
update_module_reference box_250mhz_bd_box_250mhz_p4_out_0_0

#startgroup

# Create p4
create_bd_cell -type ip -vlnv xilinx.com:ip:vitis_net_p4:1.1 vitis_net_p4_0

if {![file exists $p4_code]} {
    puts "Can't find P4 code! ($p4_code)"
    exit
}

set_property -dict [list \
    CONFIG.TDATA_NUM_BYTES {128} \
    CONFIG.AXIS_CLK_FREQ_MHZ {250} \
    CONFIG.PKT_RATE {250} \
    CONFIG.P4_FILE $p4_code] \
    [get_bd_cells vitis_net_p4_0]

# Disconnect dummy
delete_bd_objs \
    [get_bd_intf_nets box_250mhz_p4_dummy_0_m_axis] \
    [get_bd_intf_nets box_250mhz_p4_in_0_m_axis]

# Connect AXIS, clock and reset
connect_bd_intf_net [get_bd_intf_pins box_250mhz_p4_in_0/m_axis] [get_bd_intf_pins vitis_net_p4_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins vitis_net_p4_0/m_axis] [get_bd_intf_pins box_250mhz_p4_out_0/s_axis]
connect_bd_net [get_bd_ports axis_aclk] [get_bd_pins vitis_net_p4_0/s_axis_aclk]
connect_bd_net [get_bd_ports axis_aresetn] [get_bd_pins vitis_net_p4_0/s_axis_aresetn]

# Connect AXI
if {![string equal [get_bd_pins -quiet /vitis_net_p4_0/s_axi_aclk] ""]} {
    # Delete dummy GPIO
    delete_bd_objs [get_bd_intf_nets S_AXI_0_1] [get_bd_nets s_axi_aclk_0_1] [get_bd_nets axil_aresetn_1] [get_bd_cells axi_gpio_0]
    # Connect
    connect_bd_intf_net [get_bd_intf_ports s_axil] [get_bd_intf_pins vitis_net_p4_0/s_axi]
    connect_bd_net [get_bd_ports axil_aclk] [get_bd_pins vitis_net_p4_0/s_axi_aclk]
    connect_bd_net [get_bd_ports axil_aresetn] [get_bd_pins vitis_net_p4_0/s_axi_aresetn]
}

# Connect CAM clock and reset
if {![string equal [get_bd_pins -quiet /vitis_net_p4_0/cam_mem_aclk] ""]} {
    connect_bd_net [get_bd_ports axis_aclk] [get_bd_pins vitis_net_p4_0/cam_mem_aclk]
    connect_bd_net [get_bd_ports axis_aresetn] [get_bd_pins vitis_net_p4_0/cam_mem_aresetn]
}

# Connect user_metadata
if {![string equal [get_bd_pins -quiet /vitis_net_p4_0/user_metadata_in] ""]} {
    # Get bit width
    set user_metadata_width [expr [get_property LEFT [get_bd_pins /vitis_net_p4_0/user_metadata_in]] + 1]
    if {$user_metadata_width < 64} {
        puts "ERROR: The width of user_metadata in/out should be greater or equal to 64"
        exit
    }
    # Set bit width
    set_property -dict [list CONFIG.USERMETA_W $user_metadata_width] [get_bd_cells box_250mhz_p4_in_0]
    set_property -dict [list CONFIG.USERMETA_W $user_metadata_width] [get_bd_cells box_250mhz_p4_out_0]
    # Disconnect and delete dummy
    delete_bd_objs \
        [get_bd_nets box_250mhz_p4_in_0_user_metadata_in] \
        [get_bd_nets box_250mhz_p4_in_0_user_metadata_in_valid] \
        [get_bd_nets box_250mhz_p4_dummy_0_user_metadata_out] \
        [get_bd_nets box_250mhz_p4_dummy_0_user_metadata_out_valid] \
        [get_bd_cells box_250mhz_p4_dummy_0]
    # Connect
    connect_bd_net [get_bd_pins box_250mhz_p4_in_0/user_metadata_in] [get_bd_pins vitis_net_p4_0/user_metadata_in]
    connect_bd_net [get_bd_pins box_250mhz_p4_in_0/user_metadata_in_valid] [get_bd_pins vitis_net_p4_0/user_metadata_in_valid]
    connect_bd_net [get_bd_pins vitis_net_p4_0/user_metadata_out] [get_bd_pins box_250mhz_p4_out_0/user_metadata_out]
    connect_bd_net [get_bd_pins vitis_net_p4_0/user_metadata_out_valid] [get_bd_pins box_250mhz_p4_out_0/user_metadata_out_valid]
} else {
    puts "ERROR: P4 instance should have user_metadata in/out ports"
    exit
}

#endgroup

# Assign address
set range [expr 2 ** [get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins /vitis_net_p4_0/s_axi]]]
set range [expr $range < 4096 ? 4096 : $range]
assign_bd_address -range $range [get_bd_addr_segs /vitis_net_p4_0/s_axi/*]

# Validate
validate_bd_design

# Generate RTL wrapper
set wrapper_path [make_wrapper -fileset sources_1 -files [get_files -norecurse $design_name.bd] -top]
add_files -norecurse -fileset sources_1 $wrapper_path
update_compile_order -fileset sources_1

