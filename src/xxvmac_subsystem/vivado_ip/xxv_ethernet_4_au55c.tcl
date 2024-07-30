# *************************************************************************
#
# Copyright 2020 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# *************************************************************************
set xxv_ethernet xxv_ethernet_4
create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name $xxv_ethernet -dir ${ip_build_dir}

if {$fixstars_xg_mac} {
    set_property -dict [list \
      CONFIG.CORE {Ethernet PCS/PMA 64-bit} \
      CONFIG.DATA_PATH_INTERFACE {MII} \
    ] [get_ips $xxv_ethernet]
} else {
    set_property -dict [list \
      CONFIG.CORE {Ethernet MAC+PCS/PMA 64-bit} \
    ] [get_ips $xxv_ethernet]
}

set_property -dict [list \
  CONFIG.BASE_R_KR {BASE-R} \
  CONFIG.ENABLE_TX_FLOW_CONTROL_LOGIC {0} \
  CONFIG.GT_REF_CLK_FREQ {161.1328125} \
  CONFIG.INCLUDE_AXI4_INTERFACE {1} \
  CONFIG.LINE_RATE {10} \
  CONFIG.RUNTIME_SWITCH {0} \
  CONFIG.STATISTICS_REGS_TYPE {0} \
  CONFIG.NUM_OF_CORES {1} \
  CONFIG.GT_DRP_CLK {125} \
  CONFIG.ENABLE_PIPELINE_REG {1} \
  CONFIG.GT_GROUP_SELECT {Quad_X0Y7} \
  CONFIG.LANE1_GT_LOC {X0Y28} \
] [get_ips $xxv_ethernet]
