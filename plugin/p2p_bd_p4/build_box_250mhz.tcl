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
variable design_name
set design_name box_250mhz_bd

create_bd_design $design_name

source ${design_name}_script.tcl

set wrapper_path [make_wrapper -fileset sources_1 -files [get_files -norecurse $design_name.bd] -top]
add_files -norecurse -fileset sources_1 $wrapper_path
update_compile_order -fileset sources_1

