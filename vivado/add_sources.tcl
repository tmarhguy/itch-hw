# Add RTL and constraints to the existing itch-hw Vivado project (repo root).
# Usage (from repo root):
#   vivado -mode batch -source vivado/add_sources.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set xpr_path   [file join $repo_root itch-hw.xpr]
set rtl_root   [file join $repo_root rtl]

if {![file exists $xpr_path]} {
  error "Project not found: $xpr_path"
}

open_project $xpr_path

# Add every SystemVerilog file under rtl/ (recursive). Safe to re-run.
set sv_files [glob -nocomplain -directory $rtl_root -types f -recursive *.sv]

set added 0
foreach path $sv_files {
  set norm [file normalize $path]
  if {[lsearch -exact [get_files -quiet -of_objects [get_filesets sources_1]] $norm] < 0} {
    add_files -norecurse -fileset sources_1 $norm
    incr added
    puts "Added: $norm"
  }
}

set xdc_path [file join $repo_root constraints nexys_a7_100t.xdc]
if {![file exists $xdc_path]} {
  error "Constraints not found: $xdc_path"
}
if {[llength [get_files -quiet -of_objects [get_filesets constrs_1] $xdc_path]] == 0} {
  add_files -fileset constrs_1 $xdc_path
}

# Optional generated IP (after vivado/create_eth_ip.tcl)
set ip_dir [file join $repo_root ip]
if {[file isdirectory $ip_dir]} {
  foreach xci [glob -nocomplain -directory $ip_dir -tails *.xci] {
    set ip_path [file join $ip_dir $xci]
    if {[llength [get_files -quiet $ip_path]] == 0} {
      add_files -norecurse $ip_path
    }
  }
}

set_property top nexys_a7_100t_top [get_filesets sources_1]
set_property top_lib xil_defaultlib [get_filesets sources_1]
update_compile_order -fileset sources_1

set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]

# Sanity check: eth ingress dependencies present in fileset.
foreach req {lan8720_mdio.sv udp_rx_minimal.sv byte_cdc_fifo.sv moldudp64_rx.sv} {
  if {[llength [get_files -quiet -of_objects [get_filesets sources_1] */$req]] == 0} {
    error "Required source missing from sources_1: $req"
  }
}

save_project
close_project

puts "Sources sync complete ($added new file\[s\]). Top: nexys_a7_100t_top"
