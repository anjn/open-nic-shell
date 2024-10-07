
################################################################
# This is a generated script based on design: box_250mhz_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source box_250mhz_bd_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# box_250mhz_p4_dummy, box_250mhz_p4_in, box_250mhz_p4_out

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu55c-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:au55c:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name box_250mhz_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:axis_dwidth_converter:1.1\
xilinx.com:ip:axis_switch:1.1\
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
box_250mhz_p4_dummy\
box_250mhz_p4_in\
box_250mhz_p4_out\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set m_axis_adap_tx_250mhz [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_adap_tx_250mhz ]

  set m_axis_qdma_c2h_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_qdma_c2h_0 ]

  set m_axis_qdma_c2h_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_qdma_c2h_1 ]

  set s_axil [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {16} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axil

  set s_axis_adap_rx_250mhz [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_adap_rx_250mhz ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {48} \
   ] $s_axis_adap_rx_250mhz

  set s_axis_qdma_h2c_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_qdma_h2c_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {48} \
   ] $s_axis_qdma_h2c_0

  set s_axis_qdma_h2c_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_qdma_h2c_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {48} \
   ] $s_axis_qdma_h2c_1


  # Create ports
  set axil_aclk [ create_bd_port -dir I -type clk axil_aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {axil_aresetn} \
 ] $axil_aclk
  set axil_aresetn [ create_bd_port -dir I -type rst axil_aresetn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $axil_aresetn
  set axis_aclk [ create_bd_port -dir I -type clk axis_aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {m_axis_adap_tx_250mhz:m_axis_qdma_c2h_0:s_axis_adap_rx_250mhz:s_axis_qdma_h2c_0:s_axis_qdma_h2c_1:m_axis_qdma_c2h_1} \
   CONFIG.ASSOCIATED_RESET {axis_aresetn} \
 ] $axis_aclk
  set axis_aresetn [ create_bd_port -dir I -type rst axis_aresetn ]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32} \
 ] $axis_data_fifo_0

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32} \
 ] $axis_data_fifo_1

  # Create instance: axis_data_fifo_2, and set properties
  set axis_data_fifo_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_2 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32} \
 ] $axis_data_fifo_2

  # Create instance: axis_data_fifo_3, and set properties
  set axis_data_fifo_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_3 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32} \
   CONFIG.TDEST_WIDTH {0} \
 ] $axis_data_fifo_3

  # Create instance: axis_data_fifo_4, and set properties
  set axis_data_fifo_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_4 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32} \
   CONFIG.TDEST_WIDTH {0} \
 ] $axis_data_fifo_4

  # Create instance: axis_data_fifo_5, and set properties
  set axis_data_fifo_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_5 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {32} \
   CONFIG.TDEST_WIDTH {0} \
 ] $axis_data_fifo_5

  # Create instance: axis_dwidth_converter_0, and set properties
  set axis_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {128} \
   CONFIG.S_TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_converter_0

  # Create instance: axis_dwidth_converter_1, and set properties
  set axis_dwidth_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {128} \
   CONFIG.S_TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_converter_1

  # Create instance: axis_dwidth_converter_2, and set properties
  set axis_dwidth_converter_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_2 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {128} \
   CONFIG.S_TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_converter_2

  # Create instance: axis_dwidth_converter_3, and set properties
  set axis_dwidth_converter_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_3 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {64} \
 ] $axis_dwidth_converter_3

  # Create instance: axis_dwidth_converter_4, and set properties
  set axis_dwidth_converter_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_4 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {64} \
 ] $axis_dwidth_converter_4

  # Create instance: axis_dwidth_converter_5, and set properties
  set axis_dwidth_converter_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_5 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {64} \
 ] $axis_dwidth_converter_5

  # Create instance: axis_switch_0, and set properties
  set axis_switch_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch_0 ]
  set_property -dict [ list \
   CONFIG.M00_AXIS_HIGHTDEST {0x00000002} \
   CONFIG.NUM_SI {3} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {128} \
 ] $axis_switch_0

  # Create instance: axis_switch_1, and set properties
  set axis_switch_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch_1 ]
  set_property -dict [ list \
   CONFIG.DECODER_REG {1} \
   CONFIG.M00_AXIS_BASETDEST {0x00000001} \
   CONFIG.M00_AXIS_HIGHTDEST {0x00000001} \
   CONFIG.M01_AXIS_BASETDEST {0x000000ff} \
   CONFIG.M01_AXIS_HIGHTDEST {0x000000ff} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {1} \
 ] $axis_switch_1

  # Create instance: box_250mhz_p4_dummy_0, and set properties
  set block_name box_250mhz_p4_dummy
  set block_cell_name box_250mhz_p4_dummy_0
  if { [catch {set box_250mhz_p4_dummy_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $box_250mhz_p4_dummy_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: box_250mhz_p4_in_0, and set properties
  set block_name box_250mhz_p4_in
  set block_cell_name box_250mhz_p4_in_0
  if { [catch {set box_250mhz_p4_in_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $box_250mhz_p4_in_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: box_250mhz_p4_out_0, and set properties
  set block_name box_250mhz_p4_out
  set block_cell_name box_250mhz_p4_out_0
  if { [catch {set box_250mhz_p4_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $box_250mhz_p4_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {3} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_ports s_axil] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axis_switch_0/S00_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS1 [get_bd_intf_pins axis_data_fifo_1/M_AXIS] [get_bd_intf_pins axis_switch_0/S01_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_2_M_AXIS [get_bd_intf_pins axis_data_fifo_2/M_AXIS] [get_bd_intf_pins axis_switch_0/S02_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_3_M_AXIS [get_bd_intf_pins axis_data_fifo_3/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_3/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_4_M_AXIS [get_bd_intf_pins axis_data_fifo_4/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_4/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_5_M_AXIS [get_bd_intf_pins axis_data_fifo_5/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_5/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_1_M_AXIS [get_bd_intf_pins axis_data_fifo_1/S_AXIS] [get_bd_intf_pins axis_dwidth_converter_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_2_M_AXIS [get_bd_intf_pins axis_data_fifo_2/S_AXIS] [get_bd_intf_pins axis_dwidth_converter_2/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_3_M_AXIS [get_bd_intf_ports m_axis_qdma_c2h_0] [get_bd_intf_pins axis_dwidth_converter_3/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_4_M_AXIS [get_bd_intf_ports m_axis_qdma_c2h_1] [get_bd_intf_pins axis_dwidth_converter_4/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_5_M_AXIS [get_bd_intf_ports m_axis_adap_tx_250mhz] [get_bd_intf_pins axis_dwidth_converter_5/M_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M00_AXIS [get_bd_intf_pins axis_switch_0/M00_AXIS] [get_bd_intf_pins box_250mhz_p4_in_0/s_axis]
  connect_bd_intf_net -intf_net axis_switch_1_M00_AXIS [get_bd_intf_pins axis_data_fifo_3/S_AXIS] [get_bd_intf_pins axis_switch_1/M00_AXIS]
  connect_bd_intf_net -intf_net axis_switch_1_M01_AXIS [get_bd_intf_pins axis_data_fifo_4/S_AXIS] [get_bd_intf_pins axis_switch_1/M01_AXIS]
  connect_bd_intf_net -intf_net axis_switch_1_M02_AXIS [get_bd_intf_pins axis_data_fifo_5/S_AXIS] [get_bd_intf_pins axis_switch_1/M02_AXIS]
  connect_bd_intf_net -intf_net box_250mhz_p4_dummy_0_m_axis [get_bd_intf_pins box_250mhz_p4_dummy_0/m_axis] [get_bd_intf_pins box_250mhz_p4_out_0/s_axis]
  connect_bd_intf_net -intf_net box_250mhz_p4_in_0_m_axis [get_bd_intf_pins box_250mhz_p4_dummy_0/s_axis] [get_bd_intf_pins box_250mhz_p4_in_0/m_axis]
  connect_bd_intf_net -intf_net box_250mhz_p4_out_0_m_axis [get_bd_intf_pins axis_switch_1/S00_AXIS] [get_bd_intf_pins box_250mhz_p4_out_0/m_axis]
  connect_bd_intf_net -intf_net s_axis_adap_rx_250mhz_1 [get_bd_intf_ports s_axis_adap_rx_250mhz] [get_bd_intf_pins axis_dwidth_converter_2/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_qdma_h2c_0_1 [get_bd_intf_ports s_axis_qdma_h2c_0] [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_qdma_h2c_1_1 [get_bd_intf_ports s_axis_qdma_h2c_1] [get_bd_intf_pins axis_dwidth_converter_1/S_AXIS]

  # Create port connections
  connect_bd_net -net axil_aresetn_1 [get_bd_ports axil_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn]
  connect_bd_net -net box_250mhz_p4_dummy_0_user_metadata_out [get_bd_pins box_250mhz_p4_dummy_0/user_metadata_out] [get_bd_pins box_250mhz_p4_out_0/user_metadata_out]
  connect_bd_net -net box_250mhz_p4_dummy_0_user_metadata_out_valid [get_bd_pins box_250mhz_p4_dummy_0/user_metadata_out_valid] [get_bd_pins box_250mhz_p4_out_0/user_metadata_out_valid]
  connect_bd_net -net box_250mhz_p4_in_0_user_metadata_in [get_bd_pins box_250mhz_p4_dummy_0/user_metadata_in] [get_bd_pins box_250mhz_p4_in_0/user_metadata_in]
  connect_bd_net -net box_250mhz_p4_in_0_user_metadata_in_valid [get_bd_pins box_250mhz_p4_dummy_0/user_metadata_in_valid] [get_bd_pins box_250mhz_p4_in_0/user_metadata_in_valid]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_ports axil_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk]
  connect_bd_net -net s_axis_aclk_1_1 [get_bd_ports axis_aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins axis_data_fifo_2/s_axis_aclk] [get_bd_pins axis_data_fifo_3/s_axis_aclk] [get_bd_pins axis_data_fifo_4/s_axis_aclk] [get_bd_pins axis_data_fifo_5/s_axis_aclk] [get_bd_pins axis_dwidth_converter_0/aclk] [get_bd_pins axis_dwidth_converter_1/aclk] [get_bd_pins axis_dwidth_converter_2/aclk] [get_bd_pins axis_dwidth_converter_3/aclk] [get_bd_pins axis_dwidth_converter_4/aclk] [get_bd_pins axis_dwidth_converter_5/aclk] [get_bd_pins axis_switch_0/aclk] [get_bd_pins axis_switch_1/aclk] [get_bd_pins box_250mhz_p4_dummy_0/aclk] [get_bd_pins box_250mhz_p4_in_0/aclk] [get_bd_pins box_250mhz_p4_out_0/aclk]
  connect_bd_net -net s_axis_aresetn_0_1 [get_bd_ports axis_aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins axis_data_fifo_2/s_axis_aresetn] [get_bd_pins axis_data_fifo_3/s_axis_aresetn] [get_bd_pins axis_data_fifo_4/s_axis_aresetn] [get_bd_pins axis_data_fifo_5/s_axis_aresetn] [get_bd_pins axis_dwidth_converter_0/aresetn] [get_bd_pins axis_dwidth_converter_1/aresetn] [get_bd_pins axis_dwidth_converter_2/aresetn] [get_bd_pins axis_dwidth_converter_3/aresetn] [get_bd_pins axis_dwidth_converter_4/aresetn] [get_bd_pins axis_dwidth_converter_5/aresetn] [get_bd_pins axis_switch_0/aresetn] [get_bd_pins axis_switch_1/aresetn] [get_bd_pins box_250mhz_p4_dummy_0/aresetn] [get_bd_pins box_250mhz_p4_in_0/aresetn] [get_bd_pins box_250mhz_p4_out_0/aresetn]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins axis_switch_0/s_req_suppress] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces s_axil] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


