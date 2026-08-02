# Generate Xilinx Ethernet IP (run once from repo root):
#   vivado -mode batch -source vivado/create_eth_ip.tcl
#
# Committed RTL uses eth_mac_gmii_stub + eth_ingress for lab bring-up.
# After IP generation, replace the stub instance in eth_ingress.sv.

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set ip_dir     [file join $repo_root ip]

file mkdir $ip_dir

create_project -force eth_ip_gen $ip_dir/part -part xc7a100tcsg324-1
set_property ip_repo_paths $ip_dir [current_project]
update_ip_catalog

create_ip -name axi_ethernet -vendor xilinx.com -library ip -module_name axi_ethernet_0
set_property -dict [list \
  CONFIG.PHY_TYPE {RGMII} \
  CONFIG.TX {1} \
  CONFIG.RX {1} \
] [get_ips axi_ethernet_0]

generate_target all [get_ips axi_ethernet_0]
export_ip_user_files -of_objects [get_ips axi_ethernet_0] -no_script -sync -force -quiet

close_project
puts "Ethernet IP exported under $ip_dir (optional upgrade path)."
