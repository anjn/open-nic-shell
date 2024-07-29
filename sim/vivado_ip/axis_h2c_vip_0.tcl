create_ip -name axi4stream_vip -vendor xilinx.com -library ip -module_name axis_h2c_vip_0 -dir ${ip_build_dir}
set_property -dict [list \
    CONFIG.INTERFACE_MODE {MASTER} \
    CONFIG.TDATA_NUM_BYTES {64} \
    CONFIG.TID_WIDTH {0} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TUSER_WIDTH {49} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.Component_Name {axis_h2c_vip_0} \
] [get_ips axis_h2c_vip_0]
