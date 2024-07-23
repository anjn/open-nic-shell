set axis_dwidth_converter xxvmac_subsystem_axis_dwidth_converter_tx
create_ip -name axis_dwidth_converter -vendor xilinx.com -library ip -module_name $axis_dwidth_converter
set_property -dict [list \
  CONFIG.HAS_TKEEP {1} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.M_TDATA_NUM_BYTES {64} \
  CONFIG.S_TDATA_NUM_BYTES {8} \
  CONFIG.TUSER_BITS_PER_BYTE {1} \
] [get_ips $axis_dwidth_converter]

