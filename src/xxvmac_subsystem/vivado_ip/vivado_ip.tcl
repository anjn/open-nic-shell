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
set ips {
    xxv_ethernet_0
    xxvmac_subsystem_axi_crossbar
    xxvmac_subsystem_axis_dwidth_converter_rx
    xxvmac_subsystem_axis_dwidth_converter_tx
}
if {$num_cmac_port == 2} {
    lappend ips "xxv_ehternet_1"
}
