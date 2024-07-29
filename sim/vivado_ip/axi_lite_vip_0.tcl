create_ip -name axi_vip -vendor xilinx.com -library ip -module_name axi_lite_vip_0 -dir ${ip_build_dir}
set_property -dict [list \
    CONFIG.Component_Name {axi_lite_vip_0} \
    CONFIG.PROTOCOL {AXI4LITE} \
    CONFIG.INTERFACE_MODE {MASTER} \
    CONFIG.SUPPORTS_NARROW {0} \
    CONFIG.HAS_BURST {0} \
    CONFIG.HAS_LOCK {0} \
    CONFIG.HAS_CACHE {0} \
    CONFIG.HAS_REGION {0} \
    CONFIG.HAS_QOS {0} \
] [get_ips axi_lite_vip_0]
